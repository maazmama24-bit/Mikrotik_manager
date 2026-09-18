import 'package:flutter/material.dart';
import 'mikrotik_api.dart';

// =============================================================================
// Firewall Page
// =============================================================================

class FirewallPage extends StatefulWidget {
  final MikroTikApi api;

  const FirewallPage({
    super.key,
    required this.api,
  });

  @override
  State<FirewallPage> createState() => _FirewallPageState();
}

class _FirewallPageState extends State<FirewallPage>
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
        title: const Text('🔥 Firewall'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Filter', icon: Icon(Icons.filter_alt, size: 18)),
            Tab(text: 'NAT', icon: Icon(Icons.swap_horiz, size: 18)),
            Tab(text: 'Mangle', icon: Icon(Icons.tune, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          FilterTab(api: widget.api),
          NatTab(api: widget.api),
          MangleTab(api: widget.api),
        ],
      ),
    );
  }
}

// =============================================================================
// Filter Tab
// =============================================================================

class FilterTab extends StatefulWidget {
  final MikroTikApi api;
  const FilterTab({super.key, required this.api});

  @override
  State<FilterTab> createState() => _FilterTabState();
}

class _FilterTabState extends State<FilterTab> {
  List<Map<String, String>> _items = [];
  bool _loading = true;
  String? _error;
  String _filterChain = 'all';

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
      final items = await widget.api.getFirewallFilterRules();
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
    if (_filterChain == 'all') return _items;

