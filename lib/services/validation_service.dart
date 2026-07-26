import 'dart:io';
import 'package:email_validator/email_validator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class ValidationService extends GetxService {
  
  /// Checks if DNS resolution is active (offline check).
  Future<bool> _isDnsWorking() async {
    try {
      final lookupResult = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      return lookupResult.isNotEmpty && lookupResult.first.rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Validates raw lead objects and flags structures, empty cells, and duplicates.
  List<Map<String, String>> parseAlternativeContacts(String text) {
    final List<Map<String, String>> contacts = [];
    if (text.isEmpty) return contacts;

    // 1. Try parsing HTML anchor tags: <a href="url">name</a>
    final htmlRegex = RegExp(r'''<a\s+[^>]*href=["']([^"']+)["'][^>]*>(.*?)</a>''', caseSensitive: false);
    final htmlMatches = htmlRegex.allMatches(text);
    if (htmlMatches.isNotEmpty) {
      for (final match in htmlMatches) {
        final url = match.group(1)?.trim() ?? '';
        final name = match.group(2)?.replaceAll(RegExp(r'<[^>]*>'), '').trim() ?? '';
        final cleanedName = name.replaceFirst(RegExp(r'^[,;\s]+'), '').replaceFirst(RegExp(r'[,;\s]+$'), '');
        if (url.isNotEmpty && cleanedName.isNotEmpty) {
          contacts.add({'name': cleanedName, 'link': url});
        }
      }
      if (contacts.isNotEmpty) return contacts;
    }

    // 2. Try parsing HYPERLINK formulas: HYPERLINK("url", "name")
    final formulaRegex = RegExp(r'''HYPERLINK\(\s*["']([^"']+)["']\s*,\s*["']([^"']+)["']\s*\)''', caseSensitive: false);
    final formulaMatches = formulaRegex.allMatches(text);
    if (formulaMatches.isNotEmpty) {
      for (final match in formulaMatches) {
        final url = match.group(1)?.trim() ?? '';
        final name = match.group(2)?.trim() ?? '';
        final cleanedName = name.replaceFirst(RegExp(r'^[,;\s]+'), '').replaceFirst(RegExp(r'[,;\s]+$'), '');
        if (url.isNotEmpty && cleanedName.isNotEmpty) {
          contacts.add({'name': cleanedName, 'link': url});
        }
      }
      if (contacts.isNotEmpty) return contacts;
    }

    // 3. Try parsing Markdown links: [name](url)
    final mdRegex = RegExp(r'\[([^\]]+)\]\((https?://[^\s\)]+)\)');
    final mdMatches = mdRegex.allMatches(text);
    if (mdMatches.isNotEmpty) {
      for (final match in mdMatches) {
        final name = match.group(1)?.trim() ?? '';
        final url = match.group(2)?.trim() ?? '';
        final cleanedName = name.replaceFirst(RegExp(r'^[,;\s]+'), '').replaceFirst(RegExp(r'[,;\s]+$'), '');
        if (cleanedName.isNotEmpty && url.isNotEmpty) {
          contacts.add({'name': cleanedName, 'link': url});
        }
      }
      if (contacts.isNotEmpty) return contacts;
    }

    // 4. Try parsing parentheses: name (url) or similar
    final parenRegex = RegExp(r'([^()]+)\((https?://[^\s\)]+)\)');
    final parenMatches = parenRegex.allMatches(text);
    if (parenMatches.isNotEmpty) {
      for (final match in parenMatches) {
        final name = match.group(1)?.trim() ?? '';
        final url = match.group(2)?.trim() ?? '';
        final cleanedName = name.replaceFirst(RegExp(r'^[,;\s]+'), '').replaceFirst(RegExp(r'[,;\s]+$'), '');
        if (cleanedName.isNotEmpty && url.isNotEmpty) {
          contacts.add({'name': cleanedName, 'link': url});
        }
      }
      if (contacts.isNotEmpty) return contacts;
    }

    // 5. Try parsing delimiters: name - url, name : url, name | url
    final delimRegex = RegExp(r'([^:\-\|,\n]+)\s*[:\-\|]\s*(https?://[^\s,;\n]+)');
    final delimMatches = delimRegex.allMatches(text);
    if (delimMatches.isNotEmpty) {
      for (final match in delimMatches) {
        final name = match.group(1)?.trim() ?? '';
        final url = match.group(2)?.trim() ?? '';
        final cleanedName = name.replaceFirst(RegExp(r'^[,;\s]+'), '').replaceFirst(RegExp(r'[,;\s]+$'), '');
        if (cleanedName.isNotEmpty && url.isNotEmpty) {
          contacts.add({'name': cleanedName, 'link': url});
        }
      }
      if (contacts.isNotEmpty) return contacts;
    }

    // 6. Fallback: Split by commas or semicolons
    final parts = text.split(RegExp(r'[,;\n]'));
    for (var part in parts) {
      part = part.trim();
      if (part.isEmpty) continue;
      
      // Check if the part contains a URL
      final urlRegex = RegExp(r'https?://[^\s]+');
      final urlMatch = urlRegex.firstMatch(part);
      if (urlMatch != null) {
        final url = urlMatch.group(0)!;
        var name = part.replaceAll(url, '').replaceAll(RegExp(r'[()\-\[\]:|]'), '').trim();
        name = name.replaceFirst(RegExp(r'^[,;\s]+'), '').replaceFirst(RegExp(r'[,;\s]+$'), '');
        contacts.add({
          'name': name.isNotEmpty ? name : 'Contact',
          'link': url,
        });
      } else {
        // Just name without URL
        final name = part.replaceFirst(RegExp(r'^[,;\s]+'), '').replaceFirst(RegExp(r'[,;\s]+$'), '');
        if (name.isNotEmpty) {
          contacts.add({
            'name': name,
            'link': '',
          });
        }
      }
    }

    return contacts;
  }

  /// Validates raw lead objects and flags structures, empty cells, and duplicates.
  Future<List<Map<String, dynamic>>> validateLeads({
    required List<Map<String, dynamic>> leads,
    required String campaignType,
    bool removeDuplicates = true,
    bool detectDuplicateRecruiter = true,
  }) async {
    final Set<String> seenEmails = {};
    final Set<String> seenMobiles = {};
    final Set<String> seenLinkedInLinks = {};
    final Set<String> seenRecruiters = {};
    final List<Map<String, dynamic>> validated = [];

    // Load same-day sent history from storage
    final storage = GetStorage();
    final List<dynamic> rawHistory = storage.read('sent_history') ?? [];
    final String todayDate = DateTime.now().toLocal().toString().split(' ')[0]; // YYYY-MM-DD
    final Set<String> emailedToday = {};
    for (var entry in rawHistory) {
      if (entry is Map) {
        final String email = (entry['email'] ?? '').toString().toLowerCase().trim();
        final String date = (entry['date'] ?? '').toString().trim();
        if (date == todayDate && email.isNotEmpty) {
          emailedToday.add(email);
        }
      }
    }

    final bool isDnsAvailable = await _isDnsWorking();

    // LinkedIn Campaign: explode 'Alternative Contacts' cells
    final List<Map<String, dynamic>> explodedLeads = [];
    if (campaignType == 'LinkedIn') {
      int newId = 0;
      for (var lead in leads) {
        final String altContactsStr = (lead['Alternative Contacts'] ?? '').toString().trim();
        final List<Map<String, String>> parsedContacts = parseAlternativeContacts(altContactsStr);

        if (parsedContacts.isNotEmpty) {
          for (var contact in parsedContacts) {
            final Map<String, dynamic> cCopy = Map<String, dynamic>.from(lead);
            cCopy['id'] = newId++;
            cCopy['Recruiter'] = contact['name'] ?? '';
            cCopy['LinkedIn Name'] = contact['link'] ?? '';
            explodedLeads.add(cCopy);
          }
        } else {
          // Fallback to primary recruiter if they have a LinkedIn profile URL
          final String linkedinVal = (lead['LinkedIn Name'] ?? '').toString().trim();
          if (linkedinVal.isNotEmpty) {
            final Map<String, dynamic> cCopy = Map<String, dynamic>.from(lead);
            cCopy['id'] = newId++;
            explodedLeads.add(cCopy);
          } else {
            // Keep the row but let it fail or skip in validation
            final Map<String, dynamic> cCopy = Map<String, dynamic>.from(lead);
            cCopy['id'] = newId++;
            explodedLeads.add(cCopy);
          }
        }
      }
    } else {
      explodedLeads.addAll(leads);
    }

    // 1. Initial sequential check for duplicates, empty, structure, and history
    for (var lead in explodedLeads) {
      final Map<String, dynamic> lCopy = Map<String, dynamic>.from(lead);
      
      final String email = (lCopy['Email'] ?? '').toString().trim();
      final String mobile = (lCopy['Mobile'] ?? '').toString().trim();
      final String linkedinUrl = (lCopy['LinkedIn Name'] ?? '').toString().trim();
      final String recruiter = (lCopy['Recruiter'] ?? '').toString().trim();
      final String company = (lCopy['Company'] ?? '').toString().trim();

      if (campaignType == 'Email') {
        // 1. Check if email is empty or indicates no email provided
        final String emailLower = email.toLowerCase();
        final bool isEmailEmpty = email.isEmpty ||
            emailLower == 'na' ||
            emailLower == 'n/a' ||
            emailLower == 'null' ||
            emailLower == 'none' ||
            emailLower == 'not provided' ||
            emailLower == 'no email provided' ||
            emailLower == 'no email';
            
        if (isEmailEmpty) {
          lCopy['Status'] = 'Skipped';
          lCopy['Reason'] = 'Email Not Provided';
          validated.add(lCopy);
          continue;
        }

        // 2. Validate email structure
        final bool isValidSyntax = EmailValidator.validate(email);
        if (!isValidSyntax) {
          lCopy['Status'] = 'Invalid';
          lCopy['Reason'] = 'Invalid email structure';
          validated.add(lCopy);
          continue;
        }

        final String normalizedEmail = email.toLowerCase();

        // Check if email was already sent today to prevent duplicates
        if (emailedToday.contains(normalizedEmail)) {
          lCopy['Status'] = 'Skipped';
          lCopy['Reason'] = 'Already emailed today';
          validated.add(lCopy);
          continue;
        }

        // 3. Deduplicate Email
        if (removeDuplicates && seenEmails.contains(normalizedEmail)) {
          lCopy['Status'] = 'Duplicate';
          lCopy['Reason'] = 'Duplicate Email';
          validated.add(lCopy);
          continue;
        }
        seenEmails.add(normalizedEmail);
      } else if (campaignType == 'WhatsApp') {
        // --- WhatsApp Campaign Validation ---
        final String mobileLower = mobile.toLowerCase();
        final bool isMobileEmpty = mobile.isEmpty ||
            mobileLower == 'na' ||
            mobileLower == 'n/a' ||
            mobileLower == 'null' ||
            mobileLower == 'none' ||
            mobileLower == 'not provided' ||
            mobileLower == 'no mobile provided' ||
            mobileLower == 'no mobile';

        if (isMobileEmpty) {
          lCopy['Status'] = 'Skipped';
          lCopy['Reason'] = 'Empty Mobile Number';
          validated.add(lCopy);
          continue;
        }

        // Clean scientific notation if present (e.g. 9.1816E+11)
        String standardizedMobile = mobile;
        if (standardizedMobile.toUpperCase().contains('E')) {
          final parsedDouble = double.tryParse(standardizedMobile);
          if (parsedDouble != null) {
            standardizedMobile = parsedDouble.round().toString();
          }
        }

        // Clean digits: remove non-digits
        final String cleanMobile = standardizedMobile.replaceAll(RegExp(r'\D'), '');
        
        // Handle auto-prefixing 10 digit Indian number with 91
        String finalMobile = cleanMobile;
        if (cleanMobile.length == 10) {
          finalMobile = '91$cleanMobile';
        }
        
        // Update display mobile number with standardized digits
        lCopy['Mobile'] = finalMobile;

        // Verify if mobile number matches the Indian country code format (91xxxxxxxxxx)
        final bool isValidIndianMobile = finalMobile.length == 12 && finalMobile.startsWith('91');

        if (!isValidIndianMobile) {
          lCopy['Status'] = 'Skipped';
          lCopy['Reason'] = 'Other Country / Invalid Mobile';
          validated.add(lCopy);
          continue;
        }

        // Deduplicate mobile numbers
        if (removeDuplicates && seenMobiles.contains(finalMobile)) {
          lCopy['Status'] = 'Duplicate';
          lCopy['Reason'] = 'Duplicate Mobile Number';
          validated.add(lCopy);
          continue;
        }
        seenMobiles.add(finalMobile);
      } else if (campaignType == 'LinkedIn') {
        // --- LinkedIn Campaign Validation ---
        if (linkedinUrl.isEmpty) {
          lCopy['Status'] = 'Skipped';
          lCopy['Reason'] = 'Empty LinkedIn Link';
          validated.add(lCopy);
          continue;
        }

        final String urlLower = linkedinUrl.toLowerCase();
        final bool isValidLinkedIn = urlLower.contains('linkedin.com');
        if (!isValidLinkedIn) {
          lCopy['Status'] = 'Invalid';
          lCopy['Reason'] = 'Invalid LinkedIn Link';
          validated.add(lCopy);
          continue;
        }

        // Deduplicate LinkedIn link
        if (removeDuplicates && seenLinkedInLinks.contains(urlLower)) {
          lCopy['Status'] = 'Duplicate';
          lCopy['Reason'] = 'Duplicate LinkedIn Link';
          validated.add(lCopy);
          continue;
        }
        seenLinkedInLinks.add(urlLower);
      }

      // Deduplicate Recruiter per Company
      if (detectDuplicateRecruiter && recruiter.isNotEmpty) {
        final String recruiterKey = '${recruiter.toLowerCase()}|||${company.toLowerCase()}';
        if (seenRecruiters.contains(recruiterKey)) {
          lCopy['Status'] = 'Duplicate';
          lCopy['Reason'] = 'Duplicate Recruiter for Company';
          validated.add(lCopy);
          continue;
        }
        seenRecruiters.add(recruiterKey);
      }

      lCopy['Status'] = 'Ready';
      lCopy['Reason'] = '';
      validated.add(lCopy);
    }

    // 2. Concurrent domain DNS lookup verification for leads marked 'Ready' (Email only)
    if (campaignType == 'Email' && isDnsAvailable) {
      final List<Future<void>> lookupFutures = [];
      for (var lead in validated) {
        if (lead['Status'] == 'Ready') {
          final String email = (lead['Email'] ?? '').toString().trim();
          final parts = email.split('@');
          if (parts.length == 2) {
            final domain = parts[1];
            final future = InternetAddress.lookup(domain)
                .timeout(const Duration(seconds: 3))
                .then((addresses) {
                  if (addresses.isEmpty || addresses.first.rawAddress.isNotEmpty == false) {
                    lead['Status'] = 'Invalid';
                    lead['Reason'] = 'Domain lookup failed (non-existent domain)';
                  }
                })
                .catchError((_) {
                  lead['Status'] = 'Invalid';
                  lead['Reason'] = 'Domain lookup failed (non-existent domain)';
                });
            lookupFutures.add(future);
          }
        }
      }
      if (lookupFutures.isNotEmpty) {
        await Future.wait(lookupFutures);
      }
    }

    return validated;
  }
}

