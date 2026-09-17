import 'package:flutter/material.dart';
import 'models/card_template.dart';
import 'services/template_storage.dart';

// =============================================================================
// Templates Page - إدارة القوالب
// =============================================================================

class TemplatesPage extends StatefulWidget {
  const TemplatesPage({super.key});

  @override
  State<TemplatesPage> createState() => _TemplatesPageState();
}

class _TemplatesPageState extends State<TemplatesPage> {
  final TemplateStorage _storage = TemplateStorage();

  List<CardTemplate> _templates = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    if (!mounted) return;

    setState(() => _loading = true);

    final all = await _storage.loadAll();

    if (!mounted) return;

    setState(() {
      _templates = all;
      _loading = false;
    });
  }

  Future<void> _deleteTemplate(CardTemplate template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف القالب'),
          content: Text(
            'هل تريد حذف القالب "${template.name}" نهائياً؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
              ),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _storage.delete(template.id);
    await _loadTemplates();

    if (!mounted) return;
    _showMessage('تم حذف القالب ✅');
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🎨 قوالب الطباعة'),
        actions: [
          IconButton(
            onPressed: _loadTemplates,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _templates.isEmpty
          ? _buildEmptyState()
          : _buildList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _createNewTemplate,
        icon: const Icon(Icons.add),
        label: const Text('قالب جديد'),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.dashboard_customize,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد قوالب بعد',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'اضغط "قالب جديد" لإنشاء أول قالب طباعة',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),
            FilledButton.icon(
              onPressed: _createNewTemplate,
              icon: const Icon(Icons.add),
              label: const Text('إنشاء قالب جديد'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: const CircleAvatar(
              radius: 25,
              child: Icon(Icons.dashboard_customize),
            ),
            title: Text(
              template.name,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (template.description.isNotEmpty)
                  Text(template.description),
                const SizedBox(height: 4),
                Text(
                  '${template.rows}×${template.cols} • '
                      '${template.cardWidth.toInt()}×${template.cardHeight.toInt()} mm • '
                      '${template.fields.length} حقل',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _editTemplate(template);
                    break;
                  case 'duplicate':
                    _duplicateTemplate(template);
                    break;
                  case 'delete':
                    _deleteTemplate(template);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, size: 20),
                      SizedBox(width: 8),
                      Text('تعديل'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'duplicate',
                  child: Row(
                    children: [
                      Icon(Icons.copy, size: 20),
                      SizedBox(width: 8),
                      Text('نسخ'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 20, color: Colors.red),
                      SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            onTap: () => _editTemplate(template),
          ),
        );
      },
    );
  }

  Future<void> _createNewTemplate() async {
    final now = DateTime.now().millisecondsSinceEpoch.toString();

    final template = CardTemplate(
      id: 'tpl_$now',
      name: 'قالب جديد',
      description: '',
      fields: CardTemplate.defaultFields(),
    );

    await _storage.add(template);
    await _loadTemplates();

    if (!mounted) return;

    // هنا سنفتح شاشة التحرير لاحقاً
    _showMessage('تم إنشاء القالب — سنضيف شاشة التحرير قريباً');
  }

  Future<void> _editTemplate(CardTemplate template) async {
    // هنا سنفتح شاشة التحرير لاحقاً
    _showMessage('شاشة التحرير ستُضاف في المرحلة القادمة');
  }

  Future<void> _duplicateTemplate(CardTemplate template) async {
    final now = DateTime.now().millisecondsSinceEpoch.toString();

    final copy = template.copy();
    copy.id = 'tpl_$now';
    copy.name = '${template.name} (نسخة)';

    await _storage.add(copy);
    await _loadTemplates();

    if (!mounted) return;
    _showMessage('تم نسخ القالب ✅');
  }
}