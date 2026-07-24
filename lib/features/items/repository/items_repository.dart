import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../core/config/firebase_config.dart';
import '../models/item_models.dart';

class ItemsRepository {
  ItemsRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  bool get _isAvailable => FirebaseConfig.isConfigured;

  String? get _userId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> get _profiles =>
      _db.collection('profiles');
  CollectionReference<Map<String, dynamic>> get _itemCategories =>
      _db.collection('item_categories');
  CollectionReference<Map<String, dynamic>> get _items =>
      _db.collection('items');
  CollectionReference<Map<String, dynamic>> get _itemTypes =>
      _db.collection('item_types');
  CollectionReference<Map<String, dynamic>> get _itemsV2 =>
      _db.collection('items_v2');
  CollectionReference<Map<String, dynamic>> get _stockEntriesV2 =>
      _db.collection('stock_entries_v2');

  Map<String, dynamic> _withId(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return {'id': doc.id, ...data};
  }

  Future<String?> getMyFullName() async {
    if (!_isAvailable || _userId == null) return null;
    final displayName = _auth.currentUser?.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final snap = await _profiles.doc(_userId!).get();
    final name = snap.data()?['full_name'] as String?;
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

    final existing = await _itemCategories
        .where('user_id', isEqualTo: _userId!)
        .where('name', isEqualTo: name)
        .limit(1)
        .get();

    final normalizedUrl =
        (imageUrl?.trim().isEmpty ?? true) ? null : imageUrl!.trim();

    if (existing.docs.isNotEmpty) {
      final doc = existing.docs.first;
      final currentUrl = doc.data()['image_url'] as String?;
      if (normalizedUrl != null &&
          (currentUrl == null || currentUrl.isEmpty)) {
        await doc.reference.update({'image_url': normalizedUrl});
      }
      return doc.id;
    }

    final ref = await _itemCategories.add({
      'name': name,
      'image_url': normalizedUrl,
      'user_id': _userId!,
      'created_at': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Returns true if an item with this name already exists (case-insensitive).
  Future<bool> itemNameExists(String name) async {
    if (!_isAvailable || _userId == null) return false;
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final all = await _items.where('user_id', isEqualTo: _userId!).get();
    final lowerName = trimmed.toLowerCase();
    for (final doc in all.docs) {
      final itemName = doc.data()['name'] as String?;
      if (itemName != null && itemName.toLowerCase() == lowerName) return true;
    }
    return false;
  }

  Future<StockItem> addNormalItem({
    required String name,
    String? sku,
    int quantity = 0,
  }) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) throw ArgumentError('Item name is required');

    if (await itemNameExists(trimmedName)) {
      throw Exception(
        'An item with this name already exists (as normal or under a category).',
      );
    }

    final ref = await _items.add({
      'name': trimmedName,
      'sku': sku?.trim().isEmpty == true ? null : sku?.trim(),
      'category_id': null,
      'quantity': quantity,
      'user_id': _userId!,
      'created_at': FieldValue.serverTimestamp(),
    });
    final snap = await ref.get();
    return StockItem.fromJson(_withId(snap));
  }

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
      throw Exception(
        'An item with this name already exists (as normal or under a category).',
      );
    }

