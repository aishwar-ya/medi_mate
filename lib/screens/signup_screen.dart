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

  static const Color _darkText =
      Color(0xFF211738);

  static const Color _mediumText =
      Color(0xFF71677F);

  static const Color _purple =
      Color(0xFF6D28D9);

  static const Color _lightPurple =
      Color(0xFF8B5CF6);

  static const Color _fieldBackground =
      Color(0xFFFAF8FE);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  // ============================================================
  // SIGN UP
  // ============================================================

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
      final supabase =
          Supabase.instance.client;

      final response =
          await supabase.auth.signUp(
        email: _emailController.text.trim(),
        password: _passwordController.text,
        data: {
          'full_name':
              _fullNameController.text.trim(),
        },
      );

      if (response.user != null && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Sign up successful! Please check your email at '
              '${_emailController.text.trim()} to confirm your account.',
            ),
            backgroundColor:
                const Color(0xFF16A34A),
            duration:
                const Duration(seconds: 6),
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

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message, {
    bool error = false,
  }) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
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
                      height: 160,

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
                  top: 28,
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
                              Color(
                            0xFF6D28D9,
                          ),
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
                  top: 20,
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
                  top: 32,
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
                      18,
                      16,
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
        12,
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

          // Smaller illustration
          _buildIllustration(),

          const SizedBox(
            height: 2,
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

            child: const Text(
              'GET STARTED',
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
            'Create Account',
            style:
                TextStyle(
              fontSize: 27,
              fontWeight:
                  FontWeight.w800,
              color: _darkText,
              height: 1.1,
            ),
          ),

          const SizedBox(
            height: 6,
          ),

          const Text(
            'Join MediMate and take control of your health',
            style:
                TextStyle(
              fontSize: 13.5,
              height: 1.35,
              color: _mediumText,
            ),
          ),

          const SizedBox(
            height: 17,
          ),

          // ========================================================
          // FULL NAME
          // ========================================================

          const Text(
            'Full Name',
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

          TextFormField(
            controller:
                _fullNameController,

            textCapitalization:
                TextCapitalization.words,

            textInputAction:
                TextInputAction.next,

            style:
                const TextStyle(
              color: _darkText,
              fontSize: 13.5,
              fontWeight:
                  FontWeight.w600,
            ),

            cursorColor:
                _purple,

            decoration:
                _inputDecoration(
              hint:
                  'Enter your full name',
              icon:
                  Icons
                      .person_outline_rounded,
            ),

            validator: (value) {
              if (value == null ||
                  value.trim().isEmpty) {
                return 'Please enter your full name';
              }

              if (value
                      .trim()
                      .length <
                  2) {
                return 'Name must be at least 2 characters';
              }

              return null;
            },
          ),

          const SizedBox(
            height: 11,
          ),

          // ========================================================
          // EMAIL
          // ========================================================

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
              fontSize: 13.5,
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
                  Icons.email_outlined,
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

          const SizedBox(
            height: 11,
          ),

          // ========================================================
          // PASSWORD
          // ========================================================

          const Text(
            'Password',
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

          TextFormField(
            controller:
                _passwordController,

            obscureText:
                _obscurePassword,

            textInputAction:
                TextInputAction.next,

            style:
                const TextStyle(
              color: _darkText,
              fontSize: 13.5,
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
                  size: 20,
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

          const SizedBox(
            height: 11,
          ),

          // ========================================================
          // CONFIRM PASSWORD
          // ========================================================

          const Text(
            'Confirm Password',
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

          TextFormField(
            controller:
                _confirmPasswordController,

            obscureText:
                _obscureConfirmPassword,

            textInputAction:
                TextInputAction.done,

            style:
                const TextStyle(
              color: _darkText,
              fontSize: 13.5,
              fontWeight:
                  FontWeight.w600,
            ),

            cursorColor:
                _purple,

            decoration:
                _inputDecoration(
              hint:
                  'Confirm your password',
              icon:
                  Icons
                      .lock_outline_rounded,

              suffixIcon:
                  IconButton(
                onPressed: () {
                  setState(() {
                    _obscureConfirmPassword =
                        !_obscureConfirmPassword;
                  });
                },

                icon:
                    Icon(
                  _obscureConfirmPassword
                      ? Icons
                          .visibility_outlined
                      : Icons
                          .visibility_off_outlined,
                  color:
                      const Color(
                    0xFF8B829B,
                  ),
                  size: 20,
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

          const SizedBox(
            height: 11,
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
              horizontal: 11,
              vertical: 9,
            ),

            decoration:
                BoxDecoration(
              color:
                  const Color(
                0xFFF1EAFF,
              ),
              borderRadius:
                  BorderRadius.circular(
                13,
              ),
              border: Border.all(
                color:
                    const Color(
                  0xFFE0D3F7,
                ),
              ),
            ),

            child: Row(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [
                Container(
                  width: 30,
                  height: 30,

                  decoration:
                      BoxDecoration(
                    color:
                        const Color(
                      0xFFE1D3FF,
                    ),
                    borderRadius:
                        BorderRadius
                            .circular(
                      9,
                    ),
                  ),

                  child:
                      const Icon(
                    Icons
                        .shield_outlined,
                    color:
                        _purple,
                    size: 17,
                  ),
                ),

                const SizedBox(
                  width: 9,
                ),

                const Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        'Password requirements',
                        style:
                            TextStyle(
                          fontSize:
                              11,
                          fontWeight:
                              FontWeight
                                  .w800,
                          color:
                              Color(
                            0xFF34264B,
                          ),
                        ),
                      ),

                      SizedBox(
                        height: 4,
                      ),

                      _Requirement(
                        text:
                            'At least 8 characters',
                      ),

                      SizedBox(
                        height: 2,
                      ),

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

          const SizedBox(
            height: 9,
          ),

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
                  CrossAxisAlignment
                      .start,

              children: [
                Checkbox(
                  value:
                      _agreedToTerms,

                  activeColor:
                      _purple,

                  checkColor:
                      Colors.white,

                  side:
                      const BorderSide(
                    color:
                        Color(
                      0xFF9B93A8,
                    ),
                    width: 1.5,
                  ),

                  shape:
                      RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius
                            .circular(
                      5,
                    ),
                  ),

                  materialTapTargetSize:
                      MaterialTapTargetSize
                          .shrinkWrap,

                  visualDensity:
                      VisualDensity
                          .compact,

                  onChanged: (value) {
                    setState(() {
                      _agreedToTerms =
                          value ??
                              false;
                    });
                  },
                ),

                const SizedBox(
                  width: 3,
                ),

                const Expanded(
                  child: Padding(
                    padding:
                        EdgeInsets.only(
                      top: 7,
                    ),

                    child: Text(
                      'I agree to the Terms of Service '
                      'and Privacy Policy',

                      style:
                          TextStyle(
                        color:
                            _mediumText,
                        fontSize:
                            11.5,
                        height: 1.3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            height: 7,
          ),

          // ========================================================
          // CREATE ACCOUNT
          // ========================================================

          _buildCreateAccountButton(),
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
    Widget? suffixIcon,
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
        color: _purple,
        size: 20,
      ),

      suffixIcon:
          suffixIcon,

      filled: true,

      fillColor:
          _fieldBackground,

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
          color: _purple,
          width: 1.7,
        ),
      ),

      errorBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(
          14,
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
          14,
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

  // ============================================================
  // CREATE ACCOUNT BUTTON
  // ============================================================

  Widget _buildCreateAccountButton() {
    final disabled =
        _isLoading ||
        !_agreedToTerms;

    return SizedBox(
      width:
          double.infinity,

      height: 50,

      child: DecoratedBox(
        decoration:
            BoxDecoration(
          gradient: disabled
              ? const LinearGradient(
                  colors: [
                    Color(
                      0xFFB9A8D8,
                    ),
                    Color(
                      0xFF9D8BC1,
                    ),
                  ],
                )
              : const LinearGradient(
                  begin:
                      Alignment
                          .centerLeft,
                  end:
                      Alignment
                          .centerRight,
                  colors: [
                    _lightPurple,
                    _purple,
                  ],
                ),

          borderRadius:
              BorderRadius.circular(
            14,
          ),

          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color: _purple
                        .withOpacity(
                      0.25,
                    ),
                    blurRadius: 14,
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
          onPressed: disabled
              ? null
              : _handleSignup,

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
                14,
              ),
            ),
          ),

          child: _isLoading
              ? const SizedBox(
                  width: 21,
                  height: 21,

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

              : const Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .center,

                  children: [
                    Text(
                      'Create Account',
                      style:
                          TextStyle(
                        fontSize:
                            14,
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
    );
  }

  // ============================================================
  // ILLUSTRATION
  // ============================================================

  Widget _buildIllustration() {
    return SizedBox(
      width: 210,
      height: 145,

      child: Stack(
        alignment:
            Alignment.center,

        children: [

          // Heart
          Positioned(
            top: 2,
            left: 3,

            child: Container(
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
                    Color(
                  0xFF8B5CF6,
                ),
                size: 21,
              ),
            ),
          ),

          // Plus
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
                Icons.add_rounded,
                color:
                    Color(
                  0xFF6D28D9,
                ),
                size: 23,
              ),
            ),
          ),

          // Doctor
          Image.asset(
            'assets/images/home_doctor.png',

            width: 185,
            height: 150,

            fit:
                BoxFit.contain,

            errorBuilder:
                (_, __, ___) {
              return const Icon(
                Icons
                    .medical_services_rounded,
                color:
                    Color(
                  0xFF6D28D9,
                ),
                size: 65,
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // DECORATIVE DOT
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
// PASSWORD REQUIREMENT
// ============================================================

class _Requirement
    extends StatelessWidget {
  final String text;

  const _Requirement({
    required this.text,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return Row(
      children: [
        const Icon(
          Icons
              .check_circle_rounded,
          color:
              Color(0xFF7C3AED),
          size: 13,
        ),

        const SizedBox(
          width: 5,
        ),

        Expanded(
          child: Text(
            text,

            style:
                const TextStyle(
              fontSize: 9.5,
              color:
                  Color(
                0xFF71677F,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ============================================================
// CURVED HEADER
// ============================================================

class _HeaderClipper
    extends CustomClipper<Path> {
  @override
  Path getClip(
    Size size,
  ) {
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