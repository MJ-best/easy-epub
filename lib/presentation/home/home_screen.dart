import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../viewmodels/library_viewmodel.dart';
import '../create_book/create_book_screen.dart';
import '../preview/preview_screen.dart';
import '../../core/constants/app_constants.dart';

/// Home screen displaying eBook library
/// Stateless widget following MVVM pattern
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppBar(
        title: Text(
          'EasyPub',
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        toolbarHeight: 52,
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
            tooltip: '검색',
            onPressed: () => _showSearchDialog(context),
          ),
        ],
      ),
      body: Consumer<LibraryViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (viewModel.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(viewModel.error!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => viewModel.loadEbooks(),
                    child: const Text('다시 시도'),
                  ),
                ],
              ),
            );
          }

          if (!viewModel.hasEbooks) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.book_outlined,
                    size: 64,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '전자책이 없습니다',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '새 전자책을 만들어보세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.secondary,
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: viewModel.ebooks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final ebook = viewModel.ebooks[index];
                return _EbookListItem(
                  title: ebook.title,
                  author: ebook.author,
                  modifiedDate: ebook.modifiedAt,
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
                  onDelete: () => _confirmDelete(context, viewModel, ebook.id),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 8, right: 8),
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
            child: const Icon(Icons.add, size: 28),
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
        return AlertDialog(
          title: const Text('전자책 검색'),
          content: TextField(
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '제목 또는 저자명 입력',
              prefixIcon: Icon(Icons.search),
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
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EbookListItem({
    required this.title,
    required this.author,
    required this.modifiedDate,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat('yyyy.MM.dd');

    return Semantics(
      label: '$title, 저자: $author',
      button: true,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.book,
                      color: Theme.of(context).colorScheme.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '$author · ${dateFormatter.format(modifiedDate)}',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.error,
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
