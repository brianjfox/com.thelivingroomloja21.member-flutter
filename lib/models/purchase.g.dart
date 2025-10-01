// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Purchase _$PurchaseFromJson(Map<String, dynamic> json) => Purchase(
  id: Purchase._intFromJson(json['id']),
  userEmail: json['user_email'] as String,
  itemId: Purchase._intFromJson(json['item_id']),
  priceAsked: Purchase._doubleFromJson(json['price_asked']),
  pricePaid: Purchase._doubleFromJson(json['price_paid']),
  purchasedOn: json['purchased_on'] as String,
  settled: Purchase._boolFromJson(json['settled']),
  settledOn: json['settled_on'] as String?,
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  code: json['code'] as String?,
  name: json['name'] as String?,
  description: json['description'] as String?,
  fname: json['fname'] as String?,
  lname: json['lname'] as String?,
  phone: json['phone'] as String?,
  item: json['item'] == null
      ? null
      : Item.fromJson(json['item'] as Map<String, dynamic>),
  user: json['user'] == null
      ? null
      : User.fromJson(json['user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PurchaseToJson(Purchase instance) => <String, dynamic>{
  'id': instance.id,
  'user_email': instance.userEmail,
  'item_id': instance.itemId,
  'price_asked': instance.priceAsked,
  'price_paid': instance.pricePaid,
  'purchased_on': instance.purchasedOn,
  'settled_on': instance.settledOn,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'code': instance.code,
  'name': instance.name,
  'description': instance.description,
  'fname': instance.fname,
  'lname': instance.lname,
  'phone': instance.phone,
  'item': instance.item,
  'user': instance.user,
};
