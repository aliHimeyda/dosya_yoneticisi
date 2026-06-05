import 'package:dosya_gezgini/app/app.dart';
import 'package:dosya_gezgini/core/localization/locale_provider.dart';
import 'package:dosya_gezgini/core/theme/app_theme.dart';
import 'package:dosya_gezgini/data/repositories/category_repository.dart';
import 'package:dosya_gezgini/data/repositories/directory_cache_repository.dart';
import 'package:dosya_gezgini/data/repositories/file_index_repository.dart';
import 'package:dosya_gezgini/data/repositories/folder_count_repository.dart';
import 'package:dosya_gezgini/data/repositories/hidden_repository.dart';
import 'package:dosya_gezgini/data/repositories/recent_repository.dart';
import 'package:dosya_gezgini/data/repositories/saved_repository.dart';
import 'package:dosya_gezgini/data/repositories/search_repository.dart';
import 'package:dosya_gezgini/data/repositories/thumbnail_cache_repository.dart';
import 'package:dosya_gezgini/data/services/category_query_service.dart';
import 'package:dosya_gezgini/data/services/cleaning_service.dart';
import 'package:dosya_gezgini/data/services/file_index_service.dart';
import 'package:dosya_gezgini/data/services/file_operation_service.dart';
import 'package:dosya_gezgini/data/services/file_system_service.dart';
import 'package:dosya_gezgini/data/services/hive_service.dart';
import 'package:dosya_gezgini/data/services/search_query_service.dart';
import 'package:dosya_gezgini/data/services/thumbnail_cache_service.dart';
import 'package:dosya_gezgini/features/files/state/altislem_provider.dart';
import 'package:dosya_gezgini/features/files/state/dosyaislemleri.dart';
import 'package:dosya_gezgini/features/files/state/izinler.dart';
import 'package:dosya_gezgini/features/menu/state/localestoragebilgileri.dart';
import 'package:dosya_gezgini/features/search/state/search_controller.dart'
    as search_state;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();
  final hiveService = HiveService();
  await hiveService.init();
  final fileIndexRepository = FileIndexRepository(hiveService);
  final directoryCacheRepository = DirectoryCacheRepository(hiveService);
  final folderCountRepository = FolderCountRepository(hiveService);
  final recentRepository = RecentRepository(hiveService);
  final savedRepository = SavedRepository(hiveService);
  final hiddenRepository = HiddenRepository(hiveService);
  final thumbnailCacheRepository = ThumbnailCacheRepository(hiveService);
  final thumbnailCacheService = ThumbnailCacheService(
    repository: thumbnailCacheRepository,
  );
  final fileSystemService = FileSystemService();
  final fileIndexService = FileIndexService(
    repository: fileIndexRepository,
    fileSystemService: fileSystemService,
  );
  final fileOperationService = FileOperationService();
  final cleaningService = CleaningService(
    fileIndexService: fileIndexService,
    thumbnailCacheRepository: thumbnailCacheRepository,
  );
  final categoryRepository = CategoryRepository(
    fileIndexService: fileIndexService,
    categoryQueryService: CategoryQueryService(fileIndexRepository),
  );
  final searchRepository = SearchRepository(
    fileIndexService: fileIndexService,
    searchQueryService: SearchQueryService(fileIndexRepository),
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: AppColors.kuyupembe,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    buildApp(
      hiveService: hiveService,
      fileIndexRepository: fileIndexRepository,
      directoryCacheRepository: directoryCacheRepository,
      folderCountRepository: folderCountRepository,
      recentRepository: recentRepository,
      savedRepository: savedRepository,
      hiddenRepository: hiddenRepository,
      cleaningService: cleaningService,
      fileOperationService: fileOperationService,
      thumbnailCacheRepository: thumbnailCacheRepository,
      thumbnailCacheService: thumbnailCacheService,
      fileIndexService: fileIndexService,
      categoryRepository: categoryRepository,
      searchRepository: searchRepository,
    ),
  );
}

Widget buildApp({
  required HiveService hiveService,
  required FileIndexRepository fileIndexRepository,
  required DirectoryCacheRepository directoryCacheRepository,
  required FolderCountRepository folderCountRepository,
  required RecentRepository recentRepository,
  required SavedRepository savedRepository,
  required HiddenRepository hiddenRepository,
  required CleaningService cleaningService,
  required FileOperationService fileOperationService,
  required ThumbnailCacheRepository thumbnailCacheRepository,
  required ThumbnailCacheService thumbnailCacheService,
  required FileIndexService fileIndexService,
  required CategoryRepository categoryRepository,
  required SearchRepository searchRepository,
}) {
  return MultiProvider(
    providers: [
      Provider<HiveService>.value(value: hiveService),
      Provider<FileIndexRepository>.value(value: fileIndexRepository),
      Provider<DirectoryCacheRepository>.value(value: directoryCacheRepository),
      Provider<FolderCountRepository>.value(value: folderCountRepository),
      Provider<RecentRepository>.value(value: recentRepository),
      Provider<SavedRepository>.value(value: savedRepository),
      Provider<HiddenRepository>.value(value: hiddenRepository),
      Provider<CleaningService>.value(value: cleaningService),
      Provider<FileOperationService>.value(value: fileOperationService),
      Provider<ThumbnailCacheRepository>.value(value: thumbnailCacheRepository),
      Provider<ThumbnailCacheService>.value(value: thumbnailCacheService),
      Provider<FileIndexService>.value(value: fileIndexService),
      Provider<CategoryRepository>.value(value: categoryRepository),
      Provider<SearchRepository>.value(value: searchRepository),
      ChangeNotifierProvider(create: (_) => AppTheme()),
      ChangeNotifierProvider(
        create: (_) => LocaleProvider()..loadSavedLocale(),
      ),
      ChangeNotifierProvider(
        create:
            (_) => Dosyaislemleri(
              savedRepository: savedRepository,
              hiddenRepository: hiddenRepository,
              cleaningService: cleaningService,
              fileOperationService: fileOperationService,
              fileIndexService: fileIndexService,
            ),
      ),
      ChangeNotifierProvider(create: (_) => Altislemprovider()),
      ChangeNotifierProvider(
        create:
            (_) => search_state.SearchController(
              searchRepository: searchRepository,
            ),
      ),
      ChangeNotifierProvider(
        create:
            (_) => Izinler(
              directoryCacheRepository: directoryCacheRepository,
              folderCountRepository: folderCountRepository,
              recentRepository: recentRepository,
              savedRepository: savedRepository,
              hiddenRepository: hiddenRepository,
            )..requestAllStoragePermission(),
      ),
      ChangeNotifierProvider(
        create: (_) => Localestoragebilgileri()..depolamabilgilernigetir(),
      ),
    ],
    child: const DosyaGezginiApp(),
  );
}
