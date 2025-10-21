// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meeting.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class MeetingAdapter extends TypeAdapter<Meeting> {
  @override
  final int typeId = 10;

  @override
  Meeting read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Meeting(
      meetingId: fields[0] as String,
      title: fields[1] as String,
      sessionIds: (fields[2] as List).cast<String>(),
      isOpen: fields[3] as bool,
      createdAt: fields[4] as DateTime,
      endsAt: fields[5] as DateTime?,
      shortCode: fields[6] as String,
      jwtKeyId: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Meeting obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.meetingId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.sessionIds)
      ..writeByte(3)
      ..write(obj.isOpen)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.endsAt)
      ..writeByte(6)
      ..write(obj.shortCode)
      ..writeByte(7)
      ..write(obj.jwtKeyId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MeetingAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
