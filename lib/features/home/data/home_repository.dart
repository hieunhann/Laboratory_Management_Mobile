import '../../../core/network/api_client.dart';
import '../../../shared/models/bundle_model.dart';
import '../../../shared/models/blog_model.dart';

class HomeRepository {
  // ─── Bundles (Gói xét nghiệm) ────────────────────────────
  static Future<List<BundleModel>> getBundles({int limit = 50, String? search}) async {
    try {
      final Map<String, dynamic> params = {'page': 1, 'pageSize': limit};
      if (search != null && search.isNotEmpty) {
        params['search'] = search;
      }
      final response = await ApiClient.publicInstance.get(
        'testorder/api/TestBundle',
        queryParameters: params,
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

  // ─── Lấy chi tiết gói xét nghiệm kèm danh sách xét nghiệm con ──────────
  static Future<BundleModel?> getBundleDetails(int bundleId) async {
    try {
      final response = await ApiClient.publicInstance.get(
        'testorder/api/CatalogBundle/$bundleId',
      );
      final data = response.data;
      // Trả về danh sách gồm 1 phần tử đã được nhóm (grouped)
      if (data is List && data.isNotEmpty) {
        return BundleModel.fromJson(data.first as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
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
