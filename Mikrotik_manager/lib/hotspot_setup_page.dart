import 'package:flutter/material.dart';
import 'mikrotik_api.dart';

// =============================================================================
// Hotspot Page - الشاشة الرئيسية
// =============================================================================

class HotspotPage extends StatefulWidget {
  final MikroTikApi api;

  const HotspotPage({
    super.key,
    required this.api,
  });

  @override
  State<HotspotPage> createState() => _HotspotPageState();
}

class _HotspotPageState extends State<HotspotPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📶 Hotspot'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Setup', icon: Icon(Icons.auto_fix_high, size: 18)),
            Tab(text: 'Servers', icon: Icon(Icons.dns, size: 18)),
            Tab(text: 'Active', icon: Icon(Icons.wifi, size: 18)),
            Tab(text: 'Hosts', icon: Icon(Icons.devices, size: 18)),
            Tab(text: 'Bindings', icon: Icon(Icons.link, size: 18)),
            Tab(text: 'Walled Garden', icon: Icon(Icons.yard, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          HotspotSetupTab(api: widget.api),
          HotspotServersTab(api: widget.api),
          HotspotActiveTab(api: widget.api),
          HotspotHostsTab(api: widget.api),
          HotspotIpBindingsTab(api: widget.api),
          HotspotWalledGardenTab(api: widget.api),
        ],
      ),
    );
  }
}

// =============================================================================
// Hotspot Setup Tab - معالج الإعداد
// =============================================================================

class HotspotSetupTab extends StatefulWidget {
  final MikroTikApi api;
  const HotspotSetupTab({super.key, required this.api});

  @override
  State<HotspotSetupTab> createState() => _HotspotSetupTabState();
}

