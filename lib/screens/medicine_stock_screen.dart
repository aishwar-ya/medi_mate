import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MedicineStockScreen extends StatefulWidget {
  const MedicineStockScreen({super.key});

  @override
  State<MedicineStockScreen> createState() => _MedicineStockScreenState();
}

class _MedicineStockScreenState extends State<MedicineStockScreen> {
  final supabase = Supabase.instance.client;

  late Future<List<dynamic>> _stockFuture;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _dosageController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();

  static const Color purple = Color(0xFF7C3AED);
  static const Color purpleDark = Color(0xFF5B21B6);
  static const Color lavender = Color(0xFFF3EEFF);
  static const Color pageBackground = Color(0xFFF8F6FF);
  static const Color textDark = Color(0xFF211738);
  static const Color textMuted = Color(0xFF716A80);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFDC2626);
  static const Color success = Color(0xFF16A34A);

  @override
  void initState() {
    super.initState();
    _stockFuture = _getStock();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _getStock() async {
    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User is not logged in');
      }

      final data = await supabase
          .from('medications')
          .select('id, name, dosage, stock_quantity')
          .eq('user_id', userId)
          .order('name', ascending: true);

      return data;
    } catch (e) {
      throw Exception('Failed to load stock: ${e.toString()}');
    }
  }

  Future<void> _addMedication() async {
    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User is not logged in');
      }

      final name = _nameController.text.trim();
      final dosage = _dosageController.text.trim();
      final quantity = int.tryParse(_quantityController.text.trim());

      if (name.isEmpty || quantity == null || quantity < 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a valid name and quantity.'),
            ),
          );
        }
        return;
      }

      await supabase.from('medications').insert({
        'user_id': userId,
        'name': name,
        'dosage': dosage,
        'stock_quantity': quantity,
      });

      setState(() {
        _stockFuture = _getStock();
      });

      _nameController.clear();
      _dosageController.clear();
      _quantityController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication added successfully'),
            backgroundColor: success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding medication: ${e.toString()}'),
            backgroundColor: danger,
          ),
        );
      }
    }
  }

  Future<void> _updateQuantity(String id, int newQuantity) async {
    try {
      await supabase
          .from('medications')
          .update({'stock_quantity': newQuantity})
          .eq('id', id);

      setState(() {
        _stockFuture = _getStock();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock updated successfully'),
            backgroundColor: success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating stock: ${e.toString()}'),
            backgroundColor: danger,
          ),
        );
      }
    }
  }

  Future<void> _deleteMedication(String id) async {
    try {
      await supabase.from('medications').delete().eq('id', id);

      setState(() {
        _stockFuture = _getStock();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication deleted successfully'),
            backgroundColor: success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting medication: ${e.toString()}'),
            backgroundColor: danger,
          ),
        );
      }
    }
  }

  Future<void> _showAddMedicationDialog() async {
    _nameController.clear();
    _dosageController.clear();
    _quantityController.clear();

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        title: const Text(
          'Add New Medication',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogField(
                controller: _nameController,
                label: 'Medication Name',
                hint: 'Enter medication name',
                icon: Icons.medication_outlined,
              ),
              const SizedBox(height: 12),
              _dialogField(
                controller: _dosageController,
                label: 'Dosage',
                hint: 'e.g., 500mg',
                icon: Icons.science_outlined,
              ),
              const SizedBox(height: 12),
              _dialogField(
                controller: _quantityController,
                label: 'Quantity',
                hint: 'Enter number of pills',
                icon: Icons.inventory_2_outlined,
                keyboardType: TextInputType.number,
              ),
            ],
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _addMedication();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(
        color: textDark,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: purple),
        filled: true,
        fillColor: lavender,
        labelStyle: const TextStyle(color: textMuted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE3D8F7)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFE3D8F7)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: purple, width: 1.5),
        ),
      ),
    );
  }

  Future<void> _showUpdateQuantityDialog(
    String id,
    int currentQuantity,
  ) async {
    final controller =
        TextEditingController(text: currentQuantity.toString());

    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
        ),
        title: const Text(
          'Update Stock Quantity',
          style: TextStyle(
            color: textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(
            color: textDark,
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            labelText: 'New Quantity',
            hintText: 'Enter new quantity',
            prefixIcon: const Icon(
              Icons.inventory_2_outlined,
              color: purple,
            ),
            suffixText: 'pills',
            filled: true,
            fillColor: lavender,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: Color(0xFFE3D8F7)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(15),
              borderSide: const BorderSide(color: purple, width: 1.5),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
        actions: [
          TextButton(
            onPressed: () {
              controller.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: textMuted),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              final newQuantity = int.tryParse(controller.text.trim());

              if (newQuantity != null && newQuantity >= 0) {
                Navigator.pop(dialogContext);
                controller.dispose();
                _updateQuantity(id, newQuantity);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enter a valid quantity.'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(13),
              ),
            ),
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBackground,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: FutureBuilder<List<dynamic>>(
              future: _stockFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: purple),
                  );
                }

                if (snapshot.hasError) {
                  return _buildErrorState(snapshot.error.toString());
                }

                final stockList = snapshot.data ?? [];

                return RefreshIndicator(
                  color: purple,
                  onRefresh: () async {
                    setState(() {
                      _stockFuture = _getStock();
                    });
                    await _stockFuture;
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildHeader(),
                        const SizedBox(height: 14),
                        _buildOverviewCard(stockList),
                        const SizedBox(height: 20),
                        _buildInventoryList(stockList),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      height: 152,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF0E9FF), Color(0xFFE8DCFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: 13,
            left: 13,
            child: GestureDetector(
              onTap: () {
                if (Navigator.of(context).canPop()) {
                  Navigator.of(context).pop();
                }
              },
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: textDark,
                  size: 18,
                ),
              ),
            ),
          ),
          const Positioned(
            left: 58,
            top: 15,
            child: Text(
              'Stock',
              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const Positioned(
            left: 58,
            top: 42,
            child: Text(
              'Keep your medicines ready',
              style: TextStyle(
                color: textMuted,
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            left: 16,
            bottom: 18,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Manage your medicine stock',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tap a medicine to update its quantity',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            right: 4,
            bottom: -2,
            child: Image.asset(
              'assets/images/stock_medicine.png',
              width: 148,
              height: 106,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(List<dynamic> stockList) {
    int totalPills = 0;
    int lowStock = 0;

    for (final med in stockList) {
      final quantity = (med['stock_quantity'] as num?)?.toInt() ?? 0;
      totalPills += quantity;
      if (quantity <= 10) lowStock++;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE7DDF5)),
        boxShadow: [
          BoxShadow(
            color: purple.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _overviewStat(Icons.medication_rounded, stockList.length.toString(), 'Medicines')),
          Container(width: 1, height: 34, color: const Color(0xFFEAE3F5)),
          Expanded(child: _overviewStat(Icons.inventory_2_rounded, totalPills.toString(), 'Total pills')),
          Container(width: 1, height: 34, color: const Color(0xFFEAE3F5)),
          Expanded(child: _overviewStat(
            lowStock > 0 ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
            lowStock.toString(),
            'Low stock',
          )),
        ],
      ),
    );
  }

  Widget _overviewStat(IconData icon, String value, String label) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: purple, size: 16),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: textDark,
            fontSize: 13,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          label,
          style: const TextStyle(color: textMuted, fontSize: 7),
        ),
      ],
    );
  }

  Widget _buildInventoryList(List<dynamic> stockList) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 2),
        if (stockList.isEmpty)
          _buildEmptyState()
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: stockList.length,
            separatorBuilder: (context, index) => const SizedBox(height: 9),
            itemBuilder: (context, index) {
              final med = stockList[index];
              return _buildMedicationCard(
                context,
                id: med['id']?.toString(),
                name: med['name']?.toString() ?? 'Unnamed',
                dosage: med['dosage']?.toString() ?? '',
                quantity: (med['stock_quantity'] as num?)?.toInt() ?? 0,
              );
            },
          ),
      ],
    );
  }

  Widget _buildMedicationCard(
    BuildContext context, {
    required String name,
    required String dosage,
    required int quantity,
    String? id,
  }) {
    final bool isEmpty = quantity <= 0;
    final bool isLow = quantity > 0 && quantity <= 10;
    final Color statusColor =
        isEmpty ? danger : (isLow ? warning : success);
    final String statusText =
        isEmpty ? 'Out of stock' : (isLow ? 'Low stock' : 'In stock');

    return Dismissible(
      key: Key(id ?? '$name-$quantity'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: danger,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 18),
      ),
      onDismissed: (_) {
        if (id != null) _deleteMedication(id);
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: id != null
              ? () => _showUpdateQuantityDialog(id, quantity)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Ink(
            height: 78,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLow || isEmpty
                    ? statusColor.withOpacity(0.22)
                    : const Color(0xFFE6DDF3),
              ),
              boxShadow: [
                BoxShadow(
                  color: purple.withOpacity(0.035),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: lavender,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: purple,
                    size: 21,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textDark,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dosage.isEmpty ? '—' : dosage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: textMuted,
                          fontSize: 9,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$quantity pills',
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: lavender,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(
                  Icons.chevron_right_rounded,
                  color: purple,
                    size: 17,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE5DCF4)),
      ),
      child: Column(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: lavender,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.inventory_2_outlined, color: purple, size: 27),
          ),
          const SizedBox(height: 10),
          const Text(
            'No medicines yet',
            style: TextStyle(color: textDark, fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          const Text(
            'Add your medicines to start managing your stock.',
            textAlign: TextAlign.center,
            style: TextStyle(color: textMuted, fontSize: 9),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5DCF4)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: danger, size: 38),
              const SizedBox(height: 10),
              const Text(
                'Couldn’t load stock',
                style: TextStyle(color: textDark, fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: textMuted, fontSize: 9),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _stockFuture = _getStock();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: purple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Try Again', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
