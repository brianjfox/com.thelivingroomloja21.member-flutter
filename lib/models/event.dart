import 'package:json_annotation/json_annotation.dart';
import 'user.dart';

part 'event.g.dart';

enum EventType {
  @JsonValue('music')
  music,
  @JsonValue('poetry')
  poetry,
  @JsonValue('lecture')
  lecture,
  @JsonValue('dinner')
  dinner,
  @JsonValue('party')
  party,
  @JsonValue('snooker')
  snooker,
  @JsonValue('other')
  other,
}

enum AttendanceStatus {
  @JsonValue('interested')
  interested,
  @JsonValue('not_interested')
  notInterested,
  @JsonValue('maybe')
  maybe,
  @JsonValue('definitely')
  definitely,
  @JsonValue('attended')
  attended,
}

@JsonSerializable()
class Event {
  final int id;
  final String name;
  @JsonKey(name: 'starting_at')
  final String startingAt;
  @JsonKey(name: 'ending_at')
  final String endingAt;
  final String description;
  @JsonKey(name: 'event_type')
  final EventType eventType;
  @JsonKey(name: 'event_other')
  final String? eventOther;
  final String organizer; // user email
  @JsonKey(fromJson: _doubleFromJson)
  final double? cost; // only visible to admins
  @JsonKey(fromJson: _doubleFromJson)
  final double? price; // suggested donation
  final String? fname; // organizer's first name
  final String? lname; // organizer's last name
  @JsonKey(name: 'organizer_user')
  final User? organizerUser;

  const Event({
    required this.id,
    required this.name,
    required this.startingAt,
    required this.endingAt,
    required this.description,
    required this.eventType,
    this.eventOther,
    required this.organizer,
    this.cost,
    this.price,
    this.fname,
    this.lname,
    this.organizerUser,
  });

  factory Event.fromJson(Map<String, dynamic> json) => _$EventFromJson(json);
  Map<String, dynamic> toJson() => _$EventToJson(this);

  String get organizerName => fname != null && lname != null ? '$fname $lname' : organizerUser?.fullName ?? organizer;
  String get eventTypeDisplay => eventType == EventType.other ? (eventOther ?? 'Other') : eventType.name;

  static double? _doubleFromJson(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }
}

@JsonSerializable()
class EventAttendance {
  @JsonKey(name: 'user_email')
  final String userEmail;
  @JsonKey(name: 'event_id')
  final int eventId;
  final AttendanceStatus status;
  @JsonKey(name: 'created_at')
  final String createdAt;
  @JsonKey(name: 'updated_at')
  final String updatedAt;

  const EventAttendance({
    required this.userEmail,
    required this.eventId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory EventAttendance.fromJson(Map<String, dynamic> json) => _$EventAttendanceFromJson(json);
  Map<String, dynamic> toJson() => _$EventAttendanceToJson(this);
}
