import '../../../core/network/api_client.dart';
import '../../../shared/models/blog_model.dart';

class BlogRepository {
  // ─── Get approved blogs ───────────────────────────────────
  static Future<List<BlogModel>> getApprovedBlogs({
    int page = 1,
    int pageSize = 20,
    String? search,
    int? categoryId,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'pageSize': pageSize,
        'status': 1,
      };
      if (search != null && search.isNotEmpty) params['search'] = search;
      if (categoryId != null) params['categoryId'] = categoryId;

      // Try public first
      try {
        final response = await ApiClient.publicInstance
            .get('blog/api/BlogPost', queryParameters: params);
        return _parseBlogs(response.data);
      } catch (_) {
        final response =
            await ApiClient.get('blog/api/BlogPost', params: params);
        return _parseBlogs(response.data);
      }
    } catch (e) {
      return [];
    }
  }

  // ─── Get blog by ID ───────────────────────────────────────
  static Future<BlogModel?> getBlogById(dynamic id) async {
    try {
      try {
        final response =
            await ApiClient.publicInstance.get('blog/api/BlogPost/$id');
        final data = response.data;
        final d = data['data'] ?? data;
        return d != null
            ? BlogModel.fromJson(d as Map<String, dynamic>)
            : null;
      } catch (_) {
        final response = await ApiClient.get('blog/api/BlogPost/$id');
        final data = response.data;
        final d = data['data'] ?? data;
        return d != null
            ? BlogModel.fromJson(d as Map<String, dynamic>)
            : null;
      }
    } catch (e) {
      return null;
    }
  }

  // ─── Get categories ───────────────────────────────────────
  static Future<List<BlogCategoryModel>> getCategories() async {
    try {
      try {
        final response =
            await ApiClient.publicInstance.get('blog/api/Category');
        return _parseCategories(response.data);
      } catch (_) {
        final response = await ApiClient.get('blog/api/Category');
        return _parseCategories(response.data);
      }
    } catch (e) {
      return [];
    }
  }

  // ─── Get comments ─────────────────────────────────────────
  static Future<List<Map<String, dynamic>>> getComments(dynamic postId) async {
    try {
      try {
        final response = await ApiClient.publicInstance
            .get('blog/api/Comment/post/$postId');
        final data = response.data;
        List items = data is List ? data : data['data'] ?? data['items'] ?? [];
        return items.cast<Map<String, dynamic>>();
      } catch (_) {
        final response =
            await ApiClient.get('blog/api/Comment/post/$postId');
        final data = response.data;
        List items = data is List ? data : data['data'] ?? data['items'] ?? [];
        return items.cast<Map<String, dynamic>>();
      }
    } catch (e) {
      return [];
    }
  }

  // ─── Create comment ───────────────────────────────────────
  static Future<bool> createComment(Map<String, dynamic> payload) async {
    try {
      await ApiClient.post('blog/api/Comment', data: payload);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ─── Helpers ──────────────────────────────────────────────
  static List<BlogModel> _parseBlogs(dynamic data) {
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = data['items'] ?? data['data'] ?? [];
    }
    return items
        .map((e) => BlogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static List<BlogCategoryModel> _parseCategories(dynamic data) {
    List items = [];
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = data['data'] ?? data['items'] ?? [];
    }
    return items
        .map((e) => BlogCategoryModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
