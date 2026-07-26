import 'dart:async';
import 'dart:io';
import 'package:get/get.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:path/path.dart' as p;

class SmtpMailerService extends GetxService {
  final StreamController<Map<String, dynamic>> _eventStreamController =
      StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get eventStream => _eventStreamController.stream;

  bool isRunning = false;
  bool isPaused = false;
  bool stopRequested = false;

  double delay = 2.0;
  int threads = 1;
  int maxEmails = 1000;

  final List<Future> _activeWorkers = [];

  void _emitEvent(String eventName, Map<String, dynamic> data) {
    final Map<String, dynamic> payload = {
      'event': eventName,
      'timestamp': _getCurrentTimestamp(),
    };
    payload.addAll(data);
    _eventStreamController.add(payload);
  }

  void _logInfo(String message) {
    _emitEvent('log', {'message': message, 'level': 'INFO'});
  }

  void _logError(String message) {
    _emitEvent('log', {'message': message, 'level': 'ERROR'});
  }

  String _getCurrentTimestamp() {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  String _personalize(String template, Map<String, dynamic> lead) {
    String text = template;
    lead.forEach((key, value) {
      text = text.replaceAll('{$key}', value.toString());
      text = text.replaceAll('{${key.toLowerCase()}}', value.toString());
    });
    return text;
  }

  Future<void> _checkPause() async {
    while (isPaused && !stopRequested) {
      await Future.delayed(const Duration(milliseconds: 100));
    }
  }

  Future<void> startSendingCampaign({
    required List<Map<String, dynamic>> leads,
    required String senderEmail,
    required String appPassword,
    required String senderName,
    required String subjectTemplate,
    required double delaySeconds,
    required int workerThreads,
    required int limitMaxEmails,
    required String resumePath,
  }) async {
    isRunning = true;
    isPaused = false;
    stopRequested = false;
    delay = delaySeconds;
    threads = workerThreads;
    maxEmails = limitMaxEmails;

    _logInfo("Starting sending engine campaign...");

    final readyLeads = leads.where((l) => l['Status'] == 'Ready' || l['Status'] == 'Failed').toList();
    _logInfo("Found ${readyLeads.length} leads in queue to process. Delay: ${delay}s. Workers: $threads");

    if (readyLeads.isEmpty) {
      isRunning = false;
      _emitEvent('sending_completed', {});
      return;
    }

    final smtpServer = gmail(senderEmail, appPassword);
    int sentCount = 0;

    // Concurrency logic
    final List<Map<String, dynamic>> queue = List.from(readyLeads);

    _activeWorkers.clear();
    for (int i = 0; i < threads; i++) {
      final worker = _runWorker(i + 1, queue, smtpServer, senderEmail, senderName, subjectTemplate, resumePath, () => sentCount++);
      _activeWorkers.add(worker);
    }

    // Wait for all workers to finish
    await Future.wait(_activeWorkers);

    isRunning = false;
    _logInfo("Campaign completed.");
    _emitEvent('sending_completed', {});
  }

  Future<void> _runWorker(
    int workerId,
    List<Map<String, dynamic>> queue,
    SmtpServer smtpServer,
    String senderEmail,
    String senderName,
    String subjectTemplate,
    String resumePath,
    void Function() incrementSent,
  ) async {
    _logInfo("Worker $workerId started.");

    while (queue.isNotEmpty && !stopRequested) {
      await _checkPause();
      if (stopRequested) break;

      // Dart runs on event-loop, list remove is atomic
      final lead = queue.removeAt(0);
      final int leadId = lead['id'] ?? -1;

      // Update state to Sending
      _emitEvent('lead_status_update', {'id': leadId, 'status': 'Sending', 'reason': ''});

      _logInfo("Worker $workerId sending email to: ${lead['Email']}");

      try {
        await _sendEmail(
          smtpServer: smtpServer,
          senderEmail: senderEmail,
          senderName: senderName,
          recipientEmail: lead['Email'],
          recruiter: lead['Recruiter'],
          company: lead['Company'],
          subject: _personalize(subjectTemplate, lead),
          body: _personalize(lead['EmailBody'] ?? lead['Email Body'] ?? '', lead),
          resumePath: resumePath,
        );

        incrementSent();
        _emitEvent('send_progress', {
          'id': leadId,
          'status': 'Sent',
          'reason': '',
          'log': 'Sent to ${lead['Email']} (${lead['Company']})',
        });
      } catch (e) {
        final reason = _mapExceptionToReason(e);
        _emitEvent('send_progress', {
          'id': leadId,
          'status': 'Failed',
          'reason': reason,
          'log': 'Failed sending to ${lead['Email']}: $reason',
        });
      }

      if (delay > 0 && queue.isNotEmpty && !stopRequested) {
        await Future.delayed(Duration(milliseconds: (delay * 1000).round()));
      }
    }

    _logInfo("Worker $workerId stopped.");
  }

  Future<void> _sendEmail({
    required SmtpServer smtpServer,
    required String senderEmail,
    required String senderName,
    required String recipientEmail,
    required String recruiter,
    required String company,
    required String subject,
    required String body,
    required String resumePath,
  }) async {
    String finalBody = body;
    if (finalBody.isEmpty) {
      finalBody = "Hi $recruiter,\n\nI am interested in applying for a role at $company.";
    }

    final message = Message()
      ..from = Address(senderEmail, senderName)
      ..recipients.add(recipientEmail)
      ..subject = subject;

    if (finalBody.toLowerCase().contains("<html>") || finalBody.toLowerCase().contains("<body>")) {
      message.html = finalBody;
    } else {
      message.text = finalBody;
    }

    // Attach PDF
    if (resumePath.isNotEmpty) {
      final file = File(resumePath);
      if (await file.exists()) {
        message.attachments.add(FileAttachment(file)
          ..fileName = p.basename(resumePath)
          ..contentType = 'application/pdf');
      } else {
        throw Exception("Attachment missing: resume PDF not found.");
      }
    }

    await send(message, smtpServer);
  }

  String _mapExceptionToReason(dynamic e) {
    final errStr = e.toString().toLowerCase();
    if (errStr.contains('authentication') ||
        errStr.contains('username and password not accepted') ||
        errStr.contains('535') ||
        errStr.contains('invalid credentials')) {
      return 'Authentication Failed (Check App Password)';
    } else if (errStr.contains('timeout') ||
        errStr.contains('socketexception') ||
        errStr.contains('host lookup failed')) {
      return 'Connection Timeout (No Internet or Blocked SMTP)';
    } else if (errStr.contains('attachment') || errStr.contains('not found')) {
      return 'Resume PDF missing or unreadable';
    } else {
      return 'Error: $e';
    }
  }

  void pause() {
    if (isRunning && !isPaused) {
      isPaused = true;
      _logInfo("Sending campaign paused.");
      _emitEvent('status_paused', {});
    }
  }

  void resume() {
    if (isRunning && isPaused) {
      isPaused = false;
      _logInfo("Sending campaign resumed.");
      _emitEvent('status_resumed', {});
    }
  }

  void stop() {
    if (isRunning) {
      stopRequested = true;
      isPaused = false; // Release lock if paused
      _logInfo("Campaign stop requested.");
      _emitEvent('status_stopped', {});
    }
  }

  Future<void> sendTestEmail({
    required String senderEmail,
    required String appPassword,
    required String senderName,
    required String resumePath,
  }) async {
    _logInfo("Sending test email to: $senderEmail");

    final smtpServer = gmail(senderEmail, appPassword);
    
    try {
      await _sendEmail(
        smtpServer: smtpServer,
        senderEmail: senderEmail,
        senderName: senderName,
        recipientEmail: senderEmail,
        recruiter: "Self (Test)",
        company: "ApplyEngine System",
        subject: "ApplyEngine Mobile Verification",
        body: "Hello!\n\nThis is a test email sent natively from the ApplyEngine mobile application to verify your App Password and resume attachment.",
        resumePath: resumePath,
      );

      _logInfo("Test email delivered successfully.");
      _emitEvent('test_email_result', {'status': 'Sent', 'reason': ''});
    } catch (e) {
      final reason = _mapExceptionToReason(e);
      _logError("Test email dispatch failed: $reason");
      _emitEvent('test_email_result', {'status': 'Failed', 'reason': reason});
    }
  }

  Future<void> sendTestCampaignToSelf({
    required List<Map<String, dynamic>> leads,
    required String senderEmail,
    required String appPassword,
    required String senderName,
    required String subjectTemplate,
    required String resumePath,
  }) async {
    _logInfo("Starting 2-email self-test campaign to: $senderEmail...");
    final smtpServer = gmail(senderEmail, appPassword);
    final testLeads = leads.take(2).toList();
    
    if (testLeads.isEmpty) {
      _logError("No leads available to run test campaign.");
      _emitEvent('test_email_result', {'status': 'Failed', 'reason': 'No leads loaded.'});
      return;
    }

    try {
      for (int i = 0; i < testLeads.length; i++) {
        final lead = testLeads[i];
        final count = i + 1;
        _logInfo("Sending test email $count/${testLeads.length} to self using lead: ${lead['Email'] ?? 'Unknown'}");
        
        await _sendEmail(
          smtpServer: smtpServer,
          senderEmail: senderEmail,
          senderName: senderName,
          recipientEmail: senderEmail, // Sent to self!
          recruiter: lead['Recruiter'] ?? 'Recruiter',
          company: lead['Company'] ?? 'Company',
          subject: "[TEST $count] ${_personalize(subjectTemplate, lead)}",
          body: _personalize(lead['Email Body'] ?? lead['EmailBody'] ?? '', lead),
          resumePath: resumePath,
        );
      }
      _logInfo("2-email self-test campaign delivered successfully to $senderEmail.");
      _emitEvent('test_email_result', {'status': 'Sent', 'reason': ''});
    } catch (e) {
      final reason = _mapExceptionToReason(e);
      _logError("Self-test campaign failed: $reason");
      _emitEvent('test_email_result', {'status': 'Failed', 'reason': reason});
    }
  }
}
