import 'package:hive_flutter/hive_flutter.dart';
import '../../features/medicine/data/adapters/dose_adapter.dart';
import '../../features/medicine/data/adapters/dose_occurrence_adapter.dart';
import '../../features/medicine/data/adapters/medicine_adapter.dart';
import '../../features/medicine/data/models/dose_occurrence_model.dart';
import '../../features/medicine/data/models/medicine_model.dart';
import '../constants/hive_constants.dart';

class HiveService {
  HiveService._();

  static Future<void> init() async {
    await Hive.initFlutter();

    _registerAdapters();

    await _openBoxes();
  }

  static void _registerAdapters() {
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(DoseAdapter());
    }

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(MedicineAdapter());
    }

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(DoseOccurrenceAdapter());
    }
  }

  static Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox<MedicineModel>(HiveConstants.medicinesBox),
      Hive.openBox<DoseOccurrenceModel>(HiveConstants.doseOccurrencesBox),
    ]);
  }
}
