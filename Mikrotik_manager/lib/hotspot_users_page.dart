import 'package:flutter/material.dart';
import 'mikrotik_api.dart';
import 'add_hotspot_pages.dart';

// =============================================================================
// Hotspot Users Page — تصميم جديد
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

final TextEditingController _searchController = TextEditingController();

List<Map<String, String>> _users = [];
List<Map<String, String>> _allUsers = [];

bool _loading = false;
String? _error;

String? _selectedProfile;
String _searchType = 'name';
String _sortBy = 'name';
bool _ascending = true;
bool _allLoaded = false;

// فلتر العرض: all / active / disabled
String _viewFilter = 'all';

// هل شريط البحث مفتوح؟
bool _showSearchBar = false;

@override
void initState() {
super.initState();

_api = widget.api;

if (widget.profile != null && widget.profile!.trim().isNotEmpty) {
_selectedProfile = widget.profile;
}
}

@override
void dispose() {
_searchController.dispose();
super.dispose();
}

// ===========================================================================
// View Filter
// ===========================================================================

List<Map<String, String>> get _visibleUsers {
List<Map<String, String>> filtered = _users;

switch (_viewFilter) {
case 'active':
filtered = _users.where((u) {
final d = u['disabled'] == 'yes' || u['disabled'] == 'true';
return !d;
}).toList();
break;
case 'disabled':
filtered = _users.where((u) {
final d = u['disabled'] == 'yes' || u['disabled'] == 'true';
return d;
}).toList();
break;
case 'all':
default:
filtered = _users;
break;
}

return filtered;
}

int get _activeCount {
return _users.where((u) {
final d = u['disabled'] == 'yes' || u['disabled'] == 'true';
return !d;
}).length;
}

int get _disabledCount {
return _users.where((u) {
final d = u['disabled'] == 'yes' || u['disabled'] == 'true';
return d;
}).length;
}

// ===========================================================================
// Search
// ===========================================================================

Future<void> _searchUsers() async {
if (_loading) return;

final search = _searchController.text.trim();

if (search.isEmpty) {
if (_allUsers.isNotEmpty) {
setState(() {
_users = List<Map<String, String>>.from(_allUsers);
_sortUsers();
});
}
return;
}

if (_allUsers.isEmpty) {
setState(() => _loading = true);

try {
final all = await _api.getAllHotspotUsers(
profile: _selectedProfile,
);

if (!mounted) return;

setState(() {
_allUsers = List<Map<String, String>>.from(all);
_users = List<Map<String, String>>.from(all);
_allLoaded = true;
_loading = false;
_sortUsers();
});
} catch (e) {
if (!mounted) return;
setState(() => _loading = false);
_showMessage('فشل جلب الكروت: $e', isError: true);
return;
}
}

final query = search.toLowerCase();

final filtered = _allUsers.where((user) {
final name = (user['name'] ?? '').toLowerCase();
final password = (user['password'] ?? '').toLowerCase();
final comment = (user['comment'] ?? '').toLowerCase();
final profile = (user['profile'] ?? '').toLowerCase();

return name.contains(query) ||
password.contains(query) ||
comment.contains(query) ||
profile.contains(query);
}).toList();

if (!mounted) return;

if (filtered.isEmpty) {
_showMessage('لم يتم العثور على نتائج لـ "$search"', isError: true);
return;
}

setState(() {
_users = filtered;
_sortUsers();
});

_showMessage('تم العثور على ${filtered.length} كرت ✅');
}

// ===========================================================================
// Load by Profile
// ===========================================================================

