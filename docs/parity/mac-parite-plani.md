# UpLa for Mac: Windows ile birebir arayüz — parite matrisi ve aşamalı plan

**Amaç.** Mac uygulamasını Windows'taki UpLa ile aynı menülere, aynı pencerelere ve aynı metinlere kavuşturmak. Windows'taki her öğe için Mac'te bugün ne olduğu, ne zaman ve nasıl yapılacağı, nerede macOS'e uyarlanması gerektiği bu belgede.

**Dayanak.**
- Windows: `windows-arayuz-envanteri.md` (UpLa 2.0.2, `upla-sharex` `ce4359069`). O belgenin bölümleri "envanter §N", bu belgenin bölümleri yalnızca "§N" diye anılır. 2.0.3 yalnızca onay işareti hatasını düzeltir (envanter §12.1).
- Windows referans görüntüleri: `windows-ref/` (UpLa 2.0.3, Türkçe; dizin `README.md`'de).
- Mac bugün: `UpLa-mac`, dal `feature/screen-recording` @ `952d30d` (PR #3, ekran kaydı dahil; birleştirilmedi). `main` (`954b4ce`) bundan yalnızca ekran kaydı ve DMG kadar eksik.
- Plan yazılırken hiçbir şey çalıştırılmadı veya değiştirilmedi; iki depo da yalnızca okundu. Görüntüler sonradan, 2.0.3'ün temiz bir taşınabilir kopyasından alındı.
- **Kararlar verildi (2026-10-10):** kullanıcı §9'daki 22 önerinin hepsini kabul etti.

---

## 0. Özet

**Bugün.** Mac 0.1 yalnızca bir menü çubuğu uygulaması: ana penceresi yok, ayarları tek pencerede altı sekme. Windows sol panelindeki 16 öğenin yarısının bir karşılığı var, ama çoğu başka adla ve başka yerde. Ana pencere, görev listesi, Araçlar, Yakalama sonrası / Yükleme sonrası menüleri, Görev ayarları, kısayol listesi, tost bildirimi, Resim geçmişi ve Hata ayıklama hiç yok.

Matristeki 412 Windows öğesinden Mac'te **38'i var**, **65'i kısmen var**, **279'u yok**; **29'u** Windows'a özgü ya da Windows'ta da işlevsiz olduğu için taşınmayacak (§4).

**Önerilen yaklaşım.**
- AppKit ile Windows'takinin aynısı bir **ana pencere**: solda aynı düğme paneli ve sağa açılan aynı menüler, sağda küçük resimli görev listesi.
- **Menü çubuğu simgesi tepsi simgesinin yerini alır**; menüsü Windows tepsi menüsüyle aynı sırada.
- **Dört ayrı ayar penceresi** (Uygulama, Görev, Kısayol, Hedef ayarları); Windows'taki ağaç düğümleri ve seçenek adlarıyla.
- **Metinler Windows'un `.resx` dosyalarından betikle aktarılır**; elle yazılmaz.
- **Ayar modeli ShareX'in görev ayarları yapısına göre yeniden kurulur**: Yakalama sonrası ve Yükleme sonrası bayrakları Windows'taki bit değerleriyle, menüler değere bağlı.

**Aşamalar.** Her aşama kendi başına yayınlanabilir; sıra kullanıcıya kazandırdığı değere göre.

| Aşama | İçerik | Efor | Kullanıcının kazancı |
|---|---|---|---|
| 1 | Ana pencere, birebir menüler (sol panel ve menü çubuğu), Yakalama sonrası / Yükleme sonrası görev listeleri, görev listesi, ayar pencerelerinin iskeleti | L (≈3–4 hafta) | Uygulama Windows'taki gibi görünür ve aynı yerden kullanılır |
| 2 | Ayarların tamamı, kısayol listesi ve kısayola özel ayarlar, tost bildirimi ve sesler, Geçmiş / Resim geçmişi / Hata ayıklama, görev pencereleri | L (≈3–4 hafta) | Windows'taki bütün seçenekler ve akışlar |
| 3 | Yerel karşılığı olan araçlar: OCR, QR kod, ekrana sabitle, renk seçiciler, cetvel, görüntüleyici, birleştirici, güzelleştirici, efektler | L (≈3 hafta) | Araçlar menüsü dolar |
| 4 | Kendi bölge yakalama ekranı, Bölge (Basit) / (Saydam) / Son bölge, GIF kaydı, kayıt çubuğu ve duraklatma, kaydırarak yakalama, aksiyonlar, dizin takibi, Finder entegrasyonu | L (≈4–5 hafta) | Yakalama ve kayıt Windows'takiyle aynı |
| 5 | Resim düzenleyici (çizim araçları) ve kalan ağır öğeler | L+ (≈4–6 hafta) | Düzenleyici ve bölge ekranında çizim |

**Efor ölçeği:** S = en çok 1 gün · M = 2–5 gün · L = 1–3 hafta. Hafta tahminleri tek geliştirici + Claude Code ve Mac'te elle test içindir; kabadır. Asıl darboğaz Mac'te test etmek.

**PLAN.md'yi değiştiren nokta.** Mac PLAN.md'deki "Not planned: ShareX's other destinations, custom uploaders, workflows and tools" maddesi bu istekle değişir: **araçlar ve iş akışları (kısayol listesi) kapsama girer.** upla.com.tr dışındaki hedefler, özel yükleyiciler ve NSFW ise Windows UpLa'da da olmadığı için kapsam dışında kalır.

---

## 1. "Birebir"in kuralları

1. **Aynı yapı ve sıra:** sol panel, bütün menüler ve alt menüler, ayar pencerelerinin ağaç düğümleri, seçeneklerin sırası Windows'takiyle aynı.
2. **Aynı metinler:** Windows'un Türkçe ve İngilizce metinleri tek kaynaktır (§2.7). Mac'te yalnızca platform sözcükleri değişir: "Windows", "Gezgin", "Geri Dönüşüm Kutusu", "görev çubuğu", "sistem tepsisi", Ctrl/Win tuşları (liste §3.2).
3. **Aynı varsayılanlar:** Yakalama sonrası **Resimi panoya kopyala + Resimi dosya olarak kaydet + Resimi yükle**; Yükleme sonrası **Adresi panoya kopyala**; küçük resim görünümü; aynı anda 5 yükleme; son 10 görevin saklanması. Mac'in bugünkü farklı varsayılanları için karar 9.
4. **Windows hataları kopyalanmaz** (envanter §12): onay işaretleri gerçek bayrakları gösterir; çift "upla.com.tr" radyo düğmesi yok.
5. **İşlevsiz Windows öğeleri gösterilmez** (karar 7): hep gri olan Kısaltılmış adres / Küçük resim dosya / Küçük resim, Kütüğü karşıya yükle, Metin olarak yükle, ikincil yükleyiciler, yükleyici filtreleri, Upload text özellikleri.
6. **Henüz yapılmamış öğeler** yayınlanan sürümde gizli kalır (karar 10).
7. **macOS'in zorunlu kıldığı yerlerde** en yakın karşılık kullanılır (§3); Mac'e özgü zorunlu öğeler (Ekran Kaydı İzni penceresi, uygulama menüsü, ⌘Q) kalır.

---

## 2. Hedef Mac arayüzü

### 2.1 Ana pencere

- **Pencere:** `NSWindow`; başlık "UpLa <sürüm>" (sürüm için karar 18); yükleme sürerken "UpLa <sürüm> - 45,0%". 879×531 pt, en küçük 650×500, ekranın ortasında. Konum ve boyut varsayılan olarak hatırlanmaz (Uygulama ayarları'ndan açılır).
- **Sol panel:** yaklaşık 188 pt genişliğinde dikey bir `NSStackView`; simge + metin, sola hizalı düğmeler, Windows'taki üç ayırıcıyla.
  - Açılır düğmelerin sağ kenarında "▸".
  - Tıklayınca menü `NSMenu.popUp(positioning:at:in:)` ile **düğmenin sağ kenarında, üst hizasında** açılır; Windows'taki gibi sağa açılır.
  - Hesap düğmesinin metni duruma göre "Giriş yap" ya da kullanıcı adı.
- **Görev alanı (sağ):**
  - Boşken kısayol tablosu (Kısayol tuşu / Açıklama, yeşil/kırmızı şerit).
  - **Küçük resim görünümü** (varsayılan): `NSCollectionView`, akış düzeni; 200×150 kutucuk, başlık üstte, üst kenarda durum çizgisi, ilerleme çubuğu, "Hata" rozeti, en yeni başta.
  - **Liste görünümü:** `NSTableView`, yedi sütun (Dosya adı, Durum, İlerleme, Hız, Geçen, Kalan, Adres) ve durum simgeleri; `NSSplitView` içinde sağda önizleme.
  - Görev sağ tık menüsü, klavye kısayolları, sürükle bırak (envanter §1.14–1.16).
- **Neden AppKit:** menünün sağa açılması, çoklu seçim, sürükleyip dışarı bırakma, klavye ve sütun genişliklerini hatırlama SwiftUI'de zor veya kırılgan. Ayar formları bugünkü gibi SwiftUI'de kalabilir.
- **Yakalama:** ana pencereden başlatılan yakalamada pencere önce gizlenir (`orderOut`, 250 ms), sonra geri gelir.
- **Kapatma:** X, ⌘W ve Esc pencereyi gizler; uygulama menü çubuğunda sürer (`applicationShouldTerminateAfterLastWindowClosed` = false). İlk kapatmada bilgi tostu (metin §3.2).

### 2.2 Menü çubuğu simgesi = tepsi simgesi

- `NSStatusItem` menüsü envanter §2.2'deki 25 öğelik sırayla; her açılışta yeniden kurulur (Pencere ▸, Monitör ▸, Son bağlantılar, hesap menüsü).
- **Simge:** UpLa logosu, şablon (template) görüntü olarak. Yükleme sırasında Windows'taki gibi alttan dolan ilerleme simgesi (bugünkü " 45%" metni yerine ya da yanında).
- **Tıklama eylemleri:** sol / çift / orta tık için üç ayar (Windows'taki listeler). `NSStatusBarButton.sendAction(on: [.leftMouseUp, .rightMouseUp, .otherMouseUp])` ve `NSEvent.clickCount` ile. Varsayılanlar için karar 3.
- **Kayıt sırasında** Windows'taki gibi ikinci bir durum simgesi (sarı bekliyor / kırmızı kayıtta; sol tık durdurur; sağ tık Başlat/Durdur, Duraklat/Devam et, İptal). Aşama 4.

### 2.3 Dock simgesi ve uygulama menüsü

- **Dock:** (a) her zaman, (b) hiç (bugünkü `LSUIElement`), (c) yalnızca ana pencere açıkken (`NSApp.setActivationPolicy(.regular/.accessory)` geçişi). Öneri (c) + Uygulama ayarları › Genel'de Mac'e özgü **Dock'ta simge göster** seçeneği (karar 1).
- **Uygulama menüsü:** Dock simgesi görünürken macOS üstte uygulamanın menülerini gösterir. Öneri:
  - **UpLa:** UpLa Hakkında · Uygulama ayarları... ⌘, · — · Hizmetler · — · UpLa'yı Gizle ⌘H · Diğerlerini Gizle · Tümünü Göster · — · UpLa'dan Çık ⌘Q
  - **Düzen:** bugünkü gibi (Geri Al, Yinele, Kes, Kopyala, Yapıştır, Tümünü Seç)
  - **Yakala**, **Yükle**, **Araçlar:** sol paneldeki menülerin aynısı, aynı kurucudan (ek maliyet yok, Mac kullanıcısına doğal gelir)
  - **Pencere:** Simge Durumuna Küçült ⌘M · Kapat ⌘W · UpLa penceresini göster
- **Dock simgesinde ilerleme:** `NSDockTile` ile; Windows'taki "Görev çubuğu tuşunda durum göster"in karşılığı.

### 2.4 Ayar pencereleri

- Dört ayrı pencere, Windows'taki başlıklarla: "UpLa - Uygulama ayarları", "UpLa - Görev ayarları", "UpLa - Kısayol ayarları", "UpLa - Hedef ayarları".
- **Düzen:** solda kenar çubuğu (`NavigationSplitView` + `List`; alt düğümler hep açık; Windows'taki düğüm adları ve sırası), sağda `Form`.
- **Davranış:** modsuz ve tek örnek (macOS'te ayarlar modal olmaz); değişiklik anında uygulanır (Windows'ta da öyle). ⌘, Uygulama ayarları'nı açar.
- **Görev ayarları iki modlu:** varsayılan ayarlar ve kısayola özel ayarlar ("… ayarlarını değiştir" kutularıyla), Windows'taki gibi.
- **Gelişmiş sayfaları:** `PropertyGrid`'in karşılığı kategorili bir `Form`; bölüm başlıkları İngilizce kategori adları, satırlar İngilizce özellik adları (Windows'ta da çevrilmemiş).

### 2.5 Ortak model ve kurucular

| Parça | İçerik |
|---|---|
| `TaskSettings` (Codable) | `AfterCaptureTasks` / `AfterUploadTasks` `OptionSet`'leri **Windows'taki bit değerleriyle** (`ShareX/Enums.cs`: CopyImageToClipboard = 1<<5, SaveImageToFile = 1<<8, UploadImageToHost = 1<<20, CopyURLToClipboard = 1<<3 …). Menü öğeleri sırasına değil değerine bağlanır. Yakalama, resim, yükleme, araç, gelişmiş alt modelleri; varsayılan ayarlar + kısayol başına kopyalar (override bayraklarıyla). |
| `ApplicationConfig`, `HotkeysConfig` | JSON dosyaları, `~/Library/Application Support/UpLa/` (Windows'taki ApplicationConfig.json / HotkeysConfig.json). |
| `WorkerTask` hattı | Windows'taki çalışma sırası (envanter §4.1): hızlı menü → pencere → güzelleştir/efekt/düzenleyici → kopyala/sabitle/yazdır → kaydet → dosya görevleri → OCR → yükleme öncesi → yükle (1 yeniden deneme) → sil → yükleme sonrası → ses ve tost. |
| `TaskManager` | Görev listesi: durum, ilerleme, hız, geçen/kalan süre; aynı anda en çok 5 yükleme; son 10 görevin saklanıp açılışta "Geçmiş" olarak gelmesi. Bugünkü `UploadManager` seri kuyruğunun yerini alır. |
| `NameParser` | `%y`, `%mo`, `%ra{10}`, `%pn` … (envanter §13.1); dosya adı, alt klasör ve pano biçimleri için. |
| `MenuBuilder` | Yakala, Yükle, Araçlar, Yakalama sonrası, Yükleme sonrası, Hedefler, hesap menülerini tek yerden kurar. Ana pencere, menü çubuğu simgesi ve uygulama menüsü aynı kurucuyu kullanır; birebirliği koruyan budur. |
| İkonlar | Asset catalog'da Fugue ikonları (karar 5); koyu temada beyaz sürümleri olanlar (edit_drop_cap, barcode_2d, layer_shape_line …) ayrı. |

Bugünkü dosyalardan en çok değişecekler: `StatusItemController.swift` (menü), `AppController.swift` (eylemler), `AppSettings.swift` (ayar modeli), `SettingsView.swift` (dört pencereye bölünür), `HotKeyCenter.swift` (liste modeli), `UploadManager.swift` (görev yöneticisi), `Notifier.swift` (tost), `HistoryView.swift` / `HistoryStore.swift`, `CaptureService.swift`, `WindowManager.swift`, `AboutView.swift`, `AccountSettingsView.swift`.

### 2.6 Bugünkü Mac ayarlarının yeni yerleri (geçiş)

İlk açılışta eski UserDefaults anahtarları yeni modele çevrilir; kullanıcının seçtiği değerler korunur, yalnızca hiç dokunulmamış varsayılanlar Windows'unkilere geçer.

| Mac bugün (sekme › denetim, anahtar) | Yeni yeri (Windows'taki gibi) |
|---|---|
| Genel › Oturum açıldığında UpLa'yı başlat (`SMAppService`) | Uygulama ayarları › Entegrasyon › **Oturum açıldığında UpLa'yı çalıştır** (Windows: "Windows başladığında UpLa'yı çalıştır") |
| Genel › Yükleme bitince bildirim göster (`ShowNotifications`) | Görev ayarları › Genel › Uyarılar › **Görev bittikten sonra tost bildirimi göster** |
| Yakalama › upla.com.tr'ye yükle ve linki kopyala (`UploadAfterCapture`) | İki ayrı bayrak: Yakalama sonrası ▸ **Resimi yükle** + Yükleme sonrası ▸ **Adresi panoya kopyala** |
| Yakalama › Resmi panoya kopyala (`CopyImageAfterCapture`) | Yakalama sonrası ▸ **Resimi panoya kopyala** |
| Yakalama › Bir klasöre kaydet (`SaveAfterCapture`) | Yakalama sonrası ▸ **Resimi dosya olarak kaydet** |
| Yakalama › Klasör: (`SaveFolderPath`) | Uygulama ayarları › Yollar › **Özel ekran görüntüsü dizini kullan:** + yol |
| Kayıt › Saniyedeki kare sayısı (`RecordingFramesPerSecond`) | Görev ayarları › Yakalama › Ekran kaydedici › **Ekran kayıt FPS:** |
| Kayıt › Fare imlecini göster (`RecordingShowsCursor`) | aynı sayfa › **Ekran kaydında imleç göster** |
| Kayıt › Sistem sesini kaydet (`RecordingCapturesAudio`) | **Ekran kayıt ayarları...** penceresi › **Ses kaynağı:** |
| Kayıt › Yüklenecek ekran kayıtlarını yükleme sınırına gelince durdur (`StopRecordingAtUploadLimit`) | Hedef ayarları › upla.com.tr (Windows'taki yeri) |
| upla.com.tr sekmesi (link türü, albüm, etiketler, otomatik silme, kategori, genişlik) | Hedef ayarları › upla.com.tr, Windows'taki satır sırasıyla |
| Hesap sekmesi | Hedef ayarları › upla.com.tr sayfasının üst kısmı |
| Kısayollar sekmesi (`HotKey.*`) | Kısayol ayarları penceresi (liste modeli) |
| `ShowUploadWarning` | aynı ad; Uygulama ayarları › Gelişmiş › Upload |

### 2.7 Metinlerin birebir aktarılması

- **Kaynak:** Windows'taki form `*.tr.resx` / `*.resx` dosyaları, `ShareX.HelpersLib`, `ShareX`, `ShareX.ScreenCaptureLib`, `ShareX.HistoryLib`, `ShareX.ImageEffectsLib` `Properties/Resources(.tr).resx` dosyaları ve `UplaStrings.cs`.
- **Yöntem:** bir betik (Mac'te bugün kullanılan `extract_strings.py` / `tr_strings.py` gibi) bu dosyalardan `Localizable.xcstrings` üretir: anahtar = Windows'un İngilizce metni, Türkçe çeviri = Windows'un Türkçe metni. Böylece iki dil de Windows'la aynı olur. Mac'e özgü metinler (izin penceresi, kayıt durum satırları vb.) elle tutulur. Platform sözcükleri §3.2'deki küçük eşleme tablosuyla değiştirilir.
- **Yeniden çalıştırılabilir:** Windows'ta bir metin değişince betik yeniden çalıştırılır.
- **Görsel karşılaştırma:** Mac'teki Claude oturumu Windows uygulamasını göremez. Windows'taki her menünün ve pencerenin Türkçe ekran görüntüsü `docs/parity/windows-ref/` klasöründe; her aşamanın sonunda Mac görüntüleriyle yan yana karşılaştırılır.

---

## 3. macOS alışkanlıklarıyla çakışan yerler

### 3.1 Davranış

| Windows | Birebir kopyalanırsa | Öneri |
|---|---|---|
| Menüler düğmenin **sağına** açılır | Mac'te açılır menüler genelde düğmenin altına açılır | Sorun değil: `NSMenu.popUp` ile tam Windows'taki yere açılır |
| Yakalama sonrası, Yükleme sonrası, Hedefler ve gecikme menüleri tıklayınca **açık kalır** | `NSMenu` her tıkta kapanır; açık tutmak için `NSMenuItem.view` ile özel satır gerekir (vurgu ve klavye gezintisi elle yazılır) | Aşama 1'de macOS standardı (tek tık = tek değişiklik); istenirse sonra özel satır (karar 11) |
| Tepsi simgesine **sol tık = Bölge yakala**, çift tık = ana pencere, orta tık = pano | Mac'te durum simgesine tık menüyü açar; çift tık tanımlıysa tek tık ~0,5 sn gecikir | Üç ayar aynen gelir; varsayılan için karar 3 |
| Kapat / Esc pencereyi **tepsiye gizler**, ilk seferde tost | Mac'te pencereyi kapatmak zaten uygulamayı kapatmaz | Aynı davranış; metin "menü çubuğu" olarak (§3.2) |
| Ayar pencereleri **modal** | Mac'te ayar pencereleri modal olmaz | Modsuz, tek örnek |
| Ağaçla gezinme, Microsoft Sans Serif | Mac'te kenar çubuğu ve sistem yazı tipi | `NavigationSplitView` kenar çubuğu; aynı düğüm adları ve sıra |
| Özellik ızgarası (Gelişmiş) | AppKit'te yok | Kategorili `Form`, İngilizce adlarla |
| Koyu "Dark" teması ve tema düzenleyici | Özel renkler yerel denetimlerle uyuşmaz; macOS'in açık/koyu görünümü var | Karar 4 |
| Ctrl'li kısayollar (Ctrl+C, Ctrl+U, Ctrl+Enter…), Del, Shift+Del, Alt+C, Menü tuşu | Mac'te ⌘, ⌫, ⌥ | Ctrl → ⌘, Del → ⌫, Shift+Del → ⌘⌫ (Finder'daki "Çöp Sepeti'ne taşı"), Alt → ⌥, Menü tuşu → sağ tık / ⌃tık. **Ctrl+P (Ekrana sabitle)** macOS'te ⌘P = Yazdır ile çakışır; öneri ⇧⌘P. |
| Print Screen'li varsayılan kısayollar | Mac klavyelerinde Print Screen yok | Karar 8 |
| Kısayol metni "Ctrl + Shift + Print Screen" | Mac'te glif biçimi | "⌃⌥⇧⌘" + tuş (ör. "⌥⇧⌘4"); kısayol tablosu ve İş akışları menüsü de böyle |
| Kısayol kaydında Esc kısayolu **boşaltır** | Mac'te Esc iptal demektir (bugünkü Mac: Esc iptal, Sil kaldırır) | Mac davranışı kalır; ipucu metni bunu söyler |
| Son bağlantılar: **sol tık kopyalar, sağ tık açar** | `NSMenuItem` sağ tıkı ayırt etmez | Tık kopyalar; ⌥ basılıyken aynı satır "aç" olur (`isAlternate`). İpucu satırının metni buna göre (§3.2) |
| Görev çubuğu ilerlemesi | Görev çubuğu yok | Dock simgesinde ilerleme |
| Beyaz tepsi simgesi | Menü çubuğu simgesi şablondur, açık/koyuya kendisi uyar | Seçenek gösterilmez |
| Dil menüsü (25 dil) | Mac'te yalnızca Türkçe ve İngilizce var; macOS'in uygulama başına dil ayarı var | **Dil:** yalnızca Otomatik / English / Türkçe (`AppleLanguages` + yeniden başlatma sorusu) |
| Tam ekran = bütün ekranlar tek resim | `screencapture` her ekranı ayrı dosyaya yazar | Her `SCDisplay` `SCScreenshotManager` ile yakalanıp tek tuvalde birleştirilir |
| Windows OCR, FFmpeg, DirectShow | — | Vision, AVFoundation / VideoToolbox (§6, §7) |
| Hakkında: "ShareX programını temel alır", .NET kütüphaneleri, çevirmenler | Mac uygulaması ShareX kodu içermiyor; Json.NET, ImageListView, FFmpeg, ZXing kullanılmıyor | Aynı düzen, doğru metin (karar 16) |
| Uygulamadan çıkış yalnızca tepside "Çıkış" | macOS'te uygulama menüsünde "UpLa'dan Çık ⌘Q" zorunlu | İkisi de: menü çubuğu menüsünde **Çıkış**, uygulama menüsünde **UpLa'dan Çık** |
| "Would you like to open this file?" gibi çevrilmemiş metinler | — | Karar 6 |

### 3.2 Metin uyarlamaları (yalnızca platform sözcükleri)

| Windows metni | Mac'te önerilen metin |
|---|---|
| UpLa sistem tepsisine küçültüldü. | UpLa menü çubuğunda çalışmaya devam ediyor. |
| Bildirim alanında simge göster | Menü çubuğunda simge göster |
| Başlangıçta simge durumuna küçült | Açılışta pencereyi gösterme |
| Tepsi simgesinde durum göster | Menü çubuğu simgesinde durum göster |
| Görev çubuğu tuşunda durum göster | Dock simgesinde durum göster |
| Tepsi simgesi bir kere / çift / orta tuş ile tıklandığında: | Menü çubuğu simgesine bir kere / çift / orta tuş ile tıklandığında: |
| Tepsi menüsünü aç/kapat | Menü çubuğu menüsünü aç/kapat |
| Tepsi menüsünde son görevleri göster / ilk göster | Menü çubuğu menüsünde son görevleri göster / ilk göster |
| Adresi kopyalamak için sol tıklayın. Adresi açmak için sağ tıklayın. | Adresi kopyalamak için tıklayın. Adresi açmak için ⌥ ile tıklayın. |
| Windows başladığında UpLa'yı çalıştır | Oturum açıldığında UpLa'yı çalıştır |
| "UpLa ile yükle" tuşunu Windows sağ tık menüsünde göster | "UpLa ile yükle"yi Finder'ın Hızlı İşlemler menüsünde göster |
| "UpLa ile düzenle" tuşunu Windows sağ tık menüsünde göster | "UpLa ile düzenle"yi Finder'ın Hızlı İşlemler menüsünde göster |
| "Gönder" menüsünde UpLa göster | Paylaş menüsünde UpLa göster |
| Windows yazdırma penceresini gösterme | Sistem yazdırma penceresini gösterme |
| Show file in explorer (yalnızca İngilizce) | Show file in Finder (Türkçe "Dosyayı klasörde göster" aynı kalır) |
| Antivirüs yazılımınız veya Windows'daki kontrollü klasör erişimi özelliği UpLa'yı engelliyor olabilir. | Klasöre yazma izni yok olabilir; Sistem Ayarları › Gizlilik ve Güvenlik'i kontrol edin. |
| Ctrl + Print Screen gibi kısayol metinleri | ⌥⇧⌘3 gibi glifler |
| "bu bilgisayar" geçen hesap metinleri | Aynı kalır (karar 6d); bugünkü Mac "bu Mac" der |

---

## 4. Parite matrisi

**Sütunlar.**
- **Mac bugün:** **var** (aynısı ya da yalnızca metin farkı) · **kısmen** · **yok** · **—** (Windows'a özgü veya işlevsiz).
- **Plan:** **Aşama N** · **macOS karşılığı (Aşama N)** · **Yalnızca Windows:** neden · **Gösterilmez:** neden · **—** (iş yok).
- **Efor:** S / M / L; iş yoksa "—". Bir menü öğesinin eforu, işi başka bir satırda (ör. aracın kendisinde) yapılıyorsa "S (araçla)" yazılır.

**Matris özeti** (412 satır; 4.24'teki 13 Mac'e özgü öğe hariç):

| Bölüm | Satır | var | kısmen | yok | — |
|---|---|---|---|---|---|
| 4.1 Ana pencere ve sol panel | 23 | 0 | 10 | 13 | 0 |
| 4.2 Yakala | 12 | 1 | 2 | 9 | 0 |
| 4.3 Yükle | 5 | 2 | 1 | 2 | 0 |
| 4.4 Araçlar | 11 | 0 | 0 | 11 | 0 |
| 4.5 Yakalama sonrası | 22 | 2 | 1 | 17 | 2 |
| 4.6 Yükleme sonrası | 5 | 0 | 1 | 4 | 0 |
| 4.7 Hedefler | 5 | 0 | 0 | 4 | 1 |
| 4.8 Hesap menüsü | 12 | 8 | 2 | 0 | 1 (+1 Mac'e özgü) |
| 4.9 Hata ayıklama ve Hakkında | 10 | 0 | 2 | 6 | 2 |
| 4.10 Görev alanı | 14 | 0 | 1 | 13 | 0 |
| 4.11 Görev sağ tık menüsü | 26 | 0 | 6 | 18 | 2 |
| 4.12 Sürükle bırak | 4 | 0 | 1 | 2 | 1 |
| 4.13 Menü çubuğu simgesi | 13 | 2 | 5 | 5 | 1 |
| 4.14 Kısayollar ve görev türleri | 45 | 2 | 10 | 32 | 1 |
| 4.15 Görev pencereleri | 10 | 0 | 0 | 10 | 0 |
| 4.16 Bildirimler ve iletişim kutuları | 17 | 3 | 4 | 9 | 1 |
| 4.17 Ekran kaydı | 23 | 3 | 4 | 11 | 5 |
| 4.18 Uygulama ayarları | 51 | 4 | 5 | 36 | 6 |
| 4.19 Görev ayarları | 52 | 1 | 1 | 44 | 6 |
| 4.20 Kısayol ayarları | 9 | 0 | 4 | 5 | 0 |
| 4.21 Hedef ayarları ve giriş | 12 | 9 | 1 | 2 | 0 |
| 4.22 Geçmiş pencereleri | 15 | 1 | 4 | 10 | 0 |
| 4.23 Bölge ekranı ve düzenleyici | 16 | 0 | 0 | 16 | 0 |
| **Toplam** | **412** | **38** | **65** | **279** | **29** (+1) |

Aşamalara göre: Aşama 1 → 124 satır, Aşama 2 → 143, Aşama 3 → 31, Aşama 4 → 52, Aşama 5 → 17; zaten var, iş yok → 16; yalnızca Windows → 13; gösterilmez → 11; karara bağlı veya isteğe bağlı → 5.

### 4.1 Ana pencere: çerçeve ve sol panel

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| Ana pencere ("UpLa 2.0.2", 879×531, ortada) | yok | Aşama 1 | L | `NSWindow` + AppKit (§2.1). Mac bugün yalnızca menü çubuğunda |
| Başlıkta yükleme yüzdesi | yok | Aşama 1 | S | |
| Koyu "Dark" tema, Segoe UI | yok | Aşama 1 | M | Karar 4; sistem yazı tipi |
| Kapat / Esc → gizle, ilk seferde bilgi | yok | Aşama 1 | S | §3.2'deki metin |
| Ana pencereden yakalarken pencereyi gizleme | yok | Aşama 1 | S | `orderOut` → yakalama → `orderFront` |
| 1 **Yakala** ▸ | kısmen | Aşama 1 | M | Bugün menüde düz "Bölge Yakala", "Pencere Yakala", "Tam Ekranı Yakala" |
| 2 **Yükle** ▸ | kısmen | Aşama 1 | S | Bugün "Dosya Yükle…", "Panodan Yükle" düz öğeler |
| 3 **Araçlar** ▸ | yok | Aşama 1 (menü), Aşama 3 (araçlar) | — | Menü, araçlar geldikçe dolar (karar 10) |
| 4 **Yakalama sonrası** ▸ | kısmen | Aşama 1 | M | Bugün Ayarlar › Yakalama'da 3 anahtar |
| 5 **Yükleme sonrası** ▸ | yok | Aşama 1 | S | Bugün link her zaman kopyalanıyor |
| 6 **Hedefler** ▸ | yok | Aşama 1 | S | Tek hedef; sabit menü |
| 7 **Uygulama ayarları...** | kısmen | Aşama 1 (iskelet), Aşama 2 (tam) | L | Bugün "Ayarlar…" (6 sekme) |
| 8 **Görev ayarları...** | yok | Aşama 1 (iskelet), Aşama 2 | L | |
| 9 **Kısayol ayarları...** | kısmen | Aşama 2 | L | Bugün Ayarlar › Kısayollar, 4 sabit kısayol |
| 10 **Hedef ayarları...** | kısmen | Aşama 1 | M | Bugün Ayarlar › upla.com.tr + Hesap sekmeleri |
| 11 **Giriş yap** ▸ (hesap) | kısmen | Aşama 1 | S | Bugün "upla.com.tr Hesabı ▸"; düğme metni kullanıcı adına dönüşmüyor |
| 12 **Ekran görüntüsü dizini...** | kısmen | Aşama 1 | S | Bugün yalnızca Ayarlar'da "Finder'da Göster"; o ayın klasörü yoksa üst klasör açılır |
| 13 **Geçmiş...** | kısmen | Aşama 1 (yer ve ad), Aşama 2 (Windows düzeni) | M | Bugün "Son Yüklemeler ▸ Geçmişi Göster…" |
| 14 **Resim geçmişi...** | yok | Aşama 2 | M | |
| 15 **Hata ayıklama** ▸ | yok | Aşama 2 | M | |
| 16 **Hakkında...** | kısmen | Aşama 1 | S | Bugün "UpLa Hakkında", basit pencere |
| Menüyü göster (sol paneli gizleme) | yok | Aşama 2 | S | |
| Politikayla yüklemeyi kapatma (`DisableUpload`) | yok | macOS karşılığı (isteğe bağlı) | S | Yönetilen tercihler (MDM / `defaults`) |

### 4.2 Yakala ▸

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| **Tam ekran** | kısmen | Aşama 1 | M | Bugün yalnızca ana ekran (`screencapture -m`). Bütün ekranlar tek resim: her `SCDisplay` için `SCScreenshotManager.captureImage`, tek tuvalde birleştirme (farklı ölçekli ekranlara dikkat) |
| **Pencere** ▸ (pencere listesi) | yok | Aşama 1 | M | `SCShareableContent.current.windows` (başlık + `NSRunningApplication.icon`, 50 karakterde "..."); yakalama `SCContentFilter(desktopIndependentWindow:)` veya `screencapture -l <windowID>`. Bugünkü macOS pencere seçimi kısayol olarak kalabilir (karar 8) |
| **Monitör** ▸ | yok | Aşama 1 | S | `NSScreen` / `SCDisplay`; "1. 2560x1600" (piksel) |
| **Bölge** | var | Aşama 1 (aynı kalır), Aşama 4 (kendi ekranı) | — | Bugün `screencapture -i` (macOS seçimi); Windows'taki bölge ekranı Aşama 4 |
| **Bölge (Basit)** | yok | Aşama 4 | M | Kendi seçim katmanı; kayıttaki `RegionSelector` temel alınabilir |
| **Bölge (Saydam)** | yok | Aşama 4 | M | Donmuş görüntü yerine canlı ekran üstünde saydam katman |
| **Son bölge** | yok | Aşama 4 | S | `screencapture -i` seçilen alanı bildirmez; kendi katmanla alan saklanır, sonra `screencapture -R x,y,w,h` / `SCScreenshotManager` |
| **Ekran kaydetme** | kısmen | Aşama 1 | S | Bugün "Bölge Kaydet…" (sürükle = bölge, tık = tam ekran); ad ve yer değişir. Pencere ve tam ekran kaydı için §4.24 |
| **Ekran kaydetme (GIF)** | yok | Aşama 4 | M | ScreenCaptureKit kareleri → ImageIO `CGImageDestination` (GIF), 15 FPS |
| **Kaydırarak yakalama...** | yok | Aşama 4 | L | Erişilebilirlik izni + `CGEvent` kaydırma olayları + Vision `VNTranslationalImageRegistrationRequest` ile parçaları birleştirme |
| **İmleç göster** | yok | Aşama 1 | S | `screencapture -C` (yalnızca etkileşimsiz yakalamada) / `SCStreamConfiguration.showsCursor` |
| **Ekran görüntüsü gecikmesi: 0sn** ▸ (Gecikme yok, 1–5 saniye) | yok | Aşama 1 | S | `screencapture -T <sn>` veya bekleme; menü metni "{0}sn" |

### 4.3 Yükle ▸

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| **Dosya yükle...** | var | Aşama 1 (metin) | S | Başlık "UpLa - Dosya yükle"; son klasörü hatırlar, yoksa Masaüstü |
| **Klasör yükle...** | yok | Aşama 1 | S | `NSOpenPanel` (klasör) + alt klasör taraması; başlık "UpLa - Dizin yükle" |
| **Sürükle bırak ile yükle...** | kısmen | Aşama 2 | S | Bugün yalnızca simgeye bırakma; bırakma penceresi `NSPanel` (§4.15) |
| **Panodan yükle...** (tepsi) | var | Aşama 1 (metin), Aşama 2 (Pano içeriği penceresi) | S | |
| **Adresden indirip yükle...** (tepsi) | yok | Aşama 2 | S | Giriş kutusu (panodaki adresle dolu) + `URLSession` indirme |

### 4.4 Araçlar ▸

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| **Renk seçici...** | yok | Aşama 3 | M | Windows düzeninde özel pencere (HSB/RGB/Alfa/Hex/CMYK/İsim, Eski/Yeni, Standart/Son renkler, kopyalama menüsü); `NSColorPanel` birebir değil |
| **Ekrandan renk seçici...** | yok | Aşama 3 | S | `NSColorSampler` (sistemin büyüteci); Windows'taki bilgi yazısı ve ⌘+tık biçimi için kendi katman gerekir (M) |
| **Cetvel...** | yok | Aşama 3 | M | Tam ekran saydam `NSPanel`; dikdörtgen + ölçüler |
| **Ekrana sabitle...** | yok | Aşama 3 | M | Kenarsız `NSPanel` (`.floating`, `.canJoinAllSpaces`); sürükle, yakınlaştır, saydamlık; Ekrandan / Panodan / Dosyadan |
| **Resim düzenleyici...** | yok | Aşama 5 | L | §4.23 |
| **Resim güzelleştirici...** | yok | Aşama 3 | M | Core Graphics: kenar boşluğu, dolgu, akıllı dolgu, yuvarlak köşe, gölge, arka plan |
| **Resim efektleri...** | yok | Aşama 3 (pencere + temel efektler), Aşama 5 (tamamı) | L | Core Image (`CIFilter`) karşılıkları; 51 efekt (envanter §13.8) |
| **Resim görüntüleyici...** | yok | Aşama 3 | S | `NSImageView` penceresi, ‹ › aynı klasör; Aşama 1'de geçici olarak Quick Look (`QLPreviewPanel`) |
| **Resim birleştirici...** | yok | Aşama 3 | M | Core Graphics; yön, hiza, boşluk, sarma, arka plan |
| **OCR...** | yok | Aşama 3 | M | Vision `VNRecognizeTextRequest`; Türkçe desteği Mac'te doğrulanmalı (`supportedRecognitionLanguages()`); servis linkleri aynı |
| **QR kod...** | yok | Aşama 3 | S | Üretme `CIFilter.qrCodeGenerator()`, tarama `VNDetectBarcodesRequest` |

### 4.5 Yakalama sonrası ▸ (20 görev)

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| 1 Hızlı görev menüsünü göster | yok | Aşama 2 | M | `NSMenu.popUp` imleç konumunda + düzenleyici (§4.15) |
| 2 "Yakalama sonrası" penceresini göster | yok | Aşama 2 | M | §4.15 |
| 3 Resmi güzelleştir | yok | Aşama 3 | S (araçla) | |
| 4 Resim efekti ekle ▸ | yok | Aşama 3 | S (araçla) | Alt menü ön ayarlar (radyo) |
| 5 Resim düzenleyicide aç | yok | Aşama 5 | S (araçla) | |
| 6 Resimi panoya kopyala ✓ | var | Aşama 1 | S | Bugün varsayılan kapalı; Windows'ta açık (karar 9) |
| 7 Ekrana sabitle | yok | Aşama 3 | S (araçla) | |
| 8 Resimi yazdır | yok | Aşama 2 | S | `NSPrintOperation(view: NSImageView)` |
| 9 Resimi dosya olarak kaydet ✓ | kısmen | Aşama 1 | S | Bugün "Bir klasöre kaydet" ☐, `~/Pictures/UpLa`, ad `UpLa_tarih`; Windows ✓, `Screenshots/%y-%mo`, `%ra{10}` (karar 9) |
| 10 Resimi dosya olarak farklı kaydet... | yok | Aşama 1 | S | `NSSavePanel` |
| 11 Aksiyonları gerçekleştir | yok | Aşama 4 | M | `Process` / `NSWorkspace.open(_:withApplicationAt:)` |
| 12 Dosyayı panoya kopyala | yok | Aşama 1 | S | `NSPasteboard.writeObjects([url as NSURL])` |
| 13 Dosya yolunu panoya kopyala | yok | Aşama 1 | S | |
| 14 Klasör yolunu panoya kopyala | yok | Aşama 1 | S | 12–14'ten yalnızca ilk geçerli olan |
| 15 Dosyayı klasörde göster | yok | Aşama 1 | S | `NSWorkspace.activateFileViewerSelecting` |
| 16 QR kodunu tara | yok | Aşama 3 | S (araçla) | |
| 17 Yazı tanı (OCR) | yok | Aşama 3 | S (araçla) | Sessiz değilse OCR penceresi + yanına `.txt` |
| 18 "Yükleme öncesi" penceresini göster | yok | Aşama 2 | S | §4.15 |
| 19 Resimi yükle ✓ | var | Aşama 1 | S | Bugün "upla.com.tr'ye yükle ve linki kopyala"; iki bayrağa ayrılır (§2.6) |
| 20 Dosyayı sil | yok | Aşama 1 | S | Yüklemeden sonra yerel dosyayı siler |
| Onay işaretlerinin gerçek bayrakları göstermesi | — | Aşama 1 | S | Windows hatası (envanter §12.1) kopyalanmaz |
| Menünün tıklayınca açık kalması | — | Aşama 1 (karar 11) | M | `NSMenuItem.view` ile özel satır |

### 4.6 Yükleme sonrası ▸ (5 görev)

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| 1 "Yükleme sonrası" penceresini göster | yok | Aşama 2 | M | §4.15 |
| 2 Adresi paylaş | yok | Aşama 2 | S | Facebook, Reddit, Pinterest, Tumblr, LinkedIn, VK paylaşım adresleri (Windows'takilerle aynı), `NSWorkspace.open` |
| 3 Adresi panoya kopyala ✓ | kısmen | Aşama 1 | S | Bugün her zaman kopyalanır, kapatılamaz |
| 4 Adresi aç | yok | Aşama 1 | S | `NSWorkspace.open` |
| 5 QR kod penceresini göster | yok | Aşama 3 | S (araçla) | |

### 4.7 Hedefler ▸

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| **Resim yükleyici: upla.com.tr** ▸ (upla.com.tr ✓; Dosya yükleyici ▸ upla.com.tr) | yok | Aşama 1 | S | Tek hedef; radyo öğeleri. "Dosya yükleyici" seçimi aynı sunucuya dosya API'siyle gider |
| **Metin yükleyici: upla.com.tr** ▸ (tepsi) | yok | Aşama 1 | S | Metin yine bilgisayarda reddedilir |
| **Dosya yükleyici: upla.com.tr** ▸ (tepsi) | yok | Aşama 1 | S | |
| **Adres paylaşım servisi: Facebook** ▸ (6 servis; tepsi) | yok | Aşama 2 | S | Adresi paylaş ile birlikte |
| Ayarı geçersiz hedefi kırmızı gösterme | — | Gösterilmez: upla.com.tr'de hiç olmaz | — | |

### 4.8 Hesap menüsü

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| Ana penceredeki düğme metni: **Giriş yap** / kullanıcı adı / "… (tekrar giriş yapın)" | kısmen | Aşama 1 | S | Bugün başlık hep "upla.com.tr Hesabı" |
| Tepsideki başlık: **upla.com.tr hesabı** / "upla.com.tr hesabı: <ad>" / "… (tekrar giriş yapın)" | kısmen | Aşama 1 | S | Bugün "upla.com.tr Hesabı" ve "(tekrar giriş yapın)" |
| **Giriş yap...** | var | Aşama 1 (metin) | S | "Giriş Yap…" → "Giriş yap..." (karar 6) |
| **Hesap oluştur** | var | Aşama 1 (metin) | S | |
| **Profilim** | var | — | — | |
| **Bağlı cihazlar** | var | Aşama 1 (metin) | S | |
| **Çıkış yap** (soru + sunucu hatası sorusu) | var | Aşama 1 (metin) | S | "bu Mac" → "bu bilgisayar" (karar 6d) |
| **Tekrar giriş yap...** | var | Aşama 1 (metin) | S | |
| **Misafir olarak devam et** | var | — | — | |
| **Kötüye kullanımı bildir** | var | — | — | |
| Ayarlar yüklenirken devre dışı "Giriş yap..." | — | Gösterilmez: Mac'te ayarlar eşzamanlı yüklenir | — | |
| (Mac'e özgü) "Giriş yapıldı: …" satırı, "Elle girilen API anahtarı kullanılıyor", "Anahtarı Kaldır…" | Mac'te var | Aşama 1: kaldırılır | S | Elle girilen anahtar Hedef ayarları'ndaki **Çıkış yap** ile kaldırılır (Windows'taki gibi) |

### 4.9 Hata ayıklama ▸ ve Hakkında

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| **Hata ayıklama kütüğü...** penceresi (canlı kütük, Başlama yolu) | yok | Aşama 2 | M | Uygulama içi kütük arabelleği + dosya `~/Library/Logs/UpLa/UpLa-Log-yyyy-MM.txt`; `os.Logger`'a da yazılır |
| — **Hepsini kopyala** | yok | Aşama 2 | S | |
| — **Kütük dosyasını aç...** | yok | Aşama 2 | S | |
| — **Yüklenen kütüphaneler** | — | Yalnızca Windows: .NET derlemelerini listeler | — | |
| — **Kütüğü karşıya yükle...** | — | Gösterilmez: upla.com.tr metin kabul etmiyor (Windows'ta da çalışmıyor) | — | |
| **Resim yükleme testi** | yok | Aşama 2 | S | UpLa logosu PNG'si; yükleme sonrası görevler uygulanır |
| Hakkında: düzen (sol 400×600 logo paneli, başlık, güncelleme satırı, zengin metin) | kısmen | Aşama 1 | M | Bugün 420 genişliğinde basit pencere |
| Hakkında: güncelleme satırı | yok | Aşama 2 | M | Sparkle 2 (PLAN.md M5) |
| Hakkında: metin ve linkler | kısmen | Aşama 1 | S | Mac'e uyarlanmış metin (karar 16) |
| Hakkında: logo animasyonu ve gizli sürpriz | yok | Aşama 5 (isteğe bağlı) | S | |

### 4.10 Görev alanı

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| Boşken kısayol tablosu (**Kısayol tuşu** / **Açıklama**, yeşil/kırmızı şerit) | yok | Aşama 1 | S | Çift tık Kısayol ayarları'nı açar |
| Küçük resim görünümü (varsayılan) | yok | Aşama 1 | L | `NSCollectionView` |
| — Başlık üstte; tıklayınca adres, yoksa dosya | yok | Aşama 1 | S | |
| — Durum çizgisi, ilerleme çubuğu, "Hata" rozeti | yok | Aşama 1 | S | |
| — Küçük resme tıklama: resim görüntüleyici | yok | Aşama 1 (Quick Look), Aşama 3 (kendi görüntüleyici) | S | |
| — Video küçük resmi + Oynat simgesi | yok | Aşama 1 | S | `QLThumbnailGenerator` / `AVAssetImageGenerator` |
| — Resmi resim kutucuğuna bırakma: Resimleri birleştir (Yatay/Dikey) | yok | Aşama 3 | S | |
| Liste görünümü (7 sütun, durum simgeleri, genişlikler hatırlanır) | yok | Aşama 1 | M | `NSTableView` |
| Önizleme bölmesi (Kenar/Alt, damalı arka plan, G x Y, Resim kopyala) | yok | Aşama 2 | M | |
| Liste ↔ küçük resim geçişi | yok | Aşama 1 | S | |
| Açılışta son 10 görevin "Geçmiş" olarak gelmesi | kısmen | Aşama 1 | S | Bugün yalnızca "Son Yüklemeler" menüsünde |
| Seçim (⌘tık, ⇧tık, ⌘A) | yok | Aşama 1 | S | |
| Dışarı sürükleme (dosya; ⌥ ile adres metni) | yok | Aşama 1 | S | `NSPasteboardWriting` |
| Klavye kısayolları (Enter, ⌘↩, ⇧↩, ⌘C, ⇧⌘C …; §3.1 eşlemesiyle) | yok | Aşama 1 | S | ⌘V panodan yükler |

### 4.11 Görev sağ tık menüsü

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| **Hataları göster** ("UpLa - Hata": Yükleme hataları, Kütük dosyasını aç..., Tamam) | kısmen | Aşama 1 | S | Bugün hata yalnızca bildirimde |
| **Yüklemeyi durdur** | kısmen | Aşama 1 | S | Bugün yalnızca hepsini iptal eden "Yüklemeleri İptal Et" |
| **Aç** ▸ Adres, Küçük resim adresi, Silme adresi (onaylı), Dosya, Dizin | kısmen | Aşama 1 | S | Bugün Geçmiş'te "Aç" ve "Silme Sayfasını Aç…" |
| **Aç** ▸ Kısaltılmış adres, Küçük resim dosya | — | Gösterilmez: UpLa'da hep gri (karar 7) | — | |
| **Kopyala** ▸ Adres, Küçük resim adresi, Silme adresi | kısmen | Aşama 1 | S | Bugün yalnızca "Linki Kopyala" |
| **Kopyala** ▸ Dosya, Resim, Resim boyutları, Yazı | yok | Aşama 1 | S | |
| **Kopyala** ▸ HTML / Forum (BBCode) / Markdown (9 biçim) | yok | Aşama 1 | S | Resim biçimleri yalnızca "Doğrudan dosya linki"yle etkin |
| **Kopyala** ▸ Dosya yolu, Dosya adı, Dosya adı uzantısıyla birlikte, Klasör | yok | Aşama 1 | S | |
| **Kopyala** ▸ özel pano biçimleri | yok | Aşama 2 | S | Uygulama ayarları › Pano biçimleri |
| **Kopyala** ▸ Kısaltılmış adres, Küçük resim dosya, Küçük resim | — | Gösterilmez: hep gri (karar 7) | — | |
| **Yükle** (⌘U) | yok | Aşama 1 | S | |
| **İndir** (⌘D) | yok | Aşama 2 | S | |
| **Resim düzenle...** (⌘E) | yok | Aşama 5 | S (araçla) | |
| **Resmi güzelleştir...** | yok | Aşama 3 | S (araçla) | |
| **Resim efekti ekle...** | yok | Aşama 3 | S (araçla) | |
| **Ekrana sabitle** | yok | Aşama 3 | S (araçla) | Kısayol ⇧⌘P (§3.1) |
| **Aksiyon çalıştır** ▸ | yok | Aşama 4 | S | |
| **Listeden sil** (⌫) | kısmen | Aşama 1 | S | Bugün Geçmiş'te "Geçmişten Kaldır" |
| **Yerel dosya sil...** (⌘⌫) | yok | Aşama 1 | S | Soru + `FileManager.trashItem` (Çöp Sepeti) |
| **Adresi paylaş** ▸ | yok | Aşama 2 | S | |
| **QR kod göster...** | yok | Aşama 3 | S (araçla) | |
| **Resimden yazı yakala (OCR)...** | yok | Aşama 3 | S (araçla) | |
| **Resimleri birleştir...** ▸ (Yatay / Dikey) | yok | Aşama 3 | S (araçla) | |
| **Yanıtı göster...** ("UpLa - Yanıt", 4 sekme) | yok | Aşama 2 | M | "İnternet tarayıcı" sekmesi `WKWebView` |
| **Listeyi temizle** | kısmen | Aşama 1 | S | Bugünkü "Geçmişi Temizle…" başka bir iş (§4.24) |
| **Liste / Küçük resim görünümüne geç** | yok | Aşama 1 | S | |

### 4.12 Sürükle bırak

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| Ana pencereye dosya ve klasör bırakma | kısmen | Aşama 1 | S | Bugün yalnızca menü çubuğu simgesine dosya |
| Ana pencereye resim verisi bırakma (yakalama gibi işlenir) | yok | Aşama 1 | S | |
| Ana pencereye metin bırakma | — | Aşama 1: kabul edilmez | — | Windows'ta da upla.com.tr reddediyor |
| Bırakma penceresi ("Buraya sürükle") | yok | Aşama 2 | S | §4.15 |

### 4.13 Menü çubuğu simgesi (tepsi)

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| Simge: UpLa logosu | kısmen | Aşama 1 | S | Bugün SF Symbol `arrow.up.circle`; logo şablon görüntü olarak |
| İpucu "UpLa" | var | — | — | |
| İlerleme simgesi (alttan dolan kare + yüzde) | kısmen | Aşama 1 | S | Bugün " 45%" metni |
| Sol / çift / orta tık eylemleri | yok | Aşama 2 | M | Bugün her tık menüyü açar (karar 3) |
| Menü öğelerinin sırası (25 öğe) | kısmen | Aşama 1 | M | |
| **İş akışları** ▸ | yok | Aşama 1 (5 kısayol), Aşama 2 (kısayol listesinden) | S | |
| **Kısayolları devre dışı bırak** / **Kısayolları aktif et** | yok | Aşama 1 | S | `HotKeyCenter` bütün kayıtları kaldırır / geri yükler; tost |
| **Son bağlantılar** ▸ (ipucu satırı, `[HH:mm:ss] link`) | kısmen | Aşama 1 | S | Bugün "Son Yüklemeler ▸" dosya adlarıyla; sağ tık için §3.1 |
| **Aksiyonlar araç çubuğunu göster/sakla** | yok | Aşama 2 | M | §4.15 |
| **UpLa penceresini göster** | yok | Aşama 1 | S | |
| **Çıkış** | var | Aşama 1 (metin) | S | Bugün "UpLa'dan Çık"; uygulama menüsünde o ad kalır |
| Kayıt sürerken çıkış sorusu | kısmen | Aşama 1 | S | Bugün Mac kaydı bitirip saklayarak çıkar; Windows sorar, "Evet" kaydı bitirir ama çıkmaz |
| **UpLa'yı yönetici olarak yeniden başlat** | — | Yalnızca Windows: UAC (zaten gizli) | — | |

### 4.14 Kısayollar ve görev türleri

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| 5 varsayılan kısayol | kısmen | Aşama 1 | S | Mac'te 4: ⌥⇧⌘3 tam ekran, ⌥⇧⌘4 bölge, ⌥⇧⌘5 pencere (macOS seçimi), ⌥⇧⌘6 kayıt. Eksik: aktif pencere, GIF kaydı (karar 8) |
| Kısayol metni ("Ctrl + Print Screen") | — | macOS karşılığı | — | Glif biçimi ("⌥⇧⌘4"); Carbon `RegisterEventHotKey` (bugünkü) her birleşimi kaydedebilir |
| Basılı tutunca yineleme sınırı (500 ms) | yok | Aşama 2 | S | |
| Tam ekranda kısayolları kapatma (`DisableHotkeysOnFullscreen`) | yok | Aşama 4 | M | Ön plandaki pencere ekranı kaplıyor mu: `CGWindowListCopyWindowInfo` |

Görev türleri kısayol listesinde (Aşama 2), tepsi tıklama listelerinde ve İş akışları menüsünde kullanılır. Aşağıdaki "Plan", türün Mac'te çalışır hâle geleceği aşamadır.

| Görev türü | Mac bugün | Plan | Not |
|---|---|---|---|
| **Yükle** › Dosya yükle | kısmen (menüde) | Aşama 2 | |
| Dizin yükle | yok | Aşama 2 | Menüde Aşama 1 |
| Panodan yükle | kısmen (menüde) | Aşama 2 | |
| İçerik gösterici ile panodan yükle | yok | Aşama 2 | Tepsi orta tık varsayılanı |
| Adresten yükle | yok | Aşama 2 | |
| Sürükle bırak ile yükle | yok | Aşama 2 | |
| Tüm aktif yüklemeleri durdur | kısmen (menüde "Yüklemeleri İptal Et") | Aşama 2 | |
| **Ekran yakalama** › Tüm ekranı yakala | kısmen (⌥⇧⌘3, yalnızca ana ekran) | Aşama 1 | Bütün ekranlar |
| Aktif pencereyi yakala | yok | Aşama 1 | Ön plandaki uygulamanın en üstteki penceresi (`CGWindowList`, katman 0) |
| Önceden yapılandırılmış pencereyi yakala | yok | Aşama 2 | Başlık eşleşmesi |
| Aktif ekranı yakala | yok | Aşama 1 | İmlecin olduğu ekran |
| Bölge yakala | var (⌥⇧⌘4) | — | Aşama 4'te kendi ekranı |
| Bölge yakala (Basit) | yok | Aşama 4 | |
| Bölge yakala (Saydam) | yok | Aşama 4 | |
| Özel bölge yakala | yok | Aşama 2 | `screencapture -R` |
| Son bölgeyi yakala | yok | Aşama 4 | |
| Kaydırarak yakalamayı başlat/durdur | yok | Aşama 4 | |
| **Ekran kaydetme** › Ekran kaydetme başlat/durdur | var (⌥⇧⌘6) | — | |
| Aktif pencere alanıyla ekran kaydetme başlat | kısmen ("Pencere Kaydet…" sistem seçicisi) | Aşama 2 | Seçicisiz, ön plandaki pencere |
| Özel alan ile ekran kaydetme başlat | yok | Aşama 2 | Görev ayarları › Yakalama › Önceden ayarlanmış bölge |
| Son bölgeyi kullanarak ekran kaydet | yok | Aşama 4 | |
| Ekran kaydetme (GIF) başlat/durdur | yok | Aşama 4 | |
| Aktif pencere alanıyla ekran kaydetme (GIF) başlat | yok | Aşama 4 | |
| Özel alan ile ekran kaydetme (GIF) başlat | yok | Aşama 4 | |
| Son bölgeyi kullanarak ekran kaydet (GIF) | yok | Aşama 4 | |
| Ekran kaydını durdur | kısmen (menüde "Kaydı Durdur") | Aşama 2 | |
| Ekran kaydını duraklat | yok | Aşama 4 | |
| Ekran kaydetme iptal et | kısmen (menüde "Kaydı İptal Et") | Aşama 2 | |
| **Araçlar** › Renk seçici, Renk seçici ekranı, Cetvel | yok | Aşama 3 | |
| Ekrana sabitle, (Ekrandan), (Panodan), (Dosyadan), (Tümünü kapat) | yok | Aşama 3 | |
| Resim düzenleyici | yok | Aşama 5 | |
| Resim güzelleştirici, Resim efektleri, Resim görüntüleyici, Resim birleştirici | yok | Aşama 3 | |
| OCR, QR kod, QR kod (Ekrandan çöz), QR kodu (Bölge tara) | yok | Aşama 3 | |
| **Diğer** › Devre dışı bırak/Aktif et kısayolları | yok | Aşama 1 | |
| Ana pencereyi aç | yok | Aşama 1 | Tepsi çift tık varsayılanı |
| Ekran görüntüleri dizinini aç | yok | Aşama 1 | |
| Geçmiş penceresini aç | kısmen (menüde) | Aşama 2 | |
| Resim geçmişi penceresini aç | yok | Aşama 2 | |
| Aksiyonlar araç çubuğunu göster/sakla | yok | Aşama 2 | |
| Tepsi menüsünü aç/kapat | yok | Aşama 2 | `statusItem.button?.performClick(nil)`; metin §3.2 |
| UpLa'yı kapat | kısmen (menüde) | Aşama 2 | |

### 4.15 Görev pencereleri ve küçük pencereler

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| "UpLa - Yakalama sonrası görevler" (3 sekme, Dosya ismi:, Devam / Kopyala / İptal, önizleme) | yok | Aşama 2 | M | Ekran kayıtlarında da açılır |
| "UpLa - Dinamik hedefler" (Yükleme öncesi) | yok | Aşama 2 | S | Tek radyo düğmesi (Windows'taki çift "upla.com.tr" kopyalanmaz) |
| "Yükleme sonrası" penceresi (önizleme, biçim listesi, 6 düğme) | yok | Aşama 2 | M | Windows'taki "yalnızca tostla açılır" tuhaflığı kopyalanmaz |
| Hızlı görev menüsü | yok | Aşama 2 | M | Ön ayar adları İngilizce (karar 6b) |
| Hızlı görev menüsü düzenleyici + öğe düzenleme | yok | Aşama 2 | M | Bit eşlemesi doğru |
| Pano içeriği penceresi | yok | Aşama 2 | S | `NSPasteboard` türleri: resim, metin, dosya |
| Bırakma penceresi ("Buraya sürükle") | yok | Aşama 2 | S | `NSPanel` 150×150, her zaman üstte, sağ alt, saydamlık 100/255 → 255 |
| Aksiyonlar araç çubuğu (başlık menüsü: Kapat, Konumu kitle, En üstte dur, UpLa başlangıcında aç, Düzenle...) | yok | Aşama 2 | M | Yüzen `NSPanel` |
| "UpLa - Yanıt" penceresi | yok | Aşama 2 | M | §4.11 |
| "UpLa - Hata" penceresi | yok | Aşama 1 | S | §4.11 |

### 4.16 Bildirimler, sesler ve iletişim kutuları

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| Görev bitti tostu (resimli / metin; sağ alt; 3 sn + 1 sn solma; tık eylemleri; dışarı sürükleme) | kısmen | Aşama 2 | M | Bugün macOS bildirimi (tık linki açar). `NSPanel` (`.nonactivatingPanel`, `.floating`), `NSAnimationContext` ile solma (karar 12) |
| Hata tostu (5 sn, hata sesi) | kısmen | Aşama 2 | S | Bugün bildirim |
| upla.com.tr hata metinleri | var | Aşama 1 (metin denetimi) | S | Mac metinleri Windows'la neredeyse aynı; "bu Mac" farkları (karar 6d) |
| "UpLa sistem tepsisine küçültüldü." | yok | Aşama 1 | S | Metin §3.2 |
| "Kısayollar devre dışı kaldı." / "Kısayollar aktif edildi." | yok | Aşama 1 | S | |
| Kayıt yükleme sınırı tostları | var | Aşama 2 (tost biçimi) | S | Bugünkü metin ("Kayıt yükleme sınırında durduruldu (20 MB)") Windows metnine döner |
| "UpLa - Ayarlar kaydedilemedi" | yok | Aşama 2 | S | Metin §3.2 |
| Sesler: yakalama, görev, işlem, hata + kişisel ses dosyaları | yok | Aşama 2 | S | `NSSound`; ShareX'in ses dosyaları GPL ile yeniden kullanılabilir (karar 13) |
| İlk yükleme sorusu | kısmen | Aşama 1 | S | Bugün başka metin ve düğmeler ("Yüklemeye Devam Et" / "Otomatik Yüklemeyi Kapat"; kapatınca klasöre kaydetmeyi açar). Windows metni ve Evet / Hayır |
| 100 MB'tan büyük dosya uyarısı | yok | Aşama 1 | S | "Bu mesajı tekrar gösterme." kutulu `NSAlert` |
| 10'dan fazla dosya onayı | yok | Aşama 1 | S | Aynı |
| Pano erişim hatası sorusu | yok | Aşama 2 | S | |
| Silme linki onayı | var | — | — | Metin aynı |
| Yerel dosya silme onayı | yok | Aşama 1 | S | |
| Kısayol kaydı başarısız uyarısı | kısmen | Aşama 1 | S | Bugün yalnızca ayarlarda kırmızı yazı |
| Kaydı iptal onayı (seçenek açıksa) | yok | Aşama 4 | S | |
| Kütüğü karşıya yükleme sorusu | — | Gösterilmez (öğe yok) | — | |

### 4.17 Ekran kaydı

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| MP4 ekran kaydı ve yükleme | var | — | — | ScreenCaptureKit + `AVAssetWriter`, H.264 |
| Yükleme sınırında durma ve tostları | var | — | — | Aynı sınırlar (18 MiB / 95.000.000 bayt) |
| Bölge seçimi | kısmen | Aşama 4 | M | Bugün kendi katmanı (sürükle / tık); Windows'taki bölge ekranıyla birleşir |
| Kayıt çerçevesi (kesikli kenarlık; beklerken sarı, kayıtta yeşil) | yok | Aşama 4 | M | Kenarlık penceresi `SCContentFilter` ile kayıttan dışlanır |
| Kayıt çubuğu: **Başlat/Durdur**, **Duraklat/Devam et**, **İptal**, süre | yok | Aşama 4 | M | |
| Duraklatma | yok | Aşama 4 | M | `AVAssetWriter`'da zaman damgası kaydırma; duraklatılan süre sınıra sayılır |
| Otomatik başlat + gecikme (geri sayım), sabit süre | kısmen | Aşama 4 | S | Bugün hemen başlar |
| İkinci tepsi simgesi (sarı / kırmızı, ipuçları, sağ tık menüsü) | kısmen | Aşama 4 | S | Bugün menü çubuğunda kırmızı nokta + süre |
| "Kodlanıyor... NN%" | yok | Aşama 4 | S | GIF için |
| GIF kaydı (15 FPS) | yok | Aşama 4 | M | |
| FFmpeg indirme penceresi | — | Yalnızca Windows: Mac AVFoundation kullanır | — | |
| **Ekran kayıt FPS:** (1–60) | kısmen | Aşama 2 | S | Bugün 30 / 60 seçimi |
| **GIF FPS:** | yok | Aşama 4 | S | |
| **Ekran kaydında imleç göster** | var | — | — | |
| **Kaydetmeye başla: … saniye sonra**, **Sabit süre:** | yok | Aşama 4 | S | |
| **İlk kayıpsız kodlama kullanarak kayıt yap…** | — | Yalnızca Windows: FFmpeg'e özgü iki geçiş | — | |
| **Saydam alan seçici kullan** | yok | Aşama 4 | S | |
| **İptal ederken onay sor** | yok | Aşama 4 | S | |
| **Ekran kayıt ayarları...** penceresi | yok | macOS karşılığı (Aşama 4) | M | Mac sürümü: **Video kodlayıcı:** H.264 / HEVC / GIF; **Ses kaynağı:** Yok / Sistem sesi / Mikrofon; **Ses kodlayıcı:** AAC; **Bit hızı** |
| — Video kaynağı (gdigrab / ddagrab / dshow) | — | Yalnızca Windows | — | ScreenCaptureKit tek kaynak |
| — x265, VP8, VP9, NVENC, AMF, Quick Sync, WebP; Opus, Vorbis, MP3 | — | Yalnızca Windows (FFmpeg) | — | VideoToolbox H.264 / HEVC; upla.com.tr yalnızca mp4 / webm kabul ediyor |
| — Kayıt cihazlarını yükle..., Özel FFmpeg yolu, Ek komut satırı parametreleri, Özel komutları kullan, Seçenekleri sıfırla... | — | Yalnızca Windows (Seçenekleri sıfırla... Mac penceresinde kalır) | — | |
| — Mikrofon | yok | Aşama 4 | M | macOS 15: `SCStreamConfiguration.captureMicrophone`; 14: `AVCaptureSession` + `NSMicrophoneUsageDescription` |

### 4.18 Uygulama ayarları

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| Pencere ve 12 düğümlü ağaç | kısmen | Aşama 1 (iskelet) | M | Bugün "UpLa Ayarları" (sekmeli) |
| **Genel** › Dil: | yok | macOS karşılığı (Aşama 2) | S | Otomatik / English / Türkçe (§3.1) |
| Bildirim alanında simge göster | yok | Aşama 2 | S | "Menü çubuğunda simge göster"; kapalıyken Dock simgesi açık olmalı |
| Başlangıçta simge durumuna küçült | yok | Aşama 2 | S | "Açılışta pencereyi gösterme" |
| Tepsi simgesinde durum göster | var (her zaman) | Aşama 2 | S | |
| Görev çubuğu tuşunda durum göster | yok | macOS karşılığı (Aşama 2) | S | Dock simgesinde ilerleme |
| Ana pencere konumunu / boyutunu hatırla | yok | Aşama 2 | S | `setFrameAutosaveName` |
| Beyaz UpLa ikonu kullan | — | Yalnızca Windows: menü çubuğu simgesi şablon görüntüdür | — | |
| Tepsi simgesi tıklama eylemleri (3) | yok | Aşama 2 | M | Karar 3 |
| Hızlı görev menüsünü düzenle... | yok | Aşama 2 | S | |
| Güncellemeleri otomatik kontrol et | yok | Aşama 2 | M | Sparkle 2 |
| Güncelleme kanalı, Geliştirici sürümünü kur... | — | Gösterilmez (Windows'ta da gizli) | — | |
| (Mac'e özgü) Dock'ta simge göster | — | Aşama 1 | S | Karar 1 |
| **Tema** sayfası (liste, Ekle, Kaldır, Dışa / İçe aktar, Sıfırla, özellik ızgarası) | yok | Karar 4 | M–L | |
| **Entegrasyon** › Windows başladığında UpLa'yı çalıştır | var (Genel'de) | Aşama 1 (yer, metin) | S | `SMAppService`; "Giriş Öğeleri Ayarlarını Aç" Mac'e özgü olarak kalır |
| "UpLa ile yükle" sağ tık menüsü | yok | macOS karşılığı (Aşama 4) | M | Finder Hızlı İşlem / `NSServices` |
| "UpLa ile düzenle" | yok | macOS karşılığı (Aşama 5) | S | Düzenleyiciyle |
| "Gönder" menüsü | yok | macOS karşılığı (Aşama 4) | M | Paylaş uzantısı (Share Extension; ayrı hedef ve imza) |
| **Yollar** › UpLa kişisel dizini + Uygula + Aç... + önizleme | yok | Aşama 2 | M | Yeniden başlatma sorusuyla |
| Özel ekran görüntüsü dizini kullan + yol + Gözat... | kısmen | Aşama 1 | S | Bugün "Klasör: Seç…" |
| Alt dizin şablonu (`%y-%mo`) + Aç... + önizleme | yok | Aşama 2 | S | `NameParser` |
| Pencere için alt dizin şablonu | yok | Aşama 2 | S | |
| **Ayarlar** › Not metni, Ayarlar ✓ / Geçmiş ✓, Dışarı aktar..., İçeri aktar... | yok | Aşama 2 | M | zip yedeği (Mac biçimi; .sxb ile uyumlu olmak zorunda değil) |
| Ayarları sıfırla... | kısmen | Aşama 2 | S | Bugün yalnızca kısayollarda "Varsayılanları Geri Yükle" |
| Eski yedek / günlük dosyalarını temizle + Saklancak dosya sayısı | yok | Aşama 2 | S | |
| **Ana pencere** › Menüyü göster | yok | Aşama 2 | S | |
| Görev görünümü modu | yok | Aşama 1 | S | |
| Küçük resim görünümü: Başlığı göster, Başlık konumu, Küçük resim boyutu + Sıfırla, Küçük resim tıklama eylemi | yok | Aşama 2 | S | |
| Liste görünümü: Kolonları göster, Resim ön izleme görünürlüğü, Resim ön izleme konumu | yok | Aşama 2 | S | |
| **Pano biçimleri** (Ekle..., Düzenle..., Kaldır, liste, açıklama) | yok | Aşama 2 | M | |
| **Yükleme** › Aynı anda yükleme limiti (5) | kısmen | Aşama 2 | M | Bugün seri kuyruk (1) |
| Tampon boyutu | — | Gösterilmez: `URLSession` kendisi yönetir | — | |
| Yükleme hatasında yeniden deneme (1) | yok | Aşama 2 | S | |
| İkincil yükleyiciler (3 liste) + "Tekrar denerken ikincil yükleyicileri…" | — | Gösterilmez: tek hedef (karar 7) | — | |
| **Geçmiş** › Görevleri geçmişe kaydet | var (her zaman) | Aşama 2 | S | |
| Adres boş değilse kaydet | yok | Aşama 2 | S | |
| Son görevleri kaydet, En fazla kaydedilecek görev sayısı, Açılışta ana pencerede göster, Tepsi menüsünde göster / ilk göster | kısmen | Aşama 1 | S | |
| **Yazdırma** › Resim yazdırma ayarları... (+ Yazıcı ayarları penceresi) | yok | Aşama 2 | M | `NSPrintInfo`; kenar boşluğu, otomatik döndür / boyutlandır / büyüt / ortala |
| Resim yazdırma ayarları penceresini gösterme | yok | Aşama 2 | S | |
| Windows yazdırma penceresini gösterme + Varsayılan yazıcıyı değiştir | yok | macOS karşılığı (Aşama 2) | S | `NSPrintOperation.showsPrintPanel = false`; `NSPrinter(name:)` |
| **Vekil Sunucu** (Hiçbiri / Elle / Otomatik, Sunucu, Port, Kullanıcı adı, Şifre) | yok | Aşama 2 (düşük öncelik) | M | `URLSessionConfiguration.connectionProxyDictionary`; "Otomatik" = sistem ayarı (`URLSession` varsayılanı); şifre Anahtar Zinciri'nde |
| **Gelişmiş** › Application (BinaryUnits, ShowMostRecentTaskFirst, WorkflowsOnlyShowEdited, TrayAutoExpandCaptureMenu, ShowMainWindowTip, BrowserPath, SaveSettingsAfterTaskCompleted, AutoSelectLastCompletedTask) | yok | Aşama 2 | S | BrowserPath → `NSWorkspace.open(_:withApplicationAt:)`; DevMode gösterilmez |
| Clipboard › ShowClipboardContentViewer | yok | Aşama 2 | S | |
| Clipboard › DefaultClipboardCopyImageFillBackground, UseAlternativeClipboardCopyImage / GetImage | — | Yalnızca Windows: Windows panosunun saydamlık sorunları için | — | |
| Drag and drop window (DropSize, DropOffset, DropAlignment, DropOpacity, DropHoverOpacity) | yok | Aşama 2 | S | |
| Hotkey (DisableHotkeys, DisableHotkeysOnFullscreen, HotkeyRepeatLimit) | yok | Aşama 2 (Fullscreen Aşama 4) | S | |
| Image (RotateImageByExifOrientationData, PNGStripColorSpaceInformation) | yok | Aşama 2 | S | ImageIO |
| Paths (UseMachineSpecificUploadersConfig, CustomUploadersConfigPath, CustomHotkeysConfigPath, CustomScreenshotsPath2) | yok | Aşama 2 (düşük öncelik) | S | |
| Upload › DisableUpload | yok | İsteğe bağlı | S | §4.1 |
| Upload › URLEncodeIgnoreEmoji, ShowMultiUploadWarning, ShowLargeFileSizeWarning | yok | Aşama 2 | S | |
| Upload › ShowUploadWarning | var | — | — | |

### 4.19 Görev ayarları

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| Pencere, ağaç; varsayılan mod | yok | Aşama 1 (iskelet) | M | |
| Kısayola özel mod ve "… ayarlarını değiştir" kutuları | yok | Aşama 2 | M | |
| **Görev** › Görev:, Açıklama: | yok | Aşama 2 | S | |
| Yakalama sonrası / Yükleme sonrası ayarlarını değiştir + menü düğmeleri | yok | Aşama 2 | S | Bit eşlemesi doğru (Windows hatası kopyalanmaz) |
| Hedefleri değiştir + Hedefler... | yok | Aşama 2 | S | |
| Varsayılan ekran görüntüsü klasörünü değiştir | yok | Aşama 2 | S | |
| **Genel › Uyarılar** › 3 ses kutusu | yok | Aşama 2 | S | |
| Görev bittikten sonra tost bildirimi göster | var | Aşama 1 (yer) | S | Bugünkü "Yükleme bitince bildirim göster" |
| Tost bildirimi grubu (Süre, Solma süresi, Konum, Boyut, 3 tık eylemi, Ekran görüntüsü alırken otomatik olarak sakla, Tam ekran ise uyarıları devre dışı bırak) | yok | Aşama 2 | M | |
| Kişisel sesler (4) | yok | Aşama 2 | S | |
| **Resim** › Resim biçimi (PNG / JPEG / GIF / BMP / TIFF) | yok | Aşama 2 | S | Bugün hep PNG; ImageIO |
| PNG bit derinliği | yok | Aşama 2 | S | 24 bit = alfa kanalını atma |
| JPEG kalitesi (90) | yok | Aşama 2 | S | |
| GIF kalitesi | — | Yalnızca Windows: dört .NET kodlayıcısı; ImageIO'da tek GIF kodlayıcı var | — | |
| JPEG'e geçme eşiği (2048 kB) + kaliteyi otomatik ayarlama | yok | Aşama 2 | S | Retina ekran görüntüleri bu eşiği sık aşar; doğrulanmalı |
| Dosya varsa: | yok | Aşama 2 | S | |
| **Efekt** › Resim efektleri ayarları..., yakalama sonrası efekt ekranı, yalnızca bölgeye uygula, rastgele efekt | yok | Aşama 3 | S | |
| **Yakalama** › Ekran görüntülerinde imleç göster | yok | Aşama 1 | S | |
| Ekran görüntüsü gecikmesi | yok | Aşama 1 | S | |
| Pencereyi şeffaflık ile yakala / gölge ile yakala | kısmen | Aşama 2 | S | Bugün pencere yakalama hep gölgesiz (`-o`); Windows varsayılanı da sonuçta gölgesiz (şeffaflık kapalı) |
| Gölge çıkıntısı | — | Yalnızca Windows: gölgeyi macOS kendisi çizer | — | |
| Pencere yakalarken başlık çubuğunu yakalama | — | Yalnızca Windows: başka uygulamaların pencere içi alanı bilinmez | — | |
| Masaüstü simgelerini otomatik gizle | yok | macOS karşılığı (Aşama 4) | M | `SCContentFilter` ile Finder'ın masaüstü simge pencereleri dışlanır |
| Görev çubuğunu gizle | — | Yalnızca Windows: görev çubuğu yok; Dock programla gizlenemez | — | |
| Önceden ayarlanmış bölge (X / Y / Genişlik / Yükseklik) + Bölge seç... | yok | Aşama 2 (sayılar), Aşama 4 (Bölge seç...) | S | |
| Önceden yapılandırılmış pencere başlığı | yok | Aşama 2 | S | |
| **Bölge yakala** › Çoklu bölge modu | yok | Aşama 4 | M | |
| Fare sağ / orta / 4 / 5 tuşu eylemleri | yok | Aşama 4 | S | `otherMouseDown` buttonNumber 2–4 |
| Pencere alanlarını tespit et | yok | Aşama 4 | M | `SCShareableContent` pencere çerçeveleri |
| Pencere içindeki kontrol bölgelerini tespit et | yok | Aşama 4 (isteğe bağlı) | L | Erişilebilirlik izni (`AXUIElement`) |
| Arka plan karartma yoğunluğu, özel bilgi yazısı, Alt ile boyut kilitleme, pozisyon / boyut bilgisi | yok | Aşama 4 | S | |
| Büyüteç (göster, kare, piksel sayısı, piksel boyutu) | yok | Aşama 4 | M | |
| Artı imleçler (ekranı kaplayan, merkez), sabit boyutlu bölge, FPS göster / limiti, aktif ekrana sınırlama | yok | Aşama 4 | S | |
| **Ekran kaydedici** | | | | §4.17 |
| **OCR** › Varsayılan dil | yok | Aşama 3 | S | Vision dilleri |
| Sessizce OCR uygula, Sonuçları otomatik olarak panoya kopyala, Servis bağlantısı açılınca kapat | yok | Aşama 3 | S | |
| **Dosya adlandırma** › iki isim deseni + önizleme + değişken menüsü | yok | Aşama 2 | M | Bugün sabit `UpLa_yyyy-MM-dd_HH-mm-ss` |
| Dosya yüklemeleri için de isim deseni kullan | yok | Aşama 2 | S | |
| Otomatik artan sayı + Değiştir | yok | Aşama 2 | S | |
| Kişisel zaman dilimi kullan | yok | Aşama 2 | S | `TimeZone.knownTimeZoneIdentifiers` |
| Problematik karakterleri alt çizgiyle değiştir | yok | Aşama 2 | S | |
| Sonuç linkini regex ile değiştir (Desen, Değiştirme) | yok | Aşama 2 | S | `NSRegularExpression` |
| **Panodan yükleme** › Pano dosya linki içeriyorsa indir ve yükle; adres içeriyorsa paylaş | yok | Aşama 2 | S | |
| **Yükleyici filtreleri** sayfası | — | Gösterilmez: tek hedef (Windows'ta da iki aynı öğe) | — | |
| **Araçlar** › üç ekran renk seçici biçimi | yok | Aşama 3 | S | Piksel bilgisi değişkenleri |
| **Aksiyon** › liste + Ekle... / Düzenle... / Kopyala / Kaldır + Aksiyonlar... + Aksiyonlar penceresi | yok | Aşama 4 | M | Varsayılan programlar Mac'te Önizleme vb.; "Aksiyonlar..." linki ShareX sayfasına gider |
| **Dizinleri takip et** + liste + Dizin gözetle penceresi | yok | Aşama 4 | M | FSEvents (`FSEventStream`) |
| **Gelişmiş** › After upload (ResultForceHTTPS, ClipboardContentFormat, BalloonTipContentFormat, OpenURLFormat, AutoCloseAfterUploadForm) | yok | Aşama 2 | S | |
| Capture › RegionCaptureDisableAnnotation | yok | Aşama 5 | S | |
| General › ProcessImagesDuringFileUpload / ClipboardUpload, UseAfterCaptureTasksDuringFileUpload, TextTaskSaveAsFile, AutoClearClipboard | yok | Aşama 2 | S | ProcessImagesDuringExtensionUpload gösterilmez |
| Name pattern (NamePatternMaxLength, NamePatternMaxTitleLength) | yok | Aşama 2 | S | |
| Upload › ImageExtensions, TextExtensions | yok | Aşama 2 | S | |
| Upload text (TextFileExtension, TextCustom, TextCustomEncodeInput) | — | Gösterilmez: upla.com.tr metin kabul etmiyor | — | |

### 4.20 Kısayol ayarları

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| "UpLa - Kısayol ayarları" penceresi (liste modeli) | kısmen | Aşama 2 | L | Bugün Ayarlar › Kısayollar'da 4 sabit satır; Aşama 1'de bu sekme yeni pencereye taşınır |
| **Ekle...** / **Düzenle...** / **Kaldır** / **Çoğalt** / **↑** / **↓** | yok | Aşama 2 | M | |
| **Sıfırla...** (onaylı) | kısmen | Aşama 2 | S | Bugün "Varsayılanları Geri Yükle" (onaysız) |
| Satır: görev düğmesi (görev türü menüsü, "*") | yok | Aşama 2 | M | |
| Satır: dişli (kısayola özel Görev ayarları) | yok | Aşama 2 | M | |
| Satır: kısayol düğmesi (yeşil / kırmızı / sarı simge, "Kısayol seçiniz...") | kısmen | Aşama 2 | S | Kaydedici var; durum bugün kırmızı yazıyla |
| Esc kısayolu boşaltır | kısmen | §3.1 | — | Mac'te Esc iptal, Sil kaldırır |
| Alt çubuk "Kısayol tuşları devre dışı. Buraya tıklıyarak yeniden etkinleştirebilirsiniz." | yok | Aşama 2 | S | |
| Açılınca kaydedilemeyen kısayolları yeniden deneme | yok | Aşama 2 | S | |

### 4.21 Hedef ayarları ve giriş penceresi

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| Pencere başlığı + ağaç (**Resim yükleyiciler** › **upla.com.tr**) | yok | Aşama 1 | S | |
| **upla.com.tr hesabı:** durum metni (5 durum) | var | Aşama 1 (yer) | S | Bugün Hesap sekmesinde |
| Giriş yap... / Tekrar giriş yap... / Çıkış yap düğmeleri; Profilim, Bağlı cihazlar, Hesap oluştur, Misafir olarak devam et | var | Aşama 1 (yer, metin) | S | |
| **API anahtarını elle gir (gelişmiş)** | var | — | — | |
| **API anahtarı:** + **Göster** | var | — | — | |
| **Doğrula** + **Anahtar al** | kısmen | Aşama 1 | S | Bugün "Bu Anahtarı Kullan" + "Anahtarı Doğrula"; Windows'ta yazılan anahtar hemen geçerli, ayrı "kullan" düğmesi yok |
| Anahtar durum satırı + açıklama metni | var | — | — | |
| Kopyalanacak link, Albüm (+ örnek), Etiketler, Kategori kimliği, Otomatik silme, Sunucuda en fazla genişlik, iki not metni | var | Aşama 1 (yer, sıra) | S | |
| Yüklenecek ekran kayıtlarını yükleme sınırına gelince durdur | var | Aşama 1 (yer) | S | Bugün Kayıt sekmesinde |
| **API belgesi** linki | yok | Aşama 1 | S | https://upla.com.tr/api-v1 |
| Açılışta hesabı sunucudan yenileme (`me`) | var | — | — | |
| Giriş penceresi (alanlar, linkler, iki adımlı doğrulama, hata metinleri, ekran görüntüsünden gizleme) | var | Aşama 1 (metin) | S | "Giriş Yap" → "Giriş yap"; "bu Mac" → "bu bilgisayar" (karar 6) |

### 4.22 Geçmiş pencereleri

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| "UpLa - Geçmiş" penceresi (araç çubuğu, liste: simge / Tarih / Dosya adı / Adres, önizleme) | kısmen | Aşama 2 | L | Bugün "Yükleme Geçmişi": satır listesi, Linki Kopyala / Aç düğmeleri |
| Başlıkta Toplam / Filtrelenmiş / tür sayıları | kısmen | Aşama 2 | S | Bugün alt bilgide "Yüklemeler: N" |
| **Ara** + **Gelişmiş arama** paneli (Adres, Dosya adı, Sunucu, Dosya türü, Tarih aralığı) | yok | Aşama 2 | M | |
| **Sık kullanılanlar** | yok | Aşama 2 | S | |
| **İstatistikleri göster...** | yok | Aşama 2 | S | |
| **Klasörü içe aktar...** (+ pencere) | yok | Aşama 2 | S | |
| **Ayarlar...** (Geçmiş ayarları) | yok | Aşama 2 | S | |
| Sağ tık: Aç ▸ / Kopyala ▸ | kısmen | Aşama 2 | S | Bugün Linki Kopyala, Aç, Silme Sayfasını Aç… |
| Sağ tık: Favorite, Edit tag..., Edit item..., Rename file..., Delete item..., Delete file & item... | kısmen | Aşama 2 | M | Bugün yalnızca "Geçmişten Kaldır"; Windows'ta çevrilmemiş (karar 6b) |
| Sağ tık: Resim önizleme..., Dosyayı karşıya aktar | yok | Aşama 2 | S | |
| Sağ tık: Resimi düzenle..., Ekrana sabitle | yok | Aşama 5 / Aşama 3 | S (araçla) | |
| Klavye (Enter, ⌘C, ⌫, ⇧⌫ …) ve F5 (⌘R) | yok | Aşama 2 | S | |
| "UpLa - Resim geçmişi" ızgarası (250×150, en çok 500, kaydırınca daha fazlası) | yok | Aşama 2 | M | `NSCollectionView` |
| Resim geçmişi ayarları penceresi | yok | Aşama 2 | S | |
| Geçmiş dosyası | var | — | — | Mac'te `~/Library/Application Support/UpLa/history.json` (en çok 500); Windows biçimiyle uyumlu olması gerekmiyor |

### 4.23 Bölge yakalama ekranı ve resim düzenleyici

| Windows öğesi | Mac bugün | Plan | Efor | Not / macOS karşılığı |
|---|---|---|---|---|
| Bölge yakalama ekranı: donmuş ekran, karartma, sürükleyerek seçim | yok | Aşama 4 | L | Her ekran önce `SCScreenshotManager` ile yakalanır, üstüne tam ekran `NSPanel`; çoklu ekran ve farklı ölçekler |
| Pencere algılama (üstüne gelince vurgula, tıkla seç) | yok | Aşama 4 | M | |
| Büyüteç + piksel bilgisi + konum / boyut | yok | Aşama 4 | M | |
| Fare eylemleri, Alt ile boyut kilitleme, sabit boyut, çoklu bölge, artı imleçler, FPS, aktif ekrana sınırlama | yok | Aşama 4 | M | |
| Araç çubuğu: bölge araçları (Dikdörtgen / Elips / Serbest bölge) | yok | Aşama 4 | M | |
| Araç çubuğu: Yakala ▸ (Bölgeleri yakala, Son bölgeyi yakala, Tam ekran yakala, Aktif ekranı yakala, Monitör yakala ▸) | yok | Aşama 4 | S | |
| Araç çubuğu: Ayarlar ▸ (ekran seçenekleri) | yok | Aşama 4 | S | |
| Seç ve taşı + 16 çizim aracı (Dikdörtgen, Elips, Serbest çizim, Serbest çizim ok, Çizgi, Ok, Yazı (Dış çizgili), Yazı (Arkaplanlı), Konuşma balonu, Kademe, Büyüt, Resim (Dosya), Resim (Ekrandan), Çıkartma, İmleç, Akıllı silgi) | yok | Aşama 5 | L | Core Graphics çizim katmanı; harf kısayolları (R, E, F, L, A, O, T, S, I, M) |
| Efekt araçları (Bulanıklaştır, Mozaikle, Vurgula, Spot ışığı) | yok | Aşama 5 | M | `CIGaussianBlur`, `CIPixellate` |
| Resmi kırp, Kesip çıkar (Yırtık kenarlar, Dalga, Testere dişi) | yok | Aşama 5 | M | |
| Renk düğmeleri + Araç seçenekleri ▸ (çerçeve boyutu / stili, köşe, yazı boyutu, kademe tipi, gölge …) | yok | Aşama 5 | M | |
| Düzenle ▸ (Geri al, Yeniden yap, Resim/yazı yapıştır, Çoğalt, Sil, Hepsini sil, sıralama) | yok | Aşama 5 | M | `UndoManager` |
| Düzenleyici açılış penceresi (Resim dosyası aç..., Panodan resim yükle, URL'den resim yükle..., Yeni resim oluştur..., İptal) | yok | Aşama 5 | S | |
| Düzenleyici araç çubuğu başı (Yakalama sonrası görevlerini çalıştır; Kaydet; Farklı kaydet; Kopyala; Yükle; Yazdır; görev modunda Uygula / Devam / İptal) | yok | Aşama 5 | M | Kısayollar ⌘S, ⇧⌘S, ⌘C, ⌘U, ⌘P |
| Resim ▸ (Yeni resim, aç, ekle, Resim boyutu, Tuval boyutu, kırp, otomatik kırp, döndür, çevir, Resim efekti ekle) | yok | Aşama 5 | M | |
| Düzenleyici Ayarlar ▸ (Editör başlangıç modu, Açılışta sığdır, Otomatik kopyala, Görevden sonra kapat) | yok | Aşama 5 | S | |

### 4.24 Mac'te olup Windows'ta olmayanlar

| Mac öğesi | Öneri |
|---|---|
| Ekran Kaydı İzni penceresi | Kalır (macOS zorunlu) |
| Uygulama menüsü (UpLa, Düzen, Pencere) ve ⌘Q | Kalır; Dock simgesi görünürken görünür (§2.3) |
| Menü çubuğu simgesine dosya bırakma | Kalır (zararsız ek; karar 21) |
| Bölge Kaydet… / Pencere Kaydet… / Tam Ekranı Kaydet | Menüde **Ekran kaydetme** olarak birleşir: sürükle = bölge, tık = tam ekran (bugünkü katman). Pencere kaydı "Aktif pencere alanıyla ekran kaydetme başlat" görev türüyle (Aşama 2); sistem pencere seçicisi kalkar |
| Menüdeki "Kaydediliyor… 0:42, 12,3 MB", "Kaydı Durdur", "Kaydı İptal Et" ve durum satırları | Aşama 4'teki kayıt çubuğu ve ikinci simge gelene kadar kalır, sonra kalkar |
| Menüdeki "Yükleniyor… 45%" ve "Yüklemeleri İptal Et" | Ana pencere gelince (Aşama 1) kalkar; iptal görev listesinde "Yüklemeyi durdur" ve "Tüm aktif yüklemeleri durdur" görev türüyle |
| "Son Yüklemeler ▸" ve "Geçmişi Göster…" | "Son bağlantılar ▸" ve "Geçmiş..." olur |
| İlk yükleme sorusunun Mac'e özgü davranışı (kapatınca klasöre kaydetmeyi açma) | Windows metni ve davranışı; "Resimi dosya olarak kaydet" varsayılan açık olacağından ek davranışa gerek kalmaz (karar 9) |
| Hesap menüsündeki "Giriş yapıldı: …", "Elle girilen API anahtarı kullanılıyor", "Anahtarı Kaldır…" | Kalkar (§4.8) |
| Ayarlardaki ipucu metinleri ("UpLa menü çubuğunda çalışır…", macOS seçimi ipucu, kısayol kuralları) | Windows'ta yok. Mac'e özgü zorunlu bilgiler (kısayolda ⌘ veya ⌃ gerekliliği) ipucu (tooltip) olarak kalır, diğerleri kalkar |
| Geçmiş penceresindeki "Geçmişi Temizle…" | Windows'ta yok; Geçmiş ayarları penceresine taşınarak kalabilir (karar 21) |
| "Silme Sayfasını Aç…" | Aç ▸ **Silme adresi** olur (onay sorusu aynı) |
| Bildirim izni yoksa hataların uyarı kutusuyla gösterilmesi | Kalır |

---

## 5. Aşamalar

Her aşama birkaç PR'a bölünür ve her PR kendi başına derlenip denenebilir. Bir aşama yayınlandığında o aşamanın menü öğeleri çalışır; sonraki aşamaların öğeleri gizli kalır (karar 10).

### Aşama 1 — Ana pencere, birebir menüler, görev listeleri, ayar iskeleti

**Efor:** L (≈3–4 hafta). **Kazanç:** uygulama Windows'taki gibi görünür; bugünkü bütün işlevler Windows'taki yerlerinden çalışır.

**Kapsam (önerilen PR sırasıyla):**
1. **Temel:**
   - metin aktarma betiği ve yeni `Localizable.xcstrings` (§2.7);
   - ikon seti (karar 5);
   - `TaskSettings`, `ApplicationConfig`, `HotkeysConfig` modelleri (Windows bit değerleriyle) ve eski UserDefaults'tan geçiş (§2.6);
   - `MenuBuilder`.
2. **Ana pencere:**
   - çerçeve ve sol panelin 16 öğesi, sağa açılan menüler;
   - Dock politikası (karar 1), uygulama menüsü;
   - kapatınca gizleme ve ilk kapatma bilgisi.
3. **Menüler:**
   - **Yakala:** Tam ekran (bütün ekranlar), Pencere ▸, Monitör ▸, Bölge (macOS seçimi), Ekran kaydetme, İmleç göster, Ekran görüntüsü gecikmesi ▸.
   - **Yükle:** Dosya yükle..., Klasör yükle...; tepside ayrıca Panodan yükle....
   - **Yakalama sonrası** (20 öğe; Aşama 1'de çalışanlar görünür), **Yükleme sonrası** (5 öğe), **Hedefler**.
   - **Hesap düğmesi**, **Ekran görüntüsü dizini...**, **Geçmiş...** (bugünkü pencere), **Hakkında...** (Windows düzeni).
4. **Görev hattı:**
   - Windows'taki çalışma sırası;
   - `%ra{10}` adı, `Screenshots/%y-%mo` klasörü, PNG;
   - basit görevler: farklı kaydet, dosya / yol / klasör kopyala, klasörde göster, dosyayı sil, adresi kopyala, adresi aç;
   - varsayılanlar (karar 9).
5. **Görev alanı:**
   - kısayol tablosu, küçük resim görünümü, liste görünümü;
   - görev sağ tık menüsü (Aç ▸, Kopyala ▸ ve bütün biçimler), "UpLa - Hata" penceresi;
   - klavye, sürükle bırak, son 10 görev.
6. **Menü çubuğu menüsü:**
   - tepsi sırası (25 öğe), İş akışları (5 varsayılan kısayol), Kısayolları devre dışı bırak, Son bağlantılar, UpLa penceresini göster, Çıkış;
   - ilerleme simgesi.
7. **Ayar iskeleti:**
   - dört pencere ve Windows ağaçları;
   - bugünkü Mac seçenekleri Windows'taki yerlerinde (§2.6);
   - Hedef ayarları'nın upla.com.tr sayfası Windows sırasıyla;
   - bu aşamada içeriği olmayan düğümler gizli.
8. **İletişim kutuları:** ilk yükleme sorusu (Windows metni), 10'dan fazla dosya, büyük dosya, yerel dosya silme, kısayol kaydı başarısız, kayıt sürerken çıkış.
9. **Kısayollar:** Aktif pencereyi yakala ve Aktif ekranı yakala eylemleri; varsayılanlar (karar 8).

**Riskler:**
- `.accessory` ↔ `.regular` geçişlerinde odak ve menü çubuğu tuhaflıkları (pencere öne gelmeyebilir).
- Özel konumda açılan `NSMenu`'nün koyu görünümde ve çoklu ekranda doğru yere açılması.
- Küçük resim üretiminin ana iş parçacığını yormaması (Retina, büyük videolar).
- 0.1 kullanıcılarının ayar geçişi: varsayılan değişiklikleri kullanıcının seçimini ezmemeli.
- Bütün ekranları tek resimde birleştirme (farklı ölçekler, negatif koordinatlı ekranlar).
- Kapsam büyük: PR'lar küçük tutulmalı; her PR'dan sonra Mac'te deneme.

**Mac'te doğrulanacaklar:**
- [ ] Ana pencere açılış ve kapanışı; Dock simgesi ve uygulama menüsünün görünüp kaybolması; ⌘Q, ⌘W, Esc.
- [ ] Sol paneldeki her açılır menünün düğmenin sağına açılması; açık ve koyu görünümde okunurluk.
- [ ] Pencere ▸: başlıklar ve uygulama simgeleri (Ekran Kaydı izniyle), seçilen pencerenin doğru yakalanması, gölge.
- [ ] Monitör ▸ ve Tam ekran: iki ekran, Retina + Retina olmayan ekran.
- [ ] Gecikme ve İmleç göster.
- [ ] Yakalama sonrası / Yükleme sonrası onaylarının gerçek ayarları göstermesi ve değiştirmesi; ilk açılıştaki varsayılanlar.
- [ ] Görev listesi: ilerleme, Hata rozeti ve penceresi, sağ tık menüsü ve kopyalama biçimleri, Finder'a sürükleme, kısayollar.
- [ ] Son 10 görevin yeniden açılışta "Geçmiş" olarak gelmesi.
- [ ] Türkçe ve İngilizce metinlerin Windows referans görüntüleriyle aynı olması.
- [ ] 0.1'den yükseltmede eski ayarların taşınması.

**Bitti sayılır:** sol panel, menü çubuğu menüsü ve bütün alt menüler Windows referans görüntüleriyle aynı (henüz çalışmayan öğeler gizli); bugünkü Mac işlevlerinin hepsi yeni yerlerinden çalışıyor.

### Aşama 2 — Ayarların tamamı, kısayol listesi, tost ve sesler, geçmiş pencereleri

**Efor:** L (≈3–4 hafta). **Kazanç:** Windows'taki bütün seçenekler, kısayol başına ayarlar ve görev pencereleri.

**Kapsam:**
- **Uygulama ayarları:** uygulanabilir bütün seçenekler (§4.18): menü çubuğu ve Dock seçenekleri, tıklama eylemleri, kişisel dizin ve alt klasör şablonları, yedek dışa / içe aktarma, ana pencere ve liste seçenekleri, pano biçimleri, eşzamanlı 5 yükleme ve yeniden deneme, geçmiş, yazdırma, vekil sunucu, Gelişmiş.
- **Görev ayarları:** bütün sayfalar (§4.19), kısayola özel mod ve override kutuları; isim deseni motoru ve değişken menüsü; resim biçimi ve kalite; tost bildirimi grubu; sesler.
- **Kısayol ayarları:** liste modeli, görev türü menüsü (Mac'te çalışan türler), dişli → kısayola özel Görev ayarları, durum simgeleri, Sıfırla...; İş akışları menüsü artık listeden.
- **Tost penceresi** (resimli / metin, 9 konum, tık eylemleri, sürükleme), hata tostu, diğer tostlar.
- **Geçmiş** penceresi Windows düzeninde, **Resim geçmişi**, alt pencereleri; **Hata ayıklama kütüğü** ve **Resim yükleme testi**.
- **Görev pencereleri:** Yakalama sonrası, Dinamik hedefler, Yükleme sonrası, Hızlı görev menüsü ve düzenleyicisi, Pano içeriği, Bırakma penceresi, Aksiyonlar araç çubuğu, Yanıt.
- **Yükleme:** Adresden indirip yükle, İndir, Adresi paylaş ve paylaşım servisleri, özel bölge / önceden yapılandırılmış pencere / aktif pencere kaydı görev türleri.
- **Güncelleme:** Sparkle denetimi ve Hakkında'daki satır (PLAN.md'deki M5 ile birleşebilir; imzalı sürüm ister).

**Riskler:**
- Görev ayarları modelinin genişliği ve kısayola özel ayarların varsayılanla birleşme kuralları (override mantığı Windows'taki gibi olmalı).
- Tost penceresinin odak çalmaması; Spaces ve tam ekran uygulamaların üstünde görünmesi (`collectionBehavior`).
- Eşzamanlı yüklemelerde ilerleme, iptal ve sunucu tarafındaki sel (flood) sınırı.
- Sparkle'ın imza ve notarization gerektirmesi (Apple Developer Program).

**Mac'te doğrulanacaklar:**
- [ ] Tost: 9 konum, süre / solma, fare üstündeyken bekleme, üç tık eylemi, dışarı sürükleme, tam ekran uygulamada davranış.
- [ ] Seslerin çalması ve kişisel ses dosyaları.
- [ ] Kısayol listesi: ekle / kaldır / çoğalt / sırala / sıfırla, çakışan kısayol uyarısı, kısayola özel ayarların uygulanması ("*").
- [ ] İsim desenleri ve önizlemeler; alt klasör şablonu.
- [ ] Geçmiş: arama, gelişmiş arama, sık kullanılanlar, istatistikler, klasör içe aktarma; Resim geçmişi kaydırma.
- [ ] Yazdırma; vekil sunucuyla yükleme (varsa); yedek dışa / içe aktarma.
- [ ] Beş eşzamanlı yükleme ve tek tek iptal.

**Bitti sayılır:** Windows'taki ayar pencerelerinin Mac'te uygulanabilen her seçeneği var ve çalışıyor; görev pencereleri ve tost Windows'takiyle aynı.

### Aşama 3 — Yerel karşılığı olan araçlar

**Efor:** L (≈3 hafta). **Kazanç:** Araçlar menüsü ve araca bağlı görevler dolar.

**Kapsam:** 11 aracın düzenleyici dışındaki 10'u ve bunlara bağlı her şey:
- Yakalama sonrası 3, 4 (temel efektler), 7, 16, 17; Yükleme sonrası 5;
- görev menüsünde Resmi güzelleştir..., Resim efekti ekle..., Ekrana sabitle, QR kod göster..., Resimden yazı yakala (OCR)..., Resimleri birleştir... ▸ ve kutucuğa bırakarak birleştirme;
- Araçlar görev türleri; Görev ayarları'nın Efekt, OCR ve Araçlar sayfaları.

**Önerilen sıra (değere göre, karar 14):** OCR → QR kod → Ekrana sabitle → Ekrandan renk seçici → Resim görüntüleyici → Resim birleştirici → Resim güzelleştirici → Cetvel → Renk seçici → Resim efektleri (temel set).

**Riskler:**
- Vision'ın Türkçe metin tanıma desteği macOS sürümüne bağlı olabilir.
- `NSColorSampler` Windows'taki bilgi yazısını göstermez; birebir için kendi katman gerekir.
- Core Image efektleri ShareX'inkilerle piksel piksel aynı sonuç vermez.
- Sabitlenen pencerelerin Spaces, tam ekran ve çoklu ekrandaki davranışı.

**Mac'te doğrulanacaklar:**
- [ ] OCR dil listesi; Türkçe ve İngilizce metinde sonuç kalitesi; servis linkleri.
- [ ] QR üretme, ekrandan / bölgeden / dosyadan tarama.
- [ ] Sabitleme: sürükleme, yakınlaştırma, saydamlık, Tümünü kapat.
- [ ] Renk seçicilerde Retina koordinatları ve kopyalanan biçimler.
- [ ] Birleştirici ve güzelleştirici çıktılarının Windows çıktılarıyla karşılaştırılması.

### Aşama 4 — Kendi bölge yakalama ekranı ve kayıt eksikleri

**Efor:** L (≈4–5 hafta). **Kazanç:** yakalama ve kayıt Windows'takiyle aynı.

**Kapsam:**
- **Kendi Bölge ekranı:** seçim, pencere algılama, büyüteç, bilgi yazısı, fare eylemleri, sabit boyut, Alt ile boyutlar, çoklu bölge, Yakala ▸ ve Ayarlar ▸ menüleri. Ardından **Bölge (Basit)**, **Bölge (Saydam)**, **Son bölge**, **Özel bölge**, **Bölge seç...**.
- **Ekran kaydı:**
  - Windows'taki çerçeve ve kayıt çubuğu, duraklatma, geri sayım, sabit süre, ikinci durum simgesi, iptal onayı;
  - GIF kaydı ve GIF FPS;
  - **Ekran kayıt ayarları...** penceresinin Mac sürümü ve mikrofon.
- **Kaydırarak yakalama.**
- **Aksiyonlar:** Görev ayarları › Aksiyon, Aksiyon çalıştır ▸, Aksiyonları gerçekleştir.
- **Dizinleri takip et.**
- **Finder entegrasyonu:** Hızlı İşlem / Hizmetler ve Paylaş uzantısı.
- **Diğer:** masaüstü simgelerini gizleme; tam ekranda kısayolları ve tostları kapatma.

**Riskler:**
- Çoklu ekran ve farklı ölçekler; donmuş ekran görüntülerinin bellek kullanımı (birden fazla 5K ekran).
- Kayıt çerçevesinin ve çubuğunun kayıttan dışlanması.
- GIF dosya boyutu (misafir sınırı 20 MB).
- Duraklatma sonrası ses ve görüntü zaman damgaları.
- Erişilebilirlik izni (kaydırarak yakalama, kontrol algılama) Mac App Store sandbox'ında verilmez (karar 19).
- Paylaş uzantısı ayrı hedef, ayrı imza ve App Group ister.

**Mac'te doğrulanacaklar:**
- [ ] Bölge ekranında Esc ve sağ tık iptali; Retina doğruluğu; ekranlar arası seçim; menü çubuğu ve Dock üzerinde pencere algılama.
- [ ] Son bölge ve özel bölgenin aynı alanı yakalaması.
- [ ] Kayıt çubuğu ve çerçevenin kayıtta görünmemesi; duraklat / devam sonrası ses-görüntü uyumu.
- [ ] GIF'in upla.com.tr'de oynaması ve sınırda kesilmesi; mikrofon izni.
- [ ] Kaydırarak yakalamanın Safari ve Finder'da birleştirme kalitesi.
- [ ] Finder Hızlı İşlem ve Paylaş menüsünde "UpLa"nın görünmesi.

### Aşama 5 — Resim düzenleyici ve kalan ağır öğeler

**Efor:** L+ (≈4–6 hafta; karar 15'e göre ikiye bölünebilir). **Kazanç:** Windows'taki düzenleyici ve bölge ekranında çizim.

**Kapsam:**
- **Düzenleyici:** açılış penceresi; Seç ve taşı + 16 çizim aracı, efekt araçları, Resmi kırp, Kesip çıkar; renkler ve Araç seçenekleri ▸; Düzenle ▸, Resim ▸, düzenleyici Ayarlar ▸; geri al / yinele.
- **Bölge ekranında çizim** (annotation).
- **Düzenleyiciye bağlı öğeler:** "Resim düzenleyicide aç" görevi, "Resim düzenle..." menüsü, tostun orta tık eylemi "Resimi düzenle", geçmişteki "Resimi düzenle...", Finder'da "UpLa ile düzenle".
- **Kalanlar:** Resim efektlerinin kalan bütün efektleri; isteğe bağlı olarak Hakkında logo animasyonu ve politika ayarları.

**Riskler:**
- Kapsam: ShareX düzenleyicisi binlerce satır; karar 15 olmadan iş uzar.
- Yazı araçlarında Türkçe karakterler ve yazı tipleri.
- Büyük Retina görüntülerde bulanıklaştırma performansı.
- Geri al yığını.
- Tek harfli araç kısayollarının macOS kısayollarıyla çakışmaması.

**Mac'te doğrulanacaklar:**
- [ ] Her aracın çizim, seçme, taşıma ve boyutlandırma davranışı (Windows referans görüntüleriyle).
- [ ] Geri al / yinele.
- [ ] Kaydet, farklı kaydet, kopyala, yükle, yazdır.
- [ ] Görev modunda Enter / Space / Esc.
- [ ] Çıktı çözünürlüğü (Retina) ve dosya boyutu.

---

## 6. Yalnızca Windows'ta kalacak öğeler ve nedenleri

| Windows öğesi | Neden | Mac'te |
|---|---|---|
| UpLa'yı yönetici olarak yeniden başlat | UAC; Windows'ta da gizli | yok |
| Beyaz UpLa ikonu kullan | Menü çubuğu simgesi şablon görüntüdür | yok |
| Görev çubuğu tuşunda durum göster | Görev çubuğu yok | Dock simgesinde durum göster |
| Windows başladığında UpLa'yı çalıştır | — | Oturum açıldığında UpLa'yı çalıştır (`SMAppService`) |
| Gezgin sağ tık menüsü, "Gönder" menüsü | — | Finder Hızlı İşlem / Paylaş uzantısı (Aşama 4) |
| Güncelleme kanalı, Geliştirici sürümünü kur... | Windows'ta da gizli | yok |
| Tampon boyutu | `URLSession` kendisi yönetir | yok |
| İkincil yükleyiciler, Yükleyici filtreleri | Tek hedef; Windows'ta da işlevsiz | yok |
| GIF kalitesi (dört .NET kodlayıcısı) | ImageIO'da tek GIF kodlayıcı | yok |
| Gölge çıkıntısı; pencere yakalarken başlık çubuğunu yakalamama; görev çubuğunu gizleme | Windows pencere yapısına özgü | yok |
| FFmpeg indirme; gdigrab / ddagrab / dshow kaynakları; NVENC / AMF / Quick Sync, x265, VP8 / VP9, WebP; Opus / Vorbis / MP3; Kayıt cihazlarını yükle...; Özel FFmpeg yolu; Ek komut satırı parametreleri; Özel komutlar; İlk kayıpsız kodlama | FFmpeg ve DirectShow'a özgü | ScreenCaptureKit + VideoToolbox (H.264 / HEVC), AAC; Mac'e özgü Ekran kayıt ayarları penceresi |
| Hata ayıklama › Yüklenen kütüphaneler | .NET derlemeleri | yok |
| Kütüğü karşıya yükle..., Tema › Metin olarak yükle, Upload text özellikleri | upla.com.tr metin kabul etmiyor | yok |
| Pano: DefaultClipboardCopyImageFillBackground, UseAlternativeClipboardCopyImage / GetImage | Windows panosunun saydamlık sorunları | yok |
| Kısaltılmış adres, Küçük resim dosya, Küçük resim (Aç / Kopyala) | UpLa'da hep gri | yok (karar 7) |
| ProcessImagesDuringExtensionUpload | Tarayıcı uzantısı kaldırıldı | yok |
| Windows OCR dilleri | Windows.Media.Ocr | Vision dilleri |
| Politika anahtarları (HKLM / HKCU\SOFTWARE\UpLa) | Kayıt defteri | İsteğe bağlı: yönetilen tercihler |
| "Disable Print Screen key for Snipping Tool" (kurulum) | Windows Ekran Alıntısı Aracı | yok |
| DevMode, "(Release, Admin)" başlığı | Geliştirici özelliği | yok |
| Microsoft Store'a özgü gizlemeler | Store paketi | Mac App Store kararına bağlı (karar 19) |

---

## 7. macOS API eşlemesi (özet)

| Windows'taki işlev | macOS karşılığı |
|---|---|
| Bölge, pencere ve tam ekran yakalama | Bugün `/usr/sbin/screencapture`; kendi ekran için `SCScreenshotManager.captureImage` (macOS 14+), `SCShareableContent`, `SCContentFilter` |
| Pencere ve monitör listeleri | `SCShareableContent.windows` / `.displays`, `NSScreen`, `NSRunningApplication.icon` |
| Aktif pencere / aktif ekran | `NSWorkspace.frontmostApplication` + `CGWindowListCopyWindowInfo` (katman 0); `NSEvent.mouseLocation` |
| Ekran kaydı (MP4) | ScreenCaptureKit `SCStream` + `AVAssetWriter` (bugün var) |
| GIF kaydı | `SCStream` kareleri → ImageIO `CGImageDestination` (`UTType.gif`) |
| Mikrofon | macOS 15 `SCStreamConfiguration.captureMicrophone`; 14'te `AVCaptureSession` |
| Kaydırarak yakalama | Erişilebilirlik izni + `CGEvent(scrollWheelEvent2Source:)` + Vision `VNTranslationalImageRegistrationRequest` |
| Genel kısayollar | Carbon `RegisterEventHotKey` (bugün var) |
| Tepsi simgesi ve menüsü | `NSStatusItem`, `NSMenu` |
| Görev çubuğu ilerlemesi | `NSDockTile` |
| Tost bildirimi | `NSPanel` (`.nonactivatingPanel`, `.floating`) + `NSAnimationContext`; isteğe bağlı `UNUserNotificationCenter` (bugün var) |
| Sesler | `NSSound` |
| Pano | `NSPasteboard` |
| Gezgin'de göster / Geri Dönüşüm Kutusu | `NSWorkspace.activateFileViewerSelecting`, `FileManager.trashItem` |
| Yazdırma | `NSPrintOperation`, `NSPrintInfo`, `NSPrinter` |
| OCR | Vision `VNRecognizeTextRequest` |
| QR kod | `CIFilter.qrCodeGenerator()`, Vision `VNDetectBarcodesRequest` |
| Renk seçici / ekrandan renk | Özel pencere; `NSColorSampler` |
| Ekrana sabitle, cetvel, bırakma penceresi, aksiyonlar araç çubuğu | Kenarsız `NSPanel` (`.floating`, `.canJoinAllSpaces`, `.fullScreenAuxiliary`) |
| Resim efektleri, bulanıklaştır / mozaik | Core Image (`CIGaussianBlur`, `CIPixellate`, renk filtreleri) |
| Güzelleştirici, birleştirici, düzenleyici çizimleri | Core Graphics |
| Resim biçimleri ve kalite | ImageIO (`CGImageDestination`, `kCGImageDestinationLossyCompressionQuality`) |
| Video küçük resmi | `QLThumbnailGenerator`, `AVAssetImageGenerator` |
| Resim görüntüleyici | `NSImageView` penceresi; geçici olarak `QLPreviewPanel` |
| Dizin takibi | FSEvents (`FSEventStream`) |
| Dış program çalıştırma (Aksiyonlar) | `Process`, `NSWorkspace.open(_:withApplicationAt:)` |
| Başlangıçta çalıştırma | `SMAppService.mainApp` (bugün var) |
| Gezgin sağ tık / Gönder | `NSServices` / Finder Hızlı İşlem, Share Extension |
| Vekil sunucu | `URLSessionConfiguration.connectionProxyDictionary` |
| Güncelleme | Sparkle 2 |
| DPAPI ile anahtar saklama | Anahtar Zinciri (bugün var) |
| Giriş penceresini yakalamadan gizleme | `NSWindow.sharingType = .none` (bugün var) |
| Görünüm / tema | `NSAppearance` (`.aqua` / `.darkAqua`) |

---

## 8. Önerilen çalışma düzeni

1. **Önce PR #3 (ekran kaydı):** MacBook'ta test edilip birleştirilmeli; parite işi güncel `main` üzerinden başlamalı.
2. **Belgeler Mac deposunda:** bu iki belge `docs/parity/` altında; Mac'teki Claude oturumu yalnızca depodakini görür. PLAN.md'nin "Not planned" maddesi bu plana göre güncellendi; kilometre taşları Aşama 1 başlarken güncellenmeli.
3. **Windows referans görüntüleri:** `docs/parity/windows-ref/` (2.0.3, Türkçe): sol paneldeki her açılır menü, tepsi menüsü, Uygulama ve Görev ayarlarının her düğümü, Kısayol ve Hedef ayarları, görev sağ tık menüsü, Hakkında, Geçmiş, Resim geçmişi. Dizin `README.md`'de. Mac görüntüleri bunlarla karşılaştırılır.
4. **Dallar:** her alt adım ayrı dal ve PR (`parity/1-temel`, `parity/1-ana-pencere`, …). Birleştirme kararı her zaman kullanıcının.
5. **Metin betiği** depoda tutulmalı ve her aşamanın başında yeniden çalıştırılmalı.
6. **Windows tarafında ayrı küçük işler** (karar 20):
   - onay işareti hatasının düzeltilmesi (envanter §12.1; `MainForm.SetMultiEnumChecked`, `TaskSettingsForm`, `QuickTaskInfoEditForm`) — **2.0.3'te yapıldı** (`1ce7e55ff`);
   - çevrilmemiş metinler (karar 6b) — Windows `main`'de yapıldı (`92748c3ad`), sonraki sürümde çıkacak;
   - yazım hataları (karar 6a) — aynı commit.
   Bunlar Mac'teki metinleri de etkiler: metin betiği metinleri Windows deposunun `main` dalından alır, ayrı bir düzeltme tablosu gerekmez. "Yükleme sonrası" penceresindeki biçim adları Windows'ta İngilizce kaldı (o pencere grupları bu adlara bakarak kuruyor).

---

## 9. Kararlar

**Kullanıcı 2026-10-10'da 22 önerinin hepsini kabul etti.** Aşağıdaki her *Öneri* artık karardır; değiştirmek için kullanıcıya sorulur.

1. **Dock simgesi:** her zaman mı, hiç mi (bugünkü), yoksa yalnızca ana pencere açıkken mi? — *Öneri:* yalnızca ana pencere açıkken; Uygulama ayarları'nda "Dock'ta simge göster" seçeneğiyle.
2. **Açılışta ana pencere:** Windows'taki gibi normal açılışta gösterilsin, oturum açılışında (giriş öğesi) gizli kalsın mı? — *Öneri:* evet, Windows'taki gibi.
3. **Menü çubuğu simgesine tıklama:** Windows varsayılanları (sol tık Bölge yakala, çift tık ana pencere, orta tık pano) mı, macOS alışkanlığı (her tık menüyü açar) mı? — *Öneri:* ayarlar Windows'taki gibi gelsin; varsayılan **sol tık menüyü açsın** (macOS'te beklenen bu; çift tık tanımlanınca tek tık da gecikir). Tam birebirlik istersen varsayılanı "Bölge yakala" yaparız.
4. **Görünüm:** Windows'taki "Dark" teması renkleri ve tema düzenleyicisi birebir mi, macOS'in açık / koyu görünümü mü? — *Öneri:* macOS görünümü; Tema sayfasında yalnızca Sistem / Açık / Koyu. Koyu modda Windows'a çok yakın görünür; ShareX tema düzenleyicisi Mac'te pek işe yaramaz.
5. **İkonlar:** Windows'taki Fugue ikonları mı (birebir görünüm; CC BY 3.0, Hakkında'da atıf zaten var), macOS'in SF Symbols ikonları mı? — *Öneri:* Fugue (birebir); menü çubuğunda UpLa logosu.
6. **Metinler:**
   - a) Windows'taki yazım hataları ("Resimi", "Adresden", "tıklıyarak", "Saklancak" …) kopyalansın mı? — *Öneri:* hayır; iki uygulamada da düzeltelim.
   - b) Windows'ta çevrilmemiş metinler (geçmiş menüsündeki Favorite / Edit tag... vb., "Would you like to open this file?") Mac'te Türkçe olsun mu? — *Öneri:* evet, Windows'ta da çevirelim. Gelişmiş özellik adları, efekt adları ve hızlı görev ön ayar adları İngilizce kalsın (Windows'ta da öyle).
   - c) "..." mı, macOS'in "…" karakteri mi? — *Öneri:* "…" (görünüşü aynı, macOS kuralı).
   - d) Hesap metinlerinde "bu Mac" mi, Windows'taki "bu bilgisayar" mı? — *Öneri:* "bu bilgisayar" (Windows metni aynen; Mac için de doğru).
7. **Windows'ta işlevsiz öğeler** (hep gri Kısaltılmış adres / Küçük resim dosya / Küçük resim, Kütüğü karşıya yükle, Metin olarak yükle, ikincil yükleyiciler, yükleyici filtreleri) Mac'te gösterilsin mi? — *Öneri:* hayır.
8. **Varsayılan kısayollar** (Mac'te Print Screen yok):
   - *Öneri:* ⌥⇧⌘3 Tüm ekranı yakala, ⌥⇧⌘4 Bölge yakala, ⌥⇧⌘5 **Aktif pencereyi yakala** (Windows'taki gibi; bugünkü "pencere seç" yerine), ⌥⇧⌘6 Ekran kaydetme başlat/durdur, ⌥⇧⌘7 Ekran kaydetme (GIF) başlat/durdur (Aşama 4'te).
   - Bugünkü "pencere seç" yakalaması Pencere ▸ menüsü ve kısayol listesinde kalabilir.
   - Mac'e PC klavyesi takılıysa Print Screen tuşu F13 olarak görünür ve atanabilir.
9. **Varsayılan görevler ve dosyalar:** Windows'taki gibi mi (Yakalama sonrası panoya kopyala + kaydet + yükle; ad `%ra{10}`; klasör `Belgeler/UpLa/Screenshots/yyyy-MM`), bugünkü Mac gibi mi (yalnızca yükle; ad `UpLa_tarih`; klasör `Resimler/UpLa`)? — *Öneri:* Windows'taki gibi; mevcut kullanıcıların kendi seçtikleri korunur. Not: "Masaüstü ve Belgeler" iCloud'la eşitleniyorsa ekran görüntüleri de iCloud'a gider; istersen klasör `Resimler/UpLa/Screenshots` olur.
10. **Henüz yapılmamış menü öğeleri** yayınlanan sürümde gizli mi, gri mi olsun? — *Öneri:* gizli (yarım öğeler kafa karıştırır, App Store'da da red sebebidir); test sürümlerinde gri gösterme seçeneği olabilir.
11. **Menüler tıklayınca açık kalsın mı** (Windows'ta Yakalama sonrası vb. menüler açık kalıyor; Mac'te özel satır gerekir)? — *Öneri:* Aşama 1'de macOS'in normal davranışı; gerekirse sonra.
12. **Bildirimler:** Windows'taki tost penceresi mi, macOS bildirimleri mi, ikisi de mi? — *Öneri:* varsayılan Windows tostu (birebir); Görev ayarları › Uyarılar'a Mac'e özgü "macOS bildirimi kullan" seçeneği.
13. **Sesler** Windows'taki gibi varsayılan açık mı? — *Öneri:* açık, ShareX'in ses dosyalarıyla.
14. **Araçların önceliği** (Aşama 3 sırası). — *Öneri:* OCR, QR kod, Ekrana sabitle, Ekrandan renk seçici, Resim görüntüleyici, Resim birleştirici, Resim güzelleştirici, Cetvel, Renk seçici, Resim efektleri. Sana gereksiz gelen araç varsa çıkarabiliriz.
15. **Resim düzenleyici kapsamı:** ShareX düzenleyicisinin tamamı mı (26 araç ve bütün menüler), yoksa önce temel set mi? — *Öneri:* önce temel set (Dikdörtgen, Ok, Yazı, Kademe, Vurgula, Bulanıklaştır, Mozaikle, Resmi kırp + geri al, kaydet, kopyala, yükle), kalanı sonra.
16. **Hakkında metni:** Windows'taki "ShareX programını temel alır" cümlesi ve ShareX'in çevirmen / kitaplık listesi Mac için doğru değil (Mac uygulaması ShareX kodu içermiyor). — *Öneri:* aynı düzen; metinde "ShareX'in arayüzünü ve metinlerini örnek alır" gibi doğru bir atıf; yalnızca gerçekten kullanılan bileşenler (Fugue Icons, Sparkle, ShareX metinleri ve sesleri) listelensin.
17. **Bölge yakalama:** Aşama 4'e kadar macOS'in kendi seçimi kalsın mı; sonra hangisi varsayılan olsun? — *Öneri:* Aşama 4'te kendi ekranımız varsayılan olsun (birebir); macOS seçimi Mac'e özgü bir seçenek olarak kalabilir.
18. **Sürüm numarası:** pencere başlığında Mac kendi numarasıyla mı ("UpLa 1.0"), Windows'la hizalı mı ("UpLa 2.x")? — *Öneri:* kendi numarası.
19. **Dağıtım:** Developer ID + notarization (PLAN.md'deki plan) mı, Mac App Store mu? App Store sandbox'ı `screencapture` aracını, Erişilebilirlik iznini (kaydırarak yakalama), aksiyonları ve dizin takibini kısıtlar. — *Öneri:* Developer ID + notarization (Apple Developer Program, yıllık 99 $).
20. **Windows tarafı:** onay işareti hatası (envanter §12.1) ve metin düzeltmeleri Windows'ta da yapılsın mı (2.0.3)? — *Öneri:* evet; küçük ve ayrı bir iş.
21. **Mac'e özgü fazlalar:** menü çubuğu simgesine dosya bırakma ve Geçmiş'teki "Geçmişi Temizle…" kalsın mı? — *Öneri:* kalsın (zararsız); "Geçmişi Temizle…" Geçmiş ayarları penceresine taşınsın.
22. **Başlangıç sırası:** önce PR #3 (ekran kaydı) MacBook'ta test edilip birleştirilsin mi, sonra parite işine mi başlansın? — *Öneri:* evet. Ardından Aşama 1'in ilk PR'ı (metin betiği + model + `MenuBuilder`).

