import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../data/blog_repository.dart';
import '../../../shared/models/blog_model.dart';
import '../../../core/utils/format_utils.dart';

class BlogListScreen extends StatefulWidget {
  const BlogListScreen({super.key});
  @override
  State<BlogListScreen> createState() => _BlogListScreenState();
}

class _BlogListScreenState extends State<BlogListScreen> {
  List<BlogModel> _blogs = [];
  List<BlogCategoryModel> _categories = [];
  bool _loading = true;
  int? _selectedCategory;
  String _search = '';
  final _searchCtrl = TextEditingController();

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

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      BlogRepository.getApprovedBlogs(
          categoryId: _selectedCategory, search: _search),
      BlogRepository.getCategories(),
    ]);
    if (mounted) {
      setState(() {
        _blogs = results[0] as List<BlogModel>;
        _categories = results[1] as List<BlogCategoryModel>;
        _loading = false;
      });
    }
  }

  Future<void> _onSearch() async {
    setState(() => _loading = true);
    final blogs = await BlogRepository.getApprovedBlogs(
        search: _search, categoryId: _selectedCategory);
    if (mounted) setState(() { _blogs = blogs; _loading = false; });
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
              onChanged: (v) => _search = v,
              onSubmitted: (_) => _onSearch(),
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
          // ─── Categories filter ────────────────────────
          if (_categories.isNotEmpty)
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: [
                  _buildCategoryChip(null, 'Tất cả'),
                  ..._categories.map((c) => _buildCategoryChip(c.categoryId, c.categoryName ?? '')),
                ],
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

  Widget _buildCategoryChip(int? id, String label) {
    final isSelected = _selectedCategory == id;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(
          fontSize: 12,
          color: isSelected ? Colors.white : AppTheme.primary,
        )),
        selected: isSelected,
        selectedColor: AppTheme.primary,
        backgroundColor: AppTheme.surfaceVariant,
        onSelected: (_) {
          setState(() => _selectedCategory = id);
          _onSearch();
        },
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
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: const Center(
                child: Icon(Icons.article_rounded, size: 48, color: AppTheme.primary),
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
                      const Icon(Icons.person_outline_rounded, size: 13, color: AppTheme.textHint),
                      const SizedBox(width: 4),
                      Text(blog.authorName ?? 'Tác giả',
                          style: const TextStyle(fontSize: 11, color: AppTheme.textHint)),
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
