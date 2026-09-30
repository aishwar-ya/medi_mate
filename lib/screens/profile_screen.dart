import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final supabase = Supabase.instance.client;

  bool _isLoading = true;
  String _fullName = 'Loading...';

  // ------------------------------------------------------------
  // COLORS
  // ------------------------------------------------------------

  static const Color primary = Color(0xFF7C3AED);
  static const Color primaryDark = Color(0xFF5B21B6);
  static const Color lavender = Color(0xFFF3EEFF);
  static const Color background = Color(0xFFF8F6FF);
  static const Color textDark = Color(0xFF211738);
  static const Color textMuted = Color(0xFF716A80);
  static const Color border = Color(0xFFE5DCF4);

  // ------------------------------------------------------------
  // INIT
  // ------------------------------------------------------------

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  // ------------------------------------------------------------
  // LOAD PROFILE
  // ------------------------------------------------------------

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {
        throw Exception('User not logged in');
      }

      final data = await supabase
          .from('profiles')
          .select('full_name')
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          final name = data?['full_name'] as String?;

          _fullName = name != null && name.trim().isNotEmpty
              ? name.trim()
              : 'No Name';

          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _fullName = 'Error';
          _isLoading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load profile: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ------------------------------------------------------------
  // GET INITIALS
  // ------------------------------------------------------------

  String _getInitials(String name) {
    final parts = name
        .split(' ')
        .where((s) => s.trim().isNotEmpty)
        .toList();

    if (parts.isEmpty) {
      return '?';
    }

    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    }

    return (parts[0][0] + parts.last[0]).toUpperCase();
  }

  // ------------------------------------------------------------
  // CHANGE PASSWORD
  // ------------------------------------------------------------

  Future<void> _resetPassword() async {
    final email = supabase.auth.currentUser?.email;

    if (email == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find user email.'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return;
    }

    try {
      await supabase.auth.resetPasswordForEmail(email);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Password reset code sent to $email',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to send reset code: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ------------------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------------------

  Future<void> _signOut() async {
    try {
      await supabase.auth.signOut();

      // AuthGate handles navigation.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sign out failed: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final initials = _getInitials(_fullName);

    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 430,
            ),
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: primary,
                    ),
                  )
                : Column(
                    children: [
                      _buildHeader(),

                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(
                            12,
                            0,
                            12,
                            14,
                          ),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _buildIntro(),

                              const SizedBox(height: 6),

                              _buildPersonalCard(initials),

                              const SizedBox(height: 10),

                              // PERSONAL INFORMATION
                              _sectionLabel(
                                Icons.person_outline_rounded,
                                'Personal Information',
                              ),

                              const SizedBox(height: 8),

                              // ONLY ONE PROFILE EDIT OPTION
                              _buildInfoRow(
                                Icons.edit_outlined,
                                'Edit Profile',
                                'Update your profile name',
                                onTap: _editName,
                              ),

                              const SizedBox(height: 10),

                              // ACCOUNT
                              _sectionLabel(
                                Icons.shield_outlined,
                                'Account',
                              ),

                              const SizedBox(height: 8),

                              _buildInfoRow(
                                Icons.lock_outline_rounded,
                                'Change Password',
                                'Update your MediMate account password',
                                onTap: _resetPassword,
                              ),

                              const SizedBox(height: 10),

                              _buildSignOutButton(),
                            ],
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

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------

  Widget _buildHeader() {
    return Container(
      height: 104,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFF8B5CF6),
            Color(0xFF6D28D9),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(
        14,
        8,
        14,
        14,
      ),
      child: Row(
        children: [
          // BACK BUTTON
          _headerButton(
            Icons.arrow_back_rounded,
            () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }
            },
          ),

          const Spacer(),

          // MEDIMATE LOGO
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(.95),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.medication_rounded,
                  color: primary,
                  size: 19,
                ),
              ),

              const SizedBox(width: 7),

              const Text(
                'MediMate',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),

          const Spacer(),

          // EMPTY SPACE TO KEEP LOGO CENTERED
          const SizedBox(
            width: 38,
            height: 38,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER BUTTON
  // ------------------------------------------------------------

  Widget _headerButton(
    IconData icon,
    VoidCallback onTap,
  ) {
    return Material(
      color: Colors.white.withOpacity(.18),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 38,
          height: 38,
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // INTRO
  // ------------------------------------------------------------

  Widget _buildIntro() {
    return Transform.translate(
      offset: const Offset(0, -20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(
          18,
          18,
          18,
          2,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: const Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Text(
              'Profile',
              style: TextStyle(
                color: textDark,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),

            SizedBox(height: 3),

            Text(
              'Manage your personal information',
              style: TextStyle(
                color: textMuted,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // PROFILE CARD
  // ------------------------------------------------------------

  Widget _buildPersonalCard(
    String initials,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 13,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: border,
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 66,
            height: 66,
            decoration: BoxDecoration(
              color: lavender,
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFE1D5FF),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: primary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Text(
            _fullName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),

          const SizedBox(height: 3),

          const Text(
            'Your MediMate profile',
            style: TextStyle(
              color: textMuted,
              fontSize: 9,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // SECTION LABEL
  // ------------------------------------------------------------

  Widget _sectionLabel(
    IconData icon,
    String title,
  ) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(
            icon,
            color: primary,
            size: 16,
          ),
        ),

        const SizedBox(width: 8),

        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------
  // OPTION ROW
  // ------------------------------------------------------------

  Widget _buildInfoRow(
    IconData icon,
    String title,
    String subtitle, {
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 9,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: border,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: lavender,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  icon,
                  color: primary,
                  size: 19,
                ),
              ),

              const SizedBox(width: 11),

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 2),

                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 8,
                      ),
                    ),
                  ],
                ),
              ),

              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFF77708A),
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // SIGN OUT
  // ------------------------------------------------------------

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 42,
      child: OutlinedButton.icon(
        onPressed: _signOut,
        icon: const Icon(
          Icons.logout_rounded,
          size: 18,
        ),
        label: const Text(
          'Sign Out',
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor:
              const Color(0xFFDC2626),
          backgroundColor:
              const Color(0xFFFFF3F5),
          side: const BorderSide(
            color: Color(0xFFF4D0D5),
          ),
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // EDIT PROFILE NAME
  // ------------------------------------------------------------

  Future<void> _editName() async {
    final controller =
        TextEditingController(
      text: _fullName,
    );

    final newName =
        await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Edit Profile',
          ),

          content: TextField(
            controller: controller,
            autofocus: true,
            decoration:
                const InputDecoration(
              labelText: 'Name',
              prefixIcon: Icon(
                Icons.person_outline_rounded,
              ),
            ),
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'Cancel',
              ),
            ),

            FilledButton(
              onPressed: () {
                final value =
                    controller.text.trim();

                if (value.isNotEmpty) {
                  Navigator.pop(
                    context,
                    value,
                  );
                }
              },
              child: const Text(
                'Save',
              ),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (newName == null ||
        newName.trim().isEmpty) {
      return;
    }

    try {
      await supabase
          .from('profiles')
          .update({
        'full_name': newName.trim(),
      }).eq(
        'id',
        supabase.auth.currentUser!.id,
      );

      if (mounted) {
        setState(() {
          _fullName = newName.trim();
        });

        ScaffoldMessenger.of(context)
            .showSnackBar(
          const SnackBar(
            content: Text(
              'Profile updated',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update profile: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}