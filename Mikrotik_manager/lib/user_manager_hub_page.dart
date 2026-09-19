import 'package:flutter/material.dart';
import 'mikrotik_api.dart';

// =============================================================================
// User Manager Hub Page
// =============================================================================

class UserManagerHubPage extends StatefulWidget {
  final MikroTikApi api;

  const UserManagerHubPage({
    super.key,
    required this.api,
  });

  @override
  State<UserManagerHubPage> createState() =>
      _UserManagerHubPageState();
}

class _UserManagerHubPageState extends State<UserManagerHubPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('👤 User Manager'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Cards', icon: Icon(Icons.credit_card, size: 18)),
            Tab(text: 'Profiles', icon: Icon(Icons.category, size: 18)),
            Tab(text: 'Limitations', icon: Icon(Icons.tune, size: 18)),
            Tab(text: 'Sessions', icon: Icon(Icons.wifi, size: 18)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CardsTab(api: widget.api),
          _ProfilesTab(api: widget.api),
          _LimitationsTab(api: widget.api),
          _SessionsTab(api: widget.api),
        ],
      ),
    );
  }
}

// =============================================================================
// Cards Tab — توليد + عرض
// =============================================================================

class _CardsTab extends StatefulWidget {
  final MikroTikApi api;

  const _CardsTab({required this.api});

