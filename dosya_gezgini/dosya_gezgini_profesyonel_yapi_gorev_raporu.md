# Dosya Gezgini Projesi Profesyonel Yapı Güncelleme Görev Raporu

Bu rapor, mevcut `dosya_gezgini` Flutter projesinin performans, mimari sürdürülebilirlik, veri saklama, arama, kategori, loading ve dosya gezinti mantıklarını profesyonel dosya yöneticisi yaklaşımına taşımak için hazırlanmıştır.

Bu dosya doğrudan Codex / AI geliştirme ajanına verilecek bir görev listesi olarak kullanılabilir.

Kaynak alınacak ana rapor:

```text
PROJE_CALISMA_MANTIGI_RAPORU.md
```

Ajan her göreve başlamadan önce mevcut proje kodlarını ve özellikle `PROJE_CALISMA_MANTIGI_RAPORU.md` içindeki ilgili bölümü okumalıdır. Her görev tamamlandığında, bu rapordaki ilgili yapı anlatımı artık eski davranışı değil, yeni profesyonel davranışı anlatacak şekilde güncellenmelidir.

---

# 0. Genel Uygulama Talimatları

Bu görevler uygulanırken aşağıdaki kurallara uyulmalıdır:

1. Projenin mevcut Flutter mimarisi korunmalıdır.
2. Kod yapısı temiz, katmanlı ve sürdürülebilir hale getirilmelidir.
3. Mevcut `Provider` yapısı tamamen çöpe atılmamalı, ama sorumlulukları ayrıştırılmalıdır.
4. Gerekli veri saklama işlemleri için `Hive` kullanılmalıdır.
5. `Hive` ile ilgili tüm kalıcı veri işlemleri yeni oluşturulacak `data/` katmanında toplanmalıdır.
6. Loading gerektiren yerlerde ortak skeleton widget'ları kullanılmalıdır.
7. Skeleton widget'ları `lib/shared/` altında tanımlanmalıdır.
8. Klasör sayfalarında aşağı kaydırarak yenileme desteği `RefreshIndicator` ile sağlanmalıdır.
9. Tüm listeleme ekranlarında 100'er item yükleyen incremental loading / pagination sistemi uygulanmalıdır.
10. Kategorik klasörler açılırken kullanıcıya açıklayıcı progress yazıları gösterilebilir.
11. Normal klasör açılışlarında kullanıcıya uzun yazılarla bekletme yapılmamalı, sadece uygun skeleton animasyonları gösterilmelidir.
12. Ağır dosya sistemi işlemleri mümkün olduğunca UI akışını kilitlemeyecek şekilde tasarlanmalıdır.
13. Her görev tamamlandıktan sonra `PROJE_CALISMA_MANTIGI_RAPORU.md` içindeki ilgili başlık güncellenmelidir.
14. Yapı güncellemeleri tamamlandıktan sonra ayrıca `project_arcithecture.md` dosyası oluşturulmalıdır.
15. Daha sonra ek kontrol sistemleri uygulanırken hem oluşturulan `project_arcithecture.md` hem de güncellenen `PROJE_CALISMA_MANTIGI_RAPORU.md` dikkate alınmalıdır.

---

# 1. Güncellenmesi Gereken Yapılar

Bu bölümde her yapı ayrı bir görev olarak ele alınmıştır. Her görev için:

- Mevcut yapı
- Bulunduğu klasör / dosya
- Mevcut görev
- Zayıf taraf
- Profesyonel güncelleme hedefi
- Uygulama adımları
- Rapor güncelleme talimatı

ayrı ayrı verilmiştir.

---

## Görev 1: Klasör Açma Akışını Profesyonel Loading Mantığına Taşı

### Mevcut yapı

İlgili dosyalar:

```text
lib/features/files/presentation/widgets/dosya_folder.dart
lib/features/files/state/izinler.dart
lib/features/files/state/folderleragaci.dart
lib/features/files/presentation/pages/klasoricerigisayfasi.dart
lib/features/home/presentation/pages/anasayfa_icerigi.dart
```

Mevcut rapora göre klasör tıklama akışı şöyledir:

```text
Klasor.onTap
-> ensongezilenfolders.add(klasor)
-> Izinler.setCurrentFolder(klasor)
   -> fileTree.loadFolder(klasor)
   -> currentFolder = klasor
-> context.push('/klasoricerigisayfasi')
-> Klasoricerigisayfasi getCurrentFolder içeriğini render eder
```

### Mevcut sorun

Klasöre tıklanınca önce klasör içeriği yükleniyor, sonra sayfa açılıyor. Büyük klasörlerde bu durum kullanıcıya donma gibi görünür.

### Profesyonel hedef

Akış şu hale getirilmelidir:

```text
Kullanıcı klasöre tıklar
-> Sayfa hemen açılır
-> Sayfa içinde skeleton loading görünür
-> Klasör içeriği async yüklenir
-> İçerik parça parça ekrana basılır
```

### Yapılacaklar

1. `Klasor` widget'ındaki `onTap` içinde ağır `await setCurrentFolder(...)` çağrısı kullanıcı geçişini geciktirmeyecek şekilde düzenlenmelidir.
2. Klasöre tıklandığında önce hedef klasör bilgisi sayfaya aktarılmalıdır.
3. Route parametresi, query parametresi veya `extra` ile klasör path'i aktarılmalıdır.
4. `Klasoricerigisayfasi` açıldığında kendi `initState` veya provider tetiklemesi ile klasör içeriğini yüklemelidir.
5. Yükleme sırasında `shared` altındaki skeleton widget'ı gösterilmelidir.
6. Yükleme tamamlanınca liste görünmelidir.
7. Yükleme hatası olursa hata widget'ı gösterilmelidir.
8. Klasör yükleme sırasında normal klasörler için açıklayıcı uzun progress yazısı gösterilmemelidir.
9. Sadece skeleton animasyonu kullanılmalıdır.
10. Kategorik klasörler için progress yazıları ayrıca Görev 5 kapsamında ele alınmalıdır.

### Rapor güncelleme talimatı

Görev tamamlanınca `PROJE_CALISMA_MANTIGI_RAPORU.md` içinde şu bölümler güncellenmelidir:

```text
8. Klasör Container'ına Tıklanınca Gerçekleşen Tam Akış
7.2 Klasoricerigisayfasi
16.3 Bir klasöre tıklama
18. Sonuç
```

Eski anlatımda "önce provider yükler, sonra route push edilir" mantığı varsa kaldırılmalıdır. Yeni anlatımda "sayfa önce açılır, içerik sayfa içinde async yüklenir" mantığı yazılmalıdır.

---

## Görev 2: Klasör Kimliğini Sadece Provider Yerine Path Tabanlı Taşı

### Mevcut yapı

İlgili dosyalar:

```text
lib/app/router/app_router.dart
lib/features/files/state/izinler.dart
lib/features/files/presentation/widgets/dosya_folder.dart
lib/features/files/presentation/pages/klasoricerigisayfasi.dart
```

