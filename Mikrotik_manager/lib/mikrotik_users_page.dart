import 'package:flutter/material.dart';
import 'mikrotik_api.dart';

// =============================================================================
// MikroTik Users Page - مستخدمو MikroTik
// =============================================================================

class MikrotikUsersPage extends StatefulWidget {
  final MikroTikApi api;

  const MikrotikUsersPage({
    super.key,
    required this.api,
  });

  @override
  State<MikrotikUsersPage> createState() => _MikrotikUsersPageState();
}

class _MikrotikUsersPageState extends State<MikrotikUsersPage> {
  late final MikroTikApi _api;

  List<Map<String, String>> _users = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _api = widget.api;
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await _api.getMikrotikUsers();

      if (!mounted) return;

      setState(() {
        _users = users;
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

  void _openChangePassword(Map<String, String> user) {
    final id = user['.id'];
    if (id == null || id.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChangePasswordPage(
          api: _api,
          userId: id,
          userName: user['name'] ?? '',
        ),
      ),
    ).then((_) => _loadUsers());
  }

  Future<void> _deleteUser(Map<String, String> user) async {
    final id = user['.id'];
    final name = user['name'] ?? '';

    if (id == null || id.isEmpty) return;

    if (name == 'admin') {
      _showMessage('لا يمكن حذف admin', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المستخدم'),
          content: Text('هل تريد حذف المستخدم "$name" نهائياً؟'),
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
        );
      },
    );

    if (confirmed != true) return;

    try {
      await _api.deleteMikrotikUser(id);

      if (!mounted) return;

      _showMessage('تم حذف المستخدم ✅');
      await _loadUsers();
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل الحذف: $e', isError: true);
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
        title: const Text('👤 مستخدمو MikroTik'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddMikrotikUserPage(api: _api),
                ),
              ).then((_) => _loadUsers());
            },
            tooltip: 'إضافة مستخدم',
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? _buildError()
          : _users.isEmpty
          ? const Center(child: Text('لا يوجد مستخدمون'))
          : ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _users.length,
        itemBuilder: (context, index) {
          final user = _users[index];
          final name = user['name'] ?? '';
          final group = user['group'] ?? '';
          final disabled = user['disabled'] == 'true' ||
              user['disabled'] == 'yes';
          final comment = user['comment'] ?? '';

          return Card(
            margin: const EdgeInsets.only(bottom: 10),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: CircleAvatar(
                child: Icon(
                  disabled ? Icons.block : Icons.person,
                  color: name == 'admin' ? Colors.red : null,
                ),
              ),
              title: Row(
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  if (name == 'admin')
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(
                        Icons.star,
                        color: Colors.amber,
                        size: 16,
                      ),
                    ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المجموعة: $group'),
                  if (comment.isNotEmpty)
                    Text(
                      comment,
                      style: const TextStyle(fontSize: 11),
                    ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'password':
                      _openChangePassword(user);
                      break;
                    case 'delete':
                      _deleteUser(user);
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'password',
                    child: Row(
                      children: [
                        Icon(Icons.key, size: 20),
                        SizedBox(width: 8),
                        Text('تغيير كلمة المرور'),
                      ],
                    ),
                  ),
                  if (name != 'admin')
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
              onTap: () => _openChangePassword(user),
            ),
          );
        },
      ),
    );
  }

  Widget _buildError() {
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
              onPressed: _loadUsers,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Change Password Page - تغيير كلمة المرور
// =============================================================================

class ChangePasswordPage extends StatefulWidget {
  final MikroTikApi api;
  final String userId;
  final String userName;

  const ChangePasswordPage({
    super.key,
    required this.api,
    required this.userId,
    required this.userName,
  });

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _saving = false;
  bool _obscure1 = true;
  bool _obscure2 = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final seed = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < 10; i++) {
      buffer.write(chars[(seed + i * 7) % chars.length]);
    }
    return buffer.toString();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmController.text) {
      _showMessage('كلمتا المرور غير متطابقتين', isError: true);
      return;
    }

    setState(() => _saving = true);

    try {
      await widget.api.updateMikrotikUserPassword(
        id: widget.userId,
        newPassword: _passwordController.text,
      );

      if (!mounted) return;

      _showMessage('تم تغيير كلمة المرور بنجاح ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('فشل التغيير: $e', isError: true);
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
    final isSelf = widget.userName == 'admin';

    return Scaffold(
      appBar: AppBar(
        title: Text('🔑 ${widget.userName}'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      child: Icon(Icons.person),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.userName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSelf
                                ? 'أنت متصل بهذا المستخدم'
                                : 'تغيير كلمة المرور',
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

            if (isSelf) ...[
              const SizedBox(height: 12),
              const Card(
                color: Colors.orange,
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(Icons.warning, color: Colors.white),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'تحذير: إذا غيّرت كلمة مرور حسابك الحالي، ستحتاج لتحديثها في التطبيق أيضاً.',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 20),

            TextFormField(
              controller: _passwordController,
              obscureText: _obscure1,
              decoration: InputDecoration(
                labelText: 'كلمة المرور الجديدة',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure1 = !_obscure1),
                  icon: Icon(
                    _obscure1 ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 4) {
                  return 'كلمة المرور يجب أن تكون 4 أحرف على الأقل';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _confirmController,
              obscureText: _obscure2,
              decoration: InputDecoration(
                labelText: 'تأكيد كلمة المرور',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure2 = !_obscure2),
                  icon: Icon(
                    _obscure2 ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) {
                  return 'أعد كتابة كلمة المرور';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: _saving
                  ? null
                  : () {
                final newPass = _generatePassword();
                setState(() {
                  _passwordController.text = newPass;
                  _confirmController.text = newPass;
                  _obscure1 = false;
                  _obscure2 = false;
                });
              },
              icon: const Icon(Icons.casino),
              label: const Text('توليد كلمة مرور عشوائية'),
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
                  _saving ? 'جاري الحفظ...' : '💾 حفظ كلمة المرور',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
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
// Add Mikrotik User Page - إضافة مستخدم
// =============================================================================

class AddMikrotikUserPage extends StatefulWidget {
  final MikroTikApi api;

  const AddMikrotikUserPage({
    super.key,
    required this.api,
  });

  @override
  State<AddMikrotikUserPage> createState() => _AddMikrotikUserPageState();
}

class _AddMikrotikUserPageState extends State<AddMikrotikUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _commentController = TextEditingController();

  String _selectedGroup = 'full';
  bool _saving = false;
  bool _obscure = true;

  final List<String> _groups = const [
    'full',
    'write',
    'read',
    'api',
    'winbox',
    'web',
    'ftp',
    'romon',
    'policy',
    'dude',
    'sniffer',
    'sensitive',
    'test',
    'rest-api',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final id = await widget.api.addMikrotikUser(
        name: _nameController.text.trim(),
        password: _passwordController.text,
        group: _selectedGroup,
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;

      if (id == null || id.isEmpty) {
        setState(() => _saving = false);
        _showMessage('فشل إنشاء المستخدم', isError: true);
        return;
      }

      _showMessage('تم إنشاء المستخدم بنجاح ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('فشل الإنشاء: $e', isError: true);
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
        title: const Text('➕ إضافة مستخدم'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم *',
                hintText: 'مثال: operator1',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'أدخل اسم المستخدم';
                }
                if (v.trim().length < 3) {
                  return 'الاسم قصير جداً';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'كلمة المرور *',
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  onPressed: () => setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.length < 4) {
                  return 'كلمة المرور 4 أحرف على الأقل';
                }
                return null;
              },
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              initialValue: _selectedGroup,
              decoration: const InputDecoration(
                labelText: 'المجموعة *',
                border: OutlineInputBorder(),
              ),
              items: _groups.map((g) {
                return DropdownMenuItem(value: g, child: Text(g));
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedGroup = v);
              },
            ),

            const SizedBox(height: 12),

            TextFormField(
              controller: _commentController,
              decoration: const InputDecoration(
                labelText: 'ملاحظة (اختياري)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
                  _saving ? 'جاري الإنشاء...' : '💾 إنشاء المستخدم',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}