import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/api_service.dart';
import '../models/alert.dart';
import '../models/lost_found_item.dart';
import 'lost_found_screen.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<Alert> _allAlerts = [];
  List<Alert> _academicAlerts = [];
  List<Alert> _emergencyAlerts = [];
  List<LostFoundItem> _lostFoundItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _fetchAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchAlerts(),
      _fetchLostFound(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAlerts() async {
    try {
      final response = await ApiService().get('/alerts');
      final alertsJson = response['alerts'] as List;
      final all = alertsJson.map((j) => Alert.fromJson(j)).toList();
      setState(() {
        _allAlerts = all;
        _academicAlerts = all.where((a) => a.category == 'academic').toList();
        _emergencyAlerts = all.where((a) => a.category == 'emergency').toList();
      });
    } catch (e) {
      setState(() {
        _allAlerts = _staticAlerts();
        _academicAlerts =
            _allAlerts.where((a) => a.category == 'academic').toList();
        _emergencyAlerts =
            _allAlerts.where((a) => a.category == 'emergency').toList();
      });
    }
  }

  Future<void> _fetchLostFound() async {
    try {
      final response = await ApiService().get('/lost-found');
      final itemsJson = response['items'] as List;
      setState(() {
        _lostFoundItems =
            itemsJson.map((j) => LostFoundItem.fromJson(j)).toList();
      });
    } catch (e) {
      setState(() {
        _lostFoundItems = _staticLostFound();
      });
    }
  }

  // ── Static fallback data ──
  List<Alert> _staticAlerts() {
    return [
      Alert(
          id: '1',
          title: 'Class Cancelled',
          description: 'Data Structures class at 10 AM is cancelled today.',
          category: 'academic',
          priority: 'normal',
          createdAt: DateTime.now().subtract(const Duration(minutes: 30))),
      Alert(
          id: '2',
          title: 'Library Due',
          description: 'Return "Design Patterns" by tomorrow.',
          category: 'academic',
          priority: 'normal',
          createdAt: DateTime.now().subtract(const Duration(hours: 1))),
      Alert(
          id: '3',
          title: 'Weather Alert',
          description: 'Heavy rain expected. Carry an umbrella.',
          category: 'emergency',
          priority: 'high',
          createdAt: DateTime.now().subtract(const Duration(hours: 2))),
      Alert(
          id: '4',
          title: 'Exam Schedule',
          description: 'Mid-semester exams start from March 15.',
          category: 'academic',
          priority: 'normal',
          createdAt: DateTime.now().subtract(const Duration(hours: 5))),
      Alert(
          id: '5',
          title: 'Assignment Due',
          description: 'OS assignment submission deadline is tomorrow.',
          category: 'academic',
          priority: 'normal',
          createdAt: DateTime.now().subtract(const Duration(hours: 3))),
      Alert(
          id: '6',
          title: 'New Grades',
          description: 'DBMS lab grades have been published.',
          category: 'academic',
          priority: 'normal',
          createdAt: DateTime.now().subtract(const Duration(days: 1))),
      Alert(
          id: '7',
          title: 'Campus Closure',
          description: 'Campus will be closed on Feb 25 for maintenance.',
          category: 'emergency',
          priority: 'high',
          createdAt: DateTime.now().subtract(const Duration(hours: 6))),
      Alert(
          id: '8',
          title: 'Weather Warning',
          description:
              'Cyclone alert: Stay indoors. All outdoor activities suspended.',
          category: 'emergency',
          priority: 'urgent',
          createdAt: DateTime.now().subtract(const Duration(hours: 8))),
      Alert(
          id: '9',
          title: 'Safety Threat',
          description:
              'Suspicious activity reported near Block C. Avoid the area.',
          category: 'emergency',
          priority: 'urgent',
          createdAt: DateTime.now().subtract(const Duration(hours: 10))),
      Alert(
          id: '10',
          title: 'Power Shutdown',
          description:
              'Scheduled power cut from 2 PM - 5 PM in academic blocks.',
          category: 'emergency',
          priority: 'normal',
          createdAt: DateTime.now().subtract(const Duration(hours: 12))),
    ];
  }

  List<LostFoundItem> _staticLostFound() {
    return [
      LostFoundItem(
          id: '1',
          itemType: 'found',
          category: 'Bags',
          itemName: 'Blue Backpack',
          location: 'Found near Library entrance',
          createdAt: DateTime.now().subtract(const Duration(hours: 1))),
      LostFoundItem(
          id: '2',
          itemType: 'lost',
          category: 'ID / Cards',
          itemName: 'Student ID Card',
          location: 'Lost in Cafeteria area',
          createdAt: DateTime.now().subtract(const Duration(hours: 3))),
      LostFoundItem(
          id: '3',
          itemType: 'found',
          category: 'Electronics',
          itemName: 'AirPods Pro',
          location: 'Found in Lecture Hall 3',
          createdAt: DateTime.now().subtract(const Duration(hours: 5))),
      LostFoundItem(
          id: '4',
          itemType: 'lost',
          category: 'Electronics',
          itemName: 'Laptop Charger',
          location: 'Lost in Computer Lab B',
          createdAt: DateTime.now().subtract(const Duration(days: 1))),
    ];
  }

  // ── Helpers ──
  String _relativeTime(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }

  IconData _alertIcon(Alert alert) {
    switch (alert.category) {
      case 'academic':
        if (alert.title.toLowerCase().contains('grade')) {
          return Icons.grade_rounded;
        }
        if (alert.title.toLowerCase().contains('assignment')) {
          return Icons.assignment_rounded;
        }
        if (alert.title.toLowerCase().contains('exam')) {
          return Icons.event_note_rounded;
        }
        if (alert.title.toLowerCase().contains('library')) {
          return Icons.menu_book_rounded;
        }
        return Icons.school_rounded;
      case 'emergency':
        if (alert.title.toLowerCase().contains('weather') ||
            alert.title.toLowerCase().contains('cyclone')) {
          return Icons.thunderstorm_rounded;
        }
        if (alert.title.toLowerCase().contains('power')) {
          return Icons.power_off_rounded;
        }
        if (alert.title.toLowerCase().contains('closure')) {
          return Icons.lock_rounded;
        }
        return Icons.warning_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _alertColor(Alert alert) {
    switch (alert.category) {
      case 'academic':
        return [
          AppColors.accentTeal,
          AppColors.accentOrange,
          AppColors.accentPink,
          AppColors.accentGreen,
        ][alert.title.hashCode.abs() % 4];
      case 'emergency':
        return AppColors.accentRed;
      default:
        return AppColors.accentPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child:
              Text('Alerts', style: Theme.of(context).textTheme.headlineMedium),
        ),
        const SizedBox(height: 16),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 20),
          decoration: BoxDecoration(
              color: tc.glassWhite, borderRadius: BorderRadius.circular(14)),
          child: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorSize: TabBarIndicatorSize.tab,
            indicator: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(12)),
            labelColor: Colors.white,
            unselectedLabelColor: tc.textMuted,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            unselectedLabelStyle: const TextStyle(fontSize: 13),
            dividerColor: Colors.transparent,
            padding: const EdgeInsets.all(4),
            tabs: const [
              Tab(text: 'All'),
              Tab(text: 'Academics'),
              Tab(text: 'Lost & Found'),
              Tab(text: 'Emergency')
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.accentTeal))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAllTab(tc),
                    _buildAcademicsTab(tc),
                    _buildLostFoundTab(context, tc),
                    _buildEmergencyTab(tc)
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildAllTab(Tc tc) {
    if (_allAlerts.isEmpty) {
      return Center(
          child: Text('No alerts yet',
              style: TextStyle(color: tc.textMuted, fontSize: 16)));
    }
    return RefreshIndicator(
      onRefresh: _fetchAll,
      color: AppColors.accentTeal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: _allAlerts.length,
        itemBuilder: (_, i) {
          final alert = _allAlerts[i];
          return _alertCard(
              tc,
              alert.title,
              alert.description ?? '',
              _relativeTime(alert.createdAt),
              _alertIcon(alert),
              _alertColor(alert));
        },
      ),
    );
  }

  Widget _buildAcademicsTab(Tc tc) {
    if (_academicAlerts.isEmpty) {
      return Center(
          child: Text('No academic alerts',
              style: TextStyle(color: tc.textMuted, fontSize: 16)));
    }
    return RefreshIndicator(
      onRefresh: _fetchAll,
      color: AppColors.accentTeal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: _academicAlerts.length,
        itemBuilder: (_, i) {
          final alert = _academicAlerts[i];
          return _alertCard(
              tc,
              alert.title,
              alert.description ?? '',
              _relativeTime(alert.createdAt),
              _alertIcon(alert),
              _alertColor(alert));
        },
      ),
    );
  }

  Widget _buildLostFoundTab(BuildContext context, Tc tc) {
    return Stack(
      children: [
        _lostFoundItems.isEmpty
            ? Center(
                child: Text('No lost & found items',
                    style: TextStyle(color: tc.textMuted, fontSize: 16)))
            : RefreshIndicator(
                onRefresh: _fetchAll,
                color: AppColors.accentTeal,
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: _lostFoundItems.length,
                  itemBuilder: (_, i) {
                    final item = _lostFoundItems[i];
                    return _lostFoundCard(
                        tc,
                        item.itemName,
                        item.location ?? 'Location not specified',
                        _relativeTime(item.createdAt),
                        item.itemType == 'found');
                  },
                ),
              ),
        Positioned(
          right: 20,
          bottom: 20,
          child: GestureDetector(
            onTap: () async {
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const LostFoundScreen()));
              _fetchLostFound(); // refresh after returning
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
              ),
              child:
                  const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyTab(Tc tc) {
    if (_emergencyAlerts.isEmpty) {
      return Center(
          child: Text('No emergency alerts',
              style: TextStyle(color: tc.textMuted, fontSize: 16)));
    }
    return RefreshIndicator(
      onRefresh: _fetchAll,
      color: AppColors.accentTeal,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
        itemCount: _emergencyAlerts.length,
        itemBuilder: (_, i) {
          final alert = _emergencyAlerts[i];
          return _emergencyCard(
              tc, alert.title, alert.description ?? '', _alertIcon(alert));
        },
      ),
    );
  }

  Widget _alertCard(Tc tc, String title, String desc, String time,
      IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(title,
                            style: TextStyle(
                                color: tc.textPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 14))),
                    Text(time,
                        style: TextStyle(color: tc.textMuted, fontSize: 11)),
                  ]),
                  const SizedBox(height: 6),
                  Text(desc,
                      style: TextStyle(
                          color: tc.textSecondary, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _lostFoundCard(
      Tc tc, String item, String location, String time, bool isFound) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (isFound ? AppColors.accentGreen : AppColors.accentRed)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                  isFound ? Icons.check_circle_rounded : Icons.search_rounded,
                  color: isFound ? AppColors.accentGreen : AppColors.accentRed,
                  size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item,
                      style: TextStyle(
                          color: tc.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(location,
                      style: TextStyle(color: tc.textMuted, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color:
                        (isFound ? AppColors.accentGreen : AppColors.accentRed)
                            .withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(isFound ? 'Found' : 'Lost',
                      style: TextStyle(
                          color: isFound
                              ? AppColors.accentGreen
                              : AppColors.accentRed,
                          fontSize: 10,
                          fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 6),
                Text(time, style: TextStyle(color: tc.textMuted, fontSize: 10)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emergencyCard(Tc tc, String title, String desc, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: AppColors.accentRed.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Icon(icon, color: AppColors.accentRed, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          color: tc.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 6),
                  Text(desc,
                      style: TextStyle(
                          color: tc.textSecondary, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
