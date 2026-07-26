import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';
import 'package:applyengine/models/lead_model.dart';
import 'package:applyengine/services/excel_service.dart';
import 'package:applyengine/services/validation_service.dart';
import 'package:applyengine/services/smtp_mailer_service.dart';

class MailController extends GetxController with WidgetsBindingObserver {
  final ExcelService _excelService = Get.find<ExcelService>();
  final ValidationService _validationService = Get.find<ValidationService>();
  final SmtpMailerService _mailerService = Get.find<SmtpMailerService>();
  final _storage = GetStorage();

  static const _whatsappChannel = MethodChannel('com.applyengine/whatsapp_automator');

  // Observable Settings Fields
  final senderEmail = ''.obs;
  final appPassword = ''.obs;
  final senderName = 'ApplyEngine'.obs;
  final subject = ''.obs;
  final delay = 2.0.obs;
  final threads = 1.obs;
  final maxEmails = 1000.obs;
  final excelPath = ''.obs;
  final resumePath = ''.obs;
  final removeDuplicates = true.obs;
  final detectDuplicateRecruiter = true.obs;
  final campaignHistory = <Map<String, dynamic>>[].obs;
  final whatsappHistory = <Map<String, dynamic>>[].obs;
  final linkedinHistory = <Map<String, dynamic>>[].obs;
  
  // WhatsApp & LinkedIn Fields
  final campaignType = 'Email'.obs; // 'Email', 'WhatsApp' or 'LinkedIn'
  final whatsappBody = ''.obs;
  final linkedinBody = ''.obs;
  final isAccessibilityActive = false.obs;
  final testMobile = ''.obs;
  final testLinkedinProfile = ''.obs;
  bool _isTestingWhatsApp = false;
  bool _isTestingWhatsAppPdf = false;
  bool _isTestingLinkedIn = false;


  // Execution States
  final leads = <LeadModel>[].obs;
  final logs = <String>[].obs;
  final isProcessing = false.obs;
  final isPaused = false.obs;
  final isExcelLoading = false.obs;
  final isTestingEmail = false.obs;

  // Search, Filter, Sort State
  final searchQuery = ''.obs;
  final statusFilter = 'All'.obs;
  final sortColumn = 'Company'.obs;
  final onlyWithMobile = false.obs;
  final sortAscending = true.obs;

  // ETR & Metrics
  final currentRecruiter = ''.obs;
  final currentCompany = ''.obs;
  final currentEmail = ''.obs;
  final currentStatus = ''.obs;
  final emailsPerMinute = 0.0.obs;
  final estimatedTimeRemaining = '00:00'.obs;

  // Statistical Counts
  final totalCount = 0.obs;
  final readyCount = 0.obs;
  final sentCount = 0.obs;
  final failedCount = 0.obs;
  final invalidCount = 0.obs;
  final skippedCount = 0.obs;
  final duplicateCount = 0.obs;

  // Stream Subscription & Timer
  StreamSubscription<Map<String, dynamic>>? _mailerEventSub;
  Timer? _metricsTimer;
  DateTime? _sendingStartTime;
  int _initialSentCount = 0;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    _loadSettings();
    _subscribeToMailerEvents();
    _setupAutoSave();
    checkAccessibilityPermission();
    
