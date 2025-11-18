/// Storage service for update preferences
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:azure_key_vault_manager/core/logging/app_logger.dart';

/// Service for persisting update-related preferences
class UpdateStorage {
  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
    webOptions: WebOptions(
      dbName: 'keyvault_ui_updates',
      publicKey: 'keyvault_ui_updates_key',
    ),
  );

  // Storage keys
  static const String _skippedVersionKey = 'skipped_update_version';
  static const String _lastCheckTimeKey = 'last_update_check_time';

  /// Gets the version that the user chose to skip
  Future<String?> getSkippedVersion() async {
    try {
      return await _storage.read(key: _skippedVersionKey);
    } catch (e) {
      AppLogger.error('Error reading skipped version: $e');
      return null;
    }
  }

  /// Saves the version that the user wants to skip
  Future<void> setSkippedVersion(String version) async {
    try {
      await _storage.write(key: _skippedVersionKey, value: version);
      AppLogger.info('Skipped version set to: $version');
    } catch (e) {
      AppLogger.error('Error saving skipped version: $e');
    }
  }

  /// Clears the skipped version preference
  Future<void> clearSkippedVersion() async {
    try {
      await _storage.delete(key: _skippedVersionKey);
      AppLogger.info('Skipped version cleared');
    } catch (e) {
      AppLogger.error('Error clearing skipped version: $e');
    }
  }

  /// Gets the timestamp of the last update check
  Future<DateTime?> getLastCheckTime() async {
    try {
      final timestamp = await _storage.read(key: _lastCheckTimeKey);
      if (timestamp == null) return null;
      return DateTime.tryParse(timestamp);
    } catch (e) {
      AppLogger.error('Error reading last check time: $e');
      return null;
    }
  }

  /// Saves the timestamp of the last update check
  Future<void> setLastCheckTime(DateTime time) async {
    try {
      await _storage.write(
        key: _lastCheckTimeKey,
        value: time.toIso8601String(),
      );
      AppLogger.info('Last check time updated');
    } catch (e) {
      AppLogger.error('Error saving last check time: $e');
    }
  }

  /// Clears all update-related storage
  Future<void> clearAll() async {
    try {
      await _storage.delete(key: _skippedVersionKey);
      await _storage.delete(key: _lastCheckTimeKey);
      AppLogger.info('All update preferences cleared');
    } catch (e) {
      AppLogger.error('Error clearing update preferences: $e');
    }
  }

  /// Checks if the user has skipped a specific version
  Future<bool> hasSkippedVersion(String version) async {
    final skippedVersion = await getSkippedVersion();
    return skippedVersion == version;
  }
}
