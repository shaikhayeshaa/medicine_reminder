import 'package:hive/hive.dart';

import '../models/dose_model.dart';

class DoseAdapter extends TypeAdapter<DoseModel> {
  @override
  final int typeId = 1;

  @override
  DoseModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();

    final fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return DoseModel(
      id: fields[0] as String,
      hour: fields[1] as int,
      minute: fields[2] as int,
      quantity: fields[3] as double,
      unit: fields[4] as String,
      foodInstruction: fields[5] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DoseModel obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.hour)
      ..writeByte(2)
      ..write(obj.minute)
      ..writeByte(3)
      ..write(obj.quantity)
      ..writeByte(4)
      ..write(obj.unit)
      ..writeByte(5)
      ..write(obj.foodInstruction);
  }
}
