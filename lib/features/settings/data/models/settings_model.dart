import '../../domain/entities/settings_entity.dart';

class SettingsModel {
  final String reminderSoundId;
  final bool vibrationEnabled;
  final int defaultSnoozeMinutes;
  final bool notificationsEnabled;

  const SettingsModel({
    required this.reminderSoundId,
    required this.vibrationEnabled,
    required this.defaultSnoozeMinutes,
    required this.notificationsEnabled,
  });

  /// Converts the domain object into the object stored by Hive.
  factory SettingsModel.fromEntity(SettingsEntity entity) {
    return SettingsModel(
      reminderSoundId: entity.reminderSoundId,
      vibrationEnabled: entity.vibrationEnabled,
      defaultSnoozeMinutes: entity.defaultSnoozeMinutes,
      notificationsEnabled: entity.notificationsEnabled,
    );
  }

  /// Converts persisted data back into the domain representation.
  SettingsEntity toEntity() {
    return SettingsEntity(
      reminderSoundId: reminderSoundId,
      vibrationEnabled: vibrationEnabled,
      defaultSnoozeMinutes: defaultSnoozeMinutes,
      notificationsEnabled: notificationsEnabled,
    );
  }

  /// Used when no settings have been persisted yet.
  factory SettingsModel.defaults() {
    return SettingsModel.fromEntity(SettingsEntity.defaults);
  }
}
