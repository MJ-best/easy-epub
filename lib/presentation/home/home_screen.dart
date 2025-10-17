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
      appBar: AppBar(
        title: const Text('EasyPub'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
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
                    size: 80,
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    '아직 생성된 전자책이 없습니다',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '아래 버튼을 눌러 첫 전자책을 만들어보세요',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: viewModel.refresh,
            child: GridView.builder(
              padding: const EdgeInsets.all(AppConstants.DEFAULT_PADDING),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.65,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: viewModel.ebooks.length,
              itemBuilder: (context, index) {
                final ebook = viewModel.ebooks[index];
                return _EbookCard(
                  title: ebook.title,
                  author: ebook.author,
                  coverImagePath: ebook.coverImagePath,
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
      floatingActionButton: Semantics(
        label: '새 전자책 만들기',
        button: true,
        child: FloatingActionButton.extended(
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
          icon: const Icon(Icons.add),
          label: const Text('새 전자책 만들기'),
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

class _EbookCard extends StatelessWidget {
  final String title;
  final String author;
  final String? coverImagePath;
  final DateTime modifiedDate;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _EbookCard({
    required this.title,
    required this.author,
    this.coverImagePath,
    required this.modifiedDate,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormatter = DateFormat(AppConstants.DATE_FORMAT);

    return Semantics(
      label: '$title, 저자: $author',
      button: true,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Cover Image
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Theme.of(context).colorScheme.primaryContainer,
                  child: coverImagePath != null
                      ? Image.asset(
                          coverImagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholder(context),
                        )
                      : _buildPlaceholder(context),
                ),
              ),
              // Book Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      author,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            dateFormatter.format(modifiedDate),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Semantics(
                          label: '삭제',
                          button: true,
                          child: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            iconSize: 20,
                            constraints: const BoxConstraints(
                              minWidth: AppConstants.MIN_TOUCH_TARGET_SIZE,
                              minHeight: AppConstants.MIN_TOUCH_TARGET_SIZE,
                            ),
                            onPressed: onDelete,
                            tooltip: '삭제',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(BuildContext context) {
    return Center(
      child: Icon(
        Icons.book,
        size: 64,
        color: Theme.of(context).colorScheme.onPrimaryContainer.withOpacity(0.5),
      ),
    );
  }
}
