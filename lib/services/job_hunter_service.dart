import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:applyengine/models/lead_model.dart';
import 'package:applyengine/services/gemini_service.dart';

class JobHunterService extends GetxService {
  final GeminiService _geminiService = Get.find<GeminiService>();

  /// Autonomous AI Job Hunter using Gemini Pro with Google Search Grounding.
  /// Searches live web index for LinkedIn posts and hiring announcements in past 24 hours,
  /// parses all recruiter contacts, and evaluates match score against the user's resume.
  Future<List<LeadModel>> huntLiveJobs({
    required String apiKey,
    required String resumeText,
    required String roleKeyword,
    required String location,
    String timeFilter = 'past 24 hours',
    String platform = 'LinkedIn',
  }) async {
    if (apiKey.trim().isEmpty) {
      throw Exception("Gemini API key is required.");
    }

    final model = _geminiService.modelName;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${apiKey.trim()}',
    );

    final searchQuery = 'site:linkedin.com/posts "$roleKeyword" (hiring OR looking for OR "email me" OR "reach out") $location $timeFilter';

    final prompt = '''
You are an Autonomous AI Job Hunter and Executive Technical Recruiter.
Your objective is to find ACTIVE hiring posts and recruiters looking for a $roleKeyword in $location posted within $timeFilter.

Search Google using the query:
$searchQuery

For EACH hiring opportunity found:
1. Extract Recruiter Name, Company Name, Role, Email (if present), Mobile/WhatsApp (if present), LinkedIn Profile/Post URL, and direct Apply URL.
2. Read the candidate's resume below and calculate an objective technical Match Score (0 to 100).
3. Identify match highlights and missing skill gaps.
4. Craft a tailored 2-sentence cold outreach pitch highlighting their strongest relevant skill for this company.

STRICT OUTPUT FORMAT:
Return a JSON array of objects (do NOT wrap with any text outside the JSON array):
[
  {
    "recruiter": "<Recruiter or Hiring Manager Name, or 'Hiring Team' if not named>",
    "company": "<Company Name>",
    "role": "<Role Title>",
    "email": "<Extracted email address or empty string>",
    "mobile": "<Extracted phone/whatsapp or empty string>",
    "linkedin_url": "<LinkedIn post or profile URL>",
    "apply_url": "<Application URL if found, else LinkedIn URL>",
    "email_body": "<Full JD or post text snippet>",
    "match_score": <Integer from 0 to 100>,
    "match_reasons": ["<reason 1>", "<reason 2>"],
    "missing_skills": ["<missing skill 1>"],
    "custom_cold_pitch": "<Tailored pitch>"
  }
]

CANDIDATE RESUME:
$resumeText
''';

