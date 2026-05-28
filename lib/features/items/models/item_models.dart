/// Category for "special" (category-based) items.
class ItemCategory {
  final String id;
  final String name;
  final String? imageUrl;

  const ItemCategory({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory ItemCategory.fromJson(Map<String, dynamic> json) {
    return ItemCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
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

/// Excel-style "Type" (profile/die), e.g. HETVA DIE 2001.
class StockItemType {
  final String id;
  final String name;
  final String? imageUrl;
  final String? remark;

  const StockItemType({
    required this.id,
    required this.name,
    this.imageUrl,
    this.remark,
  });

  factory StockItemType.fromJson(Map<String, dynamic> json) {
    return StockItemType(
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      remark: json['remark'] as String?,
    );
  }
}

/// Excel-style stock line: (type + code + finish) with qty_10ft/qty_12ft.
class StockSheetItem {
  final String id;
  final String typeId;
  final String typeName;
  final String? typeImageUrl;
  final String code;
  final String finish;
  final int qty10ft;
  final int qty12ft;
  final String? remark;

  const StockSheetItem({
    required this.id,
    required this.typeId,
    required this.typeName,
    required this.typeImageUrl,
    required this.code,
    required this.finish,
    required this.qty10ft,
    required this.qty12ft,
    this.remark,
  });

  factory StockSheetItem.fromJson(Map<String, dynamic> json) {
    // When selected with join: item_types(name, image_url)
    final joinedType = json['item_types'];
    final typeName =
        (json['type_name'] as String?) ??
        (joinedType is Map ? joinedType['name'] as String? : null) ??
        '';
    final typeImageUrl =
        (json['type_image_url'] as String?) ??
        (joinedType is Map ? joinedType['image_url'] as String? : null);

    return StockSheetItem(
      id: json['id'] as String,
      typeId: json['type_id'] as String,
      typeName: typeName,
      typeImageUrl: typeImageUrl,
      code: json['code'] as String,
      finish: json['finish'] as String,
      qty10ft: (json['qty_10ft'] as num?)?.toInt() ?? 0,
      qty12ft: (json['qty_12ft'] as num?)?.toInt() ?? 0,
      remark: json['remark'] as String?,
    );
  }
}

/// Stock entry (history) for items_v2 (10ft/12ft deltas).
class StockEntryV2 {
  final String id;
  final String itemId;
  final String entryType; // 'in' | 'out'
  final int delta10ft;
  final int delta12ft;
  final String? location;
  final String? notes;
  final DateTime createdAt;
  final String? typeName;
  final String? typeImageUrl;
  final String? code;
  final String? finish;
  final String? enteredByName;

  const StockEntryV2({
    required this.id,
    required this.itemId,
    required this.entryType,
    required this.delta10ft,
    required this.delta12ft,
    required this.location,
    required this.notes,
    required this.createdAt,
    required this.typeName,
    required this.typeImageUrl,
    required this.code,
    required this.finish,
    required this.enteredByName,
  });

  bool get isIn => entryType == 'in';

  String get itemLabel {
    final parts = <String>[];
    if (typeName != null && typeName!.trim().isNotEmpty) parts.add(typeName!.trim());
    if (code != null && code!.trim().isNotEmpty) parts.add(code!.trim());
    if (finish != null && finish!.trim().isNotEmpty) parts.add(finish!.trim());
    return parts.join(' · ');
  }

  factory StockEntryV2.fromJson(Map<String, dynamic> json) {
    final joinedItem = json['items_v2'];
    final type = joinedItem is Map ? joinedItem['item_types'] : null;
    return StockEntryV2(
      id: json['id'] as String,
      itemId: json['item_id'] as String,
      entryType: json['entry_type'] as String,
      delta10ft: (json['delta_10ft'] as num?)?.toInt() ?? 0,
      delta12ft: (json['delta_12ft'] as num?)?.toInt() ?? 0,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
      createdAt:
          DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      typeName: type is Map ? type['name'] as String? : null,
      typeImageUrl: type is Map ? type['image_url'] as String? : null,
      code: joinedItem is Map ? joinedItem['code'] as String? : null,
      finish: joinedItem is Map ? joinedItem['finish'] as String? : null,
      enteredByName: json['entered_by_name'] as String?,
    );
  }
}
