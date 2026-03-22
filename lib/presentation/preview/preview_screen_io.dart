import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/book_document.dart';

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
  EpubController? _epubController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    try {
      final bytes = await widget.epubFile.readAsBytes();
      _epubController = EpubController(
        document: EpubDocument.openData(bytes),
      );

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'EPUB 로드 실패: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _epubController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.share, color: theme.colorScheme.primary, size: 24),
            onPressed: _shareEpub,
            tooltip: '공유',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('EPUB 로딩 중...'),
          ],
        ),
      );
    }

    if (_error != null || _epubController == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 72,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 20),
              Text(
                _error ?? '미리보기를 열 수 없습니다.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('돌아가기'),
              ),
            ],
          ),
        ),
      );
    }

    return EpubView(
      controller: _epubController!,
      builders: EpubViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(
          textStyle: TextStyle(
            height: 1.6,
            fontSize: 16,
          ),
        ),
        chapterDividerBuilder: (_) => const Divider(),
      ),
    );
  }

  Future<void> _shareEpub() async {
    try {
      final result = await Share.shareXFiles(
        [widget.epubFile],
        subject: widget.title,
      );
      if (result.status == ShareResultStatus.success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('EPUB를 공유했습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('공유 실패: ${e.toString()}')),
        );
      }
    }
  }
}
