/// Models for app update functionality
library;

import 'package:json_annotation/json_annotation.dart';

part 'update_models.g.dart';

/// Represents information about an available update
@JsonSerializable()
class UpdateInfo {
  /// The version string (e.g., "1.0.0", "v1.0.0")
  final String version;

  /// The release notes/changelog
  final String? releaseNotes;

  /// The download URL for the release
  final String downloadUrl;

  /// The release date
  final DateTime? releaseDate;

  /// The tag name from GitHub (usually same as version)
  final String tagName;

  /// Whether this is a prerelease
  final bool isPrerelease;

  const UpdateInfo({
    required this.version,
    this.releaseNotes,
    required this.downloadUrl,
    this.releaseDate,
    required this.tagName,
    this.isPrerelease = false,
  });

  /// Creates an UpdateInfo from JSON
  factory UpdateInfo.fromJson(Map<String, dynamic> json) =>
      _$UpdateInfoFromJson(json);

  /// Converts to JSON
  Map<String, dynamic> toJson() => _$UpdateInfoToJson(this);

  /// Creates an UpdateInfo from GitHub API release response
  factory UpdateInfo.fromGitHubRelease(Map<String, dynamic> json) {
    final tagName = json['tag_name'] as String? ?? '';
    // Remove 'v' prefix if present
    final version = tagName.startsWith('v') ? tagName.substring(1) : tagName;

    return UpdateInfo(
      version: version,
      tagName: tagName,
      releaseNotes: json['body'] as String?,
      downloadUrl: json['html_url'] as String? ?? '',
      releaseDate: json['published_at'] != null
          ? DateTime.tryParse(json['published_at'] as String)
          : null,
      isPrerelease: json['prerelease'] as bool? ?? false,
    );
  }

  /// Gets a clean version string (normalized, no 'v' prefix)
  String get cleanVersion {
    return version.startsWith('v') ? version.substring(1) : version;
  }
}

/// Result of an update check operation
class UpdateCheckResult {
  /// Whether an update is available
  final bool updateAvailable;

  /// Information about the update (null if no update available)
  final UpdateInfo? updateInfo;

  /// Current version of the app
  final String currentVersion;

  /// Error message if the check failed
  final String? error;

  const UpdateCheckResult({
    required this.updateAvailable,
    this.updateInfo,
    required this.currentVersion,
    this.error,
  });

  /// Creates a result indicating no update is available
  factory UpdateCheckResult.noUpdate(String currentVersion) {
    return UpdateCheckResult(
      updateAvailable: false,
      currentVersion: currentVersion,
    );
  }

  /// Creates a result indicating an update is available
  factory UpdateCheckResult.updateAvailable({
    required UpdateInfo updateInfo,
    required String currentVersion,
  }) {
    return UpdateCheckResult(
      updateAvailable: true,
      updateInfo: updateInfo,
      currentVersion: currentVersion,
    );
  }

  /// Creates a result indicating an error occurred
  factory UpdateCheckResult.error({
    required String currentVersion,
    required String error,
  }) {
    return UpdateCheckResult(
      updateAvailable: false,
      currentVersion: currentVersion,
      error: error,
    );
  }

  /// Whether the check was successful (no error)
  bool get isSuccess => error == null;
}

/// Represents version comparison result
class VersionComparison {
  /// -1 if current < latest, 0 if equal, 1 if current > latest
  final int result;

  const VersionComparison(this.result);

  bool get isNewer => result < 0;
  bool get isEqual => result == 0;
  bool get isOlder => result > 0;
}
