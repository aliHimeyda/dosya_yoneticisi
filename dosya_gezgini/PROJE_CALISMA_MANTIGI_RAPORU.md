# Dosya Gezgini Projesi Çalışma Mantığı Raporu

Bu rapor, `dosya_gezgini` Flutter uygulamasının çalışma mantığını kod üzerinden detaylı biçimde açıklar. Özellikle şu başlıklara odaklanır:

- Uygulamanın açılış akışı
- `provider` tabanlı state yönetimi
- `go_router` ile kurulan router ve shell yapısı
- Klasör/dosya modeli, path mantığı ve klasörler arasında gezinme
- Bir klasör container'ına tıklanınca gerçekleşen tam akış
- Sayfa stack'lerinin nasıl kurulduğu ve geri davranışının nasıl çalıştığı

İnceleme yapılan ana dosyalar:

- `lib/main.dart`
- `lib/app/bootstrap.dart`
- `lib/app/app.dart`
- `lib/app/router/app_router.dart`
- `lib/features/files/state/*.dart`
- `lib/features/files/presentation/**/*.dart`
- `lib/features/navigation/presentation/pages/anasayfa.dart`
- `lib/features/home/presentation/pages/anasayfa_icerigi.dart`
- `lib/features/menu/presentation/pages/menu.dart`

## 1. Genel Mimari Özeti

Proje, mimari olarak üç ana eksen etrafında dönüyor:

1. `Provider` tabanlı global uygulama durumu
2. `go_router` tabanlı yönlendirme
3. Android dosya sistemi üzerinde çalışan, lazy-load mantıklı bir dosya ağacı

Bu üç yapı birbirine şu şekilde bağlanıyor:

- Router ekranı değiştiriyor.
- Provider'lar ekranda hangi verinin gösterileceğini belirliyor.
- Dosya sistemi verisi `FileTree`, `FolderNode` ve `Izinler` üzerinden belleğe taşınıyor.
- UI tarafındaki klasör ve dosya kartları aynı widget'lar üzerinden tekrar tekrar kullanılıyor.

Bu uygulamada önemli bir tasarım kararı var:

- Klasörün hangi klasör olduğu route üzerinden taşınmıyor.
- Bunun yerine aktif klasör bilgisi provider içinde tutuluyor.
- Yani URL sabit kalabiliyor, ama gösterilen klasör değişiyor.

Bu karar özellikle klasör içeriğine girme akışının merkezinde duruyor.

## 2. Uygulama Açılış Akışı

### 2.1 `main.dart`

Uygulama `main.dart` içinde sadece `bootstrap()` çağırıyor.

- Dosya: `lib/main.dart`
- Amaç: uygulama başlangıcını tek bir bootstrap katmanına devretmek

Akış:

1. `main()` çalışır.
2. `bootstrap()` await edilir.

### 2.2 `bootstrap.dart`

Asıl başlangıç kurulumu burada yapılıyor.

- Dosya: `lib/app/bootstrap.dart`
- Kritik satırlar: `runApp(buildApp())`, `MultiProvider`, başlangıç provider'ları

Burada yapılanlar:

1. `WidgetsFlutterBinding.ensureInitialized()` çağrılır.
2. `SystemChrome.setSystemUIOverlayStyle(...)` ile status bar görünümü ayarlanır.
3. `runApp(buildApp())` ile widget ağacı başlatılır.
4. `buildApp()` içinde tüm global provider'lar `MultiProvider` ile en üste yerleştirilir.

### 2.3 Başlangıçta ayağa kalkan provider'lar

`buildApp()` içinde şu provider'lar global olarak kurulur:

| Provider | Rolü | Başlangıçta tetiklenen işlem |
| --- | --- | --- |
| `AppTheme` | tema yönetimi | yok |
| `LocaleProvider` | dil/locale yönetimi | `loadSavedLocale()` |
| `Dosyaislemleri` | dosya işlemleri ve seçim durumu | yok |
| `Altislemprovider` | alt işlem çubuğu / seçim modu anahtarı | yok |
| `Izinler` | storage izni, aktif klasör, `FileTree` | `requestAllStoragePermission()` |
| `Localestoragebilgileri` | depolama alanı bilgileri | `depolamabilgilernigetir()` |

Buradaki en önemli nokta:

- Dosya sistemi ağacı başlangıçta tam recursive olarak kurulmaz.
- `Izinler.requestAllStoragePermission()` izin aldıktan sonra sadece `fileTree.buildTree()` çağırır.
- `buildTree()` de sadece root klasörü yükler.
- Alt klasörler kullanıcı girdikçe lazy-load edilir.

## 3. Uygulama Widget Kabuğu

### 3.1 `DosyaGezginiApp`

Dosya: `lib/app/app.dart`

Bu widget uygulamanın en üst Flutter kabuğudur. `Consumer2<AppTheme, LocaleProvider>` kullanır. Bunun anlamı:

- tema değişirse tüm `MaterialApp.router` yeniden build olur
- dil değişirse locale yeniden uygulanır

Bu katmanda:

- `debugShowCheckedModeBanner: false`
- `locale: localeProvider.locale`
- `supportedLocales: AppLocalizations.supportedLocales`
- `theme: themeProvider.theme`
- `routerConfig: router`

Yani uygulamanın tema, localization ve router kökü burada birleşir.

### Güncel rebuild davranışı

Task 7 sonrasında bu katmanda dosya liste state'i veya seçim modu gibi sık değişen
provider alanları izlenmez. Uygulama kabuğu yalnızca tema, locale ve router gibi
uygulama seviyesindeki state ile ilgilenir; dosya gezgini ekranlarındaki sık rebuild
ihtiyacı alt widget seviyesindeki `Selector` yapılarina dağıtılmıştır.

## 4. Router Yapısı

### 4.1 Router'ın tanımlandığı yer

Dosya: `lib/app/router/app_router.dart`

Bu dosya iki önemli şey içerir:

1. `Paths` sabitleri
2. `GoRouter` tanımı

Tanımlı path'ler:

- `/logo`
- `/`
- `/arama`
- `/dosyalar`
- `/menu`
- `/klasoricerigisayfasi`
- `/gizlidosyalar`
- `/kaydedilendosyalar`
- `/temizliksayfasi`
- `/katagorikicerik`

Not:

- Klasör detay sayfası base route olarak `/klasoricerigisayfasi` altında tanımlıdır.
- Gerçek klasör kimliği ise query parametresi ile taşınır:
  `/klasoricerigisayfasi?path=/storage/emulated/0/Download`

### 4.2 İlk açılış rotası

`GoRouter.initialLocation = Paths.logo`

Bu yüzden uygulama ilk açıldığında direkt splash/logo ekranına gider.

Sonrasında `Logosayfasi` içinde 2 saniye sonra:

- `context.go(Paths.anasayfa)`

çağrılır.

Burada özellikle `go` kullanılması önemli:

- `push` yeni sayfa eklerdi
- `go` mevcut location'ı değiştirir

Bu sayede splash ekranı kalıcı bir back-stack katmanı gibi davranmaz; uygulama ana yapıya geçer.

### 4.3 `StatefulShellRoute.indexedStack` neden önemli?

Ana gövde şu yapı ile kurulmuş:

- dışta bir `GoRoute('/logo')`
- onun yanında bir `StatefulShellRoute.indexedStack(...)`

Bu shell route'un builder'ı her zaman `Anasayfa` widget'ını döndürür:

- `Anasayfa(navigationShell: navigationShell)`

Bunun anlamı şudur:

- Uygulamanın ortak çerçevesi `Anasayfa` içinde yaşar.
- Üst bar, alt navigation, action bar ve FAB burada kalıcıdır.
- Değişen kısım `navigationShell` içindeki aktif branch olur.

### 4.4 Branch yapısı

Shell altında 9 branch tanımlı:

| Branch index | Path | Sayfa | Not |
| --- | --- | --- | --- |
| 0 | `/menu` | `Menu` | alt navigasyonda var |
| 1 | `/` | `Anasayfaicerigi` | alt navigasyonda var |
| 2 | `/dosyalar` | `Dosyalar` | alt navigasyonda var |
| 3 | `/arama` | `Arama` | alt navigasyonda var |
| 4 | `/klasoricerigisayfasi` | `Klasoricerigisayfasi` | gizli detay branch |
| 5 | `/gizlidosyalar` | `Gizlidosyalar` | gizli detay branch |
| 6 | `/kaydedilendosyalar` | `Kaydedilendosyalar` | gizli detay branch |
| 7 | `/temizliksayfasi` | `Temizliksayfasi` | gizli detay branch |
| 8 | `/katagorikicerik` | `Katagorikicerik` | tanımlı ama mevcut akışta kullanılmıyor |

Burada kritik mimari karar şu:

- Alt navigation bar sadece ilk 4 branch'i gösteriyor.
- Ama router tarafında toplam 9 branch var.
- Yani bazı ekranlar navigation bar'da görünmeyen "detay/yardımcı" branch'ler olarak tanımlanmış.

### 4.5 Navigation bar branch değiştirme mantığı

Dosya: `lib/features/navigation/presentation/pages/anasayfa.dart`

`NavigationBar.onDestinationSelected = widget.navigationShell.goBranch`

Bu şu anlama gelir:

- Menü, ana sayfa, dosyalar, arama sekmeleri tab mantığında çalışır.
- Sekme değiştirirken URL branch değişir.
- Shell route indexed stack olduğu için her branch kendi navigator durumunu koruyabilir.

Yani bu kısım klasik "bottom tab + ayrı navigator state" mantığına yakındır.

### 4.6 `push`, `go` ve `goBranch` bu projede nasıl kullanılıyor?

Bu projede üç farklı navigasyon biçimi var:

#### `context.go(...)`

Kullanıldığı yer:

- Splash'tan ana yapıya geçiş

Amaç:

- yeni sayfa yığmak yerine aktif location'ı değiştirmek

#### `widget.navigationShell.goBranch(...)`

Kullanıldığı yer:

- Alt navigation sekmeleri

Amaç:

- shell branch değiştirmek
- sekmeler arası state'i olabildiğince korumak

#### `context.push(...)`

Kullanıldığı yerler:

- klasör içeriği ekranına gitmek
- gizli dosyalar
- kaydedilen dosyalar
- temizlik sayfası

Amaç:

- o anda bulunulan deneyimin üstüne yeni bir ekran açmak

Bu proje açısından önemli sonuç:

- Klasörler arası derinleşme `?path=` query parametresi ile kimlik kazanıyor.
- İnce ayar ve hızlı geçiş için aynı anda `FolderRouteData` nesnesi `extra` ile de aktarılıyor.
- Sayfa açılışında asıl hedef klasör bilgisi route üzerinden okunuyor.
- Provider sadece görünür klasör, breadcrumb ve operasyon desteği için yardımcı state tutuyor.
- Aynı hedef path zaten açıksa yeniden `push(...)` yapılmıyor.

