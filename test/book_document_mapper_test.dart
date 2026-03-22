import 'dart:typed_data';

import 'package:easypub/data/models/book_document_mapper.dart';
import 'package:easypub/data/models/ebook_model.dart';
import 'package:easypub/domain/entities/book_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookDocumentMapper', () {
    test('ebookModelFromDocument round-trips style reference fields', () {
      final now = DateTime(2026, 3, 21, 12);
      final document = BookDocument(
        schemaVersion: 1,
        metadata: BookMetadata(
          id: 'doc-1',
          title: '스타일 라운드트립',
          author: '저자',
          language: 'ko',
          createdAt: now,
          modifiedAt: now,
        ),
        body: const BookBody(
          sourceFormat: 'markdown',
          sourceMarkdown: '# 1장\n\n본문',
        ),
        presentation: BookPresentation(
          templateType: 'novel',
          customCss: 'h1.chapter-title { letter-spacing: 0.08em; }',
          customCssSourceName: 'reference.epub',
          referenceTitle: '참조 EPUB',
          referenceAuthor: '참조 저자',
          importedFonts: [
            ImportedFontAsset(
              fileName: 'font_1.ttf',
              mimeType: 'font/ttf',
              bytes: Uint8List.fromList([1, 2, 3]),
              originalHref: '../Fonts/original.ttf',
            ),
          ],
          structureReference: const [
            StructureReferenceEntry(level: 1, title: '1장'),
            StructureReferenceEntry(level: 2, title: '소절'),
          ],
          styleClassHints: const StyleClassHints(
            headingLevel1: ['chapter-title'],
            paragraph: ['body-copy'],
          ),
        ),
      );

      final ebook = ebookModelFromDocument(
        id: 'ebook-1',
        document: document,
      );
      final restored = ebook.toBookDocument();

      expect(restored.customCssSourceName, 'reference.epub');
      expect(restored.styleReferenceTitle, '참조 EPUB');
      expect(restored.styleReferenceAuthor, '참조 저자');
      expect(restored.importedFonts, hasLength(1));
      expect(restored.structureReference, hasLength(2));
      expect(restored.styleClassHints.headingLevel1, contains('chapter-title'));
      expect(restored.styleClassHints.paragraph, contains('body-copy'));
    });

    test('legacy EbookModel without documentJson restores safely', () {
      final now = DateTime(2026, 3, 21, 12);
      final ebook = EbookModel(
        id: 'legacy-1',
        title: '레거시 문서',
        author: '저자',
        content: '## 장\n\n본문',
        templateType: 'essay',
        createdAt: now,
        modifiedAt: now,
      );

      final restored = ebook.toBookDocument();

      expect(restored.title, '레거시 문서');
      expect(restored.structureReference, isEmpty);
      expect(restored.styleClassHints.isEmpty, isTrue);
      expect(restored.chapters, hasLength(1));
    });
  });
}
