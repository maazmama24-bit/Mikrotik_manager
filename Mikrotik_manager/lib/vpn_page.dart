import 'package:flutter/material.dart';
import 'mikrotik_api.dart';

// =============================================================================
// VPN Page
// =============================================================================

class VpnPage extends StatefulWidget {
  final MikroTikApi api;

  const VpnPage({
    super.key,
    required this.api,
  });

  @override
  State<VpnPage> createState() => _VpnPageState();
}

class _VpnPageState extends State<VpnPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
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
        title: const Text('🔐 VPN'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'L2TP Server', icon: Icon(Icons.settings, size: 18)),
            Tab(text: 'L2TP Users', icon: Icon(Icons.people, size: 18)),
            Tab(text: 'PPTP', icon: Icon(Icons.security, size: 18)),
            Tab(text: 'المتصلون', icon: Icon(Icons.link, size: 18)),
            Tab(text: 'WireGuard', icon: Icon(Icons.vpn_key, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          L2tpServerTab(api: widget.api),
          L2tpUsersTab(api: widget.api),
          PptpTab(api: widget.api),
          VpnActiveTab(api: widget.api),
          WireGuardTab(api: widget.api),
        ],
      ),
    );
  }
}

// =============================================================================
// L2TP Server Tab
// =============================================================================

class L2tpServerTab extends StatefulWidget {
  final MikroTikApi api;
  const L2tpServerTab({super.key, required this.api});

  @override
  State<L2tpServerTab> createState() => _L2tpServerTabState();
}

class _L2tpServerTabState extends State<L2tpServerTab> {
  final _ipsecSecretController = TextEditingController();

  bool _enabled = false;
  bool _useIpsec = false;
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
    _ipsecSecretController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await widget.api.getL2tpServer();

      if (!mounted) return;

      setState(() {
        _enabled = data['enabled'] == 'true';
        _useIpsec = data['use-ipsec'] == 'true';
        _ipsecSecretController.text = data['ipsec-secret'] ?? '';
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
    setState(() => _saving = true);

    try {
      await widget.api.updateL2tpServer(
        enabled: _enabled,
        useIpsec: _useIpsec,
        ipsecSecret: _ipsecSecretController.text.trim(),
      );

      if (!mounted) return;
      _showMessage('تم الحفظ ✅');
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '🛡️ L2TP Server',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Card(
          child: SwitchListTile(
            title: const Text('تفعيل L2TP Server'),
            subtitle: const Text('السماح للعملاء بالاتصال'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            secondary: Icon(
              _enabled ? Icons.check_circle : Icons.cancel,
              color: _enabled ? Colors.green : Colors.grey,
            ),
          ),
        ),

        const SizedBox(height: 10),

        Card(
          child: SwitchListTile(
            title: const Text('استخدام IPsec'),
            subtitle: const Text('تشفير إضافي (موصى به)'),
            value: _useIpsec,
            onChanged: (v) => setState(() => _useIpsec = v),
            secondary: Icon(
              _useIpsec ? Icons.lock : Icons.lock_open,
              color: _useIpsec ? Colors.green : Colors.orange,
            ),
          ),
        ),

        const SizedBox(height: 16),

        if (_useIpsec) ...[
          const Text(
            '🔑 IPsec Secret',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _ipsecSecretController,
            decoration: const InputDecoration(
              labelText: 'IPsec Secret',
              hintText: 'كلمة سر قوية',
              border: OutlineInputBorder(),
              helperText: 'تستخدم في إعداد العميل',
            ),
          ),
          const SizedBox(height: 16),
        ],

        Card(
          color: Colors.blue.shade50,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue),
                    SizedBox(width: 8),
                    Text(
                      'معلومات مهمة',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'للاتصال بالراوتر من خارج الشبكة، ستحتاج:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                _buildStep('1', 'تفعيل L2TP + IPsec هنا'),
                _buildStep('2', 'إضافة مستخدم في تبويب L2TP Users'),
                _buildStep('3', 'فتح المنافذ UDP 500, 1701, 4500 في Firewall'),
                _buildStep('4', 'الاتصال من جوالك/كمبيوترك'),
              ],
            ),
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
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 10,
            backgroundColor: Colors.blue,
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
        ],
      ),
    );
  }
}

// =============================================================================
// L2TP Users Tab
// =============================================================================

