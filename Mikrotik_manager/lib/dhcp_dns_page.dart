import 'package:flutter/material.dart';
import 'mikrotik_api.dart';

// =============================================================================
// DHCP DNS Page - تبويبات DHCP و DNS
// =============================================================================

class DhcpDnsPage extends StatefulWidget {
  final MikroTikApi api;

  const DhcpDnsPage({
    super.key,
    required this.api,
  });

  @override
  State<DhcpDnsPage> createState() => _DhcpDnsPageState();
}

class _DhcpDnsPageState extends State<DhcpDnsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        title: const Text('📡 DHCP / DNS'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.wifi_tethering), text: 'DHCP'),
            Tab(icon: Icon(Icons.dns), text: 'DNS'),
            Tab(icon: Icon(Icons.lan), text: 'IP'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          DhcpTab(api: widget.api),
          DnsTab(api: widget.api),
          IpTab(api: widget.api),
        ],
      ),
    );
  }
}

// =============================================================================
// DHCP Tab
// =============================================================================

class DhcpTab extends StatefulWidget {
  final MikroTikApi api;

  const DhcpTab({super.key, required this.api});

  @override
  State<DhcpTab> createState() => _DhcpTabState();
}

class _DhcpTabState extends State<DhcpTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          tabs: const [
            Tab(text: 'Leases'),
            Tab(text: 'Networks'),
            Tab(text: 'Servers'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              DhcpLeasesTab(api: widget.api),
              DhcpNetworksTab(api: widget.api),
              DhcpServersTab(api: widget.api),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// DHCP Leases Tab
// =============================================================================

class DhcpLeasesTab extends StatefulWidget {
  final MikroTikApi api;

  const DhcpLeasesTab({super.key, required this.api});

  @override
  State<DhcpLeasesTab> createState() => _DhcpLeasesTabState();
}

class _DhcpLeasesTabState extends State<DhcpLeasesTab> {
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
      final items = await widget.api.getDhcpLeases();
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

    final confirmed = await _confirmDelete(
      context,
      'حذف Lease',
      'هل تريد حذف العقد "${item['address']}"؟',
    );

    if (!confirmed) return;

    try {
      await widget.api.deleteDhcpLease(id);
      if (!mounted) return;
      _showMessage('تم الحذف ✅');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return _buildError(_error!, _load);
    if (_items.isEmpty) return const Center(child: Text('لا توجد Leases'));

    return Stack(
      children: [
        ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: _items.length,
          itemBuilder: (context, i) {
            final item = _items[i];
            final status = item['status'] ?? '';
            final isBound = status == 'bound';
            final isDynamic = item['dynamic'] == 'true';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  isBound ? Colors.green.shade100 : Colors.grey.shade300,
                  child: Icon(
                    isBound ? Icons.check_circle : Icons.hourglass_empty,
                    color: isBound ? Colors.green : Colors.grey,
                  ),
                ),
                title: Row(
                  children: [
                    Text(
                      item['address'] ?? '',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (isDynamic)
                      const Padding(
                        padding: EdgeInsets.only(right: 6),
                        child: Icon(Icons.bolt, size: 14, color: Colors.orange),
                      ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MAC: ${item['mac-address'] ?? '-'}'),
                    if ((item['host-name'] ?? '').isNotEmpty)
                      Text('Host: ${item['host-name']}'),
                    if ((item['comment'] ?? '').isNotEmpty)
                      Text(
                        item['comment']!,
                        style: const TextStyle(fontSize: 11),
                      ),
                  ],
                ),
                trailing: isDynamic
                    ? null
                    : IconButton(
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
            onPressed: () => _openAdd(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }

  Future<void> _openAdd() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => const _AddLeaseDialog(),
    );

    if (result == true) await _load();
  }

  Widget _buildError(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 15),
            Text(error, textAlign: TextAlign.center),
            const SizedBox(height: 15),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ));
  }

  Future<bool> _confirmDelete(
      BuildContext context, String title, String content) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
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
    return result == true;
  }
}

// =============================================================================
// DHCP Networks Tab
// =============================================================================

class DhcpNetworksTab extends StatefulWidget {
  final MikroTikApi api;
  const DhcpNetworksTab({super.key, required this.api});

  @override
  State<DhcpNetworksTab> createState() => _DhcpNetworksTabState();
}

class _DhcpNetworksTabState extends State<DhcpNetworksTab> {
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
      final items = await widget.api.getDhcpNetworks();
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
    if (_items.isEmpty) return const Center(child: Text('لا توجد Networks'));

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final item = _items[i];

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.network_check)),
            title: Text(
              item['address'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if ((item['gateway'] ?? '').isNotEmpty)
                  Text('Gateway: ${item['gateway']}'),
                if ((item['dns-server'] ?? '').isNotEmpty)
                  Text('DNS: ${item['dns-server']}'),
                if ((item['comment'] ?? '').isNotEmpty)
                  Text(item['comment']!, style: const TextStyle(fontSize: 11)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// DHCP Servers Tab
// =============================================================================

class DhcpServersTab extends StatefulWidget {
  final MikroTikApi api;
  const DhcpServersTab({super.key, required this.api});

  @override
  State<DhcpServersTab> createState() => _DhcpServersTabState();
}

class _DhcpServersTabState extends State<DhcpServersTab> {
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
      final items = await widget.api.getDhcpServers();
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

    final current = item['disabled'] == 'true';
    try {
      await widget.api.updateDhcpServer(id: id, disabled: !current);
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
    if (_items.isEmpty) return const Center(child: Text('لا توجد Servers'));

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final item = _items[i];
        final disabled = item['disabled'] == 'true';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: disabled ? Colors.red.shade100 : Colors.green.shade100,
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
                if ((item['lease-time'] ?? '').isNotEmpty)
                  Text('Lease: ${item['lease-time']}'),
              ],
            ),
            trailing: Switch(
              value: !disabled,
              onChanged: (_) => _toggle(item),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// DNS Tab
// =============================================================================

class DnsTab extends StatefulWidget {
  final MikroTikApi api;
  const DnsTab({super.key, required this.api});

  @override
  State<DnsTab> createState() => _DnsTabState();
}

class _DnsTabState extends State<DnsTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          tabs: const [
            Tab(text: 'Settings'),
            Tab(text: 'Static Entries'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              DnsSettingsTab(api: widget.api),
              DnsStaticTab(api: widget.api),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// DNS Settings
// =============================================================================

class DnsSettingsTab extends StatefulWidget {
  final MikroTikApi api;
  const DnsSettingsTab({super.key, required this.api});

  @override
  State<DnsSettingsTab> createState() => _DnsSettingsTabState();
}

class _DnsSettingsTabState extends State<DnsSettingsTab> {
  final _formKey = GlobalKey<FormState>();
  final _serversController = TextEditingController();

  bool _allowRemote = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _serversController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final settings = await widget.api.getDnsSettings();
      if (!mounted) return;

      setState(() {
        _serversController.text = settings['servers'] ?? '';
        _allowRemote = settings['allow-remote-requests'] == 'true';
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.api.updateDnsSettings(
        servers: _serversController.text.trim(),
        allowRemoteRequests: _allowRemote,
      );

      if (!mounted) return;
      _showMessage('تم الحفظ ✅');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل: $e', isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
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

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            '🌐 إعدادات DNS',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          TextFormField(
            controller: _serversController,
            decoration: const InputDecoration(
              labelText: 'DNS Servers',
              hintText: 'مثال: 8.8.8.8,1.1.1.1',
              border: OutlineInputBorder(),
              helperText: 'افصل بين السيرفرات بفاصلة',
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: SwitchListTile(
              title: const Text('Allow Remote Requests'),
              subtitle: const Text(
                'السماح للعملاء باستخدام الراوتر كـ DNS',
              ),
              value: _allowRemote,
              onChanged: (v) => setState(() => _allowRemote = v),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              icon: _saving
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.save),
              label: Text(_saving ? 'جاري الحفظ...' : 'حفظ التغييرات'),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// DNS Static Entries
// =============================================================================

class DnsStaticTab extends StatefulWidget {
  final MikroTikApi api;
  const DnsStaticTab({super.key, required this.api});

  @override
  State<DnsStaticTab> createState() => _DnsStaticTabState();
}

class _DnsStaticTabState extends State<DnsStaticTab> {
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
      final items = await widget.api.getDnsStaticEntries();
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
        title: const Text('حذف الإدخال'),
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
      await widget.api.deleteDnsStaticEntry(id);
      if (!mounted) return;
      _showMessage('تم الحذف ✅');
      await _load();
    } catch (e) {
      if (!mounted) return;
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
          const Center(child: Text('لا توجد إدخالات ثابتة'))
        else
          ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.dns)),
                  title: Text(
                    item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('→ ${item['address'] ?? '-'}'),
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
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (_) => _AddDnsStaticDialog(api: widget.api),
              );
              if (result == true) await _load();
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Add Lease Dialog
// =============================================================================

class _AddLeaseDialog extends StatefulWidget {
  const _AddLeaseDialog();

  @override
  State<_AddLeaseDialog> createState() => _AddLeaseDialogState();
}

class _AddLeaseDialogState extends State<_AddLeaseDialog> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _macController = TextEditingController();
  final _commentController = TextEditingController();

  @override
  void dispose() {
    _addressController.dispose();
    _macController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة Lease'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.100',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _macController,
              decoration: const InputDecoration(
                labelText: 'MAC Address',
                hintText: 'AA:BB:CC:DD:EE:FF',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('إضافة'),
        ),
      ],
    );
  }
}

// =============================================================================
// Add DNS Static Dialog
// =============================================================================

class _AddDnsStaticDialog extends StatefulWidget {
  final MikroTikApi api;
  const _AddDnsStaticDialog({required this.api});

  @override
  State<_AddDnsStaticDialog> createState() => _AddDnsStaticDialogState();
}

class _AddDnsStaticDialogState extends State<_AddDnsStaticDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _commentController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.api.addDnsStaticEntry(
        name: _nameController.text.trim(),
        address: _addressController.text.trim(),
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة DNS Entry'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'example.com',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: '192.168.1.10',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('إضافة'),
        ),
      ],
    );
  }
}

// =============================================================================
// DHCP Clients Tab
// =============================================================================

class DhcpClientsTab extends StatefulWidget {
  final MikroTikApi api;
  const DhcpClientsTab({super.key, required this.api});

  @override
  State<DhcpClientsTab> createState() => _DhcpClientsTabState();
}

class _DhcpClientsTabState extends State<DhcpClientsTab> {
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
      final items = await widget.api.getDhcpClients();
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
  Future<void> _openDialog({Map<String, String>? item}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _DhcpClientDialog(
        api: widget.api,
        existing: item,
      ),
    );

    if (result == true) await _load();
  }

  Future<void> _delete(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف DHCP Client'),
        content: Text('هل تريد حذف "${item['interface']}"؟'),
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
      await widget.api.deleteDhcpClient(id);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }
  Future<void> _toggle(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final current = item['disabled'] == 'true';

    try {
      await widget.api.updateDhcpClient(
        id: id,
        disabled: !current,
      );
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
          const Center(child: Text('لا يوجد DHCP Clients'))
        else
          ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];
              final disabled = item['disabled'] == 'true';
              final status = item['status'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: disabled
                        ? Colors.red.shade100
                        : status == 'bound'
                        ? Colors.green.shade100
                        : Colors.grey.shade300,
                    child: Icon(
                      Icons.cloud_download,
                      color: disabled
                          ? Colors.red
                          : status == 'bound'
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
                  title: Text(
                    item['interface'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((item['address'] ?? '').isNotEmpty)
                        Text(
                          'IP: ${item['address']}',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      if ((item['gateway'] ?? '').isNotEmpty)
                        Text('Gateway: ${item['gateway']}'),
                      Text(
                        'الحالة: $status',
                        style: TextStyle(
                          fontSize: 11,
                          color: status == 'bound'
                              ? Colors.green
                              : Colors.grey,
                        ),
                      ),
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
                        onPressed: () => _openDialog(item: item),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      IconButton(
                        onPressed: () => _delete(item),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                  onTap: () => _openDialog(item: item),
                ),
              );
            },
          ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () => _openDialog(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// IP Addresses Tab
// =============================================================================

class IpAddressesTab extends StatefulWidget {
  final MikroTikApi api;
  const IpAddressesTab({super.key, required this.api});

  @override
  State<IpAddressesTab> createState() => _IpAddressesTabState();
}

class _IpAddressesTabState extends State<IpAddressesTab> {
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
      final items = await widget.api.getIpAddresses();
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
  Future<void> _openDialog({Map<String, String>? item}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _IpAddressDialog(
        api: widget.api,
        existing: item,
      ),
    );

    if (result == true) await _load();
  }
  Future<void> _delete(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف العنوان'),
        content: Text('هل تريد حذف "${item['address']}"؟'),
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
      await widget.api.deleteIpAddress(id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحذف ✅')),
      );
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
          const Center(child: Text('لا توجد عناوين IP'))
        else
          ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];
              final isDynamic = item['dynamic'] == 'true';
              final disabled = item['disabled'] == 'true';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: disabled
                        ? Colors.red.shade100
                        : isDynamic
                        ? Colors.orange.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      Icons.lan,
                      color: disabled
                          ? Colors.red
                          : isDynamic
                          ? Colors.orange
                          : Colors.blue,
                    ),
                  ),
                  title: Text(
                    item['address'] ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Interface: ${item['interface'] ?? '-'}'),
                      if ((item['network'] ?? '').isNotEmpty)
                        Text('Network: ${item['network']}'),
                      if ((item['comment'] ?? '').isNotEmpty)
                        Text(
                          item['comment']!,
                          style: const TextStyle(fontSize: 11),
                        ),
                    ],
                  ),
                  trailing: isDynamic
                      ? const Icon(Icons.bolt, color: Colors.orange)
                      : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () => _openDialog(item: item),
                        icon: const Icon(Icons.edit, color: Colors.blue),
                      ),
                      IconButton(
                        onPressed: () => _delete(item),
                        icon: const Icon(Icons.delete, color: Colors.red),
                      ),
                    ],
                  ),
                  onTap: isDynamic ? null : () => _openDialog(item: item),
                ),
              );
            },
          ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            onPressed: () => _openDialog(),
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// IP Pools Tab
// =============================================================================

