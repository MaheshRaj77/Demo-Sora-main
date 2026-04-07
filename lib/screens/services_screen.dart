import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  static const _services = [
    _ServiceData(
      name: 'Papido',
      subtitle: 'Bike Taxi',
      tagline: 'Quick rides around campus',
      url: 'https://wa.me/918547420669?text=Hi',
      isWhatsApp: true,
      icon: Icons.two_wheeler_rounded,
      gradientColors: [Color(0xFFFF6B35), Color(0xFFFF4500)],
      badge: 'WhatsApp',
    ),
    _ServiceData(
      name: 'Plinkit',
      subtitle: 'Grocery Delivery',
      tagline: 'Groceries at your doorstep',
      url: 'https://wa.me/919385722520?text=Hi',
      isWhatsApp: true,
      icon: Icons.shopping_bag_rounded,
      gradientColors: [Color(0xFF22C55E), Color(0xFF16A34A)],
      badge: 'WhatsApp',
    ),
    _ServiceData(
      name: 'Pumato',
      subtitle: 'Food Ordering',
      tagline: 'Order food online',
      url: 'https://pumato.online/',
      isWhatsApp: false,
      icon: Icons.restaurant_rounded,
      gradientColors: [Color(0xFFEF4444), Color(0xFFDC2626)],
      badge: 'Website',
    ),
  ];

  Future<void> _launch(BuildContext context, _ServiceData s) async {
    final uri = Uri.parse(s.url);
    try {
      final launched = await launchUrl(
        uri,
        mode: s.isWhatsApp
            ? LaunchMode.externalApplication
            : LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open ${s.name}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not open ${s.name}'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return Scaffold(
      backgroundColor: tc.bg,
      body: Container(
        decoration: BoxDecoration(gradient: tc.bgGradient),
        child: SafeArea(
          child: Column(children: [
            const GlassAppBar(title: 'Services'),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                children: [
                  Text(
                    'Campus Services',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: tc.textMuted,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ..._services.map((s) => _ServiceCard(
                    service: s,
                    onTap: () => _launch(context, s),
                  )),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final _ServiceData service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    final s = service;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            color: tc.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.white.withValues(alpha: 0.80),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: tc.glassBorder),
            boxShadow: [
              BoxShadow(
                color: s.gradientColors.first.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(children: [
            // Left icon strip
            Container(
              width: 80,
              height: 90,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: s.gradientColors,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(20)),
              ),
              child: Icon(s.icon, color: Colors.white, size: 34),
            ),
            const SizedBox(width: 16),
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Text(
                        s.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: tc.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _Badge(
                        label: s.badge,
                        isWhatsApp: s.isWhatsApp,
                        color: s.gradientColors.first,
                      ),
                    ]),
                    const SizedBox(height: 3),
                    Text(
                      s.subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: s.gradientColors.first,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      s.tagline,
                      style: TextStyle(
                        fontSize: 12,
                        color: tc.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Arrow
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: s.gradientColors.first.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  s.isWhatsApp
                      ? Icons.chat_bubble_rounded
                      : Icons.open_in_browser_rounded,
                  size: 16,
                  color: s.gradientColors.first,
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool isWhatsApp;
  final Color color;
  const _Badge({required this.label, required this.isWhatsApp, required this.color});

  @override
  Widget build(BuildContext context) {
    final bgColor = isWhatsApp ? const Color(0xFF25D366) : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: bgColor.withValues(alpha: 0.30)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(
          isWhatsApp ? Icons.chat_bubble_rounded : Icons.language_rounded,
          size: 10,
          color: bgColor,
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: bgColor,
            letterSpacing: 0.5,
          ),
        ),
      ]),
    );
  }
}

class _ServiceData {
  final String name, subtitle, tagline, url, badge;
  final bool isWhatsApp;
  final IconData icon;
  final List<Color> gradientColors;

  const _ServiceData({
    required this.name,
    required this.subtitle,
    required this.tagline,
    required this.url,
    required this.isWhatsApp,
    required this.icon,
    required this.gradientColors,
    required this.badge,
  });
}
