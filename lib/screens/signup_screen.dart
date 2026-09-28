import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController =
      TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agreedToTerms = false;

  static const Color _darkText = Color(0xFF211738);
  static const Color _mediumText = Color(0xFF71677F);
  static const Color _purple = Color(0xFF6D28D9);
  static const Color _lightPurple = Color(0xFF8B5CF6);
  static const Color _fieldBackground = Color(0xFFFAF8FE);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  // ================================================================
  // SIGN UP
  // ================================================================

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_agreedToTerms) {
      _showMessage(
        'Please agree to the terms and conditions.',
        error: true,
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      final response = await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name':
              _fullNameController.text.trim(),
        },
      );

      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sign up successful! Please check your email at '
              '${_emailController.text.trim()} to confirm your account.',
            ),
            backgroundColor: const Color(0xFF16A34A),
            duration: const Duration(seconds: 6),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );

        Navigator.pushReplacementNamed(
          context,
          '/login',
        );
      } else {
        if (mounted) {
          _showMessage(
            'Sign up failed. Please try again.',
            error: true,
          );
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showMessage(
          e.message,
          error: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Sign up failed: ${e.toString()}',
          error: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ================================================================
  // MESSAGE
  // ================================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
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
            // BACKGROUND
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
            // MAIN CONTENT
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
  // DESKTOP
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
  // MOBILE
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
  // FORM
  // ================================================================

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          // ========================================================
          // LABEL
          // ========================================================

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
              'GET STARTED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
                color: _purple,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ========================================================
          // HEADING
          // ========================================================

          const Text(
            'Create Your Account',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w800,
              color: _darkText,
              height: 1.15,
            ),
          ),

          const SizedBox(height: 12),

          const Text(
            'Create your MediMate account and start managing your daily health needs.',
            style: TextStyle(
              fontSize: 15,
              height: 1.5,
              color: _mediumText,
            ),
          ),

          const SizedBox(height: 27),

          // ========================================================
          // FULL NAME
          // ========================================================

          const Text(
            'Full Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF34264B),
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller: _fullNameController,
            textCapitalization:
                TextCapitalization.words,
            textInputAction:
                TextInputAction.next,
            style: const TextStyle(
              color: _darkText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: _purple,
            decoration: _inputDecoration(
              hint: 'Enter your full name',
              icon:
                  Icons.person_outline_rounded,
            ),
            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter your full name';
              }

              if (value.trim().length < 2) {
                return 'Name must be at least 2 characters';
              }

              return null;
            },
          ),

          const SizedBox(height: 17),

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

          const SizedBox(height: 17),

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
                TextInputAction.next,
            style: const TextStyle(
              color: _darkText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: _purple,
            decoration: _inputDecoration(
              hint: 'Enter your password',
              icon:
                  Icons.lock_outline_rounded,
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
                  color:
                      const Color(0xFF8B829B),
                ),
              ),
            ),
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return 'Please enter your password';
              }

              if (value.length < 8) {
                return 'Password must be at least 8 characters';
              }

              if (!RegExp(
                r'^(?=.*[a-zA-Z])(?=.*[0-9])',
              ).hasMatch(value)) {
                return 'Password must contain letters and numbers';
              }

              return null;
            },
          ),

          const SizedBox(height: 17),

          // ========================================================
          // CONFIRM PASSWORD
          // ========================================================

          const Text(
            'Confirm Password',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF34264B),
            ),
          ),

          const SizedBox(height: 8),

          TextFormField(
            controller:
                _confirmPasswordController,
            obscureText:
                _obscureConfirmPassword,
            textInputAction:
                TextInputAction.done,
            style: const TextStyle(
              color: _darkText,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
            cursorColor: _purple,
            decoration: _inputDecoration(
              hint: 'Confirm your password',
              icon:
                  Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword =
                        !_obscureConfirmPassword;
                  });
                },
                icon: Icon(
                  _obscureConfirmPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color:
                      const Color(0xFF8B829B),
                ),
              ),
            ),
            validator: (value) {
              if (value == null ||
                  value.isEmpty) {
                return 'Please confirm your password';
              }

              if (value !=
                  _passwordController.text) {
                return 'Passwords do not match';
              }

              return null;
            },
          ),

          const SizedBox(height: 18),

          // ========================================================
          // PASSWORD INFO
          // ========================================================

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1EAFF),
              borderRadius:
                  BorderRadius.circular(17),
              border: Border.all(
                color: const Color(0xFFE0D3F7),
              ),
            ),
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFE1D3FF),
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.shield_outlined,
                    color: _purple,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password requirements',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight:
                              FontWeight.w800,
                          color:
                              Color(0xFF34264B),
                        ),
                      ),
                      SizedBox(height: 7),
                      _Requirement(
                        text:
                            'At least 8 characters',
                      ),
                      SizedBox(height: 4),
                      _Requirement(
                        text:
                            'Contains letters and numbers',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          // ========================================================
          // TERMS
          // ========================================================

          GestureDetector(
            onTap: () {
              setState(() {
                _agreedToTerms =
                    !_agreedToTerms;
              });
            },
            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: _agreedToTerms,
                  activeColor: _purple,
                  checkColor: Colors.white,
                  side: const BorderSide(
                    color: Color(0xFF9B93A8),
                    width: 1.5,
                  ),
                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(5),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _agreedToTerms =
                          value ?? false;
                    });
                  },
                ),
                const SizedBox(width: 4),
                const Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: 12,
                    ),
                    child: Text(
                      'I agree to the Terms of Service '
                      'and Privacy Policy',
                      style: TextStyle(
                        color: _mediumText,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ========================================================
          // CREATE ACCOUNT BUTTON
          // ========================================================

          _buildCreateAccountButton(),
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
  // CREATE ACCOUNT BUTTON
  // ================================================================

  Widget _buildCreateAccountButton() {
    final disabled =
        _isLoading || !_agreedToTerms;

    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled
              ? const LinearGradient(
                  colors: [
                    Color(0xFFB9A8D8),
                    Color(0xFF9D8BC1),
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    _lightPurple,
                    _purple,
                  ],
                ),
          borderRadius:
              BorderRadius.circular(17),
          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color:
                        _purple.withOpacity(0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 9),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: disabled
              ? null
              : _handleSignup,
          style: ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                Colors.transparent,
            disabledForegroundColor:
                Colors.white,
            shadowColor:
                Colors.transparent,
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
                      'Create Account',
                      style: TextStyle(
                        fontSize: 15,
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
          width: 210,
          height: 210,
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
              width: 145,
              height: 145,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Container(
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color:
                        const Color(0xFFE9DDFF),
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    color: _purple,
                    size: 45,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Welcome to MediMate',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: Color(0xFF34264B),
          ),
        ),

        const SizedBox(height: 8),

        const Text(
          'Keep your medicines, reminders and\ndaily health routine organized.',
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
// PASSWORD REQUIREMENT
// ================================================================

class _Requirement extends StatelessWidget {
  final String text;

  const _Requirement({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF7C3AED),
          size: 16,
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF71677F),
            ),
          ),
        ),
      ],
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