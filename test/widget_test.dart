import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:medicine_reminder/core/presentation/widgets/status_badge.dart';
import 'package:medicine_reminder/features/medicine/domain/entities/dose_status.dart';

void main() {
  testWidgets('status badge clearly renders each dose status', (tester) async {
    for (final status in DoseStatus.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: StatusBadge(status: status)),
        ),
      );

      final expectedLabel = switch (status) {
        DoseStatus.pending => 'Pending',
        DoseStatus.taken => 'Taken',
        DoseStatus.missed => 'Missed',
        DoseStatus.skipped => 'Skipped',
      };

      expect(find.text(expectedLabel), findsOneWidget);
    }
  });
}
