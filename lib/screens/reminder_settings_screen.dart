import 'package:flutter/material.dart';
import 'package:medi_mate/screens/profile_screen.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

class ReminderSettingsScreen extends StatefulWidget {

  const ReminderSettingsScreen({super.key});

  @override

  State<ReminderSettingsScreen> createState() =>

      _ReminderSettingsScreenState();

}

class _ReminderSettingsScreenState extends State<ReminderSettingsScreen> {

  final supabase = Supabase.instance.client;

  static const Color primary = Color(0xFF7C3AED);

  static const Color background = Color(0xFFF8F6FF);

  static const Color lavender = Color(0xFFF0E9FF);

  static const Color textDark = Color(0xFF211738);

  static const Color textMuted = Color(0xFF716A80);

  static const Color border = Color(0xFFE5DCF4);

  Future<Map<String, dynamic>?> _loadSettings() async {

    try {

      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {

        throw Exception('User not logged in');

      }

      final data = await supabase

          .from('profiles')

          .select()

          .eq('id', userId)

          .maybeSingle();

      return data;

    } catch (e) {

      throw Exception('Failed to load settings: $e');

    }

  }

  Future<void> _updateSetting(String columnName, bool value) async {

    try {

      final userId = supabase.auth.currentUser?.id;

      if (userId == null) {

        throw Exception('User not logged in');

      }

      await supabase

          .from('profiles')

          .update({columnName: value})

          .eq('id', userId);

    } catch (e) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(

          content: Text('Failed to save setting: $e'),

          backgroundColor: Colors.red,

        ),

      );

    }

  }


  String _displayName(Map<String, dynamic> settings) {
    final user = supabase.auth.currentUser;
    final metadata = user?.userMetadata ?? <String, dynamic>{};
    final name = metadata['full_name'] ??
        metadata['name'] ??
        settings['full_name'] ??
        settings['name'];

    if (name != null && name.toString().trim().isNotEmpty) {
      return name.toString().trim();
    }

    final email = user?.email ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }

    return 'MediMate User';
  }

  Future<void> _editProfile(Map<String, dynamic> settings) async {
    final controller = TextEditingController(text: _displayName(settings));

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Edit Profile',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: TextField(
            controller: controller,
            autofocus: true,
            enabled: true,
            textCapitalization: TextCapitalization.words,
            cursorColor: primary,
            style: const TextStyle(
              color: textDark,
              fontSize: 17,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              labelText: 'Name',
              hintText: 'Enter your name',
              labelStyle: const TextStyle(
                color: primary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              floatingLabelStyle: const TextStyle(
                color: primary,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              hintStyle: const TextStyle(
                color: textMuted,
                fontSize: 16,
              ),
              prefixIcon: const Icon(
                Icons.person_outline_rounded,
                color: primary,
                size: 25,
              ),
              filled: true,
              fillColor: const Color(0xFFF1ECFF),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Color(0xFFE0D5FF),
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: primary,
                  width: 2,
                ),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel', style: TextStyle(color: textMuted)),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();
                if (value.isNotEmpty) {
                  Navigator.pop(dialogContext, value);
                }
              },
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (newName == null || newName.trim().isEmpty) return;

    try {
      await supabase.auth.updateUser(
        UserAttributes(
          data: {
            'full_name': newName.trim(),
            'name': newName.trim(),
          },
        ),
      );

      if (!mounted) return;

      setState(() {
        settings['full_name'] = newName.trim();
        settings['name'] = newName.trim();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _changePassword() async {
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();

    final shouldChange = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                'Change Password',
                style: TextStyle(
                  color: textDark,
                  fontWeight: FontWeight.w800,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'New password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8F6FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm password',
                      prefixIcon: const Icon(Icons.lock_reset_rounded),
                      filled: true,
                      fillColor: const Color(0xFFF8F6FF),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        errorText!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel', style: TextStyle(color: textMuted)),
                ),
                FilledButton(
                  onPressed: () {
                    final password = passwordController.text;
                    final confirm = confirmController.text;

                    if (password.length < 6) {
                      setDialogState(() {
                        errorText = 'Password must be at least 6 characters.';
                      });
                      return;
                    }

                    if (password != confirm) {
                      setDialogState(() {
                        errorText = 'Passwords do not match.';
                      });
                      return;
                    }

                    Navigator.pop(dialogContext, true);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: primary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );

    final password = passwordController.text;
    passwordController.dispose();
    confirmController.dispose();

    if (shouldChange != true) return;

    try {
      await supabase.auth.updateUser(UserAttributes(password: password));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password changed successfully'),
          backgroundColor: primary,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to change password: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Log out?',
            style: TextStyle(
              color: textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          content: const Text(
            'Are you sure you want to log out of MediMate?',
            style: TextStyle(color: textMuted, fontSize: 13),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel', style: TextStyle(color: textMuted)),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: FilledButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Log out'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    try {
      await supabase.auth.signOut();

      if (!mounted) return;

      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to log out: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    IconData trailing = Icons.chevron_right_rounded,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: lavender,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: primary, size: 18),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: textDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: textMuted,
                        fontSize: 7.5,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(trailing, color: textMuted, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(Map<String, dynamic> settings) {
    return _buildActionCard(
      icon: Icons.person_rounded,
      title: _displayName(settings),
      subtitle: 'View and manage your profile',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => const ProfileScreen(),
          ),
        );
      },
      trailing: Icons.chevron_right_rounded,
    );
  }

  Widget _buildAccountCard() {
    return Column(
      children: [
        _buildActionCard(
          icon: Icons.lock_outline_rounded,
          title: 'Change Password',
          subtitle: 'Update your MediMate account password',
          onTap: _changePassword,
        ),
        const SizedBox(height: 7),
        _buildActionCard(
          icon: Icons.logout_rounded,
          title: 'Log out',
          subtitle: 'Sign out of your MediMate account',
          onTap: _logout,
        ),
      ],
    );
  }

  Widget _buildAboutCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF1ECFF),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE0D3F8)),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: primary, size: 18),
          SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About MediMate',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Medication reminders, hydration tracking and stock management in one place.',
                  style: TextStyle(
                    color: textMuted,
                    fontSize: 7.5,
                    height: 1.35,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Version 1.0.0',
                  style: TextStyle(color: textMuted, fontSize: 7),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>?>(
          future: _loadSettings(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: primary),
              );
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final settings = snapshot.data ?? <String, dynamic>{};

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 5),

                      _buildSectionTitle(
                        'Profile',
                        Icons.person_rounded,
                      ),
                      const SizedBox(height: 6),
                      _buildProfileCard(settings),

                      const SizedBox(height: 12),

                      _buildSectionTitle(
                        'Notifications',
                        Icons.notifications_rounded,
                      ),
                      const SizedBox(height: 6),

                      _buildSectionTitle(
                        'Medication',
                        Icons.medication_rounded,
                      ),
                      const SizedBox(height: 3),

                      _buildSettingsCard(
                        children: [
                          _buildSettingItem(
                            icon: Icons.notifications_active_rounded,
                            title: 'Medication Reminders',
                            subtitle:
                                'Receive reminders to take your medications',
                            value: settings['medication_reminders'] ?? false,
                            onChanged: (value) {
                              setState(() {
                                settings['medication_reminders'] = value;
                              });
                              _updateSetting('medication_reminders', value);
                            },
                          ),
                          _buildDivider(),
                          _buildSettingItem(
                            icon: Icons.inventory_2_rounded,
                            title: 'Refill Reminders',
                            subtitle:
                                'Receive reminders to refill your medications',
                            value: settings['refill_reminders'] ?? false,
                            onChanged: (value) {
                              setState(() {
                                settings['refill_reminders'] = value;
                              });
                              _updateSetting('refill_reminders', value);
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 6),

                      _buildSectionTitle(
                        'Hydration',
                        Icons.water_drop_rounded,
                      ),
                      const SizedBox(height: 3),

                      _buildSettingsCard(
                        children: [
                          _buildSettingItem(
                            icon: Icons.water_drop_rounded,
                            title: 'Hydration Reminders',
                            subtitle: 'Receive reminders to drink water',
                            value: settings['hydration_reminders'] ?? false,
                            onChanged: (value) {
                              setState(() {
                                settings['hydration_reminders'] = value;
                              });
                              _updateSetting('hydration_reminders', value);
                            },
                          ),
                          _buildDivider(),
                          _buildSettingItem(
                            icon: Icons.emoji_events_rounded,
                            title: 'Goal Achievement',
                            subtitle:
                                'Get notified when you reach your hydration goal',
                            value: settings['goal_achievement'] ?? false,
                            onChanged: (value) {
                              setState(() {
                                settings['goal_achievement'] = value;
                              });
                              _updateSetting('goal_achievement', value);
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _buildSectionTitle(
                        'Account',
                        Icons.security_rounded,
                      ),
                      const SizedBox(height: 6),
                      _buildAccountCard(),

                      const SizedBox(height: 12),

                      _buildSectionTitle(
                        'About',
                        Icons.info_outline_rounded,
                      ),
                      const SizedBox(height: 6),
                      _buildAboutCard(),

                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 45,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            top: 1,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.maybePop(context),
                  child: const Padding(
                    padding: EdgeInsets.only(right: 1),
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: primary,
                      size: 17,
                    ),
                  ),
                ),
                const Text(
                  'Notifications',
                  style: TextStyle(
                    color: textDark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const Positioned(
            left: 2,
            top: 22,
            child: Text(
              'Manage your medication and hydration reminders',
              style: TextStyle(
                color: textMuted,
                fontSize: 7.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Positioned(
            right: 1,
            top: -2,
            child: Container(
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: lavender,
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Image.asset(
                  'assets/images/notification_bell.png',
                  width: 39,
                  height: 39,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.notifications_active_rounded,
                    color: primary,
                    size: 24,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: lavender,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Icon(
            icon,
            color: primary,
            size: 12,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: const TextStyle(
            color: textDark,
            fontSize: 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsCard({
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: primary.withOpacity(0.025),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 7,
        vertical: 4,
      ),
      child: SizedBox(
        height: 31,
        child: Row(
          children: [
            Container(
              width: 25,
              height: 25,
              decoration: BoxDecoration(
                color: lavender,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: primary,
                size: 13,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textDark,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textMuted,
                      fontSize: 6.2,
                      height: 1.05,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            _buildCompactSwitch(value, onChanged),
          ],
        ),
      ),
    );
  }

  Widget _buildCompactSwitch(
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 31,
        height: 17,
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: value ? primary : const Color(0xFFD8D0E5),
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment:
              value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 13,
            height: 13,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 7),
      child: Divider(
        height: 1,
        color: Color(0xFFEDE8F4),
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: lavender,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: const Color(0xFFE0D2FA)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: primary,
              size: 12,
            ),
          ),
          const SizedBox(width: 7),
          const Expanded(
            child: Text(
              'You can turn these reminders on or off at any time. Your preferences are saved to your MediMate account.',
              style: TextStyle(
                color: textMuted,
                fontSize: 6.5,
                height: 1.15,
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildErrorState(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: border),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: Colors.red,
                size: 35,
              ),
              const SizedBox(height: 10),
              const Text(
                'Unable to load settings',
                style: TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: textMuted,
                  fontSize: 10,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => setState(() {}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(11),
                  ),
                ),
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
