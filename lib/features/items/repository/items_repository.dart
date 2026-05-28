import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../models/item_models.dart';

class ItemsRepository {
  ItemsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  bool get _isAvailable => SupabaseConfig.isConfigured;

  String? get _userId => _client.auth.currentUser?.id;

  Future<String?> getMyFullName() async {
    if (!_isAvailable || _userId == null) return null;
    final res = await _client
        .from('profiles')
        .select('full_name')
        .eq('id', _userId!)
        .maybeSingle();
    if (res == null) return null;
    final name = res['full_name'] as String?;
    if (name == null || name.trim().isEmpty) return null;
    return name.trim();
  }

  /// Get or create category by name for current user. Returns category id.
  Future<String> getOrCreateCategoryId(
    String categoryName, {
    String? imageUrl,
  }) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    final name = categoryName.trim();
    if (name.isEmpty) throw ArgumentError('Category name is required');

    final existing = await _client
        .from('item_categories')
        .select('id, image_url')
        .eq('user_id', _userId!)
        .eq('name', name)
        .maybeSingle();

    if (existing != null && existing['id'] != null) {
      final trimmedUrl = imageUrl?.trim();
      final urlToSet = (trimmedUrl == null || trimmedUrl.isEmpty)
          ? null
          : trimmedUrl;
      final currentUrl = existing['image_url'] as String?;
      if (urlToSet != null && (currentUrl == null || currentUrl.isEmpty)) {
        await _client.from('item_categories').update({
          'image_url': urlToSet,
        }).eq('id', existing['id']);
      }
      return existing['id'] as String;
    }

    final insert = await _client.from('item_categories').insert({
      'name': name,
      'image_url': imageUrl?.trim().isEmpty == true ? null : imageUrl?.trim(),
      'user_id': _userId!,
    }).select('id').single();

