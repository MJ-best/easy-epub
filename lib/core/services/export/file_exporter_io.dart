import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

import 'file_exporter.dart';

FileExporter createPlatformFileExporter() => _IoFileExporter();

class _IoFileExporter implements FileExporter {
  @override
  Future<String?> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final directory = await getApplicationDocumentsDirectory();
    final sanitizedFileName = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
    final file = File('${directory.path}/$sanitizedFileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}
