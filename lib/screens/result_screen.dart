import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/glass_widgets.dart';
import '../services/api_service.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key});

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  int _selectedSem = 4;
  List<_SubjectGrade> _grades = [];
  String _sgpa = '—';
  String _cgpa = '—';
  int _totalCredits = 0;
  bool _isLoading = true;

  // Store fetched data per semester for caching
  final Map<int, _SemesterData> _semCache = {};

  @override
  void initState() {
    super.initState();
    _fetchResults();
  }

  Future<void> _fetchResults() async {
    setState(() => _isLoading = true);

    // Check local cache first
    if (_semCache.containsKey(_selectedSem)) {
      final cached = _semCache[_selectedSem]!;
      setState(() {
        _grades = cached.grades;
        _sgpa = cached.sgpa;
        _cgpa = cached.cgpa;
        _totalCredits = cached.totalCredits;
        _isLoading = false;
      });
      return;
    }

    try {
      final response =
          await ApiService().get('/results?semester=$_selectedSem');
      final resultsList = response['results'] as List;

      if (resultsList.isEmpty) {
        setState(() {
          _grades = [];
          _sgpa = '—';
          _cgpa = '—';
          _totalCredits = 0;
          _isLoading = false;
        });
        return;
      }

      // The backend returns [{semester, gpa, subjects: [...]}]
      // Find the matching semester or use first entry
      final semData = resultsList.firstWhere(
          (r) => r['semester'] == _selectedSem,
          orElse: () => resultsList.first);

      final subjects = (semData['subjects'] as List?) ?? [];
      final grades = subjects.map((s) {
        final gradeStr = s['grade'] as String;
        final gradePoints = double.tryParse(s['grade_points'].toString()) ?? 0;
        return _SubjectGrade(
          s['subject'] as String,
          gradeStr,
          gradePoints.round(),
          _gradeColor(gradeStr),
        );
      }).toList();

      int credits = 0;
      for (final s in subjects) {
        credits += (s['credits'] as int?) ?? 4;
      }

      final sgpa = semData['gpa']?.toString() ?? '—';

      // Calculate approximate CGPA from all semesters
      double totalWeightedGpa = 0;
      int totalSemesters = 0;
      for (final r in resultsList) {
        final gpa = double.tryParse(r['gpa']?.toString() ?? '');
        if (gpa != null) {
          totalWeightedGpa += gpa;
          totalSemesters++;
        }
      }
      final cgpa = totalSemesters > 0
          ? (totalWeightedGpa / totalSemesters).toStringAsFixed(2)
          : '—';

      final data = _SemesterData(
        grades: grades,
        sgpa: sgpa,
        cgpa: cgpa,
        totalCredits: credits,
      );
      _semCache[_selectedSem] = data;

      setState(() {
        _grades = grades;
        _sgpa = sgpa;
        _cgpa = cgpa;
        _totalCredits = credits;
        _isLoading = false;
      });
    } catch (e) {
      // Fall back to static data
      final staticData = _staticResults();
      final grades = staticData[_selectedSem] ?? [];
      int credits = grades.length * 4;
      double sum = 0;
      for (final g in grades) {
        sum += g.point;
      }
      final sgpa =
          grades.isNotEmpty ? (sum / grades.length).toStringAsFixed(1) : '—';

      setState(() {
        _grades = grades;
        _sgpa = sgpa;
        _cgpa = '8.8';
        _totalCredits = credits;
        _isLoading = false;
      });
    }
  }

  Color _gradeColor(String grade) {
    switch (grade) {
      case 'A+':
      case 'O':
        return AppColors.accentGreen;
      case 'A':
        return AppColors.accentTeal;
      case 'B+':
        return AppColors.accentOrange;
      case 'B':
        return AppColors.accentPurple;
      case 'C':
        return AppColors.accentPink;
      default:
        return AppColors.accentRed;
    }
  }

  Map<int, List<_SubjectGrade>> _staticResults() {
    return {
      4: [
        _SubjectGrade('Data Structures', 'A+', 10, AppColors.accentGreen),
        _SubjectGrade('Operating Systems', 'A', 9, AppColors.accentTeal),
        _SubjectGrade('DBMS', 'A+', 10, AppColors.accentGreen),
        _SubjectGrade('Computer Networks', 'B+', 8, AppColors.accentOrange),
        _SubjectGrade('Mathematics III', 'A', 9, AppColors.accentTeal),
      ],
      3: [
        _SubjectGrade('OOP with Java', 'A', 9, AppColors.accentTeal),
        _SubjectGrade('Digital Electronics', 'B+', 8, AppColors.accentOrange),
        _SubjectGrade('Discrete Maths', 'A+', 10, AppColors.accentGreen),
        _SubjectGrade('Data Communication', 'B', 7, AppColors.accentPurple),
      ],
    };
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
              const GlassAppBar(title: 'Results'),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () {
                    _semCache.remove(_selectedSem);
                    return _fetchResults();
                  },
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                    children: [
                      _buildSemSelector(tc),
                      const SizedBox(height: 18),
                      _buildGpaSummary(tc),
                      const SizedBox(height: 18),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_grades.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 40),
                          child: Center(
                            child: Text('No results for Semester $_selectedSem',
                                style: TextStyle(
                                    color: tc.textMuted, fontSize: 14)),
                          ),
                        )
                      else
                        ..._grades.map((g) => _gradeCard(tc, g)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSemSelector(Tc tc) {
    return SizedBox(
      height: 44,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 8,
        itemBuilder: (_, i) {
          final sem = i + 1;
          final isSelected = _selectedSem == sem;
          return GestureDetector(
            onTap: () {
              if (_selectedSem != sem) {
                setState(() => _selectedSem = sem);
                _fetchResults();
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 78,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.primaryGradient : null,
                color: isSelected ? null : tc.glassWhite,
                borderRadius: BorderRadius.circular(12),
                border: isSelected ? null : Border.all(color: tc.glassBorder),
              ),
              alignment: Alignment.center,
              child: Text('Sem $sem',
                  style: TextStyle(
                      color: isSelected ? Colors.white : tc.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGpaSummary(Tc tc) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Column(children: [
            const Text('SGPA',
                style: TextStyle(
                    color: AppColors.accentTeal,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(_sgpa,
                style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
          ]),
          Container(width: 1, height: 50, color: tc.glassBorder),
          Column(children: [
            const Text('CGPA',
                style: TextStyle(
                    color: AppColors.accentPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(_cgpa,
                style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
          ]),
          Container(width: 1, height: 50, color: tc.glassBorder),
          Column(children: [
            Text('Credits',
                style: TextStyle(
                    color: tc.textMuted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text('$_totalCredits',
                style: TextStyle(
                    color: tc.textPrimary,
                    fontSize: 28,
                    fontWeight: FontWeight.w800)),
          ]),
        ],
      ),
    );
  }

  Widget _gradeCard(Tc tc, _SubjectGrade g) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                  color: g.color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Center(
                  child: Text(g.grade,
                      style: TextStyle(
                          color: g.color,
                          fontWeight: FontWeight.w800,
                          fontSize: 16))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(g.name,
                      style: TextStyle(
                          color: tc.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text('Grade Point: ${g.point}',
                      style: TextStyle(color: tc.textMuted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubjectGrade {
  final String name, grade;
  final int point;
  final Color color;
  const _SubjectGrade(this.name, this.grade, this.point, this.color);
}

class _SemesterData {
  final List<_SubjectGrade> grades;
  final String sgpa;
  final String cgpa;
  final int totalCredits;
  const _SemesterData({
    required this.grades,
    required this.sgpa,
    required this.cgpa,
    required this.totalCredits,
  });
}
