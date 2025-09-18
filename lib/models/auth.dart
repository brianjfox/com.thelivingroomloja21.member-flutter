import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'auth.g.dart';

@JsonSerializable()
class AuthResponse {
  final bool success;
  final String message;
  final AuthData data;
  final bool? revoked;

  const AuthResponse({
    required this.success,
    required this.message,
    required this.data,
    this.revoked,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => _$AuthResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AuthResponseToJson(this);
}

@JsonSerializable()
class AuthData {
  final User user;
  final String token;
  @JsonKey(name: 'newEnrollmentToken')
  final String? newEnrollmentToken;

  const AuthData({
    required this.user,
    required this.token,
    this.newEnrollmentToken,
  });

  factory AuthData.fromJson(Map<String, dynamic> json) => _$AuthDataFromJson(json);
  Map<String, dynamic> toJson() => _$AuthDataToJson(this);
}

@JsonSerializable()
class BiometricEnrollmentRequest {
  final String email;
  final String password;

  const BiometricEnrollmentRequest({
    required this.email,
    required this.password,
  });

  factory BiometricEnrollmentRequest.fromJson(Map<String, dynamic> json) => _$BiometricEnrollmentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BiometricEnrollmentRequestToJson(this);
}

@JsonSerializable()
class BiometricEnrollmentResponse {
  final bool success;
  final String message;
  final BiometricEnrollmentData data;

  const BiometricEnrollmentResponse({
    required this.success,
    required this.message,
    required this.data,
  });

  factory BiometricEnrollmentResponse.fromJson(Map<String, dynamic> json) => _$BiometricEnrollmentResponseFromJson(json);
  Map<String, dynamic> toJson() => _$BiometricEnrollmentResponseToJson(this);
}

@JsonSerializable()
class BiometricEnrollmentData {
  @JsonKey(name: 'enrollmentToken')
  final String enrollmentToken;

  const BiometricEnrollmentData({
    required this.enrollmentToken,
  });

  factory BiometricEnrollmentData.fromJson(Map<String, dynamic> json) => _$BiometricEnrollmentDataFromJson(json);
  Map<String, dynamic> toJson() => _$BiometricEnrollmentDataToJson(this);
}

@JsonSerializable()
class BiometricAuthRequest {
  final String email;
  @JsonKey(name: 'enrollmentToken')
  final String enrollmentToken;
  @JsonKey(name: 'deviceId')
  final String deviceId;
  final String platform;

  const BiometricAuthRequest({
    required this.email,
    required this.enrollmentToken,
    required this.deviceId,
    required this.platform,
  });

  factory BiometricAuthRequest.fromJson(Map<String, dynamic> json) => _$BiometricAuthRequestFromJson(json);
  Map<String, dynamic> toJson() => _$BiometricAuthRequestToJson(this);
}
