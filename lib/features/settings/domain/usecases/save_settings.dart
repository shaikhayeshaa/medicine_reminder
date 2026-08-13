import '../entities/settings_entity.dart';
import '../repositories/settings_repository.dart';

class SaveSettingsUseCase {
  final SettingsRepository repository;

  const SaveSettingsUseCase({required this.repository});

  Future<void> call(SettingsEntity settings) {
    return repository.saveSettings(settings);
  }
}
