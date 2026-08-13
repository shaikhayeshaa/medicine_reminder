import 'package:hive/hive.dart';
import '../../domain/entities/dose_status.dart';
import '../models/dose_occurrence_model.dart';

class DoseOccurrenceAdapter extends TypeAdapter<DoseOccurrenceModel> {
  @override
  final int typeId = 2;

  @override
  DoseOccurrenceModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();

    final fields = <int, dynamic>{
      for (int i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return DoseOccurrenceModel(
      id: fields[0] as String,
      medicineId: fields[1] as String,
      doseId: fields[2] as String,
      scheduledAt: fields[3] as DateTime,
      quantity: fields[4] as double,
      unit: fields[5] as String,
      foodInstruction: fields[6] as String,
      status: DoseStatus.values.firstWhere(
        (status) => status.name == fields[7],
        orElse: () => DoseStatus.pending,
      ),
      actionAt: fields[8] as DateTime?,
      snoozedUntil: fields[9] as DateTime?,
      createdAt: fields[10] as DateTime,
      medicineName: fields[11] as String,
      medicineDescription: fields[12] as String,
      medicineType: fields[13] as String,
      medicineStrength: fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DoseOccurrenceModel obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.medicineId)
      ..writeByte(2)
      ..write(obj.doseId)
      ..writeByte(3)
      ..write(obj.scheduledAt)
      ..writeByte(4)
      ..write(obj.quantity)
      ..writeByte(5)
      ..write(obj.unit)
      ..writeByte(6)
      ..write(obj.foodInstruction)
      ..writeByte(7)
      ..write(obj.status.name)
      ..writeByte(8)
      ..write(obj.actionAt)
      ..writeByte(9)
      ..write(obj.snoozedUntil)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.medicineName)
      ..writeByte(12)
      ..write(obj.medicineDescription)
      ..writeByte(13)
      ..write(obj.medicineType)
      ..writeByte(14)
      ..write(obj.medicineStrength);
  }
}
