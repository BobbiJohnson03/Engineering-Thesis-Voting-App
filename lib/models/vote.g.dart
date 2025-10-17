// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'vote.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class VoteAdapter extends TypeAdapter<Vote> {
  @override
  final int typeId = 6;

  @override
  Vote read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Vote(
      voteId: fields[0] as String,
      sessionId: fields[1] as String,
      questionId: fields[2] as String,
      selectedOptionIds: (fields[3] as List).cast<String>(),
      submittedAt: fields[4] as DateTime,
      byTicketId: fields[5] as String,
      hashPrev: fields[6] as String,
      hashSelf: fields[7] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Vote obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.voteId)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.questionId)
      ..writeByte(3)
      ..write(obj.selectedOptionIds)
      ..writeByte(4)
      ..write(obj.submittedAt)
      ..writeByte(5)
      ..write(obj.byTicketId)
      ..writeByte(6)
      ..write(obj.hashPrev)
      ..writeByte(7)
      ..write(obj.hashSelf);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
