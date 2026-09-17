import 'dart:io';
import 'package:flutter/material.dart';
import 'mikrotik_api.dart';
import 'services/backup_service.dart';

// =============================================================================
// Backup Restore Page
// =============================================================================

class BackupRestorePage extends StatefulWidget {
  final MikroTikApi api;
  final String host;
  final String username;
  final String password;

  const BackupRestorePage({
    super.key,
    required this.api,
    required this.host,
    required this.username,
    required this.password,
  });

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  late final BackupService _service;

  List<FileSystemEntity> _localBackups = [];
  bool _loadingBackups = true;

  // حالة العمليات
  bool _working = false;
  String? _statusMessage;

  @override
  void initState() {
    super.initState();
    _service = BackupService(widget.api);
    _loadLocalBackups();
  }

  Future<void> _loadLocalBackups() async {
    if (!mounted) return;

    setState(() => _loadingBackups = true);

    final files = await _service.getLocalBackups();

    if (!mounted) return;

    setState(() {
      _localBackups = files;
      _loadingBackups = false;
    });
  }

  // ===========================================================================
  // Backup Actions
  // ===========================================================================

  Future<void> _createBinaryBackup() async {
    final fileName = _service.generateBackupFileName(
      prefix: 'backup',
      extension: 'backup',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('📦 نسخة Binary'),
          content: Text(
            'سيتم إنشاء نسخة احتياطية كاملة.\n\n'
                'اسم الملف: $fileName\n\n'
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

    _runOperation(
      operation: () async {
        // 1. إنشاء على الراوتر
        setStatus('جاري إنشاء النسخة على الراوتر...');
        final created = await _service.createBinaryBackup(
          fileName: fileName,
        );

        if (!created) throw Exception('فشل إنشاء النسخة');

        // 2. تحميل على الجوال
        setStatus('جاري التحميل على الجوال...');
        final localPath = await _service.downloadFile(
          host: widget.host,
          username: widget.username,
          password: widget.password,
          remoteFileName: fileName,
        );

        if (localPath == null) throw Exception('فشل التحميل');

        // 3. حذف من الراوتر
        try {
          await widget.api.deleteFile(fileName);
        } catch (_) {}

        return localPath;
      },
      successMessage: 'تم حفظ النسخة بنجاح ✅',
    );
  }

  Future<void> _createRscBackup() async {
    final fileName = _service.generateBackupFileName(
      prefix: 'config',
      extension: 'rsc',
    );

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('📄 تصدير إعدادات (RSC)'),
          content: Text(
            'سيتم تصدير إعدادات الراوتر كأوامر نصية.\n\n'
                'اسم الملف: $fileName\n\n'
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

    _runOperation(
      operation: () async {
        setStatus('جاري تصدير الإعدادات...');
        final created = await _service.createRscBackup(
          fileName: fileName,
        );

        if (!created) throw Exception('فشل التصدير');

        setStatus('جاري التحميل على الجوال...');
        final localPath = await _service.downloadFile(
          host: widget.host,
          username: widget.username,
          password: widget.password,
          remoteFileName: fileName,
        );

        if (localPath == null) throw Exception('فشل التحميل');

        try {
          await widget.api.deleteFile(fileName);
        } catch (_) {}

        return localPath;
      },
      successMessage: 'تم تصدير الإعدادات بنجاح ✅',
    );
  }

  // ===========================================================================
  // Restore Actions
  // ===========================================================================

  Future<void> _restoreBackup(FileSystemEntity entity) async {
    final file = File(entity.path);
    final fileName = file.uri.pathSegments.last;
    final ext = fileName.split('.').last.toLowerCase();

    if (ext != 'backup' && ext != 'rsc') {
      _showMessage('نوع الملف غير مدعوم', isError: true);
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            ext == 'backup'
                ? '⚠️ استعادة نسخة Binary'
                : '📄 استيراد إعدادات (RSC)',
          ),
          content: Text(
            ext == 'backup'
                ? 'سيتم استعادة نسخة Binary كاملة.\n\n'
                '⚠️ تحذير: قد يتم فقدان الإعدادات الحالية!\n\n'
                'هل أنت متأكد؟'
                : 'سيتم استيراد الأوامر من الملف.\n\n'
                'هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.orange,
              ),
              child: const Text('متابعة'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    _runOperation(
      operation: () async {
        setStatus('جاري رفع الملف إلى الراوتر...');

        final uploaded = await _service.uploadFile(
          host: widget.host,
          username: widget.username,
          password: widget.password,
          localPath: entity.path,
          remoteFileName: fileName,
        );

        if (!uploaded) throw Exception('فشل الرفع');

        setStatus('جاري الاستعادة...');

        if (ext == 'backup') {
          await _service.restoreBinaryBackup(fileName: fileName);
        } else {
          await _service.importRscBackup(fileName: fileName);
        }

        // حذف الملف من الراوتر
        try {
          await widget.api.deleteFile(fileName);
        } catch (_) {}

        return 'done';
      },
      successMessage: 'تمت الاستعادة بنجاح ✅\n'
          'قد يفقد الاتصال بالراوتر لبضع ثوان',
    );
  }

  Future<void> _deleteLocal(FileSystemEntity entity) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('حذف النسخة'),
          content: const Text(
            'سيتم حذف الملف من الجوال.\n\n'
                'هل تريد المتابعة؟',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('حذف'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    await _service.deleteLocalBackup(entity.path);
    await _loadLocalBackups();

    if (!mounted) return;
    _showMessage('تم حذف الملف ✅');
  }


  // ===========================================================================
  // Helpers
  // ===========================================================================

  void setStatus(String message) {
    if (!mounted) return;
    setState(() => _statusMessage = message);
  }

  Future<void> _runOperation({
    required Future<String?> Function() operation,
    required String successMessage,
  }) async {
    setState(() {
      _working = true;
      _statusMessage = null;
    });

    try {
      await operation();

      if (!mounted) return;

      _showMessage(successMessage);
      await _loadLocalBackups();
    } catch (e) {
      if (!mounted) return;
      _showMessage('فشل: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _working = false;
          _statusMessage = null;
        });
      }
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
          duration: const Duration(seconds: 4),
        ),
      );
  }

  String _formatDate(DateTime date) {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final h = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$y/$m/$d - $h:$min';
  }

  // ===========================================================================
  // Build
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💾 Backup / Restore'),
        actions: [
          IconButton(
            onPressed: _loadingBackups ? null : _loadLocalBackups,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _working
          ? _buildWorkingView()
          : ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildActionsCard(),
          const SizedBox(height: 12),
          _buildBackupsList(),
        ],
      ),
    );
  }

