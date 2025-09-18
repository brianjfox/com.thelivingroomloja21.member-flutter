// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'purchase.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Purchase _$PurchaseFromJson(Map<String, dynamic> json) => Purchase(
  id: (json['id'] as num).toInt(),
  userEmail: json['user_email'] as String,
  itemId: (json['item_id'] as num).toInt(),
  priceAsked: (json['price_asked'] as num).toDouble(),
  pricePaid: (json['price_paid'] as num).toDouble(),
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
  'settled': instance.settled,
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
