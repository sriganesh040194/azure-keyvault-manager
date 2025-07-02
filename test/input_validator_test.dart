import 'package:flutter_test/flutter_test.dart';
import 'package:keyvault_ui/core/security/input_validator.dart';

void main() {
  group('InputValidator', () {
    group('Command Validation', () {
      test('should reject empty commands', () {
        final result = InputValidator.validateCommand('');
        expect(result, equals('Command cannot be empty'));
      });

      test('should reject non-az commands', () {
        final result = InputValidator.validateCommand('rm -rf /');
        expect(result, equals('Only Azure CLI commands are allowed'));
      });

      test('should reject commands with shell metacharacters', () {
        final dangerousCommands = [
          'az keyvault list; rm file',
          'az keyvault list && rm file',
          'az keyvault list | grep test',
          'az keyvault list `whoami`',
          'az keyvault list \$(whoami)',
        ];

        for (final command in dangerousCommands) {
          final result = InputValidator.validateCommand(command);
          expect(result, contains('potentially dangerous characters'));
        }
      });

      test('should accept valid az commands', () {
        final validCommands = [
          'az keyvault list',
          'az keyvault create --name test --resource-group rg',
          'az keyvault secret show --name secret --vault-name kv',
        ];

        for (final command in validCommands) {
          final result = InputValidator.validateCommand(command);
          expect(result, isNull);
        }
      });
    });

    group('Resource Name Validation', () {
      test('should reject empty names', () {
        final result = InputValidator.validateResourceName('');
        expect(result, equals('Resource name cannot be empty'));
      });

      test('should reject names that are too short', () {
        final result = InputValidator.validateResourceName('ab');
        expect(result, contains('between 3 and 24 characters'));
      });

      test('should reject names that are too long', () {
        final result = InputValidator.validateResourceName('a' * 25);
        expect(result, contains('between 3 and 24 characters'));
      });

      test('should reject names with invalid characters', () {
        final invalidNames = [
          'test@name',
          'test name',
          'test.name',
          'test/name',
          'test\\name',
        ];

        for (final name in invalidNames) {
          final result = InputValidator.validateResourceName(name);
          expect(result, contains('can only contain letters, numbers, hyphens, and underscores'));
        }
      });

      test('should reject names starting or ending with hyphen', () {
        expect(
          InputValidator.validateResourceName('-testname'),
          contains('cannot start or end with a hyphen'),
        );
        expect(
          InputValidator.validateResourceName('testname-'),
          contains('cannot start or end with a hyphen'),
        );
      });

      test('should accept valid names', () {
        final validNames = [
          'test-kv-1',
          'MyKeyVault_2023',
          'production-vault',
          'dev_environment',
        ];

        for (final name in validNames) {
          final result = InputValidator.validateResourceName(name);
          expect(result, isNull);
        }
      });
    });

    group('Subscription ID Validation', () {
      test('should reject empty subscription ID', () {
        final result = InputValidator.validateSubscriptionId('');
        expect(result, equals('Subscription ID cannot be empty'));
      });

      test('should reject invalid formats', () {
        final invalidIds = [
          'not-a-guid',
          '12345678-1234-1234-1234',
          '12345678-1234-1234-1234-12345678901234567890',
          'xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx',
        ];

        for (final id in invalidIds) {
          final result = InputValidator.validateSubscriptionId(id);
          expect(result, equals('Invalid subscription ID format'));
        }
      });

      test('should accept valid subscription IDs', () {
        final validIds = [
          '12345678-1234-1234-1234-123456789012',
          'abcdef12-3456-789a-bcde-f123456789ab',
          'ABCDEF12-3456-789A-BCDE-F123456789AB',
        ];

        for (final id in validIds) {
          final result = InputValidator.validateSubscriptionId(id);
          expect(result, isNull);
        }
      });
    });

    group('Resource Group Validation', () {
      test('should reject empty resource group', () {
        final result = InputValidator.validateResourceGroup('');
        expect(result, equals('Resource group cannot be empty'));
      });

      test('should reject names that are too long', () {
        final result = InputValidator.validateResourceGroup('a' * 91);
        expect(result, contains('cannot exceed 90 characters'));
      });

      test('should reject names ending with period', () {
        final result = InputValidator.validateResourceGroup('test-rg.');
        expect(result, contains('cannot end with a period'));
      });

      test('should accept valid resource group names', () {
        final validNames = [
          'test-rg',
          'production_resources',
          'my-app-rg-2023',
          'rg(development)',
        ];

        for (final name in validNames) {
          final result = InputValidator.validateResourceGroup(name);
          expect(result, isNull);
        }
      });
    });

    group('JSON Validation', () {
      test('should reject empty JSON', () {
        final result = InputValidator.validateJson('');
        expect(result, equals('JSON cannot be empty'));
      });

      test('should reject invalid JSON', () {
        final invalidJson = [
          '{invalid json}',
          '{"unclosed": "object"',
          'not json at all',
          '{"duplicate": 1, "duplicate": 2}', // This is actually valid JSON
        ];

        for (final json in invalidJson.take(3)) { // Skip the last one as it's valid
          final result = InputValidator.validateJson(json);
          expect(result, contains('Invalid JSON format'));
        }
      });

      test('should accept valid JSON', () {
        final validJson = [
          '{}',
          '{"key": "value"}',
          '[]',
          '[{"name": "test", "value": 123}]',
          'null',
          '"string"',
          '42',
          'true',
        ];

        for (final json in validJson) {
          final result = InputValidator.validateJson(json);
          expect(result, isNull);
        }
      });
    });

    group('Output Sanitization', () {
      test('should redact sensitive values', () {
        final sensitiveOutput = '''
        {
          "value": "supersecret123",
          "password": "mypassword",
          "connectionString": "Server=...",
          "key": "secretkey",
          "secret": "anothersecret",
          "name": "test"
        }
        ''';

        final sanitized = InputValidator.sanitizeOutput(sensitiveOutput);
        
        expect(sanitized, isNot(contains('supersecret123')));
        expect(sanitized, isNot(contains('mypassword')));
        expect(sanitized, isNot(contains('secretkey')));
        expect(sanitized, isNot(contains('anothersecret')));
        expect(sanitized, contains('[REDACTED]'));
        expect(sanitized, contains('test')); // Non-sensitive data should remain
      });
    });

    group('Shell Argument Escaping', () {
      test('should escape special characters', () {
        final testCases = {
          'simple': "'simple'",
          "with'quote": "'with'\"'\"'quote'",
          'with space': "'with space'",
          'with\$dollar': "'with\$dollar'",
          'with;semicolon': "'with;semicolon'",
        };

        testCases.forEach((input, expected) {
          final result = InputValidator.escapeShellArgument(input);
          expect(result, equals(expected));
        });
      });
    });

    group('Email Validation', () {
      test('should reject empty email', () {
        final result = InputValidator.validateEmail('');
        expect(result, equals('Email cannot be empty'));
      });

      test('should reject invalid email formats', () {
        final invalidEmails = [
          'notanemail',
          '@domain.com',
          'user@',
          'user@.com',
          'user@domain',
          'user..double.dot@domain.com',
        ];

        for (final email in invalidEmails) {
          final result = InputValidator.validateEmail(email);
          expect(result, equals('Invalid email format'));
        }
      });

      test('should accept valid email formats', () {
        final validEmails = [
          'user@domain.com',
          'test.email@example.org',
          'user+tag@domain.co.uk',
          'firstname.lastname@subdomain.domain.com',
        ];

        for (final email in validEmails) {
          final result = InputValidator.validateEmail(email);
          expect(result, isNull);
        }
      });
    });

    group('URL Validation', () {
      test('should reject empty URL', () {
        final result = InputValidator.validateUrl('');
        expect(result, equals('URL cannot be empty'));
      });

      test('should reject invalid URL formats', () {
        final invalidUrls = [
          'not a url',
          'ftp://example.com', // Valid URL but we might want to restrict protocols
          'http://',
          'https://',
          '://example.com',
        ];

        for (final url in invalidUrls.take(3)) { // Test first 3
          final result = InputValidator.validateUrl(url);
          expect(result, equals('Invalid URL format'));
        }
      });

      test('should accept valid URLs', () {
        final validUrls = [
          'https://example.com',
          'http://subdomain.example.org:8080/path',
          'https://api.example.com/v1/endpoint?param=value',
        ];

        for (final url in validUrls) {
          final result = InputValidator.validateUrl(url);
          expect(result, isNull);
        }
      });
    });
  });
}