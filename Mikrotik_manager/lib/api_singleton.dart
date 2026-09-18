import 'dart:async';
import 'package:flutter/material.dart';
import 'mikrotik_api.dart';

// =============================================================================
// ApiSingleton — إدارة مركزية للاتصال
// =============================================================================

/// مدير الاتصال المركزي مع الراوتر.
///
/// يستخدم نمط Singleton لضمان أن جميع الصفحات تستخدم
/// نفس الاتصال، وتُشارك نفس الحالة.
class ApiSingleton extends ChangeNotifier {
  // ===========================================================================
  // Singleton
  // ===========================================================================

  ApiSingleton._internal();

  static final ApiSingleton _instance = ApiSingleton._internal();

  factory ApiSingleton() => _instance;

  // ===========================================================================
  // API Instance
  // ===========================================================================

  MikroTikApi? _api;
  MikroTikApi? get api => _api;

  // ===========================================================================
  // Connection State
  // ===========================================================================

  bool _isConnected = false;
  bool get isConnected => _isConnected;

  bool _isConnecting = false;
  bool get isConnecting => _isConnecting;

  bool _isReconnecting = false;
  bool get isReconnecting => _isReconnecting;

  String? _lastError;
  String? get lastError => _lastError;

  /// معلومات الراوتر الحالي.
  Map<String, dynamic>? _currentRouter;
  Map<String, dynamic>? get currentRouter => _currentRouter;

  // ===========================================================================
  // Health Check
  // ===========================================================================

  Timer? _healthCheckTimer;

  /// عدد محاولات إعادة الاتصال.
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 3;

  // ===========================================================================
  // Callbacks للاستماع
  // ===========================================================================

  /// يُستدعى عند انقطاع الاتصال.
  VoidCallback? onDisconnected;

  /// يُستدعى عند نجاح إعادة الاتصال.
  VoidCallback? onReconnected;

  // ===========================================================================
  // Connect
  // ===========================================================================

  /// الاتصال بالراوتر.
  Future<bool> connect({
    required String host,
    required String username,
    required String password,
    int port = 8728,
    Map<String, dynamic>? routerInfo,
  }) async {
    // إلغاء محاولة سابقة
    if (_isConnecting) return false;

    _isConnecting = true;
    _lastError = null;
    notifyListeners();

    try {
      // إغلاق الاتصال السابق إن وُجد
      await disconnect(silent: true);

      final api = MikroTikApi();

      final connected = await api.connect(
        host: host,
        username: username,
        password: password,
        port: port,
      );

      if (!connected) {
        _isConnecting = false;
        _isConnected = false;
        _lastError = api.lastError ?? 'فشل الاتصال بالراوتر';
        notifyListeners();
        return false;
      }

      _api = api;
      _isConnected = true;
      _isConnecting = false;
      _reconnectAttempts = 0;

      if (routerInfo != null) {
        _currentRouter = routerInfo;
      }

      notifyListeners();

      // بدء المراقبة
      _startHealthCheck();

      return true;
    } catch (e) {
      _isConnecting = false;
      _isConnected = false;
      _lastError = e.toString();
      _api = null;
      notifyListeners();
      return false;
    }
  }

  // ===========================================================================
  // Disconnect
  // ===========================================================================

  Future<void> disconnect({bool silent = false}) async {
    _healthCheckTimer?.cancel();
    _healthCheckTimer = null;

    _api?.disconnect();
    _api = null;

    _isConnected = false;
    _isConnecting = false;
    _isReconnecting = false;

    if (!silent) {
      _currentRouter = null;
      _lastError = null;
      _reconnectAttempts = 0;
      notifyListeners();
    }
  }

  // ===========================================================================
  // Health Check
  // ===========================================================================

  void _startHealthCheck() {
    _healthCheckTimer?.cancel();

    _healthCheckTimer = Timer.periodic(
      const Duration(seconds: 15),
          (timer) {
        if (!_isConnected) return;
        _performHealthCheck();
      },
    );
  }

  Future<void> _performHealthCheck() async {
    if (_api == null || !_isConnected) return;

    try {
      await _api!.getRouterInfo();
    } catch (e) {
      // فشل الاتصال
      await _handleConnectionLoss();
    }
  }

  // ===========================================================================
  // Connection Loss Handling
  // ===========================================================================

  /// يُستدعى عندما يُكتشف انقطاع الاتصال.
  Future<void> _handleConnectionLoss() async {
    if (!_isConnected) return;

    _isConnected = false;
    notifyListeners();

    // إشعار المستمعين
    onDisconnected?.call();

    // محاولة إعادة اتصال تلقائي
    await _attemptReconnect();
  }

  /// محاولة إعادة الاتصال.
  Future<void> _attemptReconnect() async {
    if (_currentRouter == null) return;

    _isReconnecting = true;
    notifyListeners();

    final host = _currentRouter!['host']?.toString();
    final username = _currentRouter!['username']?.toString();
    final password = _currentRouter!['password']?.toString();
    final port = int.tryParse(
      _currentRouter!['port']?.toString() ?? '',
    ) ??
        8728;

    if (host == null || username == null || password == null) {
      _isReconnecting = false;
      notifyListeners();
      return;
    }

    // محاولة فورية أولاً
    final firstSuccess = await _tryReconnect(
      host: host,
      username: username,
      password: password,
      port: port,
    );

    if (firstSuccess) {
      _isReconnecting = false;
      notifyListeners();
      onReconnected?.call();
      return;
    }

    // محاولات لاحقة بانتظار
    _reconnectAttempts = 1;

    while (_reconnectAttempts < _maxReconnectAttempts &&
        _isConnected == false) {
      _reconnectAttempts++;

      final waitSeconds = _reconnectAttempts == 2
          ? 5
          : _reconnectAttempts == 3
          ? 10
          : 30;

      // عدّاد انتظار
      for (int i = waitSeconds; i > 0; i--) {
        if (_isConnected) {
          _isReconnecting = false;
          notifyListeners();
          return;
        }
        await Future.delayed(const Duration(seconds: 1));
      }

      final success = await _tryReconnect(
        host: host,
        username: username,
        password: password,
        port: port,
      );

      if (success) {
        _isReconnecting = false;
        notifyListeners();
        onReconnected?.call();
        return;
      }
    }

    _isReconnecting = false;
    notifyListeners();
  }

  Future<bool> _tryReconnect({
    required String host,
    required String username,
    required String password,
    required int port,
  }) async {
    try {
      final api = MikroTikApi();

      final connected = await api.connect(
        host: host,
        username: username,
        password: password,
        port: port,
      );

      if (!connected) {
        api.disconnect();
        return false;
      }

      _api = api;
      _isConnected = true;
      _reconnectAttempts = 0;
      _isReconnecting = false;
      notifyListeners();

      _startHealthCheck();

      return true;
    } catch (e) {
      return false;
    }
  }

  /// إعادة محاولة يدوية.
  Future<bool> manualReconnect() async {
    _reconnectAttempts = 0;
    await _attemptReconnect();
    return _isConnected;
  }

  // ===========================================================================
  // Utils
  // ===========================================================================

  /// التحقق من الاتصال قبل أي عملية.
  bool ensureConnected() {
    return _isConnected && _api != null;
  }

  /// فصل عند اكتشاف خطأ في عملية.
  Future<void> handleOperationError(String error) async {
    _lastError = error;
    await _handleConnectionLoss();
  }
}