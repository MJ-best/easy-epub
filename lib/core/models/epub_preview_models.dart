import 'package:flutter/foundation.dart';

enum WebPreviewMode { scrolled, paginated }

enum EpubPreviewStatus { idle, loading, ready, error }

class EpubPreviewSource {
  const EpubPreviewSource({
    required this.bytes,
    required this.fileName,
  });

  final Uint8List bytes;
  final String fileName;
}

class PreviewNavigationItem {
  const PreviewNavigationItem({
    required this.label,
    required this.href,
    required this.depth,
  });

  factory PreviewNavigationItem.fromJson(Map<String, dynamic> json) {
    return PreviewNavigationItem(
      label: json['label'] as String? ?? '',
      href: json['href'] as String? ?? '',
      depth: json['depth'] as int? ?? 0,
    );
  }

  final String label;
  final String href;
  final int depth;
}

class PreviewLocation {
  const PreviewLocation({
    required this.href,
    required this.chapterTitle,
    required this.progress,
  });

  factory PreviewLocation.fromJson(Map<String, dynamic> json) {
    return PreviewLocation(
      href: json['href'] as String? ?? '',
      chapterTitle: json['chapterTitle'] as String? ?? '',
      progress: (json['progress'] as num?)?.toDouble() ?? 0,
    );
  }

  final String href;
  final String chapterTitle;
  final double progress;
}

class EpubPreviewController extends ChangeNotifier {
  EpubPreviewStatus _status = EpubPreviewStatus.idle;
  String? _errorMessage;
  List<PreviewNavigationItem> _navigation = const [];
  PreviewLocation? _location;
  Future<void> Function()? _nextPage;
  Future<void> Function()? _previousPage;
  Future<void> Function(String href)? _goToHref;

  EpubPreviewStatus get status => _status;
  String? get errorMessage => _errorMessage;
  List<PreviewNavigationItem> get navigation => List.unmodifiable(_navigation);
  PreviewLocation? get location => _location;
  bool get isLoading => _status == EpubPreviewStatus.loading;
  bool get isReady => _status == EpubPreviewStatus.ready;
  bool get hasError => _status == EpubPreviewStatus.error;

  void setLoading() {
    _status = EpubPreviewStatus.loading;
    _errorMessage = null;
    _navigation = const [];
    _location = null;
    notifyListeners();
  }

  void setReady() {
    _status = EpubPreviewStatus.ready;
    _errorMessage = null;
    notifyListeners();
  }

  void setError(String message) {
    _status = EpubPreviewStatus.error;
    _errorMessage = message;
    _navigation = const [];
    _location = null;
    notifyListeners();
  }

  void setNavigation(List<PreviewNavigationItem> items) {
    _navigation = List.unmodifiable(items);
    notifyListeners();
  }

  void setLocation(PreviewLocation location) {
    _location = location;
    notifyListeners();
  }

  void attachActions({
    Future<void> Function()? nextPage,
    Future<void> Function()? previousPage,
    Future<void> Function(String href)? goToHref,
  }) {
    _nextPage = nextPage;
    _previousPage = previousPage;
    _goToHref = goToHref;
  }

  void detachActions() {
    _nextPage = null;
    _previousPage = null;
    _goToHref = null;
  }

  Future<void> nextPage() async {
    await _nextPage?.call();
  }

  Future<void> previousPage() async {
    await _previousPage?.call();
  }

  Future<void> goToHref(String href) async {
    await _goToHref?.call(href);
  }

  void reset() {
    _status = EpubPreviewStatus.idle;
    _errorMessage = null;
    _navigation = const [];
    _location = null;
    detachActions();
    notifyListeners();
  }
}
