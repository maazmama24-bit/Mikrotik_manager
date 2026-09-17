import 'mikrotik_api.dart';

/// Repository لإدارة مستخدمي Hotspot.
///
/// لا يحتوي على أي بيانات خاصة براوتر معين.
/// يعمل كطبقة بين واجهة Flutter و MikroTikApi.
///
/// يوفّر:
/// - Cache محلي مع مراعاة الراوتر
/// - Pagination
/// - بحث محلي
/// - مزامنة عند التعديل والحذف
class HotspotUsersRepository {
  HotspotUsersRepository(this.api);

  final MikroTikApi api;

  // ===========================================================================
  // Configuration
  // ===========================================================================

  /// حجم الصفحة الافتراضي.
  static const int defaultPageSize = 100;

  /// الحد الأقصى للكاش في الذاكرة.
  /// عند تجاوزه، يتم الاحتفاظ بأحدث العناصر فقط.
  static const int maxCacheSize = 5000;

  // ===========================================================================
  // Cache
  // ===========================================================================

  List<Map<String, String>> _cachedUsers = [];

  String? _lastProfile;
  String? _lastSearch;

  /// Device ID الخاص بالراوتر المرتبط بالكاش.
  /// يُستخدم لمنع تسرّب البيانات بين الراوترات.
  String? _cachedRouterId;

  /// وقت آخر تحديث للكاش.
  DateTime? _lastCacheTime;

  // ===========================================================================
  // Load Users
  // ===========================================================================

  /// تحميل المستخدمين من الراوتر.
  ///
  /// - إذا كان `forceRefresh` = false وكانت نفس الاستعلامات، يعيد الكاش.
  /// - إذا تغير الراوتر، يمسح الكاش تلقائياً.
  Future<List<Map<String, String>>> loadUsers({
    String? profile,
    String? search,
    bool forceRefresh = false,
    String? routerId,
  }) async {
    // إذا تغيّر الراوتر، امسح الكاش
    if (routerId != null && routerId != _cachedRouterId) {
      clearCache();
      _cachedRouterId = routerId;
    }

    final normalizedProfile = _normalize(profile);
    final normalizedSearch = _normalize(search);

    final sameQuery = _lastProfile == normalizedProfile &&
        _lastSearch == normalizedSearch;

    if (!forceRefresh && sameQuery && _cachedUsers.isNotEmpty) {
      return List<Map<String, String>>.from(_cachedUsers);
    }

    final users = await api.getHotspotUsers(
      profile: normalizedProfile,
      username: normalizedSearch,
    );

    // طبّق الحد الأقصى
    if (users.length > maxCacheSize) {
      _cachedUsers = List<Map<String, String>>.from(
        users.take(maxCacheSize),
      );
    } else {
      _cachedUsers = List<Map<String, String>>.from(users);
    }

    _lastProfile = normalizedProfile;
    _lastSearch = normalizedSearch;
    _lastCacheTime = DateTime.now();

    return List<Map<String, String>>.from(_cachedUsers);
  }

  /// تحميل جميع المستخدمين (بدون فلترة).
  Future<List<Map<String, String>>> loadAllUsers({
    String? profile,
    bool forceRefresh = true,
    String? routerId,
  }) async {
    if (routerId != null && routerId != _cachedRouterId) {
      clearCache();
      _cachedRouterId = routerId;
    }

    final normalizedProfile = _normalize(profile);

    final sameQuery =
        _lastProfile == normalizedProfile && _lastSearch == null;

    if (!forceRefresh && sameQuery && _cachedUsers.isNotEmpty) {
      return List<Map<String, String>>.from(_cachedUsers);
    }

    final users = await api.getAllHotspotUsers(
      profile: normalizedProfile,
    );

    if (users.length > maxCacheSize) {
      _cachedUsers = List<Map<String, String>>.from(
        users.take(maxCacheSize),
      );
    } else {
      _cachedUsers = List<Map<String, String>>.from(users);
    }

    _lastProfile = normalizedProfile;
    _lastSearch = null;
    _lastCacheTime = DateTime.now();

    return List<Map<String, String>>.from(_cachedUsers);
  }

  // ===========================================================================
  // Pagination
  // ===========================================================================

  /// إرجاع صفحة من الكاش.
  List<Map<String, String>> getPage({
    int page = 0,
    int pageSize = defaultPageSize,
  }) {
    if (page < 0) page = 0;

    if (pageSize <= 0) pageSize = defaultPageSize;

    if (_cachedUsers.isEmpty) return [];

    final start = page * pageSize;

    if (start >= _cachedUsers.length) return [];

    final end = (start + pageSize > _cachedUsers.length)
        ? _cachedUsers.length
        : start + pageSize;

    return List<Map<String, String>>.from(
      _cachedUsers.sublist(start, end),
    );
  }

  int get totalCachedUsers => _cachedUsers.length;

  int get totalPages {
    if (_cachedUsers.isEmpty) return 0;

    return (_cachedUsers.length / defaultPageSize).ceil();
  }

  // ===========================================================================
  // Single User
  // ===========================================================================

  Future<Map<String, String>?> getUser(String id) async {
    return api.getHotspotUserById(id);
  }

  /// البحث في الكاش عن مستخدم بالـ ID.
  Map<String, String>? getCachedUserById(String id) {
    for (final user in _cachedUsers) {
      if (user['.id'] == id) {
        return user;
      }
    }

    return null;
  }

