// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
  email: json['email'] as String,
  fname: json['fname'] as String,
  lname: json['lname'] as String,
  dob: json['dob'] as String,
  phone: json['phone'] as String,
  nif: json['nif'] as String,
  address: json['address'] as String,
  status: json['status'] as String,
  isAdmin: User._boolFromInt(json['is_admin']),
  languagePref: json['language_pref'] as String,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
);

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'email': instance.email,
  'fname': instance.fname,
  'lname': instance.lname,
  'dob': instance.dob,
  'phone': instance.phone,
  'nif': instance.nif,
  'address': instance.address,
  'status': instance.status,
  'is_admin': User._boolToInt(instance.isAdmin),
  'language_pref': instance.languagePref,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
};
