import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/theme_provider.dart';
import '../viewmodels/library_viewmodel.dart';
import '../create_book/create_book_screen.dart';
import '../preview/preview_screen.dart';

/// Home screen displaying eBook library
/// Stateless widget following MVVM pattern
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        titleSpacing: 20,
        title: Text(
          'EasyPub',
          style: theme.textTheme.displaySmall?.copyWith(
            color: theme.colorScheme.onSurface,
            letterSpacing: -0.3,
          ),
        ),
        actions: [
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              final isDark = themeProvider.isDark(context);
              return IconButton(
                icon: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: theme.colorScheme.primary,
                  size: 26,
                ),
                tooltip: isDark ? '라이트 모드' : '다크 모드',
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.search, color: theme.colorScheme.primary, size: 26),
            tooltip: '검색',
            onPressed: () => _showSearchDialog(context),
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: Consumer<LibraryViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (viewModel.error != null) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
                  const SizedBox(height: 20),
                  Text(
                    viewModel.error!,
                    style: theme.textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () => viewModel.loadEbooks(),
                      child: const Text('다시 시도'),
                    ),
                  ),
                ],
              ),
            );
          }

          if (!viewModel.hasEbooks) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 42),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Icon(
                      Icons.book_outlined,
                      size: 48,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '전자책이 없습니다',
                    style: theme.textTheme.titleLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '새 전자책을 만들어보세요',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: viewModel.ebooks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final ebook = viewModel.ebooks[index];
                return _EbookListItem(
                  title: ebook.title,
                  author: ebook.author,
                  modifiedDate: ebook.modifiedAt,
                  epubFilePath: ebook.epubFilePath,
                  onTap: () {
                    if (ebook.epubFilePath != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PreviewScreen(epubPath: ebook.epubFilePath!),
                        ),
                      );
                    }
                  },
                  onShare: ebook.epubFilePath != null
                      ? () => _shareEpub(context, ebook.epubFilePath!)
                      : null,
                  onDelete: () => _confirmDelete(context, viewModel, ebook.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: Semantics(
          label: '새 전자책 만들기',
          button: true,
          child: FloatingActionButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const CreateBookScreen(),
                ),
              );
              if (result == true && context.mounted) {
                context.read<LibraryViewModel>().loadEbooks();
              }
            },
            child: const Icon(Icons.add, size: 26),
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        String query = '';
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
          actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
          title: Text(
            '전자책 검색',
            style: theme.textTheme.titleLarge,
          ),
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
            ElevatedButton(
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

  Future<void> _shareEpub(BuildContext context, String epubPath) async {
    try {
      final file = File(epubPath);
      if (!await file.exists()) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('파일을 찾을 수 없습니다')),
          );
        }
        return;
      }

      await Share.shareXFiles(
        [XFile(epubPath)],
        subject: 'EPUB 전자책 공유',
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 실패: ${e.toString()}')),
        );
      }
    }
  }

  void _confirmDelete(BuildContext context, LibraryViewModel viewModel, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제 확인'),
        content: const Text('이 전자책을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          ElevatedButton(
            onPressed: () {
              viewModel.deleteEbook(id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _EbookListItem extends StatelessWidget {
  final String title;
  final String author;
  final DateTime modifiedDate;
  final String? epubFilePath;
  final VoidCallback onTap;
  final VoidCallback? onShare;
  final VoidCallback onDelete;

  const _EbookListItem({
    required this.title,
    required this.author,
    required this.modifiedDate,
    this.epubFilePath,
    required this.onTap,
    this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormatter = DateFormat('yyyy.MM.dd');

    final textScale = MediaQuery.textScalerOf(context).scale(1.0).clamp(1.0, 1.3);

    return Semantics(
      label: '$title, 저자: $author',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 18 * textScale,
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 76,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.menu_book,
                      color: theme.colorScheme.primary,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleMedium,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$author · ${dateFormatter.format(modifiedDate)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (onShare != null)
                    IconButton(
                      iconSize: 24,
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        Icons.share_outlined,
                        color: theme.colorScheme.primary,
                      ),
                      onPressed: onShare,
                      tooltip: '공유',
                    ),
                  IconButton(
                    iconSize: 26,
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.delete_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: onDelete,
                    tooltip: '삭제',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
