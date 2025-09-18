// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
  id: (json['id'] as num).toInt(),
  code: json['code'] as String,
  name: json['name'] as String,
  displayName: json['display_name'] as String?,
  description: json['description'] as String,
  cost: Item._doubleFromJson(json['cost']),
  price: Item._doubleFromJson(json['price']),
  isAlcohol: Item._boolFromJson(json['is_alcohol']),
  createdAt: json['created_at'] as String,
  updatedAt: json['updated_at'] as String,
  onHand: Item._intFromJson(json['on_hand']),
  tags: json['tags'] as String?,
  barcode: json['barcode'] as String?,
);

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
  'id': instance.id,
  'code': instance.code,
  'name': instance.name,
  'display_name': instance.displayName,
  'description': instance.description,
  'cost': instance.cost,
  'price': instance.price,
  'is_alcohol': instance.isAlcohol,
  'created_at': instance.createdAt,
  'updated_at': instance.updatedAt,
  'on_hand': instance.onHand,
  'tags': instance.tags,
  'barcode': instance.barcode,
};
