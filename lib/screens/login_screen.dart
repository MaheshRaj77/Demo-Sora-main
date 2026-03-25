import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/auth_service.dart';
import '../services/api_service.dart';

class LoginScreen extends StatefulWidget {
  final VoidCallback onLoginSuccess;
  final VoidCallback onGuestAccess;

  const LoginScreen({
    super.key,
    required this.onLoginSuccess,
    required this.onGuestAccess,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  bool _isLogin = true;
  bool _isLoading = false;
  String? _error;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _departmentController = TextEditingController();
  final _rollNumberController = TextEditingController();
  String? _selectedYear;
  String? _selectedSemester;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.1, 0.8, curve: Curves.easeOutCubic),
    ));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    _departmentController.dispose();
    _rollNumberController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _error = 'Please fill in all required fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await AuthService().login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        await AuthService().register(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          fullName: _nameController.text.trim(),
          department: _departmentController.text.trim().isEmpty
              ? null
              : _departmentController.text.trim(),
          year: _selectedYear,
          semester: _selectedSemester,
          rollNumber: _rollNumberController.text.trim().isEmpty
              ? null
              : _rollNumberController.text.trim(),
        );
      }
      widget.onLoginSuccess();
    } on ApiException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Connection error. Is the server running?');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);

    return Scaffold(
      backgroundColor: tc.bg,
      body: Container(
        decoration: BoxDecoration(gradient: tc.bgGradient),
        child: Stack(
          children: [
            // Ambient orbs
            if (tc.isDark) ...[
              Positioned(
                top: -60,
                left: -80,
                child: _orb(AppColors.accentTeal, 260, 0.08),
              ),
              Positioned(
                bottom: 80,
                right: -100,
                child: _orb(AppColors.accentPurple, 300, 0.06),
              ),
              Positioned(
                top: 200,
                right: -40,
                child: _orb(AppColors.accentBlue, 200, 0.04),
              ),
            ],
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnim,
                child: SlideTransition(
                  position: _slideAnim,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLogo(tc),
                        const SizedBox(height: 44),
                        _buildToggle(tc),
                        const SizedBox(height: 28),
                        if (_error != null) ...[
                          _buildError(),
                          const SizedBox(height: 16),
                        ],
                        _buildForm(tc),
                        const SizedBox(height: 32),
                        _buildSubmit(tc),
                        const SizedBox(height: 16),
                        _buildGuestButton(tc),
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
    return Center(
      child: Column(
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(26),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentTeal.withValues(alpha: 0.3),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: const Icon(Icons.school_rounded,
                color: Colors.white, size: 42),
          ),
          const SizedBox(height: 20),
          Text(
            'PUnova',
            style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontSize: 36,
                  letterSpacing: -0.8,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            _isLogin
                ? 'Welcome back! Sign in to continue.'
                : 'Create your campus account.',
            style: TextStyle(color: tc.textMuted, fontSize: 15, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildToggle(Tc tc) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: tc.glassFill,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: tc.glassBorder, width: 0.5),
          ),
          child: Row(
            children: [
              _tabButton('Sign In', _isLogin, tc,
                  () => setState(() => _isLogin = true)),
              _tabButton('Register', !_isLogin, tc,
                  () => setState(() => _isLogin = false)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.accentRed.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.accentRed.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.accentRed, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!,
                style: const TextStyle(
                    color: AppColors.accentRed, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildForm(Tc tc) {
    return Column(
      children: [
        if (!_isLogin) ...[
          GlassTextField(
            hint: 'Full Name',
            controller: _nameController,
            icon: Icons.person_rounded,
          ),
          const SizedBox(height: 14),
        ],
        GlassTextField(
          hint: 'Email',
          controller: _emailController,
          icon: Icons.email_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 14),
        GlassTextField(
          hint: 'Password',
          controller: _passwordController,
          icon: Icons.lock_rounded,
          isPassword: true,
        ),
        if (!_isLogin) ...[
          const SizedBox(height: 14),
          GlassTextField(
            hint: 'Department',
            controller: _departmentController,
            icon: Icons.business_rounded,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _glassDropdown(
                  hint: 'Year',
                  icon: Icons.calendar_today_rounded,
                  value: _selectedYear,
                  items: const ['1st Year', '2nd Year', '3rd Year', '4th Year'],
                  onChanged: (v) => setState(() => _selectedYear = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _glassDropdown(
                  hint: 'Semester',
                  icon: Icons.school_rounded,
                  value: _selectedSemester,
                  items: const ['1', '2', '3', '4', '5', '6', '7', '8'],
                  onChanged: (v) => setState(() => _selectedSemester = v),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          GlassTextField(
            hint: 'Roll Number',
            controller: _rollNumberController,
            icon: Icons.badge_rounded,
          ),
        ],
      ],
    );
  }

  Widget _buildSubmit(Tc tc) {
    return SizedBox(
      width: double.infinity,
      child: GlassButton(
        text: _isLogin ? 'Sign In' : 'Create Account',
        onPressed: _isLoading ? null : _submit,
        isLoading: _isLoading,
        icon: _isLoading ? null : Icons.arrow_forward_rounded,
      ),
    );
  }

  Widget _buildGuestButton(Tc tc) {
    return SizedBox(
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: GestureDetector(
            onTap: widget.onGuestAccess,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: tc.glassFill,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: tc.glassBorder, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.person_outline_rounded,
                      color: tc.textMuted, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Continue as Guest',
                    style: TextStyle(
                      color: tc.textMuted,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabButton(String label, bool isActive, Tc tc, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: isActive ? AppColors.primaryGradient : null,
            borderRadius: BorderRadius.circular(13),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : tc.textMuted,
              fontWeight: FontWeight.w600,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }

  Widget _glassDropdown({
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final tc = Tc.of(context);
    return Container(
      decoration: BoxDecoration(
        color: tc.glassFill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tc.glassBorder, width: 0.5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: Row(
            children: [
              Icon(icon, color: tc.textMuted, size: 20),
              const SizedBox(width: 10),
              Text(hint, style: TextStyle(color: tc.textMuted, fontSize: 15)),
            ],
          ),
          icon: Icon(Icons.expand_more_rounded, color: tc.textMuted, size: 20),
          dropdownColor: tc.isDark
              ? const Color(0xFF1E1E2C)
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          style: TextStyle(color: tc.textPrimary, fontSize: 16),
          items: items.map((item) => DropdownMenuItem(
            value: item,
            child: Row(
              children: [
                Icon(icon, color: tc.textMuted, size: 18),
                const SizedBox(width: 10),
                Text(item),
              ],
            ),
          )).toList(),
          onChanged: onChanged,
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
