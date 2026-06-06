# Dosya Islemleri Follow Raporu

Bu rapor, mevcut sistemde dosya ve klasor islemlerinin hangi katmanlardan
gecerek calistigini ve her islemin adim adim hangi akisi izledigini anlatir.
Odak noktasi `Dosyaislemleri` state sinifi, `FileOperationService`,
`CleaningService`, `Izinler`, `FileTree` ve bunlari tetikleyen UI aksiyonlaridir.

Incelenen ana dosyalar:

- `lib/features/files/state/dosyaislemleri.dart`
- `lib/data/services/file_operation_service.dart`
- `lib/data/services/cleaning_service.dart`
- `lib/features/navigation/presentation/pages/anasayfa.dart`
- `lib/features/files/state/izinler.dart`

## 1. Genel Yapi

Dosya islemlerinde genel sorumluluk dagilimi su sekildedir:

- UI katmani kullanici aksiyonunu toplar.
- `Dosyaislemleri` islemi orkestre eder.
- Fiziksel dosya sistemi mutasyonu gerekiyorsa is servise devredilir.
- Islem tamamlaninca `Izinler`, `FileTree` ve `FileIndexService` uzerinden
  gorunen icerik yeniden senkronize edilir.
- Gerekirse Hive tabanli persistent listeler de temizlenir veya guncellenir.

Bu mimaride temel kural sudur:

- UI dogrudan dosya sistemi yazma/silme/rename yapmaz.
- Fiziksel mutasyonlar `FileOperationService` icinde toplanir.
- State katmani popup, secim, clipboard, toast ve refresh akisini yonetir.

## 2. Ortak Islem Pipeline'i

Fiziksel dosya sistemi degistiren islemlerin cogu ayni ana akisi izler:

1. Kullanici bir aksiyon tetikler.
2. UI secili ogeyi veya hedef klasoru `Dosyaislemleri` tarafina iletir.
3. `Dosyaislemleri` gerekli on kontrolleri yapar.
4. Islem `showProgress: true` ile `_runOperationWithProgress(...)` icinde
   calistirilir.
5. Popup acilir, baslik olarak `"{islem} islemi devam ediyor"` turu bir metin
   gosterilir.
6. `FileOperationProgress` uzerinden ilerleme cizgisi guncellenir.
7. Gercek dosya sistemi mutasyonu service katmaninda yapilir.
8. Sonuc state katmanina doner.
9. Basariliysa `_refreshAfterFilesystemMutation(...)` cagrilir.
10. Root liste, aktif klasor ve file index yeniden yuklenir.
11. Secim/clipboard gerekiyorsa duzeltilir.
12. Kullaniciya toast gosterilir.

Bu ortak popup davranisinda iki kritik detay vardir:

- Popup `rootNavigator` uzerinden acilir, bu sayede bottom sheet kapaninca
  kaybolmaz.
- Cok hizli biten islemlerde popup gorunmez hale gelmesin diye minimum gorunur
  kalma suresi uygulanir.

## 3. Mutation Sonrasi Ortak Guncelleme

Fiziksel dosya sistemi degistiren bir islem basariyla bittiginde
`_refreshAfterFilesystemMutation(...)` su zinciri izler:

1. Eger silinen veya tasinan eski path'ler varsa
   `izinler.removePathsFromPersistentCollections(...)` cagrilir.
2. `izinler.refreshRootEntries()` ile root duzeyindeki liste guncellenir.
3. Aktif klasor sanal klasor degilse `fileTree.loadFolder(..., forceRefresh: true)`
   ile icerik diskten yeniden okunur.
4. `izinler.setVisibleFolder(currentFolder)` ile guncel klasor tekrar gorunur
   hale getirilir.
5. `FileIndexService.refreshIndex(...)` ile arama ve kategori indexleri de
   senkron tutulur.

Bu yuzden kullanici islem bittiginde ayni ekranda yeni klasoru, silinen ogeyi,
yeniden adlandirilmis girdiyi veya yapistirilmis dosyayi guncel olarak gorur.

## 4. Secim ve Clipboard Akisi

Bir cok islem secim uzerinden calisir. Secim tarafindaki temel akis:

1. Kullanici dosya veya klasor uzerinde secim moduna girer.
2. `toggleFolderSelection(...)` veya `toggleFileSelection(...)` secili listeyi
   gunceller.
3. Secim bilgisi `folderlistesi` ve `filelistesi` icinde tutulur.
4. Fiziksel islem baslatilacaginda bu listeler `_selectedEntries` ile
   `FileOperationEntry` listesine donusturulur.

