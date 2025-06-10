import 'package:flutter/material.dart';

import '../../widget/form_fields.dart';
import '../../widget/utils.dart';

class AddReminderPage extends StatefulWidget {
  final Function(String, TimeOfDay, int, String) onSave;
  final Color backgroundColor;
  final Color appBarColor;
  final Color textColor;
  final Color iconColor;

  const AddReminderPage({
    required this.onSave,
    required this.backgroundColor,
    required this.appBarColor,
    required this.textColor,
    required this.iconColor,
    super.key,
  });

  @override
  _AddReminderPageState createState() => _AddReminderPageState();
}

class _AddReminderPageState extends State<AddReminderPage> {
  final _formKey = GlobalKey<FormState>();
  final _medicineController = TextEditingController();
  TimeOfDay _selectedTime = TimeOfDay.now();
  int _repeatHours = 0;
  String _category = 'General';
  bool _isSaving = false;
  bool _hasChanges = false;

  @override
  void dispose() {
    _medicineController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    if (_isSaving) return;
    try {
      final TimeOfDay? picked = await showTimePickerDialog(context, _selectedTime);
      if (picked != null && mounted) {
        setState(() {
          _selectedTime = picked;
          _hasChanges = true;
        });
      }
    } catch (e) {
      showSnackBar(context, 'Error selecting time: $e', Colors.red[400]!);
    }
  }

  Future<void> _saveReminder() async {
    if (_formKey.currentState!.validate() && !_isSaving) {
      setState(() => _isSaving = true);
      try {
        await widget.onSave(
          _medicineController.text.trim(),
          _selectedTime,
          _repeatHours,
          _category,

        );
        if (mounted) {
          showSnackBar(context, 'Reminder saved successfully!', widget.iconColor);
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSaving = false);
          showSnackBar(context, 'Failed to save reminder: $e', Colors.red[400]!);
        }
      }
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasChanges || _isSaving) return true;
    return await showDiscardDialog(context) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: widget.backgroundColor,
        appBar: AppBar(
          title: Text('Add Reminder', style: TextStyle(color: Colors.white)),
          backgroundColor: widget.appBarColor,
          iconTheme: IconThemeData(color: widget.iconColor),
          centerTitle: true,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              onChanged: () => setState(() => _hasChanges = true),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  buildSectionHeader("Medication Information", color: widget.textColor),
                  const SizedBox(height: 16),
                  buildMedicineField(_medicineController, _isSaving, textColor: widget.textColor),
                  const SizedBox(height: 24),
                  buildSectionHeader("Category", color: widget.textColor),
                  const SizedBox(height: 16),
                  buildCategoryDropdown(
                    _category,
                    _isSaving,
                        (value) => setState(() => _category = value!),
                    textColor: widget.textColor,
                  ),
                  const SizedBox(height: 24),
                  buildSectionHeader("Reminder Time", color: widget.textColor),
                  const SizedBox(height: 16),
                  buildTimePicker(context, _selectedTime, _selectTime, iconColor: widget.iconColor, textColor: widget.textColor),
                  const SizedBox(height: 24),
                  buildSectionHeader("Repeat Interval", color: widget.textColor),
                  const SizedBox(height: 40),
                  buildSaveButton(_isSaving, _saveReminder, backgroundColor: widget.iconColor),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}