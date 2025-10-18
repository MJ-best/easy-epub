import 'package:flutter_test/flutter_test.dart';
import 'package:easypub/data/services/markdown_parser.dart';

void main() {
  group('MarkdownParser 테스트', () {
    test('표 마크다운이 HTML 테이블로 변환됨', () {
      const markdown = '''
| 헤더1 | 헤더2 |
|-------|-------|
| 내용1 | 내용2 |
| 내용3 | 내용4 |
''';

      final html = MarkdownParser.parseToHtml(markdown);

      expect(html.contains('<table'), true);
      expect(html.contains('<thead>'), true);
      expect(html.contains('<tbody>'), true);
      expect(html.contains('<th'), true);
      expect(html.contains('<td'), true);
      expect(html.contains('헤더1'), true);
      expect(html.contains('내용1'), true);
    });

    test('이미지 마크다운이 HTML img 태그로 변환됨', () {
      const markdown = '![테스트 이미지](https://example.com/image.jpg)';

      final html = MarkdownParser.parseToHtml(markdown);

      expect(html.contains('<img'), true);
      expect(html.contains('src='), true);
      expect(html.contains('alt='), true);
      expect(html.contains('https://example.com/image.jpg'), true);
      expect(html.contains('테스트 이미지'), true);
    });

    test('인라인 이미지도 변환됨', () {
      const markdown = '텍스트와 ![이미지](url.jpg) 함께 사용';

      final html = MarkdownParser.parseToHtml(markdown);

      expect(html.contains('<img'), true);
      expect(html.contains('url.jpg'), true);
    });

    test('가운데 정렬 HTML이 유지됨', () {
      const markdown = '<p style="text-align: center;">중앙 정렬</p>';

      final html = MarkdownParser.parseToHtml(markdown);

      expect(html.contains('중앙 정렬'), true);
    });

    test('제목이 올바르게 변환됨', () {
      const markdown = '''
# 제목 1
## 제목 2
### 제목 3
''';

      final html = MarkdownParser.parseToHtml(markdown);

      expect(html.contains('<h1 class="h1">제목 1</h1>'), true);
      expect(html.contains('<h2 class="h2">제목 2</h2>'), true);
      expect(html.contains('<h3 class="h3">제목 3</h3>'), true);
    });

    test('굵게와 기울임이 변환됨', () {
      const markdown = '**굵은 글씨**와 *기울임 글씨*';

      final html = MarkdownParser.parseToHtml(markdown);

      expect(html.contains('<strong>굵은 글씨</strong>'), true);
      expect(html.contains('<em>기울임 글씨</em>'), true);
    });

    test('순서 없는 목록이 변환됨', () {
      const markdown = '''
- 항목 1
- 항목 2
- 항목 3
''';

      final html = MarkdownParser.parseToHtml(markdown);

      expect(html.contains('<ul class="list">'), true);
      expect(html.contains('<li>항목 1</li>'), true);
      expect(html.contains('<li>항목 2</li>'), true);
    });

    test('순서 있는 목록이 변환됨', () {
      const markdown = '''
1. 첫 번째
2. 두 번째
3. 세 번째
''';

      final html = MarkdownParser.parseToHtml(markdown);

      expect(html.contains('<ol class="list">'), true);
      expect(html.contains('<li>첫 번째</li>'), true);
      expect(html.contains('<li>두 번째</li>'), true);
    });

    test('복합 마크다운이 올바르게 변환됨', () {
      const markdown = '''
# 제목

본문 **굵게** *기울임*

| 컬럼1 | 컬럼2 |
|-------|-------|
| A     | B     |

![이미지](test.jpg)

- 항목1
- 항목2
''';

      final html = MarkdownParser.parseToHtml(markdown);

      // 모든 요소가 포함되어 있는지 확인
      expect(html.contains('<h1'), true);
      expect(html.contains('<strong>'), true);
      expect(html.contains('<em>'), true);
      expect(html.contains('<table'), true);
      expect(html.contains('<img'), true);
      expect(html.contains('<ul'), true);
    });

    test('링크가 올바르게 변환됨', () {
      const markdown = '[링크 텍스트](https://example.com)';

      final html = MarkdownParser.parseToHtml(markdown);

      expect(html.contains('<a href='), true);
      expect(html.contains('https://example.com'), true);
      expect(html.contains('링크 텍스트'), true);
    });

    test('인라인 코드가 변환됨', () {
      const markdown = '이것은 `코드`입니다.';

      final html = MarkdownParser.parseToHtml(markdown);

      expect(html.contains('<code>코드</code>'), true);
    });

    test('특수 문자가 이스케이프됨', () {
      const markdown = '< > & " \'';

      final html = MarkdownParser.parseToHtml(markdown);

      expect(html.contains('&lt;'), true);
      expect(html.contains('&gt;'), true);
      expect(html.contains('&amp;'), true);
      expect(html.contains('&quot;'), true);
      expect(html.contains('&apos;'), true);
    });
  });
}
