import 'package:flutter/material.dart';
import 'mikrotik_api.dart';

// =============================================================================
// Interfaces Page
// =============================================================================

class InterfacesPage extends StatefulWidget {
  final MikroTikApi api;

  const InterfacesPage({
    super.key,
    required this.api,
  });

  @override
  State<InterfacesPage> createState() => _InterfacesPageState();
}

class _InterfacesPageState extends State<InterfacesPage> {
  late final MikroTikApi _api;

  List<Map<String, String>> _items = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _api = widget.api;
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final items = await _api.getInterfaces();
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

  List<Map<String, String>> get _filtered {
    if (_filter == 'all') return _items;

    return _items.where((item) {
      final type = item['type'] ?? '';

      switch (_filter) {
        case 'ether':
          return type.startsWith('ether');
        case 'bridge':
          return type == 'bridge';
        case 'vlan':
          return type == 'vlan';
        case 'wireless':
          return type.contains('wlan') || type.contains('wireless');
        case 'ppp':
          return type.startsWith('ppp') || type == 'l2tp-in' || type == 'pptp-in';
        default:
          return true;
      }
    }).toList();
  }

  Future<void> _toggle(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final current = item['disabled'] == 'true';

    try {
      await _api.updateInterface(id: id, disabled: !current);
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل: $e', isError: true);
    }
  }

