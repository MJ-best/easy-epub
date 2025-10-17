import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/providers/theme_provider.dart';
import 'data/models/ebook_model.dart';
import 'data/repositories/ebook_repository_impl.dart';
import 'data/services/epub_generator_service_v2.dart';
import 'presentation/home/home_screen.dart';
import 'presentation/viewmodels/library_viewmodel.dart';
import 'presentation/viewmodels/create_book_viewmodel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(EbookModelAdapter());

  // Initialize repository
  final repository = EbookRepositoryImpl();
  await repository.init();

  // Initialize services
  final epubGenerator = EpubGeneratorServiceV2();

  runApp(
    EasyPubApp(
      repository: repository,
      epubGenerator: epubGenerator,
    ),
  );
}

/// Main application widget
class EasyPubApp extends StatelessWidget {
  final EbookRepositoryImpl repository;
  final EpubGeneratorServiceV2 epubGenerator;

  const EasyPubApp({
    super.key,
    required this.repository,
    required this.epubGenerator,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Theme provider
        ChangeNotifierProvider(create: (_) => ThemeProvider()),

        // Repository provider
        Provider<EbookRepositoryImpl>.value(value: repository),

        // Service provider
        Provider<EpubGeneratorServiceV2>.value(value: epubGenerator),

        // ViewModel providers
        ChangeNotifierProvider(
          create: (_) => LibraryViewModel(repository)..loadEbooks(),
        ),
        ChangeNotifierProvider(
          create: (_) => CreateBookViewModel(repository, epubGenerator),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: AppConstants.APP_NAME,
            debugShowCheckedModeBanner: false,

            // Theme configuration
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,

            // Localization
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('ko', 'KR'),
              Locale('en', 'US'),
            ],
            locale: const Locale('ko', 'KR'),

            // Home screen
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
