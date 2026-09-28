import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class AddMedicationScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddMedicationScreen({super.key, this.initialData});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  dynamic _medicationId;

  final TextEditingController _nameController = TextEditingController();

  final TextEditingController _dosageController = TextEditingController();

  final TextEditingController _stockController = TextEditingController();

  final TextEditingController _barcodeController = TextEditingController();

  String _selectedFrequency = 'Once daily';

  List<String> _selectedTimes = ['8:00 AM'];

  final List<String> _frequencies = ['Once daily', 'Twice daily', 'As needed'];

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      final init = widget.initialData!;

      _medicationId = init['id'];

      _nameController.text = init['name']?.toString() ?? '';

      _dosageController.text = init['dosage']?.toString() ?? '';

      _stockController.text = init['stock_quantity']?.toString() ?? '30';

      _selectedFrequency = init['frequency']?.toString() ?? 'Once daily';

      // ------------------------------------------------------------
      // BARCODE
      // ------------------------------------------------------------

      if (init['barcode'] != null && init['barcode'].toString().isNotEmpty) {
        _barcodeController.text = init['barcode'].toString();
      } else if (_medicationId != null) {
        final idString = _medicationId.toString().padLeft(3, '0');

        _barcodeController.text = 'MEDIC$idString';
      }

      // ------------------------------------------------------------
      // REMINDER TIMES
      // ------------------------------------------------------------

      if (init['reminder_times'] != null) {
        final times = init['reminder_times'];

        if (times is List) {
          _selectedTimes =
              times
                  .map((time) => time.toString())
                  .where((time) => time.isNotEmpty)
                  .toList();
        }
      }

      // Make sure the frequency and reminder count agree.
      if (_selectedFrequency == 'Once daily') {
        if (_selectedTimes.isEmpty) {
          _selectedTimes = ['8:00 AM'];
        } else {
          _selectedTimes = [_selectedTimes.first];
        }
      } else if (_selectedFrequency == 'Twice daily') {
        if (_selectedTimes.isEmpty) {
          _selectedTimes = ['8:00 AM', '8:00 PM'];
        } else if (_selectedTimes.length == 1) {
          _selectedTimes = [_selectedTimes.first, '8:00 PM'];
        } else if (_selectedTimes.length > 2) {
          _selectedTimes = [_selectedTimes[0], _selectedTimes[1]];
        }
      } else if (_selectedFrequency == 'As needed') {
        _selectedTimes = [];
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _stockController.dispose();
    _barcodeController.dispose();

    super.dispose();
  }

  // ============================================================
  // PARSE TIME
  // ============================================================

  TimeOfDay _parseTimeOfDay(String value) {
    try {
      final parts = value.trim().split(' ');

      if (parts.length != 2) {
        return TimeOfDay.now();
      }

      final hm = parts[0].split(':');

      if (hm.length != 2) {
        return TimeOfDay.now();
      }

      int hour = int.parse(hm[0]);
      final int minute = int.parse(hm[1]);

      final String period = parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  // ============================================================
  // PICK TIME
  // ============================================================

  Future<void> _pickTime(int index) async {
    if (index < 0 || index >= _selectedTimes.length) {
      return;
    }

    final TimeOfDay currentTime = _parseTimeOfDay(_selectedTimes[index]);

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (!mounted || pickedTime == null) {
      return;
    }

    final String formattedTime = pickedTime.format(context);

    setState(() {
      _selectedTimes[index] = formattedTime;
    });

    debugPrint(
      'Updated reminder ${index + 1}: '
      '$formattedTime',
    );
  }

  // ============================================================
  // CHANGE FREQUENCY
  // ============================================================

  void _changeFrequency(String value) {
    setState(() {
      _selectedFrequency = value;

      if (value == 'Once daily') {
        _selectedTimes = [
          _selectedTimes.isNotEmpty ? _selectedTimes.first : '8:00 AM',
        ];
      } else if (value == 'Twice daily') {
        if (_selectedTimes.isEmpty) {
          _selectedTimes = ['8:00 AM', '8:00 PM'];
        } else if (_selectedTimes.length == 1) {
          _selectedTimes = [_selectedTimes.first, '8:00 PM'];
        } else if (_selectedTimes.length > 2) {
          _selectedTimes = [_selectedTimes[0], _selectedTimes[1]];
        }
      } else if (value == 'As needed') {
        _selectedTimes = [];
      }
    });

    debugPrint('Frequency changed to: $value');

    debugPrint('Reminder times: $_selectedTimes');
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final bool isEditing = _medicationId != null;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,

        title: Text(
          isEditing ? 'Edit Medication' : 'Add Medication',

          style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w700),
        ),

        centerTitle: false,
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 32),

          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 850),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // ==================================================
                  // INTRO
                  // ==================================================
                  Text(
                    isEditing
                        ? 'Update your medication details'
                        : 'Add a medicine to your medication list',

                    style: TextStyle(
                      fontSize: 14,
                      color: theme.textTheme.bodyMedium?.color?.withValues(
                        alpha: 0.60,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ==================================================
                  // MEDICATION DETAILS
                  // ==================================================
                  _buildSectionHeader(
                    icon: Icons.medication_outlined,
                    title: 'Medication Details',
                    subtitle: 'Enter the basic information about your medicine',
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),

                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.08),
                      ),
                    ),

                    child: Column(
                      children: [
                        _buildTextField(
                          'Medication Name',
                          _nameController,
                          'e.g., Atorvastatin',
                        ),

                        const SizedBox(height: 18),

                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 500) {
                              return Column(
                                children: [
                                  _buildTextField(
                                    'Dosage',
                                    _dosageController,
                                    'e.g., 10mg',
                                  ),

                                  const SizedBox(height: 18),

                                  _buildTextField(
                                    'Stock',
                                    _stockController,
                                    'e.g., 30',
                                    TextInputType.number,
                                  ),
                                ],
                              );
                            }

                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    'Dosage',
                                    _dosageController,
                                    'e.g., 10mg',
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: _buildTextField(
                                    'Stock',
                                    _stockController,
                                    'e.g., 30',
                                    TextInputType.number,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // SCHEDULE
                  // ==================================================
                  _buildSectionHeader(
                    icon: Icons.schedule_rounded,
                    title: 'Schedule',
                    subtitle: 'Choose when you need to take this medicine',
                  ),

                  const SizedBox(height: 14),

                  Container(
                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),

                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.08),
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        _buildDropdown(
                          'Frequency',
                          _selectedFrequency,
                          _frequencies,
                          (value) {
                            if (value != null) {
                              _changeFrequency(value);
                            }
                          },
                        ),

                        if (_selectedFrequency != 'As needed') ...[
                          const SizedBox(height: 20),

                          const Text(
                            'Reminder Time(s)',

                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 10),

                          for (int i = 0; i < _selectedTimes.length; i++)
                            _buildTimeCard(i),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // BARCODE
                  // ==================================================
                  _buildSectionHeader(
                    icon: Icons.qr_code_2_rounded,
                    title: 'Medicine Barcode',
                    subtitle:
                        'Use this barcode to quickly identify the medicine',
                  ),

                  const SizedBox(height: 14),

                  Container(
                    width: double.infinity,

                    padding: const EdgeInsets.all(18),

                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(20),

                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.08),
                      ),
                    ),

                    child: Column(
                      children: [
                        TextField(
                          controller: _barcodeController,

                          readOnly: true,

                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: theme.textTheme.bodyLarge?.color,
                          ),

                          decoration: InputDecoration(
                            labelText: 'Barcode ID',

                            hintText: 'Auto-generated after saving',

                            prefixIcon: Icon(
                              Icons.qr_code_2_rounded,
                              color: colorScheme.primary,
                            ),

                            filled: true,

                            fillColor: colorScheme.primary.withValues(
                              alpha: 0.06,
                            ),

                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),

                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Align(
                          alignment: Alignment.centerLeft,

                          child: Text(
                            _barcodeController.text.isNotEmpty
                                ? 'Medicine ID: '
                                    '${_barcodeController.text}'
                                : 'Code will be generated after saving',

                            style: TextStyle(
                              fontSize: 12,
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.60),
                            ),
                          ),
                        ),

                        if (_barcodeController.text.trim().isNotEmpty) ...[
                          const SizedBox(height: 18),

                          Container(
                            width: double.infinity,

                            padding: const EdgeInsets.all(16),

                            decoration: BoxDecoration(
                              color: Colors.white,

                              borderRadius: BorderRadius.circular(16),

                              border: Border.all(color: Colors.grey.shade300),
                            ),

                            child: Column(
                              children: [
                                const Text(
                                  'Scannable Code 128',

                                  style: TextStyle(
                                    color: Colors.black87,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),

                                const SizedBox(height: 14),

                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    return BarcodeWidget(
                                      barcode: Barcode.code128(
                                        useCode128A: false,
                                        useCode128B: true,
                                        useCode128C: false,
                                      ),

                                      data: _barcodeController.text.trim(),

                                      width: constraints.maxWidth,

                                      height: 120,

                                      color: Colors.black,

                                      backgroundColor: Colors.white,

                                      drawText: true,

                                      textPadding: 8,

                                      errorBuilder: (context, error) {
                                        return Padding(
                                          padding: const EdgeInsets.all(12),

                                          child: Text(
                                            'Unable to generate barcode: $error',

                                            textAlign: TextAlign.center,

                                            style: const TextStyle(
                                              color: Colors.red,
                                            ),
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  _barcodeController.text.trim(),

                                  style: const TextStyle(
                                    color: Colors.black87,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                  ),
                                ),

                                const SizedBox(height: 6),

                                const Text(
                                  'Scan this Code 128 barcode with MediMate.',

                                  textAlign: TextAlign.center,

                                  style: TextStyle(
                                    color: Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 30),

                  // ==================================================
                  // SAVE BUTTON
                  // ==================================================
                  SizedBox(
                    width: double.infinity,

                    height: 54,

                    child: ElevatedButton.icon(
                      onPressed: _saveMedication,

                      icon: Icon(
                        isEditing ? Icons.check_rounded : Icons.add_rounded,
                      ),

                      label: Text(
                        isEditing ? 'Update Medication' : 'Save Medication',

                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),

                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,

                        foregroundColor: Colors.white,

                        elevation: 0,

                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SECTION HEADER
  // ============================================================

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Container(
          width: 42,
          height: 42,

          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.12),

            borderRadius: BorderRadius.circular(12),
          ),

          child: Icon(icon, color: colorScheme.primary, size: 22),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,

                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),

              const SizedBox(height: 3),

              Text(
                subtitle,

                style: TextStyle(
                  fontSize: 12,
                  color: theme.textTheme.bodySmall?.color?.withValues(
                    alpha: 0.60,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================================
  // TIME CARD
  // ============================================================

  Widget _buildTimeCard(int index) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,

      margin: const EdgeInsets.only(bottom: 10),

      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.07),

        borderRadius: BorderRadius.circular(14),

        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.10)),
      ),

      child: Material(
        color: Colors.transparent,

        child: InkWell(
          borderRadius: BorderRadius.circular(14),

          onTap: () {
            _pickTime(index);
          },

          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),

            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,

                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.12),

                    borderRadius: BorderRadius.circular(11),
                  ),

                  child: Icon(
                    Icons.access_time_rounded,

                    size: 20,

                    color: colorScheme.primary,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        'Reminder ${index + 1}',

                        style: TextStyle(
                          fontSize: 11,

                          color: theme.textTheme.bodySmall?.color?.withValues(
                            alpha: 0.55,
                          ),
                        ),
                      ),

                      const SizedBox(height: 2),

                      Text(
                        _selectedTimes[index],

                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),

                IconButton(
                  onPressed: () {
                    _pickTime(index);
                  },

                  icon: Icon(
                    Icons.edit_outlined,
                    size: 19,
                    color: colorScheme.primary,
                  ),

                  tooltip: 'Change time',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SAVE MEDICATION
  // ============================================================

  void _saveMedication() {
    debugPrint('==============================');
    debugPrint('💾 UPDATE/SAVE PRESSED');
    debugPrint('⏰ FREQUENCY: $_selectedFrequency');
    debugPrint('⏰ SELECTED TIMES: $_selectedTimes');
    debugPrint('==============================');
    if (_nameController.text.trim().isEmpty ||
        _dosageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );

      return;
    }

    final int stockQuantity = int.tryParse(_stockController.text.trim()) ?? 30;

    debugPrint('Stock quantity: $stockQuantity');

    // ==========================================================
    // MEDICATION DATA
    // ==========================================================

    final Map<String, dynamic> med = {
      if (_medicationId != null) 'id': _medicationId,

      'name': _nameController.text.trim(),

      'dosage': _dosageController.text.trim(),

      'frequency': _selectedFrequency,

      'stock_quantity': stockQuantity,

      if (_barcodeController.text.trim().isNotEmpty)
        'barcode': _barcodeController.text.trim(),
    };

    // ==========================================================
    // REMINDER TIMES
    // ==========================================================

    if (_selectedFrequency != 'As needed' && _selectedTimes.isNotEmpty) {
      med['reminder_times'] = List<String>.from(_selectedTimes);

      debugPrint(
        'Saving reminder times: '
        '$_selectedTimes',
      );

      final String timeStr = _selectedTimes.first;

      try {
        final List<String> parts = timeStr.split(' ');

        if (parts.length == 2) {
          final List<String> hm = parts[0].split(':');

          if (hm.length == 2) {
            int hour = int.parse(hm[0]);

            final int minute = int.parse(hm[1]);

            final String ampm = parts[1].toUpperCase();

            // Convert 12-hour time
            // to 24-hour time.

            if (ampm == 'PM' && hour != 12) {
              hour += 12;
            }

            if (ampm == 'AM' && hour == 12) {
              hour = 0;
            }

            final DateTime now = DateTime.now();

            DateTime nextDose = DateTime(
              now.year,
              now.month,
              now.day,
              hour,
              minute,
            );

            // If time has already passed,
            // schedule for tomorrow.

            if (nextDose.isBefore(now)) {
              nextDose = nextDose.add(const Duration(days: 1));
            }

            med['next_dose'] = nextDose.toIso8601String();

            debugPrint('Selected time: $timeStr');

            debugPrint(
              'Parsed as: '
              '${hour.toString().padLeft(2, '0')}:'
              '${minute.toString().padLeft(2, '0')}',
            );

            debugPrint(
              'Next dose scheduled for: '
              '$nextDose',
            );
          }
        }
      } catch (e) {
        debugPrint('Error parsing time: $e');
      }
    } else {
      med['reminder_times'] = <String>[];

      med['next_dose'] = null;
    }

    // ==========================================================
    // RETURN DATA
    // ==========================================================

    debugPrint('Saving medication data: $med');

    Navigator.pop(context, med);
  }

  // ============================================================
  // TEXT FIELD
  // ============================================================

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hint, [
    TextInputType type = TextInputType.text,
  ]) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: controller,

          keyboardType: type,

          decoration: InputDecoration(
            hintText: hint,

            filled: true,

            fillColor: colorScheme.primary.withValues(alpha: 0.06),

            prefixIcon: Icon(
              label == 'Medication Name'
                  ? Icons.medication_outlined
                  : label == 'Dosage'
                  ? Icons.straighten_rounded
                  : Icons.inventory_2_outlined,

              color: colorScheme.primary,
            ),

            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),

              borderSide: BorderSide.none,
            ),

            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),

              borderSide: BorderSide.none,
            ),

            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),

              borderSide: BorderSide(color: colorScheme.primary, width: 1.3),
            ),

            contentPadding: const EdgeInsets.symmetric(
              horizontal: 15,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DROPDOWN
  // ============================================================

  Widget _buildDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,

      children: [
        Text(
          label,

          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),

          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.06),

            borderRadius: BorderRadius.circular(14),

            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.08),
            ),
          ),

          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,

              isExpanded: true,

              icon: Icon(
                Icons.keyboard_arrow_down_rounded,

                color: colorScheme.primary,
              ),

              items:
                  items.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,

                      child: Text(
                        item,

                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    );
                  }).toList(),

              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}
