class TimetableEntry {
  final String id;
  final String dayOfWeek;
  final String subject;
  final String timeSlot;
  final String? faculty;
  final String? room;
  final String accentColor;

  TimetableEntry({
    required this.id,
    required this.dayOfWeek,
    required this.subject,
    required this.timeSlot,
    this.faculty,
    this.room,
    this.accentColor = '#00D2FF',
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) {
    // Build timeSlot from separate start_time / end_time fields
    final start = json['start_time'] as String? ?? '';
    final end = json['end_time'] as String? ?? '';
    final timeSlot = (start.isNotEmpty && end.isNotEmpty)
        ? '$start – $end'
        : (json['time_slot'] as String? ?? '');

    return TimetableEntry(
      id: json['id'],
      dayOfWeek: json['day_of_week'],
      subject: json['subject_name'] ?? json['subject'] ?? '',
      timeSlot: timeSlot,
      faculty: json['instructor'] ?? json['faculty'],
      room: json['room'],
      accentColor: json['accent_color'] ?? '#00D2FF',
    );
  }
}
