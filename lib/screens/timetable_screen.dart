import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../models/timetable_entry.dart';

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final List<String> _days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
  final List<String> _daysFull = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday'
  ];
  int _selectedDay = 0;
  List<TimetableEntry> _entries = [];
  bool _isLoading = true;

  // Department support
  static const List<String> _departments = [
    'Computer Science',
    'Electronics',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biotechnology',
    'Commerce',
    'Management',
    'English',
    'History',
    'Political Science',
    'Sociology',
    'Economics',
    'Tamil',
    'Hindi',
    'Earth Sciences',
    'Biochemistry',
    'Statistics',
    'International Business',
    'Bioinformatics',
  ];
  String _selectedDepartment = 'Computer Science';

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedDay = (now.weekday - 1).clamp(0, 5);
    _loadUserDepartment();
  }

  Future<void> _loadUserDepartment() async {
    try {
      final cachedUser = await AuthService().getCachedUser();
      if (cachedUser != null && cachedUser['department'] != null) {
        final dept = cachedUser['department'] as String;
        if (_departments.contains(dept)) {
          setState(() => _selectedDepartment = dept);
        }
      }
    } catch (_) {}
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    setState(() => _isLoading = true);
    try {
      final dept = Uri.encodeComponent(_selectedDepartment);
      final response =
          await ApiService().get('/timetable?day=${_daysFull[_selectedDay]}&department=$dept');
      final ttJson = response['timetable'] as List;
      setState(() {
        _entries = ttJson.map((j) => TimetableEntry.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _entries = [];
        _isLoading = false;
      });
    }
  }

  Color _parseHex(String hex) {
    hex = hex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
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
              const GlassAppBar(title: 'Timetable'),
              const SizedBox(height: 8),
              _buildDeptSelector(tc),
              const SizedBox(height: 12),
              _buildDaySelector(tc),
              SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: tc.accent))
                    : _entries.isEmpty
                        ? Center(
                            child: Text('No classes today',
                                style: TextStyle(
                                    color: tc.textMuted, fontSize: 16)))
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                            itemCount: _entries.length,
                            itemBuilder: (_, i) => _classCard(tc, _entries[i]),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeptSelector(Tc tc) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: _selectedDepartment,
            isExpanded: true,
            icon: Icon(Icons.keyboard_arrow_down_rounded, color: tc.accent),
            dropdownColor: tc.bgCard,
            style: TextStyle(
              color: tc.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            items: _departments.map((dept) {
              return DropdownMenuItem(
                value: dept,
                child: Text(dept),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null && val != _selectedDepartment) {
                setState(() => _selectedDepartment = val);
                _fetchTimetable();
              }
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDaySelector(Tc tc) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _days.length,
        itemBuilder: (_, i) {
          final isSelected = i == _selectedDay;
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () {
                setState(() => _selectedDay = i);
                _fetchTimetable();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  gradient: isSelected ? tc.primaryGradient : null,
                  color: isSelected ? null : tc.glassWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: isSelected ? null : Border.all(color: tc.glassBorder),
                ),
                child: Text(
                  _days[i],
                  style: TextStyle(
                    color: isSelected ? Colors.white : tc.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _classCard(Tc tc, TimetableEntry entry) {
    final accent = _parseHex(entry.accentColor);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: accent,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.subject,
                      style: TextStyle(
                          color: tc.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 14, color: tc.textMuted),
                      const SizedBox(width: 4),
                      Text(entry.timeSlot,
                          style: TextStyle(color: tc.textMuted, fontSize: 12)),
                      const SizedBox(width: 16),
                      Icon(Icons.person_rounded, size: 14, color: tc.textMuted),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(entry.faculty ?? '',
                            style: TextStyle(color: tc.textMuted, fontSize: 12),
                            overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.room_rounded, size: 14, color: tc.textMuted),
                      const SizedBox(width: 4),
                      Text(entry.room ?? '',
                          style: TextStyle(color: tc.textMuted, fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
