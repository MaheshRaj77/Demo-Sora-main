import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/api_service.dart';
import '../models/service_item.dart';

class ServicesScreen extends StatefulWidget {
  const ServicesScreen({super.key});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  List<_ServiceDisplayData> _services = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchServices();
  }

  Future<void> _fetchServices() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('/services');
      final servicesJson = response['services'] as List;
      setState(() {
        _services = servicesJson.map((j) {
          final s = ServiceItem.fromJson(j);
          return _ServiceDisplayData(
            s.name,
            s.subtitle ?? j['description'] ?? j['category'] ?? '',
            _iconFromName(s.iconName) ?? _iconFromServiceName(s.name),
            _gradientFromColors(s.gradientStart, s.gradientEnd) ??
                _gradientFromCategory(j['category']),
          );
        }).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _services = _staticServices();
        _isLoading = false;
      });
    }
  }

  IconData? _iconFromName(String? name) {
    if (name == null) return null;
    const iconMap = {
      'fastfood_rounded': Icons.fastfood_rounded,
      'account_balance_wallet_rounded': Icons.account_balance_wallet_rounded,
      'local_laundry_service_rounded': Icons.local_laundry_service_rounded,
      'edit_rounded': Icons.edit_rounded,
      'print_rounded': Icons.print_rounded,
      'local_hospital_rounded': Icons.local_hospital_rounded,
    };
    return iconMap[name];
  }

  IconData _iconFromServiceName(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('library')) return Icons.menu_book_rounded;
    if (lower.contains('health') || lower.contains('medical')) return Icons.local_hospital_rounded;
    if (lower.contains('it') || lower.contains('help') || lower.contains('tech')) return Icons.computer_rounded;
    if (lower.contains('cafeteria') || lower.contains('food') || lower.contains('canteen')) return Icons.fastfood_rounded;
    if (lower.contains('sport') || lower.contains('gym')) return Icons.sports_soccer_rounded;
    if (lower.contains('laundry')) return Icons.local_laundry_service_rounded;
    if (lower.contains('print') || lower.contains('xerox')) return Icons.print_rounded;
    if (lower.contains('hostel')) return Icons.hotel_rounded;
    if (lower.contains('transport') || lower.contains('bus')) return Icons.directions_bus_rounded;
    if (lower.contains('pay') || lower.contains('wallet') || lower.contains('fee')) return Icons.account_balance_wallet_rounded;
    return Icons.miscellaneous_services_rounded;
  }

  LinearGradient? _gradientFromColors(String? start, String? end) {
    if (start == null && end == null) return null;
    Color parseHex(String? hex, Color fallback) {
      if (hex == null || hex.isEmpty) return fallback;
      hex = hex.replaceFirst('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    }

    return LinearGradient(
      colors: [
        parseHex(start, const Color(0xFF00D2FF)),
        parseHex(end, const Color(0xFF00F0B5))
      ],
    );
  }

  LinearGradient _gradientFromCategory(String? category) {
    switch (category?.toLowerCase()) {
      case 'academic':
        return const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)]);
      case 'health':
        return const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF4ADE80)]);
      case 'tech':
        return const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)]);
      case 'food':
        return const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFF7931E)]);
      case 'recreation':
        return const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]);
      default:
        return const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF472B6)]);
    }
  }

  List<_ServiceDisplayData> _staticServices() {
    return [
      _ServiceDisplayData('Papido', 'Food Ordering', Icons.fastfood_rounded,
          const LinearGradient(colors: [Color(0xFFFF6B35), Color(0xFFF7931E)])),
      _ServiceDisplayData(
          'Plink It',
          'Digital Payments',
          Icons.account_balance_wallet_rounded,
          const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF818CF8)])),
      _ServiceDisplayData(
          'Laundry',
          'Schedule Pickup',
          Icons.local_laundry_service_rounded,
          const LinearGradient(colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)])),
      _ServiceDisplayData('Stationery', 'Order Supplies', Icons.edit_rounded,
          const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFF472B6)])),
      _ServiceDisplayData('Print Shop', 'Print & Copy', Icons.print_rounded,
          const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)])),
      _ServiceDisplayData(
          'Health',
          'Medical Services',
          Icons.local_hospital_rounded,
          const LinearGradient(colors: [Color(0xFF22C55E), Color(0xFF4ADE80)])),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return Scaffold(
      backgroundColor: tc.bg,
      body: Container(
        decoration: BoxDecoration(gradient: tc.bgGradient),
        child: SafeArea(
          child: Column(
            children: [
              const GlassAppBar(title: 'Services'),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentTeal))
                    : RefreshIndicator(
                        onRefresh: _fetchServices,
                        color: AppColors.accentTeal,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          itemCount: _services.length,
                          itemBuilder: (_, i) => _serviceCard(tc, _services[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _serviceCard(Tc tc, _ServiceDisplayData s) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                  gradient: s.gradient,
                  borderRadius: BorderRadius.circular(16)),
              child: Icon(s.icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.name,
                      style: TextStyle(
                          color: tc.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(s.subtitle,
                      style: TextStyle(color: tc.textMuted, fontSize: 13)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: tc.textMuted, size: 24),
          ],
        ),
      ),
    );
  }
}

class _ServiceDisplayData {
  final String name;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  const _ServiceDisplayData(this.name, this.subtitle, this.icon, this.gradient);
}
