import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'models/card_template.dart';
import 'services/template_storage.dart';

class TemplateEditorPage extends StatefulWidget {
  final CardTemplate template;
  final List<Map<String, String>>? cards;
  final bool isNewTemplate;

  const TemplateEditorPage({
    super.key,
    required this.template,
    this.cards,
    this.isNewTemplate = false,
  });

  @override
  State<TemplateEditorPage> createState() => _TemplateEditorPageState();
}
class _TemplateEditorPageState extends State<TemplateEditorPage> {
  final TemplateStorage _storage = TemplateStorage();

  late CardTemplate _template;
  String? _selectedFieldId;
  bool _saving = false;
  bool _printing = false;

  @override
  void initState() {
    super.initState();
    _template = widget.template.copy();
  }

  Future<void> _save() async {
    setState(() => _saving = true);

    try {
      if (widget.isNewTemplate) {
        await _storage.add(_template);
      } else {
        final exists = await _storage.getById(_template.id);
        if (exists != null) {
          await _storage.update(_template);
        } else {
          await _storage.add(_template);
        }
      }

      if (!mounted) return;
      _snack('تم حفظ القالب ✅');
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      _snack('فشل: $e', isError: true);
    }
  }

  Future<void> _print() async {
    final cards = widget.cards;
    if (cards == null || cards.isEmpty) {
      _snack('لا توجد كروت للطباعة', isError: true);
      return;
    }

    setState(() => _printing = true);

    try {
      await _storage.saveAll([_template]);
      await _printPdf(cards);
    } catch (e) {
      if (!mounted) return;
      _snack('فشل: $e', isError: true);
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _printPdf(List<Map<String, String>> cards) async {
    final doc = pw.Document();
    final perPage = _template.rows * _template.cols;

    final pages = <List<Map<String, String>>>[];
    for (int i = 0; i < cards.length; i += perPage) {
      final end = (i + perPage > cards.length) ? cards.length : i + perPage;
      pages.add(cards.sublist(i, end));
    }

    for (final pageCards in pages) {
      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(8),
          build: (context) {
            return pw.Wrap(
              spacing: 2,
              runSpacing: 2,
              children: pageCards.map((card) {
                return pw.SizedBox(
                  width: _template.cardWidth * PdfPageFormat.mm,
                  height: _template.cardHeight * PdfPageFormat.mm,
                  child: _buildPdfCard(card),
                );
              }).toList(),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(onLayout: (format) async => doc.save());
  }

  pw.Widget _buildPdfCard(Map<String, String> card) {
    final visibleFields = _template.fields.where((f) => f.visible).toList();
    final cardW = _template.cardWidth * PdfPageFormat.mm;
    final cardH = _template.cardHeight * PdfPageFormat.mm;

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.5),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: pw.Stack(
        children: visibleFields.map((field) {
          final value = _fieldValueForPdf(field, card);
          if (value.isEmpty) return pw.SizedBox();

          return pw.Positioned(
            left: field.x * cardW - 40,
            top: field.y * cardH - 5,
            child: pw.SizedBox(
              width: 80,
              child: pw.Text(
                value,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(
                  fontSize: field.fontSize * 0.7,
                  fontWeight:
                  field.fontStyle.toLowerCase().contains('bold')
                      ? pw.FontWeight.bold
                      : pw.FontWeight.normal,
                  fontStyle:
                  field.fontStyle.toLowerCase().contains('italic')
                      ? pw.FontStyle.italic
                      : pw.FontStyle.normal,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _fieldValueForPdf(TemplateField field, Map<String, String> card) {
    if (field.isCustom) return field.customValue;

    switch (field.key) {
      case 'network':
        return _template.networkName;
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
    final index = _template.fields.indexWhere((f) => f.id == updated.id);
    if (index == -1) return;
    setState(() {
      _template.fields[index] = updated;
    });
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: isError ? Colors.red : const Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  void _openFieldSettings(TemplateField field) {
    setState(() => _selectedFieldId = field.id);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          padding: const EdgeInsets.all(20),
          height: 480,
          child: Column(
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.tune, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      field.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close, color: Colors.white54),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView(
                  children: [
                    _sliderItem(
                      label: 'حجم الخط',
                      value: field.fontSize,
                      min: 6,
                      max: 40,
                      onChanged: (v) {
                        field.fontSize = v;
                        _updateField(field);
                        setSheet(() {});
                      },
                    ),
                    const SizedBox(height: 12),
                    _styleSelector(field, setSheet),
                    const SizedBox(height: 16),
                    _visibilityToggle(field, setSheet),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sliderItem({
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                value.toStringAsFixed(0),
                style: const TextStyle(
                  color: Color(0xFFA78BFA),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          activeColor: const Color(0xFF7C3AED),
          inactiveColor: Colors.white12,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _styleSelector(TemplateField field, StateSetter setSheet) {
    final styles = [
      {'value': 'normal', 'label': 'عادي'},
      {'value': 'bold', 'label': 'عريض'},
      {'value': 'italic', 'label': 'مائل'},
      {'value': 'boldItalic', 'label': 'عريض مائل'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('نمط الخط',
            style: TextStyle(color: Colors.white70, fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: styles.map((s) {
            final isSelected = field.fontStyle == s['value'];
            return GestureDetector(
              onTap: () {
                field.fontStyle = s['value']!;
                _updateField(field);
                setSheet(() {});
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF7C3AED)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color:
                    isSelected ? const Color(0xFF7C3AED) : Colors.white12,
                  ),
                ),
                child: Text(
                  s['label']!,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 12,
                    fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _visibilityToggle(TemplateField field, StateSetter setSheet) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            field.visible ? Icons.visibility : Icons.visibility_off,
            color: field.visible ? const Color(0xFF10B981) : Colors.white38,
            size: 20,
          ),
          const SizedBox(width: 12),
          const Text('إظهار الحقل',
              style: TextStyle(color: Colors.white, fontSize: 14)),
          const Spacer(),
          Switch(
            value: field.visible,
            activeThumbColor: const Color(0xFF7C3AED),
            onChanged: (v) {
              field.visible = v;
              _updateField(field);
              setSheet(() {});
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('🎨 مصمم القوالب',
            style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            tooltip: 'حفظ',
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFFA78BFA),
              ),
            )
                : const Icon(Icons.save, color: Color(0xFFA78BFA)),
          ),
          if (widget.cards != null)
            IconButton(
              tooltip: 'طباعة',
              onPressed: _printing ? null : _print,
              icon: _printing
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF10B981),
                ),
              )
                  : const Icon(Icons.print, color: Color(0xFF10B981)),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(flex: 5, child: _buildPreviewArea()),
          _buildFieldsList(),
        ],
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Center(
        child: AspectRatio(
          aspectRatio: _template.cardWidth / _template.cardHeight,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final cardW = constraints.maxWidth;
              final cardH = constraints.maxHeight;

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: const Color(0xFF7C3AED), width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: _template.fields
                      .where((f) => f.visible)
                      .map((field) => _buildDraggableField(field, cardW, cardH))
                      .toList(),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDraggableField(
      TemplateField field, double cardW, double cardH) {
    final isSelected = _selectedFieldId == field.id;

    return Positioned(
      left: field.x * cardW - 40,
      top: field.y * cardH - 8,
      child: GestureDetector(
        onTap: () => setState(() => _selectedFieldId = field.id),
        onPanUpdate: (details) {
          setState(() {
            final newX = (field.x * cardW + details.delta.dx) / cardW;
            final newY = (field.y * cardH + details.delta.dy) / cardH;
            field.x = newX.clamp(0.0, 1.0);
            field.y = newY.clamp(0.0, 1.0);
            _selectedFieldId = field.id;
          });
        },
        child: Container(
          width: 80,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isSelected
                ? Border.all(color: const Color(0xFF7C3AED), width: 1.5)
                : null,
          ),
          child: Text(
            _displayValue(field),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: field.fontSize * 0.5,
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

    switch (field.key) {
      case 'network':
        return _template.networkName;
      case 'name':
        return '1234567';
      case 'password':
        return '1234567';
      case 'limit-uptime':
        return '8 يوم';
      case 'limit-gb':
        return '5GB';
      case 'comment':
        return 'ملاحظة';
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

  Widget _buildFieldsList() {
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _template.fields.length,
              itemBuilder: (ctx, i) {
                final field = _template.fields[i];
                final isSelected = _selectedFieldId == field.id;

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF7C3AED).withValues(alpha: 0.15)
                        : Colors.white.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF7C3AED)
                          : Colors.transparent,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: field.visible
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.white.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        field.visible ? Icons.visibility : Icons.visibility_off,
                        color: field.visible
                            ? const Color(0xFF10B981)
                            : Colors.white38,
                        size: 18,
                      ),
                    ),
                    title: Text(
                      field.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      'حجم ${field.fontSize.toInt()}',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                    trailing: IconButton(
                      onPressed: () => _openFieldSettings(field),
                      icon: const Icon(Icons.tune,
                          color: Color(0xFFA78BFA), size: 20),
                    ),
                    onTap: () => setState(() => _selectedFieldId = field.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}