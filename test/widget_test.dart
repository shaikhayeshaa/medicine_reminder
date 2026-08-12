import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/app/app.dart';

void main() {
  testWidgets('Medicine Reminder app smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const MedicineReminderApp(),
    );

    expect(
      find.text('Medicine Reminder'),
      findsOneWidget,
    );
  });
}