import 'package:flutter/material.dart';
import 'mikrotik_api.dart';

// =============================================================================
// User Manager Users Page
// =============================================================================

class UserManagerUsersPage extends StatefulWidget {
  final MikroTikApi api;

  const UserManagerUsersPage({
    super.key,
    required this.api,
  });

  @override
  State<UserManagerUsersPage> createState() =>
      _UserManagerUsersPageState();
}

class _UserManagerUsersPageState
    extends State<UserManagerUsersPage> {
  late final MikroTikApi _api;

  final TextEditingController _searchController =
  TextEditingController();

  List<Map<String, String>> _users = [];
  List<Map<String, String>> _allUsers = [];

  bool _loading = true;
  String? _error;

  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api;
    _loadUsers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final users = await _api.getUserManagerUsers();

      if (!mounted) return;

      setState(() {
        _users = users;
        _allUsers = List<Map<String, String>>.from(users);
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

  void _searchUsers() {
    final query = _searchController.text.trim().toLowerCase();

    if (query.isEmpty) {
      setState(() {
        _users = List<Map<String, String>>.from(_allUsers);
      });
      return;
    }

    final filtered = _allUsers.where((user) {
      final name = (user['name'] ?? '').toLowerCase();
      final group = (user['group'] ?? '').toLowerCase();
      final attributes = (user['attributes'] ?? '').toLowerCase();

      return name.contains(query) ||
          group.contains(query) ||
          attributes.contains(query);
    }).toList();

    setState(() {
      _users = filtered;
    });

    if (filtered.isEmpty) {
      _showMessage(
        'لم يتم العثور على نتائج لـ "$query"',
        isError: true,
      );
    } else {
      _showMessage('تم العثور على ${filtered.length} كرت ✅');
    }
  }

  Future<void> _openAddUser() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => _AddUserManagerUserDialog(api: _api),
    );

    if (result == true) await _loadUsers();
  }

  Future<void> _deleteUser(Map<String, String> user) async {
    final id = user['.id'];
    final name = user['name'] ?? '';

    if (id == null || id.isEmpty) {
      _showMessage('لا يوجد ID لهذا المستخدم', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('حذف المستخدم'),
        content: Text(
          'هل تريد حذف "$name" نهائياً؟\n\n'
              '⚠️ لا يمكن التراجع.',
        ),
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
      await _api.deleteUserManagerUser(id);

      if (!mounted) return;

      setState(() {
        _users.removeWhere((item) => item['.id'] == id);
        _allUsers.removeWhere((item) => item['.id'] == id);
      });

      _showMessage('تم حذف "$name" ✅');
    } catch (e) {
      if (!mounted) return;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text('👥 User Manager (${_users.length})'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'بحث',
            onPressed: () {
              setState(() => _showSearchBar = !_showSearchBar);
              if (!_showSearchBar) {
                _searchController.clear();
                setState(() {
                  _users = List<Map<String, String>>.from(_allUsers);
                });
              }
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loading ? null : _loadUsers,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loading ? null : _openAddUser,
        icon: const Icon(Icons.person_add),
        label: const Text('إضافة مستخدم'),
      ),
      body: Column(
        children: [
          if (_showSearchBar)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم الكرت أو المجموعة...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: _searchUsers,
                    icon: const Icon(Icons.arrow_forward),
                  ),
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  isDense: true,
                ),
                onSubmitted: (_) => _searchUsers(),
              ),
            ),
          if (_loading) const LinearProgressIndicator(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading && _users.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
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
                onPressed: _loadUsers,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
    }

    if (_users.isEmpty) {
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
                  Icons.people_outline,
                  size: 60,
                  color: Colors.blue.shade400,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'لا يوجد مستخدمون',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اضغط "إضافة مستخدم" لإنشاء أول كرت',
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: _users.length,
      itemBuilder: (context, index) {
        return _buildUserCard(_users[index]);
      },
    );
  }

  Widget _buildUserCard(Map<String, String> user) {
    final name = user['name'] ?? '-';
    final group = user['group'] ?? '-';
    final sharedUsers = user['shared-users'] ?? '1';
    final attributes = user['attributes'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.blue.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // أيقونة
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person,
                color: Colors.blue,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),

            // المعلومات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'monospace',
                    ),
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          group,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Icon(
                        Icons.devices,
                        size: 11,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        sharedUsers,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                  if (attributes.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      attributes,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            // زر الحذف
            IconButton(
              onPressed: () => _deleteUser(user),
              tooltip: 'حذف',
              icon: const Icon(
                Icons.delete,
                color: Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Add User Dialog
// =============================================================================

class _AddUserManagerUserDialog extends StatefulWidget {
  final MikroTikApi api;

  const _AddUserManagerUserDialog({required this.api});

  @override
  State<_AddUserManagerUserDialog> createState() =>
      _AddUserManagerUserDialogState();
}

class _AddUserManagerUserDialogState
    extends State<_AddUserManagerUserDialog> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sharedUsersController =
  TextEditingController(text: '1');

  bool _saving = false;
  bool _obscure = true;

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _sharedUsersController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final id = await widget.api.addUserManagerUser(
        name: _nameController.text.trim(),
        password: _passwordController.text,
        sharedUsers: int.tryParse(
          _sharedUsersController.text.trim(),
        ) ??
            1,
      );

      if (!mounted) return;

      if (id == null || id.isEmpty) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل الإنشاء'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('➕ إضافة مستخدم'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المستخدم *',
                hintText: 'مثال: 98123',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.person),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'مطلوب';
                }
                if (v.trim().length < 3) {
                  return 'الاسم قصير جداً';
                }
                return null;
              },
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              decoration: InputDecoration(
                labelText: 'كلمة المرور (اختياري)',
                hintText: 'اتركها فارغة للدخول بدون كلمة مرور',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () =>
                      setState(() => _obscure = !_obscure),
                  icon: Icon(
                    _obscure
                        ? Icons.visibility
                        : Icons.visibility_off,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: _sharedUsersController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'عدد الأجهزة',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.devices),
                helperText: 'عدد الأجهزة المسموح بها لكل كرت',
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
      actions: [
        TextButton(
          onPressed:
          _saving ? null : () => Navigator.pop(context, false),
          child: const Text('إلغاء'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text('إضافة'),
        ),
      ],
    );
  }
}