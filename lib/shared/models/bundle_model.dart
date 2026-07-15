class BundleModel {
  final dynamic bundleId;
  final String? bundleName;
  final String? description;
  final num? price;
  final bool? isActive;
  final List<CatalogModel>? catalogs;

  BundleModel({
    this.bundleId,
    this.bundleName,
    this.description,
    this.price,
    this.isActive,
    this.catalogs,
  });

  factory BundleModel.fromJson(Map<String, dynamic> json) {
    return BundleModel(
      bundleId: json['bundleId'] ?? json['id'],
      bundleName: json['bundleName']?.toString() ?? json['name']?.toString(),
      description: json['description']?.toString(),
      price: json['price'] as num?,
      isActive: json['isActive'] as bool?,
      catalogs: () {
        final catsRaw = json['catalogs'] ?? json['catalogDTOs'] ?? json['catalogBundles'] ?? json['bundleCatalogs'] ?? json['testCatalogs'] ?? json['tests'] ?? json['testItems'];
        return (catsRaw as List<dynamic>?)
            ?.map((e) => CatalogModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }(),
    );
  }

  String get displayName => bundleName ?? 'Gói xét nghiệm';
  String get displayPrice =>
      price != null ? '${_formatPrice(price!)} đ' : 'Liên hệ';

  String _formatPrice(num p) {
    return p.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class CatalogModel {
  final dynamic catalogId;
  final String? catalogName;
  final String? description;
  final num? price;
  final bool? isActive;
  final List<dynamic>? parameters;

  CatalogModel({
    this.catalogId,
    this.catalogName,
    this.description,
    this.price,
    this.isActive,
    this.parameters,
  });

  factory CatalogModel.fromJson(Map<String, dynamic> json) {
    return CatalogModel(
      // API trả về 'testName', fallback 'catalogName' hoặc 'name'
      catalogId: json['catalogId'] ?? json['id'],
      catalogName: json['testName']?.toString()
          ?? json['catalogName']?.toString()
          ?? json['name']?.toString(),
      description: json['description']?.toString(),
      price: (json['price'] as num?)?.toDouble(),
      isActive: json['isActive'] as bool?,
      parameters: json['parameters'] as List<dynamic>?,
    );
  }

  String get displayName => catalogName ?? 'Xét nghiệm';
  String get displayPrice =>
      price != null ? '${_formatPrice(price!)} đ' : 'Liên hệ';

  String _formatPrice(num p) {
    return p.toInt().toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}
