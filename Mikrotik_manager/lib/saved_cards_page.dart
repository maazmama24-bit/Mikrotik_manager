import 'package:flutter/material.dart';
import 'models/saved_card.dart';
import 'services/saved_cards_storage.dart';
import 'print_cards_page.dart';

// =============================================================================
// Saved Cards Page - كروتي المحفوظة
// =============================================================================

class SavedCardsPage extends StatefulWidget {
  const SavedCardsPage({super.key});

  @override
  State<SavedCardsPage> createState() => _SavedCardsPageState();
}

class _SavedCardsPageState extends State<SavedCardsPage> {
  final SavedCardsStorage _storage = SavedCardsStorage();

  List<SavedGroup> _groups = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (!mounted) return;

    setState(() => _loading = true);

    final all = await _storage.loadAll();

    if (!mounted) return;

    setState(() {
      _groups = all;
      _loading = false;
    });
  }

  Future<void> _deleteGroup(SavedGroup group) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف المجموعة'),
          content: Text(
            'هل تريد حذف المجموعة "${group.name}" نهائياً؟\n\n'
                'سيتم حذف ${group.count} كرت من التطبيق (لن تُحذف من الراوتر).',
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

    await _storage.delete(group.id);
    await _loadGroups();

    if (!mounted) return;
    _showMessage('تم حذف المجموعة ✅');
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('⚠️ حذف كل المجموعات'),
          content: const Text(
            'سيتم حذف جميع المجموعات المحفوظة.\n\n'
                'لا يمكن التراجع عن هذا الإجراء.\n\n'
                'هل أنت متأكد؟',
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
              child: const Text('حذف الكل'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _storage.deleteAll();
    await _loadGroups();

    if (!mounted) return;
    _showMessage('تم حذف جميع المجموعات ✅');
  }

  void _openGroup(SavedGroup group) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SavedGroupDetailsPage(group: group),
      ),
    ).then((_) => _loadGroups());
  }

  void _printGroup(SavedGroup group) {
    final printCards = group.cards
        .map((c) => c.toPrintMap())
        .toList();

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PrintCardsPage(
          cards: printCards,
          networkName: group.networkName.isEmpty
              ? 'MikroTik'
              : group.networkName,
        ),
      ),
    );
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
        title: const Text('📁 كروتي المحفوظة'),
        actions: [
          IconButton(
            onPressed: _loadGroups,
            icon: const Icon(Icons.refresh),
          ),
          if (_groups.isNotEmpty)
            IconButton(
              onPressed: _deleteAll,
              tooltip: 'حذف الكل',
              icon: const Icon(Icons.delete_sweep, color: Colors.red),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _groups.isEmpty
          ? _buildEmptyState()
          : _buildList(),
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
              Icons.folder_open,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            const Text(
              'لا توجد كروت محفوظة',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'عندما تولّد كروتاً جديدة، سيتم حفظها هنا تلقائياً',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _groups.length,
      itemBuilder: (context, index) {
        final group = _groups[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _openGroup(group),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 25,
                        child: Icon(Icons.folder),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              group.name,
                              style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              group.displayDate,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _printGroup(group),
                        tooltip: 'طباعة',
                        icon: const Icon(
                          Icons.print,
                          color: Colors.green,
                        ),
                      ),
                      IconButton(
                        onPressed: () => _deleteGroup(group),
                        tooltip: 'حذف',
                        icon: const Icon(
                          Icons.delete,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                  if (group.summary.isNotEmpty) ...[
                    const Divider(),
                    Text(
                      group.summary,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// Saved Group Details Page - تفاصيل المجموعة
// =============================================================================

class SavedGroupDetailsPage extends StatelessWidget {
  final SavedGroup group;

  const SavedGroupDetailsPage({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(group.name),
        actions: [
          IconButton(
            onPressed: () {
              final printCards = group.cards
                  .map((c) => c.toPrintMap())
                  .toList();

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PrintCardsPage(
                    cards: printCards,
                    networkName: group.networkName.isEmpty
                        ? 'MikroTik'
                        : group.networkName,
                  ),
                ),
              );
            },
            tooltip: 'طباعة',
            icon: const Icon(Icons.print),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: Colors.blue.shade50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _infoChip('عدد الكروت', group.count.toString()),
                if (group.profile.isNotEmpty)
                  _infoChip('البروفايل', group.profile),
                if (group.limitGb.isNotEmpty)
                  _infoChip('البيانات', '${group.limitGb} GB'),
                if (group.limitUptime.isNotEmpty)
                  _infoChip('المدة', group.limitUptime),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: group.cards.length,
              itemBuilder: (context, index) {
                final card = group.cards[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListTile(
                    dense: true,
                    leading: CircleAvatar(
                      radius: 15,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),
                    title: Text(
                      card.name,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (card.password.isNotEmpty)
                          Text(
                            'كلمة المرور: ${card.password}',
                            style: const TextStyle(fontSize: 11),
                          ),
                        if (card.limitGb.isNotEmpty)
                          Text(
                            'البيانات: ${card.limitGb} GB',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.blue,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}