import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';

import '../../core/models/epub_preview_models.dart';
import '../../domain/entities/book_document.dart';
import '../models/book_document_mapper.dart';
import '../models/ebook_model.dart';
import '../models/template_type.dart';
import 'markdown_parser.dart';

class EpubBuildResult {
  const EpubBuildResult({
    required this.fileName,
    required this.bytes,
  });

  final String fileName;
  final Uint8List bytes;
}

class EpubPreviewBundle {
  const EpubPreviewBundle({
    required this.htmlDocument,
    required this.stylesheet,
    required this.chapterCount,
  });

  final String htmlDocument;
  final String stylesheet;
  final int chapterCount;
}

class EpubGeneratorServiceV2 {
  Future<EpubBuildResult> buildEpub(EbookModel ebook) async {
    return buildEpubFromDocument(ebook.toBookDocument());
  }

  Future<EpubPreviewSource> buildPreviewSource(BookDocument document) async {
    final epub = await buildEpubFromDocument(document);
    return EpubPreviewSource(
      bytes: epub.bytes,
      fileName: epub.fileName,
    );
  }

  Future<EpubBuildResult> buildEpubFromDocument(BookDocument document) async {
    final archive = Archive();
    final chapters = document.chapters;
    final coverAsset = _buildCoverAsset(document);
    final stylesheet = buildStylesheetForDocument(document);
    final hasExplicitChapters = BookStructureParser.hasExplicitChapters(
      document.rawMarkdown,
      structureReference: document.structureReference,
    );
    final fileName =
        '${_sanitizeFilename(document.title.isEmpty ? 'ebook' : document.title)}.epub';

    _addStoredFile(
      archive,
      'mimetype',
      Uint8List.fromList(utf8.encode('application/epub+zip')),
      compress: false,
    );
    _addStoredFile(
      archive,
      'META-INF/container.xml',
      Uint8List.fromList(utf8.encode(_buildContainerXml())),
    );
    _addStoredFile(
      archive,
      'OEBPS/Styles/style.css',
      Uint8List.fromList(utf8.encode(stylesheet)),
    );
    _addStoredFile(
      archive,
      'OEBPS/toc.ncx',
      Uint8List.fromList(
        utf8.encode(_buildTocNcx(document, chapters, coverAsset != null)),
      ),
    );
    _addStoredFile(
      archive,
      'OEBPS/content.opf',
      Uint8List.fromList(
        utf8.encode(_buildContentOpf(document, chapters, coverAsset)),
      ),
    );

    for (final font in document.importedFonts) {
      _addStoredFile(
        archive,
        'OEBPS/Fonts/${font.fileName}',
        font.bytes,
      );
    }

    if (coverAsset != null) {
      _addStoredFile(
        archive,
        'OEBPS/Images/${coverAsset.fileName}',
        coverAsset.bytes,
      );
      _addStoredFile(
        archive,
        'OEBPS/Text/cover.xhtml',
        Uint8List.fromList(utf8.encode(_buildCoverPage(document, coverAsset))),
      );
    }

    for (var i = 0; i < chapters.length; i++) {
      final chapterId = 'chapter${(i + 1).toString().padLeft(2, '0')}';
      final chapter = chapters[i];
      _addStoredFile(
        archive,
        'OEBPS/Text/$chapterId.xhtml',
        Uint8List.fromList(
          utf8.encode(
            _buildChapterHtml(
              chapter.title,
              chapter.markdown,
              includeVisibleTitle: hasExplicitChapters,
              styleClassHints: document.styleClassHints,
            ),
          ),
        ),
      );
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData == null) {
      throw Exception('EPUB 파일 생성에 실패했습니다.');
    }

    return EpubBuildResult(
      fileName: fileName,
      bytes: Uint8List.fromList(zipData),
    );
  }

  EpubPreviewBundle buildPreviewBundle(
    BookDocument document, {
    bool showTableOfContents = true,
    double textScale = 1.0,
  }) {
    final stylesheet = buildStylesheetForDocument(document);
    final hasExplicitChapters = BookStructureParser.hasExplicitChapters(
      document.rawMarkdown,
      structureReference: document.structureReference,
    );
    final previewStylesheet = _buildPreviewStylesheet(
      stylesheet,
      document.importedFonts,
      textScale: textScale,
    );
    final htmlDocument = _buildPreviewHtmlDocument(
      document,
      stylesheet: previewStylesheet,
      showTableOfContents: showTableOfContents,
      includeVisibleChapterTitles: hasExplicitChapters,
    );

    return EpubPreviewBundle(
      htmlDocument: htmlDocument,
      stylesheet: previewStylesheet,
      chapterCount: document.chapters.length,
    );
  }

