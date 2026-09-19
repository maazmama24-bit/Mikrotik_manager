import 'package:flutter/material.dart';
import 'dart:async';
import 'mikrotik_api.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'router_storage.dart';
import 'add_hotspot_pages.dart';
import 'templates_page.dart';
import 'saved_cards_page.dart';
import 'mikrotik_users_page.dart';
import 'backup_restore_page.dart';
import 'dhcp_dns_page.dart';
import 'interfaces_page.dart';
import 'vpn_page.dart';
import 'hotspot_setup_page.dart';
import 'firewall_page.dart';
import 'hotspot_users_page.dart';
import 'user_manager_sessions_page.dart';
import 'user_manager_users_page.dart';
import 'user_manager_hub_page.dart';
import 'api_singleton.dart';

void main() {
  runApp(const MikrotikManagerApp());
}

class MikrotikManagerApp extends StatelessWidget {
  const MikrotikManagerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MikroTik Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.blue,
      ),
      locale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const HomePage(),
    );
  }
}

// =============================================================================
// Home
// =============================================================================

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final RouterStorage _storage = RouterStorage();

  Future<void> _openSavedRouters() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SavedRoutersPage(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _addRouter() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const RouterSettingsPage(),
      ),
    );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MikroTik Manager'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _storage.getRouters(),
        builder: (context, snapshot) {
          final routers = snapshot.data ?? [];

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.router,
                    size: 80,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'MikroTik Manager',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    routers.isEmpty
                        ? 'لم تتم إضافة أي راوتر بعد'
                        : 'عدد الراوترات المحفوظة: ${routers.length}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _addRouter,
                      icon: const Icon(Icons.add),
                      label: const Text('إضافة راوتر'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _openSavedRouters,
                      icon: const Icon(Icons.router),
                      label: const Text('الراوترات المحفوظة'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// =============================================================================
// Saved Routers
// =============================================================================
class SavedRoutersPage extends StatefulWidget {
  const SavedRoutersPage({super.key});

  @override
  State<SavedRoutersPage> createState() => _SavedRoutersPageState();
}

class _SavedRoutersPageState extends State<SavedRoutersPage> {
  final RouterStorage _storage = RouterStorage();

  List<Map<String, dynamic>> _routers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRouters();
  }

  Future<void> _loadRouters() async {
    final routers = await _storage.getRouters();

    if (!mounted) return;

    setState(() {
      _routers = routers;
      _loading = false;
    });
  }

  Future<void> _deleteRouter(int index) async {
    final name = _routers[index]['name']?.toString() ?? 'MikroTik';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الراوتر'),
        content: Text('هل تريد حذف الراوتر "$name" نهائياً؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _storage.deleteRouter(index);

    if (!mounted) return;

    await _loadRouters();
  }

  void _openRouter(Map<String, dynamic> router) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouterDashboardPage(
          router: router,
        ),
      ),
    );
  }

  String _connectionMode(Map<String, dynamic> router) {
    final mode = router['connectionMode']?.toString();

    if (mode == 'cloud') {
      return 'Cloud / Remote';
    }

    return 'Local';
  }

  bool _isCloudConnected(Map<String, dynamic> router) {
    return router['cloudConnected'] == true;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('الراوترات (${_routers.length})'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loadRouters,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _routers.isEmpty
          ? _buildEmpty()
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _routers.length,
        itemBuilder: (context, index) {
          return _buildRouterCard(_routers[index], index);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const RouterSettingsPage(),
            ),
          );

          if (!mounted) return;

          _loadRouters();
        },
        icon: const Icon(Icons.add),
        label: const Text('إضافة راوتر'),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.router_outlined,
                size: 60,
                color: Colors.blue.shade400,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد راوترات محفوظة',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'اضغط "إضافة راوتر" لإضافة أول راوتر',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRouterCard(Map<String, dynamic> router, int index) {
    final name = router['name']?.toString() ?? 'MikroTik';
    final host = router['host']?.toString() ?? '-';
    final deviceId = router['deviceId']?.toString() ?? '-';
    final cloudConnected = _isCloudConnected(router);
    final mode = _connectionMode(router);
    final isCloud = mode == 'Cloud / Remote';

    // لون البطاقة حسب النوع
    final baseColor = isCloud ? Colors.purple : Colors.blue;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: baseColor.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: baseColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _openRouter(router),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // ========================================
                // الرأس: الأيقونة + الاسم + الوضع
                // ========================================
                Row(
                  children: [
                    // أيقونة الراوتر
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            baseColor.withValues(alpha: 0.7),
                            baseColor,
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.router,
                        color: Colors.white,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // الاسم + IP
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (cloudConnected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    Icons.cloud_done,
                                    size: 16,
                                    color: Colors.green.shade600,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Icon(
                                Icons.lan,
                                size: 12,
                                color: Colors.grey.shade600,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                host,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade700,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // قائمة
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'open':
                            _openRouter(router);
                            break;
                          case 'delete':
                            _deleteRouter(index);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'open',
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new, size: 20),
                              SizedBox(width: 8),
                              Text('فتح'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete,
                                size: 20,
                                color: Colors.red,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'حذف',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(
                  height: 1,
                  color: Colors.grey.shade200,
                ),
                const SizedBox(height: 10),

                // ========================================
                // التفاصيل السفلية
                // ========================================
                Row(
                  children: [
                    // الوضع
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: baseColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isCloud ? Icons.cloud : Icons.lan,
                            size: 12,
                            color: baseColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            isCloud ? 'سحابي' : 'محلي',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: baseColor,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Device ID
                    Expanded(
                      child: Row(
                        children: [
                          Icon(
                            Icons.fingerprint,
                            size: 12,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              deviceId.length > 18
                                  ? '${deviceId.substring(0, 18)}...'
                                  : deviceId,
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey.shade600,
                                fontFamily: 'monospace',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // سهم الفتح
                    Icon(
                      Icons.chevron_left,
                      color: baseColor.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Router Dashboard
// =============================================================================
class RouterDashboardPage extends StatefulWidget {
  final Map<String, dynamic> router;

  const RouterDashboardPage({
    super.key,
    required this.router,
  });

  @override
  State<RouterDashboardPage> createState() => _RouterDashboardPageState();
}

class _RouterDashboardPageState extends State<RouterDashboardPage> {
  final ApiSingleton _singleton = ApiSingleton();

  MikroTikApi? get _api => _singleton.api;

  bool _connecting = false;
  bool _connected = false;
  bool _readingData = false;
  bool _reconnecting = false;

  Map<String, String>? _routerInfo;

  String? _lastUpdate;

  @override
  void initState() {
    super.initState();

    // إذا كان Singleton متصلاً بنفس الراوتر، استعد الحالة
    final currentHost = widget.router['host']?.toString();
    final cachedHost = _singleton.currentRouter?['host']?.toString();

    if (_singleton.isConnected && currentHost == cachedHost) {
      _connected = true;
      _readInfo();
    }

    _singleton.addListener(_onSingletonChange);
  }

  @override
  void dispose() {
    _singleton.removeListener(_onSingletonChange);
    super.dispose();
  }

  void _onSingletonChange() {
    if (!mounted) return;

    // فقدان الاتصال
    if (!_singleton.isConnected && _connected) {
      setState(() {
        _connected = false;
        _reconnecting = true;
        _routerInfo = null;
        _lastUpdate = null;
      });

      _showMessage(
        'انقطع الاتصال — جاري إعادة الاتصال تلقائياً',
        isError: true,
      );
    }

    // نجاح إعادة الاتصال
    if (_singleton.isConnected && !_connected) {
      setState(() {
        _connected = true;
        _reconnecting = false;
      });

      _showMessage('✅ تم إعادة الاتصال بنجاح');
      _readInfo();
    }

    // فشل إعادة الاتصال
    if (!_singleton.isConnected && _reconnecting) {
      setState(() {
        _reconnecting = _singleton.isReconnecting;
      });
    }
  }

  String _currentTime() {
    final now = DateTime.now();

    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final second = now.second.toString().padLeft(2, '0');

    return '$hour:$minute:$second';
  }

  String _value(String key) {
    return _routerInfo?[key] ?? 'غير معروف';
  }

  Future<void> _readInfo() async {
    if (_api == null) return;

    try {
      final info = await _api!.getRouterInfo();

      if (!mounted) return;

      setState(() {
        _routerInfo = info;
        _lastUpdate = _currentTime();
      });
    } catch (e) {
      // تجاهل
    }
  }

  Future<bool> _connect() async {
    if (_connecting) return false;

    setState(() => _connecting = true);

    try {
      final connected = await _singleton.connect(
        host: widget.router['host'].toString(),
        username: widget.router['username'].toString(),
        password: widget.router['password'].toString(),
        port: int.tryParse(widget.router['port'].toString()) ?? 8728,
        routerInfo: widget.router,
      );

      if (!connected) {
        if (mounted) setState(() => _connected = false);

        _showMessage(
          _singleton.lastError ?? 'فشل الاتصال بالراوتر',
          isError: true,
        );

        return false;
      }

      if (mounted) setState(() => _connected = true);

      return true;
    } catch (e) {
      if (mounted) setState(() => _connected = false);

      _showMessage('فشل الاتصال: $e', isError: true);

      return false;
    } finally {
      if (mounted) setState(() => _connecting = false);
    }
  }

  Future<void> _connectAndReadInfo() async {
    if (_connecting || _connected) return;

    final connected = await _connect();

    if (!connected) return;

    try {
      final info = await _api!.getRouterInfo();

      if (!mounted) return;

      setState(() {
        _routerInfo = info;
        _lastUpdate = _currentTime();
      });

      _showMessage('تم الاتصال بالراوتر بنجاح ✅');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _connected = false;
        _routerInfo = null;
        _lastUpdate = null;
      });

      _showMessage(
        'تم الاتصال لكن فشل قراءة معلومات الراوتر: $e',
        isError: true,
      );
    }
  }
  /// فصل الاتصال يدوياً.
  void _forceDisconnect(String message) {
    if (!mounted) return;

    _singleton.disconnect();

    setState(() {
      _connected = false;
      _routerInfo = null;
      _lastUpdate = null;
    });

    _showMessage(message);
  }

  Future<void> _updateData() async {
    if (!_connected || _readingData) return;
    if (_api == null) return;

    setState(() => _readingData = true);

    try {
      final info = await _api!.getRouterInfo();

      if (!mounted) return;

      setState(() {
        _routerInfo = info;
        _lastUpdate = _currentTime();
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage('فشل تحديث البيانات', isError: true);
    } finally {
      if (mounted) setState(() => _readingData = false);
    }
  }

  Map<String, dynamic> get _router => widget.router;

  /// شاشة اختيار نوع الكروت (Hotspot / User Manager).
  Future<void> _openUsers({String? profile}) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => const _CardsManagerTypeDialog(),
    );

    if (!mounted || choice == null) return;

    if (choice == 'hotspot') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HotspotUsersPage(
            api: _api!,
            host: _router['host'].toString(),
            username: _router['username'].toString(),
            password: _router['password'].toString(),
            port: int.tryParse(_router['port'].toString()) ?? 8728,
            profile: profile,
          ),
        ),
      );
    } else if (choice == 'user_manager') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserManagerHubPage(api: _api!),
        ),
      );
    }
  }

  /// شاشة اختيار نوع توليد الكروت.
  Future<void> _openGenerateCards() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (_) => const _GenerateCardsTypeDialog(),
    );

    if (!mounted || choice == null) return;

    if (choice == 'hotspot') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => HotspotCardsHubPage(
            api: _api!,
            host: _router['host'].toString(),
            username: _router['username'].toString(),
            password: _router['password'].toString(),
            port: int.tryParse(_router['port'].toString()) ?? 8728,
          ),
        ),
      );
      if (mounted) setState(() {});
    } else if (choice == 'user_manager') {
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserManagerHubPage(
            api: _api!,
            singleTab: 'cards',
          ),
        ),
      );
      if (mounted) setState(() {});
    }
  }
  Future<void> _openProfiles() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotspotProfilesPage(
          api: _api!,
          host: _router['host'].toString(),
          username: _router['username'].toString(),
          password: _router['password'].toString(),
          port: int.tryParse(_router['port'].toString()) ?? 8728,
        ),
      ),
    );
  }

  Future<void> _openConnectedUsers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectedUsersPage(
          api: _api!,
          host: _router['host'].toString(),
          username: _router['username'].toString(),
          password: _router['password'].toString(),
          port: int.tryParse(_router['port'].toString()) ?? 8728,
        ),
      ),
    );
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => RouterSettingsHubPage(
          router: widget.router,
          api: _api!,
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  // ===========================================================================
  // Action Button (Grid)
  // ===========================================================================

  Widget _actionButton({
    required IconData icon,
    required String title,
    required VoidCallback? onPressed,
    Color? color,
  }) {
    final enabled = onPressed != null;
    final baseColor = color ?? Colors.blue;

    return Material(
      color: enabled
          ? baseColor.withValues(alpha: 0.08)
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: enabled
                      ? baseColor.withValues(alpha: 0.15)
                      : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 24,
                  color: enabled ? baseColor : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: enabled ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Stat Card (معلومات الراوتر)
  // ===========================================================================

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    Color color = Colors.blue,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Info Row
  // ===========================================================================

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final routerName = widget.router['name']?.toString() ?? 'MikroTik';
    final deviceId = widget.router['deviceId']?.toString() ?? '-';
    final connectionMode =
        widget.router['connectionMode']?.toString() ?? 'local';

    return Scaffold(
      appBar: AppBar(
        title: Text(routerName),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'كروتي المحفوظة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const SavedCardsPage(),
                ),
              );
            },
            icon: const Icon(Icons.folder_special),
          ),
          IconButton(
            tooltip: 'قوالب الطباعة',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const TemplatesPage(),
                ),
              );
            },
            icon: const Icon(Icons.dashboard_customize),
          ),
          IconButton(
            tooltip: 'الإعدادات',
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_connected) await _updateData();
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            // =========================================================
            // بطاقة الاتصال
            // =========================================================
            _buildConnectionCard(connectionMode),

            const SizedBox(height: 12),

            // =========================================================
            // الإجراءات السريعة
            // =========================================================
            const Text(
              '⚡ الإجراءات السريعة',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // ======================================================
            // الصف الأول: إدارة الكروت + توليد + القوالب
            // ======================================================
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.people,
                    title: 'إدارة الكروت',
                    color: Colors.blue,
                    onPressed: _connected ? () => _openUsers() : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    icon: Icons.auto_awesome,
                    title: 'توليد الكروت',
                    color: Colors.deepOrange,
                    onPressed: _connected ? _openGenerateCards : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ======================================================
            // الصف الثاني: القوالب + بروفايلات Hotspot
            // ======================================================
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.dashboard_customize,
                    title: 'القوالب',
                    color: Colors.teal,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TemplatesPage(),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    icon: Icons.category,
                    title: 'بروفايلات Hotspot',
                    color: Colors.purple,
                    onPressed: _connected ? _openProfiles : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ======================================================
            // الصف الثالث: المتصلون + طباعة الكروت
            // ======================================================
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.wifi,
                    title: 'المتصلون الآن',
                    color: Colors.green,
                    onPressed: _connected ? _openConnectedUsers : null,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _actionButton(
                    icon: Icons.print,
                    title: 'كروتي المحفوظة',
                    color: Colors.orange,
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SavedCardsPage(),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // ======================================================
            // الصف الرابع: إعدادات الراوتر
            // ======================================================
            Row(
              children: [
                Expanded(
                  child: _actionButton(
                    icon: Icons.settings,
                    title: 'إعدادات الراوتر',
                    color: Colors.grey,
                    onPressed: _openSettings,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),
            // =========================================================
            // معلومات الراوتر
            // =========================================================
            const Text(
              '📊 معلومات الراوتر',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.4,
              children: [
                _statCard(
                  icon: Icons.badge,
                  label: 'Identity',
                  value: _value('identity'),
                  color: Colors.blue,
                ),
                _statCard(
                  icon: Icons.system_update,
                  label: 'Version',
                  value: _value('version'),
                  color: Colors.purple,
                ),
                _statCard(
                  icon: Icons.memory,
                  label: 'Board',
                  value: _value('board'),
                  color: Colors.teal,
                ),
                _statCard(
                  icon: Icons.developer_board,
                  label: 'Architecture',
                  value: _value('architecture'),
                  color: Colors.indigo,
                ),
                _statCard(
                  icon: Icons.speed,
                  label: 'CPU',
                  value: _value('cpu'),
                  color: Colors.orange,
                ),
                _statCard(
                  icon: Icons.show_chart,
                  label: 'CPU Load',
                  value: '${_value('cpuLoad')}%',
                  color: Colors.red,
                ),
                _statCard(
                  icon: Icons.timer,
                  label: 'Uptime',
                  value: _value('uptime'),
                  color: Colors.green,
                ),
                _statCard(
                  icon: Icons.memory,
                  label: 'Free Memory',
                  value: _value('freeMemory'),
                  color: Colors.cyan,
                ),
                _statCard(
                  icon: Icons.storage,
                  label: 'Total Memory',
                  value: _value('totalMemory'),
                  color: Colors.brown,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // =========================================================
            // بيانات الاتصال
            // =========================================================
            const Text(
              '🔌 بيانات الاتصال',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    _infoRow(
                      Icons.lan,
                      'العنوان',
                      widget.router['host']?.toString() ?? '',
                    ),
                    const Divider(height: 1),
                    _infoRow(
                      Icons.person,
                      'المستخدم',
                      widget.router['username']?.toString() ?? '',
                    ),
                    const Divider(height: 1),
                    _infoRow(
                      Icons.numbers,
                      'المنفذ',
                      widget.router['port']?.toString() ?? '8728',
                    ),
                    const Divider(height: 1),
                    _infoRow(
                      Icons.fingerprint,
                      'Device ID',
                      deviceId,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // =========================================================
            // زر قطع الاتصال
            // =========================================================
            if (_connected)
              SizedBox(
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('قطع الاتصال'),
                        content: const Text(
                          'هل تريد قطع الاتصال بالراوتر؟\n\n'
                              'لن تفقد البيانات المحفوظة.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text('إلغاء'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            child: const Text('قطع الاتصال'),
                          ),
                        ],
                      ),
                    );

                    if (confirmed != true) return;

                    _forceDisconnect('تم قطع الاتصال 🔌');
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(
                      color: Colors.red,
                      width: 1.5,
                    ),
                  ),
                  icon: const Icon(Icons.link_off),
                  label: const Text(
                    'قطع الاتصال بالراوتر',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // Connection Card
  // ===========================================================================

  Widget _buildConnectionCard(String connectionMode) {
    return Card(
      elevation: 3,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: _connected
                ? [Colors.green.shade400, Colors.green.shade600]
                : [Colors.grey.shade400, Colors.grey.shade600],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _connected ? Icons.check_circle : Icons.cloud_off,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _connected ? 'متصل الآن' : 'غير متصل',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    connectionMode == 'cloud'
                        ? 'اتصال عن بُعد / Cloud'
                        : 'اتصال محلي',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 13,
                    ),
                  ),
                  if (_lastUpdate != null)
                    Text(
                      'آخر تحديث: $_lastUpdate',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 11,
                      ),
                    ),
                ],
              ),
            ),
            if (!_connected)
              FilledButton.icon(
                onPressed: _connecting ? null : _connectAndReadInfo,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.green.shade700,
                ),
                icon: _connecting
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green,
                  ),
                )
                    : const Icon(Icons.link),
                label: Text(
                  _connecting ? 'جاري الاتصال' : 'اتصال',
                ),
              )
            else
              IconButton(
                onPressed: _readingData ? null : _updateData,
                tooltip: 'تحديث',
                icon: _readingData
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(
                  Icons.refresh,
                  color: Colors.white,
                  size: 28,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Hotspot Profiles
// =============================================================================

class HotspotProfilesPage extends StatefulWidget {
  final MikroTikApi api;
  final String host;
  final String username;
  final String password;
  final int port;

  const HotspotProfilesPage({
    super.key,
    required this.api,
    required this.host,
    required this.username,
    required this.password,
    required this.port,
  });

  @override
  State<HotspotProfilesPage> createState() => _HotspotProfilesPageState();
}

class _HotspotProfilesPageState extends State<HotspotProfilesPage> {
  late final MikroTikApi _api;

  List<Map<String, String>> _profiles = [];

  // إحصائيات لكل بروفايل: name -> { count, online }
  final Map<String, int> _profileCardCount = {};
  final Map<String, int> _profileOnlineCount = {};

  bool _loading = true;
  bool _loadingStats = false;
  String? _error;

  @override
  void initState() {
    super.initState();

    _api = widget.api;

    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final profiles = await _api.getHotspotProfiles();

      if (!mounted) return;

      setState(() {
        _profiles = profiles;
        _loading = false;
      });

      // تحميل الإحصائيات في الخلفية
      _loadStatistics();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// جلب عدد الكروت والمتصلين لكل بروفايل.
  Future<void> _loadStatistics() async {
    if (_loadingStats || _profiles.isEmpty) return;

    setState(() => _loadingStats = true);

    try {
      // جلب جميع الكروت
      final allUsers = await _api.getAllHotspotUsers();

      if (!mounted) return;

      // جلب المتصلين
      final active = await _api.getConnectedUsers();

      if (!mounted) return;

      // حساب العدد لكل بروفايل
      final counts = <String, int>{};
      for (final user in allUsers) {
        final p = user['profile'] ?? '';
        counts[p] = (counts[p] ?? 0) + 1;
      }

      final onlineCounts = <String, int>{};
      for (final user in active) {
        // نبحث عن البروفايل من الكرت الأصلي
        final name = user['user'] ?? user['name'] ?? '';

        for (final u in allUsers) {
          if (u['name'] == name) {
            final p = u['profile'] ?? '';
            onlineCounts[p] = (onlineCounts[p] ?? 0) + 1;
            break;
          }
        }
      }

      setState(() {
        _profileCardCount
          ..clear()
          ..addAll(counts);

        _profileOnlineCount
          ..clear()
          ..addAll(onlineCounts);

        _loadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingStats = false);
    }
  }

  String _value(Map<String, String> profile, String key) {
    final value = profile[key];

    if (value == null || value.isEmpty) {
      return '-';
    }

    return value;
  }


  Future<void> _openProfile(Map<String, String> profile) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotspotProfileDetailsPage(
          api: _api,
          host: widget.host,
          username: widget.username,
          password: widget.password,
          port: widget.port,
          profile: profile,
        ),
      ),
    );

    if (mounted) _loadProfiles();
  }

  Future<void> _openProfileUsers(Map<String, String> profile) async {
    final profileName = profile['name']?.trim() ?? '';

    if (profileName.isEmpty) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotspotUsersPage(
          api: _api,
          host: widget.host,
          username: widget.username,
          password: widget.password,
          port: widget.port,
          profile: profileName,
        ),
      ),
    );

    if (mounted) _loadStatistics();
  }

  Future<void> _deleteProfile(Map<String, String> profile) async {
    final id = profile['.id'];
    final name = profile['name'] ?? '';

    if (id == null) return;

    if (name == 'default') {
      _showMessage('لا يمكن حذف default', isError: true);
      return;
    }

    final cardCount = _profileCardCount[name] ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف البروفايل'),
        content: Text(
          'هل تريد حذف البروفايل "$name"؟\n\n'
              '${cardCount > 0 ? "⚠️ يحتوي على $cardCount كرت!\n\n" : ""}'
              'لا يمكن التراجع.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.deleteHotspotProfile(id);
      if (!mounted) return;
      _showMessage('تم حذف البروفايل ✅');
      await _loadProfiles();
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل: $e', isError: true);
    }
  }

  Future<void> _addProfile() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddHotspotProfilePage(api: _api),
      ),
    );

    if (result == true) {
      await _loadProfiles();
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hotspot Profiles (${_profiles.length})',
        ),
        actions: [
          if (_loadingStats)
            const Padding(
              padding: EdgeInsets.all(14),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
            ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loading ? null : _loadProfiles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addProfile,
        icon: const Icon(Icons.add),
        label: const Text('إضافة بروفايل'),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 15),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: _loadProfiles,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_profiles.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.category, size: 60, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'لا توجد Hotspot Profiles',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadProfiles,
      child: ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _profiles.length,
        itemBuilder: (context, index) {
          final profile = _profiles[index];
          return _buildProfileCard(profile);
        },
      ),
    );
  }

  Widget _buildProfileCard(Map<String, String> profile) {
    final name = profile['name'] ?? '';
    final addressPool = _value(profile, 'address-pool');
    final rateLimit = _value(profile, 'rate-limit');
    final sessionTimeout = _value(profile, 'session-timeout');
    final idleTimeout = _value(profile, 'idle-timeout');
    final sharedUsers = _value(profile, 'shared-users');

    final cardCount = _profileCardCount[name] ?? 0;
    final onlineCount = _profileOnlineCount[name] ?? 0;
    final isDefault = name == 'default';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _openProfile(profile),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ========== الرأس ==========
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDefault
                          ? Colors.orange.shade100
                          : Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isDefault ? Icons.star : Icons.category,
                      color: isDefault ? Colors.orange : Colors.blue,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (isDefault)
                              const Padding(
                                padding: EdgeInsets.only(right: 4),
                                child: Icon(
                                  Icons.verified,
                                  size: 14,
                                  color: Colors.orange,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pool: $addressPool',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // ========== الإحصائيات ==========
              Row(
                children: [
                  _statChip(
                    icon: Icons.credit_card,
                    value: '$cardCount',
                    label: 'كرت',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 6),
                  _statChip(
                    icon: Icons.wifi,
                    value: '$onlineCount',
                    label: 'متصل',
                    color: onlineCount > 0 ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 6),
                  _statChip(
                    icon: Icons.speed,
                    value: _shortRate(rateLimit),
                    label: 'سرعة',
                    color: Colors.purple,
                  ),
                ],
              ),

              const Divider(height: 14),

              // ========== التفاصيل المختصرة ==========
              Row(
                children: [
                  Expanded(
                    child: _miniRow(
                      Icons.timer,
                      'Session',
                      sessionTimeout,
                    ),
                  ),
                  Expanded(
                    child: _miniRow(
                      Icons.hourglass_empty,
                      'Idle',
                      idleTimeout,
                    ),
                  ),
                  Expanded(
                    child: _miniRow(
                      Icons.people,
                      'Shared',
                      sharedUsers,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // ========== الأزرار ===========
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _openProfileUsers(profile),
                      icon: const Icon(Icons.people, size: 16),
                      label: const Text(
                        'الكروت',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _openProfile(profile),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.blue,
                      ),
                      icon: const Icon(Icons.edit, size: 16),
                      label: const Text(
                        'تعديل',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                  if (!isDefault) ...[
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => _deleteProfile(profile),
                      tooltip: 'حذف',
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _shortRate(String raw) {
    if (raw == '-' || raw.isEmpty) return '-';
    final parts = raw.split('/');
    if (parts.isNotEmpty) return parts[0];
    return raw;
  }

  Widget _statChip({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _miniRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 12, color: Colors.grey),
        const SizedBox(width: 3),
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Hotspot Profile Details
// =============================================================================

class HotspotProfileDetailsPage extends StatefulWidget {
  final MikroTikApi api;

  final String host;
  final String username;
  final String password;
  final int port;

  final Map<String, String> profile;

  const HotspotProfileDetailsPage({
    super.key,
    required this.api,
    required this.host,
    required this.username,
    required this.password,
    required this.port,
    required this.profile,
  });

  @override
  State<HotspotProfileDetailsPage> createState() =>
      _HotspotProfileDetailsPageState();
}

class _HotspotProfileDetailsPageState
    extends State<HotspotProfileDetailsPage> {
  late final MikroTikApi _api;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _addressPoolController;
  late final TextEditingController _sharedUsersController;
  late final TextEditingController _rateLimitController;
  late final TextEditingController _sessionTimeoutController;
  late final TextEditingController _idleTimeoutController;
  late final TextEditingController _keepaliveTimeoutController;
  late final TextEditingController _statusAutorefreshController;
  late final TextEditingController _queueTypeController;
  late final TextEditingController _parentQueueController;
  late final TextEditingController _onLoginController;
  late final TextEditingController _onLogoutController;

  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _api = widget.api;

    _nameController = TextEditingController(
      text: widget.profile['name'] ?? '',
    );

    _addressPoolController = TextEditingController(
      text: widget.profile['address-pool'] ?? '',
    );

    _sharedUsersController = TextEditingController(
      text: widget.profile['shared-users'] ?? '',
    );

    _rateLimitController = TextEditingController(
      text: widget.profile['rate-limit'] ?? '',
    );

    _sessionTimeoutController = TextEditingController(
      text: widget.profile['session-timeout'] ?? '',
    );

    _idleTimeoutController = TextEditingController(
      text: widget.profile['idle-timeout'] ?? '',
    );

    _keepaliveTimeoutController = TextEditingController(
      text: widget.profile['keepalive-timeout'] ?? '',
    );

    _statusAutorefreshController = TextEditingController(
      text: widget.profile['status-autorefresh'] ?? '',
    );

    _queueTypeController = TextEditingController(
      text: widget.profile['queue-type'] ?? '',
    );

    _parentQueueController = TextEditingController(
      text: widget.profile['parent-queue'] ?? '',
    );

    _onLoginController = TextEditingController(
      text: widget.profile['on-login'] ?? '',
    );

    _onLogoutController = TextEditingController(
      text: widget.profile['on-logout'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressPoolController.dispose();
    _sharedUsersController.dispose();
    _rateLimitController.dispose();
    _sessionTimeoutController.dispose();
    _idleTimeoutController.dispose();
    _keepaliveTimeoutController.dispose();
    _statusAutorefreshController.dispose();
    _queueTypeController.dispose();
    _parentQueueController.dispose();
    _onLoginController.dispose();
    _onLogoutController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final id = widget.profile['.id'];

    if (id == null || id.isEmpty) {
      _showMessage(
        'لم يتم العثور على ID الخاص بالبروفايل',
        isError: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _api.updateHotspotProfile(
        id: id,
        name: _nameController.text.trim(),
        addressPool: _addressPoolController.text.trim(),
        sharedUsers: _sharedUsersController.text.trim(),
        rateLimit: _rateLimitController.text.trim(),
        sessionTimeout: _sessionTimeoutController.text.trim(),
        idleTimeout: _idleTimeoutController.text.trim(),
        keepaliveTimeout: _keepaliveTimeoutController.text.trim(),
        statusAutorefresh:
        _statusAutorefreshController.text.trim(),
        queueType: _queueTypeController.text.trim(),
        parentQueue: _parentQueueController.text.trim(),
        onLogin: _onLoginController.text.trim(),
        onLogout: _onLogoutController.text.trim(),
      );

      if (!mounted) return;

      _showMessage('تم حفظ البروفايل بنجاح ✅');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'فشل حفظ البروفايل: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profileName = widget.profile['name'] ?? 'Profile';

    return Scaffold(
      appBar: AppBar(
        title: Text(profileName),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'إعدادات Hotspot Profile',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _field(
              label: 'Name',
              controller: _nameController,
            ),
            _field(
              label: 'Address Pool',
              controller: _addressPoolController,
            ),
            _field(
              label: 'Shared Users',
              controller: _sharedUsersController,
            ),
            _field(
              label: 'Rate Limit',
              controller: _rateLimitController,
              hint: 'مثال: 2M/2M',
            ),
            _field(
              label: 'Session Timeout',
              controller: _sessionTimeoutController,
              hint: 'مثال: 1h',
            ),
            _field(
              label: 'Idle Timeout',
              controller: _idleTimeoutController,
              hint: 'مثال: 5m',
            ),
            _field(
              label: 'Keepalive Timeout',
              controller: _keepaliveTimeoutController,
              hint: 'مثال: 2m',
            ),
            _field(
              label: 'Status Autorefresh',
              controller: _statusAutorefreshController,
            ),
            _field(
              label: 'Queue Type',
              controller: _queueTypeController,
            ),
            _field(
              label: 'Parent Queue',
              controller: _parentQueueController,
            ),
            _field(
              label: 'On Login',
              controller: _onLoginController,
              maxLines: 4,
            ),
            _field(
              label: 'On Logout',
              controller: _onLogoutController,
              maxLines: 4,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? 'جاري الحفظ...' : 'حفظ التغييرات',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


// =============================================================================
// Hotspot User Edit
// =============================================================================

class HotspotUserEditPage extends StatefulWidget {
  final MikroTikApi api;

  final String host;
  final String username;
  final String password;
  final int port;

  final Map<String, String> user;

  const HotspotUserEditPage({
    super.key,
    required this.api,
    required this.host,
    required this.username,
    required this.password,
    required this.port,
    required this.user,
  });

  @override
  State<HotspotUserEditPage> createState() =>
      _HotspotUserEditPageState();
}

class _HotspotUserEditPageState extends State<HotspotUserEditPage> {
  late final MikroTikApi _api;

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _profileController;
  late final TextEditingController _macAddressController;
  late final TextEditingController _limitUptimeController;
  late final TextEditingController _limitBytesController;
  late final TextEditingController _commentController;
  late final TextEditingController _addressController;
  late final TextEditingController _routesController;
  late final TextEditingController _emailController;
  late final TextEditingController _serverController;

  bool _disabled = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _api = widget.api;

    _nameController = TextEditingController(
      text: widget.user['name'] ?? '',
    );

    _passwordController = TextEditingController(
      text: widget.user['password'] ?? '',
    );

    _profileController = TextEditingController(
      text: widget.user['profile'] ?? '',
    );

    _macAddressController = TextEditingController(
      text: widget.user['mac-address'] ?? '',
    );

    _limitUptimeController = TextEditingController(
      text: widget.user['limit-uptime'] ?? '',
    );

    _limitBytesController = TextEditingController(
      text: widget.user['limit-bytes-total'] ?? '',
    );

    _commentController = TextEditingController(
      text: widget.user['comment'] ?? '',
    );

    _addressController = TextEditingController(
      text: widget.user['address'] ?? '',
    );

    _routesController = TextEditingController(
      text: widget.user['routes'] ?? '',
    );

    _emailController = TextEditingController(
      text: widget.user['email'] ?? '',
    );

    _serverController = TextEditingController(
      text: widget.user['server'] ?? '',
    );

    _disabled = widget.user['disabled'] == 'yes';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _profileController.dispose();
    _macAddressController.dispose();
    _limitUptimeController.dispose();
    _limitBytesController.dispose();
    _commentController.dispose();
    _addressController.dispose();
    _routesController.dispose();
    _emailController.dispose();
    _serverController.dispose();

    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final id = widget.user['.id'];

    if (id == null || id.isEmpty) {
      _showMessage(
        'لم يتم العثور على ID الخاص بالمستخدم',
        isError: true,
      );
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      await _api.updateHotspotUser(
        id: id,
        name: _nameController.text.trim(),
        password: _passwordController.text,
        profile: _profileController.text.trim(),
        macAddress: _macAddressController.text.trim(),
        limitUptime: _limitUptimeController.text.trim(),
        limitBytesTotal: _limitBytesController.text.trim(),
        comment: _commentController.text.trim(),
        address: _addressController.text.trim(),
        routes: _routesController.text.trim(),
        email: _emailController.text.trim(),
        server: _serverController.text.trim(),
        disabled: _disabled,
      );

      if (!mounted) return;

      _showMessage('تم حفظ المستخدم بنجاح ✅');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'فشل حفظ المستخدم: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscureText = false,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentName = widget.user['name'] ?? 'Hotspot User';

    return Scaffold(
      appBar: AppBar(
        title: Text(currentName),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'تعديل مستخدم Hotspot',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _field(
              label: 'Username',
              controller: _nameController,
            ),
            _field(
              label: 'Password',
              controller: _passwordController,
              obscureText: true,
            ),
            _field(
              label: 'Profile',
              controller: _profileController,
            ),
            _field(
              label: 'MAC Address',
              controller: _macAddressController,
            ),
            _field(
              label: 'Limit Uptime',
              controller: _limitUptimeController,
              hint: 'مثال: 1d',
            ),
            _field(
              label: 'Limit Bytes Total',
              controller: _limitBytesController,
              hint: 'مثال: 2147483648',
            ),
            _field(
              label: 'Comment',
              controller: _commentController,
              maxLines: 3,
            ),
            _field(
              label: 'Address',
              controller: _addressController,
            ),
            _field(
              label: 'Routes',
              controller: _routesController,
              maxLines: 3,
            ),
            _field(
              label: 'Email',
              controller: _emailController,
            ),
            _field(
              label: 'Server',
              controller: _serverController,
            ),
            Card(
              child: SwitchListTile(
                title: const Text('Disabled'),
                subtitle: Text(
                  _disabled ? 'المستخدم معطّل' : 'المستخدم فعّال',
                ),
                value: _disabled,
                onChanged: _saving
                    ? null
                    : (value) {
                  setState(() {
                    _disabled = value;
                  });
                },
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? 'جاري الحفظ...' : 'حفظ التغييرات',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Connected Hotspot Users
// =============================================================================
class ConnectedUsersPage extends StatefulWidget {
  final MikroTikApi api;

  final String host;
  final String username;
  final String password;
  final int port;

  const ConnectedUsersPage({
    super.key,
    required this.api,
    required this.host,
    required this.username,
    required this.password,
    required this.port,
  });

  @override
  State<ConnectedUsersPage> createState() => _ConnectedUsersPageState();
}

class _ConnectedUsersPageState extends State<ConnectedUsersPage> {
  late final MikroTikApi _api;

  final TextEditingController _searchController = TextEditingController();
  bool _showSearch = false;
  List<Map<String, String>> _activeUsers = [];

  bool _loading = true;
  bool _readingHosts = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.api;
    _loadActiveUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadActiveUsers() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await _api.getConnectedUsers();

      if (!mounted) return;

      setState(() {
        _activeUsers = users;
        _loading = false;
      });

      // جلب أسماء الأجهزة في الخلفية
      _enrichWithHostNames();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  /// جلب أسماء الأجهزة من Hotspot Hosts وربطها بالمتصلين.
  Future<void> _enrichWithHostNames() async {
    if (_readingHosts || _activeUsers.isEmpty) return;

    setState(() => _readingHosts = true);

    try {
      final hosts = await _api.getHotspotHosts();

      if (!mounted) return;

      // نبني خريطة: mac -> host-name
      final macToName = <String, String>{};
      for (final host in hosts) {
        final mac = (host['mac-address'] ?? '').toLowerCase();
        final name = host['host-name'] ?? '';
        if (mac.isNotEmpty && name.isNotEmpty) {
          macToName[mac] = name;
        }
      }

      // نحدّث القائمة
      for (final user in _activeUsers) {
        final mac = (user['mac-address'] ?? '').toLowerCase();
        final name = macToName[mac];
        if (name != null && name.isNotEmpty) {
          user['_host-name'] = name;
        }
      }

      if (!mounted) return;
      setState(() => _readingHosts = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _readingHosts = false);
    }
  }

  Future<void> _disconnectUser(Map<String, String> user) async {
    final id = user['.id'];

    if (id == null || id.isEmpty) {
      _showMessage('لم يتم العثور على Active ID', isError: true);
      return;
    }

    final name = user['user'] ?? user['name'] ?? 'المستخدم';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('فصل المستخدم'),
          content: Text('هل تريد فصل "$name" من الجلسة الحالية؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('فصل'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _api.disconnectHotspotUser(id);

      if (!mounted) return;

      setState(() {
        _activeUsers.removeWhere((item) => item['.id'] == id);
      });

      _showMessage('تم فصل المستخدم بنجاح ✅');
    } catch (e) {
      _showMessage('فشل فصل المستخدم: $e', isError: true);
    }
  }

  Future<void> _deleteUser(Map<String, String> activeUser) async {
    final activeId = activeUser['.id'];
    final username = activeUser['user'] ?? activeUser['name'];

    if (username == null || username.isEmpty) {
      _showMessage('لم يتم العثور على اسم المستخدم', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف الكرت'),
          content: Text(
            'سيتم فصل المستخدم ثم حذف الكرت "$username" نهائيًا.\n\n'
                'هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('فصل وحذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      if (activeId != null && activeId.isNotEmpty) {
        try {
          await _api.disconnectHotspotUser(activeId);
        } catch (_) {}
      }

      final users = await _api.findHotspotUsersByName(username);

      if (users.isEmpty) {
        throw Exception(
          'تم فصل الجلسة، لكن لم يتم العثور على كرت المستخدم للحذف',
        );
      }

      final String userId = users.first;

      if (userId.isEmpty) {
        throw Exception('لم يتم العثور على User ID');
      }

      await _api.deleteHotspotUser(userId);

      if (!mounted) return;

      setState(() {
        _activeUsers.removeWhere((item) => item['.id'] == activeId);
      });

      _showMessage('تم فصل وحذف الكرت بنجاح ✅');
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل حذف الكرت: $e', isError: true);
    }
  }
  List<Map<String, String>> get _filteredUsers {
    if (_searchController.text.trim().isEmpty) {
      return _activeUsers;
    }

    final query = _searchController.text.trim().toLowerCase();

    return _activeUsers.where((user) {
      final name = (user['user'] ?? user['name'] ?? '').toLowerCase();
      final address = (user['address'] ?? '').toLowerCase();
      final mac = (user['mac-address'] ?? '').toLowerCase();
      final hostName = (user['_host-name'] ?? '').toLowerCase();

      return name.contains(query) ||
          address.contains(query) ||
          mac.contains(query) ||
          hostName.contains(query);
    }).toList();
  }


  int get _totalBytesIn {
    int total = 0;
    for (final u in _activeUsers) {
      total += int.tryParse(u['bytes-in'] ?? '0') ?? 0;
    }
    return total;
  }

  int get _totalBytesOut {
    int total = 0;
    for (final u in _activeUsers) {
      total += int.tryParse(u['bytes-out'] ?? '0') ?? 0;
    }
    return total;
  }

  String _value(Map<String, String> user, String key) {
    final value = user[key];

    if (value == null || value.isEmpty) {
      return '-';
    }

    return value;
  }

  String _formatBytes(String value) {
    final bytes = int.tryParse(value);
    if (bytes == null || bytes <= 0) return '0 B';

    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('🟢 النشطون الآن (${_activeUsers.length})'),
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _showSearch = !_showSearch;
                if (!_showSearch) {
                  _searchController.clear();
                }
              });
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            onPressed: _loading ? null : _loadActiveUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
        body: Column(
            children: [
        if (_showSearch && !_loading && _error == null)
        Padding(
        padding: const EdgeInsets.all(8),
    child: TextField(
    controller: _searchController,
    autofocus: true,
    decoration: InputDecoration(
    hintText: 'ابحث...',
    prefixIcon: const Icon(Icons.search),
    suffixIcon: IconButton(
    icon: const Icon(Icons.clear),
    onPressed: () {
    _searchController.clear();
    setState(() {});
    },
    ),
    border: const OutlineInputBorder(),
    isDense: true,
    ),
    onChanged: (_) => setState(() {}),
    ),
    ),
    Expanded(
    child: _loading
    ? const Center(child: CircularProgressIndicator())
        : _error != null
          ? Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline,
                size: 60,
                color: Colors.red,
              ),
              const SizedBox(height: 15),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: _loadActiveUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      )
          : _activeUsers.isEmpty
          ? const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.wifi_off, size: 60),
            SizedBox(height: 12),
            Text(
              'لا يوجد مستخدمون نشطون الآن',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      )
        : ListView(
    padding: const EdgeInsets.all(8),
    children: [
    _statsCard(),
    ..._filteredUsers.map((user) {

          final name = user['user'] ?? user['name'] ?? '-';
          final address = _value(user, 'address');
          final mac = _value(user, 'mac-address');
          final uptime = _value(user, 'uptime');
          final bytesIn = _value(user, 'bytes-in');
          final bytesOut = _value(user, 'bytes-out');
          final server = _value(user, 'server');
          final hostName = user['_host-name'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 6),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 0,
              ),
              childrenPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                radius: 18,
                backgroundColor: Colors.green,
                child: Icon(
                  Icons.wifi,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          hostName.isNotEmpty
                              ? hostName
                              : name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (hostName.isNotEmpty)
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontFamily: 'monospace',
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '$address • $uptime',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              children: [
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      _detailRow('اسم الكرت', name),
                      if (hostName.isNotEmpty)
                        _detailRow('اسم الجهاز', hostName),
                      _detailRow('IP', address),
                      _detailRow('MAC', mac),
                      _detailRow('المدة', uptime),
                      _detailRow('Server', server),
                      _detailRow(
                        'Bytes In',
                        _formatBytes(bytesIn),
                      ),
                      _detailRow(
                        'Bytes Out',
                        _formatBytes(bytesOut),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () =>
                                  _disconnectUser(user),
                              icon: const Icon(
                                Icons.link_off,
                                size: 18,
                              ),
                              label: const Text('فصل'),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () =>
                                  _deleteUser(user),
                              style: FilledButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              icon: const Icon(
                                Icons.delete,
                                size: 18,
                              ),
                              label: const Text('حذف الكرت'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
    }),
    ],
    ),
    ),
            ],
        ),
    );
  }

  Widget _statsCard() {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [Colors.green.shade400, Colors.green.shade600],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.wifi,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'المتصلون الآن',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        '${_activeUsers.length}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _statsItem(
                      Icons.download,
                      'تنزيل',
                      _formatBytes(_totalBytesIn.toString()),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                  Expanded(
                    child: _statsItem(
                      Icons.upload,
                      'رفع',
                      _formatBytes(_totalBytesOut.toString()),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statsItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
// =============================================================================
// Hotspot Cards Hub Page - شاشة وسيطة
// =============================================================================

class HotspotCardsHubPage extends StatelessWidget {
  final MikroTikApi api;
  final String host;
  final String username;
  final String password;
  final int port;
  final String? defaultProfile;

  const HotspotCardsHubPage({
    super.key,
    required this.api,
    required this.host,
    required this.username,
    required this.password,
    required this.port,
    this.defaultProfile,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('🌟 توليد الكروت'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ============================================
          // العنوان الترحيبي
          // ============================================
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade400, Colors.blue.shade700],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.auto_awesome,
                  color: Colors.white,
                  size: 40,
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'اختر نوع التوليد',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'كرت واحد أو مجموعة كروت',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ============================================
          // الخيار 1: كرت واحد
          // ============================================
          _buildOptionCard(
            context,
            icon: Icons.person_add,
            title: 'كرت واحد',
            subtitle: 'إضافة كرت واحد ببيانات مخصصة',
            color: Colors.blue,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddHotspotUserPage(
                    api: api,
                    host: host,
                    username: username,
                    password: password,
                    port: port,
                    defaultProfile: defaultProfile,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // ============================================
          // الخيار 2: مجموعة كروت
          // ============================================
          _buildOptionCard(
            context,
            icon: Icons.library_add,
            title: 'مجموعة كروت',
            subtitle: 'توليد 10، 100، 1000 كرت دفعة واحدة',
            color: Colors.deepOrange,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GenerateCardsPage(
                    api: api,
                    host: host,
                    username: username,
                    password: password,
                    port: port,
                    defaultProfile: defaultProfile,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // ============================================
          // زر عرض المستخدمين
          // ============================================
          _buildOptionCard(
            context,
            icon: Icons.people,
            title: 'عرض الكروت',
            subtitle: 'عرض وإدارة الكروت الموجودة',
            color: Colors.green,
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HotspotUsersPage(
                    api: api,
                    host: host,
                    username: username,
                    password: password,
                    port: port,
                    profile: defaultProfile,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  size: 28,
                  color: color,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: color.withValues(alpha: 0.6),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Router Settings Hub
// =============================================================================

class RouterSettingsHubPage extends StatelessWidget {
  final Map<String, dynamic> router;
  final MikroTikApi api;

  const RouterSettingsHubPage({
    super.key,
    required this.router,
    required this.api,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('⚙️ إعدادات الراوتر'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ============================================
          // إعدادات الاتصال
          // ============================================
          _sectionTitle(
            context,
            'إعدادات الاتصال',
            Icons.wifi,
            Colors.blue,
          ),

          _settingsTile(
            context,
            icon: Icons.lan,
            title: 'Local',
            subtitle: 'إعداد الاتصال المحلي بالراوتر',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => RouterSettingsPage(
                    router: router,
                  ),
                ),
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.cloud,
            title: 'Cloud',
            subtitle: 'إعداد الاتصال والوصول عبر Cloud',
            color: Colors.lightBlue,
            onTap: () {
              _showComingSoon(context, 'إعدادات Cloud');
            },
          ),

          _settingsTile(
            context,
            icon: Icons.vpn_lock,
            title: 'VPN',
            subtitle: 'L2TP، PPTP، WireGuard',
            color: Colors.deepPurple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VpnPage(api: api),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // ============================================
          // إعدادات MikroTik
          // ============================================
          _sectionTitle(
            context,
            'إعدادات MikroTik',
            Icons.settings,
            Colors.teal,
          ),

          _settingsTile(
            context,
            icon: Icons.auto_fix_high,
            title: '📶 Hotspot Setup',
            subtitle: 'معالج إعداد Hotspot كامل + الإدارة',
            color: Colors.orange,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HotspotPage(api: api),
                ),
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.category,
            title: 'Hotspot Profiles',
            subtitle: 'إدارة بروفايلات Hotspot',
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HotspotProfilesPage(
                    api: api,
                    host: router['host']?.toString() ?? '',
                    username: router['username']?.toString() ?? '',
                    password: router['password']?.toString() ?? '',
                    port: int.tryParse(
                      router['port']?.toString() ?? '',
                    ) ??
                        8728,
                  ),
                ),
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.wifi_tethering,
            title: 'User Manager Sessions',
            subtitle: 'عرض المتصلين النشطين وقطع اتصالهم',
            color: Colors.green,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserManagerSessionsPage(api: api),
                ),
              );
            },
          ),
          _settingsTile(
            context,
            icon: Icons.people,
            title: 'User Manager Users',
            subtitle: 'إدارة مستخدمي User Manager (إضافة / حذف)',
            color: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserManagerUsersPage(api: api),
                ),
              );
            },
          ),
          _settingsTile(
            context,
            icon: Icons.dashboard_customize,
            title: 'User Manager Hub',
            subtitle: 'توليد كروت + Profiles + Limitations + Sessions',
            color: Colors.teal,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserManagerHubPage(api: api),
                ),
              );
            },
          ),
          _settingsTile(
            context,
            icon: Icons.settings_applications,
            title: 'IP و DHCP و DNS',
            subtitle: 'إدارة شبكات DHCP وإعدادات DNS',
            color: Colors.cyan,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DhcpDnsPage(api: api),
                ),
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.security,
            title: 'Firewall و NAT',
            subtitle: 'قواعد الجدار الناري وترجمة العناوين',
            color: Colors.red,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FirewallPage(api: api),
                ),
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.cable,
            title: 'الواجهات (Interfaces)',
            subtitle: 'عرض وإدارة واجهات الشبكة',
            color: Colors.brown,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InterfacesPage(api: api),
                ),
              );
            },
          ),

          const SizedBox(height: 12),

          // ============================================
          // إدارة الراوتر
          // ============================================
          _sectionTitle(
            context,
            'إدارة الراوتر',
            Icons.build,
            Colors.green,
          ),

          _settingsTile(
            context,
            icon: Icons.key,
            title: 'المستخدمون وكلمات المرور',
            subtitle: 'عرض وتعديل مستخدمي MikroTik',
            color: Colors.amber,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MikrotikUsersPage(api: api),
                ),
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.restart_alt,
            title: 'إعادة تشغيل الراوتر',
            subtitle: 'Restart MikroTik',
            color: Colors.orange,
            onTap: () {
              _confirmAction(
                context,
                title: 'إعادة تشغيل الراوتر',
                message: 'هل أنت متأكد أنك تريد إعادة تشغيل الراوتر؟',
                actionText: 'إعادة التشغيل',
                onConfirm: () async {
                  try {
                    await api.restartRouter();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم إرسال أمر إعادة تشغيل الراوتر بنجاح ✅',
                            ),
                          ),
                        );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('فشل إعادة تشغيل الراوتر: $e'),
                          ),
                        );
                    }
                  }
                },
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.power_settings_new,
            title: 'إيقاف تشغيل الراوتر',
            subtitle: 'Shutdown MikroTik',
            color: Colors.deepOrange,
            onTap: () {
              _confirmAction(
                context,
                title: 'إيقاف تشغيل الراوتر',
                message: 'هل أنت متأكد أنك تريد إيقاف تشغيل الراوتر؟',
                actionText: 'إيقاف التشغيل',
                onConfirm: () async {
                  try {
                    await api.shutdownRouter();

                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          const SnackBar(
                            content: Text(
                              'تم إرسال أمر إيقاف تشغيل الراوتر بنجاح ✅',
                            ),
                          ),
                        );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                        ..hideCurrentSnackBar()
                        ..showSnackBar(
                          SnackBar(
                            content: Text('فشل إيقاف تشغيل الراوتر: $e'),
                          ),
                        );
                    }
                  }
                },
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.backup,
            title: 'Backup / Restore',
            subtitle: 'النسخ الاحتياطي واستعادة إعدادات الراوتر',
            color: Colors.purple,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BackupRestorePage(
                    api: api,
                    host: router['host']?.toString() ?? '',
                    username: router['username']?.toString() ?? '',
                    password: router['password']?.toString() ?? '',
                  ),
                ),
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.warning_amber_rounded,
            title: 'إعادة ضبط المصنع',
            subtitle: 'حذف إعدادات الراوتر وإعادته للوضع الافتراضي',
            danger: true,
            onTap: () {
              _confirmAction(
                context,
                title: '⚠️ إعادة ضبط المصنع',
                message:
                'هذا الإجراء خطير وقد يؤدي إلى فقدان إعدادات الراوتر وفقدان الاتصال به.\n\nهل تريد المتابعة؟',
                actionText: 'متابعة',
                onConfirm: () {
                  _showComingSoon(context, 'إعادة ضبط المصنع');
                },
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(
      BuildContext context,
      String title,
      IconData icon,
      Color color,
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 10,
        top: 8,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: 20,
              color: color,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _settingsTile(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required VoidCallback onTap,
        bool danger = false,
        Color? color,
      }) {
    final baseColor = danger ? Colors.red : (color ?? Colors.blue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: baseColor.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: baseColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    size: 22,
                    color: baseColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: danger ? Colors.red : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_left,
                  color: baseColor.withValues(alpha: 0.6),
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showComingSoon(
      BuildContext context,
      String title,
      ) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$title — سيتم ربط الوظيفة في المرحلة التالية',
        ),
      ),
    );
  }

  void _confirmAction(
      BuildContext context, {
        required String title,
        required String message,
        required String actionText,
        required VoidCallback onConfirm,
      }) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                onConfirm();
              },
              child: Text(actionText),
            ),
          ],
        );
      },
    );
  }
}

// =============================================================================
// Router Settings
// =============================================================================

class RouterSettingsPage extends StatefulWidget {
  final Map<String, dynamic>? router;

  const RouterSettingsPage({
    super.key,
    this.router,
  });

  @override
  State<RouterSettingsPage> createState() =>
      _RouterSettingsPageState();
}

class _RouterSettingsPageState extends State<RouterSettingsPage> {
  final RouterStorage _storage = RouterStorage();

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _hostController;
  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _portController;

  final MikroTikApi _testApi = MikroTikApi();

  bool _saving = false;
  bool _testing = false;

  bool get _isEditing => widget.router != null;

  @override
  void initState() {
    super.initState();

    final router = widget.router;

    _nameController = TextEditingController(
      text: router?['name']?.toString() ?? '',
    );

    _hostController = TextEditingController(
      text: router?['host']?.toString() ?? '',
    );

    _usernameController = TextEditingController(
      text: router?['username']?.toString() ?? '',
    );

    _passwordController = TextEditingController(
      text: router?['password']?.toString() ?? '',
    );

    _portController = TextEditingController(
      text: router?['port']?.toString() ?? '8728',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _hostController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _portController.dispose();

    _testApi.disconnect();

    super.dispose();
  }

  Future<void> _testConnection() async {
    if (_testing) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _testing = true;
    });

    try {
      _testApi.disconnect();

      final connected = await _testApi.connect(
        host: _hostController.text.trim(),
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        port: int.tryParse(_portController.text.trim()) ?? 8728,
      );

      if (!mounted) return;

      if (connected) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'تم الاتصال بالراوتر بنجاح ✅',
              ),
            ),
          );
      } else {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                _testApi.lastError ?? 'فشل الاتصال بالراوتر',
              ),
              backgroundColor: Colors.red,
            ),
          );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('فشل اختبار الاتصال: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      _testApi.disconnect();

      if (mounted) {
        setState(() {
          _testing = false;
        });
      }
    }
  }

  Future<void> _saveRouter() async {
    if (_saving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final name = _nameController.text.trim();
      final host = _hostController.text.trim();
      final username = _usernameController.text.trim();
      final password = _passwordController.text;
      final port = int.tryParse(_portController.text.trim()) ?? 8728;

      if (_isEditing) {
        final deviceId =
        widget.router!['deviceId']?.toString();

        if (deviceId == null || deviceId.isEmpty) {
          throw Exception(
            'لم يتم العثور على Device ID الخاص بالراوتر',
          );
        }

        await _storage.updateRouter(
          deviceId: deviceId,
          name: name,
          host: host,
          username: username,
          password: password,
          port: port,
        );
      } else {
        await _storage.saveRouter(
          name: name,
          host: host,
          username: username,
          password: password,
          port: port,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              _isEditing
                  ? 'تم تحديث بيانات الراوتر بنجاح ✅'
                  : 'تم حفظ الراوتر بنجاح ✅',
            ),
          ),
        );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text('فشل حفظ الراوتر: $e'),
            backgroundColor: Colors.red,
          ),
        );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'تعديل الراوتر' : 'إضافة راوتر',
        ),
        actions: [
          IconButton(
            onPressed: _saving ? null : _saveRouter,
            tooltip: 'حفظ',
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 28,
                      child: Icon(
                        Icons.router,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditing
                                ? 'تعديل بيانات الراوتر'
                                : 'إضافة راوتر جديد',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            'أدخل بيانات الاتصال بالراوتر',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              '🌐 إعدادات الاتصال',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            _field(
              label: 'اسم الراوتر',
              controller: _nameController,
              hint: 'مثال: الراوتر الرئيسي',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'أدخل اسم الراوتر';
                }
                return null;
              },
            ),

            _field(
              label: 'IP / Host',
              controller: _hostController,
              hint: 'مثال: 10.40.40.1',
              keyboardType: TextInputType.text,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'أدخل عنوان الراوتر';
                }
                return null;
              },
            ),

            _field(
              label: 'Username',
              controller: _usernameController,
              hint: 'مثال: admin',
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'أدخل اسم المستخدم';
                }
                return null;
              },
            ),

            _field(
              label: 'Password',
              controller: _passwordController,
              obscureText: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'أدخل كلمة المرور';
                }
                return null;
              },
            ),

            _field(
              label: 'API Port',
              controller: _portController,
              hint: '8728',
              keyboardType: TextInputType.number,
              validator: (value) {
                final port = int.tryParse(value?.trim() ?? '');

                if (port == null || port < 1 || port > 65535) {
                  return 'أدخل منفذًا صحيحًا';
                }

                return null;
              },
            ),

            const SizedBox(height: 8),

            SizedBox(
              height: 52,
              child: OutlinedButton.icon(
                onPressed: _testing ? null : _testConnection,
                icon: _testing
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.network_check),
                label: Text(
                  _testing
                      ? 'جاري اختبار الاتصال...'
                      : 'اختبار الاتصال',
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _saving ? null : _saveRouter,
                icon: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? 'جاري الحفظ...' : 'حفظ الراوتر',
                ),
              ),
            ),

            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'معلومات الاتصال',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'يستخدم التطبيق MikroTik API للاتصال بالراوتر.',
                      style: TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'المنفذ الافتراضي: 8728',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Add Hotspot Profile Page
