import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/epub_preview_models.dart';
import '../../core/services/export/file_exporter.dart';
import '../../data/models/book_document_mapper.dart';
import '../../data/models/template_type.dart';
import '../../data/services/markdown_parser.dart';
import '../../domain/entities/book_document.dart';
import '../preview/preview_screen.dart';
import '../viewmodels/create_book_viewmodel.dart';
import '../widgets/epub_preview_frame.dart';

enum PreviewSurface { reader, browser, print }

class CreateBookScreen extends StatefulWidget {
  const CreateBookScreen({
    super.key,
    this.ebookId,
  });

  final String? ebookId;

  @override
  State<CreateBookScreen> createState() => _CreateBookScreenState();
}

class _CreateBookScreenState extends State<CreateBookScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _authorController;
  late final TextEditingController _contentController;

  CreateBookViewModel? _viewModel;
  bool _syncingControllers = false;
  bool _initialized = false;

  final EpubPreviewController _webPreviewController = EpubPreviewController();

  PreviewSurface _previewSurface = PreviewSurface.reader;
  WebPreviewMode _webPreviewMode = WebPreviewMode.scrolled;
  double _previewTextScale = 1.0;
  double _previewWidth = 680;
  bool _showTableOfContents = true;
  EpubPreviewSource? _webPreviewSource;
  Timer? _previewDebounce;
  int _previewGeneration = 0;
  String _lastPreviewFingerprint = '';

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _authorController = TextEditingController();
    _contentController = TextEditingController();

    _titleController.addListener(() {
      if (_syncingControllers || _viewModel == null) {
        return;
      }
      _viewModel!.setTitle(_titleController.text);
    });
    _authorController.addListener(() {
      if (_syncingControllers || _viewModel == null) {
        return;
      }
      _viewModel!.setAuthor(_authorController.text);
    });
    _contentController.addListener(() {
      if (_syncingControllers || _viewModel == null) {
        return;
      }
      _viewModel!.setContent(_contentController.text);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final nextViewModel = context.read<CreateBookViewModel>();

    if (_viewModel != nextViewModel) {
      _viewModel?.removeListener(_syncControllersFromViewModel);
      _viewModel = nextViewModel;
      _viewModel!.addListener(_syncControllersFromViewModel);
    }

    if (!_initialized) {
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted || _viewModel == null) {
          return;
        }
        if (widget.ebookId == null) {
          _viewModel!.reset();
        } else {
          await _viewModel!.loadEbook(widget.ebookId!);
        }
        _syncControllersFromViewModel();
      });
    }
  }

  @override
  void dispose() {
    _previewDebounce?.cancel();
    _webPreviewController.dispose();
    _viewModel?.removeListener(_syncControllersFromViewModel);
    _titleController.dispose();
    _authorController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _syncControllersFromViewModel() {
    final viewModel = _viewModel;
    if (!mounted || viewModel == null) {
      return;
    }

    _syncingControllers = true;
    _replaceControllerText(_titleController, viewModel.title);
    _replaceControllerText(_authorController, viewModel.author);
    _replaceControllerText(_contentController, viewModel.content);
    _syncingControllers = false;

    _syncWebPreview(viewModel);
    setState(() {});
  }

  void _syncWebPreview(CreateBookViewModel viewModel) {
    if (!kIsWeb) {
      return;
    }

    final hasPreviewContent = viewModel.content.trim().isNotEmpty ||
        viewModel.coverImageBytes != null;
    if (!hasPreviewContent) {
      _previewDebounce?.cancel();
      _previewGeneration += 1;
      _lastPreviewFingerprint = '';
      _webPreviewSource = null;
      _webPreviewController.reset();
      return;
    }

    final fingerprint = jsonEncode(viewModel.previewDocument.toJson());
    if (fingerprint == _lastPreviewFingerprint) {
      return;
    }

    _lastPreviewFingerprint = fingerprint;
    _scheduleWebPreviewBuild();
  }

  void _scheduleWebPreviewBuild() {
    if (!kIsWeb) {
      return;
    }

    _previewDebounce?.cancel();
    _previewDebounce = Timer(
      const Duration(milliseconds: 450),
      _rebuildWebPreviewSource,
    );
  }

  Future<void> _rebuildWebPreviewSource() async {
    final viewModel = _viewModel;
    if (!mounted || !kIsWeb || viewModel == null) {
      return;
    }

    final generation = ++_previewGeneration;
    _webPreviewController.setLoading();

    try {
      final source = await viewModel.buildPreviewSource();
      if (!mounted || generation != _previewGeneration) {
        return;
      }

      setState(() {
        _webPreviewSource = source;
      });
    } catch (error) {
      if (!mounted || generation != _previewGeneration) {
        return;
      }
      setState(() {
        _webPreviewSource = null;
      });
      _webPreviewController.setError(
        '미리보기용 EPUB 생성에 실패했습니다.\n$error',
      );
    }
  }

  void _replaceControllerText(TextEditingController controller, String value) {
    if (controller.text == value) {
      return;
    }
    controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
      composing: TextRange.empty,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final createBookViewModel = context.read<CreateBookViewModel>();

    return ChangeNotifierProvider<CreateBookViewModel>.value(
      value: createBookViewModel,
      child: Consumer<CreateBookViewModel>(
        builder: (context, viewModel, child) {
          final isDesktop = MediaQuery.of(context).size.width >= 1100;

          return Scaffold(
            backgroundColor: theme.colorScheme.surface,
            appBar: AppBar(
              title: Text(
                viewModel.isEditing ? '전자책 편집' : '새 전자책',
                style: theme.textTheme.titleLarge,
              ),
              leading: IconButton(
                icon: Icon(
                  Icons.close,
                  color: theme.colorScheme.onSurface,
                  size: 24,
                ),
                onPressed: () => Navigator.pop(context),
                tooltip: '닫기',
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.upload_file_outlined),
                  onPressed: viewModel.isGenerating ? null : _importMarkdown,
                  tooltip: 'Markdown 불러오기',
                ),
                IconButton(
                  icon: const Icon(Icons.style_outlined),
                  onPressed: viewModel.isGenerating ? null : _importEpubStyle,
                  tooltip: 'EPUB 스타일 가져오기',
                ),
                if (isDesktop)
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextButton.icon(
                      onPressed:
                          viewModel.isGenerating ? null : _handleSaveDraft,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('임시 저장'),
                    ),
                  ),
              ],
            ),
            body: LayoutBuilder(
              builder: (context, constraints) {
                final wideLayout = constraints.maxWidth >= 1100;
                if (wideLayout) {
                  return Row(
                    children: [
                      Expanded(
                        flex: 11,
                        child: _EditorPane(
                          titleController: _titleController,
                          authorController: _authorController,
                          contentController: _contentController,
                          viewModel: viewModel,
                          onImportMarkdown: _importMarkdown,
                          onImportEpubStyle: _importEpubStyle,
                          onPickCover: _pickCoverImage,
                          onRemoveCover: viewModel.clearCoverImage,
                          onInsertMarkdown: _insertMarkdown,
                          onApplyStructureTemplate: _applyStructureTemplate,
                          onInsertStructureEntry:
                              _insertStructureReferenceEntry,
                          onClearImportedStyle: _clearImportedStyleReference,
                        ),
                      ),
                      VerticalDivider(
                        width: 1,
                        thickness: 1,
                        color: theme.colorScheme.outlineVariant,
                      ),
                      Expanded(
                        flex: 9,
                        child: _PreviewWorkspace(
                          viewModel: viewModel,
                          previewSurface: _previewSurface,
                          webPreviewMode: _webPreviewMode,
                          previewTextScale: _previewTextScale,
                          previewWidth: _previewWidth,
                          showTableOfContents: _showTableOfContents,
                          previewController: _webPreviewController,
                          previewSource: _webPreviewSource,
                          onRetryPreview: _rebuildWebPreviewSource,
                          onPreviewSurfaceChanged: (value) {
                            setState(() => _previewSurface = value);
                          },
                          onWebPreviewModeChanged: (value) {
                            setState(() => _webPreviewMode = value);
                          },
                          onPreviewTextScaleChanged: (value) {
                            setState(() => _previewTextScale = value);
                          },
                          onPreviewWidthChanged: (value) {
                            setState(() => _previewWidth = value);
                          },
                          onToggleTableOfContents: (value) {
                            setState(() => _showTableOfContents = value);
                          },
                        ),
                      ),
                    ],
                  );
                }

                return ListView(
                  padding: const EdgeInsets.only(bottom: 120),
                  children: [
                    _EditorPane(
                      titleController: _titleController,
                      authorController: _authorController,
                      contentController: _contentController,
                      viewModel: viewModel,
                      onImportMarkdown: _importMarkdown,
                      onImportEpubStyle: _importEpubStyle,
                      onPickCover: _pickCoverImage,
                      onRemoveCover: viewModel.clearCoverImage,
                      onInsertMarkdown: _insertMarkdown,
                      onApplyStructureTemplate: _applyStructureTemplate,
                      onInsertStructureEntry: _insertStructureReferenceEntry,
                      onClearImportedStyle: _clearImportedStyleReference,
                    ),
                    _PreviewWorkspace(
                      viewModel: viewModel,
                      previewSurface: _previewSurface,
                      webPreviewMode: _webPreviewMode,
                      previewTextScale: _previewTextScale,
                      previewWidth: _previewWidth,
                      showTableOfContents: _showTableOfContents,
                      previewController: _webPreviewController,
                      previewSource: _webPreviewSource,
                      onRetryPreview: _rebuildWebPreviewSource,
                      onPreviewSurfaceChanged: (value) {
                        setState(() => _previewSurface = value);
                      },
                      onWebPreviewModeChanged: (value) {
                        setState(() => _webPreviewMode = value);
                      },
                      onPreviewTextScaleChanged: (value) {
                        setState(() => _previewTextScale = value);
                      },
                      onPreviewWidthChanged: (value) {
                        setState(() => _previewWidth = value);
                      },
                      onToggleTableOfContents: (value) {
                        setState(() => _showTableOfContents = value);
                      },
                    ),
                  ],
                );
              },
            ),
            bottomNavigationBar: _ActionBar(
              isBusy: viewModel.isGenerating,
              onSaveDraft: _handleSaveDraft,
              onGenerate: _handleGenerate,
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleSaveDraft() async {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return;
    }

    final saved = await viewModel.saveDraft();
    if (!mounted || saved == null) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          viewModel.isEditing ? '전자책 초안을 저장했습니다.' : '새 전자책 초안을 저장했습니다.',
        ),
      ),
    );
  }

  Future<void> _handleGenerate() async {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return;
    }

    final result = await viewModel.generateEbook();
    if (!mounted || result == null) {
      return;
    }

    final exporter = createFileExporter();
    final savedPath = await exporter.saveBytes(
      bytes: result.epub.bytes,
      fileName: result.epub.fileName,
      mimeType: 'application/epub+zip',
    );

    if (!mounted) {
      return;
    }

    await _showSuccessDialog(
      result: result,
      savedPath: savedPath,
    );
  }

  Future<void> _showSuccessDialog({
    required EbookGenerationResult result,
    required String? savedPath,
  }) async {
    final theme = Theme.of(context);

    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            Icon(Icons.check_circle,
                color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 12),
            const Expanded(child: Text('EPUB 생성 완료')),
          ],
        ),
        content: Text(
          kIsWeb
              ? '브라우저 다운로드를 시작했습니다. 실제 EPUB 리더에서 결과를 확인해보세요.'
              : '전자책이 성공적으로 생성되었습니다.',
        ),
        actions: [
          if (!kIsWeb)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  this.context,
                  MaterialPageRoute(
                    builder: (_) => PreviewScreen(
                      epubFile: XFile.fromData(
                        result.epub.bytes,
                        mimeType: 'application/epub+zip',
                        name: result.epub.fileName,
                      ),
                      title: result.ebook.title,
                      document: result.ebook.toBookDocument(),
                      fallbackHtml: MarkdownParser.parseToHtml(
                        result.ebook.content,
                        options: MarkdownRenderOptions(
                          styleClassHints:
                              result.ebook.toBookDocument().styleClassHints,
                        ),
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('미리보기'),
            ),
          if (!kIsWeb)
            TextButton.icon(
              onPressed: () async {
                await Share.shareXFiles(
                  [
                    XFile.fromData(
                      result.epub.bytes,
                      mimeType: 'application/epub+zip',
                      name: result.epub.fileName,
                    ),
                  ],
                  subject: result.ebook.title,
                );
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              icon: const Icon(Icons.share_outlined),
              label: const Text('공유'),
            ),
          if (savedPath != null)
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(this.context).showSnackBar(
                  SnackBar(
                    content: Text('파일 저장 위치\n$savedPath'),
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              icon: const Icon(Icons.folder_open_outlined),
              label: const Text('저장 위치'),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  Future<void> _importMarkdown() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['md', 'markdown', 'txt'],
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      return;
    }

    final content = utf8.decode(bytes, allowMalformed: true);
    final title = _titleController.text.trim().isEmpty
        ? _titleFromFileName(file.name)
        : _titleController.text;

    _syncingControllers = true;
    _titleController.text = title;
    _contentController.text = content;
    _syncingControllers = false;

    _viewModel?.setTitle(title);
    _viewModel?.setContent(content);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${file.name} 파일을 불러왔습니다.')),
    );
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    if (file.bytes == null || file.bytes!.isEmpty) {
      return;
    }

    _viewModel?.setCoverImage(
      path: file.path,
      bytes: file.bytes,
      mimeType: _mimeTypeFromExtension(file.extension),
    );
  }

  Future<void> _importEpubStyle() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['epub'],
      withData: true,
    );

    if (!mounted || result == null || result.files.isEmpty) {
      return;
    }

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty || _viewModel == null) {
      return;
    }

    final imported = await _viewModel!.applyImportedEpubStyle(
      bytes: bytes,
      sourceName: file.name,
    );

    if (!mounted || imported == null) {
      return;
    }

    final warningText = imported.warnings.isEmpty
        ? ''
        : '\n주의: ${imported.warnings.join(' / ')}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${file.name}의 스타일 레퍼런스를 가져왔습니다.$warningText'),
        duration: const Duration(seconds: 5),
      ),
    );
  }

  void _insertMarkdown(
    String prefix, {
    String suffix = '',
    bool needsNewline = false,
  }) {
    final selection = _contentController.selection;
    final text = _contentController.text;

    if (selection.isValid) {
      final selectedText = selection.textInside(text);
      final newText = '$prefix$selectedText$suffix';
      _contentController.value = TextEditingValue(
        text: text.replaceRange(selection.start, selection.end, newText),
        selection: TextSelection.collapsed(
          offset: selection.start + prefix.length + selectedText.length,
        ),
      );
      return;
    }

    final offset =
        selection.baseOffset < 0 ? text.length : selection.baseOffset;
    final newText = needsNewline ? '\n$prefix$suffix\n' : '$prefix$suffix';
    _contentController.value = TextEditingValue(
      text: text.replaceRange(offset, offset, newText),
      selection: TextSelection.collapsed(offset: offset + prefix.length),
    );
  }

  void _insertSnippet(
    String snippet, {
    bool surroundWithBlankLines = false,
  }) {
    final normalizedSnippet = snippet.trim();
    if (normalizedSnippet.isEmpty) {
      return;
    }

    final selection = _contentController.selection;
    final text = _contentController.text;
    final start = selection.isValid && selection.start >= 0
        ? selection.start
        : text.length;
    final end = selection.isValid && selection.end >= 0 ? selection.end : start;
    final before = text.substring(0, start);
    final after = text.substring(end);

    final prefix = !surroundWithBlankLines
        ? ''
        : before.isEmpty
            ? ''
            : before.endsWith('\n\n')
                ? ''
                : before.endsWith('\n')
                    ? '\n'
                    : '\n\n';
    final suffix = !surroundWithBlankLines
        ? ''
        : after.isEmpty
            ? '\n\n'
            : after.startsWith('\n\n')
                ? ''
                : after.startsWith('\n')
                    ? '\n'
                    : '\n\n';

    final replacement = '$prefix$normalizedSnippet$suffix';
    _contentController.value = TextEditingValue(
      text: text.replaceRange(start, end, replacement),
      selection: TextSelection.collapsed(offset: start + replacement.length),
    );
  }

  void _applyStructureTemplate() {
    final viewModel = _viewModel;
    if (viewModel == null || !viewModel.hasStructureTemplate) {
      return;
    }

    if (_contentController.text.trim().isEmpty) {
      final applied = viewModel.applyStructureReferenceToDraft(
        replaceExisting: true,
      );
      if (applied) {
        return;
      }
    }

    final template = viewModel.buildStructureTemplate();
    _insertSnippet(
      template,
      surroundWithBlankLines: _contentController.text.trim().isNotEmpty,
    );
  }

  void _insertStructureReferenceEntry(StructureReferenceEntry entry) {
    final viewModel = _viewModel;
    if (viewModel == null) {
      return;
    }

    final snippet = viewModel.buildStructureSnippet(
      entry,
      includeBodyPlaceholder: false,
    );
    _insertSnippet(snippet, surroundWithBlankLines: true);
  }

  void _clearImportedStyleReference() {
    final viewModel = _viewModel;
    if (viewModel == null || !viewModel.hasImportedStyle) {
      return;
    }

    viewModel.clearStyleReference();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('EPUB 스타일 레퍼런스를 해제했습니다.')),
    );
  }

  String _titleFromFileName(String name) {
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex <= 0) {
      return name;
    }
    return name.substring(0, dotIndex);
  }

  String _mimeTypeFromExtension(String? extension) {
    final normalized = extension?.toLowerCase() ?? '';
    switch (normalized) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}

