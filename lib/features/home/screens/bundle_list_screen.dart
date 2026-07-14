import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../config/app_theme.dart';
import '../../../shared/models/bundle_model.dart';
import '../data/home_repository.dart';

class BundleListScreen extends StatefulWidget {
  final String? search;
  const BundleListScreen({super.key, this.search});

  @override
  State<BundleListScreen> createState() => _BundleListScreenState();
}

class _BundleListScreenState extends State<BundleListScreen> {
  List<BundleModel> _bundles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBundles();
  }

  Future<void> _loadBundles() async {
    final results = await HomeRepository.getBundles(
      limit: 50,
      search: widget.search,
    ); // Lấy tối đa 50 gói kèm search filter
    if (mounted) {
      setState(() {
        _bundles = results;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: Text(
          widget.search != null && widget.search!.isNotEmpty
              ? 'Gói xét nghiệm ${widget.search}'
              : 'Tất cả gói xét nghiệm',
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _bundles.isEmpty
          ? const Center(
              child: Text(
                'Không có gói xét nghiệm nào',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _bundles.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final bundle = _bundles[index];
                return _buildBundleCard(bundle);
              },
            ),
    );
  }

  Widget _buildBundleCard(BundleModel bundle) {
    return GestureDetector(
      onTap: () => context.push('/bundles/${bundle.bundleId}'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.medical_services_rounded,
                    color: AppTheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bundle.displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        bundle.displayPrice,
                        style: const TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (bundle.description != null &&
                bundle.description!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text(
                bundle.description!,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  height: 1.4,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () =>
                  context.push('/booking?bundleId=${bundle.bundleId}'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 44),
              ),
              child: const Text('Đặt lịch ngay'),
            ),
          ],
        ),
      ),
    );
  }
}
