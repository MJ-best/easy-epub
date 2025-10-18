import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_picker/image_picker.dart';
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
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
          _ContentEditor(viewModel: viewModel),
          const SizedBox(height: 24),
          Text(
            '표지 이미지 (선택사항)',
            style: theme.textTheme.titleSmall?.copyWith(
              color: theme.colorScheme.secondary,
              letterSpacing: 0.1,
            ),
          ),
          const SizedBox(height: 12),
          _CoverImagePicker(viewModel: viewModel),
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

class _ContentEditor extends StatefulWidget {
  final CreateBookViewModel viewModel;

  const _ContentEditor({required this.viewModel});

  @override
  State<_ContentEditor> createState() => _ContentEditorState();
}

class _ContentEditorState extends State<_ContentEditor> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.viewModel.content);
    _controller.addListener(() {
      widget.viewModel.setContent(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _insertMarkdown(String prefix, {String suffix = '', bool needsNewline = false}) {
    final selection = _controller.selection;
    final text = _controller.text;

    if (selection.isValid) {
      final selectedText = selection.textInside(text);
      final newText = '$prefix$selectedText$suffix';

      _controller.value = TextEditingValue(
        text: text.replaceRange(selection.start, selection.end, newText),
        selection: TextSelection.collapsed(offset: selection.start + prefix.length + selectedText.length),
      );
    } else {
      final newText = needsNewline ? '\n$prefix$suffix\n' : '$prefix$suffix';
      final offset = _controller.selection.baseOffset;
      _controller.value = TextEditingValue(
        text: text.replaceRange(offset, offset, newText),
        selection: TextSelection.collapsed(offset: offset + prefix.length),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text(
                  '본문',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.secondary,
                    letterSpacing: 0.1,
                  ),
                ),
                const Spacer(),
                _MarkdownToolbar(
                  onBoldPressed: () => _insertMarkdown('**', suffix: '**'),
                  onItalicPressed: () => _insertMarkdown('*', suffix: '*'),
                  onHeadingPressed: () => _insertMarkdown('# '),
                  onListPressed: () => _insertMarkdown('- ', needsNewline: true),
                  onTablePressed: () => _insertMarkdown('\n| 헤더1 | 헤더2 |\n|-------|-------|\n| 내용1 | 내용2 |\n'),
                  onImagePressed: () => _insertMarkdown('![이미지 설명](이미지_URL)'),
                  onCenterPressed: () => _insertMarkdown('<p class="center">', suffix: '</p>'),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 220),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  labelText: '본문',
                  hintText: '마크다운으로 작성하세요\n\n# 제목\n## 부제목\n본문 내용...',
                  alignLabelWithHint: true,
                  floatingLabelBehavior: FloatingLabelBehavior.auto,
                  border: InputBorder.none,
                ),
                maxLines: null,
                minLines: 12,
                keyboardType: TextInputType.multiline,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MarkdownToolbar extends StatelessWidget {
  final VoidCallback onBoldPressed;
  final VoidCallback onItalicPressed;
  final VoidCallback onHeadingPressed;
  final VoidCallback onListPressed;
  final VoidCallback onTablePressed;
  final VoidCallback onImagePressed;
  final VoidCallback onCenterPressed;

  const _MarkdownToolbar({
    required this.onBoldPressed,
    required this.onItalicPressed,
    required this.onHeadingPressed,
    required this.onListPressed,
    required this.onTablePressed,
    required this.onImagePressed,
    required this.onCenterPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 4,
      children: [
        _ToolButton(
          icon: Icons.format_bold,
          tooltip: '굵게',
          onPressed: onBoldPressed,
        ),
        _ToolButton(
          icon: Icons.format_italic,
          tooltip: '기울임',
          onPressed: onItalicPressed,
        ),
        _ToolButton(
          icon: Icons.title,
          tooltip: '제목',
          onPressed: onHeadingPressed,
        ),
        _ToolButton(
          icon: Icons.format_list_bulleted,
          tooltip: '목록',
          onPressed: onListPressed,
        ),
        _ToolButton(
          icon: Icons.table_chart,
          tooltip: '표',
          onPressed: onTablePressed,
        ),
        _ToolButton(
          icon: Icons.image,
          tooltip: '이미지',
          onPressed: onImagePressed,
        ),
        _ToolButton(
          icon: Icons.format_align_center,
          tooltip: '가운데 정렬',
          onPressed: onCenterPressed,
        ),
      ],
    );
  }
}

class _ToolButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  const _ToolButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: 32,
      height: 32,
      child: IconButton(
        icon: Icon(icon, size: 18),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        color: theme.colorScheme.primary,
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

class _PreviewPanel extends StatelessWidget {
  final CreateBookViewModel viewModel;

  const _PreviewPanel({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final surfaceColor = theme.colorScheme.surface;

    if (viewModel.content.isEmpty && viewModel.coverImagePath == null) {
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
    final templateStyles = _getTemplateStyles(viewModel.selectedTemplate, theme);
    final tocEntries = MarkdownParser.extractTableOfContents(viewModel.content);

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
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    viewModel.selectedTemplate.displayName,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: theme.brightness == Brightness.dark ? const Color(0xFF111111) : Colors.white,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Cover image preview
                    if (viewModel.coverImagePath != null) ...[
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            File(viewModel.coverImagePath!),
                            width: 240,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    // Table of Contents
                    if (tocEntries.isNotEmpty) ...[
                      Text(
                        '목차',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...tocEntries.map((entry) {
                        final indent = (entry.level - 1) * 16.0;
                        return Padding(
                          padding: EdgeInsets.only(left: indent, bottom: 8),
                          child: Text(
                            entry.title,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontSize: entry.level == 1 ? 16 : (entry.level == 2 ? 15 : 14),
                              fontWeight: entry.level == 1 ? FontWeight.w600 : FontWeight.normal,
                              color: theme.brightness == Brightness.dark ? Colors.white : Colors.black,
                            ),
                          ),
                        );
                      }),
                      const SizedBox(height: 32),
                      Divider(
                        color: theme.brightness == Brightness.dark
                            ? Colors.white24
                            : Colors.black12,
                      ),
                      const SizedBox(height: 32),
                    ],
                    // Content HTML
                    if (viewModel.content.isNotEmpty)
                      Html(
                        data: html,
                        style: templateStyles,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Get template-specific HTML styles
  Map<String, Style> _getTemplateStyles(TemplateType template, ThemeData theme) {
    final textColor = theme.brightness == Brightness.dark ? Colors.white : Colors.black;
    final codeBackgroundColor = theme.brightness == Brightness.dark ? const Color(0xFF1F1F1F) : const Color(0xFFF5F5F5);

    switch (template) {
      case TemplateType.novel:
        // 소설형: 세리프 폰트, 들여쓰기, 중앙 정렬 제목
        return {
          "body": Style(
            fontFamily: 'Noto Serif KR',
            fontSize: FontSize(18),
            lineHeight: const LineHeight(1.8),
            color: textColor,
            textAlign: TextAlign.justify,
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          "h1": Style(
            fontFamily: 'Noto Serif KR',
            fontSize: FontSize(28),
            fontWeight: FontWeight.bold,
            lineHeight: const LineHeight(1.4),
            margin: Margins(top: Margin(36), bottom: Margin(18)),
            color: textColor,
            textAlign: TextAlign.center,
          ),
          "h2": Style(
            fontFamily: 'Noto Serif KR',
            fontSize: FontSize(24),
            fontWeight: FontWeight.bold,
            lineHeight: const LineHeight(1.4),
            margin: Margins(top: Margin(30), bottom: Margin(14)),
            color: textColor,
            textAlign: TextAlign.center,
          ),
          "h3": Style(
            fontFamily: 'Noto Serif KR',
            fontSize: FontSize(20),
            fontWeight: FontWeight.bold,
            lineHeight: const LineHeight(1.4),
            margin: Margins(top: Margin(24), bottom: Margin(12)),
            color: textColor,
          ),
          "p": Style(
            fontFamily: 'Noto Serif KR',
            fontSize: FontSize(18),
            lineHeight: const LineHeight(1.8),
            margin: Margins(bottom: Margin(12)),
            textAlign: TextAlign.justify,
            color: textColor,
          ),
          "ul": Style(
            fontSize: FontSize(18),
            lineHeight: const LineHeight(1.8),
            margin: Margins(top: Margin(10), bottom: Margin(10)),
            padding: HtmlPaddings(left: HtmlPadding(32)),
          ),
          "ol": Style(
            fontSize: FontSize(18),
            lineHeight: const LineHeight(1.8),
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
            backgroundColor: codeBackgroundColor,
            padding: HtmlPaddings.all(6),
          ),
          "a": Style(
            color: theme.colorScheme.primary,
            textDecoration: TextDecoration.none,
          ),
          "table": Style(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            margin: Margins(top: Margin(16), bottom: Margin(16)),
          ),
          "th": Style(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            padding: HtmlPaddings.all(8),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            fontWeight: FontWeight.bold,
          ),
          "td": Style(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            padding: HtmlPaddings.all(8),
          ),
          "img": Style(
            width: Width(100, Unit.percent),
            height: Height.auto(),
            display: Display.block,
            margin: Margins(top: Margin(12), bottom: Margin(12)),
          ),
          ".center": Style(
            textAlign: TextAlign.center,
          ),
        };

      case TemplateType.essay:
        // 수필형: 산세리프 폰트, 깔끔한 레이아웃
        return {
          "body": Style(
            fontFamily: 'Noto Sans KR',
            fontSize: FontSize(17),
            lineHeight: const LineHeight(1.7),
            color: textColor,
            textAlign: TextAlign.justify,
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          "h1": Style(
            fontFamily: 'Noto Sans KR',
            fontSize: FontSize(26),
            fontWeight: FontWeight.w600,
            lineHeight: const LineHeight(1.4),
            margin: Margins(top: Margin(32), bottom: Margin(16)),
            color: textColor,
          ),
          "h2": Style(
            fontFamily: 'Noto Sans KR',
            fontSize: FontSize(22),
            fontWeight: FontWeight.w600,
            lineHeight: const LineHeight(1.4),
            margin: Margins(top: Margin(28), bottom: Margin(12)),
            color: textColor,
          ),
          "h3": Style(
            fontFamily: 'Noto Sans KR',
            fontSize: FontSize(19),
            fontWeight: FontWeight.w600,
            lineHeight: const LineHeight(1.4),
            margin: Margins(top: Margin(22), bottom: Margin(10)),
            color: textColor,
          ),
          "p": Style(
            fontFamily: 'Noto Sans KR',
            fontSize: FontSize(17),
            lineHeight: const LineHeight(1.7),
            margin: Margins(bottom: Margin(14)),
            textAlign: TextAlign.justify,
            color: textColor,
          ),
          "ul": Style(
            fontSize: FontSize(17),
            lineHeight: const LineHeight(1.7),
            margin: Margins(top: Margin(10), bottom: Margin(10)),
            padding: HtmlPaddings(left: HtmlPadding(32)),
          ),
          "ol": Style(
            fontSize: FontSize(17),
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
            fontSize: FontSize(15),
            backgroundColor: codeBackgroundColor,
            padding: HtmlPaddings.all(6),
          ),
          "a": Style(
            color: theme.colorScheme.primary,
            textDecoration: TextDecoration.none,
          ),
          "table": Style(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            margin: Margins(top: Margin(16), bottom: Margin(16)),
          ),
          "th": Style(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            padding: HtmlPaddings.all(8),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            fontWeight: FontWeight.bold,
          ),
          "td": Style(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            padding: HtmlPaddings.all(8),
          ),
          "img": Style(
            width: Width(100, Unit.percent),
            height: Height.auto(),
            display: Display.block,
            margin: Margins(top: Margin(12), bottom: Margin(12)),
          ),
          ".center": Style(
            textAlign: TextAlign.center,
          ),
        };

      case TemplateType.manual:
        // 매뉴얼형: 구조화된 레이아웃, 강조된 제목
        return {
          "body": Style(
            fontFamily: 'Noto Sans KR',
            fontSize: FontSize(16),
            lineHeight: const LineHeight(1.6),
            color: textColor,
            textAlign: TextAlign.justify,
            margin: Margins.zero,
            padding: HtmlPaddings.zero,
          ),
          "h1": Style(
            fontFamily: 'Noto Sans KR',
            fontSize: FontSize(24),
            fontWeight: FontWeight.bold,
            lineHeight: const LineHeight(1.4),
            margin: Margins(top: Margin(28), bottom: Margin(14)),
            padding: HtmlPaddings(left: HtmlPadding(12), top: HtmlPadding(8), bottom: HtmlPadding(8)),
            color: textColor,
            backgroundColor: theme.brightness == Brightness.dark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
            border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
          ),
          "h2": Style(
            fontFamily: 'Noto Sans KR',
            fontSize: FontSize(20),
            fontWeight: FontWeight.bold,
            lineHeight: const LineHeight(1.4),
            margin: Margins(top: Margin(24), bottom: Margin(12)),
            padding: HtmlPaddings(bottom: HtmlPadding(6)),
            color: textColor,
            border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 2)),
          ),
          "h3": Style(
            fontFamily: 'Noto Sans KR',
            fontSize: FontSize(18),
            fontWeight: FontWeight.bold,
            lineHeight: const LineHeight(1.4),
            margin: Margins(top: Margin(20), bottom: Margin(10)),
            color: textColor,
          ),
          "p": Style(
            fontFamily: 'Noto Sans KR',
            fontSize: FontSize(16),
            lineHeight: const LineHeight(1.6),
            margin: Margins(bottom: Margin(12)),
            textAlign: TextAlign.justify,
            color: textColor,
          ),
          "ul": Style(
            fontSize: FontSize(16),
            lineHeight: const LineHeight(1.6),
            margin: Margins(top: Margin(8), bottom: Margin(12)),
            padding: HtmlPaddings(left: HtmlPadding(28)),
          ),
          "ol": Style(
            fontSize: FontSize(16),
            lineHeight: const LineHeight(1.6),
            margin: Margins(top: Margin(8), bottom: Margin(12)),
            padding: HtmlPaddings(left: HtmlPadding(28)),
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
            fontFamily: 'Roboto Mono',
            fontSize: FontSize(14),
            backgroundColor: codeBackgroundColor,
            padding: HtmlPaddings.all(6),
          ),
          "a": Style(
            color: theme.colorScheme.primary,
            textDecoration: TextDecoration.none,
          ),
          "table": Style(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            margin: Margins(top: Margin(16), bottom: Margin(16)),
          ),
          "th": Style(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            padding: HtmlPaddings.all(8),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            fontWeight: FontWeight.bold,
          ),
          "td": Style(
            border: Border.all(color: theme.colorScheme.outlineVariant),
            padding: HtmlPaddings.all(8),
          ),
          "img": Style(
            width: Width(100, Unit.percent),
            height: Height.auto(),
            display: Display.block,
            margin: Margins(top: Margin(12), bottom: Margin(12)),
          ),
          ".center": Style(
            textAlign: TextAlign.center,
          ),
        };
    }
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
          height: 52,
          child: ElevatedButton(
            onPressed: viewModel.isGenerating
                ? null
                : () => _handleGenerate(context, viewModel),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
              disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
              elevation: viewModel.isGenerating ? 0 : 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: viewModel.isGenerating
                ? SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  )
                : Text(
                    '전자책 생성',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onPrimary,
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
      final shouldShowOptions = await _showSuccessDialog(context, ebook.epubFilePath);
      if (shouldShowOptions == true) {
        Navigator.pop(context, true);
      }
    }
  }

  Future<bool?> _showSuccessDialog(BuildContext context, String? epubPath) async {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Icon(Icons.check_circle, color: theme.colorScheme.primary, size: 28),
              const SizedBox(width: 12),
              const Text('전자책 생성 완료'),
            ],
          ),
          content: const Text('전자책이 성공적으로 생성되었습니다.'),
          actions: [
            if (epubPath != null) ...[
              TextButton.icon(
                onPressed: () {
                  Navigator.pop(context, false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('파일이 저장되었습니다\n$epubPath'),
                      duration: const Duration(seconds: 3),
                    ),
                  );
                },
                icon: const Icon(Icons.file_download),
                label: const Text('저장 위치'),
              ),
              TextButton.icon(
                onPressed: () async {
                  await _shareEpub(context, epubPath);
                },
                icon: const Icon(Icons.share),
                label: const Text('공유'),
              ),
            ],
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _shareEpub(BuildContext context, String epubPath) async {
    try {
      final file = File(epubPath);
      if (await file.exists()) {
        final result = await Share.shareXFiles(
          [XFile(epubPath)],
          subject: 'EPUB 전자책 공유',
        );
        if (result.status == ShareResultStatus.success && context.mounted) {
          Navigator.pop(context, true);
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 실패: ${e.toString()}')),
        );
      }
    }
  }
}

class _CoverImagePicker extends StatelessWidget {
  final CreateBookViewModel viewModel;

  const _CoverImagePicker({required this.viewModel});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final imagePicker = ImagePicker();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            try {
              final XFile? image = await imagePicker.pickImage(
                source: ImageSource.gallery,
                maxWidth: 800,
                maxHeight: 1200,
                imageQuality: 85,
              );
              if (image != null) {
                viewModel.setCoverImagePath(image.path);
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('이미지 선택 실패: ${e.toString()}')),
                );
              }
            }
          },
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: viewModel.coverImagePath != null
                ? Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          File(viewModel.coverImagePath!),
                          width: 60,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '표지 이미지 선택됨',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '탭하여 변경',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: theme.colorScheme.error),
                        onPressed: () => viewModel.setCoverImagePath(null),
                        tooltip: '제거',
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 60,
                        height: 90,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 32,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '표지 이미지 추가',
                              style: theme.textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '갤러리에서 선택',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.secondary,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
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
