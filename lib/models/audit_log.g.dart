// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuditLogAdapter extends TypeAdapter<AuditLog> {
  @override
  final int typeId = 12;

  @override
  AuditLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditLog(
      id: fields[0] as String,
      action: fields[1] as AuditAction,
      sessionId: fields[2] as String,
      timestamp: fields[3] as DateTime,
      userHash: fields[4] as String,
      previousLogHash: fields[5] as String,
      logHash: fields[6] as String,
      details: (fields[7] as Map).cast<String, dynamic>(),
      meetingId: fields[8] as String,
    );
  }

  @override
  void write(BinaryWriter writer, AuditLog obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.action)
      ..writeByte(2)
      ..write(obj.sessionId)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.userHash)
      ..writeByte(5)
      ..write(obj.previousLogHash)
      ..writeByte(6)
      ..write(obj.logHash)
      ..writeByte(7)
      ..write(obj.details)
      ..writeByte(8)
      ..write(obj.meetingId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AuditLogAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
