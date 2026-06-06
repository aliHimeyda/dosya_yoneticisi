# Project Architecture

## 1. Genel Mimari YaklaÅŸÄ±m

Bu proje Flutter + Provider + GoRouter tabanlÄ± bir dosya yÃ¶neticisidir.
Uygulama giriÅŸ noktasÄ± `lib/main.dart` iÃ§inden `bootstrap()` Ã§aÄŸrÄ±sÄ± ile baÅŸlar.
`bootstrap()` iÃ§inde Hive, repository, service ve provider katmanlarÄ± ayaÄŸa
kaldÄ±rÄ±lÄ±r; ardÄ±ndan `MaterialApp.router` kullanan uygulama shell'i Ã§alÄ±ÅŸtÄ±rÄ±lÄ±r.

Genel akÄ±ÅŸ:

```text
main.dart
-> app/bootstrap.dart
-> Hive / repository / service init
-> MultiProvider kurulumu
-> app/app.dart
-> app/router/app_router.dart
-> feature sayfalarÄ±
```

Katmanlar arasÄ± temel ilke:

- `features/` kullanÄ±cÄ± akÄ±ÅŸÄ±, state orchestration ve ekranlarÄ± taÅŸÄ±r
- `data/` kalÄ±cÄ± veri, cache, index ve dosya sistemi servislerini taÅŸÄ±r
- `shared/` tekrar kullanÄ±labilir UI ve pagination altyapÄ±sÄ±nÄ± taÅŸÄ±r
- `core/` tema, lokalizasyon ve global sabitleri taÅŸÄ±r
- `app/` uygulama bootstrap ve routing kompozisyonunu taÅŸÄ±r

Kurallar:

- UI dosya sistemi iÅŸini doÄŸrudan yapmamalÄ±dÄ±r
- Hive eriÅŸimi `data/repositories/` altÄ±nda toplanmalÄ±dÄ±r
- AÄŸÄ±r dosya sistemi ve cache iÅŸleri service/repository katmanÄ±nda tutulmalÄ±dÄ±r
- Feature state sÄ±nÄ±flarÄ± servisleri orkestre etmeli, veriyi kendisi Ã¼retmemelidir

## 2. KlasÃ¶r YapÄ±sÄ±

Mevcut Ã¼st seviye `lib/` yapÄ±sÄ±:

```text
lib/
  main.dart
  app/
  core/
  data/
  features/
  l10n/
  legacy/
  shared/
```

Katman Ã¶zeti:

- `app/`: bootstrap, app shell, router
- `core/`: tema, localization, global constant
- `data/`: model, repository, service, cache, index
- `features/`: ekranlar ve feature state
- `shared/`: ortak widget ve pagination
- `l10n/`: ARB dosyalarÄ± ve generated localization Ã§Ä±ktÄ±larÄ±
- `legacy/`: eski yapÄ±dan kalmÄ±ÅŸ geÃ§iÅŸ dosyalarÄ±; yeni geliÅŸtirme burada yapÄ±lmamalÄ±dÄ±r

## 3. app/ KatmanÄ±

### lib/app/

Konum:
`lib/app/`

GÃ¶revi:
UygulamanÄ±n ayaÄŸa kaldÄ±rÄ±ldÄ±ÄŸÄ±, dependency graph'in kurulduÄŸu ve ana shell'in
oluÅŸturulduÄŸu katmandÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`app.dart`, `bootstrap.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`core/`, `data/`, `features/`

Dikkat edilmesi gereken kurallar:
- Yeni provider veya service kayÄ±tlarÄ± Ã¶nce `bootstrap.dart` iÃ§inde baÄŸlanmalÄ±dÄ±r
- `app.dart` iÃ§inde iÅŸ kuralÄ± yazÄ±lmamalÄ±; yalnÄ±zca app shell tutulmalÄ±dÄ±r

### lib/app/router/

Konum:
`lib/app/router/`

GÃ¶revi:
GoRouter tabanlÄ± navigation aÄŸacÄ±nÄ±, branch navigator key'lerini ve route helper
path Ã¼reticilerini taÅŸÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`app_router.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`features/navigation/`, `features/files/presentation/`, `features/home/`,
`features/menu/`, `features/search/`, `features/splash/`

Dikkat edilmesi gereken kurallar:
- KlasÃ¶r ekranlarÄ± path/query/extra bilgisi ile aÃ§Ä±lmalÄ±dÄ±r
- Route helper mantÄ±ÄŸÄ± UI iÃ§inde tekrar yazÄ±lmamalÄ±dÄ±r
- Branch stack davranÄ±ÅŸÄ± `app_router.dart` dÄ±ÅŸÄ±nda daÄŸÄ±lmamalÄ±dÄ±r

