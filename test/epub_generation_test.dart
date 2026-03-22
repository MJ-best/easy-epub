import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:easypub/data/services/epub_generator_service_v2.dart';
import 'package:easypub/domain/entities/book_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EpubGeneratorServiceV2', () {
    test('문서 모델과 커스텀 CSS를 EPUB로 생성하고 preview source를 export와 일치시킨다', () async {
      final generator = EpubGeneratorServiceV2();
      final now = DateTime(2026, 3, 21);
      final document = BookDocument(
        schemaVersion: 1,
        metadata: BookMetadata(
          id: 'book-epub-test',
          title: '생성 테스트',
          author: '검수자',
          language: 'ko',
          createdAt: now,
          modifiedAt: now,
        ),
        body: const BookBody(
          sourceFormat: 'markdown',
          sourceMarkdown: '# 1장\n\n본문입니다.\n\n# 2장\n\n다음 장입니다.',
        ),
        presentation: BookPresentation(
          templateType: 'novel',
          customCss:
              '@font-face { font-family: "Imported"; src: url("../Fonts/imported_1.ttf"); }\nbody { color: #654321; font-family: "Imported"; }',
          customCssSourceName: 'reference.epub',
          styleClassHints: const StyleClassHints(
            headingLevel1: ['chapter-title'],
            paragraph: ['body-copy'],
          ),
          importedFonts: [
            ImportedFontAsset(
              fileName: 'imported_1.ttf',
              mimeType: 'font/ttf',
              bytes: Uint8List.fromList([7, 7, 7, 7]),
              originalHref: '../Fonts/original.ttf',
            ),
          ],
        ),
        cover: BookCover(
          fileName: 'cover.jpg',
          mimeType: 'image/jpeg',
          bytes: Uint8List.fromList([8, 6, 7, 5, 3, 0, 9]),
        ),
      );

      final result = await generator.buildEpubFromDocument(document);
      final archive = ZipDecoder().decodeBytes(result.bytes, verify: false);

      expect(result.fileName, '생성 테스트.epub');
      expect(
        _readTextFile(archive, 'OEBPS/Styles/style.css'),
        contains('../Fonts/imported_1.ttf'),
      );
      expect(_readTextFile(archive, 'OEBPS/content.opf'), contains('생성 테스트'));
      expect(_readTextFile(archive, 'OEBPS/content.opf'),
          contains('Fonts/imported_1.ttf'));
      expect(_readTextFile(archive, 'OEBPS/toc.ncx'), contains('2장'));
      expect(_readTextFile(archive, 'OEBPS/Text/chapter01.xhtml'),
          contains('<h1 class="h1 chapter-title">1장</h1>'));
      expect(_readTextFile(archive, 'OEBPS/Text/chapter01.xhtml'),
          contains('본문입니다.'));
      expect(_findFile(archive, 'OEBPS/Text/cover.xhtml'), isNotNull);
      expect(_findFile(archive, 'OEBPS/Images/cover.jpg'), isNotNull);
      expect(_findFile(archive, 'OEBPS/Fonts/imported_1.ttf'), isNotNull);

      final previewSource = await generator.buildPreviewSource(document);
      expect(previewSource.fileName, result.fileName);
      expect(previewSource.bytes, orderedEquals(result.bytes));

      final previewArchive =
          ZipDecoder().decodeBytes(previewSource.bytes, verify: false);
      expect(_readTextFile(previewArchive, 'OEBPS/Styles/style.css'),
          contains('../Fonts/imported_1.ttf'));
      expect(
          _findFile(previewArchive, 'OEBPS/Fonts/imported_1.ttf'), isNotNull);

      final previewBundle = generator.buildPreviewBundle(document);
      expect(previewBundle.htmlDocument, contains('data:font/ttf;base64'));
      expect(previewBundle.htmlDocument, contains('목차'));
      expect(previewBundle.htmlDocument, contains('epub-chapter'));
    });
  });
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
