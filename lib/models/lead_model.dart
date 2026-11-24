class LeadModel {
  final int id;
  final String recruiter;
  final String company;
  final String role;
  final String email;
  final String mobile;
  final String linkedinName;
  final String emailBody;
  final String whatsappBody;
  final String linkedinBody;
  final String resumeLink;
  String status; // Ready, Sending, Sent, Failed, Invalid, Skipped, Duplicate
  String reason;
  
  // AI Pro Matching Fields
  int matchScore; // 0 to 100
  List<String> matchReasons;
  List<String> missingSkills;
  String customPitch;
  String applyUrl;
  String source; // 'LinkedIn', 'Naukri', 'Indeed', 'Excel'

  LeadModel({
    required this.id,
    required this.recruiter,
    required this.company,
    required this.role,
    required this.email,
    required this.mobile,
    required this.linkedinName,
    required this.emailBody,
    required this.whatsappBody,
    required this.linkedinBody,
    required this.resumeLink,
    required this.status,
    required this.reason,
    this.matchScore = 0,
    this.matchReasons = const [],
    this.missingSkills = const [],
    this.customPitch = '',
    this.applyUrl = '',
    this.source = 'Excel',
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] ?? 0,
      recruiter: json['Recruiter'] ?? json['recruiter'] ?? '',
      company: json['Company'] ?? json['company'] ?? '',
      role: json['Role'] ?? json['role'] ?? '',
      email: json['Email'] ?? json['email'] ?? '',
      mobile: json['Mobile'] ?? json['mobile'] ?? '',
      linkedinName: json['LinkedIn Name'] ?? json['linkedin_url'] ?? '',
      emailBody: json['Email Body'] ?? json['EmailBody'] ?? '',
      whatsappBody: json['Whatsapp Body'] ?? json['WhatsappBody'] ?? '',
      linkedinBody: json['LinkedIn Body'] ?? json['LinkedInBody'] ?? '',
      resumeLink: json['Resume Link'] ?? json['resumeLink'] ?? '',
      status: json['Status'] ?? json['status'] ?? 'Ready',
      reason: json['Reason'] ?? json['reason'] ?? '',
      matchScore: (json['matchScore'] ?? json['match_score'] ?? 0) is num
          ? (json['matchScore'] ?? json['match_score'] as num).round()
          : 0,
      matchReasons: (json['matchReasons'] is List || json['match_reasons'] is List)
          ? List<String>.from(((json['matchReasons'] ?? json['match_reasons']) as List).map((e) => e.toString()))
          : const [],
      missingSkills: (json['missingSkills'] is List || json['missing_skills'] is List)
          ? List<String>.from(((json['missingSkills'] ?? json['missing_skills']) as List).map((e) => e.toString()))
          : const [],
      customPitch: json['customPitch'] ?? json['custom_cold_pitch'] ?? '',
      applyUrl: json['applyUrl'] ?? json['apply_url'] ?? '',
      source: json['source'] ?? 'Excel',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'Recruiter': recruiter,
      'Company': company,
      'Role': role,
      'Email': email,
      'Mobile': mobile,
      'LinkedIn Name': linkedinName,
      'Email Body': emailBody,
      'Whatsapp Body': whatsappBody,
      'LinkedIn Body': linkedinBody,
      'Resume Link': resumeLink,
      'Status': status,
      'Reason': reason,
      'matchScore': matchScore,
      'matchReasons': matchReasons,
      'missingSkills': missingSkills,
      'customPitch': customPitch,
      'applyUrl': applyUrl,
      'source': source,
    };
  }
}
