import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/card_template.dart';

// =============================================================================
// Template Storage
// =============================================================================

/// خدمة تخزين قوالب الطباعة محلياً.
class TemplateStorage {
  static const String _key = 'card_templates_v1';

  // ===========================================================================
  // Load
  // ===========================================================================

  /// تحميل جميع القوالب.
  Future<List<CardTemplate>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);

    if (raw == null || raw.isEmpty) {
      return [];
    }

    try {
      final decoded = jsonDecode(raw) as List<dynamic>;

      return decoded
          .map((item) => CardTemplate.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  // ===========================================================================
  // Save
  // ===========================================================================

  /// حفظ جميع القوالب (يستبدل القائمة كاملة).
  Future<void> saveAll(List<CardTemplate> templates) async {
    final prefs = await SharedPreferences.getInstance();

    final list = templates.map((t) => t.toJson()).toList();
    await prefs.setString(_key, jsonEncode(list));
  }

  /// إضافة قالب جديد.
  Future<void> add(CardTemplate template) async {
    final all = await loadAll();
    all.add(template);
    await saveAll(all);
  }

  /// تحديث قالب موجود.
  Future<void> update(CardTemplate template) async {
    final all = await loadAll();

    final index = all.indexWhere((t) => t.id == template.id);

    if (index == -1) return;

    all[index] = template;
    await saveAll(all);
  }

  /// حذف قالب بالمعرف.
  Future<void> delete(String id) async {
    final all = await loadAll();
    all.removeWhere((t) => t.id == id);
    await saveAll(all);
  }

  // ===========================================================================
  // Queries
  // ===========================================================================

  /// جلب قالب واحد بالمعرف.
  Future<CardTemplate?> getById(String id) async {
    final all = await loadAll();

    for (final t in all) {
      if (t.id == id) return t;
    }

    return null;
  }

  /// عدد القوالب.
  Future<int> count() async {
    final all = await loadAll();
    return all.length;
  }

  /// هل التخزين فارغ؟
  Future<bool> isEmpty() async {
    final all = await loadAll();
    return all.isEmpty;
  }
}