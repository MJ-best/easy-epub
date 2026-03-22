import 'package:flutter/material.dart';

import '../../core/models/epub_preview_models.dart';

class EpubPreviewFrame extends StatelessWidget {
  const EpubPreviewFrame({
    super.key,
    required this.previewSource,
    required this.mode,
    required this.fontScale,
    required this.controller,
  });

  final EpubPreviewSource previewSource;
  final WebPreviewMode mode;
  final double fontScale;
  final EpubPreviewController controller;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