    return _items.where((item) {
      return (item['chain'] ?? '') == _filterChain;
    }).toList();
  }

  Set<String> get _chains {
    return _items.map((e) => e['chain'] ?? '').where((c) => c.isNotEmpty).toSet();
  }

  Future<void> _toggle(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final disabled = item['disabled'] == 'true';

    try {
      await widget.api.toggleFirewallFilterRule(
        id: id,
        disabled: !disabled,
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل: $e', isError: true);
    }
  }

  Future<void> _delete(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القاعدة'),
        content: Text(
          'هل تريد حذف القاعدة؟\n\n'
              'Chain: ${item['chain']}\n'
              'Action: ${item['action']}',
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
      await widget.api.deleteFirewallFilterRule(id);
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

  Color _actionColor(String action) {
    switch (action) {
      case 'accept':
        return Colors.green;
      case 'drop':
        return Colors.red;
      case 'reject':
        return Colors.orange;
      case 'jump':
        return Colors.blue;
      case 'return':
        return Colors.purple;
      default:
        return Colors.grey;
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

    final chains = ['all', ..._chains];
    final filtered = _filtered;

    return Scaffold(
      body: Column(
        children: [
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: chains.map((chain) {
                    final count = chain == 'all'
                        ? _items.length
                        : _items.where((e) => e['chain'] == chain).length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          chain == 'all' ? 'الكل ($count)' : '$chain ($count)',
                        ),
                        selected: _filterChain == chain,
                        onSelected: (_) => setState(() => _filterChain = chain),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد قواعد'))
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final item = filtered[i];
                final disabled = item['disabled'] == 'true';
                final action = item['action'] ?? '';
                final isInvalid = item['invalid'] == 'true';

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: disabled
                          ? Colors.grey.shade300
                          : _actionColor(action).withValues(alpha: 0.2),
                      child: Icon(
                        _iconForAction(action),
                        size: 18,
                        color: disabled
                            ? Colors.grey
                            : _actionColor(action),
                      ),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['chain'] ?? '',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            action,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _actionColor(action),
                            ),
                          ),
                        ),
                        if (isInvalid)
                          const Icon(
                            Icons.warning,
                            size: 14,
                            color: Colors.orange,
                          ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((item['protocol'] ?? '').isNotEmpty)
                          Text(
                            'proto: ${item['protocol']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if ((item['src-address'] ?? '').isNotEmpty)
                          Text(
                            'src: ${item['src-address']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if ((item['dst-address'] ?? '').isNotEmpty)
                          Text(
                            'dst: ${item['dst-address']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if ((item['comment'] ?? '').isNotEmpty)
                          Text(
                            item['comment']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
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
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          onPressed: () => _delete(item),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _iconForAction(String action) {
    switch (action) {
      case 'accept':
        return Icons.check;
      case 'drop':
        return Icons.block;
      case 'reject':
        return Icons.cancel;
      case 'jump':
        return Icons.arrow_forward;
      case 'return':
        return Icons.keyboard_return;
      default:
        return Icons.filter_alt;
    }
  }
}

// =============================================================================
// NAT Tab
// =============================================================================

class NatTab extends StatefulWidget {
  final MikroTikApi api;
  const NatTab({super.key, required this.api});

  @override
  State<NatTab> createState() => _NatTabState();
}

class _NatTabState extends State<NatTab> {
  List<Map<String, String>> _items = [];
  bool _loading = true;
  String? _error;
  String _filterChain = 'all';

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
      final items = await widget.api.getFirewallNatRules();
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
    if (_filterChain == 'all') return _items;
    return _items.where((item) => (item['chain'] ?? '') == _filterChain).toList();
  }

  Set<String> get _chains {
    return _items.map((e) => e['chain'] ?? '').where((c) => c.isNotEmpty).toSet();
  }

  Future<void> _toggle(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final disabled = item['disabled'] == 'true';

    try {
      await widget.api.updateFirewallNatRule(
        id: id,
        disabled: !disabled,
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل: $e', isError: true);
    }
  }

  Future<void> _delete(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القاعدة'),
        content: Text(
          'Chain: ${item['chain']}\n'
              'Action: ${item['action']}',
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
      await widget.api.deleteFirewallNatRule(id);
      if (!mounted) return;
      _showMessage('تم الحذف ✅');
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل: $e', isError: true);
    }
  }

  Future<void> _openAddDialog({Map<String, String>? item}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => NatRuleDialog(
        api: widget.api,
        existing: item,
      ),
    );

    if (result == true) await _load();
  }

  Future<void> _quickMasquerade() async {
    final interfaces = await widget.api.getInterfaces();
    if (!mounted) return;

    final usable = interfaces.where((i) {
      final type = i['type'] ?? '';
      final disabled = i['disabled'] == 'true';
      return type.startsWith('ether') && !disabled;
    }).toList();

    if (usable.isEmpty) {
      _showMessage('لا توجد واجهات متاحة', isError: true);
      return;
    }

    final selected = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Masquerade سريع'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: usable.length,
            itemBuilder: (context, i) {
              final name = usable[i]['name'] ?? '';
              return ListTile(
                title: Text(name),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => Navigator.pop(context, name),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );

    if (selected == null) return;

    try {
      await widget.api.addMasqueradeRule(
        outInterface: selected,
        comment: 'Masquerade - $selected',
      );
      if (!mounted) return;
      _showMessage('تمت إضافة Masquerade على $selected ✅');
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

  Color _actionColor(String action) {
    switch (action) {
      case 'masquerade':
        return Colors.green;
      case 'dst-nat':
        return Colors.blue;
      case 'src-nat':
        return Colors.purple;
      case 'redirect':
        return Colors.orange;
      case 'accept':
        return Colors.green;
      case 'drop':
        return Colors.red;
      default:
        return Colors.grey;
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

    final chains = ['all', ..._chains];
    final filtered = _filtered;

    return Scaffold(
      body: Column(
        children: [
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: chains.map((chain) {
                    final count = chain == 'all'
                        ? _items.length
                        : _items.where((e) => e['chain'] == chain).length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          chain == 'all' ? 'الكل ($count)' : '$chain ($count)',
                        ),
                        selected: _filterChain == chain,
                        onSelected: (_) => setState(() => _filterChain = chain),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد قواعد NAT'))
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final item = filtered[i];
                final disabled = item['disabled'] == 'true';
                final action = item['action'] ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: disabled
                          ? Colors.grey.shade300
                          : _actionColor(action).withValues(alpha: 0.2),
                      child: Icon(
                        Icons.swap_horiz,
                        size: 18,
                        color: disabled
                            ? Colors.grey
                            : _actionColor(action),
                      ),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['chain'] ?? '',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            action,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _actionColor(action),
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((item['src-address'] ?? '').isNotEmpty)
                          Text(
                            'src: ${item['src-address']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if ((item['dst-address'] ?? '').isNotEmpty)
                          Text(
                            'dst: ${item['dst-address']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        if ((item['to-addresses'] ?? '').isNotEmpty)
                          Text(
                            '→ ${item['to-addresses']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.green,
                            ),
                          ),
                        if ((item['comment'] ?? '').isNotEmpty)
                          Text(
                            item['comment']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
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
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          onPressed: () => _openAddDialog(item: item),
                          icon: const Icon(
                            Icons.edit,
                            color: Colors.blue,
                          ),
                        ),
                        IconButton(
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          onPressed: () => _delete(item),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _openAddDialog(item: item),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: 'quickMasq',
            onPressed: _quickMasquerade,
            backgroundColor: Colors.green,
            tooltip: 'Masquerade سريع',
            child: const Icon(Icons.flash_on),
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            heroTag: 'addNat',
            onPressed: () => _openAddDialog(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Mangle Tab
// =============================================================================

class MangleTab extends StatefulWidget {
  final MikroTikApi api;
  const MangleTab({super.key, required this.api});

  @override
  State<MangleTab> createState() => _MangleTabState();
}

class _MangleTabState extends State<MangleTab> {
  List<Map<String, String>> _items = [];
  bool _loading = true;
  String? _error;
  String _filterChain = 'all';

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
      final items = await widget.api.getFirewallMangleRules();
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
    if (_filterChain == 'all') return _items;
    return _items.where((item) => (item['chain'] ?? '') == _filterChain).toList();
  }

  Set<String> get _chains {
    return _items.map((e) => e['chain'] ?? '').where((c) => c.isNotEmpty).toSet();
  }

  Future<void> _toggle(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final disabled = item['disabled'] == 'true';

    try {
      await widget.api.toggleFirewallMangleRule(
        id: id,
        disabled: !disabled,
      );
      if (!mounted) return;
      await _load();
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل: $e', isError: true);
    }
  }

  Future<void> _delete(Map<String, String> item) async {
    final id = item['.id'];
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف القاعدة'),
        content: Text('Chain: ${item['chain']}'),
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
      await widget.api.deleteFirewallMangleRule(id);
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

    final chains = ['all', ..._chains];
    final filtered = _filtered;

    return Scaffold(
      body: Column(
        children: [
          if (_items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: chains.map((chain) {
                    final count = chain == 'all'
                        ? _items.length
                        : _items.where((e) => e['chain'] == chain).length;

                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(
                          chain == 'all' ? 'الكل ($count)' : '$chain ($count)',
                        ),
                        selected: _filterChain == chain,
                        onSelected: (_) => setState(() => _filterChain = chain),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          Expanded(
            child: filtered.isEmpty
                ? const Center(child: Text('لا توجد قواعد Mangle'))
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final item = filtered[i];
                final disabled = item['disabled'] == 'true';

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 2,
                    ),
                    leading: CircleAvatar(
                      radius: 16,
                      backgroundColor: disabled
                          ? Colors.grey.shade300
                          : Colors.deepPurple.shade100,
                      child: Icon(
                        Icons.tune,
                        size: 18,
                        color: disabled ? Colors.grey : Colors.deepPurple,
                      ),
                    ),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item['chain'] ?? '',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item['action'] ?? '',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if ((item['new-packet-mark'] ?? '').isNotEmpty)
                          Text(
                            'mark: ${item['new-packet-mark']}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.deepPurple,
                            ),
                          ),
                        if ((item['comment'] ?? '').isNotEmpty)
                          Text(
                            item['comment']!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontStyle: FontStyle.italic,
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
                          iconSize: 18,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(
                            minWidth: 30,
                            minHeight: 30,
                          ),
                          onPressed: () => _delete(item),
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
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
// NAT Rule Dialog
// =============================================================================

class NatRuleDialog extends StatefulWidget {
  final MikroTikApi api;
  final Map<String, String>? existing;

  const NatRuleDialog({
    super.key,
    required this.api,
    this.existing,
  });

  @override
  State<NatRuleDialog> createState() => _NatRuleDialogState();
}

class _NatRuleDialogState extends State<NatRuleDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _chainController;
  late TextEditingController _actionController;
  late TextEditingController _protocolController;
  late TextEditingController _srcAddressController;
  late TextEditingController _dstAddressController;
  late TextEditingController _dstPortController;
  late TextEditingController _toAddressesController;
  late TextEditingController _toPortsController;
  late TextEditingController _inInterfaceController;
  late TextEditingController _outInterfaceController;
  late TextEditingController _commentController;

  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  final List<String> _chains = const ['srcnat', 'dstnat'];
  final List<String> _actions = const [
    'masquerade',
    'src-nat',
    'dst-nat',
    'redirect',
    'accept',
    'drop',
    'return',
    'jump',
  ];

  @override
  void initState() {
    super.initState();

    _chainController = TextEditingController(
      text: widget.existing?['chain'] ?? 'srcnat',
    );
    _actionController = TextEditingController(
      text: widget.existing?['action'] ?? 'masquerade',
    );
    _protocolController = TextEditingController(
      text: widget.existing?['protocol'] ?? '',
    );
    _srcAddressController = TextEditingController(
      text: widget.existing?['src-address'] ?? '',
    );
    _dstAddressController = TextEditingController(
      text: widget.existing?['dst-address'] ?? '',
    );
    _dstPortController = TextEditingController(
      text: widget.existing?['dst-port'] ?? '',
    );
    _toAddressesController = TextEditingController(
      text: widget.existing?['to-addresses'] ?? '',
    );
    _toPortsController = TextEditingController(
      text: widget.existing?['to-ports'] ?? '',
    );
    _inInterfaceController = TextEditingController(
      text: widget.existing?['in-interface'] ?? '',
    );
    _outInterfaceController = TextEditingController(
      text: widget.existing?['out-interface'] ?? '',
    );
    _commentController = TextEditingController(
      text: widget.existing?['comment'] ?? '',
    );
  }

  @override
  void dispose() {
    _chainController.dispose();
    _actionController.dispose();
    _protocolController.dispose();
    _srcAddressController.dispose();
    _dstAddressController.dispose();
    _dstPortController.dispose();
    _toAddressesController.dispose();
    _toPortsController.dispose();
    _inInterfaceController.dispose();
    _outInterfaceController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (_isEditing) {
        await widget.api.updateFirewallNatRule(
          id: widget.existing!['.id'] ?? '',
          chain: _chainController.text,
          action: _actionController.text,
          protocol: _protocolController.text,
          srcAddress: _srcAddressController.text,
          dstAddress: _dstAddressController.text,
          dstPort: _dstPortController.text,
          toAddresses: _toAddressesController.text,
          toPorts: _toPortsController.text,
          inInterface: _inInterfaceController.text,
          outInterface: _outInterfaceController.text,
          comment: _commentController.text,
        );
      } else {
        await widget.api.addFirewallNatRule(
          chain: _chainController.text,
          action: _actionController.text,
          protocol: _protocolController.text,
          srcAddress: _srcAddressController.text,
          dstAddress: _dstAddressController.text,
          dstPort: _dstPortController.text,
          toAddresses: _toAddressesController.text,
          toPorts: _toPortsController.text,
          inInterface: _inInterfaceController.text,
          outInterface: _outInterfaceController.text,
          comment: _commentController.text,
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
      title: Text(_isEditing ? 'تعديل قاعدة NAT' : 'إضافة قاعدة NAT'),
      content: SizedBox(
        width: double.maxFinite,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _chainController.text.isEmpty
                      ? 'srcnat'
                      : _chainController.text,
                  decoration: const InputDecoration(
                    labelText: 'Chain *',
                    border: OutlineInputBorder(),
                  ),
                  items: _chains
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _chainController.text = v;
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _actionController.text.isEmpty
                      ? 'masquerade'
                      : _actionController.text,
                  decoration: const InputDecoration(
                    labelText: 'Action *',
                    border: OutlineInputBorder(),
                  ),
                  items: _actions
                      .map((a) => DropdownMenuItem(value: a, child: Text(a)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) _actionController.text = v;
                  },
                ),
                const SizedBox(height: 10),
                _field('Protocol', _protocolController,
                    hint: 'tcp / udp / icmp'),
                _field('Src Address', _srcAddressController,
                    hint: '192.168.1.0/24'),
                _field('Dst Address', _dstAddressController,
                    hint: '0.0.0.0/0'),
                _field('Dst Port', _dstPortController, hint: '80,443'),
                _field('To Addresses', _toAddressesController,
                    hint: '192.168.1.10'),
                _field('To Ports', _toPortsController, hint: '8080'),
                _field('In Interface', _inInterfaceController,
                    hint: 'ether1'),
                _field('Out Interface', _outInterfaceController,
                    hint: 'ether1'),
                _field('Comment', _commentController),
              ],
            ),
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

  Widget _field(
      String label,
      TextEditingController controller, {
        String? hint,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
      ),
    );
  }
}