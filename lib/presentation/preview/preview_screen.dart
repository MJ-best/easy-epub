import 'dart:io';
import 'package:flutter/material.dart';
import 'package:epub_view/epub_view.dart';
import 'package:share_plus/share_plus.dart';

/// Screen for previewing EPUB files
/// Uses epub_view package for rendering
class PreviewScreen extends StatefulWidget {
  final String epubPath;

  const PreviewScreen({
    super.key,
    required this.epubPath,
  });

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late EpubController _epubController;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadEpub();
  }

  Future<void> _loadEpub() async {
    try {
      final file = File(widget.epubPath);
      if (!await file.exists()) {
        setState(() {
          _error = 'EPUB 파일을 찾을 수 없습니다';
          _isLoading = false;
        });
        return;
      }

      final bytes = await file.readAsBytes();
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
    _epubController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(
          '미리보기',
          style: theme.textTheme.titleLarge,
        ),
        actions: [
          Semantics(
            label: '공유',
            button: true,
            child: IconButton(
              icon: Icon(Icons.share, color: theme.colorScheme.primary, size: 26),
              onPressed: _shareEpub,
              tooltip: '공유',
            ),
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

    if (_error != null) {
      return Center(
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
              _error!,
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
      );
    }

    return EpubView(
      controller: _epubController,
      onExternalLinkPressed: (href) {
        // Handle external links if needed
      },
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
      final file = File(widget.epubPath);
      if (await file.exists()) {
        await Share.shareXFiles(
          [XFile(widget.epubPath)],
          subject: 'EPUB 전자책 공유',
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
