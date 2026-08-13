import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/hive_service.dart';
import 'core/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Local data must be available before Riverpod providers are created.
  await HiveService.init();

  // Initializes timezone data and notification callbacks before the UI starts.
  await NotificationService.instance.initialize();

  runApp(
    const ProviderScope(
      child: MedicineReminderApp(),
    ),
  );
}