## 5. Sayfa Stack'leri Nasıl Kuruluyor?

Bu uygulamada tek bir stack yok. Üç farklı "stack benzeri" yapı var:

1. GoRouter route stack'i
2. Stateful shell branch yapısı
3. `Izinler.previousFolders` listesi

Bu ayrımı anlamadan proje davranışını doğru okumak zor.

### 5.1 GoRouter route stack'i

Başlangıç örneği:

```text
Uygulama açılışı
-> /logo
-> context.go('/')
-> shell route aktif
```

Bu noktadan sonra kullanıcı tab değiştirirse branch değişir.

Detay sayfaları açılırsa `push(...)` kullanılır.

### 5.2 Stateful shell branch stack mantığı

`StatefulShellRoute.indexedStack` her branch için ayrı navigator mantığı kurar. Kodda bunun sonucu şudur:

- `Menu`, `Anasayfaicerigi`, `Dosyalar`, `Arama` sekme mantığında çalışır.
- Shell değişse bile dış kabuk (`Anasayfa`) yerinde kalır.
- Ortak UI chrome korunur.

Yani kullanıcı sekme değiştirince tüm uygulama baştan açılmaz; sadece aktif branch değişir.

### 5.3 Klasör geçmişi stack'i: `previousFolders`

`previousFolders` halen projede bulunur, ama artık standart klasör geri davranışının ana kaynağı değildir.

Dosya: `lib/features/files/state/izinler.dart`

Bu listede route değil, `FolderNode` tutulur.

Yani:

- GoRouter hangi klasör sayfasının açık olduğunu `?path=` query parametresi ile bilir.
- `previousFolders` ise sadece ileride gerekebilecek yardımcı fallback state'ini taşır.

Bu fark çok kritik.

Örnek akış:

```text
Kullanıcı /dosyalar ekranında
-> "Belgeler" klasörüne tıkladı
-> push('/klasoricerigisayfasi?path=/storage/emulated/0/Belgeler')
-> sayfa Belgeler path'ini route üzerinden alır

Belgeler içindeyken "Projeler" klasörüne tıkladı
-> push('/klasoricerigisayfasi?path=/storage/emulated/0/Belgeler/Projeler')
-> yeni sayfa Projeler path'ini route üzerinden alır
```

Burada dikkat edilmesi gereken nokta:

- Router tarafında base path aynı kalsa da query parametresi değişir.
- Dolayısıyla klasör derinliği artık görünür route kimliğinde de temsil edilir.
- Bu yüzden standart geri dönüş için ayrıca provider stack yürütmek gerekmez.
- `previousFolders` ise sadece özel fallback senaryoları için elde tutulur.

### 5.4 Geri tuşuna basınca ne olur?

Bu sorunun cevabı tek katmanlı değil.

#### `Anasayfa` içindeki genel PopScope

Dosya: `lib/features/navigation/presentation/pages/anasayfa.dart`

Shell seviyesinde:

- Eğer `Altislemprovider.anahtar == true` ise geri tuşu önce seçim/alt işlem modunu kapatır.
- `Dosyaislemleri.folderlistesi` ve `filelistesi` temizlenir.

Yani geri tuşunun ilk önceliği sayfa değil, seçim modunu kapatmaktır.

#### Klasör içeriği sayfalarındaki PopScope

Dosyalar:

- `klasoricerigisayfasi.dart`
- `gizlidosyalar.dart`
- `kaydedilendosyalar.dart`
- `katagorikicerik.dart`

Bu sayfalarda geri davranışı şu öncelikle ele alınır:

1. Eğer seçim modu açıksa önce seçim modu kapatılır.
2. Değilse normal `Navigator.pop()` / route stack davranışı çalışır.
3. Önceki klasör sayfası route stack'te zaten varsa o sayfa yeniden görünür olur.
4. Görünür klasör state'i yeniden açılan sayfanın lifecycle akışı ile senkronize edilir.

Yani klasör içinde geri gitme mantığının esas kaynağı artık route stack'tir.
`previousFolders` listesi ana mekanizma olmaktan çıkarılmıştır.

## 6. Provider'ların Detaylı İşlevleri

## 6.1 `AppTheme`

Dosya: `lib/core/theme/app_theme.dart`

Görevleri:

- açık/koyu tema arasında geçiş
- aktif theme nesnesini sağlama
- tema ikonunu (`temaiconu`) tutma
- `isdarkmode` bayrağını UI için hazır halde verme

Nasıl çalışır:

- `themeMode` başlangıçta `ThemeMode.light`
- `theme` getter'ı o anki moda göre `lightMode` veya `darkMode` döndürür
- `changetheme()` çağrıldığında mod ve ikon değişir, sonra `notifyListeners()`

Bu provider özellikle `Menu` ekranındaki tema switch'i tarafından kullanılır.

## 6.2 `LocaleProvider`

Dosya: `lib/core/localization/locale_provider.dart`

Görevleri:

- uygulamanın aktif dilini tutmak
- dili `SharedPreferences` ile kalıcı hale getirmek

İşleyiş:

- desteklenen diller: `tr`, `en`, `ar`
- açılışta `loadSavedLocale()` çağrılır
- kayıtlı language code varsa eşleşen locale yüklenir
- `setLanguageCode(...)` ile seçim değişince hem bellekte hem `SharedPreferences` içinde güncellenir

Bu provider `MaterialApp.router.locale` alanına bağlanmıştır; yani dil değişimi uygulama seviyesinde anında yansır.

## 6.3 `Localestoragebilgileri`

Dosya: `lib/features/menu/state/localestoragebilgileri.dart`

Görevi:

- toplam, boş ve kullanılan depolama alanını okumak

Nasıl çalışır:

- `DiskSpace.getTotalDiskSpace`
- `DiskSpace.getFreeDiskSpace`

ile veriyi alır, sonra GB benzeri gösterim için `/1024` ile dönüştürür.

Bu veri `Menu` ekranındaki storage progress alanında kullanılır.

## 6.4 `Altislemprovider`

Dosya: `lib/features/files/state/altislem_provider.dart`

Bu provider çok küçük ama uygulama akışında çok merkezidir.

Görevi:

- seçim/alt işlem modunun açık mı kapalı mı olduğunu tutmak

Alanlar:

- `_anahtar`
- `secilmismi`

Ana fonksiyon:

- `changeanahtar()` -> bool değeri tersine çevirir ve `notifyListeners()` çağırır

Bu provider şu davranışları tetikler:

- alt işlem çubuğunun görünmesi
- dosya/klasör satırlarındaki seçim çemberlerinin görünmesi
- geri tuşunun önce seçim modunu kapatması

## 6.5 `Izinler`

Dosya: `lib/features/files/state/izinler.dart`

Bu provider dosya gezgini davranışının merkezidir.

Görevleri:

- storage iznini istemek
- `FileTree` nesnesini sahiplenmek
- aktif klasörü tutmak
- önceki klasör geçmişini tutmak
- breadcrumb/path listesi üretmek

### İç alanları

- `fileTree = FileTree(storageRootPath)`
- `_izin`
- `_currentFolder`
- `_currentFolderPath`
- `previousFolders`

### `storageRootPath`

Dosya: `lib/core/constants/storage_paths.dart`

Sabit değer:

```dart
const String storageRootPath = '/storage/emulated/0';
```

Bu doğrudan Android cihazın ortak depolama kökünü hedefler.

Sonuç:

- proje Android merkezli tasarlanmıştır
- breadcrumb ve dosya tarama mantığı bu path yapısını varsayar

### `izin` getter'ı

`SharedPreferences` içindeki `izinanahtari` değerine bakar. Orada bilgi yoksa `Permission.manageExternalStorage.status.isGranted` sonucu kullanılır.

Yani izin durumu hem cihaz iznine hem yerel preference kaydına bağlı izlenir.

### `requestAllStoragePermission()`

İşleyiş:

1. `manageExternalStorage` durumu okunur
2. Zaten izin varsa `setIzin(true)` ve `fileTree.buildTree()`
3. İzin yoksa request atılır
4. Verilirse yine `buildTree()`
5. Reddedilirse `setIzin(false)`
6. Kalıcı ret gibi durumda `openAppSettings()` çağrılır

Burada çok önemli bir nokta:

- `fileTree.buildTree()` çağrısı root içeriğini yükler.
- Tüm alt klasörler baştan kurulmaz.

### `setCurrentFolder(FolderNode folder)`

Bu metod klasör geçişinin kalbidir.

İşleyiş:

1. Eğer `_currentFolder != null` ise ve hedef klasör `previousFolders` içinde yoksa mevcut klasör geçmiş listesine eklenir.
2. `await fileTree.loadFolder(folder)` ile hedef klasörün içeriği okunur.
3. `_currentFolder = folder` yapılır.
4. `notifyListeners()` çağrılır.

Yani aktif klasörü değiştirmek sadece pointer değiştirmek değildir; önce o klasörün verisi lazy-load edilir.

### `goBack()`

Bu metod route pop yapmaz. Sadece:

- `previousFolders.removeLast()` ile önceki `FolderNode` alınır
- `_currentFolder` buna set edilir
- `notifyListeners()` çağrılır

Dolayısıyla uygulama içindeki klasör geri geçmişi UI route geçmişinden bağımsızdır.

### `getcurrentFolderPath`

Bu getter breadcrumb/path gösterimi üretir.

Mantık:

- `_currentFolder == null` ise `['kok dizin']`
- path segment sayısı düşükse yine `['kok dizin']`
- aksi halde `_currentFolder.path.split('/').sublist(4)`

Bu tasarım şu varsayıma dayanır:

- root path `/storage/emulated/0`
- ilk 4 segment breadcrumb'e dahil edilmeyecek

Örnek:

```text
/storage/emulated/0/Download/Belgeler
-> split sonrası ilk 4 segment atılır
-> ['Download', 'Belgeler']
```

Yani breadcrumb `FolderNode.parent` üzerinden değil, path string'i üzerinden türetilir.

### Güncel selector odaklı davranış

Task 7 ile birlikte `Izinler` provider'ı yalnızca "tüm nesneyi izle" mantığıyla
kullanılmaz. Bunun yerine dar getter ve snapshot alanları sunar:

- `currentFolder`
- `currentFolderPathSegments`
- `rootEntries`
- `hiddenEntries`
- `savedEntries`
- `recentEntries`
- senkron izin durum getter'ları

Böylece ekranlar `context.watch<Izinler>()` yerine ihtiyaç duyduğu veri dilimini
`Selector` ile izler ve ilgisiz `notifyListeners()` çağrılarında komple yeniden
build olmaz.