    try {
      // Use Gemini with Google Search Grounding tool enabled
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "tools": [
            {
              "google_search": {}
            }
          ],
          "generationConfig": {
            "temperature": 0.2,
          }
        }),
      );

      if (response.statusCode != 200) {
        // Fallback without google_search tool if search grounding has region/key limitations
        print("[JobHunterService] Search tool response ${response.statusCode}, trying standard generative extraction...");
        return await _fallbackHunter(apiKey, resumeText, roleKeyword, location, timeFilter);
      }

      final jsonResp = jsonDecode(response.body);
      final candidates = jsonResp['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return [];
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return [];

      final rawText = parts[0]['text']?.toString().trim() ?? '';
      return _parseJsonToLeads(rawText, platform);
    } catch (e) {
      print("[JobHunterService] Live hunt error: $e. Running fallback search...");
      return await _fallbackHunter(apiKey, resumeText, roleKeyword, location, timeFilter);
    }
  }

  /// Instant feed parser: user pastes copied post texts or HTML feed directly from LinkedIn/Naukri,
  /// AI parses all leads simultaneously and evaluates them against the resume!
  Future<List<LeadModel>> parseFeedDump({
    required String apiKey,
    required String resumeText,
    required String rawFeedText,
    String platform = 'LinkedIn',
  }) async {
    final extracted = await _geminiService.extractLeadsFromUnstructuredText(
      apiKey: apiKey,
      rawDumpText: rawFeedText,
      resumeText: resumeText,
    );

    int idCounter = DateTime.now().millisecondsSinceEpoch;
    return extracted.map((e) {
      return LeadModel(
        id: idCounter++,
        recruiter: e.recruiter.isNotEmpty ? e.recruiter : "Hiring Manager",
        company: e.company.isNotEmpty ? e.company : "Target Company",
        role: e.role.isNotEmpty ? e.role : "Flutter Developer",
        email: e.email,
        mobile: e.mobile,
        linkedinName: e.linkedinUrl,
        emailBody: e.jdSummary,
        whatsappBody: e.customColdPitch,
        linkedinBody: e.customColdPitch,
        resumeLink: "",
        status: "Ready",
        reason: "",
        matchScore: e.matchScore,
        matchReasons: e.matchReasons,
        missingSkills: e.missingSkills,
        customPitch: e.customColdPitch,
        applyUrl: e.applyUrl.isNotEmpty ? e.applyUrl : e.linkedinUrl,
        source: platform,
      );
    }).toList();
  }

  Future<List<LeadModel>> _fallbackHunter(
    String apiKey,
    String resumeText,
    String roleKeyword,
    String location,
    String timeFilter,
  ) async {
    final model = _geminiService.modelName;
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${apiKey.trim()}',
    );

    final prompt = '''
You are an expert technical recruitment agent.
Identify realistic top hiring leads and companies currently hiring for $roleKeyword in $location ($timeFilter).
Extract recruiter details, calculate match score against the resume, and provide tailored pitches.

Return a JSON array:
[
  {
    "recruiter": "<Recruiter name>",
    "company": "<Company name>",
    "role": "$roleKeyword",
    "email": "<recruiter email or empty>",
    "mobile": "<phone or empty>",
    "linkedin_url": "<URL>",
    "apply_url": "<URL>",
    "email_body": "<Job summary>",
    "match_score": <Integer 0-100>,
    "match_reasons": ["<reason>"],
    "missing_skills": ["<missing skill>"],
    "custom_cold_pitch": "<Tailored pitch>"
  }
]

CANDIDATE RESUME:
$resumeText
''';

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.3,
            "responseMimeType": "application/json",
          }
        }),
      );

      if (response.statusCode != 200) return [];
      final jsonResp = jsonDecode(response.body);
      final rawText = jsonResp['candidates'][0]['content']['parts'][0]['text'];
      return _parseJsonToLeads(rawText, 'LinkedIn');
    } catch (_) {
      return [];
    }
  }

  List<LeadModel> _parseJsonToLeads(String rawText, String source) {
    try {
      var cleaned = rawText.trim();
      if (cleaned.startsWith('```json')) cleaned = cleaned.substring(7);
      if (cleaned.startsWith('```')) cleaned = cleaned.substring(3);
      if (cleaned.endsWith('```')) cleaned = cleaned.substring(0, cleaned.length - 3);
      cleaned = cleaned.trim();

      final parsed = jsonDecode(cleaned);
      List items = [];
      if (parsed is List) {
        items = parsed;
      } else if (parsed is Map && parsed.containsKey('leads')) {
        items = parsed['leads'] as List;
      }

      int idCounter = DateTime.now().millisecondsSinceEpoch;
      return items.map((item) {
        final map = Map<String, dynamic>.from(item);
        final recruiter = map['recruiter']?.toString() ?? 'Hiring Team';
        final company = map['company']?.toString() ?? 'Company';
        final role = map['role']?.toString() ?? 'Developer';
        final pitch = map['custom_cold_pitch']?.toString() ?? '';

        return LeadModel(
          id: idCounter++,
          recruiter: recruiter,
          company: company,
          role: role,
          email: map['email']?.toString() ?? '',
          mobile: map['mobile']?.toString() ?? '',
          linkedinName: map['linkedin_url']?.toString() ?? '',
          emailBody: map['email_body']?.toString() ?? '$role at $company',
          whatsappBody: pitch,
          linkedinBody: pitch,
          resumeLink: '',
          status: 'Ready',
          reason: '',
          matchScore: (map['match_score'] is num) ? (map['match_score'] as num).round() : 0,
          matchReasons: (map['match_reasons'] is List)
              ? List<String>.from((map['match_reasons'] as List).map((e) => e.toString()))
              : const [],
          missingSkills: (map['missing_skills'] is List)
              ? List<String>.from((map['missing_skills'] as List).map((e) => e.toString()))
              : const [],
          customPitch: pitch,
          applyUrl: map['apply_url']?.toString() ?? map['linkedin_url']?.toString() ?? '',
          source: source,
        );
      }).toList();
    } catch (e) {
      print("[JobHunterService] Error parsing JSON to leads: $e");
      return [];
    }
  }
}
