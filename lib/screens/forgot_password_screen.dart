import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'reset_password_screen.dart';
import 'theme/app_theme.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Please enter your email address.');
      return;
    }

    if (!email.contains('@')) {
      _showMessage('Please enter a valid email address.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final supabase = Supabase.instance.client;

      await supabase.auth.resetPasswordForEmail(email);

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

  void _continueToReset() {
    final email = _emailController.text.trim();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ResetPasswordScreen(
          email: email,
        ),
      ),
    );
  }

  void _showMessage(
    String message, {
    bool success = false,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor:
            success ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(20),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 700;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F0FF),
      body: SafeArea(
        child: Stack(
          children: [
            // ---------------------------------------------------------
            // BACKGROUND DECORATION
            // ---------------------------------------------------------
            Positioned(
              top: -100,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4D5FF),
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
                decoration: BoxDecoration(
                  color: const Color(0xFFD8C5FF),
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
                decoration: BoxDecoration(
                  color: const Color(0xFFE9DEFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // ---------------------------------------------------------
            // TOP PURPLE CURVED HEADER
            // ---------------------------------------------------------
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

            // ---------------------------------------------------------
            // BACK BUTTON
            // ---------------------------------------------------------
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

            // ---------------------------------------------------------
            // DECORATIVE DOTS
            // ---------------------------------------------------------
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
                    mainAxisAlignment: MainAxisAlignment.end,
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

            // ---------------------------------------------------------
            // MAIN CONTENT
            // ---------------------------------------------------------
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
        // Small label
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
            'ACCOUNT RECOVERY',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: Color(0xFF6D28D9),
            ),
          ),
        ),

        const SizedBox(height: 15),

        // Heading
        Text(
          _emailSent
              ? 'Check your email'
              : 'Forgot your password?',
          style: const TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.w800,
            color: Color(0xFF211738),
            height: 1.15,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          _emailSent
              ? 'We sent a 6-digit reset code to your email address.'
              : 'Enter your email address and we will send you a reset code.',
          style: const TextStyle(
            fontSize: 15,
            height: 1.5,
            color: Color(0xFF71677F),
          ),
        ),

        const SizedBox(height: 28),

        if (!_emailSent)
          _buildEmailForm()
        else
          _buildEmailSentForm(),

        const SizedBox(height: 25),

        // Security information
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF4EEFF),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE1D4F7),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5D8FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.shield_outlined,
                  color: Color(0xFF6D28D9),
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your account is secure',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF34264B),
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'The reset code can only be used once and expires after a limited time.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Color(0xFF776D86),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 25),

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
  // EMAIL FORM
  // ================================================================

  Widget _buildEmailForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Email Address',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF34264B),
          ),
        ),

        const SizedBox(height: 9),

        TextField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) {
            if (!_isLoading) {
              _sendResetCode();
            }
          },
          style: const TextStyle(
            color: Color(0xFF30233F),
            fontWeight: FontWeight.w600,
          ),
          decoration: InputDecoration(
            hintText: 'Enter your email address',
            hintStyle: const TextStyle(
              color: Color(0xFFAAA2B7),
              fontSize: 14,
            ),
            prefixIcon: const Icon(
              Icons.email_outlined,
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

        const SizedBox(height: 20),

        _buildPurpleButton(
          label: 'Send Reset Code',
          icon: Icons.arrow_forward_rounded,
          loading: _isLoading,
          onPressed: _isLoading
              ? null
              : _sendResetCode,
        ),
      ],
    );
  }

  // ================================================================
  // EMAIL SENT FORM
  // ================================================================

  Widget _buildEmailSentForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F5FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFE0D3F7),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8DEFF),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFF6D28D9),
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _emailController.text.trim(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF34264B),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        const Text(
          'Open the email we sent you and enter the 6-digit reset code to create your new password.',
          style: TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF71677F),
          ),
        ),

        const SizedBox(height: 20),

        _buildPurpleButton(
          label: 'Enter Reset Code',
          icon: Icons.arrow_forward_rounded,
          onPressed: _continueToReset,
        ),

        const SizedBox(height: 10),

        Center(
          child: TextButton(
            onPressed: () {
              setState(() {
                _emailSent = false;
              });
            },
            child: const Text(
              'Use another email',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF6D28D9),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================================================================
  // PURPLE BUTTON
  // ================================================================

  Widget _buildPurpleButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 56,
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
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF7C3AED).withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: loading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(
                      Colors.white,
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Icon(
                      icon,
                      size: 20,
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
                    borderRadius: BorderRadius.circular(24),
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
          'Reset securely',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF34264B),
          ),
        ),

        const SizedBox(height: 7),

        const Text(
          'We will help you get back into\nyour MediMate account.',
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

class _HeaderClipper extends CustomClipper<Path> {
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