## 4. core/ KatmanÄ±

### lib/core/

Konum:
`lib/core/`

GÃ¶revi:
UygulamanÄ±n her yerinde kullanÄ±lan temel altyapÄ± parÃ§alarÄ±nÄ± gruplar.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
theme, localization ve constants dosyalarÄ±

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
TÃ¼m katmanlar

Dikkat edilmesi gereken kurallar:
- Feature'e Ã¶zel sabitler buraya deÄŸil ilgili feature/data katmanÄ±na konmalÄ±dÄ±r
- `core/` baÄŸÄ±msÄ±z ve hafif tutulmalÄ±dÄ±r

### lib/core/constants/

Konum:
`lib/core/constants/`

GÃ¶revi:
Global seviyede kullanÄ±lan sabitleri taÅŸÄ±r. Åu anda Ã¶zellikle storage root
hesabÄ±nda kullanÄ±lÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`storage_paths.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`data/services/`, `features/files/state/`

Dikkat edilmesi gereken kurallar:
- Root path mantÄ±ÄŸÄ± tek yerde tutulmalÄ±dÄ±r
- AynÄ± sabit farklÄ± feature dosyalarÄ±na kopyalanmamalÄ±dÄ±r

### lib/core/localization/

Konum:
`lib/core/localization/`

GÃ¶revi:
Lokalizasyon provider'Ä± ve `BuildContext` extension'larÄ±nÄ± taÅŸÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`locale_provider.dart`, `l10n_extensions.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
TÃ¼m presentation katmanlarÄ±, `app/app.dart`

Dikkat edilmesi gereken kurallar:
- UI metinleri doÄŸrudan hard-code edilmemeli, l10n Ã¼zerinden alÄ±nmalÄ±dÄ±r
- Locale deÄŸiÅŸimi iÃ§in feature state yerine bu katman kullanÄ±lmalÄ±dÄ±r

### lib/core/theme/

Konum:
`lib/core/theme/`

GÃ¶revi:
Uygulama temasÄ± ve renk ÅŸemasÄ±nÄ± yÃ¶netir.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`app_theme.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`app/app.dart`, tÃ¼m UI widget'larÄ±

Dikkat edilmesi gereken kurallar:
- Tema sabitleri sayfalara daÄŸÄ±lmamalÄ±dÄ±r
- Yeni renk/typography kararlarÄ± Ã¶nce bu katmanda merkezileÅŸtirilmelidir

## 5. data/ KatmanÄ±

### lib/data/

Konum:
`lib/data/`

GÃ¶revi:
KalÄ±cÄ± veri, index, cache, query ve dosya sistemi iÅŸleri iÃ§in ana veri katmanÄ±dÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
constants, models, repositories, services

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
AÄŸÄ±rlÄ±klÄ± olarak `features/files/`, `features/search/`, `features/home/`

Dikkat edilmesi gereken kurallar:
- UI burada olmamalÄ±dÄ±r
- Repository ve service sorumluluklarÄ± karÄ±ÅŸtÄ±rÄ±lmamalÄ±dÄ±r

### lib/data/constants/

Konum:
`lib/data/constants/`

GÃ¶revi:
File index, kategori, cleanup, Hive box ve kalÄ±cÄ± koleksiyon limit sabitlerini taÅŸÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`file_category_constants.dart`, `cleaning_constants.dart`,
`hive_box_names.dart`, `persistent_collection_limits.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`data/services/`, `data/repositories/`, `features/files/state/`

Dikkat edilmesi gereken kurallar:
- SayÄ± limitleri ve kategori tanÄ±mlarÄ± magic number olarak feature iÃ§ine yazÄ±lmamalÄ±dÄ±r
- Hive box isimleri burada merkezi kalmalÄ±dÄ±r

### lib/data/models/

Konum:
`lib/data/models/`

GÃ¶revi:
Repository ve servislerin taÅŸÄ±dÄ±ÄŸÄ± veri sÃ¶zleÅŸmelerini tanÄ±mlar.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
index, cache, cleanup, operation, access control, search, category,
recent/saved/hidden model dosyalarÄ±

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`data/repositories/`, `data/services/`, `features/*/state/`

Dikkat edilmesi gereken kurallar:
- Model dosyalarÄ± UI baÄŸÄ±mlÄ±lÄ±ÄŸÄ± iÃ§ermemelidir
- `toMap/fromMap` mantÄ±ÄŸÄ± Hive iÃ§in stabil tutulmalÄ±dÄ±r

### lib/data/services/

Konum:
`lib/data/services/`

