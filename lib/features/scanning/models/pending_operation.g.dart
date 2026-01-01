// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pending_operation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PendingOperation _$PendingOperationFromJson(Map<String, dynamic> json) =>
    PendingOperation(
      id: json['id'] as String,
      operationType: json['operationType'] as String,
      sessionId: json['sessionId'] as String?,
      errorContext: ErrorContext.fromJson(
        json['errorContext'] as Map<String, dynamic>,
      ),
      queuedAt: DateTime.parse(json['queuedAt'] as String),
      retryCount: (json['retryCount'] as num).toInt(),
    );

Map<String, dynamic> _$PendingOperationToJson(PendingOperation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'operationType': instance.operationType,
      'sessionId': instance.sessionId,
      'errorContext': instance.errorContext.toJson(),
      'queuedAt': instance.queuedAt.toIso8601String(),
      'retryCount': instance.retryCount,
    };
