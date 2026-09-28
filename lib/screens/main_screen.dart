import 'package:flutter/material.dart';
// FIX: Use relative imports
import 'hydration_screen.dart'; 
import 'medication_list_screen.dart'; 
import 'reminder_settings_screen.dart'; 

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  // 1. Controls which tab is currently selected
  int _currentIndex = 0;

  // 2. A list of all your main screens
  final List<Widget> _screens = [
    const MedicationListScreen(),
    const HydrationScreen(),
    const ReminderSettingsScreen(), // Or a future "Profile" screen
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 3. Display the currently selected screen
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // 4. The Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          // 5. Update the state when a tab is tapped
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.medication_liquid),
            label: 'Medications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop),
            label: 'Hydration',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}