`Altislemprovider` seçim modunu `setSelectionMode(...)` ile kontrollü açıp kapatır.
`Dosyaislemleri` ise seçim listelerini doğrudan widget içi local state yerine
`toggle...Selection`, `clearSelection` ve türetilmiş getter'lar üzerinden yönetir.

## 6.6 `FolderNode`

Dosya: `lib/features/files/state/folderleragaci.dart`

Bu sınıf gerçek veya sanal bir klasörü temsil eder.

Alanları:

- `name`
- `path`
- `folderchildren`
- `filechildren`
- `olusumtarihi`
- `parent`
- `isVirtual`
- `allowedExtensions`
- `areChildrenLoaded`
- `folderCountModel`

Önemli davranışları:

- Gerçek klasörse constructor içinde `_olusumtarihi()` çağrılır.
- Bu metod `FileStat.stat(path)` ile tarih bilgisini alır.
- `replaceChildren(...)` ile çocuk listeleri atomik biçimde yenilenir ve o klasörün çocuklarının artık gerçekten yüklendiği işaretlenir.
- `childCount` yalnızca belleğe gerçekten yüklenmiş `folderchildren + filechildren` toplamını verir.
- Liste kartlarında görünen item sayısı artık doğrudan `childCount` üzerinden okunmaz.
- Bunun yerine `FolderCountModel` ile hydrate edilen `itemCountLabel` kullanılır.
- `applyFolderCountModel(...)` bir klasörün `folderCount`, `fileCount`, `totalCount`, `isLoaded` ve `updatedAt` metadata'sını UI'a taşır.

Not:

- `parent` alanı vardır.
- Ancak geri gezinme bu alan üzerinden yapılmaz.
- Geri gezinme `Izinler.previousFolders` üzerinden yapılır.

## 6.7 `FileTree`

Dosya: `lib/features/files/state/folderleragaci.dart`

Bu sınıf uygulamanın dosya modelidir.

### Temel görevleri

- root klasörü temsil etmek
- klasör içeriklerini lazy-load etmek
- kategori klasörlerini üretmek
- arama yapmak
- son gezilen, kaydedilen, gizlenen listeleri tutmak

### İç listeler

- `arananfolder`
- `arananfile`
- `kaydedilenfolder`
- `kaydedilenfile`
- `gizlenenfolder`
- `gizlenenfile`
- `ensongezilenfolders`
- `ensongezilenfiles`

### Güncel kalıcı veri davranışı

Task 8 sonrasında bu listeler doğrudan kalıcı veri kaynağı değildir. Güncel yapıda:

- asıl kayıtlar `lib/data/repositories/` altındaki Hive repository'lerinde tutulur
- `RecentRepository`, `SavedRepository`, `HiddenRepository` path bazlı kayıt yazar
- `FileTree` içindeki ilgili listeler yalnızca UI için hydrate edilmiş cache görevi görür
- uygulama açılışında `Izinler` provider bu repository'leri okuyup `FileTree` listelerini yeniden kurar
- dosya sisteminde artık bulunmayan path'ler okunurken tespit edilir ve Hive kaydı otomatik temizlenir

Bu yüzden `kaydedilen*`, `gizlenen*` ve `ensongezilen*` listeleri artık tek gerçek kaynak
değil, repository verisinin ekrana hazırlanmış yansımasıdır.

### Klasör item count cache davranışı

Task 11 sonrasında `FileTree` yalnızca klasör içeriği listelerini değil, klasör item sayısı
metadata'sını da yönetir.

Bu yapı için yeni kalıcı kaynak:

- `lib/data/models/folder_count_model.dart`
- `lib/data/repositories/folder_count_repository.dart`
- Hive kutusu: `folder_count_cache`

Her kayıt şu alanları taşır:

- `path`
- `folderCount`
- `fileCount`
- `totalCount`
- `isLoaded`
- `updatedAt`

Çalışma mantığı:

1. Liste ekranlarında görünür olan fiziksel klasör kartları `ensureFolderCount(...)` ile sayım ister.
2. Önce bellekteki cache kontrol edilir.
3. Bellekte yoksa Hive'daki `folder_count_cache` okunur.
4. Cache bulunduysa klasör kartı `0` yerine kaydedilmiş toplam item sayısını hemen gösterebilir.
5. Cache yoksa sayım işi arka plan kuyruğuna alınır.
6. Kuyruk en fazla sınırlı sayıda işi aynı anda çalıştırır; böylece UI thread'i gereksiz yüklenmez.
7. Sayım tamamlanınca `FolderCountModel` Hive'a yazılır ve ilgili `FolderNode` güncellenir.

Bu yüzden root, arama, kaydedilenler, gizliler ve son gezilenler gibi ekranlarda görülen
klasör sayaçları artık çocuk listelerin o an bellekte yüklü olup olmamasına bağlı değildir.

### Directory content cache davranışı

Task 12 sonrasında `FileTree` gerçek klasör içeriklerini de ayrı bir cache katmanı ile yönetir.

Bu yapı için yeni kalıcı kaynak:

- `lib/data/models/directory_cache_model.dart`
- `lib/data/repositories/directory_cache_repository.dart`
- Hive kutusu: `directory_cache_box`

Her kayıt şu alanları taşır:

- `path`
- `folderPaths`
- `filePaths`
- `directoryModifiedAt`
- `updatedAt`

Bu cache'in görevi şudur:

- klasör açılır açılmaz daha önce görülmüş içeriği hızlıca ekrana basmak
- aynı klasöre her dönüşte gereksiz dosya sistemi taramasını azaltmak
- manuel refresh geldiğinde gerçek dosya sisteminden yeni snapshot üretmek
- klasör silinmişse ilgili cache kaydını otomatik temizlemek
- cache yaşı veya klasör modified date değişimine göre invalidation kararı vermek

### Sanal kategori klasörleri

`FileTree` hâlâ gerçek dosya sisteminin dışında sanal kategori klasörleri üretir:

- bilinmeyen dosyalar
- excel
- resim
- video
- ses
- word
- zip
- pdf
- txt
- powerpoint

Ancak bu sanal klasörler artık doğrudan recursive tarama yapan veri kaynakları değildir.
Yeni yapıda görevleri şunlardır:

- `isVirtual: true` ile UI ve route kimliği taşımak
- `path: 'virtual:<isim>'` ile hangi kategorinin açıldığını belirlemek
- `allowedExtensions` bilgisini kategori tanımıyla birlikte tutmak

Gerçek kategori verisi artık `lib/data/` katmanında yönetilir:

- `HiveService` Hive başlatma ve box erişimini yönetir
- `FileIndexRepository` aktif index ve taslak index kutularını yönetir
- `FileIndexService` cihaz dosyalarını tarayıp Hive index oluşturur
- `CategoryQueryService` kategori sonuçlarını index üzerinden sorgular
- `CategoryRepository` sayfanın kullandığı kategori erişim katmanıdır

### `buildTree()`

Root klasörü tamamen recursive kurmaz; yalnızca root için `loadFolder(root)` çağırır.

Ancak Task 12 sonrasında bu çağrı da doğrudan dosya sistemi okumak zorunda değildir:

- önce root için `directory_cache_box` içindeki cache snapshot'ı aranır
- varsa root liste cache'ten hydrate edilir
- cache geçerliyse başlangıç yüklemesi oradan tamamlanabilir
- cache eskiyse veya invalid ise gerçek dosya sistemi refresh'i çalışır

Yani başlangıç davranışı artık şu mantığa yaklaşır:

```text
loadFolder(root)
```

İsmi ağaç olsa da çalışma biçimi hâlâ lazy'dir; sadece root için ilk görünen veri artık
cache katmanı üzerinden hızlandırılabilir.

### `loadFolder(FolderNode folder)`

Burada artık iki farklı veri davranışı vardır:

#### Gerçek klasör

`folder.isVirtual == false` ise `_loadDirectoryFolder(folder, forceRefresh: ...)` çalışır.

Bu metod:

1. `Directory(folder.path)` oluşturur
2. klasör yoksa önce ilgili directory cache temizlenir, sonra hata döner
3. klasör varsa mevcut klasörün `FileStat.modified` değeri okunur
4. `directory_cache_box` içinde bu path için kayıt varsa önce cache snapshot'ı hydrate edilebilir
5. cache snapshot hydrate edildiğinde kullanıcı ilk veriyi beklemeden görebilir
6. ardından invalidation kontrolü yapılır:
7. cache süresi aşılmış mı?
8. klasör modified date değişmiş mi?
9. manuel `forceRefresh` istenmiş mi?
10. refresh gerekmiyorsa cache doğrudan kullanılabilir ve gereksiz dosya sistemi okuması atlanır
11. refresh gerekiyorsa `dir.list(followLinks: false)` ile gerçek çocuklar okunur
12. alt klasörler `FolderNode` olarak üretilir
13. eğer o alt klasör için önceden bilinen sayaç cache'i varsa yeni node'a hemen hydrate edilir
14. dosyalar `File` olarak toplanır
15. alfabetik sıralanır
16. final snapshot `folder.replaceChildren(...)` ile uygulanır
17. yeni klasör içeriği `DirectoryCacheModel` olarak `directory_cache_box` içine yazılır
18. aynı anda ilgili klasörün gerçek `folderCount/fileCount/totalCount` bilgisi de `FolderCountModel` olarak cache'e yazılır

Yani:

- sadece bir seviye içeriği yükler
- recursive yükleme yapmaz
- önce cache snapshot gösterebilir
- invalidation kontrolü geçiyorsa gereksiz refresh'i atlayabilir
- refresh sırasında mevcut görünür snapshot varsa partial ilerleme ile ekranı küçültmez; final sonuç gelene kadar mevcut liste görünür kalır
- açılmış klasör için kesin item sayısını aynı anda kalıcı cache'e de taşır

#### Sanal klasör

`folder.isVirtual == true` olduğunda `FileTree` artık root dizini recursive taramaz.
Bu durumda `loadFolder(...)` sadece eldeki çocuk listesini sıralayıp UI’a geri verir.

Kategori klasörünün gerçek verisi şu akışla hazırlanır:

1. `Klasoricerigisayfasi` açılır
2. `CategoryRepository.ensureCategoryReady(...)` çağrılır
3. Hive index yoksa `FileIndexService.refreshIndex(...)` tüm root’u tarar
4. sonuçlar `file_index_draft` kutusunda toplanır
5. tarama bitince aktif Hive index kutusuna alınır
6. sayfa `CategoryQueryService` ile ilk 100 sonucu çeker
7. scroll ilerledikçe sonraki 100 sonuç yüklenir

Sonuç:

- kategori klasörleri fiziksel klasör değildir
- aynı UI ile gösterilirler
- içerikleri artık doğrudan dosya sistemi recursive taramasıyla değil, Hive index/cache ile hazırlanır

