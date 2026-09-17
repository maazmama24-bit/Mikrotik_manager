import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/saved_card.dart';

// =============================================================================
// Saved Cards Storage
// =============================================================================

/// خدمة تخزين مجموعات الكروت محلياً.
class SavedCardsStorage {
  static const String _key = 'saved_card_groups_v1';

  // ===========================================================================
  // Load
  // ===========================================================================

  /// تحميل جميع المجموعات.
  Future<List<SavedGroup>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .map((item) => SavedGroup.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // Save
  // ===========================================================================

  /// حفظ جميع المجموعات (يستبدل القائمة كاملة).
  Future<void> saveAll(List<SavedGroup> groups) async {
    final prefs = await SharedPreferences.getInstance();

    final list = groups.map((g) => g.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  /// إضافة مجموعة جديدة.
  Future<void> add(SavedGroup group) async {
    final all = await loadAll();
    all.insert(0, group); // الأحدث أولاً
    await saveAll(all);
  }

  /// تحديث مجموعة موجودة.
  Future<void> update(SavedGroup group) async {
    final all = await loadAll();

    final index = all.indexWhere((g) => g.id == group.id);

    if (index == -1) return;

    all[index] = group;
    await saveAll(all);
  }

  /// حذف مجموعة بالمعرف.
  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((g) => g.id == id);
    await saveAll(all);
  }

  /// حذف جميع المجموعات.
  Future<void> deleteAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  // ===========================================================================
  // Queries
  // ===========================================================================

  /// جلب مجموعة بالمعرف.
  Future<SavedGroup?> getById(String id) async {
    final all = await loadAll();

    for (final g in all) {
      if (g.id == id) return g;
    }

    return null;
  }

  /// عدد المجموعات.
  Future<int> count() async {
    final all = await loadAll();
    return all.length;
  }

  /// إجمالي عدد الكروت في كل المجموعات.
  Future<int> totalCards() async {
    final all = await loadAll();

    int total = 0;
    for (final g in all) {
      total += g.cards.length;
    }

    return total;
  }
}