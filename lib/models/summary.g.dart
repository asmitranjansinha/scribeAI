// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'summary.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SummaryAdapter extends TypeAdapter<Summary> {
  @override
  final int typeId = 0;

  @override
  Summary read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Summary(
      id: fields[0] as String,
      transcription: fields[1] as String,
      summary: fields[2] as String,
      eventId: fields[3] as String,
      audioPath: fields[4] as String,
      createdAt: fields[5] as DateTime,
      eventName: fields[6] as String,
      eventDescription: fields[7] as String,
      eventStartTime: fields[8] as DateTime,
      eventEndTime: fields[9] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Summary obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.transcription)
      ..writeByte(2)
      ..write(obj.summary)
      ..writeByte(3)
      ..write(obj.eventId)
      ..writeByte(4)
      ..write(obj.audioPath)
      ..writeByte(5)
      ..write(obj.createdAt)
      ..writeByte(6)
      ..write(obj.eventName)
      ..writeByte(7)
      ..write(obj.eventDescription)
      ..writeByte(8)
      ..write(obj.eventStartTime)
      ..writeByte(9)
      ..write(obj.eventEndTime);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SummaryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
