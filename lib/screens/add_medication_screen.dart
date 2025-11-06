import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AddMedicationScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  const AddMedicationScreen({super.key, this.initialData});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  dynamic _medicationId;
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _stockController = TextEditingController();

  String _selectedFrequency = 'Once daily';
  List<String> _selectedTimes = ['8:00 AM']; // supports multiple times

  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'As needed',
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      final init = widget.initialData!;
      _medicationId = init['id'];
      _nameController.text = init['name'] ?? '';
      _dosageController.text = init['dosage'] ?? '';
      _stockController.text = init['stock_quantity']?.toString() ?? '0';
      _selectedFrequency = init['frequency'] ?? 'Once daily';

      // Load existing times if editing
      if (init['reminder_times'] != null) {
        _selectedTimes = List<String>.from(init['reminder_times']);
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  void _pickTime(int index) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: now,
    );
    if (picked != null) {
      setState(() {
        _selectedTimes[index] = picked.format(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adjust times list based on frequency
    if (_selectedFrequency == 'Once daily' && _selectedTimes.length != 1) {
      _selectedTimes = [_selectedTimes.first];
    } else if (_selectedFrequency == 'Twice daily' && _selectedTimes.length != 2) {
      if (_selectedTimes.length == 1) {
        _selectedTimes.add('8:00 PM');
      } else if (_selectedTimes.isEmpty) {
        _selectedTimes = ['8:00 AM', '8:00 PM'];
      }
    } else if (_selectedFrequency == 'As needed') {
      _selectedTimes = [];
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Medication', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField('Medication Name', _nameController, 'e.g., Ibuprofen'),
            const SizedBox(height: 16),
            _buildTextField('Dosage', _dosageController, 'e.g., 200mg'),
            const SizedBox(height: 16),
            _buildTextField('Stock', _stockController, 'e.g., 30', TextInputType.number),
            const SizedBox(height: 16),

            // Frequency dropdown
            _buildDropdown('Frequency', _selectedFrequency, _frequencies, (val) {
              if (val != null) setState(() => _selectedFrequency = val);
            }),
            const SizedBox(height: 16),

            // Reminder times (changes with frequency)
            if (_selectedFrequency != 'As needed') ...[
              const Text('Reminder Time(s)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              for (int i = 0; i < _selectedTimes.length; i++)
                GestureDetector(
                  onTap: () => _pickTime(i),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor.withAlpha(26),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_selectedTimes[i],
                            style: const TextStyle(fontSize: 16)),
                        const Icon(Icons.access_time),
                      ],
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _saveMedication,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Medication',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _saveMedication() {
    if (_nameController.text.isEmpty || _dosageController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final med = {
      'id': _medicationId,
      'name': _nameController.text.trim(),
      'dosage': _dosageController.text.trim(),
      'frequency': _selectedFrequency,
      'reminder_times': _selectedTimes,
      'stock_quantity': int.tryParse(_stockController.text) ?? 0,
    };

    Navigator.pop(context, med);
  }

  Widget _buildTextField(String label, TextEditingController controller,
      String hint, [TextInputType type = TextInputType.text]) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600])),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: type,
          decoration: InputDecoration(
            hintText: hint,
            filled: true,
            fillColor: Theme.of(context).primaryColor.withAlpha(26),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(
      String label, String value, List<String> items, void Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey[600])),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor.withAlpha(26),
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}