Mevcut rapora göre klasörün hangi klasör olduğu route üzerinden taşınmıyor. Aktif klasör bilgisi provider içinde tutuluyor.

### Mevcut sorun

Aynı statik route tekrar tekrar kullanılmaktadır:

```text
/klasoricerigisayfasi
```

Bu route tek başına hangi klasörün açık olduğunu anlatmaz. Bu durum debug, geri dönüş ve derin link mantığını zorlaştırır.

### Profesyonel hedef

Klasör sayfası kendi hedef path bilgisini bilmelidir.

Önerilen route mantığı:

```text
/klasoricerigisayfasi?path=/storage/emulated/0/Download
```

veya GoRouter `extra` ile:

```dart
context.push(Paths.klasoricerigisayfasi, extra: folder.path);
```

### Yapılacaklar

1. `app_router.dart` içinde klasör içerik sayfası path veya extra alacak şekilde düzenlenmelidir.
2. `Klasoricerigisayfasi` artık sadece `Izinler.getCurrentFolder` bağımlılığı ile çalışmamalıdır.
3. Sayfaya gelen path'e göre klasör içeriği yüklenmelidir.
4. `Izinler` provider aktif klasörü yine tutabilir, ama klasör sayfasının tek veri kaynağı olmamalıdır.
5. `currentFolder` daha çok UI state ve breadcrumb desteği için kullanılmalıdır.
6. Aynı route'a tekrar tekrar bilinçsiz push yapılması engellenmelidir.
7. Aynı path zaten açıksa gereksiz yeniden yükleme yapılmamalıdır.
8. Son gezilenler path tabanlı kaydedilmelidir.

### Rapor güncelleme talimatı

Görev tamamlanınca `PROJE_CALISMA_MANTIGI_RAPORU.md` içinde şu bölümler değiştirilmelidir:

```text
4. Router Yapısı
4.6 push, go ve goBranch
5. Sayfa Stack'leri Nasıl Kuruluyor?
5.3 Klasör geçmişi stack'i
7.2 Klasoricerigisayfasi
10. Path ve Klasör Gezinme Mantığı
15.1 Klasör route ile değil state ile taşınıyor
```

Yeni anlatımda klasör sayfalarının path bilgisi taşıdığı, provider'ın yardımcı state olarak çalıştığı açıklanmalıdır.

---

## Görev 3: `previousFolders` Geri Geçmişini Navigator / Path Mantığıyla Uyumlu Hale Getir

### Mevcut yapı

İlgili dosya:

```text
lib/features/files/state/izinler.dart
```

Mevcut raporda `previousFolders` ayrı bir klasör geçmişi stack'i olarak anlatılmıştır.

### Mevcut sorun

Projede iki farklı geri geçmişi vardır:

```text
1. GoRouter route stack
2. Izinler.previousFolders
```

Bu iki sistem ileride karışıklık oluşturabilir.

### Profesyonel hedef

Geri davranışı mümkün olduğunca route stack ve path tabanlı sayfa yapısı üzerinden yönetilmelidir.

### Yapılacaklar

1. `previousFolders` tamamen hemen kaldırılmamalıdır.
2. Önce path tabanlı route sistemi uygulanmalıdır.
3. Geri tuşu davranışı route stack'e göre test edilmelidir.
4. Klasör içi geri dönüşte `Navigator.pop()` yeterliyse `previousFolders` azaltılmalıdır.
5. Breadcrumb için `previousFolders` yerine path segmentleri kullanılmalıdır.
6. Özel durumlarda sadece son fallback olarak provider geçmişi kullanılmalıdır.
7. `goBack()` metodu yeniden tasarlanmalı veya kullanım yerleri azaltılmalıdır.
8. `PopScope` içindeki mantık temizlenmelidir.

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölümler güncellenmelidir:

```text
5.3 Klasör geçmişi stack'i
5.4 Geri tuşuna basınca ne olur?
10.2 Breadcrumb/path gösterimi
16.4 Geri tuşu
```

Eski "geri davranışının esas kaynağı previousFolders listesidir" anlatımı yeni path + navigator yaklaşımıyla değiştirilmelidir.

---

## Görev 4: Ortak Loading Sistemi ve Skeleton Widget'ları Oluştur

### Mevcut yapı

Mevcut raporda ortak skeleton veya shared loading yapısı tanımlı değildir.

İlgili eklenecek klasör:

```text
lib/shared/
```

Önerilen yapı:

```text
lib/shared/widgets/
  app_skeleton.dart
  folder_list_skeleton.dart
  file_item_skeleton.dart
  category_grid_skeleton.dart
  storage_card_skeleton.dart
  empty_state_widget.dart
  error_state_widget.dart
```

### Mevcut sorun

Loading durumları muhtemelen her sayfada ayrı ayrı veya yetersiz yönetiliyor. Kullanıcı klasör açarken donma hissi alıyor.

### Profesyonel hedef

Bütün loading gösterimleri ortak, tekrar kullanılabilir ve animasyonlu skeleton widget'ları ile yapılmalıdır.

### Yapılacaklar

1. `lib/shared/widgets/` klasörü oluşturulmalıdır.
2. Ortak `AppSkeleton` widget'ı yazılmalıdır.
3. Liste item'ları için `FileItemSkeleton` oluşturulmalıdır.
4. Klasör/dosya sayfaları için `FolderListSkeleton` oluşturulmalıdır.
5. Kategori gridleri için `CategoryGridSkeleton` oluşturulmalıdır.
6. Boş durumlar için `EmptyStateWidget` oluşturulmalıdır.
7. Hata durumları için `ErrorStateWidget` oluşturulmalıdır.
8. Bu widget'lar tüm dosya, klasör, arama, kategori, kaydedilen ve gizli dosya ekranlarında kullanılmalıdır.
9. Normal klasör yüklemelerinde "Dosyalar hazırlanıyor..." gibi metinler yerine skeleton gösterilmelidir.
10. Sadece kategori klasörlerinde açıklayıcı progress yazıları kullanılmalıdır.

### Rapor güncelleme talimatı

Görev tamamlanınca `PROJE_CALISMA_MANTIGI_RAPORU.md` en alta veya ilgili UI bölümlerine şu yeni başlık eklenmelidir:

```text
Ortak Loading ve Skeleton Sistemi
```

Ayrıca `7. Dosya ve Klasör Ekranlarının Rolleri` altında her sayfanın loading davranışı güncellenmelidir.

---

## Görev 5: Kategorik Dosya Sistemini Index + Hive Cache Mantığına Taşı

### Mevcut yapı

İlgili dosyalar:

```text
lib/features/files/state/folderleragaci.dart
lib/features/home/presentation/pages/anasayfa_icerigi.dart
lib/features/files/presentation/pages/katagorikicerik.dart
lib/features/files/presentation/pages/klasoricerigisayfasi.dart
```

Mevcut rapora göre kategorik klasörler sanaldır:

