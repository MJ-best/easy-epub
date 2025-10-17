import 'dart:io';
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/ebook_model.dart';
import 'markdown_parser.dart';

/// Improved EPUB 2.0 generator service matching real EPUB structure
class EpubGeneratorServiceV2 {
  static const Uuid _uuid = Uuid();

  /// Generate EPUB 2.0 file from eBook model
  Future<String> generateEpub(EbookModel ebook) async {
    final tempDir = await getTemporaryDirectory();
    final epubDir = Directory('${tempDir.path}/epub_${_uuid.v4()}');
    await epubDir.create(recursive: true);

    try {
      // Create EPUB 2.0 structure
      await _createEpubStructure(epubDir);

      // Generate files
      await _generateMimetype(epubDir);
      await _generateContainerXml(epubDir);
      await _generateContentOpf(epubDir, ebook);
      await _generateTocNcx(epubDir, ebook);
      await _generateStylesheet(epubDir, ebook);
      await _generateChapterFiles(epubDir, ebook);

      // Create EPUB archive
      final epubPath = await _createEpubArchive(epubDir, ebook);

      // Clean up
      await epubDir.delete(recursive: true);

      return epubPath;
    } catch (e) {
      if (await epubDir.exists()) {
        await epubDir.delete(recursive: true);
      }
      rethrow;
    }
  }

  /// Create proper EPUB 2.0 directory structure
  Future<void> _createEpubStructure(Directory epubDir) async {
    await Directory('${epubDir.path}/META-INF').create();
    await Directory('${epubDir.path}/OEBPS').create();
    await Directory('${epubDir.path}/OEBPS/Styles').create();
    await Directory('${epubDir.path}/OEBPS/Text').create();
  }

