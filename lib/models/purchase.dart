import 'package:json_annotation/json_annotation.dart';
import 'user.dart';
import 'item.dart';

part 'purchase.g.dart';

@JsonSerializable()
class Purchase {
  @JsonKey(fromJson: _intFromJson)
  final int id;
  @JsonKey(name: 'user_email')
  final String userEmail;
  @JsonKey(name: 'item_id', fromJson: _intFromJson)
  final int itemId;
  @JsonKey(name: 'price_asked', fromJson: _doubleFromJson)
  final double priceAsked;
  @JsonKey(name: 'price_paid', fromJson: _doubleFromJson)
  final double pricePaid;
  @JsonKey(name: 'purchased_on')
  final String purchasedOn;
  @JsonKey(fromJson: _boolFromJson, includeToJson: false)
  final bool settled;
  @JsonKey(name: 'settled_on')
  final String? settledOn;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;
  
  // Item details returned directly from API
  final String? code;
  final String? name;
  final String? description;
  
  // User details returned directly from API
  final String? fname;
  final String? lname;
  final String? phone;
  
  // Legacy nested properties for backward compatibility
  final Item? item;
  final User? user;

  const Purchase({
    required this.id,
    required this.userEmail,
    required this.itemId,
    required this.priceAsked,
    required this.pricePaid,
    required this.purchasedOn,
    required this.settled,
    this.settledOn,
    required this.createdAt,
    required this.updatedAt,
    this.code,
    this.name,
    this.description,
    this.fname,
    this.lname,
    this.phone,
    this.item,
    this.user,
  });

  factory Purchase.fromJson(Map<String, dynamic> json) {
    // Compute settled status from settled_on field
    final settledOn = json['settled_on'] as String?;
    final settled = settledOn != null && settledOn.isNotEmpty;
    
    // Create a modified json with the computed settled field
    final modifiedJson = Map<String, dynamic>.from(json);
    modifiedJson['settled'] = settled;
    
    return _$PurchaseFromJson(modifiedJson);
  }
  
  Map<String, dynamic> toJson() => _$PurchaseToJson(this);

  String get itemName => name ?? item?.name ?? 'Unknown Item';
  String get userName => fname != null && lname != null ? '$fname $lname' : user?.fullName ?? 'Unknown User';

  static bool _boolFromJson(dynamic value) {
    if (value is bool) return value;
    if (value is int) return value == 1;
    if (value is String) return value == '1' || value.toLowerCase() == 'true';
    return false; // Default to false for null or other types
  }

  static int _intFromJson(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0; // Default to 0 for null or other types
  }

  static double _doubleFromJson(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0; // Default to 0.0 for null or other types
  }
}
