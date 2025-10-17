// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionAdapter extends TypeAdapter<Session> {
  @override
  final int typeId = 4;

  @override
  Session read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Session(
      sessionId: fields[0] as String,
      title: fields[1] as String,
      type: fields[2] as SessionType,
      answersSchema: fields[3] as AnswersSchema,
      maxSelectionsPerQuestion: (fields[4] as Map).cast<String, int>(),
      questionIds: (fields[5] as List).cast<String>(),
      isOpen: fields[6] as bool,
      createdAt: fields[7] as DateTime,
      expiresAt: fields[8] as DateTime?,
      jwtKeyId: fields[9] as String,
      archived: fields[10] as bool,
      ledgerHeadHash: fields[11] as String?,
      votingEndsAt: fields[12] as DateTime?,
      shortCode: fields[13] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Session obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.sessionId)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.answersSchema)
      ..writeByte(4)
      ..write(obj.maxSelectionsPerQuestion)
      ..writeByte(5)
      ..write(obj.questionIds)
      ..writeByte(6)
      ..write(obj.isOpen)
      ..writeByte(7)
      ..write(obj.createdAt)
      ..writeByte(8)
      ..write(obj.expiresAt)
      ..writeByte(9)
      ..write(obj.jwtKeyId)
      ..writeByte(10)
      ..write(obj.archived)
      ..writeByte(11)
      ..write(obj.ledgerHeadHash)
      ..writeByte(12)
      ..write(obj.votingEndsAt)
      ..writeByte(13)
      ..write(obj.shortCode);
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
