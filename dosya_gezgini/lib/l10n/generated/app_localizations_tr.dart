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
  String get fileAccessUnavailable => 'Bu öğeye şu anda erişilemiyor.';

  @override
  String get fileAccessInvalidPath => 'Yol bozuk veya geçersiz.';

  @override
  String get fileAccessDeleted => 'Öğe artık bulunamıyor.';

  @override
  String get fileAccessExpectedDirectory => 'Bu yol geçerli bir klasör değil.';

  @override
  String get fileAccessReadDenied => 'Bu klasör okunamıyor.';

  @override
  String get fileAccessPermissionDenied => 'Bu yola erişim reddedildi.';

  @override
  String get fileAccessSymbolicLinkUnsupported =>
      'Symbolic link yolları desteklenmiyor.';

  @override
  String fileSyncItemsMissing(int count) {
    return '$count kayıt artık bulunamadı ve listelerden temizlendi.';
  }

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
  String get cutReady => 'Taşımak için panoya alındı';

  @override
  String get save => 'Kaydet';

  @override
  String get hide => 'Sakla';

  @override
  String get share => 'Paylaş';

  @override
  String get rename => 'Adlandır';

  @override
  String get overwrite => 'Üzerine yaz';

  @override
  String get copyWithNewName => 'Yeni isimle kopyala';

  @override
  String get skip => 'Atla';

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
  String get pasteSuccess => 'Yapıştırma işlemi başarılı';

  @override
  String get targetFolderNotFound => 'Hedef klasör artık bulunamıyor.';

  @override
  String get destinationInsideSource =>
      'Bir klasör kendi içine taşınamaz veya kopyalanamaz.';

  @override
  String get operationRolledBack =>
      'İşlem tamamlanamadı, yapılan değişiklikler geri alındı.';

  @override
  String get operationRollbackFailed =>
      'İşlem başarısız oldu ve geri alma tamamlanamadı.';

  @override
  String get invalidName => 'Geçerli bir ad girin';

  @override
  String get itemAlreadyExists => 'Aynı isimde bir öğe zaten var';

  @override
  String get insufficientStorageSpace => 'Yeterli boş alan yok';

  @override
  String get operationDeleting => 'Öğeler siliniyor...';

  @override
  String get operationCopying => 'Öğeler kopyalanıyor...';

  @override
  String get operationMoving => 'Öğeler taşınıyor...';

  @override
  String get operationDeletingProgress => 'Silme işlemi devam ediyor';

  @override
  String get operationCopyingProgress => 'Kopyalama işlemi devam ediyor';

  @override
  String get operationMovingProgress => 'Taşıma işlemi devam ediyor';

  @override
  String get operationCreatingFolderProgress =>
      'Klasör oluşturma işlemi devam ediyor';

  @override
  String get operationRenamingProgress =>
      'Yeniden adlandırma işlemi devam ediyor';

  @override
  String get operationSyncingRecordsProgress => 'Kayıtlar senkronize ediliyor';

  @override
  String get operationRefreshingRootProgress => 'Klasör listesi yenileniyor';

  @override
  String get operationRefreshingFolderProgress => 'Klasör içeriği yenileniyor';

  @override
  String get operationRefreshingIndexProgress =>
      'Arama ve kategori dizini yenileniyor';

  @override
  String get nameConflictTitle => 'Aynı isimde öğe var';

  @override
  String nameConflictMessage(String name) {
    return '$name zaten mevcut. Nasıl devam edilsin?';
  }

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
  String get cleanupReady => 'Temizlik hazır';

  @override
  String get cleanupNothingToClean => 'Temizlenecek dosya bulunamadı';

  @override
  String get cleanupDeleting => 'Temizlik uygulanıyor...';

  @override
  String cleanupScannedFiles(int count) {
    return 'Taranan dosya: $count';
  }

  @override
  String cleanupCandidatesFound(int count) {
    return 'Gereksiz dosya: $count';
  }

  @override
  String cleanupRecoverableSpace(String size) {
    return 'Geri kazanılabilir alan: $size';
  }

  @override
  String get cleanupConfirmTitle => 'Temizliği başlat';

  @override
  String cleanupConfirmMessage(int count, String size) {
    return '$count dosya silinecek ve $size alan boşalacak. Devam edilsin mi?';
  }

  @override
  String cleanupDeletedCount(int count) {
    return 'Silinen dosya: $count';
  }

  @override
  String cleanupFailedCount(int count) {
    return 'Hatalı dosya: $count';
  }

  @override
  String get cleanupCurrentFile => 'İşlenen dosya';

  @override
  String get cleanupReportTitle => 'Temizlik raporu';

  @override
  String cleanupFreedSpace(String size) {
    return 'Boşalan alan: $size';
  }

  @override
  String cleanupScanIssues(int count) {
    return 'Tarama hataları ($count)';
  }

  @override
  String cleanupDeleteIssues(int count) {
    return 'Silme hataları ($count)';
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