  void _openDetails(Map<String, String> item) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => InterfaceDetailsPage(
          api: _api,
          interface: item,
        ),
      ),
    ).then((_) => _load());
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
        title: const Text('🔌 الواجهات'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildChip('all', 'الكل', _items.length),
                  _buildChip('ether', 'Ethernet', _countBy('ether')),
                  _buildChip('bridge', 'Bridge', _countBy('bridge')),
                  _buildChip('vlan', 'VLAN', _countBy('vlan')),
                  _buildChip('wireless', 'لاسلكي', _countBy('wireless')),
                  _buildChip('ppp', 'PPP', _countBy('ppp')),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
    );
  }

  int _countBy(String type) {
    return _items.where((item) {
      final t = item['type'] ?? '';
      switch (type) {
        case 'ether':
          return t.startsWith('ether');
        case 'bridge':
          return t == 'bridge';
        case 'vlan':
          return t == 'vlan';
        case 'wireless':
          return t.contains('wlan') || t.contains('wireless');
        case 'ppp':
          return t.startsWith('ppp') || t == 'l2tp-in' || t == 'pptp-in';
        default:
          return false;
      }
    }).length;
  }

  Widget _buildChip(String value, String label, int count) {
    final selected = _filter == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text('$label ($count)'),
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
      ),
    );
  }

  Widget _buildBody() {
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

    final items = _filtered;

    if (items.isEmpty) {
      return const Center(child: Text('لا توجد واجهات'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: items.length,
      itemBuilder: (context, i) {
        final item = items[i];
        final disabled = item['disabled'] == 'true';
        final running = item['running'] == 'true';
        final type = item['type'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: disabled
                  ? Colors.red.shade100
                  : running
                  ? Colors.green.shade100
                  : Colors.grey.shade300,
              child: Icon(
                _iconForType(type),
                color: disabled
                    ? Colors.red
                    : running
                    ? Colors.green
                    : Colors.grey,
              ),
            ),
            title: Text(
              item['name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'النوع: $type',
                  style: const TextStyle(fontSize: 12),
                ),
                Row(
                  children: [
                    Icon(
                      running ? Icons.check_circle : Icons.cancel,
                      size: 12,
                      color: running ? Colors.green : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      disabled
                          ? 'معطّلة'
                          : running
                          ? 'تعمل'
                          : 'متوقفة',
                      style: TextStyle(
                        fontSize: 11,
                        color: disabled
                            ? Colors.red
                            : running
                            ? Colors.green
                            : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            trailing: Switch(
              value: !disabled,
              onChanged: (_) => _toggle(item),
            ),
            onTap: () => _openDetails(item),
          ),
        );
      },
    );
  }

  IconData _iconForType(String type) {
    if (type.startsWith('ether')) return Icons.settings_ethernet;
    if (type == 'bridge') return Icons.device_hub;
    if (type == 'vlan') return Icons.account_tree;
    if (type.contains('wlan') || type.contains('wireless')) {
      return Icons.wifi;
    }
    if (type.startsWith('ppp') || type.contains('l2tp') || type.contains('pptp')) {
      return Icons.vpn_lock;
    }
    return Icons.cable;
  }
}

// =============================================================================
// Interface Details Page
// =============================================================================

class InterfaceDetailsPage extends StatefulWidget {
  final MikroTikApi api;
  final Map<String, String> interface;

  const InterfaceDetailsPage({
    super.key,
    required this.api,
    required this.interface,
  });

  @override
  State<InterfaceDetailsPage> createState() => _InterfaceDetailsPageState();
}

class _InterfaceDetailsPageState extends State<InterfaceDetailsPage> {
  late final MikroTikApi _api;

  final _nameController = TextEditingController();
  final _commentController = TextEditingController();

  List<Map<String, String>> _addresses = [];

  Map<String, String>? _traffic;

  bool _loadingDetails = true;
  bool _saving = false;
  bool _loadingTraffic = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api;

    _nameController.text = widget.interface['name'] ?? '';
    _commentController.text = widget.interface['comment'] ?? '';

    _loadDetails();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    if (!mounted) return;

    setState(() => _loadingDetails = true);

    try {
      final addresses = await _api.getInterfaceAddresses(
        widget.interface['name'] ?? '',
      );

      if (!mounted) return;

      setState(() {
        _addresses = addresses;
        _loadingDetails = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingDetails = false);
    }
  }

  Future<void> _refreshTraffic() async {
    if (_loadingTraffic) return;

    setState(() => _loadingTraffic = true);

    try {
      final traffic = await _api.getInterfaceTraffic(
        widget.interface['name'] ?? '',
      );

      if (!mounted) return;
      setState(() {
        _traffic = traffic;
        _loadingTraffic = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingTraffic = false);
    }
  }

  Future<void> _save() async {
    final id = widget.interface['.id'];
    if (id == null) return;

    setState(() => _saving = true);

    try {
      await _api.updateInterface(
        id: id,
        name: _nameController.text.trim(),
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;
      _showMessage('تم الحفظ ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('فشل: $e', isError: true);
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

  String _formatBps(String? value) {
    if (value == null || value.isEmpty) return '0';

    final n = int.tryParse(value) ?? 0;

    if (n < 1000) return '$n bps';
    if (n < 1000000) return '${(n / 1000).toStringAsFixed(1)} Kbps';
    if (n < 1000000000) {
      return '${(n / 1000000).toStringAsFixed(2)} Mbps';
    }
    return '${(n / 1000000000).toStringAsFixed(2)} Gbps';
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.interface;
    final disabled = item['disabled'] == 'true';
    final running = item['running'] == 'true';

    return Scaffold(
      appBar: AppBar(
        title: Text(item['name'] ?? 'Interface'),
        actions: [
          IconButton(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // الحالة
          Card(
            color: disabled
                ? Colors.red.shade50
                : running
                ? Colors.green.shade50
                : Colors.grey.shade100,
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Icon(
                    running ? Icons.check_circle : Icons.cancel,
                    color: disabled
                        ? Colors.red
                        : running
                        ? Colors.green
                        : Colors.grey,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          disabled
                              ? 'معطّلة'
                              : running
                              ? 'تعمل الآن'
                              : 'متوقفة',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'النوع: ${item['type'] ?? '-'}',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // المعلومات الأساسية
          const Text(
            '📋 المعلومات',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _infoRow('MAC', item['mac-address'] ?? '-'),
                  _infoRow('MTU', item['mtu'] ?? '-'),
                  _infoRow('Actual MTU', item['actual-mtu'] ?? '-'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // عناوين IP
          const Text(
            '🌐 عناوين IP',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          if (_loadingDetails)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(child: CircularProgressIndicator()),
              ),
            )
          else if (_addresses.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'لا توجد عناوين IP',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
              ),
            )
          else
            ..._addresses.map((addr) {
              return Card(
                margin: const EdgeInsets.only(bottom: 6),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.lan),
                  title: Text(
                    addr['address'] ?? '',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text('Network: ${addr['network'] ?? '-'}'),
                ),
              );
            }),

          const SizedBox(height: 16),

          // حركة المرور
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 حركة المرور',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _loadingTraffic ? null : _refreshTraffic,
                icon: _loadingTraffic
                    ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
                    : const Icon(Icons.refresh, size: 18),
                label: const Text('قياس'),
              ),
            ],
          ),

          if (_traffic != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.download,
                            color: Colors.blue,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Rx',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _formatBps(_traffic!['rx-bits-per-second']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 60,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.upload,
                            color: Colors.green,
                            size: 32,
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Tx',
                            style: TextStyle(color: Colors.grey),
                          ),
                          Text(
                            _formatBps(_traffic!['tx-bits-per-second']),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // تعديل
          const Text(
            '✏️ تعديل',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          TextField(
            controller: _nameController,
            decoration: const InputDecoration(
              labelText: 'الاسم',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _commentController,
            decoration: const InputDecoration(
              labelText: 'ملاحظة',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
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

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}