import 'package:flutter/material.dart';
import 'mikrotik_api.dart';
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
      appBar: AppBar(
        title: const Text('الراوترات المحفوظة'),
        actions: [
          IconButton(
            onPressed: _loadRouters,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
          : _routers.isEmpty
          ? const Center(
        child: Text(
          'لا توجد راوترات محفوظة',
          style: TextStyle(
            fontSize: 18,
          ),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _routers.length,
        itemBuilder: (context, index) {
          final router = _routers[index];

          final name =
              router['name']?.toString() ?? 'MikroTik';

          final host = router['host']?.toString() ?? '-';

          final deviceId =
              router['deviceId']?.toString() ?? '-';

          final cloudConnected = _isCloudConnected(router);

          return Card(
            margin: const EdgeInsets.only(
              bottom: 10,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _openRouter(router);
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          radius: 25,
                          child: Icon(
                            Icons.router,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight:
                                  FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                host,
                                style: const TextStyle(
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          cloudConnected
                              ? Icons.cloud_done
                              : Icons.cloud_off,
                          color: cloudConnected
                              ? Colors.green
                              : Colors.grey,
                        ),
                        IconButton(
                          onPressed: () {
                            _deleteRouter(index);
                          },
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Icon(
                          Icons.cloud_outlined,
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          _connectionMode(router),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'ID: ${deviceId.length > 18 ? '${deviceId.substring(0, 18)}...' : deviceId}',
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
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
        child: const Icon(Icons.add),
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
  final MikroTikApi _api = MikroTikApi();

  bool _connecting = false;
  bool _connected = false;
  bool _readingData = false;

  Map<String, String>? _routerInfo;

  String? _lastUpdate;

  @override
  void dispose() {
    _api.disconnect();
    super.dispose();
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

  Future<bool> _connect() async {
    if (_connecting) {
      return false;
    }

    setState(() {
      _connecting = true;
    });

    try {
      final connected = await _api.connect(
        host: widget.router['host'].toString(),
        username: widget.router['username'].toString(),
        password: widget.router['password'].toString(),
        port: int.tryParse(
          widget.router['port'].toString(),
        ) ??
            8728,
      );

      if (!connected) {
        if (mounted) {
          setState(() {
            _connected = false;
          });
        }

        _showMessage(
          _api.lastError ?? 'فشل الاتصال بالراوتر',
          isError: true,
        );

        return false;
      }

      if (mounted) {
        setState(() {
          _connected = true;
        });
      }

      return true;
    } catch (e) {
      _api.disconnect();

      if (mounted) {
        setState(() {
          _connected = false;
        });
      }

      _showMessage(
        'فشل الاتصال: $e',
        isError: true,
      );

      return false;
    } finally {
      if (mounted) {
        setState(() {
          _connecting = false;
        });
      }
    }
  }

  Future<void> _connectAndReadInfo() async {
    if (_connecting || _connected) {
      return;
    }

    final connected = await _connect();

    if (!connected) {
      return;
    }

    try {
      final info = await _api.getRouterInfo();

      if (!mounted) return;

      setState(() {
        _routerInfo = info;
        _lastUpdate = _currentTime();
      });

      _showMessage(
        'تم الاتصال بالراوتر بنجاح ✅',
      );
    } catch (e) {
      _api.disconnect();

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

  Future<void> _updateData() async {
    if (!_connected || _readingData) {
      return;
    }

    setState(() {
      _readingData = true;
    });

    try {
      final info = await _api.getRouterInfo();

      if (!mounted) return;

      setState(() {
        _routerInfo = info;
        _lastUpdate = _currentTime();
      });
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'فشل تحديث معلومات الراوتر: $e',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          _readingData = false;
        });
      }
    }
  }

  Map<String, dynamic> get _router {
    return widget.router;
  }

  Future<void> _openUsers({
    String? profile,
  }) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotspotUsersPage(
          api: _api,
          host: _router['host'].toString(),
          username: _router['username'].toString(),
          password: _router['password'].toString(),
          port: int.tryParse(
            _router['port'].toString(),
          ) ??
              8728,
          profile: profile,
        ),
      ),
    );
  }

  Future<void> _openProfiles() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotspotProfilesPage(
          api: _api,
          host: _router['host'].toString(),
          username: _router['username'].toString(),
          password: _router['password'].toString(),
          port: int.tryParse(
            _router['port'].toString(),
          ) ??
              8728,
        ),
      ),
    );
  }

  Future<void> _openConnectedUsers() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectedUsersPage(
          api: _api,
          host: _router['host'].toString(),
          username: _router['username'].toString(),
          password: _router['password'].toString(),
          port: int.tryParse(
            _router['port'].toString(),
          ) ??
              8728,
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
          api: _api,
        ),
      ),
    );
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

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Card(
      margin: const EdgeInsets.all(5),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 25,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
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

  Widget _actionButton({
    required IconData icon,
    required String title,
    required VoidCallback? onPressed,
  }) {
    return Expanded(
      child: Card(
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 16,
              horizontal: 8,
            ),
            child: Column(
              children: [
                Icon(
                  icon,
                  size: 30,
                ),
                const SizedBox(height: 7),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routerName =
        widget.router['name']?.toString() ?? 'MikroTik';

    final deviceId =
        widget.router['deviceId']?.toString() ?? '-';

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
            onPressed: _openSettings,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_connected) {
            await _updateData();
          }
        },
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      _connected
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      color: _connected ? Colors.green : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _connected ? 'متصل' : 'غير متصل',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            connectionMode == 'cloud'
                                ? 'اتصال عن بُعد / Cloud'
                                : 'اتصال محلي',
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                          if (_lastUpdate != null)
                            Text(
                              'آخر تحديث: $_lastUpdate',
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (!_connected)
                      FilledButton.icon(
                        onPressed:
                        _connecting ? null : _connectAndReadInfo,
                        icon: _connecting
                            ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                            : const Icon(Icons.link),
                        label: Text(
                          _connecting ? 'جاري الاتصال' : 'اتصال',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const Icon(
                      Icons.fingerprint,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Device ID',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            deviceId,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _actionButton(
                  icon: Icons.category,
                  title: 'Hotspot Profiles',
                  onPressed: _connected ? _openProfiles : null,
                ),
                _actionButton(
                  icon: Icons.people,
                  title: 'مستخدمو Hotspot',
                  onPressed: _connected ? () => _openUsers() : null,
                ),
              ],
            ),
            Row(
              children: [
                _actionButton(
                  icon: Icons.wifi,
                  title: '🟢 المتصلون الآن',
                  onPressed: _connected ? _openConnectedUsers : null,
                ),
                _actionButton(
                  icon: Icons.print,
                  title: 'طباعة الكروت',
                  onPressed: _connected
                      ? () {
                    _showMessage(
                      'ميزة طباعة الكروت سيتم إضافتها لاحقًا',
                    );
                  }
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _actionButton(
                  icon: Icons.settings,
                  title: 'الإعدادات',
                  onPressed: _openSettings,
                ),
              ],
            ),
            const SizedBox(height: 15),
            const Text(
              'معلومات الراوتر',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 5),
            GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 2.2,
              children: [
                _infoCard(
                  title: 'Identity',
                  value: _value('identity'),
                  icon: Icons.badge,
                ),
                _infoCard(
                  title: 'Version',
                  value: _value('version'),
                  icon: Icons.system_update,
                ),
                _infoCard(
                  title: 'Board',
                  value: _value('board'),
                  icon: Icons.memory,
                ),
                _infoCard(
                  title: 'Architecture',
                  value: _value('architecture'),
                  icon: Icons.developer_board,
                ),
                _infoCard(
                  title: 'CPU',
                  value: _value('cpu'),
                  icon: Icons.speed,
                ),
                _infoCard(
                  title: 'CPU Load',
                  value: '${_value('cpuLoad')}%',
                  icon: Icons.show_chart,
                ),
                _infoCard(
                  title: 'Uptime',
                  value: _value('uptime'),
                  icon: Icons.timer,
                ),
                _infoCard(
                  title: 'Free Memory',
                  value: _value('freeMemory'),
                  icon: Icons.memory,
                ),
                _infoCard(
                  title: 'Total Memory',
                  value: _value('totalMemory'),
                  icon: Icons.storage,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'بيانات الاتصال',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _connectionRow(
                      'العنوان',
                      widget.router['host']?.toString() ?? '',
                    ),
                    _connectionRow(
                      'المستخدم',
                      widget.router['username']?.toString() ?? '',
                    ),
                    _connectionRow(
                      'المنفذ',
                      widget.router['port']?.toString() ?? '8728',
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

  Widget _connectionRow(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        vertical: 4,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
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

  bool _loading = true;

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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  String _value(
      Map<String, String> profile,
      String key,
      ) {
    final value = profile[key];

    if (value == null || value.isEmpty) {
      return '-';
    }

    return value;
  }

  Future<void> _openProfile(
      Map<String, String> profile,
      ) async {
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

    if (mounted) {
      _loadProfiles();
    }
  }

  Future<void> _openProfileUsers(
      Map<String, String> profile,
      ) async {
    final profileName = profile['name']?.trim() ?? '';

    if (profileName.isEmpty) {
      return;
    }

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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotspot Profiles'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadProfiles,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(),
      )
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
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: _loadProfiles,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      )
          : _profiles.isEmpty
          ? const Center(
        child: Text(
          'لا توجد Hotspot Profiles',
          style: TextStyle(fontSize: 18),
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _profiles.length,
        itemBuilder: (context, index) {
          final profile = _profiles[index];

          final name = _value(profile, 'name');
          final addressPool =
          _value(profile, 'address-pool');
          final rateLimit =
          _value(profile, 'rate-limit');
          final sessionTimeout =
          _value(profile, 'session-timeout');
          final idleTimeout =
          _value(profile, 'idle-timeout');
          final sharedUsers =
          _value(profile, 'shared-users');

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                _openProfile(profile);
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const CircleAvatar(
                          child: Icon(Icons.category),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            name,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip:
                          'مستخدمو هذا البروفايل',
                          onPressed: () {
                            _openProfileUsers(profile);
                          },
                          icon: const Icon(Icons.people),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                    const Divider(),
                    _profileDetailRow(
                        'Address Pool', addressPool),
                    _profileDetailRow(
                        'Rate Limit', rateLimit),
                    _profileDetailRow(
                        'Session Timeout', sessionTimeout),
                    _profileDetailRow(
                        'Idle Timeout', idleTimeout),
                    _profileDetailRow(
                        'Shared Users', sharedUsers),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _profileDetailRow(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 145,
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
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
// Hotspot Users
// =============================================================================

class HotspotUsersPage extends StatefulWidget {
  final MikroTikApi api;

  final String host;
  final String username;
  final String password;
  final int port;

  final String? profile;

  const HotspotUsersPage({
    super.key,
    required this.api,
    required this.host,
    required this.username,
    required this.password,
    required this.port,
    this.profile,
  });

  @override
  State<HotspotUsersPage> createState() => _HotspotUsersPageState();
}

class _HotspotUsersPageState extends State<HotspotUsersPage> {
  late final MikroTikApi _api;

  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, String>> _users = [];

  bool _loading = false;

  String? _error;

  String? _selectedProfile;

  String _searchType = 'name';

  String _sortBy = 'name';

  bool _ascending = true;

  bool _allLoaded = false;

  @override
  void initState() {
    super.initState();

    _api = widget.api;

    if (widget.profile != null &&
        widget.profile!.trim().isNotEmpty) {
      _selectedProfile = widget.profile;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    if (_loading) return;

    final search = _searchController.text.trim();

    if (search.isEmpty) {
      _showMessage(
        'اكتب اسم أو رقم الكرت أولاً.',
        isError: true,
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _allLoaded = false;
    });

    try {
      final users = await _api.getHotspotUsers(
        username: search,
      );

      if (!mounted) return;

      setState(() {
        _users = List<Map<String, String>>.from(users);
        _sortUsers();
        _loading = false;
      });

      if (_users.isEmpty) {
        _showMessage(
          'لم يتم العثور على الكرت "$search".',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _users = [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadByProfile() async {
    if (_loading) return;

    final profile = _selectedProfile?.trim();

    if (profile == null || profile.isEmpty) {
      _showMessage(
        'حدد البروفايل أولاً.',
        isError: true,
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _allLoaded = false;
    });

    try {
      final users = await _api.getHotspotUsers(
        profile: profile,
      );

      if (!mounted) return;

      setState(() {
        _users = List<Map<String, String>>.from(users);
        _sortUsers();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _users = [];
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _loadAllUsers() async {
    if (_loading) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('جلب جميع الكروت'),
          content: const Text(
            'سيتم جلب جميع Hotspot Users من الراوتر.\n\n'
                'إذا كان الراوتر يحتوي على آلاف أو عشرات الآلاف من الكروت، '
                'قد يستغرق الأمر وقتًا ويستهلك موارد من الراوتر.\n\n'
                'هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('جلب الكروت'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _allLoaded = false;
    });

    try {
      final users = await _api.getAllHotspotUsers(
        profile: _selectedProfile,
      );

      if (!mounted) return;

      setState(() {
        _users = List<Map<String, String>>.from(users);
        _sortUsers();
        _loading = false;
        _allLoaded = true;
      });

      _showMessage('تم جلب ${_users.length} كرت بنجاح ✅');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _users = [];
        _loading = false;
        _error = e.toString();
        _allLoaded = false;
      });
    }
  }

  void _sortUsers() {
    _users.sort(
          (a, b) {
        String valueA;
        String valueB;

        switch (_sortBy) {
          case 'number':
            valueA = _extractNumber(a['name'] ?? '');
            valueB = _extractNumber(b['name'] ?? '');
            break;

          case 'profile':
            valueA = (a['profile'] ?? '').toLowerCase();
            valueB = (b['profile'] ?? '').toLowerCase();
            break;

          case 'duration':
            valueA = _durationToSeconds(a['limit-uptime'] ?? '')
                .toString()
                .padLeft(20, '0');

            valueB = _durationToSeconds(b['limit-uptime'] ?? '')
                .toString()
                .padLeft(20, '0');
            break;

          case 'name':
          default:
            valueA = (a['name'] ?? '').toLowerCase();
            valueB = (b['name'] ?? '').toLowerCase();
            break;
        }

        final result = valueA.compareTo(valueB);

        return _ascending ? result : -result;
      },
    );
  }

  String _extractNumber(String value) {
    final match = RegExp(r'\d+').firstMatch(value);

    if (match == null) {
      return value.toLowerCase();
    }

    final number = int.tryParse(match.group(0)!) ?? 0;

    return number.toString().padLeft(20, '0');
  }

  int _durationToSeconds(String value) {
    if (value.trim().isEmpty) {
      return 0;
    }

    int total = 0;

    final dayMatch = RegExp(
      r'(\d+)d',
      caseSensitive: false,
    ).firstMatch(value);

    final hourMatch = RegExp(
      r'(\d+)h',
      caseSensitive: false,
    ).firstMatch(value);

    final minuteMatch = RegExp(
      r'(\d+)m',
      caseSensitive: false,
    ).firstMatch(value);

    final secondMatch = RegExp(
      r'(\d+)s',
      caseSensitive: false,
    ).firstMatch(value);

    if (dayMatch != null) {
      total += (int.tryParse(dayMatch.group(1)!) ?? 0) * 86400;
    }

    if (hourMatch != null) {
      total += (int.tryParse(hourMatch.group(1)!) ?? 0) * 3600;
    }

    if (minuteMatch != null) {
      total += (int.tryParse(minuteMatch.group(1)!) ?? 0) * 60;
    }

    if (secondMatch != null) {
      total += int.tryParse(secondMatch.group(1)!) ?? 0;
    }

    return total;
  }

  void _changeSort(String value) {
    setState(() {
      if (_sortBy == value) {
        _ascending = !_ascending;
      } else {
        _sortBy = value;
        _ascending = true;
      }

      _sortUsers();
    });
  }

  Future<void> _editUser(
      Map<String, String> user,
      ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotspotUserEditPage(
          api: _api,
          host: widget.host,
          username: widget.username,
          password: widget.password,
          port: widget.port,
          user: user,
        ),
      ),
    );

    if (!mounted) return;

    if (_allLoaded) {
      await _loadAllUsersWithoutDialog();
    } else if (_searchController.text.trim().isNotEmpty) {
      await _searchUsers();
    } else if (_selectedProfile != null &&
        _selectedProfile!.isNotEmpty) {
      await _loadByProfile();
    }
  }

  Future<void> _loadAllUsersWithoutDialog() async {
    if (_loading) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await _api.getAllHotspotUsers(
        profile: _selectedProfile,
      );

      if (!mounted) return;

      setState(() {
        _users = List<Map<String, String>>.from(users);
        _sortUsers();
        _loading = false;
        _allLoaded = true;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _deleteUser(
      Map<String, String> user,
      ) async {
    final id = user['.id'];

    if (id == null || id.isEmpty) {
      _showMessage(
        'لا يوجد ID لهذا المستخدم',
        isError: true,
      );
      return;
    }

    final name = user['name'] ?? 'المستخدم';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد الحذف'),
          content: Text(
            'هل تريد حذف الكرت "$name" نهائيًا؟',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      setState(() {
        _loading = true;
      });

      await _api.deleteHotspotUser(id);

      if (!mounted) return;

      setState(() {
        _users.removeWhere((item) => item['.id'] == id);
        _loading = false;
      });

      _showMessage('تم حذف الكرت بنجاح ✅');
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });

      _showMessage(
        'فشل حذف الكرت: $e',
        isError: true,
      );
    }
  }
  /// فتح شاشة إضافة كرت واحد.
  Future<void> _openAddUser() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AddHotspotUserPage(
          api: _api,
          host: widget.host,
          username: widget.username,
          password: widget.password,
          port: widget.port,
          defaultProfile: _selectedProfile,
        ),
      ),
    );

    if (!mounted) return;

    if (added == true) {
      if (_allLoaded) {
        await _loadAllUsersWithoutDialog();
      } else if (_selectedProfile != null && _selectedProfile!.isNotEmpty) {
        await _loadByProfile();
      }
    }
  }

  /// فتح شاشة توليد الكروت الجماعية.
  Future<void> _openGenerateCards() async {
    final generated = await Navigator.push<int>(
      context,
      MaterialPageRoute(
        builder: (_) => GenerateCardsPage(
          api: _api,
          host: widget.host,
          username: widget.username,
          password: widget.password,
          port: widget.port,
          defaultProfile: _selectedProfile,
        ),
      ),
    );

    if (!mounted) return;

    if (generated != null && generated > 0) {
      _showMessage('تم توليد $generated كرت بنجاح ✅');
      if (_allLoaded) {
        await _loadAllUsersWithoutDialog();
      } else if (_selectedProfile != null && _selectedProfile!.isNotEmpty) {
        await _loadByProfile();
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

  Widget _userDetailRow(
      String title,
      String value,
      ) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 125,
            child: Text(
              title,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.profile == null
        ? 'مستخدمو Hotspot'
        : 'مستخدمو: ${widget.profile}';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            tooltip: 'إضافة كرت',
            onPressed: _loading ? null : _openAddUser,
            icon: const Icon(Icons.add_circle_outline),
          ),
          IconButton(
            tooltip: 'توليد كروت',
            onPressed: _loading ? null : _openGenerateCards,
            icon: const Icon(Icons.auto_awesome),
          ),
          IconButton(
            tooltip: 'جلب جميع الكروت',
            onPressed: _loading ? null : _loadAllUsers,
            icon: const Icon(Icons.list_alt),
          ),
          IconButton(
            tooltip: 'بحث',
            onPressed: _loading ? null : _searchUsers,
            icon: const Icon(Icons.search),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _searchType,
                        decoration: const InputDecoration(
                          labelText: 'نوع البحث',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('اسم المستخدم'),
                          ),
                          DropdownMenuItem(
                            value: 'number',
                            child: Text('رقم الكرت'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          setState(() {
                            _searchType = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _sortBy,
                        decoration: const InputDecoration(
                          labelText: 'الفرز',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'name',
                            child: Text('حسب الاسم'),
                          ),
                          DropdownMenuItem(
                            value: 'number',
                            child: Text('حسب الرقم'),
                          ),
                          DropdownMenuItem(
                            value: 'profile',
                            child: Text('حسب البروفايل'),
                          ),
                          DropdownMenuItem(
                            value: 'duration',
                            child: Text('حسب المدة'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;

                          _changeSort(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (widget.profile != null)
                  DropdownButtonFormField<String?>(
                    initialValue: _selectedProfile,
                    decoration: const InputDecoration(
                      labelText: 'البروفايل',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      const DropdownMenuItem<String?>(
                        value: null,
                        child: Text('كل البروفايلات'),
                      ),
                      DropdownMenuItem<String?>(
                        value: widget.profile,
                        child: Text(widget.profile!),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedProfile = value;
                      });
                    },
                  ),
                if (widget.profile != null)
                  const SizedBox(height: 10),
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: _searchType == 'name'
                        ? 'اسم المستخدم'
                        : 'رقم الكرت',
                    hintText: _searchType == 'name'
                        ? 'مثال: 63134750'
                        : 'مثال: 63134750',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: _loading ? null : _searchUsers,
                      icon: const Icon(Icons.arrow_forward),
                    ),
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _searchUsers(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _loading ? null : _searchUsers,
                        icon: const Icon(Icons.search),
                        label: const Text('بحث عن كرت'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed:
                        _loading ? null : _loadByProfile,
                        icon: const Icon(Icons.folder),
                        label: const Text('جلب البروفايل'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _loading ? null : _loadAllUsers,
                    icon: const Icon(Icons.list_alt),
                    label: const Text(
                      '📋 جلب جميع الكروت',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _users.isEmpty
                            ? 'لم يتم تحميل نتائج بعد'
                            : _allLoaded
                            ? 'تم تحميل جميع النتائج: ${_users.length}'
                            : 'عدد النتائج: ${_users.length}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _users.isEmpty
                          ? null
                          : () {
                        setState(() {
                          _ascending = !_ascending;
                          _sortUsers();
                        });
                      },
                      icon: Icon(
                        _ascending
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                      ),
                      label: const Text('عكس الترتيب'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_loading) const LinearProgressIndicator(),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.all(15),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 45,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 10),
                      FilledButton.icon(
                        onPressed: _loadAllUsers,
                        icon: const Icon(Icons.refresh),
                        label: const Text('إعادة المحاولة'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (!_loading && _error == null && _users.isEmpty)
            const Expanded(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.manage_search,
                        size: 70,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 15),
                      Text(
                        'ابحث عن كرت أو جلب جميع الكروت',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'لن يتم تحميل جميع الكروت تلقائيًا، وذلك لتجنب الضغط على الراوتر.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (_users.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                  bottom: 20,
                ),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];

                  final username = user['name'] ?? '-';
                  final profile = user['profile'] ?? '-';
                  final password = user['password'] ?? '';
                  final limitBytes =
                      user['limit-bytes-total'] ?? '-';
                  final limitUptime = user['limit-uptime'] ?? '-';

                  final disabled = user['disabled'] == 'yes' ||
                      user['disabled'] == 'true';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ExpansionTile(
                      leading: CircleAvatar(
                        child: Icon(
                          disabled ? Icons.block : Icons.person,
                        ),
                      ),
                      title: Text(
                        username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text('Profile: $profile'),
                      children: [
                        _userDetailRow('Username', username),
                        _userDetailRow('Password', password),
                        _userDetailRow('Profile', profile),
                        _userDetailRow('Limit Bytes', limitBytes),
                        _userDetailRow('Limit Uptime', limitUptime),
                        _userDetailRow(
                          'Disabled',
                          disabled ? 'نعم' : 'لا',
                        ),
                        _userDetailRow(
                          'Comment',
                          user['comment'] ?? '-',
                        ),
                        const SizedBox(height: 8),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () {
                                    _editUser(user);
                                  },
                                  icon: const Icon(Icons.edit),
                                  label: const Text('تعديل'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () {
                                    _deleteUser(user);
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  icon: const Icon(Icons.delete),
                                  label: const Text('حذف'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
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
        : ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: _filteredUsers.length,
      itemBuilder: (context, index) {
        final user = _filteredUsers[index];

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
        },
    ),
    ),
            ],
        ),
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
      appBar: AppBar(
        title: const Text('⚙️ إعدادات الراوتر'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(
            context,
            '🌐 إعدادات الاتصال',
          ),

          _settingsTile(
            context,
            icon: Icons.lan,
            title: 'Local',
            subtitle: 'إعداد الاتصال المحلي بالراوتر',
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
            onTap: () {
              _showComingSoon(
                context,
                'إعدادات Cloud',
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.vpn_lock,
            title: 'VPN',
            subtitle: 'L2TP، PPTP، WireGuard',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VpnPage(api: api),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          _sectionTitle(
            context,
            '📡 إعدادات MikroTik',
          ),

          _settingsTile(
            context,
            icon: Icons.auto_fix_high,
            title: '📶 Hotspot Setup',
            subtitle: 'معالج إعداد Hotspot كامل + الإدارة',
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
            icon: Icons.list_alt,
            title: 'Profiles',
            subtitle: 'عرض وتعديل Hotspot Profiles',
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
            icon: Icons.dns,
            title: 'RADIUS',
            subtitle: 'إعداد RADIUS والمصادقة والمحاسبة',
            onTap: () {
              _showComingSoon(
                context,
                'إعدادات RADIUS',
              );
            },
          ),
          _settingsTile(
            context,
            icon: Icons.settings_applications,
            title: 'IP و DHCP و DNS',
            subtitle: 'إدارة شبكات DHCP وإعدادات DNS',
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
            onTap: () {
              _showComingSoon(
                context,
                'Firewall و NAT',
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.cable,
            title: 'الواجهات (Interfaces)',
            subtitle: 'عرض وإدارة واجهات الشبكة',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => InterfacesPage(api: api),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          _sectionTitle(
            context,
            '🛠️ إدارة الراوتر',
          ),
          _settingsTile(
            context,
            icon: Icons.key,
            title: 'المستخدمون وكلمات المرور',
            subtitle: 'عرض وتعديل مستخدمي MikroTik',
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
            onTap: () {
              _confirmAction(
                context,
                title: 'إعادة تشغيل الراوتر',
                message:
                'هل أنت متأكد أنك تريد إعادة تشغيل الراوتر؟',
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
                            content: Text(
                              'فشل إعادة تشغيل الراوتر: $e',
                            ),
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
            onTap: () {
              _confirmAction(
                context,
                title: 'إيقاف تشغيل الراوتر',
                message:
                'هل أنت متأكد أنك تريد إيقاف تشغيل الراوتر؟',
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
                            content: Text(
                              'فشل إيقاف تشغيل الراوتر: $e',
                            ),
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
            subtitle:
            'النسخ الاحتياطي واستعادة إعدادات الراوتر',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BackupRestorePage(
                    api: api,
                    host: router['host']?.toString() ?? '',
                    username:
                    router['username']?.toString() ?? '',
                    password:
                    router['password']?.toString() ?? '',
                  ),
                ),
              );
            },
          ),

          _settingsTile(
            context,
            icon: Icons.warning_amber_rounded,
            title: 'إعادة ضبط المصنع',
            subtitle:
            'حذف إعدادات الراوتر وإعادته للوضع الافتراضي',
            danger: true,
            onTap: () {
              _confirmAction(
                context,
                title: '⚠️ إعادة ضبط المصنع',
                message:
                'هذا الإجراء خطير وقد يؤدي إلى فقدان إعدادات الراوتر وفقدان الاتصال به.\n\nهل تريد المتابعة؟',
                actionText: 'متابعة',
                onConfirm: () {
                  _showComingSoon(
                    context,
                    'إعادة ضبط المصنع',
                  );
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
      ) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 8,
        top: 4,
      ),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(
          fontWeight: FontWeight.bold,
        ),
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
      }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 4,
        ),
        leading: CircleAvatar(
          child: Icon(
            icon,
            color: danger ? Colors.red : null,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: danger ? Colors.red : null,
          ),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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