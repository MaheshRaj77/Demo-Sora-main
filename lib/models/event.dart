class Event {
  final String id;
  final String title;
  final String? description;
  final DateTime eventDate;
  final String? venue;
  final String? category;
  final String? imageUrl;

  Event({
    required this.id,
    required this.title,
    this.description,
    required this.eventDate,
    this.venue,
    this.category,
    this.imageUrl,
  });

  factory Event.fromJson(Map<String, dynamic> json) {
    return Event(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      eventDate: DateTime.parse(json['event_date']),
      venue: json['venue'],
      category: json['category'],
      imageUrl: json['image_url'],
    );
  }

  String get formattedDate {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[eventDate.month - 1]} ${eventDate.day.toString().padLeft(2, '0')}';
  }
}
