// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'مستكشف الملفات';

  @override
  String get actionLabel => 'إجراء';

  @override
  String get languageLabel => 'اللغة';

  @override
  String get themeMode => 'وضع المظهر';

  @override
  String get deepCleanup => 'تنظيف عميق';

  @override
  String get privateFiles => 'الملفات الخاصة';

  @override
  String get savedFiles => 'الملفات المحفوظة';

  @override
  String get downloadsLabel => 'التنزيلات';

  @override
  String get permissionDeniedShort => 'لا يوجد إذن';

  @override
  String get unreadableShort => 'غير قابل للقراءة';

  @override
  String get errorOccurred => 'حدث خطأ ما';

  @override
  String get fileAccessUnavailable => 'لا يمكن الوصول إلى هذا العنصر الآن.';

  @override
  String get fileAccessInvalidPath => 'المسار تالف أو غير صالح.';

  @override
  String get fileAccessDeleted => 'لم يعد من الممكن العثور على العنصر.';

  @override
  String get fileAccessExpectedDirectory => 'هذا المسار ليس مجلدًا صالحًا.';

  @override
  String get fileAccessReadDenied => 'لا يمكن قراءة هذا المجلد.';

  @override
  String get fileAccessPermissionDenied => 'تم رفض الوصول إلى هذا المسار.';

  @override
  String get fileAccessSymbolicLinkUnsupported =>
      'مسارات الروابط الرمزية غير مدعومة.';

  @override
  String fileSyncItemsMissing(int count) {
    return 'تعذر العثور على $count من العناصر المتعقبة وتمت إزالتها من القوائم.';
  }

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get recentlyVisited => 'تمت زيارته مؤخرًا';

  @override
  String get noOpenedFolder => 'لا يوجد مجلد مفتوح بعد.';

  @override
  String get listEnd => '----------  نهاية القائمة  ----------';

  @override
  String get categoryFiles => 'ملفات';

  @override
  String get categoryExcel => 'إكسل';

  @override
  String get categoryImages => 'صور';

  @override
  String get categoryVideos => 'فيديو';

  @override
  String get categoryAudio => 'صوت';

  @override
  String get categoryWord => 'وورد';

  @override
  String get categoryPowerPoint => 'عروض';

  @override
  String get categoryArchives => 'أرشيف';

  @override
  String get categoryPdf => 'بي دي إف';

  @override
  String get categoryText => 'نص';

  @override
  String get folderEmpty => 'لا توجد ملفات أو مجلدات في هذا الدليل.';

  @override
  String get searchHint => 'بحث';

  @override
  String searchMinCharacters(int count) {
    return 'اكتب $count أحرف على الأقل للبحث.';
  }

  @override
  String get noSearchResults => 'لم يتم العثور على نتائج للبحث.';

  @override
  String get createFolder => 'إنشاء مجلد';

  @override
  String get hiddenFiles => 'الملفات المخفية';

  @override
  String get paste => 'لصق';

  @override
  String get deleteWarning => 'تحذير، سيتم حذف العناصر المحددة!';

  @override
  String get delete => 'حذف';

  @override
  String get copy => 'نسخ';

  @override
  String get cut => 'قص';

  @override
  String get cutReady => 'تمت الإضافة إلى الحافظة للنقل';

  @override
  String get save => 'حفظ';

  @override
  String get hide => 'إخفاء';

  @override
  String get share => 'مشاركة';

  @override
  String get rename => 'إعادة تسمية';

  @override
  String get overwrite => 'استبدال';

  @override
  String get copyWithNewName => 'النسخ باسم جديد';

  @override
  String get skip => 'تخطي';

  @override
  String get passwordHint => 'أدخل كلمة المرور';

  @override
  String get incorrectPassword => 'كلمة المرور غير صحيحة';

  @override
  String get forgotHiddenPassword => 'نسيت كلمة المرور';

  @override
  String get hiddenPasswordVerifyDescription =>
      'أدخل كلمة المرور للوصول إلى الملفات المخفية.';

  @override
  String get hiddenPasswordCreateTitle => 'أنشئ كلمة مرور جديدة';

  @override
  String get hiddenPasswordCreateDescription =>
      'أنشئ كلمة مرورك للملفات المخفية.';

  @override
  String get hiddenPasswordCreateAction => 'إنشاء كلمة المرور';

  @override
  String get hiddenPasswordResetTitle => 'حدد كلمة مرور جديدة';

  @override
  String get hiddenPasswordResetDescription =>
      'أنشئ كلمة المرور الجديدة للملفات المخفية.';

  @override
  String get hiddenPasswordUpdateAction => 'تحديث كلمة المرور';

  @override
  String get hiddenPasswordNewHint => 'كلمة المرور الجديدة';

  @override
  String get hiddenPasswordConfirmHint => 'أعد إدخال كلمة المرور الجديدة';

  @override
  String get hiddenPasswordEmptyError => 'لا يمكن أن تكون كلمة المرور فارغة.';

  @override
  String get hiddenPasswordMismatch => 'كلمتا المرور غير متطابقتين.';

  @override
  String get hiddenPasswordUpdateFailed =>
      'تعذر تحديث كلمة المرور. يرجى المحاولة مرة أخرى.';

  @override
  String get hiddenPasswordUpdatedSuccess =>
      'تم تحديث كلمة مرور الملفات المخفية.';

  @override
  String get hiddenPasswordDeviceAuthReason =>
      'قم بالتحقق من قفل الهاتف لإعادة تعيين كلمة مرور الملفات المخفية';

  @override
  String get hiddenPasswordNoSecureLock =>
      'لا يوجد قفل شاشة معد على هاتفك. أعدد قفلاً للجهاز أولاً لإعادة تعيين كلمة المرور.';

  @override
  String get hiddenPasswordResetCancelled => 'تم إلغاء العملية.';

  @override
  String get hiddenPasswordAuthFailed => 'فشل التحقق من الهاتف.';

  @override
  String get hiddenPasswordAuthUnsupported =>
      'التحقق الآمن غير مدعوم على هذا الجهاز.';

  @override
  String get ok => 'موافق';

  @override
  String get cancel => 'إلغاء';

  @override
  String get newFolderDefaultName => 'مجلد جديد';

  @override
  String get deleteSuccess => 'اكتملت عملية الحذف بنجاح';

  @override
  String get copied => 'تم النسخ';

  @override
  String get newFolderCreated => 'تم إنشاء مجلد جديد';

  @override
  String get newFileAdded => 'تمت إضافة ملف جديد';

  @override
  String get renameSuccess => 'اكتملت إعادة التسمية بنجاح';

  @override
  String get savedSuccess => 'تم الحفظ';

  @override
  String get hiddenSuccess => 'تم الإخفاء';

  @override
  String get pasteSuccess => 'اكتملت عملية اللصق بنجاح';

  @override
  String get targetFolderNotFound => 'تعذر العثور على المجلد الهدف.';

  @override
  String get destinationInsideSource =>
      'لا يمكن نسخ المجلد أو نقله إلى داخل نفسه.';

  @override
  String get operationRolledBack =>
      'تعذر إكمال العملية وتم التراجع عن جميع التغييرات.';

  @override
  String get operationRollbackFailed => 'فشلت العملية وتعذر إكمال التراجع.';

  @override
  String get invalidName => 'أدخل اسمًا صالحًا';

  @override
  String get itemAlreadyExists => 'يوجد عنصر آخر بالاسم نفسه';

  @override
  String get insufficientStorageSpace => 'لا توجد مساحة خالية كافية';

  @override
  String get operationDeleting => 'جارٍ حذف العناصر...';

  @override
  String get operationCopying => 'جارٍ نسخ العناصر...';

  @override
  String get operationMoving => 'جارٍ نقل العناصر...';

  @override
  String get operationDeletingProgress => 'عملية الحذف جارية';

  @override
  String get operationCopyingProgress => 'عملية النسخ جارية';

  @override
  String get operationMovingProgress => 'عملية النقل جارية';

  @override
  String get operationCreatingFolderProgress => 'عملية إنشاء المجلد جارية';

  @override
  String get operationRenamingProgress => 'عملية إعادة التسمية جارية';

  @override
  String get operationSyncingRecordsProgress => 'جارٍ مزامنة السجلات';

  @override
  String get operationRefreshingRootProgress => 'جارٍ تحديث قائمة المجلدات';

  @override
  String get operationRefreshingFolderProgress => 'جارٍ تحديث محتوى المجلد';

  @override
  String get operationRefreshingIndexProgress =>
      'جارٍ تحديث فهرس البحث والتصنيفات';

  @override
  String get nameConflictTitle => 'يوجد تعارض في الاسم';

  @override
  String nameConflictMessage(String name) {
    return '$name موجود بالفعل. كيف تريد المتابعة؟';
  }

  @override
  String get cleanupInProgress => 'التنظيف جارٍ...';

  @override
  String get operationCompleted => 'اكتملت العملية';

  @override
  String get cleanerTitle => 'التنظيف العميق';

  @override
  String get cleanerStop => 'إيقاف';

  @override
  String get cleanerStopping => 'جارٍ الإيقاف...';

  @override
  String get cleanerCompleted => 'اكتمل';

  @override
  String get cleanerCleaningInProgress => 'جارٍ التنظيف...';

  @override
  String get cleanerCleaningCurrent => 'التنظيف جارٍ';

  @override
  String get cleanerScanCompleted => 'اكتمل الفحص';

  @override
  String get cleanerScanStopped => 'تم إيقاف الفحص';

  @override
  String get cleanerScanningPrefix => 'جارٍ الفحص';

  @override
  String get cleanerScanSummaryTitle => 'ملخص الفحص';

  @override
  String get cleanerCleaningSummaryTitle => 'ملخص التنظيف';

  @override
  String get cleanerStageCacheFiles => 'ملفات التخزين المؤقت';

  @override
  String get cleanerStageUnusedFiles => 'الملفات غير المستخدمة';

  @override
  String get cleanerStagePackages => 'الحزم';

  @override
  String get cleanerStageResidualFiles => 'الملفات المتبقية';

  @override
  String get cleanerStageMemory => 'الذاكرة';

  @override
  String get temporaryFilesCollected => 'تم فحص الملفات المؤقتة';

  @override
  String get cacheFilesCollected => 'تم فحص ملفات التخزين المؤقت';

  @override
  String cleanupWillFree(String size) {
    return 'سيتم تحرير $size ميجابايت';
  }

  @override
  String get cleanupReady => 'التنظيف جاهز';

  @override
  String get cleanupNothingToClean => 'لم يتم العثور على ملفات للتنظيف';

  @override
  String get cleanupDeleting => 'يجري تنفيذ التنظيف...';

  @override
  String cleanupScannedFiles(int count) {
    return 'الملفات المفحوصة: $count';
  }

  @override
  String cleanupCandidatesFound(int count) {
    return 'ملفات التنظيف: $count';
  }

  @override
  String cleanupRecoverableSpace(String size) {
    return 'المساحة القابلة للاستعادة: $size';
  }

  @override
  String get cleanupConfirmTitle => 'ابدأ التنظيف';

  @override
  String cleanupConfirmMessage(int count, String size) {
    return 'سيتم حذف $count ملف وتحرير $size. هل تريد المتابعة؟';
  }

  @override
  String cleanupDeletedCount(int count) {
    return 'الملفات المحذوفة: $count';
  }

  @override
  String cleanupFailedCount(int count) {
    return 'الملفات الفاشلة: $count';
  }

  @override
  String get cleanupCurrentFile => 'الملف الحالي';

  @override
  String get cleanupReportTitle => 'تقرير التنظيف';

  @override
  String cleanupFreedSpace(String size) {
    return 'المساحة المحررة: $size';
  }

  @override
  String cleanupScanIssues(int count) {
    return 'مشكلات الفحص ($count)';
  }

  @override
  String cleanupDeleteIssues(int count) {
    return 'مشكلات الحذف ($count)';
  }

  @override
  String get clean => 'تنظيف';

  @override
  String categoryIndexPreparing(String category) {
    return 'جارٍ إعداد ملفات $category...';
  }

  @override
  String get navigationMenu => 'القائمة';

  @override
  String get navigationRecent => 'الأخيرة';

  @override
  String get navigationFolders => 'المجلدات';

  @override
  String get navigationSearch => 'بحث';
}
