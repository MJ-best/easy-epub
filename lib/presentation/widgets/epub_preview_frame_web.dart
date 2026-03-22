import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_util' as js_util;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

import '../../core/models/epub_preview_models.dart';

class EpubPreviewFrame extends StatefulWidget {
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
  State<EpubPreviewFrame> createState() => _EpubPreviewFrameState();
}

class _EpubPreviewFrameState extends State<EpubPreviewFrame> {
  static var _nextId = 0;

  late final html.DivElement _hostElement;
  late final String _viewType;
  late final html.EventListener _readyListener;
  late final html.EventListener _relocatedListener;
  late final html.EventListener _errorListener;

  int _sessionGeneration = 0;
  String? _sessionId;

  @override
  void initState() {
    super.initState();
    _viewType = 'epub-preview-frame-${_nextId++}';
    _hostElement = html.DivElement()
      ..style.border = '0'
      ..style.width = '100%'
      ..style.height = '100%'
      ..style.backgroundColor = 'transparent'
      ..style.overflow = 'hidden';

    _readyListener = _handleReady;
    _relocatedListener = _handleRelocated;
    _errorListener = _handleError;

    _hostElement.addEventListener('easy-epub-ready', _readyListener);
    _hostElement.addEventListener('easy-epub-relocated', _relocatedListener);
    _hostElement.addEventListener('easy-epub-error', _errorListener);

    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (viewId) => _hostElement,
    );

