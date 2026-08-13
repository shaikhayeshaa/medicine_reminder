import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/medicine_entity.dart';
import 'medicine_providers.dart';

class MedicineNotifier
    extends AsyncNotifier<List<MedicineEntity>> {
  @override
  Future<List<MedicineEntity>> build() async {
    final repository = ref.watch(
      medicineRepositoryProvider,
    );

    return repository.getAllMedicines();
  }

  Future<void> refreshMedicines() async {
    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final repository = ref.read(
        medicineRepositoryProvider,
      );

      return repository.getAllMedicines();
    });
  }
}

final medicineNotifierProvider =
    AsyncNotifierProvider<
        MedicineNotifier,
        List<MedicineEntity>>(
  MedicineNotifier.new,
);