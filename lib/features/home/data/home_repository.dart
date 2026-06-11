import '../../../core/network/api_client.dart';
import '../../../shared/models/bundle_model.dart';
import '../../../shared/models/blog_model.dart';

class HomeRepository {
  // ─── Bundles (Gói xét nghiệm) ────────────────────────────
  static Future<List<BundleModel>> getBundles({int limit = 6}) async {
    try {
      final response = await ApiClient.get(
        'testorder/api/CatalogBundle',
        params: {'pageNumber': 1, 'pageSize': limit},
      );
      final data = response.data;
      List items = data['items'] ?? data['data'] ?? data ?? [];
      return items
          .map((e) => BundleModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ─── Approved Blogs ───────────────────────────────────────
  static Future<List<BlogModel>> getApprovedBlogs({int limit = 3}) async {
    try {
      // Try public access first
      final response = await ApiClient.publicInstance.get(
        'blog/api/BlogPost',
        queryParameters: {'page': 1, 'pageSize': limit, 'status': 1},
      );
      final data = response.data;
      List items = data['items'] ?? data['data'] ?? data ?? [];
      return items
          .map((e) => BlogModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      try {
        final response = await ApiClient.get(
          'blog/api/BlogPost',
          params: {'page': 1, 'pageSize': limit, 'status': 1},
        );
        final data = response.data;
        List items = data['items'] ?? data['data'] ?? data ?? [];
        return items
            .map((e) => BlogModel.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {
        return [];
      }
    }
  }
}
