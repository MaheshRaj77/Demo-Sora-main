/// ─── User Model (DTO) ───────────────────────────────────────
/// Maps to the backend User MongoDB document.
class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'guest', 'student', 'faculty', 'admin'
  final String? department;
  final int? year;
  final int? semester;
  final String? rollNumber;
  final String? bio;
  final String? avatarUrl;
  final bool isActive;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    this.department,
    this.year,
    this.semester,
    this.rollNumber,
    this.bio,
    this.avatarUrl,
    this.isActive = true,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['_id'] ?? json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      role: json['role'] ?? 'student',
      department: json['department'],
      year: json['year'],
      semester: json['semester'],
      rollNumber: json['rollNumber'],
      bio: json['bio'],
      avatarUrl: json['avatarUrl'],
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'email': email,
        'fullName': fullName,
        'department': department,
        'year': year,
        'semester': semester,
        'rollNumber': rollNumber,
        'bio': bio,
      };

  /// Human-friendly relative time
  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inDays > 365) return '${diff.inDays ~/ 365}y ago';
    if (diff.inDays > 30) return '${diff.inDays ~/ 30}mo ago';
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'just now';
  }

  /// Guest user placeholder
  static final UserModel guest = UserModel(
    id: 'guest',
    email: '',
    fullName: 'Guest User',
    role: 'guest',
    createdAt: DateTime(2000),
  );
}
