import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:easypub/presentation/create_book/create_book_screen.dart';
import 'package:easypub/presentation/viewmodels/create_book_viewmodel.dart';
import 'package:easypub/domain/repositories/ebook_repository.dart';
import 'package:easypub/data/services/epub_generator_service_v2.dart';
import 'package:easypub/data/services/epub_style_import_service.dart';
import 'package:easypub/data/models/ebook_model.dart';
import 'package:easypub/data/models/template_type.dart';

class _FakeEbookRepository implements EbookRepository {
  @override
  Future<void> clearAll() async {}

  @override
  Future<void> deleteEbook(String id) async {}

  @override
  Future<List<EbookModel>> getAllEbooks() async => [];

  @override
  Future<EbookModel?> getEbookById(String id) async => null;

  @override
  Future<List<EbookModel>> searchEbooks(String query) async => [];

  @override
  Future<void> saveEbook(EbookModel ebook) async {}

  @override
  Future<void> updateEbook(EbookModel ebook) async {}
}

void main() {
  group('CreateBookScreen 편집기 스모크 테스트', () {
    testWidgets('새 전자책 화면의 핵심 편집 도구와 안내 문구를 보여준다', (tester) async {
      final repository = _FakeEbookRepository();
      final epubGenerator = EpubGeneratorServiceV2();
      final viewModel = CreateBookViewModel(
        repository,
        epubGenerator,
        EpubStyleImportService(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<CreateBookViewModel>.value(
          value: viewModel,
          child: const MaterialApp(home: CreateBookScreen()),
        ),
      );

      // 제목 입력
      await tester.enterText(
        find.widgetWithText(TextField, '전자책 제목'),
        '테스트 전자책',
      );

      // 본문 입력 (마크다운 포함)
      final contentField = find.widgetWithText(
          TextField, '마크다운으로 작성하세요\n\n# 제목\n## 부제목\n본문 내용...');
      await tester.enterText(
        contentField,
        '# 제목 1\n\n본문 내용입니다.\n\n**굵은 글씨**와 *기울임*\n\n- 목록1\n- 목록2',
      );

      await tester.pumpAndSettle();

      expect(find.text('스타일 레퍼런스'), findsOneWidget);
      expect(find.textContaining('CSS와 폰트'), findsOneWidget);
      expect(viewModel.content.contains('# 제목 1'), isTrue);
    });

    testWidgets('템플릿 선택이 viewModel 상태를 갱신한다', (tester) async {
      final repository = _FakeEbookRepository();
      final epubGenerator = EpubGeneratorServiceV2();
      final viewModel = CreateBookViewModel(
        repository,
        epubGenerator,
        EpubStyleImportService(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<CreateBookViewModel>.value(
          value: viewModel,
          child: const MaterialApp(home: CreateBookScreen()),
        ),
      );

      // 초기 템플릿 확인
      expect(viewModel.selectedTemplate, TemplateType.novel);

      // 템플릿 변경
      viewModel.selectTemplate(TemplateType.essay);
      await tester.pumpAndSettle();

      expect(viewModel.selectedTemplate, TemplateType.essay);
    });

    testWidgets('본문 편집 필드 입력은 viewModel에 반영된다', (tester) async {
      final repository = _FakeEbookRepository();
      final epubGenerator = EpubGeneratorServiceV2();
      final viewModel = CreateBookViewModel(
        repository,
        epubGenerator,
        EpubStyleImportService(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<CreateBookViewModel>.value(
          value: viewModel,
          child: const MaterialApp(home: CreateBookScreen()),
        ),
      );

      // 표 마크다운 입력
      final contentField = find.widgetWithText(
          TextField, '마크다운으로 작성하세요\n\n# 제목\n## 부제목\n본문 내용...');
      await tester.enterText(
        contentField,
        '| 헤더1 | 헤더2 |\n|-------|-------|\n| 내용1 | 내용2 |',
      );

      await tester.pumpAndSettle();

      expect(viewModel.content.contains('| 헤더1 | 헤더2 |'), isTrue);
    });

    testWidgets('이미지 마크다운 문자열도 초안에 유지된다', (tester) async {
      final repository = _FakeEbookRepository();
      final epubGenerator = EpubGeneratorServiceV2();
      final viewModel = CreateBookViewModel(
        repository,
        epubGenerator,
        EpubStyleImportService(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<CreateBookViewModel>.value(
          value: viewModel,
          child: const MaterialApp(home: CreateBookScreen()),
        ),
      );

      // 이미지 마크다운 입력
      final contentField = find.widgetWithText(
          TextField, '마크다운으로 작성하세요\n\n# 제목\n## 부제목\n본문 내용...');
      await tester.enterText(
        contentField,
        '![테스트 이미지](https://example.com/image.jpg)',
      );

      await tester.pumpAndSettle();

      expect(viewModel.content.contains('!['), isTrue);
      expect(viewModel.content.contains(']('), isTrue);
    });

    testWidgets('편집 도구와 스타일 가져오기 버튼이 노출된다', (tester) async {
      final repository = _FakeEbookRepository();
      final epubGenerator = EpubGeneratorServiceV2();
      final viewModel = CreateBookViewModel(
        repository,
        epubGenerator,
        EpubStyleImportService(),
      );

      await tester.pumpWidget(
        ChangeNotifierProvider<CreateBookViewModel>.value(
          value: viewModel,
          child: const MaterialApp(home: CreateBookScreen()),
        ),
      );

      await tester.pumpAndSettle();

      // 굵게 버튼 찾기
      final boldButton = find.byTooltip('굵게');
      expect(boldButton, findsOneWidget);

      // 기울임 버튼 찾기
      final italicButton = find.byTooltip('기울임');
      expect(italicButton, findsOneWidget);

      // 제목 버튼 찾기
      final headingButton = find.byTooltip('제목');
      expect(headingButton, findsOneWidget);

      // 목록 버튼 찾기
      final listButton = find.byTooltip('목록');
      expect(listButton, findsOneWidget);

      // 표 버튼 찾기
      final tableButton = find.byTooltip('표');
      expect(tableButton, findsOneWidget);

      // 이미지 버튼 찾기
      final imageButton = find.byTooltip('이미지');
      expect(imageButton, findsOneWidget);

      // 가운데 정렬 버튼 찾기
      final centerButton = find.byTooltip('가운데 정렬');
      expect(centerButton, findsOneWidget);

      final styleImportButton = find.byTooltip('EPUB 스타일 가져오기');
      expect(styleImportButton, findsOneWidget);
    });
  });
}