  Widget _buildWorkingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              _statusMessage ?? 'جاري المعالجة...',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📤 إنشاء نسخة احتياطية',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _createBinaryBackup,
                    icon: const Icon(Icons.archive),
                    label: const Text('Binary'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _createRscBackup,
                    icon: const Icon(Icons.description),
                    label: const Text('RSC'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackupsList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            '📁 النسخ المحفوظة على الجوال',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        if (_loadingBackups)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(),
            ),
          )
        else if (_localBackups.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Center(
                child: Text(
                  'لا توجد نسخ محفوظة',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          )
        else
          ..._localBackups.map((entity) {
            final file = File(entity.path);
            final fileName = file.uri.pathSegments.last;
            final stat = file.statSync();
            final isBinary = fileName.endsWith('.backup');

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor:
                  isBinary ? Colors.blue.shade100 : Colors.green.shade100,
                  child: Icon(
                    isBinary ? Icons.archive : Icons.description,
                    color: isBinary ? Colors.blue : Colors.green,
                  ),
                ),
                title: Text(
                  fileName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                subtitle: Text(
                  '${_formatDate(stat.modified)} • '
                      '${_service.formatSize(stat.size)}',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _restoreBackup(entity),
                      tooltip: 'استعادة',
                      icon: const Icon(Icons.restore, color: Colors.orange),
                    ),
                    IconButton(
                      onPressed: () => _deleteLocal(entity),
                      tooltip: 'حذف',
                      icon: const Icon(Icons.delete, color: Colors.red),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}