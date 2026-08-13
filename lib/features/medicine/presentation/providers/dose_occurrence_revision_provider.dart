import 'package:flutter_riverpod/flutter_riverpod.dart';

class DoseOccurrenceRevisionNotifier extends Notifier<int> {
  @override
  int build() => 0;

  void changed() {
    state++;
  }
}

final doseOccurrenceRevisionProvider =
    NotifierProvider<DoseOccurrenceRevisionNotifier, int>(
      DoseOccurrenceRevisionNotifier.new,
    );
