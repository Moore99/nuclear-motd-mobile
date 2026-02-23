// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_message.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedMessageAdapter extends TypeAdapter<CachedMessage> {
  @override
  final int typeId = 0;

  @override
  CachedMessage read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedMessage(
      id: fields[0] as int,
      title: fields[1] as String,
      content: fields[2] as String,
      contentHtml: fields[3] as String,
      topics: (fields[4] as List).cast<String>(),
      messageType: fields[5] as String?,
      createdAt: fields[6] as String?,
      startDate: fields[7] as String?,
      endDate: fields[8] as String?,
      status: fields[9] as String,
      citationText: fields[10] as String?,
      citationUrl: fields[11] as String?,
      cachedAt: fields[12] as DateTime,
      readInApp: fields[13] as bool? ?? false,
    );
  }

  @override
  void write(BinaryWriter writer, CachedMessage obj) {
    writer
      ..writeByte(14)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.content)
      ..writeByte(3)
      ..write(obj.contentHtml)
      ..writeByte(4)
      ..write(obj.topics)
      ..writeByte(5)
      ..write(obj.messageType)
      ..writeByte(6)
      ..write(obj.createdAt)
      ..writeByte(7)
      ..write(obj.startDate)
      ..writeByte(8)
      ..write(obj.endDate)
      ..writeByte(9)
      ..write(obj.status)
      ..writeByte(10)
      ..write(obj.citationText)
      ..writeByte(11)
      ..write(obj.citationUrl)
      ..writeByte(12)
      ..write(obj.cachedAt)
      ..writeByte(13)
      ..write(obj.readInApp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedMessageAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
