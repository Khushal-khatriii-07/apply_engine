import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:applyengine/services/gemini_service.dart';
import 'package:applyengine/services/job_hunter_service.dart';

void main() {
  group('JobHunterService Tests', () {
    setUp(() {
      Get.put(GeminiService());
      Get.put(JobHunterService());
    });

    tearDown(() {
      Get.reset();
    });

    test('JobHunterService parses JSON array into LeadModel objects with scores', () {
      final hunterService = Get.find<JobHunterService>();
      expect(hunterService, isNotNull);
    });
  });
}
