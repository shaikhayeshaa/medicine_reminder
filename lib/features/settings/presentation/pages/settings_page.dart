import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reminder_sound_option.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_section_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: settingsAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stackTrace) => _SettingsErrorState(
          onRetry: () {
            ref.invalidate(settingsControllerProvider);
          },
        ),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            children: [
              SettingsSectionCard(
                icon: Icons.notifications_active_outlined,
                title: 'Notifications',
                subtitle: 'Allow future medicine reminder notifications.',
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Medicine reminders'),
                  value: settings.notificationsEnabled,
                  onChanged: (value) async {
                    try {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .setNotificationsEnabled(value);
                    } catch (error) {
                      if (!context.mounted) return;
                      _showSaveError(context, error);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              SettingsSectionCard(
                icon: Icons.vibration_outlined,
                title: 'Vibration',
                subtitle: 'Vibrate when a supported reminder is delivered.',
                child: SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Vibration'),
                  value: settings.vibrationEnabled,
                  onChanged: (value) async {
                    try {
                      await ref
                          .read(settingsControllerProvider.notifier)
                          .setVibrationEnabled(value);
                    } catch (error) {
                      if (!context.mounted) return;
                      _showSaveError(context, error);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              SettingsSectionCard(
                icon: Icons.snooze_outlined,
                title: 'Default Snooze',
                subtitle: 'Choose the default snooze duration.',
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final minutes in const [5, 10, 15, 30])
                      ChoiceChip(
                        label: Text('$minutes min'),
                        selected: settings.defaultSnoozeMinutes == minutes,
                        onSelected: (_) async {
                          try {
                            await ref
                                .read(settingsControllerProvider.notifier)
                                .setDefaultSnoozeMinutes(minutes);
                          } catch (error) {
                            if (!context.mounted) return;
                            _showSaveError(context, error);
                          }
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SettingsSectionCard(
                icon: Icons.volume_up_outlined,
                title: 'Reminder Sound',
                subtitle: 'Select and preview the sound for future reminders.',
                child: Column(
                  children: [
                    for (final option in reminderSoundOptions)
                      _SoundOptionTile(
                        option: option,
                        selected: settings.reminderSoundId == option.id,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  static void _showSaveError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to save setting: $error'),
      ),
    );
  }
}

class _SoundOptionTile extends ConsumerWidget {
  final ReminderSoundOption option;
  final bool selected;

  const _SoundOptionTile({
    required this.option,
    required this.selected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
      ),
      title: Text(option.title),
      onTap: () async {
        try {
          await ref
              .read(settingsControllerProvider.notifier)
              .setReminderSound(option.id);
        } catch (error) {
          if (!context.mounted) return;
          _showError(context, error);
        }
      },
      trailing: IconButton(
        tooltip: 'Play ${option.title}',
        icon: const Icon(Icons.play_arrow_rounded),
        onPressed: () async {
          try {
            final previewService = ref.read(
              settingsSoundPreviewServiceProvider,
            );

            await previewService.play(option.assetFileName);
          } catch (error) {
            if (!context.mounted) return;
            _showError(context, error);
          }
        },
      ),
    );
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Unable to play/save sound: $error'),
      ),
    );
  }
}

class _SettingsErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _SettingsErrorState({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
            ),
            const SizedBox(height: 12),
            const Text('Unable to load settings.'),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }
}
