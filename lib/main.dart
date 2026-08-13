import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/services/notification_service.dart';
import 'core/services/hive_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await HiveService.init();
    await NotificationService.instance.initialize();


  runApp(const ProviderScope(child: MedicineReminderApp()));
}
