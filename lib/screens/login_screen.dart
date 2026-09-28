import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/push_notification_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  static const Color _darkText = Color(0xFF211738);
  static const Color _mediumText = Color(0xFF71677F);
  static const Color _purple = Color(0xFF6D28D9);
  static const Color _lightPurple = Color(0xFF8B5CF6);
  static const Color _fieldBackground = Color(0xFFFAF8FE);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ================================================================
  // LOGIN
  // ================================================================

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      await supabase.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // FCM is non-critical.
      // If it fails, login still continues.
      try {
        await _saveFCMToken();
      } catch (e) {
        debugPrint(
          'FCM token saving failed: $e',
        );
      }

      if (!mounted) return;

      Navigator.pushNamed(
        context,
        '/home',
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showError(e.message);
    } catch (e) {
      if (!mounted) return;

      _showError(
        'An unexpected error occurred. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ================================================================
  // SAVE FCM TOKEN
  // ================================================================

  Future<void> _saveFCMToken() async {
    final token =
        await PushNotificationService.getToken();

    if (token == null || token.isEmpty) {
      debugPrint(
        'FCM token is null or empty.',
      );
      return;
    }

    final supabase = Supabase.instance.client;

    final userId =
        supabase.auth.currentUser?.id;

    if (userId == null) {
      debugPrint(
        'No user ID found. Skipping FCM token save.',
      );
      return;
    }

    await supabase.from('profiles').upsert({
      'id': userId,
      'Token': token,
    });

    debugPrint(
      'FCM token saved successfully.',
    );
  }

  // ================================================================
  // ERROR MESSAGE
  // ================================================================

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ================================================================
  // BUILD
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F0FF),
      body: SafeArea(
        child: Stack(
          children: [
            // ========================================================
            // BACKGROUND DECORATIONS
            // ========================================================

            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  color: Color(0xFFE4D5FF),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              top: -70,
              right: -90,
              child: Container(
                width: 280,
                height: 280,
                decoration: const BoxDecoration(
                  color: Color(0xFFD8C5FF),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            Positioned(
              bottom: -130,
              left: -100,
              child: Container(
                width: 300,
                height: 300,
                decoration: const BoxDecoration(
                  color: Color(0xFFE9DEFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ========================================================
            // PURPLE CURVED HEADER
            // ========================================================

            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: ClipPath(
                clipper: _HeaderClipper(),
                child: Container(
                  height: isSmallScreen ? 220 : 250,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF8B5CF6),
                        Color(0xFF6D28D9),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ========================================================
            // BACK BUTTON
            // ========================================================

            Positioned(
              top: 20,
              left: 20,
              child: Material(
                color: Colors.white,
                elevation: 4,
                shadowColor: Colors.black26,
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: () {
                    Navigator.pop(context);
                  },
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.arrow_back_rounded,
                      color: Color(0xFF5422B8),
                      size: 24,
                    ),
                  ),
                ),
              ),
            ),

            // ========================================================
            // DECORATIVE DOTS
            // ========================================================

            Positioned(
              top: 32,
              right: 30,
              child: Column(
                children: [
                  Row(
                    children: [
                      _dot(),
                      const SizedBox(width: 8),
                      _dot(),
                      const SizedBox(width: 8),
                      _dot(),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const SizedBox(width: 32),
                      _dot(),
                      const SizedBox(width: 8),
                      _dot(),
                    ],
                  ),
                ],
              ),
            ),

            // ========================================================
            // CONTENT
            // ========================================================

            Center(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal:
                      isSmallScreen ? 20 : 40,
                  vertical: 30,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 920,
                  ),
                  child: isSmallScreen
                      ? _buildMobileLayout()
                      : _buildDesktopLayout(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================================================================
  // DESKTOP LAYOUT
  // ================================================================

  Widget _buildDesktopLayout() {
    return Container(
      margin: const EdgeInsets.only(top: 60),
      padding: const EdgeInsets.all(42),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(34),
        border: Border.all(
          color: const Color(0xFFE3D7F8),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.16),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 6,
            child: _buildForm(),
          ),
          const SizedBox(width: 50),
          Expanded(
            flex: 4,
            child: _buildIllustration(),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // MOBILE LAYOUT
  // ================================================================

  Widget _buildMobileLayout() {
    return Container(
      margin: const EdgeInsets.only(top: 90),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFE3D7F8),
        ),
        boxShadow: [
          BoxShadow(
            color: _purple.withOpacity(0.15),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildIllustration(),
          const SizedBox(height: 25),
          _buildForm(),
        ],
      ),
    );
  }

  // ================================================================
  // LOGIN FORM
  // ================================================================

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // Small label
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 6,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF0E9FF),
              borderRadius:
                  BorderRadius.circular(30),
            ),
            child: const Text(
              'WELCOME BACK',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: _purple,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // Heading
          const Text(
            'Welcome Back!',
            style: TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: _darkText,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Sign in to keep track of your medications, reminders and hydration.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: _mediumText,
            ),
          ),

          const SizedBox(height: 28),

          // ========================================================
          // EMAIL
          // ========================================================

          const Text(
            'Email Address',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF34264B),
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _emailController,
            keyboardType:
                TextInputType.emailAddress,
            textInputAction:
                TextInputAction.next,
            style: const TextStyle(
              color: _darkText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: _purple,
            decoration: _inputDecoration(
              hint: 'Enter your email address',
              icon: Icons.email_outlined,
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter your email';
              }

              if (!value.contains('@') ||
                  !value.contains('.')) {
                return 'Please enter a valid email';
              }

              return null;
            },
          ),

          const SizedBox(height: 18),

          // ========================================================
          // PASSWORD
          // ========================================================

          const Text(
            'Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF34264B),
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction:
                TextInputAction.done,
            onFieldSubmitted: (_) {
              if (!_isLoading) {
                _handleLogin();
              }
            },
            style: const TextStyle(
              color: _darkText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: _purple,
            decoration: _inputDecoration(
              hint: 'Enter your password',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword =
                        !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF8B829B),
                ),
              ),
            ),
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return 'Please enter your password';
              }

              if (value.length < 6) {
                return 'Password must be at least 6 characters';
              }

              return null;
            },
          ),

          // ========================================================
          // FORGOT PASSWORD
          // ========================================================

          Align(
            alignment:
                Alignment.centerRight,
            child: TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/forgot-password',
                );
              },
              style: TextButton.styleFrom(
                foregroundColor: _purple,
                padding: const EdgeInsets.symmetric(
                  horizontal: 4,
                  vertical: 8,
                ),
              ),
              child: const Text(
                'Forgot Password?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ========================================================
          // SIGN IN BUTTON
          // ========================================================

          _buildSignInButton(),

          const SizedBox(height: 24),

          // ========================================================
          // DIVIDER
          // ========================================================

          Row(
            children: [
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xFFE5DEEF),
                ),
              ),
              const Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'OR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF968CA2),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 1,
                  color: const Color(0xFFE5DEEF),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ========================================================
          // SIGN UP
          // ========================================================

          Center(
            child: Wrap(
              alignment: WrapAlignment.center,
              children: [
                const Text(
                  "Don't have an account? ",
                  style: TextStyle(
                    color: _mediumText,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/signup',
                    );
                  },
                  child: const Text(
                    'Sign Up',
                    style: TextStyle(
                      color: _purple,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================================================================
  // INPUT DECORATION
  // ================================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFAAA2B7),
        fontSize: 14,
      ),
      prefixIcon: Icon(
        icon,
        color: _purple,
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _fieldBackground,
      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFDCCEF4),
          width: 1.3,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _purple,
          width: 2,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.2,
        ),
      ),
      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.5,
        ),
      ),
    );
  }

  // ================================================================
  // SIGN IN BUTTON
  // ================================================================

  Widget _buildSignInButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              _lightPurple,
              _purple,
            ],
          ),
          borderRadius:
              BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: _purple.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed:
              _isLoading ? null : _handleLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                Colors.transparent,
            disabledForegroundColor:
                Colors.white,
            shadowColor: Colors.transparent,
            elevation: 0,
            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(17),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 23,
                  height: 23,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      Colors.white,
                    ),
                  ),
                )
              : const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      'Sign In',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),
                    SizedBox(width: 10),
                    Icon(
                      Icons.arrow_forward_rounded,
                      size: 21,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ================================================================
  // ILLUSTRATION
  // ================================================================

  Widget _buildIllustration() {
    return Column(
      children: [
        Container(
          width: 220,
          height: 220,
          decoration: BoxDecoration(
            color: const Color(0xFFF0E8FF),
            shape: BoxShape.circle,
            border: Border.all(
              color: const Color(0xFFE1D2FF),
              width: 2,
            ),
          ),
          child: Center(
            child: Container(
              width: 150,
              height: 150,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFE9DDFF),
                    borderRadius:
                        BorderRadius.circular(26),
                  ),
                  child: const Icon(
                    Icons.medication_rounded,
                    color: _purple,
                    size: 52,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        const Text(
          'Your health, simplified',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF34264B),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Manage your medications,\n'
          'reminders and daily health needs.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF81778F),
          ),
        ),

        const SizedBox(height: 20),

        Row(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            _featureIcon(
              Icons.medication_outlined,
              'Medicines',
            ),
            const SizedBox(width: 12),
            _featureIcon(
              Icons.notifications_none_rounded,
              'Reminders',
            ),
            const SizedBox(width: 12),
            _featureIcon(
              Icons.water_drop_outlined,
              'Hydration',
            ),
          ],
        ),
      ],
    );
  }

  // ================================================================
  // FEATURE ICON
  // ================================================================

  Widget _featureIcon(
    IconData icon,
    String label,
  ) {
    return Column(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFF1EAFF),
            borderRadius:
                BorderRadius.circular(13),
          ),
          child: Icon(
            icon,
            color: _purple,
            size: 21,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF81778F),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // DECORATIVE DOT
  // ================================================================

  Widget _dot() {
    return Container(
      width: 7,
      height: 7,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }
}

// ================================================================
// CURVED HEADER
// ================================================================

class _HeaderClipper
    extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(
      0,
      size.height - 35,
    );

    path.quadraticBezierTo(
      size.width * 0.25,
      size.height - 5,
      size.width * 0.50,
      size.height - 32,
    );

    path.quadraticBezierTo(
      size.width * 0.76,
      size.height - 62,
      size.width,
      size.height - 20,
    );

    path.lineTo(
      size.width,
      0,
    );

    path.close();

    return path;
  }

  @override
  bool shouldReclip(
    CustomClipper<Path> oldClipper,
  ) {
    return false;
  }
}