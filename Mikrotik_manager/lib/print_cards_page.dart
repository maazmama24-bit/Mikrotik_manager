import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// =============================================================================
// Print Cards Page
// =============================================================================

class PrintCardsPage extends StatefulWidget {
  final List<Map<String, String>> cards;
  final String networkName;

  const PrintCardsPage({
    super.key,
    required this.cards,
    required this.networkName,
  });

  @override
  State<PrintCardsPage> createState() => _PrintCardsPageState();
}

class _PrintCardsPageState extends State<PrintCardsPage> {
  // ===========================================================================
  // Controllers
  // ===========================================================================

  late final TextEditingController _rowsController;
  late final TextEditingController _colsController;
  late final TextEditingController _fontSizeController;
  late final TextEditingController _cardWidthController;
  late final TextEditingController _cardHeightController;
  late final TextEditingController _networkNameController;

  // ===========================================================================
  // Options
  // ===========================================================================

  bool _showPassword = true;
  bool _showUptime = true;
  bool _showGb = true;
  bool _showNetworkName = true;

  bool _generating = false;

  @override
  void initState() {
    super.initState();

    _rowsController = TextEditingController(text: '5');
    _colsController = TextEditingController(text: '2');
    _fontSizeController = TextEditingController(text: '10');
    _cardWidthController = TextEditingController(text: '80');
    _cardHeightController = TextEditingController(text: '50');
    _networkNameController = TextEditingController(
      text: widget.networkName,
    );
  }