class _EditorPane extends StatelessWidget {
  const _EditorPane({
    required this.titleController,
    required this.authorController,
    required this.contentController,
    required this.viewModel,
    required this.onImportMarkdown,
    required this.onImportEpubStyle,
    required this.onPickCover,
    required this.onRemoveCover,
    required this.onInsertMarkdown,
    required this.onApplyStructureTemplate,
    required this.onInsertStructureEntry,
    required this.onClearImportedStyle,
  });

  final TextEditingController titleController;
  final TextEditingController authorController;
  final TextEditingController contentController;
  final CreateBookViewModel viewModel;
  final Future<void> Function() onImportMarkdown;
  final Future<void> Function() onImportEpubStyle;
  final Future<void> Function() onPickCover;
  final VoidCallback onRemoveCover;
  final void Function(String prefix, {String suffix, bool needsNewline})
      onInsertMarkdown;
  final VoidCallback onApplyStructureTemplate;
  final ValueChanged<StructureReferenceEntry> onInsertStructureEntry;
  final VoidCallback onClearImportedStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stats = _EditorStats.fromContent(contentController.text);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: viewModel.isEditing ? '문서 정보' : '새 전자책',
            subtitle: '웹과 모바일에서 같은 초안을 편집하고 EPUB로 내보냅니다.',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(label: '문단 ${stats.paragraphCount}'),
                _StatChip(label: '챕터 ${viewModel.chapterCount}'),
                _StatChip(label: '헤딩 ${stats.headingCount}'),
                _StatChip(label: '단어 ${stats.wordCount}'),
                _StatChip(label: '예상 읽기 ${stats.readingMinutes}분'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '메타데이터',
            child: Column(
              children: [
                TextField(
                  key: const ValueKey('create-book-title-field'),
                  controller: titleController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '전자책 제목',
                    counterText: '',
                  ),
                  maxLength: 100,
                ),
                const SizedBox(height: 12),
                TextField(
                  key: const ValueKey('create-book-author-field'),
                  controller: authorController,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: '저자',
                    hintText: '저자명 (선택사항)',
                    counterText: '',
                  ),
                  maxLength: 50,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '스타일 레퍼런스',
            subtitle:
                '다른 EPUB의 CSS, 폰트, 목차/제목 구조만 현재 초안의 스타일 레퍼런스로 연결합니다. 이미지는 가져오지 않습니다.',
            trailing: TextButton.icon(
              onPressed: onImportEpubStyle,
              icon: const Icon(Icons.style_outlined),
              label: const Text('EPUB 스타일 가져오기'),
            ),
            child: _ImportedStyleCard(
              viewModel: viewModel,
              onApplyStructureTemplate: onApplyStructureTemplate,
              onInsertStructureEntry: onInsertStructureEntry,
              onClearImportedStyle: onClearImportedStyle,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '본문 편집',
            subtitle: 'Markdown을 입력하면 우측에서 EPUB 스타일로 실시간 확인할 수 있습니다.',
            trailing: TextButton.icon(
              onPressed: onImportMarkdown,
              icon: const Icon(Icons.upload_file_outlined),
              label: const Text('Markdown 불러오기'),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _ToolbarButton(
                      icon: Icons.format_bold,
                      tooltip: '굵게',
                      onPressed: () => onInsertMarkdown('**', suffix: '**'),
                    ),
                    _ToolbarButton(
                      icon: Icons.format_italic,
                      tooltip: '기울임',
                      onPressed: () => onInsertMarkdown('*', suffix: '*'),
                    ),
                    _ToolbarButton(
                      icon: Icons.title,
                      tooltip: '제목',
                      onPressed: () => onInsertMarkdown('# '),
                    ),
                    _ToolbarButton(
                      icon: Icons.format_list_bulleted,
                      tooltip: '목록',
                      onPressed: () =>
                          onInsertMarkdown('- ', needsNewline: true),
                    ),
                    _ToolbarButton(
                      icon: Icons.table_chart,
                      tooltip: '표',
                      onPressed: () => onInsertMarkdown(
                        '\n| 헤더1 | 헤더2 |\n|-------|-------|\n| 내용1 | 내용2 |\n',
                      ),
                    ),
                    _ToolbarButton(
                      icon: Icons.image_outlined,
                      tooltip: '이미지',
                      onPressed: () => onInsertMarkdown('![이미지 설명](이미지_URL)'),
                    ),
                    _ToolbarButton(
                      icon: Icons.format_align_center,
                      tooltip: '가운데 정렬',
                      onPressed: () => onInsertMarkdown(
                        '<p class="center">',
                        suffix: '</p>',
                      ),
                    ),
                    _ToolbarButton(
                      icon: Icons.format_quote,
                      tooltip: '인용문',
                      onPressed: () => onInsertMarkdown(
                        '<blockquote class="quote">',
                        suffix: '</blockquote>',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  key: const ValueKey('create-book-content-field'),
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '본문',
                    hintText: '마크다운으로 작성하세요\n\n# 제목\n## 부제목\n본문 내용...',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                  minLines: 18,
                  maxLines: null,
                  keyboardType: TextInputType.multiline,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            title: '표지와 템플릿',
            child: Column(
              children: [
                _CoverPickerCard(
                  viewModel: viewModel,
                  onPickCover: onPickCover,
                  onRemoveCover: onRemoveCover,
                ),
                const SizedBox(height: 16),
                _TemplateSelector(viewModel: viewModel),
                if (viewModel.error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _errorMessage(viewModel.error!),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _errorMessage(String errorKey) {
    switch (errorKey) {
      case 'titleRequired':
        return '제목을 입력해주세요.';
      case 'contentRequired':
        return '본문을 입력하거나 최소한 초안 내용을 저장해주세요.';
      case 'errorOccurred':
        return '처리 중 오류가 발생했습니다. 다시 시도해주세요.';
      case 'styleImportFailed':
        return 'EPUB 스타일을 가져오지 못했습니다. 다른 파일로 다시 시도해주세요.';
      default:
        return errorKey;
    }
  }
}

class _PreviewWorkspace extends StatelessWidget {
  const _PreviewWorkspace({
    required this.viewModel,
    required this.previewSurface,
    required this.webPreviewMode,
    required this.previewTextScale,
    required this.previewWidth,
    required this.showTableOfContents,
    required this.previewController,
    required this.previewSource,
    required this.onRetryPreview,
    required this.onPreviewSurfaceChanged,
    required this.onWebPreviewModeChanged,
    required this.onPreviewTextScaleChanged,
    required this.onPreviewWidthChanged,
    required this.onToggleTableOfContents,
  });

  final CreateBookViewModel viewModel;
  final PreviewSurface previewSurface;
  final WebPreviewMode webPreviewMode;
  final double previewTextScale;
  final double previewWidth;
  final bool showTableOfContents;
  final EpubPreviewController previewController;
  final EpubPreviewSource? previewSource;
  final Future<void> Function() onRetryPreview;
  final ValueChanged<PreviewSurface> onPreviewSurfaceChanged;
  final ValueChanged<WebPreviewMode> onWebPreviewModeChanged;
  final ValueChanged<double> onPreviewTextScaleChanged;
  final ValueChanged<double> onPreviewWidthChanged;
  final ValueChanged<bool> onToggleTableOfContents;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SectionCard(
            title: '미리보기 설정',
            subtitle: kIsWeb
                ? '실제 생성되는 EPUB 바이트를 스크롤형 또는 페이지형으로 렌더링합니다.'
                : '웹 문서, 이북 리더, 인쇄형 레이아웃을 빠르게 비교합니다.',
            margin: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (kIsWeb)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: WebPreviewMode.values.map((mode) {
                      return ChoiceChip(
                        label: Text(_webModeLabel(mode)),
                        selected: webPreviewMode == mode,
                        onSelected: (_) => onWebPreviewModeChanged(mode),
                      );
                    }).toList(),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: PreviewSurface.values.map((surface) {
                      return ChoiceChip(
                        label: Text(_surfaceLabel(surface)),
                        selected: previewSurface == surface,
                        onSelected: (_) => onPreviewSurfaceChanged(surface),
                      );
                    }).toList(),
                  ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _SliderField(
                        label: '텍스트 크기',
                        valueLabel: '${(previewTextScale * 100).round()}%',
                        value: previewTextScale,
                        min: 0.85,
                        max: 1.3,
                        onChanged: onPreviewTextScaleChanged,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _SliderField(
                        label: '페이지 폭',
                        valueLabel: '${previewWidth.round()}px',
                        value: previewWidth,
                        min: 520,
                        max: 920,
                        onChanged: onPreviewWidthChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('목차 표시'),
                  value: showTableOfContents,
                  onChanged: onToggleTableOfContents,
                ),
                if (kIsWeb) ...[
                  const SizedBox(height: 8),
                  AnimatedBuilder(
                    animation: previewController,
                    builder: (context, child) {
                      final statusText = switch (previewController.status) {
                        EpubPreviewStatus.loading => '생성 중',
                        EpubPreviewStatus.ready => '준비 완료',
                        EpubPreviewStatus.error => '렌더 실패',
                        EpubPreviewStatus.idle => '대기 중',
                      };
                      final detail = previewController.location == null
                          ? ''
                          : ' · ${(previewController.location!.progress * 100).round()}%';

                      return Row(
                        children: [
                          Text(
                            '상태: $statusText$detail',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: previewController.hasError
                                  ? theme.colorScheme.error
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: previewController.isReady
                                ? previewController.previousPage
                                : null,
                            icon: const Icon(Icons.chevron_left),
                            tooltip: '이전 페이지',
                          ),
                          IconButton(
                            onPressed: previewController.isReady
                                ? previewController.nextPage
                                : null,
                            icon: const Icon(Icons.chevron_right),
                            tooltip: '다음 페이지',
                          ),
                          IconButton(
                            onPressed: () => onRetryPreview(),
                            icon: const Icon(Icons.refresh),
                            tooltip: '다시 렌더링',
                          ),
                        ],
                      );
                    },
                  ),
                ],
                if (viewModel.hasImportedStyle) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color:
                            theme.colorScheme.primary.withValues(alpha: 0.12),
                      ),
                    ),
                    child: Text(
                      '"${viewModel.importedStyleSourceName ?? '가져온 EPUB'}"의 CSS와 폰트가 최종 EPUB export와 웹 미리보기에 같이 적용됩니다.',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: _PreviewCanvas(
              viewModel: viewModel,
              previewSurface: previewSurface,
              webPreviewMode: webPreviewMode,
              previewTextScale: previewTextScale,
              previewWidth: previewWidth,
              showTableOfContents: showTableOfContents,
              previewController: previewController,
              previewSource: previewSource,
            ),
          ),
        ],
      ),
    );
  }

  String _surfaceLabel(PreviewSurface surface) {
    switch (surface) {
      case PreviewSurface.reader:
        return '이북 리더';
      case PreviewSurface.browser:
        return '웹 문서';
      case PreviewSurface.print:
        return '인쇄형';
    }
  }

  String _webModeLabel(WebPreviewMode mode) {
    switch (mode) {
      case WebPreviewMode.scrolled:
        return '스크롤형';
      case WebPreviewMode.paginated:
        return '페이지형';
    }
  }
}

class _PreviewCanvas extends StatelessWidget {
  const _PreviewCanvas({
    required this.viewModel,
    required this.previewSurface,
    required this.webPreviewMode,
    required this.previewTextScale,
    required this.previewWidth,
    required this.showTableOfContents,
    required this.previewController,
    required this.previewSource,
  });

  final CreateBookViewModel viewModel;
  final PreviewSurface previewSurface;
  final WebPreviewMode webPreviewMode;
  final double previewTextScale;
  final double previewWidth;
  final bool showTableOfContents;
  final EpubPreviewController previewController;
  final EpubPreviewSource? previewSource;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tocEntries = MarkdownParser.extractTableOfContents(viewModel.content);

    if (viewModel.content.trim().isEmpty && viewModel.coverImageBytes == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.visibility_outlined,
                size: 48,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                '실시간 미리보기',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '본문을 입력하거나 Markdown 파일을 불러오면\n여기에서 EPUB 레이아웃을 확인할 수 있습니다.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final previewStyles = _buildTemplateStyles(
      theme: theme,
      template: viewModel.selectedTemplate,
      scale: previewTextScale,
    );
    final canvasStyle = _previewCanvasStyle(theme, previewSurface);

    if (kIsWeb) {
      return ColoredBox(
        color: theme.colorScheme.surfaceContainerLow,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Center(
            child: Container(
              width: previewWidth,
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: AnimatedBuilder(
                animation: previewController,
                builder: (context, child) {
                  final navigation = previewController.navigation;
                  final errorText = previewController.errorMessage;
                  final showNavigation =
                      showTableOfContents && navigation.isNotEmpty;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (errorText != null) ...[
                        _PreviewErrorBanner(message: errorText),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        height: 920,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showNavigation) ...[
                              SizedBox(
                                width: 220,
                                child: _WebPreviewNavigationPanel(
                                  items: navigation,
                                  onSelected: previewController.goToHref,
                                ),
                              ),
                              const SizedBox(width: 16),
                            ],
                            Expanded(
                              child: Stack(
                                children: [
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: theme
                                            .colorScheme.surfaceContainerLow,
                                        borderRadius: BorderRadius.circular(18),
                                        border: Border.all(
                                          color:
                                              theme.colorScheme.outlineVariant,
                                        ),
                                      ),
                                      clipBehavior: Clip.antiAlias,
                                      child: previewSource == null
                                          ? const _PreviewLoadingState()
                                          : EpubPreviewFrame(
                                              previewSource: previewSource!,
                                              mode: webPreviewMode,
                                              fontScale: previewTextScale,
                                              controller: previewController,
                                            ),
                                    ),
                                  ),
                                  if (previewController.isLoading)
                                    const Positioned.fill(
                                      child: _PreviewLoadingOverlay(),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );
    }

    final previewHtml = MarkdownParser.parseToHtml(
      viewModel.content,
      options: MarkdownRenderOptions(
        styleClassHints: viewModel.styleClassHints,
      ),
    );

    return ColoredBox(
      color: canvasStyle.outerBackground,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        child: Center(
          child: Container(
            width: previewWidth,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 36),
            decoration: BoxDecoration(
              color: canvasStyle.pageBackground,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
              ),
              boxShadow: canvasStyle.shadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (viewModel.coverImageBytes != null) ...[
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Image.memory(
                        viewModel.coverImageBytes!,
                        width: 240,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                ],
                if (showTableOfContents && tocEntries.isNotEmpty) ...[
                  Text(
                    '목차',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: canvasStyle.textColor,
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
                          color: canvasStyle.textColor,
                          fontWeight: entry.level == 1
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 28),
                  Divider(color: theme.colorScheme.outlineVariant),
                  const SizedBox(height: 28),
                ],
                Html(
                  data: previewHtml,
                  style: previewStyles,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  _PreviewCanvasStyle _previewCanvasStyle(
    ThemeData theme,
    PreviewSurface surface,
  ) {
    switch (surface) {
      case PreviewSurface.reader:
        return _PreviewCanvasStyle(
          outerBackground: theme.colorScheme.surfaceContainerLow,
          pageBackground: theme.colorScheme.surface,
          textColor: theme.colorScheme.onSurface,
          shadow: const [],
        );
      case PreviewSurface.browser:
        return _PreviewCanvasStyle(
          outerBackground: theme.colorScheme.surfaceContainer,
          pageBackground: theme.colorScheme.surface,
          textColor: theme.colorScheme.onSurface,
          shadow: [
            BoxShadow(
              color: theme.colorScheme.shadow,
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        );
      case PreviewSurface.print:
        return _PreviewCanvasStyle(
          outerBackground: theme.colorScheme.surfaceContainerHigh,
          pageBackground: theme.colorScheme.surface,
          textColor: theme.colorScheme.onSurface,
          shadow: [
            BoxShadow(
              color: theme.colorScheme.shadow.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        );
    }
  }

  Map<String, Style> _buildTemplateStyles({
    required ThemeData theme,
    required TemplateType template,
    required double scale,
  }) {
    final baseColor = _previewCanvasStyle(theme, previewSurface).textColor;
    final codeBackground = theme.colorScheme.secondaryContainer;

    final bodyFont = switch (template) {
      TemplateType.novel => 'Noto Serif KR',
      TemplateType.essay || TemplateType.manual => 'Noto Sans KR',
    };

    final bodyFontSize = switch (template) {
          TemplateType.novel => 18.0,
          TemplateType.essay => 17.0,
          TemplateType.manual => 16.0,
        } *
        scale;
    final h1Size = switch (template) {
          TemplateType.novel => 28.0,
          TemplateType.essay => 26.0,
          TemplateType.manual => 24.0,
        } *
        scale;
    final h2Size = switch (template) {
          TemplateType.novel => 24.0,
          TemplateType.essay => 22.0,
          TemplateType.manual => 20.0,
        } *
        scale;
    final h3Size = switch (template) {
          TemplateType.novel => 20.0,
          TemplateType.essay => 19.0,
          TemplateType.manual => 18.0,
        } *
        scale;

    return {
      'body': Style(
        fontFamily: bodyFont,
        fontSize: FontSize(bodyFontSize),
        color: baseColor,
        lineHeight: LineHeight(template == TemplateType.novel ? 1.85 : 1.7),
        margin: Margins.zero,
        padding: HtmlPaddings.zero,
        textAlign: TextAlign.justify,
      ),
      'h1': Style(
        fontFamily: bodyFont,
        fontSize: FontSize(h1Size),
        fontWeight: FontWeight.w700,
        textAlign:
            template == TemplateType.novel ? TextAlign.center : TextAlign.left,
        margin: Margins(top: Margin(32), bottom: Margin(16)),
        color: baseColor,
      ),
      'h2': Style(
        fontFamily: bodyFont,
        fontSize: FontSize(h2Size),
        fontWeight: FontWeight.w700,
        textAlign:
            template == TemplateType.novel ? TextAlign.center : TextAlign.left,
        margin: Margins(top: Margin(26), bottom: Margin(14)),
        color: baseColor,
      ),
      'h3': Style(
        fontFamily: bodyFont,
        fontSize: FontSize(h3Size),
        fontWeight: FontWeight.w700,
        margin: Margins(top: Margin(22), bottom: Margin(12)),
        color: baseColor,
      ),
      'p': Style(
        fontFamily: bodyFont,
        fontSize: FontSize(bodyFontSize),
        margin: Margins(bottom: Margin(14)),
        textAlign: TextAlign.justify,
        color: baseColor,
      ),
      'ul': Style(
        fontSize: FontSize(bodyFontSize),
        padding: HtmlPaddings(left: HtmlPadding(28)),
        margin: Margins(top: Margin(10), bottom: Margin(12)),
      ),
      'ol': Style(
        fontSize: FontSize(bodyFontSize),
        padding: HtmlPaddings(left: HtmlPadding(28)),
        margin: Margins(top: Margin(10), bottom: Margin(12)),
      ),
      'li': Style(margin: Margins(bottom: Margin(8))),
      'strong': Style(fontWeight: FontWeight.w700),
      'em': Style(fontStyle: FontStyle.italic),
      'code': Style(
        fontFamily: 'Roboto Mono',
        fontSize: FontSize(bodyFontSize * 0.92),
        backgroundColor: codeBackground,
        padding: HtmlPaddings.all(6),
      ),
      'table': Style(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        margin: Margins(top: Margin(16), bottom: Margin(16)),
      ),
      'th': Style(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        padding: HtmlPaddings.all(8),
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        fontWeight: FontWeight.w700,
      ),
      'td': Style(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        padding: HtmlPaddings.all(8),
      ),
      'img': Style(
        width: Width(100, Unit.percent),
        height: Height.auto(),
        display: Display.block,
        margin: Margins(top: Margin(12), bottom: Margin(12)),
      ),
      'a': Style(
        color: theme.colorScheme.primary,
        textDecoration: TextDecoration.none,
      ),
      '.center': Style(textAlign: TextAlign.center),
      'blockquote': Style(
        margin: Margins(top: Margin(16), bottom: Margin(16)),
        padding: HtmlPaddings(
            left: HtmlPadding(16), top: HtmlPadding(8), bottom: HtmlPadding(8)),
        border: Border(
          left: BorderSide(
            color: theme.colorScheme.outline,
            width: 4,
          ),
        ),
      ),
    };
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({
    required this.isBusy,
    required this.onSaveDraft,
    required this.onGenerate,
  });

  final bool isBusy;
  final Future<void> Function() onSaveDraft;
  final Future<void> Function() onGenerate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border(
            top: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: isBusy ? null : onSaveDraft,
                icon: const Icon(Icons.save_outlined),
                label: const Text('임시 저장'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: isBusy ? null : onGenerate,
                icon: isBusy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        kIsWeb ? Icons.download_outlined : Icons.auto_awesome),
                label: Text(kIsWeb ? 'EPUB 다운로드' : 'EPUB 생성'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoverPickerCard extends StatelessWidget {
  const _CoverPickerCard({
    required this.viewModel,
    required this.onPickCover,
    required this.onRemoveCover,
  });

  final CreateBookViewModel viewModel;
  final Future<void> Function() onPickCover;
  final VoidCallback onRemoveCover;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onPickCover,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: viewModel.coverImageBytes != null
            ? Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(
                      viewModel.coverImageBytes!,
                      width: 72,
                      height: 108,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('표지 이미지 선택됨', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          '클릭해서 교체하거나 제거할 수 있습니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: onRemoveCover,
                    icon: Icon(Icons.close, color: theme.colorScheme.error),
                    tooltip: '제거',
                  ),
                ],
              )
            : Row(
                children: [
                  Container(
                    width: 72,
                    height: 108,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      color: theme.colorScheme.secondary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('표지 이미지 추가', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 4),
                        Text(
                          'JPG, PNG, WebP를 지원합니다.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, color: theme.colorScheme.secondary),
                ],
              ),
      ),
    );
  }
}

class _ImportedStyleCard extends StatelessWidget {
  const _ImportedStyleCard({
    required this.viewModel,
    required this.onApplyStructureTemplate,
    required this.onInsertStructureEntry,
    required this.onClearImportedStyle,
  });

  final CreateBookViewModel viewModel;
  final VoidCallback onApplyStructureTemplate;
  final ValueChanged<StructureReferenceEntry> onInsertStructureEntry;
  final VoidCallback onClearImportedStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!viewModel.hasImportedStyle) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(
          '아직 연결된 EPUB 스타일 레퍼런스가 없습니다. 가져온 CSS와 폰트는 웹 미리보기와 최종 export에 함께 적용됩니다.',
          style: theme.textTheme.bodyMedium,
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  viewModel.importedStyleSourceName ?? '가져온 EPUB 스타일',
                  style: theme.textTheme.titleSmall,
                ),
              ),
              TextButton(
                onPressed: onClearImportedStyle,
                child: const Text('레퍼런스 해제'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '현재 초안은 Markdown을 유지하고, 최종 EPUB과 웹 미리보기에는 가져온 CSS와 폰트가 적용됩니다. 이미지는 가져오지 않습니다.',
            style: theme.textTheme.bodyMedium,
          ),
          if (viewModel.importedStyleReferenceTitle != null ||
              viewModel.importedStyleReferenceAuthor != null) ...[
            const SizedBox(height: 12),
            Text(
              '참조 문서: ${viewModel.importedStyleReferenceTitle ?? '제목 없음'}'
              '${viewModel.importedStyleReferenceAuthor == null ? '' : ' · ${viewModel.importedStyleReferenceAuthor}'}',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (viewModel.hasImportedFonts) ...[
            const SizedBox(height: 12),
            Text(
              '가져온 폰트 ${viewModel.importedFontCount}개',
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (!viewModel.styleClassHints.isEmpty) ...[
            const SizedBox(height: 12),
            Text(
              '스타일 클래스 힌트가 감지되었습니다. heading/paragraph/list에 참조 CSS 클래스가 함께 주입됩니다.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
          ],
          if (viewModel.structureReference.isNotEmpty) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Text('구조 참조', style: theme.textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: onApplyStructureTemplate,
                  icon: const Icon(Icons.auto_awesome_outlined),
                  label: const Text('구조 템플릿 삽입'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...viewModel.structureReference.take(8).map(
                  (entry) => Padding(
                    padding: EdgeInsets.only(
                      left: (entry.level - 1) * 12,
                      bottom: 6,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.title,
                            style: theme.textTheme.bodySmall,
                          ),
                        ),
                        TextButton(
                          onPressed: () => onInsertStructureEntry(entry),
                          child: const Text('삽입'),
                        ),
                      ],
                    ),
                  ),
                ),
            if (viewModel.structureReference.length > 8)
              Text(
                '외 ${viewModel.structureReference.length - 8}개 항목',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
          ],
          if (viewModel.importWarnings.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...viewModel.importWarnings.map(
              (warning) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text(
                  '주의: $warning',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.secondary,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TemplateSelector extends StatelessWidget {
  const _TemplateSelector({required this.viewModel});

  final CreateBookViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '템플릿',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: TemplateType.values.map((template) {
            final selected = viewModel.selectedTemplate == template;
            return ChoiceChip(
              selected: selected,
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(template.displayName),
                  Text(
                    template.description,
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
              onSelected: (_) => viewModel.selectTemplate(template),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filledTonal(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      visualDensity: VisualDensity.compact,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.trailing,
    this.margin = const EdgeInsets.fromLTRB(20, 0, 20, 0),
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final Widget? trailing;
  final EdgeInsets margin;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: margin,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (trailing != null) trailing!,
                ],
              ),
              const SizedBox(height: 16),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Text(label),
    );
  }
}

class _SliderField extends StatelessWidget {
  const _SliderField({
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label · $valueLabel'),
        Slider(
          value: value,
          min: min,
          max: max,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _EditorStats {
  const _EditorStats({
    required this.paragraphCount,
    required this.headingCount,
    required this.wordCount,
    required this.readingMinutes,
  });

  factory _EditorStats.fromContent(String content) {
    final trimmed = content.trim();
    final paragraphCount = trimmed.isEmpty
        ? 0
        : trimmed
            .split(RegExp(r'\n\s*\n'))
            .where((item) => item.trim().isNotEmpty)
            .length;
    final headingCount = MarkdownParser.extractTableOfContents(content).length;
    final wordCount = trimmed.isEmpty
        ? 0
        : trimmed.split(RegExp(r'\s+')).where((item) => item.isNotEmpty).length;
    final readingMinutes = wordCount == 0 ? 0 : (wordCount / 220).ceil();

    return _EditorStats(
      paragraphCount: paragraphCount,
      headingCount: headingCount,
      wordCount: wordCount,
      readingMinutes: readingMinutes,
    );
  }

  final int paragraphCount;
  final int headingCount;
  final int wordCount;
  final int readingMinutes;
}

class _PreviewCanvasStyle {
  const _PreviewCanvasStyle({
    required this.outerBackground,
    required this.pageBackground,
    required this.textColor,
    required this.shadow,
  });

  final Color outerBackground;
  final Color pageBackground;
  final Color textColor;
  final List<BoxShadow> shadow;
}

class _PreviewErrorBanner extends StatelessWidget {
  const _PreviewErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onErrorContainer,
        ),
      ),
    );
  }
}

class _PreviewLoadingState extends StatelessWidget {
  const _PreviewLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

class _PreviewLoadingOverlay extends StatelessWidget {
  const _PreviewLoadingOverlay();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.72),
      child: const Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _WebPreviewNavigationPanel extends StatelessWidget {
  const _WebPreviewNavigationPanel({
    required this.items,
    required this.onSelected,
  });

  final List<PreviewNavigationItem> items;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Text('목차', style: theme.textTheme.titleSmall),
          ),
          Divider(color: theme.colorScheme.outlineVariant, height: 1),
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 10),
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final item = items[index];
                return Padding(
                  padding: EdgeInsets.only(
                    left: 14 + (item.depth * 12),
                    right: 10,
                  ),
                  child: TextButton(
                    onPressed: () => onSelected(item.href),
                    style: TextButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 10,
                      ),
                    ),
                    child: Text(
                      item.label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