  String buildStylesheetForDocument(BookDocument document) {
    return _buildStylesheet(
      TemplateType.fromString(document.templateType),
      importedStylesheet: document.customCss,
    );
  }

  void _addStoredFile(
    Archive archive,
    String path,
    Uint8List bytes, {
    bool compress = true,
  }) {
    final file = ArchiveFile(path, bytes.length, bytes);
    file.compress = compress;
    archive.addFile(file);
  }

  String _buildContainerXml() {
    return '''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''';
  }

  String _buildContentOpf(
    BookDocument document,
    List<BookChapter> chapters,
    _CoverAsset? coverAsset,
  ) {
    final manifestItems = StringBuffer()
      ..writeln(
        '    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>',
      )
      ..writeln(
        '    <item id="style" href="Styles/style.css" media-type="text/css"/>',
      );
    final spineItems = StringBuffer();

    if (coverAsset != null) {
      manifestItems.writeln(
        '    <item id="cover-image" href="Images/${coverAsset.fileName}" media-type="${coverAsset.mimeType}"/>',
      );
      manifestItems.writeln(
        '    <item id="cover-page" href="Text/cover.xhtml" media-type="application/xhtml+xml"/>',
      );
      spineItems.writeln('    <itemref idref="cover-page"/>');
    }

    for (var i = 0; i < chapters.length; i++) {
      final chapterId = 'chapter${(i + 1).toString().padLeft(2, '0')}';
      manifestItems.writeln(
        '    <item id="$chapterId" href="Text/$chapterId.xhtml" media-type="application/xhtml+xml"/>',
      );
      spineItems.writeln('    <itemref idref="$chapterId"/>');
    }

    for (var i = 0; i < document.importedFonts.length; i++) {
      final font = document.importedFonts[i];
      manifestItems.writeln(
        '    <item id="font-${i + 1}" href="Fonts/${font.fileName}" media-type="${font.mimeType}"/>',
      );
    }

    final author =
        document.author.trim().isEmpty ? 'Unknown' : document.author.trim();

    return '''<?xml version="1.0" encoding="utf-8"?>
<package version="2.0" unique-identifier="BookId" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:opf="http://www.idpf.org/2007/opf">
    <dc:title>${_escapeXml(document.title)}</dc:title>
    <dc:creator opf:role="aut">${_escapeXml(author)}</dc:creator>
    <dc:language>${_escapeXml(document.language)}</dc:language>
    <dc:publisher>Easy Epub</dc:publisher>
    <dc:identifier id="BookId" opf:scheme="UUID">urn:uuid:${document.metadata.id}</dc:identifier>
    <dc:date opf:event="publication">${_formatDate(document.metadata.createdAt)}</dc:date>
    <dc:date opf:event="modification">${_formatDate(document.metadata.modifiedAt)}</dc:date>
${coverAsset != null ? '    <meta name="cover" content="cover-image"/>' : ''}
  </metadata>
  <manifest>
$manifestItems  </manifest>
  <spine toc="ncx">
$spineItems  </spine>
</package>''';
  }