Ek olarak gizlenen path'ler de `FileTree` seviyesinde ayrı bir set olarak tutulur.
Gerçek klasör taranırken hidden repository'den hydrate edilmiş bu path seti kontrol edilir;
böylece daha önce gizlenmiş öğeler normal klasör listesine tekrar düşmez.

### `agactaarama(String aranan)`

Arama davranışı:

1. `isSearching = true`
2. önce eski arama listeleri temizlenir
3. root klasör recursive taranır
4. klasör adı `contains(query)` ise `arananfolder` listesine eklenir
5. dosya adı `startsWith(query)` ise `arananfile` listesine eklenir
6. listeler alfabetik sıralanır
7. `isSearching = false`

Bu da önemli bir tasarım detayı:

- klasör araması `contains`
- dosya araması `startsWith`

## 6.8 `Dosyaislemleri`
### Task 14 sonrası güncel operasyon mimarisi

Task 14 sonrasında `Dosyaislemleri`, gerçek dosya sistemi işini doğrudan yapan sınıf
değil; seçim, clipboard ve progress state'ini yöneten provider katmanıdır.

Fiziksel operasyonlar artık şu katmanda toplanır:

- `lib/data/models/file_operation_models.dart`
- `lib/data/services/file_operation_service.dart`

Yeni davranış özeti:

- `kopyala(...)` seçili öğeleri clipboard state'ine alır
- `kes(...)` artık orijinali hemen silmez; yalnızca clipboard'ı cut moduna alır
- gerçek taşıma `yapistir(...)` sırasında yapılır
- paste öncesinde boş alan ve hedef çakışması kontrol edilir
- aynı isim varsa kullanıcıya `üzerine yaz / yeni isimle kopyala / atla / iptal`
  seçenekleri sunulur
- move akışında servis önce hedefe kopyalar, doğrulama sonrası source'u siler
- silme ve rename akışları servis içinde geçerli isim, hedef varlığı ve entity
  varlığı kontrolleriyle çalışır
- büyük batch işlemlerde provider geçici bir progress dialog açar ve servis
  progress callback'leriyle bu dialog güncellenir
- fiziksel değişiklikten sonra `Izinler.refreshRootEntries()` ve gerekirse
  `fileTree.loadFolder(..., forceRefresh: true)` ile görünür liste/cache state'i yenilenir
- arama ve kategori tarafında kullanılan Hive index için
  `FileIndexService.refreshIndex(...)` arka planda tetiklenir

Bu nedenle Task 14 sonrası doğru yorum şudur:

- `Dosyaislemleri` = UI state + orchestration
- `FileOperationService` = güvenli fiziksel dosya operasyonları
- repository + `Izinler` sync akışı = kalıcı kayıtlar ve görünür liste yenileme

### GÃ¼ncel arama davranÄ±ÅŸÄ±

`FileTree.agactaarama(...)` artÄ±k arama ekranÄ±nÄ±n ana veri kaynaÄŸÄ± olarak kullanÄ±lmaz.
Arama akÄ±ÅŸÄ± `features/search/state/search_controller.dart` iÃ§indeki `SearchController` ile yÃ¶netilir.

Yeni akÄ±ÅŸ:

1. kullanÄ±cÄ± yazmaya baÅŸlar
2. controller 400 ms debounce uygular
3. sorgu 2 karakterden kÄ±saysa arama baÅŸlatÄ±lmaz
4. `SearchRepository.ensureSearchReady(...)` Hive index'i hazÄ±rlar
5. gerekirse `FileIndexService` root altÄ±ndaki dosya ve klasÃ¶rleri Hive iÃ§ine indexler
6. `SearchQueryService` dosya adÄ±, klasÃ¶r adÄ±, uzantÄ±, kategori ve `parentPath` alanlarÄ± Ã¼zerinden sorgu yapar
7. ilk 100 sonuÃ§ dÃ¶ner, scroll ile sonraki 100 sonuÃ§lar yÃ¼klenir

Bu nedenle gÃ¼ncel arama mantÄ±ÄŸÄ±:

- recursive fiziksel tarama yerine Hive index Ã¼zerinden Ã§alÄ±ÅŸÄ±r
- dosya ve klasÃ¶r kayÄ±tlarÄ±nÄ± aynÄ± index iÃ§inde tutar
- arama state'ini `FileTree` yerine ayrÄ± controller katmanÄ±nda yÃ¶netir

Dosya: `lib/features/files/state/dosyaislemleri.dart`

Bu provider uygulamadaki operasyon katmanıdır.

Görevleri:

- seçili klasör ve dosyaları tutmak
- kopyala/kes/yapıştır işlemleri
- silme
- yeniden adlandırma
- kaydetme
- gizleme
- klasör veya dosya ekleme
- paylaşma
- temizlik modülü için gereksiz dosya toplama ve silme

### Temel state alanları

- `folderlistesi` -> seçili klasörler
- `filelistesi` -> seçili dosyalar
- `kopyalananfolder`
- `kopyalananfile`
- `gereksizdosyalar`
- `gereksizdosyalartoplamboyutu`
- `loading`
- `aramaloading`
- `gecicidosyalaralinmasi`
- `onbellekdosyalarialinmasi`

### Metotların işlev özeti

| Metot | Ne yapar? |
| --- | --- |
| `temizlenecekleritoplamaislemi` | temp/cache alanlarını tarar, silinebilir dosyaları listeler |
| `gereksizdosyalaritemizle` | bulunan gereksiz dosyaları siler |
| `sil` | seçili dosya/klasörleri gerçek dosya sisteminden siler |
| `kopyala` | seçili öğeleri kopyalama tamponuna alır |
| `kes` | seçili öğeleri kopyalama tamponuna alır, sonra orijinal yerden siler |
| `yapistir` | kopyalanan klasör/dosyaları aktif klasöre ekler |
| `klasorekle` | aktif klasör altında yeni klasör oluşturur |
| `fileekle` | aktif klasöre dosya kopyalar |
| `adlandir` | dosya veya klasörü rename eder |
| `kaydet` | seçili öğeleri `FileTree.kaydedilen*` listelerine ekler |
| `sakla` | seçili öğeleri `FileTree.gizlenen*` listelerine taşır |
| `dosyalaripaylas` | seçili dosyaları `share_plus` ile paylaşır |

### Bu provider neden önemli?

Çünkü UI'daki seçim modu doğrudan bu sınıfa yansır:

- kullanıcı uzun basar
- ilgili `Klasor` veya `Dosya` widget'ı seçili state'ini değiştirir
- `Dosyaislemleri.folderlistesi` veya `filelistesi` güncellenir
- alt işlem çubuğundaki eylemler bu listeler üzerinden çalışır

Yani operasyon katmanı ile UI seçim modu sıkı bağlıdır.

### Güncel kalıcı kayıt davranışı

Task 8 sonrasında `Dosyaislemleri` içindeki kaydetme, gizleme ve silme akışları doğrudan
`FileTree` listelerini authoritative kaynak gibi mutate etmez.

Güncel akış:

- `kaydet(...)` seçili path'leri `SavedRepository` içine yazar
- `sakla(...)` seçili path'leri `HiddenRepository` içine yazar
- klasör veya dosya açılışında recent kayıtları `RecentRepository` üzerinden güncellenir
- yazma sonrası `Izinler.syncSavedEntries()`, `syncHiddenEntries()`, `syncRecentEntries()`
  ile provider cache'i yeniden hydrate edilir
- silme veya kesme ile path ortadan kalkarsa `removePathsFromPersistentCollections(...)`
  çağrılır ve ilgili Hive kayıtları da temizlenir

Bu sayede provider tarafı Hive box ile doğrudan konuşmaz; kalıcı veri akışı repository
katmanında kalır.

## 7. Dosya ve Klasör Ekranlarının Rolleri

## 7.1 `Dosyalar` sayfası

Dosya: `lib/features/files/presentation/pages/dosyalar.dart`

Bu ekran root klasörün direkt çocuklarını listeler.

Dikkat edilmesi gereken kritik fark:

- Bu ekran root için tüm `Izinler` nesnesini izlemez.
- Liste verisi `Selector<Izinler, FolderFileEntries>` üzerinden `rootEntries`
  snapshot'ı ile alınır.
- Yani burası aktif klasör (`getCurrentFolder`) ekranı değildir.
- Burası root listeleme ekranıdır.
- İzin kontrolü çözülürken shared `FolderListSkeleton` gösterir.
- Root boşsa `EmptyStateWidget`, beklenmeyen hata durumunda `ErrorStateWidget` kullanır.

Task 9 sonrasında liste verisi `PaginatedFileListView` üzerinden gösterilir:

- İlk açılışta en fazla 100 öğe listelenir.
- Kullanıcı aşağı kaydırdıkça sonraki 100 öğe yüklenir.
- Yükleme sırasında listenin alt kısmında `FileItemSkeleton` placeholder'ları gösterilir.
- Veri değiştiğinde (Selector tetiklendiğinde) pagination ilk 100 öğeye sıfırlanır.

Task 12 sonrasında root liste için ek davranış vardır:

- uygulama açılışında root klasör mümkünse önce `directory_cache_box` içinden hydrate edilir
- bu sayede kullanıcı root ekranında daha hızlı ilk içerik görebilir
- cache süresi dolmuşsa veya root modified date değişmişse gerçek dosya sistemi refresh'i devreye girer
- pull-to-refresh `Izinler.refreshRootEntries()` üzerinden `fileTree.buildTree(forceRefresh: true)` çalıştırır
- manuel refresh cache'i yalnızca okumakla kalmaz, yeni dosya sistemi snapshot'ı ile günceller

Bu yüzden `/dosyalar` ekranı artık yalnızca root çocuklarını gösteren basit bir liste değil,
aynı zamanda root klasör cache'inin görünür yüzüdür.

Başka bir ifadeyle:

- `/dosyalar` = kök dizin görünümü
- `/klasoricerigisayfasi` = aktif klasör görünümü

## 7.2 `Klasoricerigisayfasi`

Dosya: `lib/features/files/presentation/pages/klasoricerigisayfasi.dart`

Bu ekran hedef klasörün path bilgisini route query parametresinden alır.
İn-app geçişlerde aynı anda `FolderRouteData` nesnesi `extra` ile de taşınır.

Ekran açılır açılmaz:

- hedef klasör için sayfa içi state hazırlanır
- gerekiyorsa query path'ten `FolderNode` referansı yeniden çözülür
- görünür klasör bilgisi breadcrumb ve dosya operasyonları için provider ile senkronize edilir
- içerik `fileTree.loadFolder(..., forceRefresh: ..., onProgress: ...)` ile sayfa içinde async yüklenir
- eğer klasör için geçerli cache varsa ilk aşamada cache snapshot gösterilir
- cache yoksa shared `FolderListSkeleton` gösterilir
- cache geçersizse veya manuel refresh istenmişse gerçek dosya sistemi arka planda çalışır
- kullanıcı o sırada mevcut cache listesini görmeye devam eder
- final refresh tamamlanınca tam liste güncel snapshot ile görünür
- hata varsa `ErrorStateWidget`, boşsa `EmptyStateWidget` gösterilir

