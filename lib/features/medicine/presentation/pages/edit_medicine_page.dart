import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/dose_entity.dart';
import '../../domain/entities/medicine_entity.dart';
import '../providers/medicine_management_providers.dart';

class EditMedicinePage extends ConsumerWidget {
  final String medicineId;

  const EditMedicinePage({
    super.key,
    required this.medicineId,
  });

  @override
  Widget build(
    BuildContext context,
    WidgetRef ref,
  ) {
    final medicineAsync = ref.watch(
      medicineByIdProvider(medicineId),
    );

    return medicineAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(
          title: const Text('Edit Medicine'),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(
          title: const Text('Edit Medicine'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Unable to load medicine.\n$error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
      data: (medicine) {
        if (medicine == null) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Edit Medicine'),
            ),
            body: const Center(
              child: Text('Medicine not found.'),
            ),
          );
        }

        return _EditMedicineForm(
          key: ValueKey(medicine.id),
          medicine: medicine,
        );
      },
    );
  }
}

class _EditMedicineForm
    extends ConsumerStatefulWidget {
  final MedicineEntity medicine;

  const _EditMedicineForm({
    super.key,
    required this.medicine,
  });

  @override
  ConsumerState<_EditMedicineForm>
      createState() => _EditMedicineFormState();
}

class _EditMedicineFormState
    extends ConsumerState<_EditMedicineForm> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _typeController;
  late final TextEditingController _strengthController;

  late DateTime _startDate;
  DateTime? _endDate;

  late final List<_EditDoseController> _doses;

  @override
  void initState() {
    super.initState();

    final medicine = widget.medicine;

    // Form fields stay local so typing does not rebuild the whole Riverpod tree.
    _nameController =
        TextEditingController(text: medicine.name);
    _descriptionController =
        TextEditingController(text: medicine.description);
    _typeController =
        TextEditingController(text: medicine.type);
    _strengthController =
        TextEditingController(text: medicine.strength);

    _startDate = medicine.startDate;
    _endDate = medicine.endDate;

    _doses = medicine.doses
        .map(_EditDoseController.fromEntity)
        .toList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _typeController.dispose();
    _strengthController.dispose();

    for (final dose in _doses) {
      dose.dispose();
    }

    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = selected;

      // Prevent an invalid end date after start-date change.
      if (_endDate != null &&
          _endDate!.isBefore(_startDate)) {
        _endDate = null;
      }
    });
  }

  Future<void> _pickEndDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );

    if (selected == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = selected;
    });
  }

  void _addDose() {
    setState(() {
      _doses.add(
        _EditDoseController.empty(
          id: _uuid.v4(),
        ),
      );
    });
  }

  void _removeDose(int index) {
    if (_doses.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'At least one dose is required.',
          ),
        ),
      );
      return;
    }

    final removed = _doses.removeAt(index);
    removed.dispose();

    setState(() {});
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_doses.isEmpty) {
      return;
    }

    final doses = <DoseEntity>[];

    for (final controller in _doses) {
      final quantity = double.tryParse(
        controller.quantityController.text.trim(),
      );

      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Every dose needs a valid quantity.',
            ),
          ),
        );
        return;
      }

      doses.add(
        DoseEntity(
          id: controller.id,
          hour: controller.time.value.hour,
          minute: controller.time.value.minute,
          quantity: quantity,
          unit: controller.unitController.text.trim(),
          foodInstruction:
              controller.foodController.text.trim(),
        ),
      );
    }

    final oldMedicine = widget.medicine;

    final updated = MedicineEntity(
      id: oldMedicine.id,
      name: _nameController.text.trim(),
      description:
          _descriptionController.text.trim(),
      type: _typeController.text.trim(),
      strength: _strengthController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      doses: doses,
      isActive: oldMedicine.isActive,
      createdAt: oldMedicine.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref
        .read(
          medicineManagementControllerProvider.notifier,
        )
        .updateMedicine(updated);

    if (!mounted) {
      return;
    }

    final result = ref.read(
      medicineManagementControllerProvider,
    );

    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to update medicine: ${result.error}',
          ),
        ),
      );
      return;
    }

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(
      medicineManagementControllerProvider.select(
        (state) => state.isLoading,
      ),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Medicine'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              16,
              16,
              16,
              120,
            ),
            children: [
              Text(
                'Basic information',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Medicine name',
                  border: OutlineInputBorder(),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _typeController,
                decoration: const InputDecoration(
                  labelText: 'Medicine type',
                  border: OutlineInputBorder(),
                ),
                validator: _requiredValidator,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _strengthController,
                decoration: const InputDecoration(
                  labelText: 'Strength',
                  border: OutlineInputBorder(),
                ),
                validator: _requiredValidator,
              ),

              const SizedBox(height: 24),

              Text(
                'Treatment',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge,
              ),
              const SizedBox(height: 12),

              _DateTile(
                title: 'Start date',
                value: DateFormat(
                  'dd MMM yyyy',
                ).format(_startDate),
                onTap: _pickStartDate,
              ),
              const SizedBox(height: 8),

              _DateTile(
                title: 'End date',
                value: _endDate == null
                    ? 'No end date'
                    : DateFormat(
                        'dd MMM yyyy',
                      ).format(_endDate!),
                onTap: _pickEndDate,
                trailing: _endDate == null
                    ? null
                    : IconButton(
                        tooltip: 'Remove end date',
                        onPressed: () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Doses',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _addDose,
                    icon: const Icon(Icons.add),
                    label: const Text('Add dose'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              for (var index = 0;
                  index < _doses.length;
                  index++)
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 12),
                  child: _DoseEditorCard(
                    controller: _doses[index],
                    onRemove: () =>
                        _removeDose(index),
                  ),
                ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(16),
        child: FilledButton.icon(
          onPressed: isSaving ? null : _save,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
              : const Icon(Icons.save_outlined),
          label: Text(
            isSaving
                ? 'Saving...'
                : 'Save Changes',
          ),
        ),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Required';
    }

    return null;
  }
}

