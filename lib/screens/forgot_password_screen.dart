import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController =
      TextEditingController();

  bool _isLoading = false;
  bool _emailSent = false;

  static const Color purple = Color(0xFF6D28D9);
  static const Color lightPurple = Color(0xFF8B5CF6);
  static const Color textDark = Color(0xFF211738);
  static const Color textMuted = Color(0xFF71677F);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  // ============================================================
  // SEND RESET CODE
  // ============================================================

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage(
        'Please enter your email address.',
      );
      return;
    }

    if (!email.contains('@')) {
      _showMessage(
        'Please enter a valid email address.',
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase =
          Supabase.instance.client;

      await supabase.auth.resetPasswordForEmail(
        email,
      );

      if (!mounted) return;

      setState(() {
        _emailSent = true;
      });

      _showMessage(
        'Reset code sent to your email.',
        success: true,
      );
    } on AuthException catch (e) {
      if (!mounted) return;

      _showMessage(e.message);
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Something went wrong. Please try again.',
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
  // CONTINUE TO RESET PASSWORD
  // ============================================================

  void _continueToReset() {
    final email =
        _emailController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ResetPasswordScreen(
          email: email,
        ),
      ),
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: success
            ? const Color(0xFF16A34A)
            : const Color(0xFFDC2626),
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

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final size =
        MediaQuery.of(context).size;

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
                // BACKGROUND DECORATION
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
                      height: 155,

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
                          color: Colors
                              .white
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
                              FontWeight
                                  .w800,
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
                      12,
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
  // MOBILE CARD
  // ============================================================

  Widget _buildMobileLayout() {
    return Container(
      margin:
          const EdgeInsets.only(
        top: 48,
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

          // Doctor illustration
          _buildIllustration(),

          const SizedBox(
            height: 3,
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

          child: Text(
            _emailSent
                ? 'EMAIL SENT'
                : 'ACCOUNT RECOVERY',

            style:
                const TextStyle(
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
        Text(
          _emailSent
              ? 'Check your email'
              : 'Forgot Password?',

          style:
              const TextStyle(
            fontSize: 27,
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
          _emailSent
              ? 'We sent a reset code to your email address.'
              : 'Enter your email address and we’ll send you a reset code.',

          style:
              const TextStyle(
            fontSize: 13.5,
            height: 1.35,
            color: textMuted,
          ),
        ),

        const SizedBox(
          height: 17,
        ),

        if (!_emailSent)
          _buildEmailForm()
        else
          _buildEmailSentForm(),

        const SizedBox(
          height: 17,
        ),

        // Security card
        _buildSecurityCard(),

        const SizedBox(
          height: 15,
        ),

        // Back to login
        Center(
          child: TextButton.icon(
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
              'Back to Login',
              style:
                  TextStyle(
                fontSize: 12.5,
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
  // EMAIL FORM
  // ============================================================

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

        const Text(
          'Email',
          style:
              TextStyle(
            fontSize: 13,
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
              _emailController,

          keyboardType:
              TextInputType
                  .emailAddress,

          textInputAction:
              TextInputAction.done,

          onSubmitted: (_) {
            if (!_isLoading) {
              _sendResetCode();
            }
          },

          style:
              const TextStyle(
            color:
                Color(0xFF30233F),
            fontSize: 13.5,
            fontWeight:
                FontWeight.w600,
          ),

          cursorColor:
              purple,

          decoration:
              _inputDecoration(
            hint:
                'Enter your email',
            icon:
                Icons.email_outlined,
          ),
        ),

        const SizedBox(
          height: 14,
        ),

        _buildPurpleButton(
          label:
              'Send Reset Code',
          icon:
              Icons
                  .arrow_forward_rounded,
          loading:
              _isLoading,
          onPressed:
              _isLoading
                  ? null
                  : _sendResetCode,
        ),
      ],
    );
  }

  // ============================================================
  // EMAIL SENT
  // ============================================================

  Widget _buildEmailSentForm() {
    return Column(
      crossAxisAlignment:
          CrossAxisAlignment.start,

      children: [

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
              0xFFF8F5FF,
            ),

            borderRadius:
                BorderRadius.circular(
              15,
            ),

            border: Border.all(
              color:
                  const Color(
                0xFFE0D3F7,
              ),
            ),
          ),

          child: Row(
            children: [

              Container(
                width: 40,
                height: 40,

                decoration:
                    const BoxDecoration(
                  color:
                      Color(0xFFE8DEFF),
                  shape:
                      BoxShape.circle,
                ),

                child:
                    const Icon(
                  Icons
                      .mark_email_read_outlined,
                  color:
                      purple,
                  size: 21,
                ),
              ),

              const SizedBox(
                width: 11,
              ),

              Expanded(
                child: Text(
                  _emailController
                      .text
                      .trim(),

                  overflow:
                      TextOverflow
                          .ellipsis,

                  style:
                      const TextStyle(
                    fontSize: 13,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(
                      0xFF34264B,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(
          height: 12,
        ),

        const Text(
          'Open the email we sent you and enter the 6-digit reset code to create your new password.',

          style:
              TextStyle(
            fontSize: 13,
            height: 1.4,
            color: textMuted,
          ),
        ),

        const SizedBox(
          height: 15,
        ),

        _buildPurpleButton(
          label:
              'Enter Reset Code',
          icon:
              Icons
                  .arrow_forward_rounded,
          onPressed:
              _continueToReset,
        ),

        const SizedBox(
          height: 5,
        ),

        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _emailSent =
                    false;
              });
            },

            child:
                const Text(
              'Use another email',
              style:
                  TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w700,
                color: purple,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // SECURITY CARD
  // ============================================================

  Widget _buildSecurityCard() {
    return Container(
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
                  BorderRadius.circular(
                10,
              ),
            ),

            child:
                const Icon(
              Icons.shield_outlined,
              color:
                  purple,
              size: 19,
            ),
          ),

          const SizedBox(
            width: 10,
          ),

          const Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                Text(
                  'Your account is secure',

                  style:
                      TextStyle(
                    fontSize: 12,
                    fontWeight:
                        FontWeight.w700,
                    color:
                        Color(
                      0xFF34264B,
                    ),
                  ),
                ),

                SizedBox(
                  height: 3,
                ),

                Text(
                  'The reset code can only be used once and expires after a limited time.',

                  style:
                      TextStyle(
                    fontSize: 10.5,
                    height: 1.3,
                    color:
                        Color(
                      0xFF776D86,
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
        color: Color(0xFF7C3AED),
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
          color: Color(0xFF7C3AED),
          width: 1.7,
        ),
      ),
    );
  }

  // ============================================================
  // PURPLE BUTTON
  // ============================================================

  Widget _buildPurpleButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
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
                0.24,
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
              onPressed,

          style:
              ElevatedButton.styleFrom(
            backgroundColor:
                Colors.transparent,

            foregroundColor:
                Colors.white,

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

          child: loading
              ? const SizedBox(
                  width: 20,
                  height: 20,

                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.3,
                    valueColor:
                        AlwaysStoppedAnimation<
                            Color>(
                      Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  children: [
                    Text(
                      label,

                      style:
                          const TextStyle(
                        fontSize: 13.5,
                        fontWeight:
                            FontWeight.w800,
                      ),
                    ),

                    const SizedBox(
                      width: 8,
                    ),

                    Icon(
                      icon,
                      size: 18,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  // ============================================================
  // DOCTOR ILLUSTRATION
  // ============================================================

  Widget _buildIllustration() {
    return SizedBox(
      width: 205,
      height: 140,

      child: Stack(
        alignment:
            Alignment.center,

        children: [

          // Heart
          Positioned(
            top: 0,
            left: 2,

            child: Container(
              width: 42,
              height: 42,

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

          // Mail icon
          Positioned(
            top: 25,
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
                    .mark_email_read_rounded,
                color:
                    Color(0xFF6D28D9),
                size: 21,
              ),
            ),
          ),

          Image.asset(
            'assets/images/home_doctor.png',

            width: 180,
            height: 145,

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