GÃ¶revi:
Dosya sistemi, indexleme, temizlik, thumbnail Ã¼retimi ve query Ã¼retimi gibi
iÅŸ kurallarÄ±nÄ± uygular.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`file_index_service.dart`, `file_operation_service.dart`,
`cleaning_service.dart`, `thumbnail_cache_service.dart`,
`file_access_service.dart`, `file_system_service.dart`,
`category_query_service.dart`,
`search_query_service.dart`, `hive_service.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`data/repositories/`, `features/files/state/`, `features/search/state/`

Dikkat edilmesi gereken kurallar:
- AÄŸÄ±r I/O iÅŸleri burada tutulmalÄ±dÄ±r
- Service'ler mÃ¼mkÃ¼n olduÄŸunca UI context baÄŸÄ±msÄ±z olmalÄ±dÄ±r
- Dosya operasyonlarÄ±nÄ±n doÄŸrulama ve conflict Ã§Ã¶zÃ¼m hazÄ±rlÄ±ÄŸÄ± burada yapÄ±lmalÄ±dÄ±r

### lib/data/repositories/

Konum:
`lib/data/repositories/`

GÃ¶revi:
Hive tabanlÄ± kalÄ±cÄ± veri eriÅŸimini ve index/query sonuÃ§larÄ±nÄ±n okunmasÄ±nÄ±
merkezileÅŸtirir.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`file_index_repository.dart`, `directory_cache_repository.dart`,
`folder_count_repository.dart`, `recent_repository.dart`,
`saved_repository.dart`, `hidden_repository.dart`,
`thumbnail_cache_repository.dart`, `category_repository.dart`,
`search_repository.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`data/services/`, `app/bootstrap.dart`, `features/files/state/`,
`features/search/state/`

Dikkat edilmesi gereken kurallar:
- Hive box eriÅŸimi feature katmanÄ±na sÄ±zmamalÄ±dÄ±r
- Path bazlÄ± koleksiyonlar duplicate Ã¼retmeyecek ÅŸekilde key tabanlÄ± tutulmalÄ±dÄ±r
- Missing path cleanup senaryolarÄ± sync akÄ±ÅŸlarÄ±yla uyumlu kalmalÄ±dÄ±r

## 6. shared/ KatmanÄ±

### lib/shared/

Konum:
`lib/shared/`

GÃ¶revi:
Feature baÄŸÄ±msÄ±z ortak UI ve ortak listeleme altyapÄ±sÄ±nÄ± taÅŸÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
pagination ve widgets klasÃ¶rleri

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`features/files/presentation/`, `features/home/presentation/`,
`features/search/presentation/`, `features/menu/presentation/`

Dikkat edilmesi gereken kurallar:
- Ortak davranÄ±ÅŸ burada toplanmalÄ±, feature iÃ§inde kopya widget Ã¼retilmemelidir

### lib/shared/widgets/

Konum:
`lib/shared/widgets/`

GÃ¶revi:
Skeleton, empty state ve error state bileÅŸenlerini ortaklaÅŸtÄ±rÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`app_skeleton.dart`, `folder_list_skeleton.dart`, `file_item_skeleton.dart`,
`category_grid_skeleton.dart`, `storage_card_skeleton.dart`,
`empty_state_widget.dart`, `error_state_widget.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
TÃ¼m presentation katmanlarÄ±

Dikkat edilmesi gereken kurallar:
- Normal klasÃ¶r loading akÄ±ÅŸÄ±nda aÃ§Ä±klayÄ±cÄ± uzun metin yerine skeleton kullanÄ±lmalÄ±dÄ±r
- Empty/error state tasarÄ±mlarÄ± feature bazlÄ± yeniden yazÄ±lmamalÄ±dÄ±r

### lib/shared/pagination/

Konum:
`lib/shared/pagination/`

GÃ¶revi:
100'er item incremental loading mantÄ±ÄŸÄ±nÄ± merkezileÅŸtirir.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`paginated_state.dart`, `paginated_controller.dart`, `paginated_file_list.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`features/files/presentation/`, `features/home/presentation/`

Dikkat edilmesi gereken kurallar:
- `PaginatedController.pageSize` merkezi kuraldÄ±r
- Liste sÄ±fÄ±rlama ve `didUpdateWidget` davranÄ±ÅŸlarÄ± burada korunmalÄ±dÄ±r

## 7. features/ KatmanÄ±

### lib/features/files/

Konum:
`lib/features/files/`

GÃ¶revi:
Dosya gezme, klasÃ¶r aÃ§ma, kayÄ±t, gizleme, temizlik ve operasyon akÄ±ÅŸlarÄ±nÄ±n ana
feature katmanÄ±dÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
state, presentation, route model dosyalarÄ±

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`data/`, `shared/`, `app/router/`, `core/`

