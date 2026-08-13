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

  Future<void> _selectTime(BuildContext context) async {
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
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${index + 1}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Dose ${index + 1}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (onRemove != null)
                IconButton(
                  tooltip: 'Remove dose',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 8),
          ValueListenableBuilder<TimeOfDay>(
            valueListenable: controller.time,
            builder: (context, selectedTime, child) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.schedule_rounded, color: scheme.primary),
                title: const Text('Dose time'),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _selectTime(context),
              );
            },
          ),
          TextFormField(
            controller: controller.quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Quantity'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter dose quantity';
              }
              final quantity = double.tryParse(value.trim());
              if (quantity == null || quantity <= 0) {
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
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter dose unit';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.foodInstructionController,
            decoration: const InputDecoration(
              labelText: 'Food instruction',
              hintText: 'After breakfast',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Enter food instruction';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }
}
