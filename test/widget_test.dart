import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:applyengine/main.dart';
import 'package:applyengine/services/excel_service.dart';
import 'package:applyengine/services/validation_service.dart';
import 'package:applyengine/services/smtp_mailer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Disable network fetching of fonts in tests
    GoogleFonts.config.allowRuntimeFetching = false;

    // Catch and ignore all font loading failures so widget tests can run using fallback system fonts
    final originalOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      final exception = details.exception.toString();
      if (exception.contains('google_fonts') || 
          exception.contains('Failed to load font') || 
          exception.contains('allowRuntimeFetching') ||
          exception.contains('assets')) {
        debugPrint('Ignored font error in test: $exception');
        return;
      }
      originalOnError?.call(details);
    };

    const MethodChannel('plugins.flutter.io/path_provider')
        .setMockMethodCallHandler((MethodCall methodCall) async {
      if (methodCall.method == 'getApplicationDocumentsDirectory') {
        return '.';
      }
      return null;
    });
  });

  setUp(() async {
    await GetStorage.init();
    
    // Inject required services
    Get.put(ExcelService());
    Get.put(ValidationService());
    Get.put(SmtpMailerService());
  });

  tearDown(() {
    Get.reset();
  });

  testWidgets('ApplyEngine App Smoke Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ApplyEngineApp());
    // Pump and settle to let the Splash Screen transition finish and clear all timers
    await tester.pump(const Duration(seconds: 4));
    await tester.pumpAndSettle();
  });
}





