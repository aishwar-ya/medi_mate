import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:medi_mate/screens/login_screen.dart';
import 'package:medi_mate/screens/medication_list_screen.dart';
import 'package:medi_mate/screens/hydration_screen.dart';
import 'package:medi_mate/screens/barcode_scanner_screen.dart';
import 'package:medi_mate/screens/medicine_stock_screen.dart';
import 'package:medi_mate/screens/reminder_settings_screen.dart';
import 'package:medi_mate/screens/signup_screen.dart';
import 'package:medi_mate/services/notification_service.dart';

// 1. Import your new voice reminder screen
// (Make sure the path is correct for your project structure)
import 'package:medi_mate/screens/voice_reminder_page.dart'; // <-- ADDED

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();

  await Supabase.initialize(
    url: 'https://szqdwessijrfzbvoxtkd.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InN6cWR3ZXNzaWpyZnpidm94dGtkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjA2NzgwMDUsImV4cCI6MjA3NjI1NDAwNX0.NySJkCKDoNILDaGB9mJgvRTAVX80KKlScMoK4EMxuW8',
  );

  runApp(const MediMateApp());
}

class MediMateApp extends StatelessWidget {
  const MediMateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MediMate',
      theme: ThemeData(
        primaryColor: const Color(0xFF13a4ec),
        scaffoldBackgroundColor: const Color(0xFFF6F7F8),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF6F7F8),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black),
          titleTextStyle: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        fontFamily: 'Manrope',
      ),
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF13a4ec),
        scaffoldBackgroundColor: const Color(0xFF101c22),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF101c22),
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.white),
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomePage(),
        // 2. Add the route for your new screen
        '/voice_reminder': (context) => const VoiceReminderPage(), // <-- ADDED
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // If logged in -> go to home
        if (session != null) {
          return const HomePage();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const MedicationListScreen(),
    const HydrationScreen(),
    const BarcodeScannerScreen(),
    const MedicineStockScreen(),
    const ReminderSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),

      // 3. Add the Floating Action Button
      floatingActionButton: FloatingActionButton( // <-- ADDED
        onPressed: () {
          // This will open your new page
          Navigator.pushNamed(context, '/voice_reminder');
        },
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.mic, color: Colors.white), // Added white color for contrast
      ), // <-- ADDED

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(26),
              blurRadius: 4,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          elevation: 0,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          selectedLabelStyle: const TextStyle(fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.medication),
              label: 'Medications',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.water_drop),
              label: 'Hydration',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.qr_code_scanner),
              label: 'Scan',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory),
              label: 'Stock',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }
}