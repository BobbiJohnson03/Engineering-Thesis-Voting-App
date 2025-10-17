// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'enums.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SessionTypeAdapter extends TypeAdapter<SessionType> {
  @override
  final int typeId = 0;

  @override
  SessionType read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SessionType.public;
      case 1:
        return SessionType.secret;
      default:
        return SessionType.public;
    }
  }

  @override
  void write(BinaryWriter writer, SessionType obj) {
    switch (obj) {
      case SessionType.public:
        writer.writeByte(0);
        break;
      case SessionType.secret:
        writer.writeByte(1);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionTypeAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AnswersSchemaAdapter extends TypeAdapter<AnswersSchema> {
  @override
  final int typeId = 1;

  @override
  AnswersSchema read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AnswersSchema.yesNo;
      case 1:
        return AnswersSchema.yesNoAbstain;
      case 2:
        return AnswersSchema.custom;
      default:
        return AnswersSchema.yesNo;
    }
  }

  @override
  void write(BinaryWriter writer, AnswersSchema obj) {
    switch (obj) {
      case AnswersSchema.yesNo:
        writer.writeByte(0);
        break;
      case AnswersSchema.yesNoAbstain:
        writer.writeByte(1);
        break;
      case AnswersSchema.custom:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnswersSchemaAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