Dikkat edilmesi gereken kurallar:
- Dosya sistemi eriÅŸimi doÄŸrudan widget iÃ§inde yapÄ±lmamalÄ±dÄ±r
- Path tabanlÄ± folder routing korunmalÄ±dÄ±r

### lib/features/files/state/

Konum:
`lib/features/files/state/`

GÃ¶revi:
Dosya aÄŸacÄ±, izin durumu, selection mode ve dosya operasyon orchestration'Ä±nÄ± taÅŸÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`izinler.dart`, `folderleragaci.dart`, `dosyaislemleri.dart`, `altislem_provider.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`data/repositories/`, `data/services/`, `features/files/presentation/`

Dikkat edilmesi gereken kurallar:
- `FileTree` cache hydrate, folder count ve directory cache mantÄ±ÄŸÄ±nÄ±n merkezidir
- `Izinler` permission + sync + root refresh sorumluluÄŸunu taÅŸÄ±r
- `Dosyaislemleri` UI state orkestrasyonu yapar; fiziksel dosya operasyonunu service'e bÄ±rakÄ±r

### lib/features/files/presentation/

Konum:
`lib/features/files/presentation/`

GÃ¶revi:
Dosya/klasÃ¶r ekranlarÄ±nÄ±, klasÃ¶r route modelini ve dosya item widget'larÄ±nÄ± taÅŸÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`pages/`, `widgets/`, `models/folder_route_data.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`features/files/state/`, `shared/`, `core/`, `app/router/`

Dikkat edilmesi gereken kurallar:
- Sayfalar provider state'i tÃ¼ketmeli, servis yaratmamalÄ±dÄ±r
- Folder page'ler route ile gelen path bilgisini kullanmalÄ±dÄ±r
- Refresh ve pagination ortak bileÅŸenlerle saÄŸlanmalÄ±dÄ±r

### lib/features/search/

Konum:
`lib/features/search/`

GÃ¶revi:
Index tabanlÄ± arama akÄ±ÅŸÄ±nÄ± ve arama ekranÄ±nÄ± taÅŸÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`state/search_controller.dart`, `presentation/pages/arama.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`data/repositories/search_repository.dart`, `shared/`, `core/`

Dikkat edilmesi gereken kurallar:
- Arama dosya sistemini doÄŸrudan recursive taramamalÄ±dÄ±r
- Index ve query servisleri Ã¼zerinden ilerlemelidir

### lib/features/home/

Konum:
`lib/features/home/`

GÃ¶revi:
Ana sayfadaki kategori kartlarÄ± ve son gezilenler akÄ±ÅŸÄ±nÄ± taÅŸÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`presentation/pages/anasayfa_icerigi.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`features/files/state/`, `app/router/`, `shared/`

Dikkat edilmesi gereken kurallar:
- Recent verisi repository -> sync -> fileTree zinciriyle gelmelidir
- Ana sayfa route helper'larÄ±nÄ± kendi iÃ§inde yeniden Ã¼retmemelidir

### lib/features/menu/

Konum:
`lib/features/menu/`

GÃ¶revi:
MenÃ¼ ekranÄ±nÄ±, depolama bilgi kartÄ±nÄ± ve menÃ¼den aÃ§Ä±lan yardÄ±mcÄ± sayfalarÄ± taÅŸÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`presentation/pages/menu.dart`, `state/localestoragebilgileri.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`features/files/presentation/pages/`, `core/`

Dikkat edilmesi gereken kurallar:
- MenÃ¼ state'i dosya aÄŸacÄ± state'i ile karÄ±ÅŸtÄ±rÄ±lmamalÄ±dÄ±r
- MenÃ¼den aÃ§Ä±lan ekranlar router Ã¼zerinden yÃ¶netilmelidir

### lib/features/navigation/

Konum:
`lib/features/navigation/`

GÃ¶revi:
Stateful shell tab yapÄ±sÄ±nÄ± ve ana navigation kabuÄŸunu taÅŸÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`presentation/pages/anasayfa.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`app/router/`, `features/menu/`, `features/home/`, `features/files/`, `features/search/`

Dikkat edilmesi gereken kurallar:
- Tab branch state'i router ile uyumlu kalmalÄ±dÄ±r
- Ortak shell app-level logic ile karÄ±ÅŸmamalÄ±dÄ±r

### lib/features/splash/

Konum:
`lib/features/splash/`

GÃ¶revi:
BaÅŸlangÄ±Ã§ splash/logotype ekranÄ±nÄ± taÅŸÄ±r.

