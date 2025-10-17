// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'audit_log.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class AuditLogAdapter extends TypeAdapter<AuditLog> {
  @override
  final int typeId = 8;

  @override
  AuditLog read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AuditLog(
      action: fields[0] as String,
      sessionId: fields[1] as String,
      subjectId: fields[2] as String?,
      timestamp: fields[3] as DateTime,
      details: fields[4] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, AuditLog obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.action)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.subjectId)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.details);
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
