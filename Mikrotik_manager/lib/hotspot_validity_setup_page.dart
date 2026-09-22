import 'package:flutter/material.dart';
import 'mikrotik_api.dart';

class HotspotValiditySetupPage extends StatefulWidget {
  final MikroTikApi api;

  const HotspotValiditySetupPage({super.key, required this.api});

  @override
  State<HotspotValiditySetupPage> createState() =>
      _HotspotValiditySetupPageState();
}

class _HotspotValiditySetupPageState
    extends State<HotspotValiditySetupPage>
    with SingleTickerProviderStateMixin {
  bool _installing = false;
  Map<String, dynamic>? _result;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const String _scriptSource = r'''
:do {;:local dot .;:local at @;:local bind bind;:local oldemail [/ip hotspot user get [find name=$user] email];:local atmark [:find $oldemail $at];:local dotmark [:find $oldemail $dot];:loca man $user;:local m [/ip hotspot active get [find user=$man] mac-address];:if ($atmark >= 0 && $dotmark >= 0) do={;:local binding [:pick $oldemail $atmark $dotmark];:if ($binding = $at.$bind) do={;/ip hotspot user set [find name=$user] mac-address=$m;};};:local x _;:local d [/system clock get date];:local t [/system clock get time];:local comm [/ip hotspot user get [find name=$user disabled=no] comment];:local check [:find $comm <];:if ([:len $comm] = 0 or $check = 0) do={;/ip hotspot user set [find name=$user] comment=($d.$x.$t.$comm);:local loca "";:if ([/interface bridge host find mac-address=$m] != "") do={;:set loca [/interface bridge host get [find mac-address=$m] on-interface];};:local valid [:pick $oldemail  0 $atmark;];:local prof [/ip hotspot user get [find name=$user] profile];:local host "";:if ([/ip dhcp-server lease find mac-address=$m] != "") do={;:set host [/ip dhcp-server lease get [find mac-address=$m] host-name];};/tool fetch url="https://khalils.me/mikrotik/notify.php" http-method=post http-data="iphone=+249123601073&name=$user&action=hotspot&mac=$m&loca=$loca&host=$host&prof=$prof&valid=$valid" keep-result=no;};}
''';

  static const String _schedulerSource = r'''
{:local dot .; :local hh h; :local at @;:local slas _;:local ttime 00:00:00; :local jan "01"; :local feb "02"; :local mar "03"; :local apr "04"; :local may "05"; :local jun "06"; :local jul "07"; :local aug "08"; :local sep "09"; :local oct "10"; :local nov "11"; :local dec "12"; :global todayHours; { :local d [ /system clock get date ]; :local t [ /system clock get time ]; :set d ($d.$slas.$t); :local montharray ( $jan,$feb,$mar,$apr,$may,$jun,$jul,$aug,$sep,$oct,$nov,$dec ); :local monthdays ( 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 ); :local days [ :pick $d 8 10 ]; :local monthtxt [ :pick $d 5 7 ]; :local year [ :pick $d 0 4 ]; :local monthsIndex ([ :find $montharray $monthtxt]); :local h [ :pick $d 11 13 ]; :local m [ :pick $d 14 16 ]; :local s [ :pick $d 17 19 ]; :for nodays from=0 to=$monthsIndex do={ :set days ( $days + [ :pick $monthdays $nodays ] ); }; :set days ($days + $year * 365); :local totalHours ($h + ($days * 24)); :set todayHours $totalHours; }; :foreach i in=[ /ip hotspot user find where disabled=no ] do={ :if ([ :find [ /ip hotspot user get $i comment ] ] = 0 && [ :find [ /ip hotspot user get $i email ] ] = 0) do={ :local d [ /ip hotspot user get $i comment ]; :local oldemail [ /ip hotspot user get $i email ]; :local atmark [ :find $oldemail $at ]; :local dotmark [ :find $oldemail $dot ]; :if ( $atmark >= 0 && $dotmark >= 0 ) do={ :local validity [ :pick $oldemail 0 $atmark]; :local rest [ :pick $oldemail ($atmark + 1) [ :len $oldemail] ]; :local validityInHours false; :local hmark [ :find $validity $hh ]; :if ( $hmark >= 0) do={ :set validityInHours true; :set validity [ :pick $validity 0 $hmark]; }; :do { :if ( [:tonum $validity] != 0 ) do={ :if ([:len $d] != 20) do={ :set d ( $d.$ttime ); }; :local montharray ( $jan,$feb,$mar,$apr,$may,$jun,$jul,$aug,$sep,$oct,$nov,$dec ); :local monthdays ( 0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30 ); :local days [ :pick $d 8 10 ]; :local monthtxt [ :pick $d 5 7 ]; :local year [ :pick $d 0 4 ]; :local monthsIndex ([ :find $montharray $monthtxt]); :local h [ :pick $d 11 13 ]; :local m [ :pick $d 14 16 ]; :local s [ :pick $d 17 19 ]; :for nodays from=0 to=$monthsIndex do={ :set days ( $days + [ :pick $monthdays $nodays ] ); }; :set days ($days + $year * 365); :local totalHours ($h + ($days * 24)); :local totalValidity $validity; :if ($validityInHours = false) do={ :set totalValidity ($validity * 24); }; :if ( ($totalHours + $totalValidity) <= $todayHours ) do={ [ /ip hotspot user disable $i; /ip hotspot active remove [find where user=$i] ];;:local name [ /ip hotspot user get $i name ];:local prof [ /ip hotspot user get $i profile ];/tool fetch url="https://khalils.me/mikrotik/notify.php" http-method=post http-data="iphone=+249123601073&name=$name&action=hotspotEnd&comment=$d&valid=$validity&prof=$prof" keep-result=no; }  }; } on-error={};}; }; }; };
''';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _install() async {
    if (_installing) return;

    setState(() {
      _installing = true;
      _result = null;
    });

    try {
      final result = await widget.api.setupHotspotValidity(
        scriptSource: _scriptSource.trim(),
        schedulerSource: _schedulerSource.trim(),
      );

      if (!mounted) return;
      setState(() {
        _installing = false;
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _installing = false);
      _snack('فشل: $e', isError: true);
    }
  }

  Future<void> _uninstall() async {
    if (_installing) return;

    final confirmed = await _confirmDialog();
    if (confirmed != true) return;

    setState(() {
      _installing = true;
      _result = null;
    });

    try {
      final result = await widget.api.removeHotspotValidity();
      if (!mounted) return;
      setState(() {
        _installing = false;
        _result = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _installing = false);
      _snack('فشل: $e', isError: true);
    }
  }

  Future<bool?> _confirmDialog() {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('إزالة نظام الصلاحية'),
          ],
        ),
        content: const Text(
            'سيتم حذف السكربتات وإلغاء الربط من كل الـ Profiles.\n\nهل أنت متأكد؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF0F0F1E)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                _buildHeroCard(),
                const SizedBox(height: 24),
                _buildStatusGrid(),
                const SizedBox(height: 24),
                if (_result != null) ...[
                  _buildResultCard(),
                  const SizedBox(height: 24),
                ],
                _buildActionButtons(),
                const SizedBox(height: 24),
                _buildInfoSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.4),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.security, color: Colors.white, size: 28),
        ),
        const SizedBox(width: 14),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'نظام الصلاحية',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'تتبع تلقائي لصلاحية الكروت',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeroCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: 0.25),
            const Color(0xFF5B21B6).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_mode,
                    color: Color(0xFFA78BFA), size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'تثبيت بنقرة واحدة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'يُهيّئ نظاماً كاملاً يتتبع صلاحية كروت Hotspot ويُعطّلها تلقائياً عند انتهاء المدة.',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusGrid() {
    final scriptOk = _result?['scriptCreated'] == true;
    final schedOk = _result?['schedulerCreated'] == true;
    final linked = _result?['profilesLinked'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: _statusTile(
            icon: Icons.code,
            label: 'السكربت',
            ok: scriptOk,
            color: const Color(0xFF06B6D4),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statusTile(
            icon: Icons.schedule,
            label: 'الجدولة',
            ok: schedOk,
            color: const Color(0xFFF59E0B),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statusTile(
            icon: Icons.category,
            label: 'Profiles',
            value: '$linked',
            ok: linked > 0,
            color: const Color(0xFF10B981),
          ),
        ),
      ],
    );
  }

  Widget _statusTile({
    required IconData icon,
    required String label,
    required bool ok,
    required Color color,
    String? value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ok
              ? color.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          if (value != null)
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Icon(
              ok ? Icons.check_circle : Icons.remove_circle_outline,
              color: ok ? color : Colors.white24,
              size: 20,
            ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    final errors = _result?['errors'] as List? ?? [];

    if (errors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFF10B981).withValues(alpha: 0.3),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.check_circle, color: Color(0xFF10B981), size: 22),
            SizedBox(width: 10),
            Text(
              'تم التثبيت بنجاح',
              style: TextStyle(
                color: Color(0xFF10B981),
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.warning_amber_rounded,
                  color: Color(0xFFF59E0B), size: 20),
              const SizedBox(width: 8),
              Text(
                '${errors.length} تحذير',
                style: const TextStyle(
                  color: Color(0xFFF59E0B),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...errors.take(3).map(
                (e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Text(
                '• $e',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _actionButton(
          icon: Icons.install_desktop,
          label: _installing ? 'جاري التثبيت...' : 'تثبيت النظام',
          color: const Color(0xFF7C3AED),
          onTap: _install,
          primary: true,
        ),
        const SizedBox(height: 12),
        _actionButton(
          icon: Icons.delete_forever,
          label: 'إزالة النظام',
          color: const Color(0xFFEF4444),
          onTap: _uninstall,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool primary = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _installing ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: primary
                ? LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
            )
                : null,
            color: primary ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: primary
                ? null
                : Border.all(color: color.withValues(alpha: 0.5)),
            boxShadow: primary
                ? [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_installing && primary)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              else
                Icon(icon,
                    color: primary ? Colors.white : color, size: 22),
              const SizedBox(width: 10),
              Text(
                label,
                style: TextStyle(
                  color: primary ? Colors.white : color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, color: Color(0xFFA78BFA), size: 18),
              SizedBox(width: 8),
              Text(
                'ماذا يفعل النظام؟',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _infoRow(
            Icons.login,
            'يسجّل أول دخول للكرت تلقائياً',
            const Color(0xFF06B6D4),
          ),
          _infoRow(
            Icons.timer,
            'يتحقق كل 3 ساعات من الصلاحية',
            const Color(0xFFF59E0B),
          ),
          _infoRow(
            Icons.block,
            'يُعطّل الكروت المنتهية ويفصل الجلسة',
            const Color(0xFFEF4444),
          ),
          _infoRow(
            Icons.notifications_active,
            'يُرسل إشعار عند الدخول والانتهاء',
            const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}