Future<void> _loadByProfile() async {
if (_loading) return;

final profile = _selectedProfile?.trim();

if (profile == null || profile.isEmpty) {
_showMessage('حدد البروفايل أولاً.', isError: true);
return;
}

setState(() {
_loading = true;
_error = null;
_allLoaded = false;
});

try {
final users = await _api.getHotspotUsers(profile: profile);

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

// ===========================================================================
// Load All Users
// ===========================================================================

Future<void> _loadAllUsers() async {
if (_loading) return;

final confirmed = await showDialog<bool>(
context: context,
builder: (context) {
return AlertDialog(
title: const Text('جلب جميع الكروت'),
content: const Text(
'سيتم جلب جميع Hotspot Users من الراوتر.\n\n'
'إذا كان الراوتر يحتوي على آلاف الكروت، '
'قد يستغرق الأمر وقتًا.\n\n'
'هل تريد المتابعة؟',
),
actions: [
TextButton(
onPressed: () => Navigator.pop(context, false),
child: const Text('إلغاء'),
),
FilledButton(
onPressed: () => Navigator.pop(context, true),
child: const Text('جلب الكروت'),
),
],
);
},
);

if (confirmed != true) return;

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
_allUsers = List<Map<String, String>>.from(users);
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
_allUsers = List<Map<String, String>>.from(users);
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

// ===========================================================================
// Sort
// ===========================================================================

void _sortUsers() {
_users.sort((a, b) {
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
});
}

String _extractNumber(String value) {
final match = RegExp(r'\d+').firstMatch(value);

if (match == null) return value.toLowerCase();

final number = int.tryParse(match.group(0)!) ?? 0;
return number.toString().padLeft(20, '0');
}

int _durationToSeconds(String value) {
if (value.trim().isEmpty) return 0;

int total = 0;

final dayMatch =
RegExp(r'(\d+)d', caseSensitive: false).firstMatch(value);
final hourMatch =
RegExp(r'(\d+)h', caseSensitive: false).firstMatch(value);
final minuteMatch =
RegExp(r'(\d+)m', caseSensitive: false).firstMatch(value);
final secondMatch =
RegExp(r'(\d+)s', caseSensitive: false).firstMatch(value);

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

// ===========================================================================
// Edit / Delete / Add / Generate
// ===========================================================================

Future<void> _editUser(Map<String, String> user) async {
// placeholder — نضيف HotspotUserEditPage لاحقاً
_showMessage('شاشة التعديل ستُضاف قريباً');
}

Future<void> _deleteUser(Map<String, String> user) async {
final id = user['.id'];

if (id == null || id.isEmpty) {
_showMessage('لا يوجد ID لهذا المستخدم', isError: true);
return;
}

final name = user['name'] ?? 'المستخدم';

final confirmed = await showDialog<bool>(
context: context,
builder: (context) {
return AlertDialog(
title: const Text('تأكيد الحذف'),
content: Text('هل تريد حذف الكرت "$name" نهائيًا؟'),
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
setState(() => _loading = true);

await _api.deleteHotspotUser(id);

if (!mounted) return;

setState(() {
_users.removeWhere((item) => item['.id'] == id);
_allUsers.removeWhere((item) => item['.id'] == id);
_loading = false;
});

_showMessage('تم حذف الكرت بنجاح ✅');
} catch (e) {
if (!mounted) return;

setState(() => _loading = false);

_showMessage('فشل حذف الكرت: $e', isError: true);
}
}

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
} else if (_selectedProfile != null &&
_selectedProfile!.isNotEmpty) {
await _loadByProfile();
}
}
}

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
} else if (_selectedProfile != null &&
_selectedProfile!.isNotEmpty) {
await _loadByProfile();
}
}
}

// ===========================================================================
// Helpers
// ===========================================================================

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

