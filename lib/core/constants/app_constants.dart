/// Application-wide constants
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'EasyPub';
  static const String appVersion = '1.0.0';

  // Database
  static const String ebookBoxName = 'ebooks';
  static const String settingsBoxName = 'settings';

  // UI Constants
  static const double minTouchTargetSize = 44.0;
  static const double defaultPadding = 16.0;
  static const double cardBorderRadius = 12.0;
  static const double thumbnailWidth = 120.0;
  static const double thumbnailHeight = 180.0;

  // EPUB Generation
  static const String defaultLanguage = 'ko';
  static const String defaultPublisher = 'EasyPub';

  // File Extensions
  static const String epubExtension = '.epub';

  // Date Format
  static const String dateFormat = 'yyyy-MM-dd HH:mm';
}