    return insert['id'].toString();
  }

  /// Returns true if an item with this name already exists (normal or under any category), case-insensitive.
  Future<bool> itemNameExists(String name) async {
    if (!_isAvailable || _userId == null) return false;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final all = await _client
        .from('items')
        .select('name')
        .eq('user_id', _userId!);
    final list = all as List;
    final lowerName = trimmed.toLowerCase();
    for (final row in list) {
      final itemName = (row as Map<String, dynamic>)['name'] as String?;
      if (itemName != null && itemName.toLowerCase() == lowerName) return true;
    }
    return false;
  }

  /// Insert a normal item (no category).
  Future<StockItem> addNormalItem({
    required String name,
    String? sku,
    int quantity = 0,
  }) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) throw ArgumentError('Item name is required');

    if (await itemNameExists(trimmedName)) {
      throw Exception('An item with this name already exists (as normal or under a category).');
    }

    final res = await _client.from('items').insert({
      'name': trimmedName,
      'sku': sku?.trim().isEmpty == true ? null : sku?.trim(),
      'category_id': null,
      'quantity': quantity,
      'user_id': _userId!,
    }).select().single();

    return StockItem.fromJson(Map<String, dynamic>.from(res));
  }

  /// Insert a special (category-based) item.
  Future<StockItem> addSpecialItem({
    required String categoryName,
    required String itemName,
    String? categoryImageUrl,
    String? sku,
    int quantity = 0,
  }) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    final cat = categoryName.trim();
    final item = itemName.trim();
    if (cat.isEmpty) throw ArgumentError('Category name is required');
    if (item.isEmpty) throw ArgumentError('Item name is required');

    final categoryId = await getOrCreateCategoryId(
      cat,
      imageUrl: categoryImageUrl,
    );

    if (await itemNameExists(item)) {
      throw Exception('An item with this name already exists (as normal or under a category).');
    }

    final res = await _client.from('items').insert({
      'name': item,
      'sku': sku?.trim().isEmpty == true ? null : sku?.trim(),
      'category_id': categoryId,
      'quantity': quantity,
      'user_id': _userId!,
    }).select().single();

    final map = Map<String, dynamic>.from(res);
    map['category_name'] = cat;
    return StockItem.fromJson(map);
  }

  /// Fetch all normal items (no category).
  Future<List<StockItem>> getNormalItems() async {
    if (!_isAvailable || _userId == null) return [];

    final res = await _client
        .from('items')
        .select()
        .eq('user_id', _userId!)
        .isFilter('category_id', null)
        .order('name');

    return (res as List)
        .map((e) => StockItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all categories with their items (for special / manage items).
  Future<List<ItemCategory>> getCategories() async {
    if (!_isAvailable || _userId == null) return [];

    final res = await _client
        .from('item_categories')
        .select()
        .eq('user_id', _userId!)
        .order('name');

    return (res as List)
        .map((e) => ItemCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Fetch all items that have a category (special items), with category name.
  Future<List<StockItem>> getSpecialItems() async {
    if (!_isAvailable || _userId == null) return [];

    final res = await _client
        .from('items')
        .select('*, item_categories(name)')
        .eq('user_id', _userId!)
        .not('category_id', 'is', null)
        .order('name');

    return (res as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
      final cat = map['item_categories'];
      if (cat is Map) {
        map['category_name'] = cat['name'];
      }
      map.remove('item_categories');
      return StockItem.fromJson(map);
    }).toList();
  }

  /// Fetch items by category id (for one category's items).
  Future<List<StockItem>> getItemsByCategoryId(String categoryId) async {
    if (!_isAvailable || _userId == null) return [];

    final res = await _client
        .from('items')
        .select('*, item_categories(name)')
        .eq('user_id', _userId!)
        .eq('category_id', categoryId)
        .order('name');

    return (res as List).map((e) {
      final map = Map<String, dynamic>.from(e as Map<String, dynamic>);
      final cat = map['item_categories'];
      if (cat is Map) {
        map['category_name'] = cat['name'];
      }
      map.remove('item_categories');
      return StockItem.fromJson(map);
    }).toList();
  }

  /// All items grouped: normal list + categories with items (for manage screen).
  Future<({List<StockItem> normal, List<ItemCategory> categories})> getManageData() async {
    final normal = await getNormalItems();
    final categories = await getCategories();
    return (normal: normal, categories: categories);
  }

  /// Categories with their items (each category has list of items).
  Future<List<MapEntry<ItemCategory, List<StockItem>>>> getCategoriesWithItems() async {
    final categories = await getCategories();
    final result = <MapEntry<ItemCategory, List<StockItem>>>[];
    for (final cat in categories) {
      final items = await getItemsByCategoryId(cat.id);
      result.add(MapEntry(cat, items));
    }
    return result;
  }

  Exception _notConfigured() {
    return Exception('Supabase not configured or user not signed in');
  }

  // ----------------------------------------------------------------------------
  // Excel-style stock (types + items_v2)
  // ----------------------------------------------------------------------------

  Future<List<StockItemType>> getItemTypes() async {
    if (!_isAvailable || _userId == null) return [];
    final res = await _client
        .from('item_types')
        .select()
        .order('name');

    return (res as List)
        .map((e) => StockItemType.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<String> getOrCreateTypeId({
    required String typeName,
    String? imageUrl,
    String? remark,
  }) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    final name = typeName.trim();
    if (name.isEmpty) throw ArgumentError('Type name is required');

    final existing = await _client
        .from('item_types')
        .select('id, image_url, remark')
        .eq('name', name)
        .maybeSingle();

    final normalizedUrl = (imageUrl?.trim().isEmpty ?? true) ? null : imageUrl!.trim();
    final normalizedRemark = (remark?.trim().isEmpty ?? true) ? null : remark!.trim();

    if (existing != null && existing['id'] != null) {
      final id = existing['id'] as String;
      final currentUrl = existing['image_url'] as String?;
      final currentRemark = existing['remark'] as String?;
      final shouldUpdate =
          (normalizedUrl != null && (currentUrl == null || currentUrl.isEmpty)) ||
          (normalizedRemark != null && (currentRemark == null || currentRemark.isEmpty));
      if (shouldUpdate) {
        await _client.from('item_types').update({
          if (normalizedUrl != null) 'image_url': normalizedUrl,
          if (normalizedRemark != null) 'remark': normalizedRemark,
        }).eq('id', id);
      }
      return id;
    }

    final insert = await _client.from('item_types').insert({
      'name': name,
      'image_url': normalizedUrl,
      'remark': normalizedRemark,
      'user_id': _userId!,
    }).select('id').single();

    return insert['id'].toString();
  }

  Future<StockSheetItem> addStockSheetItem({
    required String typeName,
    String? typeImageUrl,
    required String code,
    required String finish,
    int qty10ft = 0,
    int qty12ft = 0,
    String? remark,
  }) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    final t = typeName.trim();
    final c = code.trim();
    final f = finish.trim();
    if (t.isEmpty) throw ArgumentError('Type is required');
    if (c.isEmpty) throw ArgumentError('Code is required');
    if (f.isEmpty) throw ArgumentError('Finish is required');

    final typeId = await getOrCreateTypeId(
      typeName: t,
      imageUrl: typeImageUrl,
    );

    final res = await _client.from('items_v2').insert({
      'type_id': typeId,
      'code': c,
      'finish': f,
      'qty_10ft': qty10ft,
      'qty_12ft': qty12ft,
      'remark': remark?.trim().isEmpty == true ? null : remark?.trim(),
      'user_id': _userId!,
    }).select('*, item_types(name, image_url)').single();

    return StockSheetItem.fromJson(Map<String, dynamic>.from(res));
  }

  Future<List<StockSheetItem>> getStockSheetItems() async {
    if (!_isAvailable || _userId == null) return [];
    final res = await _client
        .from('items_v2')
        .select('*, item_types(name, image_url)')
        .order('created_at', ascending: false);

    return (res as List)
        .map((e) => StockSheetItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> recordStockEntry({
    required String itemId,
    required String entryType, // 'in' | 'out'
    required int delta10ft,
    required int delta12ft,
    String? location,
    String? notes,
  }) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    if (entryType != 'in' && entryType != 'out') {
      throw ArgumentError('Invalid entry type');
    }
    if (delta10ft == 0 && delta12ft == 0) {
      throw ArgumentError('Enter at least one quantity');
    }

    final item = await _client
        .from('items_v2')
        .select('qty_10ft, qty_12ft')
        .eq('id', itemId)
        .single();

    final current10 = (item['qty_10ft'] as num?)?.toInt() ?? 0;
    final current12 = (item['qty_12ft'] as num?)?.toInt() ?? 0;

    final sign = entryType == 'in' ? 1 : -1;
    final next10 = current10 + (sign * delta10ft);
    final next12 = current12 + (sign * delta12ft);
    if (next10 < 0 || next12 < 0) {
      throw Exception('Not enough stock for this operation');
    }

    await _client.from('items_v2').update({
      'qty_10ft': next10,
      'qty_12ft': next12,
    }).eq('id', itemId);

    final enteredByName = await getMyFullName();

    await _client.from('stock_entries_v2').insert({
      'item_id': itemId,
      'entry_type': entryType,
      'delta_10ft': delta10ft,
      'delta_12ft': delta12ft,
      'entered_by_name': enteredByName,
      'location': location?.trim().isEmpty == true ? null : location?.trim(),
      'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
      'user_id': _userId!,
    });
  }

  Future<StockSheetItem?> getStockSheetItemById(String itemId) async {
    if (!_isAvailable || _userId == null) return null;
    final res = await _client
        .from('items_v2')
        .select('*, item_types(name, image_url)')
        .eq('id', itemId)
        .maybeSingle();
    if (res == null) return null;
    return StockSheetItem.fromJson(Map<String, dynamic>.from(res));
  }

  Future<List<StockEntryV2>> getStockEntries({
    int limit = 50,
    String? entryType, // 'in' | 'out'
    DateTime? since,
    String? itemId,
  }) async {
    if (!_isAvailable || _userId == null) return [];
    var q = _client
        .from('stock_entries_v2')
        .select(
          'id, item_id, entry_type, delta_10ft, delta_12ft, location, notes, created_at, items_v2(code, finish, item_types(name))',
        );

    if (entryType != null && entryType.isNotEmpty) {
      q = q.eq('entry_type', entryType);
    }
    if (itemId != null && itemId.isNotEmpty) {
      q = q.eq('item_id', itemId);
    }
    if (since != null) {
      q = q.gte('created_at', since.toUtc().toIso8601String());
    }

    final res = await q.order('created_at', ascending: false).limit(limit);
    return (res as List)
        .map((e) => StockEntryV2.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<StockEntryV2?> getStockEntryById(String entryId) async {
    if (!_isAvailable || _userId == null) return null;
    final res = await _client
        .from('stock_entries_v2')
        .select(
          'id, item_id, entry_type, delta_10ft, delta_12ft, location, notes, created_at, entered_by_name, items_v2(code, finish, item_types(name, image_url))',
        )
        .eq('id', entryId)
        .maybeSingle();
    if (res == null) return null;
    return StockEntryV2.fromJson(Map<String, dynamic>.from(res));
  }

  Future<void> updateStockEntry({
    required String entryId,
    required int newDelta10ft,
    required int newDelta12ft,
    String? newLocation,
    String? newNotes,
  }) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    final existing = await getStockEntryById(entryId);
    if (existing == null) throw Exception('Entry not found');

    if (newDelta10ft == 0 && newDelta12ft == 0) {
      throw ArgumentError('Enter at least one quantity');
    }

    final item = await _client
        .from('items_v2')
        .select('qty_10ft, qty_12ft')
        .eq('id', existing.itemId)
        .single();

    final current10 = (item['qty_10ft'] as num?)?.toInt() ?? 0;
    final current12 = (item['qty_12ft'] as num?)?.toInt() ?? 0;

    final sign = existing.entryType == 'in' ? 1 : -1;
    final diff10 = newDelta10ft - existing.delta10ft;
    final diff12 = newDelta12ft - existing.delta12ft;

    final next10 = current10 + (sign * diff10);
    final next12 = current12 + (sign * diff12);
    if (next10 < 0 || next12 < 0) {
      throw Exception('Not enough stock for this operation');
    }

    await _client.from('items_v2').update({
      'qty_10ft': next10,
      'qty_12ft': next12,
    }).eq('id', existing.itemId);

    await _client.from('stock_entries_v2').update({
      'delta_10ft': newDelta10ft,
      'delta_12ft': newDelta12ft,
      'location': newLocation?.trim().isEmpty == true ? null : newLocation?.trim(),
      'notes': newNotes?.trim().isEmpty == true ? null : newNotes?.trim(),
      'entered_by_name': await getMyFullName(),
    }).eq('id', entryId);
  }

  Future<void> deleteStockEntry(String entryId) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    final existing = await getStockEntryById(entryId);
    if (existing == null) return;

    final item = await _client
        .from('items_v2')
        .select('qty_10ft, qty_12ft')
        .eq('id', existing.itemId)
        .single();

    final current10 = (item['qty_10ft'] as num?)?.toInt() ?? 0;
    final current12 = (item['qty_12ft'] as num?)?.toInt() ?? 0;

    final sign = existing.entryType == 'in' ? 1 : -1;
    final next10 = current10 - (sign * existing.delta10ft);
    final next12 = current12 - (sign * existing.delta12ft);
    if (next10 < 0 || next12 < 0) {
      throw Exception('Cannot delete: would make stock negative');
    }

    await _client.from('items_v2').update({
      'qty_10ft': next10,
      'qty_12ft': next12,
    }).eq('id', existing.itemId);

    await _client.from('stock_entries_v2').delete().eq('id', entryId);
  }
}
