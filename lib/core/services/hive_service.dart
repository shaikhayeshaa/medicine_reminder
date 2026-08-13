import 'package:hive_flutter/hive_flutter.dart';
import 'package:medicine_reminder/features/settings/data/adapters/settings_adapter.dart';
import 'package:medicine_reminder/features/settings/data/models/settings_model.dart';
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
    if (!Hive.isAdapterRegistered(3)) {
      Hive.registerAdapter(SettingsAdapter());
    }
  }

  static Future<void> _openBoxes() async {
    await Future.wait([
      Hive.openBox<MedicineModel>(HiveConstants.medicinesBox),
      Hive.openBox<DoseOccurrenceModel>(HiveConstants.doseOccurrencesBox),
      Hive.openBox<SettingsModel>(HiveConstants.settingsBox),
    ]);
  }
}


// Medicine          typeId = 0
// Dose              typeId = 1
// DoseOccurrence    typeId = 2
// Settings          typeId = 3