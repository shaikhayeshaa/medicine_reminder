class ReminderSoundOption {
  final String id;
  final String title;
  final String assetFileName;

  /// Android raw-resource name used later by NotificationService.
  final String androidResourceName;

  /// iOS bundle filename used later by NotificationService.
  final String iosFileName;

  const ReminderSoundOption({
    required this.id,
    required this.title,
    required this.assetFileName,
    required this.androidResourceName,
    required this.iosFileName,
  });
}

const List<ReminderSoundOption> reminderSoundOptions = [
  ReminderSoundOption(
    id: 'default_alarm',
    title: 'Default Alarm',
    assetFileName: 'default_alarm.wav',
    androidResourceName: 'default_alarm',
    iosFileName: 'default_alarm.wav',
  ),
  ReminderSoundOption(
    id: 'alarm_2',
    title: 'Alarm 2',
    assetFileName: 'alarm_2.wav',
    androidResourceName: 'alarm_2',
    iosFileName: 'alarm_2.wav',
  ),
  ReminderSoundOption(
    id: 'alarm_3',
    title: 'Alarm 3',
    assetFileName: 'alarm_3.wav',
    androidResourceName: 'alarm_3',
    iosFileName: 'alarm_3.wav',
  ),
];

ReminderSoundOption soundOptionById(String id) {
  return reminderSoundOptions.firstWhere(
    (option) => option.id == id,
    orElse: () => reminderSoundOptions.first,
  );
}