  @override
  State<_CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<_CardsTab> {
  List<Map<String, String>> _users = [];
  List<Map<String, String>> _profiles = [];

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await widget.api.getUserManagerUsers();
      final profiles = await widget.api.getUserManagerProfiles();

      if (!mounted) return;

      setState(() {
        _users = users;
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

  Future<void> _openGenerate() async {
    final result = await showDialog<int>(
      context: context,
      builder: (_) => _GenerateCardsDialog(
        api: widget.api,
        profiles: _profiles,
      ),
    );

    if (result != null && result > 0) {
      _showMessage('تم إنشاء $result كرت ✅');
      await _loadAll();
    }
  }

  Future<void> _deleteUser(Map<String, String> user) async {
    final id = user['.id'];
    final name = user['name'] ?? '';

    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف الكرت'),
        content: Text('هل تريد حذف "$name"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.api.deleteUserManagerUser(id);
      if (!mounted) return;
      _showMessage('تم الحذف ✅');
      await _loadAll();
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل: $e', isError: true);
    }
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

  @override
  Widget build(BuildContext context) {
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
              const Icon(Icons.error_outline,
                  size: 60, color: Colors.red),
              const SizedBox(height: 15),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 15),
              FilledButton.icon(
                onPressed: _loadAll,
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
        if (_users.isEmpty)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.credit_card,
                    size: 60, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'لا توجد كروت',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          )
        else
          ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
            itemCount: _users.length,
            itemBuilder: (context, i) {
              final user = _users[i];
              final name = user['name'] ?? '-';
              final group = user['group'] ?? '-';
              final sharedUsers = user['shared-users'] ?? '1';

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: Colors.blue.withValues(alpha: 0.15),
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person,
                        color: Colors.blue, size: 22),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  subtitle: Text(
                    '$group • $sharedUsers device(s)',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: IconButton(
                    onPressed: () => _deleteUser(user),
                    icon: const Icon(Icons.delete,
                        color: Colors.red),
                  ),
                ),
              );
            },
          ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            onPressed: _openGenerate,
            backgroundColor: Colors.green,
            icon: const Icon(Icons.auto_awesome,
                color: Colors.white),
            label: const Text(
              'توليد كروت',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// Profiles Tab
// =============================================================================

class _ProfilesTab extends StatefulWidget {
  final MikroTikApi api;

  const _ProfilesTab({required this.api});

  @override
  State<_ProfilesTab> createState() => _ProfilesTabState();
}

class _ProfilesTabState extends State<_ProfilesTab> {
  List<Map<String, String>> _profiles = [];
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
      final profiles = await widget.api.getUserManagerProfiles();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_profiles.isEmpty) {
      return const Center(child: Text('لا توجد Profiles'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _profiles.length,
      itemBuilder: (context, i) {
        final profile = _profiles[i];
        final name = profile['name'] ?? '-';
        final validity = profile['validity'] ?? '-';
        final startsWhen = profile['starts-when'] ?? '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.purple.withValues(alpha: 0.15),
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.category,
                  color: Colors.purple, size: 22),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المدة: $validity'),
                Text('يبدأ عند: $startsWhen'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Limitations Tab
// =============================================================================

class _LimitationsTab extends StatefulWidget {
  final MikroTikApi api;

  const _LimitationsTab({required this.api});

  @override
  State<_LimitationsTab> createState() => _LimitationsTabState();
}

class _LimitationsTabState extends State<_LimitationsTab> {
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
      final items =
      await widget.api.getUserManagerLimitations();
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
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(child: Text(_error!));
    }

    if (_items.isEmpty) {
      return const Center(child: Text('لا توجد Limitations'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _items.length,
      itemBuilder: (context, i) {
        final item = _items[i];
        final name = item['name'] ?? '-';
        final transferLimit = item['transfer-limit'] ?? '-';
        final uptimeLimit = item['uptime-limit'] ?? '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.orange.withValues(alpha: 0.15),
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.tune,
                  color: Colors.orange, size: 22),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('حد البيانات: $transferLimit'),
                Text('حد المدة: $uptimeLimit'),
              ],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Sessions Tab
// =============================================================================

class _SessionsTab extends StatefulWidget {
  final MikroTikApi api;

  const _SessionsTab({required this.api});

  @override
  State<_SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<_SessionsTab> {
  List<Map<String, String>> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      final sessions =
      await widget.api.getUserManagerSessions();
      if (!mounted) return;
      setState(() {
        _sessions = sessions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_sessions.isEmpty) {
      return const Center(child: Text('لا يوجد متصلون'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _sessions.length,
      itemBuilder: (context, i) {
        final session = _sessions[i];
        final name = session['user'] ?? '-';
        final ip = session['user-address'] ?? '-';
        final uptime = session['uptime'] ?? '-';

        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: Colors.green.withValues(alpha: 0.2),
            ),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi,
                  color: Colors.green, size: 22),
            ),
            title: Text(
              name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                fontFamily: 'monospace',
              ),
            ),
            subtitle: Text('$ip • $uptime'),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Generate Cards Dialog
// =============================================================================

class _GenerateCardsDialog extends StatefulWidget {
  final MikroTikApi api;
  final List<Map<String, String>> profiles;

  const _GenerateCardsDialog({
    required this.api,
    required this.profiles,
  });

  @override
  State<_GenerateCardsDialog> createState() =>
      _GenerateCardsDialogState();
}

class _GenerateCardsDialogState
    extends State<_GenerateCardsDialog> {
  final _formKey = GlobalKey<FormState>();

  final _prefixController = TextEditingController(text: '');
  final _startController = TextEditingController(text: '1');
  final _countController = TextEditingController(text: '10');
  final _lengthController = TextEditingController(text: '8');
  final _sharedController = TextEditingController(text: '1');

  String? _selectedProfile;

  String _generationMode = 'random'; // random | sequential

  bool _generating = false;
  bool _cancelRequested = false;
  int _current = 0;
  int _total = 0;
  int _success = 0;
  int _failed = 0;

  @override
  void initState() {
    super.initState();

    if (widget.profiles.isNotEmpty) {
      _selectedProfile = widget.profiles.first['name'];
    }
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _startController.dispose();
    _countController.dispose();
    _lengthController.dispose();
    _sharedController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Random Number
  // ===========================================================================

  String _randomNumber(int length) {
    final now = DateTime.now().microsecondsSinceEpoch;
    final buffer = StringBuffer();

    for (int i = 0; i < length; i++) {
      final digit = (now + i * 7 + _success * 13) % 10;
      buffer.write(digit.abs());
    }

    return buffer.toString();
  }

  // ===========================================================================
  // Generate
  // ===========================================================================

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProfile == null ||
        _selectedProfile!.isEmpty) {
      _showMessage('يجب اختيار Profile', isError: true);
      return;
    }

    final count =
        int.tryParse(_countController.text.trim()) ?? 0;
    if (count <= 0 || count > 1000) {
      _showMessage('العدد يجب أن يكون 1-1000', isError: true);
      return;
    }

    // تأكيد
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد التوليد'),
        content: Text(
          'سيتم إنشاء $count كرت في User Manager.\n\n'
              '⏱️ الوقت المتوقع: ~${(count * 0.3).ceil()} ثانية\n\n'
              'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('توليد'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _generating = true;
      _cancelRequested = false;
      _current = 0;
      _total = count;
      _success = 0;
      _failed = 0;
    });

    final prefix = _prefixController.text.trim();
    final start =
        int.tryParse(_startController.text.trim()) ?? 1;
    final length =
        int.tryParse(_lengthController.text.trim()) ?? 8;
    final shared = int.tryParse(
      _sharedController.text.trim(),
    ) ??
        1;

    for (int i = 0; i < count; i++) {
      if (_cancelRequested) break;

      setState(() => _current = i + 1);

      String name;

      if (_generationMode == 'sequential') {
        final num = start + i;
        final numStr = num.toString().padLeft(length, '0');
        name = '$prefix$numStr';
      } else {
        name = _randomNumber(length);
      }

      try {
        // التحقق من عدم التكرار
        final exists = await _userExists(name);

        if (exists) {
          // جرب مرة أخرى
          name = _randomNumber(length + 2);
        }

        final id = await widget.api.addUserManagerUser(
          name: name,
          password: '',
          sharedUsers: shared,
        );

        if (id != null && id.isNotEmpty) {
          setState(() => _success++);
        } else {
          setState(() => _failed++);
        }
      } catch (e) {
        setState(() => _failed++);
      }
    }

    if (!mounted) return;

    setState(() => _generating = false);

    Navigator.pop(context, _success);
  }

  Future<bool> _userExists(String name) async {
    try {
      final all = await widget.api.getUserManagerUsers();
      return all.any(
            (u) => (u['name'] ?? '').toLowerCase() ==
            name.toLowerCase(),
      );
    } catch (_) {
      return false;
    }
  }

  void _cancel() {
    setState(() => _cancelRequested = true);
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

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.green),
          const SizedBox(width: 8),
          const Expanded(
            child: Text('توليد كروت'),
          ),
          if (_generating)
            IconButton(
              onPressed: _cancel,
              tooltip: 'إلغاء',
              icon: const Icon(Icons.cancel,
                  color: Colors.red),
            ),
        ],
      ),
      content: _generating
          ? _buildProgress()
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // نوع التوليد
              Row(
                children: [
                  Expanded(
                    child: _modeChip(
                      'تسلسلي',
                      'sequential',
                      Icons.format_list_numbered,
                      Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _modeChip(
                      'عشوائي',
                      'random',
                      Icons.shuffle,
                      Colors.deepOrange,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // الحقول
              if (_generationMode == 'sequential') ...[
                TextFormField(
                  controller: _prefixController,
                  decoration: const InputDecoration(
                    labelText: 'البادئة',
                    hintText: 'user',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.text_fields),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (_generationMode == 'sequential' &&
                        (v == null ||
                            v.trim().isEmpty)) {
                      return 'مطلوب';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _startController,
                        keyboardType:
                        TextInputType.number,
                        decoration:
                        const InputDecoration(
                          labelText: 'يبدأ من',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _lengthController,
                        keyboardType:
                        TextInputType.number,
                        decoration:
                        const InputDecoration(
                          labelText: 'عدد الخانات',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                TextFormField(
                  controller: _lengthController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'طول الرقم',
                    hintText: '8',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.straighten),
                    isDense: true,
                  ),
                  validator: (v) {
                    if (_generationMode == 'random') {
                      final n = int.tryParse(
                          v?.trim() ?? '');
                      if (n == null ||
                          n < 4 ||
                          n > 20) {
                        return '4-20';
                      }
                    }
                    return null;
                  },
                ),
              ],

              const SizedBox(height: 10),

              TextFormField(
                controller: _countController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد الكروت',
                  hintText: '10',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                  isDense: true,
                  helperText: 'الحد الأقصى 1000',
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1) {
                    return 'العدد 1 على الأقل';
                  }
                  if (n > 1000) return 'الحد 1000';
                  return null;
                },
              ),

              const SizedBox(height: 10),

              // Profile
              if (widget.profiles.isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: _selectedProfile,
                  isDense: true,
                  decoration: const InputDecoration(
                    labelText: 'Profile',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.category),
                    isDense: true,
                    helperText:
                    'يحدد المدة وكيفية البدء',
                  ),
                  items: widget.profiles.map((p) {
                    final name = p['name'] ?? '';
                    final validity =
                        p['validity'] ?? '';
                    return DropdownMenuItem(
                      value: name,
                      child: Text(
                        '$name ($validity)',
                        style: const TextStyle(
                          fontSize: 13,
                        ),
                      ),
                    );
                  }).toList(),
                  onChanged: (v) {
                    setState(() => _selectedProfile = v);
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius:
                    BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.warning,
                          color: Colors.red, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'لا توجد Profiles — أنشئ واحداً أولاً',
                          style: TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 10),

              TextFormField(
                controller: _sharedController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'عدد الأجهزة',
                  hintText: '1',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.devices),
                  isDense: true,
                ),
                validator: (v) {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 1) {
                    return 'رقم غير صالح';
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: _generating
          ? null
          : [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('إلغاء'),
        ),
        FilledButton.icon(
          onPressed: _generate,
          icon: const Icon(Icons.auto_awesome, size: 18),
          label: const Text('توليد'),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _modeChip(
      String label,
      String mode,
      IconData icon,
      Color color,
      ) {
    final isSelected = _generationMode == mode;

    return GestureDetector(
      onTap: () => setState(() => _generationMode = mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 8,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.15)
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected
                    ? FontWeight.bold
                    : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.autorenew,
            size: 40, color: Colors.green),
        const SizedBox(height: 12),
        const Text(
          'جاري التوليد...',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        LinearProgressIndicator(
          value: _total > 0 ? _current / _total : 0,
        ),
        const SizedBox(height: 8),
        Text(
          '$_current / $_total',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            Column(
              children: [
                const Text(
                  'نجح',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '$_success',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            Column(
              children: [
                const Text(
                  'فشل',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 12,
                  ),
                ),
                Text(
                  '$_failed',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}