Yani bu ekran artık sadece `Izinler.getCurrentFolder` verisini körlemesine render etmez.
Provider aktif klasörü yardımcı UI state olarak tutar; asıl hedef klasör bilgisi route
query path'i üzerinden taşınır ve yükleme sayfanın lifecycle akışında yapılır.

Task 12 ile birlikte bu lifecycle içine şu cache davranışı da eklenmiştir:

- `forceRefresh: false` ise sayfa önce cache kullanmayı dener
- cache yaşı ve klasör modified date geçerliyse gereksiz dosya sistemi taraması atlanabilir
- `RefreshIndicator` her zaman `forceRefresh: true` ile gerçek refresh ister
- refresh sırasında mevcut görünen sayfalama penceresi mümkün olduğunca korunur; liste geçici olarak sıfıra düşmez

Task 9 sonrasında dizin klasörleri de 100'er öğe ile sayfalanır:

- `_visibleDirectoryFolderCount` ve `_visibleDirectoryFileCount` state alanları ile
  o an görünen dizin öğesi sayısı takip edilir.
- Klasör yüklendikten sonra ilk sayfa (en fazla 100 öğe) gösterilir.
- Kullanıcı scroll ile alta yaklaştığında `_loadMoreDirectoryItems()` tetiklenir ve
  sonraki 100 öğe eklenir.
- Kategori klasörleri için mevcut `_hasMoreCategoryItems` + `_loadMoreCategoryItems()`
  mekanizması korunur; dizin ve kategori pagination'ları birbirinden bağımsızdır.
- Yeni klasöre girilince ya da `RefreshIndicator` tetiklenince pagination sıfırlanır.

## 7.3 `Gizlidosyalar`

Dosya: `lib/features/files/presentation/pages/gizlidosyalar.dart`

Bu ekran:

- `fileTree.gizlenenfolder`
- `fileTree.gizlenenfile`

listelerini gösterir.

Navigasyon açısından önemli nokta:

- Bu listedeki klasörler de yine aynı `Klasor` widget'ı ile çizilir.
- Dolayısıyla bir gizli klasöre tıklamak da normal klasörle aynı `onTap` akışına girer.
- Liste boşsa ekran doğrudan `EmptyStateWidget` ile durum gösterir.

Güncel yapıda bu ekran seçim modunu `Selector<Altislemprovider, bool>` ile,
liste verisini ise `Selector<Izinler, FolderFileEntries>` ile izler.

Task 9 sonrasında liste verisi `PaginatedFileListView` üzerinden gösterilir:
ilk 100 öğe anında listelenir, kullanıcı scroll ile alta yaklaştığında
sonraki 100 öğe yüklenir ve listenin altında `FileItemSkeleton` gösterilir.

## 7.4 `Kaydedilendosyalar`

Dosya: `lib/features/files/presentation/pages/kaydedilendosyalar.dart`

Bu ekran:

- `fileTree.kaydedilenfolder`
- `fileTree.kaydedilenfile`

listelerini gösterir.

Klasör tıklama davranışı yine aynıdır; aynı `Klasor` widget'ı kullanılır.
- Kayıtlı öğe yoksa liste yerine `EmptyStateWidget` render edilir.

Güncel yapıda bu ekran da gizli dosyalar sayfası gibi dar selector'larla çalışır;
selection state ve saved list state birbirinden ayrı rebuild alır.

Task 9 sonrasında liste verisi `PaginatedFileListView` üzerinden gösterilir:
ilk 100 öğe anında listelenir, kullanıcı scroll ile alta yaklaştığında
sonraki 100 öğe yüklenir ve listenin altında `FileItemSkeleton` gösterilir.

## 7.5 `Katagorikicerik`

Dosya: `lib/features/files/presentation/pages/katagorikicerik.dart`

Bu ekran artık bağımsız bir kategori listeleme mantığı taşımaz.
Güncel yapıda görevi yalnızca uyumluluk katmanı olmaktır:

- `Izinler.getCurrentFolder` içinden o anki hedef klasörü alır
- bu bilgiyi `FolderRouteData` olarak `Klasoricerigisayfasi` widget’ına iletir
- böylece kategori ekranı ile normal klasör ekranı aynı yükleme, hata, refresh ve pagination akışını paylaşır

Pratik sonuç:

- kategorik içerik davranışının tek merkezi `Klasoricerigisayfasi` olmuştur
- eski ayrı kategori sayfası mantığı kaldırılmıştır
- tanımlı route dursa bile veri yükleme mantığı tek yerde tutulur

Ayrıca wrapper ekran `currentFolder` alanını tüm provider yerine
`Selector<Izinler, FolderNode?>` ile izler.

## 7.6 `Arama`

Dosya: `lib/features/search/presentation/pages/arama.dart`

Arama ekranı:

- üstte bir `TextField`
- altta arama sonuçlarını gösteren bir liste

Kullanıcı yazdıkça:

- `context.read<Izinler>().fileTree.agactaarama(text)`

çalışır.

Sonuçlar:

- klasörse `Klasor`
- dosyaysa `Dosya`

widget'ı ile gösterilir.

Bu şu demektir:

- arama sonucu klasöre tıklamak da normal klasör açılış akışına girer
- arama çalışırken shared `FolderListSkeleton` gösterilir
- sorgu boşsa veya sonuç yoksa `EmptyStateWidget` kullanılır
- arama sırasında hata yakalanırsa `ErrorStateWidget` ile tekrar deneme aksiyonu verilir

### GÃ¼ncel davranÄ±ÅŸ

Arama ekranÄ± artÄ±k doÄŸrudan `context.read<Izinler>().fileTree.agactaarama(text)` Ã§aÄŸrÄ±sÄ± yapmaz.
Onun yerine `SearchController` kullanÄ±r ve ÅŸu davranÄ±ÅŸÄ± uygular:

- `TextField` giriÅŸi 400 ms debounce ile iÅŸlenir
- minimum 2 karakter zorunludur
- arama ilk olarak Hive index iÃ§inde yapÄ±lÄ±r
- ilk 100 sonuÃ§ listelenir
- scroll sona yaklaÅŸtÄ±kÃ§a sonraki 100 sonuÃ§ yÃ¼klenir
- arama loading durumunda shared `FolderListSkeleton` gÃ¶sterilir
- sorgu boÅŸsa veya sonuÃ§ yoksa `EmptyStateWidget` kullanÄ±lÄ±r
- hata varsa `ErrorStateWidget` ile tekrar deneme sunulur
- aktif sorguda `RefreshIndicator` ile force refresh yapÄ±labilir

Bu yÃ¼zden gÃ¼ncel arama ekranÄ±:

- fiziksel dosya sistemini her harfte recursive taramaz
- aynÄ± Hive index Ã¼zerinden hem dosya hem klasÃ¶r sonucu Ã¼retebilir
- pagination ve debounce mantÄ±ÄŸÄ±nÄ± UI'dan ayÄ±rÄ±p controller katmanÄ±na taÅŸÄ±r

## 7.7 `Anasayfaicerigi`

Dosya: `lib/features/home/presentation/pages/anasayfa_icerigi.dart`

Bu ekran iki ana parçadan oluşur:

1. kategori ikonları
2. son gezilen öğeler

İzin ve ilk veri beklenirken kategori alanında `CategoryGridSkeleton`,
son gezilenler alanında `FolderListSkeleton` gösterilir.

### Kategori ikonları

Her ikon tıklandığında:

1. ilgili sanal kategori `FolderNode` seçilir
2. hedef klasör path'i route query ve `FolderRouteData` ile taşınır
3. `context.push(Paths.folderContentLocation(...))`

Yani kategori ekranları ayrı route kullanmaz; yine klasör içeriği sayfasını kullanır.

Bu akışın yeni farkı şudur:

1. sayfa açılır açılmaz hedef sanal kategori path'i çözülür
2. Hive index hazır değilse kullanıcıya yalnızca kategoriye özel hazırlık metni gösterilir
3. `FileIndexService` root dizini tarayıp `IndexedFileModel` kayıtlarını Hive içine yazar
4. ilk 100 sonuç `CategoryRepository` üzerinden çekilir
5. kullanıcı aşağı indikçe sonraki 100 sonuç sayfalanarak yüklenir
6. index eskiyse sayfa mevcut cache’i gösterirken arka planda sessiz refresh başlatılabilir

Bu nedenle ana sayfadaki kategori kısayolları artık ağır recursive taramayı doğrudan tetiklemez;
yalnızca kategori kimliğini açar ve veri katmanındaki index/cache akışını başlatır.

### Son gezilenler

`fileTree.ensongezilenfolders` ve `fileTree.ensongezilenfiles` listeleri gösterilir.

Buradaki klasörler de yine `Klasor` widget'ı ile açılır.

Task 7 sonrasında ana sayfa bu veriyi tüm `Izinler` provider'ını izleyerek değil,
`Selector<Izinler, FolderFileEntries>` üzerinden `recentEntries` snapshot'ı ile alır.
Kategori kısayolları ile son gezilenler listesi birbirinden bağımsız rebuild olur.
Liste boşsa `EmptyStateWidget` gösterilir.

Task 9 sonrasında `Anasayfaicerigi` `StatefulWidget`'a dönüştürülmüştür:

- Dış `ListView`'e bir `ScrollController` bağlanmıştır.
- Son gezilenler bölümü `_PaginatedRecentSection` alt widget'ı üzerinden çalışır.
- `_PaginatedRecentSection`, dış `ScrollController`'ı dinler; scroll alta yaklaştığında
  otomatik olarak sonraki 100 öğeyi yükler.
- Selector tetiklenince (veri değişince) `didUpdateWidget` aracılığıyla pagination sıfırlanır.
- Tüm recent öğeler gösterildiğinde listenin sonunda `l10n.listEnd` metni çıkar;
  daha fazla öğe varken alt kısımda `FileItemSkeleton` placeholder gösterilir.

## 7.8 `Menu`

Dosya: `lib/features/menu/presentation/pages/menu.dart`

Bu ekran dosya gezinme kadar yoğun olmasa da genel mimariyi tamamlar.

İçerikleri:

- saat stream'i
- pil stream'i
- storage kullanımı
- tema değişimi
- dil seçimi
- derin temizlik rotası
- gizli dosyalar rotası
- kaydedilen dosyalar rotası

Bu sayfa ayrıca gizli dosyalar için bottom sheet şifre akışı da barındırır.

Üstteki saat, depolama ve pil özetleri ilk veri gelene kadar artık ham spinner
yerine shared `AppSkeleton` ve `StorageCardSkeleton` kullanır.

