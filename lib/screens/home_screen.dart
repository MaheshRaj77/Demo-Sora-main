import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../widgets/shared_widgets.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'forum_screen.dart';
import 'services_screen.dart';
import 'events_screen.dart';
import 'circulars_screen.dart';
import 'timetable_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'alerts_screen.dart';
import 'map_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Student';
  String _department = 'Computer Science';
  int _semester = 5;
  List<Map<String, dynamic>> _updates = [];
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    await Future.wait([
      _loadUserData(),
      _fetchUpdates(),
    ]);
  }

  Future<void> _loadUserData() async {
    try {
      final isLoggedIn = await AuthService().isLoggedIn();
      if (isLoggedIn) {
        final response = await AuthService().getProfile();
        final user = response['user'];
        if (mounted && user != null) {
          setState(() {
            _userName = user['full_name'] ?? 'Student';
            _department = user['department'] ?? 'Computer Science';
            _semester = int.tryParse(user['semester']?.toString() ?? '') ?? 0;
          });
        }
      }
    } catch (e) {
      // Use defaults
    }
  }

  Future<void> _fetchUpdates() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _hasError = false;
    });
    try {
      final response = await ApiService().get('/circulars');
      final circulars = response['circulars'] as List;
      if (mounted) {
        setState(() {
          _updates = circulars.take(3).map((c) {
            return {
              'tag': c['is_important'] == true ? 'Important' : 'Academic',
              'time': _timeAgo(DateTime.parse(c['created_at'])),
              'title': c['title'] as String,
              'desc': (c['description'] ?? '') as String,
              'color': c['is_important'] == true
                  ? AppColors.error
                  : AppColors.accent,
            };
          }).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
        _updates = [];
      });
    }
  }

  String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => screen,
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 200),
      ),
    );
  }

  Future<void> _launchResultsUrl() async {
    final uri = Uri.parse('https://pondiuni.samarth.edu.in/index.php/site/login');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    // Dynamically compute bottom padding to account for nav bar + safe area
    final bottomPad = MediaQuery.of(context).padding.bottom + 80;
    return RefreshIndicator(
      onRefresh: _loadAll,
      color: AppColors.accent,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: EdgeInsets.fromLTRB(20, 12, 20, bottomPad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Greeting ──
            _buildGreeting(context, tc),
            const SizedBox(height: 16),

            // ── Search Bar ──
            SearchBarGlass(
              hint: 'Search services, events, forum...',
              readOnly: true,
              onTap: () {
                // Open a search overlay
                _showSearchSheet(context, tc);
              },
            ),
            const SizedBox(height: 28),

            // ── Quick Access ──
            const SectionHeader(title: 'Quick Access'),
            const SizedBox(height: 14),
            _buildQuickAccess(context, tc),
            const SizedBox(height: 28),

            // ── Academics ──
            const SectionHeader(title: 'Academics'),
            const SizedBox(height: 14),
            _buildAcademics(context, tc),
            const SizedBox(height: 28),

            // ── Campus ──
            const SectionHeader(title: 'Campus'),
            const SizedBox(height: 14),
            _buildCampusRow(context, tc),
            const SizedBox(height: 28),

            // ── Latest Updates ──
            SectionHeader(
              title: 'Latest Updates',
              actionText: 'See All',
              onAction: () => _navigateTo(context, const CircularsScreen()),
            ),
            const SizedBox(height: 14),

            if (_isLoading)
              const SkeletonListLoader(itemCount: 2)
            else if (_hasError)
              ErrorCard(
                message: 'Could not load updates',
                onRetry: _fetchUpdates,
              )
            else if (_updates.isEmpty)
              const EmptyState(
                icon: Icons.article_outlined,
                title: 'No updates yet',
                subtitle: 'New circulars and announcements will appear here.',
              )
            else
              ..._updates.map((u) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _buildUpdateCard(
                    tc,
                    u['tag'] as String,
                    u['time'] as String,
                    u['title'] as String,
                    u['desc'] as String,
                    u['color'] as Color,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ── GREETING ──
  Widget _buildGreeting(BuildContext context, Tc tc) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good Morning'
        : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: tc.bgSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: tc.border, width: 1),
          ),
          child: Icon(Icons.person_rounded, size: 24, color: tc.textSecondary),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting, $_userName',
                style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _semester > 0
                    ? '$_department  ·  Sem $_semester'
                    : _department,
                style: TextStyle(color: tc.textMuted, fontSize: 13),
              ),
            ],
          ),
        ),
        GestureDetector(
          onTap: () => _navigateTo(context, const AlertsScreen()),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tc.bgSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tc.border, width: 1),
            ),
            child: Icon(Icons.notifications_none_rounded,
                color: tc.textSecondary, size: 20),
          ),
        ),
      ],
    );
  }

  // ── QUICK ACCESS 2×2 GRID ──
  Widget _buildQuickAccess(BuildContext context, Tc tc) {
    final items = [
      _QuickItem(Icons.forum_rounded, 'Forum', AppColors.accentPurple,
          () => _navigateTo(context, const ForumScreen())),
      _QuickItem(Icons.miscellaneous_services_rounded, 'Services',
          AppColors.accentPink,
          () => _navigateTo(context, const ServicesScreen())),
      _QuickItem(Icons.event_rounded, 'Events', AppColors.accentOrange,
          () => _navigateTo(context, const EventsScreen())),
      _QuickItem(Icons.description_rounded, 'Circulars', AppColors.accentTeal,
          () => _navigateTo(context, const CircularsScreen())),
    ];

    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: items.map((item) {
          return _quickAccessTile(tc, item);
        }).toList(),
      ),
    );
  }

  Widget _quickAccessTile(Tc tc, _QuickItem item) {
    // Tile icon size scales with screen width (compact on small phones)
    final iconSize = MediaQuery.of(context).size.width < 360 ? 44.0 : 52.0;
    return GestureDetector(
      onTap: item.onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSize,
            height: iconSize,
            decoration: BoxDecoration(
              color: item.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(item.icon, color: item.color, size: iconSize * 0.46),
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: TextStyle(
              color: tc.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ── ACADEMICS ROW ──
  Widget _buildAcademics(BuildContext context, Tc tc) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.schedule_rounded,
            title: 'Timetable',
            subtitle: 'View schedule',
            color: AppColors.accent,
            onTap: () => _navigateTo(context, const TimetableScreen()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.assessment_rounded,
            title: 'Results',
            subtitle: 'View grades',
            color: AppColors.accentGreen,
            onTap: () => _launchResultsUrl(),
          ),
        ),
      ],
    );
  }

  // ── CAMPUS ROW ──
  Widget _buildCampusRow(BuildContext context, Tc tc) {
    return Row(
      children: [
        Expanded(
          child: _ActionCard(
            icon: Icons.map_rounded,
            title: 'Map',
            subtitle: 'Campus map',
            color: AppColors.accentOrange,
            onTap: () => _navigateTo(context, const MapScreen()),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _ActionCard(
            icon: Icons.search_rounded,
            title: 'Lost & Found',
            subtitle: 'Find & report',
            color: AppColors.accentPink,
            onTap: () => _navigateTo(context, const AlertsScreen(initialTab: 2)),
          ),
        ),
      ],
    );
  }

  // ── UPDATE CARD ──
  Widget _buildUpdateCard(Tc tc, String tag, String time, String title,
      String desc, Color accent) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      onTap: () => _navigateTo(context, const CircularsScreen()),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StatusBadge(label: tag, color: accent),
              const Spacer(),
              Text(time, style: TextStyle(color: tc.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 12),
          Text(title,
              style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2)),
          const SizedBox(height: 4),
          Text(desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: tc.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  // ── SEARCH BOTTOM SHEET ──
  void _showSearchSheet(BuildContext context, Tc tc) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: tc.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SearchSheet(),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PRIVATE HELPER WIDGETS
// ═══════════════════════════════════════════════════════════════════════

class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickItem(this.icon, this.label, this.color, this.onTap);
}

/// Compact tappable action card for Academics / Campus sections.
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.96),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: TextStyle(
                            color: tc.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style:
                            TextStyle(color: tc.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded,
                  color: tc.textMuted, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bottom sheet for searching across features.
class _SearchSheet extends StatefulWidget {
  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _controller = TextEditingController();
  String _query = '';

  final _allItems = <_SearchItem>[
    _SearchItem('Forum', Icons.forum_rounded, 'Discussions & posts'),
    _SearchItem('Services', Icons.miscellaneous_services_rounded, 'Campus services'),
    _SearchItem('Events', Icons.event_rounded, 'Upcoming events'),
    _SearchItem('Circulars', Icons.description_rounded, 'Announcements'),
    _SearchItem('Timetable', Icons.schedule_rounded, 'Class schedule'),
    _SearchItem('Results', Icons.assessment_rounded, 'Exam grades'),
    _SearchItem('Map', Icons.map_rounded, 'Campus navigation'),
    _SearchItem('Lost & Found', Icons.search_rounded, 'Report or find items'),
    _SearchItem('Alerts', Icons.notifications_rounded, 'Notifications'),
  ];

  List<_SearchItem> get _filtered {
    if (_query.isEmpty) return _allItems;
    return _allItems
        .where((i) =>
            i.title.toLowerCase().contains(_query.toLowerCase()) ||
            i.subtitle.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  Future<void> _launchResultsUrl() async {
    final uri = Uri.parse('https://pondiuni.samarth.edu.in/index.php/site/login');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _navigate(String title) {
    Navigator.pop(context);
    Widget? screen;
    switch (title) {
      case 'Forum':
        screen = const ForumScreen();
      case 'Services':
        screen = const ServicesScreen();
      case 'Events':
        screen = const EventsScreen();
      case 'Circulars':
        screen = const CircularsScreen();
      case 'Timetable':
        screen = const TimetableScreen();
      case 'Results':
        _launchResultsUrl();
        return;
      case 'Map':
        screen = const MapScreen();
      case 'Lost & Found':
        screen = const AlertsScreen(initialTab: 2);
      case 'Alerts':
        screen = const AlertsScreen();
    }
    if (screen != null) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => screen!),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: tc.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          // Search Input
          SearchBarGlass(
            controller: _controller,
            hint: 'Search features...',
            onChanged: (q) => setState(() => _query = q),
          ),
          const SizedBox(height: 16),
          // Results
          ..._filtered.map((item) => GestureDetector(
                onTap: () => _navigate(item.title),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: tc.bgSurface,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item.icon,
                            color: tc.textSecondary, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: TextStyle(
                                    color: tc.textPrimary,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 15)),
                            Text(item.subtitle,
                                style: TextStyle(
                                    color: tc.textMuted, fontSize: 12)),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded,
                          color: tc.textMuted, size: 14),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _SearchItem {
  final String title;
  final IconData icon;
  final String subtitle;
  const _SearchItem(this.title, this.icon, this.subtitle);
}