  /// Generate mimetype (must be first file, uncompressed)
  Future<void> _generateMimetype(Directory epubDir) async {
    final file = File('${epubDir.path}/mimetype');
    await file.writeAsString('application/epub+zip', flush: true);
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

  /// Generate EPUB 2.0 compliant content.opf
  Future<void> _generateContentOpf(Directory epubDir, EbookModel ebook) async {
    final chapters = _splitIntoChapters(ebook.content);

    final manifestItems = StringBuffer();
    final spineItems = StringBuffer();

    // Add NCX and CSS
    manifestItems.writeln('    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>');
    manifestItems.writeln('    <item id="style" href="Styles/style.css" media-type="text/css"/>');

    // Add chapter files
    for (var i = 0; i < chapters.length; i++) {
      final chapterId = 'chapter${(i + 1).toString().padLeft(2, '0')}';
      manifestItems.writeln('    <item id="$chapterId" href="Text/$chapterId.html" media-type="application/xhtml+xml"/>');
      spineItems.writeln('    <itemref idref="$chapterId"/>');
    }

    final contentOpf = '''<?xml version="1.0" encoding="utf-8"?>
<package version="2.0" unique-identifier="BookId" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:title>${_escapeXml(ebook.title)}</dc:title>
    <dc:creator opf:role="aut">${_escapeXml(ebook.author)}</dc:creator>
    <dc:language>ko</dc:language>
    <dc:identifier id="BookId" opf:scheme="UUID">urn:uuid:${ebook.id}</dc:identifier>
    <dc:date opf:event="publication">${_formatDate(ebook.createdAt)}</dc:date>
    <dc:date opf:event="modification">${_formatDate(ebook.modifiedAt)}</dc:date>
  </metadata>
  <manifest>
$manifestItems  </manifest>
  <spine toc="ncx">
$spineItems  </spine>
</package>''';

    final file = File('${epubDir.path}/OEBPS/content.opf');
    await file.writeAsString(contentOpf);
  }

  /// Generate NCX navigation file
  Future<void> _generateTocNcx(Directory epubDir, EbookModel ebook) async {
    final chapters = _splitIntoChapters(ebook.content);
    final navPoints = StringBuffer();

    for (var i = 0; i < chapters.length; i++) {
      final chapterId = 'chapter${(i + 1).toString().padLeft(2, '0')}';
      final title = chapters[i]['title'] ?? '챕터 ${i + 1}';
      navPoints.writeln('''    <navPoint id="navPoint-${i + 1}" playOrder="${i + 1}">
      <navLabel>
        <text>${_escapeXml(title)}</text>
      </navLabel>
      <content src="Text/$chapterId.html"/>
    </navPoint>''');
    }

    final tocNcx = '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN"
  "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">

<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="urn:uuid:${ebook.id}"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle>
    <text>${_escapeXml(ebook.title)}</text>
  </docTitle>
  <navMap>
$navPoints  </navMap>
</ncx>''';

    final file = File('${epubDir.path}/OEBPS/toc.ncx');
    await file.writeAsString(tocNcx);
  }

  /// Generate CSS stylesheet matching real EPUB example
  Future<void> _generateStylesheet(Directory epubDir, EbookModel ebook) async {
    final css = '''@charset "utf-8";

/* Korean Typography - Based on Published EPUB */
body {
  font-family: "KoPub Batang", "Noto Serif KR", "Apple SD Gothic Neo", serif;
  font-size: 1em;
  line-height: 1.8em;
  margin: 1.5em;
  padding: 0;
  color: #000;
  text-align: justify;
  word-break: keep-all;
  word-wrap: break-word;
}

/* Headings - Professional Book Style */
h1.h1 {
  font-family: "KoPub Dotum", "Noto Sans KR", sans-serif;
  font-size: 1.6em;
  font-weight: bold;
  line-height: 1.5em;
  margin: 2em 0 1em 0;
  padding: 0;
  text-align: left;
  color: #000;
  letter-spacing: -0.02em;
  page-break-after: avoid;
}

h2.h2 {
  font-family: "KoPub Dotum", "Noto Sans KR", sans-serif;
  font-size: 1.3em;
  font-weight: bold;
  line-height: 1.5em;
  margin: 1.5em 0 0.8em 0;
  padding: 0;
  text-align: left;
  color: #000;
  letter-spacing: -0.02em;
  page-break-after: avoid;
}

h3.h3 {
  font-family: "KoPub Dotum", "Noto Sans KR", sans-serif;
  font-size: 1.1em;
  font-weight: bold;
  line-height: 1.5em;
  margin: 1.3em 0 0.6em 0;
  padding: 0;
  text-align: left;
  color: #000;
  letter-spacing: -0.02em;
}

/* Paragraphs - Book Typography */
p.txt {
  font-size: 1em;
  font-style: normal;
  line-height: 1.8em;
  margin: 0;
  padding: 0;
  text-align: justify;
  text-indent: 0;
  letter-spacing: -0.02em;
  word-spacing: 0;
}

p.txt.bl {
  margin-bottom: 1em;
}

p.txtf {
  font-size: 1em;
  font-style: normal;
  line-height: 1.8em;
  margin: 0;
  padding: 0;
  text-align: justify;
  text-indent: 0;
  letter-spacing: -0.02em;
}

p.txtf1 {
  font-size: 1.1em;
  font-style: normal;
  font-weight: normal;
  line-height: 1.8em;
  margin: 0;
  padding: 0;
  text-align: justify;
  text-indent: 0;
  letter-spacing: -0.02em;
}

/* Lists - Book Style */
ul.list, ol.list {
  font-size: 1em;
  line-height: 1.8em;
  margin: 0.5em 0;
  padding-left: 2em;
  text-align: justify;
}

ul.list li, ol.list li {
  margin-bottom: 0.3em;
  letter-spacing: -0.02em;
}

/* Inline Elements */
strong {
  font-weight: bold;
}

em {
  font-style: italic;
}

code {
  font-family: "Courier New", "Consolas", monospace;
  font-size: 0.95em;
  background-color: #f5f5f5;
  padding: 0.1em 0.3em;
  border-radius: 2px;
}

/* Links */
a {
  color: #0066cc;
  text-decoration: none;
}

a:hover {
  text-decoration: underline;
}

/* Utility Classes */
.bl {
  display: block;
}

.w100 {
  width: 100%;
}

.icenter {
  text-align: center;
}

.center {
  text-align: center;
}

.right {
  text-align: right;
}

.left {
  text-align: left;
}

/* Line Break */
br {
  content: "";
  display: block;
  margin: 0.5em 0;
}

/* Page Breaks */
.page-break {
  page-break-after: always;
}

.page-break-before {
  page-break-before: always;
}
''';

    final file = File('${epubDir.path}/OEBPS/Styles/style.css');
    await file.writeAsString(css);
  }

  /// Generate chapter HTML files
  Future<void> _generateChapterFiles(Directory epubDir, EbookModel ebook) async {
    final chapters = _splitIntoChapters(ebook.content);

    for (var i = 0; i < chapters.length; i++) {
      final chapterId = 'chapter${(i + 1).toString().padLeft(2, '0')}';
      final title = chapters[i]['title'] ?? ebook.title;
      final content = chapters[i]['content'] ?? '';

      final html = _generateChapterHtml(title, content);
      final file = File('${epubDir.path}/OEBPS/Text/$chapterId.html');
      await file.writeAsString(html);
    }
  }

  /// Generate chapter HTML content
  String _generateChapterHtml(String title, String content) {
    final contentHtml = MarkdownParser.parseToHtml(content);

    return '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">

<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>${_escapeXml(title)}</title>
  <link href="../Styles/style.css" type="text/css" rel="stylesheet"/>
</head>

<body>
$contentHtml
</body>
</html>''';
  }

  /// Split content into chapters based on H1 headings
  List<Map<String, String>> _splitIntoChapters(String content) {
    final chapters = <Map<String, String>>[];
    final lines = content.split('\n');

    String? currentTitle;
    final currentContent = StringBuffer();

    for (final line in lines) {
      if (line.trim().startsWith('# ')) {
        // Save previous chapter
        if (currentTitle != null) {
          chapters.add({
            'title': currentTitle,
            'content': currentContent.toString().trim(),
          });
          currentContent.clear();
        }
        currentTitle = line.trim().substring(2).trim();
      } else {
        currentContent.writeln(line);
      }
    }

    // Save last chapter
    if (currentTitle != null) {
      chapters.add({
        'title': currentTitle,
        'content': currentContent.toString().trim(),
      });
    }

    // If no chapters found, create single chapter
    if (chapters.isEmpty) {
      chapters.add({
        'title': '본문',
        'content': content,
      });
    }

    return chapters;
  }

  /// Create EPUB archive
  Future<String> _createEpubArchive(Directory epubDir, EbookModel ebook) async {
    final archive = Archive();

    // Add mimetype first (uncompressed)
    final mimetypeFile = File('${epubDir.path}/mimetype');
    final mimetypeBytes = await mimetypeFile.readAsBytes();
    final mimetypeArchive = ArchiveFile(
      'mimetype',
      mimetypeBytes.length,
      mimetypeBytes,
    );
    mimetypeArchive.compress = false; // Don't compress mimetype
    archive.addFile(mimetypeArchive);

    // Add all other files
    await _addDirectoryToArchive(archive, epubDir, epubDir.path, excludeMimetype: true);

    // Encode to ZIP
    final encoder = ZipEncoder();
    final zipData = encoder.encode(archive);
    if (zipData == null) {
      throw Exception('Failed to encode EPUB archive');
    }

    // Save to documents directory
    final docsDir = await getApplicationDocumentsDirectory();
    final sanitizedTitle = _sanitizeFilename(ebook.title);
    final epubPath = '${docsDir.path}/$sanitizedTitle.epub';
    final epubFile = File(epubPath);
    await epubFile.writeAsBytes(zipData);

    return epubPath;
  }

  /// Add directory to archive recursively
  Future<void> _addDirectoryToArchive(
    Archive archive,
    Directory dir,
    String basePath, {
    bool excludeMimetype = false,
  }) async {
    await for (final entity in dir.list(recursive: false)) {
      if (entity is File) {
        final relativePath = entity.path.substring(basePath.length + 1);

        // Skip mimetype if already added
        if (excludeMimetype && relativePath == 'mimetype') {
          continue;
        }

        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      } else if (entity is Directory) {
        await _addDirectoryToArchive(archive, entity, basePath, excludeMimetype: excludeMimetype);
      }
    }
  }

  /// Format date for EPUB metadata
  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Sanitize filename
  String _sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
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