Clipboard tarafindaki temel akis:

1. `kopyala(...)` veya `kes(...)` secili listeyi clipboard'a yazar.
2. `_syncClipboardFromSelection(...)` kopyalanan klasor ve dosya listelerini
   doldurur.
3. `_clipboardOperation` alani `copy` veya `cut` olarak set edilir.
4. Kullanici secimi kapatir; clipboard ise sonraki yapistir icin korunur.
5. `yapistir(...)` sirasinda `_clipboardEntries` okunur.
6. Eger islem `cut` ise basarili tasinan path'ler `_removeClipboardPaths(...)`
   ile clipboard'dan dusulur.

## 5. Yeni Klasor Olusturma Akisi

Metot: `Dosyaislemleri.klasorekle(...)`

Adimlar:

1. UI yeni klasor adini alir ve `klasorekle(...)` cagirir.
2. `Dosyaislemleri`, `Izinler.currentFolder` uzerinden yazilabilir hedef klasoru
   `_resolveWritableDirectoryPath(...)` ile bulur.
3. Hedef klasor sanal ise veya yazilabilir degilse islem hemen hata toast'i ile
   durur.
4. `_runOperationWithProgress(...)` ile progress popup acilir.
5. Popup acildiktan sonra elle ilk progress degeri `0/1` olarak set edilir.
6. `FileOperationService.createFolder(...)` cagrilir.
7. Service icinde klasor adi validate edilir.
8. Parent klasor icin yazma yetkisi ve erisim kontrolu yapilir.
9. Hedef path zaten var mi bakilir.
10. Yeni klasor `Directory.create(...)` ile olusturulur.
11. Olusum dogrulamasi yapilir.
12. Kismi olusum varsa rollback denemesi yapilir.
13. Sonuc state katmanina doner ve progress `1/1` olur.
14. Basariliysa `_refreshAfterFilesystemMutation(...)` cagrilir.
15. Kullaniciya "yeni klasor olusturuldu" toast'i gosterilir.

## 6. Disaridan Dosya Ekleme Akisi

Metot: `Dosyaislemleri.fileekle(...)`

Bu akis, secim clipboard'i kullanmadan tek bir dosyayi mevcut klasore kopyalar.

Adimlar:

1. UI disaridan gelen `File` nesnesini `fileekle(...)` ile state katmanina verir.
2. Hedef klasor `_resolveWritableDirectoryPath(...)` ile bulunur.
3. Hedef yazilabilir degilse islem hata toast'i ile biter.
4. `_runOperationWithProgress(...)` popup'i acilir.
5. `FileOperationService.pasteEntries(...)` cagrilir.
6. Service bunu tek elemanli bir `copy` islemi gibi ele alir.
7. Kaynak dosya validate edilir.
8. Hedef klasor validate edilir.
9. Gerekli bos alan kontrol edilir.
10. Hedefte ayni isim varsa conflict resolution akisi calisir.
11. Dosya kopyalanir.
12. Kopyanin boyut bazli dogrulamasi yapilir.
13. Hata varsa rollback denenir.
14. Basariliysa `_refreshAfterFilesystemMutation(...)` cagrilir.
15. Kullaniciya "yeni dosya eklendi" toast'i gosterilir.

## 7. Yeniden Adlandirma Akisi

Metot: `Dosyaislemleri.adlandir(...)`

Adimlar:

1. UI eski path ve yeni adi state katmanina yollar.
2. `_runOperationWithProgress(...)` popup'i acilir.
3. Ilk progress degeri `0/1` olarak ayarlanir.
4. `FileOperationService.renameEntry(...)` cagrilir.
5. Service yeni adi validate eder.
6. Kaynak path'in varligi, tipi ve parent yazma yetkisi kontrol edilir.
7. Hedef path hesaplanir.
8. Eski ad ile yeni ad ayni normalize path'e cikiyorsa no-op basari doner.
9. Hedefte ayni isim varsa `alreadyExists` hatasi doner.
10. `rename(...)` operasyonu uygulanir.
11. Islem sonrasi yeni hedefin gercekten var oldugu dogrulanir.
12. Kaynak kaybolup hedefte yarim rename kaldiysa rollback denenir.
13. Sonuc state katmanina doner ve progress `1/1` olur.
14. Basariliysa secim listesi `_syncSelectionAfterRename(...)` ile guncellenir.
15. Clipboard listesi `_syncClipboardAfterRename(...)` ile guncellenir.
16. `_refreshAfterFilesystemMutation(...)` cagrilir.
17. Kullaniciya "yeniden adlandirma basarili" toast'i gosterilir.

