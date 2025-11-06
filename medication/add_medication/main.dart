import 'package:flutter/material.dart';

// Main function to run the app
void main() {
  runApp(const MyApp());
}

// MyApp is the root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Define the primary color from your CSS
    const Color primaryColor = Color(0xFF13a4ec);

    // Define the light theme for the app
    final ThemeData lightTheme = ThemeData(
      brightness: Brightness.light,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: const Color(0xFFf6f7f8),
      fontFamily: 'Manrope',
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
        titleTextStyle: TextStyle(
          color: Colors.black,
          fontFamily: 'Manrope',
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: primaryColor.withOpacity(0.1),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
          minimumSize: const Size(double.infinity, 56),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 4,
          shadowColor: primaryColor.withOpacity(0.4),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        selectedLabelStyle: TextStyle(fontWeight: FontWeight.w500),
      ),
    );
    
    // You can similarly define a darkTheme if needed

    return MaterialApp(
      title: 'Stitch Design',
      theme: lightTheme,
      // darkTheme: darkTheme, // Uncomment to add dark mode
      // themeMode: ThemeMode.system, // Use system setting
      home: const AddMedicationScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

// The main screen widget
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  int _selectedIndex = 0; // To track the selected tab in the bottom navigation

  // Options for the dropdown menus
  final List<String> _frequencyOptions = ['Once a day', 'Twice a day', 'As needed'];
  String? _selectedFrequency = 'Once a day';
  
  final List<String> _reminderOptions = ['8:00 AM', '12:00 PM', '6:00 PM'];
  String? _selectedReminder = '8:00 AM';

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            // Handle back button press
          },
        ),
        title: const Text('Add Medication'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medication Name Field
            const Text(
              'Medication Name',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'e.g., Ibuprofen',
              ),
            ),
            const SizedBox(height: 16),

            // Dosage Field
            const Text(
              'Dosage',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            TextFormField(
              decoration: const InputDecoration(
                hintText: 'e.g., 200mg',
              ),
            ),
            const SizedBox(height: 16),

            // Frequency Dropdown
            const Text(
              'Frequency',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedFrequency,
              items: _frequencyOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedFrequency = newValue;
                });
              },
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 16),

            // Reminder Time Dropdown
            const Text(
              'Reminder Time',
              style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedReminder,
              items: _reminderOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedReminder = newValue;
                });
              },
              decoration: const InputDecoration(),
            ),
            const SizedBox(height: 32),

            // Save Button
            ElevatedButton(
              onPressed: () {
                // Handle save medication action
              },
              child: const Text('Save Medication'),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.medical_services_outlined),
            activeIcon: Icon(Icons.medical_services),
            label: 'Medications',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.water_drop_outlined),
            activeIcon: Icon(Icons.water_drop),
            label: 'Hydration',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Stock',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}