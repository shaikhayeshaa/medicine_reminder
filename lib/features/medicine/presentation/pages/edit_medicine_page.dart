import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/presentation/widgets/app_background.dart';
import '../../../../core/presentation/widgets/glass_app_bar.dart';
import '../../../../core/presentation/widgets/glass_surface.dart';
import '../../domain/entities/dose_entity.dart';
import '../../domain/entities/medicine_entity.dart';
import '../providers/medicine_management_providers.dart';

class EditMedicinePage extends ConsumerWidget {
  final String medicineId;

  const EditMedicinePage({super.key, required this.medicineId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medicineAsync = ref.watch(medicineByIdProvider(medicineId));

    return medicineAsync.when(
      loading: () => const _EditLoadingState(),
      error: (error, stackTrace) => _EditMessageState(
        title: 'Unable to load medicine',
        message: '$error',
      ),
      data: (medicine) {
        if (medicine == null) {
          return const _EditMessageState(
            title: 'Medicine not found',
            message: 'This medicine may have been deleted.',
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

class _EditMedicineForm extends ConsumerStatefulWidget {
  final MedicineEntity medicine;

  const _EditMedicineForm({super.key, required this.medicine});

  @override
  ConsumerState<_EditMedicineForm> createState() => _EditMedicineFormState();
}

class _EditMedicineFormState extends ConsumerState<_EditMedicineForm> {
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

    // Form state remains local so typing doesn't fan out through Riverpod.
    _nameController = TextEditingController(text: medicine.name);
    _descriptionController = TextEditingController(text: medicine.description);
    _typeController = TextEditingController(text: medicine.type);
    _strengthController = TextEditingController(text: medicine.strength);
    _startDate = medicine.startDate;
    _endDate = medicine.endDate;
    _doses = medicine.doses.map(_EditDoseController.fromEntity).toList();
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
      if (_endDate != null && _endDate!.isBefore(_startDate)) {
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
      _doses.add(_EditDoseController.empty(id: _uuid.v4()));
    });
  }

  void _removeDose(int index) {
    if (_doses.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('At least one dose is required.')),
      );
      return;
    }

    final removed = _doses.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    final doses = <DoseEntity>[];

    for (final controller in _doses) {
      final quantity = double.tryParse(
        controller.quantityController.text.trim(),
      );

      if (quantity == null || quantity <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Every dose needs a valid quantity.')),
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
          foodInstruction: controller.foodController.text.trim(),
        ),
      );
    }

    final old = widget.medicine;
    final updated = MedicineEntity(
      id: old.id,
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _typeController.text.trim(),
      strength: _strengthController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      doses: doses,
      isActive: old.isActive,
      createdAt: old.createdAt,
      updatedAt: DateTime.now(),
    );

    await ref
        .read(medicineManagementControllerProvider.notifier)
        .updateMedicine(updated);

    if (!mounted) {
      return;
    }

    final result = ref.read(medicineManagementControllerProvider);
    if (result.hasError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update medicine: ${result.error}')),
      );
      return;
    }

    context.pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(
      medicineManagementControllerProvider.select((state) => state.isLoading),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'Edit Medicine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF1769D8),
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        flexibleSpace: const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1769D8), Color(0xFF10BEB1)],
            ),
          ),
        ),
      ),
      body: AppBackground(
        child: SafeArea(
          top: false,
          bottom: false,
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 150),
              children: [
                const _EditSectionHeader(
                  icon: Icons.edit_note_rounded,
                  title: 'Medicine details',
                  subtitle: 'Future doses will use these updated values.',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Medicine name'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _typeController,
                  decoration: const InputDecoration(labelText: 'Medicine type'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _strengthController,
                  decoration: const InputDecoration(labelText: 'Strength'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 26),
                const _EditSectionHeader(
                  icon: Icons.date_range_rounded,
                  title: 'Treatment',
                  subtitle: 'Previous completed history stays unchanged.',
                ),
                const SizedBox(height: 14),
                _EditDateTile(
                  title: 'Start date',
                  value: DateFormat('dd MMM yyyy').format(_startDate),
                  onTap: _pickStartDate,
                ),
                const SizedBox(height: 10),
                _EditDateTile(
                  title: 'End date',
                  value: _endDate == null
                      ? 'No end date • ongoing'
                      : DateFormat('dd MMM yyyy').format(_endDate!),
                  onTap: _pickEndDate,
                  onClear: _endDate == null
                      ? null
                      : () {
                          setState(() {
                            _endDate = null;
                          });
                        },
                ),
                const SizedBox(height: 26),
                Row(
                  children: [
                    const Expanded(
                      child: _EditSectionHeader(
                        icon: Icons.schedule_rounded,
                        title: 'Daily doses',
                        subtitle:
                            'Changing a dose rebuilds only future occurrences.',
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _addDose,
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Add dose'),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                for (var index = 0; index < _doses.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DoseEditorCard(
                      controller: _doses[index],
                      onRemove: () => _removeDose(index),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
        child: GlassSurface(
          borderRadius: BorderRadius.circular(24),
          padding: const EdgeInsets.all(8),
          child: FilledButton.icon(
            onPressed: isSaving ? null : _save,
            icon: isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_rounded),
            label: Text(isSaving ? 'Saving...' : 'Save Changes'),
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

class _EditSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EditSectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: scheme.primary, size: 21),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditDateTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _EditDateTile({
    required this.title,
    required this.value,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.calendar_today_rounded),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.labelMedium),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.titleMedium),
              ],
            ),
          ),
          if (onClear != null)
            IconButton(
              tooltip: 'Remove end date',
              onPressed: onClear,
              icon: const Icon(Icons.close_rounded),
            )
          else
            const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _DoseEditorCard extends StatelessWidget {
  final _EditDoseController controller;
  final VoidCallback onRemove;

  const _DoseEditorCard({required this.controller, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Theme.of(
            context,
          ).colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: Column(
        children: [
          ValueListenableBuilder<TimeOfDay>(
            valueListenable: controller.time,
            builder: (context, time, child) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.schedule_rounded),
                title: const Text('Dose time'),
                subtitle: Text(time.format(context)),
                trailing: IconButton(
                  tooltip: 'Remove dose',
                  onPressed: onRemove,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
                onTap: () async {
                  final selected = await showTimePicker(
                    context: context,
                    initialTime: time,
                  );
                  if (selected != null) {
                    controller.time.value = selected;
                  }
                },
              );
            },
          ),
          TextFormField(
            controller: controller.quantityController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Quantity'),
            validator: (value) {
              final number = double.tryParse(value?.trim() ?? '');
              return number == null || number <= 0
                  ? 'Enter a valid quantity'
                  : null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.unitController,
            decoration: const InputDecoration(
              labelText: 'Unit',
              hintText: 'Tablet, ml, capsule...',
            ),
            validator: (value) =>
                value == null || value.trim().isEmpty ? 'Required' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: controller.foodController,
            decoration: const InputDecoration(
              labelText: 'Food instruction',
              hintText: 'After food',
            ),
          ),
        ],
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

  factory _EditDoseController.fromEntity(DoseEntity dose) {
    return _EditDoseController(
      id: dose.id,
      time: ValueNotifier(TimeOfDay(hour: dose.hour, minute: dose.minute)),
      quantityController: TextEditingController(
        text: _quantityText(dose.quantity),
      ),
      unitController: TextEditingController(text: dose.unit),
      foodController: TextEditingController(text: dose.foodInstruction),
    );
  }

  factory _EditDoseController.empty({required String id}) {
    return _EditDoseController(
      id: id,
      time: ValueNotifier(TimeOfDay.now()),
      quantityController: TextEditingController(text: '1'),
      unitController: TextEditingController(text: 'Tablet'),
      foodController: TextEditingController(text: 'After food'),
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

class _EditLoadingState extends StatelessWidget {
  const _EditLoadingState();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: AppBackground(
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _EditMessageState extends StatelessWidget {
  final String title;
  final String message;

  const _EditMessageState({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const GlassAppBar(title: 'Edit Medicine'),
      body: AppBackground(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text('$title\n$message', textAlign: TextAlign.center),
          ),
        ),
      ),
    );
  }
}