## 8. Silme Akisi

Metot: `Dosyaislemleri.sil(...)`

Adimlar:

1. Secili dosya ve klasorler `_selectedEntries` ile toplanir.
2. Secim bos ise islem hic baslamaz.
3. `_runOperationWithProgress(...)` popup'i acilir.
4. `FileOperationService.deleteEntries(...)` cagrilir.
5. Service icinde secili girdiler `_collapseNestedEntries(...)` ile sadeletilir.
   Bu sayede bir klasor seciliyken onun altindaki cocuklar ikinci kez islenmez.
6. Her girdi icin sira ile progress guncellenir.
7. Her path icin kaynak varligi ve parent yazma yetkisi validate edilir.
8. Path bulunamazsa `skippedPaths` icine yazilir.
9. Gecerli girdiler `delete(recursive: true)` ile silinir.
10. Hata alan girdiler `failures` listesine yazilir.
11. Tum liste bitince final progress guncellenir.
12. Sonuc `removedPaths`, `skippedPaths` ve `failures` ile geri doner.
13. `removedPaths` bilgisiyle `_refreshAfterFilesystemMutation(...)` cagrilir.
14. Persistent saved/hidden/recent listelerden silinmis path'ler temizlenir.
15. Secim temizlenir ve secim modu kapatilir.
16. Sonuc durumuna gore basari veya hata toast'i gosterilir.

## 9. Kopyalama Akisi

Metot: `Dosyaislemleri.kopyala(...)`

Bu islem fiziksel kopyalama yapmaz. Yalnizca clipboard hazirlar.

Adimlar:

1. Secili klasor ve dosyalar okunur.
2. `_syncClipboardFromSelection(mode: ClipboardOperation.copy)` cagrilir.
3. Secili klasorler `kopyalananfolder` listesine yazilir.
4. Secili dosyalar `kopyalananfile` listesine yazilir.
5. `_clipboardOperation = copy` olarak tutulur.
6. Aktif secim temizlenir.
7. Secim modu kapatilir.
8. Kullaniciya "kopyalandi" toast'i gosterilir.

Gercek fiziksel kopyalama daha sonra `yapistir(...)` icinde olur.

## 10. Kesme Akisi

Metot: `Dosyaislemleri.kes(...)`

Bu islem de aninda fiziksel tasima yapmaz. Sadece clipboard'i `cut` moduna alir.

Adimlar:

1. Secili ogeler okunur.
2. `_syncClipboardFromSelection(mode: ClipboardOperation.cut)` cagrilir.
3. Secili klasor ve dosyalar clipboard listelerine yazilir.
4. `_clipboardOperation = cut` olarak tutulur.
5. Aktif secim temizlenir.
6. Secim modu kapatilir.
7. Kullaniciya "kesildi, yapistirmaya hazir" toast'i gosterilir.

Gercek tasima daha sonra `yapistir(...)` icinde copy + verify + source delete
mantigi ile yapilir.

## 11. Yapistirma Akisi

Metot: `Dosyaislemleri.yapistir(...)`

Bu akis hem kopya olusturma hem de tasima isini kapsar.

Adimlar:

1. `_clipboardEntries` ve `_clipboardOperation` okunur.
2. Clipboard bos ise veya mod yoksa islem baslamaz.
3. Hedef klasor `_resolveWritableDirectoryPath(...)` ile bulunur.
4. Hedef sanal klasor ise islem hata toast'i ile biter.
5. `_runOperationWithProgress(...)` popup'i acilir.
6. Baslik `copy` icin kopyalama, `cut` icin tasima metni olur.
7. `FileOperationService.pasteEntries(...)` cagrilir.

Service tarafindaki detayli akis:

1. Gelen liste `_collapseNestedEntries(...)` ile sadeletilir.
2. Hedef klasor icin yazma ve erisim kontrolu yapilir.
3. Her kaynak girdi validate edilir.
4. `cut` modunda kaynak parent klasor yazma yetkisi de zorunlu tutulur.
5. Bos alan hesaplanir ve diskte yeterli alan var mi kontrol edilir.
6. Her oge icin progress guncellenir.
7. Hedef path `destinationDirectoryPath + entry.name` olarak hesaplanir.
8. `_resolveDestinationPath(...)` conflict durumunu cozer.
9. Kullaniciya isim cakismasi varsa bottom sheet gosterilir:
   overwrite, yeni adla kopyala, skip, cancel.
