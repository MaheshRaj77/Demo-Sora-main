import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import '../theme/app_theme.dart';

/// A lock screen that requires biometric/PIN authentication to proceed.
class BiometricLockScreen extends StatefulWidget {
  final VoidCallback onUnlocked;
  const BiometricLockScreen({super.key, required this.onUnlocked});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen>
    with SingleTickerProviderStateMixin {
  final LocalAuthentication _auth = LocalAuthentication();
  String _status = 'Verifying identity...';
  bool _isAuthenticating = false;
  bool _biometricAvailable = true;
  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnim = Tween(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
    // Check availability first, then auto-trigger
    _checkAndAuthenticate();
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  Future<void> _checkAndAuthenticate() async {
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      final canCheckBiometrics = await _auth.canCheckBiometrics;
      if (!isDeviceSupported && !canCheckBiometrics) {
        // Device doesn't support any auth — just unlock
        if (mounted) {
          setState(() {
            _biometricAvailable = false;
            _status = 'No screen lock configured. Unlocking...';
          });
          await Future.delayed(const Duration(seconds: 1));
          widget.onUnlocked();
        }
        return;
      }

      // List available biometrics for debugging
      final availableBiometrics = await _auth.getAvailableBiometrics();
      debugPrint('Available biometrics: $availableBiometrics');
      debugPrint('Device supported: $isDeviceSupported, canCheck: $canCheckBiometrics');

      await _authenticate();
    } catch (e) {
      debugPrint('Biometric check error: $e');
      // If checking fails, just unlock
      if (mounted) {
        setState(() {
          _status = 'Authentication unavailable. Unlocking...';
        });
        await Future.delayed(const Duration(seconds: 1));
        widget.onUnlocked();
      }
    }
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating || !mounted) return;
    setState(() {
      _isAuthenticating = true;
      _status = 'Verifying identity...';
    });

    try {
      final didAuthenticate = await _auth.authenticate(
        localizedReason: 'Authenticate to unlock PUnova',
      );

      if (!mounted) return;

      if (didAuthenticate) {
        widget.onUnlocked();
      } else {
        setState(() {
          _status = 'Authentication failed. Tap to retry.';
          _isAuthenticating = false;
        });
      }
    } catch (e) {
      debugPrint('Auth error: $e');
      if (!mounted) return;
      setState(() {
        _status = 'Tap the fingerprint to try again';
        _isAuthenticating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return Scaffold(
      backgroundColor: tc.bg,
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(gradient: tc.bgGradient),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // App logo
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accentTeal.withValues(alpha: 0.3),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.school_rounded,
                    color: Colors.white, size: 40),
              ),
              const SizedBox(height: 24),
              Text('PUnova',
                  style: TextStyle(
                      color: tc.textPrimary,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5)),
              const SizedBox(height: 8),
              Text('App is locked',
                  style: TextStyle(color: tc.textMuted, fontSize: 14)),
              const Spacer(),
              // Fingerprint icon with pulse
              GestureDetector(
                onTap: (_isAuthenticating || !_biometricAvailable)
                    ? null
                    : _authenticate,
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (_, child) => Transform.scale(
                    scale: _pulseAnim.value,
                    child: child,
                  ),
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.primaryGradient,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentTeal.withValues(alpha: 0.4),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.fingerprint_rounded,
                        color: Colors.white, size: 44),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(_status,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: tc.textSecondary, fontSize: 13)),
              ),
              const SizedBox(height: 16),
              // Skip button — fallback for devices with issues
              TextButton(
                onPressed: () => widget.onUnlocked(),
                child: Text('Skip',
                    style: TextStyle(color: tc.textMuted, fontSize: 12)),
              ),
              const Spacer(flex: 2),
            ],
          ),
        ),
      ),
    );
  }
}