class _HotspotSetupTabState extends State<HotspotSetupTab> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController(text: 'hotspot1');
  final _poolNameController = TextEditingController(text: 'hs-pool-1');
  final _poolRangeController = TextEditingController(
    text: '192.168.88.10-192.168.88.254',
  );
  final _dnsNameController = TextEditingController(text: 'hotspot.local');

  String? _selectedInterface;
  List<Map<String, String>> _interfaces = [];
  bool _loadingInterfaces = true;

  bool _setting = false;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _loadInterfaces();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _poolNameController.dispose();
    _poolRangeController.dispose();
    _dnsNameController.dispose();
    super.dispose();
  }

  Future<void> _loadInterfaces() async {
    if (!mounted) return;
    setState(() => _loadingInterfaces = true);

    try {
      final items = await widget.api.getInterfaces();
      final usable = items.where((item) {
        final type = item['type'] ?? '';
        final running = item['running'] == 'true';
        final disabled = item['disabled'] == 'true';

        return (type.startsWith('ether') ||
            type == 'bridge' ||
            type.contains('wlan')) &&
            running &&
            !disabled;
      }).toList();

      if (!mounted) return;
      setState(() {
        _interfaces = usable;
        _loadingInterfaces = false;
        if (usable.isNotEmpty && _selectedInterface == null) {
          _selectedInterface = usable.first['name'];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingInterfaces = false);
    }
  }

  Future<void> _runSetup() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedInterface == null) {
      _showMessage('اختر واجهة أولاً', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ تأكيد الإعداد'),
        content: Text(
          'سيتم:\n\n'
              '1. إنشاء IP Pool باسم: ${_poolNameController.text}\n'
              '2. إنشاء Hotspot باسم: ${_nameController.text}\n'
              '3. تفعيل DNS\n\n'
              'على الواجهة: $_selectedInterface\n\n'
              'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('متابعة'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _setting = true;
      _result = null;
    });

    try {
      final result = await widget.api.setupHotspot(
        interface: _selectedInterface!,
        hotspotName: _nameController.text.trim(),
        poolName: _poolNameController.text.trim(),
        poolRange: _poolRangeController.text.trim(),
        dnsName: _dnsNameController.text.trim(),
      );

      if (!mounted) return;
      setState(() {
        _result = result;
        _setting = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _setting = false);
      _showMessage('فشل الإعداد: $e', isError: true);
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
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.blue.shade50,
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 30),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'معالج إنشاء Hotspot كامل\n'
                        'سيُنشئ IP Pool + Hotspot Server + DNS تلقائياً',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),

        const Text(
          '📡 الواجهة',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),

        if (_loadingInterfaces)
          const LinearProgressIndicator()
        else if (_interfaces.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'لا توجد واجهات متاحة. تأكد من اتصال الواجهات.',
                style: TextStyle(color: Colors.red),
              ),
            ),
          )
        else
          DropdownButtonFormField<String>(
            initialValue: _selectedInterface,
            decoration: const InputDecoration(
              labelText: 'الواجهة *',
              border: OutlineInputBorder(),
            ),
            items: _interfaces.map((item) {
              final name = item['name'] ?? '';
              final type = item['type'] ?? '';
              return DropdownMenuItem(
                value: name,
                child: Text('$name ($type)'),
              );
            }).toList(),
            onChanged: (v) => setState(() => _selectedInterface = v),
          ),

        const SizedBox(height: 20),

        Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                '⚙️ الإعدادات',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم Hotspot',
                  hintText: 'hotspot1',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _poolNameController,
                decoration: const InputDecoration(
                  labelText: 'اسم IP Pool',
                  hintText: 'hs-pool-1',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _poolRangeController,
                decoration: const InputDecoration(
                  labelText: 'نطاق IP Pool',
                  hintText: '192.168.88.10-192.168.88.254',
                  border: OutlineInputBorder(),
                  helperText: 'من - إلى',
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _dnsNameController,
                decoration: const InputDecoration(
                  labelText: 'DNS Name',
                  hintText: 'hotspot.local',
                  border: OutlineInputBorder(),
                  helperText: 'يظهر للعملاء بدلاً من IP',
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        SizedBox(
          height: 54,
          child: FilledButton.icon(
            onPressed:
            _setting || _interfaces.isEmpty ? null : _runSetup,
            icon: _setting
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
                : const Icon(Icons.play_arrow),
            label: Text(
              _setting ? 'جاري الإعداد...' : '🚀 بدء الإعداد',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),

        if (_result != null) ...[
          const SizedBox(height: 20),
          Card(
            color: _result!['serverCreated'] == true
                ? Colors.green.shade50
                : Colors.orange.shade50,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _result!['serverCreated'] == true
                            ? Icons.check_circle
                            : Icons.warning,
                        color: _result!['serverCreated'] == true
                            ? Colors.green
                            : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'نتيجة الإعداد',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                  _resultRow(
                    'IP Pool',
                    _result!['poolCreated'] == true,
                  ),
                  _resultRow(
                    'Hotspot Server',
                    _result!['serverCreated'] == true,
                  ),
                  _resultRow(
                    'DNS',
                    _result!['dnsEnabled'] == true,
                  ),
                  if ((_result!['errors'] as List).isNotEmpty) ...[
                    const Divider(),
                    const Text(
                      'الأخطاء:',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ...(_result!['errors'] as List).map(
                          (e) => Text(
                        '• $e',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _resultRow(String label, bool success) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            success ? Icons.check : Icons.close,
            color: success ? Colors.green : Colors.red,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(label),
        ],
      ),
    );
  }
}

// =============================================================================
// Hotspot Servers Tab
// =============================================================================

class HotspotServersTab extends StatefulWidget {
  final MikroTikApi api;
  const HotspotServersTab({super.key, required this.api});

  @override
  State<HotspotServersTab> createState() => _HotspotServersTabState();
}

class _HotspotServersTabState extends State<HotspotServersTab> {
  List<Map<String, String>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.api.getHotspotServers();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _toggle(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;
    final disabled = item['disabled'] == 'true';

    try {
      await widget.api.updateHotspotServer(id: id, disabled: !disabled);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _delete(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف Hotspot Server'),
        content: Text('هل تريد حذف "${item['name']}"؟'),
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
      await widget.api.deleteHotspotServer(id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_items.isEmpty)
          const Center(child: Text('لا توجد Hotspot Servers'))
        else
          ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];
              final disabled = item['disabled'] == 'true';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: disabled
                        ? Colors.red.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      Icons.dns,
                      color: disabled ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                    item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Interface: ${item['interface'] ?? '-'}'),
                      Text('Pool: ${item['address-pool'] ?? '-'}'),
                      if ((item['profile'] ?? '').isNotEmpty)
                        Text('Profile: ${item['profile']}'),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Switch(
                        value: !disabled,
                        onChanged: (_) => _toggle(item),
                      ),
                      IconButton(
                        onPressed: () => _delete(item),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _load,
            child: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Hotspot Active Tab - المتصلون الآن
// =============================================================================

class HotspotActiveTab extends StatefulWidget {
  final MikroTikApi api;
  const HotspotActiveTab({super.key, required this.api});

  @override
  State<HotspotActiveTab> createState() => _HotspotActiveTabState();
}

class _HotspotActiveTabState extends State<HotspotActiveTab> {
  List<Map<String, String>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.api.getConnectedUsers();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _disconnect(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('فصل المستخدم'),
        content: Text('هل تريد فصل "${item['user'] ?? item['name']}"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('فصل'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.api.disconnectHotspotUser(id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _items.isEmpty
          ? const Center(child: Text('لا يوجد متصلون الآن'))
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const CircleAvatar(
                backgroundColor: Colors.green,
                child: Icon(Icons.wifi, color: Colors.white),
              ),
              title: Text(
                item['user'] ?? item['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((item['address'] ?? '').isNotEmpty)
                    Text('IP: ${item['address']}'),
                  if ((item['mac-address'] ?? '').isNotEmpty)
                    Text('MAC: ${item['mac-address']}'),
                  if ((item['uptime'] ?? '').isNotEmpty)
                    Text('المدة: ${item['uptime']}'),
                ],
              ),
              trailing: IconButton(
                onPressed: () => _disconnect(item),
                tooltip: 'فصل',
                icon: const Icon(Icons.link_off, color: Colors.red),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// =============================================================================
// Hotspot Hosts Tab
// =============================================================================

class HotspotHostsTab extends StatefulWidget {
  final MikroTikApi api;
  const HotspotHostsTab({super.key, required this.api});

  @override
  State<HotspotHostsTab> createState() => _HotspotHostsTabState();
}

class _HotspotHostsTabState extends State<HotspotHostsTab> {
  List<Map<String, String>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.api.getHotspotHosts();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _toggleBypass(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final bypassed = item['bypassed'] == 'true';

    try {
      await widget.api.makeHostBypassed(id, bypassed: !bypassed);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: _items.isEmpty
          ? const Center(child: Text('لا توجد أجهزة مكتشفة'))
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          final bypassed = item['bypassed'] == 'true';
          final authorized = item['authorized'] == 'true';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: bypassed
                    ? Colors.orange.shade100
                    : authorized
                    ? Colors.green.shade100
                    : Colors.grey.shade300,
                child: Icon(
                  bypassed
                      ? Icons.flash_on
                      : authorized
                      ? Icons.check_circle
                      : Icons.devices,
                  color: bypassed
                      ? Colors.orange
                      : authorized
                      ? Colors.green
                      : Colors.grey,
                ),
              ),
              title: Text(
                item['mac-address'] ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                  fontSize: 13,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((item['address'] ?? '').isNotEmpty)
                    Text('IP: ${item['address']}'),
                  if ((item['uptime'] ?? '').isNotEmpty)
                    Text('المدة: ${item['uptime']}'),
                  Text(
                    bypassed
                        ? 'متجاوز (بدون تسجيل دخول)'
                        : authorized
                        ? 'مُصرّح'
                        : 'غير مُصرّح',
                    style: TextStyle(
                      fontSize: 11,
                      color: bypassed
                          ? Colors.orange
                          : authorized
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
              trailing: IconButton(
                onPressed: () => _toggleBypass(item),
                tooltip: bypassed ? 'إلغاء التجاوز' : 'تجاوز',
                icon: Icon(
                  bypassed ? Icons.flash_off : Icons.flash_on,
                  color: bypassed ? Colors.grey : Colors.orange,
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _load,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

// =============================================================================
// Hotspot IP Bindings Tab
// =============================================================================

class HotspotIpBindingsTab extends StatefulWidget {
  final MikroTikApi api;
  const HotspotIpBindingsTab({super.key, required this.api});

  @override
  State<HotspotIpBindingsTab> createState() => _HotspotIpBindingsTabState();
}

class _HotspotIpBindingsTabState extends State<HotspotIpBindingsTab> {
  List<Map<String, String>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.api.getHotspotIpBindings();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _delete(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف Binding'),
        content: Text(
          'هل تريد حذف "${item['mac-address'] ?? item['address']}"؟',
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
      await widget.api.deleteHotspotIpBinding(id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_items.isEmpty)
          const Center(child: Text('لا توجد Bindings'))
        else
          ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];
              final type = item['type'] ?? '';
              final isBypassed = type == 'bypassed';
              final isBlocked = type == 'blocked';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isBlocked
                        ? Colors.red.shade100
                        : isBypassed
                        ? Colors.orange.shade100
                        : Colors.green.shade100,
                    child: Icon(
                      isBlocked
                          ? Icons.block
                          : isBypassed
                          ? Icons.flash_on
                          : Icons.check,
                      color: isBlocked
                          ? Colors.red
                          : isBypassed
                          ? Colors.orange
                          : Colors.green,
                    ),
                  ),
                  title: Text(
                    item['mac-address'] ?? item['address'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('النوع: $type'),
                      if ((item['address'] ?? '').isNotEmpty)
                        Text('IP: ${item['address']}'),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () => _delete(item),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ),
              );
            },
          ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _load,
            child: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Hotspot Walled Garden Tab
// =============================================================================

class HotspotWalledGardenTab extends StatefulWidget {
  final MikroTikApi api;
  const HotspotWalledGardenTab({super.key, required this.api});

  @override
  State<HotspotWalledGardenTab> createState() =>
      _HotspotWalledGardenTabState();
}

class _HotspotWalledGardenTabState extends State<HotspotWalledGardenTab> {
  List<Map<String, String>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await widget.api.getHotspotWalledGarden();
      if (!mounted) return;
      setState(() {
        _items = items;
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

  Future<void> _delete(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القاعدة'),
        content: Text('هل تريد حذف "${item['dst-host'] ?? item['dst-address']}"؟'),
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
      await widget.api.deleteHotspotWalledGarden(id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
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
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        if (_items.isEmpty)
          const Center(child: Text('لا توجد قواعد'))
        else
          ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];
              final action = item['action'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: action == 'allow'
                        ? Colors.green.shade100
                        : Colors.red.shade100,
                    child: Icon(
                      action == 'allow' ? Icons.check : Icons.block,
                      color: action == 'allow' ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                    item['dst-host'] ??
                        item['dst-address'] ??
                        'قاعدة',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('العملية: $action'),
                      if ((item['comment'] ?? '').isNotEmpty)
                        Text(
                          item['comment']!,
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                  trailing: IconButton(
                    onPressed: () => _delete(item),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ),
              );
            },
          ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: _load,
            child: const Icon(Icons.refresh),
          ),
        ),
      ],
    );
  }
}