```text
isVirtual: true
path: virtual:<isim>
allowedExtensions: [...]
```

Kategori açılınca root dizini recursive taranır.

### Mevcut sorun

Her kategori açılışında root recursive tarama yapmak yavaştır. Bu yüzden kategori ekranları boş kalabilir veya geç yüklenebilir.

### Profesyonel hedef

Kategori ekranları doğrudan dosya sistemi taramasıyla değil, Hive üzerinde tutulan file index/cache üzerinden çalışmalıdır.

### Yeni data katmanı

Eklenecek yapı:

```text
lib/data/
  constants/
    hive_box_names.dart
    file_category_constants.dart

  models/
    indexed_file_model.dart
    folder_count_model.dart
    recent_item_model.dart
    favorite_item_model.dart
    hidden_item_model.dart

  services/
    hive_service.dart
    file_system_service.dart
    file_index_service.dart
    category_query_service.dart

  repositories/
    file_index_repository.dart
    category_repository.dart
    recent_repository.dart
    favorite_repository.dart
    hidden_repository.dart
```

### Yapılacaklar

1. `Hive` projeye eklenmelidir.
2. Uygulama başlangıcında Hive initialize edilmelidir.
3. `HiveService` ortak box açma, kapatma ve temizleme işlemlerini yönetmelidir.
4. `FileIndexService` cihazdaki dosyaları tarayıp index kaydı oluşturmalıdır.
5. `IndexedFileModel` içinde şu alanlar olmalıdır:

```text
path
name
extension
mimeType
size
modifiedAt
parentPath
isDirectory
category
indexedAt
```

6. Kategori sorguları `CategoryRepository` üzerinden yapılmalıdır.
7. Resim, video, ses, pdf, zip, word, excel, txt, powerpoint gibi kategoriler index üzerinden çekilmelidir.
8. Kategori ekranı açılırken eğer index hazır değilse kullanıcıya progress yazıları gösterilmelidir.
9. Progress yazıları sadece kategori açılışlarında kullanılmalıdır.
10. Örnek progress yazıları:

```text
PDF dosyaları hazırlanıyor...
Resim dosyaları taranıyor...
Video dosyaları listeleniyor...
```

11. Normal klasör açılışlarında bu yazılar kullanılmamalıdır.
12. Kategori sonucu 100'er item halinde sayfalanmalıdır.
13. Kategori index refresh işlemi gerektiğinde arka planda yapılmalıdır.

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölümler güncellenmelidir:

```text
6.7 FileTree
7.5 Katagorikicerik
7.7 Anasayfaicerigi
10.4 Sanal klasör path'leri
15.3 Dosya ağacı tam önceden yüklenmiyor
```

Yeni anlatımda kategori sisteminin `FileTree` recursive scan yerine `Hive` tabanlı index/cache üzerinden çalıştığı açıklanmalıdır.

---

## Görev 6: Arama Sistemini Debounce + Hive Index + Pagination Mantığına Taşı

### Mevcut yapı

İlgili dosyalar:

```text
lib/features/search/presentation/pages/arama.dart
lib/features/files/state/folderleragaci.dart
```

Mevcut rapora göre kullanıcı yazdıkça:

```text
context.read<Izinler>().fileTree.agactaarama(text)
```

çalışır ve root recursive taranır.

### Mevcut sorun

Her harfte recursive arama yapılırsa uygulama yavaşlar.

### Profesyonel hedef

Arama sistemi şu şekilde olmalıdır:

```text
TextField
-> debounce 400 ms
-> minimum 2 veya 3 karakter
-> Hive index içinde sorgu
-> 100'er sonuç
-> scroll ile devamını yükle
```

### Yapılacaklar

1. Yeni bir `SearchProvider` veya `SearchController` oluşturulmalıdır.
2. Arama UI doğrudan `FileTree.agactaarama` çağırmamalıdır.
3. TextField için debounce uygulanmalıdır.
4. Minimum karakter sınırı eklenmelidir.
5. Arama ilk olarak Hive index üzerinden yapılmalıdır.
6. Dosya adı, klasör adı, uzantı, kategori ve parentPath üzerinden filtre yapılabilmelidir.
7. Arama sonuçları 100'er item halinde gösterilmelidir.
8. Scroll sona yaklaştıkça sonraki 100 item yüklenmelidir.
9. Arama loading durumunda skeleton gösterilmelidir.
10. Hiç sonuç yoksa `EmptyStateWidget` gösterilmelidir.
11. Hata varsa `ErrorStateWidget` gösterilmelidir.
12. Derin canlı arama gerekiyorsa ayrı "Derin arama" aksiyonu olarak tasarlanmalıdır.

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölümler güncellenmelidir:

```text
6.7 FileTree - agactaarama
7.6 Arama
15.3 Dosya ağacı tam önceden yüklenmiyor
```

Yeni anlatımda aramanın artık `FileTree` içinde recursive tarama ile değil, `SearchProvider + Hive index` ile çalıştığı yazılmalıdır.

---

## Görev 7: Provider Rebuild Optimizasyonu İçin Selector Kullan

### Mevcut yapı

İlgili dosyalar:

```text
lib/features/files/presentation/pages/dosyalar.dart
lib/features/files/presentation/pages/klasoricerigisayfasi.dart
lib/features/files/presentation/pages/gizlidosyalar.dart
lib/features/files/presentation/pages/kaydedilendosyalar.dart
lib/features/files/presentation/pages/katagorikicerik.dart
lib/features/navigation/presentation/pages/anasayfa.dart
```

Mevcut raporda birçok yerde `context.watch<Izinler>()` ile provider izlenmektedir.

### Mevcut sorun

`context.watch<Izinler>()` geniş rebuild tetikleyebilir. Büyük listelerde bu performans kaybı oluşturur.

### Profesyonel hedef

Gerekli yerlerde `Selector` kullanılmalıdır.

Özellikle kullanılması istenen yapı:

```dart
Selector<Izinler, FolderNode?>(
  selector: (_, izinler) => izinler.currentFolder,
  builder: ...
)
```

### Yapılacaklar

1. `Izinler` içinde `currentFolder` public getter olarak düzenlenmelidir.
2. `getCurrentFolder` getter'ı varsa standart isimlendirme için korunabilir veya yeni getter ile uyumlu hale getirilebilir.
3. Klasör içerik sayfasında tüm provider'ı izlemek yerine sadece gerekli alan izlenmelidir.
4. Folder content, loading state, error state ayrı ayrı selector ile izlenmelidir.
5. Seçim modu için `Altislemprovider` ayrı izlenmelidir.
6. Dosya işlemleri için `Dosyaislemleri` sadece gerekli widget'larda izlenmelidir.
7. Büyük liste widget'larının gereksiz rebuild olması engellenmelidir.
8. Klasör ve dosya item widget'ları mümkün olduğunca `const`, `ValueKey` ve dar state ile çalışmalıdır.
9. Scroll sırasında liste yeniden komple build olmamalıdır.

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölümler güncellenmelidir:

