import 'package:hive/hive.dart';
import '../models/settings_model.dart';

class SettingsAdapter extends TypeAdapter<SettingsModel> {
  @override
  final int typeId = 3;

  @override
  SettingsModel read(BinaryReader reader) {
    final fieldCount = reader.readByte();
    final fields = <int, dynamic>{
      for (var i = 0; i < fieldCount; i++) reader.readByte(): reader.read(),
    };

    return SettingsModel(
      reminderSoundId: fields[0] as String? ?? 'default_alarm',
      vibrationEnabled: fields[1] as bool? ?? true,
      defaultSnoozeMinutes: fields[2] as int? ?? 10,
      notificationsEnabled: fields[3] as bool? ?? true,
    );
  }

  @override
  void write(BinaryWriter writer, SettingsModel obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.reminderSoundId)
      ..writeByte(1)
      ..write(obj.vibrationEnabled)
      ..writeByte(2)
      ..write(obj.defaultSnoozeMinutes)
      ..writeByte(3)
      ..write(obj.notificationsEnabled);
  }
}
