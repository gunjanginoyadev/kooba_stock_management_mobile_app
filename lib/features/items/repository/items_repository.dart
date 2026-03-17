import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/supabase_config.dart';
import '../models/item_models.dart';

class ItemsRepository {
  ItemsRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  bool get _isAvailable => SupabaseConfig.isConfigured;

  String? get _userId => _client.auth.currentUser?.id;

  /// Get or create category by name for current user. Returns category id.
  Future<String> getOrCreateCategoryId(String categoryName) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    final name = categoryName.trim();
    if (name.isEmpty) throw ArgumentError('Category name is required');

    final existing = await _client
        .from('item_categories')
        .select('id')
        .eq('user_id', _userId!)
        .eq('name', name)
        .maybeSingle();

    if (existing != null && existing['id'] != null) {
      return existing['id'] as String;
    }

    final insert = await _client.from('item_categories').insert({
      'name': name,
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
    String? sku,
    int quantity = 0,
  }) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    final cat = categoryName.trim();
    final item = itemName.trim();
    if (cat.isEmpty) throw ArgumentError('Category name is required');
    if (item.isEmpty) throw ArgumentError('Item name is required');

    final categoryId = await getOrCreateCategoryId(cat);

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
}
