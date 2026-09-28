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

      await supabase.from('medications').insert({
        'user_id': userId,
        'name': _nameController.text.trim(),
        'dosage': _dosageController.text.trim(),
        'stock_quantity': int.parse(_quantityController.text.trim()),
      });

      // Refresh the stock list
      setState(() {
        _stockFuture = _getStock();
      });

      // Clear the form
      _nameController.clear();
      _dosageController.clear();
      _quantityController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication added successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding medication: ${e.toString()}')),
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

      // Refresh the stock list
      setState(() {
        _stockFuture = _getStock();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating stock: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _deleteMedication(String id) async {
    try {
      await supabase.from('medications').delete().eq('id', id);

      // Refresh the stock list
      setState(() {
        _stockFuture = _getStock();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Medication deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting medication: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _showAddMedicationDialog() async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add New Medication'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Medication Name',
                    hintText: 'Enter medication name',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _dosageController,
                  decoration: const InputDecoration(
                    labelText: 'Dosage',
                    hintText: 'e.g., 500mg',
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _quantityController,
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    hintText: 'Enter number of pills',
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _addMedication();
                },
                child: const Text('Add'),
              ),
            ],
          ),
    );
  }

  Future<void> _showUpdateQuantityDialog(String id, int currentQuantity) async {
    final controller = TextEditingController(text: currentQuantity.toString());
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Update Stock Quantity'),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(
                labelText: 'New Quantity',
                hintText: 'Enter new quantity',
              ),
              keyboardType: TextInputType.number,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  final newQuantity = int.tryParse(controller.text);
                  if (newQuantity != null) {
                    _updateQuantity(id, newQuantity);
                  }
                },
                child: const Text('Update'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Stock',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddMedicationDialog(),
        child: const Icon(Icons.add),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _stockFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No medications in stock.'));
          }

          final stockList = snapshot.data!;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Medication Inventory',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: stockList.length,
                    separatorBuilder:
                        (context, index) => const SizedBox(height: 12),
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
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMedicationCard(
    BuildContext context, {
    required String name,
    required String dosage,
    required int quantity,
    String? id,
  }) {
    return Dismissible(
      key: Key(id ?? DateTime.now().toString()),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        color: Colors.red,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (id != null) {
          _deleteMedication(id);
        }
      },
      child: InkWell(
        onTap:
            id != null ? () => _showUpdateQuantityDialog(id, quantity) : null,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.medication,
                  color: Theme.of(context).primaryColor,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      dosage,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  Text(
                    quantity.toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'pills',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
