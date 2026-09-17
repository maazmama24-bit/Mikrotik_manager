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
  // إعدادات التخطيط
  late final TextEditingController _rowsController;
  late final TextEditingController _colsController;
  late final TextEditingController _fontSizeController;
  late final TextEditingController _cardWidthController;
  late final TextEditingController _cardHeightController;
  late final TextEditingController _networkNameController;

  // خيارات العرض
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

  Future<void> _print() async {
    if (_generating) return;

    if (_rows < 1 || _cols < 1) {
      _showMessage('عدد الصفوف والأعمدة يجب أن يكون 1 على الأقل', isError: true);
      return;
    }

    setState(() => _generating = true);

    try {
      final doc = pw.Document();

      // قسّم الكروت إلى صفحات
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
              // تقسيم الكروت إلى صفوف
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
        title: const Text('🖨️ طباعة الكروت'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'إجمالي الكروت: ${widget.cards.length}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'كروت في الصفحة: $_perPage',
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    'عدد الصفحات: $_totalPages',
                    style: const TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          const Text(
            '📐 التخطيط',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          Row(
            children: [
              Expanded(
                child: _numberField(
                  label: 'عدد الصفوف',
                  controller: _rowsController,
                  min: 1,
                  max: 15,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _numberField(
                  label: 'عدد الأعمدة',
                  controller: _colsController,
                  min: 1,
                  max: 6,
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
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          const Text(
            '📄 المحتوى',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),

          TextField(
            controller: _networkNameController,
            decoration: const InputDecoration(
              labelText: 'اسم الشبكة',
              hintText: 'مثال: شبكة الفيصلية',
              border: OutlineInputBorder(),
            ),
          ),

          const SizedBox(height: 10),

          SwitchListTile(
            title: const Text('إظهار اسم الشبكة'),
            value: _showNetworkName,
            onChanged: (v) => setState(() => _showNetworkName = v),
          ),
          SwitchListTile(
            title: const Text('إظهار كلمة المرور'),
            value: _showPassword,
            onChanged: (v) => setState(() => _showPassword = v),
          ),
          SwitchListTile(
            title: const Text('إظهار المدة'),
            value: _showUptime,
            onChanged: (v) => setState(() => _showUptime = v),
          ),
          SwitchListTile(
            title: const Text('إظهار حجم البيانات'),
            value: _showGb,
            onChanged: (v) => setState(() => _showGb = v),
          ),

          const SizedBox(height: 20),

          SizedBox(
            height: 54,
            child: FilledButton.icon(
              onPressed: _generating ? null : _print,
              icon: _generating
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
                  : const Icon(Icons.print),
              label: Text(
                _generating ? 'جاري التوليد...' : '🖨️ طباعة PDF',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberField({
    required String label,
    required TextEditingController controller,
    required int min,
    required int max,
    bool isDouble = false,
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
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}