class IpPoolsTab extends StatefulWidget {
  final MikroTikApi api;
  const IpPoolsTab({super.key, required this.api});

  @override
  State<IpPoolsTab> createState() => _IpPoolsTabState();
}

class _IpPoolsTabState extends State<IpPoolsTab> {
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
      final items = await widget.api.getIpPools();
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
        title: const Text('حذف Pool'),
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
      await widget.api.deleteIpPool(id);
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحذف ✅')),
      );
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
          const Center(child: Text('لا توجد IP Pools'))
        else
          ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: _items.length,
            itemBuilder: (context, i) {
              final item = _items[i];

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.storage),
                  ),
                  title: Text(
                    item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['ranges'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                        ),
                      ),
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
            onPressed: () async {
              final result = await showDialog<bool>(
                context: context,
                builder: (_) => _AddIpPoolDialog(api: widget.api),
              );
              if (result == true) await _load();
            },
            child: const Icon(Icons.add),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Add IP Pool Dialog
// =============================================================================

class _AddIpPoolDialog extends StatefulWidget {
  final MikroTikApi api;
  const _AddIpPoolDialog({required this.api});

  @override
  State<_AddIpPoolDialog> createState() => _AddIpPoolDialogState();
}

class _AddIpPoolDialogState extends State<_AddIpPoolDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rangesController = TextEditingController();
  final _commentController = TextEditingController();

  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _rangesController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.api.addIpPool(
        name: _nameController.text.trim(),
        ranges: _rangesController.text.trim(),
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('إضافة IP Pool'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'pool1',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _rangesController,
              decoration: const InputDecoration(
                labelText: 'Ranges',
                hintText: '192.168.1.10-192.168.1.100',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('إضافة'),
        ),
      ],
    );
  }
}