```text
3. Uygulama Widget Kabuğu
6. Provider'ların Detaylı İşlevleri
7. Dosya ve Klasör Ekranlarının Rolleri
11. Anasayfa Shell Sayfasının Rolü
```

Yeni anlatımda `context.watch` yerine `Selector` ve dar rebuild mantığının kullanıldığı açıklanmalıdır.

---

## Görev 8: Hive Tabanlı Kalıcı Veri Katmanı Oluştur

### Mevcut yapı

İlgili dosyalar:

```text
lib/features/files/state/folderleragaci.dart
lib/features/files/state/dosyaislemleri.dart
lib/features/home/presentation/pages/anasayfa_icerigi.dart
lib/features/files/presentation/pages/gizlidosyalar.dart
lib/features/files/presentation/pages/kaydedilendosyalar.dart
```

Mevcut rapora göre şu listeler memory içinde tutuluyor:

```text
kaydedilenfolder
kaydedilenfile
gizlenenfolder
gizlenenfile
ensongezilenfolders
ensongezilenfiles
arananfolder
arananfile
```

### Mevcut sorun

Bu listeler kalıcı değildir veya dosya sistemi değişikliklerine dayanıklı değildir. Uygulama kapanınca veya dosya silinince bozulabilir.

### Profesyonel hedef

Veri saklama gerektiren tüm yapılarda Hive kullanılmalıdır.

### Hive ile saklanacak veri tipleri

```text
file index
folder count cache
directory content cache metadata
recent items
favorite/saved items
hidden items
thumbnail cache metadata
search history
category scan state
```

### Yapılacaklar

1. `lib/data/` klasörü oluşturulmalıdır.
2. `HiveService` oluşturulmalıdır.
3. Box isimleri `hive_box_names.dart` içinde merkezi tutulmalıdır.
4. Model sınıfları `lib/data/models/` altında olmalıdır.
5. Repository sınıfları `lib/data/repositories/` altında olmalıdır.
6. Ortak sorgular repository katmanında yazılmalıdır.
7. UI veya Provider doğrudan Hive box ile konuşmamalıdır.
8. `Dosyaislemleri.kaydet` artık `FavoriteRepository` üzerinden kalıcı kayıt yapmalıdır.
9. `Dosyaislemleri.sakla` artık `HiddenRepository` üzerinden kalıcı kayıt yapmalıdır.
10. Son gezilenler `RecentRepository` üzerinden saklanmalıdır.
11. Arama sonuçları index üzerinden alınmalıdır.
12. Kategori dosyaları index üzerinden alınmalıdır.
13. Hive kayıtları path bazlı olmalıdır.
14. Dosya silinmişse ilgili Hive kaydı temizlenmelidir.
15. Gereken yerlerde `ValueListenableBuilder` veya provider ile Hive değişiklikleri UI'a yansıtılmalıdır.

### Önerilen data klasör yapısı

```text
lib/data/
  constants/
    hive_box_names.dart
    file_extensions.dart
    file_categories.dart

  models/
    indexed_file_model.dart
    folder_count_model.dart
    recent_item_model.dart
    saved_item_model.dart
    hidden_item_model.dart
    directory_cache_model.dart
    thumbnail_cache_model.dart
    search_history_model.dart

  services/
    hive_service.dart
    file_system_service.dart
    file_index_service.dart
    thumbnail_cache_service.dart
    background_scan_service.dart

  repositories/
    file_index_repository.dart
    folder_count_repository.dart
    recent_repository.dart
    saved_repository.dart
    hidden_repository.dart
    directory_cache_repository.dart
    search_repository.dart
    category_repository.dart
```

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölümler güncellenmelidir:

```text
6.7 FileTree
6.8 Dosyaislemleri
13. Gizli Dosyalar ve Kaydedilen Dosyalar Mantığı
14. Son Gezilenler Mantığı
```

Yeni anlatımda memory listeleri yerine Hive repository mantığı açıklanmalıdır.

---

## Görev 9: Tüm Sayfalarda 100'er Item Yükleyen Incremental Loading Sistemi Kur

### Mevcut yapı

İlgili dosyalar:

```text
lib/features/files/presentation/pages/dosyalar.dart
lib/features/files/presentation/pages/klasoricerigisayfasi.dart
lib/features/files/presentation/pages/gizlidosyalar.dart
lib/features/files/presentation/pages/kaydedilendosyalar.dart
lib/features/files/presentation/pages/katagorikicerik.dart
lib/features/search/presentation/pages/arama.dart
lib/features/home/presentation/pages/anasayfa_icerigi.dart
```

### Mevcut sorun

Liste verileri muhtemelen bir kerede UI'a veriliyor. Büyük klasörlerde bu yavaşlık yapabilir.

### Profesyonel hedef

Sadece büyük klasörlerde değil, tüm listeleme sayfalarında 100'er item çekme mantığı uygulanmalıdır.

### Yapılacaklar

1. Ortak bir pagination modeli oluşturulmalıdır.
2. Her listeleme sayfası ilk açıldığında en fazla 100 item göstermelidir.
3. Eğer klasörde 100'den az item varsa sadece mevcut item sayısı gösterilmelidir.
4. Scroll sona yaklaştığında sonraki 100 item yüklenmelidir.
5. Bu sistem klasör, kategori, arama, gizli dosyalar, kaydedilen dosyalar ve son gezilenler için uygulanmalıdır.
6. Pagination provider veya controller üzerinden yönetilmelidir.
7. Sayfa yenilenince pagination sıfırlanmalı ve ilk 100 tekrar yüklenmelidir.
8. Yeni yükleme sırasında liste altına küçük loading gösterilmelidir.
9. İlk yükleme sırasında skeleton gösterilmelidir.
10. Veri yoksa empty state gösterilmelidir.

### Önerilen ortak yapı

```text
lib/shared/pagination/
  paginated_state.dart
  paginated_controller.dart
  paginated_file_list.dart
```

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölümler güncellenmelidir:

```text
7. Dosya ve Klasör Ekranlarının Rolleri
7.6 Arama
7.7 Anasayfaicerigi
13. Gizli Dosyalar ve Kaydedilen Dosyalar Mantığı
14. Son Gezilenler Mantığı
```

Yeni anlatımda tüm listelerin 100'er item ile incremental yüklendiği açıklanmalıdır.

---

## Görev 10: Klasör Sayfalarına RefreshIndicator ile Aşağı Kaydırarak Yenileme Ekle

### Mevcut yapı

İlgili dosyalar:

```text
lib/features/files/presentation/pages/dosyalar.dart
lib/features/files/presentation/pages/klasoricerigisayfasi.dart
lib/features/files/presentation/pages/gizlidosyalar.dart
lib/features/files/presentation/pages/kaydedilendosyalar.dart
lib/features/files/presentation/pages/katagorikicerik.dart
```

### Mevcut sorun

Kullanıcı klasör içeriğini elle yenileyemiyor veya refresh mantığı standart değil.

### Profesyonel hedef