class L2tpUsersTab extends StatefulWidget {
  final MikroTikApi api;
  const L2tpUsersTab({super.key, required this.api});

  @override
  State<L2tpUsersTab> createState() => _L2tpUsersTabState();
}

class _L2tpUsersTabState extends State<L2tpUsersTab> {
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
      final all = await widget.api.getL2tpUsers();
      final filtered = all.where((item) {
        final service = item['service'] ?? '';
        return service == 'l2tp' || service == 'any';
      }).toList();

      if (!mounted) return;
      setState(() {
        _items = filtered;
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
      builder: (_) => L2tpUserDialog(
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
        title: const Text('حذف المستخدم'),
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
      await widget.api.deleteL2tpUser(id);
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

  Future<void> _toggle(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final disabled = item['disabled'] == 'true';

    try {
      await widget.api.updateL2tpUser(id: id, disabled: !disabled);
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
          const Center(child: Text('لا يوجد مستخدمون'))
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
                    backgroundColor:
                    disabled ? Colors.red.shade100 : Colors.green.shade100,
                    child: Icon(
                      disabled ? Icons.block : Icons.person,
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
                      if ((item['remote-address'] ?? '').isNotEmpty)
                        Text('IP: ${item['remote-address']}'),
                      if ((item['comment'] ?? '').isNotEmpty)
                        Text(
                          item['comment']!,
                          style: const TextStyle(fontSize: 11),
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
// L2TP User Dialog
// =============================================================================

class L2tpUserDialog extends StatefulWidget {
  final MikroTikApi api;
  final Map<String, String>? existing;

  const L2tpUserDialog({
    super.key,
    required this.api,
    this.existing,
  });

  @override
  State<L2tpUserDialog> createState() => _L2tpUserDialogState();
}

class _L2tpUserDialogState extends State<L2tpUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remoteAddressController = TextEditingController();
  final _commentController = TextEditingController();

  bool _saving = false;
  bool _obscure = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _nameController.text = widget.existing!['name'] ?? '';
      _remoteAddressController.text =
          widget.existing!['remote-address'] ?? '';
      _commentController.text = widget.existing!['comment'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _remoteAddressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await widget.api.updateL2tpUser(
          id: widget.existing!['.id'] ?? '',
          name: _nameController.text.trim(),
          password: _passwordController.text.isEmpty
              ? null
              : _passwordController.text,
          remoteAddress: _remoteAddressController.text.trim(),
          comment: _commentController.text.trim(),
        );
      } else {
        await widget.api.addL2tpUser(
          name: _nameController.text.trim(),
          password: _passwordController.text,
          remoteAddress: _remoteAddressController.text.trim(),
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
      title: Text(_isEditing ? 'تعديل مستخدم' : 'إضافة مستخدم'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'كلمة المرور (اتركها فارغة)'
                      : 'كلمة المرور',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (v) {
                  if (!_isEditing && (v == null || v.isEmpty)) {
                    return 'مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _remoteAddressController,
                decoration: const InputDecoration(
                  labelText: 'IP ثابت (اختياري)',
                  hintText: '192.168.100.10',
                  border: OutlineInputBorder(),
                  helperText: 'اتركه فارغاً للـ IP الديناميكي',
                ),
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
// PPTP Tab
// =============================================================================

class PptpTab extends StatefulWidget {
  final MikroTikApi api;
  const PptpTab({super.key, required this.api});

  @override
  State<PptpTab> createState() => _PptpTabState();
}

class _PptpTabState extends State<PptpTab>
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
            Tab(text: 'Server'),
            Tab(text: 'Users'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              PptpServerTab(api: widget.api),
              PptpUsersTab(api: widget.api),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// PPTP Server Tab
// =============================================================================

class PptpServerTab extends StatefulWidget {
  final MikroTikApi api;
  const PptpServerTab({super.key, required this.api});

  @override
  State<PptpServerTab> createState() => _PptpServerTabState();
}

class _PptpServerTabState extends State<PptpServerTab> {
  bool _enabled = false;
  bool _loading = true;
  bool _saving = false;
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
      final data = await widget.api.getPptpServer();

      if (!mounted) return;
      setState(() {
        _enabled = data['enabled'] == 'true';
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
    setState(() => _saving = true);

    try {
      await widget.api.updatePptpServer(enabled: _enabled);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم الحفظ ✅')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('فشل: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          '🛡️ PPTP Server',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        Card(
          child: SwitchListTile(
            title: const Text('تفعيل PPTP Server'),
            subtitle: const Text('غير آمن - استخدم L2TP إن أمكن'),
            value: _enabled,
            onChanged: (v) => setState(() => _enabled = v),
            secondary: Icon(
              _enabled ? Icons.check_circle : Icons.cancel,
              color: _enabled ? Colors.green : Colors.grey,
            ),
          ),
        ),

        const SizedBox(height: 16),

        Card(
          color: Colors.orange.shade50,
          child: const Padding(
            padding: EdgeInsets.all(14),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'PPTP قديم وضعيف أمنياً. يُنصح باستخدام L2TP/IPsec أو WireGuard.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
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
    );
  }
}

// =============================================================================
// PPTP Users Tab
// =============================================================================

class PptpUsersTab extends StatefulWidget {
  final MikroTikApi api;
  const PptpUsersTab({super.key, required this.api});

  @override
  State<PptpUsersTab> createState() => _PptpUsersTabState();
}

class _PptpUsersTabState extends State<PptpUsersTab> {
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
      final all = await widget.api.getPptpUsers();
      final filtered = all.where((item) {
        final service = item['service'] ?? '';
        return service == 'pptp' || service == 'any';
      }).toList();

      if (!mounted) return;
      setState(() {
        _items = filtered;
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
      builder: (_) => PptpUserDialog(api: widget.api, existing: item),
    );

    if (result == true) await _load();
  }

  Future<void> _delete(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستخدم'),
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
      await widget.api.deletePptpUser(id);
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

    final disabled = item['disabled'] == 'true';

    try {
      await widget.api.updatePptpUser(id: id, disabled: !disabled);
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
          const Center(child: Text('لا يوجد مستخدمون'))
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
                    backgroundColor:
                    disabled ? Colors.red.shade100 : Colors.green.shade100,
                    child: Icon(
                      disabled ? Icons.block : Icons.person,
                      color: disabled ? Colors.red : Colors.green,
                    ),
                  ),
                  title: Text(
                    item['name'] ?? '',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('PPTP • ${item['remote-address'] ?? '-'}'),
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
// PPTP User Dialog
// =============================================================================

class PptpUserDialog extends StatefulWidget {
  final MikroTikApi api;
  final Map<String, String>? existing;

  const PptpUserDialog({
    super.key,
    required this.api,
    this.existing,
  });

  @override
  State<PptpUserDialog> createState() => _PptpUserDialogState();
}

class _PptpUserDialogState extends State<PptpUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _remoteAddressController = TextEditingController();
  final _commentController = TextEditingController();

  bool _saving = false;
  bool _obscure = true;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();

    if (_isEditing) {
      _nameController.text = widget.existing!['name'] ?? '';
      _remoteAddressController.text =
          widget.existing!['remote-address'] ?? '';
      _commentController.text = widget.existing!['comment'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _remoteAddressController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await widget.api.updatePptpUser(
          id: widget.existing!['.id'] ?? '',
          name: _nameController.text.trim(),
          password: _passwordController.text.isEmpty
              ? null
              : _passwordController.text,
          remoteAddress: _remoteAddressController.text.trim(),
          comment: _commentController.text.trim(),
        );
      } else {
        await widget.api.addPptpUser(
          name: _nameController.text.trim(),
          password: _passwordController.text,
          remoteAddress: _remoteAddressController.text.trim(),
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
      title: Text(_isEditing ? 'تعديل مستخدم' : 'إضافة مستخدم'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المستخدم',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'مطلوب' : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _passwordController,
                obscureText: _obscure,
                decoration: InputDecoration(
                  labelText: _isEditing
                      ? 'كلمة المرور (اتركها فارغة)'
                      : 'كلمة المرور',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                validator: (v) {
                  if (!_isEditing && (v == null || v.isEmpty)) {
                    return 'مطلوب';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _remoteAddressController,
                decoration: const InputDecoration(
                  labelText: 'IP ثابت (اختياري)',
                  hintText: '192.168.100.10',
                  border: OutlineInputBorder(),
                ),
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
// VPN Active Connections Tab
// =============================================================================

class VpnActiveTab extends StatefulWidget {
  final MikroTikApi api;
  const VpnActiveTab({super.key, required this.api});

  @override
  State<VpnActiveTab> createState() => _VpnActiveTabState();
}

class _VpnActiveTabState extends State<VpnActiveTab> {
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
      final all = await widget.api.getVpnActiveConnections();
      final filtered = all.where((item) {
        final service = item['service'] ?? '';
        return service == 'l2tp' || service == 'pptp';
      }).toList();

      if (!mounted) return;
      setState(() {
        _items = filtered;
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
        title: const Text('فصل الاتصال'),
        content: Text('هل تريد فصل "${item['name']}"؟'),
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
      await widget.api.disconnectVpnConnection(id);
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
          ? const Center(child: Text('لا توجد اتصالات نشطة'))
          : ListView.builder(
        padding: const EdgeInsets.all(10),
        itemCount: _items.length,
        itemBuilder: (context, i) {
          final item = _items[i];
          final service = item['service'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.green.shade100,
                child: Icon(
                  service == 'l2tp' ? Icons.vpn_lock : Icons.security,
                  color: Colors.green,
                ),
              ),
              title: Text(
                item['name'] ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('الخدمة: ${service.toUpperCase()}'),
                  if ((item['address'] ?? '').isNotEmpty)
                    Text('IP: ${item['address']}'),
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
// WireGuard Tab
// =============================================================================

class WireGuardTab extends StatefulWidget {
  final MikroTikApi api;
  const WireGuardTab({super.key, required this.api});

  @override
  State<WireGuardTab> createState() => _WireGuardTabState();
}

class _WireGuardTabState extends State<WireGuardTab>
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
            Tab(text: 'Interfaces'),
            Tab(text: 'Peers'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              WireGuardInterfacesTab(api: widget.api),
              WireGuardPeersTab(api: widget.api),
            ],
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// WireGuard Interfaces Tab
// =============================================================================

class WireGuardInterfacesTab extends StatefulWidget {
  final MikroTikApi api;
  const WireGuardInterfacesTab({super.key, required this.api});

  @override
  State<WireGuardInterfacesTab> createState() => _WireGuardInterfacesTabState();
}

class _WireGuardInterfacesTabState extends State<WireGuardInterfacesTab> {
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
      final items = await widget.api.getWireGuardInterfaces();

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

    if (_items.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.vpn_key, size: 60, color: Colors.grey),
              SizedBox(height: 12),
              Text(
                'WireGuard غير مُفعّل',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                'يتطلب RouterOS v7 أو أحدث',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

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
              backgroundColor:
              disabled ? Colors.red.shade100 : Colors.green.shade100,
              child: Icon(
                Icons.vpn_key,
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
                if ((item['listen-port'] ?? '').isNotEmpty)
                  Text('Port: ${item['listen-port']}'),
                if ((item['public-key'] ?? '').isNotEmpty)
                  Text(
                    'Key: ${(item['public-key']?.substring(0, 20) ?? '')}...',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// WireGuard Peers Tab
// =============================================================================

class WireGuardPeersTab extends StatefulWidget {
  final MikroTikApi api;
  const WireGuardPeersTab({super.key, required this.api});

  @override
  State<WireGuardPeersTab> createState() => _WireGuardPeersTabState();
}

class _WireGuardPeersTabState extends State<WireGuardPeersTab> {
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
      final items = await widget.api.getWireGuardPeers();

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

    if (_items.isEmpty) {
      return const Center(child: Text('لا يوجد Peers'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(10),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final item = _items[i];
        final lastHandshake = item['last-handshake'] ?? '';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: lastHandshake.isNotEmpty &&
                  lastHandshake != '0s'
                  ? Colors.green.shade100
                  : Colors.grey.shade300,
              child: Icon(
                Icons.device_hub,
                color: lastHandshake.isNotEmpty && lastHandshake != '0s'
                    ? Colors.green
                    : Colors.grey,
              ),
            ),
            title: Text(
              item['comment']?.isNotEmpty == true
                  ? item['comment']!
                  : 'Peer',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Interface: ${item['interface'] ?? '-'}'),
                if ((item['current-endpoint-address'] ?? '').isNotEmpty)
                  Text(
                    'Endpoint: ${item['current-endpoint-address']}',
                    style: const TextStyle(fontSize: 11),
                  ),
                if (lastHandshake.isNotEmpty)
                  Text(
                    'آخر اتصال: $lastHandshake',
                    style: TextStyle(
                      fontSize: 11,
                      color: lastHandshake != '0s'
                          ? Colors.green
                          : Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}