// =============================================================================
// Add / Edit IP Address Dialog
// =============================================================================

class _IpAddressDialog extends StatefulWidget {
  final MikroTikApi api;
  final Map<String, String>? existing;

  const _IpAddressDialog({
    required this.api,
    this.existing,
  });

  @override
  State<_IpAddressDialog> createState() => _IpAddressDialogState();
}

class _IpAddressDialogState extends State<_IpAddressDialog> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _interfaceController = TextEditingController();
  final _commentController = TextEditingController();

  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _addressController.text = widget.existing!['address'] ?? '';
      _interfaceController.text = widget.existing!['interface'] ?? '';
      _commentController.text = widget.existing!['comment'] ?? '';
    }
  }

  @override
  void dispose() {
    _addressController.dispose();
    _interfaceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await widget.api.updateIpAddress(
          id: widget.existing!['.id'] ?? '',
          address: _addressController.text.trim(),
          interface: _interfaceController.text.trim(),
          comment: _commentController.text.trim(),
        );
      } else {
        await widget.api.addIpAddress(
          address: _addressController.text.trim(),
          interface: _interfaceController.text.trim(),
          comment: _commentController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'تعديل IP Address' : 'إضافة IP Address'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'IP Address',
                hintText: '192.168.1.1/24',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _interfaceController,
              decoration: const InputDecoration(
                labelText: 'Interface',
                hintText: 'ether1',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(_isEditing ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }
}

// =============================================================================
// Add / Edit DHCP Client Dialog
// =============================================================================

class _DhcpClientDialog extends StatefulWidget {
  final MikroTikApi api;
  final Map<String, String>? existing;

  const _DhcpClientDialog({
    required this.api,
    this.existing,
  });

  @override
  State<_DhcpClientDialog> createState() => _DhcpClientDialogState();
}

class _DhcpClientDialogState extends State<_DhcpClientDialog> {
  final _formKey = GlobalKey<FormState>();
  final _interfaceController = TextEditingController();
  final _commentController = TextEditingController();

  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _interfaceController.text = widget.existing!['interface'] ?? '';
      _commentController.text = widget.existing!['comment'] ?? '';
    }
  }

  @override
  void dispose() {
    _interfaceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await widget.api.updateDhcpClient(
          id: widget.existing!['.id'] ?? '',
          interface: _interfaceController.text.trim(),
          comment: _commentController.text.trim(),
        );
      } else {
        await widget.api.addDhcpClient(
          interface: _interfaceController.text.trim(),
          comment: _commentController.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(_isEditing ? 'تعديل DHCP Client' : 'إضافة DHCP Client'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _interfaceController,
              decoration: const InputDecoration(
                labelText: 'Interface',
                hintText: 'ether1',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : Text(_isEditing ? 'حفظ' : 'إضافة'),
        ),
      ],
    );
  }
}

