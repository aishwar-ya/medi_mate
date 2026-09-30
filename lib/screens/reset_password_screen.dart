import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({
    super.key,
    required this.email,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {
  final TextEditingController _codeController =
      TextEditingController();

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;

  static const Color purple = Color(0xFF6D28D9);
  static const Color lightPurple = Color(0xFF8B5CF6);
  static const Color textDark = Color(0xFF211738);
  static const Color textMuted = Color(0xFF71677F);

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================================
  // RESET PASSWORD
  // ============================================================

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword =
        _confirmPasswordController.text.trim();

    if (code.isEmpty) {
      _showMessage(
        'Please enter the reset code.',
      );
      return;
    }

    if (code.length != 6) {
      _showMessage(
        'The reset code must contain 6 digits.',
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage(
        'Please enter a new password.',
      );
      return;
    }

    if (password.length < 6) {
      _showMessage(
        'Password must contain at least 6 characters.',
      );
      return;
    }

    if (confirmPassword.isEmpty) {
      _showMessage(
        'Please confirm your password.',
      );
      return;
    }

    if (password != confirmPassword) {
      _showMessage(
        'Passwords do not match.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase =
          Supabase.instance.client;

      debugPrint(
        '🔐 Verifying password recovery code...',
      );

      final response =
          await supabase.auth.verifyOTP(
        email: widget.email,
        token: code,
        type: OtpType.recovery,
      );

      if (response.session == null) {
        throw const AuthException(
          'Unable to verify the reset code.',
        );
      }

      debugPrint(
        '✅ Recovery code verified successfully',
      );

      debugPrint(
        '🔑 Updating password...',
      );

      await supabase.auth.updateUser(
        UserAttributes(
          password: password,
        ),
      );

      debugPrint(
        '✅ Password updated successfully',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Password updated successfully!',
          ),
          backgroundColor: Color(0xFF16A34A),
          behavior: SnackBarBehavior.floating,
        ),
      );

      await Future.delayed(
        const Duration(milliseconds: 700),
      );

      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login',
        (route) => false,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      debugPrint(
        '❌ Password reset error: ${e.message}',
      );

      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;

      debugPrint(
        '❌ Password reset error: $e',
      );

      _showMessage(
        'Unable to reset password. Please try again.',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            const Color(0xFFDC2626),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    final frameWidth =
        size.width < 430
            ? size.width
            : 430.0;

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
                  right: -100,
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
                            Color(
                              0xFF8B5CF6,
                            ),
                            Color(
                              0xFF6D28D9,
                            ),
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
                        MainAxisAlignment
                            .center,

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
                              purple,
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
                // BACK BUTTON
                // ==================================================

                Positioned(
                  top: 19,
                  left: 20,

                  child: Material(
                    color: Colors.white,
                    elevation: 4,
                    shadowColor:
                        Colors.black26,
                    shape:
                        const CircleBorder(),

                    child: InkWell(
                      customBorder:
                          const CircleBorder(),

                      onTap: () {
                        Navigator.pop(
                          context,
                        );
                      },

                      child:
                          const SizedBox(
                        width: 48,
                        height: 48,

                        child: Icon(
                          Icons
                              .arrow_back_rounded,
                          color:
                              Color(
                            0xFF5422B8,
                          ),
                          size: 24,
                        ),
                      ),
                    ),
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
                // MAIN CONTENT
                // ==================================================

                Center(
                  child:
                      SingleChildScrollView(
                    padding:
                        const EdgeInsets
                            .fromLTRB(
                      16,
                      10,
                      16,
                      20,
                    ),

                    child:
                        _buildMobileLayout(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MOBILE LAYOUT
  // ============================================================

  Widget _buildMobileLayout() {
    return Container(
      margin:
          const EdgeInsets.only(
        top: 50,
      ),

      padding:
          const EdgeInsets.fromLTRB(
        18,
        10,
        18,
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
                purple.withOpacity(
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

          _buildIllustration(),

          const SizedBox(
            height: 0,
          ),

          _buildForm(),
        ],
      ),
    );
  }

  // ============================================================
  // FORM
  // ============================================================

  Widget _buildForm() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        // Small label
        Container(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 11,
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

          child:
              const Text(
            'PASSWORD RECOVERY',

            style:
                TextStyle(
              fontSize: 10,
              fontWeight:
                  FontWeight.w800,
              letterSpacing: 1.1,
              color: purple,
            ),
          ),
        ),

        const SizedBox(
          height: 9,
        ),

        // Heading
        const Text(
          'Reset Your Password',

          style:
              TextStyle(
            fontSize: 26,
            fontWeight:
                FontWeight.w800,
            color: textDark,
            height: 1.1,
          ),
        ),

        const SizedBox(
          height: 6,
        ),

        Text(
          'Enter the 6-digit code and your new password.',

          style:
              const TextStyle(
            fontSize: 13,
            height: 1.35,
            color: textMuted,
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        // ========================================================
        // EMAIL
        // ========================================================

        const Text(
          'Email',
          style:
              TextStyle(
            fontSize: 12.5,
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xFF34264B),
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 13,
            vertical: 12,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFF6F2FF,
            ),

            borderRadius:
                BorderRadius.circular(
              13,
            ),

            border: Border.all(
              color:
                  const Color(
                0xFFE1D5F4,
              ),
            ),
          ),

          child: Row(
            children: [

              const Icon(
                Icons.email_outlined,
                color: purple,
                size: 19,
              ),

              const SizedBox(
                width: 9,
              ),

              Expanded(
                child: Text(
                  widget.email,

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 12.5,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        Color(
                      0xFF4B3D5E,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 13,
        ),

        // ========================================================
        // RESET CODE
        // ========================================================

        const Text(
          '6-Digit Reset Code',
          style:
              TextStyle(
            fontSize: 12.5,
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xFF34264B),
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        TextField(
          controller:
              _codeController,

          keyboardType:
              TextInputType.number,

          maxLength: 6,

          textAlign:
              TextAlign.center,

          style:
              const TextStyle(
            fontSize: 19,
            fontWeight:
                FontWeight.w800,
            letterSpacing: 6,
            color: textDark,
          ),

          cursorColor:
              purple,

          decoration:
              _inputDecoration(
            hint:
                '000000',
            icon:
                Icons
                    .password_rounded,
          ).copyWith(
            counterText: '',
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ========================================================
        // NEW PASSWORD
        // ========================================================

        const Text(
          'New Password',
          style:
              TextStyle(
            fontSize: 12.5,
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xFF34264B),
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        TextField(
          controller:
              _passwordController,

          obscureText:
              !_showPassword,

          style:
              const TextStyle(
            fontSize: 13,
            color: textDark,
          ),

          cursorColor:
              purple,

          decoration:
              _inputDecoration(
            hint:
                'Enter new password',
            icon:
                Icons.lock_outline_rounded,
          ).copyWith(
            suffixIcon:
                IconButton(
              onPressed: () {
                setState(() {
                  _showPassword =
                      !_showPassword;
                });
              },

              icon: Icon(
                _showPassword
                    ? Icons
                        .visibility_off_outlined
                    : Icons
                        .visibility_outlined,

                color:
                    const Color(
                  0xFF806F9B,
                ),

                size: 20,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        // ========================================================
        // CONFIRM PASSWORD
        // ========================================================

        const Text(
          'Confirm Password',
          style:
              TextStyle(
            fontSize: 12.5,
            fontWeight:
                FontWeight.w700,
            color:
                Color(0xFF34264B),
          ),
        ),

        const SizedBox(
          height: 5,
        ),

        TextField(
          controller:
              _confirmPasswordController,

          obscureText:
              !_showConfirmPassword,

          style:
              const TextStyle(
            fontSize: 13,
            color: textDark,
          ),

          cursorColor:
              purple,

          decoration:
              _inputDecoration(
            hint:
                'Confirm new password',
            icon:
                Icons
                    .lock_reset_rounded,
          ).copyWith(
            suffixIcon:
                IconButton(
              onPressed: () {
                setState(() {
                  _showConfirmPassword =
                      !_showConfirmPassword;
                });
              },

              icon: Icon(
                _showConfirmPassword
                    ? Icons
                        .visibility_off_outlined
                    : Icons
                        .visibility_outlined,

                color:
                    const Color(
                  0xFF806F9B,
                ),

                size: 20,
              ),
            ),
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        // ========================================================
        // PASSWORD REQUIREMENTS
        // ========================================================

        Container(
          width:
              double.infinity,

          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 12,
            vertical: 11,
          ),

          decoration:
              BoxDecoration(
            color:
                const Color(
              0xFFF4EEFF,
            ),

            borderRadius:
                BorderRadius.circular(
              15,
            ),

            border: Border.all(
              color:
                  const Color(
                0xFFE1D4F7,
              ),
            ),
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,

            children: [

              Container(
                width: 34,
                height: 34,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFE5D8FF,
                  ),
                  borderRadius:
                      BorderRadius
                          .circular(
                    10,
                  ),
                ),

                child:
                    const Icon(
                  Icons.shield_outlined,
                  color: purple,
                  size: 19,
                ),
              ),

              const SizedBox(
                width: 10,
              ),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [

                    const Text(
                      'Password requirements',

                      style:
                          TextStyle(
                        fontSize: 12,
                        fontWeight:
                            FontWeight.w800,
                        color:
                            Color(
                          0xFF34264B,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    _requirement(
                      'At least 6 characters',
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    _requirement(
                      'Use a secure password',
                    ),

                    const SizedBox(
                      height: 3,
                    ),

                    _requirement(
                      'Both passwords must match',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        // ========================================================
        // UPDATE PASSWORD BUTTON
        // ========================================================

        SizedBox(
          width:
              double.infinity,

          height: 50,

          child: DecoratedBox(
            decoration:
                BoxDecoration(
              gradient:
                  const LinearGradient(
                begin:
                    Alignment.centerLeft,
                end:
                    Alignment.centerRight,
                colors: [
                  lightPurple,
                  purple,
                ],
              ),

              borderRadius:
                  BorderRadius.circular(
                14,
              ),

              boxShadow: [
                BoxShadow(
                  color:
                      purple.withOpacity(
                    0.25,
                  ),
                  blurRadius: 13,
                  offset:
                      const Offset(
                    0,
                    6,
                  ),
                ),
              ],
            ),

            child:
                ElevatedButton(
              onPressed:
                  _isLoading
                      ? null
                      : _resetPassword,

              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    Colors.transparent,

                foregroundColor:
                    Colors.white,

                disabledBackgroundColor:
                    Colors.transparent,

                shadowColor:
                    Colors.transparent,

                elevation: 0,

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    14,
                  ),
                ),
              ),

              child:
                  _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,

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
                              'Update Password',

                              style:
                                  TextStyle(
                                fontSize: 13.5,
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
                              size: 18,
                            ),
                          ],
                        ),
            ),
          ),
        ),

        const SizedBox(
          height: 10,
        ),

        // ========================================================
        // BACK TO LOGIN
        // ========================================================

        Center(
          child:
              TextButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },

            icon:
                const Icon(
              Icons
                  .arrow_back_rounded,
              size: 16,
            ),

            label:
                const Text(
              'Back to Sign In',

              style:
                  TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
              ),
            ),

            style:
                TextButton.styleFrom(
              foregroundColor:
                  purple,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      hintText: hint,

      hintStyle:
          const TextStyle(
        color:
            Color(0xFFAAA2B7),
        fontSize: 12.5,
      ),

      prefixIcon:
          Icon(
        icon,
        color: purple,
        size: 20,
      ),

      filled: true,

      fillColor:
          const Color(0xFFFAF8FE),

      contentPadding:
          const EdgeInsets
              .symmetric(
        horizontal: 14,
        vertical: 13,
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
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
          14,
        ),

        borderSide:
            const BorderSide(
          color:
              Color(0xFF7C3AED),
          width: 1.7,
        ),
      ),
    );
  }

  // ============================================================
  // REQUIREMENT
  // ============================================================

  Widget _requirement(String text) {
    return Row(
      children: [

        const Icon(
          Icons.check_circle_rounded,
          color:
              Color(0xFF7C3AED),
          size: 15,
        ),

        const SizedBox(
          width: 6,
        ),

        Expanded(
          child: Text(
            text,

            style:
                const TextStyle(
              fontSize: 10.5,
              color:
                  Color(0xFF71677F),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // DOCTOR ILLUSTRATION
  // ============================================================

  Widget _buildIllustration() {
    return SizedBox(
      width: 205,
      height: 135,

      child: Stack(
        alignment:
            Alignment.center,

        children: [

          // Heart
          Positioned(
            top: 2,
            left: 2,

            child: Container(
              width: 40,
              height: 40,

              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFE9DDFF),
                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(
                Icons.favorite_rounded,
                color:
                    Color(0xFF8B5CF6),
                size: 20,
              ),
            ),
          ),

          // Lock
          Positioned(
            top: 20,
            right: 0,

            child: Container(
              width: 40,
              height: 40,

              decoration:
                  const BoxDecoration(
                color:
                    Color(0xFFE1D2FF),
                shape:
                    BoxShape.circle,
              ),

              child:
                  const Icon(
                Icons
                    .lock_reset_rounded,
                color:
                    Color(0xFF6D28D9),
                size: 21,
              ),
            ),
          ),

          // Doctor
          Image.asset(
            'assets/images/home_doctor.png',

            width: 175,
            height: 140,

            fit:
                BoxFit.contain,

            errorBuilder:
                (_, __, ___) {
              return const Icon(
                Icons
                    .medical_services_rounded,
                color:
                    Color(0xFF6D28D9),
                size: 60,
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DOT
  // ============================================================

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

// ============================================================
// HEADER CLIPPER
// ============================================================

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
    CustomClipper<Path>
        oldClipper,
  ) {
    return false;
  }
}