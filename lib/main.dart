import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:firebase_core/firebase_core.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:medi_mate/screens/splash_screen.dart';

import 'firebase_options.dart';

import 'package:medi_mate/services/notification_service.dart';

import 'package:medi_mate/services/push_notification_service.dart';

// Screens

import 'package:medi_mate/screens/login_screen.dart';

import 'package:medi_mate/screens/signup_screen.dart';

import 'package:medi_mate/screens/reset_password_screen.dart';

import 'package:medi_mate/screens/forgot_password_screen.dart';

import 'package:medi_mate/screens/medication_list_screen.dart';

import 'package:medi_mate/screens/hydration_screen.dart';

import 'package:medi_mate/screens/medicine_stock_screen.dart';

import 'package:medi_mate/screens/reminder_settings_screen.dart';

import 'package:medi_mate/screens/voice_reminder_page.dart';

// =============================================================

// MAIN

// =============================================================

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ===========================================================

  // FIREBASE

  // ===========================================================

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    print('✅ Firebase initialized');
  } catch (e) {
    print('⚠️ Firebase failed: $e');
  }

  // ===========================================================

  // LOCAL NOTIFICATIONS

  // ===========================================================

  try {
    await NotificationService.init();

    print('✅ Notification service initialized');
  } catch (e) {
    print('⚠️ Notification service unavailable: $e');
  }

  // ===========================================================

  // PUSH NOTIFICATIONS

  // ===========================================================

  try {
    await PushNotificationService.init();

    print('✅ PushNotificationService initialized successfully.');
  } catch (e) {
    print('⚠️ Push notifications unavailable: $e');
  }

  // ===========================================================

  // SUPABASE

  // ===========================================================

  await Supabase.initialize(
    url: 'https://szqdwessijrfzbvoxtkd.supabase.co',

    publishableKey: const String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),

    authOptions: const FlutterAuthClientOptions(
      // Password recovery now uses an OTP code entered manually.

      // There is no recovery URL/code exchange in this app.
      detectSessionInUri: false,

      authFlowType: AuthFlowType.pkce,
    ),
  );

  print('✅ Supabase initialized');

  runApp(const MediMateApp());
}

// Kept for compatibility with the existing project structure.

void registerServiceWorker() {}

// =============================================================

// MEDIMATE APP

// =============================================================

class MediMateApp extends StatefulWidget {
  const MediMateApp({super.key});

  @override
  State<MediMateApp> createState() => _MediMateAppState();
}

class _MediMateAppState extends State<MediMateApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,

      debugShowCheckedModeBanner: false,

      title: 'MediMate',

      // =======================================================

      // LIGHT THEME

      // =======================================================
      theme: ThemeData(
        primaryColor: const Color(0xFF13A4EC),

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

      // =======================================================

      // DARK THEME

      // =======================================================
      darkTheme: ThemeData.dark().copyWith(
        primaryColor: const Color(0xFF13A4EC),

        scaffoldBackgroundColor: const Color(0xFF101C22),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF101C22),

          elevation: 0,

          iconTheme: IconThemeData(color: Colors.white),

          titleTextStyle: TextStyle(
            color: Colors.white,

            fontSize: 20,

            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      // =======================================================

      // ROUTES

      // =======================================================
      initialRoute: '/splash',

      routes: {
        '/': (context) => const AuthGate(),

        '/splash': (context) => const SplashScreen(),

        '/auth': (context) => const AuthGate(),

        '/login': (context) => const LoginScreen(),

        '/signup': (context) => const SignupScreen(),

        '/forgot-password': (context) => const ForgotPasswordScreen(),

        // The OTP reset screen receives the email as a route argument.

        // The ForgotPasswordScreen can also open it directly with the

        // email already supplied to its constructor.
        '/reset-password': (context) {
          final email = ModalRoute.of(context)?.settings.arguments as String?;

          if (email == null || email.trim().isEmpty) {
            return const ForgotPasswordScreen();
          }

          return ResetPasswordScreen(email: email);
        },

        '/home': (context) => const HomePage(),

        '/voice_reminder': (context) => const VoiceReminderPage(),

        '/exploreHome': (context) => const HomePage(),
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
  }
}

// =============================================================

// AUTH GATE

// =============================================================

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _isLoading = true;

  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();

    _checkAuth();
  }

  // ===========================================================

  // CHECK AUTH

  // ===========================================================

  Future<void> _checkAuth() async {
    try {
      await Future.delayed(const Duration(milliseconds: 500));

      final session = Supabase.instance.client.auth.currentSession;

      if (mounted) {
        setState(() {
          _isLoggedIn = session != null;

          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ Auth check error: $e');

      if (mounted) {
        setState(() {
          _isLoggedIn = false;

          _isLoading = false;
        });
      }
    }
  }

  // ===========================================================

  // BUILD

  // ===========================================================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              CircularProgressIndicator(),

              SizedBox(height: 16),

              Text('Loading MediMate...'),
            ],
          ),
        ),
      );
    }

    return _isLoggedIn ? const HomePage() : const LoginScreen();
  }
}

// =============================================================

// HOME PAGE

// =============================================================

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

    const MedicineStockScreen(),

    const ReminderSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const purple = Color(0xFF7C3AED);

    const pageBackground = Color(0xFFF8F6FF);

    // Keep the selected screen completely unconstrained here.

    // The individual screens already handle their 430px mobile layout.

    return Scaffold(
      backgroundColor: pageBackground,

      body: _screens[_currentIndex],

      floatingActionButton:
          _currentIndex == 2
              ? null
              : FloatingActionButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/voice_reminder');
                },

                backgroundColor: purple,

                mini: true,

                child: const Icon(Icons.mic, color: Colors.white, size: 18),
              ),

      bottomNavigationBar: SafeArea(
        top: false,

        child: Container(
          height: 62,

          color: pageBackground,

          child: Center(
            child: SizedBox(
              width: 430,

              height: 58,

              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,

                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),

                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(18),

                      blurRadius: 10,

                      offset: const Offset(0, -2),
                    ),
                  ],
                ),

                child: Row(
                  children: [
                    _bottomNavItem(
                      0,

                      Icons.medication_rounded,

                      'Medications',

                      purple,
                    ),

                    _bottomNavItem(
                      1,

                      Icons.water_drop_rounded,

                      'Hydration',

                      purple,
                    ),

                    _bottomNavItem(
                      2,

                      Icons.inventory_2_rounded,

                      'Stock',

                      purple,
                    ),

                    _bottomNavItem(
                      3,

                      Icons.settings_rounded,

                      'Settings',

                      purple,
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

  Widget _bottomNavItem(
    int index,

    IconData icon,

    String label,

    Color activeColor,
  ) {
    final selected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _currentIndex = index;
          });
        },

        borderRadius: BorderRadius.circular(14),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Icon(
              icon,

              size: selected ? 21 : 19,

              color: selected ? activeColor : const Color(0xFF9A91A8),
            ),

            const SizedBox(height: 3),

            Text(
              label,

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

              style: TextStyle(
                color: selected ? activeColor : const Color(0xFF8B829B),

                fontSize: 8.5,

                fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