Şifre doğruysa:

- `context.push(Paths.gizlidosyalar)`

çağrılır.

## Ortak Loading ve Skeleton Sistemi

Shared loading katmanı `lib/shared/widgets/` altında toplanır.

Temel parçalar:

- `AppSkeleton` ortak animasyonlu blok iskeletidir.
- `FileItemSkeleton` tek satırlık dosya/klasör placeholder'ıdır.
- `FolderListSkeleton` liste tabanlı ekranlar için çoklu satır skeleton üretir.
- `CategoryGridSkeleton` ana sayfa kategori alanı için kullanılır.
- `StorageCardSkeleton` menu üst bilgi kartlarının loading durumunu gösterir.
- `EmptyStateWidget` ve `ErrorStateWidget` tüm ekranlarda ortak boş/hata sunumudur.

Profesyonel davranış kuralı şudur:

- normal klasör yüklemelerinde kullanıcıya açıklayıcı uzun progress metni gösterilmez
- bunun yerine skeleton placeholder'lar kullanılır
- açıklayıcı progress metinleri sadece kategorik sistem gibi ağır özel akışlara bırakılır

## 8. Klasör Container'ına Tıklanınca Gerçekleşen Tam Akış

Bu bölüm raporun en kritik kısmıdır.

Klasör satırı widget'ı:

- Dosya: `lib/features/files/presentation/widgets/dosya_folder.dart`
- Widget adı: `Klasor`

Bu widget proje içinde çok tekrar kullanılıyor:

- root liste (`Dosyalar`)
- klasör içeriği ekranı
- arama sonuçları
- gizli dosyalar
- kaydedilen dosyalar
- son gezilenler

Yani klasör açma mantığının tek merkezi büyük ölçüde bu widget'tır.

### 8.1 `Klasor` widget'ının sorumlulukları

Bu widget:

- klasör ikonunu ve adını gösterir
- oluşturulma/değişim tarihini gösterir
- item sayısını doğrudan `childCount` yerine `FolderCountModel` cache metadata'sından göstermeye çalışır
- sayaç cache'i yoksa geçici olarak `-` gösterir; yanlışlıkla `0` göstermez
- kendi `FolderNode` değişimlerini dinlediği için tarih veya sayaç bilgisi sonradan geldiğinde kart kendini yeniden çizer
- seçim modunda seçili durumunu taşır
- uzun basınca seçim moduna sokar
- normal tıklamada klasör içine girer

Ek davranış:

- kart ekrana ilk geldiğinde fiziksel klasörse `Izinler.ensureFolderCount(...)` çağrısı tetiklenir
- böylece yalnızca gerçekten görünür olan klasör kartları için arka planda sayaç işi başlatılır
- aynı path için tekrar eden işler `FileTree` içindeki kuyruk mantığıyla bastırılır

### 8.2 Uzun basma akışı

Kullanıcı klasöre uzun bastığında:

1. `Altislemprovider.changeanahtar()` çağrılır
2. widget içindeki `secilmismi` bool'u `true/false` yapılır
3. seçildiyse `Dosyaislemleri.folderlistesi` içine ilgili `FolderNode` eklenir

Bu akış klasöre girmek için değil, toplu işlem moduna geçmek içindir.

### 8.3 Normal tıklama akışı

Kullanıcı klasör container'ına normal tıklayınca `onTap` içinde şu adımlar gerçekleşir:

#### Adım 1: `Izinler` provider okunur

```dart
context.read<Izinler>()
```

Bu provider son gezilenler repository'sini güncellemek ve gerektiğinde klasör
sayaç metadata'sını tetiklemek için kullanılır.

#### Adım 2: Son gezilenler listesi güncellenir

```dart
unawaited(context.read<Izinler>().addRecentFolderEntry(widget.klasor));
```

Bu sayede kullanıcı daha sonra ana sayfadaki "son gezilenler" bölümünde bu klasörü tekrar görebilir.
Kayıt artık doğrudan memory listesine eklenmez; önce `RecentRepository` içine path bazlı yazılır,
ardından `Izinler.syncRecentEntries()` ile UI cache'i hydrate edilir.

Bu adım route değişmeden önce yapılır.

#### Adım 3: Route `extra` ile hedef klasör bilgisi aktarılır

Klasör tıklanır tıklanmaz ağır bir `await setCurrentFolder(...)` çağrısı yapılmaz.
Bunun yerine hedef klasör bilgisi route `extra` içine konur:

```dart
context.push(
  Paths.klasoricerigisayfasi,
  extra: FolderRouteData.fromFolderNode(widget.klasor),
);
```

Bu yapının kritik sonucu şudur:

- kullanıcı geçişi beklemeden yeni sayfayı görür
- klasör path'i route akışında taşınır
- sayfa açılışı dosya sistemi yüklemesine bloklanmaz

### 8.4 Yeni sayfa açıldığında içerik nasıl belirleniyor?

`Klasoricerigisayfasi` açıldığında route `extra` içindeki `FolderRouteData`
okunur ve hedef `FolderNode` çözülür.

Sonra görünüm şu sırayla oluşur:

1. Sayfa hemen açılır
2. shared `FolderListSkeleton` gösterilir
3. görünür klasör provider ile senkronize edilir
4. `fileTree.loadFolder(..., onProgress: ...)` çağrılır
5. klasör içeriği async okunur
6. ilk parçalar geldikçe liste ekrana basılır
7. yükleme bitince geçici loading göstergesi kalkar
8. hata varsa shared hata durumu gösterilir

Bu nedenle klasör yükleme sorumluluğu artık route öncesi provider çağrısında değil,
sayfanın kendi lifecycle akışındadır.

### 8.5 Bir klasörün içine girdikten sonra başka klasöre tıklanırsa ne olur?

İkinci bir klasöre tıklanırsa süreç tekrar eder:

1. ilgili klasör son gezilenlere eklenir
2. aynı ekran yeni bir route kaydı olarak tekrar `push(...)` edilir
3. yeni sayfa örneği anında açılır
4. o sayfa kendi klasörünü kendi içinde async yükler
5. geri dönüşte navigator stack bir önceki klasör sayfasını yeniden görünür yapar

Bu yüzden uygulamanın klasör derinliği esas olarak şu ikinin birleşimidir:

- router stack
- route `extra` ile taşınan hedef klasör bilgisi

### 8.6 Aynı akış hangi ekranlardan tekrar kullanılıyor?

Bu çok önemli:

- `Dosyalar` ekranındaki klasörler
- `Arama` ekranındaki klasör sonuçları
- `Gizlidosyalar` ekranındaki klasörler
- `Kaydedilendosyalar` ekranındaki klasörler
- `Anasayfaicerigi` içindeki son gezilen klasörler

hepsi aynı `Klasor` widget'ını kullandığı için aynı akıştan geçer.

Aynı tekrar kullanım, klasör item count cache davranışını da standartlaştırır:

- root listede görülen klasörler
- arama sonuçlarındaki klasörler
- gizli ve kaydedilen klasörler
- son gezilen klasörler

aynı `FolderCountModel` + Hive cache mantığıyla sayaç gösterir.

Yani "klasör tıklandı -> route `extra` hazırlandı -> sayfa hemen açıldı ->
içerik sayfa içinde async yüklendi" mantığı uygulama genelinde tekrar eden
standart davranıştır.

## 9. Dosya Container'ına Tıklanınca Ne Oluyor?

Dosya widget'ı da aynı dosyada:

- `Dosya` widget'ı
- Dosya: `lib/features/files/presentation/widgets/dosya_folder.dart`

Akış:

1. Dosya son gezilenler listesine eklenir: `ensongezilenfiles`
2. Eğer uzantı `.zip` ise `unzipFile(...)` çalışır
3. Değilse `OpenFilex.open(widget.file.path)` ile dış uygulama/işletim sistemi seviyesinde açılır

Ek notlar:

- görsel ve video thumbnail üretimi artık widget içinde doğrudan yapılmaz
- `ThumbnailCacheService` önce Hive içindeki `thumbnail_cache_metadata` kaydını kontrol eder
- geçerli thumbnail varsa uygulamanın cache dizinindeki dosya doğrudan gösterilir
- thumbnail yoksa item önce normal dosya ikonuyla çizilir
- üretim arka planda başlatılır ve tamamlanınca sadece ilgili `Dosya` item'ı yeniden çizilir
- aynı dosya için tekrar tekrar thumbnail üretimi yapılmaz; servis aynı path için tek job tutar
- video thumbnail üretimi limitli kuyrukla çalışır, hızlı scroll sırasında üretim ertelenebilir
- zip dosyaları `getExternalStorageDirectory()/unzip` altına açılır

## 10. Path ve Klasör Gezinme Mantığı

Bu proje için "path mantığı" birkaç ayrı noktaya bölünmüş durumda.

### 10.1 Fiziksel root path

Root:

```text
/storage/emulated/0
```

Bu path:

- `FileTree` kökü
- aramanın başlangıç noktası
- kategori taramasının başlangıç noktası

Task 12 sonrasında bu path aynı zamanda root directory cache anahtarıdır:

- `directory_cache_box['/storage/emulated/0']`
- root klasör snapshot'ı bu key ile tutulur

### 10.2 Breadcrumb/path gösterimi

Breadcrumb doğrudan `FolderNode.parent` kullanılarak üretilmiyor.

Bunun yerine:

- klasör sayfasının hedefi önce route query içindeki `path` ile belirleniyor
- `/dosyalar` route'una dönülürse görünür klasör state'i tekrar root klasöre senkronize ediliyor
- diğer klasör sayfalarında bu path provider içindeki görünür klasör state'i ile senkronize ediliyor
- aktif klasörün `path` string'i `/` ile split ediliyor
- ilk 4 segment atılıyor
- root için `kok dizin`, sanal klasör için doğrudan klasör adı gösteriliyor

Bu yüzden path gösterimi Android storage şemasına bağımlı.

### 10.3 Root ekranı ile aktif klasör kavramı farklı

Bu çok önemli mimari detay:

- `Dosyalar` ekranı root'un çocuklarını gösterir
- `Izinler.getCurrentFolder` ise route ile açılmış görünür klasörü temsil eder

Yani kullanıcı root ekranında olabilir ama `/klasoricerigisayfasi?path=...` route'u
açıldığında aktif klasör kimliği query path üzerinden kurulur.

Aynı path bilgisi artık sadece navigasyon için değil, directory cache anahtarı olarak da kullanılır.
Bu yüzden route path ile cache path birbiriyle uyumludur:

- hangi klasör açıldıysa aynı string cache key olur
- aynı klasöre geri dönüldüğünde önce cache okunabilir
- manuel refresh geldiğinde yine aynı key üzerindeki cache kaydı güncellenir