// =============================================================================

class AddHotspotProfilePage extends StatefulWidget {
  final MikroTikApi api;

  const AddHotspotProfilePage({
    super.key,
    required this.api,
  });

  @override
  State<AddHotspotProfilePage> createState() => _AddHotspotProfilePageState();
}

class _AddHotspotProfilePageState extends State<AddHotspotProfilePage> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _sharedUsersController = TextEditingController(text: '1');
  final _rateLimitController = TextEditingController();
  final _sessionTimeoutController = TextEditingController();
  final _idleTimeoutController = TextEditingController();
  final _keepaliveTimeoutController = TextEditingController();

  List<Map<String, String>> _pools = [];
  String? _selectedPool;
  bool _loadingPools = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPools();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sharedUsersController.dispose();
    _rateLimitController.dispose();
    _sessionTimeoutController.dispose();
    _idleTimeoutController.dispose();
    _keepaliveTimeoutController.dispose();
    super.dispose();
  }

  Future<void> _loadPools() async {
    if (!mounted) return;
    setState(() => _loadingPools = true);

    try {
      final pools = await widget.api.getIpPools();
      if (!mounted) return;
      setState(() {
        _pools = pools;
        _loadingPools = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingPools = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final id = await widget.api.addHotspotProfile(
        name: _nameController.text.trim(),
        addressPool: _selectedPool,
        sharedUsers: _sharedUsersController.text.trim(),
        rateLimit: _rateLimitController.text.trim(),
        sessionTimeout: _sessionTimeoutController.text.trim(),
        idleTimeout: _idleTimeoutController.text.trim(),
        keepaliveTimeout: _keepaliveTimeoutController.text.trim(),
      );

      if (!mounted) return;

      if (id == null || id.isEmpty) {
        setState(() => _saving = false);
        _showMessage('فشل الإنشاء', isError: true);
        return;
      }

      _showMessage('تم إنشاء البروفايل ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('فشل: $e', isError: true);
    }
  }

  void _showMessage(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : null,
      ));
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    String? helperText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          helperText: helperText,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('➕ إضافة Hotspot Profile'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '📝 المعلومات الأساسية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _field(
              label: 'اسم البروفايل *',
              controller: _nameController,
              hint: 'مثال: باقة شهرية',
              validator: (v) =>
              v == null || v.trim().isEmpty ? 'مطلوب' : null,
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _loadingPools
                  ? const LinearProgressIndicator()
                  : DropdownButtonFormField<String>(
                initialValue: _selectedPool,
                decoration: const InputDecoration(
                  labelText: 'IP Pool',
                  border: OutlineInputBorder(),
                  helperText: 'اتركه فارغاً للاستخدام الافتراضي',
                ),
                items: [
                  const DropdownMenuItem<String>(
                    value: null,
                    child: Text('بدون'),
                  ),
                  ..._pools.map((pool) {
                    final name = pool['name'] ?? '';
                    return DropdownMenuItem<String>(
                      value: name,
                      child: Text(name),
                    );
                  }),
                ],
                onChanged: (v) => setState(() => _selectedPool = v),
              ),
            ),

            _field(
              label: 'Shared Users',
              controller: _sharedUsersController,
              hint: '1',
              helperText: 'عدد الأجهزة المسموحة لكل كرت',
            ),

            const SizedBox(height: 20),

            const Text(
              '⏱️ 📊 القيود',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _field(
              label: 'Rate Limit',
              controller: _rateLimitController,
              hint: 'مثال: 2M/2M',
              helperText: 'تحميل/رفع',
            ),

            _field(
              label: 'Session Timeout',
              controller: _sessionTimeoutController,
              hint: 'مثال: 1h، 30m، 1d',
            ),

            _field(
              label: 'Idle Timeout',
              controller: _idleTimeoutController,
              hint: 'مثال: 5m',
            ),

            _field(
              label: 'Keepalive Timeout',
              controller: _keepaliveTimeoutController,
              hint: 'مثال: 2m',
            ),

            const SizedBox(height: 20),

            SizedBox(
              height: 54,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? 'جاري الإنشاء...' : '💾 إنشاء البروفايل',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// =============================================================================
// 🗂️ Cards Manager Type Dialog
// =============================================================================

class _CardsManagerTypeDialog extends StatelessWidget {
  const _CardsManagerTypeDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === Header ===
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4A6CF7), Color(0xFF3451C7)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.folder_special,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'إدارة الكروت',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),

              const Text(
                'اختر نوع الكروت التي تريد إدارتها:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),

              // === Hotspot ===
              _optionCard(
                context: context,
                icon: Icons.wifi,
                title: 'كروت Hotspot',
                subtitle: 'إدارة كروت Hotspot العادية\n(hotspot/user)',
                color: const Color(0xFF2196F3),
                value: 'hotspot',
              ),

              const SizedBox(height: 10),

              // === User Manager ===
              _optionCard(
                context: context,
                icon: Icons.router,
                title: 'كروت User Manager',
                subtitle: 'إدارة كروت RADIUS المدمجة\n(user-manager/user)',
                color: const Color(0xFF7C3AED),
                value: 'user_manager',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String value,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: color.withValues(alpha: 0.7),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
// =============================================================================
// 🌟 Generate Cards Type Dialog
// =============================================================================

class _GenerateCardsTypeDialog extends StatelessWidget {
  const _GenerateCardsTypeDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // === Header ===
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6F00), Color(0xFFE65100)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'توليد الكروت',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Divider(height: 24),

              const Text(
                'اختر نوع الكروت التي تريد توليدها:',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 14),

              // === Hotspot ===
              _optionCard(
                context: context,
                icon: Icons.wifi,
                title: 'كروت Hotspot',
                subtitle:
                'توليد كروت Hotspot العادية\n(يدعم كرت واحد أو مجموعة)',
                color: const Color(0xFF2196F3),
                value: 'hotspot',
              ),

              const SizedBox(height: 10),

              // === User Manager ===
              _optionCard(
                context: context,
                icon: Icons.router,
                title: 'كروت User Manager',
                subtitle:
                'توليد كروت RADIUS المدمجة\n(30/100/1000 كرت دفعة واحدة)',
                color: const Color(0xFF7C3AED),
                value: 'user_manager',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _optionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String value,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.pop(context, value),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left,
                color: color.withValues(alpha: 0.7),
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}