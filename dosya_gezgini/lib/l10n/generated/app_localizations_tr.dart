// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Turkish (`tr`).
class AppLocalizationsTr extends AppLocalizations {
  AppLocalizationsTr([String locale = 'tr']) : super(locale);

  @override
  String get appTitle => 'Dosya Gezgini';

  @override
  String get actionLabel => 'İşlem';

  @override
  String get languageLabel => 'Dil';

  @override
  String get themeMode => 'Tema Modu';

  @override
  String get deepCleanup => 'Derin Temizleme';

  @override
  String get privateFiles => 'Özel Dosyalar';

  @override
  String get savedFiles => 'Kaydedilen Dosyalar';

  @override
  String get errorOccurred => 'Bir hata oluştu';

  @override
  String get tryAgain => 'Tekrar Dene';

  @override
  String get recentlyVisited => 'En Son Gezilenler';

  @override
  String get noOpenedFolder => 'Henüz açılmış klasör yok.';

  @override
  String get listEnd => '----------  Liste Sonu  ----------';

  @override
  String get categoryFiles => 'dosyalar';

  @override
  String get categoryExcel => 'excel';

  @override
  String get categoryImages => 'resimler';

  @override
  String get categoryVideos => 'videolar';

  @override
  String get categoryAudio => 'ses';

  @override
  String get categoryWord => 'word';

  @override
  String get categoryPowerPoint => 'sunum';

  @override
  String get categoryArchives => 'arşiv';

  @override
  String get categoryPdf => 'pdf';

  @override
  String get categoryText => 'metin';

  @override
  String get folderEmpty => 'Bu klasörde hiç dosya veya dizin yok.';

  @override
  String get searchHint => 'Arama yap';

  @override
  String searchMinCharacters(int count) {
    return 'Arama için en az $count karakter yazın.';
  }

  @override
  String get noSearchResults => 'Arama sonucu bulunamadı.';

  @override
  String get createFolder => 'Klasör Oluştur';

  @override
  String get hiddenFiles => 'Gizli Dosyalar';

  @override
  String get paste => 'Yapıştır';

  @override
  String get deleteWarning => 'Dikkat, seçimler silinecek!';

  @override
  String get delete => 'Sil';

  @override
  String get copy => 'Kopyala';

  @override
  String get cut => 'Kes';

  @override
  String get save => 'Kaydet';

  @override
  String get hide => 'Sakla';

  @override
  String get share => 'Paylaş';

  @override
  String get rename => 'Adlandır';

  @override
  String get passwordHint => 'Şifreyi giriniz';

  @override
  String get incorrectPassword => 'Şifre hatalı';

  @override
  String get ok => 'Tamam';

  @override
  String get cancel => 'İptal';

  @override
  String get newFolderDefaultName => 'yeni klasör';

  @override
  String get deleteSuccess => 'Silme işlemi başarılı';

  @override
  String get copied => 'Kopyalandı';

  @override
  String get newFolderCreated => 'Yeni klasör oluşturuldu';

  @override
  String get newFileAdded => 'Yeni dosya eklendi';

  @override
  String get renameSuccess => 'Adlandırma işlemi başarılı';

  @override
  String get savedSuccess => 'Kaydedildi';

  @override
  String get hiddenSuccess => 'Saklandı';

  @override
  String get cleanupInProgress => 'Temizlik devam ediyor...';

  @override
  String get operationCompleted => 'İşlem sonlandı';

  @override
  String get temporaryFilesCollected => 'Geçici dosyalar tarandı';

  @override
  String get cacheFilesCollected => 'Önbellek dosyaları tarandı';

  @override
  String cleanupWillFree(String size) {
    return '$size MB boşaltılacak';
  }

  @override
  String get clean => 'Temizle';

  @override
  String categoryIndexPreparing(String category) {
    return '$category dosyaları hazırlanıyor...';
  }

  @override
  String get navigationMenu => 'Menü';

  @override
  String get navigationRecent => 'Son';

  @override
  String get navigationFolders => 'Klasörler';

  @override
  String get navigationSearch => 'Arama';
}
