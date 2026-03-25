import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'forum_screen.dart';
import 'services_screen.dart';
import 'events_screen.dart';
import 'circulars_screen.dart';
import 'timetable_screen.dart';
import 'result_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _fetchUpdates();
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
    try {
      final response = await ApiService().get('/circulars');
      final circulars = response['circulars'] as List;
      if (mounted && circulars.isNotEmpty) {
        setState(() {
          _updates = circulars.take(3).map((c) {
            return {
              'tag': c['is_important'] == true ? 'Important' : 'Academic',
              'time': _timeAgo(DateTime.parse(c['created_at'])),
              'title': c['title'] as String,
              'desc': (c['description'] ?? '') as String,
              'color': c['is_important'] == true
                  ? AppColors.accentTeal
                  : AppColors.accentPurple,
            };
          }).toList();
        });
      }
    } catch (e) {
      setState(() {
        _updates = [
          {
            'tag': 'Academic',
            'time': '2h ago',
            'title': 'Fall 2024 Registration Open',
            'desc':
                'Course registration is now open for all senior students. Check your allotted time slot.',
            'color': AppColors.accentTeal
          },
          {
            'tag': 'Event',
            'time': '5h ago',
            'title': 'Tech Fest 2024 Registrations',
            'desc':
                'Annual tech fest is around the corner. Register your team for hackathon and coding contests.',
            'color': AppColors.accentPurple
          },
        ];
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
        transitionDuration: const Duration(milliseconds: 250),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildGreeting(context, tc),
          const SizedBox(height: 30),
          const SectionHeader(title: 'Quick Access'),
          const SizedBox(height: 16),
          _buildQuickAccess(context),
          const SizedBox(height: 30),
          const SectionHeader(title: 'Academics'),
          const SizedBox(height: 16),
          _buildAcademics(context, tc),
          const SizedBox(height: 30),
          const SectionHeader(title: 'Latest Updates', actionText: 'See All'),
          const SizedBox(height: 16),
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
          if (_updates.isEmpty) ...[
            _buildUpdateCard(tc, 'Academic', '2h ago',
                'Fall 2024 Registration Open',
                'Course registration is now open for all senior students.',
                AppColors.accentTeal),
            const SizedBox(height: 12),
            _buildUpdateCard(tc, 'Event', '5h ago',
                'Tech Fest 2024 Registrations',
                'Annual tech fest is around the corner. Register your team.',
                AppColors.accentPurple),
          ],
        ],
      ),
    );
  }

  Widget _buildGreeting(BuildContext context, Tc tc) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accentTeal.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.person_rounded,
                size: 28, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$greeting, $_userName',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 18,
                        letterSpacing: -0.2,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                   _semester > 0
                       ? '$_department  •  Semester $_semester'
                       : _department,
                   style: TextStyle(color: tc.textMuted, fontSize: 13),
                 ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: tc.glassFill,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tc.glassBorder, width: 0.5),
            ),
            child: Icon(Icons.notifications_none_rounded,
                color: tc.textSecondary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccess(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          GlassIconTile(
            icon: Icons.forum_rounded,
            label: 'Forum',
            gradient: const LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF818CF8)]),
            onTap: () => _navigateTo(context, const ForumScreen()),
          ),
          GlassIconTile(
            icon: Icons.miscellaneous_services_rounded,
            label: 'Services',
            gradient: const LinearGradient(
                colors: [Color(0xFFEC4899), Color(0xFFF472B6)]),
            onTap: () => _navigateTo(context, const ServicesScreen()),
          ),
          GlassIconTile(
            icon: Icons.event_rounded,
            label: 'Events',
            gradient: const LinearGradient(
                colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)]),
            onTap: () => _navigateTo(context, const EventsScreen()),
          ),
          GlassIconTile(
            icon: Icons.description_rounded,
            label: 'Circulars',
            gradient: const LinearGradient(
                colors: [Color(0xFF14B8A6), Color(0xFF2DD4BF)]),
            onTap: () => _navigateTo(context, const CircularsScreen()),
          ),
        ],
      ),
    );
  }

  Widget _buildAcademics(BuildContext context, Tc tc) {
    return Row(
      children: [
        Expanded(
          child: _AcademicTile(
            icon: Icons.schedule_rounded,
            title: 'Timetable',
            subtitle: 'View schedule',
            gradient: AppColors.primaryGradient,
            onTap: () => _navigateTo(context, const TimetableScreen()),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _AcademicTile(
            icon: Icons.assessment_rounded,
            title: 'Results',
            subtitle: 'View grades',
            gradient: AppColors.purpleGradient,
            onTap: () => _navigateTo(context, const ResultScreen()),
          ),
        ),
      ],
    );
  }

  Widget _buildUpdateCard(Tc tc, String tag, String time, String title,
      String desc, Color accent) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(tag,
                    style: TextStyle(
                        color: accent,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ),
              const Spacer(),
              Text(time, style: TextStyle(color: tc.textMuted, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 14),
          Text(title,
              style: TextStyle(
                  color: tc.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2)),
          const SizedBox(height: 6),
          Text(desc,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  color: tc.textSecondary, fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }
}

class _AcademicTile extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final LinearGradient gradient;
  final VoidCallback onTap;

  const _AcademicTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  State<_AcademicTile> createState() => _AcademicTileState();
}

class _AcademicTileState extends State<_AcademicTile> {
  double _scale = 1.0;

  @override
  Widget build(BuildContext context) {
    final tc = Tc.of(context);
    return GestureDetector(
      onTapDown: (_) => setState(() => _scale = 0.95),
      onTapUp: (_) {
        setState(() => _scale = 1.0);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _scale = 1.0),
      child: AnimatedScale(
        scale: _scale,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: GlassCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: widget.gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: widget.gradient.colors.first
                          .withValues(alpha: 0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(widget.icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 14),
              Text(widget.title,
                  style: TextStyle(
                      color: tc.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 15)),
              const SizedBox(height: 4),
              Text(widget.subtitle,
                  style: TextStyle(color: tc.textMuted, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}
