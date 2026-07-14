import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../config/app_theme.dart';
import '../data/blog_repository.dart';
import '../../../shared/models/blog_model.dart';
import '../../../core/utils/format_utils.dart';
import '../../auth/data/auth_repository.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});
  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  List<BlogModel> _allBlogs = [];
  List<BlogModel> _blogs = [];
  bool _loading = true;
  String _search = '';
  final _searchCtrl = TextEditingController();
  final Map<String, String> _userNames = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _removeDiacritics(String str) {
    const withDia = 'áàảãạâấầẩẫậăắằẳẵặéèẻẽẹêếềểễệíìỉĩịóòỏõọôốồổỗộơớờởỡợúùủũụưứừửữựýỳỷỹỵđÁÀẢÃẠÂẤẦẨẪẬĂẮẰẲẴẶÉÈẺẼẸÊẾỀỂỄỆÍÌỈĨỊÓÒỎÕỌÔỐỒỔỖỘƠỚỜỞỠỢÚÙỦŨỤƯỨỪỬỮỰÝỲỶỸỴĐ';
    const withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyydAAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';
    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final blogs = await BlogRepository.getApprovedBlogs(page: 1, pageSize: 100);
    
    // Fetch author names
    final uniqueAuthorIds = blogs
        .map((b) => b.authorId)
        .where((id) => id != null && id.isNotEmpty)
        .map((id) => id!)
        .toSet();

    await Future.wait(uniqueAuthorIds.map((userId) async {
      if (!_userNames.containsKey(userId)) {
        try {
          final user = await AuthRepository.getUserById(userId);
          if (user != null && user.fullName != null && user.fullName!.isNotEmpty) {
            _userNames[userId] = user.fullName!;
          }
        } catch (_) {}
      }
    }));
    
    if (mounted) {
      setState(() {
        _allBlogs = blogs;
        _loading = false;
      });
      _onSearch();
    }
  }

  void _onSearch() {
    setState(() {
      if (_search.trim().isEmpty) {
        _blogs = _allBlogs;
      } else {
        final query = _removeDiacritics(_search.toLowerCase().trim());
        _blogs = _allBlogs.where((blog) {
          final title = _removeDiacritics(blog.displayTitle.toLowerCase());
          final category = _removeDiacritics((blog.categoryName ?? '').toLowerCase());
          return title.contains(query) || category.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Tin tức y tế'),
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () => context.pop()),
      ),
      body: Column(
        children: [
          // ─── Search bar ───────────────────────────────
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) {
                _search = v;
                _onSearch();
              },
              decoration: InputDecoration(
                hintText: 'Tìm kiếm bài viết...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.primary),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _search = '';
                          _onSearch();
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
            ),
          ),
          // ─── Blog list ────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
                : _blogs.isEmpty
                    ? const Center(child: Text('Không có bài viết',
                        style: TextStyle(color: AppTheme.textSecondary)))
                    : RefreshIndicator(
                        color: AppTheme.primary,
                        onRefresh: _loadData,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _blogs.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _buildBlogCard(_blogs[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlogCard(BlogModel blog) {
    return GestureDetector(
      onTap: () => context.push('/blog/${blog.postId}'),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: blog.fullImageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: blog.fullImageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: Icon(Icons.image, size: 48, color: Colors.grey),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.broken_image, size: 48, color: Colors.grey),
                        ),
                      )
                    : const Center(
                        child: Icon(Icons.article_rounded, size: 48, color: AppTheme.primary),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (blog.categoryName != null)
                    Text(blog.categoryName!,
                        style: const TextStyle(color: AppTheme.primary,
                            fontSize: 11, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(blog.displayTitle,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 15,
                          color: AppTheme.textPrimary),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text(blog.displaySummary,
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      if ((blog.authorId != null && _userNames.containsKey(blog.authorId)) || 
                          (blog.authorName != null && blog.authorName!.isNotEmpty)) ...[
                        const Icon(Icons.person_outline_rounded, size: 13, color: AppTheme.textHint),
                        const SizedBox(width: 4),
                        Text(_userNames[blog.authorId] ?? blog.authorName!,
                            style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                      ],
                      const Spacer(),
                      if (blog.createdAt != null)
                        Text(FormatUtils.formatDate(blog.createdAt),
                            style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
