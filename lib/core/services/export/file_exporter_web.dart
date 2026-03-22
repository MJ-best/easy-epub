import 'dart:typed_data';
import 'dart:html' as html;

import 'file_exporter.dart';

FileExporter createPlatformFileExporter() => _WebFileExporter();

class _WebFileExporter implements FileExporter {
  @override
  Future<String?> saveBytes({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
  }) async {
    final blob = html.Blob([bytes], mimeType);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = fileName
      ..style.display = 'none';

    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    return null;
  }
}
