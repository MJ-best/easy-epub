import 'dart:typed_data';

import 'file_exporter_stub.dart'
    if (dart.library.html) 'file_exporter_web.dart'
    if (dart.library.io) 'file_exporter_io.dart';

abstract class FileExporter {
  Future<String?> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  });
}

FileExporter createFileExporter() => createPlatformFileExporter();
