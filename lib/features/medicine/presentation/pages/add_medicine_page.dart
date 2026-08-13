import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/dose_entity.dart';
import '../../domain/entities/medicine_entity.dart';
import '../controllers/dose_input_controller.dart';
import '../providers/add_medicine_controller.dart';
import '../widgets/dose_form_card.dart';
import 'package:go_router/go_router.dart';

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
    _doses.add(
      DoseInputController(id: _uuid.v4(), initialTime: TimeOfDay.now()),
    );
  }

  void _addDose() {
    setState(() {
      _doses.add(
        DoseInputController(id: _uuid.v4(), initialTime: TimeOfDay.now()),
      );
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

    if (selectedDate == null) {
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

    if (selectedDate == null) {
      return;
    }

    setState(() {
      _endDate = selectedDate;
    });
  }

  Future<void> _submit() async {
    final isValid = _formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }

    if (_doses.isEmpty) {
      return;
    }

    final now = DateTime.now();

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
      createdAt: now,
      updatedAt: now,
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
          SnackBar(
            content: Text(
              'Unable to save medicine: '
              '${next.error}',
            ),
          ),
        );

        return;
      }

      if (next.hasValue) {
        context.pop(true);
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Add Medicine')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 700),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Basic Information',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Medicine name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter medicine name';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _descriptionController,
                      textInputAction: TextInputAction.next,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _typeController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Medicine type',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter medicine type';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 12),

                    TextFormField(
                      controller: _strengthController,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Strength',
                        hintText: '500 mg',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter medicine strength';
                        }

                        return null;
                      },
                    ),

                    const SizedBox(height: 28),

                    Text(
                      'Treatment',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),

                    const SizedBox(height: 12),

                    _DateTile(
                      title: 'Start date',
                      value: DateFormat('dd MMM yyyy').format(_startDate),
                      onTap: _selectStartDate,
                    ),

                    const SizedBox(height: 8),

                    _DateTile(
                      title: 'End date',
                      value: _endDate == null
                          ? 'No end date'
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
                        Expanded(
                          child: Text(
                            'Doses',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),

                        TextButton.icon(
                          onPressed: _addDose,
                          icon: const Icon(Icons.add),
                          label: const Text('Add Dose'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    for (int index = 0; index < _doses.length; index++)
                      DoseFormCard(
                        key: ValueKey(_doses[index].id),
                        controller: _doses[index],
                        index: index,
                        onRemove: _doses.length == 1
                            ? null
                            : () => _removeDose(index),
                      ),

                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),

      bottomNavigationBar: _SaveMedicineBar(onPressed: _submit),
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
    return Card(
      child: ListTile(
        leading: const Icon(Icons.calendar_today_outlined),
        title: Text(title),
        subtitle: Text(value),
        onTap: onTap,
        trailing: onClear != null
            ? IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.close),
              )
            : const Icon(Icons.chevron_right),
      ),
    );
  }
}

//sirf _SaveMedicineBar provider watch kar raha hai.
//select ki wajah se ye selected boolean change hone par relevant consumer rebuild karta hai.

class _SaveMedicineBar extends ConsumerWidget {
  final VoidCallback onPressed;

  const _SaveMedicineBar({required this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSaving = ref.watch(
      addMedicineControllerProvider.select((state) => state.isLoading),
    );

    return SafeArea(
      minimum: const EdgeInsets.all(16),
      child: FilledButton.icon(
        onPressed: isSaving ? null : onPressed,
        icon: isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.check),
        label: Text(isSaving ? 'Saving...' : 'Save Medicine'),
      ),
    );
  }
}
