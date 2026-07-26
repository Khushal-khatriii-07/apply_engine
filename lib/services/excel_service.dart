import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:excel/excel.dart';
import 'package:get/get.dart';
import 'package:xml/xml.dart';

class ExcelService extends GetxService {
  
  void _replaceArchiveFile(Archive archive, String name, List<int> content) {
    final newFile = ArchiveFile(name, content.length, content);
    archive.addFile(newFile);
  }

  /// In-memory sanitization of duplicate shared strings and custom number formats (< 164)
  List<int> _sanitizeExcelBytes(List<int> bytes) {
    try {
      final decodedArchive = ZipDecoder().decodeBytes(bytes);
      final archive = Archive();
      for (final file in decodedArchive.files) {
        archive.addFile(file);
      }
      
      // 1. STANDARDIZE WORKBOOK RELATIONSHIPS (Id, Target, Type case-sensitivity & target paths)
      final relsFile = archive.findFile('xl/_rels/workbook.xml.rels');
      if (relsFile != null && relsFile.content != null) {
        relsFile.decompress();
        final contentBytes = relsFile.content;
        if (contentBytes != null) {
          final relsXml = XmlDocument.parse(utf8.decode(contentBytes));
          final relationships = relsXml.findAllElements('Relationship').toList();
          bool modified = false;
          for (final rel in relationships) {
            String? idVal;
            String? targetVal;
            String? typeVal;
            
            XmlAttribute? idAttr;
            XmlAttribute? targetAttr;
            XmlAttribute? typeAttr;
            
            for (final attr in rel.attributes) {
              final nameLower = attr.name.local.toLowerCase();
              if (nameLower == 'id') {
                idVal = attr.value;
                idAttr = attr;
              } else if (nameLower == 'target') {
                targetVal = attr.value;
                targetAttr = attr;
              } else if (nameLower == 'type') {
                typeVal = attr.value;
                typeAttr = attr;
              }
            }
            
            if (idAttr != null && idAttr.name.toString() != 'Id') {
              rel.removeAttribute(idAttr.name.toString());
              rel.setAttribute('Id', idVal!);
              modified = true;
            }
            if (targetAttr != null) {
              // Clean target paths (strip leading slash or /xl/ prefix)
              String cleanedTarget = targetVal ?? '';
              if (cleanedTarget.startsWith('/xl/')) {
                cleanedTarget = cleanedTarget.substring(4);
              } else if (cleanedTarget.startsWith('xl/')) {
                cleanedTarget = cleanedTarget.substring(3);
              } else if (cleanedTarget.startsWith('/')) {
                cleanedTarget = cleanedTarget.substring(1);
              }
              
              if (cleanedTarget != targetVal || targetAttr.name.toString() != 'Target') {
                rel.removeAttribute(targetAttr.name.toString());
                rel.setAttribute('Target', cleanedTarget);
                modified = true;
              }
            }
            if (typeAttr != null && typeAttr.name.toString() != 'Type') {
              rel.removeAttribute(typeAttr.name.toString());
              rel.setAttribute('Type', typeVal!);
              modified = true;
            }
          }
          if (modified) {
            _replaceArchiveFile(archive, 'xl/_rels/workbook.xml.rels', utf8.encode(relsXml.toString()));
          }
        }
      }

      // 2. STANDARDIZE WORKBOOK SHEETS ATTRIBUTES (r:id namespaces)
      final workbookFile = archive.findFile('xl/workbook.xml');
      if (workbookFile != null && workbookFile.content != null) {
        workbookFile.decompress();
        final contentBytes = workbookFile.content;
        if (contentBytes != null) {
          final workbookXml = XmlDocument.parse(utf8.decode(contentBytes));
          final sheetsElement = workbookXml.findAllElements('sheets').firstOrNull;
          if (sheetsElement != null) {
            final sheetList = sheetsElement.findElements('sheet').toList();
            bool modified = false;
            for (final sheet in sheetList) {
              String? rId;
              XmlAttribute? idAttr;
              for (final attr in sheet.attributes) {
                if (attr.name.local == 'id') {
                  rId = attr.value;
                  idAttr = attr;
                  break;
                }
              }
              if (idAttr != null && idAttr.name.toString() != 'r:id') {
                sheet.removeAttribute(idAttr.name.toString());
                sheet.setAttribute('r:id', rId!);
                modified = true;
              }
            }
            if (modified) {
              _replaceArchiveFile(archive, 'xl/workbook.xml', utf8.encode(workbookXml.toString()));
            }
          }
        }
      }

      // 3. SANITIZE ALL WORKSHEET CELLS
      // We do this to prevent crashes on empty inlineStr, empty boolean/error/str, and invalid shared strings references.
      final sharedStringsFile = archive.findFile('xl/sharedStrings.xml');
      final List<XmlElement> siElements = [];
      final Map<int, int> oldToNewIndex = {};
      
      if (sharedStringsFile != null && sharedStringsFile.content != null) {
        sharedStringsFile.decompress();
        final contentBytes = sharedStringsFile.content;
        if (contentBytes != null) {
          try {
            final sstXml = XmlDocument.parse(utf8.decode(contentBytes));
            final sstElement = sstXml.findElements('sst').firstOrNull;
            if (sstElement != null) {
              final parsedSis = sstElement.findElements('si').toList();
              siElements.addAll(parsedSis);
              
              final List<XmlElement> uniqueSiElements = [];
              final Map<String, int> siToNewIndex = {};
              
              for (int i = 0; i < parsedSis.length; i++) {
                final si = parsedSis[i];
                final String key = si.toString();
                if (!siToNewIndex.containsKey(key)) {
                  final newIdx = uniqueSiElements.length;
                  siToNewIndex[key] = newIdx;
                  uniqueSiElements.add(si.copy() as XmlElement);
                }
                oldToNewIndex[i] = siToNewIndex[key]!;
              }
              
              // Rewrite sharedStrings if duplicates are present
              if (uniqueSiElements.length < parsedSis.length) {
                sstElement.children.clear();
                sstElement.children.addAll(uniqueSiElements);
                sstElement.setAttribute('count', uniqueSiElements.length.toString());
                sstElement.setAttribute('uniqueCount', uniqueSiElements.length.toString());
                
                _replaceArchiveFile(archive, 'xl/sharedStrings.xml', utf8.encode(sstXml.toString()));
              }
            }
          } catch (e) {
            print("[ExcelService] Warning: Failed parsing shared strings XML: $e");
          }
        }
      }
      
      // Now always process and clean sheet cells
      for (final file in archive.files) {
        if (file.name.startsWith('xl/worksheets/sheet') && file.name.endsWith('.xml')) {
          if (file.content != null) {
            file.decompress();
            try {
              final sheetXml = XmlDocument.parse(utf8.decode(file.content!));
              final cells = sheetXml.findAllElements('c');
              bool modified = false;
              
              for (final cell in cells) {
                final formulaNode = cell.findElements('f').firstOrNull;
                final vElement = cell.findElements('v').firstOrNull;
                if (formulaNode != null && vElement != null) {
                  final formulaText = formulaNode.innerText.trim();
                  if (formulaText.toUpperCase().contains('HYPERLINK')) {
                    if (!vElement.innerText.toUpperCase().contains('HYPERLINK')) {
                      vElement.children.clear();
                      vElement.children.add(XmlText(formulaText));
                      modified = true;
                    }
                  }
                }

                final type = cell.getAttribute('t');
                if (type == 's') {
                  final vElement = cell.findElements('v').firstOrNull;
                  if (vElement != null) {
                    final int? oldIdx = int.tryParse(vElement.innerText.trim());
                    if (oldIdx != null && oldIdx >= 0 && oldIdx < siElements.length) {
                      final int? newIdx = oldToNewIndex[oldIdx];
                      if (newIdx != null && newIdx != oldIdx) {
                        vElement.children.clear();
                        vElement.children.add(XmlText(newIdx.toString()));
                        modified = true;
                      }
                    } else {
                      // Out of bounds or invalid: remove shared string type and content to avoid crash
                      cell.removeAttribute('t');
                      if (vElement.parent != null) {
                        vElement.parent!.children.remove(vElement);
                      }
                      modified = true;
                    }
                  } else {
                    cell.removeAttribute('t');
                    modified = true;
                  }
                } else if (type == 'inlineStr') {
                  if (cell.findAllElements('t').isEmpty) {
                    cell.removeAttribute('t');
                    modified = true;
                  }
                } else if (type == 'b' || type == 'e' || type == 'str') {
                  if (cell.findElements('v').isEmpty) {
                    cell.removeAttribute('t');
                    modified = true;
                  }
                }
              }
              
              if (modified) {
                _replaceArchiveFile(archive, file.name, utf8.encode(sheetXml.toString()));
              }
            } catch (e) {
              print("[ExcelService] Warning: Failed parsing sheet XML ${file.name}: $e");
            }
          }
        }
      }
      
      // 4. DEDUPLICATE & CLEAN STYLES (numFmtId < 164)
      final stylesFile = archive.findFile('xl/styles.xml');
      if (stylesFile != null && stylesFile.content != null) {
        stylesFile.decompress();
        final contentBytes = stylesFile.content;
        if (contentBytes != null) {
          final stylesXml = XmlDocument.parse(utf8.decode(contentBytes));
          final numFmts = stylesXml.findAllElements('numFmts').firstOrNull;
          if (numFmts != null) {
            final numFmtList = numFmts.findElements('numFmt').toList();
            bool modified = false;
            for (final numFmt in numFmtList) {
              final idStr = numFmt.getAttribute('numFmtId');
              if (idStr != null) {
                final id = int.tryParse(idStr);
                if (id != null && id < 164) {
                  numFmt.parent?.children.remove(numFmt);
                  modified = true;
                }
              }
            }
            if (modified) {
              _replaceArchiveFile(archive, 'xl/styles.xml', utf8.encode(stylesXml.toString()));
            }
          }
        }
      }
      
      return ZipEncoder().encode(archive) ?? bytes;
    } catch (e, s) {
      print('Sanitizer error: $e\n$s');
      // Return un-sanitized bytes in case of error (let parser try to decode)
      return bytes;
    }
  }