10. Klasor kendi icine tasinmaya/kopyalanmaya calisiliyorsa islem reddedilir.
11. Overwrite secildiyse eski hedef once backup path'e tasinir.
12. Dosya ise `File.copy(...)`, klasor ise recursive copy uygulanir.
13. Kopya dogrulanir:
    dosyada boyut,
    klasorde snapshot karsilastirmasi yapilir.
14. Mod `cut` ise dogrulanmis kopya sonrasinda kaynak silinir.
15. Kaynak silme basarisiz olursa yeni hedef rollback edilir.
16. Genel hata olursa destination rollback yapilir.
17. Basarili ise `createdPaths` ve gerekirse `removedPaths` doldurulur.

State katmanina donus sonrasi:

1. Sonuc `cancelled` ise islem sessizce biter.
2. Mod `cut` ise tasinan path'ler clipboard'dan dusulur.
3. Clipboard bosaldiysa `_clipboardOperation` temizlenir.
4. `_refreshAfterFilesystemMutation(...)` cagrilir.
5. Kullaniciya ozet durumuna gore basari veya hata toast'i gosterilir.

## 12. Kaydetme Akisi

Metot: `Dosyaislemleri.kaydet(...)`

Bu islem fiziksel dosya sistemi degistirmez. Secili ogeleri uygulamanin
saved listesine yazar.

Adimlar:

1. Secili klasor ve dosyalar okunur.
2. Her oge icin `SavedItemModel` uretilir.
3. `SavedRepository.upsertAll(...)` cagrilir.
4. Repository path bazli duplicate engelleme ve guncelleme mantigini uygular.
5. `izinler.syncSavedEntries()` ile UI tarafindaki saved data yenilenir.
6. Secim temizlenir.
7. Secim modu kapatilir.
8. Kullaniciya "kaydedildi" toast'i gosterilir.

Burada fiziksel diskte klasor veya dosya degisimi olmaz.

## 13. Gizleme Akisi

Metot: `Dosyaislemleri.sakla(...)`

Bu islem de fiziksel silme yapmaz. Ogeyi uygulamanin hidden listesine tasir ve
gorunen listelerden dusurur.

Adimlar:

1. Secili klasor ve dosyalar okunur.
2. Her oge icin `HiddenItemModel` uretilir.
3. `HiddenRepository.upsertAll(...)` cagrilir.
4. `izinler.syncHiddenEntries()` ile hidden durum verisi yenilenir.
5. `izinler.refreshRootEntries()` ile root liste guncellenir.
6. Aktif klasor sanal degilse ayni klasor `forceRefresh: true` ile tekrar okunur.
7. `izinler.setVisibleFolder(currentFolder)` ile guncel gorunum korunur.
8. Secim temizlenir.
9. Secim modu kapatilir.
10. Kullaniciya "gizlendi" toast'i gosterilir.

Burada fiziksel dosya sistemi degismez; sadece uygulama ici filtre sonucu
gorunum degisir.

## 14. Paylasma Akisi

Metot: `Dosyaislemleri.dosyalaripaylas()`

Adimlar:

1. Mevcut `filelistesi` icindeki dosyalar uzerinden donulur.
2. Her dosya icin fiziksel varlik `exists()` ile kontrol edilir.
3. Var olanlar `XFile` listesine cevrilir.
4. Liste bos degilse `Share.shareXFiles(...)` cagrilir.

Not:

- Bu akis klasorleri degil, paylasilabilir dosyalari esas alir.
- Fiziksel dosya sistemi uzerinde mutasyon yapmaz.

## 15. Cleanup Tarama Akisi

Metot: `Dosyaislemleri.startCleanupScan()`

Adimlar:

1. Baska cleanup tarama veya silme suruyorsa yeni islem baslatilmaz.
2. Cleanup state alanlari sifirlanir.
3. `loading = true` yapilir ve sayfa progress durumuna gecilir.
4. `CleaningService.scan(...)` cagrilir.
5. Service temp/cache kaynaklarini chunk'li sekilde tarar.
6. Progress geldikce `_cleanupScanProgress` guncellenir.
7. Hangi kaynaklarin tamamlandigi state icinde isaretlenir.
8. Tarama sonucu `CleaningScanResult` olarak doner.
9. `_syncCleanupCandidates(...)` ile UI listesine donusturulur.
10. Toplam byte hesabi guncellenir.
11. Son durumda loading kapatilir ve UI adaylari gosterir.

## 16. Cleanup Silme Akisi

Metot: `Dosyaislemleri.startCleanupDelete()`

Adimlar:

