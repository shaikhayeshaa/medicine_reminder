import '../entities/settings_entity.dart';
import '../repositories/settings_repository.dart';

class GetSettingsUseCase {
  final SettingsRepository repository;

  const GetSettingsUseCase({
    required this.repository,
  });

  Future<SettingsEntity> call() {
    return repository.getSettings();
  }
}
