import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HydrationScreen extends StatefulWidget {
  const HydrationScreen({super.key});

  @override
  State<HydrationScreen> createState() => _HydrationScreenState();
}

class _HydrationScreenState extends State<HydrationScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  double _goalAmount = 2.0;
  double _currentAmount = 0.0;
  double _progress = 0.0;

  final _goalEditController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadHydrationData();
  }

  String _getTodayDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _loadHydrationData() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser!.id;
      final today = _getTodayDate();

      final data = await supabase
          .from('hydration_log')
          .select()
          .eq('user_id', userId)
          .eq('date', today)
          .maybeSingle();

      if (data != null) {
        _currentAmount = (data['current_amount'] as num).toDouble();
        _goalAmount = (data['goal_amount'] as num).toDouble();
      } else {
        _goalAmount = 2.0;
        _currentAmount = 0.0;
      }

      _updateProgress();
      _goalEditController.text = _goalAmount.toStringAsFixed(1);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load hydration data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveHydrationData() async {
    try {
      final userId = supabase.auth.currentUser!.id;
      final today = _getTodayDate();

      await supabase.from('hydration_log').upsert({
        'user_id': userId,
        'date': today,
        'current_amount': _currentAmount,
        'goal_amount': _goalAmount,
      }, onConflict: 'user_id, date');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save hydration data: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _updateProgress() {
    setState(() {
      _progress = (_currentAmount / _goalAmount).clamp(0.0, 1.0);
    });
  }

  void _addWater(double amount) {
    setState(() {
      final bool wasGoalMet = _progress == 1.0;
      _currentAmount = (_currentAmount + amount).clamp(0.0, _goalAmount);
      _updateProgress();

      if (_progress == 1.0 && !wasGoalMet) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('🎉 Goal reached! Well done!'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    });
    _saveHydrationData();
  }

  void _resetWater() {
    setState(() {
      _currentAmount = 0.0;
      _updateProgress();
    });
    _saveHydrationData();
  }

  void _showEditGoalDialog(BuildContext context) {
    _goalEditController.text = _goalAmount.toStringAsFixed(1);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Daily Goal'),
          content: TextField(
            controller: _goalEditController,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              suffixText: 'L',
              labelText: 'Goal',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final double? newGoal =
                    double.tryParse(_goalEditController.text);
                if (newGoal != null && newGoal > 0) {
                  setState(() {
                    _goalAmount = newGoal;
                    _updateProgress();
                  });
                  _saveHydrationData();
                  Navigator.pop(context);
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _goalEditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 24),
            Expanded(child: _buildWaterGlass()),
            const SizedBox(height: 24),
            _buildWaterLoggingTitle(),
            const SizedBox(height: 16),
            _buildWaterLoggingButtons(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Hydration',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        IconButton(
          icon: Icon(Icons.edit, color: Theme.of(context).primaryColor),
          tooltip: 'Edit Goal',
          onPressed: () => _showEditGoalDialog(context),
        ),
      ],
    );
  }

  Widget _buildWaterLoggingTitle() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Log Water',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        TextButton.icon(
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Reset'),
          onPressed: _resetWater,
          style: TextButton.styleFrom(foregroundColor: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildWaterGlass() {
    final String percent = (_progress * 100).toStringAsFixed(0);
    final Color primaryColor = Theme.of(context).primaryColor;

    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blueGrey.shade100, width: 4),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        LayoutBuilder(builder: (context, constraints) {
          final double glassHeight = constraints.maxHeight;
          return Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 750),
              curve: Curves.easeInOutCubic,
              height: glassHeight * _progress,
              width: double.infinity,
              decoration: BoxDecoration(
                color: primaryColor,
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          );
        }),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$percent%',
              style: TextStyle(
                fontSize: 52,
                fontWeight: FontWeight.bold,
                color: _progress > 0.4 ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${_currentAmount.toStringAsFixed(1)}L / ${_goalAmount.toStringAsFixed(1)}L',
              style: TextStyle(
                fontSize: 18,
                color: _progress > 0.6
                    ? Colors.white.withAlpha(204) 
                    : Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildWaterLoggingButtons() {
    return Row(
      children: [
        Expanded(
          child: _buildWaterButton(
            amount: 0.25,
            label: '250ml',
            icon: Icons.local_drink_rounded,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildWaterButton(
            amount: 0.5,
            label: '500ml',
            icon: Icons.opacity_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildWaterButton({
    required double amount,
    required String label,
    required IconData icon,
  }) {
    final Color primaryColor = Theme.of(context).primaryColor;

    return InkWell(
      onTap: () => _addWater(amount),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: primaryColor.withAlpha(26), 
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: primaryColor.withAlpha(77), 
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: primaryColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: primaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}