  String _buildTocNcx(
    BookDocument document,
    List<BookChapter> chapters,
    bool hasCover,
  ) {
    final navPoints = StringBuffer();
    var order = 1;

    if (hasCover) {
      navPoints.writeln('''    <navPoint id="navPoint-cover" playOrder="$order">
      <navLabel>
        <text>표지</text>
      </navLabel>
      <content src="Text/cover.xhtml"/>
    </navPoint>''');
      order += 1;
    }

    for (var i = 0; i < chapters.length; i++) {
      final chapterId = 'chapter${(i + 1).toString().padLeft(2, '0')}';
      final title = chapters[i].title;
      navPoints
          .writeln('''    <navPoint id="navPoint-${i + 1}" playOrder="$order">
      <navLabel>
        <text>${_escapeXml(title)}</text>
      </navLabel>
      <content src="Text/$chapterId.xhtml"/>
    </navPoint>''');
      order += 1;
    }

    return '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE ncx PUBLIC "-//NISO//DTD ncx 2005-1//EN"
  "http://www.daisy.org/z3986/2005/ncx-2005-1.dtd">
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <head>
    <meta name="dtb:uid" content="urn:uuid:${document.metadata.id}"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="0"/>
    <meta name="dtb:maxPageNumber" content="0"/>
  </head>
  <docTitle>
    <text>${_escapeXml(document.title)}</text>
  </docTitle>
  <navMap>
$navPoints  </navMap>
</ncx>''';
  }

  String _buildStylesheet(
    TemplateType template, {
    String? importedStylesheet,
  }) {
    if (importedStylesheet != null && importedStylesheet.trim().isNotEmpty) {
      return importedStylesheet;
    }

    final base = '''@charset "utf-8";
body {
  margin: 0;
  padding: 0;
  color: #1d1d1f;
  background: #ffffff;
  word-break: keep-all;
}
img {
  max-width: 100%;
  height: auto;
}
.book-cover {
  text-align: center;
  padding: 4em 2em 3em;
}
.book-cover img {
  max-width: 70%;
  margin-bottom: 2em;
}
.book-cover h1 {
  margin-bottom: 0.4em;
}
.book-cover .byline {
  color: #666666;
  font-size: 0.95em;
}
h1.h1, h2.h2, h3.h3 {
  page-break-after: avoid;
}
p.txt, p.txtf, p.txtf1 {
  margin: 0 0 1em;
}
ul.list, ol.list {
  margin: 0.8em 0 1.2em;
  padding-left: 1.6em;
}
table {
  width: 100%;
  border-collapse: collapse;
  margin: 1.2em 0;
}
th, td {
  border: 1px solid #d7d7d7;
  padding: 0.6em;
}
.center {
  text-align: center;
}
blockquote.quote {
  margin: 1.4em 0;
  padding: 0.8em 1em;
  border-left: 4px solid #c9c9c9;
  color: #4a4a4a;
}
.page-break-before {
  page-break-before: always;
}
''';

    switch (template) {
      case TemplateType.novel:
        return '''$base
body {
  font-family: "Georgia", "Noto Serif KR", serif;
  font-size: 1.05em;
  line-height: 1.9;
  padding: 0 1.4em 1.4em;
  text-align: justify;
}
h1.h1, h2.h2 {
  text-align: center;
  font-weight: 700;
}
p.txt, p.txtf, p.txtf1 {
  text-indent: 1em;
}
''';
      case TemplateType.essay:
        return '''$base
body {
  font-family: "Noto Sans KR", "Apple SD Gothic Neo", sans-serif;
  font-size: 1em;
  line-height: 1.75;
  padding: 0 1.3em 1.3em;
  text-align: justify;
}
h1.h1, h2.h2, h3.h3 {
  font-family: "Noto Sans KR", sans-serif;
}
''';
      case TemplateType.manual:
        return '''$base
body {
  font-family: "Noto Sans KR", "Apple SD Gothic Neo", sans-serif;
  font-size: 0.97em;
  line-height: 1.65;
  padding: 0 1.1em 1.1em;
}
h1.h1 {
  padding: 0.4em 0.6em;
  background: #f3f4f6;
  border-left: 4px solid #4f46e5;
}
h2.h2 {
  border-bottom: 2px solid #e5e7eb;
  padding-bottom: 0.25em;
}
code {
  font-family: "Courier New", monospace;
  background: #f3f4f6;
  padding: 0.1em 0.3em;
}
''';
    }
  }

  String _buildCoverPage(BookDocument document, _CoverAsset coverAsset) {
    final title =
        document.title.trim().isEmpty ? '제목 없는 전자책' : document.title.trim();
    final author =
        document.author.trim().isEmpty ? 'Unknown' : document.author.trim();

    return '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>${_escapeXml(title)}</title>
  <link href="../Styles/style.css" type="text/css" rel="stylesheet"/>
</head>
<body>
  <section class="book-cover">
    <img src="../Images/${coverAsset.fileName}" alt="${_escapeXml(title)} 표지"/>
    <h1 class="h1">${_escapeXml(title)}</h1>
    <p class="txt byline">${_escapeXml(author)}</p>
  </section>
  </body>
</html>''';
  }

