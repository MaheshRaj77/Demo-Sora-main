import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/api_config.dart';
import 'theme/app_theme.dart';
import 'screens/welcome_screen.dart';
import 'screens/home_screen.dart';
import 'screens/map_screen.dart';
import 'screens/my_id_screen.dart';
import 'screens/alerts_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/biometric_lock_screen.dart';
import 'services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:google_fonts/google_fonts.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ✅ Initialize API configuration
  ApiConfig.initialize();
  
  GoogleFonts.config.allowRuntimeFetching = false;
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Colors.transparent,
  ));
  runApp(const ProviderScope(child: CampusConnectApp()));
}

/// Global theme notifier — shared across the whole app.
class ThemeNotifier extends ChangeNotifier {
  bool _isDarkMode = true;
  String? _profileImagePath;

  bool get isDarkMode => _isDarkMode;
  String? get profileImagePath => _profileImagePath;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  void setProfileImage(String path) {
    _profileImagePath = path;
    notifyListeners();
  }
}

/// Provides the ThemeNotifier down the widget tree.
class ThemeProvider extends InheritedNotifier<ThemeNotifier> {
  const ThemeProvider({
    super.key,
    required ThemeNotifier notifier,
    required super.child,
  }) : super(notifier: notifier);

  static ThemeNotifier of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<ThemeProvider>()!
        .notifier!;
  }
}

class CampusConnectApp extends StatefulWidget {
  const CampusConnectApp({super.key});

  @override
  State<CampusConnectApp> createState() => _CampusConnectAppState();
}

class _CampusConnectAppState extends State<CampusConnectApp> {
  final _themeNotifier = ThemeNotifier();

  @override
  void dispose() {
    _themeNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemeProvider(
      notifier: _themeNotifier,
      child: AnimatedBuilder(
        animation: _themeNotifier,
        builder: (context, _) {
          return MaterialApp(
            title: 'PUnova',
            debugShowCheckedModeBanner: false,
            theme: _themeNotifier.isDarkMode
                ? AppTheme.darkTheme
                : AppTheme.lightTheme,
            home: const AppEntry(),
          );
        },
      ),
    );
  }
}

/// Entry point: Login → Welcome → Dashboard flow.
class AppEntry extends StatefulWidget {
  const AppEntry({super.key});

  @override
  State<AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<AppEntry> {
  // 0 = checking, 1 = login, 2 = welcome, 3 = dashboard, 4 = guest dashboard, 5 = biometric lock
  int _screen = 0;
  int _nextScreen = 3; // what to show after unlock

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isLoggedIn = await AuthService().isLoggedIn();
    final targetScreen = isLoggedIn ? 3 : 1;

    // Check if app lock is enabled (only for logged-in users)
    if (isLoggedIn) {
      final prefs = await SharedPreferences.getInstance();
      final appLockEnabled = prefs.getBool('app_lock_enabled') ?? false;
      if (appLockEnabled) {
        setState(() {
          _nextScreen = targetScreen;
          _screen = 5; // show lock screen first
        });
        return;
      }
    }

    setState(() => _screen = targetScreen);
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case 0:
        final tc = Tc.of(context);
        return Scaffold(
          backgroundColor: tc.bg,
          body: Container(
            decoration: BoxDecoration(gradient: tc.bgGradient),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accentTeal.withValues(alpha: 0.3),
                          blurRadius: 32,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school_rounded,
                        color: Colors.white, size: 36),
                  ),
                  const SizedBox(height: 24),
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.accentTeal,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      case 1:
        return LoginScreen(
          onLoginSuccess: () => setState(() => _screen = 2),
          onGuestAccess: () {
            AuthService().loginAsGuest();
            setState(() => _screen = 4);
          },
        );
      case 2:
        return WelcomeScreen(
          onGetStarted: () => setState(() => _screen = 3),
        );
      case 4:
        return const GuestDashboardShell();
      case 5:
        return BiometricLockScreen(
          onUnlocked: () => setState(() => _screen = _nextScreen),
        );
      default:
        return const DashboardShell();
    }
  }
}

/// Liquid glass dashboard with floating frosted navigation bar.
class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _currentIndex = 0;

  void _onTabTapped(int index) {
    if (index == 2) {
      Navigator.of(context).push(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const MyIdScreen(),
          transitionsBuilder: (_, anim, __, child) {
            return FadeTransition(opacity: anim, child: child);
          },
          transitionDuration: const Duration(milliseconds: 300),
        ),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);

    final activeTab = _currentIndex > 2 ? _currentIndex - 1 : _currentIndex;
    const tabs = <Widget>[
      HomeScreen(),
      MapScreen(),
      AlertsScreen(),
      ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: tc.bg,
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: tc.bgGradient),
        child: Stack(
          children: [
            // Ambient gradient orbs
            if (tc.isDark) ...[
              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentTeal.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                left: -100,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentPurple.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
            SafeArea(
              bottom: false,
              child: tabs[activeTab],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingNavBar(tc),
    );
  }

  Widget _buildFloatingNavBar(Tc tc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: tc.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: tc.isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: tc.isDark ? 0.3 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(Icons.home_rounded, 'Home', 0, tc),
                  _navItem(Icons.map_rounded, 'Map', 1, tc),
                  _navCenterItem(tc),
                  _navItem(Icons.notifications_rounded, 'Alerts', 3, tc),
                  _navItem(Icons.person_rounded, 'Profile', 4, tc),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index, Tc tc) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentTeal.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.accentTeal : tc.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.accentTeal : tc.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navCenterItem(Tc tc) {
    return GestureDetector(
      onTap: () => _onTabTapped(2),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accentTeal.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.badge_rounded, color: Colors.white, size: 24),
      ),
    );
  }
}

/// Restricted dashboard for guest users — only Home, Map, and Alerts.
class GuestDashboardShell extends StatefulWidget {
  const GuestDashboardShell({super.key});

  @override
  State<GuestDashboardShell> createState() => _GuestDashboardShellState();
}

class _GuestDashboardShellState extends State<GuestDashboardShell> {
  int _currentIndex = 0;

  final _tabs = const <Widget>[
    HomeScreen(),
    MapScreen(),
    AlertsScreen(),
  ];

  void _onTabTapped(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);

    return Scaffold(
      backgroundColor: tc.bg,
      extendBody: true,
      body: Container(
        decoration: BoxDecoration(gradient: tc.bgGradient),
        child: Stack(
          children: [
            if (tc.isDark) ...[
              Positioned(
                top: -100,
                right: -80,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentTeal.withValues(alpha: 0.06),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 120,
                left: -100,
                child: Container(
                  width: 320,
                  height: 320,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        AppColors.accentPurple.withValues(alpha: 0.04),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
            ],
            SafeArea(
              bottom: false,
              child: _tabs[_currentIndex],
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildGuestNavBar(tc),
    );
  }

  Widget _buildGuestNavBar(Tc tc) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: SafeArea(
        top: false,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
            child: Container(
              height: 68,
              decoration: BoxDecoration(
                color: tc.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.white.withValues(alpha: 0.72),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: tc.isDark
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.06),
                  width: 0.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: tc.isDark ? 0.3 : 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _guestNavItem(Icons.home_rounded, 'Home', 0, tc),
                  _guestNavItem(Icons.map_rounded, 'Map', 1, tc),
                  _guestNavItem(Icons.notifications_rounded, 'Alerts', 2, tc),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _guestNavItem(IconData icon, String label, int index, Tc tc) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accentTeal.withValues(alpha: 0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 22,
                color: isSelected ? AppColors.accentTeal : tc.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppColors.accentTeal : tc.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
