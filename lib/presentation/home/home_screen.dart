import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers/theme_provider.dart';
import '../../core/services/export/file_exporter.dart';
import '../../data/models/book_document_mapper.dart';
import '../../data/models/ebook_model.dart';
import '../../data/models/template_type.dart';
import '../../data/services/epub_generator_service_v2.dart';
import '../../data/services/markdown_parser.dart';
import '../create_book/create_book_screen.dart';
import '../preview/preview_screen.dart';
import '../viewmodels/library_viewmodel.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 12,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/icon/icon.png',
              width: 28,
              height: 28,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            Text(
              'Easy Epub',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurface,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isDark = themeProvider.isDark(context);
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                tooltip: isDark ? '라이트 모드' : '다크 모드',
                onPressed: themeProvider.toggleTheme,
              );
            },
          ),
          IconButton(
            icon: Icon(
              Icons.search,
              color: theme.colorScheme.onSurface,
              size: 24,
            ),
            tooltip: '검색',
            onPressed: () => _showSearchDialog(context),
          ),
          if (MediaQuery.of(context).size.width >= 900)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: FilledButton.icon(
                onPressed: () => _openEditor(context),
                icon: const Icon(Icons.add),
                label: const Text('새 전자책'),
              ),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
      body: Consumer<LibraryViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline,
                        size: 64, color: theme.colorScheme.error),
                    const SizedBox(height: 20),
                    Text(
                      viewModel.error!,
                      style: theme.textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    FilledButton(
                      onPressed: viewModel.loadEbooks,
                      child: const Text('다시 시도'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _LibraryPane(
            ebooks: viewModel.ebooks,
            hasEbooks: viewModel.hasEbooks,
            onCreate: () => _openEditor(context),
            onEdit: (ebook) => _openEditor(context, ebookId: ebook.id),
            onPreview: (ebook) => _previewEpub(context, ebook),
            onExport: (ebook) => _exportEpub(context, ebook),
            onShare: (ebook) => _shareEpub(context, ebook),
            onDelete: (ebook) => _confirmDelete(context, viewModel, ebook),
          );
        },
      ),
      floatingActionButton: MediaQuery.of(context).size.width >= 900
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add),
              label: const Text('새 전자책'),
            ),
    );
  }

  Future<void> _openEditor(BuildContext context, {String? ebookId}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateBookScreen(ebookId: ebookId),
      ),
    );
    if (context.mounted) {
      await context.read<LibraryViewModel>().loadEbooks();
    }
  }

  Future<void> _previewEpub(BuildContext context, EbookModel ebook) async {
    final generator = context.read<EpubGeneratorServiceV2>();
    final epub = await generator.buildEpub(ebook);

    if (!context.mounted) {
      return;
    }

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PreviewScreen(
          epubFile: XFile.fromData(
            epub.bytes,
            name: epub.fileName,
            mimeType: 'application/epub+zip',
          ),
          title: ebook.title,
          document: ebook.toBookDocument(),
          fallbackHtml: MarkdownParser.parseToHtml(
            ebook.content,
            options: MarkdownRenderOptions(
              styleClassHints: ebook.toBookDocument().styleClassHints,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _exportEpub(BuildContext context, EbookModel ebook) async {
    final generator = context.read<EpubGeneratorServiceV2>();
    final epub = await generator.buildEpub(ebook);
    final fileExporter = createFileExporter();
    final savedPath = await fileExporter.saveBytes(
      bytes: epub.bytes,
      fileName: epub.fileName,
      mimeType: 'application/epub+zip',
    );

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          savedPath == null
              ? '브라우저 다운로드를 시작했습니다.'
              : 'EPUB 파일을 저장했습니다.\n$savedPath',
        ),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _shareEpub(BuildContext context, EbookModel ebook) async {
    final generator = context.read<EpubGeneratorServiceV2>();
    final epub = await generator.buildEpub(ebook);

    if (kIsWeb) {
      await _exportEpub(context, ebook);
      return;
    }

    await Share.shareXFiles(
      [
        XFile.fromData(
          epub.bytes,
          name: epub.fileName,
          mimeType: 'application/epub+zip',
        ),
      ],
      subject: ebook.title,
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        final theme = Theme.of(context);

        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('전자책 검색', style: theme.textTheme.titleLarge),
          content: TextField(
            autofocus: true,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '제목 또는 저자명 입력',
              prefixIcon: Icon(Icons.search, color: theme.colorScheme.primary),
            ),
            onChanged: (value) => query = value,
            onSubmitted: (value) {
              Navigator.pop(context);
              context.read<LibraryViewModel>().searchEbooks(value);
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(context);
                context.read<LibraryViewModel>().searchEbooks(query);
              },
              child: const Text('검색'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(
    BuildContext context,
    LibraryViewModel viewModel,
    EbookModel ebook,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: Text('"${ebook.title}" 전자책을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              viewModel.deleteEbook(ebook.id);
              Navigator.pop(context);
            },
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _LibraryPane extends StatelessWidget {
  const _LibraryPane({
    required this.ebooks,
    required this.hasEbooks,
    required this.onCreate,
    required this.onEdit,
    required this.onPreview,
    required this.onExport,
    required this.onShare,
    required this.onDelete,
  });

  final List<EbookModel> ebooks;
  final bool hasEbooks;
  final VoidCallback onCreate;
  final ValueChanged<EbookModel> onEdit;
  final ValueChanged<EbookModel> onPreview;
  final ValueChanged<EbookModel> onExport;
  final ValueChanged<EbookModel> onShare;
  final ValueChanged<EbookModel> onDelete;

  @override
  Widget build(BuildContext context) {
    if (!hasEbooks) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        children: [
          _LibraryHeader(
            ebookCount: ebooks.length,
            onCreate: onCreate,
          ),
          const SizedBox(height: 56),
          _EmptyLibraryState(onCreate: onCreate),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: context.read<LibraryViewModel>().refresh,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
        itemCount: ebooks.length + 1,
        separatorBuilder: (context, index) =>
            SizedBox(height: index == 0 ? 22 : 14),
        itemBuilder: (context, index) {
          if (index == 0) {
            return _LibraryHeader(
              ebookCount: ebooks.length,
              onCreate: onCreate,
            );
          }

          final ebook = ebooks[index - 1];
          return _EbookListItem(
            ebook: ebook,
            onEdit: () => onEdit(ebook),
            onPreview: () => onPreview(ebook),
            onExport: () => onExport(ebook),
            onShare: () => onShare(ebook),
            onDelete: () => onDelete(ebook),
          );
        },
      ),
    );
  }
}

class _LibraryHeader extends StatelessWidget {
  const _LibraryHeader({
    required this.ebookCount,
    required this.onCreate,
  });

  final int ebookCount;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('전자책 라이브러리', style: theme.textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                '초안을 열고, 스타일을 다듬고, 웹 미리보기로 확인한 뒤 EPUB으로 내보냅니다.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '$ebookCount개의 전자책이 저장되어 있습니다.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        if (isWide) ...[
          const SizedBox(width: 16),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('새 전자책'),
          ),
        ],
      ],
    );
  }
}

class _EmptyLibraryState extends StatelessWidget {
  const _EmptyLibraryState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Column(
          children: [
            Icon(
              Icons.book_outlined,
              size: 56,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 20),
            Text('전자책이 없습니다', style: theme.textTheme.titleLarge),
            const SizedBox(height: 12),
            Text(
              '새 문서를 열어 제목, 스타일, 미리보기 흐름을 바로 시작할 수 있습니다.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add),
              label: const Text('새 전자책'),
            ),
          ],
        ),
      ),
    );
  }
}

enum _BookAction { preview, export, share, delete }

class _EbookListItem extends StatelessWidget {
  const _EbookListItem({
    required this.ebook,
    required this.onEdit,
    required this.onPreview,
    required this.onExport,
    required this.onShare,
    required this.onDelete,
  });

  final EbookModel ebook;
  final VoidCallback onEdit;
  final VoidCallback onPreview;
  final VoidCallback onExport;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final template = TemplateType.fromString(ebook.templateType);
    final dateFormatter = DateFormat('yyyy.MM.dd');
    final headingCount =
        MarkdownParser.extractTableOfContents(ebook.content).length;
    final document = ebook.toBookDocument();

    return Card(
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 56,
                height: 78,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.menu_book, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ebook.title,
                      style: theme.textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${ebook.author} · ${dateFormatter.format(ebook.modifiedAt)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${template.displayName} · heading $headingCount개',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (document.hasCustomCss ||
                        document.structureReference.isNotEmpty ||
                        document.hasImportedFonts) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (document.hasCustomCss)
                            _LibraryMetaChip(
                              label: '스타일 레퍼런스',
                              color: theme.colorScheme.primaryContainer,
                              textColor: theme.colorScheme.onPrimaryContainer,
                            ),
                          if (document.structureReference.isNotEmpty)
                            _LibraryMetaChip(
                              label:
                                  '구조 ${document.structureReference.length}개',
                              color: theme.colorScheme.surfaceContainerHigh,
                              textColor: theme.colorScheme.onSurface,
                            ),
                          if (document.hasImportedFonts)
                            _LibraryMetaChip(
                              label: '폰트 ${document.importedFonts.length}개',
                              color: theme.colorScheme.surfaceContainerHigh,
                              textColor: theme.colorScheme.onSurface,
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        TextButton.icon(
                          onPressed: onEdit,
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text('편집'),
                        ),
                        TextButton.icon(
                          onPressed: onPreview,
                          icon: const Icon(Icons.visibility_outlined, size: 18),
                          label: const Text('미리보기'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              PopupMenuButton<_BookAction>(
                tooltip: '더보기',
                onSelected: (action) {
                  switch (action) {
                    case _BookAction.preview:
                      onPreview();
                      break;
                    case _BookAction.export:
                      onExport();
                      break;
                    case _BookAction.share:
                      onShare();
                      break;
                    case _BookAction.delete:
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _BookAction.preview,
                    child: Text('미리보기'),
                  ),
                  PopupMenuItem(
                    value: _BookAction.export,
                    child: Text(kIsWeb ? '다운로드' : '저장'),
                  ),
                  if (!kIsWeb)
                    const PopupMenuItem(
                      value: _BookAction.share,
                      child: Text('공유'),
                    ),
                  PopupMenuItem(
                    value: _BookAction.delete,
                    child: Text(
                      '삭제',
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                ],
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.more_horiz,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LibraryMetaChip extends StatelessWidget {
  const _LibraryMetaChip({
    required this.label,
    required this.color,
    required this.textColor,
  });

  final String label;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.bodySmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
