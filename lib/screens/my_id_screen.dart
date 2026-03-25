import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:qr_flutter/qr_flutter.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/auth_service.dart';

class MyIdScreen extends StatefulWidget {
  const MyIdScreen({super.key});

  @override
  State<MyIdScreen> createState() => _MyIdScreenState();
}

class _MyIdScreenState extends State<MyIdScreen> {
  String _name = '';
  String _role = 'STUDENT';
  String _idNumber = '';
  String _department = '';
  String _validUpto = '31/05/2026';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final user = await AuthService().getProfile();
      if (mounted) {
        setState(() {
          _name = user['full_name'] ?? user['name'] ?? 'Student';
          _role = (user['role'] ?? 'STUDENT').toString().toUpperCase();
          _idNumber = user['roll_number'] ?? user['id']?.toString() ?? '';
          _department = user['department'] ?? 'Computer Science';
          _validUpto = user['valid_upto'] ?? '31/05/2026';
          _isLoading = false;
        });
      } else {
        _useFallback();
      }
    } catch (_) {
      _useFallback();
    }
  }

  void _useFallback() {
    if (!mounted) return;
    setState(() {
      _name = 'Balakumaran D';
      _role = 'POST GRADUATION';
      _idNumber = 'S67480';
      _department = 'Computer Science';
      _validUpto = '31/05/2026';
      _isLoading = false;
    });
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
            if (tc.isDark) ...[
              Positioned(
                top: -80,
                right: -60,
                child: _orb(AppColors.accentBlue, 260, 0.08),
              ),
              Positioned(
                bottom: 100,
                left: -80,
                child: _orb(AppColors.accentPurple, 280, 0.05),
              ),
            ],
            SafeArea(
              child: Column(
                children: [
                  GlassAppBar(
                    title: 'My ID',
                    actions: [
                      GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: tc.glassFill,
                            borderRadius: BorderRadius.circular(12),
                            border:
                                Border.all(color: tc.glassBorder, width: 0.5),
                          ),
                          child: Icon(Icons.share_outlined,
                              color: tc.textSecondary, size: 18),
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 8),
                      physics: const BouncingScrollPhysics(),
                      child: _buildIdCard(context, tc),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIdCard(BuildContext context, Tc tc) {
    const double avatarRadius = 44;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: tc.isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.white.withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: tc.glassBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: tc.isDark ? 0.2 : 0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header ──
              Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 28),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F3AAE), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius:
                          BorderRadius.vertical(top: Radius.circular(24)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.school,
                              color: Colors.white, size: 15),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Pondicherry University',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: AppColors.warmGradient,
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle, color: tc.bgCard),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: tc.bgMedium,
                          child: Icon(Icons.person_rounded,
                              size: 44, color: tc.textMuted),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 1),

              // ── Name & Role ──
              _isLoading
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accentTeal),
                    )
                  : Column(
                      children: [
                        Text(
                          _name,
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: tc.textPrimary),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: AppColors.accentTeal.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _role,
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.accentTeal,
                                letterSpacing: 1.4),
                          ),
                        ),
                      ],
                    ),

              const SizedBox(height: 22),

              // ── QR Code ──
              SizedBox(
                width: 160,
                height: 160,
                child: CustomPaint(
                  painter: _CornerBorderPainter(
                    color: AppColors.accentTeal.withValues(alpha: 0.35),
                    strokeWidth: 2.5,
                    cornerLength: 24,
                    cornerRadius: 8,
                  ),
                  child: Center(
                    child: QrImageView(
                      data:
                          'PUNOVA-$_idNumber-${_name.replaceAll(' ', '-').toUpperCase()}',
                      version: QrVersions.auto,
                      size: 128,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: Color(0xFF0F2A4A)),
                      dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: Color(0xFF0F2A4A)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Scan for campus access',
                  style: TextStyle(
                      fontSize: 12,
                      color: tc.textMuted,
                      fontStyle: FontStyle.italic)),

              const SizedBox(height: 18),

              // ── Divider ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Container(
                  height: 0.5,
                  color: tc.glassBorder,
                ),
              ),

              const SizedBox(height: 18),

              // ── Details ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                            child: _detailBlock(tc, 'ID NUMBER', _idNumber,
                                CrossAxisAlignment.start)),
                        _detailBlock(tc, 'VALID UPTO', _validUpto,
                            CrossAxisAlignment.end),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('DEPARTMENT',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: tc.textMuted,
                                letterSpacing: 1)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 10),
                          decoration: BoxDecoration(
                            color: tc.glassFill,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: tc.glassBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.computer_rounded,
                                  size: 16, color: AppColors.accentTeal),
                              const SizedBox(width: 8),
                              Text(_department,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: tc.textPrimary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sync_rounded, size: 14, color: tc.textMuted),
                  const SizedBox(width: 6),
                  Text('Last synced: Just now',
                      style: TextStyle(fontSize: 12, color: tc.textMuted)),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailBlock(
      Tc tc, String label, String value, CrossAxisAlignment align) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tc.textMuted,
                letterSpacing: 1)),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: tc.textPrimary,
                letterSpacing: 0.5)),
      ],
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

class _CornerBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double cornerRadius;

  _CornerBorderPainter(
      {required this.color,
      required this.strokeWidth,
      required this.cornerLength,
      required this.cornerRadius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final w = size.width, h = size.height, cl = cornerLength, r = cornerRadius;

    canvas.drawPath(
        Path()
          ..moveTo(0, cl)
          ..lineTo(0, r)
          ..quadraticBezierTo(0, 0, r, 0)
          ..lineTo(cl, 0),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(w - cl, 0)
          ..lineTo(w - r, 0)
          ..quadraticBezierTo(w, 0, w, r)
          ..lineTo(w, cl),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(0, h - cl)
          ..lineTo(0, h - r)
          ..quadraticBezierTo(0, h, r, h)
          ..lineTo(cl, h),
        paint);
    canvas.drawPath(
        Path()
          ..moveTo(w - cl, h)
          ..lineTo(w - r, h)
          ..quadraticBezierTo(w, h, w, h - r)
          ..lineTo(w, h - cl),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
