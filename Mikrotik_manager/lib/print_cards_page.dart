import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models/card_template.dart';
import 'services/template_storage.dart';

class PrintCardsPage extends StatefulWidget {
  final List<Map<String, String>> cards;
  final String networkName;
  final CardTemplate? initialTemplate;

  const PrintCardsPage({
    super.key,
    required this.cards,
    required this.networkName,
    this.initialTemplate,
  });

  @override
  State<PrintCardsPage> createState() => _PrintCardsPageState();
}

class _PrintCardsPageState extends State<PrintCardsPage> {
  final TemplateStorage _storage = TemplateStorage();

  List<CardTemplate> _allTemplates = [];
  CardTemplate? _template;
  String? _selectedFieldId;
  bool _loading = true;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    final all = await _storage.loadAll();

    if (!mounted) return;
    debugPrint('🔍 عدد القوالب المحمّلة: ${all.length}');
    for (final t in all) {
      debugPrint('🔍 - ${t.name} (${t.id}) bg=${t.backgroundImage}');
    }
    setState(() {
      _allTemplates = all;

      // أولوية: initialTemplate ثم آخر قالب
      if (widget.initialTemplate != null) {
        _template = widget.initialTemplate!.copy();
      } else if (all.isNotEmpty) {
        _template = all.first.copy();
      } else {
        _template = CardTemplate(
          id: 'default',
          name: 'افتراضي',
          networkName: widget.networkName,
          rows: 16,
          cols: 6,
          cardWidth: 31,
          cardHeight: 17,
          fields: CardTemplate.defaultFields(),
        );
      }
      _loading = false;
    });
  }

  Future<void> _saveTemplate() async {
    if (_template == null) return;

    // ابحث عن القالب في القائمة
    final index = _allTemplates.indexWhere((t) => t.id == _template!.id);

    if (index != -1) {
      _allTemplates[index] = _template!;
    } else {
      _allTemplates.add(_template!);
    }

    await _storage.saveAll(_allTemplates);
  }

  int get _perPage =>
      (_template?.rows ?? 16) * (_template?.cols ?? 6);

  int get _totalPages {
    if (_perPage <= 0) return 0;
    return (widget.cards.length / _perPage).ceil();
  }

  Future<void> _print() async {
    if (_printing || _template == null) return;

    setState(() => _printing = true);

    try {
      await _saveTemplate();

      // 📝 حمّل الخط العربي
      final fontData = await rootBundle.load('assets/fonts/Cairo-Regular.ttf');
      final fontBoldData = await rootBundle.load('assets/fonts/Cairo-Bold.ttf');
      final arabicFont = pw.Font.ttf(fontData);
      final arabicFontBold = pw.Font.ttf(fontBoldData);

      final doc = pw.Document();
      final template = _template!;
      final perPage = _perPage;
      final cols = template.cols;

      // 🖼️ حمّل صورة الخلفية مرة واحدة
      pw.MemoryImage? bgImage;
      if (template.backgroundImage != null &&
          template.backgroundImage!.isNotEmpty) {
        try {
          final bytes =
          await rootBundle.load(template.backgroundImage!);
          bgImage = pw.MemoryImage(bytes.buffer.asUint8List());
        } catch (e) {
          debugPrint('⚠️ فشل تحميل الخلفية: $e');
        }
      }

      final pages = <List<Map<String, String>>>[];
      for (int i = 0; i < widget.cards.length; i += perPage) {
        final end = (i + perPage > widget.cards.length)
            ? widget.cards.length
            : i + perPage;
        pages.add(widget.cards.sublist(i, end));
      }

      for (final pageCards in pages) {
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(6),
            build: (context) {
              final cardW = template.cardWidth * PdfPageFormat.mm;
              final cardH = template.cardHeight * PdfPageFormat.mm;

              final rows = <List<Map<String, String>>>[];
              for (int i = 0; i < pageCards.length; i += cols) {
                final end = (i + cols > pageCards.length)
                    ? pageCards.length
                    : i + cols;
                rows.add(pageCards.sublist(i, end));
              }

              return pw.Column(
                mainAxisSize: pw.MainAxisSize.min,
                mainAxisAlignment: pw.MainAxisAlignment.start,
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: rows.map((rowCards) {
                    return pw.Row(
                      mainAxisSize: pw.MainAxisSize.min,
                      mainAxisAlignment: pw.MainAxisAlignment.center,
                      crossAxisAlignment: pw.CrossAxisAlignment.center,
                      children: rowCards.map((card) {
                        return pw.SizedBox(
                          width: cardW,
                          height: cardH,
                          child: _buildPdfCard(
                            card,
                            template,
                            bgImage,
                            arabicFont,
                            arabicFontBold,
                          ),
                        );
                      }).toList(),
                    );
                  }).toList(),
              );
            },
          ),
        );
      }

      await Printing.layoutPdf(onLayout: (format) async => doc.save());

      if (!mounted) return;
      _snack('تم الحفظ والطباعة ✅');
    } catch (e) {
      if (!mounted) return;
      _snack('فشل: $e', isError: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }
  pw.Widget _buildPdfCard(
      Map<String, String> card,
      CardTemplate template,
      pw.MemoryImage? bgImage,
      pw.Font arabicFont,
      pw.Font arabicFontBold,
      ) {
    final visibleFields =
    template.fields.where((f) => f.visible).toList();
    final cardW = template.cardWidth * PdfPageFormat.mm;
    final cardH = template.cardHeight * PdfPageFormat.mm;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.4),
        borderRadius: pw.BorderRadius.circular(1),
      ),
      child: pw.Stack(
        children: [
          // 🖼️ الخلفية
          if (bgImage != null)
            pw.Positioned.fill(
              child: pw.Image(bgImage, fit: pw.BoxFit.cover),
            ),

          // ✍️ الحقول
          ...visibleFields.map((field) {
            final value = _fieldValue(field, card);
            if (value.isEmpty) return pw.SizedBox();

            // الحساب نفسه كما في المعاينة، مع تعديل بسيط
            final fontSize = field.fontSize * 0.10;

            // ارتفاع سطر النص
            final lineHeight = fontSize * 1.8;

            // موضع النص
            final top = (field.y * cardH) - (lineHeight / 2);

            return pw.Positioned(
              left: 0,
              top: top,
              child: pw.Container(
                width: cardW,
                height: lineHeight,
                alignment: pw.Alignment.center,
                child: pw.Directionality(
                  textDirection: pw.TextDirection.rtl,
                  child: pw.Text(
                    value,
                    textAlign: pw.TextAlign.center,
                    maxLines: 1,
                    overflow: pw.TextOverflow.clip,
                    style: pw.TextStyle(
                      font: field.fontStyle.toLowerCase().contains('bold')
                          ? arabicFontBold
                          : arabicFont,
                      fontSize: fontSize,
                    ),
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  String _fieldValue(
      TemplateField field, Map<String, String> card) {
    if (field.isCustom) return field.customValue;

    switch (field.key) {
      case 'network':
        return _template?.networkName ?? widget.networkName;
      case 'name':
        return card['name'] ?? '';
      case 'password':
        return card['password'] ?? '';
      case 'limit-uptime':
        return card['limit-uptime'] ?? '';
      case 'limit-gb':
        return card['limit-gb'] ?? '';
      case 'comment':
        return card['comment'] ?? '';
      default:
        return '';
    }
  }

  void _updateField(TemplateField updated) {
    final index =
    _template!.fields.indexWhere((f) => f.id == updated.id);
    if (index == -1) return;
    setState(() {
      _template!.fields[index] = updated;
    });
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor:
          isError ? Colors.red : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1A1A2E),
          foregroundColor: Colors.white,
          title: const Text('🖨️ طباعة الكروت'),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Color(0xFFA78BFA)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          '🖨️ طباعة الكروت',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Column(
        children: [
          // 🔝 المعاينة الثابتة (لا تتحرك)
          Container(
            color: const Color(0xFF0F0F1E),
            child: _buildPreviewArea(),
          ),

          // 📜 المحتوى القابل للتمرير
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              children: [
                _buildTemplateSelector(),
                const SizedBox(height: 16),
                _buildGridSettings(),
                const SizedBox(height: 20),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4),
                  child: Row(
                    children: [
                      Icon(Icons.tune,
                          color: Color(0xFFA78BFA), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'الحقول',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ..._template!.fields.map((f) => _buildFieldCard(f)),
                const SizedBox(height: 20),
                _buildPrintButton(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Template Selector
  // ===========================================================================

  Widget _buildTemplateSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.layers,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          const Text(
            'القالب:',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _allTemplates.isEmpty
                ? const Text(
              'لا توجد قوالب',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 13,
              ),
            )
                : DropdownButton<String>(
              value: _template?.id,
              isExpanded: true,
              dropdownColor: const Color(0xFF1A1A2E),
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down,
                  color: Color(0xFFA78BFA)),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              items: _allTemplates
                  .map((t) => DropdownMenuItem(
                value: t.id,
                child: Text(
                  t.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ))
                  .toList(),
              onChanged: (id) {
                if (id == null) return;
                final t = _allTemplates
                    .firstWhere((x) => x.id == id);
                setState(() {
                  _template = t.copy();
                  _selectedFieldId = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Preview
  // ===========================================================================

  Widget _buildPreviewArea() {
    final template = _template!;
    final bgPath = template.backgroundImage;

    return Column(
      children: [
        _buildStatsBar(),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          child: AspectRatio(
            aspectRatio: template.cardWidth / template.cardHeight,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final cardW = constraints.maxWidth;
                final cardH = constraints.maxHeight;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(
                        color: const Color(0xFF7C3AED), width: 2),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C3AED)
                            .withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Stack(
                      children: [
                        // 🖼️ الخلفية
                        if (bgPath != null && bgPath.isNotEmpty)
                          Positioned.fill(
                            child: Image.asset(
                              bgPath,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                              const SizedBox(),
                            ),
                          ),

                        // ✍️ الحقول
                        ...template.fields
                            .where((f) => f.visible)
                            .map((field) => _buildDraggableField(
                            field, cardW, cardH)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsBar() {
    return Container(
      padding:
      const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          _statItem(Icons.credit_card, 'كرت',
              '${widget.cards.length}'),
          Container(width: 1, height: 22, color: Colors.white12),
          _statItem(Icons.grid_view, 'صفحة', '$_perPage'),
          Container(width: 1, height: 22, color: Colors.white12),
          _statItem(Icons.description, 'صفحات', '$_totalPages'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFA78BFA), size: 14),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
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

  Widget _buildDraggableField(
      TemplateField field, double cardW, double cardH) {
    final isSelected = _selectedFieldId == field.id;
    final value = _displayValue(field);
    final fontSize = field.fontSize * 0.5;

    // عرض ديناميكي — يمنع الانكسار
    final dynamicWidth = value.length * fontSize * 0.65 + 20;

    return Positioned(
      left: field.x * cardW - (dynamicWidth / 2),
      top: field.y * cardH - (fontSize / 2) - 4,
      child: GestureDetector(
        onTap: () => setState(() => _selectedFieldId = field.id),
        onPanUpdate: (details) {
          setState(() {
            final newX =
                (field.x * cardW + details.delta.dx) / cardW;
            final newY =
                (field.y * cardH + details.delta.dy) / cardH;
            field.x = newX.clamp(0.0, 1.0);
            field.y = newY.clamp(0.0, 1.0);
            _selectedFieldId = field.id;
          });
        },
        child: Container(
          width: dynamicWidth,
          padding:
          const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(
                color: const Color(0xFF7C3AED), width: 1.5)
                : null,
          ),
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.visible,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: _fontWeight(field.fontStyle),
              fontStyle: _fontStyle(field.fontStyle),
              color: Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  String _displayValue(TemplateField field) {
    if (field.isCustom) return field.customValue;

    final firstCard = widget.cards.isNotEmpty
        ? widget.cards.first
        : <String, String>{};

    switch (field.key) {
      case 'network':
        return _template!.networkName;
      case 'name':
        return firstCard['name'] ?? '1234567';
      case 'password':
        return firstCard['password'] ?? '***';
      case 'limit-uptime':
        return firstCard['limit-uptime'] ?? '8 يوم';
      case 'limit-gb':
        return firstCard['limit-gb'] ?? '5GB';
      case 'note1':
        return firstCard['note1'] ?? 'ملاحظة 1';
      case 'note2':
        return firstCard['note2'] ?? 'ملاحظة 2';
      case 'comment':
        return firstCard['comment'] ?? 'ملاحظة';
      default:
        return field.label;
    }
  }

  FontWeight _fontWeight(String style) {
    return style.toLowerCase().contains('bold')
        ? FontWeight.bold
        : FontWeight.normal;
  }

  FontStyle _fontStyle(String style) {
    return style.toLowerCase().contains('italic')
        ? FontStyle.italic
        : FontStyle.normal;
  }

  // ===========================================================================
  // Fields List (Bottom)
  // ===========================================================================


  Widget _buildGridSettings() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF7C3AED).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(Icons.grid_view,
                  color: Color(0xFFA78BFA), size: 16),
              SizedBox(width: 8),
              Text(
                'إعدادات الصفحة',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _gridRow(
                  icon: Icons.table_rows,
                  label: 'صفوف',
                  value: _template!.rows,
                  min: 1,
                  max: 30,
                  onChanged: (v) {
                    setState(() => _template!.rows = v);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _gridRow(
                  icon: Icons.view_column,
                  label: 'أعمدة',
                  value: _template!.cols,
                  min: 1,
                  max: 20,
                  onChanged: (v) {
                    setState(() => _template!.cols = v);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${_template!.rows * _template!.cols} كرت في الصفحة',
            style: const TextStyle(
              color: Color(0xFF10B981),
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _gridRow({
    required IconData icon,
    required String label,
    required int value,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFA78BFA), size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
          const Spacer(),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.remove,
                color: Colors.white54, size: 18),
            onPressed: value > min
                ? () => onChanged(value - 1)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: const Icon(Icons.add,
                color: Colors.white54, size: 18),
            onPressed: value < max
                ? () => onChanged(value + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildFieldCard(TemplateField field) {
    final isSelected = _selectedFieldId == field.id;
    final isEditable = field.key != 'name' && field.key != 'password';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
            : Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF7C3AED)
              : Colors.white12,
        ),
      ),
      child: Column(
        children: [
          // Row 1: Name + Size + Visibility
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: field.visible
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  field.visible
                      ? Icons.visibility
                      : Icons.visibility_off,
                  color: field.visible
                      ? const Color(0xFF10B981)
                      : Colors.white38,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  field.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF7C3AED)
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${field.fontSize.toInt()} pt',
                  style: const TextStyle(
                    color: Color(0xFFA78BFA),
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Transform.scale(
                scale: 0.75,
                child: Switch(
                  value: field.visible,
                  activeThumbColor: const Color(0xFF7C3AED),
                  onChanged: (v) {
                    field.visible = v;
                    _updateField(field);
                  },
                ),
              ),
            ],
          ),

          // Row 2: Editable value
          if (isEditable) ...[
            const SizedBox(height: 8),
            _buildValueEditor(field),
          ],

          const SizedBox(height: 8),

          // Row 3: Font size slider
          Row(
            children: [
              const Icon(Icons.text_fields,
                  color: Colors.white38, size: 14),
              const SizedBox(width: 8),
              Expanded(
                child: Slider(
                  value: field.fontSize.clamp(1, 100),
                  min: 1,
                  max: 100,
                  activeColor: const Color(0xFF7C3AED),
                  inactiveColor: Colors.white12,
                  onChanged: (v) {
                    field.fontSize = v;
                    _updateField(field);
                  },
                ),
              ),
            ],
          ),

          // Row 4: Style chips
          Row(
            children: [
              _styleChip(field, 'normal', 'عادي'),
              const SizedBox(width: 6),
              _styleChip(field, 'bold', 'عريض'),
              const SizedBox(width: 6),
              _styleChip(field, 'italic', 'مائل'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildValueEditor(TemplateField field) {
    String currentValue;

    switch (field.key) {
      case 'network':
        currentValue = _template!.networkName;
        break;
      case 'limit-uptime':
        currentValue = field.customValue.isNotEmpty
            ? field.customValue
            : '8 يوم';
        break;
      case 'limit-gb':
        currentValue = field.customValue.isNotEmpty
            ? field.customValue
            : '5GB';
        break;
      case 'note1':
      case 'note2':
        currentValue = field.customValue;
        break;
      case 'comment':
        currentValue = field.customValue;
        break;
      default:
        currentValue = field.customValue;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white12),
      ),
      child: TextFormField(
        key: ValueKey('${field.id}_${field.key}'),
        initialValue: currentValue,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
        ),
        decoration: InputDecoration(
          hintText: 'اكتب القيمة...',
          hintStyle: const TextStyle(
            color: Colors.white24,
            fontSize: 12,
          ),
          icon: const Icon(Icons.edit,
              color: Color(0xFFA78BFA), size: 16),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
        onChanged: (v) {
          setState(() {
            if (field.key == 'network') {
              _template!.networkName = v;
            } else {
              field.customValue = v;
              field.isCustom = true;
              final index = _template!.fields
                  .indexWhere((f) => f.id == field.id);
              if (index != -1) {
                _template!.fields[index] = field;
              }
            }
          });
        },
      ),
    );
  }


  Widget _styleChip(TemplateField field, String value, String label) {
    final isSelected = field.fontStyle == value;
    return GestureDetector(
      onTap: () {
        field.fontStyle = value;
        _updateField(field);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF7C3AED)
              : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF7C3AED)
                : Colors.white12,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white70,
            fontSize: 11,
            fontWeight: isSelected
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // Print Button
  // ===========================================================================

  Widget _buildPrintButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
      ),
      child: SizedBox(
        height: 56,
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _printing ? null : _print,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          icon: _printing
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
            _printing
                ? 'جاري التحضير...'
                : '💾 حفظ وطباعة PDF',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}