  @override
  void dispose() {
    _rowsController.dispose();
    _colsController.dispose();
    _fontSizeController.dispose();
    _cardWidthController.dispose();
    _cardHeightController.dispose();
    _networkNameController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // Getters
  // ===========================================================================

  int get _rows => int.tryParse(_rowsController.text.trim()) ?? 5;
  int get _cols => int.tryParse(_colsController.text.trim()) ?? 2;

  double get _fontSize =>
      double.tryParse(_fontSizeController.text.trim()) ?? 10;

  double get _cardWidth =>
      double.tryParse(_cardWidthController.text.trim()) ?? 80;

  double get _cardHeight =>
      double.tryParse(_cardHeightController.text.trim()) ?? 50;

  int get _perPage => _rows * _cols;

  int get _totalPages {
    if (_perPage <= 0) return 0;
    return (widget.cards.length / _perPage).ceil();
  }

  // ===========================================================================
  // Print
  // ===========================================================================

  Future<void> _print() async {
    if (_generating) return;

    if (_rows < 1 || _cols < 1) {
      _showMessage(
        'عدد الصفوف والأعمدة يجب أن يكون 1 على الأقل',
        isError: true,
      );
      return;
    }

    setState(() => _generating = true);

    try {
      final doc = pw.Document();

      final pages = <List<Map<String, String>>>[];

      for (int i = 0; i < widget.cards.length; i += _perPage) {
        final end = (i + _perPage > widget.cards.length)
            ? widget.cards.length
            : i + _perPage;
        pages.add(widget.cards.sublist(i, end));
      }

      for (final pageCards in pages) {
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(20),
            build: (context) {
              final rows = <List<Map<String, String>>>[];

              for (int i = 0; i < pageCards.length; i += _cols) {
                final end = (i + _cols > pageCards.length)
                    ? pageCards.length
                    : i + _cols;
                rows.add(pageCards.sublist(i, end));
              }

              return pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: rows.map((rowCards) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: pw.Row(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: rowCards.map((card) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(right: 4),
                          child: pw.SizedBox(
                            width: _cardWidth,
                            height: _cardHeight,
                            child: _buildCard(card),
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        );
      }

      await Printing.layoutPdf(
        onLayout: (format) async => doc.save(),
      );
    } catch (e) {
      _showMessage('فشل توليد PDF: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() => _generating = false);
      }
    }
  }

  // ===========================================================================
  // PDF Card
  // ===========================================================================

  pw.Widget _buildCard(Map<String, String> card) {
    final name = card['name'] ?? '';
    final password = card['password'] ?? '';
    final uptime = card['limit-uptime'] ?? '';
    final gb = card['limit-gb'] ?? '';
    final networkName = _networkNameController.text.trim();

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 1),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(6),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          if (_showNetworkName && networkName.isNotEmpty)
            pw.Text(
              networkName,
              style: pw.TextStyle(
                fontSize: _fontSize + 1,
                fontWeight: pw.FontWeight.bold,
              ),
              maxLines: 1,
              overflow: pw.TextOverflow.clip,
            ),
          pw.Divider(thickness: 0.5, height: 4),
          pw.Row(
            children: [
              pw.Text(
                'User: ',
                style: pw.TextStyle(fontSize: _fontSize - 1),
              ),
              pw.Expanded(
                child: pw.Text(
                  name,
                  style: pw.TextStyle(
                    fontSize: _fontSize + 2,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  maxLines: 1,
                ),
              ),
            ],
          ),
          if (_showPassword && password.isNotEmpty)
            pw.Row(
              children: [
                pw.Text(
                  'Pass: ',
                  style: pw.TextStyle(fontSize: _fontSize - 1),
                ),
                pw.Expanded(
                  child: pw.Text(
                    password,
                    style: pw.TextStyle(
                      fontSize: _fontSize + 2,
                      fontWeight: pw.FontWeight.bold,
                    ),
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          pw.Row(
            children: [
              if (_showUptime && uptime.isNotEmpty)
                pw.Expanded(
                  child: pw.Text(
                    '⏱ $uptime',
                    style: pw.TextStyle(fontSize: _fontSize - 1),
                  ),
                ),
              if (_showGb && gb.isNotEmpty)
                pw.Expanded(
                  child: pw.Text(
                    '📊 $gb GB',
                    style: pw.TextStyle(fontSize: _fontSize - 1),
                    textAlign: pw.TextAlign.right,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
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

  IconData _iconFromEmoji(String emoji) {
    switch (emoji) {
      case '📐':
        return Icons.aspect_ratio;
      case '📄':
        return Icons.description;
      case '👁️':
        return Icons.visibility;
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

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required int min,
    required int max,
    bool isDouble = false,
    IconData? icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: isDouble
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.number,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          hintText: '$min - $max',
          prefixIcon: icon != null ? Icon(icon, size: 18) : null,
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
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Color color,
    required Function(bool) onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: value
            ? color.withValues(alpha: 0.08)
            : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: value
              ? color.withValues(alpha: 0.3)
              : Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: SwitchListTile(
        dense: true,
        title: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: value ? color : Colors.grey,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: value ? FontWeight.bold : FontWeight.normal,
                color: value ? color : Colors.grey.shade700,
              ),
            ),
          ],
        ),
        value: value,
        activeThumbColor: color,
        onChanged: onChanged,
      ),
    );
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('🖨️ طباعة الكروت'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          // ============================================
          // بطاقة الإحصائيات
          // ============================================
          _buildStatsCard(),

          const SizedBox(height: 16),

          // ============================================
          // التخطيط
          // ============================================
          _sectionTitle('📐', 'التخطيط'),

          _sectionCard(
            accent: Colors.blue,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        label: 'عدد الصفوف',
                        controller: _rowsController,
                        min: 1,
                        max: 15,
                        icon: Icons.table_rows,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _numberField(
                        label: 'عدد الأعمدة',
                        controller: _colsController,
                        min: 1,
                        max: 6,
                        icon: Icons.view_column,
                      ),
                    ),
                  ],
                ),

                _numberField(
                  label: 'حجم الخط (pt)',
                  controller: _fontSizeController,
                  min: 5,
                  max: 30,
                  isDouble: true,
                  icon: Icons.text_fields,
                ),

                Row(
                  children: [
                    Expanded(
                      child: _numberField(
                        label: 'عرض الكرت (mm)',
                        controller: _cardWidthController,
                        min: 30,
                        max: 150,
                        isDouble: true,
                        icon: Icons.straighten,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _numberField(
                        label: 'ارتفاع الكرت (mm)',
                        controller: _cardHeightController,
                        min: 20,
                        max: 120,
                        isDouble: true,
                        icon: Icons.height,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ============================================
          // المحتوى
          // ============================================
          _sectionTitle('📄', 'المحتوى', color: Colors.teal),

          _sectionCard(
            accent: Colors.teal,
            child: TextField(
              controller: _networkNameController,
              decoration: InputDecoration(
                labelText: 'اسم الشبكة',
                hintText: 'مثال: شبكة الفيصلية',
                prefixIcon: const Icon(Icons.wifi, size: 18),
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
                  borderSide:
                  const BorderSide(color: Colors.teal, width: 2),
                ),
              ),
            ),
          ),

          // ============================================
          // خيارات العرض
          // ============================================
          _sectionTitle('👁️', 'خيارات العرض', color: Colors.purple),

          _sectionCard(
            accent: Colors.purple,
            child: Column(
              children: [
                _switchTile(
                  icon: Icons.wifi,
                  title: 'إظهار اسم الشبكة',
                  value: _showNetworkName,
                  color: Colors.blue,
                  onChanged: (v) =>
                      setState(() => _showNetworkName = v),
                ),
                _switchTile(
                  icon: Icons.lock,
                  title: 'إظهار كلمة المرور',
                  value: _showPassword,
                  color: Colors.purple,
                  onChanged: (v) => setState(() => _showPassword = v),
                ),
                _switchTile(
                  icon: Icons.timer,
                  title: 'إظهار المدة',
                  value: _showUptime,
                  color: Colors.green,
                  onChanged: (v) => setState(() => _showUptime = v),
                ),
                _switchTile(
                  icon: Icons.data_usage,
                  title: 'إظهار حجم البيانات',
                  value: _showGb,
                  color: Colors.orange,
                  onChanged: (v) => setState(() => _showGb = v),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // ============================================
          // زر الطباعة
          // ============================================
          SizedBox(
            height: 56,
            child: FilledButton.icon(
              onPressed: _generating ? null : _print,
              style: FilledButton.styleFrom(
                backgroundColor: Colors.green.shade600,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _generating
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : const Icon(Icons.print, size: 22),
              label: Text(
                _generating ? 'جاري التوليد...' : '🖨️ طباعة PDF',
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
    );
  }

  // ===========================================================================
  // Stats Card
  // ===========================================================================

  Widget _buildStatsCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.indigo.shade700],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.indigo.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.print,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'جاهز للطباعة',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${widget.cards.length} كرت',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _statsItem(
                    Icons.grid_view,
                    'في الصفحة',
                    '$_perPage',
                  ),
                ),
                Container(
                  width: 1,
                  height: 30,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
                Expanded(
                  child: _statsItem(
                    Icons.description,
                    'صفحات',
                    '$_totalPages',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statsItem(IconData icon, String label, String value) {
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
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}