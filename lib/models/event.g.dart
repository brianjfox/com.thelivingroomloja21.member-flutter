// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'event.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Event _$EventFromJson(Map<String, dynamic> json) => Event(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  startingAt: json['starting_at'] as String,
  endingAt: json['ending_at'] as String,
  description: json['description'] as String,
  eventType: $enumDecode(_$EventTypeEnumMap, json['event_type']),
  eventOther: json['event_other'] as String?,
  organizer: json['organizer'] as String,
  cost: Event._doubleFromJson(json['cost']),
  price: Event._doubleFromJson(json['price']),
  fname: json['fname'] as String?,
  lname: json['lname'] as String?,
  organizerUser: json['organizer_user'] == null
      ? null
      : User.fromJson(json['organizer_user'] as Map<String, dynamic>),
);

Map<String, dynamic> _$EventToJson(Event instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'starting_at': instance.startingAt,
  'ending_at': instance.endingAt,
  'description': instance.description,
  'event_type': _$EventTypeEnumMap[instance.eventType]!,
  'event_other': instance.eventOther,
  'organizer': instance.organizer,
  'cost': instance.cost,
  'price': instance.price,
  'fname': instance.fname,
  'lname': instance.lname,
  'organizer_user': instance.organizerUser,
};

const _$EventTypeEnumMap = {
  EventType.music: 'music',
  EventType.poetry: 'poetry',
  EventType.lecture: 'lecture',
  EventType.dinner: 'dinner',
  EventType.party: 'party',
  EventType.snooker: 'snooker',
  EventType.other: 'other',
};

EventAttendance _$EventAttendanceFromJson(Map<String, dynamic> json) =>
    EventAttendance(
      userEmail: json['user_email'] as String,
      eventId: (json['event_id'] as num).toInt(),
      status: $enumDecode(_$AttendanceStatusEnumMap, json['status']),
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );

Map<String, dynamic> _$EventAttendanceToJson(EventAttendance instance) =>
    <String, dynamic>{
      'user_email': instance.userEmail,
      'event_id': instance.eventId,
      'status': _$AttendanceStatusEnumMap[instance.status]!,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
    };

const _$AttendanceStatusEnumMap = {
  AttendanceStatus.interested: 'interested',
  AttendanceStatus.notInterested: 'not_interested',
  AttendanceStatus.maybe: 'maybe',
  AttendanceStatus.definitely: 'definitely',
  AttendanceStatus.attended: 'attended',
};
