import 'package:flutter/material.dart';

import '../controllers/dose_input_controller.dart';

class DoseFormCard extends StatelessWidget {
  final DoseInputController controller;
  final int index;
  final VoidCallback? onRemove;

  const DoseFormCard({
    super.key,
    required this.controller,
    required this.index,
    this.onRemove,
  });

  Future<void> _selectTime(
    BuildContext context,
  ) async {
    final selectedTime = await showTimePicker(
      context: context,
      initialTime: controller.time.value,
    );

    if (selectedTime != null) {
      controller.time.value = selectedTime;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: 16,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Dose ${index + 1}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium,
                  ),
                ),

                if (onRemove != null)
                  IconButton(
                    tooltip: 'Remove dose',
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            ValueListenableBuilder<TimeOfDay>(
              valueListenable: controller.time,
              builder: (
                context,
                selectedTime,
                child,
              ) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.schedule_outlined,
                  ),
                  title: const Text(
                    'Dose time',
                  ),
                  subtitle: Text(
                    selectedTime.format(context),
                  ),
                  trailing: const Icon(
                    Icons.chevron_right,
                  ),
                  onTap: () => _selectTime(
                    context,
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller:
                  controller.quantityController,
              keyboardType:
                  const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter dose quantity';
                }

                final quantity = double.tryParse(
                  value.trim(),
                );

                if (quantity == null ||
                    quantity <= 0) {
                  return 'Enter a valid quantity';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: controller.unitController,
              decoration: const InputDecoration(
                labelText: 'Unit',
                hintText: 'Tablet, ml, capsule...',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter dose unit';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller:
                  controller.foodInstructionController,
              decoration: const InputDecoration(
                labelText: 'Food instruction',
                hintText: 'After breakfast',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null ||
                    value.trim().isEmpty) {
                  return 'Enter food instruction';
                }

                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}