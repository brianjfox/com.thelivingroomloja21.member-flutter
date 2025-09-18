import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String email;
  final String fname;
  final String lname;
  final String dob;
  final String phone;
  final String nif;
  final String address;
  final String status;
  @JsonKey(name: 'is_admin', fromJson: _boolFromInt, toJson: _boolToInt)
  final bool isAdmin;
  @JsonKey(name: 'language_pref')
  final String languagePref;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const User({
    required this.email,
    required this.fname,
    required this.lname,
    required this.dob,
    required this.phone,
    required this.nif,
    required this.address,
    required this.status,
    required this.isAdmin,
    required this.languagePref,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String get fullName => '$fname $lname';

  // Helper functions for boolean conversion
  static bool _boolFromInt(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }

  static int _boolToInt(bool value) => value ? 1 : 0;
}
