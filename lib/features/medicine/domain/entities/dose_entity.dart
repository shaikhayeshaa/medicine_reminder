class DoseEntity {
  final String id;
  final int hour;
  final int minute;
  final double quantity;
  final String unit;
  final String foodInstruction;

  const DoseEntity({
    required this.id,
    required this.hour,
    required this.minute,
    required this.quantity,
    required this.unit,
    required this.foodInstruction,
  });
}

// not using TimeOfDay as that's Flutter ui class
// domain should be flutter-independent