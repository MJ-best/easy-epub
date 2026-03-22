import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:easypub/data/models/ebook_model.dart';
import 'package:easypub/data/services/epub_generator_service_v2.dart';
import 'package:easypub/data/services/epub_style_import_service.dart';
import 'package:easypub/domain/repositories/ebook_repository.dart';
import 'package:easypub/presentation/viewmodels/create_book_viewmodel.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeEbookRepository implements EbookRepository {
  EbookModel? _ebook;

  @override
  Future<void> clearAll() async {
    _ebook = null;
  }

  @override
  Future<void> deleteEbook(String id) async {
    if (_ebook?.id == id) {
      _ebook = null;
    }
  }

  @override
  Future<List<EbookModel>> getAllEbooks() async {
    return _ebook == null ? const [] : [_ebook!];
  }

  @override
  Future<EbookModel?> getEbookById(String id) async {
    return _ebook?.id == id ? _ebook : null;
  }

  @override
  Future<List<EbookModel>> searchEbooks(String query) async {
    final ebook = _ebook;
    if (ebook == null) {
      return const [];
    }
    return ebook.title.contains(query) ? [ebook] : const [];
  }

  @override
  Future<void> saveEbook(EbookModel ebook) async {
    _ebook = ebook;
  }

  @override
  Future<void> updateEbook(EbookModel ebook) async {
    _ebook = ebook;
  }
}

