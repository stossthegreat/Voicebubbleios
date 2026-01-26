// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recording_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class RecordingItemAdapter extends TypeAdapter<RecordingItem> {
  @override
  final int typeId = 1;

  @override
  RecordingItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return RecordingItem(
      id: fields[0] as String,
      rawTranscript: fields[1] as String,
      finalText: fields[2] as String,
      presetUsed: fields[3] as String,
      outcomes: (fields[4] as List).cast<String>(),
      projectId: fields[5] as String?,
      createdAt: fields[6] as DateTime,
      editHistory: (fields[7] as List).cast<String>(),
      presetId: fields[8] as String,
      continuedFromId: fields[9] as String?,
      continuedInIds: (fields[10] as List?)?.cast<String>(),
      hiddenInLibrary: fields[11] as bool? ?? false,
      hiddenInOutcomes: fields[12] as bool? ?? false,
      isCompleted: fields[13] as bool? ?? false,
      tags: (fields[14] as List?)?.cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, RecordingItem obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.rawTranscript)
      ..writeByte(2)
      ..write(obj.finalText)
      ..writeByte(3)
      ..write(obj.presetUsed)
      ..writeByte(4)
      ..write(obj.outcomes)
      ..writeByte(5)
      ..write(obj.projectId)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.editHistory)
      ..writeByte(8)
      ..write(obj.presetId)
      ..writeByte(9)
      ..write(obj.continuedFromId)
      ..writeByte(10)
      ..write(obj.continuedInIds)
      ..writeByte(11)
      ..write(obj.hiddenInLibrary)
      ..writeByte(12)
      ..write(obj.hiddenInOutcomes)
      ..writeByte(13)
      ..write(obj.isCompleted)
      ..writeByte(14)
      ..write(obj.tags);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecordingItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
