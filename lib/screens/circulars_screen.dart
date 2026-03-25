import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/api_service.dart';
import '../models/circular.dart';

class CircularsScreen extends StatefulWidget {
  const CircularsScreen({super.key});

  @override
  State<CircularsScreen> createState() => _CircularsScreenState();
}

class _CircularsScreenState extends State<CircularsScreen> {
  List<Circular> _circulars = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchCirculars();
  }

  Future<void> _fetchCirculars() async {
    setState(() => _isLoading = true);
    try {
      final response = await ApiService().get('/circulars');
      final circularsJson = response['circulars'] as List;
      setState(() {
        _circulars = circularsJson.map((j) => Circular.fromJson(j)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _circulars = _staticCirculars();
        _isLoading = false;
      });
    }
  }

  List<Circular> _staticCirculars() {
    return [
      Circular(
          id: '1',
          title: 'Exam Schedule Notice',
          description:
              'End semester examinations will commence from March 1st.',
          publishedDate: DateTime(2024, 2, 18),
          isImportant: true),
      Circular(
          id: '2',
          title: 'Library Rules Update',
          description: 'New library timings: 8 AM to 10 PM on weekdays.',
          publishedDate: DateTime(2024, 2, 15),
          isImportant: true),
      Circular(
          id: '3',
          title: 'Hostel Maintenance',
          description: 'Annual maintenance work in hostels from Feb 15-20.',
          publishedDate: DateTime(2024, 2, 12)),
      Circular(
          id: '4',
          title: 'Fee Payment Reminder',
          description: 'Last date for semester fee payment is February 28.',
          publishedDate: DateTime(2024, 2, 10)),
      Circular(
          id: '5',
          title: 'Workshop Registration',
          description: 'AI/ML Workshop by Google DevRel team on Feb 25.',
          publishedDate: DateTime(2024, 2, 8)),
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
              const GlassAppBar(title: 'Circulars'),
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                            color: AppColors.accentTeal))
                    : RefreshIndicator(
                        onRefresh: _fetchCirculars,
                        color: AppColors.accentTeal,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                          itemCount: _circulars.length,
                          itemBuilder: (_, i) =>
                              _circularCard(tc, _circulars[i], i),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circularCard(Tc tc, Circular circular, int index) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(circular.title,
                      style: TextStyle(
                          color: tc.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 15)),
                ),
                if (circular.isImportant)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.accentTeal,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(circular.description ?? '',
                style: TextStyle(
                    color: tc.textSecondary, fontSize: 13, height: 1.4)),
            const SizedBox(height: 10),
            Text(circular.formattedDate,
                style: TextStyle(color: tc.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