class _DateTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

  const _DateTile({
    required this.title,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        onTap: onTap,
        leading: const Icon(
          Icons.calendar_month_outlined,
        ),
        title: Text(title),
        subtitle: Text(value),
        trailing: trailing ??
            const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _DoseEditorCard extends StatelessWidget {
  final _EditDoseController controller;
  final VoidCallback onRemove;

  const _DoseEditorCard({
    required this.controller,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            ValueListenableBuilder<TimeOfDay>(
              valueListenable: controller.time,
              builder: (
                context,
                time,
                child,
              ) {
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.schedule_outlined,
                  ),
                  title: const Text('Dose time'),
                  subtitle: Text(
                    time.format(context),
                  ),
                  trailing: IconButton(
                    tooltip: 'Remove dose',
                    onPressed: onRemove,
                    icon: const Icon(
                      Icons.delete_outline,
                    ),
                  ),
                  onTap: () async {
                    final selected =
                        await showTimePicker(
                      context: context,
                      initialTime: time,
                    );

                    if (selected != null) {
                      controller.time.value =
                          selected;
                    }
                  },
                );
              },
            ),

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
                final number = double.tryParse(
                  value?.trim() ?? '',
                );

                if (number == null || number <= 0) {
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
                  return 'Required';
                }

                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: controller.foodController,
              decoration: const InputDecoration(
                labelText: 'Food instruction',
                hintText: 'After food',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditDoseController {
  final String id;
  final ValueNotifier<TimeOfDay> time;
  final TextEditingController quantityController;
  final TextEditingController unitController;
  final TextEditingController foodController;

  _EditDoseController({
    required this.id,
    required this.time,
    required this.quantityController,
    required this.unitController,
    required this.foodController,
  });

  factory _EditDoseController.fromEntity(
    DoseEntity dose,
  ) {
    return _EditDoseController(
      id: dose.id,
      time: ValueNotifier(
        TimeOfDay(
          hour: dose.hour,
          minute: dose.minute,
        ),
      ),
      quantityController: TextEditingController(
        text: _quantityText(dose.quantity),
      ),
      unitController: TextEditingController(
        text: dose.unit,
      ),
      foodController: TextEditingController(
        text: dose.foodInstruction,
      ),
    );
  }

  factory _EditDoseController.empty({
    required String id,
  }) {
    return _EditDoseController(
      id: id,
      time: ValueNotifier(TimeOfDay.now()),
      quantityController:
          TextEditingController(text: '1'),
      unitController:
          TextEditingController(text: 'Tablet'),
      foodController: TextEditingController(),
    );
  }

  static String _quantityText(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }

    return quantity.toString();
  }

  void dispose() {
    time.dispose();
    quantityController.dispose();
    unitController.dispose();
    foodController.dispose();
  }
}
