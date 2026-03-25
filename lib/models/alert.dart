class Alert {
  final String id;
  final String title;
  final String? description;
  final String category;
  final String priority;
  final DateTime createdAt;

  Alert({
    required this.id,
    required this.title,
    this.description,
    required this.category,
    this.priority = 'normal',
    required this.createdAt,
  });

  factory Alert.fromJson(Map<String, dynamic> json) {
    return Alert(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      category: json['category'],
      priority: json['priority'] ?? 'normal',
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
