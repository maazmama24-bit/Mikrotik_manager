import 'dart:math';
import 'package:flutter/material.dart';
import 'mikrotik_api.dart';
import 'print_cards_page.dart';


// =============================================================================
// 🎨 App Colors
// =============================================================================

class _AppColors {
  static const primary = Color(0xFF4A6CF7);
  static const primaryDark = Color(0xFF3451C7);
  static const accent = Color(0xFF00C2A8);
  static const cards = Color(0xFF7C3AED);
  static const profiles = Color(0xFFF59E0B);
  static const limitations = Color(0xFFEF4444);
  static const sessions = Color(0xFF10B981);
  static const bg = Color(0xFFF4F6FB);
}

// =============================================================================
// User Manager Hub Page
// =============================================================================

class UserManagerHubPage extends StatefulWidget {
  final MikroTikApi api;

  /// إذا كانت محددة، يعرض هذا التاب فقط بدون شريط التابات.
  /// القيم: 'cards' | 'profiles' | 'limitations' | 'sessions'
  final String? singleTab;

  const UserManagerHubPage({
    super.key,
    required this.api,
    this.singleTab,
  });

  @override
  State<UserManagerHubPage> createState() => _UserManagerHubPageState();
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
    // 🎯 وضع "تاب واحد"
    if (widget.singleTab != null) {
      return _buildSingleTabView();
    }

