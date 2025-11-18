/// Service for checking app updates from GitHub releases
library;

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:azure_key_vault_manager/services/update/update_models.dart';
import 'package:azure_key_vault_manager/core/logging/app_logger.dart';

/// Service for checking and managing app updates
class UpdateService {
  final String githubOwner;
  final String githubRepo;

  const UpdateService({
    required this.githubOwner,
    required this.githubRepo,
  });

  /// Checks if an update is available
  Future<UpdateCheckResult> checkForUpdates() async {
    try {
      // Get current app version
      final packageInfo = await PackageInfo.fromPlatform();
      final currentVersion = packageInfo.version;

      AppLogger.info('Checking for updates. Current version: $currentVersion');

      // Fetch latest release from GitHub
      final latestRelease = await _fetchLatestRelease();

      if (latestRelease == null) {
        AppLogger.warning('No releases found on GitHub');
        return UpdateCheckResult.noUpdate(currentVersion);
      }

      // Parse release info
      final updateInfo = UpdateInfo.fromGitHubRelease(latestRelease);

      AppLogger.info('Latest version on GitHub: ${updateInfo.version}');

      // Compare versions
      final comparison = _compareVersions(currentVersion, updateInfo.cleanVersion);

      if (comparison.isNewer) {
        AppLogger.info('Update available: ${updateInfo.version}');
        return UpdateCheckResult.updateAvailable(
          updateInfo: updateInfo,
          currentVersion: currentVersion,
        );
      } else {
        AppLogger.info('App is up to date');
        return UpdateCheckResult.noUpdate(currentVersion);
      }
    } catch (e) {
      AppLogger.error('Error checking for updates: $e');
      return UpdateCheckResult.error(
        currentVersion: await _getCurrentVersion(),
        error: e.toString(),
      );
    }
  }

  /// Fetches the latest release from GitHub API
  Future<Map<String, dynamic>?> _fetchLatestRelease() async {
    final url = Uri.parse(
      'https://api.github.com/repos/$githubOwner/$githubRepo/releases/latest',
    );

    try {
      final response = await http.get(
        url,
        headers: {
          'Accept': 'application/vnd.github.v3+json',
          'User-Agent': 'Azure-Key-Vault-Manager',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Request timed out');
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return json;
      } else if (response.statusCode == 404) {
        // No releases found
        AppLogger.warning('No releases found (404)');
        return null;
      } else {
        throw Exception(
          'GitHub API error: ${response.statusCode} - ${response.body}',
        );
      }
    } catch (e) {
      AppLogger.error('Error fetching latest release: $e');
      rethrow;
    }
  }

  /// Gets the current app version
  Future<String> _getCurrentVersion() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      return packageInfo.version;
    } catch (e) {
      AppLogger.error('Error getting current version: $e');
      return '0.0.0';
    }
  }

  /// Compares two version strings
  /// Returns: -1 if current < latest, 0 if equal, 1 if current > latest
  VersionComparison _compareVersions(String current, String latest) {
    try {
      // Clean version strings (remove 'v' prefix if present)
      final currentClean = current.startsWith('v') ? current.substring(1) : current;
      final latestClean = latest.startsWith('v') ? latest.substring(1) : latest;

      // Split into parts
      final currentParts = currentClean.split('.').map(int.parse).toList();
      final latestParts = latestClean.split('.').map(int.parse).toList();

      // Ensure both have at least 3 parts (major.minor.patch)
      while (currentParts.length < 3) {
        currentParts.add(0);
      }
      while (latestParts.length < 3) {
        latestParts.add(0);
      }

      // Compare each part
      for (var i = 0; i < 3; i++) {
        if (currentParts[i] < latestParts[i]) {
          return const VersionComparison(-1); // Update available
        } else if (currentParts[i] > latestParts[i]) {
          return const VersionComparison(1); // Current is newer
        }
      }

      return const VersionComparison(0); // Equal
    } catch (e) {
      AppLogger.error('Error comparing versions: $e');
      // On error, assume no update to be safe
      return const VersionComparison(0);
    }
  }

  /// Gets the current app version as a string
  Future<String> getCurrentVersion() async {
    return _getCurrentVersion();
  }

  /// Gets information about the latest release without checking if it's newer
  Future<UpdateInfo?> getLatestReleaseInfo() async {
    try {
      final latestRelease = await _fetchLatestRelease();
      if (latestRelease == null) return null;
      return UpdateInfo.fromGitHubRelease(latestRelease);
    } catch (e) {
      AppLogger.error('Error getting latest release info: $e');
      return null;
    }
  }
}
