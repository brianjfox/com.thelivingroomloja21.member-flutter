// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'auth.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthResponse _$AuthResponseFromJson(Map<String, dynamic> json) => AuthResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: AuthData.fromJson(json['data'] as Map<String, dynamic>),
  revoked: json['revoked'] as bool?,
);

Map<String, dynamic> _$AuthResponseToJson(AuthResponse instance) =>
    <String, dynamic>{
      'success': instance.success,
      'message': instance.message,
      'data': instance.data,
      'revoked': instance.revoked,
    };

AuthData _$AuthDataFromJson(Map<String, dynamic> json) => AuthData(
  user: User.fromJson(json['user'] as Map<String, dynamic>),
  token: json['token'] as String,
  newEnrollmentToken: json['newEnrollmentToken'] as String?,
);

Map<String, dynamic> _$AuthDataToJson(AuthData instance) => <String, dynamic>{
  'user': instance.user,
  'token': instance.token,
  'newEnrollmentToken': instance.newEnrollmentToken,
};

BiometricEnrollmentRequest _$BiometricEnrollmentRequestFromJson(
  Map<String, dynamic> json,
) => BiometricEnrollmentRequest(
  email: json['email'] as String,
  password: json['password'] as String,
);

Map<String, dynamic> _$BiometricEnrollmentRequestToJson(
  BiometricEnrollmentRequest instance,
) => <String, dynamic>{'email': instance.email, 'password': instance.password};

BiometricEnrollmentResponse _$BiometricEnrollmentResponseFromJson(
  Map<String, dynamic> json,
) => BiometricEnrollmentResponse(
  success: json['success'] as bool,
  message: json['message'] as String,
  data: BiometricEnrollmentData.fromJson(json['data'] as Map<String, dynamic>),
);

Map<String, dynamic> _$BiometricEnrollmentResponseToJson(
  BiometricEnrollmentResponse instance,
) => <String, dynamic>{
  'success': instance.success,
  'message': instance.message,
  'data': instance.data,
};

BiometricEnrollmentData _$BiometricEnrollmentDataFromJson(
  Map<String, dynamic> json,
) =>
    BiometricEnrollmentData(enrollmentToken: json['enrollmentToken'] as String);

Map<String, dynamic> _$BiometricEnrollmentDataToJson(
  BiometricEnrollmentData instance,
) => <String, dynamic>{'enrollmentToken': instance.enrollmentToken};

BiometricAuthRequest _$BiometricAuthRequestFromJson(
  Map<String, dynamic> json,
) => BiometricAuthRequest(
  email: json['email'] as String,
  enrollmentToken: json['enrollmentToken'] as String,
  deviceId: json['deviceId'] as String,
  platform: json['platform'] as String,
);

Map<String, dynamic> _$BiometricAuthRequestToJson(
  BiometricAuthRequest instance,
) => <String, dynamic>{
  'email': instance.email,
  'enrollmentToken': instance.enrollmentToken,
  'deviceId': instance.deviceId,
  'platform': instance.platform,
};
