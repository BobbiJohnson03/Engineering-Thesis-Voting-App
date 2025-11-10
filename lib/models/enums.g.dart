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
        return SessionType.nonsecret;
      case 1:
        return SessionType.secret;
      default:
        return SessionType.nonsecret;
    }
  }

  @override
  void write(BinaryWriter writer, SessionType obj) {
    switch (obj) {
      case SessionType.nonsecret:
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

class SessionStatusAdapter extends TypeAdapter<SessionStatus> {
  @override
  final int typeId = 2;

  @override
  SessionStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return SessionStatus.open;
      case 1:
        return SessionStatus.closed;
      case 2:
        return SessionStatus.archived;
      default:
        return SessionStatus.open;
    }
  }

  @override
  void write(BinaryWriter writer, SessionStatus obj) {
    switch (obj) {
      case SessionStatus.open:
        writer.writeByte(0);
        break;
      case SessionStatus.closed:
        writer.writeByte(1);
        break;
      case SessionStatus.archived:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AuditActionAdapter extends TypeAdapter<AuditAction> {
  @override
  final int typeId = 13;

  @override
  AuditAction read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return AuditAction.sessionCreated;
      case 1:
        return AuditAction.voteSubmitted;
      case 2:
        return AuditAction.ticketIssued;
      case 3:
        return AuditAction.meetingJoined;
      case 4:
        return AuditAction.sessionClosed;
      default:
        return AuditAction.sessionCreated;
    }
  }

  @override
  void write(BinaryWriter writer, AuditAction obj) {
    switch (obj) {
      case AuditAction.sessionCreated:
        writer.writeByte(0);
        break;
      case AuditAction.voteSubmitted:
        writer.writeByte(1);
        break;
      case AuditAction.ticketIssued:
        writer.writeByte(2);
        break;
      case AuditAction.meetingJoined:
        writer.writeByte(3);
        break;
      case AuditAction.sessionClosed:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditActionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