### 10.4 Sanal klasör path'leri

Kategori klasörlerinde gerçek path yoktur. Örnek yapı:

```text
virtual:resim dosyalari
virtual:pdf dosyalari
```

Bu nedenle:

- kategori klasörleri fiziksel klasör gibi çizilse de mantıksal klasördür
- route üzerinde yine path kimliği taşırlar
- `virtual:...` path'i açılınca sayfa bu değeri `FileCategoryConstants` içindeki bilinen kategori tanımına eşler
- eşleşen kategori doğrudan dosya sisteminde aranmaz; önce Hive index hazır mı kontrol edilir
- sonuçlar `CategoryRepository` üzerinden index kutusundan okunur
- bu yüzden sanal path, hem UI kimliği hem de kategori sorgu anahtarı olarak kullanılır

### 10.5 Directory cache ve invalidation mantığı

Fiziksel klasörler için path artık directory cache anahtarı olarak da kullanılır.

Çalışma mantığı:

1. kullanıcı bir klasör path'i ile sayfayı açar
2. `FileTree` önce aynı path için `directory_cache_box` kaydını arar
3. kayıt varsa cache snapshot UI'a hızlıca verilebilir
4. sonra cache yaşı ve klasör modified date kontrol edilir
5. geçerliyse gereksiz dosya sistemi taraması atlanabilir
6. geçersizse veya kullanıcı refresh yapmışsa gerçek dosya sistemi okunur
7. final sonuç yine aynı path key'i altında cache'e geri yazılır

Bu yapı sayesinde path artık yalnızca routing kimliği değil, aynı zamanda klasör içeriği
cache yaşam döngüsünün de temel anahtarıdır.

## 11. `Anasayfa` Shell Sayfasının Rolü

Dosya: `lib/features/navigation/presentation/pages/anasayfa.dart`

Bu sayfa router'dan gelen `navigationShell` nesnesini alır ve tüm ortak iskeleti kurar.

İç sorumlulukları:

- üst navigation bar
- bazı durumlarda breadcrumb + popup satırı
- seçim modu alt işlem çubuğu
- alt taraftaki aç/kapat tetikleyicisi
- ortak `FloatingActionButton`
- `widget.navigationShell` body olarak yerleştirme

### 11.1 AppBar davranışı

`currentIndex == 2` yani `/dosyalar` branch'indeyken farklı bir app bar gösterilir:

- üstte navigation bar
- altta konum ve popup işlemleri

Diğer branch'lerde ise sadece üst navigation şeridi görünür.

Bu önemli bir sonuç doğurur:

- `/klasoricerigisayfasi` aktifken ayrı breadcrumb satırı gösterilmez
- çünkü o branch index 4'tür, index 2 değildir

### 11.2 Popup menü işlemleri

Bu menüden şunlar yapılabilir:

- klasör oluştur
- gizli dosyalara git
- kaydedilen dosyalara git
- uygun durumda yapıştır

Buradaki işlemler doğrudan provider'lara veya route'lara bağlanır.

### 11.3 Alt işlem çubuğu

`Altislemprovider.anahtar == true` olduğunda görünür.

Eylemler:

- sil
- kopyala
- kes
- kaydet
- sakla
- adlandır
- dosya varsa paylaş

Bu çubuk tamamen `Dosyaislemleri` provider'ındaki seçili listeler üzerinden çalışır.

### Güncel selector davranışı

Task 7 ile shell sayfasında rebuild alanı daraltılmıştır:

- alt işlem çubuğu görünürlüğü `Altislemprovider` selector'u ile ayrı izlenir
- paylaş butonu `Dosyaislemleri.hasSelectedFiles` selector'u ile ayrı izlenir
- breadcrumb/path satırı `Izinler.currentFolderPathSegments` selector'u ile güncellenir
- seçim temizleme akışı ortak helper üzerinden yapılır

Bu sayede seçim modu veya breadcrumb değiştiğinde tüm shell gövdesi yerine sadece
ilgili alt bölümler yeniden build olur.

## 12. Temizlik Sayfası Mantığı

Task 15 sonrasında bu ekranın akışı tamamen yenilenmiştir.

Güncel mimari:

- `Temizliksayfasi.initState` açılışta artık `Dosyaislemleri.startCleanupScan()` çağırır
- tarama ve silme işi UI içinde değil `lib/data/services/cleaning_service.dart`
  içindeki `CleaningService` tarafında yürür
- gereksiz dosya kriterleri merkezi sabitlerden gelir:
  `CleaningConstants.staleFileAge`,
  `CleaningConstants.largeFileThresholdBytes`,
  `CleaningConstants.scanYieldEveryFiles`
- temp ve cache dizinleri recursive stream ile parçalı taranır; her chunk sonunda
  `CleaningScanProgress` emit edilerek UI donmadan ilerleme gösterilir
- provider katmanı `cleanupScanProgress`, `cleanupScanResult`,
  `cleanupDeleteProgress`, `cleanupDeleteResult` ve `cleanupIssues`
  state'lerini açık eder
- kullanıcı onayı olmadan silme başlatılmaz; `Temizliksayfasi` önce confirm dialog gösterir
- silme sırasında determinate progress, silinen dosya sayısı, hata sayısı ve
  işlenen son path gösterilir
- silinen thumbnail cache dosyalarına ait metadata `ThumbnailCacheRepository`
  üzerinden temizlenir
- silme sonrasında `CleaningService` file index refresh tetikler; böylece silinen
  path'ler arama/index cache'lerinden de düşer
- tarama hataları ve silme hataları ekranda ayrı expansion card'larda listelenir
- işlem sonunda `cleanupReportTitle` kartı silinen dosya sayısı, boşalan alan ve
  hata özetini gösterir

Task 15 ile eski `listSync + artificial delay + direkt delete` akışı kaldırılmış,
cleanup ekranı gerçek progress ve raporlama üreten servis tabanlı yapıya geçirilmiştir.

Dosya: `lib/features/files/presentation/pages/temizliksayfasi.dart`

Bu ekran açılır açılmaz `initState` içinde:

- `context.read<Dosyaislemleri>().temizlenecekleritoplamaislemi(context)`

çalıştırır.

Provider tarafında süreç:

1. temp dizini okunur
2. app cache dizini okunur
3. recursive tüm dosyalar listelenir
4. 30 günden eski veya 100 MB'dan büyük dosyalar gereksiz sayılır
5. toplam silinecek boyut hesaplanır
6. kullanıcı onay verirse `gereksizdosyalaritemizle()` çağrılır

Bu sayfa route açısından shell içindeki gizli detay branch'lerden biridir.

## 13. Gizli Dosyalar ve Kaydedilen Dosyalar Mantığı

### 13.1 Kaydetme

`Dosyaislemleri.kaydet(...)` seçili öğeleri artık doğrudan memory listesinə eklemez.

Güncel akış:

- seçili klasör ve dosya path'leri `SavedRepository` içine yazılır
- kayıtlar Hive'da path bazlı tutulur
- ardından `Izinler.syncSavedEntries()` çağrılır
- bu metod Hive kaydını okuyup halen var olan path'leri `fileTree.kaydedilen*`
  cache listelerine yeniden hydrate eder

Bu işlem dosyayı fiziksel olarak taşımıyor; sadece kalıcı favori/kayıt referansı üretir.

Ek not:

- aynı path tekrar kaydedilirse Hive box key'i path olduğu için duplicate kayıt oluşmaz
- `Kaydedilendosyalar` ekranı `PaginatedFileListView` ile 100'er item halinde render edilir
- path artık mevcut değilse `Izinler.syncSavedEntries()` ilgili Hive kaydını otomatik temizler

### 13.2 Gizleme

`Dosyaislemleri.sakla(...)` seçili öğeleri `HiddenRepository` içine yazar ve aktif
klasör listesinden çıkarır.

Ek davranış:

- Hive'daki hidden kayıtları path bazlı saklanır
- `Izinler.syncHiddenEntries()` hem gizli öğe listesini hydrate eder
- hem de `FileTree` içine hidden path set'i yükler
- gerçek klasörler tekrar tarandığında bu path'ler normal görünür listeden filtrelenir

Yani kullanıcı perspektifinde öğe bulunduğu yerden kaybolur, gizli listede görünür
ve sonraki klasör yüklemelerinde de görünmez kalır.

Ek not:

- aynı path tekrar gizlenirse duplicate hidden kayıt oluşmaz; path box key olarak kullanılır
- `Gizlidosyalar` ekranı da `PaginatedFileListView` ile 100'er item pagination kullanır
- path artık yoksa `Izinler.syncHiddenEntries()` hidden repository kaydını temizler

### 13.3 Gizli dosyalar erişimi

Hem `Menu` hem de `Anasayfa` içindeki popup menü bir şifre bottom sheet'i açar.

Kodda şifre hard-coded:

```text
alihimeyda
```

Doğru girilirse:

- `context.push(Paths.gizlidosyalar)`

çalışır.

## 14. Son Gezilenler Mantığı

Bu proje "recent" davranışını otomatik toplar.

Klasör için:

- `Klasor.onTap` içinde `Izinler.addRecentFolderEntry(...)`

Dosya için:

- `Dosya.onTap` içinde `Izinler.addRecentFileEntry(...)`

Sonra ana sayfadaki `Anasayfaicerigi` bu listeleri gösterir.

Ancak güncel yapıda bu akış sadece memory listesine ekleme değildir:

- recent kayıtları `RecentRepository` içinde Hive'a yazılır
- uygulama açılışında repository okunup `fileTree.ensongezilen*` cache listeleri hydrate edilir
- artık bulunmayan path'ler tespit edilirse recent kaydı da otomatik silinir
- aynı path tekrar ziyaret edilirse duplicate entry oluşmaz; mevcut kayıt güncel timestamp ile overwrite edilir
- repository tarafında recent listesi üst limit ile tutulur; güncel limit `PersistentCollectionLimits.recentItemsMaxCount = 500` değeridir

Bu yüzden "recent" ekranı hâlâ kullanıcı etkileşimleriyle beslenir, ama veri kaynağı
artık kalıcı repository katmanıdır.

Task 9 sonrasında son gezilenler listesi de 100'er öğe ile sayfalanır.
`_PaginatedRecentSection` widget'ı dış `ScrollController`'ı dinler;
lista alta yaklaştığında `loadMore()` çağrılır ve sonraki 100 öğe gösterilir.

## 100'er Item Pagination Sistemi

Task 9 ile tüm listeleme ekranlarına 100'er öğe incremental loading (pagination) uygulanmıştır.

### Ortak altyapı

```text
lib/shared/pagination/
  paginated_state.dart      → Anlık pagination durumunu taşıyan immutable model
  paginated_controller.dart → Klasör+dosya listesini dilimleme ve sonraki sayfa hesaplama
  paginated_file_list.dart  → Bağımsız, kendi scroll state'ini yöneten liste widget'ı
```

