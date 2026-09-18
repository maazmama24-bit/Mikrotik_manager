import 'models/saved_card.dart';
import 'services/saved_cards_storage.dart';
import 'package:flutter/material.dart';
import 'mikrotik_api.dart';
import 'print_cards_page.dart';

// =============================================================================
// Add Hotspot User
// =============================================================================

class AddHotspotUserPage extends StatefulWidget {
  final MikroTikApi api;
  final String host;
  final String username;
  final String password;
  final int port;
  final String? defaultProfile;

  const AddHotspotUserPage({
    super.key,
    required this.api,
    required this.host,
    required this.username,
    required this.password,
    required this.port,
    this.defaultProfile,
  });

  @override
  State<AddHotspotUserPage> createState() => _AddHotspotUserPageState();
}

class _AddHotspotUserPageState extends State<AddHotspotUserPage> {
  late final MikroTikApi _api;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _passwordController;
  late final TextEditingController _commentController;
  late final TextEditingController _limitUptimeController;
  late final TextEditingController _limitGbController;

  List<Map<String, String>> _profiles = [];
  String? _selectedProfile;
  bool _loadingProfiles = true;
  bool _saving = false;

  final List<Map<String, String>> _durationPresets = const [
    {'label': '1 ساعة', 'value': '1h'},
    {'label': '1 يوم', 'value': '1d'},
    {'label': '1 أسبوع', 'value': '1w'},
    {'label': '1 شهر', 'value': '30d'},
    {'label': '3 أشهر', 'value': '90d'},
    {'label': 'مخصص', 'value': ''},
  ];

  final List<Map<String, String>> _bytesPresets = const [
    {'label': '500 MB', 'value': '524288000'},
    {'label': '1 GB', 'value': '1073741824'},
    {'label': '2 GB', 'value': '2147483648'},
    {'label': '5 GB', 'value': '5368709120'},
    {'label': '10 GB', 'value': '10737418240'},
    {'label': 'مخصص', 'value': ''},
  ];

  String? _selectedDurationPreset;
  String? _selectedBytesPreset;

