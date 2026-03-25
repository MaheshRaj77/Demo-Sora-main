import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';

class WelcomeScreen extends StatefulWidget {
  final VoidCallback onGetStarted;

  const WelcomeScreen({super.key, required this.onGetStarted});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);

    return Scaffold(
      backgroundColor: tc.bg,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(gradient: tc.bgGradient),
        child: Stack(
          children: [
            // Liquid gradient orbs
            Positioned(
              top: -80,
              right: -60,
              child: _orb(AppColors.accentTeal, 300, 0.1),
            ),
            Positioned(
              bottom: 140,
              left: -100,
              child: _orb(AppColors.accentPurple, 340, 0.07),
            ),
            Positioned(
              top: 300,
              left: 100,
              child: _orb(AppColors.accentBlue, 200, 0.04),
            ),
            // Content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        const Spacer(flex: 2),
                        _buildLogo(tc),
                        const SizedBox(height: 32),
                        Text(
                          'PUnova',
                          textAlign: TextAlign.center,
                          style: Theme.of(context)
                              .textTheme
                              .headlineLarge
                              ?.copyWith(
                                fontSize: 42,
                                height: 1.1,
                                letterSpacing: -1,
                              ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Your complete university companion.\nEverything you need, one tap away.',
                          textAlign: TextAlign.center,
                          style:
                              Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    height: 1.6,
                                    color: tc.textMuted,
                                  ),
                        ),
                        const Spacer(flex: 2),
                        _buildFeatures(tc),
                        const Spacer(),
                        SizedBox(
                          width: double.infinity,
                          child: GlassButton(
                            text: 'Get Started',
                            icon: Icons.arrow_forward_rounded,
                            onPressed: widget.onGetStarted,
                          ),
                        ),
                        const SizedBox(height: 44),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogo(Tc tc) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentTeal.withValues(alpha: 0.3),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: Image.asset('assets/images/app_logo.png', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildFeatures(Tc tc) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      alignment: WrapAlignment.center,
      children: [
        _featurePill(tc, Icons.badge_outlined, 'Digital ID'),
        _featurePill(tc, Icons.directions_bus_outlined, 'Bus Tracking'),
        _featurePill(tc, Icons.forum_outlined, 'Forum'),
        _featurePill(tc, Icons.event_outlined, 'Events'),
      ],
    );
  }

  Widget _featurePill(Tc tc, IconData icon, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: tc.glassFill,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: tc.glassBorder, width: 0.5),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.accentTeal),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: tc.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orb(Color color, double size, double alpha) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color.withValues(alpha: alpha), Colors.transparent],
        ),
      ),
    );
  }
}
