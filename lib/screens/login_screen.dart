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

    final supabase =
        Supabase.instance.client;

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
        backgroundColor:
            const Color(0xFFDC2626),
        behavior:
            SnackBarBehavior.floating,
        margin:
            const EdgeInsets.all(20),
        shape:
            RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
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

    final frameWidth =
        size.width < 430 ? size.width : 430.0;

    return Scaffold(
      backgroundColor:
          const Color(0xFFF6F0FF),

      body: SafeArea(
        child: Center(
          child: SizedBox(
            width: frameWidth,
            height: double.infinity,
            child: Stack(
              children: [

                // ==================================================
                // BACKGROUND DECORATIONS
                // ==================================================

                Positioned(
                  top: -100,
                  left: -80,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFFE4D5FF),
                      shape:
                          BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  top: -70,
                  right: -90,
                  child: Container(
                    width: 280,
                    height: 280,
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFFD8C5FF),
                      shape:
                          BoxShape.circle,
                    ),
                  ),
                ),

                Positioned(
                  bottom: -130,
                  left: -100,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration:
                        const BoxDecoration(
                      color:
                          Color(0xFFE9DEFF),
                      shape:
                          BoxShape.circle,
                    ),
                  ),
                ),

                // ==================================================
                // PURPLE HEADER
                // ==================================================

                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: ClipPath(
                    clipper:
                        _HeaderClipper(),
                    child: Container(
                      height: 175,
                      decoration:
                          const BoxDecoration(
                        gradient:
                            LinearGradient(
                          begin:
                              Alignment.topLeft,
                          end:
                              Alignment.bottomRight,
                          colors: [
                            Color(0xFF8B5CF6),
                            Color(0xFF6D28D9),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                // ==================================================
                // MEDIMATE BRAND
                // ==================================================

                Positioned(
                  top: 27,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment:
                        MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration:
                            BoxDecoration(
                          color: Colors.white
                              .withOpacity(
                            0.96,
                          ),
                          borderRadius:
                              BorderRadius
                                  .circular(
                            11,
                          ),
                        ),
                        child:
                            const Icon(
                          Icons
                              .medication_rounded,
                          color:
                              Color(0xFF6D28D9),
                          size: 22,
                        ),
                      ),

                      const SizedBox(
                        width: 9,
                      ),

                      const Text(
                        'MediMate',
                        style:
                            TextStyle(
                          color:
                              Colors.white,
                          fontSize: 23,
                          fontWeight:
                              FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // DECORATIVE DOTS
                // ==================================================

                Positioned(
                  top: 31,
                  right: 30,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          _dot(),
                          const SizedBox(
                            width: 8,
                          ),
                          _dot(),
                          const SizedBox(
                            width: 8,
                          ),
                          _dot(),
                        ],
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Row(
                        children: [
                          const SizedBox(
                            width: 32,
                          ),
                          _dot(),
                          const SizedBox(
                            width: 8,
                          ),
                          _dot(),
                        ],
                      ),
                    ],
                  ),
                ),

                // ==================================================
                // CONTENT
                // ==================================================

                Center(
                  child:
                      SingleChildScrollView(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      20,
                      20,
                      20,
                      20,
                    ),
                    child:
                        ConstrainedBox(
                      constraints:
                          const BoxConstraints(
                        maxWidth: 430,
                      ),
                      child:
                          _buildMobileLayout(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ================================================================
  // MOBILE LAYOUT
  // ================================================================

  Widget _buildMobileLayout() {
    return Container(
      margin:
          const EdgeInsets.only(
        top: 55,
      ),

      padding:
          const EdgeInsets.fromLTRB(
        20,
        16,
        20,
        18,
      ),

      decoration:
          BoxDecoration(
        color: Colors.white,

        borderRadius:
            BorderRadius.circular(
          30,
        ),

        border: Border.all(
          color:
              const Color(
            0xFFE3D7F8,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
                _purple.withOpacity(
              0.15,
            ),
            blurRadius: 30,
            offset:
                const Offset(
              0,
              15,
            ),
          ),
        ],
      ),

      child: Column(
        children: [

          // Smaller illustration area
          _buildIllustration(),

          const SizedBox(
            height: 8,
          ),

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

          // ========================================================
          // SMALL LABEL
          // ========================================================

          Container(
            padding:
                const EdgeInsets
                    .symmetric(
              horizontal: 12,
              vertical: 5,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF0E9FF,
              ),
              borderRadius:
                  BorderRadius.circular(
                30,
              ),
            ),

            child: const Text(
              'WELCOME BACK',
              style:
                  TextStyle(
                fontSize: 10,
                fontWeight:
                    FontWeight.w800,
                letterSpacing: 1.1,
                color: _purple,
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          // ========================================================
          // HEADING
          // ========================================================

          const Text(
            'Welcome Back',
            style:
                TextStyle(
              fontSize: 29,
              fontWeight:
                  FontWeight.w800,
              color: _darkText,
              height: 1.1,
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          const Text(
            'Sign in to continue to MediMate',
            style:
                TextStyle(
              fontSize: 14,
              height: 1.4,
              color: _mediumText,
            ),
          ),

          const SizedBox(
            height: 19,
          ),

          // ========================================================
          // EMAIL
          // ========================================================

          const Text(
            'Email',
            style:
                TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF34264B),
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          TextFormField(
            controller:
                _emailController,

            keyboardType:
                TextInputType
                    .emailAddress,

            textInputAction:
                TextInputAction.next,

            style:
                const TextStyle(
              color: _darkText,
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
            ),

            cursorColor:
                _purple,

            decoration:
                _inputDecoration(
              hint:
                  'Enter your email',
              icon:
                  Icons
                      .email_outlined,
            ),

            validator: (value) {
              if (value == null ||
                  value
                      .trim()
                      .isEmpty) {
                return 'Please enter your email';
              }

              if (!value
                      .contains('@') ||
                  !value
                      .contains('.')) {
                return 'Please enter a valid email';
              }

              return null;
            },
          ),

          const SizedBox(
            height: 13,
          ),

          // ========================================================
          // PASSWORD
          // ========================================================

          const Text(
            'Password',
            style:
                TextStyle(
              fontSize: 14,
              fontWeight:
                  FontWeight.w700,
              color:
                  Color(0xFF34264B),
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          TextFormField(
            controller:
                _passwordController,

            obscureText:
                _obscurePassword,

            textInputAction:
                TextInputAction.done,

            onFieldSubmitted:
                (_) {
              if (!_isLoading) {
                _handleLogin();
              }
            },

            style:
                const TextStyle(
              color: _darkText,
              fontSize: 14,
              fontWeight:
                  FontWeight.w600,
            ),

            cursorColor:
                _purple,

            decoration:
                _inputDecoration(
              hint:
                  'Enter your password',
              icon:
                  Icons
                      .lock_outline_rounded,

              suffixIcon:
                  IconButton(
                onPressed: () {
                  setState(() {
                    _obscurePassword =
                        !_obscurePassword;
                  });
                },

                icon:
                    Icon(
                  _obscurePassword
                      ? Icons
                          .visibility_outlined
                      : Icons
                          .visibility_off_outlined,
                  color:
                      const Color(
                    0xFF8B829B,
                  ),
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

            child:
                TextButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/forgot-password',
                );
              },

              style:
                  TextButton.styleFrom(
                foregroundColor:
                    _purple,
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 4,
                  vertical: 5,
                ),
              ),

              child:
                  const Text(
                'Forgot password?',
                style:
                    TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w700,
                ),
              ),
            ),
          ),

          const SizedBox(
            height: 3,
          ),

          // ========================================================
          // SIGN IN BUTTON
          // ========================================================

          _buildSignInButton(),

          const SizedBox(
            height: 14,
          ),

          // ========================================================
          // DIVIDER
          // ========================================================

          Row(
            children: [
              Expanded(
                child:
                    Container(
                  height: 1,
                  color:
                      const Color(
                    0xFFE5DEEF,
                  ),
                ),
              ),

              const Padding(
                padding:
                    EdgeInsets
                        .symmetric(
                  horizontal: 12,
                ),
                child:
                    Text(
                  'OR',
                  style:
                      TextStyle(
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(
                      0xFF968CA2,
                    ),
                  ),
                ),
              ),

              Expanded(
                child:
                    Container(
                  height: 1,
                  color:
                      const Color(
                    0xFFE5DEEF,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(
            height: 13,
          ),

          // ========================================================
          // SIGN UP
          // ========================================================

          Center(
            child:
                Wrap(
              alignment:
                  WrapAlignment
                      .center,

              children: [
                const Text(
                  "Don't have an account? ",
                  style:
                      TextStyle(
                    color:
                        _mediumText,
                    fontSize: 13,
                  ),
                ),

                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/signup',
                    );
                  },

                  child:
                      const Text(
                    'Sign Up',
                    style:
                        TextStyle(
                      color:
                          _purple,
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w800,
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

      hintStyle:
          const TextStyle(
        color:
            Color(0xFFAAA2B7),
        fontSize: 13,
      ),

      prefixIcon:
          Icon(
        icon,
        color: _purple,
        size: 21,
      ),

      suffixIcon:
          suffixIcon,

      filled: true,

      fillColor:
          _fieldBackground,

      contentPadding:
          const EdgeInsets
              .symmetric(
        horizontal: 15,
        vertical: 14,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFDCCEF4),
          width: 1.2,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        borderSide:
            const BorderSide(
          color: _purple,
          width: 1.8,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFDC2626),
          width: 1.2,
        ),
      ),

      focusedErrorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          15,
        ),
        borderSide:
            const BorderSide(
          color:
              Color(0xFFDC2626),
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
      width:
          double.infinity,

      height: 52,

      child:
          DecoratedBox(
        decoration:
            BoxDecoration(
          gradient:
              const LinearGradient(
            begin:
                Alignment.centerLeft,
            end:
                Alignment.centerRight,
            colors: [
              _lightPurple,
              _purple,
            ],
          ),

          borderRadius:
              BorderRadius.circular(
            15,
          ),

          boxShadow: [
            BoxShadow(
              color:
                  _purple.withOpacity(
                0.25,
              ),
              blurRadius: 14,
              offset:
                  const Offset(
                0,
                7,
              ),
            ),
          ],
        ),

        child:
            ElevatedButton(
          onPressed:
              _isLoading
                  ? null
                  : _handleLogin,

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent,

            foregroundColor:
                Colors.white,

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
                  BorderRadius.circular(
                15,
              ),
            ),
          ),

          child:
              _isLoading
                  ? const SizedBox(
                      width: 21,
                      height: 21,
                      child:
                          CircularProgressIndicator(
                        strokeWidth:
                            2.3,
                        valueColor:
                            AlwaysStoppedAnimation<
                                Color>(
                          Colors.white,
                        ),
                      ),
                    )
                  : const Row(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        Text(
                          'Log In',
                          style:
                              TextStyle(
                            fontSize:
                                15,
                            fontWeight:
                                FontWeight
                                    .w800,
                          ),
                        ),

                        SizedBox(
                          width: 8,
                        ),

                        Icon(
                          Icons
                              .arrow_forward_rounded,
                          size: 19,
                        ),
                      ],
                    ),
        ),
      ),
    );
  }

  // ================================================================
  // DOCTOR ILLUSTRATION
  // ================================================================

  Widget _buildIllustration() {
    return SizedBox(
      width: 215,
      height: 150,

      child:
          Stack(
        alignment:
            Alignment.center,

        children: [

          // Heart circle
          Positioned(
            top: 5,
            left: 9,
            child:
                Container(
              width: 43,
              height: 43,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFE9DDFF),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons
                    .favorite_rounded,
                color:
                    Color(0xFF8B5CF6),
                size: 21,
              ),
            ),
          ),

          // Plus circle
          Positioned(
            top: 27,
            right: 4,
            child:
                Container(
              width: 39,
              height: 39,
              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFE1D2FF),
                shape:
                    BoxShape.circle,
              ),
              child:
                  const Icon(
                Icons.add_rounded,
                color:
                    Color(0xFF6D28D9),
                size: 23,
              ),
            ),
          ),

          Image.asset(
            'assets/images/home_doctor.png',
            width: 185,
            height: 155,
            fit:
                BoxFit.contain,

            errorBuilder:
                (_, __, ___) {
              return const Icon(
                Icons
                    .medical_services_rounded,
                color:
                    Color(0xFF6D28D9),
                size: 70,
              );
            },
          ),
        ],
      ),
    );
  }

  // ================================================================
  // DECORATIVE DOT
  // ================================================================

  Widget _dot() {
    return Container(
      width: 7,
      height: 7,
      decoration:
          const BoxDecoration(
        color:
            Colors.white,
        shape:
            BoxShape.circle,
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
    final path =
        Path();

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
    CustomClipper<Path>
        oldClipper,
  ) {
    return false;
  }
}