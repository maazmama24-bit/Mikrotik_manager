import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class RouterStorage {
static const String _key = 'mikrotik_routers';

final Uuid _uuid = const Uuid();

// ============================================================
// جلب جميع أجهزة MikroTik المحفوظة
// ============================================================
Future<List<Map<String, dynamic>>> getRouters() async {
final prefs = await SharedPreferences.getInstance();

final data = prefs.getStringList(_key) ?? [];

return data
    .map(
(item) => Map<String, dynamic>.from(
jsonDecode(item) as Map,
),
)
    .toList();
}

// ============================================================
// إضافة جهاز MikroTik جديد
// ============================================================
Future<void> saveRouter({
required String name,
required String host,
required String username,
required String password,
required int port,
}) async {
final prefs = await SharedPreferences.getInstance();

final routers = await getRouters();

final deviceId = 'mt_${_uuid.v4()}';

routers.add({
'deviceId': deviceId,
'name': name,
'host': host,
'username': username,
'password': password,
'port': port,

// طريقة الاتصال الحالية
'connectionMode': 'local',

// هل الجهاز مربوط بالـ Cloud؟
'cloudConnected': false,
});

final data = routers
    .map(
(router) => jsonEncode(router),
)
    .toList();

await prefs.setStringList(
_key,
data,
);
}

// ============================================================
// تحديث بيانات جهاز MikroTik
//
// نستخدم deviceId بدل index حتى لا تتأثر البيانات
// إذا تغير ترتيب الأجهزة.
// ============================================================
Future<void> updateRouter({
required String deviceId,
String? name,
String? host,
String? username,
String? password,
int? port,
String? connectionMode,
bool? cloudConnected,
}) async {
final prefs = await SharedPreferences.getInstance();

final routers = await getRouters();

final index = routers.indexWhere(
(router) => router['deviceId'] == deviceId,
);

if (index == -1) {
return;
}

final router = routers[index];

if (name != null) {
router['name'] = name;
}

if (host != null) {
router['host'] = host;
}

if (username != null) {
router['username'] = username;
}

if (password != null) {
router['password'] = password;
}

if (port != null) {
router['port'] = port;
}

if (connectionMode != null) {
router['connectionMode'] = connectionMode;
}

if (cloudConnected != null) {
router['cloudConnected'] = cloudConnected;
}

routers[index] = router;

final data = routers
    .map(
(router) => jsonEncode(router),
)
    .toList();

await prefs.setStringList(
_key,
data,
);
}

// ============================================================
// حذف جهاز حسب Index
// ============================================================
Future<void> deleteRouter(int index) async {
final prefs = await SharedPreferences.getInstance();

final routers = await getRouters();

if (index < 0 || index >= routers.length) {
return;
}

routers.removeAt(index);

final data = routers
    .map(
(router) => jsonEncode(router),
)
    .toList();

await prefs.setStringList(
_key,
data,
);
}

// ============================================================
// حذف جهاز حسب Device ID
// ============================================================
Future<void> deleteRouterById(String deviceId) async {
final prefs = await SharedPreferences.getInstance();

final routers = await getRouters();

routers.removeWhere(
(router) => router['deviceId'] == deviceId,
);

final data = routers
    .map(
(router) => jsonEncode(router),
)
    .toList();

await prefs.setStringList(
_key,
data,
);
}

// ============================================================
// البحث عن جهاز بواسطة Device ID
// ============================================================
Future<Map<String, dynamic>?> getRouterById(
String deviceId,
) async {
final routers = await getRouters();

for (final router in routers) {
if (router['deviceId'] == deviceId) {
return router;
}
}

return null;
}

// ============================================================
// مسح جميع الأجهزة
// ============================================================
Future<void> clearRouters() async {
final prefs = await SharedPreferences.getInstance();

await prefs.remove(_key);
}
}