import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:path_provider/path_provider.dart';
import '../mikrotik_api.dart';

// =============================================================================
// Backup Service
// =============================================================================

/// خدمة النسخ الاحتياطي والاستعادة عبر SSH/SFTP.
class BackupService {
  final MikroTikApi api;

  BackupService(this.api);

  // ===========================================================================
  // Local Directory
  // ===========================================================================

  /// مجلد حفظ النسخ الاحتياطية على الجوال.
  Future<Directory> _getBackupDir() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final backupDir = Directory('${docsDir.path}/MikroTik_Backups');

    if (!await backupDir.exists()) {
      await backupDir.create(recursive: true);
    }

    return backupDir;
  }

  /// جلب جميع النسخ المحفوظة.
  Future<List<FileSystemEntity>> getLocalBackups() async {
    try {
      final dir = await _getBackupDir();
      final files = await dir.list().toList();

      files.sort((a, b) {
        final statA = a.statSync();
        final statB = b.statSync();
        return statB.modified.compareTo(statA.modified);
      });

      return files;
    } catch (e) {
      return [];
    }
  }

  /// حذف نسخة محلية.
  Future<void> deleteLocalBackup(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  // ===========================================================================
  // SSH Connection
  // ===========================================================================

  /// فتح اتصال SSH.
  Future<SSHClient> _connectSSH({
    required String host,
    required String username,
    required String password,
    int port = 22,
  }) async {
    final socket = await SSHSocket.connect(
      host,
      port,
      timeout: const Duration(seconds: 30),
    );

    final client = SSHClient(
      socket,
      username: username,
      onPasswordRequest: () => password,
    );

    return client;
  }

  // ===========================================================================
  // Create Backup on Router
  // ===========================================================================

  /// إنشاء نسخة Binary على الراوتر.
  Future<bool> createBinaryBackup({
    required String fileName,
    String? password,
  }) async {
    try {
      final result = await api.createBinaryBackup(
        fileName: fileName,
        password: password,
      );

      return result != null;
    } catch (e) {
      throw Exception('فشل إنشاء Binary: $e');
    }
  }

  /// إنشاء نسخة RSC على الراوتر.
  Future<bool> createRscBackup({
    required String fileName,
  }) async {
    try {
      final result = await api.createRscBackup(
        fileName: fileName,
      );

      return result != null;
    } catch (e) {
      throw Exception('فشل تصدير RSC: $e');
    }
  }

  // ===========================================================================
  // Download from Router via SFTP
  // ===========================================================================

  /// تحميل ملف من الراوتر إلى الجوال.
  Future<String?> downloadFile({
    required String host,
    required String username,
    required String password,
    required String remoteFileName,
    int port = 22,
  }) async {
    try {
      final client = await _connectSSH(
        host: host,
        username: username,
        password: password,
        port: port,
      );

      final sftp = await client.sftp();

      final remoteFile = await sftp.open(remoteFileName);
      final data = await remoteFile.readBytes();

      final dir = await _getBackupDir();
      final localPath = '${dir.path}/$remoteFileName';

      final localFile = File(localPath);
      await localFile.writeAsBytes(data);

      sftp.close();
      client.close();

      return localPath;
    } catch (e) {
      throw Exception('فشل التحميل: $e');
    }
  }

  // ===========================================================================
  // Upload to Router via SFTP
  // ===========================================================================

  /// رفع ملف من الجوال إلى الراوتر.
  Future<bool> uploadFile({
    required String host,
    required String username,
    required String password,
    required String localPath,
    required String remoteFileName,
    int port = 22,
  }) async {
    try {
      final client = await _connectSSH(
        host: host,
        username: username,
        password: password,
        port: port,
      );

      final sftp = await client.sftp();

      final localFile = File(localPath);
      final data = await localFile.readAsBytes();

      final remoteFile = await sftp.open(
        remoteFileName,
        mode: SftpFileOpenMode.create |
        SftpFileOpenMode.write |
        SftpFileOpenMode.truncate,
      );

      await remoteFile.writeBytes(data);

      sftp.close();
      client.close();

      return true;
    } catch (e) {
      return false;
    }
  }

  // ===========================================================================
  // Restore
  // ===========================================================================

  /// استعادة نسخة Binary.
  Future<void> restoreBinaryBackup({
    required String fileName,
    String? password,
  }) async {
    await api.restoreBinaryBackup(
      fileName: fileName,
      password: password,
    );
  }

  /// استيراد ملف RSC.
  Future<void> importRscBackup({
    required String fileName,
  }) async {
    await api.importRscBackup(fileName: fileName);
  }

  // ===========================================================================
  // Utilities
  // ===========================================================================

  /// توليد اسم ملف بتوقيت.
  String generateBackupFileName({
    required String prefix,
    required String extension,
  }) {
    final now = DateTime.now();
    final y = now.year.toString();
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');

    return '${prefix}_$y$m${d}_$h$min.$extension';
  }

  /// حجم الملف بصيغة مقروءة.
  String formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(2)} MB';
    }
    return '${(bytes / 1024 / 1024 / 1024).toStringAsFixed(2)} GB';
  }
}