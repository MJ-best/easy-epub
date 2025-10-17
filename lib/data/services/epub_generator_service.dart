import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/ebook_model.dart';
import '../models/template_type.dart';

/// Service for generating EPUB files from eBook models
class EpubGeneratorService {
  static const Uuid _uuid = Uuid();

  /// Generate EPUB file from eBook model
  /// Returns the file path of generated EPUB
  Future<String> generateEpub(EbookModel ebook) async {
    final tempDir = await getTemporaryDirectory();
    final epubDir = Directory('${tempDir.path}/epub_${_uuid.v4()}');
    await epubDir.create(recursive: true);

    try {
      // Create EPUB directory structure
      await _createEpubStructure(epubDir);

      // Generate content files
      await _generateMimetype(epubDir);
      await _generateContainerXml(epubDir);
      await _generateContentOpf(epubDir, ebook);
      await _generateTocNcx(epubDir, ebook);
      await _generateStylesheet(epubDir, ebook);
      await _generateChapter(epubDir, ebook);

      // Create EPUB archive
      final epubPath = await _createEpubArchive(epubDir, ebook);

      // Clean up temp directory
      await epubDir.delete(recursive: true);

      return epubPath;
    } catch (e) {
      // Clean up on error
      if (await epubDir.exists()) {
        await epubDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Create EPUB directory structure
  Future<void> _createEpubStructure(Directory epubDir) async {
    await Directory('${epubDir.path}/META-INF').create();
    await Directory('${epubDir.path}/OEBPS').create();
    await Directory('${epubDir.path}/OEBPS/css').create();
    await Directory('${epubDir.path}/OEBPS/text').create();
  }

  /// Generate mimetype file
  Future<void> _generateMimetype(Directory epubDir) async {
    final file = File('${epubDir.path}/mimetype');
    await file.writeAsString('application/epub+zip');
  }

  /// Generate META-INF/container.xml
  Future<void> _generateContainerXml(Directory epubDir) async {
    final containerXml = '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';

    final file = File('${epubDir.path}/META-INF/container.xml');
    await file.writeAsString(containerXml);
  }

  /// Generate OEBPS/content.opf
  Future<void> _generateContentOpf(Directory epubDir, EbookModel ebook) async {
    final contentOpf = '''<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="BookId">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>${_escapeXml(ebook.title)}</dc:title>
    <dc:creator>${_escapeXml(ebook.author)}</dc:creator>
    <dc:language>ko</dc:language>
    <dc:identifier id="BookId">${ebook.id}</dc:identifier>
    <dc:date>${ebook.createdAt.toIso8601String()}</dc:date>
    <meta property="dcterms:modified">${DateTime.now().toIso8601String()}</meta>
  </metadata>
  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="css" href="css/style.css" media-type="text/css"/>
    <item id="chapter01" href="text/chapter01.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine toc="ncx">
    <itemref idref="chapter01"/>
  </spine>
</package>''';

    final file = File('${epubDir.path}/OEBPS/content.opf');
    await file.writeAsString(contentOpf);
  }

  /// Generate OEBPS/toc.ncx
  Future<void> _generateTocNcx(Directory epubDir, EbookModel ebook) async {
    final tocNcx = '''<?xml version="1.0" encoding="UTF-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="${ebook.id}"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle>
    <text>${_escapeXml(ebook.title)}</text>
  </docTitle>
  <navMap>
    <navPoint id="navPoint-1" playOrder="1">
      <navLabel>
        <text>${_escapeXml(ebook.title)}</text>
      </navLabel>
      <content src="text/chapter01.xhtml"/>
    </navPoint>
  </navMap>
</ncx>''';

    final file = File('${epubDir.path}/OEBPS/toc.ncx');
    await file.writeAsString(tocNcx);
  }

  /// Generate OEBPS/css/style.css
  Future<void> _generateStylesheet(Directory epubDir, EbookModel ebook) async {
    final template = TemplateType.fromString(ebook.templateType);
    final file = File('${epubDir.path}/OEBPS/css/style.css');
    await file.writeAsString(template.cssStyle);
  }

  /// Generate OEBPS/text/chapter01.xhtml
  Future<void> _generateChapter(Directory epubDir, EbookModel ebook) async {
    final contentHtml = _convertContentToHtml(ebook.content);

    final chapterXhtml = '''<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" lang="ko">
<head>
  <meta charset="UTF-8"/>
  <title>${_escapeXml(ebook.title)}</title>
  <link rel="stylesheet" type="text/css" href="../css/style.css"/>
</head>
<body>
  <h1>${_escapeXml(ebook.title)}</h1>
  $contentHtml
</body>
</html>''';

    final file = File('${epubDir.path}/OEBPS/text/chapter01.xhtml');
    await file.writeAsString(chapterXhtml);
  }

  /// Create EPUB archive (ZIP format)
  Future<String> _createEpubArchive(Directory epubDir, EbookModel ebook) async {
    final encoder = ZipEncoder();
    final archive = Archive();

    // Add files to archive
    await _addDirectoryToArchive(archive, epubDir, epubDir.path);

    // Encode to zip
    final zipData = encoder.encode(archive);
    if (zipData == null) {
      throw Exception('Failed to encode EPUB archive');
    }

    // Save to documents directory
    final docsDir = await getApplicationDocumentsDirectory();
    final epubPath = '${docsDir.path}/${ebook.title}_${ebook.id}.epub';
    final epubFile = File(epubPath);
    await epubFile.writeAsBytes(zipData);

    return epubPath;
  }

  /// Add directory contents to archive recursively
  Future<void> _addDirectoryToArchive(
    Archive archive,
    Directory dir,
    String basePath,
  ) async {
    await for (final entity in dir.list(recursive: false)) {
      if (entity is File) {
        final bytes = await entity.readAsBytes();
        final relativePath = entity.path.substring(basePath.length + 1);
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      } else if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity, basePath);
      }
    }
  }

  /// Convert plain text content to HTML paragraphs
  String _convertContentToHtml(String content) {
    final lines = content.split('\n');
    final buffer = StringBuffer();

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) {
        continue;
      }

      // Detect headings (lines starting with #)
      if (trimmed.startsWith('# ')) {
        buffer.writeln('<h1>${_escapeXml(trimmed.substring(2))}</h1>');
      } else if (trimmed.startsWith('## ')) {
        buffer.writeln('<h2>${_escapeXml(trimmed.substring(3))}</h2>');
      } else {
        buffer.writeln('<p>${_escapeXml(trimmed)}</p>');
      }
    }

    return buffer.toString();
  }

  /// Escape XML special characters
  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