Klasör ve listeleme sayfalarında aşağı kaydırma ile içerik yenilenmelidir.

### Yapılacaklar

1. Dosya ve klasör liste sayfaları `RefreshIndicator` ile sarılmalıdır.
2. `onRefresh` içinde ilgili path veya kategori yeniden yüklenmelidir.
3. Refresh sırasında cache tamamen yok sayılmamalı, önce cache gösterilmeye devam edilmelidir.
4. Arka planda gerçek dosya sistemi kontrol edilmelidir.
5. Silinmiş dosyalar listeden çıkarılmalıdır.
6. Yeni dosyalar listeye eklenmelidir.
7. Kategori sayfalarında refresh index güncellemesi tetiklemelidir.
8. Arama sayfasında refresh mevcut query'i yeniden çalıştırmalıdır.
9. Refresh sonrasında pagination ilk 100 item'dan başlayacak şekilde sıfırlanmalıdır.

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölümler güncellenmelidir:

```text
7. Dosya ve Klasör Ekranlarının Rolleri
7.2 Klasoricerigisayfasi
7.5 Katagorikicerik
7.6 Arama
```

Yeni anlatımda her sayfanın `RefreshIndicator` desteği açıklanmalıdır.

---

## Görev 11: Klasör Item Count Sistemini Cache + Arka Plan Sayım Mantığına Taşı

### Mevcut yapı

İlgili dosyalar:

```text
lib/features/files/state/folderleragaci.dart
lib/features/files/presentation/widgets/dosya_folder.dart
```

Mevcut problem: Klasör item sayısı başta 0 görünür, klasöre girilip çıkınca doğru hale gelir.

### Mevcut sorun

0 gösterimi kullanıcıya klasör boşmuş gibi yanlış bilgi verir.

### Profesyonel hedef

Klasör item sayısı ayrı metadata olarak tutulmalıdır.

### Yapılacaklar

1. `FolderCountModel` oluşturulmalıdır.
2. Hive içinde `folder_count_box` kullanılmalıdır.
3. Her klasör için şu alanlar saklanmalıdır:

```text
path
folderCount
fileCount
totalCount
isLoaded
updatedAt
```

4. UI'da bilinmeyen sayı için `0` gösterilmemelidir.
5. Bilinmeyen sayı için şu tür gösterim yapılmalıdır:

```text
—
```

veya:

```text
hesaplanıyor
```

6. Klasör listesi açıldığında görünen klasörlerin item count bilgileri arka planda hesaplanmalıdır.
7. Hesaplanan sayılar Hive'a kaydedilmelidir.
8. Sonraki açılışta cache'ten hızlı gösterilmelidir.
9. Refresh yapıldığında ilgili klasör count bilgisi güncellenmelidir.
10. Sayım işlemi UI'ı kilitlememelidir.

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölümler güncellenmelidir:

```text
6.6 FolderNode
6.7 FileTree
8. Klasör Container'ına Tıklanınca Gerçekleşen Tam Akış
```

Yeni anlatımda item count bilgisinin çocuk listelerden değil Hive tabanlı `FolderCountModel` üzerinden geldiği açıklanmalıdır.

---

## Görev 12: Directory Content Cache Sistemi Kur

### Mevcut yapı

İlgili dosyalar:

```text
lib/features/files/state/folderleragaci.dart
lib/features/files/state/izinler.dart
```

Mevcut sistem klasör açılınca doğrudan dosya sistemini okur.

### Mevcut sorun

Kullanıcı aynı klasöre tekrar dönünce bile gereksiz okuma yapılabilir. Geri dönüşlerde donma oluşabilir.

### Profesyonel hedef

Klasör içerikleri cache mantığıyla yönetilmelidir.

### Yapılacaklar

1. `DirectoryCacheModel` oluşturulmalıdır.
2. Hive içinde `directory_cache_box` kullanılmalıdır.
3. Klasör path'i cache key olmalıdır.
4. Cache içinde klasörün item path listeleri ve metadata bilgileri tutulmalıdır.
5. Klasör açılınca önce cache gösterilmelidir.
6. Ardından arka planda gerçek dosya sistemi ile refresh yapılmalıdır.
7. Cache süresi veya invalidation kontrolü eklenmelidir.
8. Klasör modified date değişmişse cache yenilenmelidir.
9. Dosya yoksa cache kaydı temizlenmelidir.
10. RefreshIndicator ile manuel yenileme cache update tetiklemelidir.

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölümler güncellenmelidir:

```text
6.7 FileTree
7.1 Dosyalar
7.2 Klasoricerigisayfasi
10. Path ve Klasör Gezinme Mantığı
```

Yeni anlatımda klasör içeriklerinin önce cache'ten gösterildiği, sonra refresh edildiği açıklanmalıdır.

---

## Görev 13: Thumbnail Cache Sistemini Ayrı Servis Haline Getir

### Mevcut yapı

İlgili dosya:

```text
lib/features/files/presentation/widgets/dosya_folder.dart
```

Mevcut rapora göre dosya widget'larında görsel önizleme ve video thumbnail cache kullanımı vardır.

### Mevcut sorun

Thumbnail üretimi liste build akışını yavaşlatabilir. Özellikle video thumbnail üretimi pahalıdır.

### Profesyonel hedef

Thumbnail üretimi UI build sürecinden ayrılmalı ve cache servis üzerinden yönetilmelidir.

### Yapılacaklar

1. `ThumbnailCacheService` oluşturulmalıdır.
2. Thumbnail metadata Hive içinde saklanmalıdır.
3. Gerçek thumbnail dosyaları uygulama cache dizininde tutulmalıdır.
4. `Dosya` widget önce thumbnail cache kontrolü yapmalıdır.
5. Thumbnail yoksa geçici dosya ikonu göstermelidir.
6. Thumbnail üretimi arka planda yapılmalıdır.
7. Thumbnail oluşunca ilgili item yeniden güncellenmelidir.
8. Aynı dosya için tekrar tekrar thumbnail üretilmemelidir.
9. Video thumbnail üretimi limitli ve kontrollü olmalıdır.
10. Liste hızlı kaydırılırken gereksiz thumbnail üretimi iptal edilebilir veya ertelenebilir.

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölüm güncellenmelidir:

```text
9. Dosya Container'ına Tıklanınca Ne Oluyor?
```

Yeni anlatımda thumbnail üretiminin widget içinde ağır işlem olarak değil, cache servis üzerinden çalıştığı açıklanmalıdır.

---

## Görev 14: Dosya İşlemlerini Güvenli Operasyon Mantığına Taşı

### Mevcut yapı

İlgili dosya:

```text
lib/features/files/state/dosyaislemleri.dart
```

Mevcut raporda `Dosyaislemleri` kopyala, kes, yapıştır, sil, adlandır, kaydet, sakla gibi işlemleri yönetir.

### Mevcut sorun

Dosya operasyonlarında veri kaybı, aynı isim çakışması, boş alan kontrolü ve progress eksik olabilir.

