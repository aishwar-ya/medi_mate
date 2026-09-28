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

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ================================================================
  // RESET PASSWORD
  // ================================================================

  Future<void> _resetPassword() async {
    final code = _codeController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword =
        _confirmPasswordController.text.trim();

    if (code.isEmpty) {
      _showMessage('Please enter the reset code.');
      return;
    }

    if (code.length != 6) {
      _showMessage(
        'The reset code must contain 6 digits.',
      );
      return;
    }

    if (password.isEmpty) {
      _showMessage('Please enter a new password.');
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
      _showMessage('Passwords do not match.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

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

  // ================================================================
  // MESSAGE
  // ================================================================

  void _showMessage(String message) {
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
              right: -100,
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
                  horizontal: isSmallScreen ? 20 : 40,
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
            color: const Color(0xFF6D28D9).withOpacity(0.16),
            blurRadius: 40,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
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
            color: const Color(0xFF6D28D9).withOpacity(0.15),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 6,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF0E9FF),
            borderRadius: BorderRadius.circular(30),
          ),
          child: const Text(
            'PASSWORD RECOVERY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF6D28D9),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // Main heading
        const Text(
          'Create New Password',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF211738),
            height: 1.15,
          ),
        ),

        const SizedBox(height: 12),

        const Text(
          'Enter the code from your email and create a secure new password for your MediMate account.',
          style: TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Color(0xFF71677F),
          ),
        ),

        const SizedBox(height: 25),

        // Email
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F3FF),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: const Color(0xFFE1D5F5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8DEFF),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.email_outlined,
                  color: Color(0xFF6D28D9),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resetting password for',
                      style: TextStyle(
                        fontSize: 11,
                        color: Color(0xFF887D99),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.email,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34264B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // ==========================================================
        // RESET CODE
        // ==========================================================

        const Text(
          'Reset Code',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF34264B),
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: _codeController,
          keyboardType: TextInputType.number,
          maxLength: 6,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            letterSpacing: 8,
            color: Color(0xFF34264B),
          ),
          decoration: InputDecoration(
            hintText: '123456',
            hintStyle: const TextStyle(
              color: Color(0xFFB6ADBF),
              letterSpacing: 6,
              fontSize: 20,
            ),
            counterText: '',
            prefixIcon: const Icon(
              Icons.verified_user_outlined,
              color: Color(0xFF7C3AED),
            ),
            filled: true,
            fillColor: const Color(0xFFFAF8FE),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFDCCEF4),
                width: 1.3,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF7C3AED),
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ==========================================================
        // NEW PASSWORD
        // ==========================================================

        const Text(
          'New Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF34264B),
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: _passwordController,
          obscureText: !_showPassword,
          style: const TextStyle(
            color: Color(0xFF34264B),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Enter new password',
            hintStyle: const TextStyle(
              color: Color(0xFFAAA2B7),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF7C3AED),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _showPassword = !_showPassword;
                });
              },
              icon: Icon(
                _showPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF8B829B),
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFFAF8FE),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFDCCEF4),
                width: 1.3,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF7C3AED),
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 18),

        // ==========================================================
        // CONFIRM PASSWORD
        // ==========================================================

        const Text(
          'Confirm Password',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF34264B),
          ),
        ),

        const SizedBox(height: 8),

        TextField(
          controller: _confirmPasswordController,
          obscureText: !_showConfirmPassword,
          style: const TextStyle(
            color: Color(0xFF34264B),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Confirm new password',
            hintStyle: const TextStyle(
              color: Color(0xFFAAA2B7),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.lock_outline_rounded,
              color: Color(0xFF7C3AED),
            ),
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _showConfirmPassword =
                      !_showConfirmPassword;
                });
              },
              icon: Icon(
                _showConfirmPassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: const Color(0xFF8B829B),
              ),
            ),
            filled: true,
            fillColor: const Color(0xFFFAF8FE),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 18,
              vertical: 18,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFFDCCEF4),
                width: 1.3,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(
                color: Color(0xFF7C3AED),
                width: 2,
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        // ==========================================================
        // PASSWORD REQUIREMENTS
        // ==========================================================

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: const Color(0xFFF1EAFF),
            borderRadius: BorderRadius.circular(18),
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
                  color: const Color(0xFFE1D3FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF6D28D9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Password requirements',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF34264B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    _requirement(
                      'At least 6 characters',
                    ),
                    const SizedBox(height: 5),
                    _requirement(
                      'Use a secure password',
                    ),
                    const SizedBox(height: 5),
                    _requirement(
                      'Both passwords must match',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 23),

        // ==========================================================
        // UPDATE BUTTON
        // ==========================================================

        _buildPurpleButton(),

        const SizedBox(height: 12),

        Center(
          child: TextButton.icon(
            onPressed: () {
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            icon: const Icon(
              Icons.arrow_back_rounded,
              size: 17,
            ),
            label: const Text(
              'Back to Sign In',
              style: TextStyle(
                fontWeight: FontWeight.w700,
              ),
            ),
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFF6D28D9),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // REQUIREMENT
  // ================================================================

  Widget _requirement(String text) {
    return Row(
      children: [
        const Icon(
          Icons.check_circle_rounded,
          color: Color(0xFF7C3AED),
          size: 17,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF71677F),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // BUTTON
  // ================================================================

  Widget _buildPurpleButton() {
    return SizedBox(
      width: double.infinity,
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Color(0xFF8B5CF6),
              Color(0xFF6D28D9),
            ],
          ),
          borderRadius: BorderRadius.circular(17),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED)
                  .withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 9),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed:
              _isLoading ? null : _resetPassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            disabledBackgroundColor:
                Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(17),
            ),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 23,
                  height: 23,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : const Row(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    Text(
                      'Update Password',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
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
  // LOCK ILLUSTRATION
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
                    color: const Color(0xFFE9DDFF),
                    borderRadius:
                        BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF6D28D9),
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          'Secure your account',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF34264B),
          ),
        ),

        const SizedBox(height: 7),

        const Text(
          'Create a new password and\nkeep your MediMate account safe.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            height: 1.5,
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
// CURVED HEADER CLIPPER
// ================================================================

class _HeaderClipper
    extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();

    path.lineTo(0, size.height - 35);

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

    path.lineTo(size.width, 0);

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