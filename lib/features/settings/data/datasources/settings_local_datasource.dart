import 'package:hive/hive.dart';

import '../../../../core/constants/hive_constants.dart';
import '../models/settings_model.dart';

abstract class SettingsLocalDataSource {
  Future<SettingsModel> getSettings();

  Future<void> saveSettings(SettingsModel settings);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  static const String _settingsKey = 'app_settings';

  Box<SettingsModel> get _box =>
      Hive.box<SettingsModel>(HiveConstants.settingsBox);

  @override
  Future<SettingsModel> getSettings() async {
    final storedSettings = _box.get(_settingsKey);

    if (storedSettings != null) {
      return storedSettings;
    }

    // Persist defaults once so every later read has one source of truth.
    final defaults = SettingsModel.defaults();
    await _box.put(_settingsKey, defaults);

    return defaults;
  }

  @override
  Future<void> saveSettings(SettingsModel settings) async {
    await _box.put(_settingsKey, settings);
  }
}
