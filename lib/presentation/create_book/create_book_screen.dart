import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import '../viewmodels/create_book_viewmodel.dart';
import '../../data/models/template_type.dart';
import '../../data/services/markdown_parser.dart';

/// Screen for creating new eBooks
/// Follows MVVM pattern with stateless widget
class CreateBookScreen extends StatelessWidget {
  const CreateBookScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => context.read<CreateBookViewModel>(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '새 전자책',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.primary),
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
        return OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            if (isLandscape) {
              // Landscape: Split screen
              return Row(
                children: [
                  Expanded(
                    child: _EditorPanel(viewModel: viewModel),
                  ),
                  const VerticalDivider(width: 1, thickness: 1),
                  Expanded(
                    child: _PreviewPanel(viewModel: viewModel),
                  ),
                ],
              );
            } else {
              // Portrait: Single panel
              return Column(
                children: [
                  Expanded(
                    child: _EditorPanel(viewModel: viewModel),
                  ),
                  if (viewModel.content.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: OutlinedButton.icon(
                        onPressed: () => _showPreviewDialog(context, viewModel),
                        icon: const Icon(Icons.visibility),
                        label: const Text('미리보기'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  _BottomButton(viewModel: viewModel),
                ],
              );
            }
          },
        );
      },
    );
  }

  void _showPreviewDialog(BuildContext context, CreateBookViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              AppBar(
                title: const Text('미리보기'),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                backgroundColor: Theme.of(context).colorScheme.surface,
                foregroundColor: Theme.of(context).colorScheme.onSurface,
              ),
              Expanded(
                child: _PreviewPanel(viewModel: viewModel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorPanel extends StatelessWidget {
  final CreateBookViewModel viewModel;

  const _EditorPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '제목',
                      hintText: '전자책 제목',
                      counterText: '',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    onChanged: viewModel.setTitle,
                    maxLength: 100,
                  ),
                ),
                const Divider(height: 1, indent: 16, endIndent: 16),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '저자',
                      hintText: '저자명 (선택사항)',
                      counterText: '',
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    onChanged: viewModel.setAuthor,
                    maxLength: 50,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(
                labelText: '본문',
                hintText: '마크다운으로 작성하세요\n\n# 제목\n## 부제목\n본문 내용...',
                alignLabelWithHint: true,
                floatingLabelBehavior: FloatingLabelBehavior.auto,
              ),
              onChanged: viewModel.setContent,
              maxLines: 15,
              keyboardType: TextInputType.multiline,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '템플릿',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
          const SizedBox(height: 8),
          _TemplateSelector(viewModel: viewModel),
          const SizedBox(height: 24),
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
        ],
      ),
    );
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

class _PreviewPanel extends StatelessWidget {
  final CreateBookViewModel viewModel;

  const _PreviewPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    if (viewModel.content.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              '실시간 미리보기',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '본문 내용을 입력하면\n여기에 표시됩니다',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
            ),
          ],
        ),
      );
    }

    final html = MarkdownParser.parseToHtml(viewModel.content);

    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  width: 0.5,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility, size: 20, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text(
                  '미리보기',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Html(
                  data: html,
                  style: {
                    "body": Style(
                      fontFamily: 'Noto Serif KR',
                      fontSize: FontSize(16),
                      lineHeight: const LineHeight(1.8),
                      color: Colors.black,
                      textAlign: TextAlign.justify,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    "h1": Style(
                      fontSize: FontSize(24),
                      fontWeight: FontWeight.bold,
                      lineHeight: const LineHeight(1.5),
                      margin: Margins(top: Margin(32), bottom: Margin(16)),
                      color: Colors.black,
                    ),
                    "h2": Style(
                      fontSize: FontSize(20),
                      fontWeight: FontWeight.bold,
                      lineHeight: const LineHeight(1.5),
                      margin: Margins(top: Margin(24), bottom: Margin(12)),
                      color: Colors.black,
                    ),
                    "h3": Style(
                      fontSize: FontSize(17),
                      fontWeight: FontWeight.bold,
                      lineHeight: const LineHeight(1.5),
                      margin: Margins(top: Margin(20), bottom: Margin(10)),
                      color: Colors.black,
                    ),
                    "p": Style(
                      fontSize: FontSize(16),
                      lineHeight: const LineHeight(1.8),
                      margin: Margins(bottom: Margin(16)),
                      textAlign: TextAlign.justify,
                      color: Colors.black,
                    ),
                    "ul": Style(
                      fontSize: FontSize(16),
                      lineHeight: const LineHeight(1.8),
                      margin: Margins(top: Margin(8), bottom: Margin(8)),
                      padding: HtmlPaddings(left: HtmlPadding(32)),
                    ),
                    "ol": Style(
                      fontSize: FontSize(16),
                      lineHeight: const LineHeight(1.8),
                      margin: Margins(top: Margin(8), bottom: Margin(8)),
                      padding: HtmlPaddings(left: HtmlPadding(32)),
                    ),
                    "li": Style(
                      margin: Margins(bottom: Margin(6)),
                    ),
                    "strong": Style(
                      fontWeight: FontWeight.bold,
                    ),
                    "em": Style(
                      fontStyle: FontStyle.italic,
                    ),
                    "code": Style(
                      fontFamily: 'Courier New',
                      fontSize: FontSize(15),
                      backgroundColor: const Color(0xFFF5F5F5),
                      padding: HtmlPaddings.all(4),
                    ),
                    "a": Style(
                      color: const Color(0xFF0066CC),
                      textDecoration: TextDecoration.none,
                    ),
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  final CreateBookViewModel viewModel;

  const _BottomButton({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: viewModel.isGenerating
                ? null
                : () => _handleGenerate(context, viewModel),
            child: viewModel.isGenerating
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    '전자책 생성',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
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
}

class _TemplateSelector extends StatelessWidget {
  final CreateBookViewModel viewModel;

  const _TemplateSelector({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: TemplateType.values.asMap().entries.map((entry) {
          final index = entry.key;
          final template = entry.value;
          final isSelected = viewModel.selectedTemplate == template;
          final isLast = index == TemplateType.values.length - 1;

          return Column(
            children: [
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => viewModel.selectTemplate(template),
                  borderRadius: BorderRadius.vertical(
                    top: index == 0 ? const Radius.circular(10) : Radius.zero,
                    bottom: isLast ? const Radius.circular(10) : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(
                          _getTemplateIcon(template),
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.secondary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            template.displayName,
                            style: TextStyle(
                              fontSize: 17,
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Icon(
                            Icons.check,
                            color: Theme.of(context).colorScheme.primary,
                            size: 22,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                const Divider(height: 1, indent: 52, endIndent: 16),
            ],
          );
        }).toList(),
      ),
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
