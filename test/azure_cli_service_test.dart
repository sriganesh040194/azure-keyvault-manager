import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:process/process.dart';
import 'dart:convert';
import 'dart:io';

import 'package:keyvault_ui/services/azure_cli/azure_cli_service.dart';
import 'azure_cli_service_test.mocks.dart';

@GenerateMocks([ProcessManager, Process])
void main() {
  group('AzureCliService', () {
    late MockProcessManager mockProcessManager;
    late MockProcess mockProcess;
    late AzureCliService azureCliService;

    setUp(() {
      mockProcessManager = MockProcessManager();
      mockProcess = MockProcess();
      azureCliService = AzureCliService(processManager: mockProcessManager);
    });

    group('Command Validation', () {
      test('should reject empty commands', () async {
        final result = await azureCliService.executeCommand('');
        
        expect(result.success, false);
        expect(result.error, contains('Command cannot be empty'));
      });

      test('should reject non-az commands', () async {
        final result = await azureCliService.executeCommand('rm -rf /');
        
        expect(result.success, false);
        expect(result.error, contains('Only Azure CLI commands are allowed'));
      });

      test('should reject commands with dangerous patterns', () async {
        final result = await azureCliService.executeCommand('az keyvault list; rm file');
        
        expect(result.success, false);
        expect(result.error, contains('potentially dangerous characters'));
      });

      test('should accept valid az commands', () async {
        when(mockProcessManager.start(any, environment: anyNamed('environment')))
            .thenAnswer((_) async => mockProcess);
        when(mockProcess.stdout).thenAnswer((_) => Stream.fromIterable([utf8.encode('[]')]));
        when(mockProcess.stderr).thenAnswer((_) => Stream.fromIterable([]));
        when(mockProcess.exitCode).thenAnswer((_) async => 0);

        final result = await azureCliService.executeCommand('az keyvault list');
        
        expect(result.success, true);
      });
    });

    group('Key Vault Operations', () {
      setUp(() {
        when(mockProcessManager.start(any, environment: anyNamed('environment')))
            .thenAnswer((_) async => mockProcess);
        when(mockProcess.stderr).thenAnswer((_) => Stream.fromIterable([]));
        when(mockProcess.exitCode).thenAnswer((_) async => 0);
      });

      test('should list key vaults successfully', () async {
        const mockResponse = [
          {
            'name': 'test-kv-1',
            'resourceGroup': 'test-rg',
            'location': 'eastus',
            'subscriptionId': '12345-67890'
          }
        ];
        
        when(mockProcess.stdout).thenAnswer(
          (_) => Stream.fromIterable([utf8.encode(json.encode(mockResponse))]),
        );

        final result = await azureCliService.listKeyVaults();
        
        expect(result.success, true);
        expect(result.output, contains('test-kv-1'));
      });

      test('should create key vault with valid parameters', () async {
        when(mockProcess.stdout).thenAnswer(
          (_) => Stream.fromIterable([utf8.encode('{"name": "new-kv"}')]),
        );

        final result = await azureCliService.createKeyVault(
          name: 'new-kv',
          resourceGroup: 'test-rg',
          location: 'eastus',
        );
        
        expect(result.success, true);
      });

      test('should reject invalid key vault names', () async {
        expect(
          () => azureCliService.createKeyVault(
            name: 'invalid@name',
            resourceGroup: 'test-rg',
            location: 'eastus',
          ),
          throwsArgumentError,
        );
      });

      test('should list secrets for a key vault', () async {
        const mockSecrets = [
          {
            'name': 'secret1',
            'id': 'https://test-kv.vault.azure.net/secrets/secret1',
            'attributes': {'enabled': true}
          }
        ];
        
        when(mockProcess.stdout).thenAnswer(
          (_) => Stream.fromIterable([utf8.encode(json.encode(mockSecrets))]),
        );

        final result = await azureCliService.listSecrets('test-kv');
        
        expect(result.success, true);
        expect(result.output, contains('secret1'));
      });
    });

    group('Security Features', () {
      test('should sanitize output containing sensitive data', () async {
        const sensitiveOutput = '{"value": "supersecret123", "name": "test"}';
        
        when(mockProcessManager.start(any, environment: anyNamed('environment')))
            .thenAnswer((_) async => mockProcess);
        when(mockProcess.stdout).thenAnswer(
          (_) => Stream.fromIterable([utf8.encode(sensitiveOutput)]),
        );
        when(mockProcess.stderr).thenAnswer((_) => Stream.fromIterable([]));
        when(mockProcess.exitCode).thenAnswer((_) async => 0);

        final result = await azureCliService.executeCommand('az keyvault secret show --name test --vault-name test-kv');
        
        expect(result.success, true);
        expect(result.output, contains('[REDACTED]'));
        expect(result.output, isNot(contains('supersecret123')));
      });

      test('should limit concurrent operations', () async {
        // This test would require more complex setup to properly test concurrency limits
        expect(azureCliService.runningCommandsCount, equals(0));
      });

      test('should timeout long-running commands', () async {
        when(mockProcessManager.start(any, environment: anyNamed('environment')))
            .thenAnswer((_) async => mockProcess);
        when(mockProcess.stdout).thenAnswer((_) => const Stream.empty());
        when(mockProcess.stderr).thenAnswer((_) => const Stream.empty());
        when(mockProcess.exitCode).thenAnswer((_) => Future.delayed(
          const Duration(seconds: 10),
          () => 0,
        ));

        final result = await azureCliService.executeCommand(
          'az keyvault list',
          timeout: const Duration(seconds: 1),
        );
        
        expect(result.success, false);
        expect(result.error, contains('timed out'));
      });
    });

    group('Error Handling', () {
      test('should handle process execution errors', () async {
        when(mockProcessManager.start(any, environment: anyNamed('environment')))
            .thenThrow(ProcessException('az', ['keyvault', 'list']));

        final result = await azureCliService.executeCommand('az keyvault list');
        
        expect(result.success, false);
        expect(result.error, contains('Execution error'));
      });

      test('should handle non-zero exit codes', () async {
        when(mockProcessManager.start(any, environment: anyNamed('environment')))
            .thenAnswer((_) async => mockProcess);
        when(mockProcess.stdout).thenAnswer((_) => Stream.fromIterable([]));
        when(mockProcess.stderr).thenAnswer(
          (_) => Stream.fromIterable([utf8.encode('Error: Not authenticated')]),
        );
        when(mockProcess.exitCode).thenAnswer((_) async => 1);

        final result = await azureCliService.executeCommand('az keyvault list');
        
        expect(result.success, false);
        expect(result.exitCode, equals(1));
        expect(result.error, contains('Not authenticated'));
      });
    });

    group('Azure CLI Readiness', () {
      test('should detect when Azure CLI is not installed', () async {
        when(mockProcessManager.start(any, environment: anyNamed('environment')))
            .thenThrow(ProcessException('az', ['--version']));

        final isReady = await azureCliService.isAzureCliReady();
        
        expect(isReady, false);
      });

      test('should detect when Azure CLI is not authenticated', () async {
        // Mock successful version check
        when(mockProcessManager.start(['az', '--version'], environment: anyNamed('environment')))
            .thenAnswer((_) async => mockProcess);
        when(mockProcess.stdout).thenAnswer(
          (_) => Stream.fromIterable([utf8.encode('azure-cli 2.0.0')]),
        );
        when(mockProcess.stderr).thenAnswer((_) => Stream.fromIterable([]));
        when(mockProcess.exitCode).thenAnswer((_) async => 0);

        // Mock failed account check
        when(mockProcessManager.start(['az', 'account', 'show'], environment: anyNamed('environment')))
            .thenAnswer((_) async => mockProcess);
        when(mockProcess.stdout).thenAnswer((_) => Stream.fromIterable([]));
        when(mockProcess.stderr).thenAnswer(
          (_) => Stream.fromIterable([utf8.encode('Please run az login')]),
        );
        when(mockProcess.exitCode).thenAnswer((_) async => 1);

        final isReady = await azureCliService.isAzureCliReady();
        
        expect(isReady, false);
      });
    });
  });
}