    widget.controller.attachActions(
      nextPage: _nextPage,
      previousPage: _previousPage,
      goToHref: _goToHref,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _recreateSession();
      }
    });
  }

  @override
  void didUpdateWidget(covariant EpubPreviewFrame oldWidget) {
    super.didUpdateWidget(oldWidget);

    widget.controller.attachActions(
      nextPage: _nextPage,
      previousPage: _previousPage,
      goToHref: _goToHref,
    );

    if (oldWidget.previewSource != widget.previewSource) {
      _recreateSession();
      return;
    }

    if (oldWidget.mode != widget.mode) {
      _setFlow();
    }

    if (oldWidget.fontScale != widget.fontScale) {
      _setFontScale();
    }
  }

  @override
  void dispose() {
    widget.controller.detachActions();
    _hostElement.removeEventListener('easy-epub-ready', _readyListener);
    _hostElement.removeEventListener('easy-epub-relocated', _relocatedListener);
    _hostElement.removeEventListener('easy-epub-error', _errorListener);
    _disposeSession();
    super.dispose();
  }

  Object? get _bridge {
    if (!js_util.hasProperty(html.window, 'easyEpubPreview')) {
      return null;
    }
    return js_util.getProperty(html.window, 'easyEpubPreview');
  }

  String? get _bridgeAvailabilityError {
    final bridge = _bridge;
    if (bridge == null) {
      return '웹 EPUB 렌더러 자산을 찾을 수 없습니다.';
    }
    if (js_util.hasProperty(bridge, 'isAvailable') &&
        js_util.callMethod<bool>(bridge, 'isAvailable', const []) == true) {
      return null;
    }
    if (js_util.hasProperty(bridge, 'availabilityError')) {
      final result = js_util.callMethod<Object?>(
        bridge,
        'availabilityError',
        const [],
      );
      if (result is String && result.isNotEmpty) {
        return result;
      }
    }
    return '웹 EPUB 렌더러 자산을 찾을 수 없습니다.';
  }

  String get _modeValue =>
      widget.mode == WebPreviewMode.paginated ? 'paginated' : 'scrolled-doc';

  Future<void> _recreateSession() async {
    final bridge = _bridge;
    final availabilityError = _bridgeAvailabilityError;
    if (bridge == null || availabilityError != null) {
      widget.controller.setError(
        availabilityError ?? '웹 EPUB 렌더러 자산을 찾을 수 없습니다.',
      );
      return;
    }

    final generation = ++_sessionGeneration;
    widget.controller.setLoading();
    _disposeSession();

    final blob = html.Blob(
      [widget.previewSource.bytes],
      'application/epub+zip',
    );
    final objectUrl = html.Url.createObjectUrl(blob);

    try {
      final createPromise = js_util.callMethod<Object>(
        bridge,
        'create',
        [
          _hostElement,
          objectUrl,
          js_util.jsify({
            'flow': _modeValue,
            'fontScale': (widget.fontScale * 100).round(),
          }),
        ],
      );
      final result = await js_util.promiseToFuture<Object>(createPromise);
      if (!mounted || generation != _sessionGeneration) {
        if (result is String) {
          await js_util.promiseToFuture<Object?>(
            js_util.callMethod<Object>(
              bridge,
              'dispose',
              [result],
            ),
          );
        }
        return;
      }

      _sessionId = result as String?;
      _setFontScale();
    } catch (error) {
      if (!mounted || generation != _sessionGeneration) {
        return;
      }
      widget.controller.setError('웹 EPUB 렌더러를 초기화하지 못했습니다.\n$error');
    }
  }

  void _disposeSession() {
    final bridge = _bridge;
    final currentSession = _sessionId;
    _sessionId = null;
    _hostElement.setAttribute('data-navigation', '[]');
    _hostElement.removeAttribute('data-location');
    _hostElement.removeAttribute('data-error');

    if (bridge != null && currentSession != null) {
      js_util.callMethod<Object?>(
        bridge,
        'dispose',
        [currentSession],
      );
      return;
    }

    _hostElement.children.clear();
  }

  Future<void> _setFlow() async {
    final bridge = _bridge;
    if (bridge == null || _sessionId == null) {
      return;
    }

    widget.controller.setLoading();
    try {
      await js_util.promiseToFuture<Object>(
        js_util.callMethod<Object>(
          bridge,
          'setFlow',
          [_sessionId, _modeValue],
        ),
      );
      _setFontScale();
    } catch (error) {
      widget.controller.setError('미리보기 모드를 전환하지 못했습니다.\n$error');
    }
  }

  void _setFontScale() {
    final bridge = _bridge;
    if (bridge == null || _sessionId == null) {
      return;
    }

    js_util.callMethod<void>(
      bridge,
      'setFontScale',
      [_sessionId, (widget.fontScale * 100).round()],
    );
  }

  Future<void> _nextPage() async {
    final bridge = _bridge;
    if (bridge == null || _sessionId == null) {
      return;
    }

    try {
      await js_util.promiseToFuture<Object>(
        js_util.callMethod<Object>(
          bridge,
          'next',
          [_sessionId],
        ),
      );
    } catch (error) {
      widget.controller.setError('다음 페이지로 이동하지 못했습니다.\n$error');
    }
  }

  Future<void> _previousPage() async {
    final bridge = _bridge;
    if (bridge == null || _sessionId == null) {
      return;
    }

    try {
      await js_util.promiseToFuture<Object>(
        js_util.callMethod<Object>(
          bridge,
          'prev',
          [_sessionId],
        ),
      );
    } catch (error) {
      widget.controller.setError('이전 페이지로 이동하지 못했습니다.\n$error');
    }
  }

  Future<void> _goToHref(String href) async {
    final bridge = _bridge;
    if (bridge == null || _sessionId == null) {
      return;
    }

    try {
      await js_util.promiseToFuture<Object>(
        js_util.callMethod<Object>(
          bridge,
          'goToHref',
          [_sessionId, href],
        ),
      );
    } catch (error) {
      widget.controller.setError('목차 이동에 실패했습니다.\n$error');
    }
  }

  void _handleReady(html.Event event) {
    if (!_isCurrentSessionEvent(event)) {
      return;
    }
    final navigation = _readNavigation();
    widget.controller.setNavigation(navigation);
    widget.controller.setReady();

    final location = _readLocation();
    if (location != null) {
      widget.controller.setLocation(location);
    }
  }

  void _handleRelocated(html.Event event) {
    if (!_isCurrentSessionEvent(event)) {
      return;
    }
    final location = _readLocation();
    if (location != null) {
      widget.controller.setLocation(location);
    }
  }

  void _handleError(html.Event event) {
    if (!_isCurrentSessionEvent(event)) {
      return;
    }
    widget.controller.setError(
      _hostElement.getAttribute('data-error') ?? '웹 EPUB 렌더링 중 오류가 발생했습니다.',
    );
  }

  bool _isCurrentSessionEvent(html.Event event) {
    final sessionId = _eventSessionId(event);
    return sessionId == null || sessionId == _sessionId;
  }

  String? _eventSessionId(html.Event event) {
    if (event is! html.CustomEvent) {
      return null;
    }
    final detail = event.detail;
    if (detail is String) {
      return detail;
    }
    if (detail == null) {
      return null;
    }
    try {
      final sessionId = js_util.getProperty<Object?>(detail, 'sessionId');
      return sessionId is String ? sessionId : null;
    } catch (_) {
      return null;
    }
  }

  List<PreviewNavigationItem> _readNavigation() {
    final raw = _hostElement.getAttribute('data-navigation');
    if (raw == null || raw.isEmpty) {
      return const [];
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return const [];
      }
      return decoded
          .whereType<Map>()
          .map((item) => PreviewNavigationItem.fromJson(
                item.cast<String, dynamic>(),
              ))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  PreviewLocation? _readLocation() {
    final raw = _hostElement.getAttribute('data-location');
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        return null;
      }
      return PreviewLocation.fromJson(decoded.cast<String, dynamic>());
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