### Profesyonel hedef

Dosya işlemleri güvenli ve kontrollü hale getirilmelidir.

### Yapılacaklar

1. `FileOperationService` oluşturulmalıdır.
2. Kopyalama başlamadan önce hedefte aynı isim var mı kontrol edilmelidir.
3. Aynı isim varsa kullanıcıya seçenek sunulmalıdır:

```text
Üzerine yaz
Yeni isimle kopyala
Atla
İptal et
```

4. Kes işlemi önce hedefe kopyalamalı, doğrulama sonrası orijinali silmelidir.
5. Yeterli boş alan kontrolü yapılmalıdır.
6. Silme işleminde dosya gerçekten var mı kontrol edilmelidir.
7. Rename işleminde hedef isim geçerli mi kontrol edilmelidir.
8. Operasyon progress state'i tutulmalıdır.
9. Büyük işlemler için progress dialog veya bottom sheet kullanılmalıdır.
10. Operasyon bittikten sonra ilgili cache, index ve UI listeleri güncellenmelidir.

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölüm güncellenmelidir:

```text
6.8 Dosyaislemleri
```

Yeni anlatımda `Dosyaislemleri` doğrudan tüm fiziksel işi yapan sınıf değil, operasyon servislerini çağıran state katmanı olarak açıklanmalıdır.

---

## Görev 15: Temizlik Sayfasını Cache, Progress ve Güvenli Silme Mantığıyla Güncelle

### Mevcut yapı

İlgili dosya:

```text
lib/features/files/presentation/pages/temizliksayfasi.dart
lib/features/files/state/dosyaislemleri.dart
```

Mevcut rapora göre temizlik sayfası açılınca temp/cache alanlarını recursive tarar.

### Mevcut sorun

Temizlik taraması ağır olabilir ve UI'ı kilitleyebilir.

### Profesyonel hedef

Temizlik sistemi progress state ve güvenli silme mantığıyla çalışmalıdır.

### Yapılacaklar

1. `CleaningService` oluşturulmalıdır.
2. Temp/cache taraması parça parça yapılmalıdır.
3. Tarama sırasında progress gösterilmelidir.
4. Gereksiz dosya kriterleri merkezi sabitlerden yönetilmelidir.
5. Kullanıcı onayı olmadan silme yapılmamalıdır.
6. Silme işlemi progress ile yapılmalıdır.
7. Silinen dosyalar file index ve cache'ten temizlenmelidir.
8. Hata alınan dosyalar ayrı listelenmelidir.
9. Temizlik sonucu raporu gösterilmelidir.

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölüm güncellenmelidir:

```text
12. Temizlik Sayfası Mantığı
```

---

## Görev 16: Kaydedilen, Gizlenen ve Son Gezilen Dosyaları Hive Repository Mantığına Taşı

### Mevcut yapı

İlgili dosyalar:

```text
lib/features/files/state/folderleragaci.dart
lib/features/files/state/dosyaislemleri.dart
lib/features/files/presentation/pages/gizlidosyalar.dart
lib/features/files/presentation/pages/kaydedilendosyalar.dart
lib/features/home/presentation/pages/anasayfa_icerigi.dart
```

### Mevcut sorun

Kaydedilen, gizlenen ve son gezilen item'lar memory listelerinde tutuluyor.

### Profesyonel hedef

Bu yapılar Hive üzerinden kalıcı olarak yönetilmelidir.

### Yapılacaklar

1. `RecentRepository` oluşturulmalıdır.
2. `SavedRepository` oluşturulmalıdır.
3. `HiddenRepository` oluşturulmalıdır.
4. Kayıtlar path bazlı tutulmalıdır.
5. Aynı item tekrar tekrar eklenmemelidir.
6. Son gezilenler maksimum limit ile tutulmalıdır.
7. Dosya silinmişse ilgili kayıt otomatik temizlenmelidir.
8. Gizli dosyalar sadece UI listesinden kaldırılmamalı, hidden repository içinde işaretlenmelidir.
9. Kaydedilen dosyalar uygulama yeniden açıldığında da görünmelidir.
10. Bu sayfalarda pagination 100'er item ile uygulanmalıdır.

### Rapor güncelleme talimatı

Görev tamamlanınca şu bölümler güncellenmelidir:

```text
13. Gizli Dosyalar ve Kaydedilen Dosyalar Mantığı
14. Son Gezilenler Mantığı
```

---

# 2. Yapı Güncellemeleri Bittikten Sonra `project_arcithecture.md` Oluşturma Görevi

## Görev 17: `project_arcithecture.md` Dosyasını Oluştur

Tüm yapı güncelleme görevleri bittikten sonra proje kök dizininde şu dosya oluşturulmalıdır:

```text
project_arcithecture.md
```

Bu dosya projenin güncel klasör yapısını ve her klasörün görevini detaylı şekilde anlatmalıdır.

### Dosyada bulunması gereken ana başlıklar

```text
# Project Architecture

## 1. Genel Mimari Yaklaşım
## 2. Klasör Yapısı
## 3. app/ Katmanı
## 4. core/ Katmanı
## 5. data/ Katmanı
## 6. shared/ Katmanı
## 7. features/ Katmanı
## 8. Dosya Sistemi ve Index Mantığı
## 9. Hive Veri Saklama Mantığı
## 10. Loading ve Skeleton Mantığı
## 11. Pagination Mantığı
## 12. Refresh Mantığı
## 13. Arama Mantığı
## 14. Kategori Mantığı
## 15. Dosya Operasyonları Mantığı
## 16. Rapor Güncelleme Kuralları
```

### Detaylandırılması gereken klasörler

```text
lib/app/
lib/core/
lib/data/
lib/data/constants/
lib/data/models/
lib/data/services/
lib/data/repositories/
lib/shared/
lib/shared/widgets/
lib/shared/pagination/
lib/features/files/
lib/features/files/state/
lib/features/files/presentation/
lib/features/search/
lib/features/home/
lib/features/menu/
lib/features/navigation/
```

### Her klasör için yazılacak bilgiler

Her klasör için şu format kullanılmalıdır:

```text
## Klasör Adı

Konum:
...

Görevi:
...

İçerdiği dosya türleri:
...

Başka hangi katmanlarla iletişim kurar:
...

Dikkat edilmesi gereken kurallar:
...
```

### Rapor güncelleme talimatı

`project_arcithecture.md` oluşturulduktan sonra `PROJE_CALISMA_MANTIGI_RAPORU.md` dosyasının sonuna şu bilgi eklenmelidir:

```text
Bu proje için güncel klasör yapısı ve katman görevleri ayrıca project_arcithecture.md dosyasında tutulmaktadır.
```

---

# 3. Eklenmesi Gereken Kontrol ve Sistem Eklentileri

Bu bölümdeki her görev başlamadan önce ajan şu iki dosyayı okumalıdır:

```text
project_arcithecture.md
PROJE_CALISMA_MANTIGI_RAPORU.md
```

