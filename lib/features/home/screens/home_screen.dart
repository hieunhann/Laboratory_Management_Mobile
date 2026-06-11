import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../data/home_repository.dart';
import '../../../features/auth/providers/auth_provider.dart';
import '../../../shared/models/bundle_model.dart';
import '../../../shared/models/blog_model.dart';
import '../../../config/app_theme.dart';
import '../../../core/utils/format_utils.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<BundleModel> _bundles = [];
  List<BlogModel> _blogs = [];
  bool _loadingBundles = true;
  bool _loadingBlogs = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final bundlesFuture = HomeRepository.getBundles();
    final blogsFuture = HomeRepository.getApprovedBlogs();

    final results = await Future.wait([bundlesFuture, blogsFuture]);
    if (mounted) {
      setState(() {
        _bundles = results[0] as List<BundleModel>;
        _blogs = results[1] as List<BlogModel>;
        _loadingBundles = false;
        _loadingBlogs = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: RefreshIndicator(
        color: AppTheme.primary,
        onRefresh: _loadData,
        child: CustomScrollView(
          slivers: [
            // ─── App Bar ─────────────────────────────────
            SliverAppBar(
              expandedHeight: 0,
              floating: true,
              snap: true,
              backgroundColor: Colors.white,
              elevation: 0,
              title: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppTheme.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.medical_services_rounded,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'BloodTest',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              actions: [
                if (auth.isAuthenticated)
                  IconButton(
                    icon: const CircleAvatar(
                      radius: 16,
                      backgroundColor: AppTheme.surfaceVariant,
                      child: Icon(Icons.person_rounded,
                          size: 18, color: AppTheme.primary),
                    ),
                    onPressed: () => context.push('/profile'),
                  )
                else
                  TextButton(
                    onPressed: () => context.push('/login'),
                    child: const Text('Đăng nhập'),
                  ),
                const SizedBox(width: 8),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ─── Hero Banner ─────────────────────────
                  _buildHeroBanner(auth),
                  const SizedBox(height: 20),

                  // ─── Quick Actions ────────────────────────
                  _buildQuickActions(),
                  const SizedBox(height: 24),

                  // ─── Services ────────────────────────────
                  _buildSectionHeader(
                    title: 'Dịch vụ của chúng tôi',
                    subtitle: 'Xét nghiệm chuyên nghiệp & chính xác',
                  ),
                  const SizedBox(height: 12),
                  _buildServicesGrid(),
                  const SizedBox(height: 24),

                  // ─── Bundles ──────────────────────────────
                  _buildSectionHeader(
                    title: 'Gói xét nghiệm',
                    subtitle: 'Tiết kiệm hơn với gói dịch vụ',
                    onSeeAll: () => context.push('/booking'),
                  ),
                  const SizedBox(height: 12),
                  _buildBundlesSection(),
                  const SizedBox(height: 24),

                  // ─── Blog ─────────────────────────────────
                  _buildSectionHeader(
                    title: 'Tin tức y tế',
                    subtitle: 'Cập nhật kiến thức sức khỏe',
                    onSeeAll: () => context.push('/blog'),
                  ),
                  const SizedBox(height: 12),
                  _buildBlogsSection(),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Hero Banner ─────────────────────────────────────────
  Widget _buildHeroBanner(AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0D47A1), Color(0xFF1E88E5)],
        ),
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        boxShadow: AppTheme.elevatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '🏥 Phòng xét nghiệm hiện đại',
                        style:
                            TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Xét nghiệm máu\nchuyên nghiệp',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Kết quả nhanh chóng, chính xác\nvà bảo mật thông tin',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science_rounded,
                  size: 44,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => context.push('/booking'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                'Đặt lịch xét nghiệm ngay',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions ────────────────────────────────────────
  Widget _buildQuickActions() {
    final actions = [
      _QuickAction(
        icon: Icons.calendar_month_rounded,
        label: 'Đặt lịch',
        color: AppTheme.primary,
        bgColor: const Color(0xFFE3F2FD),
        onTap: () => context.push('/booking'),
      ),
      _QuickAction(
        icon: Icons.history_rounded,
        label: 'Lịch sử',
        color: const Color(0xFF7B1FA2),
        bgColor: const Color(0xFFF3E5F5),
        onTap: () => context.push('/history'),
      ),
      _QuickAction(
        icon: Icons.article_rounded,
        label: 'Kết quả',
        color: AppTheme.secondary,
        bgColor: const Color(0xFFE0F2F1),
        onTap: () => context.push('/medical-record'),
      ),
      _QuickAction(
        icon: Icons.newspaper_rounded,
        label: 'Tin tức',
        color: const Color(0xFFF57C00),
        bgColor: const Color(0xFFFFF3E0),
        onTap: () => context.push('/blog'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: actions
            .map((a) => _buildQuickActionItem(a))
            .toList(),
      ),
    );
  }

  Widget _buildQuickActionItem(_QuickAction action) {
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: action.bgColor,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
            child: Icon(action.icon, color: action.color, size: 28),
          ),
          const SizedBox(height: 6),
          Text(
            action.label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Services Grid ────────────────────────────────────────
  Widget _buildServicesGrid() {
    final services = [
      {'icon': Icons.bloodtype_rounded, 'name': 'Xét nghiệm máu', 'color': AppTheme.accent},
      {'icon': Icons.biotech_rounded, 'name': 'Xét nghiệm tổng quát', 'color': AppTheme.secondary},
      {'icon': Icons.monitor_heart_rounded, 'name': 'Kiểm tra tim mạch', 'color': AppTheme.primary},
      {'icon': Icons.science_rounded, 'name': 'Xét nghiệm sinh hóa', 'color': const Color(0xFF7B1FA2)},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 2.5,
        children: services.map((s) {
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (s['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(s['icon'] as IconData,
                      color: s['color'] as Color, size: 20),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s['name'] as String,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ─── Bundles Section ──────────────────────────────────────
  Widget _buildBundlesSection() {
    if (_loadingBundles) {
      return _buildShimmerList();
    }

    if (_bundles.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Không có gói xét nghiệm',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return SizedBox(
      height: 160,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _bundles.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, i) => _buildBundleCard(_bundles[i]),
      ),
    );
  }

  Widget _buildBundleCard(BundleModel bundle) {
    return GestureDetector(
      onTap: () => context.push('/booking'),
      child: Container(
        width: 180,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.medical_services_rounded,
                  color: AppTheme.primary, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              bundle.displayName,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
                color: AppTheme.textPrimary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            Text(
              bundle.displayPrice,
              style: const TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primary,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Đặt lịch',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Blogs Section ────────────────────────────────────────
  Widget _buildBlogsSection() {
    if (_loadingBlogs) {
      return _buildShimmerList();
    }

    if (_blogs.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          'Chưa có bài viết',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: _blogs
            .map((b) => _buildBlogCard(b))
            .toList(),
      ),
    );
  }

  Widget _buildBlogCard(BlogModel blog) {
    return GestureDetector(
      onTap: () => context.push('/blog/${blog.postId}'),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(AppTheme.radiusSm),
              ),
              child: const Icon(Icons.article_rounded,
                  color: AppTheme.primary, size: 32),
            ),
            const SizedBox(width: 12),
            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (blog.categoryName != null)
                    Text(
                      blog.categoryName!,
                      style: const TextStyle(
                        color: AppTheme.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Text(
                    blog.displayTitle,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  if (blog.createdAt != null)
                    Text(
                      FormatUtils.formatDate(blog.createdAt),
                      style: const TextStyle(
                        color: AppTheme.textHint,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppTheme.textHint),
          ],
        ),
      ),
    );
  }

  // ─── Section Header ───────────────────────────────────────
  Widget _buildSectionHeader({
    required String title,
    required String subtitle,
    VoidCallback? onSeeAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (onSeeAll != null)
            TextButton(
              onPressed: onSeeAll,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
              ),
              child: const Text('Xem tất cả'),
            ),
        ],
      ),
    );
  }

  // ─── Shimmer Loading ──────────────────────────────────────
  Widget _buildShimmerList() {
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, __) => Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            width: 160,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAction {
  final IconData icon;
  final String label;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });
}
