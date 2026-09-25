import 'models/saved_card.dart';
import 'services/saved_cards_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'mikrotik_api.dart';
import 'print_cards_page.dart';
import 'dart:math';

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
  late final TextEditingController _customPasswordController;
  late final TextEditingController _limitUptimeController;
  late final TextEditingController _limitGbController;

  List<Map<String, String>> _profiles = [];
  String? _selectedProfile;
  bool _loadingProfiles = true;
  bool _saving = false;
  String _passwordMode = 'same';

  // 🎫 الصلاحية
  final TextEditingController _validityValueController =
  TextEditingController(text: '24');
  String _validityUnit = 'h';



  final List<Map<String, String>> _bytesPresets = const [
    {'label': '500 MB', 'value': '0.5'},
    {'label': '1 GB', 'value': '1'},
    {'label': '2 GB', 'value': '2'},
    {'label': '5 GB', 'value': '5'},
    {'label': '10 GB', 'value': '10'},
    {'label': 'مخصص', 'value': ''},
  ];

  String? _selectedBytesPreset;

  @override
  void initState() {
    super.initState();
    _api = widget.api;
    _nameController = TextEditingController();
    _passwordController = TextEditingController();
    _commentController = TextEditingController();
    _customPasswordController = TextEditingController();
    _limitUptimeController = TextEditingController();
    _limitGbController = TextEditingController();
    _selectedProfile = widget.defaultProfile;

    // 🎲 ولّد رقماً عشوائياً جاهزاً
    _nameController.text = _generateRandomNumber(8);

    _loadProfiles();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _passwordController.dispose();
    _commentController.dispose();
    _customPasswordController.dispose();
    _limitUptimeController.dispose();
    _limitGbController.dispose();
    _validityValueController.dispose();
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
  /// توليد رقم عشوائي (أرقام فقط).
  /// يستخدم Random + Time + Counter لضمان عدم التكرار.


  String _generateRandomNumber(int length) {
    final random = Random();
    final buffer = StringBuffer();

    // أضف counter للتأكد من عدم التكرار السريع

    for (int i = 0; i < length; i++) {
      buffer.write(random.nextInt(10));
    }

    return buffer.toString();
  }

  /// إعادة توليد اسم عشوائي.
  void _regenerateName() {
    setState(() {
      _nameController.text = _generateRandomNumber(8);
    });
  }

  void _useRandomPassword() {
    setState(() => _passwordController.text = _generatePassword());
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

      // حدد كلمة المرور حسب الوضع
      String finalPassword;
      switch (_passwordMode) {
        case 'empty':
          finalPassword = '';
          break;
        case 'same':
          finalPassword = name;
          break;
        case 'random':
          finalPassword = _generatePassword();
          break;
        case 'custom':
        default:
          finalPassword = _passwordController.text;
          break;
      }

      // تحويل GB إلى Bytes
      final gbText = _limitGbController.text.trim();
      String limitBytes = '';
      if (gbText.isNotEmpty) {
        final gb = double.tryParse(gbText);
        if (gb != null && gb > 0) {
          limitBytes = (gb * 1024 * 1024 * 1024).round().toString();
        }
      }

      // 🎫 بناء email من الصلاحية
      final validityValue =
          int.tryParse(_validityValueController.text.trim()) ?? 0;
      final validityEmail = validityValue > 0
          ? MikroTikApi.buildValidityEmail(
        value: validityValue,
        unit: _validityUnit,
      )
          : null;

      final id = await _api.addHotspotUser(
        name: name,
        password: finalPassword,
        profile: _selectedProfile!,
        limitUptime: _limitUptimeController.text.trim(),
        limitBytesTotal: limitBytes,
        comment: _commentController.text.trim(),
        email: validityEmail,
      );

      if (!mounted) return;

      if (id == null || id.isEmpty) {
        setState(() => _saving = false);
        _showMessage('فشل إضافة الكرت', isError: true);
        return;
      }

      // تحديد كلمة المرور النهائية (للإضافة في الوصف)
      final displayPassword = finalPassword;

      // إظهار Dialog النجاح
      if (!mounted) return;

      setState(() => _saving = false);

      await _showSuccessDialog(
        name: name,
        password: displayPassword,
        profile: _selectedProfile!,
        uptime: _limitUptimeController.text.trim(),
        gb: _limitGbController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _showMessage('فشل إضافة الكرت: $e', isError: true);
    }
  }
  /// عرض Dialog نجاح بعد إضافة الكرت.
  Future<void> _showSuccessDialog({
    required String name,
    required String password,
    required String profile,
    required String uptime,
    required String gb,
  }) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==========================================
                // الرأس مع التدرج الأخضر
                // ==========================================
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Color(0xFF2E7D32)],
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.25),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_circle,
                          color: Colors.white,
                          size: 40,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'تم إنشاء الكرت بنجاح',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'احتفظ بالبيانات التالية',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // ==========================================
                // التفاصيل
                // ==========================================
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _detailRow(
                        icon: Icons.person,
                        label: 'اسم المستخدم',
                        value: name,
                        color: Colors.blue,
                        copyable: true,
                      ),
                      const SizedBox(height: 10),
                      _detailRow(
                        icon: Icons.lock,
                        label: 'كلمة المرور',
                        value: password.isEmpty ? '(فارغة)' : password,
                        color: Colors.purple,
                        copyable: password.isNotEmpty,
                      ),
                      const SizedBox(height: 10),
                      _detailRow(
                        icon: Icons.category,
                        label: 'البروفايل',
                        value: profile,
                        color: Colors.teal,
                      ),
                      if (uptime.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _detailRow(
                          icon: Icons.timer,
                          label: 'المدة',
                          value: uptime,
                          color: Colors.green,
                        ),
                      ],
                      if (gb.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        _detailRow(
                          icon: Icons.data_usage,
                          label: 'البيانات',
                          value: '$gb GB',
                          color: Colors.orange,
                        ),
                      ],
                    ],
                  ),
                ),

                // ==========================================
                // الأزرار
                // ==========================================
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final text = 'اسم المستخدم: $name\n'
                                'كلمة المرور: ${password.isEmpty ? "(فارغة)" : password}\n'
                                'البروفايل: $profile'
                                '${uptime.isNotEmpty ? "\nالمدة: $uptime" : ""}'
                                '${gb.isNotEmpty ? "\nالبيانات: $gb GB" : ""}';

                            await Clipboard.setData(
                              ClipboardData(text: text),
                            );

                            if (!mounted) return;

                            ScaffoldMessenger.of(context)
                              ..hideCurrentSnackBar()
                              ..showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'تم نسخ التفاصيل 📋',
                                  ),
                                  duration: Duration(seconds: 2),
                                ),
                              );
                          },
                          icon: const Icon(Icons.copy, size: 18),
                          label: const Text('نسخ'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            Navigator.pop(dialogContext);
                            Navigator.pop(context, true);
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.green.shade600,
                          ),
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('تم'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  /// صف تفاصيل في Dialog النجاح.
  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool copyable = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (copyable)
            IconButton(
              iconSize: 18,
              tooltip: 'نسخ',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(
                    SnackBar(
                      content: Text('تم نسخ $label'),
                      duration: const Duration(seconds: 1),
                    ),
                  );
              },
              icon: Icon(Icons.copy, color: color, size: 18),
            ),
        ],
      ),
    );
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
      case '🎫':
        return Icons.card_giftcard;
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
  Widget _passwordModeChip({
    required String label,
    required String mode,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _passwordMode == mode;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _passwordMode = mode;
            if (mode != 'custom') {
              _passwordController.clear();
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            vertical: 10,
            horizontal: 4,
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
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? color : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : Colors.grey.shade700,
                ),
              ),
            ],
          ),
        ),
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
                    hint: 'مثال: 74185296',
                    prefixIcon: const Icon(Icons.person_outline),
                    suffixIcon: IconButton(
                      tooltip: 'توليد رقم جديد',
                      onPressed: _regenerateName,
                      icon: const Icon(
                        Icons.refresh,
                        color: Colors.blue,
                      ),
                    ),
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

                  // خيارات كلمة المرور
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text(
                      'كلمة المرور:',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      _passwordModeChip(
                        label: 'فارغة',
                        mode: 'empty',
                        icon: Icons.lock_open,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 6),
                      _passwordModeChip(
                        label: 'مثل الاسم',
                        mode: 'same',
                        icon: Icons.content_copy,
                        color: Colors.blue,
                      ),
                      const SizedBox(width: 6),
                      _passwordModeChip(
                        label: 'عشوائية',
                        mode: 'random',
                        icon: Icons.casino,
                        color: Colors.purple,
                      ),
                      const SizedBox(width: 6),
                      _passwordModeChip(
                        label: 'مخصصة',
                        mode: 'custom',
                        icon: Icons.edit,
                        color: Colors.orange,
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // حقل كلمة المرور المخصصة
                  if (_passwordMode == 'custom')
                    _field(
                      label: 'كلمة المرور',
                      controller: _passwordController,
                      hint: 'اكتب كلمة المرور',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: 'توليد',
                        onPressed: _useRandomPassword,
                        icon: const Icon(Icons.casino),
                      ),
                    )
                  else if (_passwordMode == 'same')
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.blue.shade200,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info, color: Colors.blue, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'كلمة المرور ستكون نفس اسم المستخدم',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (_passwordMode == 'random')
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.purple.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.purple.shade200,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info, color: Colors.purple, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'سيتم توليد كلمة مرور عشوائية لكل كرت',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.purple,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.grey.shade300,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info, color: Colors.grey, size: 18),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'الكرت سيكون بدون كلمة مرور',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                          ],
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
            // 🎫 الصلاحية (Script)
            // ============================================
            _sectionTitle('🎫', 'الصلاحية', color: Colors.deepPurple),

            _sectionCard(
              accent: Colors.deepPurple,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'تُحفظ في Email (تعمل مع Script Hotspot_Validity)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _field(
                          label: 'المدة',
                          controller: _validityValueController,
                          hint: '24',
                          keyboardType: TextInputType.number,
                          prefixIcon:
                          const Icon(Icons.timer, size: 18),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            initialValue: _validityUnit,
                            decoration: const InputDecoration(
                              labelText: 'الوحدة',
                              prefixIcon:
                              Icon(Icons.schedule, size: 18),
                              border: OutlineInputBorder(),
                              filled: true,
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'm', child: Text('دقائق')),
                              DropdownMenuItem(
                                  value: 'h', child: Text('ساعات')),
                              DropdownMenuItem(
                                  value: 'd', child: Text('أيام')),
                              DropdownMenuItem(
                                  value: 'w', child: Text('أسابيع')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                setState(() => _validityUnit = v);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ============================================
            // ⏱️ المدة (limit-uptime)
            // ============================================
            _sectionTitle('⏱️', 'حد المدة', color: Colors.green),

            _sectionCard(
              accent: Colors.green,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _field(
                    label: 'مدة مخصصة (اختياري)',
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
                    label: 'بيانات مخصصة (بـ GB)',
                    controller: _limitGbController,
                    hint: 'مثال: 2 = 2 جيجا، 0.5 = 500 ميجا',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
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
  late final TextEditingController _customPasswordController;
  late final TextEditingController _randomLengthController;
  final TextEditingController _validityValueController =
  TextEditingController(text: '24');

  String _validityUnit = 'h';

  List<Map<String, String>> _profiles = [];
  String? _selectedProfile;
  bool _loadingProfiles = true;

  String _passwordMode = 'same';
  String _generationMode = 'sequential';

  List<Map<String, String>> _preview = [];

  bool _generating = false;
  int _generatedCount = 0;
  int _failedCount = 0;
  int _currentIndex = 0;
  int _totalCount = 0;
  bool _cancelled = false;

  // ألوان أساسية ثابتة (تعمل مع الوضعين)
  static const Color _accent = Color(0xFF7C3AED);
  static const Color _accentDark = Color(0xFF5B21B6);

  // ============================================================
  // Helpers — تُقرأ من الثيم
  // ============================================================
  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  Color _bgColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF0F0F1E) : const Color(0xFFF5F5F7);

  Color _cardColor(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1A1A2E) : Colors.white;

  Color _textColor(BuildContext context) =>
      _isDark(context) ? Colors.white : const Color(0xFF1A1A2E);

  Color _subTextColor(BuildContext context) =>
      _isDark(context) ? Colors.white54 : Colors.black54;

  Color _borderColor(BuildContext context) =>
      _isDark(context) ? Colors.white12 : Colors.black12;

  Color _fieldFillColor(BuildContext context) =>
      _isDark(context) ? Colors.black.withValues(alpha: 0.25) : Colors.grey.shade50;

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
    _customPasswordController = TextEditingController();
    _randomLengthController = TextEditingController(text: '6');
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
    _customPasswordController.dispose();
    _randomLengthController.dispose();
    _validityValueController.dispose();
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

  String _gbToBytes(String gbText) {
    final gb = double.tryParse(gbText.trim());
    if (gb == null || gb <= 0) return '';
    return (gb * 1024 * 1024 * 1024).round().toString();
  }

  String _generateRandomNumber(int length) {
    final random = Random();
    final buffer = StringBuffer();
    for (int i = 0; i < length; i++) {
      buffer.write(random.nextInt(10));
    }
    return buffer.toString();
  }

  String _generateRandomPassword(String seed) {
    final hash = seed.codeUnits.fold<int>(
      0,
          (prev, curr) => (prev * 31 + curr) % 1000000,
    );
    return hash.toString().padLeft(6, '0');
  }

  List<Map<String, String>> _buildList() {
    final count = int.tryParse(_countController.text.trim()) ?? 0;
    if (count <= 0) return [];

    final limitBytes = _gbToBytes(_limitGbController.text);
    final list = <Map<String, String>>[];

    final validityValue =
        int.tryParse(_validityValueController.text.trim()) ?? 0;
    final validityEmail = validityValue > 0
        ? MikroTikApi.buildValidityEmail(
      value: validityValue,
      unit: _validityUnit,
    )
        : '';

    String passwordFor(String name) {
      switch (_passwordMode) {
        case 'same':
          return name;
        case 'random':
          return _generateRandomPassword(name);
        case 'custom':
          return _customPasswordController.text.trim();
        case 'empty':
        default:
          return '';
      }
    }

    if (_generationMode == 'sequential') {
      final prefix = _prefixController.text.trim();
      final start = int.tryParse(_startNumberController.text.trim()) ?? 1;
      final padding = int.tryParse(_paddingController.text.trim()) ?? 4;
      if (prefix.isEmpty) return [];

      for (int i = 0; i < count; i++) {
        final numberStr = (start + i).toString().padLeft(padding, '0');
        final name = '$prefix$numberStr';
        list.add({
          'name': name,
          'password': passwordFor(name),
          'profile': _selectedProfile ?? '',
          'limit-uptime': _limitUptimeController.text.trim(),
          'limit-bytes-total': limitBytes,
          'limit-gb': _limitGbController.text.trim(),
          'comment': _commentController.text.trim(),
          'email': validityEmail,
        });
      }
    } else {
      final length = int.tryParse(_randomLengthController.text.trim()) ?? 6;
      if (length < 4 || length > 20) return [];
      final usedNames = <String>{};
      for (int i = 0; i < count; i++) {
        String name;
        int attempts = 0;
        do {
          name = _generateRandomNumber(length);
          attempts++;
        } while (usedNames.contains(name) && attempts < 100);
        usedNames.add(name);
        list.add({
          'name': name,
          'password': passwordFor(name),
          'profile': _selectedProfile ?? '',
          'limit-uptime': _limitUptimeController.text.trim(),
          'limit-bytes-total': limitBytes,
          'limit-gb': _limitGbController.text.trim(),
          'comment': _commentController.text.trim(),
          'email': validityEmail,
        });
      }
    }
    return list;
  }

  void _doPreview() {
    if (!_formKey.currentState!.validate()) return;
    final list = _buildList();
    if (list.isEmpty) {
      _showMessage('لا يمكن توليد كروت. تحقق من البادئة والعدد.',
          isError: true);
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
      _showMessage('لا يمكن توليد كروت. تحقق من الإعدادات.', isError: true);
      return;
    }

    final estimatedMinutes = (list.length * 0.05).ceil();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد التوليد'),
        content: Text(
          'سيتم إضافة ${list.length} كرت إلى الراوتر.\n\n'
              '⏱️ الوقت المتوقع: ~$estimatedMinutes ثانية\n'
              '(باستخدام 10 طلبات متوازية)\n\n'
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
      ),
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

    const int batchSize = 10;
    final createdCards = <Map<String, String>>[];

    for (int i = 0; i < list.length; i += batchSize) {
      if (_cancelled) break;
      if (!mounted) return;
      final end = (i + batchSize > list.length) ? list.length : i + batchSize;
      final batch = list.sublist(i, end);

      final results = await Future.wait(
        batch.map((card) async {
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
              email: card['email']?.isEmpty == true ? null : card['email'],
            );
            return {'success': 'true', 'card': card};
          } catch (e) {
            return {'success': 'false', 'card': card};
          }
        }),
      );

      for (final result in results) {
        if (result['success'] == 'true') {
          _generatedCount++;
          createdCards.add(result['card']! as Map<String, String>);
        } else {
          _failedCount++;
        }
      }
      if (!mounted) return;
      setState(() => _currentIndex = end);
    }

    if (!mounted) return;
    setState(() => _generating = false);
    if (createdCards.isNotEmpty) await _saveGroup(createdCards);

    if (_cancelled) {
      _showMessage('تم الإلغاء. أُضيف $_generatedCount كرت بنجاح.');
    } else {
      _showMessage(
        'تم إضافة $_generatedCount كرت بنجاح'
            '${_failedCount > 0 ? ' ($_failedCount فشل)' : ''} ✅',
      );
    }
  }

  Future<void> _saveGroup(List<Map<String, String>> cards) async {
    if (cards.isEmpty) return;
    try {
      final storage = SavedCardsStorage();
      final now = DateTime.now();
      final id = 'grp_${now.millisecondsSinceEpoch}';
      final prefix = _prefixController.text.trim();
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
        name: '$prefix — ${savedCards.length} كرت',
        createdAt: now.toIso8601String(),
        count: savedCards.length,
        profile: _selectedProfile ?? '',
        limitUptime: _limitUptimeController.text.trim(),
        limitGb: _limitGbController.text.trim(),
        cards: savedCards,
      );
      await storage.add(group);
    } catch (_) {}
  }

  void _cancel() => setState(() => _cancelled = true);

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

  // ============================================================
  // Widgets — تصميم عصري
  // ============================================================

  Widget _gradientHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_accent, _accentDark],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.auto_awesome,
                color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'توليد كروت جماعية',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'أنشئ مجموعة كروت بضغطة واحدة',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(BuildContext context,
      {required Widget child, Color? accent}) {
    final c = accent ?? _accent;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardColor(context),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: c.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: c.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionTitle(BuildContext context, IconData icon, String title,
      {Color? color}) {
    final c = color ?? _accent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4, right: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: c.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: c),
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: _textColor(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkField(
      BuildContext context, {
        required String label,
        required TextEditingController controller,
        String? hint,
        TextInputType? keyboardType,
        String? Function(String?)? validator,
        bool enabled = true,
        Widget? prefixIcon,
        Widget? suffixIcon,
      }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        enabled: enabled,
        keyboardType: keyboardType,
        style: TextStyle(color: _textColor(context), fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: _subTextColor(context), fontSize: 13),
          hintStyle: TextStyle(color: _subTextColor(context), fontSize: 13),
          filled: true,
          fillColor: _fieldFillColor(context),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor(context)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor(context)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _accent, width: 1.5),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _borderColor(context)),
          ),
        ),
        validator: validator,
      ),
    );
  }

  Widget _infoBox(BuildContext context, {
    required IconData icon,
    required Color color,
    required String text,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 12, color: color),
            ),
          ),
        ],
      ),
    );
  }

  Widget _generationModeChip(BuildContext context, {
    required String label,
    required String mode,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _generationMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: _generating
            ? null
            : () => setState(() => _generationMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : _fieldFillColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : _borderColor(context),
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? color : _subTextColor(context),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : _textColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _passwordModeChip(BuildContext context, {
    required String label,
    required String mode,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _passwordMode == mode;
    return Expanded(
      child: GestureDetector(
        onTap: _generating
            ? null
            : () => setState(() => _passwordMode = mode),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.15)
                : _fieldFillColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : _borderColor(context),
              width: 1.5,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected ? color : _subTextColor(context),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? color : _textColor(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _previewCardItem(BuildContext context, Map<String, String> card, int index) {
    final password = card['password'] ?? '';
    final uptime = card['limit-uptime'] ?? '';
    final gb = card['limit-gb'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _fieldFillColor(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_accent, _accentDark],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card['name'] ?? '',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: _textColor(context),
                  ),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (password.isNotEmpty)
                      _miniChip(Icons.key, password, const Color(0xFF8B5CF6)),
                    if (uptime.isNotEmpty)
                      _miniChip(Icons.timer, uptime, const Color(0xFF10B981)),
                    if (gb.isNotEmpty)
                      _miniChip(
                          Icons.data_usage, '$gb GB', const Color(0xFF06B6D4)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bg = _bgColor(context);
    final textColor = _textColor(context);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: const Text('📦 توليد كروت جماعية'),
        centerTitle: true,
        backgroundColor: bg,
        foregroundColor: textColor,
        elevation: 0,
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
            _gradientHeader(context),
            const SizedBox(height: 20),

            // ============================================
            // نمط التوليد
            // ============================================
            _sectionTitle(context, Icons.text_fields, 'نمط التوليد'),
            _sectionCard(
              context,
              accent: _accent,
              child: Column(
                children: [
                  Row(
                    children: [
                      _generationModeChip(
                        context,
                        label: 'تسلسلي',
                        mode: 'sequential',
                        icon: Icons.format_list_numbered,
                        color: const Color(0xFF8B5CF6),
                      ),
                      const SizedBox(width: 8),
                      _generationModeChip(
                        context,
                        label: 'عشوائي',
                        mode: 'random',
                        icon: Icons.shuffle,
                        color: const Color(0xFFF97316),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_generationMode == 'sequential') ...[
                    _darkField(
                      context,
                      label: 'البادئة (Prefix) *',
                      controller: _prefixController,
                      hint: 'مثال: user',
                      enabled: !_generating,
                      prefixIcon: Icon(Icons.text_fields,
                          size: 18, color: _subTextColor(context)),
                      validator: (value) {
                        if (_generationMode == 'sequential' &&
                            (value == null || value.trim().isEmpty)) {
                          return 'أدخل البادئة';
                        }
                        return null;
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _darkField(
                            context,
                            label: 'يبدأ من',
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
                          child: _darkField(
                            context,
                            label: 'عدد الخانات',
                            controller: _paddingController,
                            hint: '4',
                            keyboardType: TextInputType.number,
                            enabled: !_generating,
                            validator: (value) {
                              final n = int.tryParse(value?.trim() ?? '');
                              if (n == null || n < 1 || n > 10) {
                                return 'من 1 إلى 10';
                              }
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (_generationMode == 'random') ...[
                    _infoBox(
                      context,
                      icon: Icons.info,
                      color: const Color(0xFFF97316),
                      text: 'أسماء عشوائية بأرقام فقط — صعبة التخمين',
                    ),
                    const SizedBox(height: 12),
                    _darkField(
                      context,
                      label: 'طول الاسم *',
                      controller: _randomLengthController,
                      hint: 'مثال: 6',
                      keyboardType: TextInputType.number,
                      enabled: !_generating,
                      prefixIcon: Icon(Icons.straighten,
                          size: 18, color: _subTextColor(context)),
                      validator: (value) {
                        if (_generationMode == 'random') {
                          final n = int.tryParse(value?.trim() ?? '');
                          if (n == null || n < 4 || n > 20) {
                            return 'من 4 إلى 20';
                          }
                        }
                        return null;
                      },
                    ),
                  ],
                  _darkField(
                    context,
                    label: 'عدد الكروت *',
                    controller: _countController,
                    hint: '10',
                    keyboardType: TextInputType.number,
                    enabled: !_generating,
                    prefixIcon: Icon(Icons.numbers,
                        size: 18, color: _subTextColor(context)),
                    validator: (value) {
                      final n = int.tryParse(value?.trim() ?? '');
                      if (n == null || n < 1) return 'العدد 1 على الأقل';
                      if (n > 1000) return 'الحد 1000';
                      return null;
                    },
                  ),
                ],
              ),
            ),

            // ============================================
            // البروفايل
            // ============================================
            _sectionTitle(context, Icons.router, 'البروفايل',
                color: const Color(0xFF06B6D4)),
            _sectionCard(
              context,
              accent: const Color(0xFF06B6D4),
              child: _loadingProfiles
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(
                  color: _accent,
                  backgroundColor: Colors.white12,
                ),
              )
                  : DropdownButtonFormField<String>(
                initialValue: _selectedProfile,
                dropdownColor: _cardColor(context),
                style: TextStyle(color: _textColor(context)),
                decoration: InputDecoration(
                  labelText: 'البروفايل *',
                  labelStyle:
                  TextStyle(color: _subTextColor(context)),
                  prefixIcon: Icon(Icons.router,
                      size: 18, color: _subTextColor(context)),
                  filled: true,
                  fillColor: _fieldFillColor(context),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: _borderColor(context)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                    BorderSide(color: _borderColor(context)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: _accent, width: 1.5),
                  ),
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
            ),

            // ============================================
            // كلمة المرور
            // ============================================
            _sectionTitle(context, Icons.key, 'كلمة المرور',
                color: const Color(0xFF8B5CF6)),
            _sectionCard(
              context,
              accent: const Color(0xFF8B5CF6),
              child: Column(
                children: [
                  Row(
                    children: [
                      _passwordModeChip(context,
                          label: 'فارغة',
                          mode: 'empty',
                          icon: Icons.lock_open,
                          color: Colors.grey),
                      const SizedBox(width: 6),
                      _passwordModeChip(context,
                          label: 'مثل الاسم',
                          mode: 'same',
                          icon: Icons.content_copy,
                          color: const Color(0xFF3B82F6)),
                      const SizedBox(width: 6),
                      _passwordModeChip(context,
                          label: 'عشوائية',
                          mode: 'random',
                          icon: Icons.casino,
                          color: const Color(0xFF8B5CF6)),
                      const SizedBox(width: 6),
                      _passwordModeChip(context,
                          label: 'موحّدة',
                          mode: 'custom',
                          icon: Icons.edit,
                          color: const Color(0xFFF97316)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_passwordMode == 'custom')
                    _darkField(
                      context,
                      label: 'كلمة المرور الموحّدة',
                      controller: _customPasswordController,
                      hint: 'نفس كلمة المرور لكل الكروت',
                      enabled: !_generating,
                      prefixIcon: Icon(Icons.key,
                          size: 18, color: _subTextColor(context)),
                    )
                  else if (_passwordMode == 'same')
                    _infoBox(context,
                        icon: Icons.info,
                        color: const Color(0xFF3B82F6),
                        text: 'كل كرت ستكون كلمة مروره نفس اسم المستخدم')
                  else if (_passwordMode == 'random')
                      _infoBox(context,
                          icon: Icons.info,
                          color: const Color(0xFF8B5CF6),
                          text: 'كل كرت ستكون كلمة مروره عشوائية')
                    else
                      _infoBox(context,
                          icon: Icons.info,
                          color: Colors.grey,
                          text: 'الكروت ستكون بدون كلمة مرور'),
                ],
              ),
            ),

            // ============================================
            // الصلاحية
            // ============================================
            _sectionTitle(context, Icons.card_giftcard, 'الصلاحية',
                color: const Color(0xFFA855F7)),
            _sectionCard(
              context,
              accent: const Color(0xFFA855F7),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'تُحفظ في Email (تعمل مع Script Hotspot_Validity)',
                    style: TextStyle(
                        fontSize: 12, color: _subTextColor(context)),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _darkField(
                          context,
                          label: 'المدة',
                          controller: _validityValueController,
                          hint: '24',
                          keyboardType: TextInputType.number,
                          enabled: !_generating,
                          prefixIcon: Icon(Icons.timer,
                              size: 18, color: _subTextColor(context)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DropdownButtonFormField<String>(
                            initialValue: _validityUnit,
                            dropdownColor: _cardColor(context),
                            style: TextStyle(color: _textColor(context)),
                            decoration: InputDecoration(
                              labelText: 'الوحدة',
                              labelStyle: TextStyle(
                                  color: _subTextColor(context)),
                              prefixIcon: Icon(Icons.schedule,
                                  size: 18, color: _subTextColor(context)),
                              filled: true,
                              fillColor: _fieldFillColor(context),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _borderColor(context)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: _borderColor(context)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(
                                    color: _accent, width: 1.5),
                              ),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'm', child: Text('دقائق')),
                              DropdownMenuItem(
                                  value: 'h', child: Text('ساعات')),
                              DropdownMenuItem(
                                  value: 'd', child: Text('أيام')),
                              DropdownMenuItem(
                                  value: 'w', child: Text('أسابيع')),
                            ],
                            onChanged: _generating
                                ? null
                                : (v) {
                              if (v != null) {
                                setState(() => _validityUnit = v);
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ============================================
            // قيود أخرى
            // ============================================
            _sectionTitle(context, Icons.data_usage, 'قيود أخرى',
                color: const Color(0xFF10B981)),
            _sectionCard(
              context,
              accent: const Color(0xFF10B981),
              child: Column(
                children: [
                  _darkField(
                    context,
                    label: 'حد البيانات (بـ GB)',
                    controller: _limitGbController,
                    hint: '2 = 2 جيجا، 0.5 = 500 ميجا',
                    keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                    enabled: !_generating,
                    prefixIcon: Icon(Icons.data_usage,
                        size: 18, color: _subTextColor(context)),
                  ),
                  _darkField(
                    context,
                    label: 'ملاحظة',
                    controller: _commentController,
                    hint: 'ملاحظة توضع على جميع الكروت',
                    enabled: !_generating,
                    prefixIcon: Icon(Icons.comment,
                        size: 18, color: _subTextColor(context)),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // ============================================
            // أزرار الإجراءات
            // ============================================
            if (!_generating)
              Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: _doPreview,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _accent,
                              side: const BorderSide(color: _accent),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.visibility, size: 20),
                            label: const Text('معاينة'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _generate,
                            style: FilledButton.styleFrom(
                              backgroundColor: _accent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.auto_awesome, size: 20),
                            label: const Text('توليد'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_preview.isNotEmpty)
                    SizedBox(
                      width: double.infinity,
                      height: 52,
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
                          backgroundColor: const Color(0xFF4F46E5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
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

            // ============================================
            // شريط التقدم
            // ============================================
            if (_generating) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _cardColor(context),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _borderColor(context)),
                ),
                child: Column(
                  children: [
                    Text(
                      'جاري التوليد...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _textColor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: _totalCount > 0
                            ? _currentIndex / _totalCount
                            : 0,
                        minHeight: 8,
                        color: _accent,
                        backgroundColor: _borderColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$_currentIndex / $_totalCount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _textColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text(
                              'نجح',
                              style: TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              '$_generatedCount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _textColor(context),
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
                              '$_failedCount',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: _textColor(context),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            // ============================================
            // المعاينة
            // ============================================
            if (_preview.isNotEmpty && !_generating) ...[
              const SizedBox(height: 16),
              _sectionTitle(
                context,
                Icons.visibility,
                'معاينة الكروت (${_preview.length})',
                color: const Color(0xFF4F46E5),
              ),
              _sectionCard(
                context,
                accent: const Color(0xFF4F46E5),
                child: Column(
                  children: [
                    for (int i = 0;
                    i < (_preview.length > 20 ? 20 : _preview.length);
                    i++)
                      _previewCardItem(context, _preview[i], i),
                    if (_preview.length > 20)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '... و ${_preview.length - 20} كرت إضافي',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _subTextColor(context),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
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