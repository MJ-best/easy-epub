import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/epub_preview_models.dart';
import '../../domain/entities/book_document.dart';
import '../widgets/epub_preview_frame.dart';

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({
    super.key,
    required this.epubFile,
    required this.title,
    this.document,
    this.fallbackHtml,
  });

  final XFile epubFile;
  final String title;
  final BookDocument? document;
  final String? fallbackHtml;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  final EpubPreviewController _previewController = EpubPreviewController();
  late final Future<EpubPreviewSource?> _previewSourceFuture =
      _loadPreviewSource();
  WebPreviewMode _previewMode = WebPreviewMode.scrolled;
  bool _showTableOfContents = true;

  @override
  void dispose() {
    _previewController.dispose();
    super.dispose();
  }

  Future<EpubPreviewSource?> _loadPreviewSource() async {
    final bytes = await widget.epubFile.readAsBytes();
    if (bytes.isEmpty) {
      return null;
    }

    return EpubPreviewSource(
      bytes: bytes,
      fileName: widget.epubFile.name.isEmpty
          ? '${widget.title}.epub'
          : widget.epubFile.name,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: FutureBuilder<EpubPreviewSource?>(
        future: _previewSourceFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  '웹 EPUB 미리보기를 열지 못했습니다.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            );
          }

          final source = snapshot.data;
          if (source == null) {
            return Center(
              child: Text(
                '미리보기용 EPUB을 찾을 수 없습니다.',
                style: theme.textTheme.bodyMedium,
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '웹 EPUB 미리보기',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '다운로드되는 EPUB과 동일한 바이트를 브라우저에서 직접 렌더링합니다.',
                          style: theme.textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 8),
                        AnimatedBuilder(
                          animation: _previewController,
                          builder: (context, child) {
                            final statusText =
                                switch (_previewController.status) {
                              EpubPreviewStatus.loading => '생성 중',
                              EpubPreviewStatus.ready => '준비 완료',
                              EpubPreviewStatus.error => '렌더 실패',
                              EpubPreviewStatus.idle => '대기 중',
                            };
                            final detail = _previewController.location == null
                                ? ''
                                : ' · ${(_previewController.location!.progress * 100).round()}%';

                            return Text(
                              '상태: $statusText$detail',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: _previewController.hasError
                                    ? theme.colorScheme.error
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: WebPreviewMode.values.map((mode) {
                                return ChoiceChip(
                                  label: Text(
                                    mode == WebPreviewMode.scrolled
                                        ? '스크롤형'
                                        : '페이지형',
                                  ),
                                  selected: _previewMode == mode,
                                  onSelected: (_) {
                                    setState(() => _previewMode = mode);
                                  },
                                );
                              }).toList(),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: _previewController.isReady
                                  ? _previewController.previousPage
                                  : null,
                              icon: const Icon(Icons.chevron_left),
                              tooltip: '이전 페이지',
                            ),
                            IconButton(
                              onPressed: _previewController.isReady
                                  ? _previewController.nextPage
                                  : null,
                              icon: const Icon(Icons.chevron_right),
                              tooltip: '다음 페이지',
                            ),
                            const SizedBox(width: 8),
                            Row(
                              children: [
                                Checkbox(
                                  value: _showTableOfContents,
                                  onChanged: (value) {
                                    setState(() {
                                      _showTableOfContents = value ?? true;
                                    });
                                  },
                                ),
                                const Text('목차'),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 760,
                          child: AnimatedBuilder(
                            animation: _previewController,
                            builder: (context, child) {
                              final showNavigation = _showTableOfContents &&
                                  _previewController.navigation.isNotEmpty;
                              final errorText = _previewController.errorMessage;

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  if (errorText != null) ...[
                                    Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: theme.colorScheme.errorContainer,
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Text(
                                        errorText,
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          color: theme
                                              .colorScheme.onErrorContainer,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                  ],
                                  Expanded(
                                    child: Row(
                                      children: [
                                        if (showNavigation) ...[
                                          SizedBox(
                                            width: 240,
                                            child: _PreviewNavigationList(
                                              items:
                                                  _previewController.navigation,
                                              onSelected:
                                                  _previewController.goToHref,
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
                                                    color: theme.colorScheme
                                                        .surfaceContainerLow,
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20),
                                                    border: Border.all(
                                                      color: theme.colorScheme
                                                          .outlineVariant,
                                                    ),
                                                  ),
                                                  clipBehavior: Clip.antiAlias,
                                                  child: EpubPreviewFrame(
                                                    previewSource: source,
                                                    mode: _previewMode,
                                                    fontScale: 1.0,
                                                    controller:
                                                        _previewController,
                                                  ),
                                                ),
                                              ),
                                              if (_previewController.isLoading)
                                                ColoredBox(
                                                  color: theme
                                                      .colorScheme.surface
                                                      .withValues(alpha: 0.72),
                                                  child: const Center(
                                                    child:
                                                        CircularProgressIndicator(),
                                                  ),
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
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PreviewNavigationList extends StatelessWidget {
  const _PreviewNavigationList({
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
      child: ListView.separated(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        separatorBuilder: (context, index) => const SizedBox(height: 4),
        itemBuilder: (context, index) {
          final item = items[index];
          return Padding(
            padding: EdgeInsets.only(left: item.depth * 12),
            child: TextButton(
              onPressed: () => onSelected(item.href),
              style: TextButton.styleFrom(
                alignment: Alignment.centerLeft,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
    );
  }
}
