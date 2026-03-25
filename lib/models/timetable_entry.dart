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
    return TimetableEntry(
      id: json['id'],
      dayOfWeek: json['day_of_week'],
      subject: json['subject'],
      timeSlot: json['time_slot'],
      faculty: json['faculty'],
      room: json['room'],
      accentColor: json['accent_color'] ?? '#00D2FF',
    );
  }
}
