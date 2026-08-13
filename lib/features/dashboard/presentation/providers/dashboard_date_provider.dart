import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() {
    return _dateOnly(DateTime.now());
  }

  void selectDate(DateTime date) {
    final selectedDate = _dateOnly(date);

    if (selectedDate == state) {
      return;
    }

    state = selectedDate;
  }

  void selectToday() {
    selectDate(DateTime.now());
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }
}

final dashboardDateProvider = NotifierProvider<DashboardDateNotifier, DateTime>(
  DashboardDateNotifier.new,
);
