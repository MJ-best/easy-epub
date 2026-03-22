import 'package:easypub/domain/entities/book_document.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BookDocument', () {
    test('markdown를 챕터와 블록으로 파생한다', () {
      final now = DateTime(2026, 3, 21);
      final document = BookDocument(
        schemaVersion: 1,
        metadata: BookMetadata(
          id: 'book-1',
          title: '테스트 문서',
          author: '작성자',
          language: 'ko',
          createdAt: now,
          modifiedAt: now,
        ),
        body: const BookBody(
          sourceFormat: 'markdown',
          sourceMarkdown:
              '# 시작\n\n## 장면\n첫 문단\n\n> 인용문\n\n# 끝\n\n- 항목 1\n- 항목 2',
        ),
        presentation: const BookPresentation(templateType: 'novel'),
      );

      expect(document.chapters.length, 2);
      expect(document.chapters.first.title, '시작');
      expect(document.chapters.first.blocks[0].type, 'heading');
      expect(document.chapters.first.blocks[1].type, 'paragraph');
      expect(document.chapters.first.blocks[2].type, 'quote');
      expect(document.chapters.last.blocks.single.type, 'list');
    });

    test('구조 참조의 최소 heading level을 기준으로 챕터를 나눈다', () {
      final now = DateTime(2026, 3, 21);
      final document = BookDocument(
        schemaVersion: 1,
        metadata: BookMetadata(
          id: 'book-2',
          title: '구조 참조 문서',
          author: '작성자',
          language: 'ko',
          createdAt: now,
          modifiedAt: now,
        ),
        body: const BookBody(
          sourceFormat: 'markdown',
          sourceMarkdown: '## 1장\n\n첫 문단\n\n### 소절\n\n세부 내용\n\n## 2장\n\n다음 장',
        ),
        presentation: const BookPresentation(
          templateType: 'novel',
          structureReference: [
            StructureReferenceEntry(level: 2, title: '1장'),
            StructureReferenceEntry(level: 3, title: '소절'),
          ],
        ),
      );

      expect(document.chapters, hasLength(2));
      expect(document.chapters.first.title, '1장');
      expect(document.chapters.last.title, '2장');
    });
  });
}
