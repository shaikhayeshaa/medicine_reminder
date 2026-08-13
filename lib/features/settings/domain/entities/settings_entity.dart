class SettingsEntity {
  final String reminderSoundId;
  final bool vibrationEnabled;
  final int defaultSnoozeMinutes;
  final bool notificationsEnabled;

  const SettingsEntity({
    required this.reminderSoundId,
    required this.vibrationEnabled,
    required this.defaultSnoozeMinutes,
    required this.notificationsEnabled,
  });

  /// Default settings used the first time the app is opened.
  static const SettingsEntity defaults = SettingsEntity(
    reminderSoundId: 'default_alarm',
    vibrationEnabled: true,
    defaultSnoozeMinutes: 10,
    notificationsEnabled: true,
  );

  SettingsEntity copyWith({
    String? reminderSoundId,
    bool? vibrationEnabled,
    int? defaultSnoozeMinutes,
    bool? notificationsEnabled,
  }) {
    return SettingsEntity(
      reminderSoundId: reminderSoundId ?? this.reminderSoundId,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      defaultSnoozeMinutes: defaultSnoozeMinutes ?? this.defaultSnoozeMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
