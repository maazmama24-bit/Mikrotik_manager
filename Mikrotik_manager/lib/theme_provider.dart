import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// مزوّد الوضع المظلم للتطبيق.
///
/// المسؤوليات:
/// - تخزين ThemeMode الحالي
/// - حفظه في SharedPreferences
/// - إشعار الواجهة عند التغيير
class ThemeProvider extends ChangeNotifier {
  static const String _key = 'theme_mode';

  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  bool get isDark => _themeMode == ThemeMode.dark;

  bool get isLight => _themeMode == ThemeMode.light;

  bool get isSystem => _themeMode == ThemeMode.system;

  /// تحميل الوضع المحفوظ من التخزين.
  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString(_key);

      switch (saved) {
        case 'light':
          _themeMode = ThemeMode.light;
          break;
        case 'dark':
          _themeMode = ThemeMode.dark;
          break;
        case 'system':
        default:
          _themeMode = ThemeMode.system;
          break;
      }

      notifyListeners();
    } catch (_) {
      // في حال الفشل، نبقى على الوضع الافتراضي
    }
  }

  /// تغيير الوضع وحفظه.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;

    _themeMode = mode;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, mode.name);
    } catch (_) {
      // تجاهل أخطاء الحفظ
    }
  }

  /// تبديل سريع بين فاتح/مظلم.
  Future<void> toggle() async {
    if (_themeMode == ThemeMode.dark) {
      await setThemeMode(ThemeMode.light);
    } else {
      await setThemeMode(ThemeMode.dark);
    }
  }
}