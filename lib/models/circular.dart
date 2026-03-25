class Circular {
  final String id;
  final String title;
  final String? description;
  final DateTime publishedDate;
  final bool isImportant;
  final String? attachmentUrl;

  Circular({
    required this.id,
    required this.title,
    this.description,
    required this.publishedDate,
    this.isImportant = false,
    this.attachmentUrl,
  });

  factory Circular.fromJson(Map<String, dynamic> json) {
    return Circular(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      publishedDate: DateTime.parse(
          json['published_date'] ?? json['created_at'] ?? DateTime.now().toIso8601String()),
      isImportant: json['is_important'] ?? false,
      attachmentUrl: json['attachment_url'],
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
    return '${months[publishedDate.month - 1]} ${publishedDate.day}';
  }
}
