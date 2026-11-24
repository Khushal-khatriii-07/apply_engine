import 'package:flutter_test/flutter_test.dart';
import 'package:applyengine/models/lead_model.dart';
import 'package:applyengine/services/gemini_service.dart';

void main() {
  group('Gemini Pro Models & Results Tests', () {
    test('GeminiMatchResult correctly parses JSON output from Gemini Pro', () {
      final jsonMap = {
        "match_score": 88,
        "match_reasons": [
          "2+ years Flutter experience matches mid-level requirements",
          "Deep state management knowledge with BLoC and Riverpod"
        ],
        "missing_skills": ["Fastlane CI/CD"],
        "custom_cold_pitch": "Hi Sarah, I noticed your opening for Flutter Developer at Swiggy. With 2 years of production Flutter experience..."
      };

      final result = GeminiMatchResult.fromMap(jsonMap);

      expect(result.matchScore, 88);
      expect(result.matchReasons.length, 2);
      expect(result.missingSkills.length, 1);
      expect(result.missingSkills.first, "Fastlane CI/CD");
      expect(result.customColdPitch.contains("Swiggy"), true);
      expect(result.error, '');
    });

    test('GeminiExtractedLead parses lead list from unstructured dump', () {
      final leadMap = {
        "recruiter": "Aman Sharma",
        "company": "Razorpay",
        "role": "Senior Flutter Developer",
        "email": "aman@razorpay.com",
        "mobile": "9876543210",
        "linkedin_url": "https://linkedin.com/in/amansharma",
        "apply_url": "https://razorpay.com/careers/123",
        "jd_summary": "Looking for Flutter dev with payment SDK integration experience",
        "match_score": 82,
        "match_reasons": ["Solid Dart architecture"],
        "missing_skills": [],
        "custom_cold_pitch": "Hi Aman, regarding your Senior Flutter role at Razorpay..."
      };

      final lead = GeminiExtractedLead.fromMap(leadMap);

      expect(lead.recruiter, "Aman Sharma");
      expect(lead.company, "Razorpay");
      expect(lead.email, "aman@razorpay.com");
      expect(lead.matchScore, 82);
    });

    test('LeadModel preserves matchScore, customPitch, and JSON serialization', () {
      final lead = LeadModel(
        id: 1,
        recruiter: "John Doe",
        company: "Tech Corp",
        role: "Flutter Engineer",
        email: "john@techcorp.com",
        mobile: "919999999999",
        linkedinName: "john-doe",
        emailBody: "Job description text",
        whatsappBody: "",
        linkedinBody: "",
        resumeLink: "",
        status: "Ready",
        reason: "",
        matchScore: 92,
        matchReasons: ["Skills matched 92%"],
        missingSkills: ["Kubernetes"],
        customPitch: "Hi John, I am a great fit for Tech Corp.",
        applyUrl: "https://techcorp.com/jobs/1",
        source: "LinkedIn",
      );

      final json = lead.toJson();
      expect(json['matchScore'], 92);
      expect(json['customPitch'], "Hi John, I am a great fit for Tech Corp.");
      expect(json['source'], "LinkedIn");

      final reconstructed = LeadModel.fromJson(json);
      expect(reconstructed.matchScore, 92);
      expect(reconstructed.customPitch, "Hi John, I am a great fit for Tech Corp.");
      expect(reconstructed.missingSkills.first, "Kubernetes");
    });
  });
}

