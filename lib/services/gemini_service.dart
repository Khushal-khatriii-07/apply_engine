import 'dart:convert';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;

class GeminiMatchResult {
  final int matchScore;
  final List<String> matchReasons;
  final List<String> missingSkills;
  final String customColdPitch;
  final String error;

  GeminiMatchResult({
    required this.matchScore,
    required this.matchReasons,
    required this.missingSkills,
    required this.customColdPitch,
    this.error = '',
  });

  factory GeminiMatchResult.fromMap(Map<String, dynamic> map) {
    return GeminiMatchResult(
      matchScore: (map['match_score'] is num) ? (map['match_score'] as num).round() : 0,
      matchReasons: (map['match_reasons'] is List)
          ? List<String>.from((map['match_reasons'] as List).map((e) => e.toString()))
          : [],
      missingSkills: (map['missing_skills'] is List)
          ? List<String>.from((map['missing_skills'] as List).map((e) => e.toString()))
          : [],
      customColdPitch: map['custom_cold_pitch']?.toString() ?? '',
      error: '',
    );
  }

  factory GeminiMatchResult.withError(String message) {
    return GeminiMatchResult(
      matchScore: 0,
      matchReasons: [],
      missingSkills: [],
      customColdPitch: '',
      error: message,
    );
  }
}

class GeminiExtractedLead {
  final String recruiter;
  final String company;
  final String role;
  final String email;
  final String mobile;
  final String linkedinUrl;
  final String applyUrl;
  final String jdSummary;
  final int matchScore;
  final List<String> matchReasons;
  final List<String> missingSkills;
  final String customColdPitch;

  GeminiExtractedLead({
    required this.recruiter,
    required this.company,
    required this.role,
    required this.email,
    required this.mobile,
    required this.linkedinUrl,
    required this.applyUrl,
    required this.jdSummary,
    required this.matchScore,
    required this.matchReasons,
    required this.missingSkills,
    required this.customColdPitch,
  });

  factory GeminiExtractedLead.fromMap(Map<String, dynamic> map) {
    return GeminiExtractedLead(
      recruiter: map['recruiter']?.toString() ?? '',
      company: map['company']?.toString() ?? '',
      role: map['role']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      mobile: map['mobile']?.toString() ?? '',
      linkedinUrl: map['linkedin_url']?.toString() ?? '',
      applyUrl: map['apply_url']?.toString() ?? '',
      jdSummary: map['jd_summary']?.toString() ?? '',
      matchScore: (map['match_score'] is num) ? (map['match_score'] as num).round() : 0,
      matchReasons: (map['match_reasons'] is List)
          ? List<String>.from((map['match_reasons'] as List).map((e) => e.toString()))
          : [],
      missingSkills: (map['missing_skills'] is List)
          ? List<String>.from((map['missing_skills'] as List).map((e) => e.toString()))
          : [],
      customColdPitch: map['custom_cold_pitch']?.toString() ?? '',
    );
  }
}

class GeminiService extends GetxService {
  // Default to Gemini 1.5 Pro (or gemini-2.0-flash / gemini-2.5-pro)
  String modelName = 'gemini-1.5-pro';

