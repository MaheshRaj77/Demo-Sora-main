import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/api_service.dart';
import '../models/event.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen> {
  List<Event> _events = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('/events');
      final eventsJson = response['events'] as List;
      setState(() {
        _events = eventsJson.map((j) => Event.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _events = _staticEvents();
        _isLoading = false;
      });
    }
  }

  List<Event> _staticEvents() {
    return [
      Event(
          id: '1',
          title: 'Tech Fest 2024',
          description: 'Annual tech fest with hackathon and coding contests.',
          eventDate: DateTime(2024, 3, 15),
          venue: 'Main Auditorium',
          category: 'tech'),
      Event(
          id: '2',
          title: 'Cultural Night',
          description: 'An evening of music, dance, and drama performances.',
          eventDate: DateTime(2024, 3, 20),
          venue: 'Open Air Theatre',
          category: 'cultural'),
      Event(
          id: '3',
          title: 'Sports Day',
          description:
              'Annual sports competition. Cricket, football, athletics.',
          eventDate: DateTime(2024, 3, 25),
          venue: 'Sports Complex',
          category: 'sports'),
      Event(
          id: '4',
          title: 'Alumni Meet',
          description: 'Connect with alumni from all departments.',
          eventDate: DateTime(2024, 4, 5),
          venue: 'Convention Hall',
          category: 'networking'),
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
              const GlassAppBar(title: 'Events'),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentTeal))
                    : RefreshIndicator(
                        onRefresh: _fetchEvents,
                        color: AppColors.accentTeal,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          itemCount: _events.length,
                          itemBuilder: (_, i) => _eventCard(tc, _events[i]),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _eventCard(Tc tc, Event event) {
    final colors = [
      AppColors.accentTeal,
      AppColors.accentPurple,
      AppColors.accentGreen,
      AppColors.accentOrange,
    ];
    final color = colors[_events.indexOf(event) % colors.length];

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 65,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    event.formattedDate.split(' ').last,
                    style: TextStyle(
                        color: color,
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                  Text(
                    event.formattedDate.split(' ').first,
                    style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(event.title,
                      style: TextStyle(
                          color: tc.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16)),
                  const SizedBox(height: 4),
                  Text(event.description ?? '',
                      style: TextStyle(
                          color: tc.textSecondary, fontSize: 12, height: 1.4),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 14, color: tc.textMuted),
                      const SizedBox(width: 4),
                      Text(event.venue ?? '',
                          style: TextStyle(color: tc.textMuted, fontSize: 11)),
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