1. Tarama sonucu yoksa veya aday listesi bossa islem baslamaz.
2. Silme progress modeli ilk degerlerle olusturulur.
3. `CleaningService.deleteCandidates(...)` cagrilir.
4. Service her adayi sirayla siler.
5. Silme ilerledikce `_cleanupDeleteProgress` guncellenir.
6. Silinen path'ler ve issue listesi doner.
7. `source_not_found` olanlar da cozulmus kabul edilir.
8. Kalan aday listesi yeniden hesaplanir.
9. `_syncCleanupCandidates(...)` ile sayfa listesi guncellenir.
10. Geriye aday kalmadiysa tarama sonucu gorunumu kapanir.

Cleanup tarafi ayrica thumbnail metadata ve ilgili cache temizligini de servis
katmaninda yapar.

## 17. Conflict Resolution Akisi

Yapistirma ve disaridan dosya ekleme sirasinda isim cakismasi olursa
`_resolveConflict(...)` devreye girer.

Adimlar:

1. Service hedefte mevcut bir dosya veya klasor bulur.
2. State katmani kullaniciya bottom sheet gosterir.
3. Kullanici su seceneklerden birini secer:
   overwrite,
   yeni adla kopyala,
   skip,
   cancel.
4. Secim service'e geri doner.
5. Overwrite ise once backup alinir.
6. Yeni ad secildiyse `(1)`, `(2)` ... suffix'li unique path uretilir.
7. Skip ise yalnizca ilgili oge atlanir.
8. Cancel ise tum yapistirma akisi iptal olur.

## 18. Progress Popup Akisi

Fiziksel mutasyonlarda kullanilan popup akisi su sekildedir:

1. `_runOperationWithProgress(...)` aktif islem tipini ve basligini state'e yazar.
2. `FileOperationProgress(processedItems: 0, totalItems: n)` ile ilk durum atanir.
3. `showDialog(...)` ile `_FileOperationProgressDialog` acilir.
4. Dialog icinde:
   islem basligi,
   lineer progress cizgisi,
   `processed/total` bilgisi,
   varsa o an islenen path'in dosya adi gosterilir.
5. Service her ilerlemede `_setOperationProgress(...)` ile state'i gunceller.
6. Dialog provider degisimi ile otomatik rebuild olur.
7. Islem bitince state temizlenir.
8. Popup minimum gorunurluk suresi dolduktan sonra kapatilir.

Bu mekanizma su islemlerde kullanilir:

- yeni klasor olusturma
- dosya ekleme
- yeniden adlandirma
- silme
- yapistirma

## 19. Hata ve Rollback Mantigi

Mevcut sistemde profesyonel davranis icin su korumalar vardir:

- Gecersiz ad kontrolu
- Kaynak path varlik kontrolu
- Hedef klasor yazma yetkisi kontrolu
- Disk bos alan kontrolu
- Klasoru kendi icine tasima/kopyalama engeli
- Overwrite oncesi backup alma
- Kopya dogrulama sonrasi kaynak silme
- Hata halinde rollback denemesi
- Kullaniciya hata koduna gore lokalize mesaj gosterimi

Ozellikle `cut` isleminde kaynak once silinmez. Akis her zaman sunu izler:

1. Kopya olustur.
2. Kopyayi dogrula.
3. Ancak bundan sonra kaynagi sil.
4. Kaynak silme basarisizsa yeni hedefi geri al.

Bu yaklasim veri kaybi riskini dusurur.

## 20. Tum Islem Ozeti

Mevcut sistemde dosya islemleri iki ana gruba ayrilir:

Fiziksel dosya sistemi mutasyonu yapanlar:

- yeni klasor olusturma
- disaridan dosya ekleme
- yeniden adlandirma
- silme
- yapistirma ile kopyalama
- yapistirma ile tasima
- cleanup silme

Fiziksel dosya sistemi mutasyonu yapmayan ama uygulama verisini degistirenler:

- kopyala
- kes
- kaydet
- sakla
- paylas
- cleanup tarama

Her fiziksel mutasyonun sonunda ortak hedef aynidir:

- ekranda gorunen klasor icerigi hemen guncellensin
- root liste dogru kalsin
- arama/index/cache yapilari stale olmasin
- saved/hidden/recent gibi listelerde gecersiz path kalmasin

Bu nedenle mevcut sistemin merkezi ilkesi sudur:

- is mantigi state + service katmanina yayilir,
- UI yalnizca tetikler ve sonucu gosterir,
- fiziksel mutasyon sonrasinda her zaman senkron refresh calisir.
