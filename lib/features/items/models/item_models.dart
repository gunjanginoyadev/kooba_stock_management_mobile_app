/// Category for "special" (category-based) items.
class ItemCategory {
  final String id;
  final String name;

  const ItemCategory({
    required this.id,
    required this.name,
  });

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    return ItemCategory(
      id: json['id'] as String,
      name: json['name'] as String,
    );
  }
}

/// A stock item: normal (no category) or special (has category).
class StockItem {
  final String id;
  final String name;
  final String? sku;
  final String? categoryId;
  final String? categoryName;
  final int quantity;

  const StockItem({
    required this.id,
    required this.name,
    this.sku,
    this.categoryId,
    this.categoryName,
    this.quantity = 0,
  });

  bool get isNormal => categoryId == null || categoryId!.isEmpty;

  factory StockItem.fromJson(Map<String, dynamic> json) {
    return StockItem(
      id: json['id'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String?,
      categoryId: json['category_id'] as String?,
      categoryName: json['category_name'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toInsertJson({required String userId}) {
    return {
      'name': name,
      'sku': sku,
      'category_id': categoryId,
      'quantity': quantity,
      'user_id': userId,
    };
  }
}
