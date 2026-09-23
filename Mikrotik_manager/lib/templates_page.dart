import 'package:flutter/material.dart';
import 'models/card_template.dart';
import 'services/template_storage.dart';
import 'print_cards_page.dart';

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final TemplateStorage _storage = TemplateStorage();

  List<CardTemplate> _templates = [];
  bool _loading = true;

  static const String _defaultId = 'default_template';

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    if (!mounted) return;
    setState(() => _loading = true);

    // 📸 الخلفيات المتاحة
    final availableBackgrounds = [
      'assets/templates/template_1.jpg',
      'assets/templates/template_2.jpg',
      'assets/templates/template_3.jpg',
      'assets/templates/template_4.jpg',
      'assets/templates/template_5.jpg',
      'assets/templates/template_6.jpg',
    ];

    final all = await _storage.loadAll();

    if (!mounted) return;

    CardTemplate? defaultTpl;
    final others = <CardTemplate>[];

    for (final t in all) {
      if (t.id == _defaultId) {
        defaultTpl = t;
      } else {
        others.add(t);
      }
    }

    if (defaultTpl == null) {
      defaultTpl = CardTemplate(
        id: _defaultId,
        name: 'القالب الافتراضي',
        description: 'قالب الطباعة الأساسي',
        rows: 16,
        cols: 6,
        cardWidth: 31,
        cardHeight: 17,
        backgroundImage: null,
        fields: CardTemplate.defaultFields(),
      );
      await _storage.add(defaultTpl);
    }

    // 🎨 أنشئ قوالب للخلفيات غير المرتبطة
    for (final bgPath in availableBackgrounds) {
      final exists = others.any((t) => t.backgroundImage == bgPath);
      if (!exists) {
        final id = bgPath.split('/').last.replaceAll('.jpg', '');
        final bgTemplate = CardTemplate(
          id: 'bg_$id',
          name: 'قالب $id',
          description: 'قالب بخلفية',
          rows: 16,
          cols: 6,
          cardWidth: 31,
          cardHeight: 17,
          backgroundImage: bgPath,
          fields: CardTemplate.defaultFields(),
        );
        await _storage.add(bgTemplate);
        others.add(bgTemplate);
      }
    }

    setState(() {
      _templates = [defaultTpl!, ...others];
      _loading = false;
    });
  }

  Future<void> _resetDefault() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.restore, color: Colors.orange),
            SizedBox(width: 8),
            Text('إعادة تعيين'),
          ],
        ),
        content: const Text(
          'سيتم إعادة القالب الافتراضي لحالته الأصلية.\n\nهل تريد المتابعة؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('إعادة تعيين'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final defaultTpl = CardTemplate(
      id: _defaultId,
      name: 'القالب الافتراضي',
      description: 'قالب الطباعة الأساسي',
      rows: 16,
      cols: 6,
      cardWidth: 31,
      cardHeight: 17,
      fields: CardTemplate.defaultFields(),
    );

    await _storage.update(defaultTpl);
    await _loadTemplates();
    if (mounted) _snack('تمت إعادة التعيين ✅');
  }

  Future<void> _deleteTemplate(CardTemplate template) async {
    if (template.id == _defaultId) {
      _snack('لا يمكن حذف القالب الافتراضي', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('حذف القالب'),
          ],
        ),
        content: Text('هل تريد حذف "${template.name}" نهائياً؟'),
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

    await _storage.delete(template.id);
    await _loadTemplates();
    if (mounted) _snack('تم الحذف ✅');
  }

  Future<void> _createNewTemplate() async {
    final now = DateTime.now().millisecondsSinceEpoch.toString();

    final template = CardTemplate(
      id: 'tpl_$now',
      name: 'قالب جديد',
      description: '',
      rows: 16,
      cols: 6,
      cardWidth: 31,
      cardHeight: 17,
      fields: CardTemplate.defaultFields(),
    );

    await _storage.add(template);

    if (!mounted) return;

    // افتح الاستوديو (PrintCardsPage)
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrintCardsPage(
          cards: [],
          networkName: 'MikroTik',
          initialTemplate: template,
        ),
      ),
    );

    if (!mounted) return;
    await _loadTemplates();
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
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
        title: const Text(
          '🎨 قوالب الطباعة',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loadTemplates,
            icon: const Icon(Icons.refresh, color: Color(0xFFA78BFA)),
          ),
        ],
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: Color(0xFFA78BFA)),
      )
          : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTemplate,
        backgroundColor: const Color(0xFF7C3AED),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'قالب جديد',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildList() {
    final defaultTpl = _templates.first;
    final others = _templates.skip(1).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildDefaultCard(defaultTpl),
        const SizedBox(height: 24),
        if (others.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.folder_copy,
                    color: Color(0xFFA78BFA), size: 18),
                SizedBox(width: 8),
                Text(
                  'قوالب أخرى',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ...others.map((t) => _buildTemplateCard(t)),
        ],
        const SizedBox(height: 80),
      ],
    );
  }

  // ===========================================================================
  // Default Template Card
  // ===========================================================================

  Widget _buildDefaultCard(CardTemplate template) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF7C3AED).withValues(alpha: 0.25),
            const Color(0xFF5B21B6).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF7C3AED).withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.star,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'القالب الافتراضي',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(width: 6),
                        Icon(Icons.verified,
                            color: Color(0xFFF59E0B), size: 16),
                      ],
                    ),
                    SizedBox(height: 3),
                    Text(
                      'يُستخدم تلقائياً عند الطباعة',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statPill(
                icon: Icons.table_rows,
                label: '${template.rows} صف',
                color: const Color(0xFF06B6D4),
              ),
              const SizedBox(width: 8),
              _statPill(
                icon: Icons.view_column,
                label: '${template.cols} عمود',
                color: const Color(0xFFF59E0B),
              ),
              const SizedBox(width: 8),
              _statPill(
                icon: Icons.grid_view,
                label: '${template.rows * template.cols} كرت',
                color: const Color(0xFF10B981),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _actionButton(
              icon: Icons.restore,
              label: 'إعادة تعيين القالب',
              color: const Color(0xFFF59E0B),
              onTap: _resetDefault,
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Other Templates
  // ===========================================================================

  Widget _buildTemplateCard(CardTemplate template) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.dashboard_customize,
                color: Color(0xFFA78BFA), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${template.rows}×${template.cols} • ${template.cardWidth.toInt()}×${template.cardHeight.toInt()} mm',
                  style: const TextStyle(
                    color: Colors.white54,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => _deleteTemplate(template),
            icon: const Icon(Icons.delete_outline,
                color: Colors.red, size: 20),
            tooltip: 'حذف',
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // Small Widgets
  // ===========================================================================

  Widget _statPill({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 13),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withValues(alpha: 0.7)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 16),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}