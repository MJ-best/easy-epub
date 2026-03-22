import 'dart:typed_data';

import 'file_exporter.dart';

FileExporter createPlatformFileExporter() => _UnsupportedFileExporter();

class _UnsupportedFileExporter implements FileExporter {
  @override
  Future<String?> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) {
    throw UnsupportedError('File export is not supported on this platform.');
  }
}