Ajan her görevde önce mevcut mimariye uygun entegrasyon noktalarını belirlemeli, sonra kod değişikliği yapmalıdır.

---

## Görev 18: Dosya / Klasör Erişim Kontrol Sistemi Ekle

### Amaç

Bazı klasör veya dosyalara erişim reddedilebilir. Uygulama bu durumlarda çökmeden kullanıcıya anlaşılır bilgi vermelidir.

### Yapılacaklar

1. `FileAccessResult` modeli oluşturulmalıdır.
2. Her klasör okuma öncesi erişim kontrolü yapılmalıdır.
3. Kontrol edilecek durumlar:

```text
path var mı?
dosya mı klasör mü?
okunabilir mi?
yazılabilir mi?
erişim reddedildi mi?
symbolic link mi?
bozuk path mi?
dosya silinmiş mi?
```

4. Erişim yoksa liste boş gösterilmemelidir.
5. `ErrorStateWidget` ile kullanıcıya net mesaj gösterilmelidir.
6. Erişim hataları loglanmalıdır.
7. Hive cache içinde artık var olmayan path kayıtları temizlenmelidir.

### Rapor ekleme talimatı

`PROJE_CALISMA_MANTIGI_RAPORU.md` sonuna şu başlık eklenmelidir:

```text
Ek Kontrol: Dosya ve Klasör Erişim Kontrol Sistemi
```

---

## Görev 19: Dosya Varlık Senkronizasyon Sistemi Ekle

### Amaç

Hive içinde kayıtlı olan dosya veya klasör artık gerçek dosya sisteminde bulunmayabilir. Bu durum kontrol edilmelidir.

### Yapılacaklar

1. `FileSyncService` oluşturulmalıdır.
2. Hive kayıtları belirli aralıklarla veya refresh sırasında kontrol edilmelidir.
3. Silinmiş dosya kayıtları temizlenmelidir.
4. Taşınmış dosyalar path eşleşmesi bozulduğu için invalid olarak işaretlenmelidir.
5. Index ve kategori cache senkronize edilmelidir.
6. Hidden, saved, recent listeleri temizlenmelidir.
7. Kullanıcıya gerekiyorsa "Bazı dosyalar artık bulunamadı" bilgisi verilebilir.

### Rapor ekleme talimatı

`PROJE_CALISMA_MANTIGI_RAPORU.md` sonuna şu başlık eklenmelidir:

```text
Ek Kontrol: Dosya Varlık Senkronizasyon Sistemi
```

---

## Görev 20: Dosya Operasyonu Öncesi Güvenlik Kontrolleri Ekle

### Amaç

Silme, taşıma, kopyalama ve adlandırma işlemleri veri kaybı oluşturmayacak şekilde kontrol edilmelidir.

### Yapılacaklar

1. Operasyon öncesi path doğrulaması yapılmalıdır.
2. Hedef klasör var mı kontrol edilmelidir.
3. Hedefte aynı isimli dosya var mı kontrol edilmelidir.
4. Yeterli boş alan var mı kontrol edilmelidir.
5. İşlem sırasında hata alınırsa rollback mantığı uygulanmalıdır.
6. Kes işleminde hedefe kopyalama tamamlanmadan kaynak silinmemelidir.
7. Kullanıcı onayı gereken durumlarda dialog gösterilmelidir.
8. İşlem sonrası cache ve Hive index güncellenmelidir.

### Rapor ekleme talimatı

`PROJE_CALISMA_MANTIGI_RAPORU.md` sonuna şu başlık eklenmelidir:

```text
Ek Kontrol: Güvenli Dosya Operasyonları
```

---

## Görev 21: Kategori Index Durum Kontrolü Ekle

### Amaç

Kategori ekranları boş görünmemelidir. Index yoksa veya eskiyse kullanıcıya doğru durum gösterilmelidir.

### Yapılacaklar

1. `CategoryScanState` modeli oluşturulmalıdır.
2. Her kategori için scan durumu tutulmalıdır:

```text
notStarted
scanning
ready
failed
outdated
```

3. Kategori açılınca index yoksa scan başlatılmalıdır.
4. Scan sırasında progress yazısı gösterilmelidir.
5. Scan bitince sonuçlar 100'er item ile gösterilmelidir.
6. Scan başarısızsa hata widget'ı gösterilmelidir.
7. RefreshIndicator ile kategori yeniden taranabilmelidir.

### Progress yazıları

Bu görevde progress yazıları kullanılabilir. Örnek:

```text
PDF dosyaları hazırlanıyor...
Resim dosyaları taranıyor...
Video dosyaları listeleniyor...
```

Bu yazılar sadece kategorik klasörler için kullanılmalıdır.

### Rapor ekleme talimatı

`PROJE_CALISMA_MANTIGI_RAPORU.md` sonuna şu başlık eklenmelidir:

```text
Ek Kontrol: Kategori Index Durum Sistemi
```

---

## Görev 22: Arama Durum Kontrol Sistemi Ekle

### Amaç

Arama sırasında kullanıcıya doğru feedback verilmelidir.

### Yapılacaklar

1. Query boşsa arama yapılmamalıdır.
2. Minimum karakter şartı eklenmelidir.
3. Debounce uygulanmalıdır.
4. Index hazır değilse kullanıcıya uygun state gösterilmelidir.
5. Sonuç yoksa empty state gösterilmelidir.
6. Hata olursa error state gösterilmelidir.
7. Arama iptal edilebilir olmalıdır.
8. Yeni query girildiğinde eski query sonucu UI'a karışmamalıdır.
9. Sonuçlar 100'er item ile gelmelidir.

### Rapor ekleme talimatı

`PROJE_CALISMA_MANTIGI_RAPORU.md` sonuna şu başlık eklenmelidir:

```text
Ek Kontrol: Arama Durum Kontrol Sistemi
```

---

## Görev 23: Cache Geçerlilik Kontrol Sistemi Ekle

### Amaç

Cache hızlıdır ama her zaman doğru olmayabilir. Bu yüzden geçerlilik kontrolü olmalıdır.

### Yapılacaklar

1. Cache kayıtlarına `updatedAt` eklenmelidir.
2. Directory cache için klasör modified date kontrol edilmelidir.
3. File index için dosya modified date kontrol edilmelidir.
4. Thumbnail cache için dosya modified date değişmişse thumbnail yenilenmelidir.
5. Folder count cache için refresh durumunda tekrar hesaplanmalıdır.
6. Cache çok eskiyse arka planda yenilenmelidir.
7. Kullanıcı manuel refresh yaparsa cache güncellenmelidir.

### Rapor ekleme talimatı

`PROJE_CALISMA_MANTIGI_RAPORU.md` sonuna şu başlık eklenmelidir:

```text
Ek Kontrol: Cache Geçerlilik Kontrol Sistemi
```

---

## Görev 24: İzin Durumu ve Ayarlar Yönlendirme Kontrolü Ekle

### Amaç