    // Auto re-validate when toggling campaign mode
    ever(campaignType, (_) => revalidateLeads());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _mailerEventSub?.cancel();
    _metricsTimer?.cancel();
    super.onClose();
  }

  void _loadCampaignHistory() {
    final List<dynamic> rawEmail = _storage.read('sent_history') ?? [];
    campaignHistory.value = rawEmail.map((item) => Map<String, dynamic>.from(item)).toList();
    
    final List<dynamic> rawWhatsapp = _storage.read('whatsapp_sent_history') ?? [];
    whatsappHistory.value = rawWhatsapp.map((item) => Map<String, dynamic>.from(item)).toList();
    
    final List<dynamic> rawLinkedin = _storage.read('linkedin_sent_history') ?? [];
    linkedinHistory.value = rawLinkedin.map((item) => Map<String, dynamic>.from(item)).toList();
  }

  void _loadSettings() {
    senderEmail.value = _storage.read('senderEmail') ?? '';
    appPassword.value = _storage.read('appPassword') ?? '';
    senderName.value = _storage.read('senderName') ?? 'ApplyEngine';
    subject.value = _storage.read('subject') ?? 'Application for Flutter Developer';
    if (subject.value == 'Application for Job Position' || subject.value.isEmpty) {
      subject.value = 'Application for Flutter Developer';
    }
    delay.value = _storage.read('delay') ?? 2.0;
    threads.value = _storage.read('threads') ?? 1;
    maxEmails.value = _storage.read('maxEmails') ?? 1000;
    excelPath.value = _storage.read('excelPath') ?? '';
    resumePath.value = _storage.read('resumePath') ?? '';
    removeDuplicates.value = _storage.read('removeDuplicates') ?? true;
    detectDuplicateRecruiter.value = _storage.read('detectDuplicateRecruiter') ?? true;
    campaignType.value = _storage.read('campaignType') ?? 'Email';
    whatsappBody.value = _storage.read('whatsappBody') ?? 'Hi {Recruiter}, I noticed your post for {Role} at {Company}. Would love to connect and share my resume.';
    linkedinBody.value = _storage.read('linkedinBody') ?? 'Hi {Recruiter}, I noticed your post for {Role} at {Company}. Would love to connect!';
    testMobile.value = _storage.read('testMobile') ?? '';
    testLinkedinProfile.value = _storage.read('testLinkedinProfile') ?? '';
    _loadCampaignHistory();

    // Auto load last Excel if file exists
    if (excelPath.value.isNotEmpty && File(excelPath.value).existsSync()) {
      loadExcel();
    }
  }

  void _setupAutoSave() {
    ever(senderEmail, (val) => _storage.write('senderEmail', val));
    ever(appPassword, (val) => _storage.write('appPassword', val));
    ever(senderName, (val) => _storage.write('senderName', val));
    ever(subject, (val) => _storage.write('subject', val));
    ever(delay, (val) => _storage.write('delay', val));
    ever(threads, (val) => _storage.write('threads', val));
    ever(maxEmails, (val) => _storage.write('maxEmails', val));
    ever(excelPath, (val) => _storage.write('excelPath', val));
    ever(resumePath, (val) => _storage.write('resumePath', val));
    ever(removeDuplicates, (val) => _storage.write('removeDuplicates', val));
    ever(detectDuplicateRecruiter, (val) => _storage.write('detectDuplicateRecruiter', val));
    ever(campaignType, (val) => _storage.write('campaignType', val));
    ever(whatsappBody, (val) => _storage.write('whatsappBody', val));
    ever(linkedinBody, (val) => _storage.write('linkedinBody', val));
    ever(testMobile, (val) => _storage.write('testMobile', val));
    ever(testLinkedinProfile, (val) => _storage.write('testLinkedinProfile', val));
  }

  void _subscribeToMailerEvents() {
    _mailerEventSub = _mailerService.eventStream.listen((event) {
      final String eventName = event['event'] ?? '';

      switch (eventName) {
        case 'lead_status_update':
          final int id = event['id'] ?? -1;
          final String status = event['status'] ?? '';
          final String reason = event['reason'] ?? '';
          _updateLeadStatus(id, status, reason);
          break;

        case 'send_progress':
          final int id = event['id'] ?? -1;
          final String status = event['status'] ?? '';
          final String reason = event['reason'] ?? '';
          final String logMsg = event['log'] ?? '';

          _updateLeadStatus(id, status, reason);

          if (logMsg.isNotEmpty) {
            addLog(logMsg);
          }

          // Update details for current progress card
          final lead = leads.firstWhereOrNull((l) => l.id == id);
          if (lead != null) {
            currentRecruiter.value = lead.recruiter;
            currentCompany.value = lead.company;
            currentEmail.value = lead.email;
            currentStatus.value = status;

            if (status == 'Sent') {
              _recordEmailSentHistory(lead);
            }
          }

          _updateCounts();
          break;

        case 'sending_completed':
          isProcessing.value = false;
          isPaused.value = false;
          _metricsTimer?.cancel();
          addLog("Campaign sending complete.");
          Get.snackbar(
            "Campaign Finished",
            "ApplyEngine campaign sending session completed.",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Get.theme.colorScheme.primaryContainer,
            colorText: Get.theme.colorScheme.onPrimaryContainer,
          );
          break;

        case 'status_paused':
          isPaused.value = true;
          addLog("Campaign paused.");
          break;

        case 'status_resumed':
          isPaused.value = false;
          _sendingStartTime = DateTime.now();
          _initialSentCount = sentCount.value;
          addLog("Campaign resumed.");
          break;

        case 'status_stopped':
          isProcessing.value = false;
          isPaused.value = false;
          _metricsTimer?.cancel();
          addLog("Campaign stopped.");
          break;

        case 'test_email_result':
          isTestingEmail.value = false;
          final String status = event['status'] ?? '';
          final String reason = event['reason'] ?? '';
          if (status == 'Sent') {
            addLog("Test email delivered successfully.");
            Get.defaultDialog(
              title: "Test Email Sent",
              middleText: "The test email was successfully delivered to $senderEmail.",
              textConfirm: "OK",
              confirmTextColor: Colors.white,
              onConfirm: () => Get.back(),
            );
          } else {
            addLog("Test email failed: $reason");
            Get.defaultDialog(
              title: "Test Email Failed",
              middleText: "Could not deliver test email:\n$reason",
              textConfirm: "OK",
              confirmTextColor: Colors.white,
              onConfirm: () => Get.back(),
            );
          }
          break;

        case 'log':
          final String msg = event['message'] ?? '';
          final String timestamp = event['timestamp'] ?? '';
          addLog("$timestamp - $msg");
          break;
      }
    });
  }

  void _updateLeadStatus(int id, String status, String reason) {
    final idx = leads.indexWhere((l) => l.id == id);
    if (idx != -1) {
      leads[idx].status = status;
      leads[idx].reason = reason;
      leads.refresh();
    }
  }

  void _updateCounts() {
    totalCount.value = leads.length;
    readyCount.value = leads.where((l) => l.status == 'Ready').length;
    sentCount.value = leads.where((l) => l.status == 'Sent').length;
    failedCount.value = leads.where((l) => l.status == 'Failed').length;
    invalidCount.value = leads.where((l) => l.status == 'Invalid').length;
    skippedCount.value = leads.where((l) => l.status == 'Skipped').length;
    duplicateCount.value = leads.where((l) => l.status == 'Duplicate').length;
  }

  void addLog(String message) {
    final now = DateTime.now();
    final timeStr =
        "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}";
    logs.add("[$timeStr] $message");
    if (logs.length > 500) {
      logs.removeAt(0);
    }
  }

  // --- ACTIONS ---

  Future<void> selectExcel() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result != null && result.files.single.path != null) {
      excelPath.value = result.files.single.path!;
      loadExcel();
    }
  }

  Future<void> loadExcel() async {
    if (excelPath.value.isEmpty) return;
    isExcelLoading.value = true;
    leads.clear();
    addLog("Reading Excel file at: ${excelPath.value}...");
    
    try {
      final rawLeads = await _excelService.readExcelFile(excelPath.value);
      final validatedLeads = await _validationService.validateLeads(
        leads: rawLeads,
        campaignType: campaignType.value,
        removeDuplicates: removeDuplicates.value,
        detectDuplicateRecruiter: detectDuplicateRecruiter.value,
      );
      
      leads.value = validatedLeads.map((json) => LeadModel.fromJson(json)).toList();
      _updateCounts();
      addLog("Successfully parsed and validated ${leads.length} rows.");
    } catch (e) {
      addLog("Excel Loader Error: $e");
      Get.snackbar(
        "Excel Read Error",
        e.toString(),
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.errorContainer,
        colorText: Get.theme.colorScheme.onErrorContainer,
      );
    } finally {
      isExcelLoading.value = false;
    }
  }

  Future<void> revalidateLeads() async {
    if (excelPath.value.isEmpty) return;
    addLog("Re-validating database for campaign mode: ${campaignType.value}...");
    try {
      final rawLeads = await _excelService.readExcelFile(excelPath.value);
      final validatedLeads = await _validationService.validateLeads(
        leads: rawLeads,
        campaignType: campaignType.value,
        removeDuplicates: removeDuplicates.value,
        detectDuplicateRecruiter: detectDuplicateRecruiter.value,
      );
      leads.value = validatedLeads.map((json) => LeadModel.fromJson(json)).toList();
      _updateCounts();
      addLog("Database re-validated. Loaded ${leads.length} rows.");
    } catch (e) {
      addLog("Re-validation Error: $e");
    }
  }

  Future<void> selectResume() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.single.path != null) {
      resumePath.value = result.files.single.path!;
      addLog("Selected resume: ${p.basename(resumePath.value)}");
    }
  }

  void clearExcel() {
    excelPath.value = '';
    leads.clear();
    _updateCounts();
    addLog("Excel database cleared.");
  }

  void sendTestEmail() {
    if (senderEmail.value.isEmpty || appPassword.value.isEmpty) {
      Get.snackbar("Missing Settings", "Provide Gmail address and App Password first.");
      return;
    }
    isTestingEmail.value = true;
    addLog("Sending verification email to: ${senderEmail.value}");
    _mailerService.sendTestEmail(
      senderEmail: senderEmail.value.trim(),
      appPassword: appPassword.value.trim(),
      senderName: senderName.value.trim(),
      resumePath: resumePath.value,
    );
  }

  void sendTwoTestEmailsToSelf() {
    if (senderEmail.value.isEmpty || appPassword.value.isEmpty) {
      Get.snackbar("Credentials Required", "Configure Sender Gmail and App Password first.");
      return;
    }
    if (leads.isEmpty) {
      Get.snackbar("No Leads Loaded", "Please load an Excel sheet with leads first.");
      return;
    }
    if (resumePath.value.isEmpty) {
      Get.snackbar("Resume Required", "Please select a resume PDF in the Setup tab first.");
      return;
    }
    if (!File(resumePath.value).existsSync()) {
      Get.snackbar("File Not Found", "The selected resume PDF file does not exist at path: ${resumePath.value}");
      return;
    }
    isTestingEmail.value = true;
    addLog("Sending 2 test emails using lead templates to self: ${senderEmail.value}");
    addLog("Attaching resume: ${p.basename(resumePath.value)}");
    _mailerService.sendTestCampaignToSelf(
      leads: leads.map((l) => l.toJson()).toList(),
      senderEmail: senderEmail.value.trim(),
      appPassword: appPassword.value.trim(),
      senderName: senderName.value.trim(),
      subjectTemplate: subject.value.trim(),
      resumePath: resumePath.value,
    );
  }

  void startSending() {
    if (campaignType.value == 'WhatsApp') {
      startWhatsAppCampaign();
      return;
    }
    if (campaignType.value == 'LinkedIn') {
      startLinkedInCampaign();
      return;
    }
    if (senderEmail.value.isEmpty || appPassword.value.isEmpty) {
      Get.snackbar("Credentials Required", "Configure Sender Gmail and App Password first.");
      return;
    }
    final readyLeads = leads.where((l) => l.status == 'Ready' || l.status == 'Failed').toList();
    if (readyLeads.isEmpty) {
      Get.snackbar("Campaign Empty", "No campaign leads found in 'Ready' or 'Failed' status.");
      return;
    }

    isProcessing.value = true;
    isPaused.value = false;
    _sendingStartTime = DateTime.now();
    _initialSentCount = sentCount.value;

    _startMetricsTimer();

    _mailerService.startSendingCampaign(
      leads: leads.map((l) => l.toJson()).toList(),
      senderEmail: senderEmail.value.trim(),
      appPassword: appPassword.value.trim(),
      senderName: senderName.value.trim(),
      subjectTemplate: subject.value.trim(),
      delaySeconds: delay.value,
      workerThreads: threads.value,
      limitMaxEmails: maxEmails.value,
      resumePath: resumePath.value,
    );
  }

  void pauseSending() {
    if (campaignType.value == 'WhatsApp') {
      isPaused.value = true;
      addLog("WhatsApp Campaign paused.");
      return;
    }
    _mailerService.pause();
  }

  void resumeSending() {
    if (campaignType.value == 'WhatsApp') {
      isPaused.value = false;
      addLog("WhatsApp Campaign resumed.");
      _sendNextWhatsApp();
      return;
    }
    _mailerService.resume();
  }

  void stopSending() {
    if (campaignType.value == 'WhatsApp') {
      isProcessing.value = false;
      isPaused.value = false;
      _metricsTimer?.cancel();
      addLog("WhatsApp Campaign stopped.");
      setWhatsAppAutoSendActive(false);
      return;
    }
    _mailerService.stop();
  }

  // --- WHATSAPP AUTOMATION METHODS ---

  Future<void> checkAccessibilityPermission() async {
    if (!Platform.isAndroid) {
      isAccessibilityActive.value = true;
      return;
    }
    try {
      final bool enabled = await _whatsappChannel.invokeMethod('isAccessibilityEnabled') ?? false;
      isAccessibilityActive.value = enabled;
    } catch (e) {
      addLog("Failed checking accessibility: $e");
    }
  }

  Future<void> openAccessibilitySettings() async {
    if (!Platform.isAndroid) return;
    try {
      await _whatsappChannel.invokeMethod('openAccessibilitySettings');
    } catch (e) {
      addLog("Failed opening accessibility settings: $e");
    }
  }

  Future<void> setWhatsAppAutoSendActive(bool active) async {
    if (!Platform.isAndroid) return;
    try {
      await _whatsappChannel.invokeMethod('setAutoSendActive', {'active': active});
    } catch (e) {
      addLog("Failed setting accessibility auto-send state: $e");
    }
  }

  Future<void> startWhatsAppCampaign() async {
    if (Platform.isAndroid) {
      await checkAccessibilityPermission();
      if (!isAccessibilityActive.value) {
        Get.defaultDialog(
          title: "Permission Required",
          middleText: "JobPilot requires the 'JobPilot WhatsApp Automator' Accessibility Service to automatically click the send button and navigate back.\n\nPlease enable it in the system settings.",
          textConfirm: "Open Settings",
          textCancel: "Cancel",
          confirmTextColor: Colors.white,
          onConfirm: () {
            Get.back();
            openAccessibilitySettings();
          },
        );
        return;
      }
    }

    final readyLeads = leads.where((l) => l.status == 'Ready' || l.status == 'Failed').toList();
    if (readyLeads.isEmpty) {
      Get.snackbar("Campaign Empty", "No campaign leads found in 'Ready' or 'Failed' status.");
      return;
    }

    isProcessing.value = true;
    isPaused.value = false;
    _sendingStartTime = DateTime.now();
    _initialSentCount = sentCount.value;
    
    _startMetricsTimer();
    addLog("WhatsApp Campaign started.");
    
    if (Platform.isAndroid) {
      try {
        await _whatsappChannel.invokeMethod('setCampaignType', {'type': 'WhatsApp'});
      } catch (e) {
        addLog("Failed setting campaign type to WhatsApp: $e");
      }
      await setWhatsAppAutoSendActive(true);
    }
    
    // Launch the first lead
    _sendNextWhatsApp();
  }

  Future<void> sendTestWhatsApp() async {
    addLog("sendTestWhatsApp: started");
    if (testMobile.value.trim().isEmpty) {
      Get.snackbar("Missing Field", "Please enter a test mobile number first.");
      return;
    }
    if (Platform.isAndroid) {
      await checkAccessibilityPermission();
      if (!isAccessibilityActive.value) {
        addLog("sendTestWhatsApp: cancelled, accessibility service inactive");
        Get.defaultDialog(
          title: "Permission Required",
          middleText: "Please enable the accessibility service first to test the automator.",
          textConfirm: "Open Settings",
          textCancel: "Cancel",
          confirmTextColor: Colors.white,
          onConfirm: () {
            Get.back();
            openAccessibilitySettings();
          },
        );
        return;
      }
      try {
        await _whatsappChannel.invokeMethod('setCampaignType', {'type': 'WhatsApp'});
      } catch (e) {
        addLog("Failed setting campaign type to WhatsApp (test): $e");
      }
      await setWhatsAppAutoSendActive(true);
    }
    
    // Verify file exists if resume is selected
    if (resumePath.value.isNotEmpty) {
      final exists = File(resumePath.value).existsSync();
      addLog("sendTestWhatsApp: checking resume file: exists=$exists, path=${resumePath.value}");
      if (!exists) {
        Get.snackbar(
          "File Not Found",
          "The selected resume PDF no longer exists. Please re-select it in the Setup Tab.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
    } else {
      addLog("sendTestWhatsApp: no resume file selected");
    }
    
    addLog("sendTestWhatsApp: targeting test mobile number: ${testMobile.value}");
    String phone = testMobile.value.replaceAll(RegExp(r'\D'), '');
    if (!phone.startsWith('+') && phone.length <= 10) {
      phone = "91$phone";
    }
    
    const message = "Hello! This is a test message from JobPilot to verify your WhatsApp Automator connection.";
    
    // Setup test state machine
    _isTestingWhatsApp = true;
    _isTestingWhatsAppPdf = resumePath.value.isNotEmpty && File(resumePath.value).existsSync();
    addLog("sendTestWhatsApp: state initialized: _isTestingWhatsApp=true, _isTestingWhatsAppPdf=$_isTestingWhatsAppPdf");

    // Launch Step 1: Text message
    final uri = Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}");
    final webUri = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
    
    try {
      addLog("sendTestWhatsApp: launching prefilled text intent to WhatsApp...");
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        addLog("sendTestWhatsApp: launched via uri successfully");
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        addLog("sendTestWhatsApp: launched via webUri successfully");
      }
    } catch (e) {
      addLog("sendTestWhatsApp error: failed to launch test WhatsApp: $e");
      _isTestingWhatsApp = false;
      _isTestingWhatsAppPdf = false;
    }
  }

  String _personalize(String template, LeadModel lead) {
    String text = template;
    final map = lead.toJson();
    map.forEach((key, value) {
      text = text.replaceAll('{$key}', value.toString());
      text = text.replaceAll('{${key.toLowerCase()}}', value.toString());
    });
    return text;
  }

  Future<void> _sendNextWhatsApp() async {
    addLog("_sendNextWhatsApp: loop triggered");
    if (!isProcessing.value) {
      addLog("_sendNextWhatsApp: processing flag is false, skipping");
      return;
    }
    if (isPaused.value) {
      addLog("_sendNextWhatsApp: paused is true, skipping");
      return;
    }

    var activeLead = leads.firstWhereOrNull((l) => l.status == 'SendingText' || l.status == 'SendingPDF');
    if (activeLead == null) {
      addLog("_sendNextWhatsApp: no active lead in transition, searching for fresh lead...");
      activeLead = leads.firstWhereOrNull((l) => l.status == 'Ready' || l.status == 'Failed');
      if (activeLead == null) {
        addLog("_sendNextWhatsApp: no more leads remaining. Completing campaign.");
        isProcessing.value = false;
        _metricsTimer?.cancel();
        addLog("WhatsApp Campaign sending completed.");
        if (Platform.isAndroid) {
          await setWhatsAppAutoSendActive(false);
        }
        Get.snackbar(
          "WhatsApp Campaign Complete",
          "All leads processed successfully.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      addLog("_sendNextWhatsApp: selected next lead: ${activeLead.recruiter} (${activeLead.company}), setting status to SendingText");
      _updateLeadStatus(activeLead.id, 'SendingText', '');
      _updateCounts();
    } else {
      addLog("_sendNextWhatsApp: active lead in state machine: ${activeLead.recruiter}, current status: ${activeLead.status}");
    }

    currentRecruiter.value = activeLead.recruiter;
    currentCompany.value = activeLead.company;
    currentEmail.value = activeLead.mobile;
    currentStatus.value = activeLead.status == 'SendingText' ? 'Sending Message' : 'Attaching Resume';

    final String messageTemplate = activeLead.whatsappBody.isNotEmpty
        ? activeLead.whatsappBody
        : whatsappBody.value;
    final String message = _personalize(messageTemplate, activeLead);
    String phone = activeLead.mobile.replaceAll(RegExp(r'\D'), '');
    
    if (!phone.startsWith('+') && phone.length <= 10) {
      phone = "91$phone";
    }

    if (activeLead.status == 'SendingText') {
      addLog("Opening WhatsApp chat (Text) for: ${activeLead.recruiter} (${activeLead.company}), phone=$phone");
      final uri = Uri.parse("whatsapp://send?phone=$phone&text=${Uri.encodeComponent(message)}");
      final webUri = Uri.parse("https://wa.me/$phone?text=${Uri.encodeComponent(message)}");
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri);
          addLog("WhatsApp text intent launched for: ${activeLead.recruiter}");
        } else {
          await launchUrl(webUri, mode: LaunchMode.externalApplication);
          addLog("WhatsApp webUri text intent launched for: ${activeLead.recruiter}");
        }
      } catch (e) {
        addLog("Failed to launch WhatsApp text: $e");
        _updateLeadStatus(activeLead.id, 'Failed', 'Text launch error: $e');
        _updateCounts();
        await Future.delayed(Duration(seconds: delay.value.round()));
        _sendNextWhatsApp();
      }
    } else if (activeLead.status == 'SendingPDF') {
      addLog("Attempting PDF share step for: ${activeLead.recruiter} (${activeLead.company})");
      if (resumePath.value.isNotEmpty && Platform.isAndroid) {
        final exists = File(resumePath.value).existsSync();
        addLog("Checking resume file existence: exists=$exists, path=${resumePath.value}");
        if (exists) {
          addLog("Calling shareFileAndTextToWhatsApp method channel for: ${activeLead.recruiter}");
          try {
            final success = await _whatsappChannel.invokeMethod('shareFileAndTextToWhatsApp', {
              'phone': phone,
              'text': '', 
              'filePath': resumePath.value,
            });
            addLog("Method channel shareFileAndTextToWhatsApp invocation result: $success");
            if (success == true) {
              addLog("Method channel success, waiting for accessibility send...");
              return;
            }
          } catch (e) {
            addLog("Failed native PDF sharing method channel call: $e");
          }
        } else {
          addLog("WARNING: Resume PDF file not found at path: ${resumePath.value}");
        }
      } else {
        addLog("PDF send skipped (no resume configured or not Android)");
      }
      
      // Fallback or finish if no PDF/fails
      addLog("Finalizing lead ${activeLead.recruiter} as Sent (no PDF sent or channel failed)");
      _updateLeadStatus(activeLead.id, 'Sent', '');
      _recordWhatsappSentHistory(activeLead);
      _updateCounts();
      await Future.delayed(Duration(seconds: delay.value.round()));
      _sendNextWhatsApp();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (isProcessing.value && (campaignType.value == 'WhatsApp' || campaignType.value == 'LinkedIn')) {
      addLog("didChangeAppLifecycleState: state changed to: $state");
      if (state == AppLifecycleState.resumed) {
        addLog("App resumed from background, processing outreach transitions...");
        _handleAppResumedFromOutreach();
      }
    } else if ((_isTestingWhatsApp || _isTestingLinkedIn) && state == AppLifecycleState.resumed) {
      addLog("didChangeAppLifecycleState (test mode): state changed to: $state");
      _handleAppResumedFromOutreach();
    }
  }

  Future<void> _handleAppResumedFromOutreach() async {
    addLog("_handleAppResumedFromOutreach: triggered. Checking states...");
    
    // A. Check if we are in testing transition
    if (_isTestingWhatsApp) {
      addLog("_handleAppResumedFromOutreach (WhatsApp Test Mode): active. _isTestingWhatsAppPdf=$_isTestingWhatsAppPdf");
      if (_isTestingWhatsAppPdf && resumePath.value.isNotEmpty && Platform.isAndroid) {
        final exists = File(resumePath.value).existsSync();
        addLog("Test PDF Step: checking file existence: exists=$exists, path=${resumePath.value}");
        if (exists) {
          _isTestingWhatsAppPdf = false;
          addLog("Test PDF Step: launching PDF share intent via method channel...");
          String phone = testMobile.value.replaceAll(RegExp(r'\D'), '');
          if (!phone.startsWith('+') && phone.length <= 10) {
            phone = "91$phone";
          }
          try {
            final success = await _whatsappChannel.invokeMethod('shareFileAndTextToWhatsApp', {
              'phone': phone,
              'text': '',
              'filePath': resumePath.value,
            });
            addLog("Test PDF Step: method channel return: $success");
            if (success == true) return;
          } catch (e) {
            addLog("Test PDF Step: failed native sharing during test: $e");
          }
        } else {
          addLog("Test PDF Step WARNING: Resume PDF file not found at: ${resumePath.value}");
        }
      }
      
      addLog("Test run finished. Clearing test state variables.");
      _isTestingWhatsApp = false;
      _isTestingWhatsAppPdf = false;
      addLog("Test WhatsApp message sequence completed.");
      if (Platform.isAndroid) {
        await setWhatsAppAutoSendActive(false);
      }
      Get.snackbar("Test Successful", "Test WhatsApp message sent successfully.", snackPosition: SnackPosition.BOTTOM);
      return;
    }

    if (_isTestingLinkedIn) {
      addLog("Test run finished. Clearing test state variables.");
      _isTestingLinkedIn = false;
      bool success = true;
      if (Platform.isAndroid) {
        try {
          success = await _whatsappChannel.invokeMethod('getLinkedInLastStatus') ?? false;
        } catch (_) {}
      }
      if (Platform.isAndroid) {
        await setLinkedInAutoSendActive(false);
      }
      if (success) {
        Get.snackbar("Test Successful", "Test LinkedIn connection request sent successfully.", snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar("Test Skipped/Failed", "LinkedIn buttons not found or timeout occurred.", snackPosition: SnackPosition.BOTTOM);
      }
      return;
    }

    // B. Campaign transitions based on type
    if (campaignType.value == 'WhatsApp') {
      final textLead = leads.firstWhereOrNull((l) => l.status == 'SendingText');
      if (textLead != null) {
        final exists = resumePath.value.isNotEmpty && File(resumePath.value).existsSync();
        addLog("Campaign Transition: found textLead: ${textLead.recruiter}, hasResume=$exists");
        if (exists) {
          addLog("Campaign Transition: advancing lead status to SendingPDF");
          _updateLeadStatus(textLead.id, 'SendingPDF', '');
          _updateCounts();
          await Future.delayed(const Duration(milliseconds: 800));
          _sendNextWhatsApp();
        } else {
          addLog("Campaign Transition: no PDF configured or missing, finalizing lead as Sent");
          _updateLeadStatus(textLead.id, 'Sent', '');
          _recordWhatsappSentHistory(textLead);
          _updateCounts();
          addLog("Sent WhatsApp message to: ${textLead.recruiter} (${textLead.company})");
          await Future.delayed(Duration(seconds: delay.value.round()));
          _sendNextWhatsApp();
        }
        return;
      }

      final pdfLead = leads.firstWhereOrNull((l) => l.status == 'SendingPDF');
      if (pdfLead != null) {
        addLog("Campaign Transition: found pdfLead: ${pdfLead.recruiter}, finalizing lead as Sent");
        _updateLeadStatus(pdfLead.id, 'Sent', '');
        _recordWhatsappSentHistory(pdfLead);
        _updateCounts();
        addLog("Sent WhatsApp message and resume to: ${pdfLead.recruiter} (${pdfLead.company})");
        await Future.delayed(Duration(seconds: delay.value.round()));
        _sendNextWhatsApp();
        return;
      }
    } else if (campaignType.value == 'LinkedIn') {
      final linkedinLead = leads.firstWhereOrNull((l) => l.status == 'SendingLinkedIn');
      if (linkedinLead != null) {
        bool success = true;
        if (Platform.isAndroid) {
          try {
            success = await _whatsappChannel.invokeMethod('getLinkedInLastStatus') ?? false;
          } catch (e) {
            addLog("Error checking LinkedIn status: $e");
          }
        }
        
        if (success) {
          addLog("Campaign Transition: found linkedinLead: ${linkedinLead.recruiter}, finalizing lead as Sent");
          _updateLeadStatus(linkedinLead.id, 'Sent', '');
          _recordLinkedInSentHistory(linkedinLead);
          _updateCounts();
          addLog("Sent LinkedIn connection request to: ${linkedinLead.recruiter} (${linkedinLead.company})");
        } else {
          addLog("Campaign Transition: LinkedIn invite timed out or failed for ${linkedinLead.recruiter}, marking as Skipped");
          _updateLeadStatus(linkedinLead.id, 'Skipped', 'Profile buttons not found or already connected');
          _updateCounts();
        }
        await Future.delayed(Duration(seconds: delay.value.round()));
        _sendNextLinkedIn();
        return;
      }
    }
    
    addLog("_handleAppResumedFromOutreach: no matching active lead or test sequence found");
  }

  void sendWhatsAppNextFromUi() {
    _updateCounts();
    _sendNextWhatsApp();
  }

  // --- LINKEDIN AUTOMATION METHODS ---

  Future<void> setLinkedInAutoSendActive(bool active) async {
    if (!Platform.isAndroid) return;
    try {
      await _whatsappChannel.invokeMethod('setAutoSendActive', {'active': active});
      await _whatsappChannel.invokeMethod('setCampaignType', {'type': 'LinkedIn'});
    } catch (e) {
      addLog("Failed setting accessibility campaign type: $e");
    }
  }

  Future<void> startLinkedInCampaign() async {
    if (Platform.isAndroid) {
      await checkAccessibilityPermission();
      if (!isAccessibilityActive.value) {
        Get.defaultDialog(
          title: "Permission Required",
          middleText: "JobPilot requires the 'Automation Service' Accessibility Service to automatically click the LinkedIn connection buttons, enter your note, and return.\n\nPlease enable it in system settings.",
          textConfirm: "Open Settings",
          textCancel: "Cancel",
          confirmTextColor: Colors.white,
          onConfirm: () {
            Get.back();
            openAccessibilitySettings();
          },
        );
        return;
      }
    }

    final readyLeads = leads.where((l) => l.status == 'Ready' || l.status == 'Failed').toList();
    if (readyLeads.isEmpty) {
      Get.snackbar("Campaign Empty", "No campaign leads found in 'Ready' or 'Failed' status.");
      return;
    }

    isProcessing.value = true;
    isPaused.value = false;
    _sendingStartTime = DateTime.now();
    _initialSentCount = sentCount.value;
    
    _startMetricsTimer();
    addLog("LinkedIn Campaign started.");
    
    if (Platform.isAndroid) {
      await setLinkedInAutoSendActive(true);
    }
    
    _sendNextLinkedIn();
  }

  Future<void> _sendNextLinkedIn() async {
    addLog("_sendNextLinkedIn: loop triggered");
    if (!isProcessing.value) {
      addLog("_sendNextLinkedIn: processing flag is false, skipping");
      return;
    }
    if (isPaused.value) {
      addLog("_sendNextLinkedIn: paused is true, skipping");
      return;
    }

    var activeLead = leads.firstWhereOrNull((l) => l.status == 'SendingLinkedIn');
    if (activeLead == null) {
      addLog("_sendNextLinkedIn: no active lead in transition, searching for fresh lead...");
      activeLead = leads.firstWhereOrNull((l) => l.status == 'Ready' || l.status == 'Failed');
      if (activeLead == null) {
        addLog("_sendNextLinkedIn: no more leads remaining. Completing campaign.");
        isProcessing.value = false;
        _metricsTimer?.cancel();
        addLog("LinkedIn Campaign sending completed.");
        if (Platform.isAndroid) {
          await setLinkedInAutoSendActive(false);
        }
        Get.snackbar(
          "LinkedIn Campaign Complete",
          "All connections processed successfully.",
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      addLog("_sendNextLinkedIn: selected next lead: ${activeLead.recruiter} (${activeLead.company}), setting status to SendingLinkedIn");
      _updateLeadStatus(activeLead.id, 'SendingLinkedIn', '');
      _updateCounts();
    }

    currentRecruiter.value = activeLead.recruiter;
    currentCompany.value = activeLead.company;
    currentEmail.value = activeLead.linkedinName;
    currentStatus.value = 'Sending Invite';

    final String messageTemplate = activeLead.linkedinBody.isNotEmpty
        ? activeLead.linkedinBody
        : linkedinBody.value;
    var message = _personalize(messageTemplate, activeLead);
    if (message.length > 300) {
      message = message.substring(0, 300);
    }
    final profileUrl = activeLead.linkedinName;

    addLog("Opening LinkedIn profile for: ${activeLead.recruiter} (${activeLead.company}), url=$profileUrl");
    try {
      if (Platform.isAndroid) {
        // Send message to service first
        await _whatsappChannel.invokeMethod('setLinkedInMessage', {'message': message});
        
        // Launch profile
        final success = await _whatsappChannel.invokeMethod('openLinkedInProfile', {'url': profileUrl});
        addLog("LinkedIn launch intent result: $success");
        if (success != true) {
          throw Exception("Could not launch LinkedIn app via intent.");
        }
      } else {
        final uri = Uri.parse(profileUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        } else {
          throw Exception("Cannot launch browser URL: $profileUrl");
        }
      }
    } catch (e) {
      addLog("Failed to launch LinkedIn profile: $e");
      _updateLeadStatus(activeLead.id, 'Failed', 'Launch error: $e');
      _updateCounts();
      await Future.delayed(Duration(seconds: delay.value.round()));
      _sendNextLinkedIn();
    }
  }

  void sendLinkedInNextFromUi() {
    _updateCounts();
    _sendNextLinkedIn();
  }

  Future<void> sendTestLinkedIn() async {
    addLog("sendTestLinkedIn: started");
    if (testLinkedinProfile.value.trim().isEmpty) {
      Get.snackbar("Missing Field", "Please enter a test LinkedIn profile URL first.");
      return;
    }
    if (Platform.isAndroid) {
      await checkAccessibilityPermission();
      if (!isAccessibilityActive.value) {
        addLog("sendTestLinkedIn: cancelled, accessibility service inactive");
        Get.defaultDialog(
          title: "Permission Required",
          middleText: "Please enable the accessibility service first to test the automator.",
          textConfirm: "Open Settings",
          textCancel: "Cancel",
          confirmTextColor: Colors.white,
          onConfirm: () {
            Get.back();
            openAccessibilitySettings();
          },
        );
        return;
      }
      await setLinkedInAutoSendActive(true);
    }

    final String messageTemplate = linkedinBody.value;
    // Mock lead for personalization
    final mockLead = LeadModel(
      id: -99,
      recruiter: "RecruiterName",
      company: "CompanyName",
      role: "Flutter Developer",
      email: "recruiter@company.com",
      mobile: "919876543210",
      linkedinName: testLinkedinProfile.value,
      emailBody: "",
      whatsappBody: "",
      linkedinBody: "",
      resumeLink: "",
      status: "Ready",
      reason: "",
    );
    var message = _personalize(messageTemplate, mockLead);
    if (message.length > 300) {
      message = message.substring(0, 300);
    }

    _isTestingLinkedIn = true;

    try {
      if (Platform.isAndroid) {
        await _whatsappChannel.invokeMethod('setLinkedInMessage', {'message': message});
        final success = await _whatsappChannel.invokeMethod('openLinkedInProfile', {'url': testLinkedinProfile.value.trim()});
        addLog("sendTestLinkedIn: launched via method channel intent: $success");
      } else {
        final uri = Uri.parse(testLinkedinProfile.value.trim());
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        addLog("sendTestLinkedIn: launched via launchUrl");
      }
    } catch (e) {
      addLog("sendTestLinkedIn error: $e");
      _isTestingLinkedIn = false;
    }
  }

  void _recordLinkedInSentHistory(LeadModel lead) {
    final String todayDate = DateTime.now().toLocal().toString().split(' ')[0]; // YYYY-MM-DD
    final String timestamp = DateTime.now().toLocal().toString().substring(0, 19);

    final newRecord = {
      'linkedin_link': lead.linkedinName,
      'date': todayDate,
      'recruiter': lead.recruiter,
      'company': lead.company,
      'timestamp': timestamp,
    };

    linkedinHistory.add(newRecord);
    _storage.write('linkedin_sent_history', linkedinHistory.toList());
  }

  void retryFailed() {
    int updated = 0;
    for (var lead in leads) {
      if (lead.status == 'Failed') {
        lead.status = 'Ready';
        lead.reason = '';
        updated++;
      }
    }
    if (updated > 0) {
      leads.refresh();
      _updateCounts();
      addLog("Reset $updated failed campaign leads.");
      startSending();
    } else {
      Get.snackbar("Campaign Error", "No failed emails to retry.");
    }
  }

  Future<void> exportReport() async {
    if (leads.isEmpty) {
      Get.snackbar("Error", "Lead campaign database is empty.");
      return;
    }
    try {
      final String dir = p.dirname(excelPath.value.isNotEmpty ? excelPath.value : Directory.systemTemp.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = p.join(dir, "ApplyEngine_Report_$timestamp.xlsx");
      
      addLog("Exporting report spreadsheet...");
      await _excelService.exportReport(
        leads: leads.map((l) => l.toJson()).toList(),
        outputPath: outPath,
      );

      addLog("Report exported to: $outPath");
      Get.snackbar(
        "Report Saved",
        "Saved to: ${p.basename(outPath)}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
      );
    } catch (e) {
      addLog("Report Export Error: $e");
      Get.snackbar("Export Failed", e.toString());
    }
  }

  Future<void> exportInvalidFailed() async {
    final toExport = leads.where((l) => l.status == 'Invalid' || l.status == 'Failed').toList();
    if (toExport.isEmpty) {
      Get.snackbar("Nothing to Export", "No campaign leads found in 'Invalid' or 'Failed' status.");
      return;
    }
    try {
      final String dir = p.dirname(excelPath.value.isNotEmpty ? excelPath.value : Directory.systemTemp.path);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = p.join(dir, "ApplyEngine_Invalid_Leads_$timestamp.xlsx");
      
      addLog("Exporting invalid and failed leads for correction...");
      await _excelService.exportInvalidFailedLeads(
        leads: leads.map((l) => l.toJson()).toList(),
        outputPath: outPath,
      );

      addLog("Invalid leads exported to: $outPath");
      Get.snackbar(
        "Exported Successfully",
        "Saved to: ${p.basename(outPath)}",
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Get.theme.colorScheme.primaryContainer,
        colorText: Get.theme.colorScheme.onPrimaryContainer,
      );
    } catch (e) {
      addLog("Export Error: $e");
      Get.snackbar("Export Failed", e.toString());
    }
  }

  void removeDuplicatesManual() {
    final seen = <String>{};
    final unique = <LeadModel>[];
    int removed = 0;
    for (var l in leads) {
      if (l.email.isNotEmpty && seen.contains(l.email.toLowerCase())) {
        removed++;
      } else {
        seen.add(l.email.toLowerCase());
        unique.add(l);
      }
    }
    if (removed > 0) {
      leads.value = unique;
      _updateCounts();
      addLog("Manually pruned $removed duplicate records.");
      Get.snackbar("Duplicates Pruned", "Removed $removed duplicates.");
    } else {
      Get.snackbar("Campaign Clean", "No duplicate emails found.");
    }
  }

  void _startMetricsTimer() {
    _metricsTimer?.cancel();
    _metricsTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!isProcessing.value || isPaused.value || _sendingStartTime == null) return;

      final elapsed = DateTime.now().difference(_sendingStartTime!);
      final sentThisRun = sentCount.value - _initialSentCount;

      if (sentThisRun > 0 && elapsed.inSeconds > 2) {
        final double rate = (sentThisRun / elapsed.inSeconds) * 60.0;
        emailsPerMinute.value = double.parse(rate.toStringAsFixed(1));

        final int remainingLeadsCount = readyCount.value;
        if (remainingLeadsCount > 0) {
          final int secondsRemaining = (remainingLeadsCount / (rate / 60.0)).round();
          final int minutes = secondsRemaining ~/ 60;
          final int seconds = secondsRemaining % 60;
          estimatedTimeRemaining.value =
              "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
        } else {
          estimatedTimeRemaining.value = "00:00";
        }
      } else {
        final double estimatedRate = 60.0 / (delay.value + 1.5);
        emailsPerMinute.value = double.parse(estimatedRate.toStringAsFixed(1));

        final int remainingLeadsCount = readyCount.value;
        final int secondsRemaining = (remainingLeadsCount * (delay.value + 1.5)).round();
        final int minutes = secondsRemaining ~/ 60;
        final int seconds = secondsRemaining % 60;
        estimatedTimeRemaining.value =
            "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
      }
    });
  }

  // --- FILTERED AND SORTED VIEW ---
  List<LeadModel> get filteredLeads {
    var list = leads.toList();
    final query = searchQuery.value.toLowerCase().trim();
    if (query.isNotEmpty) {
      list = list.where((lead) {
        return lead.recruiter.toLowerCase().contains(query) ||
            lead.company.toLowerCase().contains(query) ||
            lead.email.toLowerCase().contains(query) ||
            lead.role.toLowerCase().contains(query);
      }).toList();
    }

    if (onlyWithMobile.value) {
      list = list.where((l) => l.mobile.isNotEmpty).toList();
    }

    if (statusFilter.value != 'All') {
      list = list.where((l) => l.status.toLowerCase() == statusFilter.value.toLowerCase()).toList();
    }

    list.sort((a, b) {
      int cmp = 0;
      switch (sortColumn.value) {
        case 'Company':
          cmp = a.company.toLowerCase().compareTo(b.company.toLowerCase());
          break;
        case 'Recruiter':
          cmp = a.recruiter.toLowerCase().compareTo(b.recruiter.toLowerCase());
          break;
        case 'Status':
          cmp = a.status.toLowerCase().compareTo(b.status.toLowerCase());
          break;
        default:
          cmp = a.id.compareTo(b.id);
      }
      return sortAscending.value ? cmp : -cmp;
    });

    return list;
  }

  void _recordEmailSentHistory(LeadModel lead) {
    final String todayDate = DateTime.now().toLocal().toString().split(' ')[0]; // YYYY-MM-DD
    final String timestamp = DateTime.now().toLocal().toString().substring(0, 19);

    final newRecord = {
      'email': lead.email,
      'date': todayDate,
      'recruiter': lead.recruiter,
      'company': lead.company,
      'subject': subject.value,
      'timestamp': timestamp,
    };

    campaignHistory.add(newRecord);
    _storage.write('sent_history', campaignHistory.toList());
  }

  void _recordWhatsappSentHistory(LeadModel lead) {
    final String todayDate = DateTime.now().toLocal().toString().split(' ')[0]; // YYYY-MM-DD
    final String timestamp = DateTime.now().toLocal().toString().substring(0, 19);

    final newRecord = {
      'mobile': lead.mobile,
      'date': todayDate,
      'recruiter': lead.recruiter,
      'company': lead.company,
      'timestamp': timestamp,
    };

    whatsappHistory.add(newRecord);
    _storage.write('whatsapp_sent_history', whatsappHistory.toList());
  }

  void clearEmailHistory() {
    campaignHistory.clear();
    _storage.write('sent_history', []);
    addLog("Email campaign history cleared.");
    if (excelPath.value.isNotEmpty && File(excelPath.value).existsSync()) {
      loadExcel();
    }
  }

  void clearWhatsappHistory() {
    whatsappHistory.clear();
    _storage.write('whatsapp_sent_history', []);
    addLog("WhatsApp campaign history cleared.");
    if (excelPath.value.isNotEmpty && File(excelPath.value).existsSync()) {
      loadExcel();
    }
  }

  void clearLinkedinHistory() {
    linkedinHistory.clear();
    _storage.write('linkedin_sent_history', []);
    addLog("LinkedIn campaign history cleared.");
    if (excelPath.value.isNotEmpty && File(excelPath.value).existsSync()) {
      loadExcel();
    }
  }
}
