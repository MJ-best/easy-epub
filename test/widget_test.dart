// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:easypub/domain/repositories/ebook_repository.dart';
import 'package:easypub/presentation/home/home_screen.dart';
import 'package:easypub/presentation/viewmodels/library_viewmodel.dart';
import 'package:easypub/data/models/ebook_model.dart';
import 'package:easypub/core/providers/theme_provider.dart';

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
  testWidgets('Home screen shows empty state when no ebooks', (tester) async {
    final repository = _FakeEbookRepository();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<EbookRepository>.value(value: repository),
          ChangeNotifierProvider(
            create: (_) => ThemeProvider(),
          ),
          ChangeNotifierProvider(
            create: (_) => LibraryViewModel(repository)..loadEbooks(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('전자책이 없습니다'), findsOneWidget);
  });
}
