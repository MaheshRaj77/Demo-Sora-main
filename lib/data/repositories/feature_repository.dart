/// ─── Feature Repository ─────────────────────────────────────
/// Data layer for all feature endpoints (alerts, events, forum, etc.)
/// Uses Dio API client with cursor-based pagination support.
import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';

class FeatureRepository {
  final Dio _dio = ApiClient.instance.dio;

  // ── Alerts ──────────────────────────────────────────────────
  Future<PaginatedResult<Map<String, dynamic>>> getAlerts({
    String? severity,
    String? targetAudience,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get(ApiConstants.alerts, queryParameters: {
      if (severity != null) 'severity': severity,
      if (targetAudience != null) 'targetAudience': targetAudience,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
    return _parsePaginated(response, 'alerts');
  }

  Future<Map<String, dynamic>> getAlert(String id) async {
    final response = await _dio.get('${ApiConstants.alerts}/$id');
    return (response.data['data']['alert'] as Map<String, dynamic>);
  }

  // ── Events ──────────────────────────────────────────────────
  Future<PaginatedResult<Map<String, dynamic>>> getEvents({
    String? category,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get(ApiConstants.events, queryParameters: {
      if (category != null) 'category': category,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
    return _parsePaginated(response, 'events');
  }

  // ── Circulars ───────────────────────────────────────────────
  Future<PaginatedResult<Map<String, dynamic>>> getCirculars({
    String? category,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get(ApiConstants.circulars, queryParameters: {
      if (category != null) 'category': category,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
    return _parsePaginated(response, 'circulars');
  }

  // ── Forum ───────────────────────────────────────────────────
  Future<PaginatedResult<Map<String, dynamic>>> getForumPosts({
    String? tag,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get(ApiConstants.forum, queryParameters: {
      if (tag != null) 'tag': tag,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
    return _parsePaginated(response, 'posts');
  }

  Future<Map<String, dynamic>> createForumPost({
    required String content,
    List<String>? tags,
    String? imageUrl,
  }) async {
    final response = await _dio.post(ApiConstants.forum, data: {
      'content': content,
      if (tags != null) 'tags': tags,
      if (imageUrl != null) 'imageUrl': imageUrl,
    });
    return response.data['data']['post'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> toggleUpvote(String postId) async {
    final response = await _dio.post('${ApiConstants.forum}/$postId/upvote');
    return response.data['data'] as Map<String, dynamic>;
  }

  Future<PaginatedResult<Map<String, dynamic>>> getComments(
    String postId, {
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get(
      '${ApiConstants.forum}/$postId/comments',
      queryParameters: {
        'limit': limit,
        if (cursor != null) 'cursor': cursor,
      },
    );
    return _parsePaginated(response, 'comments');
  }

  Future<Map<String, dynamic>> createComment(String postId, String content) async {
    final response = await _dio.post(
      '${ApiConstants.forum}/$postId/comments',
      data: {'content': content},
    );
    return response.data['data']['comment'] as Map<String, dynamic>;
  }

  // ── Lost & Found ────────────────────────────────────────────
  Future<PaginatedResult<Map<String, dynamic>>> getLostFoundItems({
    String? itemType,
    String? status,
    int limit = 20,
    String? cursor,
  }) async {
    final response = await _dio.get(ApiConstants.lostFound, queryParameters: {
      if (itemType != null) 'itemType': itemType,
      if (status != null) 'status': status,
      'limit': limit,
      if (cursor != null) 'cursor': cursor,
    });
    return _parsePaginated(response, 'items');
  }

  /// Create a lost/found item with optional image upload
  Future<Map<String, dynamic>> createLostFoundItem({
    required String itemType,
    required String title,
    required String description,
    String? category,
    String? location,
    String? contactInfo,
    String? imagePath,
  }) async {
    if (imagePath != null) {
      // Multipart upload
      final formData = FormData.fromMap({
        'itemType': itemType,
        'title': title,
        'description': description,
        if (category != null) 'category': category,
        if (location != null) 'location': location,
        if (contactInfo != null) 'contactInfo': contactInfo,
        'image': await MultipartFile.fromFile(imagePath, filename: 'image.jpg'),
      });
      final response = await _dio.post(ApiConstants.lostFound, data: formData);
      return response.data['data']['item'] as Map<String, dynamic>;
    }

    final response = await _dio.post(ApiConstants.lostFound, data: {
      'itemType': itemType,
      'title': title,
      'description': description,
      if (category != null) 'category': category,
      if (location != null) 'location': location,
      if (contactInfo != null) 'contactInfo': contactInfo,
    });
    return response.data['data']['item'] as Map<String, dynamic>;
  }

  // ── Timetable ───────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTimetable({String? day}) async {
    final response = await _dio.get(ApiConstants.timetable, queryParameters: {
      if (day != null) 'day': day,
    });
    final data = response.data['data'];
    return List<Map<String, dynamic>>.from(data['timetable'] ?? []);
  }

  Future<Map<String, dynamic>> addTimetableEntry(Map<String, dynamic> entry) async {
    final response = await _dio.post(ApiConstants.timetable, data: entry);
    return response.data['data']['entry'] as Map<String, dynamic>;
  }

  // ── Services ────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getServices({String? category}) async {
    final response = await _dio.get(ApiConstants.services, queryParameters: {
      if (category != null) 'category': category,
    });
    final data = response.data['data'];
    return List<Map<String, dynamic>>.from(data['services'] ?? []);
  }

  // ── Image Upload ────────────────────────────────────────────
  Future<Map<String, dynamic>> uploadImage(String filePath, {String folder = 'forum'}) async {
    final formData = FormData.fromMap({
      'image': await MultipartFile.fromFile(filePath, filename: 'upload.jpg'),
    });
    final response = await _dio.post(
      '${ApiConstants.upload}/image?folder=$folder',
      data: formData,
    );
    return response.data['data']['image'] as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> uploadAvatar(String filePath) async {
    final formData = FormData.fromMap({
      'avatar': await MultipartFile.fromFile(filePath, filename: 'avatar.jpg'),
    });
    final response = await _dio.post(
      '${ApiConstants.upload}/avatar',
      data: formData,
    );
    return response.data['data'] as Map<String, dynamic>;
  }

  // ── Helper ──────────────────────────────────────────────────
  PaginatedResult<Map<String, dynamic>> _parsePaginated(
    Response response,
    String dataKey,
  ) {
    final data = response.data['data'] as Map<String, dynamic>;
    final items = List<Map<String, dynamic>>.from(data[dataKey] ?? []);
    final meta = PaginationMeta.fromJson(data['meta'] as Map<String, dynamic>? ?? {});
    return PaginatedResult(items: items, meta: meta);
  }
}

/// Generic paginated result
class PaginatedResult<T> {
  final List<T> items;
  final PaginationMeta meta;

  const PaginatedResult({required this.items, required this.meta});
}
