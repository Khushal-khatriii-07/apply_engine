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
  });

  factory LeadModel.fromJson(Map<String, dynamic> json) {
    return LeadModel(
      id: json['id'] ?? 0,
      recruiter: json['Recruiter'] ?? '',
      company: json['Company'] ?? '',
      role: json['Role'] ?? '',
      email: json['Email'] ?? '',
      mobile: json['Mobile'] ?? '',
      linkedinName: json['LinkedIn Name'] ?? '',
      emailBody: json['Email Body'] ?? '',
      whatsappBody: json['Whatsapp Body'] ?? '',
      linkedinBody: json['LinkedIn Body'] ?? '',
      resumeLink: json['Resume Link'] ?? '',
      status: json['Status'] ?? 'Ready',
      reason: json['Reason'] ?? '',
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
    };
  }
}
