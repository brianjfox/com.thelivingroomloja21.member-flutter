import 'package:json_annotation/json_annotation.dart';

part 'item.g.dart';

@JsonSerializable()
class Item {
  final int id;
  final String code;
  final String name;
  @JsonKey(name: 'display_name')
  final String? displayName;
  final String description;
  @JsonKey(fromJson: _doubleFromJson)
  final double cost;
  @JsonKey(fromJson: _doubleFromJson)
  final double price;
  @JsonKey(name: 'is_alcohol', fromJson: _boolFromJson)
  final bool isAlcohol;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  @JsonKey(name: 'on_hand', fromJson: _intFromJson)
  final int? onHand;
  final String? tags;
  final String? barcode;

  const Item({
    required this.id,
    required this.code,
    required this.name,
    this.displayName,
    required this.description,
    required this.cost,
    required this.price,
    required this.isAlcohol,
    required this.createdAt,
    required this.updatedAt,
    this.onHand,
    this.tags,
    this.barcode,
  });

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);
  Map<String, dynamic> toJson() => _$ItemToJson(this);

  String get displayNameOrName => displayName ?? name;

  // Helper functions for type conversion
  static double _doubleFromJson(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  static int? _intFromJson(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value);
    return null;
  }

  static bool _boolFromJson(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false;
  }
}