  String _buildChapterHtml(
    String title,
    String content, {
    bool includeVisibleTitle = false,
    StyleClassHints styleClassHints = const StyleClassHints(),
  }) {
    final contentHtml = MarkdownParser.parseToHtml(
      content,
      options: MarkdownRenderOptions(styleClassHints: styleClassHints),
    );
    final headingHtml = includeVisibleTitle
        ? '<h1 class="${_mergeClasses([
                'h1',
                ...styleClassHints.headingLevel1
              ])}">${_escapeXml(title)}</h1>\n'
        : '';

    return '''<?xml version="1.0" encoding="utf-8"?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.1//EN"
  "http://www.w3.org/TR/xhtml11/DTD/xhtml11.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
  <title>${_escapeXml(title)}</title>
  <link href="../Styles/style.css" type="text/css" rel="stylesheet"/>
</head>
<body>
$headingHtml$contentHtml
</body>
</html>''';
  }

  String _buildPreviewHtmlDocument(
    BookDocument document, {
    required String stylesheet,
    required bool showTableOfContents,
    required bool includeVisibleChapterTitles,
  }) {
    final coverAsset = _buildCoverAsset(document);
    final bodyContent = StringBuffer();

    if (coverAsset != null) {
      bodyContent.writeln(_buildPreviewCoverSection(document, coverAsset));
    }

    if (showTableOfContents) {
      bodyContent.writeln(_buildPreviewTableOfContents(document));
    }

    for (var i = 0; i < document.chapters.length; i++) {
      final chapter = document.chapters[i];
      final chapterHtml = _extractBodyFragment(
        _buildChapterHtml(
          chapter.title,
          chapter.markdown,
          includeVisibleTitle: includeVisibleChapterTitles,
          styleClassHints: document.styleClassHints,
        ),
      );
      final pageBreakClass =
          i == 0 && coverAsset == null ? '' : ' page-break-before';
      bodyContent.writeln(
        '<section id="${_sanitizeHtmlId(chapter.id)}" class="epub-chapter$pageBreakClass">$chapterHtml</section>',
      );
    }

    return '''<!DOCTYPE html>
<html lang="${_escapeXml(document.language)}">
<head>
  <meta charset="utf-8"/>
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>${_escapeXml(document.title)}</title>
  <style>
$stylesheet
html, body {
  margin: 0;
  padding: 0;
  background: transparent;
}
body {
  min-height: 100vh;
}
nav.preview-toc {
  margin: 0 0 2rem;
}
nav.preview-toc h2 {
  margin-bottom: 0.8rem;
}
nav.preview-toc ol {
  list-style: none;
  margin: 0;
  padding: 0;
}
nav.preview-toc li {
  margin: 0 0 0.35rem;
}
section.epub-chapter {
  display: block;
}
  </style>
</head>
<body>
$bodyContent
</body>
</html>''';
  }

  String _buildPreviewStylesheet(
    String stylesheet,
    List<ImportedFontAsset> fonts, {
    required double textScale,
  }) {
    var previewStylesheet = stylesheet.replaceFirst(
      RegExp(r'^\s*@charset\s+"utf-8";\s*', caseSensitive: false),
      '',
    );
    for (final font in fonts) {
      previewStylesheet = previewStylesheet.replaceAll(
        '../Fonts/${font.fileName}',
        font.dataUri,
      );
    }

    final scalePercent = (textScale * 100).toStringAsFixed(0);
    return '@charset "utf-8";\nhtml { font-size: $scalePercent%; }\n$previewStylesheet';
  }

  String _buildPreviewTableOfContents(BookDocument document) {
    final entries = MarkdownParser.extractTableOfContents(document.rawMarkdown);
    if (entries.isEmpty) {
      return '';
    }

    final buffer = StringBuffer()
      ..writeln('<nav class="preview-toc">')
      ..writeln('<h2 class="h2">목차</h2>')
      ..writeln('<ol>');

    for (final entry in entries) {
      buffer.writeln(
        '<li style="padding-left:${(entry.level - 1) * 1.1}rem">${_escapeXml(entry.title)}</li>',
      );
    }

    buffer
      ..writeln('</ol>')
      ..writeln('</nav>');
    return buffer.toString();
  }

  String _buildPreviewCoverSection(
      BookDocument document, _CoverAsset coverAsset) {
    final title =
        document.title.trim().isEmpty ? '제목 없는 전자책' : document.title.trim();
    final author =
        document.author.trim().isEmpty ? 'Unknown' : document.author.trim();
    final imageDataUri =
        'data:${coverAsset.mimeType};base64,${base64Encode(coverAsset.bytes)}';

    return '''<section class="book-cover">
  <img src="$imageDataUri" alt="${_escapeXml(title)} 표지"/>
  <h1 class="h1">${_escapeXml(title)}</h1>
  <p class="txt byline">${_escapeXml(author)}</p>
</section>''';
  }

  String _extractBodyFragment(String htmlDocument) {
    final match = RegExp(
      r'<body[^>]*>([\s\S]*?)</body>',
      caseSensitive: false,
    ).firstMatch(htmlDocument);
    return match?.group(1)?.trim() ?? htmlDocument;
  }

  _CoverAsset? _buildCoverAsset(BookDocument document) {
    final bytes = document.coverBytes;
    if (bytes == null || bytes.isEmpty) {
      return null;
    }

    final mimeType = _normalizeMimeType(document.coverMimeType);
    final extension = switch (mimeType) {
      'image/png' => 'png',
      'image/webp' => 'webp',
      _ => 'jpg',
    };

    return _CoverAsset(
      fileName: 'cover.$extension',
      mimeType: mimeType,
      bytes: bytes,
    );
  }

  String _normalizeMimeType(String? mimeType) {
    final value = mimeType?.toLowerCase() ?? '';
    if (value.contains('png')) {
      return 'image/png';
    }
    if (value.contains('webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _sanitizeFilename(String filename) {
    return filename.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
  }

  String _sanitizeHtmlId(String value) {
    return value.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '-');
  }

  String _mergeClasses(List<String> classes) {
    return classes
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .join(' ');
  }

  String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}

class _CoverAsset {
  const _CoverAsset({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}
