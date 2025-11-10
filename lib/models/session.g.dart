// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final int typeId = 6;

  @override
  Session read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Session(
      id: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as SessionType,
      answersSchema: fields[3] as AnswersSchema,
      questionIds: (fields[4] as List).cast<String>(),
      status: fields[5] as SessionStatus,
      createdAt: fields[6] as DateTime,
      endsAt: fields[7] as DateTime?,
      jwtKeyId: fields[8] as String,
      ledgerHeadHash: fields[9] as String?,
      joinCode: fields[10] as String,
      meetingId: fields[11] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer
      ..writeByte(12)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.answersSchema)
      ..writeByte(4)
      ..write(obj.questionIds)
      ..writeByte(5)
      ..write(obj.status)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.endsAt)
      ..writeByte(8)
      ..write(obj.jwtKeyId)
      ..writeByte(9)
      ..write(obj.ledgerHeadHash)
      ..writeByte(10)
      ..write(obj.joinCode)
      ..writeByte(11)
      ..write(obj.meetingId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
