import 'package:flutter/material.dart';

import '../screens/theme/app_theme.dart';

class AuthBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const AuthBackButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(
        AppSpacing.sm,
      ),
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: AppColors.primary.withAlpha(45),
        shape: const CircleBorder(),
        child: IconButton(
          onPressed: onPressed,
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          tooltip: 'Back',
        ),
      ),
    );
  }
}

class AuthBackground extends StatelessWidget {
  final Widget child;

  const AuthBackground({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: Stack(
        children: [
          // Top-right purple glow
          Positioned(
            top: -120,
            right: -90,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(30),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Top-left soft purple glow
          Positioned(
            top: 80,
            left: -150,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(24),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Bottom-left stronger purple shape
          Positioned(
            bottom: -140,
            left: -100,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(35),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Bottom-right purple glow
          Positioned(
            bottom: -100,
            right: -120,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(24),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Small decorative purple circle
          Positioned(
            top: 180,
            right: 80,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(55),
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Small decorative circle
          Positioned(
            bottom: 180,
            left: 70,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.secondary.withAlpha(55),
                shape: BoxShape.circle,
              ),
            ),
          ),

          child,
        ],
      ),
    );
  }
}

class AuthHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const AuthHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(
                color: AppColors.textPrimary,
              ),
        ),

        const SizedBox(
          height: AppSpacing.sm,
        ),

        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      ],
    );
  }
}

class AuthCard extends StatelessWidget {
  final Widget child;

  const AuthCard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(
        AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(
          AppRadius.card,
        ),
        border: Border.all(
          color: AppColors.border,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(30),
            blurRadius: 35,
            spreadRadius: 2,
            offset: const Offset(
              0,
              16,
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}

class PrimaryAuthButton extends StatelessWidget {
  final String label;
  final bool isLoading;
  final VoidCallback? onPressed;

  const PrimaryAuthButton({
    super.key,
    required this.label,
    this.isLoading = false,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled =
        onPressed == null || isLoading;

    return SizedBox(
      height: 56,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: disabled
              ? const LinearGradient(
                  colors: [
                    Color(0xFFB8A9D9),
                    Color(0xFFAFA0D0),
                  ],
                )
              : AppColors.primaryGradient,

          borderRadius: BorderRadius.circular(
            AppRadius.button,
          ),

          boxShadow: disabled
              ? []
              : [
                  BoxShadow(
                    color:
                        AppColors.primary.withAlpha(65),
                    blurRadius: 16,
                    offset: const Offset(
                      0,
                      7,
                    ),
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: disabled
              ? null
              : onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor:
                Colors.transparent,
            shadowColor: Colors.transparent,
            elevation: 0,

            foregroundColor: Colors.white,

            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                AppRadius.button,
              ),
            ),
          ),
          child: isLoading
              ? const SizedBox(
                  width: 23,
                  height: 23,
                  child:
                      CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}

class AuthFooterLink extends StatelessWidget {
  final String question;
  final String actionLabel;
  final VoidCallback onTap;

  const AuthFooterLink({
    super.key,
    required this.question,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        if (question.isNotEmpty)
          Text(
            question,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),

        if (question.isNotEmpty)
          const SizedBox(
            width: 5,
          ),

        GestureDetector(
          onTap: onTap,
          child: Text(
            actionLabel,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class AnimatedLogo extends StatefulWidget {
  final Widget logo;

  const AnimatedLogo({
    super.key,
    required this.logo,
  });

  @override
  State<AnimatedLogo> createState() =>
      _AnimatedLogoState();
}

class _AnimatedLogoState
    extends State<AnimatedLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  late final Animation<double>
      _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 700,
      ),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: widget.logo,
    );
  }
}