    final ref = await _items.add({
      'name': item,
      'sku': sku?.trim().isEmpty == true ? null : sku?.trim(),
      'category_id': categoryId,
      'category_name': cat,
      'quantity': quantity,
      'user_id': _userId!,
      'created_at': FieldValue.serverTimestamp(),
    });
    final snap = await ref.get();
    final map = _withId(snap);
    map['category_name'] = cat;
    return StockItem.fromJson(map);
  }

  Future<List<StockItem>> getNormalItems() async {
    if (!_isAvailable || _userId == null) return [];

    final res = await _items.where('user_id', isEqualTo: _userId!).get();
    final items = res.docs
        .map((d) => StockItem.fromJson(_withId(d)))
        .where((i) => i.isNormal)
        .toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Future<List<ItemCategory>> getCategories() async {
    if (!_isAvailable || _userId == null) return [];

    final res =
        await _itemCategories.where('user_id', isEqualTo: _userId!).get();
    final list = res.docs.map((d) => ItemCategory.fromJson(_withId(d))).toList();
    list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return list;
  }

  Future<List<StockItem>> getSpecialItems() async {
    if (!_isAvailable || _userId == null) return [];

    final res = await _items.where('user_id', isEqualTo: _userId!).get();
    final items = res.docs
        .map((d) => StockItem.fromJson(_withId(d)))
        .where((i) => !i.isNormal)
        .toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Future<List<StockItem>> getItemsByCategoryId(String categoryId) async {
    if (!_isAvailable || _userId == null) return [];

    final res = await _items
        .where('user_id', isEqualTo: _userId!)
        .where('category_id', isEqualTo: categoryId)
        .get();
    final items = res.docs.map((d) => StockItem.fromJson(_withId(d))).toList();
    items.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return items;
  }

  Future<({List<StockItem> normal, List<ItemCategory> categories})>
      getManageData() async {
    final normal = await getNormalItems();
    final categories = await getCategories();
    return (normal: normal, categories: categories);
  }

  Future<List<MapEntry<ItemCategory, List<StockItem>>>>
      getCategoriesWithItems() async {
    final categories = await getCategories();
    final result = <MapEntry<ItemCategory, List<StockItem>>>[];
    for (final cat in categories) {
      final items = await getItemsByCategoryId(cat.id);
      result.add(MapEntry(cat, items));
    }
    return result;
  }

  Exception _notConfigured() {
    return Exception('Firebase not configured or user not signed in');
  }

  static const _firestoreTimeout = Duration(seconds: 15);

  Future<T> _withTimeout<T>(Future<T> future, String action) {
    return future.timeout(
      _firestoreTimeout,
      onTimeout: () => throw Exception(
        '$action timed out. Check internet, and that Cloud Firestore is '
        'created for project kooba-stock-management.',
      ),
    );
  }

  Exception _mapFirestoreError(Object e, String action) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          return Exception(
            'Permission denied. In Firebase Console → Firestore, deploy '
            'the rules from firestore.rules (allow signed-in users).',
          );
        case 'unavailable':
          return Exception(
            'Firestore unavailable. Check internet / Firebase status.',
          );
        case 'not-found':
          return Exception(
            'Firestore database not found. Create it in Firebase Console.',
          );
        default:
          return Exception('$action failed: ${e.code} — ${e.message}');
      }
    }
    if (e is Exception) return e;
    return Exception('$action failed: $e');
  }

  // ----------------------------------------------------------------------------
  // Excel-style stock (types + items_v2)
  // ----------------------------------------------------------------------------

  Future<List<StockItemType>> getItemTypes() async {
    if (!_isAvailable || _userId == null) return [];
    try {
      final res = await _withTimeout(
        _itemTypes.orderBy('name').get(),
        'Load types',
      );
      return res.docs.map((d) => StockItemType.fromJson(_withId(d))).toList();
    } catch (e) {
      throw _mapFirestoreError(e, 'Load types');
    }
  }

  /// Stable doc id from type name (avoids a collection query that can hang).
  String _typeDocId(String name) {
    final slug = name
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'type' : slug;
  }

  Future<String> getOrCreateTypeId({
    required String typeName,
    String? imageUrl,
    String? remark,
  }) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    final name = typeName.trim();
    if (name.isEmpty) throw ArgumentError('Type name is required');

    final normalizedUrl =
        (imageUrl?.trim().isEmpty ?? true) ? null : imageUrl!.trim();
    final normalizedRemark =
        (remark?.trim().isEmpty ?? true) ? null : remark!.trim();

    final typeId = _typeDocId(name);
    final docRef = _itemTypes.doc(typeId);

    try {
      final existing = await _withTimeout(docRef.get(), 'Load type');

      if (existing.exists) {
        final data = existing.data() ?? {};
        final currentUrl = data['image_url'] as String?;
        final currentRemark = data['remark'] as String?;
      final shouldUpdate = (normalizedUrl != null &&
              normalizedUrl != currentUrl) ||
          (normalizedRemark != null &&
              (currentRemark == null || currentRemark.isEmpty));
      if (shouldUpdate) {
        await _withTimeout(
          docRef.update({
            if (normalizedUrl != null) 'image_url': normalizedUrl,
            if (normalizedRemark != null) 'remark': normalizedRemark,
          }),
          'Update type',
        );
      }
        return typeId;
      }

      await _withTimeout(
        docRef.set({
          'name': name,
          'image_url': normalizedUrl,
          'remark': normalizedRemark,
          'user_id': _userId!,
          'created_at': FieldValue.serverTimestamp(),
        }),
        'Create type',
      );
      return typeId;
    } catch (e) {
      throw _mapFirestoreError(e, 'Save type');
    }
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

    try {
      final typeId = await getOrCreateTypeId(
        typeName: t,
        imageUrl: typeImageUrl,
      );

      final typeSnap = await _withTimeout(
        _itemTypes.doc(typeId).get(),
        'Load type',
      );
      final typeData = typeSnap.data() ?? {};
      final resolvedTypeName = (typeData['name'] as String?) ?? t;
      final resolvedTypeImage =
          (typeData['image_url'] as String?) ?? typeImageUrl?.trim();
      final typeImage = (resolvedTypeImage == null || resolvedTypeImage.isEmpty)
          ? null
          : resolvedTypeImage;
      final normalizedRemark =
          remark?.trim().isEmpty == true ? null : remark?.trim();

      final docRef = _itemsV2.doc();
      await _withTimeout(
        docRef.set({
          'type_id': typeId,
          'type_name': resolvedTypeName,
          'type_image_url': typeImage,
          'code': c,
          'finish': f,
          'qty_10ft': qty10ft,
          'qty_12ft': qty12ft,
          'remark': normalizedRemark,
          'user_id': _userId!,
          'created_at': FieldValue.serverTimestamp(),
        }),
        'Save item',
      );

      // Avoid a second round-trip that can hang waiting on the server.
      return StockSheetItem(
        id: docRef.id,
        typeId: typeId,
        typeName: resolvedTypeName,
        typeImageUrl: typeImage,
        code: c,
        finish: f,
        qty10ft: qty10ft,
        qty12ft: qty12ft,
        remark: normalizedRemark,
      );
    } catch (e) {
      throw _mapFirestoreError(e, 'Save item');
    }
  }

  Future<List<StockSheetItem>> getStockSheetItems() async {
    if (!_isAvailable || _userId == null) return [];
    final res = await _itemsV2.orderBy('created_at', descending: true).get();
    final items =
        res.docs.map((d) => StockSheetItem.fromJson(_withId(d))).toList();
    return _hydrateItemImages(items);
  }

  /// Fill missing item images from `item_types` (by type id or name).
  Future<List<StockSheetItem>> _hydrateItemImages(
    List<StockSheetItem> items,
  ) async {
    if (items.isEmpty) return items;
    final needsLookup = items.any(
      (i) => i.typeImageUrl == null || i.typeImageUrl!.trim().isEmpty,
    );
    if (!needsLookup) return items;

    final typeImages = await _loadTypeImageIndex();
    if (typeImages.isEmpty) return items;

    return items.map((item) {
      final existing = item.typeImageUrl?.trim();
      if (existing != null && existing.isNotEmpty) return item;
      final url = typeImages.urlFor(
        typeId: item.typeId,
        typeName: item.typeName,
      );
      if (url == null) return item;
      return StockSheetItem(
        id: item.id,
        typeId: item.typeId,
        typeName: item.typeName,
        typeImageUrl: url,
        code: item.code,
        finish: item.finish,
        qty10ft: item.qty10ft,
        qty12ft: item.qty12ft,
        remark: item.remark,
      );
    }).toList();
  }

  Future<_TypeImageIndex> _loadTypeImageIndex() async {
    final byId = <String, String>{};
    final byName = <String, String>{};
    try {
      final snap = await _itemTypes.get();
      for (final doc in snap.docs) {
        final data = doc.data();
        final url = (data['image_url'] as String?)?.trim();
        if (url == null || url.isEmpty) continue;
        byId[doc.id] = url;
        final name = (data['name'] as String?)?.trim().toLowerCase();
        if (name != null && name.isNotEmpty) byName[name] = url;
      }
    } catch (_) {}
    return _TypeImageIndex(byId: byId, byName: byName);
  }

  /// Resolve image URLs for stock entries (entry → item → item type).
  Future<List<StockEntryV2>> enrichEntryImages(List<StockEntryV2> entries) async {
    if (entries.isEmpty) return entries;

    final itemIds =
        entries.map((e) => e.itemId).where((id) => id.isNotEmpty).toSet();
    final imageByItemId = <String, String>{};

    await Future.wait(
      itemIds.map((id) async {
        try {
          final item = await getStockSheetItemById(id);
          final url = item?.typeImageUrl?.trim();
          if (url != null && url.isNotEmpty) imageByItemId[id] = url;
        } catch (_) {}
      }),
    );

    final stillMissing = entries.any((e) {
      final fromEntry = e.typeImageUrl?.trim();
      if (fromEntry != null && fromEntry.isNotEmpty) return false;
      return imageByItemId[e.itemId] == null;
    });

    _TypeImageIndex? typeImages;
    if (stillMissing) {
      typeImages = await _loadTypeImageIndex();
    }

    return entries.map((e) {
      final fromEntry = e.typeImageUrl?.trim();
      if (fromEntry != null && fromEntry.isNotEmpty) return e;

      final fromItem = imageByItemId[e.itemId];
      if (fromItem != null && fromItem.isNotEmpty) {
        return _copyEntryWithImage(e, fromItem);
      }

      final fromType = typeImages?.urlFor(
        typeId: e.typeName != null ? _typeDocId(e.typeName!) : null,
        typeName: e.typeName,
      );
      if (fromType != null) return _copyEntryWithImage(e, fromType);

      return e;
    }).toList();
  }

  StockEntryV2 _copyEntryWithImage(StockEntryV2 e, String url) {
    return StockEntryV2(
      id: e.id,
      itemId: e.itemId,
      entryType: e.entryType,
      delta10ft: e.delta10ft,
      delta12ft: e.delta12ft,
      location: e.location,
      notes: e.notes,
      createdAt: e.createdAt,
      typeName: e.typeName,
      typeImageUrl: url,
      code: e.code,
      finish: e.finish,
      enteredByName: e.enteredByName,
    );
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

    final enteredByName = await getMyFullName();
    final itemRef = _itemsV2.doc(itemId);

    await _db.runTransaction((tx) async {
      final itemSnap = await tx.get(itemRef);
      if (!itemSnap.exists) throw Exception('Item not found');
      final item = itemSnap.data()!;
      final current10 = (item['qty_10ft'] as num?)?.toInt() ?? 0;
      final current12 = (item['qty_12ft'] as num?)?.toInt() ?? 0;

      final sign = entryType == 'in' ? 1 : -1;
      final next10 = current10 + (sign * delta10ft);
      final next12 = current12 + (sign * delta12ft);
      if (next10 < 0 || next12 < 0) {
        throw Exception('Not enough stock for this operation');
      }

      // All reads before writes (Firestore transaction rule).
      var imageUrl = (item['type_image_url'] as String?)?.trim();
      if (imageUrl == null || imageUrl.isEmpty) {
        imageUrl = (item['image_url'] as String?)?.trim();
      }
      final typeId = item['type_id'] as String?;
      final typeName = item['type_name'] as String?;
      if ((imageUrl == null || imageUrl.isEmpty) &&
          typeId != null &&
          typeId.isNotEmpty) {
        final typeSnap = await tx.get(_itemTypes.doc(typeId));
        imageUrl = (typeSnap.data()?['image_url'] as String?)?.trim();
      }
      if ((imageUrl == null || imageUrl.isEmpty) &&
          typeName != null &&
          typeName.trim().isNotEmpty) {
        final typeSnap = await tx.get(_itemTypes.doc(_typeDocId(typeName)));
        imageUrl = (typeSnap.data()?['image_url'] as String?)?.trim();
      }

      final itemUpdate = <String, dynamic>{
        'qty_10ft': next10,
        'qty_12ft': next12,
      };
      if (imageUrl != null &&
          imageUrl.isNotEmpty &&
          ((item['type_image_url'] as String?)?.trim().isEmpty ?? true)) {
        itemUpdate['type_image_url'] = imageUrl;
      }
      tx.update(itemRef, itemUpdate);

      final entryRef = _stockEntriesV2.doc();
      tx.set(entryRef, {
        'item_id': itemId,
        'entry_type': entryType,
        'delta_10ft': delta10ft,
        'delta_12ft': delta12ft,
        'entered_by_name': enteredByName,
        'location': location?.trim().isEmpty == true ? null : location?.trim(),
        'notes': notes?.trim().isEmpty == true ? null : notes?.trim(),
        'user_id': _userId!,
        'type_name': item['type_name'],
        'type_image_url':
            (imageUrl == null || imageUrl.isEmpty) ? null : imageUrl,
        'code': item['code'],
        'finish': item['finish'],
        'created_at': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<StockSheetItem?> getStockSheetItemById(String itemId) async {
    if (!_isAvailable || _userId == null) return null;
    final snap = await _itemsV2.doc(itemId).get();
    if (!snap.exists) return null;
    var item = StockSheetItem.fromJson(_withId(snap));

    // Fall back to item_types.image_url when the item doc has no denormalized URL.
    final missing =
        item.typeImageUrl == null || item.typeImageUrl!.trim().isEmpty;
    if (missing && item.typeId.isNotEmpty) {
      final typeSnap = await _itemTypes.doc(item.typeId).get();
      final typeUrl = typeSnap.data()?['image_url'] as String?;
      if (typeUrl != null && typeUrl.trim().isNotEmpty) {
        item = StockSheetItem(
          id: item.id,
          typeId: item.typeId,
          typeName: item.typeName,
          typeImageUrl: typeUrl.trim(),
          code: item.code,
          finish: item.finish,
          qty10ft: item.qty10ft,
          qty12ft: item.qty12ft,
          remark: item.remark,
        );
      }
    }
    return item;
  }

  Future<List<StockEntryV2>> getStockEntries({
    int limit = 50,
    String? entryType, // 'in' | 'out'
    DateTime? since,
    String? itemId,
  }) async {
    if (!_isAvailable || _userId == null) return [];

    try {
      // Avoid composite indexes: use single-field queries, then filter/sort in memory.
      QuerySnapshot<Map<String, dynamic>> res;
      if (itemId != null && itemId.isNotEmpty) {
        res = await _withTimeout(
          _stockEntriesV2.where('item_id', isEqualTo: itemId).get(),
          'Load entries',
        );
      } else if (entryType != null &&
          entryType.isNotEmpty &&
          since == null) {
        res = await _withTimeout(
          _stockEntriesV2.where('entry_type', isEqualTo: entryType).get(),
          'Load entries',
        );
      } else {
        final fetchLimit =
            (since != null || (entryType != null && entryType.isNotEmpty))
                ? 500
                : limit;
        res = await _withTimeout(
          _stockEntriesV2
              .orderBy('created_at', descending: true)
              .limit(fetchLimit)
              .get(),
          'Load entries',
        );
      }

      var entries =
          res.docs.map((d) => StockEntryV2.fromJson(_withId(d))).toList();

      if (entryType != null && entryType.isNotEmpty) {
        entries = entries.where((e) => e.entryType == entryType).toList();
      }
      if (since != null) {
        entries = entries
            .where((e) => !e.createdAt.isBefore(since.toUtc()))
            .toList();
      }

      entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (entries.length > limit) {
        entries = entries.take(limit).toList();
      }
      return entries;
    } catch (e) {
      throw _mapFirestoreError(e, 'Load entries');
    }
  }

  Future<StockEntryV2?> getStockEntryById(String entryId) async {
    if (!_isAvailable || _userId == null) return null;
    final snap = await _stockEntriesV2.doc(entryId).get();
    if (!snap.exists) return null;
    var entry = StockEntryV2.fromJson(_withId(snap));

    // Older entries may lack denormalized image — pull from the item.
    final imageMissing =
        entry.typeImageUrl == null || entry.typeImageUrl!.trim().isEmpty;
    if (imageMissing && entry.itemId.isNotEmpty) {
      final item = await getStockSheetItemById(entry.itemId);
      if (item != null &&
          item.typeImageUrl != null &&
          item.typeImageUrl!.trim().isNotEmpty) {
        entry = StockEntryV2(
          id: entry.id,
          itemId: entry.itemId,
          entryType: entry.entryType,
          delta10ft: entry.delta10ft,
          delta12ft: entry.delta12ft,
          location: entry.location,
          notes: entry.notes,
          createdAt: entry.createdAt,
          typeName: entry.typeName ?? item.typeName,
          typeImageUrl: item.typeImageUrl,
          code: entry.code ?? item.code,
          finish: entry.finish ?? item.finish,
          enteredByName: entry.enteredByName,
        );
      }
    }
    return entry;
  }

  int _signFor(String entryType) => entryType == 'in' ? 1 : -1;

  /// Opening stock before any logged entries = current − sum(signed deltas).
  /// (Initial qty on the item is treated as opening balance.)
  ({int q10, int q12}) _openingBalance({
    required int current10,
    required int current12,
    required List<StockEntryV2> entries,
  }) {
    var sum10 = 0;
    var sum12 = 0;
    for (final e in entries) {
      final s = _signFor(e.entryType);
      sum10 += s * e.delta10ft;
      sum12 += s * e.delta12ft;
    }
    return (q10: current10 - sum10, q12: current12 - sum12);
  }

  /// Replays every entry in time order. Fails if stock would go negative
  /// at any step — not only at the end.
  ({int q10, int q12}) _replayHistory({
    required int opening10,
    required int opening12,
    required List<StockEntryV2> chronological,
    String? editEntryId,
    int? newDelta10,
    int? newDelta12,
    String? deleteEntryId,
  }) {
    var q10 = opening10;
    var q12 = opening12;

    for (final e in chronological) {
      if (deleteEntryId != null && e.id == deleteEntryId) continue;

      final d10 =
          (editEntryId != null && e.id == editEntryId) ? newDelta10! : e.delta10ft;
      final d12 =
          (editEntryId != null && e.id == editEntryId) ? newDelta12! : e.delta12ft;
      final s = _signFor(e.entryType);
      q10 += s * d10;
      q12 += s * d12;

      if (q10 < 0 || q12 < 0) {
        throw Exception(
          'Invalid change: stock would have gone negative at some point '
          'in history. Add a new stock in/out to correct instead.',
        );
      }
    }
    return (q10: q10, q12: q12);
  }

  Future<List<StockEntryV2>> _entriesForItemChronological(String itemId) async {
    final entries = await getStockEntries(limit: 2000, itemId: itemId);
    entries.sort((a, b) {
      final byTime = a.createdAt.compareTo(b.createdAt);
      if (byTime != 0) return byTime;
      return a.id.compareTo(b.id);
    });
    return entries;
  }

  Future<void> updateStockEntry({
    required String entryId,
    required int newDelta10ft,
    required int newDelta12ft,
    String? newLocation,
    String? newNotes,
  }) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();
    if (newDelta10ft < 0 || newDelta12ft < 0) {
      throw ArgumentError('Quantities cannot be negative');
    }
    if (newDelta10ft == 0 && newDelta12ft == 0) {
      throw ArgumentError('Enter at least one quantity');
    }

    final enteredByName = await getMyFullName();
    final existing = await getStockEntryById(entryId);
    if (existing == null) throw Exception('Entry not found');

    final item = await getStockSheetItemById(existing.itemId);
    if (item == null) throw Exception('Item not found');

    final chronological =
        await _entriesForItemChronological(existing.itemId);
    final opening = _openingBalance(
      current10: item.qty10ft,
      current12: item.qty12ft,
      entries: chronological,
    );
    final finalQty = _replayHistory(
      opening10: opening.q10,
      opening12: opening.q12,
      chronological: chronological,
      editEntryId: entryId,
      newDelta10: newDelta10ft,
      newDelta12: newDelta12ft,
    );

    try {
      await _withTimeout(
        _db.runTransaction((tx) async {
          final entryRef = _stockEntriesV2.doc(entryId);
          final itemRef = _itemsV2.doc(existing.itemId);
          final entrySnap = await tx.get(entryRef);
          final itemSnap = await tx.get(itemRef);
          if (!entrySnap.exists) throw Exception('Entry not found');
          if (!itemSnap.exists) throw Exception('Item not found');

          // Guard against concurrent edits of this entry.
          final live = entrySnap.data()!;
          final live10 = (live['delta_10ft'] as num?)?.toInt() ?? 0;
          final live12 = (live['delta_12ft'] as num?)?.toInt() ?? 0;
          if (live10 != existing.delta10ft || live12 != existing.delta12ft) {
            throw Exception(
              'This entry was changed elsewhere. Refresh and try again.',
            );
          }

          tx.update(itemRef, {
            'qty_10ft': finalQty.q10,
            'qty_12ft': finalQty.q12,
          });
          tx.update(entryRef, {
            'delta_10ft': newDelta10ft,
            'delta_12ft': newDelta12ft,
            'location': newLocation?.trim().isEmpty == true
                ? null
                : newLocation?.trim(),
            'notes':
                newNotes?.trim().isEmpty == true ? null : newNotes?.trim(),
            'entered_by_name': enteredByName,
          });
        }),
        'Update entry',
      );
    } catch (e) {
      throw _mapFirestoreError(e, 'Update entry');
    }
  }

  Future<void> deleteStockEntry(String entryId) async {
    if (!_isAvailable || _userId == null) throw _notConfigured();

    final existing = await getStockEntryById(entryId);
    if (existing == null) return;

    final item = await getStockSheetItemById(existing.itemId);
    if (item == null) {
      await _stockEntriesV2.doc(entryId).delete();
      return;
    }

    final chronological =
        await _entriesForItemChronological(existing.itemId);
    final opening = _openingBalance(
      current10: item.qty10ft,
      current12: item.qty12ft,
      entries: chronological,
    );
    final finalQty = _replayHistory(
      opening10: opening.q10,
      opening12: opening.q12,
      chronological: chronological,
      deleteEntryId: entryId,
    );

    try {
      await _withTimeout(
        _db.runTransaction((tx) async {
          final entryRef = _stockEntriesV2.doc(entryId);
          final itemRef = _itemsV2.doc(existing.itemId);
          final entrySnap = await tx.get(entryRef);
          final itemSnap = await tx.get(itemRef);
          if (!entrySnap.exists) return;
          if (!itemSnap.exists) {
            tx.delete(entryRef);
            return;
          }

          final live = entrySnap.data()!;
          final live10 = (live['delta_10ft'] as num?)?.toInt() ?? 0;
          final live12 = (live['delta_12ft'] as num?)?.toInt() ?? 0;
          if (live10 != existing.delta10ft || live12 != existing.delta12ft) {
            throw Exception(
              'This entry was changed elsewhere. Refresh and try again.',
            );
          }

          tx.update(itemRef, {
            'qty_10ft': finalQty.q10,
            'qty_12ft': finalQty.q12,
          });
          tx.delete(entryRef);
        }),
        'Delete entry',
      );
    } catch (e) {
      throw _mapFirestoreError(e, 'Delete entry');
    }
  }
}

class _TypeImageIndex {
  final Map<String, String> byId;
  final Map<String, String> byName;

  const _TypeImageIndex({required this.byId, required this.byName});

  bool get isEmpty => byId.isEmpty && byName.isEmpty;

  String? urlFor({String? typeId, String? typeName}) {
    final id = typeId?.trim();
    if (id != null && id.isNotEmpty) {
      final fromId = byId[id];
      if (fromId != null && fromId.isNotEmpty) return fromId;
    }
    final name = typeName?.trim().toLowerCase();
    if (name != null && name.isNotEmpty) {
      final fromName = byName[name];
      if (fromName != null && fromName.isNotEmpty) return fromName;
    }
    return null;
  }
}