Ä°Ã§erdiÄŸi dosya tÃ¼rleri:
`presentation/pages/logosayfasi.dart`

BaÅŸka hangi katmanlarla iletiÅŸim kurar:
`app/router/`

Dikkat edilmesi gereken kurallar:
- Splash ekranÄ± aÄŸÄ±r iÅŸ yapmamalÄ±; bootstrap iÅŸlemi app giriÅŸinde Ã§Ã¶zÃ¼lmelidir

## 8. Dosya Sistemi ve Index MantÄ±ÄŸÄ±

Dosya sistemi mantÄ±ÄŸÄ± iki ana kaynaktan yÃ¼rÃ¼r:

- gerÃ§ek dosya sistemi eriÅŸimi
- Hive tabanlÄ± file index/cache katmanÄ±

Temel bileÅŸenler:

- `FileTree` (`features/files/state/folderleragaci.dart`)
- `FileAccessService` + `FileAccessResult`
- `FileIndexService` + `FileIndexRepository`
- `DirectoryCacheRepository`
- `FolderCountRepository`
- `ThumbnailCacheService` + `ThumbnailCacheRepository`

Kurallar:

- her fiziksel klasÃ¶r okumasÄ±ndan Ã¶nce eriÅŸim kontrolÃ¼ yapÄ±lmalÄ±dÄ±r
- eriÅŸim yoksa UI boÅŸ liste yerine error state gÃ¶stermelidir
- missing veya type-mismatch path'lerde ilgili Hive cache kayÄ±tlarÄ± prune edilmelidir
- Root ve normal klasÃ¶r aÃ§Ä±lÄ±ÅŸlarÄ± `FileTree.loadFolder(...)` ile yÃ¶netilir
- directory cache snapshot'larÄ± klasÃ¶r iÃ§eriklerini hÄ±zlÄ± hydrate etmek iÃ§in kullanÄ±lÄ±r
- folder count cache gÃ¶rÃ¼nÃ¼r klasÃ¶r sayaÃ§larÄ±nÄ± arka planda doldurur
- arama ve kategori ekranlarÄ± tekrar recursive tarama yapmak yerine index verisini kullanÄ±r
- dosya sistemi mutasyonlarÄ±ndan sonra index refresh tetiklenmelidir

## 9. Hive Veri Saklama MantÄ±ÄŸÄ±

Hive bu projede yalnÄ±zca ayar deÄŸil, operasyonel cache ve kalÄ±cÄ± koleksiyon katmanÄ±
olarak da kullanÄ±lÄ±r.

BaÅŸlÄ±ca box'lar:

- `file_index`
- `file_index_metadata`
- `directory_cache_box`
- `folder_count_cache`
- `thumbnail_cache_metadata`
- `recent_items`
- `saved_items`
- `hidden_items`

Kurallar:

- path bazlÄ± koleksiyonlarda box key olarak path kullanÄ±lÄ±r
- aynÄ± item yeniden yazÄ±ldÄ±ÄŸÄ±nda duplicate yerine overwrite olur
- sync aÅŸamasÄ±nda fiziksel olarak silinmiÅŸ path'ler repository'den temizlenir
- Hive eriÅŸimi sadece repository/service zinciri Ã¼zerinden yapÄ±lmalÄ±dÄ±r

## 10. Loading ve Skeleton MantÄ±ÄŸÄ±

Ortak loading sistemi `shared/widgets/` altÄ±nda merkezileÅŸtirilmiÅŸtir.

Temel bileÅŸenler:

- `AppSkeleton`
- `FolderListSkeleton`
- `FileItemSkeleton`
- `CategoryGridSkeleton`
- `StorageCardSkeleton`
- `EmptyStateWidget`
- `ErrorStateWidget`

Kurallar:

- normal klasÃ¶r aÃ§Ä±lÄ±ÅŸlarÄ±nda uzun progress metinleri yerine skeleton gÃ¶sterilir
- kategori veya Ã¶zel tarama senaryolarÄ±nda gerekiyorsa aÃ§Ä±klayÄ±cÄ± progress kullanÄ±labilir
- boÅŸ ve hata durumlarÄ± ortak widget'larla temsil edilir

## 11. Pagination MantÄ±ÄŸÄ±

Pagination merkezi olarak `PaginatedController.pageSize = 100` Ã¼zerinden yÃ¼rÃ¼r.

Uygulama noktalarÄ±:

- root dosya listesi
- gizli dosyalar
- kaydedilen dosyalar
- recent listesi
- klasÃ¶r iÃ§erik listeleri

Kurallar:

