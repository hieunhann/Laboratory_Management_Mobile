import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import '../../../config/app_theme.dart';
import '../data/blog_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/models/blog_model.dart';
import '../../../core/utils/format_utils.dart';

class BlogDetailScreen extends StatefulWidget {
  final String postId;
  const BlogDetailScreen({super.key, required this.postId});
  @override
  State<BlogDetailScreen> createState() => _BlogDetailScreenState();
}

class _BlogDetailScreenState extends State<BlogDetailScreen> {
  BlogModel? _blog;
  List<Map<String, dynamic>> _comments = [];
  Map<String, String> _userNames = {};
  Map<int, String?> _userReactions = {};
  Map<int, int> _commentLikes = {};
  Map<int, int> _commentDislikes = {};
  String? _resolvedAuthorName;
  bool _loading = true;
  final _commentCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadBlog();
  }

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBlog() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      BlogRepository.getBlogById(widget.postId),
      BlogRepository.getComments(widget.postId),
    ]);
    
    final blog = results[0] as BlogModel?;
    final comments = results[1] as List<Map<String, dynamic>>;

    // Trích xuất các userId độc nhất
    final uniqueUserIds = comments
        .map((c) => c['userId']?.toString() ?? c['UserId']?.toString())
        .where((id) => id != null && id.isNotEmpty)
        .toSet();

    final namesMap = <String, String>{};
    await Future.wait(uniqueUserIds.map((userId) async {
      try {
        final user = await AuthRepository.getUserById(userId!);
        if (user != null && user.fullName != null && user.fullName!.isNotEmpty) {
          namesMap[userId] = user.fullName!;
        }
      } catch (_) {
        // Bỏ qua lỗi kết nối đơn lẻ
      }
    }));

    // Khởi tạo số lượng likes/dislikes ngẫu nhiên giả lập cho mỗi comment
    for (var c in comments) {
      final commentId = c['commentId'] as int? ?? c['CommentId'] as int? ?? 0;
      if (commentId != 0) {
        _commentLikes[commentId] ??= (commentId * 7) % 19;
        _commentDislikes[commentId] ??= (commentId * 3) % 7;
      }
    }

    // Tìm tên tác giả từ authorId
    String? resolvedAuthor;
    if (blog != null && blog.authorId != null && blog.authorId!.isNotEmpty) {
      try {
        final user = await AuthRepository.getUserById(blog.authorId!);
        if (user != null && user.fullName != null && user.fullName!.isNotEmpty) {
          resolvedAuthor = user.fullName;
        }
      } catch (_) {
        // Bỏ qua lỗi kết nối đơn lẻ
      }
    }

    if (mounted) {
      setState(() {
        _blog = blog;
        _comments = comments;
        _userNames = namesMap;
        _resolvedAuthorName = resolvedAuthor;
        _loading = false;
      });
    }
  }

  Future<void> _submitComment() async {
    if (_commentCtrl.text.trim().isEmpty) return;
    setState(() => _submitting = true);

    String? currentUserId;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      currentUserId = authProvider.currentUser?.userId;
    } catch (_) {}

    final success = await BlogRepository.createComment({
      'postId': int.tryParse(widget.postId) ?? widget.postId,
      'content': _commentCtrl.text.trim(),
      'commentId': 0,
      'isUpdated': false,
      if (currentUserId != null) 'userId': currentUserId,
    });
    if (success && mounted) {
      _commentCtrl.clear();
      await _loadBlog();
    }
    if (mounted) setState(() => _submitting = false);
  }

  void _toggleReaction(int commentId, String type) {
    if (commentId == 0) return;
    setState(() {
      final currentReaction = _userReactions[commentId];
      if (currentReaction == type) {
        // Hủy reaction
        _userReactions[commentId] = null;
        if (type == 'like') {
          _commentLikes[commentId] = (_commentLikes[commentId] ?? 1) - 1;
        } else {
          _commentDislikes[commentId] = (_commentDislikes[commentId] ?? 1) - 1;
        }
      } else {
        // Đổi reaction hoặc thêm mới
        if (currentReaction == 'like') {
          _commentLikes[commentId] = (_commentLikes[commentId] ?? 1) - 1;
        } else if (currentReaction == 'dislike') {
          _commentDislikes[commentId] = (_commentDislikes[commentId] ?? 1) - 1;
        }

        _userReactions[commentId] = type;
        if (type == 'like') {
          _commentLikes[commentId] = (_commentLikes[commentId] ?? 0) + 1;
        } else {
          _commentDislikes[commentId] = (_commentDislikes[commentId] ?? 0) + 1;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Bài viết'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : _blog == null
          ? const Center(child: Text('Không tìm thấy bài viết'))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero image
                  Container(
                    height: 200,
                    width: double.infinity,
                    color: AppTheme.surfaceVariant,
                    child: const Center(
                      child: Icon(
                        Icons.article_rounded,
                        size: 64,
                        color: AppTheme.primary,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Category
                        if (_blog!.categoryName != null)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _blog!.categoryName!,
                              style: const TextStyle(
                                color: AppTheme.primary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        // Title
                        Text(
                          _blog!.displayTitle,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Meta
                        Row(
                          children: [
                            if (_resolvedAuthorName != null &&
                                _resolvedAuthorName!.isNotEmpty &&
                                _resolvedAuthorName != 'Tác giả') ...[
                              const Icon(
                                Icons.person_outline_rounded,
                                size: 14,
                                color: AppTheme.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                _resolvedAuthorName!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.textHint,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: AppTheme.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              FormatUtils.formatDate(_blog!.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textHint,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 8),
                        // Content
                        if (_blog!.content != null)
                          Html(
                            data: _blog!.content!,
                            style: {
                              'body': Style(
                                fontSize: FontSize(15),
                                color: AppTheme.textPrimary,
                                lineHeight: const LineHeight(1.6),
                              ),
                            },
                          ),
                        const SizedBox(height: 24),
                        // Comments section
                        Text(
                          'Bình luận (${_comments.length})',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Comment input
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _commentCtrl,
                                decoration: const InputDecoration(
                                  hintText: 'Viết bình luận...',
                                  contentPadding: EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 10,
                                  ),
                                ),
                                maxLines: 2,
                                minLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: _submitting ? null : _submitComment,
                              icon: _submitting
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.send_rounded,
                                      color: AppTheme.primary,
                                    ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Comments list
                        ..._comments.map((c) => _buildCommentCard(c)),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildCommentCard(Map<String, dynamic> c) {
    final userId = c['userId']?.toString() ?? c['UserId']?.toString() ?? '';
    final displayName = _userNames[userId] ?? (userId.isNotEmpty ? userId : 'Người dùng');
    
    final createdDateStr = c['createdDate']?.toString() ?? c['CreatedDate']?.toString();
    final parsedDate = FormatUtils.parseUtcToLocal(createdDateStr);
    final dateText = FormatUtils.formatDateTime(parsedDate);

    final commentId = c['commentId'] as int? ?? c['CommentId'] as int? ?? 0;
    final userReaction = _userReactions[commentId];
    final hasLiked = userReaction == 'like';
    final hasDisliked = userReaction == 'dislike';
    final likesCount = _commentLikes[commentId] ?? 0;
    final dislikesCount = _commentDislikes[commentId] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusSm),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppTheme.surfaceVariant,
            child: const Icon(
              Icons.person_rounded,
              size: 16,
              color: AppTheme.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        displayName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dateText.isNotEmpty)
                      Text(
                        dateText,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppTheme.textHint,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  c['content']?.toString() ?? '',
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
                if (commentId != 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => _toggleReaction(commentId, 'like'),
                        child: Row(
                          children: [
                            Icon(
                              hasLiked ? Icons.thumb_up_rounded : Icons.thumb_up_outlined,
                              size: 14,
                              color: hasLiked ? AppTheme.primary : AppTheme.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              likesCount.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: hasLiked ? AppTheme.primary : AppTheme.textHint,
                                fontWeight: hasLiked ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => _toggleReaction(commentId, 'dislike'),
                        child: Row(
                          children: [
                            Icon(
                              hasDisliked ? Icons.thumb_down_rounded : Icons.thumb_down_outlined,
                              size: 14,
                              color: hasDisliked ? Colors.red : AppTheme.textHint,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dislikesCount.toString(),
                              style: TextStyle(
                                fontSize: 11,
                                color: hasDisliked ? Colors.red : AppTheme.textHint,
                                fontWeight: hasDisliked ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