void main() {
  group('CreateBookViewModel', () {
    test('previewDocument normalizes metadata and splits chapters', () {
      final viewModel = CreateBookViewModel(
        _FakeEbookRepository(),
        EpubGeneratorServiceV2(),
        EpubStyleImportService(),
      );

      viewModel.setContent('# 1장\n\n첫 문단\n\n# 2장\n\n둘째 문단');

      final previewDocument = viewModel.previewDocument;
      expect(previewDocument.title, '제목 없는 전자책');
      expect(previewDocument.author, 'Unknown');
      expect(previewDocument.chapters, hasLength(2));
      expect(previewDocument.chapters.first.title, '1장');
      expect(previewDocument.chapters.last.title, '2장');
    });

    test(
        'buildPreviewSource matches generated export bytes and preserves imported fonts',
        () async {
      final viewModel = CreateBookViewModel(
        _FakeEbookRepository(),
        EpubGeneratorServiceV2(),
        EpubStyleImportService(),
      );
      final fontBytes = Uint8List.fromList([1, 2, 3, 4, 5, 6]);

      viewModel.setTitle('미리보기 일치');
      viewModel.setAuthor('검수자');
      viewModel.setContent('# 1장\n\n본문입니다.');

      final imported = await viewModel.applyImportedEpubStyle(
        bytes: _buildReferenceEpub(fontBytes),
        sourceName: 'reference.epub',
      );

      expect(imported, isNotNull);
      expect(viewModel.hasImportedFonts, isTrue);

      final previewSource = await viewModel.buildPreviewSource();
      final generated = await viewModel.generateEbook();

      expect(generated, isNotNull);
      expect(previewSource.fileName, generated!.epub.fileName);
      expect(previewSource.bytes, orderedEquals(generated.epub.bytes));

      final archive =
          ZipDecoder().decodeBytes(previewSource.bytes, verify: false);
      expect(_readTextFile(archive, 'OEBPS/Styles/style.css'),
          contains('../Fonts/serif_1.ttf'));
      expect(_findFile(archive, 'OEBPS/Fonts/serif_1.ttf'), isNotNull);
      expect(_readTextFile(archive, 'OEBPS/content.opf'),
          contains('Fonts/serif_1.ttf'));
    });

    test(
        'applyImportedEpubStyle stores style metadata, structure, and class hints',
        () async {
      final viewModel = CreateBookViewModel(
        _FakeEbookRepository(),
        EpubGeneratorServiceV2(),
        EpubStyleImportService(),
      );

      final imported = await viewModel.applyImportedEpubStyle(
        bytes: _buildReferenceEpub(Uint8List.fromList([1, 2, 3])),
        sourceName: 'reference.epub',
      );

      expect(imported, isNotNull);
      expect(viewModel.hasImportedStyle, isTrue);
      expect(viewModel.importedStyleReferenceTitle, '레퍼런스 EPUB');
      expect(viewModel.importedStyleReferenceAuthor, '스타일 저자');
      expect(viewModel.importedFontCount, 1);
      expect(viewModel.structureReference, hasLength(2));
      expect(viewModel.structureReference.first.title, '1장');
      expect(
          viewModel.styleClassHints.headingLevel1, contains('chapter-title'));
      expect(
          viewModel.styleClassHints.headingLevel2, contains('section-title'));
      expect(viewModel.styleClassHints.paragraph, contains('body-copy'));
      expect(viewModel.styleClassHints.unorderedList, contains('bullet-list'));
    });

    test(
        'applyStructureReferenceToDraft creates scaffold and does not overwrite unless requested',
        () async {
      final viewModel = CreateBookViewModel(
        _FakeEbookRepository(),
        EpubGeneratorServiceV2(),
        EpubStyleImportService(),
      );

      await viewModel.applyImportedEpubStyle(
        bytes: _buildReferenceEpub(Uint8List.fromList([4, 5, 6])),
        sourceName: 'reference.epub',
      );

      expect(viewModel.applyStructureReferenceToDraft(), isTrue);
      expect(viewModel.content, contains('# 1장'));
      expect(viewModel.content, contains('## 소절'));
      expect(viewModel.chapterCount, 1);

      viewModel.setContent('# 직접 작성한 장\n\n본문');
      expect(viewModel.applyStructureReferenceToDraft(), isFalse);
      expect(viewModel.content, contains('직접 작성한 장'));

      expect(
        viewModel.applyStructureReferenceToDraft(
          replaceExisting: true,
          includeBodyPlaceholders: false,
        ),
        isTrue,
      );
      expect(viewModel.content.trim(), '# 1장\n\n## 소절');
    });

    test('saveDraft and loadEbook preserve imported style reference fields',
        () async {
      final repository = _FakeEbookRepository();
      final viewModel = CreateBookViewModel(
        repository,
        EpubGeneratorServiceV2(),
        EpubStyleImportService(),
      );

      viewModel.setTitle('라운드트립');
      viewModel.setAuthor('저자');
      await viewModel.applyImportedEpubStyle(
        bytes: _buildReferenceEpub(Uint8List.fromList([7, 8, 9])),
        sourceName: 'reference.epub',
      );
      expect(viewModel.applyStructureReferenceToDraft(), isTrue);

      final saved = await viewModel.saveDraft();
      expect(saved, isNotNull);

      viewModel.reset();
      await viewModel.loadEbook(saved!.id);

      expect(viewModel.title, '라운드트립');
      expect(viewModel.importedStyleSourceName, 'reference.epub');
      expect(viewModel.importedStyleReferenceTitle, '레퍼런스 EPUB');
      expect(viewModel.importedStyleReferenceAuthor, '스타일 저자');
      expect(viewModel.importedFontCount, 1);
      expect(viewModel.structureReference, hasLength(2));
      expect(
          viewModel.styleClassHints.headingLevel1, contains('chapter-title'));
      expect(viewModel.content, contains('# 1장'));
      expect(viewModel.content, contains('## 소절'));
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
  _addFile(archive, 'OPS/content.opf', Uint8List.fromList(utf8.encode(opf)));
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
ul.bullet-list {
  padding-left: 1.8em;
}
body {
  color: #123456;
  font-family: "Imported Serif";
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
        <content src="Text/chapter01.xhtml#section-1"/>
      </navPoint>
    </navPoint>
  </navMap>
</ncx>''')),
  );
  _addFile(archive, 'OPS/Fonts/serif.ttf', fontBytes);

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

String _readTextFile(Archive archive, String path) {
  final file = _findFile(archive, path);
  expect(file, isNotNull);
  final content = file!.content;
  if (content is Uint8List) {
    return utf8.decode(content, allowMalformed: true);
  }
  if (content is List<int>) {
    return utf8.decode(content, allowMalformed: true);
  }
  return '';
}

ArchiveFile? _findFile(Archive archive, String path) {
  for (final file in archive.files) {
    if (file.name == path) {
      return file;
    }
  }
  return null;
}