// =============================================================================
// Edit IP Pool Dialog
// =============================================================================

class _EditIpPoolDialog extends StatefulWidget {
  final MikroTikApi api;
  final Map<String, String> existing;

  const _EditIpPoolDialog({
    required this.api,
    required this.existing,
  });

  @override
  State<_EditIpPoolDialog> createState() => _EditIpPoolDialogState();
}

class _EditIpPoolDialogState extends State<_EditIpPoolDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _rangesController = TextEditingController();
  final _commentController = TextEditingController();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.existing['name'] ?? '';
    _rangesController.text = widget.existing['ranges'] ?? '';
    _commentController.text = widget.existing['comment'] ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _rangesController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      await widget.api.updateIpPool(
        id: widget.existing['.id'] ?? '',
        name: _nameController.text.trim(),
        ranges: _rangesController.text.trim(),
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('تعديل IP Pool'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _rangesController,
              decoration: const InputDecoration(
                labelText: 'Ranges',
                hintText: '192.168.1.10-192.168.1.100',
                border: OutlineInputBorder(),
              ),
              validator: (v) => v == null || v.isEmpty ? 'مطلوب' : null,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
              : const Text('حفظ'),
        ),
      ],
    );
  }
}

// =============================================================================
// IP Tab
// =============================================================================

class IpTab extends StatefulWidget {
  final MikroTikApi api;
  const IpTab({super.key, required this.api});

  @override
  State<IpTab> createState() => _IpTabState();
}

class _IpTabState extends State<IpTab>
    with SingleTickerProviderStateMixin {
  late final TabController _subTabController;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _subTabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: _subTabController,
          tabs: const [
            Tab(text: 'IP Pools'),
            Tab(text: 'IP Addresses'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              IpPoolsTab(api: widget.api),
              IpAddressesTab(api: widget.api),
            ],
          ),
        ),
      ],
    );
  }
}