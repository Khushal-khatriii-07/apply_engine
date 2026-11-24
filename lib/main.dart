import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:applyengine/screens/splash_screen.dart';
import 'package:applyengine/services/excel_service.dart';
import 'package:applyengine/services/validation_service.dart';
import 'package:applyengine/services/smtp_mailer_service.dart';
import 'package:applyengine/services/resume_service.dart';
import 'package:applyengine/services/gemini_service.dart';
import 'package:applyengine/services/job_hunter_service.dart';
import 'package:applyengine/utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize local settings database storage
  await GetStorage.init();

  // Inject native Dart campaign & AI services
  Get.put(ExcelService());
  Get.put(ValidationService());
  Get.put(SmtpMailerService());
  Get.put(ResumeService());
  Get.put(GeminiService());
  Get.put(JobHunterService());

  runApp(const ApplyEngineApp());
}

class ApplyEngineApp extends StatelessWidget {
  const ApplyEngineApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final storage = GetStorage();
    final isDark = storage.read('isDarkMode') ?? true; // Default to dark mode for premium look

    return GetMaterialApp(
      title: 'ApplyEngine',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
