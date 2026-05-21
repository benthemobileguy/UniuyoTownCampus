// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reminder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ReminderImpl _$$ReminderImplFromJson(Map<String, dynamic> json) =>
    _$ReminderImpl(
      id: json['id'] as String,
      buildingId: json['buildingId'] as String,
      buildingDisplayName: json['buildingDisplayName'] as String,
      scheduledDateTime: DateTime.parse(json['scheduledDateTime'] as String),
      notificationId: (json['notificationId'] as num).toInt(),
      isActive: json['isActive'] as bool,
      message: json['message'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$ReminderImplToJson(_$ReminderImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'buildingId': instance.buildingId,
      'buildingDisplayName': instance.buildingDisplayName,
      'scheduledDateTime': instance.scheduledDateTime.toIso8601String(),
      'notificationId': instance.notificationId,
      'isActive': instance.isActive,
      'message': instance.message,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
