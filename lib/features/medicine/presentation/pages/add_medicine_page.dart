import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/services.dart';
import '../../../../core/presentation/widgets/app_background.dart';
import '../../../../core/presentation/widgets/glass_surface.dart';
import '../../domain/entities/dose_entity.dart';
import '../../domain/entities/medicine_entity.dart';
import '../controllers/dose_input_controller.dart';
import '../providers/add_medicine_controller.dart';
import '../widgets/dose_form_card.dart';

class AddMedicinePage extends ConsumerStatefulWidget {
  const AddMedicinePage({super.key});

  @override
  ConsumerState<AddMedicinePage> createState() => _AddMedicinePageState();
}

class _AddMedicinePageState extends ConsumerState<AddMedicinePage> {
  final _formKey = GlobalKey<FormState>();
  final _uuid = const Uuid();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _typeController = TextEditingController();
  final _strengthController = TextEditingController();

  late DateTime _startDate;
  DateTime? _endDate;
  final List<DoseInputController> _doses = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, now.day);
    _addInitialDose();
  }

  void _addInitialDose() {
    final controller = DoseInputController(
      id: _uuid.v4(),
      initialTime: TimeOfDay.now(),
    );

    // Friendly defaults reduce typing for the most common medicine case.
    controller.quantityController.text = '1';
    controller.unitController.text = 'Tablet';
    controller.foodInstructionController.text = 'After food';
    _doses.add(controller);
  }

  void _addDose() {
    final controller = DoseInputController(
      id: _uuid.v4(),
      initialTime: TimeOfDay.now(),
    );
    controller.quantityController.text = '1';
    controller.unitController.text = 'Tablet';

    setState(() {
      _doses.add(controller);
    });
  }

  void _removeDose(int index) {
    if (_doses.length == 1) {
      return;
    }

    final controller = _doses.removeAt(index);
    controller.dispose();
    setState(() {});
  }

  Future<void> _selectStartDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _startDate = selectedDate;
      if (_endDate != null && _endDate!.isBefore(_startDate)) {
        _endDate = null;
      }
    });
  }

  Future<void> _selectEndDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _endDate ?? _startDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _endDate = selectedDate;
    });
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid || _doses.isEmpty) {
      return;
    }

    final currentTime = DateTime.now();
    final medicine = MedicineEntity(
      id: _uuid.v4(),
      name: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      type: _typeController.text.trim(),
      strength: _strengthController.text.trim(),
      startDate: _startDate,
      endDate: _endDate,
      doses: _doses.map((dose) {
        return DoseEntity(
          id: dose.id,
          hour: dose.time.value.hour,
          minute: dose.time.value.minute,
          quantity: double.parse(dose.quantityController.text.trim()),
          unit: dose.unitController.text.trim(),
          foodInstruction: dose.foodInstructionController.text.trim(),
        );
      }).toList(),
      isActive: true,
      createdAt: currentTime,
      updatedAt: currentTime,
    );

    await ref.read(addMedicineControllerProvider.notifier).submit(medicine);
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

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<void>>(addMedicineControllerProvider, (
      previous,
      next,
    ) {
      if (previous?.isLoading != true) {
        return;
      }

      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to save medicine: ${next.error}')),
        );
        return;
      }

      if (next.hasValue) {
        context.pop(true);
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      appBar: AppBar(
        title: const Text(
          'Add Medicine',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
        ),

        // Solid fallback so black/native background kabhi visible na ho.
        backgroundColor: const Color(0xFF1769D8),
        foregroundColor: Colors.white,

        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,

        // Status bar icons white rahenge.
        systemOverlayStyle: SystemUiOverlayStyle.light,

        // MediTrack blue → teal branded header.
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
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 150),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _SectionTitle(
                        icon: Icons.medical_information_rounded,
                        title: 'Basic information',
                        subtitle: 'What are you taking?',
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _nameController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Medicine name',
                        ),
                        validator: _required('Enter medicine name'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descriptionController,
                        textInputAction: TextInputAction.next,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Description',
                          hintText: 'Optional notes',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _typeController,
                        textInputAction: TextInputAction.next,
                        decoration: const InputDecoration(
                          labelText: 'Medicine type',
                          hintText: 'Tablet, syrup, injection...',
                        ),
                        validator: _required('Enter medicine type'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _strengthController,
                        textInputAction: TextInputAction.done,
                        decoration: const InputDecoration(
                          labelText: 'Strength',
                          hintText: '500 mg',
                        ),
                        validator: _required('Enter medicine strength'),
                      ),
                      const SizedBox(height: 28),
                      const _SectionTitle(
                        icon: Icons.date_range_rounded,
                        title: 'Treatment',
                        subtitle: 'Choose when this medicine is active.',
                      ),
                      const SizedBox(height: 14),
                      _DateTile(
                        title: 'Start date',
                        value: DateFormat('dd MMM yyyy').format(_startDate),
                        onTap: _selectStartDate,
                      ),
                      const SizedBox(height: 10),
                      _DateTile(
                        title: 'End date',
                        value: _endDate == null
                            ? 'No end date • ongoing'
                            : DateFormat('dd MMM yyyy').format(_endDate!),
                        onTap: _selectEndDate,
                        onClear: _endDate == null
                            ? null
                            : () {
                                setState(() {
                                  _endDate = null;
                                });
                              },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        children: [
                          const Expanded(
                            child: _SectionTitle(
                              icon: Icons.schedule_rounded,
                              title: 'Daily doses',
                              subtitle: 'Add every custom reminder time.',
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
                      for (int index = 0; index < _doses.length; index++)
                        DoseFormCard(
                          key: ValueKey(_doses[index].id),
                          controller: _doses[index],
                          index: index,
                          onRemove: _doses.length == 1
                              ? null
                              : () => _removeDose(index),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _SaveMedicineBar(onPressed: _submit),
    );
  }

  FormFieldValidator<String> _required(String message) {
    return (value) {
      if (value == null || value.trim().isEmpty) {
        return message;
      }
      return null;
    };
  }
}

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionTitle({
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

class _DateTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateTile({
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
              tooltip: 'Clear end date',
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

class _SaveMedicineBar extends ConsumerWidget {
  final VoidCallback onPressed;

  const _SaveMedicineBar({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(
      addMedicineControllerProvider.select((state) => state.isLoading),
    );

    return SafeArea(
      minimum: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: GlassSurface(
        borderRadius: BorderRadius.circular(24),
        padding: const EdgeInsets.all(8),
        child: FilledButton.icon(
          onPressed: isSaving ? null : onPressed,
          icon: isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.check_rounded),
          label: Text(isSaving ? 'Saving...' : 'Save Medicine'),
        ),
      ),
    );
  }
}
