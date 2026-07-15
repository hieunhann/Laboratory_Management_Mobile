class BlogModel {
  final dynamic postId;
  final String? title;
  final String? content;
  final String? summary;
  final String? authorId;
  final String? authorName;
  final String? thumbnailUrl;
  final String? imagePath;
  final int? status;
  final int? categoryId;
  final String? categoryName;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int? commentCount;

  BlogModel({
    this.postId,
    this.title,
    this.content,
    this.summary,
    this.authorId,
    this.authorName,
    this.thumbnailUrl,
    this.imagePath,
    this.status,
    this.categoryId,
    this.categoryName,
    this.createdAt,
    this.updatedAt,
    this.commentCount,
  });

  factory BlogModel.fromJson(Map<String, dynamic> json) {
    return BlogModel(
      postId: json['postId'] ?? json['id'],
      title: json['title']?.toString(),
      content: json['content']?.toString(),
      summary: json['summary']?.toString() ??
          json['description']?.toString(),
      authorId: json['authorId']?.toString(),
      authorName: json['authorName']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString() ??
          json['imageUrl']?.toString(),
      imagePath: json['imagePath']?.toString(),
      status: json['status'] as int?,
      categoryId: json['categoryId'] as int?,
      categoryName: json['categoryName']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : (json['createdDate'] != null ? DateTime.tryParse(json['createdDate'].toString()) : null),
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'].toString())
          : null,
      commentCount: json['commentCount'] as int?,
    );
  }

  bool get isApproved => status == 1;
  String get displayTitle => title ?? 'Bài viết';
  String get displaySummary =>
      summary ?? (content != null ? _truncate(content!, 100) : '');

  String? get fullImageUrl {
    if (thumbnailUrl != null && thumbnailUrl!.isNotEmpty) return thumbnailUrl;
    if (imagePath == null || imagePath!.isEmpty) return null;
    if (imagePath!.startsWith('http')) return imagePath;

    // Backend GetById sometimes returns absolute OS paths (e.g. /app/Images/file.jpg)
    // Extract just the file name and append to standard endpoint
    final fileName = imagePath!.split('/').last.split('\\').last;
    return 'https://hemalink-gateway-5ils.onrender.com/blog/Images/$fileName';
  }

  String _truncate(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}...';
  }
}

class BlogCategoryModel {
  final int? categoryId;
  final String? categoryName;
  final String? description;

  BlogCategoryModel({
    this.categoryId,
    this.categoryName,
    this.description,
  });

  factory BlogCategoryModel.fromJson(Map<String, dynamic> json) {
    return BlogCategoryModel(
      categoryId: json['categoryId'] as int? ?? json['id'] as int?,
      categoryName: json['categoryName']?.toString() ?? json['name']?.toString(),
      description: json['description']?.toString(),
    );
  }
}
