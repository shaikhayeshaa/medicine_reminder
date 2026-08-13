import 'package:hive/hive.dart';
import '../models/dose_model.dart';
import '../models/medicine_model.dart';

class MedicineAdapter extends TypeAdapter<MedicineModel> {
  @override
  final int typeId = 0;

  @override
  MedicineModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();

    final fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++)
        reader.readByte(): reader.read(),
    };

    return MedicineModel(
      id: fields[0] as String,
      name: fields[1] as String,
      description: fields[2] as String,
      type: fields[3] as String,
      strength: fields[4] as String,
      startDate: fields[5] as DateTime,
      endDate: fields[6] as DateTime?,
      doses: (fields[7] as List).cast<DoseModel>(),
      isActive: fields[8] as bool,
      createdAt: fields[9] as DateTime,
      updatedAt: fields[10] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, MedicineModel obj) {
    writer
      ..writeByte(11)

      ..writeByte(0)
      ..write(obj.id)

      ..writeByte(1)
      ..write(obj.name)

      ..writeByte(2)
      ..write(obj.description)

      ..writeByte(3)
      ..write(obj.type)

      ..writeByte(4)
      ..write(obj.strength)

      ..writeByte(5)
      ..write(obj.startDate)

      ..writeByte(6)
      ..write(obj.endDate)

      ..writeByte(7)
      ..write(obj.doses)

      ..writeByte(8)
      ..write(obj.isActive)

      ..writeByte(9)
      ..write(obj.createdAt)

      ..writeByte(10)
      ..write(obj.updatedAt);
  }
}