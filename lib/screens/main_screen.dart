import 'package:flutter/material.dart';

import 'package:medi_mate/screens/medication_list_screen.dart';
import 'package:medi_mate/screens/hydration_screen.dart';
import 'package:medi_mate/screens/medicine_stock_screen.dart';
import 'package:medi_mate/screens/reminder_settings_screen.dart';
import 'package:medi_mate/screens/voice_reminder_page.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  static const Color primary = Color(0xFF7C3AED);
  static const Color background = Color(0xFFF8F6FF);
  static const Color muted = Color(0xFF8B829B);

  late final List<Widget> _screens = [
    const MedicationListScreen(),
    const HydrationScreen(),
    const MedicineStockScreen(),
    const ReminderSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      // IMPORTANT:
      // Do not wrap this body in Center, ConstrainedBox or SizedBox.
      // The individual pages control their own 430px mobile-style layout.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // Voice reminder button
      floatingActionButton: _currentIndex == 2
          ? null
          : FloatingActionButton(
              mini: true,
              backgroundColor: primary,
              elevation: 5,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const VoiceReminderPage(),
                  ),
                );
              },
              child: const Icon(
                Icons.mic_rounded,
                color: Colors.white,
                size: 19,
              ),
            ),

      // Bottom navigation
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          height: 64,
          color: background,
          padding: const EdgeInsets.only(bottom: 2),
          child: Center(
            child: SizedBox(
              width: 430,
              height: 58,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),
                      blurRadius: 12,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    _navItem(
                      index: 0,
                      icon: Icons.medication_rounded,
                      label: 'Medications',
                    ),
                    _navItem(
                      index: 1,
                      icon: Icons.water_drop_rounded,
                      label: 'Hydration',
                    ),
                    _navItem(
                      index: 2,
                      icon: Icons.inventory_2_rounded,
                      label: 'Stock',
                    ),
                    _navItem(
                      index: 3,
                      icon: Icons.settings_rounded,
                      label: 'Settings',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _currentIndex == index;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (_currentIndex != index) {
              setState(() {
                _currentIndex = index;
              });
            }
          },
          borderRadius: BorderRadius.circular(14),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  width: selected ? 34 : 28,
                  height: selected ? 25 : 22,
                  decoration: BoxDecoration(
                    color: selected
                        ? primary.withAlpha(22)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(
                    icon,
                    size: selected ? 18 : 17,
                    color: selected ? primary : muted,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 8,
                    height: 1,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? primary : muted,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
