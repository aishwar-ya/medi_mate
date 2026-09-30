import 'package:flutter/material.dart';
import 'package:barcode_widget/barcode_widget.dart';

class AddMedicationScreen extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const AddMedicationScreen({
    super.key,
    this.initialData,
  });

  @override
  State<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState
    extends State<AddMedicationScreen> {
  dynamic _medicationId;

  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _stockController = TextEditingController();
  final _barcodeController = TextEditingController();

  String _selectedFrequency = 'Once daily';

  List<String> _selectedTimes = ['8:00 AM'];

  final List<String> _frequencies = [
    'Once daily',
    'Twice daily',
    'As needed',
  ];

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleDark = Color(0xFF5B21B6);
  static const Color lavender = Color(0xFFF3EEFF);
  static const Color pageBackground = Color(0xFFF8F6FF);
  static const Color textDark = Color(0xFF211738);
  static const Color textMuted = Color(0xFF716A80);
  static const Color borderColor = Color(0xFFE7DFF5);

  @override
  void initState() {
    super.initState();

    if (widget.initialData != null) {
      final init = widget.initialData!;

      _medicationId = init['id'];

      _nameController.text =
          init['name']?.toString() ?? '';

      _dosageController.text =
          init['dosage']?.toString() ?? '';

      _stockController.text =
          init['stock_quantity']?.toString() ?? '30';

      _selectedFrequency =
          init['frequency']?.toString() ??
              'Once daily';

      if (!_frequencies.contains(_selectedFrequency)) {
        _selectedFrequency = 'Once daily';
      }

      if (init['barcode'] != null &&
          init['barcode'].toString().isNotEmpty) {
        _barcodeController.text =
            init['barcode'].toString();
      } else if (_medicationId != null) {
        final idString =
            _medicationId.toString().padLeft(3, '0');

        _barcodeController.text =
            'MEDIC$idString';
      }

      if (init['reminder_times'] != null) {
        try {
          _selectedTimes =
              List<String>.from(
            init['reminder_times'],
          );
        } catch (_) {
          _selectedTimes = ['8:00 AM'];
        }
      }

      if (_selectedFrequency == 'As needed') {
        _selectedTimes = [];
      } else if (_selectedTimes.isEmpty) {
        _selectedTimes = ['8:00 AM'];
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
  // TIME HELPERS
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
      final minute = int.parse(hm[1]);

      final period = parts[1].toUpperCase();

      if (period == 'PM' && hour != 12) {
        hour += 12;
      }

      if (period == 'AM' && hour == 12) {
        hour = 0;
      }

      return TimeOfDay(
        hour: hour,
        minute: minute,
      );
    } catch (_) {
      return TimeOfDay.now();
    }
  }

  Future<void> _pickTime(int index) async {
    if (index < 0 ||
        index >= _selectedTimes.length) {
      return;
    }

    final picked = await showTimePicker(
      context: context,
      initialTime:
          _parseTimeOfDay(_selectedTimes[index]),
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedTimes[index] =
            picked.format(context);
      });

      debugPrint(
        '⏰ User selected time: '
        '${picked.format(context)}',
      );
    }
  }

  void _changeFrequency(String value) {
    setState(() {
      _selectedFrequency = value;

      if (value == 'Once daily') {
        _selectedTimes = [
          _selectedTimes.isNotEmpty
              ? _selectedTimes.first
              : '8:00 AM',
        ];
      } else if (value == 'Twice daily') {
        if (_selectedTimes.isEmpty) {
          _selectedTimes = [
            '8:00 AM',
            '8:00 PM',
          ];
        } else if (_selectedTimes.length == 1) {
          _selectedTimes = [
            _selectedTimes.first,
            '8:00 PM',
          ];
        } else if (_selectedTimes.length > 2) {
          _selectedTimes =
              _selectedTimes.take(2).toList();
        }
      } else {
        _selectedTimes = [];
      }
    });
  }

  void _addAnotherTime() {
    if (_selectedFrequency == 'As needed') {
      return;
    }

    if (_selectedTimes.length >= 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'You can add up to two reminder times.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _selectedTimes.add('8:00 PM');
    });
  }

  void _removeTime(int index) {
    if (_selectedTimes.length <= 1) {
      return;
    }

    setState(() {
      _selectedTimes.removeAt(index);
    });
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isEditing = _medicationId != null;

    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: 430),
            child: Column(
              children: [
                _buildHeader(isEditing),

                Expanded(
                  child: SingleChildScrollView(
                    physics:
                        const BouncingScrollPhysics(),
                    padding:
                        const EdgeInsets.fromLTRB(
                      12,
                      8,
                      12,
                      28,
                    ),
                    child: Column(
                      children: [
                        _buildMedicationDetailsCard(),

                        const SizedBox(height: 10),

                        _buildScheduleCard(),

                        const SizedBox(height: 10),

                        _buildBarcodeCard(),

                        const SizedBox(height: 14),

                        _buildSaveButton(isEditing),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================

  Widget _buildHeader(bool isEditing) {
    return Container(
      height: 100,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFEFE7FF),
            Color(0xFFDCD0FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -30,
            right: 30,
            child: Container(
              width: 95,
              height: 95,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                shape: BoxShape.circle,
              ),
            ),
          ),

          Positioned(
  right: 8,
  bottom: -4,
  child: Image.asset(
    'assets/images/home_doctor.png',
    width: 125,
    height: 105,
    fit: BoxFit.contain,
    errorBuilder: (_, __, ___) =>
        const SizedBox.shrink(),
  ),
),

          Positioned(
            left: 10,
            top: 10,
            child: GestureDetector(
              onTap: () =>
                  Navigator.pop(context),
              child: Container(
                width: 32,
                height: 32,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: purple,
                  size: 18,
                ),
              ),
            ),
          ),

          Positioned(
            left: 52,
            top: 11,
            child: Text(
              isEditing
                  ? 'Edit Medication'
                  : 'Add Medication',
              style: const TextStyle(
                color: textDark,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),

          Positioned(
            left: 52,
            top: 39,
            child: Text(
              isEditing
                  ? 'Update your medication details'
                  : 'Add a medicine to your medication list',
              style: const TextStyle(
                color: textMuted,
                fontSize: 8.5,
              ),
            ),
          ),

          Positioned(
            left: 12,
            bottom: 13,
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color:
                        Colors.white.withOpacity(0.9),
                    borderRadius:
                        BorderRadius.circular(7),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: purple,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 5),
                const Text(
                  'MediMate',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillDecoration(
    IconData icon,
    double size,
  ) {
    return Transform.rotate(
      angle: 0.15,
      child: Container(
        width: size,
        height: size * 0.65,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.68),
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        child: Icon(
          icon,
          color: purple.withOpacity(0.7),
          size: size * 0.34,
        ),
      ),
    );
  }

  // ============================================================
  // MEDICATION DETAILS
  // ============================================================

  Widget _buildMedicationDetailsCard() {
    return _buildSectionCard(
      icon: Icons.medication_rounded,
      title: 'Medication Details',
      subtitle:
          'Enter the basic information about your medicine',
      child: Column(
        children: [
          _buildInputField(
            label: 'Medication Name',
            controller: _nameController,
            hint: 'e.g., Atorvastatin',
            icon: Icons.medication_outlined,
          ),

          const SizedBox(height: 10),

          _buildInputField(
            label: 'Dosage',
            controller: _dosageController,
            hint: 'e.g., 10mg',
            icon: Icons.science_outlined,
          ),

          const SizedBox(height: 10),

          _buildInputField(
            label: 'Stock (Optional)',
            controller: _stockController,
            hint: 'e.g., 30',
            icon: Icons.inventory_2_outlined,
            keyboardType:
                TextInputType.number,
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SCHEDULE
  // ============================================================

  Widget _buildScheduleCard() {
    return _buildSectionCard(
      icon: Icons.schedule_rounded,
      title: 'Schedule',
      subtitle:
          'Choose when you need to take this medicine',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Frequency',
            style: TextStyle(
              color: textDark,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Container(
            height: 43,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 11,
            ),
            decoration: BoxDecoration(
              color: lavender,
              borderRadius:
                  BorderRadius.circular(11),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child:
                DropdownButtonHideUnderline(
              child:
                  DropdownButton<String>(
                value: _selectedFrequency,
                isExpanded: true,
                icon: const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: purple,
                  size: 18,
                ),
                style: const TextStyle(
                  color: textDark,
                  fontSize: 10,
                  fontWeight:
                      FontWeight.w600,
                ),
                items: _frequencies
                    .map(
                      (item) =>
                          DropdownMenuItem<
                              String>(
                        value: item,
                        child: Text(item),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    _changeFrequency(value);
                  }
                },
              ),
            ),
          ),

          if (_selectedFrequency != 'As needed') ...[
            const SizedBox(height: 12),

            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Reminder Time(s)',
                    style: TextStyle(
                      color: textDark,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w700,
                    ),
                  ),
                ),
                if (_selectedTimes.length < 2)
                  GestureDetector(
                    onTap: _addAnotherTime,
                    child: const Text(
                      '+ Add Another Time',
                      style: TextStyle(
                        color: purple,
                        fontSize: 8,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            for (int i = 0;
                i < _selectedTimes.length;
                i++)
              _buildTimeTile(i),
          ],
        ],
      ),
    );
  }

  Widget _buildTimeTile(int index) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 6),
      height: 43,
      padding:
          const EdgeInsets.symmetric(
        horizontal: 10,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(10),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 27,
            height: 27,
            decoration: BoxDecoration(
              color: lavender,
              borderRadius:
                  BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.access_time_rounded,
              color: purple,
              size: 14,
            ),
          ),

          const SizedBox(width: 8),

          Expanded(
            child: Text(
              _selectedTimes[index],
              style: const TextStyle(
                color: textDark,
                fontSize: 10,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),

          GestureDetector(
            onTap: () => _pickTime(index),
            child: Container(
              width: 27,
              height: 27,
              decoration: BoxDecoration(
                color: lavender,
                borderRadius:
                    BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.edit_rounded,
                color: purple,
                size: 13,
              ),
            ),
          ),

          if (_selectedTimes.length > 1) ...[
            const SizedBox(width: 5),
            GestureDetector(
              onTap: () =>
                  _removeTime(index),
              child: Container(
                width: 27,
                height: 27,
                decoration: BoxDecoration(
                  color:
                      const Color(0xFFFFF0F1),
                  borderRadius:
                      BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.close_rounded,
                  color: Colors.redAccent,
                  size: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // BARCODE
  // ============================================================

  Widget _buildBarcodeCard() {
    final hasBarcode =
        _barcodeController.text.trim().isNotEmpty;

    return _buildSectionCard(
      icon: Icons.qr_code_rounded,
      title: 'Medicine Barcode',
      subtitle:
          'Use this barcode to quickly identify the medicine',
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          const Text(
            'Barcode ID (Optional)',
            style: TextStyle(
              color: textDark,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 5),

          Container(
            height: 43,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 10,
            ),
            decoration: BoxDecoration(
              color: lavender,
              borderRadius:
                  BorderRadius.circular(11),
              border: Border.all(
                color: borderColor,
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_rounded,
                  color: purple,
                  size: 17,
                ),

                const SizedBox(width: 8),

                Expanded(
                  child: TextField(
                    controller:
                        _barcodeController,
                    readOnly: true,
                    style:
                        const TextStyle(
                      color: textDark,
                      fontSize: 9,
                      fontWeight:
                          FontWeight.w600,
                    ),
                    decoration:
                        const InputDecoration(
                      border: InputBorder.none,
                      hintText:
                          'Auto-generated after saving',
                      hintStyle:
                          TextStyle(
                        color: textMuted,
                        fontSize: 8,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 5),

          Text(
            hasBarcode
                ? 'Medicine ID: ${_barcodeController.text}'
                : 'Code will be generated after saving',
            style: const TextStyle(
              color: textMuted,
              fontSize: 7.5,
            ),
          ),

          if (hasBarcode) ...[
            const SizedBox(height: 9),
            _buildBarcodePreview(),
          ],
        ],
      ),
    );
  }

  Widget _buildBarcodePreview() {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(11),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Column(
        children: [
          const Text(
            'Scannable Medicine Barcode',
            style: TextStyle(
              color: textDark,
              fontSize: 9,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(height: 7),

          Container(
            width: double.infinity,
            height: 82,
            padding:
                const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 5,
            ),
            color: Colors.white,
            child: BarcodeWidget(
              barcode: Barcode.code128(
                useCode128A: false,
                useCode128B: true,
                useCode128C: false,
              ),
              data:
                  _barcodeController.text.trim(),
              width: 280,
              height: 72,
              color: Colors.black,
              backgroundColor: Colors.white,
              drawText: true,
              textPadding: 5,
              errorBuilder:
                  (context, error) {
                return const Center(
                  child: Text(
                    'Unable to generate barcode',
                    textAlign:
                        TextAlign.center,
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 8,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          Text(
            _barcodeController.text.trim(),
            style: const TextStyle(
              color: textDark,
              fontSize: 8,
              fontWeight:
                  FontWeight.w700,
              letterSpacing: 1,
            ),
          ),

          const SizedBox(height: 3),

          const Text(
            'Scan this Code 128 barcode with the MediMate scanner.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: textMuted,
              fontSize: 7,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SAVE BUTTON
  // ============================================================

  Widget _buildSaveButton(bool isEditing) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _saveMedication,
        style:
            ElevatedButton.styleFrom(
          backgroundColor: purple,
          foregroundColor: Colors.white,
          elevation: 0,
          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.add_rounded,
              size: 20,
            ),
            const SizedBox(width: 5),
            Text(
              isEditing
                  ? 'Update Medication'
                  : 'Save Medication',
              style: const TextStyle(
                fontSize: 13,
                fontWeight:
                    FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _buildSectionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding:
          const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
        ),
        boxShadow: [
          BoxShadow(
            color:
                purple.withOpacity(0.035),
            blurRadius: 8,
            offset:
                const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration:
                    BoxDecoration(
                  color: lavender,
                  borderRadius:
                      BorderRadius.circular(
                    9,
                  ),
                ),
                child: Icon(
                  icon,
                  color: purple,
                  size: 16,
                ),
              ),

              const SizedBox(width: 8),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                  children: [
                    Text(
                      title,
                      style:
                          const TextStyle(
                        color: textDark,
                        fontSize: 11,
                        fontWeight:
                            FontWeight.w900,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      style:
                          const TextStyle(
                        color: textMuted,
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          child,
        ],
      ),
    );
  }

  // ============================================================
  // INPUT FIELD
  // ============================================================

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType =
        TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: textDark,
            fontSize: 9,
            fontWeight:
                FontWeight.w700,
          ),
        ),

        const SizedBox(height: 5),

        Container(
          height: 43,
          decoration: BoxDecoration(
            color: lavender,
            borderRadius:
                BorderRadius.circular(11),
            border: Border.all(
              color: borderColor,
            ),
          ),
          child: TextField(
            controller: controller,
            keyboardType:
                keyboardType,
            style: const TextStyle(
              color: textDark,
              fontSize: 9.5,
              fontWeight:
                  FontWeight.w600,
            ),
            decoration:
                InputDecoration(
              hintText: hint,
              hintStyle:
                  const TextStyle(
                color: textMuted,
                fontSize: 8.5,
                fontWeight:
                    FontWeight.w400,
              ),
              prefixIcon: Icon(
                icon,
                color: purple,
                size: 16,
              ),
              prefixIconConstraints:
                  const BoxConstraints(
                minWidth: 36,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets
                      .symmetric(
                vertical: 12,
                horizontal: 8,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SAVE MEDICATION
  // ============================================================

  void _saveMedication() {
    if (_nameController.text
            .trim()
            .isEmpty ||
        _dosageController.text
            .trim()
            .isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Please fill all required fields',
          ),
        ),
      );

      return;
    }

    final int stockQuantity =
        int.tryParse(
              _stockController.text.trim(),
            ) ??
            30;

    debugPrint(
      '📦 Stock quantity: $stockQuantity',
    );

    final Map<String, dynamic> med = {
      if (_medicationId != null)
        'id': _medicationId,

      'name':
          _nameController.text.trim(),

      'dosage':
          _dosageController.text.trim(),

      'frequency':
          _selectedFrequency,

      'stock_quantity':
          stockQuantity,

      if (_barcodeController.text
          .trim()
          .isNotEmpty)
        'barcode':
            _barcodeController.text.trim(),
    };

    if (_selectedFrequency != 'As needed' &&
        _selectedTimes.isNotEmpty) {
      med['reminder_times'] =
          List<String>.from(
        _selectedTimes,
      );

      debugPrint(
        '⏰ Saving reminder times: '
        '$_selectedTimes',
      );

      final String timeStr =
          _selectedTimes.first;

      try {
        final List<String> parts =
            timeStr.split(' ');

        if (parts.length == 2) {
          final List<String> hm =
              parts[0].split(':');

          int hour =
              int.parse(hm[0]);

          final int minute =
              int.parse(hm[1]);

          final String ampm =
              parts[1].toUpperCase();

          if (ampm == 'PM' &&
              hour != 12) {
            hour += 12;
          }

          if (ampm == 'AM' &&
              hour == 12) {
            hour = 0;
          }

          final DateTime now =
              DateTime.now();

          DateTime nextDose =
              DateTime(
            now.year,
            now.month,
            now.day,
            hour,
            minute,
          );

          if (nextDose.isBefore(now)) {
            nextDose =
                nextDose.add(
              const Duration(
                days: 1,
              ),
            );
          }

          med['next_dose'] =
              nextDose.toIso8601String();

          debugPrint(
            '✅ Selected time: $timeStr',
          );

          debugPrint(
            '✅ Parsed as: '
            '${hour.toString().padLeft(2, '0')}:'
            '${minute.toString().padLeft(2, '0')}',
          );

          debugPrint(
            '✅ Next dose scheduled for: '
            '$nextDose',
          );
        } else {
          debugPrint(
            '⚠️ Invalid time format: '
            '$timeStr',
          );
        }
      } catch (e) {
        debugPrint(
          '❌ Error parsing time: $e',
        );
      }
    } else {
      med['reminder_times'] =
          <String>[];

      med['next_dose'] = null;
    }

    debugPrint(
      '💾 Saving medication data: $med',
    );

    Navigator.pop(
      context,
      med,
    );
  }
}