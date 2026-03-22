import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:easypub/data/services/epub_style_import_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EpubStyleImportService', () {
    test('EPUB에서 CSS, 폰트, 구조 참조를 추출하고 이미지는 제외한다', () async {
      final service = EpubStyleImportService();
      final fontBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6]);
      final epubBytes = _buildReferenceEpub(fontBytes);

      final imported = await service.importFromBytes(
        epubBytes: epubBytes,
        sourceName: 'reference.epub',
      );

      expect(imported.sourceName, 'reference.epub');
      expect(imported.referenceTitle, '레퍼런스 EPUB');
      expect(imported.referenceAuthor, '스타일 저자');
      expect(imported.stylesheet, contains('color: #123456'));
      expect(imported.stylesheet, contains('../Fonts/serif_1.ttf'));
      expect(imported.fonts, hasLength(1));
      expect(imported.fonts.single.bytes, orderedEquals(fontBytes));
      expect(imported.structureReference, hasLength(2));
      expect(imported.structureReference.first.title, '1장');
      expect(imported.styleClassHints.headingLevel1, contains('chapter-title'));
      expect(imported.styleClassHints.headingLevel2, contains('section-title'));
      expect(imported.styleClassHints.paragraph, contains('body-copy'));
      expect(imported.styleClassHints.blockquote, contains('pullquote'));
      expect(imported.styleClassHints.unorderedList, contains('bullet-list'));
      expect(imported.styleClassHints.orderedList, contains('number-list'));
      expect(imported.warnings.join(' '), contains('이미지 기반 CSS 자산'));
    });
  });
}

Uint8List _buildReferenceEpub(Uint8List fontBytes) {
  final archive = Archive();
  final opf = '''<?xml version="1.0" encoding="utf-8"?>
<package version="2.0" xmlns="http://www.idpf.org/2007/opf">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>레퍼런스 EPUB</dc:title>
    <dc:creator>스타일 저자</dc:creator>
  </metadata>
  <manifest>
    <item id="style" href="Styles/reference.css" media-type="text/css"/>
    <item id="toc" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="font-main" href="Fonts/serif.ttf" media-type="font/ttf"/>
    <item id="texture" href="Images/paper.png" media-type="image/png"/>
  </manifest>
</package>''';

  _addFile(
    archive,
    'mimetype',
    Uint8List.fromList(utf8.encode('application/epub+zip')),
    compress: false,
  );
  _addFile(
    archive,
    'META-INF/container.xml',
    Uint8List.fromList(
      utf8.encode('''<?xml version="1.0" encoding="UTF-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>'''),
    ),
  );
  _addFile(
    archive,
    'OPS/content.opf',
    Uint8List.fromList(utf8.encode(opf)),
  );
  _addFile(
    archive,
    'OPS/Styles/reference.css',
    Uint8List.fromList(
      utf8.encode('''
@font-face {
  font-family: "Imported Serif";
  src: url("../Fonts/serif.ttf");
}
h1.chapter-title {
  letter-spacing: 0.08em;
}
h2.section-title {
  margin-top: 2em;
}
p.body-copy {
  text-indent: 1em;
}
blockquote.pullquote {
  border-left: 4px solid #171c22;
}
ul.bullet-list {
  padding-left: 1.8em;
}
ol.number-list {
  padding-left: 1.8em;
}
body {
  color: #123456;
  font-family: "Imported Serif";
  background-image: url("../Images/paper.png");
}'''),
    ),
  );
  _addFile(
    archive,
    'OPS/toc.ncx',
    Uint8List.fromList(utf8.encode('''<?xml version="1.0" encoding="utf-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1">
  <navMap>
    <navPoint id="nav-1" playOrder="1">
      <navLabel><text>1장</text></navLabel>
      <content src="Text/chapter01.xhtml"/>
      <navPoint id="nav-2" playOrder="2">
        <navLabel><text>소절</text></navLabel>
        <content src="Text/chapter01.xhtml#section"/>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>''')),
  );
  _addFile(archive, 'OPS/Fonts/serif.ttf', fontBytes);
  _addFile(archive, 'OPS/Images/paper.png', Uint8List.fromList([8, 8, 8]));

  final zipData = ZipEncoder().encode(archive)!;
  return Uint8List.fromList(zipData);
}

void _addFile(
  Archive archive,
  String path,
  Uint8List bytes, {
  bool compress = true,
}) {
  final file = ArchiveFile(path, bytes.length, bytes);
  file.compress = compress;
  archive.addFile(file);
}