- klasÃ¶rler Ã¶nce, dosyalar sonra bÃ¼tÃ§eye girer
- scroll alt sÄ±nÄ±rÄ±nda sonraki sayfa yÃ¼klenir
- recent repository kalÄ±cÄ± olarak daha geniÅŸ tutulur; UI tarafÄ± ilk 100'Ã¼ hemen gÃ¶sterir

## 12. Refresh MantÄ±ÄŸÄ±

Refresh akÄ±ÅŸlarÄ± `RefreshIndicator` ve provider sync helper'larÄ± ile yÃ¶netilir.

Temel Ã¶rnekler:

- root dosyalar -> `Izinler.refreshRootEntries()`
- gizli dosyalar -> `Izinler.refreshHiddenEntries()`
- kaydedilen dosyalar -> `Izinler.refreshSavedEntries()`
- klasÃ¶r iÃ§eriÄŸi -> `FileTree.loadFolder(..., forceRefresh: true)`

Kurallar:

- refresh sadece UI listeyi deÄŸil, ilgili Hive cache ve fileTree state'ini de yenilemelidir
- mutasyon sonrasÄ± gerekli sync'ler Ã§aÄŸrÄ±lmadan UI state gÃ¼venilmemelidir

## 13. Arama MantÄ±ÄŸÄ±

Arama feature'i indekslenmiÅŸ dosya verisi Ã¼zerinden Ã§alÄ±ÅŸÄ±r.

BileÅŸenler:

- `SearchController`
- `SearchRepository`
- `SearchQueryService`
- `SearchPageResult`

Kurallar:

- arama sorgusu gerÃ§ek dosya sistemini her seferinde recursive gezmemelidir
- sonuÃ§lar pagination ve loading state ile birlikte sunulmalÄ±dÄ±r
- arama ekranÄ± folder route aÃ§arken genel router helper'larÄ±nÄ± kullanmalÄ±dÄ±r

## 14. Kategori MantÄ±ÄŸÄ±

Kategori sistemi `FileTree` iÃ§inde sanal klasÃ¶rler olarak temsil edilir.

BileÅŸenler:

- `file_category_constants.dart`
- `FolderNode(isVirtual: true)`
- `CategoryRepository`
- `CategoryQueryService`

Kurallar:

- kategori klasÃ¶rleri fiziksel dizin deÄŸildir
- kategori ekranÄ± uzantÄ± filtresi ve index verisi Ã¼zerinden Ã§alÄ±ÅŸmalÄ±dÄ±r
- kategori route'u normal klasÃ¶r route'undan ayrÄ± ama aynÄ± path taÅŸÄ±ma mantÄ±ÄŸÄ±yla ilerlemelidir

## 15. Dosya OperasyonlarÄ± MantÄ±ÄŸÄ±

Dosya operasyonlarÄ± artÄ±k Ã¼Ã§ seviyeye ayrÄ±lmÄ±ÅŸtÄ±r:

- UI / selection orchestration -> `Dosyaislemleri`
- fiziksel dosya iÅŸi -> `FileOperationService`
- temizlik iÅŸi -> `CleaningService`

Ek destek:

- thumbnail cache temizliÄŸi
- persistent saved/hidden/recent sync
- file index refresh
- folder reload / root refresh

Kurallar:

- copy/move/delete/rename/create iÅŸlemleri state sÄ±nÄ±fÄ±nda manuel `dart:io`
  ile daÄŸÄ±tÄ±lmamalÄ±dÄ±r
- conflict, doÄŸrulama ve progress service/result modeli Ã¼zerinden taÅŸÄ±nmalÄ±dÄ±r
- cleanup dosya operasyonlarÄ±ndan ayrÄ± bir servis olarak kalmalÄ±dÄ±r

## 16. Rapor GÃ¼ncelleme KurallarÄ±

Bu proje iÃ§in iki ana dokÃ¼man birlikte gÃ¼ncel tutulmalÄ±dÄ±r:

- `PROJE_CALISMA_MANTIGI_RAPORU.md`
- `project_arcithecture.md`

Kurallar:

- Mimariyi etkileyen her gÃ¶rev tamamlandÄ±ÄŸÄ±nda ilgili bÃ¶lÃ¼m Ã¶nce ana Ã§alÄ±ÅŸma
  raporunda gÃ¼ncellenmelidir
- Yeni klasÃ¶r, repository, service, cache veya ortak UI altyapÄ±sÄ± eklendiÄŸinde bu
  dosyada da ilgili katman bÃ¶lÃ¼mÃ¼ gÃ¼ncellenmelidir
- Gelecekteki kontrol gÃ¶revlerine baÅŸlamadan Ã¶nce iki rapor birlikte okunmalÄ±dÄ±r
- `legacy/` altÄ±nda yeni geliÅŸtirme yapÄ±lacaksa Ã¶nce bu dosyada gerekÃ§esi belirtilmelidir

