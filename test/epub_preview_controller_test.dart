import 'package:easypub/core/models/epub_preview_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EpubPreviewController', () {
    test('status, navigation, and location transitions are tracked', () {
      final controller = EpubPreviewController();

      expect(controller.status, EpubPreviewStatus.idle);
      expect(controller.navigation, isEmpty);
      expect(controller.location, isNull);

      controller.setLoading();
      expect(controller.status, EpubPreviewStatus.loading);
      expect(controller.errorMessage, isNull);

      controller.setNavigation(
        const [
          PreviewNavigationItem(
              label: '1장', href: 'Text/chapter01.xhtml', depth: 0),
        ],
      );
      controller.setLocation(
        const PreviewLocation(
          href: 'Text/chapter01.xhtml',
          chapterTitle: '1장',
          progress: 0.4,
        ),
      );
      controller.setReady();

      expect(controller.status, EpubPreviewStatus.ready);
      expect(controller.navigation.single.label, '1장');
      expect(controller.location?.chapterTitle, '1장');

      controller.setError('render failed');
      expect(controller.status, EpubPreviewStatus.error);
      expect(controller.errorMessage, 'render failed');
      expect(controller.navigation, isEmpty);
      expect(controller.location, isNull);

      controller.reset();
      expect(controller.status, EpubPreviewStatus.idle);
      expect(controller.errorMessage, isNull);
      expect(controller.navigation, isEmpty);
      expect(controller.location, isNull);
    });

    test('attached actions are invoked and cleared by reset', () async {
      final controller = EpubPreviewController();
      var nextCalls = 0;
      var previousCalls = 0;
      String? lastHref;

      controller.attachActions(
        nextPage: () async => nextCalls += 1,
        previousPage: () async => previousCalls += 1,
        goToHref: (href) async => lastHref = href,
      );

      await controller.nextPage();
      await controller.previousPage();
      await controller.goToHref('Text/chapter02.xhtml');

      expect(nextCalls, 1);
      expect(previousCalls, 1);
      expect(lastHref, 'Text/chapter02.xhtml');

      controller.reset();
      await controller.nextPage();
      await controller.previousPage();
      await controller.goToHref('Text/chapter03.xhtml');

      expect(nextCalls, 1);
      expect(previousCalls, 1);
      expect(lastHref, 'Text/chapter02.xhtml');
    });
  });
}
