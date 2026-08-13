import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:medicine_reminder/core/services/notification_service.dart';
import 'package:medicine_reminder/features/medicine/data/repositories/reminder_notification_repository_impl.dart';
import 'package:medicine_reminder/features/medicine/domain/repositories/reminder_notification_repository.dart';
import 'package:medicine_reminder/features/medicine/domain/usecases/get_dose_occurrence_by_id.dart';
import '../../domain/usecases/get_dose_occurrences_by_date.dart';
import '../../data/datasources/medicine_local_datasource.dart';
import '../../data/repositories/medicine_repository_impl.dart';
import '../../domain/repositories/medicine_repository.dart';
import '../../domain/usecases/add_medicine.dart';
import '../../domain/usecases/generate_dose_occurrences.dart';
import '../../domain/usecases/mark_dose_taken.dart';
import '../../domain/usecases/skip_dose.dart';
import '../../domain/usecases/snooze_dose.dart';

final medicineLocalDataSourceProvider = Provider<MedicineLocalDataSource>((
  ref,
) {
  return MedicineLocalDataSourceImpl();
});

final medicineRepositoryProvider = Provider<MedicineRepository>((ref) {
  final localDataSource = ref.watch(medicineLocalDataSourceProvider);

  return MedicineRepositoryImpl(localDataSource: localDataSource);
});

final generateDoseOccurrencesUseCaseProvider =
    Provider<GenerateDoseOccurrencesUseCase>((ref) {
      return GenerateDoseOccurrencesUseCase();
    });

final addMedicineUseCaseProvider = Provider<AddMedicineUseCase>((ref) {
  final repository = ref.watch(medicineRepositoryProvider);

  final generateDoseOccurrences = ref.watch(
    generateDoseOccurrencesUseCaseProvider,
  );

  return AddMedicineUseCase(
    repository: repository,
    generateDoseOccurrences: generateDoseOccurrences,
  );
});

final getDoseOccurrencesByDateUseCaseProvider =
    Provider<GetDoseOccurrencesByDateUseCase>((ref) {
      final repository = ref.watch(medicineRepositoryProvider);

      return GetDoseOccurrencesByDateUseCase(repository: repository);
    });

final markDoseTakenUseCaseProvider = Provider<MarkDoseTakenUseCase>((ref) {
  final repository = ref.watch(medicineRepositoryProvider);

  return MarkDoseTakenUseCase(repository: repository);
});

final skipDoseUseCaseProvider = Provider<SkipDoseUseCase>((ref) {
  final repository = ref.watch(medicineRepositoryProvider);

  return SkipDoseUseCase(repository: repository);
});

final snoozeDoseUseCaseProvider = Provider<SnoozeDoseUseCase>((ref) {
  final repository = ref.watch(medicineRepositoryProvider);

  return SnoozeDoseUseCase(repository: repository);
});

final getDoseOccurrenceByIdUseCaseProvider =
    Provider<GetDoseOccurrenceByIdUseCase>((ref) {
      final repository = ref.watch(medicineRepositoryProvider);

      return GetDoseOccurrenceByIdUseCase(repository: repository);
    });

final reminderNotificationRepositoryProvider =
    Provider<ReminderNotificationRepository>((ref) {
      return ReminderNotificationRepositoryImpl(
        notificationService: NotificationService.instance,
      );
    });
