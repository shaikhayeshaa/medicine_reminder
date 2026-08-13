import 'package:flutter/material.dart';

class DoseInputController {
  final String id;

  final ValueNotifier<TimeOfDay> time;

  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController foodInstructionController;

  DoseInputController({required this.id, required TimeOfDay initialTime})
    : time = ValueNotifier(initialTime),
      quantityController = TextEditingController(),
      unitController = TextEditingController(),
      foodInstructionController = TextEditingController();

  void dispose() {
    time.dispose();
    quantityController.dispose();
    unitController.dispose();
    foodInstructionController.dispose();
  }
}
