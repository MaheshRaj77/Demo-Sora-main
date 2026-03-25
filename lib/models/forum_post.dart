class ForumPost {
  final String id;
  final String? userId;
  final String title;
  final String body;
  final int likesCount;
  final int repliesCount;
  final String? authorName;
  final String? authorAvatar;
  final DateTime createdAt;

  ForumPost({
    required this.id,
    this.userId,
    required this.title,
    required this.body,
    this.likesCount = 0,
    this.repliesCount = 0,
    this.authorName,
    this.authorAvatar,
    required this.createdAt,
  });

  factory ForumPost.fromJson(Map<String, dynamic> json) {
    return ForumPost(
      id: json['id'],
      userId: json['user_id'],
      title: json['title'],
      body: json['body'],
      likesCount: json['likes_count'] ?? 0,
      repliesCount: json['replies_count'] ?? 0,
      authorName: json['author_name'],
      authorAvatar: json['author_avatar'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  /// Returns a human-readable relative time string.
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }
}

class ForumReply {
  final String id;
  final String postId;
  final String? userId;
  final String body;
  final String? authorName;
  final String? authorAvatar;
  final DateTime createdAt;

  ForumReply({
    required this.id,
    required this.postId,
    this.userId,
    required this.body,
    this.authorName,
    this.authorAvatar,
    required this.createdAt,
  });

  factory ForumReply.fromJson(Map<String, dynamic> json) {
    return ForumReply(
      id: json['id'],
      postId: json['post_id'],
      userId: json['user_id'],
      body: json['body'],
      authorName: json['author_name'],
      authorAvatar: json['author_avatar'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