  /// Clean float/scientific cell values and NA values
  String _cleanCellValue(dynamic cellValue) {
    if (cellValue == null) return '';
    String valStr = cellValue.toString().trim();
    
    // Handle scientific notation values
    if (valStr.toUpperCase().contains('E')) {
      final parsedDouble = double.tryParse(valStr);
      if (parsedDouble != null) {
        return parsedDouble.round().toString();
      }
    }
    
    // Remove trailing .0 decimals for whole floats
    if (valStr.endsWith('.0')) {
      final parsedDouble = double.tryParse(valStr);
      if (parsedDouble != null && parsedDouble == parsedDouble.roundToDouble()) {
        return parsedDouble.round().toString();
      }
    }
    
    // Map NA values to empty string
    final valLower = valStr.toLowerCase();
    if (valLower == 'na' ||
        valLower == 'n/a' ||
        valLower == 'null' ||
        valLower == 'none' ||
        valLower == 'not provided' ||
        valLower == 'no email provided' ||
        valLower == 'empty cell') {
      return '';
    }
    
    return valStr;
  }

  /// Read an Excel sheet and map columns case-insensitively to standard fields.
  Future<List<Map<String, dynamic>>> readExcelFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw FileNotFoundError("Excel database file not found at path: $filePath");
    }

    final rawBytes = await file.readAsBytes();
    
    List<int> sanitizedBytes;
    try {
      print("[ExcelService] Starting zip/xml sanitization...");
      sanitizedBytes = _sanitizeExcelBytes(rawBytes);
      print("[ExcelService] Sanitization finished successfully. Sanitized size: ${sanitizedBytes.length} bytes");
    } catch (e, s) {
      print("[ExcelService] Error during sanitization: $e\n$s");
      sanitizedBytes = rawBytes;
    }

    Excel excel;
    try {
      print("[ExcelService] Running Excel.decodeBytes...");
      excel = Excel.decodeBytes(sanitizedBytes);
      print("[ExcelService] Excel.decodeBytes decoded successfully.");
    } catch (e, s) {
      print("[ExcelService] FATAL: Excel.decodeBytes crashed! Error: $e\n$s");
      rethrow;
    }

    if (excel.tables.isEmpty) {
      throw Exception("No sheets found in the selected Excel workbook.");
    }

    // Default to the first sheet
    final String sheetName = excel.tables.keys.first;
    final Sheet sheet = excel.tables[sheetName]!;
    print("[ExcelService] Selected sheet: '$sheetName', maxRows: ${sheet.maxRows}");

    if (sheet.maxRows <= 0 || sheet.rows.isEmpty) {
      print("[ExcelService] Sheet has no rows, returning empty list.");
      return [];
    }

    // Parse Header Row
    final List<String> headers = [];
    final List<Data?> headerRow = sheet.rows.first;
    
    for (var cell in headerRow) {
      headers.add(cell?.value?.toString() ?? '');
    }
    print("[ExcelService] Parsed headers: $headers");

    // Map column index to standard field schema
    final Map<int, String> colIndexToStandardField = {};
    for (int i = 0; i < headers.length; i++) {
      final stdField = _mapHeaderToStandardField(headers[i]);
      if (stdField != null) {
        colIndexToStandardField[i] = stdField;
      }
    }
    print("[ExcelService] Column mapping: $colIndexToStandardField");

    final List<Map<String, dynamic>> leads = [];

    // Parse Data Rows
    try {
      print("[ExcelService] Parsing data rows...");
      for (int r = 1; r < sheet.maxRows; r++) {
        final List<Data?> row = sheet.rows[r];

        // Verify row is not completely empty
        bool isRowEmpty = true;
        for (var cell in row) {
          if (cell?.value != null && cell!.value.toString().trim().isNotEmpty) {
            isRowEmpty = false;
            break;
          }
        }
        if (isRowEmpty) {
          continue;
        }

        // Base schema
        final Map<String, dynamic> leadMap = {
          'id': r - 1,
          'Recruiter': '',
          'Company': '',
          'Role': '',
          'Email': '',
          'Mobile': '',
          'LinkedIn Name': '',
          'Alternative Contacts': '',
          'Email Body': '',
          'Whatsapp Body': '',
          'LinkedIn Body': '',
          'Resume Link': '',
          'Status': 'Ready',
          'Reason': ''
        };

        for (int c = 0; c < row.length; c++) {
          final cell = row[c];
          final stdField = colIndexToStandardField[c];
          if (stdField != null) {
            if (cell != null && cell.value != null) {
              try {
                final cleanedValue = _cleanCellValue(cell.value);
                leadMap[stdField] = cleanedValue;
              } catch (e, s) {
                print("[ExcelService] Error cleaning cell at Row $r, Col $c: $e\n$s");
                leadMap[stdField] = cell.value.toString().trim();
              }
            }
          }
        }

        // Regex clean and extract Company & Recruiter
        String companyVal = leadMap['Company'] ?? '';
        String recruiterVal = leadMap['Recruiter'] ?? '';

        try {
          // If fields contain URLs/links, clean them to "N/A"
          if (_isLink(companyVal)) {
            leadMap['Company'] = 'N/A';
            companyVal = 'N/A';
          }
          if (_isLink(recruiterVal)) {
            leadMap['Recruiter'] = 'N/A';
            recruiterVal = 'N/A';
          }

          // Check if Company contains parentheses like "Recruiter (Company Name)"
          if (companyVal.contains('(') && companyVal.contains(')')) {
            final regExp = RegExp(r'^([^\(]+)\((.+)\)$');
            final match = regExp.firstMatch(companyVal);
            if (match != null) {
              final extractedRecruiter = match.group(1)!.trim();
              final extractedCompany = match.group(2)!.trim();
              
              leadMap['Company'] = extractedCompany;
              if (recruiterVal.isEmpty || recruiterVal == 'N/A') {
                leadMap['Recruiter'] = extractedRecruiter;
                recruiterVal = extractedRecruiter;
              }
            }
          }

          // Clean Recruiter name if it contains parentheses like "Recruiter (Title/Role)"
          if (recruiterVal.contains('(') && recruiterVal.contains(')')) {
            final regExp = RegExp(r'^([^\(]+)\((.+)\)$');
            final match = regExp.firstMatch(recruiterVal);
            if (match != null) {
              final cleanedRecruiter = match.group(1)!.trim();
              leadMap['Recruiter'] = cleanedRecruiter;
              recruiterVal = cleanedRecruiter;
            }
          }

          // Double check after parsing parentheticals to clean any extracted URLs/links
          if (_isLink(leadMap['Company'])) leadMap['Company'] = 'N/A';
          if (_isLink(leadMap['Recruiter'])) leadMap['Recruiter'] = 'N/A';
        } catch (e, s) {
          print("[ExcelService] Error matching parentheticals at Row $r: $e\n$s");
        }

        leads.add(leadMap);
      }
      print("[ExcelService] Parsing completed. Loaded ${leads.length} rows.");
    } catch (e, s) {
      print("[ExcelService] Fatal error while parsing rows: $e\n$s");
      rethrow;
    }

    return leads;
  }

  /// Write campaign results to an output report spreadsheet.
  Future<String> exportReport({
    required List<Map<String, dynamic>> leads,
    required String outputPath,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Headers
    final List<String> headers = ['Company', 'Recruiter', 'Email', 'Status', 'Reason', 'Time'];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    final defaultTimestamp = DateTime.now().toLocal().toString().substring(0, 19);

    for (var lead in leads) {
      final row = [
        lead['Company'] ?? '',
        lead['Recruiter'] ?? '',
        lead['Email'] ?? '',
        lead['Status'] ?? '',
        lead['Reason'] ?? '',
        lead['timestamp'] ?? defaultTimestamp,
      ];
      sheet.appendRow(row.map((val) => TextCellValue(val.toString())).toList());
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(outputPath);
      await file.create(recursive: true);
      await file.writeAsBytes(fileBytes);
      return outputPath;
    } else {
      throw Exception("Could not generate Excel report bytes.");
    }
  }

  /// Write invalid and failed campaign leads to a spreadsheet for correction & re-upload.
  Future<String> exportInvalidFailedLeads({
    required List<Map<String, dynamic>> leads,
    required String outputPath,
  }) async {
    final excel = Excel.createExcel();
    final sheet = excel['Sheet1'];

    // Original Excel columns to be corrected, plus helpful details at the end
    final List<String> headers = [
      'Recruiter',
      'Company',
      'Role',
      'Email',
      'Mobile',
      'LinkedIn Name',
      'Alternative Contacts',
      'Email Body',
      'Whatsapp Body',
      'LinkedIn Body',
      'Resume Link',
      'Original Status',
      'Failure Reason'
    ];
    sheet.appendRow(headers.map((h) => TextCellValue(h)).toList());

    for (var lead in leads) {
      final status = lead['Status'] ?? '';
      if (status == 'Invalid' || status == 'Failed') {
        final row = [
          lead['Recruiter'] ?? '',
          lead['Company'] ?? '',
          lead['Role'] ?? '',
          lead['Email'] ?? '',
          lead['Mobile'] ?? '',
          lead['LinkedIn Name'] ?? '',
          lead['Alternative Contacts'] ?? '',
          lead['Email Body'] ?? lead['EmailBody'] ?? '',
          lead['Whatsapp Body'] ?? lead['WhatsappBody'] ?? '',
          lead['LinkedIn Body'] ?? lead['LinkedInBody'] ?? '',
          lead['Resume Link'] ?? '',
          status,
          lead['Reason'] ?? '',
        ];
        sheet.appendRow(row.map((val) => TextCellValue(val.toString())).toList());
      }
    }

    final fileBytes = excel.save();
    if (fileBytes != null) {
      final file = File(outputPath);
      await file.create(recursive: true);
      await file.writeAsBytes(fileBytes);
      return outputPath;
    } else {
      throw Exception("Could not generate Excel report bytes.");
    }
  }

  String? _mapHeaderToStandardField(String header) {
    final hLower = header.toLowerCase().trim();
    if (hLower.contains('alternative')) {
      return 'Alternative Contacts';
    }
    if (hLower == 'recruiter' ||
        hLower.contains('recruiter name') ||
        hLower.contains('contact')) {
      return 'Recruiter';
    }
    if (hLower.contains('company')) return 'Company';
    if (hLower.contains('role') || hLower.contains('job title') || hLower == 'job') return 'Role';
    if (hLower.contains('email') && (hLower.contains('body') || hLower.contains('message'))) {
      return 'Email Body';
    }
    if (hLower.contains('email')) return 'Email';
    if (hLower.contains('mobile') || hLower.contains('phone')) return 'Mobile';
    if (hLower.contains('linkedin') && (hLower.contains('body') || hLower.contains('message'))) {
      return 'LinkedIn Body';
    }
    if (hLower.contains('linkedin')) return 'LinkedIn Name';
    if (hLower.contains('whatsapp')) return 'Whatsapp Body';
    if (hLower.contains('resume')) return 'Resume Link';
    return null;
  }

  bool _isLink(String val) {
    final lower = val.toLowerCase().trim();
    return lower.startsWith('http') ||
        lower.contains('www.') ||
        lower.contains('.com') ||
        lower.contains('.org') ||
        lower.contains('.net') ||
        lower.contains('/');
  }
}

class FileNotFoundError implements Exception {
  final String message;
  FileNotFoundError(this.message);
  @override
  String toString() => message;
}
