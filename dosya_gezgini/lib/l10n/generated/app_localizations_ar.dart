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
  String get errorOccurred => 'حدث خطأ ما';

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
  String get invalidName => 'أدخل اسماً صالحاً';

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
  String get temporaryFilesCollected => 'تم فحص الملفات المؤقتة';

  @override
  String get cacheFilesCollected => 'تم فحص ملفات التخزين المؤقت';

  @override
  String cleanupWillFree(String size) {
    return 'سيتم تحرير $size ميجابايت';
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
