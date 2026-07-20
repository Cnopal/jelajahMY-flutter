import 'package:flutter/material.dart';

import '../models/trip.dart';
import '../services/trip_service.dart';

class TripFormScreen extends StatefulWidget {
  const TripFormScreen({this.trip, super.key});

  final Trip? trip;

  @override
  State<TripFormScreen> createState() => _TripFormScreenState();
}

class _TripFormScreenState extends State<TripFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tripService = TripService();
  late final TextEditingController _titleController;
  late final TextEditingController _notesController;
  late DateTime _startDate;
  late DateTime _endDate;
  bool _isSaving = false;

  bool get _isEditing => widget.trip != null;

  @override
  void initState() {
    super.initState();
    final trip = widget.trip;
    final today = DateUtils.dateOnly(DateTime.now());
    _titleController = TextEditingController(text: trip?.title ?? '');
    _notesController = TextEditingController(text: trip?.notes ?? '');
    _startDate = trip?.startDate ?? today;
    _endDate = trip?.endDate ?? today.add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null) return;
    setState(() {
      _startDate = date;
      if (_endDate.isBefore(date)) _endDate = date;
    });
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2100),
    );
    if (date != null) setState(() => _endDate = date);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    setState(() => _isSaving = true);

    try {
      if (_isEditing) {
        await _tripService.updateTrip(
          tripId: widget.trip!.id,
          title: _titleController.text,
          startDate: _startDate,
          endDate: _endDate,
          notes: _notesController.text,
        );
      } else {
        await _tripService.createTrip(
          title: _titleController.text,
          startDate: _startDate,
          endDate: _endDate,
          notes: _notesController.text,
        );
      }

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Trip' : 'Create Trip')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TextFormField(
                controller: _titleController,
                textInputAction: TextInputAction.next,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Trip title',
                  prefixIcon: Icon(Icons.luggage_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final length = value?.trim().length ?? 0;
                  if (length < 2) return 'Enter at least 2 characters.';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DateField(
                      label: 'Start date',
                      date: _startDate,
                      onTap: _pickStartDate,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _DateField(
                      label: 'End date',
                      date: _endDate,
                      onTap: _pickEndDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                minLines: 4,
                maxLines: 7,
                decoration: const InputDecoration(
                  labelText: 'Notes (optional)',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.notes_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(_isSaving ? 'Saving...' : 'Save Trip'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.date,
    required this.onTap,
  });

  final String label;
  final DateTime date;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: const Icon(Icons.calendar_month_outlined),
          border: const OutlineInputBorder(),
        ),
        child: Text(formatApiDate(date)),
      ),
    );
  }
}
