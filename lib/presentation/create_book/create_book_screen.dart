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
    final theme = Theme.of(context);
    final createBookViewModel = context.read<CreateBookViewModel>();

    return ChangeNotifierProvider<CreateBookViewModel>.value(
      value: createBookViewModel,
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(
            '새 전자책',
            style: theme.textTheme.titleLarge,
          ),
          leading: IconButton(
            icon: Icon(Icons.close, color: theme.colorScheme.primary, size: 26),
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
    final theme = Theme.of(context);
    return Consumer<CreateBookViewModel>(
      builder: (context, viewModel, child) {
        return OrientationBuilder(
          builder: (context, orientation) {
            final isLandscape = orientation == Orientation.landscape;

            if (isLandscape) {
              // Landscape: Split screen with bottom button
              return Column(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Expanded(
                          child: _EditorPanel(viewModel: viewModel),
                        ),
                        const VerticalDivider(width: 1, thickness: 1),
                        Expanded(
                          child: _PreviewPanel(viewModel: viewModel),
                        ),
                      ],
                    ),
                  ),
                  _BottomButton(viewModel: viewModel),
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
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      child: OutlinedButton.icon(
                        onPressed: () => _showPreviewDialog(context, viewModel),
                        icon: Icon(Icons.visibility_outlined, color: theme.colorScheme.primary),
                        label: Text(
                          '미리보기',
                          style: theme.textTheme.labelLarge,
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
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.height * 0.9,
          child: Column(
            children: [
              AppBar(
                title: Text('미리보기', style: theme.textTheme.titleLarge),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
                backgroundColor: theme.colorScheme.surface,
                foregroundColor: theme.colorScheme.onSurface,
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
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                  child: TextField(
                    textInputAction: TextInputAction.next,
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
                const Divider(height: 1, indent: 20, endIndent: 20),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                  child: TextField(
                    textInputAction: TextInputAction.next,
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
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(18),
            ),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '본문',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    letterSpacing: 0.1,
                  ),
                ),
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 220),
                  child: TextField(
                    decoration: const InputDecoration(
                      labelText: '본문',
                      hintText: '마크다운으로 작성하세요\n\n# 제목\n## 부제목\n본문 내용...',
                      alignLabelWithHint: true,
                      floatingLabelBehavior: FloatingLabelBehavior.auto,
                    ),
                    onChanged: viewModel.setContent,
                    maxLines: null,
                    minLines: 12,
                    keyboardType: TextInputType.multiline,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '템플릿',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.secondary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          _TemplateSelector(viewModel: viewModel),
          const SizedBox(height: 24),
          if (viewModel.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                _getErrorMessage(viewModel.error!, context),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.error,
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
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;

    if (viewModel.content.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.visibility_outlined,
              size: 52,
              color: theme.colorScheme.secondary,
            ),
            const SizedBox(height: 16),
            Text(
              '실시간 미리보기',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '본문 내용을 입력하면\n여기에 표시됩니다',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
        ),
      );
    }

    final html = MarkdownParser.parseToHtml(viewModel.content);

    return Container(
      color: surfaceColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: surfaceColor,
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                  width: 0.6,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.visibility, size: 22, color: theme.colorScheme.secondary),
                const SizedBox(width: 12),
                Text(
                  '미리보기',
                  style: theme.textTheme.titleSmall,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: theme.brightness == Brightness.dark ? const Color(0xFF111111) : Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Html(
                  data: html,
                  style: {
                    "body": Style(
                      fontFamily: 'Noto Sans KR',
                      fontSize: FontSize(18),
                      lineHeight: const LineHeight(1.7),
                      color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                      textAlign: TextAlign.justify,
                      margin: Margins.zero,
                      padding: HtmlPaddings.zero,
                    ),
                    "h1": Style(
                      fontSize: FontSize(28),
                      fontWeight: FontWeight.bold,
                      lineHeight: const LineHeight(1.4),
                      margin: Margins(top: Margin(36), bottom: Margin(18)),
                      color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                    "h2": Style(
                      fontSize: FontSize(24),
                      fontWeight: FontWeight.bold,
                      lineHeight: const LineHeight(1.4),
                      margin: Margins(top: Margin(30), bottom: Margin(14)),
                      color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                    "h3": Style(
                      fontSize: FontSize(20),
                      fontWeight: FontWeight.bold,
                      lineHeight: const LineHeight(1.4),
                      margin: Margins(top: Margin(24), bottom: Margin(12)),
                      color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                    "p": Style(
                      fontSize: FontSize(18),
                      lineHeight: const LineHeight(1.7),
                      margin: Margins(bottom: Margin(16)),
                      textAlign: TextAlign.justify,
                      color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                    ),
                    "ul": Style(
                      fontSize: FontSize(18),
                      lineHeight: const LineHeight(1.7),
                      margin: Margins(top: Margin(10), bottom: Margin(10)),
                      padding: HtmlPaddings(left: HtmlPadding(32)),
                    ),
                    "ol": Style(
                      fontSize: FontSize(18),
                      lineHeight: const LineHeight(1.7),
                      margin: Margins(top: Margin(10), bottom: Margin(10)),
                      padding: HtmlPaddings(left: HtmlPadding(32)),
                    ),
                    "li": Style(
                      margin: Margins(bottom: Margin(8)),
                    ),
                    "strong": Style(
                      fontWeight: FontWeight.bold,
                    ),
                    "em": Style(
                      fontStyle: FontStyle.italic,
                    ),
                    "code": Style(
                      fontFamily: 'Roboto Mono',
                      fontSize: FontSize(16),
                      backgroundColor:
                          theme.brightness == Brightness.dark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5),
                      padding: HtmlPaddings.all(6),
                    ),
                    "a": Style(
                      color: theme.colorScheme.primary,
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
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.6),
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
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Text(
                    '전자책 생성',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
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
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
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
                    top: index == 0 ? const Radius.circular(18) : Radius.zero,
                    bottom: isLast ? const Radius.circular(18) : Radius.zero,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            _getTemplateIcon(template),
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.secondary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                template.displayName,
                                style: theme.textTheme.titleSmall,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                template.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.secondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            border: Border.all(
                              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                              width: 1.2,
                            ),
                          ),
                          child: isSelected
                              ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)
                              : null,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: theme.colorScheme.outlineVariant,
                ),
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
