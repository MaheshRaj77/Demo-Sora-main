class LostFoundItem {
  final String id;
  final String? userId;
  final String itemType;
  final String category;
  final String itemName;
  final String? description;
  final String? location;
  final DateTime? foundLostDate;
  final String? imageUrl;
  final String? contactInfo;
  final String status;
  final String? reporterName;
  final DateTime createdAt;

  LostFoundItem({
    required this.id,
    this.userId,
    required this.itemType,
    required this.category,
    required this.itemName,
    this.description,
    this.location,
    this.foundLostDate,
    this.imageUrl,
    this.contactInfo,
    this.status = 'open',
    this.reporterName,
    required this.createdAt,
  });

  factory LostFoundItem.fromJson(Map<String, dynamic> json) {
    return LostFoundItem(
      id: json['id'],
      userId: json['user_id'],
      itemType: json['item_type'],
      category: json['category'],
      itemName: json['item_name'],
      description: json['description'],
      location: json['location'],
      foundLostDate: json['found_lost_date'] != null
          ? DateTime.parse(json['found_lost_date'])
          : null,
      imageUrl: json['image_url'],
      contactInfo: json['contact_info'],
      status: json['status'] ?? 'open',
      reporterName: json['reporter_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
