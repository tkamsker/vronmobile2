// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'error_context.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ErrorContext _$ErrorContextFromJson(Map<String, dynamic> json) => ErrorContext(
  timestamp: DateTime.parse(json['timestamp'] as String),
  sessionId: json['sessionId'] as String?,
  httpStatus: (json['httpStatus'] as num?)?.toInt(),
  errorCode: json['errorCode'] as String?,
  message: json['message'] as String,
  technicalMessage: json['technicalMessage'] as String?,
  retryCount: (json['retryCount'] as num).toInt(),
  userId: json['userId'] as String?,
  stackTrace: json['stackTrace'] as String?,
  isRecoverable: json['isRecoverable'] as bool,
);

Map<String, dynamic> _$ErrorContextToJson(ErrorContext instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp.toIso8601String(),
      'sessionId': instance.sessionId,
      'httpStatus': instance.httpStatus,
      'errorCode': instance.errorCode,
      'message': instance.message,
      'technicalMessage': instance.technicalMessage,
      'retryCount': instance.retryCount,
      'userId': instance.userId,
      'stackTrace': instance.stackTrace,
      'isRecoverable': instance.isRecoverable,
    };