  /// Validates if an API Key is working
  Future<bool> validateApiKey(String apiKey) async {
    if (apiKey.trim().isEmpty) return false;
    try {
      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=${apiKey.trim()}',
      );
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": "Respond with the word OK in JSON: {\"status\": \"OK\"}"}
              ]
            }
          ],
          "generationConfig": {"responseMimeType": "application/json"}
        }),
      );
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  /// Evaluates resume against a single Job Description using Gemini Advanced Reasoning
  Future<GeminiMatchResult> matchResumeWithJob({
    required String apiKey,
    required String resumeText,
    required String jobDescription,
    required String role,
    required String company,
  }) async {
    if (apiKey.trim().isEmpty) {
      return GeminiMatchResult.withError("Gemini API key is missing. Set it in Outreach Config.");
    }

    if (resumeText.trim().isEmpty) {
      return GeminiMatchResult.withError("Resume is empty. Please select a resume PDF first.");
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=${apiKey.trim()}',
    );

    final systemPrompt = '''
You are an expert AI Technical Recruiter with deep reasoning capabilities.
Your task is to thoroughly analyze the candidate's Resume against the given Job Opportunity and provide an objective Match Score and tailored cold outreach message.

TARGET SCHEMA (JSON only, no markdown wrapper):
{
  "match_score": <integer from 0 to 100 based on realistic technical alignment and experience level>,
  "match_reasons": ["<point 1 explaining why they match>", "<point 2>"],
  "missing_skills": ["<skill 1 from JD not clearly visible in resume>", "<skill 2>"],
  "custom_cold_pitch": "<a high-converting 3-sentence personalized cold outreach message (under 300 chars for LinkedIn or 2 paragraphs for Email) highlighting their strongest matching skill and enthusiasm for $company>"
}

EVALUATION RULES:
1. Be realistic and precise. High scores (>= 75%) must have strong tech stack overlap.
2. Keep custom_cold_pitch professional, punchy, and confident without generic buzzwords.
3. If recruiter name is unknown, use generic greetings.
''';

    final userContent = '''
ROLE: $role
COMPANY: $company
JOB DESCRIPTION / POST CONTENT:
$jobDescription

---
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
                {"text": "$systemPrompt\n\n$userContent"}
              ]
            }
          ],
          "generationConfig": {
            "temperature": 0.2,
            "responseMimeType": "application/json",
          }
        }),
      );

      if (response.statusCode != 200) {
        return GeminiMatchResult.withError("Gemini API Error (${response.statusCode}): ${response.body}");
      }

      final jsonResp = jsonDecode(response.body);
      final candidates = jsonResp['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) {
        return GeminiMatchResult.withError("Gemini returned empty candidate response.");
      }

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) {
        return GeminiMatchResult.withError("Empty text parts in Gemini response.");
      }

      final rawText = parts[0]['text']?.toString().trim() ?? '';
      final parsedMap = _cleanAndParseJson(rawText);

      return GeminiMatchResult.fromMap(parsedMap);
    } catch (e) {
      return GeminiMatchResult.withError("Failed communicating with Gemini Pro: $e");
    }
  }

  /// Extracts structured leads from unstructured post texts or search result dumps.
  Future<List<GeminiExtractedLead>> extractLeadsFromUnstructuredText({
    required String apiKey,
    required String rawDumpText,
    required String resumeText,
  }) async {
    if (apiKey.trim().isEmpty || rawDumpText.trim().isEmpty) {
      return [];
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$modelName:generateContent?key=${apiKey.trim()}',
    );

    final prompt = '''
You are an advanced AI Recruitment Intelligence Agent.
Extract all hiring opportunities and recruiter details from the raw text feed below.
For EACH opportunity found, analyze it against the candidate's resume and calculate the match score (0-100) and tailored cold outreach pitch.

OUTPUT FORMAT:
Return a JSON array of objects:
[
  {
    "recruiter": "<Recruiter/Hiring Manager Name, or 'Hiring Team' if not found>",
    "company": "<Company Name>",
    "role": "<Job Role, e.g. Flutter Developer>",
    "email": "<Extracted email or empty string>",
    "mobile": "<Extracted phone/whatsapp or empty string>",
    "linkedin_url": "<Profile or Post URL or empty string>",
    "apply_url": "<Direct application URL or empty string>",
    "jd_summary": "<Brief 1-line JD summary>",
    "match_score": <Integer 0-100>,
    "match_reasons": ["<reason 1>", "<reason 2>"],
    "missing_skills": ["<missing skill 1>"],
    "custom_cold_pitch": "<Tailored personalized pitch for this lead>"
  }
]

RAW TEXT FEED:
$rawDumpText

---
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
            "temperature": 0.2,
            "responseMimeType": "application/json",
          }
        }),
      );

      if (response.statusCode != 200) {
        print("[GeminiService] Error extracting leads: ${response.statusCode} - ${response.body}");
        return [];
      }

      final jsonResp = jsonDecode(response.body);
      final candidates = jsonResp['candidates'] as List?;
      if (candidates == null || candidates.isEmpty) return [];

      final content = candidates[0]['content'];
      final parts = content['parts'] as List?;
      if (parts == null || parts.isEmpty) return [];

      final rawText = parts[0]['text']?.toString().trim() ?? '';
      final parsed = _cleanAndParseJson(rawText);

      if (parsed is List) {
        return parsed.map((e) => GeminiExtractedLead.fromMap(Map<String, dynamic>.from(e))).toList();
      } else if (parsed is Map && parsed.containsKey('leads')) {
        final list = parsed['leads'] as List;
        return list.map((e) => GeminiExtractedLead.fromMap(Map<String, dynamic>.from(e))).toList();
      }

      return [];
    } catch (e) {
      print("[GeminiService] Error in extractLeadsFromUnstructuredText: $e");
      return [];
    }
  }

  dynamic _cleanAndParseJson(String raw) {
    var cleaned = raw.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    cleaned = cleaned.trim();
    return jsonDecode(cleaned);
  }
}

