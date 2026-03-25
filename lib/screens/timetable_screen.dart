import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/api_service.dart';
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

  @override
  void initState() {
    super.initState();
    // Default to current day of week
    final now = DateTime.now();
    _selectedDay = (now.weekday - 1).clamp(0, 5);
    _fetchTimetable();
  }

  Future<void> _fetchTimetable() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await ApiService().get('/timetable?day=${_daysFull[_selectedDay]}');
      final ttJson = response['timetable'] as List;
      setState(() {
        _entries = ttJson.map((j) => TimetableEntry.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _entries = _staticTimetable();
        _isLoading = false;
      });
    }
  }

  List<TimetableEntry> _staticTimetable() {
    // Monday fallback
    return [
      TimetableEntry(
          id: '1',
          dayOfWeek: 'Monday',
          subject: 'Data Structures',
          timeSlot: '09:00 – 10:00',
          faculty: 'Dr. Kumar',
          room: 'Room 301',
          accentColor: '#00D2FF'),
      TimetableEntry(
          id: '2',
          dayOfWeek: 'Monday',
          subject: 'Operating Systems',
          timeSlot: '10:15 – 11:15',
          faculty: 'Dr. Patel',
          room: 'Room 204',
          accentColor: '#7C3AED'),
      TimetableEntry(
          id: '3',
          dayOfWeek: 'Monday',
          subject: 'DBMS Lab',
          timeSlot: '11:30 – 13:00',
          faculty: 'Prof. Singh',
          room: 'Lab B2',
          accentColor: '#EC4899'),
      TimetableEntry(
          id: '4',
          dayOfWeek: 'Monday',
          subject: 'Computer Networks',
          timeSlot: '14:00 – 15:00',
          faculty: 'Dr. Sharma',
          room: 'Room 102',
          accentColor: '#22C55E'),
    ];
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
              _buildDaySelector(tc),
              const SizedBox(height: 16),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentTeal))
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
                  gradient: isSelected ? AppColors.primaryGradient : null,
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
