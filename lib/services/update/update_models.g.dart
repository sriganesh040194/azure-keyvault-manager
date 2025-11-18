// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateInfo _$UpdateInfoFromJson(Map<String, dynamic> json) => UpdateInfo(
  version: json['version'] as String,
  releaseNotes: json['releaseNotes'] as String?,
  downloadUrl: json['downloadUrl'] as String,
  releaseDate: json['releaseDate'] == null
      ? null
      : DateTime.parse(json['releaseDate'] as String),
  tagName: json['tagName'] as String,
  isPrerelease: json['isPrerelease'] as bool? ?? false,
);

Map<String, dynamic> _$UpdateInfoToJson(UpdateInfo instance) =>
    <String, dynamic>{
      'version': instance.version,
      'releaseNotes': instance.releaseNotes,
      'downloadUrl': instance.downloadUrl,
      'releaseDate': instance.releaseDate?.toIso8601String(),
      'tagName': instance.tagName,
      'isPrerelease': instance.isPrerelease,
    };