## 17. Dosya VarlÄ±k Senkronizasyon KatmanÄ±

Task 19 ile birlikte kalÄ±cÄ± Hive kayÄ±tlarÄ±nÄ± gerÃ§ek dosya sistemiyle hizalayan
ayrÄ± bir servis katmanÄ± eklenmiÅŸtir.

BileÅŸenler:

- `data/models/file_sync_models.dart`
- `data/services/file_sync_service.dart`

Sorumluluklar:

- `SavedRepository`, `HiddenRepository` ve `RecentRepository` kayÄ±tlarÄ±nÄ± topluca
  doÄŸrulamak
- her kayÄ±t iÃ§in `FileAccessService` kullanarak path'in hÃ¢lÃ¢ geÃ§erli olup
  olmadÄ±ÄŸÄ±nÄ± kontrol etmek
- artÄ±k bulunamayan veya tip uyuÅŸmazlÄ±ÄŸÄ± yaÅŸayan kayÄ±tlarÄ± ilgili listelerden
  temizlemek
- `DirectoryCacheRepository` ve `FolderCountRepository` iÃ§indeki stale klasÃ¶r
  cache kayÄ±tlarÄ±nÄ± ayÄ±klamak
- gerektiÄŸinde `FileIndexService.refreshIndex(rootPath)` Ã§aÄŸrÄ±sÄ± ile arama ve
  kategori indeksini de dosya sistemiyle tekrar hizalamak

State entegrasyonu:

- `Izinler` bu servisin ana orkestratÃ¶rÃ¼dÃ¼r
- baÅŸlangÄ±Ã§ izin yÃ¼klemesi sÄ±rasÄ±nda `synchronizePersistentCollections()` Ã§alÄ±ÅŸÄ±r
- root, hidden, saved ve aktif klasÃ¶r refresh akÄ±ÅŸlarÄ± aynÄ± servis Ã¼zerinden
  senkronizasyon baÅŸlatÄ±r
- hydrate edilen sonuÃ§lar tekrar `FileTree.setHiddenPaths`,
  `setHiddenItems`, `setSavedItems` ve `setRecentItems` Ã¼zerinden UI state'ine
  geri yazÄ±lÄ±r

Kurallar:

- path doÄŸrulama mantÄ±ÄŸÄ± UI veya widget katmanÄ±na taÅŸÄ±nmamalÄ±dÄ±r
- stale kayÄ±t temizliÄŸi repository Ã¼zerinde yapÄ±lmalÄ±, widget tarafÄ±nda manuel
  liste filtreleme ile Ã§Ã¶zÃ¼lmemelidir
- index refresh sadece senkronizasyon servisinden veya kategori/search
  repository akÄ±ÅŸlarÄ±ndan tetiklenmelidir

## 18. GÃ¼venli Dosya Operasyon Kontrolleri

Task 20 ile `FileOperationService` sadece fiziksel kopyalama/silme yapan bir
yardÄ±mcÄ± olmaktan Ã§Ä±karÄ±lÄ±p preflight kontrol ve rollback sorumluluklarÄ± da olan
gÃ¼venli mutation katmanÄ±na dÃ¶nÃ¼ÅŸtÃ¼rÃ¼lmÃ¼ÅŸtÃ¼r.

Temel deÄŸiÅŸiklikler:

- servis artÄ±k `FileAccessService` baÄŸÄ±mlÄ±lÄ±ÄŸÄ± alÄ±r
- operasyon Ã¶ncesi kaynak ve hedef path doÄŸrulamasÄ± yapÄ±lÄ±r
- hedef klasÃ¶rÃ¼n yazÄ±labilirliÄŸi mutation baÅŸlamadan kontrol edilir
- nested duplicate seÃ§imler servis iÃ§inde sadeleÅŸtirilir
- overwrite akÄ±ÅŸÄ± doÄŸrudan delete yerine backup-then-replace mantÄ±ÄŸÄ±yla Ã§alÄ±ÅŸÄ±r

Rollback kurallarÄ±:

- overwrite hedefi Ã¶nce geÃ§ici backup adÄ±na rename edilir
- yeni kopya doÄŸrulanmadan eski hedef kalÄ±cÄ± olarak silinmez
- copy doÄŸrulamasÄ± veya move source delete adÄ±mÄ± hata verirse yeni hedef silinir
  ve eski backup geri yÃ¼klenir
- rename akÄ±ÅŸÄ±nda hedef path oluÅŸup kaynak kaybolmuÅŸsa eski isim restore edilmeye Ã§alÄ±ÅŸÄ±lÄ±r

State ve UI entegrasyonu:

- `Dosyaislemleri` yeni hata kodlarÄ±nÄ± kullanÄ±cÄ± dostu metinlere Ã§evirir
- silme akÄ±ÅŸÄ± kullanÄ±cÄ± onayÄ± ile baÅŸlar
- mutation sonrasÄ±nda `Izinler.refreshRootEntries()`, aktif klasÃ¶r reload ve
  `FileIndexService.refreshIndex(...)` beklenerek Ã§alÄ±ÅŸtÄ±rÄ±lÄ±r

Kurallar:

- overwrite durumunda mevcut hedefi kopyalama baÅŸlamadan doÄŸrudan silen akÄ±ÅŸ
  tekrar eklenmemelidir
- move iÅŸlemi kaynak silmeyi kopya doÄŸrulamasÄ±ndan Ã¶nce yapmamalÄ±dÄ±r
- rollback gerektiren kararlar state katmanÄ±nda deÄŸil servis katmanÄ±nda
  uygulanmalÄ±dÄ±r
## 19. Dosya Metadata Cache Eki

Bu ek, mevcut mimaride dosya item metadata cache katmanının nereye oturduğunu
ve 5, 8, 9, 12, 15, 16. bölümler için yeni kuralları açıklar.

### 5. data/ Katmanı içindeki yeni bileşenler

- `lib/data/models/file_metadata_model.dart`
- `lib/data/repositories/file_metadata_repository.dart`
- `lib/data/services/file_metadata_service.dart`
- `lib/core/utils/file_formatters.dart`

Sorumluluk dağılımı:

- `FileMetadataModel` dosya path'i, adı, `sizeBytes`, `modifiedAt`, `updatedAt`, `exists`, `extension`, `parentPath` taşır.
- `FileMetadataRepository` sadece `file_metadata_cache` Hive box erişimini yönetir.
- `FileMetadataService` gerçek `FileStat.stat(path)` okumasını, cache hydrate, invalidation, bounded concurrency ve listenable item güncellemesini yönetir.
- `file_formatters.dart` dosya boyutu ve tarihini UI'a uygun ortak string'e çevirir.

### 8. Dosya Sistemi ve Index Mantığı içindeki yeni davranış

- `FileTree.loadFolder(...)` klasör içindeki `File` listesini ürettikten sonra `FileMetadataService.primeFiles(...)` çağırır.
- Aynı path için `file_metadata_cache` kaydı varsa dosya kartı ilk çizimde bu cache'ten hydrate olabilir.
- Cache yoksa arka planda gerçek `FileStat` okunur ve yalnızca ilgili item yeniden çizilir.
- Arama ve kategori ekranları dosya metadata'sını index alanlarından seed edip aynı cache servisiyle doğrulatır.

### 9. Hive Veri Saklama Mantığı içindeki yeni box

Yeni box:

- `file_metadata_cache`

Kurallar:

- Key her zaman dosya `path` değeridir.
- Aynı path yeniden yazıldığında overwrite olur, duplicate oluşmaz.
- Path silinirse veya klasöre dönüşürse ilgili metadata kaydı silinir.
- Stale kayıt temizliği `FileSyncService` ve `FileMetadataService` üzerinden yapılır.

### 12. Refresh Mantığı içindeki yeni davranış

- Root veya klasör refresh geldiğinde `FileTree` görünen dosyalar için metadata prime akışını da tekrar başlatır.
- `forceRefresh: true` geldiğinde metadata cache yalnızca okunmaz; gerçek `FileStat` sonucu ile overwrite edilir.
- `PaginatedFileListView` görünen dosyalar için metadata prime ederek scroll performansını korurken alt satır bilgisini erken doldurur.

### 15. Dosya Operasyonları Mantığı içindeki yeni sync kuralları

- Delete sonrası silinen path'lerin metadata cache kayıtları temizlenir.
- Rename sonrası eski file path cache'i silinir, yeni path için metadata yeniden üretilir.
- Copy / paste sonrası hedef file path'leri için yeni metadata oluşturulur.
- Move / cut-paste sonrası eski file path metadata'sı temizlenir, yeni hedef path metadata'sı üretilir.
- Cleanup silmeleri de `FileMetadataService.deleteMetadataForPaths(...)` üzerinden metadata cache'i prune eder.

### 16. Rapor Güncelleme Kuralları içindeki yeni not

`file_metadata_cache`, `file_metadata_service.dart`, `file_metadata_model.dart`
veya `core/utils/file_formatters.dart` davranışı değiştiğinde:

- `PROJE_CALISMA_MANTIGI_RAPORU.md`
- `project_arcithecture.md`

aynı turda beraber güncellenmelidir.