Dosya yöneticisi için depolama izni kritik önemdedir. İzin verilmediyse kullanıcı doğru yönlendirilmelidir.

### Yapılacaklar

1. `Izinler` provider içindeki izin mantığı sadeleştirilmelidir.
2. İzin durumu Hive veya SharedPreferences ile gereksiz çelişmeyecek şekilde yönetilmelidir.
3. Gerçek sistem izni her zaman ana kaynak olmalıdır.
4. İzin yoksa dosya listesi yerine izin ekranı gösterilmelidir.
5. Kalıcı ret varsa ayarlara yönlendirme yapılmalıdır.
6. İzin verildikten sonra root ve index başlangıç işlemleri tetiklenmelidir.
7. İzin kaybı durumunda UI kendini güncellemelidir.

### Rapor ekleme talimatı

`PROJE_CALISMA_MANTIGI_RAPORU.md` sonuna şu başlık eklenmelidir:

```text
Ek Kontrol: İzin Durumu ve Ayarlar Yönlendirme Sistemi
```

---

## Görev 25: Loglama ve Debug İzleme Sistemi Ekle

### Amaç

Dosya yöneticisi gibi karmaşık yapılarda hata kaynağını bulmak için merkezi log sistemi gerekir.

### Yapılacaklar

1. `AppLogger` oluşturulmalıdır.
2. Debug modda detaylı log yazılmalıdır.
3. Release modda hassas path bilgileri gereksiz yazılmamalıdır.
4. Log kategorileri oluşturulmalıdır:

```text
permission
folder_loading
category_scan
search
file_operation
hive
thumbnail
refresh
pagination
```

5. `debugPrint` doğrudan her yerde kullanılmamalı, logger üzerinden çağrılmalıdır.
6. Kritik hatalar kullanıcıya uygun mesaj olarak dönmelidir.

### Rapor ekleme talimatı

`PROJE_CALISMA_MANTIGI_RAPORU.md` sonuna şu başlık eklenmelidir:

```text
Ek Kontrol: Loglama ve Debug İzleme Sistemi
```

---

# 4. Yeni Eklemelerle `PROJE_CALISMA_MANTIGI_RAPORU.md` Sonuna Eklenecek Bölüm

Tüm görevler tamamlandıktan sonra `PROJE_CALISMA_MANTIGI_RAPORU.md` dosyasının en altına aşağıdaki ana başlıklar eklenmelidir. Bu başlıkların içeriği gerçek uygulanan kodlara göre detaylandırılmalıdır.

---

## Eklenen Profesyonel Sistemler

Bu bölümde proje üzerinde yapılan profesyonel mimari geliştirmeler açıklanacaktır.

### 1. Path Tabanlı Klasör Gezinme Sistemi

Klasör sayfalarının artık sadece provider state'ine bağlı olmadığı, sayfanın hedef path bilgisini aldığı ve klasör içeriğini kendi lifecycle akışı içinde yüklediği açıklanmalıdır.

### 2. Ortak Skeleton Loading Sistemi

`lib/shared/widgets/` altında tanımlanan skeleton widget'larının hangi sayfalarda kullanıldığı açıklanmalıdır.

### 3. RefreshIndicator ile Manuel Yenileme Sistemi

Klasör, kategori, arama, gizli dosyalar ve kaydedilen dosyalar ekranlarında aşağı kaydırarak yenileme davranışı anlatılmalıdır.

### 4. Hive Tabanlı Data Katmanı

`lib/data/` katmanının neden eklendiği, hangi modellerin ve repository'lerin bulunduğu açıklanmalıdır.

### 5. File Index ve Category Cache Sistemi

Kategori ekranlarının artık doğrudan recursive tarama yerine Hive index üzerinden çalıştığı yazılmalıdır.

### 6. Debounce ve Index Tabanlı Arama Sistemi

Aramanın artık her harfte recursive tarama yapmadığı, debounce ve index mantığıyla çalıştığı açıklanmalıdır.

### 7. 100'er Item Pagination Sistemi

Tüm listeleme ekranlarında ilk 100 item ve scroll ile sonraki 100 item mantığı açıklanmalıdır.

### 8. Folder Count Cache Sistemi

Klasör item sayılarının artık yanlış şekilde 0 gösterilmediği, bilinmeyen durumda skeleton veya belirsiz gösterim kullanıldığı açıklanmalıdır.

### 9. Directory Cache Sistemi

Klasör içeriklerinin önce cache'ten hızlı gösterildiği, sonra arka planda refresh edildiği açıklanmalıdır.

### 10. Thumbnail Cache Sistemi

Resim ve video önizlemelerinin widget içinde ağır işlem olarak değil, cache servis üzerinden yönetildiği açıklanmalıdır.

### 11. Güvenli Dosya Operasyonları

Kopyala, kes, yapıştır, sil, yeniden adlandır gibi işlemlerde isim çakışması, boş alan, rollback ve progress kontrollerinin nasıl yapıldığı açıklanmalıdır.

### 12. Erişim, Senkronizasyon ve Cache Geçerlilik Kontrolleri

Dosya varlığı, erişim izni, cache güncelliği, silinmiş dosya temizliği ve index senkronizasyonu açıklanmalıdır.

### 13. Selector ile Rebuild Optimizasyonu

`Selector<Izinler, FolderNode?>` ve benzeri dar rebuild yaklaşımının nerelerde kullanıldığı açıklanmalıdır.

---

# 5. Son Beklenen Mimari Sonuç

Tüm görevler tamamlandığında projenin genel mantığı şu hale gelmelidir:

```text
UI
↓
Provider / Controller
↓
Repository
↓
Service
↓
Hive Cache / Android File System
```

Klasör açma:

```text
Kullanıcı klasöre tıklar
↓
Sayfa hemen açılır
↓
Skeleton gösterilir
↓
Önce cache okunur
↓
Gerçek dosya sistemi arka planda kontrol edilir
↓
Liste 100'er item halinde gösterilir
```

Kategori açma:

```text
Kullanıcı kategoriye tıklar
↓
Kategori sayfası açılır
↓
Index hazırsa Hive'dan 100'er item gelir
↓
Index hazır değilse progress yazısı gösterilir
↓
Background scan tamamlanınca liste güncellenir
```

Arama:

```text
Kullanıcı yazar
↓
Debounce beklenir
↓
Hive index içinde arama yapılır
↓
Sonuçlar 100'er item ile gösterilir
```

Geri dönüş:

```text
Navigator path stack üzerinden döner
↓
Provider sadece UI state desteği verir
↓
previousFolders ana geri mekanizması olmaktan çıkar
```

Veri saklama:

```text
Son gezilenler
Kaydedilenler
Gizlenenler
Kategori index
Folder count
Thumbnail metadata
Directory cache
Arama geçmişi
↓
Hive repository katmanında tutulur
```

Bu güncellemelerden sonra uygulama daha hızlı, daha sürdürülebilir, daha profesyonel ve gerçek dosya yöneticisi davranışına daha yakın hale gelmelidir.