  // ===========================================================================
  // Update User
  // ===========================================================================

  Future<void> updateUser({
    required String id,
    String? name,
    String? password,
    String? profile,
    String? macAddress,
    String? limitUptime,
    String? limitBytesTotal,
    String? comment,
    String? address,
    String? routes,
    String? email,
    String? server,
    bool? disabled,
  }) async {
    // 1. حدّث على الراوتر
    await api.updateHotspotUser(
      id: id,
      name: name,
      password: password,
      profile: profile,
      macAddress: macAddress,
      limitUptime: limitUptime,
      limitBytesTotal: limitBytesTotal,
      comment: comment,
      address: address,
      routes: routes,
      email: email,
      server: server,
      disabled: disabled,
    );

    // 2. جهّز القيم المحدثة للكاش
    final values = <String, String>{};

    _addValue(values, 'name', name);
    _addValue(values, 'password', password);
    _addValue(values, 'profile', profile);
    _addValue(values, 'mac-address', macAddress);
    _addValue(values, 'limit-uptime', limitUptime);
    _addValue(values, 'limit-bytes-total', limitBytesTotal);
    _addValue(values, 'comment', comment);
    _addValue(values, 'address', address);
    _addValue(values, 'routes', routes);
    _addValue(values, 'email', email);
    _addValue(values, 'server', server);

    if (disabled != null) {
      values['disabled'] = disabled ? 'yes' : 'no';
    }

    // 3. حدّث الكاش
    _updateCachedUser(id: id, values: values);
  }

  // ===========================================================================
  // Add User
  // ===========================================================================

  /// إضافة مستخدم جديد على الراوتر.
  ///
  /// تعيد الـ ID الخاص بالمستخدم المضاف.
  Future<String?> addUser({
    required String name,
    required String password,
    required String profile,
    String? macAddress,
    String? limitUptime,
    String? limitBytesTotal,
    String? comment,
    String? address,
    String? routes,
    String? email,
    String? server,
    bool disabled = false,
  }) async {
    final id = await api.addHotspotUser(
      name: name,
      password: password,
      profile: profile,
      macAddress: macAddress,
      limitUptime: limitUptime,
      limitBytesTotal: limitBytesTotal,
      comment: comment,
      address: address,
      routes: routes,
      email: email,
      server: server,
      disabled: disabled,
    );

    // أضف إلى الكاش مباشرة
    if (id != null && id.isNotEmpty) {
      _cachedUsers.insert(0, {
        '.id': id,
        'name': name,
        'password': password,
        'profile': profile,
        'mac-address': ?macAddress,
        'limit-uptime': ?limitUptime,
        'limit-bytes-total': ?limitBytesTotal,
        'comment': ?comment,
        'address': ?address,
        'routes': ?routes,
        'email': ?email,
        'server': ?server,
        'disabled': disabled ? 'yes' : 'no',
      });
    }

    return id;
  }

  // ===========================================================================
  // Delete User
  // ===========================================================================

  Future<void> deleteUser(String id) async {
    // 1. احذف من الراوتر
    await api.deleteHotspotUser(id);

    // 2. احذف من الكاش
    _cachedUsers.removeWhere(
          (user) => user['.id'] == id,
    );
  }

  // ===========================================================================
  // Search in Cache
  // ===========================================================================

  List<Map<String, String>> searchCached(String text) {
    final query = text.trim().toLowerCase();

    if (query.isEmpty) {
      return List<Map<String, String>>.from(_cachedUsers);
    }

    return _cachedUsers.where((user) {
      final name = (user['name'] ?? '').toLowerCase();
      final comment = (user['comment'] ?? '').toLowerCase();
      final mac = (user['mac-address'] ?? '').toLowerCase();

      return name.contains(query) ||
          comment.contains(query) ||
          mac.contains(query);
    }).toList();
  }

  // ===========================================================================
  // Cache Management
  // ===========================================================================

  List<Map<String, String>> get cachedUsers {
    return List<Map<String, String>>.from(_cachedUsers);
  }

  /// حجم الكاش الحالي.
  int get cacheSize => _cachedUsers.length;

  /// وقت آخر تحديث.
  DateTime? get lastCacheTime => _lastCacheTime;

  /// الراوتر المرتبط بالكاش.
  String? get cachedRouterId => _cachedRouterId;

  /// مسح الكاش بالكامل.
  void clearCache() {
    _cachedUsers = [];
    _lastProfile = null;
    _lastSearch = null;
    _cachedRouterId = null;
    _lastCacheTime = null;
  }

  /// مسح الكاش فقط إذا تغيّر الراوتر.
  void clearIfRouterChanged(String? routerId) {
    if (routerId != _cachedRouterId) {
      clearCache();
      _cachedRouterId = routerId;
    }
  }

  // ===========================================================================
  // Cache Internals
  // ===========================================================================

  void _updateCachedUser({
    required String id,
    required Map<String, String> values,
  }) {
    final index = _cachedUsers.indexWhere(
          (user) => user['.id'] == id,
    );

    if (index == -1) return;

    _cachedUsers[index] = {
      ..._cachedUsers[index],
      ...values,
    };
  }

  void _addValue(
      Map<String, String> map,
      String key,
      String? value,
      ) {
    if (value != null) {
      map[key] = value;
    }
  }

  String? _normalize(String? value) {
    if (value == null) return null;

    final trimmed = value.trim();

    if (trimmed.isEmpty) return null;

    return trimmed;
  }
}