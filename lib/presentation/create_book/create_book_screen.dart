import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../viewmodels/create_book_viewmodel.dart';
import '../../data/models/template_type.dart';
import '../../core/constants/app_constants.dart';

/// Screen for creating new eBooks
/// Follows MVVM pattern with stateless widget
class CreateBookScreen extends StatelessWidget {
  const CreateBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => context.read<CreateBookViewModel>(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('새 전자책 만들기'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context),
            tooltip: '닫기',
          ),
        ),
        body: const _CreateBookForm(),
      ),
    );
  }
}

class _CreateBookForm extends StatelessWidget {
  const _CreateBookForm();

  @override
  Widget build(BuildContext context) {
    return Consumer<CreateBookViewModel>(
      builder: (context, viewModel, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(AppConstants.DEFAULT_PADDING),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Title Input
              Semantics(
                label: '제목 입력',
                textField: true,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '전자책 제목을 입력하세요',
                    prefixIcon: Icon(Icons.title),
                  ),
                  onChanged: viewModel.setTitle,
                  maxLength: 100,
                ),
              ),
              const SizedBox(height: 16),

              // Author Input
              Semantics(
                label: '저자 입력',
                textField: true,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '저자',
                    hintText: '저자명을 입력하세요',
                    prefixIcon: Icon(Icons.person),
                  ),
                  onChanged: viewModel.setAuthor,
                  maxLength: 50,
                ),
              ),
              const SizedBox(height: 16),

              // Content Input
              Semantics(
                label: '본문 내용 입력',
                textField: true,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: '본문 내용',
                    hintText: '전자책 내용을 입력하세요\n\n# 제목\n## 부제목\n본문...',
                    prefixIcon: Icon(Icons.article),
                    alignLabelWithHint: true,
                  ),
                  onChanged: viewModel.setContent,
                  maxLines: 10,
                  keyboardType: TextInputType.multiline,
                ),
              ),
              const SizedBox(height: 24),

              // Cover Image Selection
              _CoverImageSelector(),
              const SizedBox(height: 24),

              // Template Selection
              const Text(
                '템플릿 선택',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _TemplateSelector(),
              const SizedBox(height: 32),

              // Error Message
              if (viewModel.error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _getErrorMessage(viewModel.error!, context),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

              // Generate Button
              Semantics(
                label: '전자책 생성',
                button: true,
                child: ElevatedButton.icon(
                  onPressed: viewModel.isGenerating
                      ? null
                      : () => _handleGenerate(context, viewModel),
                  icon: viewModel.isGenerating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.create),
                  label: Text(
                    viewModel.isGenerating ? '생성 중...' : '전자책 생성',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleGenerate(
    BuildContext context,
    CreateBookViewModel viewModel,
  ) async {
    final ebook = await viewModel.createEbook();

    if (ebook != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('전자책이 생성되었습니다')),
      );
      Navigator.pop(context, true);
    }
  }

  String _getErrorMessage(String errorKey, BuildContext context) {
    switch (errorKey) {
      case 'titleRequired':
        return '제목을 입력해주세요';
      case 'contentRequired':
        return '본문을 입력해주세요';
      case 'errorOccurred':
        return '오류가 발생했습니다. 다시 시도해주세요';
      default:
        return errorKey;
    }
  }
}

class _CoverImageSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CreateBookViewModel>(
      builder: (context, viewModel, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '표지 이미지 (선택사항)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Semantics(
              label: '표지 이미지 선택',
              button: true,
              child: OutlinedButton.icon(
                onPressed: () => _selectCoverImage(context, viewModel),
                icon: const Icon(Icons.image),
                label: Text(
                  viewModel.coverImagePath != null
                      ? '이미지 변경'
                      : '이미지 선택',
                ),
              ),
            ),
            if (viewModel.coverImagePath != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '선택됨: ${viewModel.coverImagePath!.split('/').last}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        );
      },
    );
  }

  Future<void> _selectCoverImage(
    BuildContext context,
    CreateBookViewModel viewModel,
  ) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    if (result != null && result.files.single.path != null) {
      viewModel.setCoverImagePath(result.files.single.path);
    }
  }
}

class _TemplateSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<CreateBookViewModel>(
      builder: (context, viewModel, child) {
        return SizedBox(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: TemplateType.values.map((template) {
              final isSelected = viewModel.selectedTemplate == template;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Semantics(
                  label: '${template.displayName} 템플릿',
                  selected: isSelected,
                  button: true,
                  child: ChoiceChip(
                    label: SizedBox(
                      width: 100,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getTemplateIcon(template),
                            size: 32,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            template.displayName,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    selected: isSelected,
                    onSelected: (_) => viewModel.selectTemplate(template),
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  IconData _getTemplateIcon(TemplateType template) {
    switch (template) {
      case TemplateType.novel:
        return Icons.menu_book;
      case TemplateType.essay:
        return Icons.article;
      case TemplateType.manual:
        return Icons.description;
    }
  }
}
