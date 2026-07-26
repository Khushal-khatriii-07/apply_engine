import 'package:flutter_test/flutter_test.dart';
import 'package:applyengine/services/validation_service.dart';

void main() {
  group('Alternative Contacts Parser Tests', () {
    final validationService = ValidationService();

    test('Test plain comma-separated names (no links)', () {
      final text = 'khushal, nisha, rahul';
      final result = validationService.parseAlternativeContacts(text);
      expect(result.length, 3);
      expect(result[0]['name'], 'khushal');
      expect(result[0]['link'], '');
      expect(result[1]['name'], 'nisha');
      expect(result[1]['link'], '');
      expect(result[2]['name'], 'rahul');
      expect(result[2]['link'], '');
    });

    test('Test parentheses formatting: name (link)', () {
      final text = 'khushal (https://linkedin.com/in/khushal), nisha (https://linkedin.com/in/nisha)';
      final result = validationService.parseAlternativeContacts(text);
      expect(result.length, 2);
      expect(result[0]['name'], 'khushal');
      expect(result[0]['link'], 'https://linkedin.com/in/khushal');
      expect(result[1]['name'], 'nisha');
      expect(result[1]['link'], 'https://linkedin.com/in/nisha');
    });

    test('Test HTML anchor tag formatting', () {
      final text = '<a href="https://linkedin.com/in/khushal">khushal</a>, <a href="https://linkedin.com/in/nisha">nisha</a>';
      final result = validationService.parseAlternativeContacts(text);
      expect(result.length, 2);
      expect(result[0]['name'], 'khushal');
      expect(result[0]['link'], 'https://linkedin.com/in/khushal');
      expect(result[1]['name'], 'nisha');
      expect(result[1]['link'], 'https://linkedin.com/in/nisha');
    });

    test('Test Markdown link formatting', () {
      final text = '[khushal](https://linkedin.com/in/khushal), [nisha](https://linkedin.com/in/nisha)';
      final result = validationService.parseAlternativeContacts(text);
      expect(result.length, 2);
      expect(result[0]['name'], 'khushal');
      expect(result[0]['link'], 'https://linkedin.com/in/khushal');
      expect(result[1]['name'], 'nisha');
      expect(result[1]['link'], 'https://linkedin.com/in/nisha');
    });

    test('Test HYPERLINK formula formatting', () {
      final text = 'HYPERLINK("https://linkedin.com/in/khushal", "khushal")';
      final result = validationService.parseAlternativeContacts(text);
      expect(result.length, 1);
      expect(result[0]['name'], 'khushal');
      expect(result[0]['link'], 'https://linkedin.com/in/khushal');
    });

    test('Test comma and space trimming', () {
      final text = ' ,  khushal  ;  ; , nisha ';
      final result = validationService.parseAlternativeContacts(text);
      expect(result.length, 2);
      expect(result[0]['name'], 'khushal');
      expect(result[1]['name'], 'nisha');
    });
  });
}