    return Scaffold(
      backgroundColor: _AppColors.bg,
      body: NestedScrollView(
        headerSliverBuilder: (context, _) => [
          SliverAppBar(
            pinned: true,
            expandedHeight: 170,
            backgroundColor: _AppColors.primary,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              title: const Text(
                'User Manager',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_AppColors.primary, _AppColors.primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: -30,
                      right: -30,
                      child:
                      _blob(120, Colors.white.withValues(alpha: 0.08)),
                    ),
                    Positioned(
                      bottom: -40,
                      left: -20,
                      child:
                      _blob(140, Colors.white.withValues(alpha: 0.06)),
                    ),
                    const Positioned(
                      left: 20,
                      top: 60,
                      child: Row(
                        children: [
                          Icon(Icons.manage_accounts,
                              color: Colors.white, size: 32),
                          SizedBox(width: 10),
                          Text(
                            'إدارة المستخدمين والكروت',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(60),
              child: Container(
                margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  indicator: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    gradient: const LinearGradient(
                      colors: [_AppColors.primary, _AppColors.primaryDark],
                    ),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  indicatorPadding: const EdgeInsets.all(4),
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.grey.shade600,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  tabs: const [
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Icon(Icons.credit_card, size: 16),
                            SizedBox(width: 6),
                            Text('Cards'),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Icon(Icons.category, size: 16),
                            SizedBox(width: 6),
                            Text('Profiles'),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Icon(Icons.tune, size: 16),
                            SizedBox(width: 6),
                            Text('Limitations'),
                          ],
                        ),
                      ),
                    ),
                    Tab(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Row(
                          children: [
                            Icon(Icons.wifi, size: 16),
                            SizedBox(width: 6),
                            Text('Sessions'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            _CardsTab(api: widget.api),
            _ProfilesTab(api: widget.api),
            _LimitationsTab(api: widget.api),
            _SessionsTab(api: widget.api),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
  /// عرض تاب محدد فقط بدون شريط التابات.
  Widget _buildSingleTabView() {
    final tab = widget.singleTab;

    late final String title;
    late final IconData icon;
    late final Color color;
    late final Widget child;

    switch (tab) {
      case 'cards':
        title = 'توليد كروت User Manager';
        icon = Icons.credit_card;
        color = _AppColors.cards;
        child = _CardsTab(api: widget.api);
        break;
      case 'profiles':
        title = 'User Manager Profiles';
        icon = Icons.category;
        color = _AppColors.profiles;
        child = _ProfilesTab(api: widget.api);
        break;
      case 'limitations':
        title = 'User Manager Limitations';
        icon = Icons.tune;
        color = _AppColors.limitations;
        child = _LimitationsTab(api: widget.api);
        break;
      case 'sessions':
        title = 'User Manager Sessions';
        icon = Icons.wifi;
        color = _AppColors.sessions;
        child = _SessionsTab(api: widget.api);
        break;
      default:
        return const SizedBox.shrink();
    }

    return Scaffold(
      backgroundColor: _AppColors.bg,
      appBar: AppBar(
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
      body: child,
    );
  }
}

// =============================================================================
// 🧩 Shared Widgets
// =============================================================================

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Color color;

  const _EmptyState({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48, color: color),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 6),
            Text(
              subtitle!,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.error_outline,
                  size: 44, color: Colors.red),
            ),
            const SizedBox(height: 14),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: FilledButton.styleFrom(
                backgroundColor: _AppColors.primary,
                padding:
                const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingState extends StatelessWidget {
  final Color color;
  const _LoadingState({this.color = _AppColors.primary});

  @override
  Widget build(BuildContext context) {
    return Center(child: CircularProgressIndicator(color: color));
  }
}

class _ModernCard extends StatelessWidget {
  final Widget child;
  final Color accentColor;

  const _ModernCard({
    required this.child,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: child,
        ),
      ),
    );
  }
}

class _IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _IconBadge({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }
}

class _ChipLabel extends StatelessWidget {
  final String text;
  final Color color;
  final IconData? icon;

  const _ChipLabel({required this.text, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 🎴 Cards Tab — تصميم جديد
// =============================================================================

class _CardsTab extends StatefulWidget {
  final MikroTikApi api;
  const _CardsTab({required this.api});

  @override
  State<_CardsTab> createState() => _CardsTabState();
}

class _CardsTabState extends State<_CardsTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, String>> _users = [];
  List<Map<String, String>> _profiles = [];
  bool _loading = true;
  String? _error;

  // 🔍 بحث وفرز
  String _searchQuery = '';
  String _sortBy = 'name'; // name | profile | status
  String _filterStatus = 'all'; // all | active | disabled

  // 📂 البطاقات المفتوحة
  final Set<String> _expandedIds = {};

  @override
  bool get wantKeepAlive => true;

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

  // 🔍 القائمة المفلترة والمرتبة
  List<Map<String, String>> get _filteredUsers {
    var list = List<Map<String, String>>.from(_users);

    // فلترة الحالة
    if (_filterStatus == 'active') {
      list = list
          .where((u) =>
      u['disabled'] != 'true' && u['disabled'] != 'yes')
          .toList();
    } else if (_filterStatus == 'disabled') {
      list = list
          .where((u) =>
      u['disabled'] == 'true' || u['disabled'] == 'yes')
          .toList();
    }

    // بحث
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((u) {
        final name = (u['name'] ?? '').toLowerCase();
        final profile = (u['profile'] ?? '').toLowerCase();
        final comment = (u['comment'] ?? '').toLowerCase();
        return name.contains(q) ||
            profile.contains(q) ||
            comment.contains(q);
      }).toList();
    }

    // فرز
    list.sort((a, b) {
      switch (_sortBy) {
        case 'profile':
          return (a['profile'] ?? '').compareTo(b['profile'] ?? '');
        case 'status':
          final aDis = a['disabled'] == 'true' || a['disabled'] == 'yes';
          final bDis = b['disabled'] == 'true' || b['disabled'] == 'yes';
          if (aDis == bDis) return 0;
          return aDis ? 1 : -1;
        case 'name':
        default:
          return (a['name'] ?? '').compareTo(b['name'] ?? '');
      }
    });

    return list;
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  Future<void> _openAddUser() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserDialog(api: widget.api),
    );
    if (result == true) {
      _showMessage('تم إضافة المستخدم ✅');
      await _loadAll();
    }
  }

  Future<void> _openEditUser(Map<String, String> user) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _UserDialog(api: widget.api, existingUser: user),
    );
    if (result == true) {
      _showMessage('تم تحديث المستخدم ✅');
      await _loadAll();
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
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('حذف الكرت'),
          ],
        ),
        content: Text('هل تريد حذف "$name"؟'),
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
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Colors.red : _AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) return const _LoadingState(color: _AppColors.cards);
    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _loadAll);
    }

    final filtered = _filteredUsers;

    return Stack(
      children: [
        Column(
          children: [
            // 🔝 شريط البحث + الفرز + العدد
            _buildTopBar(filtered.length),

            // 📋 القائمة
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                color: _AppColors.cards,
                onRefresh: _loadAll,
                child: ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(12, 4, 12, 160),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    return _buildCard(filtered[i]);
                  },
                ),
              ),
            ),
          ],
        ),

        // 🎯 FAB إضافة
        Positioned(
          bottom: 20,
          left: 20,
          child: FloatingActionButton(
            heroTag: 'add_user',
            onPressed: _openAddUser,
            backgroundColor: _AppColors.primary,
            tooltip: 'إضافة مستخدم',
            child: const Icon(Icons.person_add, color: Colors.white),
          ),
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            heroTag: 'gen_cards',
            onPressed: _openGenerate,
            backgroundColor: _AppColors.cards,
            icon: const Icon(Icons.auto_awesome, color: Colors.white),
            label: const Text(
              'توليد',
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

  // ===========================================================================
  // 🔝 الشريط العلوي
  // ===========================================================================

  Widget _buildTopBar(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      color: _AppColors.bg,
      child: Column(
        children: [
          // الصف الأول: العدد + أيقونة الفرز
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _AppColors.cards.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.credit_card,
                        color: _AppColors.cards, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'الكروت ($count)',
                      style: TextStyle(
                        color: _AppColors.cards,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              // زر الفرز
              PopupMenuButton<String>(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.sort,
                      color: _AppColors.primary, size: 20),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (v) => setState(() => _sortBy = v),
                itemBuilder: (context) => [
                  _sortItem('name', 'الاسم (أ-ي)', Icons.sort_by_alpha),
                  _sortItem('profile', 'البروفايل', Icons.category),
                  _sortItem('status', 'الحالة', Icons.toggle_on),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),

          // الصف الثاني: البحث
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو البروفايل...',
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search,
                  color: _AppColors.primary, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: _AppColors.cards.withValues(alpha: 0.5),
                    width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // الصف الثالث: فلاتر
          Row(
            children: [
              Expanded(
                child: _filterChip(
                  'الكل',
                  'all',
                  _users.length,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _filterChip(
                  'نشط',
                  'active',
                  _users
                      .where((u) =>
                  u['disabled'] != 'true' &&
                      u['disabled'] != 'yes')
                      .length,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _filterChip(
                  'معطّل',
                  'disabled',
                  _users
                      .where((u) =>
                  u['disabled'] == 'true' ||
                      u['disabled'] == 'yes')
                      .length,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  PopupMenuItem<String> _sortItem(
      String value, String label, IconData icon) {
    final isSelected = _sortBy == value;
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(icon,
              size: 18,
              color: isSelected ? _AppColors.primary : Colors.grey),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? _AppColors.primary : null,
              fontWeight:
              isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          const Spacer(),
          if (isSelected)
            const Icon(Icons.check, color: _AppColors.primary, size: 18),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count) {
    final isSelected = _filterStatus == value;
    return GestureDetector(
      onTap: () => setState(() => _filterStatus = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _AppColors.cards : Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: _AppColors.cards.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey.shade700,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : _AppColors.cards.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  color: isSelected ? Colors.white : _AppColors.cards,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================================================================
  // 🎴 بطاقة الكرت
  // ===========================================================================

  Widget _buildCard(Map<String, String> user) {
    final id = user['.id'] ?? '';
    final name = user['name'] ?? '-';
    final profile = user['profile'] ?? '-';
    final sharedUsers = user['shared-users'] ?? '1';
    final isDisabled =
        user['disabled'] == 'true' || user['disabled'] == 'yes';
    final isExpanded = _expandedIds.contains(id);
    final comment = user['comment'] ?? '';
    final password = user['password'] ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleExpand(id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // === السطر الأساسي ===
                Row(
                  children: [
                    // الأيقونة الخضراء الدائرية
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isDisabled
                            ? Colors.grey.shade300
                            : _AppColors.sessions,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isDisabled ? Icons.block : Icons.wifi,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // الاسم + السطر الفرعي
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isDisabled
                                ? 'معطّل'
                                : '$profile${comment.isNotEmpty ? ' • $comment' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),

                    // سهم الفتح/الإغلاق
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade500,
                        size: 26,
                      ),
                    ),
                  ],
                ),

                // === الجزء المنبثق ===
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Column(
                    children: [
                      const SizedBox(height: 14),
                      Container(
                        height: 1,
                        color: Colors.grey.shade200,
                      ),
                      const SizedBox(height: 14),

                      // حبوب المعلومات
                      Row(
                        children: [
                          Expanded(
                            child: _infoChip(
                              icon: Icons.category,
                              label: 'البروفايل',
                              value: profile,
                              color: const Color(0xFFE1BEE7),
                              iconColor: const Color(0xFF9C27B0),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _infoChip(
                              icon: Icons.devices,
                              label: 'الأجهزة',
                              value: sharedUsers,
                              color: const Color(0xFFC8E6C9),
                              iconColor: const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _infoChip(
                              icon: isDisabled
                                  ? Icons.block
                                  : Icons.check_circle,
                              label: 'الحالة',
                              value: isDisabled ? 'معطّل' : 'نشط',
                              color: isDisabled
                                  ? const Color(0xFFFFCDD2)
                                  : const Color(0xFFBBDEFB),
                              iconColor: isDisabled
                                  ? const Color(0xFFE53935)
                                  : const Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),

                      // كلمة المرور (إن وُجدت)
                      if (password.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.lock_outline,
                                  size: 16,
                                  color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'كلمة المرور: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                password,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // صف الحقول الثانوية
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _secondaryField(
                              'Shared', sharedUsers, Icons.people_outline),
                          Container(
                              width: 1,
                              height: 24,
                              color: Colors.grey.shade200),
                          _secondaryField(
                              'Comment',
                              comment.isEmpty ? '-' : comment,
                              Icons.notes),
                        ],
                      ),

                      const SizedBox(height: 14),

                      // الأزرار
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openEditUser(user),
                              icon: const Icon(Icons.edit_outlined,
                                  size: 16),
                              label: const Text('تعديل'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _AppColors.primary,
                                side: BorderSide(
                                    color: _AppColors.primary
                                        .withValues(alpha: 0.4)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _deleteUser(user),
                              icon: const Icon(Icons.delete_outline,
                                  size: 16),
                              label: const Text('حذف'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(
                                    color:
                                    Colors.red.withValues(alpha: 0.4)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
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
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _secondaryField(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(width: 3),
              Icon(icon, size: 12, color: Colors.grey.shade500),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _AppColors.cards.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.credit_card,
                size: 48, color: _AppColors.cards),
          ),
          const SizedBox(height: 16),
          Text(
            _users.isEmpty ? 'لا توجد كروت' : 'لا توجد نتائج',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _users.isEmpty
                ? 'أضف مستخدماً أو استخدم التوليد الجماعي'
                : 'جرّب تعديل البحث أو الفلاتر',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 👤 User Dialog (Add / Edit)
// =============================================================================

class _UserDialog extends StatefulWidget {
  final MikroTikApi api;
  final Map<String, String>? existingUser;

  const _UserDialog({required this.api, this.existingUser});

  @override
  State<_UserDialog> createState() => _UserDialogState();
}

class _UserDialogState extends State<_UserDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _groupCtrl;
  late final TextEditingController _sharedCtrl;
  late final TextEditingController _attributesCtrl;
  late final TextEditingController _commentCtrl;

  bool _disabled = false;
  bool _obscurePassword = true;
  bool _saving = false;

  bool get isEdit => widget.existingUser != null;

  @override
  void initState() {
    super.initState();
    final u = widget.existingUser;
    _nameCtrl = TextEditingController(text: u?['name'] ?? '');
    _passwordCtrl = TextEditingController(text: u?['password'] ?? '');
    _groupCtrl = TextEditingController(text: u?['group'] ?? 'default');
    _sharedCtrl = TextEditingController(text: u?['shared-users'] ?? '1');
    _attributesCtrl = TextEditingController(text: u?['attributes'] ?? '');
    _commentCtrl = TextEditingController(text: u?['comment'] ?? '');
    _disabled = u?['disabled'] == 'true' || u?['disabled'] == 'yes';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _passwordCtrl.dispose();
    _groupCtrl.dispose();
    _sharedCtrl.dispose();
    _attributesCtrl.dispose();
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final shared = int.tryParse(_sharedCtrl.text.trim()) ?? 1;

      if (isEdit) {
        await widget.api.updateUserManagerUser(
          id: widget.existingUser!['.id']!,
          name: _nameCtrl.text.trim(),
          password: _passwordCtrl.text,
          group: _groupCtrl.text.trim(),
          sharedUsers: shared,
          attributes: _attributesCtrl.text.trim(),
          comment: _commentCtrl.text.trim(),
          disabled: _disabled,
        );
      } else {
        await widget.api.addUserManagerUser(
          name: _nameCtrl.text.trim(),
          password: _passwordCtrl.text,
          group: _groupCtrl.text.trim(),
          sharedUsers: shared,
          attributes: _attributesCtrl.text.trim().isEmpty
              ? null
              : _attributesCtrl.text.trim(),
          comment: _commentCtrl.text.trim().isEmpty
              ? null
              : _commentCtrl.text.trim(),
          disabled: _disabled,
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحفظ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              _AppColors.cards,
                              Color(0xFF9F67FF)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit : Icons.person_add,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? 'تعديل المستخدم' : 'إضافة مستخدم',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                        _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _field(
                    controller: _nameCtrl,
                    label: 'الاسم',
                    icon: Icons.person_outline,
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'كلمة المرور',
                      prefixIcon:
                      const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _groupCtrl,
                    label: 'Group',
                    icon: Icons.group_outlined,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _sharedCtrl,
                    label: 'عدد الأجهزة',
                    icon: Icons.devices,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      if (n == null || n < 1) return 'رقم غير صالح';
                      return null;
                    },
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _attributesCtrl,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Attributes (اختياري)',
                      hintText: 'Mikrotik-Rate-Limit=2M/2M',
                      prefixIcon: const Icon(Icons.tune, size: 20),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _commentCtrl,
                    label: 'ملاحظات (اختياري)',
                    icon: Icons.notes,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: SwitchListTile(
                      value: _disabled,
                      onChanged: (v) => setState(() => _disabled = v),
                      title: const Text('تعطيل المستخدم'),
                      secondary: Icon(
                        _disabled
                            ? Icons.block
                            : Icons.check_circle_outline,
                        color: _disabled ? Colors.red : Colors.green,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                          _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Icon(isEdit ? Icons.save : Icons.add),
                          label: Text(_saving
                              ? 'جاري الحفظ...'
                              : (isEdit ? 'حفظ التعديلات' : 'إضافة')),
                          style: FilledButton.styleFrom(
                            backgroundColor: _AppColors.cards,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// =============================================================================
// 📁 Profiles Tab — تصميم جديد
// =============================================================================

class _ProfilesTab extends StatefulWidget {
  final MikroTikApi api;
  const _ProfilesTab({required this.api});

  @override
  State<_ProfilesTab> createState() => _ProfilesTabState();
}

class _ProfilesTabState extends State<_ProfilesTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, String>> _profiles = [];
  bool _loading = true;
  String? _error;

  // 🔍 بحث
  String _searchQuery = '';

  // 📂 البطاقات المفتوحة
  final Set<String> _expandedIds = {};

  @override
  bool get wantKeepAlive => true;

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

  List<Map<String, String>> get _filteredProfiles {
    if (_searchQuery.isEmpty) return _profiles;
    final q = _searchQuery.toLowerCase();
    return _profiles.where((p) {
      final name = (p['name'] ?? '').toLowerCase();
      return name.contains(q);
    }).toList();
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  Future<void> _openAdd() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProfileDialog(api: widget.api),
    );
    if (result == true) {
      _showMessage('تم إضافة Profile ✅');
      await _load();
    }
  }

  Future<void> _openEdit(Map<String, String> profile) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ProfileDialog(api: widget.api, existing: profile),
    );
    if (result == true) {
      _showMessage('تم تحديث Profile ✅');
      await _load();
    }
  }

  Future<void> _delete(Map<String, String> profile) async {
    final id = profile['.id'];
    final name = profile['name'] ?? '';
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('حذف Profile'),
          ],
        ),
        content: Text('هل تريد حذف "$name"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.api.deleteUserManagerProfile(id);
      if (!mounted) return;
      _showMessage('تم الحذف ✅');
      await _load();
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
          backgroundColor: isError ? Colors.red : _AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) return const _LoadingState(color: _AppColors.profiles);
    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _load);
    }

    final filtered = _filteredProfiles;

    return Stack(
      children: [
        Column(
          children: [
            // 🔝 شريط العدد + البحث
            _buildTopBar(filtered.length),

            // 📋 القائمة
            Expanded(
              child: filtered.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                color: _AppColors.profiles,
                onRefresh: _load,
                child: ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(12, 4, 12, 100),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    return _buildProfileCard(filtered[i]);
                  },
                ),
              ),
            ),
          ],
        ),

        // 🎯 FAB إضافة
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            heroTag: 'add_profile',
            onPressed: _openAdd,
            backgroundColor: _AppColors.profiles,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'إضافة',
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

  // ===========================================================================
  // 🔝 الشريط العلوي
  // ===========================================================================

  Widget _buildTopBar(int count) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      color: _AppColors.bg,
      child: Column(
        children: [
          // العدد
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _AppColors.profiles.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.category,
                        color: _AppColors.profiles, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'البروفايلات ($count)',
                      style: TextStyle(
                        color: _AppColors.profiles,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // البحث
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ابحث باسم البروفايل...',
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search,
                  color: _AppColors.profiles, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: _AppColors.profiles.withValues(alpha: 0.5),
                    width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🎴 بطاقة البروفايل
  // ===========================================================================

  Widget _buildProfileCard(Map<String, String> profile) {
    final id = profile['.id'] ?? '';
    final name = profile['name'] ?? '-';
    final validity = profile['validity'] ?? '-';
    final startsWhen = profile['starts-when'] ?? '-';
    final nameForUsers = profile['name-for-users'] ?? '';
    final price = profile['price'] ?? '-';
    final isExpanded = _expandedIds.contains(id);
    final isDefault = name == 'default';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleExpand(id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // === السطر الأساسي ===
                Row(
                  children: [
                    // الأيقونة
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isDefault
                              ? [
                            const Color(0xFFFFB74D),
                            const Color(0xFFFFA726)
                          ]
                              : [
                            _AppColors.profiles,
                            const Color(0xFFFBC16E)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (isDefault
                                ? const Color(0xFFFFA726)
                                : _AppColors.profiles)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isDefault ? Icons.star : Icons.category,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // الاسم + السطر الفرعي
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isDefault) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF3E0),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'افتراضي',
                                    style: TextStyle(
                                      color: Color(0xFFF57C00),
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Pool: ${profile['pool'] ?? '-'}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // سهم الفتح
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade500,
                        size: 26,
                      ),
                    ),
                  ],
                ),

                // === الجزء المنبثق ===
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Column(
                    children: [
                      const SizedBox(height: 14),
                      Container(
                          height: 1, color: Colors.grey.shade200),
                      const SizedBox(height: 14),

                      // حبوب المعلومات
                      Row(
                        children: [
                          Expanded(
                            child: _infoChip(
                              icon: Icons.timer,
                              label: 'المدة',
                              value: validity,
                              color: const Color(0xFFE1BEE7),
                              iconColor: const Color(0xFF9C27B0),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _infoChip(
                              icon: Icons.play_arrow,
                              label: 'يبدأ عند',
                              value: startsWhen,
                              color: const Color(0xFFC8E6C9),
                              iconColor: const Color(0xFF4CAF50),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _infoChip(
                              icon: Icons.attach_money,
                              label: 'السعر',
                              value: price,
                              color: const Color(0xFFBBDEFB),
                              iconColor: const Color(0xFF2196F3),
                            ),
                          ),
                        ],
                      ),

                      // الاسم الظاهر (إن وُجد)
                      if (nameForUsers.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.badge_outlined,
                                  size: 16,
                                  color: Colors.grey.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'الاسم الظاهر: ',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                              Text(
                                nameForUsers,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 14),

                      // الأزرار
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => _openEdit(profile),
                              icon: const Icon(Icons.edit_outlined,
                                  size: 16),
                              label: const Text('تعديل'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: _AppColors.profiles,
                                side: BorderSide(
                                    color: _AppColors.profiles
                                        .withValues(alpha: 0.4)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed:
                              isDefault ? null : () => _delete(profile),
                              icon: const Icon(Icons.delete_outline,
                                  size: 16),
                              label: const Text('حذف'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.red,
                                side: BorderSide(
                                    color:
                                    Colors.red.withValues(alpha: 0.4)),
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
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
      ),
    );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: _AppColors.profiles.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.category,
                size: 48, color: _AppColors.profiles),
          ),
          const SizedBox(height: 16),
          Text(
            _profiles.isEmpty ? 'لا توجد Profiles' : 'لا توجد نتائج',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _profiles.isEmpty
                ? 'أضف Profile جديد'
                : 'جرّب تعديل البحث',
            style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 📁 Profile Dialog (Add / Edit) — مع Limitations
// =============================================================================

class _ProfileDialog extends StatefulWidget {
  final MikroTikApi api;
  final Map<String, String>? existing;

  const _ProfileDialog({required this.api, this.existing});

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _validityCtrl;
  late final TextEditingController _nameForUsersCtrl;

  String _selectedStartsWhen = 'first-auth';
  bool _saving = false;

  // 🔗 Limitations
  List<Map<String, String>> _allLimitations = [];
  Set<String> _selectedLimitations = {}; // أسماء Limitations المختارة
  Map<String, String> _existingLinks = {}; // name → link ID
  bool _loadingLimitations = true;

  static const _startsWhenOptions = [
    'first-auth',
    'first-use',
    'now',
  ];

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    _nameCtrl = TextEditingController(text: p?['name'] ?? '');
    _validityCtrl = TextEditingController(text: p?['validity'] ?? '');
    _nameForUsersCtrl =
        TextEditingController(text: p?['name-for-users'] ?? '');

    final sw = p?['starts-when'];
    if (sw != null && _startsWhenOptions.contains(sw)) {
      _selectedStartsWhen = sw;
    }

    _loadLimitations();
  }

  Future<void> _loadLimitations() async {
    setState(() => _loadingLimitations = true);

    try {
      // 1. جلب كل الـ Limitations المتاحة
      final allLims = await widget.api.getUserManagerLimitations();

      // 2. إذا كنا في وضع تعديل، جلب الروابط الحالية للـ Profile
      Map<String, String> existing = {};
      if (isEdit) {
        final profileName = widget.existing!['name'] ?? '';
        final links = await widget.api.getLimitationsForProfile(profileName);
        for (final link in links) {
          final limName = link['limitation'] ?? '';
          final linkId = link['.id'] ?? '';
          if (limName.isNotEmpty && linkId.isNotEmpty) {
            existing[limName] = linkId;
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _allLimitations = allLims;
        _existingLinks = existing;
        _selectedLimitations = existing.keys.toSet();
        _loadingLimitations = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingLimitations = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _validityCtrl.dispose();
    _nameForUsersCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      final profileName = _nameCtrl.text.trim();

      // 1. حفظ/تحديث الـ Profile نفسه
      if (isEdit) {
        await widget.api.updateUserManagerProfile(
          id: widget.existing!['.id']!,
          name: profileName,
          validity: _validityCtrl.text.trim(),
          startsWhen: _selectedStartsWhen,
          nameForUsers: _nameForUsersCtrl.text.trim(),
        );
      } else {
        await widget.api.addUserManagerProfile(
          name: profileName,
          validity: _validityCtrl.text.trim(),
          startsWhen: _selectedStartsWhen,
          nameForUsers: _nameForUsersCtrl.text.trim().isEmpty
              ? null
              : _nameForUsersCtrl.text.trim(),
        );
      }

      // 2. مزامنة الـ Limitations
      await _syncLimitations(profileName);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحفظ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// مزامنة الـ Limitations: ربط الجديدة + فصل الملغاة.
  Future<void> _syncLimitations(String profileName) async {
    // أ) الربط الجديدة
    for (final limName in _selectedLimitations) {
      if (!_existingLinks.containsKey(limName)) {
        try {
          await widget.api.linkProfileToLimitation(
            profileName: profileName,
            limitationName: limName,
          );
        } catch (e) {
          debugPrint('⚠️ فشل ربط $limName: $e');
        }
      }
    }

    // ب) فصل التي أُزيلت
    for (final entry in _existingLinks.entries) {
      if (!_selectedLimitations.contains(entry.key)) {
        try {
          await widget.api.unlinkProfileFromLimitation(entry.value);
        } catch (e) {
          debugPrint('⚠️ فشل فصل ${entry.key}: $e');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // === Header ===
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              _AppColors.profiles,
                              Color(0xFFFBC16E)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit : Icons.category,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? 'تعديل Profile' : 'إضافة Profile',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                        _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),

                  // === الحقول الأساسية ===
                  _field(
                    controller: _nameCtrl,
                    label: 'الاسم',
                    icon: Icons.label_outline,
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _validityCtrl,
                    label: 'المدة (مثال: 30d, 4h, 1w)',
                    icon: Icons.timer,
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedStartsWhen,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'يبدأ عند',
                      prefixIcon: const Icon(Icons.play_arrow, size: 20),
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    items: _startsWhenOptions
                        .map((s) => DropdownMenuItem(
                      value: s,
                      child: Text(s),
                    ))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() => _selectedStartsWhen = v);
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _nameForUsersCtrl,
                    label: 'الاسم الظاهر للمستخدم (اختياري)',
                    icon: Icons.badge_outlined,
                  ),

                  const SizedBox(height: 20),
                  const Divider(height: 24),

                  // === قسم Limitations ===
                  Row(
                    children: [
                      Icon(Icons.tune,
                          color: _AppColors.limitations, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Limitations المرتبطة',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      if (_selectedLimitations.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _AppColors.limitations
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_selectedLimitations.length}',
                            style: TextStyle(
                              color: _AppColors.limitations,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اختر القيود المطلوبة (حد البيانات، السرعة، الوقت)',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLimitationsList(),

                  const SizedBox(height: 20),

                  // === الأزرار ===
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                          _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Icon(isEdit ? Icons.save : Icons.add),
                          label: Text(_saving
                              ? 'جاري الحفظ...'
                              : (isEdit ? 'حفظ التعديلات' : 'إضافة')),
                          style: FilledButton.styleFrom(
                            backgroundColor: _AppColors.profiles,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLimitationsList() {
    if (_loadingLimitations) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    if (_allLimitations.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.orange.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: Colors.orange.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.orange, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'لا توجد Limitations — أضف واحدة أولاً من تاب Limitations',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: _allLimitations.map((lim) {
          final name = lim['name'] ?? '-';
          final transferLimit = lim['transfer-limit'] ?? '';
          final uptimeLimit = lim['uptime-limit'] ?? '';
          final isSelected = _selectedLimitations.contains(name);

          // بناء وصف مختصر
          final parts = <String>[];
          if (transferLimit.isNotEmpty) {
            parts.add('بيانات: $transferLimit');
          }
          if (uptimeLimit.isNotEmpty) {
            parts.add('مدة: $uptimeLimit');
          }
          final subtitle = parts.join(' • ');

          return CheckboxListTile(
            value: isSelected,
            onChanged: (v) {
              setState(() {
                if (v == true) {
                  _selectedLimitations.add(name);
                } else {
                  _selectedLimitations.remove(name);
                }
              });
            },
            title: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            subtitle: subtitle.isEmpty
                ? null
                : Text(
              subtitle,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
            secondary: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? _AppColors.limitations.withValues(alpha: 0.15)
                    : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.tune,
                size: 18,
                color: isSelected
                    ? _AppColors.limitations
                    : Colors.grey.shade500,
              ),
            ),
            activeColor: _AppColors.limitations,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            dense: true,
          );
        }).toList(),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}


// =============================================================================
// 🎚️ Limitations Tab
// =============================================================================

class _LimitationsTab extends StatefulWidget {
  final MikroTikApi api;
  const _LimitationsTab({required this.api});

  @override
  State<_LimitationsTab> createState() => _LimitationsTabState();
}

class _LimitationsTabState extends State<_LimitationsTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, String>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

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
      final items = await widget.api.getUserManagerLimitations();
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

  Future<void> _openAdd() async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LimitationDialog(api: widget.api),
    );
    if (result == true) {
      _showMessage('تم إضافة Limitation ✅');
      await _load();
    }
  }

  Future<void> _openEdit(Map<String, String> item) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _LimitationDialog(api: widget.api, existing: item),
    );
    if (result == true) {
      _showMessage('تم تحديث Limitation ✅');
      await _load();
    }
  }

  Future<void> _delete(Map<String, String> item) async {
    final id = item['.id'];
    final name = item['name'] ?? '';
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('حذف Limitation'),
          ],
        ),
        content: Text('هل تريد حذف "$name"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.api.deleteUserManagerLimitation(id);
      if (!mounted) return;
      _showMessage('تم الحذف ✅');
      await _load();
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
          backgroundColor: isError ? Colors.red : _AppColors.accent,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) return const _LoadingState(color: _AppColors.limitations);
    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _load);
    }

    return Stack(
      children: [
        if (_items.isEmpty)
          const _EmptyState(
            icon: Icons.tune,
            title: 'لا توجد Limitations',
            subtitle: 'أضف Limitation جديد',
            color: _AppColors.limitations,
          )
        else
          RefreshIndicator(
            color: _AppColors.limitations,
            onRefresh: _load,
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                final name = item['name'] ?? '-';
                final transferLimit = item['transfer-limit'] ?? '-';
                final uptimeLimit = item['uptime-limit'] ?? '-';
                final rx = item['rate-limit-rx'] ?? '';
                final tx = item['rate-limit-tx'] ?? '';

                return _ModernCard(
                  accentColor: _AppColors.limitations,
                  child: Row(
                    children: [
                      _IconBadge(
                        icon: Icons.tune,
                        color: _AppColors.limitations,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              name,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                if (transferLimit != '-')
                                  _ChipLabel(
                                    text: 'البيانات: $transferLimit',
                                    color: _AppColors.limitations,
                                    icon: Icons.download,
                                  ),
                                if (uptimeLimit != '-')
                                  _ChipLabel(
                                    text: 'المدة: $uptimeLimit',
                                    color: _AppColors.primary,
                                    icon: Icons.timer,
                                  ),
                                if (rx.isNotEmpty)
                                  _ChipLabel(
                                    text: '↓ $rx',
                                    color: _AppColors.accent,
                                    icon: Icons.arrow_downward,
                                  ),
                                if (tx.isNotEmpty)
                                  _ChipLabel(
                                    text: '↑ $tx',
                                    color: _AppColors.cards,
                                    icon: Icons.arrow_upward,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            onPressed: () => _openEdit(item),
                            icon: const Icon(Icons.edit_outlined,
                                color: _AppColors.primary),
                            tooltip: 'تعديل',
                          ),
                          IconButton(
                            onPressed: () => _delete(item),
                            icon: const Icon(Icons.delete_outline,
                                color: Colors.red),
                            tooltip: 'حذف',
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton.extended(
            heroTag: 'add_limitation',
            onPressed: _openAdd,
            backgroundColor: _AppColors.limitations,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'إضافة Limitation',
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
// 🎚️ Limitation Dialog (Add / Edit)
// =============================================================================

class _LimitationDialog extends StatefulWidget {
  final MikroTikApi api;
  final Map<String, String>? existing;

  const _LimitationDialog({required this.api, this.existing});

  @override
  State<_LimitationDialog> createState() => _LimitationDialogState();
}

class _LimitationDialogState extends State<_LimitationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _transferCtrl;
  late final TextEditingController _uptimeCtrl;
  late final TextEditingController _rxCtrl;
  late final TextEditingController _txCtrl;

  bool _saving = false;

  bool get isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final l = widget.existing;
    _nameCtrl = TextEditingController(text: l?['name'] ?? '');
    _transferCtrl =
        TextEditingController(text: l?['transfer-limit'] ?? '');
    _uptimeCtrl = TextEditingController(text: l?['uptime-limit'] ?? '');
    _rxCtrl = TextEditingController(text: l?['rate-limit-rx'] ?? '');
    _txCtrl = TextEditingController(text: l?['rate-limit-tx'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _transferCtrl.dispose();
    _uptimeCtrl.dispose();
    _rxCtrl.dispose();
    _txCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);

    try {
      if (isEdit) {
        await widget.api.updateUserManagerLimitation(
          id: widget.existing!['.id']!,
          name: _nameCtrl.text.trim(),
          transferLimit: _transferCtrl.text.trim(),
          uptimeLimit: _uptimeCtrl.text.trim(),
          rateLimitRx: _rxCtrl.text.trim(),
          rateLimitTx: _txCtrl.text.trim(),
        );
      } else {
        await widget.api.addUserManagerLimitation(
          name: _nameCtrl.text.trim(),
          transferLimit: _transferCtrl.text.trim().isEmpty
              ? null
              : _transferCtrl.text.trim(),
          uptimeLimit: _uptimeCtrl.text.trim().isEmpty
              ? null
              : _uptimeCtrl.text.trim(),
          rateLimitRx: _rxCtrl.text.trim().isEmpty
              ? null
              : _rxCtrl.text.trim(),
          rateLimitTx: _txCtrl.text.trim().isEmpty
              ? null
              : _txCtrl.text.trim(),
        );
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل الحفظ: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [
                              _AppColors.limitations,
                              Color(0xFFFF7A7A)
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          isEdit ? Icons.edit : Icons.tune,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          isEdit ? 'تعديل Limitation' : 'إضافة Limitation',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed:
                        _saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _field(
                    controller: _nameCtrl,
                    label: 'الاسم',
                    icon: Icons.label_outline,
                    validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _transferCtrl,
                    label: 'حد البيانات (مثال: 1073741824)',
                    icon: Icons.download,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _uptimeCtrl,
                    label: 'حد المدة (مثال: 30d, 4h)',
                    icon: Icons.timer,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _rxCtrl,
                    label: 'Rate Limit RX (مثال: 2M)',
                    icon: Icons.arrow_downward,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    controller: _txCtrl,
                    label: 'Rate Limit TX (مثال: 2M)',
                    icon: Icons.arrow_upward,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                          _saving ? null : () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('إلغاء'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                              : Icon(isEdit ? Icons.save : Icons.add),
                          label: Text(_saving
                              ? 'جاري الحفظ...'
                              : (isEdit ? 'حفظ التعديلات' : 'إضافة')),
                          style: FilledButton.styleFrom(
                            backgroundColor: _AppColors.limitations,
                            padding:
                            const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// =============================================================================
// 📶 Sessions Tab — تصميم جديد
// =============================================================================

class _SessionsTab extends StatefulWidget {
  final MikroTikApi api;
  const _SessionsTab({required this.api});

  @override
  State<_SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends State<_SessionsTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, String>> _sessions = [];
  List<Map<String, String>> _users = [];
  List<Map<String, String>> _profiles = [];
  List<Map<String, String>> _limitations = [];

  bool _loading = true;
  String? _error;
  DateTime _lastUpdate = DateTime.now();

  // 🔍 بحث
  String _searchQuery = '';

  // 📂 البطاقات المفتوحة
  final Set<String> _expandedIds = {};

  @override
  bool get wantKeepAlive => true;

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
      final results = await Future.wait([
        widget.api.getUserManagerSessions(),
        widget.api.getUserManagerUsers(),
        widget.api.getUserManagerProfiles(),
        widget.api.getUserManagerLimitations(),
      ]);

      // 🔍 DEBUG: اطبع أول جلسة لمعرفة أسماء الحقول الفعلية
      final sessions = results[0];
      debugPrint('🔍 عدد الجلسات: ${sessions.length}');
      if (sessions.isNotEmpty) {
        debugPrint('🔍 أول جلسة كاملة: ${sessions.first}');
        debugPrint('🔍 مفاتيح أول جلسة: ${sessions.first.keys.toList()}');
      } else {
        debugPrint('🔍 لا توجد جلسات');
      }

      if (!mounted) return;
      setState(() {
        _sessions = results[0];
        _users = results[1];
        _profiles = results[2];
        _limitations = results[3];
        _loading = false;
        _lastUpdate = DateTime.now();
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString();
      });
    }
  }

  // 🔍 فلترة
  List<Map<String, String>> get _filteredSessions {
    var list = List<Map<String, String>>.from(_sessions);

    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((s) {
        final user = (s['user'] ?? '').toLowerCase();
        final ip = (s['user-address'] ?? '').toLowerCase();
        return user.contains(q) || ip.contains(q);
      }).toList();
    }

    return list;
  }

  // 🔗 البحث عن المستخدم المرتبط
  Map<String, String>? _findUser(String userName) {
    try {
      return _users.firstWhere(
            (u) => (u['name'] ?? '').toLowerCase() ==
            userName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // 🔗 البحث عن البروفايل المرتبط
  Map<String, String>? _findProfile(String? profileName) {
    if (profileName == null || profileName.isEmpty) return null;
    try {
      return _profiles.firstWhere(
            (p) => (p['name'] ?? '').toLowerCase() ==
            profileName.toLowerCase(),
      );
    } catch (_) {
      return null;
    }
  }

  // 📊 حساب الإحصائيات الإجمالية
  ({int count, double downloadMB, double uploadMB}) get _totals {
    double down = 0;
    double up = 0;
    for (final s in _sessions) {
      down += _parseBytes(s['download']);
      up += _parseBytes(s['upload']);
    }
    return (
    count: _sessions.length,
    downloadMB: down / (1024 * 1024),
    uploadMB: up / (1024 * 1024),
    );
  }

  double _parseBytes(String? value) {
    if (value == null || value.isEmpty) return 0;
    return double.tryParse(value) ?? 0;
  }

  // ⏱️ تحويل الوقت (مثال: "1h30m" → دقائق)
  int _parseUptimeToMinutes(String? uptime) {
    if (uptime == null || uptime.isEmpty) return 0;
    int minutes = 0;
    final weekMatch = RegExp(r'(\d+)w').firstMatch(uptime);
    if (weekMatch != null) minutes += int.parse(weekMatch.group(1)!) * 7 * 24 * 60;
    final dayMatch = RegExp(r'(\d+)d').firstMatch(uptime);
    if (dayMatch != null) minutes += int.parse(dayMatch.group(1)!) * 24 * 60;
    final hourMatch = RegExp(r'(\d+)h').firstMatch(uptime);
    if (hourMatch != null) minutes += int.parse(hourMatch.group(1)!) * 60;
    final minMatch = RegExp(r'(\d+)m').firstMatch(uptime);
    if (minMatch != null) minutes += int.parse(minMatch.group(1)!);
    final secMatch = RegExp(r'(\d+)s').firstMatch(uptime);
    if (secMatch != null && minutes == 0) {
      minutes += (int.parse(secMatch.group(1)!) / 60).round();
    }
    return minutes;
  }

  // ⏱️ تنسيق الدقائق → "1h 30m"
  String _formatMinutes(int minutes) {
    if (minutes <= 0) return '-';
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (m == 0) return '${h}h';
    return '${h}h ${m}m';
  }

  // 📊 تنسيق الحجم
  String _formatBytes(double bytes) {
    if (bytes < 1024) return '${bytes.toStringAsFixed(0)} B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  Future<void> _disconnect(Map<String, String> session) async {
    final id = session['.id'];
    final user = session['user'] ?? '';
    if (id == null || id.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.wifi_off, color: Colors.red),
            SizedBox(width: 8),
            Text('قطع الاتصال'),
          ],
        ),
        content: Text('هل تريد قطع اتصال "$user"؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('قطع'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await widget.api.disconnectUserManagerSession(id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم قطع اتصال "$user" ✅'),
          backgroundColor: _AppColors.sessions,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) return const _LoadingState(color: _AppColors.sessions);
    if (_error != null) {
      return _ErrorState(error: _error!, onRetry: _load);
    }

    final filtered = _filteredSessions;

    return RefreshIndicator(
      color: _AppColors.sessions,
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 30),
        children: [
          // 🔝 البطاقة الخضراء العلوية
          _buildTopStats(),

          const SizedBox(height: 14),

          // 🔍 بحث
          TextField(
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'ابحث بالاسم أو IP...',
              hintStyle: TextStyle(
                  color: Colors.grey.shade400, fontSize: 13),
              prefixIcon: const Icon(Icons.search,
                  color: _AppColors.sessions, size: 20),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                    color: _AppColors.sessions.withValues(alpha: 0.5),
                    width: 1.5),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // 📋 قائمة المتصلين
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.wifi_off,
                      size: 48, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    _sessions.isEmpty
                        ? 'لا يوجد متصلون'
                        : 'لا توجد نتائج',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            )
          else
            ...filtered.map((s) => _buildSessionCard(s)),
        ],
      ),
    );
  }

  // ===========================================================================
  // 🔝 البطاقة الخضراء العلوية
  // ===========================================================================

  Widget _buildTopStats() {
    final totals = _totals;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // العنوان + أيقونة
          Row(
            children: [
              const Expanded(
                child: Text(
                  'المتصلون الآن',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.wifi,
                    color: Colors.white, size: 22),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // العدد الكبير
          Text(
            '${totals.count}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 42,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 14),

          // صندوق الرفع/التنزيل
          Container(
            padding:
            const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _trafficStat(
                    icon: Icons.arrow_upward,
                    label: 'رفع',
                    value: _formatBytes(totals.uploadMB * 1024 * 1024),
                  ),
                ),
                Container(
                  width: 1,
                  height: 35,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _trafficStat(
                    icon: Icons.arrow_downward,
                    label: 'تنزيل',
                    value: _formatBytes(totals.downloadMB * 1024 * 1024),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _trafficStat({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // 🎴 بطاقة المتصل
  // ===========================================================================

  Widget _buildSessionCard(Map<String, String> session) {
    final id = session['.id'] ?? '';
    final userName = session['user'] ?? '-';
    final ip = session['user-address'] ?? '-';
    final uptime = session['uptime'] ?? '-';
    final download = session['download'] ?? '0';
    final upload = session['upload'] ?? '0';
    final isExpanded = _expandedIds.contains(id);

    // 🔗 ربط مع المستخدم
    final user = _findUser(userName);
    final profileName = user?['profile'];
    final profile = _findProfile(profileName);

    // 📊 حساب المتبقي
    String remainingData = '-';
    double progressData = 0;

    // 📊 حساب الزمن المتبقي
    String remainingTime = '-';

    // إجمالي البيانات المنقضية
    final totalDown = _parseBytes(download);
    final totalUp = _parseBytes(upload);
    final totalBytes = totalDown + totalUp;

    // المدة الكلية من البروفايل (validity)
    if (profile != null) {
      final validity = profile['validity'] ?? '';
      final totalMinutes = _parseUptimeToMinutes(validity);
      final usedMinutes = _parseUptimeToMinutes(uptime);
      if (totalMinutes > 0) {
        final remaining = totalMinutes - usedMinutes;
        remainingTime = _formatMinutes(remaining);

        // نسبة الاستهلاك الزمني
        progressData = (usedMinutes / totalMinutes).clamp(0.0, 1.0);
      }
    }

    // إذا كان هناك Limitation بحد بيانات
    if (user != null) {
      final limitationName = user['limitation'] ?? '';
      if (limitationName.isNotEmpty) {
        try {
          final limitation = _limitations.firstWhere(
                (l) => (l['name'] ?? '').toLowerCase() ==
                limitationName.toLowerCase(),
          );
          final limitBytes =
          _parseBytes(limitation['transfer-limit']);
          if (limitBytes > 0) {
            final remaining = limitBytes - totalBytes;
            remainingData = _formatBytes(
                remaining > 0 ? remaining : 0);
            progressData = (totalBytes / limitBytes).clamp(0.0, 1.0);
          }
        } catch (_) {}
      }
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _toggleExpand(id),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                // === السطر الأساسي ===
                Row(
                  children: [
                    // الأيقونة الخضراء
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4CAF50),
                            Color(0xFF66BB6A)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50)
                                .withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.wifi,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),

                    // الاسم + السطر الفرعي
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'monospace',
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$uptime • $ip',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // سهم الفتح
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 250),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: Colors.grey.shade500,
                        size: 26,
                      ),
                    ),
                  ],
                ),

                // === الجزء المنبثق ===
                AnimatedCrossFade(
                  duration: const Duration(milliseconds: 250),
                  crossFadeState: isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: Column(
                    children: [
                      const SizedBox(height: 14),
                      Container(
                          height: 1, color: Colors.grey.shade200),
                      const SizedBox(height: 14),

                      // حبوب المعلومات
                      Row(
                        children: [
                          Expanded(
                            child: _infoChip(
                              icon: Icons.download,
                              label: 'تنزيل',
                              value: _formatBytes(totalDown),
                              color: const Color(0xFFBBDEFB),
                              iconColor: const Color(0xFF2196F3),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _infoChip(
                              icon: Icons.upload,
                              label: 'رفع',
                              value: _formatBytes(totalUp),
                              color: const Color(0xFFE1BEE7),
                              iconColor: const Color(0xFF9C27B0),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: _infoChip(
                              icon: Icons.timer,
                              label: 'المدة',
                              value: uptime,
                              color: const Color(0xFFC8E6C9),
                              iconColor: const Color(0xFF4CAF50),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // صندوق التقدم
                      if (remainingData != '-' || remainingTime != '-')
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              if (remainingData != '-') ...[
                                Row(
                                  children: [
                                    Icon(Icons.data_usage,
                                        size: 14,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      'البيانات المتبقية: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      remainingData,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              if (remainingTime != '-') ...[
                                Row(
                                  children: [
                                    Icon(Icons.hourglass_bottom,
                                        size: 14,
                                        color: Colors.grey.shade600),
                                    const SizedBox(width: 6),
                                    Text(
                                      'الزمن المتبقي: ',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                    Text(
                                      remainingTime,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                              ],
                              // شريط التقدم
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: LinearProgressIndicator(
                                  value: progressData,
                                  minHeight: 8,
                                  backgroundColor: Colors.grey.shade200,
                                  valueColor:
                                  const AlwaysStoppedAnimation<Color>(
                                      _AppColors.sessions),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 12),

                      // آخر تحديث
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.update,
                              size: 12, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'آخر تحديث: ${_formatTime(_lastUpdate)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // زر قطع الاتصال
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _disconnect(session),
                          icon: const Icon(Icons.link_off, size: 16),
                          label: const Text('قطع الاتصال'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: BorderSide(
                                color: Colors.red.withValues(alpha: 0.5)),
                            padding:
                            const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    return '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}:'
        '${dt.second.toString().padLeft(2, '0')}';
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: iconColor),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: iconColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// 🪄 Generate Cards Dialog
// =============================================================================

class _GenerateCardsDialog extends StatefulWidget {
  final MikroTikApi api;
  final List<Map<String, String>> profiles;

  const _GenerateCardsDialog({
    required this.api,
    required this.profiles,
  });

  @override
  State<_GenerateCardsDialog> createState() => _GenerateCardsDialogState();
}

class _GenerateCardsDialogState extends State<_GenerateCardsDialog> {
  final _formKey = GlobalKey<FormState>();

  final _prefixController = TextEditingController(text: '');
  final _startController = TextEditingController(text: '1');
  final _countController = TextEditingController(text: '10');
  final _lengthController = TextEditingController(text: '8');
  final _sharedController = TextEditingController(text: '1');

  String? _selectedProfile;
  String _generationMode = 'random';

  bool _generating = false;
  bool _cancelRequested = false;
  int _current = 0;
  int _total = 0;
  int _success = 0;
  int _failed = 0;
  final List<Map<String, String>> _generatedCards = [];

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

  final Random _random = Random();

  String _randomNumber(int length) {
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(_random.nextInt(10));
    }
    return buffer.toString();
  }
  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProfile == null || _selectedProfile!.isEmpty) {
      _showMessage('يجب اختيار Profile', isError: true);
      return;
    }

    final count = int.tryParse(_countController.text.trim()) ?? 0;
    if (count <= 0 || count > 1000) {
      _showMessage('العدد يجب أن يكون 1-1000', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد التوليد'),
        content: Text(
          'سيتم إنشاء $count كرت في User Manager.\n\n'
              '⏱️ الوقت المتوقع: ~${(count * 0.5).ceil()} ثانية\n\n'
              'هل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: _AppColors.cards,
            ),
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
      _generatedCards.clear(); // 🧹 تنظيف القائمة قبل البدء
    });

    final prefix = _prefixController.text.trim();
    final start = int.tryParse(_startController.text.trim()) ?? 1;
    final length = int.tryParse(_lengthController.text.trim()) ?? 8;
    final shared = int.tryParse(_sharedController.text.trim()) ?? 1;

    // 🚀 تحميل قائمة المستخدمين الحالية مرة واحدة فقط
    Set<String> existingNames = {};
    try {
      final all = await widget.api.getUserManagerUsers();
      existingNames = all
          .map((u) => (u['name'] ?? '').toLowerCase())
          .where((n) => n.isNotEmpty)
          .toSet();
    } catch (e) {
      debugPrint('⚠️ تعذّر تحميل المستخدمين الحاليين: $e');
    }

    for (int i = 0; i < count; i++) {
      if (_cancelRequested) break;
      if (!mounted) return;
      setState(() => _current = i + 1);

      String name;
      if (_generationMode == 'sequential') {
        final num = start + i;
        final numStr = num.toString().padLeft(length, '0');
        name = '$prefix$numStr';
      } else {
        name = _randomNumber(length);
      }

      int retry = 0;
      while (existingNames.contains(name.toLowerCase()) && retry < 5) {
        if (_generationMode == 'sequential') {
          name = '$name${DateTime.now().millisecondsSinceEpoch % 100}';
        } else {
          name = _randomNumber(length + 2);
        }
        retry++;
      }

      bool created = false;
      int nameAttempts = 0;

      while (!created && nameAttempts < 5) {
        try {
          debugPrint('📤 محاولة إضافة: $name (محاولة $nameAttempts)');
          final id = await widget.api.addUserManagerUser(
            name: name,
            password: '',
            profile: _selectedProfile!,
            sharedUsers: shared,
          );
          debugPrint('📥 نتيجة: $id');

          if (id != null && id.isNotEmpty) {
            existingNames.add(name.toLowerCase());

            // 🎯 احفظ بيانات الكرت للطباعة
            String profileValidity = '';
            try {
              final profileData = widget.profiles.firstWhere(
                    (p) => p['name'] == _selectedProfile,
              );
              profileValidity = profileData['validity'] ?? '';
            } catch (_) {}

            _generatedCards.add({
              'name': name,
              'password': name,
              'limit-uptime': profileValidity,
              'limit-gb': '',
            });

            if (mounted) setState(() => _success++);
            created = true;
          } else {
            break;
          }
        } catch (e) {
          final errStr = e.toString().toLowerCase();
          final isDuplicate = errStr.contains('already exists') ||
              errStr.contains('username already');

          debugPrint('🔴 خطأ في $name: $e');

          if (isDuplicate && nameAttempts < 4) {
            nameAttempts++;
            if (_generationMode == 'sequential') {
              name = '$prefix${start + i}${_randomNumber(3)}';
            } else {
              name = _randomNumber(length + 2);
            }
            debugPrint('🔁 اسم جديد: $name');
            continue;
          } else {
            if (mounted) setState(() => _failed++);
            break;
          }
        }
      }
    }

    if (!mounted) return;
    setState(() => _generating = false);

    final successCount = _success;
    final generatedCards =
    List<Map<String, String>>.from(_generatedCards);

    // أغلق Dialog التوليد أولاً
    Navigator.pop(context, successCount);

    // 🖨️ افتح صفحة الطباعة مباشرة إن نجح التوليد
    if (successCount > 0 && generatedCards.isNotEmpty) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrintCardsPage(
            cards: generatedCards,
            networkName: _selectedProfile ?? 'Hotspot',
          ),
        ),
      );
    }
  }



  void _cancel() => setState(() => _cancelRequested = true);

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
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: _generating ? _buildProgress() : _buildForm(),
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_AppColors.cards, Color(0xFF9F67FF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome,
                    color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'توليد كروت',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            children: [
              Expanded(
                child: _modeChip(
                  'تسلسلي',
                  'sequential',
                  Icons.format_list_numbered,
                  _AppColors.primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _modeChip(
                  'عشوائي',
                  'random',
                  Icons.shuffle,
                  _AppColors.cards,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (_generationMode == 'sequential') ...[
            TextFormField(
              controller: _prefixController,
              decoration: _inputDecoration(
                'البادئة',
                'user',
                Icons.text_fields,
              ),
              validator: (v) {
                if (_generationMode == 'sequential' &&
                    (v == null || v.trim().isEmpty)) {
                  return 'مطلوب';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _startController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'يبدأ من',
                      '1',
                      Icons.play_arrow,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    controller: _lengthController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      'عدد الخانات',
                      '4',
                      Icons.straighten,
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            TextFormField(
              controller: _lengthController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                'طول الرقم',
                '8',
                Icons.straighten,
              ),
              validator: (v) {
                if (_generationMode == 'random') {
                  final n = int.tryParse(v?.trim() ?? '');
                  if (n == null || n < 4 || n > 20) {
                    return 'يجب أن يكون بين 4 و 20';
                  }
                }
                return null;
              },
            ),
          ],
          const SizedBox(height: 12),
          TextFormField(
            controller: _countController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              'عدد الكروت',
              '10',
              Icons.numbers,
              helper: 'الحد الأقصى 1000',
            ),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              if (n == null || n < 1) return 'العدد 1 على الأقل';
              if (n > 1000) return 'الحد 1000';
              return null;
            },
          ),
          const SizedBox(height: 12),
          if (widget.profiles.isNotEmpty)
            DropdownButtonFormField<String>(
              initialValue: _selectedProfile,
              isExpanded: true,
              decoration: _inputDecoration(
                'Profile',
                null,
                Icons.category,
                helper: 'يحدد المدة وكيفية البدء',
              ),
              items: widget.profiles.map((p) {
                final name = p['name'] ?? '';
                final validity = p['validity'] ?? '';
                return DropdownMenuItem(
                  value: name,
                  child: Text(
                    '$name ($validity)',
                    style: const TextStyle(fontSize: 13),
                  ),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedProfile = v),
            )
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border:
                Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.red, size: 20),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'لا توجد Profiles — أنشئ واحداً أولاً',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sharedController,
            keyboardType: TextInputType.number,
            decoration: _inputDecoration(
              'عدد الأجهزة',
              '1',
              Icons.devices,
            ),
            validator: (v) {
              final n = int.tryParse(v?.trim() ?? '');
              if (n == null || n < 1) return 'رقم غير صالح';
              return null;
            },
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('إلغاء'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  onPressed: _generate,
                  icon: const Icon(Icons.auto_awesome, size: 18),
                  label: const Text('توليد'),
                  style: FilledButton.styleFrom(
                    backgroundColor: _AppColors.cards,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(
      String label,
      String? hint,
      IconData icon, {
        String? helper,
      }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      helperText: helper,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: Colors.grey.shade50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _AppColors.cards, width: 1.6),
      ),
      contentPadding:
      const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: isSelected
              ? LinearGradient(
            colors: [color, color.withValues(alpha: 0.7)],
          )
              : null,
          color: isSelected ? null : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
            BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgress() {
    final progress = _total > 0 ? _current / _total : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_AppColors.cards, Color(0xFF9F67FF)],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: _AppColors.cards.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child:
          const Icon(Icons.autorenew, size: 40, color: Colors.white),
        ),
        const SizedBox(height: 18),
        const Text(
          'جاري التوليد...',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 10,
            backgroundColor: Colors.grey.shade200,
            valueColor:
            const AlwaysStoppedAnimation<Color>(_AppColors.cards),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '$_current / $_total  (${(progress * 100).toStringAsFixed(0)}%)',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _progressStat(
                'نجح',
                _success,
                _AppColors.sessions,
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _progressStat(
                'فشل',
                _failed,
                _AppColors.limitations,
                Icons.cancel,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _cancel,
            icon: const Icon(Icons.cancel, color: Colors.red),
            label: const Text('إلغاء التوليد'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _progressStat(
      String label,
      int value,
      Color color,
      IconData icon,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(color: color, fontSize: 12),
          ),
          Text(
            '$value',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}