`PaginatedController.pageSize = 100` merkezi sabit olarak tutulur.

### Sayfalama mantığı

1. İlk açılışta `PaginatedController.setData(folders, files)` ile ilk sayfa hesaplanır.
2. Klasörler önce doldurulur; kalan budget'la dosyalar doldurulur.
3. `ScrollController` `extentAfter < 320` olduğunu tespit edince `loadNextPage()` çağrılır.
4. `loadNextPage()` aynı öncelik sırasıyla bir sonraki 100 öğeyi ekler.
5. Yükleme sırasında listenin alt kısmında 3 adet `FileItemSkeleton` gösterilir.
6. `hasMore == false` olduğunda yükleme biter, skeleton kaybolur.

### Hangi ekranlar etkilendi?

| Ekran | Yöntem |
|---|---|
| `Dosyalar` | `PaginatedFileListView` — root öğeleri 100'er sayfalanır |
| `Gizlidosyalar` | `PaginatedFileListView` — gizli öğeler 100'er sayfalanır |
| `Kaydedilendosyalar` | `PaginatedFileListView` — kayıtlı öğeler 100'er sayfalanır |
| `Anasayfaicerigi` (son gezilenler) | `_PaginatedRecentSection` — dış ListView scroll ile yüklenir |
| `Klasoricerigisayfasi` (dizin modu) | `_visibleDirectoryFolderCount/_FileCount` ile dilim gösterimi |
| `Klasoricerigisayfasi` (kategori modu) | Mevcut `CategoryRepository` offset pagination korunur |
| `Arama` | Mevcut `SearchController.loadMore()` mekanizması korunur |

### Pagination sıfırlama

- `PaginatedFileListView`: `didUpdateWidget` içinde liste referansı değişince otomatik sıfırlanır.
- `Klasoricerigisayfasi` dizin modu: yeni klasör yüklenince veya `RefreshIndicator` tetiklenince sıfırlanır.
- `_PaginatedRecentSection`: `didUpdateWidget` içinde entries referansı değişince sıfırlanır.

## 15. Mimari Olarak Öne Çıkan Tasarım Kararları

Bu projede özellikle dikkat çeken kararlar şunlar:

### 15.1 Klasör kimliği route path + yardımcı state ile taşınıyor

Güncel yaklaşım hibrit bir yapıdır.

Ana karar:

- klasör kimliği route query parametresindeki `path` ile taşınır
- `FolderRouteData` `extra` nesnesi in-app geçişlerde hızlı veri aktarımı sağlar
- provider içindeki `currentFolder` ise breadcrumb ve operasyonlar için yardımcı UI state olarak tutulur

Karşılığı:

- URL artık hangi klasörün açık olduğunu anlatır
- aynı path zaten açıksa gereksiz `push` ve gereksiz reload önlenebilir
- sayfa provider state'i olmadan da hedef klasörünü çözebilir

### 15.2 Root liste ve klasör içeriği ekranları ayrılmış

- `/dosyalar` -> root görünümü
- `/klasoricerigisayfasi` -> aktif klasör görünümü

Bu, kullanıcı deneyimini sadeleştiriyor ama akışın büyük kısmını `currentFolder` state'ine bağımlı hale getiriyor.

### 15.3 Dosya ağacı tam önceden yüklenmiyor

Gerçekten recursive bir full tree yerine:

- root başlangıçta
- alt klasörler ihtiyaç halinde
- kategoriler ilk ihtiyaçta Hive index’e alınarak
- sonraki kategori açılışları cache üzerinden
- index eskiyse arka planda yenileme ile
- arama ise aynÄ± Hive index'i debounce + pagination mantÄ±ÄŸÄ±yla kullanarak

yaklaşımı benimsenmiş.

### 15.4 UI tekrar kullanımı yüksek

Aynı `Klasor` ve `Dosya` widget'ları birçok ekranda tekrar kullanılıyor.

Bu sayede:

- açma davranışı standart
- seçim davranışı standart
- görünüm tutarlı

## 16. Kısa Akış Diyagramları

### 16.1 Uygulama açılışı

```text
main()
-> bootstrap()
-> MultiProvider kurulumu
-> MaterialApp.router
-> initialLocation = /logo
-> Logosayfasi
-> 2 saniye sonra context.go('/')
-> StatefulShellRoute aktif
-> Anasayfa shell görünür
```

### 16.2 Dosyalar sekmesine geçiş

```text
NavigationBar tap
-> navigationShell.goBranch(2)
-> /dosyalar branch'i aktif
-> Dosyalar sayfası root klasör çocuklarını listeler
```

### 16.3 Bir klasöre tıklama

```text
Klasor.onTap
-> ensongezilenfolders.add(klasor)
-> aynı path zaten açıksa push edilmez
-> context.push('/klasoricerigisayfasi?path=<hedef>', extra: FolderRouteData(path + meta))
-> Klasoricerigisayfasi hemen açılır
-> sayfa içinde FolderListSkeleton görünür
-> fileTree.loadFolder(hedefKlasor) async çalışır
-> içerik geldikçe liste parça parça render edilir
-> yükleme bitince tam liste görünür
```

### 16.4 Geri tuşu

```text
Back
-> seçim modu açıksa önce kapat
-> değilse normal navigator pop çalışır
-> eğer önceki route bir klasör sayfasıysa o sayfa tekrar görünür olur
-> eğer /dosyalar ekranına dönüldüyse görünür klasör state'i root'a senkronize edilir
```

## 17. Router ve Shell Davranışı İçin Resmi Referanslar

Bu projedeki `go_router` yorumlarını teyit etmek için resmi referans olarak şu dokümantasyonlar kullanılabilir:

- `StatefulShellRoute` API: https://pub.dev/documentation/go_router/latest/go_router/StatefulShellRoute-class.html
- `StatefulNavigationShell.goBranch` API: https://pub.dev/documentation/go_router/latest/go_router/StatefulNavigationShell-class.html
- `GoRouter.push` API: https://pub.dev/documentation/go_router/latest/go_router/GoRouter/push.html
- `GoRouter.go` API: https://pub.dev/documentation/go_router/latest/go_router/GoRouter/go.html

Bu proje özelinde önemli yorum:

- Kodun kendi akışı, klasör bilgisini route parametresi yerine provider state'inde taşımayı seçmiştir.
- Dolayısıyla resmi router davranışı ile uygulamanın kendi `previousFolders` mantığı birlikte düşünülmelidir.

## 18. Sonuç

Bu projenin dosya gezgini mantığı şu cümleyle özetlenebilir:

> Router hangi ekranın ve hangi hedef klasörün açılacağını `path` query parametresi ile taşır, sayfa içeriği kendi lifecycle'ında async yükler, provider ise görünür klasör ve operasyon state'ini senkronize eder.

Özellikle klasör açma akışında:

- `Klasor` widget'ı etkileşimi yakalar
- hedef klasör path'i route query parametresi ile taşınır
- `extra` sadece hızlı metadata aktarımı için kullanılır
- `context.push('/klasoricerigisayfasi')` ile ekran hemen açılır
- yeni ekran önce shared skeleton gösterir
- `FileTree` ilgili içeriği sayfa içinde async ve kademeli biçimde yükler
- provider sadece görünür klasör, breadcrumb ve operasyonlar için yardımcı state olarak senkronize edilir

Bu yüzden uygulamanın güncel klasör gezinme mantığı:

- sayfa-önce-aç yaklaşımını kullanır
- hedef klasörü route query path'i ile taşır
- yüklemeyi sayfa içinde async yapar

Ve geri navigasyon mantığı da büyük ölçüde:

- `previousFolders`
- `Altislemprovider`

üzerinden şekillenir.
## GÃ¶rev 10 GÃ¼ncel RefreshIndicator DavranÄ±ÅŸÄ±

KlasÃ¶r ve listeleme ekranlarÄ±nda manuel yenileme artÄ±k standartlaÅŸtÄ±rÄ±lmÄ±ÅŸtÄ±r.

- `Dosyalar` sayfasÄ± `RefreshIndicator` ile kÃ¶k dizini yeniden yÃ¼kler.
- Bu yenileme `Izinler.refreshRootEntries()` Ã¼zerinden Ã¶nce hidden kayÄ±tlarÄ±nÄ± senkronize eder, sonra root klasÃ¶rÃ¼ yeniden tarar, ardÄ±ndan kaydedilen ve son gezilen listelerini tekrar senkronize eder.
- `Klasoricerigisayfasi` iÃ§inde normal klasÃ¶r yenilemesi aktif klasÃ¶r path'ini yeniden dosya sisteminden okur.
- AynÄ± sayfada kategorik klasÃ¶r yenilemesi `forceRefresh` ile kategori index gÃ¼ncellemesini tetikler ve sonucu tekrar ilk sayfadan baÅŸlatÄ±r.
- `Gizlidosyalar` sayfasÄ± `HiddenRepository` kayÄ±tlarÄ±nÄ± tekrar senkronize ederek silinmiÅŸ path'leri ayÄ±klar ve pagination'Ä± baÅŸa alÄ±r.
- `Kaydedilendosyalar` sayfasÄ± `SavedRepository` kayÄ±tlarÄ±nÄ± tekrar senkronize ederek silinmiÅŸ path'leri ayÄ±klar ve pagination'Ä± baÅŸa alÄ±r.
- `Arama` sayfasÄ± mevcut query iÃ§in `SearchController.refresh()` Ã§aÄŸrÄ±sÄ± ile aramayÄ± yeniden Ã§alÄ±ÅŸtÄ±rÄ±r ve sonuÃ§larÄ± ilk 100 item'dan tekrar kurar.

Bu yapÄ±yla yenileme sÄ±rasÄ±nda mevcut cache gÃ¶rÃ¼nmeye devam eder, arka planda dosya sistemi veya index kontrol edilir ve iÃ§erik gÃ¼ncel liste ile yeniden render edilir.
## Task 10 RefreshIndicator Notes

Manual refresh is now standardized across the list pages.

- `Dosyalar` refreshes the root directory with `RefreshIndicator`.
- `Izinler.refreshRootEntries()` first syncs hidden entries, then reloads the root folder, then re-syncs saved and recent entries.
- `Klasoricerigisayfasi` refresh reloads the active folder path from the file system.
- Virtual category refresh uses `forceRefresh` and rebuilds the category page from offset `0`.
- `Gizlidosyalar` refresh re-syncs `HiddenRepository`, removes missing paths, and resets pagination.
- `Kaydedilendosyalar` refresh re-syncs `SavedRepository`, removes missing paths, and resets pagination.
- `Arama` refresh re-runs the active query through `SearchController.refresh()` and rebuilds the first page of results.

Visible cached content stays on screen during refresh while the file system or index is checked in the background.