String _formatBytes(String value) {
final bytes = int.tryParse(value);
if (bytes == null || bytes <= 0) return '-';

if (bytes < 1024) return '$bytes B';
if (bytes < 1024 * 1024) {
return '${(bytes / 1024).toStringAsFixed(1)} KB';
}
if (bytes < 1024 * 1024 * 1024) {
return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
}
return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
}

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    final title = widget.profile == null
        ? '👥 المستخدمون'
        : '👥 ${widget.profile}';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'بحث',
            onPressed: () {
              setState(() => _showSearchBar = !_showSearchBar);
              if (!_showSearchBar) {
                _searchController.clear();
                if (_allUsers.isNotEmpty) {
                  setState(() {
                    _users = List<Map<String, String>>.from(_allUsers);
                    _sortUsers();
                  });
                }
              }
            },
            icon: const Icon(Icons.search),
          ),
          IconButton(
            tooltip: 'تحديث',
            onPressed: _loading
                ? null
                : () {
              if (_allLoaded) {
                _loadAllUsersWithoutDialog();
              }
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          FloatingActionButton.small(
            heroTag: 'addUser',
            onPressed: _loading ? null : _openAddUser,
            backgroundColor: Colors.blue,
            tooltip: 'إضافة كرت',
            child: const Icon(Icons.add, color: Colors.white),
          ),
          const SizedBox(height: 8),
          FloatingActionButton.extended(
            heroTag: 'generateCards',
            onPressed: _loading ? null : _openGenerateCards,
            backgroundColor: Colors.orange,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text(
              'توليد كروت',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ============================================
          // شريط البحث (يظهر عند الطلب)
          // ============================================
          if (_showSearchBar)
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
              color: Colors.white,
              child: TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'ابحث باسم الكرت، كلمة المرور، البروفايل...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    onPressed: _loading ? null : _searchUsers,
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

          // ============================================
          // بطاقة الإحصائيات + الفلتر
          // ============================================
          if (_allLoaded && _allUsers.isNotEmpty) _buildStatsCard(),

          // ============================================
          // شريط الأدوات (فقط عند التحميل)
          // ============================================
          if (!_allLoaded || _allUsers.isEmpty) _buildToolbar(),

          // ============================================
          // شريط التقدم
          // ============================================
          if (_loading) const LinearProgressIndicator(),

          // ============================================
          // خطأ
          // ============================================
          if (_error != null) _buildError(),

          // ============================================
          // حالة فارغة
          // ============================================
          if (!_loading &&
              _error == null &&
              _users.isEmpty &&
              !_allLoaded)
            _buildEmptyState(),

          // ============================================
          // قائمة الكروت
          // ============================================
          if (_visibleUsers.isNotEmpty)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(
                  left: 10,
                  right: 10,
                  top: 4,
                  bottom: 100,
                ),
                itemCount: _visibleUsers.length,
                itemBuilder: (context, index) {
                  return _buildUserCard(_visibleUsers[index]);
                },
              ),
            )
          else if (_allLoaded && _users.isNotEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.filter_alt_off,
                      size: 60,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _viewFilter == 'active'
                          ? 'لا توجد كروت فعّالة'
                          : 'لا توجد كروت معطّلة',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Stats Card
  // ===========================================================================

  Widget _buildStatsCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade500, Colors.blue.shade700],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        children: [
          // الصف الأول — العدد الكلي
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.people,
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
                      'إجمالي الكروت',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${_users.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              // زر الفرز
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () {
                    setState(() {
                      _ascending = !_ascending;
                      _sortUsers();
                    });
                  },
                  tooltip: 'عكس الترتيب',
                  icon: Icon(
                    _ascending
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // الصف الثاني — الفلتر (All / Active / Disabled)
          Row(
            children: [
              _viewFilterChip(
                label: 'الكل',
                count: _users.length,
                value: 'all',
                color: Colors.white,
                icon: Icons.list,
              ),
              const SizedBox(width: 6),
              _viewFilterChip(
                label: 'فعّالة',
                count: _activeCount,
                value: 'active',
                color: Colors.green.shade300,
                icon: Icons.check_circle,
              ),
              const SizedBox(width: 6),
              _viewFilterChip(
                label: 'معطّلة',
                count: _disabledCount,
                value: 'disabled',
                color: Colors.red.shade300,
                icon: Icons.block,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewFilterChip({
    required String label,
    required int count,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    final isSelected = _viewFilter == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _viewFilter = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? Colors.white
                : Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isSelected ? color : Colors.white70,
              ),
              const SizedBox(width: 4),
              Text(
                '$label ($count)',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? color == Colors.white
                      ? Colors.blue.shade800
                      : color
                      : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Toolbar (قبل جلب الكروت)
  // ===========================================================================

  Widget _buildToolbar() {
    return Container(
      padding: const EdgeInsets.all(12),
      color: Colors.white,
      child: Column(
        children: [
          // صف أول: نوع البحث + الفرز
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _searchType,
                  decoration: const InputDecoration(
                    labelText: 'نوع البحث',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('اسم', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'number',
                      child: Text('رقم', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _searchType = value);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sortBy,
                  decoration: const InputDecoration(
                    labelText: 'الفرز',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                    prefixIcon: Icon(Icons.sort, size: 18),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'name',
                      child: Text('الاسم', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'number',
                      child: Text('الرقم', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'profile',
                      child:
                      Text('البروفايل', style: TextStyle(fontSize: 13)),
                    ),
                    DropdownMenuItem(
                      value: 'duration',
                      child: Text('المدة', style: TextStyle(fontSize: 13)),
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

          // صف ثاني: جلب الكل
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              onPressed: _loading ? null : _loadAllUsers,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.blue.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.cloud_download),
              label: const Text(
                '📥 جلب جميع الكروت',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // User Card
  // ===========================================================================

  Widget _buildUserCard(Map<String, String> user) {
    final username = user['name'] ?? '-';
    final profile = user['profile'] ?? '-';
    final password = user['password'] ?? '';
    final limitUptime = user['limit-uptime'] ?? '-';
    final limitBytes = user['limit-bytes-total'] ?? '';
    final comment = user['comment'] ?? '';

    final isDisabled = user['disabled'] == 'yes' ||
        user['disabled'] == 'true';

    final cardColor =
    isDisabled ? Colors.red.shade50 : Colors.green.shade50;
    final iconColor = isDisabled ? Colors.red : Colors.green;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: iconColor.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: iconColor.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
          ),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 2,
            ),
            childrenPadding: EdgeInsets.zero,
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: cardColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDisabled ? Icons.block : Icons.person,
                color: iconColor,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    username,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'monospace',
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isDisabled)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'معطّل',
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  // شارة البروفايل
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.category,
                          size: 10,
                          color: Colors.purple.shade600,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          profile,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.purple.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (password.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.lock,
                            size: 10,
                            color: Colors.amber.shade700,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            password,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.amber.shade800,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            children: [
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _detailRow(Icons.person, 'Username', username),
                    if (password.isNotEmpty)
                      _detailRow(Icons.lock, 'Password', password),
                    _detailRow(Icons.category, 'Profile', profile),
                    _detailRow(Icons.timer, 'Limit Uptime', limitUptime),
                    if (limitBytes.isNotEmpty)
                      _detailRow(
                        Icons.data_usage,
                        'Limit Bytes',
                        _formatBytes(limitBytes),
                      ),
                    _detailRow(
                      Icons.block,
                      'الحالة',
                      isDisabled ? 'معطّل' : 'فعّال',
                    ),
                    if (comment.isNotEmpty)
                      _detailRow(Icons.comment, 'ملاحظة', comment),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _editUser(user),
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('تعديل'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _deleteUser(user),
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            icon: const Icon(Icons.delete, size: 18),
                            label: const Text('حذف'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Error / Empty State
  // ===========================================================================

  Widget _buildError() {
    return Padding(
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
              Text(_error!, textAlign: TextAlign.center),
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
    );
  }

  Widget _buildEmptyState() {
    return Expanded(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(25),
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
                  Icons.manage_search,
                  size: 60,
                  color: Colors.blue.shade400,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'ابحث عن كرت أو جلب جميع الكروت',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'اضغط على "جلب جميع الكروت" أو استخدم البحث',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}