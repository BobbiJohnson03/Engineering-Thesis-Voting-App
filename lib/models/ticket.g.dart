// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ticket.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TicketAdapter extends TypeAdapter<Ticket> {
  @override
  final int typeId = 5;

  @override
  Ticket read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Ticket(
      ticketId: fields[0] as String,
      sessionId: fields[1] as String,
      issuedAt: fields[2] as DateTime,
      used: fields[3] as bool,
      revoked: fields[4] as bool,
      deviceFingerprintHash: fields[5] as String?,
      byPassId: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, Ticket obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.ticketId)
      ..writeByte(1)
      ..write(obj.sessionId)
      ..writeByte(2)
      ..write(obj.issuedAt)
      ..writeByte(3)
      ..write(obj.used)
      ..writeByte(4)
      ..write(obj.revoked)
      ..writeByte(5)
      ..write(obj.deviceFingerprintHash)
      ..writeByte(6)
      ..write(obj.byPassId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TicketAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
