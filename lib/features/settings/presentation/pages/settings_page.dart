import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/widgets/app_background.dart';
import '../../../../core/presentation/widgets/page_header.dart';
import '../models/reminder_sound_option.dart';
import '../providers/settings_providers.dart';
import '../widgets/settings_section_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: SafeArea(
          bottom: false,
          child: settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => _SettingsErrorState(
              onRetry: () {
                ref.invalidate(settingsControllerProvider);
              },
            ),
            data: (settings) {
              return ListView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 150),
                children: [
                  const PageHeader(
                    eyebrow: 'Personalize',
                    title: 'Settings',
                    subtitle: 'Choose how reminders sound, feel, and snooze.',
                  ),
                  const SizedBox(height: 22),
                  SettingsSectionCard(
                    icon: Icons.notifications_active_rounded,
                    title: 'Notifications',
                    subtitle: 'Allow future medicine reminder notifications.',
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Medicine reminders'),
                      subtitle: Text(
                        settings.notificationsEnabled
                            ? 'Future reminders are scheduled'
                            : 'All scheduled reminders are disabled',
                      ),
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
                    icon: Icons.vibration_rounded,
                    title: 'Vibration',
                    subtitle:
                        'Control vibration for supported future reminders.',
                    child: SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Vibrate on reminder'),
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
                    icon: Icons.snooze_rounded,
                    title: 'Default snooze',
                    subtitle:
                        'Used by the Snooze action directly from notifications.',
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
                    icon: Icons.graphic_eq_rounded,
                    title: 'Reminder sound',
                    subtitle:
                        'Select and preview the sound used by future reminders.',
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
        ),
      ),
    );
  }

  static void _showSaveError(BuildContext context, Object error) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Unable to save setting: $error')));
  }
}

class _SoundOptionTile extends ConsumerWidget {
  final ReminderSoundOption option;
  final bool selected;

  const _SoundOptionTile({required this.option, required this.selected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary.withValues(alpha: 0.09)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.38),
        borderRadius: BorderRadius.circular(18),
      ),
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        leading: Icon(
          selected
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: selected ? scheme.primary : scheme.onSurfaceVariant,
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
        trailing: IconButton.filledTonal(
          tooltip: 'Preview ${option.title}',
          icon: const Icon(Icons.play_arrow_rounded),
          onPressed: () async {
            try {
              await ref
                  .read(settingsSoundPreviewServiceProvider)
                  .play(option.assetFileName);
            } catch (error) {
              if (!context.mounted) return;
              _showError(context, error);
            }
          },
        ),
      ),
    );
  }

  void _showError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Unable to play/save sound: $error')),
    );
  }
}

class _SettingsErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _SettingsErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FilledButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Retry settings'),
      ),
    );
  }
}
