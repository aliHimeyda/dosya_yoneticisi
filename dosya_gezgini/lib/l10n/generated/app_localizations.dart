import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale);

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  static const List<Locale> supportedLocales = [
    Locale('tr'),
    Locale('en'),
    Locale('ar'),
  ];

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'appTitle': 'File Explorer',
      'actionLabel': 'Action',
      'languageLabel': 'Language',
      'themeMode': 'Theme Mode',
      'deepCleanup': 'Deep Cleanup',
      'privateFiles': 'Private Files',
      'savedFiles': 'Saved Files',
      'errorOccurred': 'Something went wrong',
      'tryAgain': 'Try Again',
      'recentlyVisited': 'Recently Visited',
      'noOpenedFolder': 'No opened folder yet.',
      'listEnd': '----------  End of List  ----------',
      'categoryFiles': 'files',
      'categoryExcel': 'excel',
      'categoryImages': 'images',
      'categoryVideos': 'videos',
      'categoryAudio': 'audio',
      'categoryWord': 'word',
      'categoryPowerPoint': 'slides',
      'categoryArchives': 'archive',
      'categoryPdf': 'pdf',
      'categoryText': 'text',
      'folderEmpty': 'There are no files or folders in this directory.',
      'searchHint': 'Search',
      'createFolder': 'Create Folder',
      'hiddenFiles': 'Hidden Files',
      'paste': 'Paste',
      'deleteWarning': 'Warning, selected items will be deleted!',
      'delete': 'Delete',
      'copy': 'Copy',
      'cut': 'Cut',
      'save': 'Save',
      'hide': 'Hide',
      'share': 'Share',
      'rename': 'Rename',
      'passwordHint': 'Enter password',
      'incorrectPassword': 'Incorrect password',
      'ok': 'OK',
      'cancel': 'Cancel',
      'newFolderDefaultName': 'new folder',
      'deleteSuccess': 'Delete completed successfully',
      'copied': 'Copied',
      'newFolderCreated': 'New folder created',
      'newFileAdded': 'New file added',
      'renameSuccess': 'Rename completed successfully',
      'savedSuccess': 'Saved',
      'hiddenSuccess': 'Hidden',
      'cleanupInProgress': 'Cleanup in progress...',
      'operationCompleted': 'Operation completed',
      'temporaryFilesCollected': 'Temporary files scanned',
      'cacheFilesCollected': 'Cache files scanned',
      'clean': 'Clean',
      'navigationMenu': 'Menu',
      'navigationRecent': 'Recent',
      'navigationFolders': 'Folders',
      'navigationSearch': 'Search',
    },
    'tr': {
      'appTitle': 'Dosya Gezgini',
      'actionLabel': 'İşlem',
      'languageLabel': 'Dil',
      'themeMode': 'Tema Modu',
      'deepCleanup': 'Derin Temizleme',
      'privateFiles': 'Özel Dosyalar',
      'savedFiles': 'Kaydedilen Dosyalar',
      'errorOccurred': 'Bir hata oluştu',
      'tryAgain': 'Tekrar Dene',
      'recentlyVisited': 'En Son Gezilenler',
      'noOpenedFolder': 'Henüz açılmış klasör yok.',
      'listEnd': '----------  Liste Sonu  ----------',
      'categoryFiles': 'dosyalar',
      'categoryExcel': 'excel',
      'categoryImages': 'resimler',
      'categoryVideos': 'videolar',
      'categoryAudio': 'ses',
      'categoryWord': 'word',
      'categoryPowerPoint': 'sunum',
      'categoryArchives': 'arşiv',
      'categoryPdf': 'pdf',
      'categoryText': 'metin',
      'folderEmpty': 'Bu klasörde hiç dosya veya dizin yok.',
      'searchHint': 'Arama yap',
      'createFolder': 'Klasör Oluştur',
      'hiddenFiles': 'Gizli Dosyalar',
      'paste': 'Yapıştır',
      'deleteWarning': 'Dikkat, seçimler silinecek!',
      'delete': 'Sil',
      'copy': 'Kopyala',
      'cut': 'Kes',
      'save': 'Kaydet',
      'hide': 'Sakla',
      'share': 'Paylaş',
      'rename': 'Adlandır',
      'passwordHint': 'Şifreyi giriniz',
      'incorrectPassword': 'Şifre hatalı',
      'ok': 'Tamam',
      'cancel': 'İptal',
      'newFolderDefaultName': 'yeni klasör',
      'deleteSuccess': 'Silme işlemi başarılı',
      'copied': 'Kopyalandı',
      'newFolderCreated': 'Yeni klasör oluşturuldu',
      'newFileAdded': 'Yeni dosya eklendi',
      'renameSuccess': 'Adlandırma işlemi başarılı',
      'savedSuccess': 'Kaydedildi',
      'hiddenSuccess': 'Saklandı',
      'cleanupInProgress': 'Temizlik devam ediyor...',
      'operationCompleted': 'İşlem sonlandı',
      'temporaryFilesCollected': 'Geçici dosyalar tarandı',
      'cacheFilesCollected': 'Önbellek dosyaları tarandı',
      'clean': 'Temizle',
      'navigationMenu': 'Menü',
      'navigationRecent': 'Son',
      'navigationFolders': 'Klasörler',
      'navigationSearch': 'Arama',
    },
    'ar': {
      'appTitle': 'مستكشف الملفات',
      'actionLabel': 'إجراء',
      'languageLabel': 'اللغة',
      'themeMode': 'وضع المظهر',
      'deepCleanup': 'تنظيف عميق',
      'privateFiles': 'الملفات الخاصة',
      'savedFiles': 'الملفات المحفوظة',
      'errorOccurred': 'حدث خطأ ما',
      'tryAgain': 'حاول مرة أخرى',
      'recentlyVisited': 'تمت زيارته مؤخرًا',
      'noOpenedFolder': 'لا يوجد مجلد مفتوح بعد.',
      'listEnd': '----------  نهاية القائمة  ----------',
      'categoryFiles': 'ملفات',
      'categoryExcel': 'إكسل',
      'categoryImages': 'صور',
      'categoryVideos': 'فيديو',
      'categoryAudio': 'صوت',
      'categoryWord': 'وورد',
      'categoryPowerPoint': 'عروض',
      'categoryArchives': 'أرشيف',
      'categoryPdf': 'بي دي إف',
      'categoryText': 'نص',
      'folderEmpty': 'لا توجد ملفات أو مجلدات في هذا الدليل.',
      'searchHint': 'بحث',
      'createFolder': 'إنشاء مجلد',
      'hiddenFiles': 'الملفات المخفية',
      'paste': 'لصق',
      'deleteWarning': 'تحذير، سيتم حذف العناصر المحددة!',
      'delete': 'حذف',
      'copy': 'نسخ',
      'cut': 'قص',
      'save': 'حفظ',
      'hide': 'إخفاء',
      'share': 'مشاركة',
      'rename': 'إعادة تسمية',
      'passwordHint': 'أدخل كلمة المرور',
      'incorrectPassword': 'كلمة المرور غير صحيحة',
      'ok': 'موافق',
      'cancel': 'إلغاء',
      'newFolderDefaultName': 'مجلد جديد',
      'deleteSuccess': 'اكتملت عملية الحذف بنجاح',
      'copied': 'تم النسخ',
      'newFolderCreated': 'تم إنشاء مجلد جديد',
      'newFileAdded': 'تمت إضافة ملف جديد',
      'renameSuccess': 'اكتملت إعادة التسمية بنجاح',
      'savedSuccess': 'تم الحفظ',
      'hiddenSuccess': 'تم الإخفاء',
      'cleanupInProgress': 'التنظيف جارٍ...',
      'operationCompleted': 'اكتملت العملية',
      'temporaryFilesCollected': 'تم فحص الملفات المؤقتة',
      'cacheFilesCollected': 'تم فحص ملفات التخزين المؤقت',
      'clean': 'تنظيف',
      'navigationMenu': 'القائمة',
      'navigationRecent': 'الأخيرة',
      'navigationFolders': 'المجلدات',
      'navigationSearch': 'بحث',
    },
  };

  String _value(String key) {
    final normalizedLocale = localeName.split('_').first;
    return _localizedValues[normalizedLocale]?[key] ??
        _localizedValues['en']![key]!;
  }

  String get appTitle => _value('appTitle');
  String get actionLabel => _value('actionLabel');
  String get languageLabel => _value('languageLabel');
  String get themeMode => _value('themeMode');
  String get deepCleanup => _value('deepCleanup');
  String get privateFiles => _value('privateFiles');
  String get savedFiles => _value('savedFiles');
  String get errorOccurred => _value('errorOccurred');
  String get tryAgain => _value('tryAgain');
  String get recentlyVisited => _value('recentlyVisited');
  String get noOpenedFolder => _value('noOpenedFolder');
  String get listEnd => _value('listEnd');
  String get categoryFiles => _value('categoryFiles');
  String get categoryExcel => _value('categoryExcel');
  String get categoryImages => _value('categoryImages');
  String get categoryVideos => _value('categoryVideos');
  String get categoryAudio => _value('categoryAudio');
  String get categoryWord => _value('categoryWord');
  String get categoryPowerPoint => _value('categoryPowerPoint');
  String get categoryArchives => _value('categoryArchives');
  String get categoryPdf => _value('categoryPdf');
  String get categoryText => _value('categoryText');
  String get folderEmpty => _value('folderEmpty');
  String get searchHint => _value('searchHint');
  String get createFolder => _value('createFolder');
  String get hiddenFiles => _value('hiddenFiles');
  String get paste => _value('paste');
  String get deleteWarning => _value('deleteWarning');
  String get delete => _value('delete');
  String get copy => _value('copy');
  String get cut => _value('cut');
  String get save => _value('save');
  String get hide => _value('hide');
  String get share => _value('share');
  String get rename => _value('rename');
  String get passwordHint => _value('passwordHint');
  String get incorrectPassword => _value('incorrectPassword');
  String get ok => _value('ok');
  String get cancel => _value('cancel');
  String get newFolderDefaultName => _value('newFolderDefaultName');
  String get deleteSuccess => _value('deleteSuccess');
  String get copied => _value('copied');
  String get newFolderCreated => _value('newFolderCreated');
  String get newFileAdded => _value('newFileAdded');
  String get renameSuccess => _value('renameSuccess');
  String get savedSuccess => _value('savedSuccess');
  String get hiddenSuccess => _value('hiddenSuccess');
  String get cleanupInProgress => _value('cleanupInProgress');
  String get operationCompleted => _value('operationCompleted');
  String get temporaryFilesCollected => _value('temporaryFilesCollected');
  String get cacheFilesCollected => _value('cacheFilesCollected');
  String get clean => _value('clean');
  String get navigationMenu => _value('navigationMenu');
  String get navigationRecent => _value('navigationRecent');
  String get navigationFolders => _value('navigationFolders');
  String get navigationSearch => _value('navigationSearch');

  String cleanupWillFree(String size) {
    final normalizedLocale = localeName.split('_').first;
    switch (normalizedLocale) {
      case 'tr':
        return '$size MB boşaltılacak';
      case 'ar':
        return 'سيتم تحرير $size ميجابايت';
      default:
        return '$size MB will be freed';
    }
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['tr', 'en', 'ar'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(
      AppLocalizations(locale.languageCode),
    );
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
