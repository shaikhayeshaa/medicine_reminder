import '../../domain/entities/settings_entity.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';
import '../models/settings_model.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  SettingsRepositoryImpl({required this.localDataSource});

  @override
  Future<SettingsEntity> getSettings() async {
    final model = await localDataSource.getSettings();
    return model.toEntity();
  }

  @override
  Future<void> saveSettings(SettingsEntity settings) async {
    await localDataSource.saveSettings(SettingsModel.fromEntity(settings));
  }
}