  @override
  void initState() {
    super.initState();
    _api = widget.api;
    _nameController = TextEditingController();
    _passwordController = TextEditingController();
    _commentController = TextEditingController();
    _limitUptimeController = TextEditingController();
    _limitGbController = TextEditingController();
    _selectedProfile = widget.defaultProfile;
    _loadProfiles();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _commentController.dispose();
    _limitUptimeController.dispose();
    _limitGbController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;
    setState(() => _loadingProfiles = true);

    try {
      final profiles = await _api.getHotspotProfiles();
      if (!mounted) return;

      setState(() {
        _profiles = profiles;
        _loadingProfiles = false;
        if (_selectedProfile == null && profiles.isNotEmpty) {
          _selectedProfile = profiles.first['name'];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProfiles = false);
    }
  }

  String _generatePassword() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final seed = DateTime.now().millisecondsSinceEpoch;
    final buffer = StringBuffer();
    for (int i = 0; i < 8; i++) {
      buffer.write(chars[(seed + i * 7) % chars.length]);
    }
    return buffer.toString();
  }

  void _useRandomPassword() {
    setState(() => _passwordController.text = _generatePassword());
  }

  void _selectDurationPreset(String value) {
    setState(() {
      _selectedDurationPreset = value;
      if (value.isNotEmpty) {
        _limitUptimeController.text = value;
      } else {
        _limitUptimeController.clear();
      }
    });
  }

  void _selectBytesPreset(String value) {
    setState(() {
      _selectedBytesPreset = value;
      if (value.isNotEmpty) {
        _limitGbController.text = value;
      } else {
        _limitGbController.clear();
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedProfile == null || _selectedProfile!.isEmpty) {
      _showMessage('يجب اختيار بروفايل', isError: true);
      return;
    }

    final name = _nameController.text.trim();
    setState(() => _saving = true);

    try {
      final exists = await _api.hotspotUserExists(name);

      if (exists) {
        if (!mounted) return;
        setState(() => _saving = false);
        _showMessage('الاسم "$name" موجود مسبقاً. اختر اسماً آخر.',
            isError: true);
        return;
      }

      final id = await _api.addHotspotUser(
        name: name,
        password: _passwordController.text,
        profile: _selectedProfile!,
        limitUptime: _limitUptimeController.text.trim(),
        limitBytesTotal: _limitGbController.text.trim(),
        comment: _commentController.text.trim(),
      );

      if (!mounted) return;

      if (id == null || id.isEmpty) {
        setState(() => _saving = false);
        _showMessage('فشل إضافة الكرت', isError: true);
        return;
      }

      _showMessage('تم إضافة الكرت "$name" بنجاح ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('فشل إضافة الكرت: $e', isError: true);
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

  IconData _iconFromEmoji(String emoji) {
    switch (emoji) {
      case '📝':
        return Icons.edit_note;
      case '⏱️':
        return Icons.timer;
      case '📊':
        return Icons.data_usage;
      case '💬':
        return Icons.comment;
      default:
        return Icons.circle;
    }
  }

  Widget _sectionTitle(String icon, String title, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: (color ?? Colors.blue).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              _iconFromEmoji(icon),
              size: 18,
              color: color ?? Colors.blue,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required Widget child,
    Color? accent,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (accent ?? Colors.blue).withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: (accent ?? Colors.blue).withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    bool obscureText = false,
    int maxLines = 1,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    Widget? prefixIcon,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        maxLines: obscureText ? 1 : maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
          suffixIcon: suffixIcon,
          prefixIcon: prefixIcon,
        ),
        validator: validator,
      ),
    );
  }

  Widget _presetChips({
    required List<Map<String, String>> presets,
    required String? selected,
    required Function(String) onSelected,
    required Color color,
  }) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: presets.map((preset) {
        final value = preset['value'] ?? '';
        final label = preset['label'] ?? '';
        final isSelected = selected == value;

        return GestureDetector(
          onTap: () => onSelected(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? color.withValues(alpha: 0.15)
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight:
                isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey.shade700,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('➕ إضافة كرت جديد'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            // ============================================
            // المعلومات الأساسية
            // ============================================
            _sectionTitle('📝', 'المعلومات الأساسية'),

            _sectionCard(
              accent: Colors.blue,
              child: Column(
                children: [
                  _field(
                    label: 'اسم المستخدم *',
                    controller: _nameController,
                    hint: 'مثال: user001',
                    prefixIcon: const Icon(Icons.person_outline),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'أدخل اسم المستخدم';
                      }
                      if (value.trim().length < 3) {
                        return 'الاسم قصير جداً (3 أحرف على الأقل)';
                      }
                      return null;
                    },
                  ),

                  _field(
                    label: 'كلمة المرور *',
                    controller: _passwordController,
                    hint: 'اتركها فارغة إذا كانت مثل الاسم',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      tooltip: 'توليد كلمة مرور',
                      onPressed: _useRandomPassword,
                      icon: const Icon(Icons.casino, color: Colors.purple),
                    ),
                  ),

                  if (_loadingProfiles)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(),
                    )
                  else if (_profiles.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'لا توجد بروفايلات — أنشئ بروفايل أولاً',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedProfile,
                        decoration: InputDecoration(
                          labelText: 'البروفايل *',
                          prefixIcon:
                          const Icon(Icons.category_outlined),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _profiles.map((profile) {
                          final name = profile['name'] ?? '';
                          return DropdownMenuItem<String>(
                            value: name,
                            child: Text(name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedProfile = value);
                        },
                      ),
                    ),
                ],
              ),
            ),

            // ============================================
            // المدة
            // ============================================
            _sectionTitle('⏱️', 'المدة', color: Colors.green),

            _sectionCard(
              accent: Colors.green,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختر مدة سريعة:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _presetChips(
                    presets: _durationPresets,
                    selected: _selectedDurationPreset,
                    onSelected: _selectDurationPreset,
                    color: Colors.green,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    label: 'مدة مخصصة',
                    controller: _limitUptimeController,
                    hint: 'مثال: 30d، 12h، 1w',
                    prefixIcon: const Icon(Icons.edit, size: 18),
                  ),
                ],
              ),
            ),

            // ============================================
            // البيانات
            // ============================================
            _sectionTitle('📊', 'حد البيانات', color: Colors.orange),

            _sectionCard(
              accent: Colors.orange,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'اختر حجماً سريعاً:',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _presetChips(
                    presets: _bytesPresets,
                    selected: _selectedBytesPreset,
                    onSelected: _selectBytesPreset,
                    color: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                  _field(
                    label: 'بيانات مخصصة (بالبايت)',
                    controller: _limitGbController,
                    hint: 'مثال: 1073741824 = 1GB',
                    keyboardType: TextInputType.number,
                    prefixIcon: const Icon(Icons.storage, size: 18),
                  ),
                ],
              ),
            ),

            // ============================================
            // معلومات إضافية
            // ============================================
            _sectionTitle('💬', 'معلومات إضافية', color: Colors.purple),

            _sectionCard(
              accent: Colors.purple,
              child: _field(
                label: 'ملاحظة',
                controller: _commentController,
                hint: 'مثال: كرت للعميل أحمد',
                maxLines: 2,
                prefixIcon: const Icon(Icons.comment, size: 18),
              ),
            ),

            const SizedBox(height: 8),

            // ============================================
            // زر الحفظ
            // ============================================
            SizedBox(
              height: 56,
              child: FilledButton.icon(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _saving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Icon(Icons.save, size: 22),
                label: Text(
                  _saving ? 'جاري الحفظ...' : '💾 إضافة الكرت',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// =============================================================================
// Generate Cards
// =============================================================================

class GenerateCardsPage extends StatefulWidget {
  final MikroTikApi api;
  final String host;
  final String username;
  final String password;
  final int port;
  final String? defaultProfile;

  const GenerateCardsPage({
    super.key,
    required this.api,
    required this.host,
    required this.username,
    required this.password,
    required this.port,
    this.defaultProfile,
  });

  @override
  State<GenerateCardsPage> createState() => _GenerateCardsPageState();
}
class _GenerateCardsPageState extends State<GenerateCardsPage> {
  late final MikroTikApi _api;
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _prefixController;
  late final TextEditingController _startNumberController;
  late final TextEditingController _countController;
  late final TextEditingController _paddingController;
  late final TextEditingController _limitUptimeController;
  late final TextEditingController _limitGbController;
  late final TextEditingController _commentController;

  List<Map<String, String>> _profiles = [];
  String? _selectedProfile;
  bool _loadingProfiles = true;

  String _passwordMode = 'same';

  List<Map<String, String>> _preview = [];

  bool _generating = false;
  int _generatedCount = 0;
  int _failedCount = 0;
  int _currentIndex = 0;
  int _totalCount = 0;
  bool _cancelled = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api;
    _prefixController = TextEditingController(text: 'user');
    _startNumberController = TextEditingController(text: '1');
    _countController = TextEditingController(text: '10');
    _paddingController = TextEditingController(text: '4');
    _limitUptimeController = TextEditingController();
    _limitGbController = TextEditingController();
    _commentController = TextEditingController();
    _selectedProfile = widget.defaultProfile;
    _loadProfiles();
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _startNumberController.dispose();
    _countController.dispose();
    _paddingController.dispose();
    _limitUptimeController.dispose();
    _limitGbController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    if (!mounted) return;
    setState(() => _loadingProfiles = true);

    try {
      final profiles = await _api.getHotspotProfiles();
      if (!mounted) return;

      setState(() {
        _profiles = profiles;
        _loadingProfiles = false;
        if (_selectedProfile == null && profiles.isNotEmpty) {
          _selectedProfile = profiles.first['name'];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingProfiles = false);
    }
  }

  /// تحويل الجيجا إلى بايت.
  /// مثال: 2.5 → 2684354560
  String _gbToBytes(String gbText) {
    final gb = double.tryParse(gbText.trim());
    if (gb == null || gb <= 0) return '';
    final bytes = (gb * 1024 * 1024 * 1024).round();
    return bytes.toString();
  }


  List<Map<String, String>> _buildList() {
    final prefix = _prefixController.text.trim();
    final start = int.tryParse(_startNumberController.text.trim()) ?? 1;
    final count = int.tryParse(_countController.text.trim()) ?? 0;
    final padding = int.tryParse(_paddingController.text.trim()) ?? 4;

    if (prefix.isEmpty || count <= 0) return [];

    final limitBytes = _gbToBytes(_limitGbController.text);

    final list = <Map<String, String>>[];

    for (int i = 0; i < count; i++) {
      final number = start + i;
      final numberStr = number.toString().padLeft(padding, '0');
      final name = '$prefix$numberStr';

      String password;
      switch (_passwordMode) {
        case 'same':
          password = name;
          break;
        case 'random':
          password = _generateRandomPassword(name);
          break;
        case 'empty':
        default:
          password = '';
          break;
      }

      list.add({
        'name': name,
        'password': password,
        'profile': _selectedProfile ?? '',
        'limit-uptime': _limitUptimeController.text.trim(),
        'limit-bytes-total': limitBytes,
        'limit-gb': _limitGbController.text.trim(),
        'comment': _commentController.text.trim(),
      });
    }

    return list;
  }

  String _generateRandomPassword(String seed) {
    final hash = seed.codeUnits.fold<int>(
      0,
          (prev, curr) => (prev * 31 + curr) % 1000000,
    );
    return hash.toString().padLeft(6, '0');
  }

  void _doPreview() {
    if (!_formKey.currentState!.validate()) return;

    final list = _buildList();

    if (list.isEmpty) {
      _showMessage('لا يمكن توليد كروت. تحقق من البادئة والعدد.', isError: true);
      return;
    }

    setState(() => _preview = list);
  }

  Future<void> _generate() async {
    if (_generating) return;

    if (!_formKey.currentState!.validate()) return;

    if (_selectedProfile == null || _selectedProfile!.isEmpty) {
      _showMessage('يجب اختيار بروفايل', isError: true);
      return;
    }

    final list = _buildList();

    if (list.isEmpty) {
      _showMessage('لا يمكن توليد كروت. تحقق من البادئة والعدد.', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('تأكيد التوليد'),
          content: Text(
            'سيتم إضافة ${list.length} كرت إلى الراوتر.\n\n'
                'قد يستغرق الأمر عدة دقائق حسب العدد وسرعة الاتصال.\n\n'
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
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _generating = true;
      _cancelled = false;
      _generatedCount = 0;
      _failedCount = 0;
      _currentIndex = 0;
      _totalCount = list.length;
    });

    for (int i = 0; i < list.length; i++) {
      if (_cancelled) break;
      if (!mounted) return;

      setState(() => _currentIndex = i + 1);

      final card = list[i];

      try {
        await _api.addHotspotUser(
          name: card['name'] ?? '',
          password: card['password'] ?? '',
          profile: card['profile'] ?? '',
          limitUptime: card['limit-uptime']?.isEmpty == true
              ? null
              : card['limit-uptime'],
          limitBytesTotal: card['limit-bytes-total']?.isEmpty == true
              ? null
              : card['limit-bytes-total'],
          comment: card['comment']?.isEmpty == true
              ? null
              : card['comment'],
        );

        if (mounted) setState(() => _generatedCount++);
      } catch (e) {
        if (mounted) setState(() => _failedCount++);
      }
    }

    if (!mounted) return;

    setState(() => _generating = false);

    // حفظ المجموعة محلياً إذا نجح التوليد
    if (_generatedCount > 0) {
      await _saveGroup(list.take(_generatedCount).toList());
    }

    if (_cancelled) {
      _showMessage('تم الإلغاء. أُضيف $_generatedCount كرت بنجاح.');
    } else {
      _showMessage(
        'تم إضافة $_generatedCount كرت بنجاح'
            '${_failedCount > 0 ? ' ($_failedCount فشل)' : ''} ✅',
      );
    }
  }

  /// حفظ المجموعة محلياً.
  Future<void> _saveGroup(List<Map<String, String>> cards) async {
    if (cards.isEmpty) return;

    try {
      final storage = SavedCardsStorage();
      final now = DateTime.now();

      final id = 'grp_${now.millisecondsSinceEpoch}';

      final prefix = _prefixController.text.trim();
      final count = cards.length;

      final groupName = '$prefix — $count كرت';

      final savedCards = cards.map((c) {
        return SavedCard(
          name: c['name'] ?? '',
          password: c['password'] ?? '',
          profile: c['profile'] ?? '',
          limitUptime: c['limit-uptime'] ?? '',
          limitGb: c['limit-gb'] ?? '',
          limitBytesTotal: c['limit-bytes-total'] ?? '',
          comment: c['comment'] ?? '',
        );
      }).toList();

      final group = SavedGroup(
        id: id,
        name: groupName,
        createdAt: now.toIso8601String(),
        count: savedCards.length,
        profile: _selectedProfile ?? '',
        limitUptime: _limitUptimeController.text.trim(),
        limitGb: _limitGbController.text.trim(),
        cards: savedCards,
      );

      await storage.add(group);
    } catch (_) {
      // تجاهل أخطاء الحفظ - لا نريد إيقاف التوليد
    }
  }

  void _cancel() {
    setState(() => _cancelled = true);
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
  Widget _field({
    required String label,
    required TextEditingController controller,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool enabled = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📦 توليد كروت جماعية'),
        actions: [
          if (_generating)
            IconButton(
              onPressed: _cancel,
              tooltip: 'إلغاء',
              icon: const Icon(Icons.cancel, color: Colors.red),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              '🔤 إعدادات التسمية',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _field(
              label: 'البادئة (Prefix) *',
              controller: _prefixController,
              hint: 'مثال: user',
              enabled: !_generating,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'أدخل البادئة';
                }
                return null;
              },
            ),

            Row(
              children: [
                Expanded(
                  child: _field(
                    label: 'يبدأ من *',
                    controller: _startNumberController,
                    hint: '1',
                    keyboardType: TextInputType.number,
                    enabled: !_generating,
                    validator: (value) {
                      final n = int.tryParse(value?.trim() ?? '');
                      if (n == null || n < 0) return 'رقم غير صالح';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _field(
                    label: 'العدد *',
                    controller: _countController,
                    hint: '10',
                    keyboardType: TextInputType.number,
                    enabled: !_generating,
                    validator: (value) {
                      final n = int.tryParse(value?.trim() ?? '');
                      if (n == null || n < 1) return 'العدد يجب أن يكون 1 على الأقل';
                      if (n > 1000) return 'الحد الأقصى 1000';
                      return null;
                    },
                  ),
                ),
              ],
            ),

            _field(
              label: 'عدد خانات الرقم',
              controller: _paddingController,
              hint: '4 = user0001',
              keyboardType: TextInputType.number,
              enabled: !_generating,
              validator: (value) {
                final n = int.tryParse(value?.trim() ?? '');
                if (n == null || n < 1 || n > 10) return 'من 1 إلى 10';
                return null;
              },
            ),

            const SizedBox(height: 20),

            const Text(
              '📡 البروفايل',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _loadingProfiles
                ? const LinearProgressIndicator()
                : DropdownButtonFormField<String>(
              initialValue: _selectedProfile,
              decoration: const InputDecoration(
                labelText: 'البروفايل *',
                border: OutlineInputBorder(),
              ),
              items: _profiles.map((profile) {
                final name = profile['name'] ?? '';
                return DropdownMenuItem<String>(
                  value: name,
                  child: Text(name),
                );
              }).toList(),
              onChanged: _generating
                  ? null
                  : (value) {
                setState(() => _selectedProfile = value);
              },
            ),

            const SizedBox(height: 20),

            const Text(
              '🔑 كلمة المرور',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            RadioListTile<String>(
              title: const Text('نفس اسم المستخدم'),
              value: 'same',
              groupValue: _passwordMode,
              onChanged: _generating
                  ? null
                  : (value) {
                if (value != null) {
                  setState(() => _passwordMode = value);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('فارغة (اسم المستخدم تلقائياً)'),
              value: 'empty',
              groupValue: _passwordMode,
              onChanged: _generating
                  ? null
                  : (value) {
                if (value != null) {
                  setState(() => _passwordMode = value);
                }
              },
            ),
            RadioListTile<String>(
              title: const Text('عشوائية'),
              value: 'random',
              groupValue: _passwordMode,
              onChanged: _generating
                  ? null
                  : (value) {
                if (value != null) {
                  setState(() => _passwordMode = value);
                }
              },
            ),

            const SizedBox(height: 20),

            const Text(
              '⏱️ 📊 القيود',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            _field(
              label: 'المدة',
              controller: _limitUptimeController,
              hint: 'مثال: 30d',
              enabled: !_generating,
            ),

            _field(
              label: 'حد البيانات (بـ GB)',
              controller: _limitGbController,
              hint: 'مثال: 2 = 2 جيجا، 0.5 = 500 ميجا',
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              enabled: !_generating,
            ),

            _field(
              label: 'ملاحظة',
              controller: _commentController,
              hint: 'ملاحظة توضع على جميع الكروت',
              enabled: !_generating,
            ),

            const SizedBox(height: 20),

            if (!_generating)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _doPreview,
                          icon: const Icon(Icons.visibility),
                          label: const Text('معاينة'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _generate,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('توليد'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_preview.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PrintCardsPage(
                                cards: _preview,
                                networkName: 'MikroTik',
                              ),
                            ),
                          );
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.green,
                        ),
                        icon: const Icon(Icons.print),
                        label: const Text(
                          '🖨️ طباعة الكروت PDF',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),

            if (_generating) ...[
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'جاري التوليد...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: _totalCount > 0 ? _currentIndex / _totalCount : 0,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_currentIndex / $_totalCount',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Column(
                            children: [
                              const Text(
                                'نجح',
                                style: TextStyle(color: Colors.green, fontSize: 12),
                              ),
                              Text(
                                '$_generatedCount',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              const Text(
                                'فشل',
                                style: TextStyle(color: Colors.red, fontSize: 12),
                              ),
                              Text(
                                '$_failedCount',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (_preview.isNotEmpty && !_generating) ...[
              const SizedBox(height: 20),
              const Text(
                '👁️ معاينة الكروت',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'سيتم توليد ${_preview.length} كرت',
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 10),
              Card(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _preview.length > 20 ? 20 : _preview.length,
                  itemBuilder: (context, index) {
                    final card = _preview[index];
                    final password = card['password'] ?? '';
                    final uptime = card['limit-uptime'] ?? '';
                    final gb = card['limit-gb'] ?? '';

                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 14,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                      title: Text(
                        card['name'] ?? '',
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'كلمة المرور: ${password.isEmpty ? '(الاسم)' : password}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          if (uptime.isNotEmpty)
                            Text(
                              'المدة: $uptime',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.green,
                              ),
                            ),
                          if (gb.isNotEmpty)
                            Text(
                              'البيانات: $gb GB',
                              style: const TextStyle(
                                fontSize: 11,
                                color: Colors.blue,
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              if (_preview.length > 20)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    '... و ${_preview.length - 20} كرت إضافي',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
            ],

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}