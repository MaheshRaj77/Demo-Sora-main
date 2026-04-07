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
        _circulars = [];
        _isLoading = false;
      });
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
          child: Column(
            children: [
              GlassAppBar(title: 'Circulars'),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                            color: tc.accent))
                    : RefreshIndicator(
                        onRefresh: _fetchCirculars,
                        color: tc.accent,
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
                    decoration: BoxDecoration(
                      color: tc.accent,
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
