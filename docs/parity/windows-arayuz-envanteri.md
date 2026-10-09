# UpLa 2.0.2 (Windows): arayüz envanteri

Bu belge Windows'taki UpLa'nın kullanıcının gördüğü her şeyini, uygulamadaki sırasıyla listeler: ana pencere, bütün menüler ve alt menüler, tepsi menüsü, araçlar, yakalama ve yükleme sonrası görevler, ayar pencerelerinin bütün sayfa ve seçenekleri, hesap ve giriş, Hakkında. Amaç, Mac uygulamasını bununla birebir aynı yapmak. Mac ile eşleştirme ve aşamalı plan ayrı belgede: `mac-parite-plani.md`.

**Kaynak.**
- Depo `upla-sharex`, dal `upla`, HEAD `ce4359069`. Sürüm 2.0.2 (`Directory.build.props` › `InformationalVersion`).
- Taban ShareX `v21.0.0` (`d2502561f`). Ondan sonraki 47 commit'in hepsi `upla:` commit'i; `git diff v21.0.0 HEAD` UpLa'nın yaptığı her değişikliği gösterir.

**Yöntem.** Yalnızca kod okundu. Uygulama çalıştırılmadı, iki depoda da hiçbir şey değiştirilmedi. Metinler harfi harfine şu kaynaklardan alındı:
- form metinleri: her formun yanındaki `*.tr.resx` ve `*.resx`;
- enum adları (görev türleri, yakalama sonrası görevler vb.): `ShareX.HelpersLib/Properties/Resources.tr.resx`, anahtar biçimi `EnumTürü_Değer`;
- koddan atanan metinler: `ShareX/Properties/Resources.tr.resx` ve kütüphanelerin kendi `Resources.tr.resx` dosyaları;
- UpLa'nın eklediği metinler: `ShareX.HelpersLib/Upla/UplaStrings.cs`. Bunların yalnızca Türkçe ve İngilizcesi var; başka arayüz dillerinde İngilizce görünürler.

**Doğrulama.** UI Automation ile okunan 2.0.1 ana penceresinin sol panel sırası kodla aynı: Yakala, Yükle, Araçlar, Yakalama sonrası, Yükleme sonrası, Hedefler, Uygulama ayarları..., Görev ayarları..., Kısayol ayarları..., Hedef ayarları..., Giriş yap, Ekran görüntüsü dizini..., Geçmiş..., Resim geçmişi..., Hata ayıklama, Hakkında....

**2.0.3 (2026-10-10).** Bu belge yazıldıktan sonra çıkan 2.0.3 yalnızca §12.1'deki onay işareti hatasını düzeltir (`1ce7e55ff`); başka bir arayüz değişikliği yok. `windows-ref/` klasöründeki ekran görüntüleri 2.0.3'ten alındı ve bu belgedeki metinlerle karşılaştırıldı (dizin: `README.md`).

**Gösterim.**

| İşaret | Anlamı |
|---|---|
| **Kalın Türkçe** (English) | Uygulamanın Türkçe arayüzde gösterdiği metin, harfi harfine; parantez içinde İngilizce arayüzdeki metin |
| ✓ / ☐ | Varsayılan olarak açık / kapalı |
| ▸ | Alt menü açar |
| — | Menü ayırıcısı |
| (UpLa) | ShareX'e göre UpLa'nın değiştirdiği veya eklediği öğe |
| CB, DD, NUM, TXT, BTN, MBTN, LINK, LBL, LIST, PG | Onay kutusu, açılır liste, sayı kutusu, metin kutusu, düğme, menü açan düğme, bağlantı, etiket, liste görünümü, özellik ızgarası |

- Windows metinlerinde "…" yerine üç ayrı nokta ("...") kullanılır.
- Uygulamanın kendi yazım hataları bilerek korundu: "Resimi", "Adresden", "Küçük resim dosya", "ekliyebilirsiniz", "tıklıyarak", "Saklancak", "gelicek", "boyutdan".

**İçindekiler**

0. UpLa'nın ShareX 21'e göre değiştirdikleri
1. Ana pencere
2. Sistem tepsisi
3. Kısayollar
4. Yakalama ve görev akışı (görev pencereleri, bölge yakalama ekranı, resim düzenleyici)
5. Araçlar
6. Ekran kaydı
7. Bildirimler, sesler ve iletişim kutuları
8. Ayar pencereleri
9. Hesap ve giriş penceresi
10. Geçmiş pencereleri
11. Açılış, ilk çalıştırma ve kapanış
12. Windows'taki hatalar ve tuhaflıklar (Mac'e kopyalanmamalı)
13. Değer listeleri

---

## 0. UpLa'nın ShareX 21'e göre değiştirdikleri

Mac'e bunlardan yalnızca UpLa'da görünenler taşınacak. Silinenler ve gizlenenler taşınmaz.

### 0.1 Tamamen silinenler (ana pencere, tepsi ve kod)

| Silinen öğe | Commit |
|---|---|
| Yazı yükle..., Adres kısalt..., Adres kısaltıcılar, Özel yükleyici ayarları..., Yazı yükleme testi, Adres kısaltıcı testi; görev sağ tık menüsünde Adresi kısalt, Google Lens..., Bing görsel arama... | ab03cc772 |
| upla.com.tr dışındaki bütün hedefler (Imgur, Pastebin, FTP, Dropbox, Google Drive, Amazon S3 ve diğerleri), Görev ayarları'ndaki FTP hesabı ve özel yükleyici seçimleri | f9e516e86, ab03cc772 |
| Adres paylaşım servislerinden E-posta, StumbleUpon, Delicious, Pushbullet, Google görsel arama, Bing görsel arama ve özel servis | ab03cc772 |
| Araçlar: arka plan silici, görsel karşılaştırıcı, Avalonia resim düzenleyici ve düzenleyici seçimi | d51837d47 |
| Araçlar: resim ayırıcı, küçük resim yapıcı, video çevirici, video küçük resim yapıcı, hash kontrol, metadata, dizin indeksleyici, pano görüntüleyici, kenarsız pencere, pencere incele, monitör testi | 1622bfe3c |
| "Görüntüyü analiz et..." (yapay zekâ), her yerde | 5e96be3b9 |
| "Otomatik yakalama..." | 657879498 |
| Yakalama sonrası "Küçük resimi dosya olarak kaydet" ve "Görüntüyü analiz et"; Yükleme sonrası "Adresi kısalt" | 1622bfe3c, 5e96be3b9, ab03cc772 |
| Görev ayarları: "Küçük resim" sayfası, "Eski görüntü düzenleyiciyi kullan", panodaki adresi kısaltma ve pano yolundaki dizini indeksleme; gelişmiş özellikler EarlyCopyURL, TextFormat, AutoShortenURLLength | 1622bfe3c, d51837d47, ab03cc772 |
| Uygulama ayarları › Entegrasyon: Chrome uzantısı, Firefox eklentisi ve Steam grupları | 93d8eb61d, f306c97b5 |
| Ekran kayıt ayarları: MPEG-4 / Xvid ve APNG kodlayıcıları, "None" video kaynağı | f12c8b412 |
| Hedef ayarları: "Hassas içerik (NSFW) olarak işaretle" | 1b73e688f |
| 22 kısayol görev türü (liste §3.4) | çeşitli |

### 0.2 Yalnızca ana pencereden çıkarılanlar (tepside duruyor)

`ApplyUplaMainWindowCustomizations()` (`MainForm.cs` ~2262; commit f25739868 ve 771d1671b) açılışta bunları ana pencereden kaldırır:
- Yükle ▸ **Panodan yükle...** ve **Adresden indirip yükle...**
- **İş akışları** düğmesinin tamamı
- Hedefler ▸ **Yazı yükleyiciler**, **Dosya yükleyiciler**, **Adres paylaşım servisleri**
- Hata ayıklama ▸ **Dosya yükleme testi**, **Adres paylaşım testi**
- **Bağış yap...**, **Bizi takip et: @ShareX...**, **Discord...** düğmeleri

Ekran kaydı f25739868'de gizlenmiş, 771d1671b'de geri açılmıştır; şu an görünür.

### 0.3 Kodda olup görünmeyenler

- Uygulama ayarları › Genel: **Güncelleme kanalı:** ve **Geliştirici sürümünü kur...** her UpLa sürümünde gizli. **Güncellemeleri otomatik kontrol et** Microsoft Store sürümünde ve `DisableUpdateCheck` politikası varken gizli.
- Uygulama ayarları › Entegrasyon'daki "UpLa ile yükle", "UpLa ile düzenle" ve "Gönder" kutuları ile Ekran kayıt ayarları'ndaki **Kayıt cihazlarını yükle...** Store sürümünde gizli.
- **UpLa'yı yönetici olarak yeniden başlat** yalnızca DevMode açıkken ve yönetici değilken görünür.

### 0.4 UpLa'nın eklediği veya varsayılanını değiştirdiği

- upla.com.tr hesap menüsü (7c90cd6f7); en sona **Kötüye kullanımı bildir** (1b73e688f); uygulama içi giriş penceresi.
- Her türlü ilk yüklemeden önce bir kerelik soru (ccf863d8f).
- Silme linki açılmadan önce onay (a142e31a7).
- Hedef ayarları'nda upla.com.tr sayfası (`UplaSettingsControl`).
- Ekran kayıtlarını yükleme sınırında durdurma (f6a101731); FFmpeg yoksa indirme (9436a1a08).
- Varsayılanlar:
  - Yakalama sonrası **Resimi yükle** açık (cc7261a12);
  - tek hedef upla.com.tr;
  - aynı anda en çok 5 yükleme; son görevler kaydedilir ve açılışta geri gelir (ccf863d8f);
  - **Print Screen** bölge, **Ctrl + Print Screen** tüm ekran yakalar (c3f6354e9; ShareX'te tersi);
  - adres paylaşım servisi Facebook (ShareX'te E-posta).

---

## 1. Ana pencere

Kaynak: `ShareX/Forms/MainForm.cs`, `MainForm.Designer.cs`, `MainForm.tr.resx`; hesap menüsü `ShareX.UploadersLib/Upla/UplaAccountMenu.cs`. Görsel kontrol: `docs/screenshots/main-window.png`.

### 1.1 Pencere

- **Başlık:** `UpLa 2.0.2`. Uygulama adı + Major.Minor; Build sıfırdan büyükse ".Build" eklenir.
  - Taşınabilir sürümde sonuna " Portable" eklenir (README görüntüsünde "UpLa 2.0 Portable").
  - Yükleme sürerken `UpLa 2.0.2 - 45,0%` (ortalama ilerleme, Türkçe ondalık virgül). Görev çubuğu düğmesi ve tepsi simgesi de ilerlemeyi gösterir.
  - DevMode açıkken " (Release)" veya " (Release, Admin)".
- **Simge:** mavi UpLa "up" logosu.
- **Boyut ve konum:**
  - İç alan 879×531, en küçük 650×500. Açılışta yükseklik, sol paneldeki bütün düğmeler sığacak kadar büyütülür.
  - Ekranın ortasında açılır. Konum ve boyut varsayılan olarak hatırlanmaz.
- **Tema:** "Dark" (§13.7).
  - Arka plan #272727, metin #E7E9EA, menü vurgusu #2E2E2E, menü kenarı #3F3F3F, koyu paneller #222222.
  - Başlık çubuğu da koyu. Menü yazı tipi Segoe UI 9,75 pt.
- **Yerleşim:**
  - Solda yaklaşık 188 px genişliğinde dikey bir araç çubuğu (en az 165 px, iç boşluk 8,6,8,3).
  - Sağda görev alanı (§1.14).
  - Menü çubuğu ve durum çubuğu yok.
  - Uygulama ayarları › Ana pencere › **Menüyü göster** kapatılırsa sol panel gizlenir.
- **Esc** pencereyi kapatır, yani tepsiye gizler (§11).
- Ana pencereden başlatılan bir yakalama önce pencereyi gizler (250 ms) ve yakalamadan sonra geri getirir. Tepsideki aynı öğeler pencereyi gizlemez.

### 1.2 Sol panel, yukarıdan aşağı

Her öğe simgesini ve metnini sola hizalı gösterir. Açılır öğelerin sağ kenarında "▸" oku vardır ve menüleri düğmenin **sağına** açılır.

| # | Türkçe | English | Tür | Simge (Fugue) | Ne yapar |
|---|---|---|---|---|---|
| 1 | **Yakala** | Capture | açılır ▸ | camera | §1.3 |
| 2 | **Yükle** | Upload | açılır ▸ | arrow_090 (mavi yukarı ok) | §1.4 |
| 3 | **Araçlar** | Tools | açılır ▸ | toolbox | §1.5 |
| — | ayırıcı | | | | |
| 4 | **Yakalama sonrası** | After capture tasks | açılır ▸ | image_export | §1.6 |
| 5 | **Yükleme sonrası** | After upload tasks | açılır ▸ | upload_cloud | §1.7 |
| 6 | **Hedefler** | Destinations | açılır ▸ | drive_globe | §1.8 |
| — | ayırıcı | | | | |
| 7 | **Uygulama ayarları...** | Application settings... | düğme | wrench_screwdriver | Modal "UpLa - Uygulama ayarları" (§8.1). Kapanınca tema, başlık, görünüm modu ve yerleşim yeniden uygulanır, iş akışları yeniden kurulur, ayarlar kaydedilir. |
| 8 | **Görev ayarları...** | Task settings... | düğme | gear | Modal "UpLa - Görev ayarları", varsayılan görev ayarları (§8.2). Kapanınca yalnızca **İmleç göster** ve gecikme onayları yenilenir (§12.3), ayarlar kaydedilir. |
| 9 | **Kısayol ayarları...** | Hotkey settings... | düğme | keyboard | Modal "UpLa - Kısayol ayarları" (§8.3). Kapanınca iş akışları ve kısayol tablosu yeniden kurulur, kısayollar kaydedilir. |
| 10 | **Hedef ayarları...** | Destination settings... | düğme | globe_pencil | "UpLa - Hedef ayarları" (§8.4). |
| 11 | **Giriş yap** veya kullanıcı adı | Sign in | açılır ▸ (UpLa) | UpLa uygulama simgesi, 16 px | §1.10. "Hedef ayarları..."nın hemen arkasına eklenir. |
| — | ayırıcı | | | | |
| 12 | **Ekran görüntüsü dizini...** | Screenshots folder... | düğme | folder_open_image | Gezgin'de `<kişisel dizin>\Screenshots\yyyy-MM` açar (desen `%y-%mo`, örn. `Belgeler\UpLa\Screenshots\2026-10`). O ayın klasörü yoksa `...\Screenshots` açılır. |
| 13 | **Geçmiş...** | History... | düğme | application_blog | Modsuz "UpLa - Geçmiş" (§10.1). |
| 14 | **Resim geçmişi...** | Image history... | düğme | application_icon_large | Modsuz "UpLa - Resim geçmişi" (§10.2). |
| — | ayırıcı | | | | |
| 15 | **Hata ayıklama** | Debug | açılır ▸ | traffic_cone | §1.12 |
| 16 | **Hakkında...** | About... | düğme | crown | Modal Hakkında penceresi (§1.13). |

- **Tıklayınca açık kalan menüler:** Yakalama sonrası, Yükleme sonrası, Hedefler ve bütün alt menüleri, "Ekran görüntüsü gecikmesi" alt menüsü. Böylece arka arkaya birkaç öğe değiştirilebilir.
- **Politikayla yükleme kapalıysa** (`DisableUpload`; varsayılan değil): Yükle, Yükleme sonrası, Hedefler, Hedef ayarları, hesap düğmesi ve Resim yükleme testi gizlenir.

### 1.3 Yakala ▸ (Capture)

| # | Türkçe | English | Simge | Ne yapar |
|---|---|---|---|---|
| 1 | **Tam ekran** | Fullscreen | layer_fullscreen | Bütün ekranları tek resim olarak yakalar. |
| 2 | **Pencere** ▸ | Window | application_blue | Yakala her açıldığında yeniden kurulur: görünür her pencere için bir öğe. Başlık 50 karakterden sonra "..." ile kesilir, öğede pencerenin simgesi görünür. Tıklanan pencereyi yakalar. |
| 3 | **Monitör** ▸ | Monitor | monitor | Yakala açılınca kurulur. Öğeler `1. 1920x1080`, `2. 2560x1440` biçiminde; simge ve simge boşluğu yok. Tıklanan monitörü yakalar. |
| 4 | **Bölge** | Region | layer_shape | Bölge yakalama ekranı (§4.7). |
| 5 | **Bölge (Basit)** | Region (Light) | Rectangle | Basit dikdörtgen seçimi. |
| 6 | **Bölge (Saydam)** | Region (Transparent) | layer_transparent | Saydam seçim katmanı. |
| 7 | **Son bölge** | Last region | layers | Son seçilen bölgeyi yeniden yakalar. |
| 8 | **Ekran kaydetme** | Screen recording | camcorder_image | Seçilen bölgenin video kaydını başlatır veya durdurur (§6). |
| 9 | **Ekran kaydetme (GIF)** | Screen recording (GIF) | film | GIF kaydını başlatır veya durdurur (§6). |
| 10 | **Kaydırarak yakalama...** | Scrolling capture... | ui_scroll_pane_image | "UpLa - Kaydırmalı yakalama" penceresi (§4.9). |
| — | ayırıcı | | | |
| 11 | **İmleç göster** | Show cursor | cursor | Tıklayınca değişen onay öğesi. ✓ (`CaptureSettings.ShowCursor`). Tepsideki aynı öğeyle eş zamanlı. |
| 12 | **Ekran görüntüsü gecikmesi: 0sn** ▸ | Screenshot delay: 0s | clock_select | Metin çalışırken `Ekran görüntüsü gecikmesi: {0}sn` olarak kurulur ("0.#" biçimi). Gecikme 0'dan büyükse öğenin kendisi de onaylı görünür. |
| 12.1 | **Gecikme yok** | No delay | – | ✓ |
| 12.2–12.6 | **1 saniye**, **2 saniye**, **3 saniye**, **4 saniye**, **5 saniye** | 1 second ... 5 seconds | – | Radyo düğmesi gibi; menü açık kalır. Görev ayarları'nda 0–5 dışında bir gecikme seçilmişse hiçbiri onaylı görünmez. |

Gecikme yakalamadan önce uygulanır.

### 1.4 Yükle ▸ (Upload)

| # | Türkçe | English | Simge | Ne yapar |
|---|---|---|---|---|
| 1 | **Dosya yükle...** | Upload file... | folder_open_document | Çoklu seçimli "UpLa - Dosya yükle" dosya penceresi. Son kullanılan klasörde, yoksa Masaüstünde açılır. 10'dan fazla dosyada sorar (§7.5). |
| 2 | **Klasör yükle...** | Upload folder... | folder | "UpLa - Dizin yükle" klasör seçicisi. Klasördeki ve alt klasörlerdeki bütün dosyaları yükler; 10'dan fazla dosyada aynı soru. |
| 3 | **Sürükle bırak ile yükle...** | Drag and drop upload... | inbox | Bırakma penceresini açar (§2.6). |

Ana pencereden çıkarılan, tepside duran **Panodan yükle...** ve **Adresden indirip yükle...** için §2.2. Görev alanında **Ctrl+V** yine panodan yükler (§1.14.6).

### 1.5 Araçlar ▸ (Tools)

Tepside de aynısı. Pencerelerin içeriği §5'te.

| # | Türkçe | English | Simge |
|---|---|---|---|
| 1 | **Renk seçici...** | Color picker... | color |
| 2 | **Ekrandan renk seçici...** | Screen color picker... | pipette |
| 3 | **Cetvel...** | Ruler... | ruler_triangle |
| 4 | **Ekrana sabitle...** | Pin to screen... | pin |
| — | ayırıcı | | |
| 5 | **Resim düzenleyici...** | Image editor... | image_pencil |
| 6 | **Resim güzelleştirici...** | Image beautifier... | picture_sunset |
| 7 | **Resim efektleri...** | Image effects... | image_reflection |
| 8 | **Resim görüntüleyici...** | Image viewer... | images_flickr |
| 9 | **Resim birleştirici...** | Image combiner... | document_break |
| — | ayırıcı | | |
| 10 | **OCR...** | OCR... | edit_drop_cap (koyu temada beyaz sürümü) |
| 11 | **QR kod...** | QR code... | barcode_2d (koyu temada beyaz sürümü) |

### 1.6 Yakalama sonrası ▸ (After capture tasks)

- Öğeler `AfterCaptureTasks` enum'undan gelir ("None" atlanır). Her biri simgeli bir onay öğesidir, birkaçı birlikte açık olabilir, menü tıklayınca açık kalır.
- Etiketler `HelpersLib Resources.tr.resx` › `AfterCaptureTasks_*`.
- Görevlerin ne yaptığı ve çalışma sırası: §4.1.

| # | Türkçe | English | Simge | Varsayılan |
|---|---|---|---|---|
| 1 | **Hızlı görev menüsünü göster** | Show quick task menu | ui_menu_blue | ☐ |
| 2 | **"Yakalama sonrası" penceresini göster** | Show "After capture" window | application_text_image | ☐ |
| 3 | **Resmi güzelleştir** | Beautify image | picture_sunset | ☐ |
| 4 | **Resim efekti ekle** ▸ | Add image effects | image_saturation | ☐. Alt menü resim efekti ön ayarlarını radyo öğesi olarak listeler ve her açılışta yeniden kurulur. Varsayılan tek ön ayarın adı **Name** (✓). |
| 5 | **Resim düzenleyicide aç** | Open in image editor | image_pencil | ☐ |
| 6 | **Resimi panoya kopyala** | Copy image to clipboard | clipboard_paste_image | ✓ |
| 7 | **Ekrana sabitle** | Pin to screen | pin | ☐ |
| 8 | **Resimi yazdır** | Print image | printer | ☐ |
| 9 | **Resimi dosya olarak kaydet** | Save image to file | disk | ✓ |
| 10 | **Resimi dosya olarak farklı kaydet...** | Save image to file as... | disk_rename | ☐ |
| 11 | **Aksiyonları gerçekleştir** | Perform actions | application_terminal | ☐ |
| 12 | **Dosyayı panoya kopyala** | Copy file to clipboard | clipboard_block | ☐ |
| 13 | **Dosya yolunu panoya kopyala** | Copy file path to clipboard | clipboard_list | ☐ |
| 14 | **Klasör yolunu panoya kopyala** | Copy folder path to clipboard | folder_bookmark | ☐ |
| 15 | **Dosyayı klasörde göster** | Show file in explorer | folder_stand | ☐ |
| 16 | **QR kodunu tara** | Scan QR code | barcode_2d | ☐ |
| 17 | **Yazı tanı (OCR)** | Recognize text (OCR) | edit_drop_cap | ☐ |
| 18 | **"Yükleme öncesi" penceresini göster** | Show "Before upload" window | application__arrow | ☐ |
| 19 | **Resimi yükle** | Upload image to host | upload_cloud | ✓ (UpLa) |
| 20 | **Dosyayı sil** | Delete file locally | bin | ☐ |

**Gerçek varsayılan:** Resimi panoya kopyala, Resimi dosya olarak kaydet, Resimi yükle (`TaskSettings.cs` satır 55). ShareX 21'de yalnızca ilk ikisi.

⚠ **Windows hatası, Mac'e kopyalanmamalı (§12.1):** Windows açılışta onay işaretlerini 11. öğeden itibaren kaydırarak çizer. Varsayılanlarla yalnızca 6 ve 9 onaylı görünür; yükleme açık olduğu hâlde **"Resimi yükle" onaysız görünür**. Mac gerçek durumu göstermeli: 6, 9 ve 19 onaylı.

### 1.7 Yükleme sonrası ▸ (After upload tasks)

| # | Türkçe | English | Simge | Varsayılan |
|---|---|---|---|---|
| 1 | **"Yükleme sonrası" penceresini göster** | Show "After upload" window | application_browser | ☐ |
| 2 | **Adresi paylaş** | Share URL | globe_share | ☐. Adres paylaşım servisini kullanır (varsayılan Facebook); servis yalnızca tepsiden değiştirilebilir. |
| 3 | **Adresi panoya kopyala** | Copy URL to clipboard | clipboard_paste_document_text | ✓ |
| 4 | **Adresi aç** | Open URL | globe__arrow | ☐ |
| 5 | **QR kod penceresini göster** | Show QR code window | barcode_2d | ☐ |

⚠ Aynı hata: Windows açılışta "Adresi panoya kopyala" yerine **"Adresi aç"ı onaylı** gösterir. Gerçek varsayılan yalnızca "Adresi panoya kopyala".

### 1.8 Hedefler ▸ (Destinations)

Ana pencerede tek öğe var:
- **Resim yükleyici: upla.com.tr** ▸ (Image uploader: upla.com.tr), simge `image`. Metin çalışırken `Resim yükleyici: {0}` olarak kurulur (tasarımdaki metin "Resim yükleyiciler"). Alt menü:
  - **upla.com.tr** ✓ (ImageDestination.Chevereto, "upla.com.tr" olarak gösterilir). Radyo öğesi.
  - **Dosya yükleyici** ▸ (File uploader). Radyo öğesi; yalnızca resim hedefi "dosya yükleyici" ise onaylı.
    - **upla.com.tr** (FileDestination.Chevereto). Yalnızca resim hedefi dosya yükleyiciyse onaylı; seçilince "Dosya yükleyici" de seçilir.
- Menü öğelerinde simge yok; menü tıklayınca açık kalır.
- Ayarları geçersiz bir hedef kırmızı (RGB 200,0,0) çizilir. upla.com.tr'de bu hiç olmaz, çünkü misafir anahtarı her zaman vardır. Renkler menü her açıldığında denetlenir.
- Tepside dört hedef öğesi var (§2.2).

### 1.9 Ayar düğmeleri

Uygulama ayarları..., Görev ayarları..., Kısayol ayarları..., Hedef ayarları...: bkz. §1.2 ve §8.

### 1.10 Hesap düğmesi: "Giriş yap" / kullanıcı adı (UpLa)

Menü her açılışta yeniden kurulur ve `Upla.AccountChanged` olayında güncellenir. Simge: UpLa uygulama simgesi. Yalnızca politikayla yükleme kapalıysa gizlenir.

| Durum | Ana penceredeki düğme metni | Açılır menü, sırasıyla |
|---|---|---|
| A. Misafir (varsayılan) | **Giriş yap** (Sign in) | **Giriş yap...** (Sign in...; giriş penceresi, §9.2) · **Hesap oluştur** (Sign up; https://upla.com.tr/signup) · — · **Kötüye kullanımı bildir** (Report abuse; https://upla.com.tr/page/contact) |
| B. Giriş yapılmış | `<kullanıcı adı>` | **Profilim** (My profile; kayıtlı profil linki, yalnızca geçerli bir upla.com.tr linkiyse görünür) · **Bağlı cihazlar** (Connected devices; https://upla.com.tr/upla-app/devices) · — · **Çıkış yap** (Sign out) · — · **Kötüye kullanımı bildir** |
| C. Giriş yapılmış ama sunucu anahtarı reddetti (geçici durum, kaydedilmez) | `<kullanıcı adı> (tekrar giriş yapın)` | **Tekrar giriş yap...** (Sign in again...) · — · ardından B'deki öğeler |
| D. Kayıtlı oturum bu bilgisayarda okunamıyor (DPAPI; ayarlar başka bilgisayardan gelmiş) | `<kullanıcı adı> (tekrar giriş yapın)` | **Tekrar giriş yap...** · **Misafir olarak devam et** (Continue as a guest; hesabı unutur) · **Bağlı cihazlar** · — · **Kötüye kullanımı bildir** |
| E. Elle girilmiş API anahtarı (gelişmiş, kullanıcı adı yok) | A ile aynı (**Giriş yap**) | A ile aynı. Yüklemeler anahtarı kullanır; anahtar Hedef ayarları'ndan kaldırılır. |
| F. Ayarlar henüz yükleniyor | **Giriş yap** | Tek bir **devre dışı** "Giriş yap..." |

**Tepside** aynı menü daha uzun başlıkla görünür: "upla.com.tr hesabı", "upla.com.tr hesabı: `<kullanıcı adı>`", "upla.com.tr hesabı: `<kullanıcı adı>` (tekrar giriş yapın)".

**Çıkış yap** akışı §9.3'te.

### 1.11 Ekran görüntüsü dizini..., Geçmiş..., Resim geçmişi...

§1.2'deki tablo; pencereler §10'da.

### 1.12 Hata ayıklama ▸ (Debug)

1. **Hata ayıklama kütüğü...** (Debug log...), simge application_monitor. "UpLa - Hata ayıklama kütüğü" penceresi (760×541):
   - Canlı kütük metni pencereyi doldurur; içindeki linkler tıklanabilir.
   - Altında **Başlama yolu:** (Startup path) ve uygulama klasörüne bir link.
   - Soldan sağa düğmeler:
     1. **Hepsini kopyala** (Copy all)
     2. **Kütük dosyasını aç...** (Open log file...); kütük kaydı kapalıysa devre dışı
     3. **Yüklenen kütüphaneler** (Loaded assemblies); yüklü DLL'leri kütüğe yazar
     4. **Kütüğü karşıya yükle...** (Upload log...); önce "Hata ayıklama kütüğü hassas bilgiler içerebilir. Devam etmek istediğinize emin misiniz?" diye sorar, sonra kütüğü metin olarak yükler. upla.com.tr metin kabul etmediği için her zaman hata ile biter (§12.4).
   - Kütük dosyası: `<kişisel dizin>\Logs\UpLa-Log-yyyy-MM.txt`.
2. **Resim yükleme testi** (Test image upload), simge image. UpLa logosu PNG'sini upla.com.tr'ye yükler. Yalnızca yükleme çalışır; Yükleme sonrası görevler yine uygulanır, yani adres kopyalanır.

### 1.13 Hakkında penceresi (AboutForm)

- **Pencere:** başlık "UpLa - Hakkında" (UpLa - About); iç alan 1009×601, sabit kenarlık, büyütme düğmesi yok, ortada açılır, Segoe UI 9,75; modal.
- **Sol panel** (400×601, #232323): `About_Logo.png` (400×600), büyük mavi "up" logosu ve altında "UpLa". Tıklayınca renkli dönen çizgi animasyonu başlar ve ses çalar; animasyona 10 kez tıklamak pencereyi zıplatır (gizli sürpriz).
- **Sağ üst:**
  - `UpLa 2.0.2` (Segoe UI 15,75 kalın).
  - Altında güncelleme satırı: önce dönen simge ve **Güncellemeler kontrol ediliyor...** (Checking for updates...); sonra **UpLa güncel** (UpLa is up to date), güncelleyiciyi açan **Yeni bir UpLa sürümü mevcut** linki ya da **Güncelleme kontrolü yapılamadı**. Pencere açılınca GitHub'daki Agnostique/UpLa denetlenir. Store sürümü bunun yerine "Microsoft Store" yazar ve denetlemez.
- **Sağda salt okunur zengin metin kutusu** (560×496). Başlıklar kalın 13 pt, linkler tıklanabilir:

```
UpLa
UpLa, upla.com.tr'nin ekran görüntüsü alma ve yükleme uygulamasıdır. ShareX Ekibi'nin geliştirdiği özgür ve açık kaynaklı ShareX programını temel alır ve GNU Genel Kamu Lisansı sürüm 3 (GPL v3) ile dağıtılır. UpLa resmi bir ShareX sürümü değildir; ShareX Ekibi tarafından desteklenmez.

Web sitesi: https://upla.com.tr
Kaynak kod: https://github.com/Agnostique/UpLa
Lisans: GNU General Public License v3 - https://www.gnu.org/licenses/gpl-3.0.html

ShareX
Web sitesi: https://getsharex.com
Proje sayfası: https://github.com/ShareX/ShareX

ShareX Ekibi
Jaex: https://github.com/Jaex
McoreD: https://github.com/McoreD

Çevirmenler
Türkçe: https://github.com/Jaex
Almanca: https://github.com/Starbug2 & https://github.com/Kaeltis
Fransızca: https://github.com/nwies & https://github.com/Shadorc
Basitleştirilmiş çince: https://github.com/jiajiechan
Macarca: https://github.com/devBluestar
Korece: https://github.com/123jimin
İspanyolca: https://github.com/ovnisoftware
Hollandaca: https://github.com/canihavesomecoffee
Portekizce (Brezilya): https://github.com/RockyTV & https://github.com/athosbr99
Vietnamca: https://github.com/thanhpd
Rusça: https://github.com/L1Q
Geleneksel çince: https://github.com/alantsai
İtalyanca: https://github.com/pjammo
Ukrayna: https://github.com/6c6c6
Endonezyaca: https://github.com/Nicedward
Meksika İspanyolcası: https://github.com/absay
Farsça: https://github.com/pourmand1376
Portekizce: https://github.com/FarewellAngelina
Japonca: https://github.com/kanaxx
Rumence: https://github.com/Edward205
Lehçe: https://github.com/RikoDEV
İbranice: https://github.com/erelado
Arapça: https://github.com/OthmanAliModaes

Katkıda bulunanlar
Json.NET: https://github.com/JamesNK/Newtonsoft.Json
Fugue Icons: http://p.yusukekamiyamane.com
ImageListView: https://github.com/oozcitak/imagelistview
FFmpeg: https://www.ffmpeg.org
Recorder devices: https://github.com/rdp/screen-capture-recorder-to-video-windows-free
ZXing.Net: https://github.com/micjahn/ZXing.Net

Copyright (c) 2007-2026 ShareX Team
```

İngilizce başlıklar: Website, Source code, License, Project page, ShareX Team, Translators, Credits. Açıklama `UplaStrings.AboutDescription`. ShareX'in değişiklik günlüğü, gizlilik, bağış ve topluluk linkleri bilerek çıkarıldı (4c2ef255b).

### 1.14 Görev alanı (sağ taraf)

#### 1.14.1 Boş durum: kısayol tablosu

Görev yokken ve `ShowMainWindowTip` açıkken (varsayılan) görev alanını bir tablo kaplar: iç boşluk 16,16, Segoe UI 12. README görüntüsündeki ekran budur.

- **Sütunlar:**
  1. Başlıksız ince renkli şerit: kısayol kayıtlıysa yeşil (80,160,80), kaydedilemediyse kırmızı (200,80,80).
  2. **Kısayol tuşu** (Hotkey), ortalı.
  3. **Açıklama** (Description).
- **Varsayılan satırlar:**

| Kısayol tuşu | Açıklama |
|---|---|
| Ctrl + Print Screen | Tüm ekranı yakala (Capture entire screen) |
| Print Screen | Bölge yakala (Capture region) |
| Alt + Print Screen | Aktif pencereyi yakala (Capture active window) |
| Shift + Print Screen | Ekran kaydetme başlat/durdur (Start/Stop screen recording) |
| Ctrl + Shift + Print Screen | Ekran kaydetme (GIF) başlat/durdur (Start/Stop screen recording (GIF)) |

- Çift tık Kısayol ayarları'nı açar. Sağ tık görev menüsünü açar (§1.15); bu durumda menüde yalnızca görünüm değiştirme öğesi vardır.

#### 1.14.2 Küçük resim görünümü (varsayılan, `TaskViewMode = ThumbnailView`)

- **Yerleşim:** kendi kaydırma çubuğu olan bir kutucuk akışı; **en yeni kutucuk başta** (sol üst). Kutucuk 200×150 + 4 boşluk; panel yuvarlak köşeli, temanın koyu renginde.
- **Her kutucukta:**
  - **Başlık** (dosya adı) resmin **üstünde**, Segoe UI 9 kalın. Başlığa tıklamak adresi, adres yoksa dosyayı açar. İpucu adresi gösterir; adres veya yol varsa el imleci çıkar.
  - **Küçük resim:** resim dosyalarında resmin kendisi; videolarda Windows kabuk küçük resmi ve üstünde "Oynat" simgesi; diğer dosyalarda büyük dosya türü simgesi.
  - **Durum çizgisi:** kutucuğun üst kenarında 1 px yatay gradyan. Sırada veya çalışırken soluk yeşil, bitince veya durdurulunca CornflowerBlue, hatada kırmızı, geri yüklenen öğelerde yok (§1.14.4).
  - Yükleme sürerken yüzde yazılı **ilerleme çubuğu**.
  - Görev başarısızsa üst ortada kırmızı **"Hata"** rozeti; tıklayınca hata penceresi açılır (§1.15, Hataları göster).
  - Seçiliyken noktalı çerçeve.
- **Fare:**
  - Küçük resme tıklamak varsayılan eylemi yapar: resimde bütün kutucuklarla, bu kutucuktan başlayarak yerleşik resim görüntüleyiciyi açar; video veya metinde dosyayı açar; diğer dosyalarda "Would you like to open this file?" diye sorar (bu metin çevrilmemiş; başlık "UpLa - Onay").
  - Ctrl+tık seçime ekler, Shift+tık aralık seçer, boşluğa tıklamak seçimi kaldırır.
  - Sağ tık görev menüsünü açar.
- **Sürükle bırak:**
  - Küçük resmi sürüklemek dosyayı dışarı sürükler (kopyala veya taşı).
  - Bir **resim dosyası bir resim kutucuğunun üstüne** bırakılınca kutucuk iki yarıya ayrılır: **Resimleri birleştir (Yatay)** / **Resimleri birleştir (Dikey)**. Bırakılan yarıya göre iki resim birleştirilir ve sonuç yeni bir görev olarak işlenir.

#### 1.14.3 Liste görünümü

Görev menüsündeki **Liste görünümüne geç** ile açılır.

**Sütunlar.** Başlık satırı görünür (`ShowColumns`), başlıklara tıklanmaz, genişlikler hatırlanır, son sütun kalan genişliği doldurur.

| Sütun | Varsayılan genişlik | İçerik |
|---|---|---|
| **Dosya adı** (Filename) | 150 | Dosya adı, solunda durum simgesi |
| **Durum** (Status) | 60 | **Sırada** (In queue) → **Hazırlanıyor** (Preparing) / **Başlatılıyor** (Starting) → **Yükleniyor** (Uploading); yükleme sürerken "45,0%". Sonda **Tamamlandı** (Done), **Hata** (Error) veya **Durduruldu** (Stopped). Diğer: **İndiriliyor** (Downloading), **Durduruluyor** (Stopping). Geri yüklenen öğeler **Geçmiş** (History). |
| **İlerleme** (Progress) | 125 | "1,23 MB / 4,56 MB" (ondalık birimler). Geri yüklenen öğelerde bitiş tarihi ve saati. |
| **Hız** (Speed) | 75 | "512 KB/s" |
| **Geçen** (Elapsed) | 45 | "mm:ss" (bir saati geçince h:mm:ss) |
| **Kalan** (Remaining) | 45 | "mm:ss" |
| **Adres** (URL) | 145 | Adres. Yüklenmemiş bir yakalamada yerel yol. Görev başarısızsa boş. |

- **Satır simgeleri:** mavi yukarı ok (navigation_090_button) yükleniyor; kırmızı X (cross_button) hata; yeşil tik (tick_button) bitti veya durduruldu; sağa ok (navigation_000_button) sırada; saat: geri yüklenen öğe.
- **Satırlar ve seçim:** yeni satır alta eklenir; açılıştan sonra son satıra kaydırılır. Satırın tamamı seçilir, çoklu seçim var, Ctrl+A hepsini seçer. Satır ipuçları gösterilir. Çift tık adresi (yoksa dosyayı) açar. Satırları sürüklemek dosyaları dışarı sürükler; Ctrl ile sürüklemek adresleri metin olarak sürükler.
- **Önizleme bölmesi** (`ImagePreview = Automatic`, konum `Side`):
  - Listenin sağında, 335 px'teki bir ayırıcının arkasında; ayırıcının yeri hatırlanır.
  - Yalnızca seçili satır bir resim dosyası veya resim adresiyse görünür; değilse liste tam genişliği kullanır.
  - Damalı arka plan. Fareyle üstüne gelince alt ortada "G x Y" etiketi.
  - Sol tık listedeki bütün dosyalarla resim görüntüleyiciyi açar. Sağ tıkta tek öğe: **Resim kopyala** (Copy image).
  - Yüklenirken **Resim yükleniyor...** / **Resim yükleniyor: {0}%**.

#### 1.14.4 Yeniden açılışta geri gelen görevler (UpLa varsayılanı)

- `RecentTasksSave` açık (ccf863d8f), en fazla 10 görev.
- Yeniden açılışta son 10 sonuç **Geçmiş** durumlu öğeler olarak geri gelir: listede saat simgesi, kutucukta durum çizgisi yok.
- Bu yüzden kısayol tablosu yalnızca ilk kurulumda veya **Listeyi temizle**'den sonra görünür.

#### 1.14.5 Seçim kuralları

Birkaç öğe seçiliyken kopyalama komutları değerleri satır sonlarıyla birleştirir ve başarıda ses çalar.

#### 1.14.6 Klavye (liste ve küçük resimler)

| Tuş | Ne yapar |
|---|---|
| Enter | Adresi, adres yoksa dosyayı açar |
| Ctrl+Enter | Dosyayı açar |
| Shift+Enter | Bulunduğu klasörü açar |
| Ctrl+C | Adresi, adres yoksa yolu kopyalar |
| Shift+C | Dosyayı kopyalar |
| Alt+C | Resmi kopyalar |
| Ctrl+Shift+C | Dosya yolunu kopyalar |
| Ctrl+X | Adresi kopyalar ve satırı listeden kaldırır |
| Ctrl+V | Panodan yükler; kapatılmadıysa önce "UpLa - Pano içeriği" penceresi (§2.7) |
| Ctrl+U | Seçili dosyayı yeniden yükler |
| Ctrl+D | Adresteki dosyayı indirir |
| Ctrl+E | Resmi düzenler |
| Ctrl+P | Resmi ekrana sabitler |
| Del | Listeden kaldırır (çalışan görevler kaldırılmaz) |
| Shift+Del | Dosyaları **sormadan** Geri Dönüşüm Kutusu'na taşır ve satırları kaldırır |
| Menü (Apps) tuşu | Seçili satırın altında görev menüsünü açar (yalnızca liste görünümü) |

### 1.15 Görev sağ tık menüsü (cmsTaskInfo)

Menü açılmadan önce yeniden kurulur. Sıra sabittir; hangi öğenin görüneceği aşağıdaki kurallara bağlıdır. "Aç" ve "Kopyala" alt menülerinde simge sütunu yok.

| # | Türkçe | English | Gösterilen kısayol | Simge | Ne zaman görünür / ne yapar |
|---|---|---|---|---|---|
| 1 | **Hataları göster** | Show errors | | exclamation_button | Yalnızca seçili görev başarısızsa. "UpLa - Hata" penceresi: **Yükleme hataları** başlığı, **Kütük dosyasını aç...** ve **Tamam** düğmeleri. |
| 2 | **Yüklemeyi durdur** | Stop upload | | cross_button | Yalnızca seçili görevlerden biri çalışıyorsa. Bu durumda yalnızca 2, 3 ve son üç öğe görünür. |
| 3 | **Aç** ▸ | Open | | folder_open_document | Bir satır seçiliyse her zaman. Alt menü aşağıda. |
| 4 | **Kopyala** ▸ | Copy | | document_copy | Görev çalışmıyorsa. Alt menü aşağıda. |
| 5 | **Yükle** | Upload | Ctrl+U | drive_upload | Dosya varsa; dosyayı yeniden yükler. |
| 6 | **İndir** | Download | Ctrl+D | drive_download | Adresin son parçasında "." varsa (dosya adresi). Dosyayı ekran görüntüsü klasörüne yeni bir görev olarak indirir. |
| 7 | **Resim düzenle...** | Edit image... | Ctrl+E | image_pencil | Resim dosyasıysa |
| 8 | **Resmi güzelleştir...** | Beautify image... | | picture_sunset | Resim dosyasıysa |
| 9 | **Resim efekti ekle...** | Add image effects... | | image_saturation | Resim dosyasıysa |
| 10 | **Ekrana sabitle** | Pin to screen | Ctrl+P | pin | Resim dosyasıysa |
| 11 | **Aksiyon çalıştır** ▸ | Run action | | application_terminal | Görev ayarları › Aksiyon'daki bir aksiyon dosya uzantısına uyuyorsa; her aksiyon program simgesiyle listelenir. Varsayılan liste boş olduğundan öğe gizlidir. Görev ayarları bir kez açılınca Paint (kuruluysa Paint.NET, Photoshop, IrfanView, XnView) eklenir ve öğe resimlerde görünür. |
| 12 | **Listeden sil** | Remove task from list | Del | script__minus | Görev çalışmıyorsa her zaman |
| 13 | **Yerel dosya sil...** | Delete file locally... | Shift+Del | bin | Dosya varsa. "UpLa - Dosya silme onayı" başlığıyla "Bu dosyayı gerçekten silmek istiyor musunuz?" diye sorar (Evet/Hayır); dosyayı Geri Dönüşüm Kutusu'na taşır ve satırı kaldırır. |
| 14 | **Adresi paylaş** ▸ | Share URL | | globe_share | Adres varsa. Alt menü: Facebook, Reddit, Pinterest, Tumblr, LinkedIn, VK (simge sütunu yok). |
| 15 | **QR kod göster...** | Show QR code... | | barcode_2d | Adres varsa; adres için "UpLa - QR kod" açılır. |
| 16 | **Resimden yazı yakala (OCR)...** | OCR image... | | edit_drop_cap | Resim dosyasıysa |
| 17 | **Resimleri birleştir...** ▸ | Combine images... | | document_break | Birden fazla resim dosyası seçiliyse. Öğeye tıklamak resim birleştiriciyi açar. Alt menü: **Yatay olarak birleştir** (Combine horizontally, application_tile_horizontal), **Dikey olarak birleştir** (Combine vertically, application_tile_vertical). |
| 18 | **Yanıtı göster...** | Show response... | | application_browser | Sunucu yanıtı boş değilse. "UpLa - Yanıt" penceresi; sekmeler **Sonuç**, **Yanıt bilgisi**, **Yanıt içeriği**, **İnternet tarayıcı**. |
| 19 | **Listeyi temizle** | Clear task list | | eraser | Liste boş değilse. Biten bütün satırları siler **ve** tepsideki "Son bağlantılar"ı da boşaltır. |
| — | ayırıcı | | | | 19 ile birlikte görünür |
| 20 | **Küçük resim görünümüne geç** / **Liste görünümüne geç** | Switch to thumbnail view / Switch to list view | | application_icon_large / application_list | Her zaman. Metin o anki görünüme göre değişir; varsayılan küçük resim görünümünde "Liste görünümüne geç". |

Hiçbir şey seçili değilken sağ tık yalnızca 19 ve 20'yi gösterir.

**Aç ▸ (Open).** Bütün öğeler her zaman görünür; uygun değilse gri olur.
1. **Adres** (URL) — Enter
2. **Kısaltılmış adres** (Shortened URL) — adres kısaltıcı olmadığından UpLa'da hep gri
3. **Küçük resim adresi** (Thumbnail URL)
4. **Silme adresi** (Deletion URL) — önce sorar (UpLa): uyarı simgeli Evet/Hayır, başlık **Silme linki**, metin "Silme linki açıldığında yüklenen dosya sunucudan hemen ve kalıcı olarak silinebilir. Devam etmek istiyor musunuz?"; varsayılan düğme **Hayır**
5. —
6. **Dosya** (File) — Ctrl+Enter
7. **Dizin** (Folder) — Shift+Enter
8. **Küçük resim dosya** (Thumbnail file) — küçük resim dosyası kaydedilmediğinden UpLa'da hep gri

**Kopyala ▸ (Copy).** Bütün öğeler her zaman görünür; uygun değilse gri olur.
1. **Adres** (Ctrl+C) · **Kısaltılmış adres** (hep gri) · **Küçük resim adresi** · **Silme adresi**
2. —
3. **Dosya** (Shift+C) · **Resim** (Alt+C) · **Resim boyutları** ("G x Y" kopyalar) · **Yazı** (yalnızca metin dosyaları) · **Küçük resim dosya** (hep gri) · **Küçük resim** (hep gri)
4. —
5. **HTML bağlantı** `<a href="$url">$url</a>` · **HTML resim** `<img src="$url">` · **HTML bağlantılı resim** `<a href="$url"><img src="$thumbnailurl"></a>`
6. —
7. **Forum (BBCode) bağlantı** `[url]$url[/url]` · **Forum (BBCode) resim** `[img]$url[/img]` · **Forum (BBCode) bağlantılı resim** `[url=$url][img]$thumbnailurl[/img][/url]`
8. —
9. **Markdown bağlantı** `[$url]($url)` · **Markdown resim** `![]($url)` · **Markdown bağlantılı resim** `[![]($thumbnailurl)]($url)`
10. —
11. **Dosya yolu** (Ctrl+Shift+C) · **Dosya adı** (uzantısız) · **Dosya adı uzantısıyla birlikte** · **Klasör** (klasör yolu)
12. İsteğe bağlı: ayırıcı ve Uygulama ayarları › Pano biçimleri'ndeki özel biçimler. Varsayılan olarak yok, bu bölüm gizli.

"Resim" türevleri (HTML resim, Forum resim, Markdown resim ve bağlantılı resimler) bir resim adresi ister, yani uzantısı resim olan bir link. Varsayılan link türü **Sayfa linki (önerilen)** iken gri, **Doğrudan dosya linki** seçiliyken etkin.

### 1.16 Sürükle bırak

**Ana pencereye bırakma** (pencerenin tamamı kabul eder):
- **Dosyalar** yüklenir. Klasörler bütün dosyaları ve alt klasörleriyle yüklenir. 10'dan fazla dosyada §7.5'teki onay sorulur.
- **Resim verisi (bitmap)** bir yakalama gibi işlenir; Yakalama sonrası görevler çalışır (varsayılan: kopyala, kaydet, yükle).
- **Metin** metin olarak yüklenir; upla.com.tr bunu reddeder (desteklenmeyen tür hatası).
- Bu türlerde imleç "Kopyala", diğerlerinde "Yok" gösterir.

**Bırakma penceresi:** §2.6. **Dışarı sürükleme:** §1.14.2 (kutucuklar) ve §1.14.3 (satırlar).

---

## 2. Sistem tepsisi

Kaynak: `MainForm.Designer.cs` (`niTray`, `cmsTray`), `MainForm.cs` (tepsi olayları, `InitializeUplaAccountMenus`).

### 2.1 Simge ve tıklama eylemleri

- **Simge:** UpLa logosu (`ShareX_Icon.ico`, UpLa 1.0 simgesiyle değiştirildi). **Beyaz UpLa ikonu kullan** ☐ açılırsa `ShareX_Icon_White.ico`.
- **İpucu:** `UpLa`. DevMode'da tam başlık, örn. "UpLa 2.0 (Release)".
- **Görünürlük:** **Bildirim alanında simge göster** ✓. Kapalıysa ana pencereyi kapatmak uygulamadan çıkar.
- **İlerleme:** **Tepsi simgesinde durum göster** ✓. Yükleme sürerken simge 16×16 koyu bir kareye (39,39,39) dönüşür; kare alttan maviyle (16,116,193) dolar, ortasında beyaz Arial 10 ile yüzde (0–99) yazar. **Görev çubuğu tuşunda durum göster** ✓ görev çubuğu düğmesinde de ilerleme gösterir.
- **Menü teması:** seçili uygulama teması (varsayılan "Dark": arka plan 39,39,39; metin 231,233,234; vurgu 46,46,46; kenar 63,63,63).
- **Kaydetme:** tepsi menüsü kapanınca bütün ayarlar kaydedilir; menü **Çıkış** ile kapandıysa kaydedilmez.

Tıklama eylemleri Uygulama ayarları › Genel'de seçilir; her liste §3.3'teki 54 eylemin tamamını içerir.

| Fare | Ayar etiketi | Varsayılan | Not |
|---|---|---|---|
| Sol tık | **Tepsi simgesi bir kere tıklandığında:** (On tray icon left click:) | **Bölge yakala** (Capture region) | Çift tık eylemi tanımlı olduğu için sistemin çift tık süresi (~0,5 sn) kadar bekler; çift tık eylemi yoksa hemen çalışır. |
| Çift tık | **Tepsi simgesi çift tıklandığında:** (On tray icon double left click:) | **Ana pencereyi aç** (Open main window) | |
| Orta tık | **Tepsi simgesi orta tuş ile tıklandığında:** (On tray icon middle click:) | **İçerik gösterici ile panodan yükle** (Upload from clipboard with content viewer) | Pano içeriği penceresini açar (§2.7). |
| Sağ tık | sabit | Tepsi menüsü | Gelişmiş `TrayAutoExpandCaptureMenu` ☐ açıksa Yakala alt menüsü kendiliğinden açılır. |

**Tepsi menüsünü aç/kapat** kısayol eylemi menüyü imlecin yerinde açar.

### 2.2 Tepsi menüsü (cmsTray), sırasıyla

1. **Yakala** ▸ (camera): §1.3'teki 12 öğenin aynısı; ana pencereyi gizlemez.
2. **Yükle** ▸ (arrow_090):
   1. **Dosya yükle...**
   2. **Klasör yükle...**
   3. **Panodan yükle...** (Upload from clipboard..., clipboard). Gelişmiş `ShowClipboardContentViewer` ✓ açıksa önce Pano içeriği penceresi (§2.7), değilse doğrudan yükler. Yalnızca tepside.
   4. **Adresden indirip yükle...** (Upload from URL..., drive). §2.4. Yalnızca tepside.
   5. **Sürükle bırak ile yükle...**
3. **İş akışları** ▸ (Workflows, categories). Yalnızca içinde öğe varsa görünür.
   - Eylemi "Hiçbiri" olmayan her kısayol için bir öğe. Gelişmiş `WorkflowsOnlyShowEdited` ☐ açıksa yalnızca düzenlenmiş kısayollar.
   - Öğe: kısayolun açıklaması ya da eylem adı; kısayolun kendi görev ayarları varsa sonunda "*"; sağa yaslı kısayol; eylemin simgesi. Tıklamak eylemi çalıştırır.
   - Varsayılan beş öğe: **Tüm ekranı yakala** `Ctrl + Print Screen` · **Bölge yakala** `Print Screen` · **Aktif pencereyi yakala** `Alt + Print Screen` · **Ekran kaydetme başlat/durdur** `Shift + Print Screen` · **Ekran kaydetme (GIF) başlat/durdur** `Ctrl + Shift + Print Screen`.
   - "Kısayol ayarlarından yeni iş akışı ekliyebilirsiniz..." ipucu öğesi tepside yok; yalnızca ana penceredeki (UpLa'da kaldırılmış) İş akışları düğmesinde vardı.
4. **Araçlar** ▸ (toolbox): §1.5'teki 11 öğe.
5. —
6. **Yakalama sonrası** ▸ (image_export): §1.6; aynı onay işareti hatası.
7. **Yükleme sonrası** ▸ (upload_cloud): §1.7; aynı hata.
8. **Hedefler** ▸ (drive_globe). Öğe metinleri çalışırken kurulur; yapılandırılmamış hedef kırmızı çizilir.
   - **Resim yükleyici: upla.com.tr** ▸ (image): §1.8.
   - **Metin yükleyici: upla.com.tr** ▸ (Text uploader, notebook) → **Dosya yükleyici** ✓ ▸ **upla.com.tr** ✓. Metnin kendi hedefi yok; upla.com.tr metin dosyalarını bilgisayarda, gönderilmeden reddeder.
   - **Dosya yükleyici: upla.com.tr** ▸ (File uploader, application_block) → **upla.com.tr** ✓.
   - **Adres paylaşım servisi: Facebook** ▸ (URL sharing service, globe_share) → **Facebook** ✓, **Reddit**, **Pinterest**, **Tumblr**, **LinkedIn**, **VK**.
9. —
10. **Uygulama ayarları...** (wrench_screwdriver)
11. **Görev ayarları...** (gear)
12. **Kısayol ayarları...** (keyboard)
13. **Kısayolları devre dışı bırak** (Disable hotkeys, keyboard__minus). Kısayollar kapalıyken **Kısayolları aktif et** (Enable hotkeys, keyboard__plus). Değiştirmek bir tost gösterir (§7.3). Yalnızca tepside.
14. **Hedef ayarları...** (globe_pencil)
15. **upla.com.tr hesabı** ▸ (UpLa logosu, 16 px; UpLa): §1.10. Hedef ayarları'nın hemen arkasına eklenir.
16. —
17. **Ekran görüntüsü dizini...** (folder_open_image)
18. **Geçmiş...** (application_blog)
19. **Resim geçmişi...** (application_icon_large)
20. —
21. **UpLa'yı yönetici olarak yeniden başlat** (Restart UpLa as admin, uac). Yalnızca DevMode açık ve uygulama yönetici değilken; varsayılan olarak gizli.
22. **Son bağlantılar** ▸ (Recent links, clipboard_list). Yalnızca **Son görevleri kaydet** ✓ ve **Tepsi menüsünde son görevleri göster** ✓ açıkken ve en az bir son görev varken görünür (UpLa son görevleri varsayılan olarak kaydeder; ShareX 21'de kapalı).
    - Devre dışı ipucu satırı: **Adresi kopyalamak için sol tıklayın. Adresi açmak için sağ tıklayın.** (Left click to copy URL to clipboard. Right click to open URL.)
    - —
    - En fazla 10 öğe (`RecentTasksMaxCount`), en eskisi başta (**Tepsi menüsünde son görevleri ilk göster** ☐ açıksa tersi). Öğe `[HH:mm:ss] <link>`; link 50 karakteri aşarsa başına "..." konarak kesilir, böylece sonu görünür. İpucu tam linki gösterir. Sol tık linki kopyalar, sağ tık açar (link yoksa dosyayı).
23. **Aksiyonlar araç çubuğunu göster/sakla** (Toggle actions toolbar, ui_toolbar__arrow): §2.5. Yalnızca tepside.
24. **UpLa penceresini göster** (Open main window, tick_button): ana pencereyi gösterir ve öne getirir. Yalnızca tepside.
25. **Çıkış** (Exit, cross_button): uygulamadan çıkar. Ekran kaydı sürüyorsa önce sorar (§7.5). Yalnızca tepside.

Politikayla yükleme kapalıysa (`DisableUpload`, varsayılan değil) Yükle, Yükleme sonrası, Hedefler, Hedef ayarları... ve hesap öğesi gizlenir.

### 2.3 Tepsi menüsü ile ana pencerenin farkları

- **İkisinde aynı:** Yakala (12 öğe, iki ekran kaydı dahil), Araçlar (11 öğe), Yakalama sonrası, Yükleme sonrası, dört ayar öğesi, Ekran görüntüsü dizini..., Geçmiş..., Resim geçmişi....
- **Ana pencerede eksik:** Yükle'de yalnızca Dosya yükle..., Klasör yükle..., Sürükle bırak ile yükle...; İş akışları yok; Hedefler'de yalnızca resim yükleyici.
- **Hesap öğesinin metni:** ana pencerede **Giriş yap** veya kullanıcı adı; tepside "upla.com.tr hesabı" veya "upla.com.tr hesabı: <kullanıcı adı>".
- **Yalnızca ana pencerede:** Hata ayıklama ▸, Hakkında....
- **Yalnızca tepside:** Kısayolları devre dışı bırak, Son bağlantılar, Aksiyonlar araç çubuğunu göster/sakla, UpLa penceresini göster, Çıkış.

### 2.4 Adresden indirip yükleme

**Adresden indirip yükle...** bir giriş kutusu açar: **Adresten dosya indir ve yükle** (URL to download and upload). Kutu panodaki bir adresle önceden doldurulur. Dosya indirilir, sonra yüklenir.

### 2.5 Aksiyonlar araç çubuğu

- **Açan:** **Aksiyonlar araç çubuğunu göster/sakla** (tepsi veya kısayol). Varsayılan olarak açılışta başlamaz (`ActionsToolbarRunAtStartup` ☐).
- **Görünüm:** "UpLa" başlığıyla başlayan yüzen bir araç çubuğu.
  - Başlığın ipucu: "Sol fare tuşuna basılı tut sürüklemek için\nSağ fare tuşu menüyü açmak için\nOrta fare tuşu kapatmak için".
  - Simge düğmeleri, ipucu olarak eylem adı: **Bölge yakala**, **Tüm ekranı yakala**, **Ekran kaydetme başlat/durdur**, ayırıcı, **Dosya yükle**, **İçerik gösterici ile panodan yükle**.
- **Başlık menüsü:** **Kapat** (Close) · — · **Konumu kitle** (Lock position) ☐ · **En üstte dur** (Stay top most) ✓ · **UpLa başlangıcında aç** (Open at UpLa startup) ☐ · — · **Düzenle...** (Edit...). Düzenleme penceresinde araç çubuğuna eklenebilecek bir **Ayırıcı** (Separator) öğesi de var.

### 2.6 Bırakma penceresi ("Buraya sürükle")

- **Açan:** Yükle › **Sürükle bırak ile yükle...** ve aynı adlı kısayol eylemi.
- **Görünüm:** 150×150, her zaman üstte, CornflowerBlue bir kare; siyah kenar ve 5 px WhiteSmoke iç çerçeve. Ortasında kalın Arial 20 ile, siyah gölgeli beyaz **Buraya\nsürükle** (Drop here).
- **Konum ve saydamlık:** ana ekranın çalışma alanının sağ altı, kenarlardan 5 px. Saydamlık 100/255; üstüne bir şey sürüklenince 255.
- **Davranış:** sol tuşla sürüklenerek taşınır; sağ tık kapatır. Bırakılan dosya, resim veya metin ana pencereye bırakılmış gibi işlenir.
- Boyut, uzaklık, hizalama ve saydamlıklar Uygulama ayarları › Gelişmiş › Drag and drop window'dan değişir.

### 2.7 Pano içeriği penceresi

- **Açan:** varsayılan tepsi orta tıkı, **Panodan yükle...** ve görev alanında Ctrl+V.
- **Başlık:** "UpLa - Pano içeriği".
- **Üst metin**, panoya göre:
  - **Pano içeriği: Resim (Boyut: {0} x {1})**
  - **Pano içeriği: Metin (Uzunluk: {0})**
  - **Pano içeriği: Dosya (Sayısı: {0})**
  - **Pano boş veya bilinmeyen veriler içeriyor.**
- **Düğmeler:** **Karşıya yükle** (Upload) ve **İptal**.
- **Bu pencereyi gösterme** (Don't show this window) kutusu yalnızca "Panodan yükle..." ile açılınca görünür.
- Metin yüklemek "desteklenmeyen tür" (txt) hatasıyla biter.

---

## 3. Kısayollar

Kaynak: `ShareX/HotkeyManager.cs`, `ShareX/Enums.cs`, `HelpersLib Resources.tr.resx` (`HotkeyType_*`).

### 3.1 Varsayılan kısayollar

UpLa, ShareX'e göre ilk iki tuşu değiştirdi (c3f6354e9): Print Screen bölge yakalar.

| # | Tuş | Türkçe | English | Enum |
|---|---|---|---|---|
| 1 | Ctrl + Print Screen | **Tüm ekranı yakala** | Capture entire screen | PrintScreen |
| 2 | Print Screen | **Bölge yakala** | Capture region | RectangleRegion |
| 3 | Alt + Print Screen | **Aktif pencereyi yakala** | Capture active window | ActiveWindow |
| 4 | Shift + Print Screen | **Ekran kaydetme başlat/durdur** | Start/Stop screen recording | ScreenRecorder |
| 5 | Ctrl + Shift + Print Screen | **Ekran kaydetme (GIF) başlat/durdur** | Start/Stop screen recording (GIF) | ScreenRecorderGIF |

- Varsayılan kısayolların kendi görev ayarları yok; varsayılan görev ayarlarını kullanırlar.
- Kurulum programı yeni kurulumda "Disable Print Screen key for Snipping Tool" görevini işaretli sunar.

### 3.2 Kısayol metni ve davranışı

- **Metin biçimi** (`HotkeyInfo.ToString`): değiştiriciler "Ctrl + ", "Shift + ", "Alt + ", "Win + " sırasıyla, ardından boşlukla ayrılmış tuş adı ("Print Screen", "Numpad 1", "Page Down"). Tuş adları İngilizcedir, çevrilmez. Boş kısayol "None" görünür.
- Basılı tutulan kısayol en fazla 500 ms'de bir yinelenir (`HotkeyRepeatLimit`, en az 200).
- Gelişmiş `DisableHotkeysOnFullscreen` ☐ ve `DisableHotkeys` ☐.
- Kayıt hatası iletisi: §7.5. Kısayol ayarları penceresi: §8.3.

### 3.3 Bütün görev türleri: 53 eylem + Hiçbiri

**Menülerde** (Görev ayarları › Görev sayfası, kısayol satırındaki görev düğmesi) önce **Hiçbiri** (None), sonra bu sırayla beş alt menü gelir; her öğenin simgesi var. **Tepsi tıklama listelerinde** aynı sıra kategorisiz, düz bir liste olarak görünür.

**Yükle** (Upload)

| Türkçe | English |
|---|---|
| **Dosya yükle** | Upload file |
| **Dizin yükle** | Upload folder |
| **Panodan yükle** | Upload from clipboard |
| **İçerik gösterici ile panodan yükle** | Upload from clipboard with content viewer |
| **Adresten yükle** | Upload from URL |
| **Sürükle bırak ile yükle** | Drag and drop upload |
| **Tüm aktif yüklemeleri durdur** | Stop all active uploads |

**Ekran yakalama** (Screen capture)

| Türkçe | English |
|---|---|
| **Tüm ekranı yakala** | Capture entire screen |
| **Aktif pencereyi yakala** | Capture active window |
| **Önceden yapılandırılmış pencereyi yakala** | Capture pre configured window |
| **Aktif ekranı yakala** | Capture active monitor |
| **Bölge yakala** | Capture region |
| **Bölge yakala (Basit)** | Capture region (Light) |
| **Bölge yakala (Saydam)** | Capture region (Transparent) |
| **Özel bölge yakala** | Capture pre configured region |
| **Son bölgeyi yakala** | Capture last region |
| **Kaydırarak yakalamayı başlat/durdur** | Start/Stop scrolling capture |

**Ekran kaydetme** (Screen record)

| Türkçe | English |
|---|---|
| **Ekran kaydetme başlat/durdur** | Start/Stop screen recording |
| **Aktif pencere alanıyla ekran kaydetme başlat** | Start/Stop screen recording using active window region |
| **Özel alan ile ekran kaydetme başlat** | Start/Stop screen recording using pre configured region |
| **Son bölgeyi kullanarak ekran kaydet** | Start/Stop screen recording using last region |
| **Ekran kaydetme (GIF) başlat/durdur** | Start/Stop screen recording (GIF) |
| **Aktif pencere alanıyla ekran kaydetme (GIF) başlat** | Start/Stop screen recording (GIF) using active window region |
| **Özel alan ile ekran kaydetme (GIF) başlat** | Start/Stop screen recording (GIF) using pre configured region |
| **Son bölgeyi kullanarak ekran kaydet (GIF)** | Start/Stop screen recording (GIF) using last region |
| **Ekran kaydını durdur** | Stop screen recording |
| **Ekran kaydını duraklat** | Pause screen recording |
| **Ekran kaydetme iptal et** | Abort screen recording |

**Araçlar** (Tools)

| Türkçe | English |
|---|---|
| **Renk seçici** | Color picker |
| **Renk seçici ekranı** | Screen color picker |
| **Cetvel** | Ruler |
| **Ekrana sabitle** | Pin to screen |
| **Ekrana sabitle (Ekrandan)** | Pin to screen (From screen) |
| **Ekrana sabitle (Panodan)** | Pin to screen (From clipboard) |
| **Ekrana sabitle (Dosyadan)** | Pin to screen (From file) |
| **Ekrana sabitle (Tümünü kapat)** | Pin to screen (Close all) |
| **Resim düzenleyici** | Image editor |
| **Resim güzelleştirici** | Image beautifier |
| **Resim efektleri** | Image effects |
| **Resim görüntüleyici** | Image viewer |
| **Resim birleştirici** | Image combiner |
| **OCR** | OCR |
| **QR kod** | QR code |
| **QR kod (Ekrandan çöz)** | QR code (Scan screen) |
| **QR kodu (Bölge tara)** | QR code (Scan region) |

**Diğer** (Other)

| Türkçe | English |
|---|---|
| **Devre dışı bırak/Aktif et kısayolları** | Disable/Enable hotkeys |
| **Ana pencereyi aç** | Open main window |
| **Ekran görüntüleri dizinini aç** | Open screenshots folder |
| **Geçmiş penceresini aç** | Open history window |
| **Resim geçmişi penceresini aç** | Open image history window |
| **Aksiyonlar araç çubuğunu göster/sakla** | Toggle actions toolbar |
| **Tepsi menüsünü aç/kapat** | Toggle tray menu |
| **UpLa'yı kapat** | Exit UpLa |

### 3.4 UpLa'nın çıkardığı 22 görev türü (Mac'e taşınmaz)

| Türkçe | English |
|---|---|
| Yazı yükle | Upload text |
| Adresi kısalt | Shorten URL |
| Otomatik yakala | Auto capture |
| Son bölgeyi kullanarak otomatik yakala | Start auto capture using last region |
| Otomatik yakalamayı durdur | Stop auto capture |
| (Türkçesi yok) | Background remover |
| Görsel karşılaştırıcı | Image comparer |
| Resim ayırıcı | Image splitter |
| Küçük resim yapıcı | Image thumbnailer |
| Video çevirici | Video converter |
| Video küçük resim yapıcı | Video thumbnailer |
| Görüntüyü analiz et | Analyze image |
| Hash kontrol | Hash checker |
| Metadata | Metadata |
| Metadata'yı temizle | Strip metadata |
| Dizini indeksle | Directory indexer |
| Pano görüntüleyici | Clipboard viewer |
| Kenarsız pencere | Borderless window |
| Aktif pencereyi çerçevesiz yap | Make active window borderless |
| Aktif pencereyi en üstte tut | Make active window top most |
| Pencere incele | Inspect window |
| Monitör testi | Monitor test |

---

## 4. Yakalama ve görev akışı

Kaynak: `ShareX/WorkerTask.cs`, `TaskHelpers.cs`, `TaskManager.cs`, `Forms/AfterCaptureForm.*`, `BeforeUploadForm.*`, `AfterUploadForm.*`, `ShareX.ScreenCaptureLib/Shapes/ShapeManagerMenu.cs`.

### 4.1 Yakalama sonrası görevler: ne yaparlar, hangi sırayla çalışırlar

| # | Görev | Ne yapar |
|---|---|---|
| 1 | Hızlı görev menüsünü göster | Yakalamadan sonra imlecin yerinde bir görev seti seçtiren menü açar (§4.6). |
| 2 | "Yakalama sonrası" penceresini göster | Yakalama sonrası penceresini açar (§4.3). Ekran kayıtlarında da kullanılır. |
| 3 | Resmi güzelleştir | Yakalama için güzelleştiriciyi modal açar (§5.6). |
| 4 | Resim efekti ekle | Seçili efekt ön ayarını uygular (§5.7). |
| 5 | Resim düzenleyicide aç | Kalan görevlerden önce yakalamayı düzenleyicide açar (§4.8). |
| 6 | Resimi panoya kopyala | Resmi panoya kopyalar. |
| 7 | Ekrana sabitle | Yakalamanın bir kopyasını ekrana sabitler (§5.4). |
| 8 | Resimi yazdır | Yazdırma penceresini açar. |
| 9 | Resimi dosya olarak kaydet | `Belgeler\UpLa\Screenshots\%y-%mo\%ra{10}.png` olarak kaydeder (§4.10). |
| 10 | Resimi dosya olarak farklı kaydet... | Kaydetme penceresi açar. |
| 11 | Aksiyonları gerçekleştir | Tanımlı dış programları çalıştırır (Görev ayarları › Aksiyon). |
| 12 | Dosyayı panoya kopyala | Kaydedilen dosyayı panoya kopyalar. |
| 13 | Dosya yolunu panoya kopyala | Dosya yolunu kopyalar. |
| 14 | Klasör yolunu panoya kopyala | Klasör yolunu kopyalar. |
| 15 | Dosyayı klasörde göster | Klasörü dosya seçili olarak açar. |
| 16 | QR kodunu tara | QR penceresini açar ve yakalamayı tarar. |
| 17 | Yazı tanı (OCR) | Yakalamada OCR çalıştırır. OCR sessiz değilse OCR penceresini açar ve resmin yanına bir `.txt` kaydeder. |
| 18 | "Yükleme öncesi" penceresini göster | Yüklemeden hemen önce Yükleme öncesi penceresini açar (§4.4). |
| 19 | Resimi yükle | upla.com.tr'ye yükler. İlk yükleme bir kez sorulur (§7.5). |
| 20 | Dosyayı sil | Görevin sonunda, yüklemeden sonra yerel dosyayı siler. |

- 12–14 arasından yalnızca ilk geçerli olan uygulanır: dosyayı kopyala, değilse dosya yolunu, değilse klasör yolunu.
- **Çalışma sırası** (`WorkerTask`):
  1. Hızlı görev menüsü, sonra Yakalama sonrası penceresi.
  2. Güzelleştir, sonra efektler, sonra düzenleyici.
  3. Resmi kopyala, sonra sabitle, sonra yazdır.
  4. Kaydet, sonra Farklı kaydet.
  5. Dosya görevleri: aksiyonlar, sonra dosyayı (ya da yolu ya da klasörü) kopyala, sonra klasörde göster, sonra QR tara.
  6. OCR.
  7. Yükleme öncesi penceresi, sonra yükleme (hata olursa bir kez yeniden denenir).
  8. Yerel dosyayı sil.
  9. Yükleme sonrası görevler (§4.2), ses ve tost (§7).
- **Ekran kayıtları ve yüklenen dosyalar:** `UseAfterCaptureTasksDuringFileUpload` ✓ açık olduğundan dosyaya dayalı görevler (11–17 ve 19–20) bunlarda da çalışır.

### 4.2 Yükleme sonrası görevler: ne yaparlar

| # | Görev | Ne yapar |
|---|---|---|
| 1 | "Yükleme sonrası" penceresini göster | Yükleme sonrası penceresini odak almadan, tostla birlikte açar (§4.5). |
| 2 | Adresi paylaş | Seçili paylaşım servisini (varsayılan Facebook) linkle açar. |
| 3 | Adresi panoya kopyala | Sonuç linkini kopyalar. Link türü Hedef ayarları › upla.com.tr › **Kopyalanacak link:** ile seçilir: varsayılan **Sayfa linki (önerilen)**; diğerleri **Doğrudan dosya linki** ve **Kısa link**. |
| 4 | Adresi aç | Linki tarayıcıda açar. |
| 5 | QR kod penceresini göster | Link için QR penceresini açar. |

### 4.3 "Yakalama sonrası görevler" penceresi (AfterCaptureForm)

- **Başlık:** "UpLa - Yakalama sonrası görevler" (UpLa - After capture); 784×441, modal.
- **Açan:** **"Yakalama sonrası" penceresini göster** görevi ☐. Ekran kayıtlarında da açılır.
- **Solda üç sekme:**
  - **Yakalama sonrası** (After capture): 18 görevlik onay listesi (§1.6'daki listeden Hızlı görev menüsü ve pencerenin kendisi hariç). Onay resimleri `checkbox_check` / `checkbox_uncheck`.
  - **Yükleme öncesi** (İngilizce metni "Destinations"): hedef radyo düğmeleri. Resimlerde **upla.com.tr** iki kez görünür: resim yükleyici ve dosya yükleyici.
  - **Yükleme sonrası** (After upload): 5 görevlik onay listesi.
- **Sekmelerin altında:** **Dosya ismi:** (File name:) ve üretilen ad; Enter devam eder.
- **Düğmeler:**
  - **Devam** (Continue): seçilen görevleri yalnızca bu yakalamaya uygular.
  - **Kopyala** (Copy): yalnızca resmi kopyalar, başka bir şey yapmaz; yalnızca resim varken etkin.
  - **İptal** (Cancel): yakalamayı atar.
- **Sağda:** 456×425 resim önizlemesi.
- UpLa bu listeden "küçük resmi kaydet" ve "görüntüyü analiz et"i çıkardı. Bu pencere onay işaretlerini öğe etiketiyle bağladığı için §12.1'deki hatadan etkilenmez.

### 4.4 "Dinamik hedefler" (Yükleme öncesi) penceresi (BeforeUploadForm)

- **Başlık:** "UpLa - Dinamik hedefler" (UpLa - Before upload); 774×382, modal.
- **Açan:** **"Yükleme öncesi" penceresini göster** ☐, yüklemeden hemen önce.
- **Üst metin:** "**{dosya adı} {hedef}'a yüklenmek üzere. Başka bir hedef seçebilirsiniz.**" ({0} is about to be uploaded to {1}. You may choose a different destination.) Varsayılan hedefle örneğin "aB3dE5fG7h.png upla.com.tr'a yüklenmek üzere…". Hedef yoksa **Lütfen hedef seçiniz.**
- **Solda hedef radyo düğmeleri:** resimlerde iki kez "upla.com.tr" (resim yükleyici, sonra dosya yükleyici); dosyalarda bir kez.
- **Sağda** 320×296 önizleme.
- **Düğmeler:** **Tamam** yükler; **İptal** yüklemeyi atlar, görev linksiz biter.

### 4.5 "Yükleme sonrası" penceresi (AfterUploadForm)

- **Başlık:** "UpLa - <dosya yolu veya adı>"; tasarımdaki "UpLa - Yükleme sonrası" çalışırken değiştirilir.
- **Açan:** **"Yükleme sonrası" penceresini göster** ☐. Odak almadan açılır. Kodun iç içe yapısı yüzünden **yalnızca tost da gösteriliyorsa** açılır.
- **İçerik:**
  - Resim önizlemesi.
  - Gruplu bir liste, sütunlar **Açıklama | Biçim** (Description | Format). Gruplar Forums, HTML, Wiki, Local, Custom.
  - Biçim adları her zaman İngilizce: Full URL, Shortened URL, Full Image for Forums, Full Image as HTML, Full Image for Wiki, Linked Thumbnail for Forums, Linked Thumbnail as HTML, Linked Thumbnail for Wiki, Thumbnail, Local File path, Local File path as URI.
  - Resim gömme biçimleri yalnızca link bir resim uzantısıyla bitiyorsa görünür; bu yalnızca "Doğrudan dosya linki" ile olur.
  - Bir satıra çift tıklamak onu kopyalar.
- **Düğmeler:** **Resim kopyala**, **Bağlantıyı kopyala**, **Bağlantı aç...**, **Dosya aç...**, **Klasör aç...**, **Kapat**.

### 4.6 Hızlı görev menüsü

- **Görünür:** **Hızlı görev menüsünü göster** görevi açıkken, yakalamadan sonra.
- **Görünüm:** imlecin yerinde açılan, Arial 10 bir menü; Esc kapatır.
- **Öğeler:** **Devam et** (Continue) · — · ön ayarlar · — · **Bu menüyü düzenle...** (Edit this menu...) · — · **İptal** (Cancel).
- **Varsayılan ön ayarlar.** Adları İngilizcedir ve Türkçe arayüzde de çevrilmez:
  1. "Save, Upload, Copy URL"
  2. "Save, Copy image"
  3. "Save, Copy image file"
  4. "Annotate, Save, Upload, Copy URL"
  5. (ayırıcı)
  6. "Upload, Copy URL"
  7. "Save"
  8. "Copy image"
  9. "Annotate"
- Düzenleyici pencereleri: §8.5.1 ve §8.5.2.

### 4.7 Bölge yakalama ekranı (RegionCaptureForm)

**Bölge**, **Son bölge**, ekran kaydı için bölge seçimi ve bazı araçlar bu ekranı kullanır. Ekran dondurulur, karartılır ve üstünde seçim yapılır.

**Davranış** (Görev ayarları › Yakalama › Bölge yakala'daki varsayılanlar, §8.2.4):
- Fareyle sürükleyerek dikdörtgen seçilir. **Pencere alanlarını tespit edip imleç ile yakalamaya izin ver** ✓ açık olduğundan fare bir pencerenin (✓ **Ayrıca pencere içindeki kontrol bölgelerini tespit et** ile pencere içindeki bir denetimin) üstündeyken o alan vurgulanır; tıklamak o alanı seçer.
- Arka plan %20 karartılır.
- İmlecin yanında **büyüteç** (✓; yuvarlak, piksel sayısı 15, piksel boyutu 10) ve **konum/boyut bilgisi** (✓).
- Fare eylemleri: sağ tık **Nesneyi sil veya yakalamayı iptal et**, orta tık **Araç tipini değiştir**, 4. tuş **Tam ekran yakala**, 5. tuş **Aktif ekranı yakala**.
- "Alt" basılıyken bölge şu boyutlara kilitlenir: 426x240, 640x360, 854x480, 1280x720, 1920x1080.
- Çoklu bölge modu kapalı (`QuickCrop` açık): ilk seçim hemen yakalanır. Açılırsa bölgeler taşınıp yeniden boyutlandırılabilir.
- Ek seçenekler kapalı: kare büyüteç, ekranı kaplayan artı imleç, merkez artı, sabit boyutlu bölge (250×250), FPS gösterimi (limit 100), bölgeyi aktif ekrana sınırlama.
- Gelişmiş `RegionCaptureDisableAnnotation` ☐ kapalı olduğundan seçim sırasında çizim araçları da kullanılabilir.

**Üst araç çubuğu** (`ShapeManagerMenu`). Sıra `ShapeType` enum sırasını izler; araç düğmeleri yalnızca simgedir, metin ipucunda görünür:
- **Bölge araçları** (yalnızca yakalama modunda): **Dikdörtgen bölge** (Rectangle region), **Elips bölge** (Ellipse region), **Serbest bölge** (Freehand region).
- — **Seç ve taşı (M)** (Select and move).
- **Çizim araçları:** **Dikdörtgen (R)**, **Elips (E)**, **Serbest çizim (F)**, **Serbest çizim ok**, **Çizgi (L)**, **Ok (A)**, **Yazı (Dış çizgili) (O)**, **Yazı (Arkaplanlı) (T)**, **Konuşma balonu (S)**, **Kademe (I)**, **Büyüt**, **Resim (Dosya)**, **Resim (Ekrandan)**, **Çıkartma**, **İmleç**, **Akıllı silgi**.
- **Efekt araçları:** **Bulanıklaştır (B)**, **Mozaikle (P)**, **Vurgula (H)**, **Spot ışığı**.
- **Yalnızca düzenleyici modunda:** **Resmi kırp (C)**, **Kesip çıkar (X)**.
- — Renk düğmeleri: **Çerçeve rengi...**, **Doldurma rengi...**, **Vurgulama rengi...**.
- **Araç seçenekleri** ▸ (Tool options), seçili araca göre: **Çerçeve boyutu:**, **Kenar yarıçapı:**, **Çerçeve stili:** (Düz, Tire, Nokta, Tire nokta, Tire nokta nokta), **Aradeğerleme modu:**, **İmleç tipi:**, **Bulanıklık gücü:**, **Piksel boyutu:**, **Orta noktalar:**, **Ok başı yönü:** (Son, Baş, İki taraf), **Yumuşatma:**, **Eğri enterpolasyonu**, **Yazı boyutu:**, **İlk kademe değeri:**, **Kademe tipi:** (Sayılar, Harfler (Büyük harf), Harfler (Küçük harf), Roma rakamları (Büyük harf), Roma rakamları (Küçük harf)), **Düşen gölge**, **Düşen gölge rengi...**, **Büyütme gücü:**, **Kesip çıkarma efekti:** (Efekt yok, Yırtık kenarlar, Dalga, Testere dişi), **Kesip çıkarma efekt boyutu:**, **Kesip çıkarma arka plan rengi...**.
- **Düzenle** ▸ (Edit): **Geri al**, **Yeniden yap**, **Resim/yazı yapıştır**, **Çoğalt**, **Sil**, **Hepsini sil**, **En öne getir**, **Öne getir**, **Arkaya gönder**, **En arkaya gönder**.
- **Yakala** ▸ (Capture; yalnızca yakalama modunda): **Bölgeleri yakala**, **Son bölgeyi yakala**, **Tam ekran yakala**, **Aktif ekranı yakala**, **Monitör yakala** ▸.
- **Ayarlar** ▸ (Options): **Çoklu bölge modu** (yalnızca yakalama modunda), **Pozisyon ve boyut bilgisi göster**, **Büyüteç göster**, **Kare şeklinde büyüteç**, **Büyüteç piksel sayısı:**, **Büyüteç piksel boyutu:**, **Merkez artı işaretini göster**, **Ekranı kaplayan artı şeklinde imleç göster**, yeniden boyutlandırma tutamaçları, **Animasyonları etkinleştir**, **Sabit boyut bölge modu** + **Genişlik:**/**Yükseklik:** (yalnızca yakalama modunda), **FPS göster**, **FPS limiti:**, **Nesne seçtikten sonra çizim aracına geç**, **Nesne çizdikten sonra seçim aracına geç**, **Menü durumunu hatırla**.

### 4.8 Resim düzenleyici

- **Açılış penceresi** "UpLa - Resim düzenleyici": **Resim dosyası aç...**, **Panodan resim yükle**, **URL'den resim yükle...**, **Yeni resim oluştur...**, **İptal**.
- Düzenleyici, bölge yakalama ekranının "düzenleyici modu"dur; araç çubuğu penceresinin başlığı "UpLa - Editör menüsü".
- **Araç çubuğunun başı:**
  - Düzenleyici modunda: **Yakalama sonrası görevlerini çalıştır (Enter)**.
  - Görev düzenleme modunda (Yakalama sonrası › Resim düzenleyicide aç): **Değişiklikleri uygula ve göreve devam et (Enter)**, **Göreve devam et (Space veya sağ tıklama)**, **Görevi iptal et (Esc)**.
  - Ardından: **Resimi kaydet (Ctrl + S)**, **Resimi farklı kaydet... (Ctrl + Shift + S)**, **Resimi panoya kopyala (Ctrl + C)**, **Resimi yükle (Ctrl + U)**, **Resimi yazdır... (Ctrl + P)**.
- **Araçlar:** §4.7'deki liste, bölge araçları yerine **Resmi kırp (C)** ve **Kesip çıkar (X)** ile.
- **Resim** ▸ (Image; yalnızca düzenleyicide): **Yeni resim...**, **Resim dosyasını aç...**, **Resim dosyası ekle...**, **Ekrandan resim ekle...**, **Resim boyutu...**, **Tuval boyutu...**, **Resimi kırp...**, **Resmi otomatik kırp...**, **Saat yönünde 90° döndür**, **90° saat yönünün tersine döndür**, **180° döndür**, **Yatay olarak döndür**, **Dikey olarak döndür**, **Resim efekti ekle...**.
- **Ayarlar** ▸ düzenleyicide ayrıca: **Editör başlangıç modu:** (Otomatik boyut, Standart, Pencere olarak ekranı kapla, Önceki durum, Tam ekran), **Açılışta sığdırmak için yakınlaştır**, **Resmi otomatik olarak panoya kopyala**, **Görevden sonra editörü otomatik kapat**.
- Sonuç Yakalama sonrası görevlerden geçer; varsayılan olarak kaydedilir ve yüklenir.
- UpLa yalnızca bu klasik düzenleyiciyi tutar; Avalonia düzenleyicisi ve düzenleyici seçimi kaldırıldı.

### 4.9 Kaydırarak yakalama

"UpLa - Kaydırmalı yakalama" penceresi: **Yakala...**, **Seçenekler...**, **Yükle / Kaydet**, **Kopyala** ve **?** düğmeleri. Bir pencere veya alan seçilir, uygulama içeriği kendisi kaydırır ve parçaları tek resimde birleştirir.

### 4.10 Dosya adları, klasörler ve resim biçimi

- **Kişisel dizin:** `Belgeler\UpLa` (taşınabilir sürümde `<exe klasörü>\UpLa`). Ayarlar, geçmiş, kütükler ve ekran görüntüleri burada.
- **Ekran görüntüsü klasörü:** `<kişisel dizin>\Screenshots\%y-%mo` (örn. `Screenshots\2026-10`).
- **Dosya adı:** `%ra{10}` (10 rastgele alfanumerik karakter); aktif pencere yakalamada `%pn_%ra{10}` (işlem adı, alt çizgi, 10 rastgele karakter).
- **Biçim:** PNG. Resim 2048 KB'tan büyükse JPEG (kalite 90).
- **Dosya varsa:** **Ne yapılacağını sor**.
- **Ekran kayıtları:** aynı klasöre, 10 rastgele karakter + `.mp4` (codec'e göre `.webm`, `.gif`, `.webp`).

---

## 5. Araçlar

Tepside ve ana pencerede aynı 11 araç. Kaynak: `TaskHelpers.cs` ve ilgili formlar.

### 5.1 Renk seçici...

"UpLa - Renk seçici" (Color picker) penceresi:
- **Ton/Doygunluk/Parlaklık** (Hue/Saturation/Brightness), **Kırmızı/Yeşil/Mavi**, **Alfa**, **Heksadesimal**, **Ondalık**, **CMYK** ve **İsim** alanları.
- **Eski:** / **Yeni:** renk kutuları; **Standart renkler** ve **Son renkler**.
- Ekrandan renk alan bir düğme ve **İmleç pozisyonu**.
- Kopyalama menüsü: **Hepsini kopyala**, **RGB kopyala**, **Heksadesimal kopyala**, **CMYK kopyala**, **HSB kopyala**, **Ondalık kopyala**, **Pozisyon kopyala**.
- **Tamam**, **İptal**, **Kapat**.

### 5.2 Ekrandan renk seçici...

- Tam ekran bir katman, büyüteç ve bilgi yazısı: "RGB: $r255, $g255, $b255 / Hex: $hex / X: $x Y: $y".
- Tıklamak küçük harfli, "#" içermeyen hex kopyalar (örn. `ff8800`); Ctrl+tık `255, 136, 0` kopyalar.
- Ardından işlem sesi ve "UpLa - Ekran rengi seçici" başlıklı **Panoya kopyalandı: ff8800** tostu.
- Biçimler Görev ayarları › Araçlar'dan değişir: **Ekran renk seçici formatı:**, **(Ctrl + tıklama):**, **Ekran renk seçici bilgi yazısı:**.

### 5.3 Cetvel...

Tam ekran bir katman; bir dikdörtgen çizerek ekrandaki boyut ve konum ölçülür.

### 5.4 Ekrana sabitle...

- "UpLa - Ekrana sabitle" penceresi: **Ekrandan ekrana sabitle...** (bölge seçilir), **Panodan ekrana sabitle**, **Dosyadan ekrana sabitle...**, **İptal**.
- Sonuç her zaman üstte duran, taşınabilen, yakınlaştırılabilen ve saydamlaştırılabilen bir resim penceresi.
- Panoda resim yoksa: **Pano resim içermiyor.**

### 5.5 Resim düzenleyici...

§4.8.

### 5.6 Resim güzelleştirici...

- Önce resim dosyası penceresi, sonra "UpLa - Görüntü güzelleştirici".
- **Kenar boşluğu** (Margin), **Dolgu** (Padding), **Akıllı dolgu** (Smart padding), **Yuvarlatılmış köşe** (Rounded corner).
- **Gölge** grubu: **Yarıçap**, **Opaklık**, **Mesafe**, **Açı**, **Renk...**.
- **Arka plan**: tür listesi ve **Görüntü dosyasına gözat...**.
- **Seçenekleri sıfırla...**.
- Simge düğmeleri: **Kopyala**, **Yükle**, **Kaydet**, **Farklı kaydet...**, **Yazdır...**.

### 5.7 Resim efektleri...

- Önce resim dosyası penceresi, sonra "UpLa - Resim efektleri".
- **Ön ayarlar:** listesi ve **Yeni**, **Kaldır**, **Çoğalt** düğmeleri; **Ön ayar ismi:**.
- **Efektler:** listesi ve **Ekle**, **Kaldır**, **Çoğalt**, **Temizle...**, **Yenile** düğmeleri; **Efekt ismi:**; seçili efektin özellik ızgarası (İngilizce).
- **Paketleyici...**, **Resim yükle** menüsü (**Dosyadan...** / **Panodan**), **Resim kaydet...**, **Resimi yükle**, **Tamam**, **Kapat**.
- "Ekle" menüsü dört grup açar: **Çizimler**, **İşlemeler**, **Düzenlemeler**, **Filtreler**. Efekt adları İngilizcedir, çevrilmez (liste §13.8).
- Sonuç Yakalama sonrası görevlerden geçer.

### 5.8 Resim görüntüleyici...

Önce resim dosyası penceresi, sonra "UpLa - Resim görüntüleyici"; ‹ › ile aynı klasördeki resimler arasında gezilir.

### 5.9 Resim birleştirici...

"UpLa - Resim birleştirici":
- Resim listesi: **Ekle...**, **Kaldır**, **Yukarı taşı**, **Aşağı taşı**.
- **Birleştirme yönü:** **Yatay** / **Dikey**.
- **Resim hizası:**; **Resimler arasındaki boşluk:** … **piksel olarak**.
- **Şundan sonra sar:** … **görüntü**; **Otomatik arkaplanı doldur**.
- **Resimleri birleştir ve kaydet/yükle yakalama sonrası ayarlarına göre** düğmesi.

### 5.10 OCR...

- Bir bölge seçilir, "UpLa - Optik karakter tanıma" açılır. Windows OCR kullanılır. Ana pencereden açılınca pencere önce gizlenir.
- **Dil:** (varsayılan `en`), **Ölçek faktörü:** (2), **Tek satır**, **Sonuç:**, **Servis:** ve **Servis bağlantısını aç...**, **OCR için bölge seç...**, **Hepsini kopyala**.
- Varsayılan servisler: Google Translate, Google Search, Google Images, Bing, DuckDuckGo, DeepL.

### 5.11 QR kod...

- "UpLa - QR kod": panodaki metinden QR kod üretir.
- **Yazı:**, **QR kodu:**, **QR kodu boyutu:** … px.
- **Resmi kopyala**, **Resmi kaydet...**, **Resim yükle**, **Ekranı tara**, **Bölgeyi tara...**, **Resim dosyasını tara...**.

---

## 6. Ekran kaydı

Kaynak: `ShareX/ScreenRecordManager.cs`, `ShareX.ScreenCaptureLib/Forms/ScreenRecordForm.*`, `FFmpegOptionsForm.*`; görsel `docs/screenshots/screen-recorder.png`.

### 6.1 Menü öğeleri ve kısayollar

İki Yakala menüsünde de (tepsi ve ana pencere). Görev metni "Ekran kaydı" der; menü **Ekran kaydetme** gösterir.
- **Ekran kaydetme** (Screen recording, camcorder_image): seçilen bölgeyi MP4'e (H.264/x264) kaydeder. Yeniden tıklamak kaydı durdurur.
- **Ekran kaydetme (GIF)** (Screen recording (GIF), film): GIF kaydeder; her zaman önce kayıpsız iki geçişli kayıt, sonra GIF kodlaması yapılır.
- Kısayollar: Shift + Print Screen ve Ctrl + Shift + Print Screen. 11 kayıt eylemi §3.3'te.

### 6.2 Kayıt akışı

1. **Codec denetimi (UpLa).** Kayıtlı Xvid/APNG ayarları x264'e, boş video kaynağı gdigrab'a çevrilir.
2. **FFmpeg.** `ffmpeg.exe` yoksa (Store dışı sürümler) "UpLa - FFmpeg" penceresi indirir:
   - **Ekran kaydı için gereken FFmpeg indiriliyor (yaklaşık {0} MB). Bu yalnızca bir kez yapılır.**
   - İlerleme çubuğu ve **{0} / {1} MB indirildi**, sonra **Doğrulanıyor ve kuruluyor...**; **İptal** düğmesi.
   - Hatalar: "FFmpeg indirilemedi: …\r\n\r\nİnternet bağlantınızı kontrol edip kaydı yeniden başlatın." ve "İndirilen FFmpeg dosyası beklenen dosya değil, kullanılmadı. Kaydı yeniden başlatarak tekrar deneyin."
   - Store sürümü FFmpeg'i içinde taşır, hiç indirmez.
3. **Bölge seçimi:** normal bölge ekranı (§4.7) ya da **Saydam alan seçici kullan** açıksa saydam seçici.
4. **Kayıt çerçevesi** ("UpLa - Ekran kaydetme" penceresi):
   - Bölgenin çevresinde kesikli bir kenarlık: beklerken veya duraklatılmışken sarı (241,196,27), kayıtta açık yeşil.
   - Bölgenin hemen altında 439×42 bir çubuk; Arial 12, 112×42 düğmeler:
     - **Başlat**; kayıtta **Durdur** (Start/Stop)
     - **Duraklat**; duraklatılmışken **Devam et** (Pause/Resume)
     - **İptal** (Abort)
     - süre etiketi "00:00:00" (dakika:saniye:salise). Sabit süre seçiliyse geri sayar.
   - Beklerken veya duraklatılmışken bölge süre etiketinden sürüklenerek taşınabilir.
5. **Kayıt sırasında ikinci bir tepsi simgesi:**
   - Başlamadan önce sarı kayıt simgesi; ipucu "UpLa - Bekleniyor..." (Waiting...) veya "UpLa - Kayda başlamak için tıklayın." (Click to start recording.).
   - Kayıtta kırmızı kayıt simgesi; ipucu "UpLa - Kaydı durdurmak için tıklayın." (Click to stop recording.).
   - Sol tık kaydı başlatır veya durdurur. Sağ tık menüsü: **Başlat/Durdur**, **Duraklat/Devam et**, **İptal**.
   - Kodlama sırasında (GIF veya iki geçiş) ipucu "UpLa - Kodlanıyor... NN%", simge kırmızı (140,0,36) bir ilerleme simgesi.
6. **Başlama:** varsayılanlarla (otomatik başlat ✓, gecikme 0 sn) kayıt hemen başlar; gecikme varsa önce geri sayım.
7. **Durdurma:**
   1. İşlem sesi çalar.
   2. Duraklatma parçaları birleştirilir.
   3. İki geçişli veya GIF kayıtlar kodlanır.
   4. Yakalama sonrası penceresi açıksa dosya adıyla gösterilir; yeni ad uygulanır.
   5. Bir dosya görevi çalışır: dosyaya dayalı Yakalama sonrası görevler, "Resimi yükle" açıksa yükleme, sonra Yükleme sonrası görevler ve tost.
8. **İptal** dosyayı siler. **İptal ederken onay sor** açıksa önce **Kaydı iptal etmek istediğinize emin misiniz?** diye sorar.
9. **Yükleme sınırı (UpLa).** Yalnızca kayıt yüklenecekse, özel FFmpeg komutları kullanılmıyorsa ve **Yüklenecek ekran kayıtlarını yükleme sınırına gelince durdur** ✓ açıksa (Hedef ayarları › upla.com.tr) uygulanır.
   - FFmpeg misafirde 18 MiB'ta (sınır 20 MB), üyede 95.000.000 baytta (sınır 100 MB) durur.
   - Duraklatılmış parçalar sınıra sayılır. WEBM'e `-cluster_time_limit 1000` eklenir. GIF ve iki geçişli kayıtlar kodlanırken kesilir.
   - §7.3'teki tostlar bunu bildirir.
10. **Çıktı:** `Belgeler\UpLa\Screenshots\yyyy-MM\<10 rastgele karakter>.mp4` (codec'e göre .webm/.gif/.webp). Video 30 FPS, GIF 15 FPS.

### 6.3 Görev ayarları › Yakalama › Ekran kaydedici

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Ekran kayıt ayarları...** | Screen recording options... | BTN 248×32 | §6.4'ü açar |
| **Ekran kayıt FPS:** | Screen recording FPS: | NUM 1–60 (DevMode'da 300) | 30 |
| **GIF FPS:** | GIF FPS: | NUM 1–30 (DevMode'da 60) | 15 |
| **Ekran kaydında imleç göster** | Show cursor in recording | CB | ✓ |
| **Kaydetmeye başla:** … **saniye sonra** | Start recording after: … seconds | CB + NUM 0–60, adım 0,5 | ✓, 0 |
| **Sabit süre:** … **saniye** | Fixed duration: … seconds | CB + NUM 1–60, adım 0,5 | ☐, 3 |
| **İlk kayıpsız kodlama kullanarak kayıt yap ondan sonra kullanıcı kodlama ayarlarını uygula** | Record using lossless encoding and then apply user encoding option | CB | ☐ |
| **Saydam alan seçici kullan** | Use transparent region selection | CB | ☐ |
| **İptal ederken onay sor** | Ask for confirmation when aborting | CB | ☐ |

"Yüklenecek ekran kayıtlarını yükleme sınırına gelince durdur" bu sayfada değil, Hedef ayarları › upla.com.tr'de (§8.4).

### 6.4 "UpLa - Ekran kayıt ayarları" penceresi (FFmpegOptionsForm)

Windows'a ve FFmpeg'e özgüdür. 664×456.

**Üst alanlar:**

| Türkçe | Tür | Varsayılan | Not |
|---|---|---|---|
| **Özel FFmpeg yolu kullan:** | CB + TXT + "..." BTN | ☐ | |
| **Video kaynağı:** | DD | gdigrab | "gdigrab (Graphics Device Interface)", "ddagrab (Desktop Duplication API)" (Windows 10+), sonra dshow aygıtları. UpLa "None"u kaldırdı. |
| **Ses kaynağı:** | DD | None | "None" ve dshow aygıtları |
| **Kayıt cihazlarını yükle...** + **?** + '"screen-capture-recorder" ve "virtual-audio-capturer" video/ses kaynaklarını yükler.' | BTN + BTN + LBL | | Store sürümünde gizli |
| **Video kodlayıcı:** | DD | H.264 / x264 | UpLa listesi: H.264 / x264, H.265 / x265, VP8, VP9, H.264 / NVENC, HEVC / NVENC, H.264 / AMF, HEVC / AMF, H.264 / Quick Sync, HEVC / Quick Sync, GIF, WebP. Kaldırılanlar: MPEG-4 / Xvid (ve Xvid sekmesi), APNG. |
| **Ses kodlayıcı:** | DD | AAC | AAC, Opus, Vorbis, MP3 |

**Codec'e göre ayar paneli:**

| Codec | Ayarlar |
|---|---|
| x264 / x265 | **CRF:** NUM 0–51 (28) ya da **Bit hızı kullan** CB + kbps NUM 100–100000 (3000); **Ön ayar:** Ultra fast…Placebo (Ultra fast); Fast'ten yavaşsa uyarı simgesi |
| VP8 / VP9 | **Değişken bit hızı:** kbps 3000 |
| NVENC | **Bit hızı:** 3000; **Ön ayar:** p1–p7 ("Medium (Medium quality)"); **İnce ayar:** ("Low latency") |
| GIF | **Palet modu:** full/diff/single (full); **Kıpırtılandırma modu:** none, bayer, heckbert, floyd_steinberg, sierra2, sierra2_4a, sierra3, burkes, atkinson (sierra2_4a); bayer seçiliyse Bayer ölçeği NUM 0–5 (2) |
| AMF | **Bit hızı:** 3000; **Kullanım:** ("Low latency transcoding"); **Kalite:** ("Prefer speed") |
| QuickSync | **Bit hızı:** 3000; **Ön ayar:** (Fast) |
| WebP | panel gizli |
| Ses | AAC **Bit hızı:** 64–320, adım 32 (128); Opus 32–512, adım 32 (128); Vorbis **Kalite:** 0–10 (3); MP3 **Kalite:** 9…0 (4) |

**Alt alanlar:** **Ek komut satırı parametreleri:** TXT; **Özel komutları kullan:** CB + komut satırı önizlemesi (CB işaretli değilse salt okunur); **Seçenekleri sıfırla...** BTN.

Xvid veya APNG kullanan kayıtlı ayarlar kayıt başlamadan düzeltilir.

---

## 7. Bildirimler, sesler ve iletişim kutuları

Kaynak: `ShareX/TaskManager.cs` (`Task_TaskCompleted`), `Forms/NotificationForm.cs`, `NotificationFormConfig.cs`, `WorkerTask.cs`, `UplaStrings.cs`.

### 7.1 Görev bitti tostu

**Ne zaman görünür.** Hepsi geçerli olmalı:
- görev tamamlandı ve durdurulmadı;
- sonuç metni boş değil (upla.com.tr linki; hiçbir şey yüklenmediyse yerel dosya yolu, yani "yalnızca kaydet"te de tost çıkar);
- **Görev bittikten sonra tost bildirimi göster** ✓;
- **Tam ekran ise uyarıları devre dışı bırak** ☐ kapalı ya da tam ekran bir uygulama yok.

**Resim tostu** (ekran görüntüleri, resim ve GIF dosyaları):
- Resim 400×300'e sığacak biçimde ölçeklenir; tost resim boyutu + 1 px kenar (40,40,40), başlıksız.
- Fareyle üstüne gelince üstte 40 px yarı saydam siyah bir şerit; içinde beyaz Arial 11 ile link, sığmazsa "…" ile kesilir.

**Metin tostu** (videolar ve diğer dosyalar):
- Arka plan (50,50,50), iç boşluk 10, en fazla 400×300.
- Başlık **UpLa - Görev tamamlandı** (Task completed), kalın Arial 11, (240,240,240).
- Gövde: link (`BalloonTipContentFormat` = `$result`), Arial 11, (210,210,210).

**Konum ve süre:**
- Ana ekranın çalışma alanının sağ altı, kenardan 5 px.
- Her zaman üstte; odak almaz; görev çubuğunda görünmez; el imleci.
- 3 sn görünür (**Süre**), sonra 1 sn'de solar (**Solma süresi**). Fare üstündeyken tam görünür kalır; solma fare ayrılınca başlar.
- Aynı anda tek tost olur; yenisi eskisinin yerini alır.

**Tıklama.** Her tık önce tostu kapatır, sonra eylemi yapar:

| Tık | Ayar etiketi | Varsayılan | Sonuç |
|---|---|---|---|
| Sol | **Sol tıklama eylemi:** | **Bağlantı aç** (Open link) | Linki, link yoksa dosyayı açar |
| Sağ | **Sağ tıklama eylemi:** | **Uyarı penceresini kapat** (Close notification) | Tostu kapatır |
| Orta | **Orta tıklama eylemi:** | **Resimi düzenle** (Edit image) | Resim dosyasını düzenleyicide açar |

- Seçenekler §13.3'te.
- Tostu 20 px'ten fazla sürüklemek dosyayı dışarı sürükler.

### 7.2 Hata tostu ve upla.com.tr hata metinleri

- Başlığı **UpLa - Hata** (Error) veya `UpLa - <hata başlığı>` olan metin tostu; 5 sn görünür; hata sesi çalar.
- Gövde ilk hatadır. upla.com.tr hataları (`UplaStrings`):

| Durum | Türkçe | English |
|---|---|---|
| Desteklenmeyen tür | "{0}" türündeki dosyalar upla.com.tr'ye yüklenemez. Desteklenen türler: {1}. | "{0}" files cannot be uploaded to upla.com.tr. Supported types: {1}. |
| Çok büyük, misafir | Dosya çok büyük ({0}). Misafir yüklemelerde sınır {1}; daha büyük dosyalar için hesabınızla giriş yapın. | The file is too large ({0}). Guest uploads are limited to {1}; sign in with your account for larger files. |
| Çok büyük, üye | Dosya çok büyük ({0}); tek seferde en fazla {1} yüklenebilir. | The file is too large ({0}); at most {1} can be uploaded at once. |
| Geçersiz anahtar | upla.com.tr hesap bağlantınız artık geçerli değil (bu bilgisayarın bağlantısı kaldırılmış olabilir). "upla.com.tr hesabı" menüsünden "Tekrar giriş yap"ı seçin. | Your upla.com.tr account connection is no longer valid (this computer's connection may have been removed). Choose "Sign in again" in the "upla.com.tr account" menu. |
| Elle girilen anahtar geçersiz | Elle girilen upla.com.tr API anahtarı geçersiz. Hedef ayarları › upla.com.tr bölümünden uygulamayla giriş yapın veya anahtarı kontrol edin. | The upla.com.tr API key entered by hand is invalid. Sign in with the app or check the key in Destination settings › upla.com.tr. |
| Misafir yükleme kapalı | upla.com.tr'de misafir yükleme şu anda kapalı. "upla.com.tr hesabı" menüsünden hesabınızla giriş yapın. | Guest upload is currently disabled on upla.com.tr. Sign in with your account from the "upla.com.tr account" menu. |
| Tekrar | Bu dosya kısa süre önce zaten yüklendi; upla.com.tr aynı dosyanın 24 saat içinde tekrar yüklenmesine izin vermiyor. | This file was already uploaded recently; upla.com.tr does not accept the same file again within 24 hours. |
| Sel | Çok kısa sürede çok fazla yükleme yapıldı. Lütfen biraz bekleyip tekrar deneyin. | Too many uploads in a short time. Please wait a little and try again. |
| Boş kaynak | Dosya sunucuya ulaşmadı; dosya izin verilen boyuttan büyük olabilir. | The file did not reach the server; it may be larger than allowed. |
| Yasak | Bu hesabın upla.com.tr'ye yükleme izni yok veya yükleme geçici olarak kapalı. | This account is not allowed to upload to upla.com.tr, or uploads are temporarily disabled. |
| Video işleme | upla.com.tr videoyu işleyemedi. | upla.com.tr could not process the video. |
| Genişlik | Sunucuda yeniden boyutlandırma genişliği resmin kendi genişliğinden büyük. | The resize width is larger than the image width. |
| Tür reddedildi | Bu dosya türü upla.com.tr'de şu anda kabul edilmiyor. | This file type is currently not accepted by upla.com.tr. |
| Çok büyük (sunucu) | Dosya upla.com.tr için çok büyük. | The file is too large for upla.com.tr. |
| API kapalı | upla.com.tr yükleme API'si şu anda kapalı. | The upla.com.tr upload API is currently disabled. |
| Sunucu | upla.com.tr şu anda yanıt vermiyor (HTTP {0}). Lütfen daha sonra tekrar deneyin. | upla.com.tr is not responding right now (HTTP {0}). Please try again later. |
| Bağlantı | upla.com.tr'ye bağlanılamadı. İnternet bağlantınızı kontrol edin. | Could not connect to upla.com.tr. Check your internet connection. |
| Reddedildi | upla.com.tr yüklemeyi kabul etmedi: {0} | upla.com.tr rejected the upload: {0} |
| Beklenmeyen | upla.com.tr'den beklenmeyen bir yanıt alındı. | Unexpected response from upla.com.tr. |
| Oturum okunamadı | Bu bilgisayarda kayıtlı upla.com.tr oturumu okunamadığı için dosya yüklenmedi (…) | The file was not uploaded because the upla.com.tr sign-in saved on this computer could not be read (…) |
| Geçersiz ayar | {0} ayarları yanlış veya eksik. Lütfen "Hedef ayarları" penceresinden ayar yapınız. (Hedef ayarları'nı da açar.) | {0} configuration is invalid or missing. Please check "Destination settings" window to configure it. |
| Boş adres | Adres boş. | URL is empty. |

- Desteklenen türler: jpg, jpeg, png, bmp, gif, webp resimleri; mp4 ve webm videoları.
- Boyut sınırları: misafir 20 MB, üye 100 MB (Cloudflare sınırı).

### 7.3 Diğer tostlar

Hepsi "UpLa" başlıklı metin tostlarıdır; aksi yazmadıkça 3 sn görünür.

| Ne zaman | Türkçe | English | Tost ayarına bağlı mı |
|---|---|---|---|
| Ana pencere ilk kez tepsiye kapatılınca | **UpLa sistem tepsisine küçültüldü.** (8 sn) | UpLa is minimized to the system tray. | hayır |
| Kısayollar kapatılınca | **Kısayollar devre dışı kaldı.** | Hotkeys disabled. | evet |
| Kısayollar açılınca | **Kısayollar aktif edildi.** | Hotkeys enabled. | evet |
| Ekrandan renk seçici (başlık "UpLa - Ekran rengi seçici") | **Panoya kopyalandı: {0}** | Copied to clipboard: {0} | evet |
| Kayıt yükleme sınırına ulaştı (UpLa) | **Kayıt {0} yükleme sınırına ulaştığı için durduruldu ve yükleniyor.** | The recording reached the {0} upload limit, so it was stopped and is being uploaded. | **hayır, her zaman** |
| İki geçişli veya GIF kayıt kesildi (UpLa) | **Kayıt {0} yükleme sınırını aştığı için sonu kısaltıldı.** | The recording was longer than the {0} upload limit, so its end was cut. | hayır |
| Ayarlar kaydedilemedi (başlık "UpLa - Ayarlar kaydedilemedi", 5 sn) | hata metni ya da **Antivirüs yazılımınız veya Windows'daki kontrollü klasör erişimi özelliği UpLa'yı engelliyor olabilir.** | Your anti-virus software or the controlled folder access feature in Windows could be blocking UpLa. | hayır |

Yükleme sınırı tostlarında {0} misafirde "20 MB", üyede "100 MB".

### 7.4 Sesler

Görev ayarları › Genel › Uyarılar'daki kutularla açılıp kapanır (§8.2.2); hepsi varsayılan olarak açık.
- **Yakalama sesi:** her yakalamadan sonra deklanşör sesi.
- **Görev tamamlandı sesi:** biten her görevden sonra.
- **İşlem tamamlandı sesi:** sabitleme, ekrandan renk seçici, sessiz OCR, kısayolları açıp kapama gibi araç işlemlerinde ve bir kayıt parçası bittiğinde.
- **Hata sesi:** hata tostuyla birlikte ("Görev bittikten sonra ses çal" kutusuna bağlı).
- Her biri için **Kişisel ... sesi kullan:** ile bir .wav dosyası seçilebilir.

### 7.5 İletişim kutuları

| Durum | Başlık | Metin | Düğmeler |
|---|---|---|---|
| İlk yükleme (UpLa; `WorkerTask.ConfirmUplaFirstUpload`, `ShowUploadWarning` ✓). En üstte açılır; cevap ne olursa olsun bir kez sorulur. | **upla.com.tr'ye otomatik yükleme** (Automatic upload to upla.com.tr) | "Ekran görüntüleriniz ve kayıtlarınız yakalandıktan sonra otomatik olarak upla.com.tr'ye yüklenir ve linke sahip herkesin görebileceği bir bağlantı oluşturulur.\r\n\r\nOtomatik yükleme açık kalsın mı?\r\n\r\nHayır derseniz bu dosya yüklenmez ve otomatik yükleme kapatılır; daha sonra \"Yakalama sonrası görevler\" menüsünden tekrar açabilirsiniz." | **Evet** / **Hayır**. Hayır, "Resimi yükle"yi varsayılan görevlerden ve her kısayolun kendi görevlerinden kaldırır, menüleri yeniler. Metin "Yakalama sonrası görevler" der ama düğmenin adı "Yakalama sonrası". |
| 100 MB'tan büyük dosya (`ShowLargeFileSizeWarning`) | UpLa | "Büyük bir dosya yüklüyorsunuz.\nDevam etmek istediğinizden emin misiniz?" + **Bu mesajı tekrar gösterme.** kutusu | Evet / Hayır |
| 10'dan fazla dosya | UpLa - Dosyaları yükle | "{0} tane dosyayı yüklemek istediğinize emin misiniz?" + **Bu mesajı tekrar gösterme.** | Evet / Hayır |
| Pano erişim hatası (yalnızca pano hatalarında; UpLa) | UpLa - Panodan yükle | "\"…\"\r\n\r\nPanodan yüklemeyi tekrar denemek ister misiniz?" | Evet / Hayır |
| Ekran kaydı sürerken Çıkış | UpLa | "Ekran kaydı aktifken UpLa kapatılamaz.\n\nAktif ekran kaydını sonlandırmak istiyor musunuz?" | Evet kaydı sonlandırır ama uygulamadan **çıkmaz** / Hayır |
| Kısayol kaydedilemedi (açılışta veya kısayol atanınca) | UpLa - Kısayol kaydı başarısız | "{0} kayıt edilemiyor:\n\n[kısayol] açıklama\n\nLütfen başka bir kısayol seçin veya çakışan uygulamayı kapatın ve UpLa'yı tekrar açın." ({0} = "Kısayol" veya "Kısayollar") | Tamam |
| Silme linkini açma (UpLa) | Silme linki | §1.15 | Evet / Hayır (varsayılan Hayır) |
| Yerel dosya silme | UpLa - Dosya silme onayı | "Bu dosyayı gerçekten silmek istiyor musunuz?" | Evet / Hayır |
| Kütüğü karşıya yükleme | UpLa | "Hata ayıklama kütüğü hassas bilgiler içerebilir. Devam etmek istediğinize emin misiniz?" | Evet / Hayır |
| Kaydı iptal etme (seçenek açıksa) | UpLa | "Kaydı iptal etmek istediğinize emin misiniz?" | Evet / Hayır |

Dil değişikliği, kişisel dizin, tema ve ayar sıfırlama soruları §8.1'de; hesaptan çıkış soruları §9.3'te.

---

## 8. Ayar pencereleri

Kaynak: `ShareX/Forms/ApplicationSettingsForm.*`, `TaskSettingsForm.*`, `HotkeySettingsForm.cs`, `Controls/HotkeySelectionControl.cs`, `ShareX.UploadersLib/Forms/UploadersConfigForm.cs`, `Upla/UplaSettingsControl.cs`, `ApplicationConfig.cs`, `TaskSettings.cs`.

### 8.0 Bütün ayar pencerelerinde ortak

- **Yerleşim:** solda bir gezinme ağacı (`TabToTreeView`), sağda seçili sayfa.
  - Ağaç yazı tipi Microsoft Sans Serif 9,75 pt. Bütün düğümler her zaman açık, kapatılamaz.
  - Başlıksız bir alt sekme üst düğümünde gösterilir; örneğin "Genel" genel sayfayı gösterir, "Uyarılar" onun çocuğudur.
  - İçerik alanı bir düğüm seçilene kadar gizlidir; pencere açılınca ilk düğüm seçilir.
- **Tamam/İptal/Uygula yok.** Her değişiklik hemen uygulanır.
  - Uygulama ayarları, Görev ayarları ve Kısayol ayarları **modal** (`ShowDialog`); kapanınca ApplicationConfig.json veya HotkeysConfig.json kaydedilir.
  - Hedef ayarları **modsuz ve tek örnekli**; yeniden açmak var olan pencereyi öne getirir. Kapanınca UploadersConfig.json kaydedilir.
- **Esc** Uygulama ayarları, Görev ayarları, Hedef ayarları ve giriş penceresini kapatır; Kısayol ayarları'nı kapatmaz.
- **Tema:** bütün pencereler seçili UpLa temasını kullanır; tema koyuysa başlık çubuğu da koyu.
- **Değişken menüsü ("code menu").** Bazı metin kutuları odaklanınca veya tıklanınca bir menü açar:
  - Kutunun sağında açılır; Görev sayfasındaki klasör kutusunda altında.
  - Yazı tipi Lucida Console 8. Her öğe "`%kod - açıklama`". Öğeler kategori alt menülerinde; en sonda ayırıcı ve **Kapat**.
  - Bir öğeye tıklamak kodu imlecin yerine ekler. Enter veya Esc menüyü kapatır.
  - Listeler §13.1 ve §13.2'de.

### 8.1 Uygulama ayarları (ApplicationSettingsForm)

- **Açan:** ana penceredeki **Uygulama ayarları...** ve tepsi menüsü.
- **Başlık:** "UpLa - Uygulama ayarları" (UpLa - Application settings).
- **Boyut:** iç alan 737×402, en küçük 640×440, ortalı. Ağaç genişliği 175.
- **Ağaç (12 düğüm):** **Genel** (General) · **Tema** (Theme) · **Entegrasyon** (Integration) · **Yollar** (Paths) · **Ayarlar** (Settings) · **Ana pencere** (Main window) · **Pano biçimleri** (Clipboard formats) · **Yükleme** (Upload) · **Geçmiş** (History) · **Yazdırma** (Print) · **Vekil Sunucu** (Proxy) · **Gelişmiş** (Advanced).

#### 8.1.1 Genel

İki sütun: etiketler solda (x≈13), sağ sütun denetimleri x=248, genişlik 288.

| Türkçe | English | Tür | Varsayılan | Etkisi / not |
|---|---|---|---|---|
| **Dil:** | Language: | MBTN, bayrak simgesi ve dil adı | **Otomatik** | Arayüz dilini değiştirir, sonra "UpLa dil değişikliğinin uygulanması için yeniden başlatılmalı.\nUpLa'yı yeniden başlatmak ister misiniz?" diye sorar (başlık "UpLa - Onay"); Evet yeniden başlatır. Menüde 25 öğe: "Otomatik" ve dillerin kendi adları: العربية, Nederlands, English, Français, Deutsch, עִברִית, Magyar, Bahasa Indonesia, Italiano, 日本語, 한국어, Español mexicano, فارسی, Polski, Português, Português-Brasil, Română, Русский, 简体中文, Español, 繁體中文, Türkçe, Українська, Tiếng Việt. |
| **Bildirim alanında simge göster** | Show tray icon | CB | ✓ | Tepsi simgesini hemen gösterir/gizler; sonraki satırı etkinleştirir |
| **Başlangıçta simge durumuna küçült** | Minimize to tray on start | CB (sağ sütun) | ☐ | Tepsi simgesi kapalıyken devre dışı |
| **Tepsi simgesinde durum göster** | Show progress in tray icon | CB | ✓ | |
| **Görev çubuğu tuşunda durum göster** | Show progress in taskbar button | CB (sağ sütun) | ✓ | İşletim sisteminde görev çubuğu ilerlemesi yoksa devre dışı |
| **Ana pencere konumunu hatırla** | Remember main window position | CB | ☐ | |
| **Ana pencere boyutunu hatırla** | Remember main window size | CB (sağ sütun) | ☐ | |
| **Beyaz UpLa ikonu kullan** | Use white UpLa icon | CB | ☐ | Beyaz tepsi simgesi. UpLa 1.0'ın `UseWhiteUpLaIcon` anahtarı da okunur. |
| **Tepsi simgesi bir kere tıklandığında:** | On tray icon left click: | DD, 54 görev türü düz liste (§3.3) | **Bölge yakala** | |
| **Tepsi simgesi çift tıklandığında:** | On tray icon double left click: | DD (aynı liste) | **Ana pencereyi aç** | |
| **Tepsi simgesi orta tuş ile tıklandığında:** | On tray icon middle click: | DD (aynı liste) | **İçerik gösterici ile panodan yükle** | |
| **Hızlı görev menüsünü düzenle...** | Edit quick task menu... | BTN 288×32 | | Hızlı görev menüsü düzenleyicisi (§8.5.1) |
| **Güncellemeleri otomatik kontrol et** | Automatically check for updates | CB | ✓ | Günde bir kez github.com/Agnostique/UpLa sürümlerine bakar. Store sürümünde ve HKLM/HKCU\SOFTWARE\UpLa altında `DisableUpdateCheck` varken gizli. |
| **Güncelleme kanalı:** (Sürüm / Ön sürüm / Dev) | Update channel: (Release / Pre-release / Dev) | LBL + DD | Release | **Gizli** (UpLa'nın tek kanalı var) |
| **Geliştirici sürümünü kur...** | Install dev build... | BTN | | **Gizli** |

#### 8.1.2 Tema

| Türkçe | English | Tür | Varsayılan | Etkisi |
|---|---|---|---|---|
| **Ekle** | Add | BTN | | "Dark"ın kopyası olan yeni bir tema ekler ve seçer |
| **Kaldır** | Remove | BTN | | Seçili temayı kaldırır; liste boşsa devre dışı |
| (tema listesi) | | DD 304 px | Dark | Seçilen tema bütün pencerelere canlı uygulanır |
| " **Dışa aktar**" | " Export" | MBTN: **Panoya kopyala** · **Dosyaya kaydet...** · **Metin olarak yükle** | | Temayı JSON olarak dışa aktarır. "Metin olarak yükle" metni metin yükleyiciye gönderir; upla.com.tr metni reddettiği için UpLa'da işe yaramaz. |
| " **İçe aktar**" | " Import" | MBTN: **Panodan** · **Dosyadan...** · **Adresten...** (soru "Ayarların indirileceği adres") | | İçe aktarılan temayı ekler |
| **Sıfırla...** | Reset... | BTN | | "Temaları sıfırlamak ister misiniz?" (başlık "UpLa - Onayla"), sonra 6 varsayılan temayı geri getirir |
| (tema özellikleri) | | PG; araç çubuğu yok; sırasız; İngilizce özellik adları | | Name, BackgroundColor, LightBackgroundColor, DarkBackgroundColor, TextColor, BorderColor, CheckerColor, CheckerColor2, CheckerSize (15), LinkColor, MenuHighlightColor, MenuHighlightBorderColor, MenuBorderColor, MenuCheckBackgroundColor, MenuFont (Segoe UI 9,75), ContextMenuFont (Segoe UI 9,75), ContextMenuOpacity (100; 10–100), SeparatorLightColor, SeparatorDarkColor. Değişiklikler canlı uygulanır. |

Varsayılan temalar ve renkleri §13.7'de.

#### 8.1.3 Entegrasyon

Başlığı "Windows" olan tek bir grup (çevirisi yok):

| Türkçe | English | Tür | Varsayılan | Not |
|---|---|---|---|---|
| **Windows başladığında UpLa'yı çalıştır** | Run UpLa when Windows starts | CB | Gerçek başlangıç durumunu gösterir. Kurulumdaki "Run UpLa when Windows starts" görevi varsayılan olarak işaretli; Store bildiriminde StartupTask açık. | Durum sayfa her açılışta yeniden okunur. Başlangıcı başka yer yönetiyorsa kutu devre dışı kalır ve şunlardan birini gösterir: **Başlangıç görev yöneticisinden devre dışı bırakılmış**, **Başlangıç, kuruluşunuz tarafından devre dışı bırakıldı**, **Başlangıç, kuruluşunuz tarafından etkinleştirildi** (işaretli). |
| **"UpLa ile yükle" tuşunu Windows sağ tık menüsünde göster** | Show "Upload with UpLa" button in Windows Explorer context menu | CB | kayıt defterindeki durum | Store sürümünde gizli |
| **"UpLa ile düzenle" tuşunu Windows sağ tık menüsünde göster** | Show "Edit with UpLa" button in Windows Explorer context menu | CB | kayıt defterindeki durum | Store sürümünde gizli |
| **"Gönder" menüsünde UpLa göster** | Show UpLa in "Send to" menu | CB | "Gönder" kısayolunun durumu | Store sürümünde gizli |

Kaldırılanlar (93d8eb61d, f306c97b5): "Chrome uzantısı", "Firefox eklentisi" ve "Steam" grupları.

#### 8.1.4 Yollar

| Türkçe | English | Tür | Varsayılan | Etkisi |
|---|---|---|---|---|
| **UpLa kişisel dizini:** | UpLa personal folder: | TXT 408 + **Gözat...** (pencere başlığı "UpLa kişisel dizin yolu seç") | boş | Kişisel dizini değiştirir; PersonalPath.cfg'ye yazılır |
| **Uygula** | Apply | BTN, yalnızca değişiklikten sonra etkin | | Kaydeder, sonra "Kişisel klasör değişikliklerinin uygulanması için UpLa'nın yeniden başlatılması gerekir.\n\nUpLa'yı yeniden başlatmak ister misiniz?" diye sorar (başlık "UpLa - Onay") |
| **Aç...** | Open... | BTN | | Önizlemedeki klasörü açar |
| (önizleme) | | LBL | Belgeler\UpLa (taşınabilir: <exe klasörü>\UpLa) | Çözümlenmiş yol ya da "Error: ..." |
| **Özel ekran görüntüsü dizini kullan:** | Use custom screenshots folder: | CB | ☐ | |
| (yol) + **Gözat...** | Browse... | TXT + BTN (pencere "Ekran görüntüsü dizini seç") | "" | |
| **Alt dizin şablonu:** | Sub folder pattern: | TXT + değişken menüsü (%t %pn %i %width %height %n hariç dosya adı değişkenleri) | `%y-%mo` | |
| **Aç...** + önizleme | Open... | BTN + LBL | | Önizleme tam ekran görüntüsü klasörünü gösterir, örn. …\Belgeler\UpLa\Screenshots\2026-10 |
| **Pencere için alt dizin şablonu:** | Sub folder pattern for window: | TXT + değişken menüsü (%i ve %n hariç) | "" | Pencere yakalamalarında kullanılır |

#### 8.1.5 Ayarlar

| Türkçe | English | Tür | Varsayılan | Etkisi |
|---|---|---|---|---|
| (uyarı simgesi) **Not: Dışarı aktarılan dosyayı kimseyle paylaşmayınız, çünkü hesap detayları ve yükleme girdileri gibi kişisel bilgiler içerebilir.** | Note: Do not share the exported file with anyone because it might contain private information such as account details and your upload history. | LBL | | |
| **Ayarlar** | Settings | CB | ✓ | Yedeğe ApplicationConfig, UploadersConfig ve HotkeysConfig'i katar |
| **Geçmiş** | History | CB | ✓ | Yedeğe History.json'u katar |
| **Dışarı aktar...** | Export... | BTN; kutulardan biri işaretliyken etkin | | Kaydetme penceresi; süzgeç "UpLa backup (*.sxb)", varsayılan ad `UpLa-<sürüm>-<bilgisayar>-backup.sxb` (bir zip). Çalışırken kayan ilerleme çubuğu. |
| **İçeri aktar...** | Import... | BTN | | Bir .sxb açar, bütün ayarları ve arayüzü yeniden yükler |
| **Ayarları sıfırla...** | Reset settings... | BTN | | "UpLa ayarlarını sıfırlamak ister misiniz?" (başlık "UpLa - Onayla") |
| **Eski yedek dosyalarını otomatik olarak temizle** | Automatically cleanup old backup files | CB | ☐ | |
| **Eski günlük dosyalarını otomatik olarak temizle** | Automatically cleanup old log files | CB | ☐ | |
| **Saklancak dosya sayısı:** | Number of files to keep: | NUM, en az 1 | 10 | |

#### 8.1.6 Ana pencere

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Menüyü göster** | Show menu | CB | ✓ |
| **Görev görünümü modu:** | Task view mode: | DD: **Liste görünümü** / **Küçük resim görünümü** | Küçük resim görünümü |

**Küçük resim görünümü** (Thumbnail view) grubu:

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Başlığı göster** | Show title | CB | ✓ |
| **Başlık konumu:** | Title location: | DD: **Üst** / **Alt** | Üst |
| **Küçük resim boyutu:** | Thumbnail size: | NUM G "x" NUM Y (her biri 50–500) + **Sıfırla** (200×150 yapar) | 200 × 150 |
| **Küçük resim tıklama eylemi:** | Thumbnail click action: | DD: **Varsayılan** · **Seç** · **Resim görüntüleyiciyi aç** · **Dosya aç** · **Klasör aç** · **Adresi aç** · **Resimi düzenle** | Varsayılan |

**Liste görünümü** (List view) grubu:

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Kolonları göster** | Show columns | CB | ✓ |
| **Resim ön izleme görünürlüğü:** | Image preview visibility: | DD: **Göster** · **Gizle** · **Otomatik** | Otomatik |
| **Resim ön izleme konumu:** | Image preview location: | DD: **Kenar** · **Alt** | Kenar |

#### 8.1.7 Pano biçimleri

| Türkçe | English | Tür | Not |
|---|---|---|---|
| **Bu biçimler ana pencere sağ tık menüsünde "Kopyala" alt menüsü altında görünecektir.** | These formats will appear under "Copy" sub-menu in the main window context menu. | LBL | |
| **Ekle...** | Add... | BTN | Pano içerik biçimi penceresi (§8.5.3) |
| **Düzenle...** | Edit... | BTN | Satıra çift tıklamak da aynı işi yapar |
| **Kaldır** | Remove | BTN | |
| (liste) | | LIST, sütunlar **Açıklama** / **Biçim** | Varsayılan olarak boş |

#### 8.1.8 Yükleme

| Türkçe | English | Tür | Varsayılan | Not |
|---|---|---|---|---|
| **Aynı anda yükleme limiti:** | Simultaneous upload limit: | NUM 0–25, ipucu "0 - 25 (0 iptal eder)" | **5** | UpLa varsayılanı; ShareX'te 0 |
| **Tampon boyutu:** | Buffer size: | DD, 14 boyut (2^n KB, ondalık birimle gösterilir): 1 KB … 8 MB | 33 KB | |
| **Yükleme sırasında hata olursa kaç kez tekrar denensin:** | Number of times to retry if upload fails: | NUM 0–5 | 1 | |
| **Tekrar denerken ikincil yükleyicileri sırasına göre kullan** | Use secondary uploaders order of preference when retrying | CB | ☐ | |
| **İkincil resim yükleyiciler** | Secondary image uploaders | grup içinde LIST, sürükleyerek sıralanır | upla.com.tr, Dosya yükleyici | Yalnızca UpLa'da kalan hedefler |
| **İkincil yazı yükleyiciler** | Secondary text uploaders | LIST | Dosya yükleyici | |
| **İkincil dosya yükleyiciler** | Secondary file uploaders | LIST | upla.com.tr | |

#### 8.1.9 Geçmiş

**Geçmiş** grubu:

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Görevleri geçmişe kaydet** | Save tasks to history | CB | ✓ |
| **Adres boş değilse kaydet** | Only save if URL is not empty | CB | ☐ |

**Son görevler** (Recent tasks) grubu:

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Son görevleri kaydet** | Save recent tasks | CB | ✓ (UpLa; ShareX'te kapalı) |
| **En fazla kaydedilecek görev sayısı:** | Maximum number of tasks to save: | NUM, en az 1 | 10 |
| **Açılışta ana pencerede son görevleri göster** | Show recent tasks in main window on startup | CB | ✓ |
| **Tepsi menüsünde son görevleri göster** | Show recent tasks in tray menu | CB | ✓ |
| **Tepsi menüsünde son görevleri ilk göster** | In tray menu show most recent tasks first | CB | ☐ |

#### 8.1.10 Yazdırma

| Türkçe | English | Tür | Varsayılan | Not |
|---|---|---|---|---|
| **Resim yazdırma ayarları...** | Image print settings... | BTN 208 | | Aktif ekranı yakalar ve onunla yazdırma seçeneklerini açar (§8.5.4) |
| **Resim yazdırma ayarları penceresini gösterme** | Don't show image print settings dialog | CB | ☐ | |
| **Windows yazdırma penceresini gösterme** | Don't show Windows print dialog | CB | ☐ | |
| **Varsayılan yazıcıyı değiştir:** | Default printer override: | TXT 352 | "" | Yalnızca önceki kutu işaretliyken görünür |

#### 8.1.11 Vekil Sunucu

| Türkçe | English | Tür | Varsayılan | Etkin olduğu durum |
|---|---|---|---|---|
| **Vekil sunucu konfigürasyonu:** | Proxy configuration: | DD: **Hiçbiri** · **Elle** · **Otomatik** | **Elle** (sunucu boş) | her zaman. Otomatik, sunucuyu ve portu sistem vekil sunucusundan doldurur. |
| **Sunucu:** | Host: | TXT | "" | Elle |
| **Port:** | Port: | NUM 0–65535 | 0 | Elle |
| **Kullanıcı adı:** | Username: | TXT | "" | Elle veya Otomatik |
| **Şifre:** | Password: | TXT (gizli karakterler) | "" | Elle veya Otomatik |

#### 8.1.12 Gelişmiş

Kategorili, araç çubuğu olmayan bir özellik ızgarası. Kategori adları, özellik adları ve ızgaranın altındaki açıklamalar İngilizcedir, çevrilmemiştir. Kategoriler alfabetik, özellikler kaynak sırasındadır. Açıklamalarda "ShareX" yerine "UpLa" yazar. Toplam 32 özellik:

| Kategori | Özellik (varsayılan) |
|---|---|
| Application | BinaryUnits (False; "Calculate and show file sizes in binary units (KiB, MiB etc.)") · ShowMostRecentTaskFirst (False) · WorkflowsOnlyShowEdited (False) · TrayAutoExpandCaptureMenu (False) · ShowMainWindowTip (True) · BrowserPath ("", exe seçici; "URLs will open using this path instead of default browser. Example path: chrome.exe") · SaveSettingsAfterTaskCompleted (False) · AutoSelectLastCompletedTask (False) · DevMode (False) |
| Clipboard | ShowClipboardContentViewer (True) · DefaultClipboardCopyImageFillBackground (True) · UseAlternativeClipboardCopyImage (False) · UseAlternativeClipboardGetImage (False) |
| Drag and drop window | DropSize (150) · DropOffset (5) · DropAlignment (BottomRight) · DropOpacity (100) · DropHoverOpacity (255) |
| Hotkey | DisableHotkeys (False) · DisableHotkeysOnFullscreen (False) · HotkeyRepeatLimit (500, en az 200) |
| Image | RotateImageByExifOrientationData (True) · PNGStripColorSpaceInformation (False) |
| Paths | UseMachineSpecificUploadersConfig (False) · CustomUploadersConfigPath · CustomHotkeysConfigPath · CustomScreenshotsPath2 (klasör seçiciler) |
| Upload | DisableUpload (False) · URLEncodeIgnoreEmoji (True) · **ShowUploadWarning** (True, "Show first time upload warning."; UpLa geri ekledi, ilk "upla.com.tr'ye otomatik yükleme" sorusunu yönetir) · ShowMultiUploadWarning (True) · ShowLargeFileSizeWarning (100 MB; 0 kapatır) |

### 8.2 Görev ayarları (TaskSettingsForm)

**İki mod:**
- **A. Varsayılan görev ayarları.** Ana penceredeki **Görev ayarları...** ve tepsi açar (`TaskSettingsForm(DefaultTaskSettings, isDefault: true)`).
  - Başlık "UpLa - Görev ayarları" (UpLa - Task settings).
  - **Görev** sayfası yok; bütün "… ayarlarını değiştir" kutuları gizli, bütün sayfalar her zaman düzenlenebilir.
  - "Genel"i seçmek çocuğu "Uyarılar"a, "Yükleme"yi seçmek "Dosya adlandırma"ya atlar (kendi sayfalarında yalnızca gizli değiştir kutusu var).
  - Pencere Genel › Uyarılar'da açılır.
- **B. Kısayola özel görev ayarları.** Kısayol ayarları'ndaki dişli düğmesi veya **Düzenle...** açar.
  - Başlık "UpLa - {0} için görev ayarları" (UpLa - Task settings for {0}); {0} açıklama, yoksa görev adı; başlık canlı güncellenir.
  - **Görev** sayfası ve "… ayarlarını değiştir" (Override …) kutuları var. Yeni kısayolda hepsi kapalı; kapalı bir kutunun sayfa içeriği gri olur.

**Pencere:** iç alan 784×511, en küçük 800×550, ortalı. Ağaç genişliği 190.

**Ağaç:**
- (**Görev** / Task, yalnızca B)
- **Genel** (General) › **Uyarılar** (Notifications)
- **Resim** (Image) › **Efekt** (Effects)
- **Yakalama** (Capture) › **Bölge yakala** (Region capture) · **Ekran kaydedici** (Screen recorder) · **OCR**
- **Yükleme** (Upload) › **Dosya adlandırma** (File naming) · **Panodan yükleme** (Clipboard upload) · **Yükleyici filtreleri** (Uploader filters)
- **Araçlar** (Tools)
- **Aksiyon** (Actions)
- **Dizinleri takip et** (Watch folders)
- **Gelişmiş** (Advanced)

Kaldırılan düğüm: Resim › **Küçük resim** (Thumbnail).

#### 8.2.1 Görev (yalnızca B modu)

| Türkçe | English | Tür | Varsayılan | Etkisi |
|---|---|---|---|---|
| **Görev:** | Task: | MBTN, tam genişlik (552) | kısayolun görevi | Simge ve görev adı. Menü görev türü menüsüdür (§3.3): "Hiçbiri" ve 5 kategori alt menüsü, geçerli görev onaylı. |
| **Açıklama:** | Description: | TXT | "" | Özel ad; kısayol listesinde ve pencere başlığında görev adı yerine gösterilir. |
| **Yakalama sonrası ayarlarını değiştir** | Override after capture tasks | CB | ☐ | Sonraki düğmeyi etkinleştirir |
| "**Yakalama sonrası:** {liste}" | After capture: {list} | MBTN, 20 görev (§13.9) simgeli onay öğeleri | Resimi panoya kopyala, Resimi dosya olarak kaydet, Resimi yükle | Düğme metni etkin görevleri ", " ile listeler. §12.1'deki hata burada tıklamayı da bozar. |
| **Yükleme sonrası ayarlarını değiştir** | Override after upload tasks | CB | ☐ | |
| "**Yükleme sonrası:** {liste}" | After upload: {list} | MBTN, 5 görev | Adresi panoya kopyala | §12.1 |
| **Hedefleri değiştir** | Override destinations | CB | ☐ | |
| **Hedefler...** | Destinations... | MBTN, 4 alt menü (radyo) | | **Resim yükleyici: upla.com.tr** → upla.com.tr, Dosya yükleyici ▸ upla.com.tr · **Metin yükleyici: upla.com.tr** → Dosya yükleyici ▸ upla.com.tr · **Dosya yükleyici: upla.com.tr** → upla.com.tr · **Adres paylaşım servisi: Facebook** → Facebook, Reddit, Pinterest, Tumblr, LinkedIn, VK |
| **Varsayılan ekran görüntüsü klasörünü değiştir** | Override screenshots folder | CB | ☐ | Sonraki satırı etkinleştirir |
| (klasör) + **Gözat...** | Browse... | TXT 448, değişken menüsü altında açılır (%t %pn %i %width %height %n hariç) + BTN | "" | |

Kaldırılanlar (ab03cc772): "Varsayılan FTP hesabını değiştir", "Varsayılan özel yükleyiciyi değiştir", Hedefler'deki "Adres kısaltıcılar".

#### 8.2.2 Genel › Uyarılar

B modunda Genel sayfasında yalnızca **Genel ayarları değiştir** (Override general settings) var.

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Yakalama yapıldıktan sonra ses çal** | Play sound after capture is made | CB | ✓ |
| **Görev bittikten sonra ses çal** | Play sound after task is completed | CB | ✓ |
| **İşlem tamamlandıktan sonra ses çal** | Play sound after action is completed | CB | ✓ |
| **Görev bittikten sonra tost bildirimi göster** | Show toast notification after task is completed | CB; alttaki grubu etkinleştirir | ✓ |

**Tost bildirimi** (Toast notification) grubu:

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Süre:** … **saniye** | Duration: … seconds | NUM 0–30, 1 ondalık | 3,0 |
| **Solma süresi:** … **saniye** | Fade duration: … seconds | NUM 0–30, 1 ondalık | 1,0 |
| **Konum:** | Placement: | DD, 9 konum (§13.3) | **Sağ alt** |
| **Boyut:** G x Y | Size: | NUM 100–1000 × NUM 100–1000 | 400 × 300 |
| **Sol tıklama eylemi:** | Left click action: | DD, 12 eylem (§13.3) | **Bağlantı aç** |
| **Sağ tıklama eylemi:** | Right click action: | DD | **Uyarı penceresini kapat** |
| **Orta tıklama eylemi:** | Middle click action: | DD | **Resimi düzenle** |
| **Ekran görüntüsü alırken otomatik olarak sakla** | Automatically hide on screen capture | CB | ✓ |
| **Tam ekran ise uyarıları devre dışı bırak** | Disable toast notifications on fullscreen | CB | ☐ |

Grubun altında her satır CB + TXT 280 + "..." BTN (süzgeç "Audio file (*.wav)"). Metin kutusu ve düğme yalnızca kutu işaretliyken etkin. Hepsi ☐, yol boş:
- **Kişisel yakalama sesi kullan:** (Use custom capture sound:)
- **Kişisel görev tamamlanma sesi kullan:** (Use custom task completed sound:)
- **Kişisel işlem tamamlandı sesi kullan:** (Use custom action completed sound:)
- **Kişisel hata sesi kullan:** (Use custom error sound:)

#### 8.2.3 Resim › (kalite) ve Efekt

B modunda ilk satır **Resim ayarlarını değiştir** (Override image settings).

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Resim biçimi:** | Image format: | DD 64 px: PNG, JPEG, GIF, BMP, TIFF (çevrilmez) | PNG |
| **PNG bit derinliği:** | PNG bit depth: | DD: **Varsayılan** · **Otomatik olarak tespit et** · **32 bit** · **24 bit** | Varsayılan |
| **JPEG kalitesi:** (ipucu "0 - 100") | JPEG quality: | NUM 0–100 | 90 |
| **GIF kalitesi:** | GIF quality: | DD, 4 seçenek (§13.4) | Varsayılan .NET işlemesi (Hızlı işleme fakat ortalama kalite) |
| **Eğer resim dosya boyutu ayarlanan boyutdan fazlaysa JPEG kullan:** | Use JPEG as image format if image size is bigger than the specified size: | CB | ✓ |
| (boyut) **kB** | | NUM 100–100000 | 2048 |
| **JPEG kalitesini belirtilen resim boyutuna yakın gelicek şekilde otomatik ayarla** | Adjust JPEG quality automatically to keep image size closer to the specified size | CB | ☐ |
| **Dosya varsa:** | If file exist: | DD: **Ne yapılacağını sor** · **Dosya üzerine yaz** · **Dosya adına numara ekle** · **Kaydetme** | Ne yapılacağını sor |

**Efekt** (Effects):

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **"Yakalama sonrası -> Resim efekti ekle" menüsünden resim efektlerini açıp kapatabilirsiniz.** | Note: You can enable/disable image effects from "After capture tasks -> Add image effects". | LBL | |
| **Resim efektleri ayarları...** | Image effects configuration... | BTN 208; resim efektleri penceresini açar (tek örnek) | |
| **Yakalama sonrası resim efektleri ekranını göster** | Show image effects window after capture | CB | ☐ |
| **Efektleri sadece yakalama bölgesine uygula** | Only apply effects to region capture | CB | ☐ |
| **Rastgele resim efekti kullan** | Use random image effect | CB | ☐ |

#### 8.2.4 Yakalama › (genel), Bölge yakala, Ekran kaydedici, OCR

B modunda ilk satır **Yakalama ayarlarını değiştir** (Override capture settings).

| Türkçe | English | Tür | Varsayılan | Not |
|---|---|---|---|---|
| **Ekran görüntülerinde imleç göster** | Show cursor in screenshots | CB | ✓ | |
| **Ekran görüntüsü gecikmesi:** … **saniye** | Screenshot delay: … seconds | NUM 0–300, 1 ondalık | 0 | |
| **Pencereyi şeffaflık ile yakala** | Capture window with transparency | CB | ☐ | |
| **Pencereyi gölge ile yakala (şeffaflık gerektirir)** | Capture window with shadow (requires transparency) | CB | ✓ | Şeffaflık açık değilse devre dışı |
| **Gölge çıkıntısı:** | Shadow offset: | NUM 0–200 | 100 | |
| **Pencere veya aktif pencere yakalama sırasında başlık çubuğunu yakalama** | Capture client area when doing window or active window capture | CB | ☐ | |
| **Masaüstü simgelerini otomatik gizle** | Automatically hide desktop icons | CB | ☐ | |
| **Pencere yakalama sırasında pencere görev çubuğu ile kesişirse görev çubuğunu gizle** | When doing window capture if window intersects with taskbar then hide taskbar | CB | ☐ | |
| **Önceden ayarlanmış bölge:** sütunlar **X** / **Y** / **Genişlik** / **Yükseklik** | Pre configured region: X / Y / Width / Height | 4 × NUM | 0, 0, 0, 0 | "Özel bölge yakala" kullanır |
| **Bölge seç...** | Select region... | BTN | | Bölge seçiciyi açar ve dört sayıyı doldurur |
| **Önceden yapılandırılmış pencere başlığı:** | Pre configured window title: | TXT 360 | "" | "Önceden yapılandırılmış pencereyi yakala" kullanır |

**Bölge yakala** (Region capture). Etiketler solda, girişler x=312'de bir sütunda.

| Türkçe | English | Tür | Varsayılan | Not |
|---|---|---|---|---|
| **Çoklu bölge modunu kullan, ayrıca bölgeleri yeniden boyutlandırmayı veya taşımayıda sağlar** | Use multi region mode which will also allow resizing and moving regions | CB | ☐ | Ayar tersine saklanır (QuickCrop = true) |
| **Fare sağ tuşuna basıldığında:** | Mouse right click action: | DD, 8 eylem (§13.5) | **Nesneyi sil veya yakalamayı iptal et** | |
| **Fare orta tuşuna basıldığında:** | Mouse middle click action: | DD | **Araç tipini değiştir** | |
| **Fare 4 tuşuna basıldığında:** | Mouse 4 click action: | DD | **Tam ekran yakala** | |
| **Fare 5 tuşuna basıldığında:** | Mouse 5 click action: | DD | **Aktif ekranı yakala** | |
| **Pencere alanlarını tespit edip imleç ile yakalamaya izin ver** | Detect window regions and allow cursor hover capture | CB | ✓ | |
| **Ayrıca pencere içindeki kontrol bölgelerini tespit et** | Also detect control regions inside windows | CB | ✓ | Yalnızca önceki kutu açıkken etkin |
| **Arka plan karartma yoğunluğu:** … **%** | Background dim strength: | NUM 0–50 | 20 | |
| **İmleç yanında özel bilgi yazısı kullan:** | Use custom info text near cursor: | CB + TXT, piksel bilgisi değişken menüsü | ☐; `X: $x, Y: $y$nR: $r, G: $g, B: $b$nHex: $hex` | |
| **"Alt" tuşuna basılı tutulduğunda bölgeyi bu boyutlara kitle:** | Sizes region will snap to when holding "Alt" key: | DD + "+" BTN + "-" BTN | 426x240, 640x360, 854x480, 1280x720, 1920x1080 | "+" satır içi kutu açar: **Genişlik:** NUM 2–10000 (100), **Yükseklik:** NUM 2–10000 (100), **Ekle**, **İptal**. "-" seçili boyutu kaldırır. |
| **Pozisyon ve boyut bilgisi göster** | Show position and size info | CB | ✓ | |
| **İmleç yanında büyüteç göster** | Show magnifier near cursor | CB | ✓ | Sonraki üç satırı etkinleştirir |
| **Kare şeklinde büyüteç kullan yuvarlak yerine** | Use square shape magnifier instead of circle | CB | ☐ | |
| **Büyüteç piksel sayısı:** | Magnifier pixel count: | NUM 3–35, adım 2 | 15 | |
| **Büyüteç piksel boyutu:** | Magnifier pixel size: | NUM 3–30 | 10 | |
| **Ekranı kaplayan artı şeklinde imleç göster** | Show screen wide crosshair | CB | ☐ | |
| **Merkez artı işaretini göster** | Show center crosshair | CB | ☐ | |
| **Sabit boyut bölge modu:** **Genişlik:** NUM **Yükseklik:** NUM | Fixed size region mode: Width: Height: | CB + 2 × NUM 10–10000, adım 10 | ☐; 250 × 250 | |
| **Sol üst köşede FPS göster** | Show FPS | CB | ☐ | |
| **FPS limiti:** | FPS limit: | NUM 0–300 | 100 | |
| **Bölge yakalama ve imleci aktif ekran alanına limitle** | Restrict region capture and cursor within the active monitor | CB | ☐ | |

**Ekran kaydedici:** §6.3.

**OCR:**

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Varsayılan dil:** | Default language: | DD, Windows OCR dilleri görünen ada göre sıralı; "?" BTN https://getsharex.com/docs/ocr açar | ilk uygun dil ("en" saklanır) |
| **Sessizce OCR uygula** | Process OCR silently | CB; sonraki satırı devre dışı bırakır | ☐ |
| **Sonuçları otomatik olarak panoya kopyala** | Automatically copy results to clipboard | CB | ☐ |
| **Servis bağlantısı açıldıktan sonra OCR penceresini kapat** | Close OCR window after opening service link | CB | ☐ |

#### 8.2.5 Yükleme › Dosya adlandırma, Panodan yükleme, Yükleyici filtreleri

B modunda Yükleme sayfasında yalnızca **Yükleme ayarlarını değiştir** (Override upload settings) var.

**Dosya adlandırma** (File naming):

| Türkçe | English | Tür | Varsayılan | Not |
|---|---|---|---|---|
| **Yakalama veya panodan yükleme için isim deseni:** | Name pattern for capture or clipboard upload: | TXT + değişken menüsü (%n %t %pn hariç) | `%ra{10}` | |
| "**Ön izleme:** <örnek>" | Preview: | LBL | | Örnek 1920×1080 bir resimle |
| **Aktif pencere yakalama için isim deseni:** | Name pattern for window capture: | TXT + değişken menüsü (%n hariç) | `%pn_%ra{10}` | |
| "**Ön izleme:** <örnek>" | Preview: | LBL | | Örnek "UpLa" işlem adı ve bu pencerenin başlığıyla |
| **Dosya yükleme için de gerçek dosya ismi yerine isim deseni kullan** | Use name pattern for file uploads instead of actual file name | CB | ☐ | |
| **Otomatik artan sayı:** | Auto increment number: | NUM 0–1000000000 + **Değiştir** BTN | 0 | Genel değer; yalnızca "Değiştir"e basınca kaydedilir |
| **Kişisel zaman dilimi kullan:** | Use custom time zone: | CB + Windows saat dilimleri DD | ☐; UTC | |
| **Adreslerdeki problematik karakterleri alt çizgi ile değiştir yüklerken** | Replace characters problematic in URLs by underscores when uploading | CB | ☐ | |
| **Sonuç linki regex değişimleri kullanarak değiştir** | Replace result URL using regular expression substitutions | CB; sonraki iki satırı etkinleştirir | ☐ | |
| **Desen:** | Pattern: | TXT | `^https?://(.+)$` | |
| **Değiştirme:** | Replacement: | TXT | `https://$1` | |

**Panodan yükleme** (Clipboard upload):

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Eğer pano dosya linki içeriyorsa indirip karşıya yükle** | If clipboard contains a file URL then download it and upload | CB | ☐ |
| **Pano adres içeriyorsa adres paylaşım servisi ile paylaş** | If clipboard contains a URL then share it using URL sharing service | CB | ☐ |

Kaldırılanlar: "Pano adres içeriyorsa adres kısaltıcı kullan" ve "Pano dizin yolu içeriyorsa dizini indeksle ve indeksi yükle".

**Yükleyici filtreleri** (Uploader filters):

| Türkçe | English | Tür | Not |
|---|---|---|---|
| **Yükleyici:** | Uploader: | DD | İki öğe, ikisi de "upla.com.tr" görünür (resim servisi ve dosya servisi) |
| **Uzantı filtresi:** | Extension filter: | TXT; yanında **Örnek: png, jpg, jpeg** | |
| **Ekle** / **Güncelle** / **Kaldır** | Add / Update / Remove | 3 × BTN | |
| (filtre listesi) | | LIST, sütunlar **Yükleyici** / **Uzantı** | Varsayılan boş. Yükleyici sütunu iç kimliği "Chevereto" gösterir. |

#### 8.2.6 Araçlar

B modunda ilk satır **Araç ayarlarını değiştir** (Override tools settings). Üç kutu da piksel bilgisi değişken menüsünü kullanır.

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Ekran renk seçici formatı:** | Screen color picker format: | TXT 288 | `$hex` |
| **Ekran renk seçici formatı (Ctrl + tıklama):** | Screen color picker format (Ctrl + click): | TXT | `$r255, $g255, $b255` |
| **Ekran renk seçici bilgi yazısı:** | Screen color picker info text: | TXT | `RGB: $r255, $g255, $b255$nHex: $hex$nX: $x Y: $y` |

Kaldırılan: "Eski görüntü düzenleyiciyi kullan" (d51837d47).

#### 8.2.7 Aksiyon

B modunda ilk satır **Aksiyon ayarlarını değiştir** (Override actions).

| Türkçe | English | Tür | Not |
|---|---|---|---|
| **Not: Aksiyonları buradan etkinleştirebilir veya etkisiz hale getirebilirsiniz: "Yakalama sonrası -> Aksiyonları gerçekleştir".** | Note: You can enable/disable actions from "After capture tasks -> Perform actions". | LBL | |
| **Ekle...** | Add... | BTN | Aksiyon penceresi (§8.5.5) |
| **Düzenle...** / **Kopyala** / **Kaldır** | Edit... / Duplicate / Remove | BTN; satır seçilene kadar devre dışı | |
| **Aksiyonlar...** | Actions... | BTN | https://getsharex.com/actions açar |
| (aksiyon listesi) | | Onay kutulu LIST, sürükleyerek sıralanır; sütunlar **İsim** · **Yol** · **Parametreler** · **Uzantılar** | Kayıt defterinde bulunan programlarla kendiliğinden dolar: Paint, Paint.NET, Adobe Photoshop, IrfanView, XnView (yalnızca kurulu olanlar). Kutu aksiyonu etkinleştirir. |

#### 8.2.8 Dizinleri takip et

Bu sayfada B modunda da değiştir kutusu yok.

| Türkçe | English | Tür | Varsayılan |
|---|---|---|---|
| **Dizinleri takip et ve eğer yeni dosya yaratılırsa onu yükle** | Watch folders and if new file created then upload it | CB | ☐ |
| **Ekle...** / **Düzenle...** / **Kaldır** | Add... / Edit... / Remove | 3 × BTN; dizin gözetleme penceresi (§8.5.6) | |
| (klasör listesi) | | LIST, sütunlar **Dizin yolu** · **Süzgeç** · **Alt dizinleri de dahil et** (True/False) | boş |

#### 8.2.9 Gelişmiş

B modunda ilk satır **Gelişmiş ayarları değiştir** (Override advanced settings). Kategorili, yalnızca İngilizce bir özellik ızgarası; kategoriler alfabetik.

| Kategori | Özellik (varsayılan) |
|---|---|
| After upload | ResultForceHTTPS (False) · ClipboardContentFormat ("$result") · BalloonTipContentFormat ("$result") · OpenURLFormat ("$result") · AutoCloseAfterUploadForm (False) |
| Capture | RegionCaptureDisableAnnotation (False) |
| General | ProcessImagesDuringFileUpload (False) · ProcessImagesDuringClipboardUpload (False) · ProcessImagesDuringExtensionUpload (False; tarayıcı uzantısı kaldırıldığı hâlde görünüyor) · UseAfterCaptureTasksDuringFileUpload (True) · TextTaskSaveAsFile (True) · AutoClearClipboard (False) |
| Name pattern | NamePatternMaxLength (100) · NamePatternMaxTitleLength (50) |
| Upload | ImageExtensions (jpg, jpeg, png, gif, bmp, ico, tif, tiff) · TextExtensions (txt, log, nfo, c, cpp, cc, cxx, h, hpp, hxx, cs, vb, html, htm, xhtml, xht, xml, css, js, php, bat, java, lua, py, pl, cfg, ini, dart, go, gohtml) |
| Upload text | TextFileExtension ("txt") · TextCustom ("", çok satırlı düzenleyici) · TextCustomEncodeInput (True) |

Kaldırılan özellikler: EarlyCopyURL, TextFormat, AutoShortenURLLength.

### 8.3 Kısayol ayarları (HotkeySettingsForm + HotkeySelectionControl)

- **Açan:** ana pencere ve tepsi. **Başlık:** "UpLa - Kısayol ayarları" (UpLa - Hotkey settings).
- **Boyut:** iç alan 607×461, en küçük 623×300, ortalı, Segoe UI 9,75.
- **Davranış:** modal; kapanınca HotkeysConfig.json kaydedilir. Esc kapatmaz. Pencere açılınca kaydedilemeyen kısayollar yeniden denenir.

**Üstteki düğmeler** (y=8, yükseklik 27):

| Türkçe | English | Tür | Davranış |
|---|---|---|---|
| **Ekle...** | Add... | BTN 96 | Varsayılan görev ayarlı, görevi "Hiçbiri", tuşu boş bir satır ekler; satırı seçer ve görev menüsünü hemen açar |
| **Düzenle...** | Edit... | BTN; satır seçilene kadar devre dışı | Satır için B modunda Görev ayarları'nı açar |
| **Kaldır** | Remove | BTN | Satırı siler, kısayolun kaydını kaldırır; onay sormaz |
| **Çoğalt** | Duplicate | BTN | Görev ayarlarını (dizin takibi hariç) tuşsuz yeni bir satıra kopyalar |
| **↑** | ↑ | BTN 32; satır seçili ve en az 2 satır varken | Satırı yukarı taşır; ilk satır en alta geçer |
| **↓** | ↓ | BTN 32 | Satırı aşağı taşır; son satır en üste geçer |
| **Sıfırla...** | Reset... | BTN | "Bütün kısayolları varsayılan haline döndür?" (başlık "UpLa"), sonra varsayılan listeyi geri getirir |

**Kısayol listesi.** Dikey bir satır listesi; satırlar tam genişlikte, aralarında 4 px. Her satır 27 px yüksekliğinde bir HotkeySelectionControl:
1. **Görev düğmesi** (MBTN, ≈226 px):
   - Görev simgesi, boşluk, açıklama ya da görev adı.
   - Kısayolun görev ayarları varsayılandan farklıysa sonuna "*".
   - Satır seçiliyken kalın.
   - Tıklamak satırı seçer; ok görev türü menüsünü (§3.3) geçerli görev onaylı olarak açar.
2. **Dişli düğmesi** (27×27, yalnızca simge): satırı seçer ve bu kısayolun Görev ayarları'nı açar.
3. **Kısayol düğmesi** (≈219 px):
   - Durum simgesi ve tuş metni, örn. "Ctrl + Print Screen". Boş kısayol "None".
   - Durum simgeleri: yeşil kayıtlı; kırmızı kaydedilemedi (başka uygulama kullanıyor); sarı yapılandırılmamış.
   - Tıklayınca metin **Kısayol seçiniz...** (Select a hotkey...) olur. Basılı değiştiriciler canlı gösterilir: "Ctrl + Shift + Alt + Win + ...".
   - Geçerli bir tuş düzenlemeyi bitirir. Esc kısayolu boşaltır (None). Win tuşu Win değiştiricisini açıp kapar. Yeniden tıklamak veya düğmeden çıkmak düzenlemeyi bitirir. Print Screen tuş bırakılınca yakalanır. Yalnızca değiştiricilerden oluşan kısayol None olur.
   - Tuş adları İngilizce: "Print Screen", "Page Down", "Numpad 1", "Backspace", "Enter", "Caps Lock", "Scroll Lock", rakamlar "1".
   - Düzenleme sırasında genel kısayollar duraklatılır.

**Alt çubuk.** Yalnızca kısayollar kapalıyken (DisableHotkeys) görünür; tam genişlikte bir düğme: **Kısayol tuşları devre dışı. Buraya tıklıyarak yeniden etkinleştirebilirsiniz.** (Hotkeys are disabled. You can click here to enable them.) Tıklamak kısayolları açar ve çubuğu gizler.

Kayıt hatası iletisi §7.5'te; varsayılan kısayollar §3.1'de.

### 8.4 Hedef ayarları (UploadersConfigForm + UplaSettingsControl)

- **Başlık:** "UpLa - Hedef ayarları - <UploadersConfig.json'un tam yolu>" (UpLa - Destination settings - …).
- **Boyut:** iç alan 1044×601, en küçük 840×572, ortalı.
- **Davranış:** modsuz, tek örnek; kapanınca UploadersConfig.json kaydedilir.
- **Ağaç** (genişlik 230, simgeli): **Resim yükleyiciler** (Image uploaders; genel ok simgesi) › **upla.com.tr** (UpLa uygulama simgesi; her dilde aynı). Üst düğümü seçmek çocuğa atlar, yani pencere her zaman upla.com.tr sayfasında açılır.
- Kaldırılanlar (f9e516e86, ab03cc772): ShareX 21'in diğer bütün hedef sayfaları ("Yazı yükleyiciler", "Dosya yükleyiciler", "Adres kısaltıcılar" dahil).
- Eski Chevereto alanları ("Yükleme adresi:", "API anahtarı:", "Direkt adres", "Örnek: http://example.com/api/1/upload") tasarımda duruyor; çalışırken temizlenip UpLa paneliyle değiştirilir.

#### 8.4.1 upla.com.tr sayfası

Kodla kurulan, 6 px iç boşluklu, kaydırılabilir bir panel. İki sütunlu ızgara: otomatik genişlikte etiket sütunu ve kalan alanı dolduran denetim sütunu. Sarılan metinlerin en büyük genişliği 520 px. Misafir durumunun koyu temadaki görüntüsü `docs/screenshots/upla-settings.png`.

| Satır | Sol etiket | Sağ taraf | Tür | Varsayılan |
|---|---|---|---|---|
| 1 | **upla.com.tr hesabı:** (upla.com.tr account:) | Hesap durumu metni (§8.4.2) | LBL (sarılır) | misafir metni |
| 2 | — | Sarılan bir satır: [**Giriş yap...** (Sign in...)] veya [**Tekrar giriş yap...** (Sign in again...)] · [**Çıkış yap** (Sign out)] · **Profilim** (My profile) · **Bağlı cihazlar** (Connected devices) · **Hesap oluştur** (Sign up) · **Misafir olarak devam et** (Continue as a guest) | BTN, BTN, LINK ×4; görünürlük duruma göre | |
| 3 | — | **API anahtarını elle gir (gelişmiş)** (Enter an API key by hand (advanced)) | LINK; 4–7. satırları açıp kapar | |
| 4 | **API anahtarı:** (API key:) | anahtar kutusu | TXT, gizli karakterler | "" |
| 5 | — | [**Göster** (Show)] · [**Doğrula** (Verify)] · **Anahtar al** (Get key) | CB + BTN + LINK | Göster ☐ |
| 6 | — | anahtar durum satırı | LBL | **Misafir yükleme: dosyalar bir hesaba bağlanmaz.** |
| 7 | — | **Yalnızca uygulamadan giriş yapamıyorsanız gerekir. Anahtarı "Bağlı cihazlar" sayfasındaki "Yeni API anahtarı oluştur" düğmesiyle alın. Ayarlar › API sayfasındaki "Regen key" en yeni anahtarı siler; bu, giriş yaptığınız başka bir bilgisayarın bağlantısı olabilir.** | LBL | |
| 8 | **Kopyalanacak link:** (Link to copy:) | **Sayfa linki (önerilen)** · **Doğrudan dosya linki** · **Kısa link** | DD 260 | Sayfa linki |
| 9 | **Albüm (link veya kimlik):** (Album (link or ID):) | albüm kutusu | TXT | "" |
| 10 | — | **Örnek: https://upla.com.tr/album/Tatil.AbCd (albüm sizin hesabınıza ait olmalıdır)** | LBL | |
| 11 | **Etiketler (virgülle ayırın):** (Tags (comma separated):) | etiket kutusu | TXT | "" |
| 12 | **Kategori kimliği (0 = yok):** (Category ID (0 = none):) | sayı | NUM 0–1.000.000, genişlik 100 | 0 |
| 13 | **Otomatik silme:** (Auto delete:) | **Kapalı** ve 23 süre (§13.6) | DD 160 | Kapalı |
| 14 | **Sunucuda en fazla genişlik (px, 0 = kapalı):** (Max width on server (px, 0 = off):) | sayı | NUM 0–20000, adım 100, genişlik 100 | 0 |
| 15 | — | **Albüm ve etiketler yalnızca giriş yaptığınızda çalışır. Otomatik silme, upla.com.tr'de etkinse uygulanır.** | LBL | |
| 16 | — | **Ekran kayıtları (MP4, WEBM) da upla.com.tr'ye yüklenir. Sınır misafirlerde 20 MB, giriş yapan üyelerde 100 MB.** | LBL | |
| 17 | — | **Yüklenecek ekran kayıtlarını yükleme sınırına gelince durdur** (Stop screen recordings that will be uploaded at the upload limit) | CB | ✓ |
| 18 | — | **API belgesi** (API documentation) | LINK → https://upla.com.tr/api-v1 | |

**Seçeneklerin etkisi:**
- **Kopyalanacak link:** görevin sonucu olacak linki seçer (panoya kopyalanır, geçmişte görünür): sayfa linki `url_viewer`, doğrudan dosya linki `url`, kısa link `url_short`. Seçilen link yoksa (örn. yükleme onay bekliyorsa) sayfa linki kullanılır.
- **Albüm:** link (`…/album/Ad.Kimlik`; `?` ve `#` yok sayılır) veya kimlik kabul eder; `album_id` olarak gönderilir, yalnızca üyelerde.
- **Etiketler:** `tags` olarak gönderilir, yalnızca üyelerde. Her etiket 32 karaktere kısaltılır, "/" ve "#" çıkarılır, tekrarlar atılır.
- **Kategori kimliği:** 0'dan büyükse `category_id`.
- **Otomatik silme:** `expiration`.
- **En fazla genişlik:** yalnızca bu değerden geniş resimlerde `width`; videolarda asla.
- **Sınırda durdurma kutusu:** misafir yaklaşık 18 MiB'ta (sınır 20 MiB), üye yaklaşık 95.000.000 baytta (sınır 100 MB) durur.
- 2.0.1'de kaldırıldı: **Hassas içerik (NSFW) olarak işaretle** (1b73e688f); eski ayar dosyalarındaki değer yok sayılır. **Kötüye kullanımı bildir** bu sayfada değil, yalnızca hesap menülerinde.
- UpLa 1.0'dan geçiş: kişisel bir Chevereto anahtarı (`chv_…`, misafir anahtarı dışında) "elle girilmiş anahtar" olur; eski "Direkt adres" ayarı "Doğrudan dosya linki"ne çevrilir.

#### 8.4.2 Hesap durumları (UpdateAccountUI)

*anahtar* = boşlukları atılmış PersonalAPIKey, *kullanıcı* = AccountUsername, *süresi dolmuş* = sunucu anahtarı reddedince konan, kaydedilmeyen işaret.

| Durum | Koşul | 1. satır metni | 2. satırda görünenler | Elle anahtar linki / 4–7. satırlar |
|---|---|---|---|---|
| Misafir | anahtar yok, kullanıcı yok | **Misafir olarak yüklüyorsunuz; dosyalar bir hesaba bağlanmaz. Hesabınızla yüklemek için giriş yapın.** | Giriş yap..., Hesap oluştur | Link görünür; satırlar linke tıklanana kadar gizli |
| Giriş yapılmış | anahtar + kullanıcı | **Giriş yapıldı: {0}. Dosyalar hesabınıza yüklenir.** ({0} kullanıcı adı; görünen ad farklıysa "Ad (kullanıcıadı)") | Çıkış yap, Profilim (yalnızca geçerli bir upla.com.tr profil linkiyle), Bağlı cihazlar | Gizli |
| Giriş yapılmış, bağlantı kaldırılmış | anahtar + kullanıcı + süresi dolmuş | **Bu bilgisayarın bağlantısı kaldırılmış (web sitesindeki "Bağlı cihazlar" sayfasından silinmiş olabilir). Tekrar giriş yapın.** | Tekrar giriş yap..., Çıkış yap, Profilim, Bağlı cihazlar | Gizli |
| Oturum okunamadı | anahtar yok ama kullanıcı kayıtlı (ayarlar başka bilgisayardan ya da yedekten gelmiş; anahtar çözülemiyor) | **{0} hesabının oturumu bu bilgisayarda okunamadı (ayarlar başka bir bilgisayardan veya yedekten gelmiş olabilir). Tekrar giriş yapın veya misafir olarak devam edin.** | Tekrar giriş yap..., Bağlı cihazlar, Misafir olarak devam et | Gizli |
| Elle girilmiş anahtar | anahtar var, kullanıcı yok | **Elle girilen API anahtarı kullanılıyor; dosyalar anahtarın sahibi olan hesaba yüklenir.** | Çıkış yap | Link ve satırlar her zaman görünür |

**Eylemler:**
- **Giriş yap... / Tekrar giriş yap...** giriş penceresini (§9.2) bu pencerenin sahipliğinde açar.
- **Çıkış yap:** §9.3.
- **Misafir olarak devam et** hatırlanan hesabı sormadan unutur.
- **Linkler:** Profilim → profil adresi (yalnızca upla.com.tr'deki http/https linkleri); Bağlı cihazlar ve Anahtar al → https://upla.com.tr/upla-app/devices; Hesap oluştur → https://upla.com.tr/signup.
- **Anahtar kutusu:** boşluk ve denetim karakterleri atılır. Bir anahtar yazmak uygulama oturumunun yerini alır (kullanıcı adı, ad ve adres silinir; durum "elle girilmiş anahtar" olur). **Göster** maskeyi açıp kapar.
- **Doğrula:** durum satırı önce **Doğrulanıyor...**, sonra:
  - anahtarla: **Anahtar geçerli; dosyalar hesabınıza yüklenecek.** · **Anahtar geçersiz. Uygulamadan giriş yapın veya "Bağlı cihazlar" sayfasından yeni bir anahtar oluşturun.** · **Bu anahtar eski formatta ve artık desteklenmiyor. Uygulamadan giriş yapın veya "Bağlı cihazlar" sayfasından yeni bir anahtar oluşturun.** · **Anahtar geçerli ancak bu hesabın yükleme izni yok.**
  - kutu boşken misafir anahtarı denenir: **Misafir yükleme kullanılabilir.** veya **Misafir yükleme şu anda kapalı. Hesabınızla giriş yapın.**
  - hata: **Anahtar doğrulanamadı: {0}**
- **Boştaki durum satırı:** kutu boşsa **Misafir yükleme: dosyalar bir hesaba bağlanmaz.**; değilse **Dosyalar bu anahtarın sahibi olan hesaba yüklenir.**
- **Açılışta:** giriş yapılmışsa hesap sunucudan yenilenir (`POST /upla-app/me`); geçersiz anahtar "bağlantı kaldırılmış" durumuna geçirir.
- **Canlı güncelleme:** hesap başka bir yerden (örn. ana penceredeki hesap menüsü) değişince sayfa yenilenir.

### 8.5 Bu pencerelerin açtığı alt pencereler

#### 8.5.1 Hızlı görev menüsü düzenleyici

- **Başlık:** "UpLa - Hızlı görev menüsü düzenleyici" (UpLa - Quick task menu editor); 464×432.
- **Liste:** ızgara çizgili, başlıksız LIST; sürükleyerek sıralanır; çift tık düzenler.
- **İpucu:** **İpucu: Eğer boş bir görev yaratırsanız menüde ayraç çizgisi olarak gözükecektir.**
- **Düğmeler:** **Ekle**, **Düzenle**, **Kaldır**, **Kapat**, **Varsayılan ayarlara dön...** ("Bütün hızlı görevleri varsayılan haline döndür?" diye sorar).
- Varsayılan öğeler §4.6'da (İngilizce adlar).

#### 8.5.2 Hızlı görev menüsü öğesini düzenle

- **Başlık:** "UpLa - Hızlı görev menüsü öğesini düzenle"; 440×192.
- **Alanlar:** **Menü yazısı:** TXT (yer tutucusu üretilen ad); **Yakalama sonrası görevleri:** MBTN (§13.9); **Yükleme sonrası görevleri:** MBTN (§13.10); **Tamam**.
- §12.1'deki hata burada da var.

#### 8.5.3 Pano içerik biçimi

- **Başlık:** "UpLa - Pano içerik biçimi"; 417×168.
- **Alanlar:** **Açıklama:** TXT; **Biçim:** TXT, bütün dosya adı değişkenlerinin menüsüyle.
- **İpucu:** **Desteklenen değişkenler: $result, $url, $shorturl, $thumbnailurl, $deletionurl, $filepath, $filename, $filenamenoext, $thumbnailfilename, $thumbnailfilenamenoext, $folderpath, $foldername, $uploadtime ve %y, %mo, %d gibi diğer değişkenler vs.**
- **Düğmeler:** **Tamam** / **İptal**.

#### 8.5.4 Yazıcı ayarları

- **Başlık:** "UpLa - Yazıcı ayarları"; 248×222.
- **Alanlar:** **Kenar boşluğu:** NUM 0–1000 (5); **Resimi otomatik döndür** ✓; **Resimi otomatik boyutlandır** ✓; içeride **Resimin büyümesine izin ver** ☐ ve **Resimi ortala** ☐.
- **Düğmeler:** **Ön izleme...**, **Yazdır...**, **İptal**.

#### 8.5.5 Aksiyonlar (aksiyon düzenleyici)

- **Başlık:** "UpLa - Aksiyonlar"; 313×337.
- **Alanlar:** **İsim:** TXT; **Dosya yolu:** TXT + "..." BTN; **Parametreler:** TXT; **Çıkış dosya adı uzantısı: (Boş = Aynı dosya uzantısını kullan)** TXT; **Uzantı süzgeçi: (Örnek: jpg png mp4)** TXT; **Gizli pencere** CB; **Girdi dosyasını sil** CB (yalnızca çıkış uzantısı varken etkin).
- **Düğmeler:** **Tamam** / **İptal**.

#### 8.5.6 Dizin gözetle

- **Başlık:** "UpLa - Dizin gözetle"; 324×208.
- **Alanlar:** **Dizin yolu:** TXT + "..." BTN; **Süzgeç:** TXT, altında **Örnek: *.png**; **Alt dizinleri de içer** CB; **Dosyayı ekran görüntüleri klasörüne taşı** CB.
- **Düğmeler:** **Tamam** / **İptal**.

Ekran kayıt ayarları penceresi §6.4'te, resim efektleri penceresi §5.7'de.

---

## 9. Hesap ve giriş penceresi

Kaynak: `ShareX.UploadersLib/Upla/UplaSignInForm.cs`, `UplaAccountMenu.cs`, `Upla.cs`, `UplaStrings.cs`.

### 9.1 Hesabın göründüğü yerler

- Ana penceredeki hesap düğmesi: §1.10.
- Tepsi menüsündeki **upla.com.tr hesabı** ▸: §2.2 madde 15 (aynı öğeler, uzun başlık).
- Hedef ayarları › upla.com.tr sayfası: §8.4.

### 9.2 Giriş penceresi: "upla.com.tr'ye giriş yap" (UplaSignInForm)

- **Açan:** hesap menüsündeki **Giriş yap...** / **Tekrar giriş yap...** ve Hedef ayarları sayfası.
- **Pencere:** başlık **upla.com.tr'ye giriş yap** (Sign in to upla.com.tr). Sabit iletişim kutusu: küçültme/büyütme yok, görev çubuğunda görünür, ortalı, içeriğe göre boyutlanır, 10 px iç boşluk, uygulama simgesi.
- **İçeriği ekran görüntülerinden ve kayıtlardan gizlenir** (UpLa dahil her uygulama için).
- Enter = **Giriş yap**. Esc, **İptal** ve X düğmesi iptal eder; süren bir isteği de yarıda keser.

| Satır | Türkçe | English | Tür |
|---|---|---|---|
| 1 | **Kullanıcı adı veya e-posta:** | Username or email: | TXT 260; son kullanıcı adıyla dolu gelir |
| 2 | **Şifre:** | Password: | TXT 260, gizli karakterler |
| 3 | **Doğrulama kodu:** | Verification code: | TXT 120, en çok 10 karakter. Sunucu iki adımlı doğrulama isteyene kadar gizli; yalnızca rakamlar gönderilir |
| 4 | Bilgi/durum metni (iki sütuna yayılır, en çok 380 px). Başta: **Şifreniz yalnızca upla.com.tr'ye gönderilir ve bu bilgisayarda saklanmaz. Hesabınızda bu bilgisayar için ayrı bir bağlantı oluşturulur; upla.com.tr/upla-app/devices adresindeki "Bağlı cihazlar" sayfasından kaldırabilirsiniz. Şifrenizi değiştirmek bu bağlantıyı kaldırmaz.** | Your password is only sent to upla.com.tr and is not stored on this computer. A separate connection is created in your account for this computer; you can remove it on the "Connected devices" page at upla.com.tr/upla-app/devices. Changing your password does not remove it. | LBL |
| 5 | **Şifremi unuttum** · **Hesap oluştur** · **Bağlı cihazlar** | Forgot password · Sign up · Connected devices | LINK ×3 → /account/password-forgot, /signup, /upla-app/devices |
| 6 | [**Giriş yap**] [**İptal**], sağa yaslı, İptal en sağda | Sign in · Cancel | BTN ×2 |

- **Odak:** kullanıcı adı doluysa şifre kutusu, değilse kullanıcı adı kutusu.
- **Akış:**
  1. Boş alan varsa: **Kullanıcı adınızı veya e-postanızı ve şifrenizi girin.**
  2. Değilse durum **Giriş yapılıyor...** olur; alanlar ve "Giriş yap" devre dışı kalır, bekleme imleci çıkar. "İptal" etkin kalır.
  3. `POST https://upla.com.tr/upla-app/login`; alanlar login-subject, password, device ve varsa two-factor-code. `X-Upla-App: 1` başlığı gönderilir. Zaman aşımı 30 sn.
  4. Cihaz adı "<bilgisayar adı> (<kurulum kimliğinin ilk 8 karakteri>)".

| Sonuç | İleti ve tepki |
|---|---|
| Başarılı | Anahtarı (DPAPI ile şifreli) kullanıcı adı, ad ve profil adresiyle kaydeder, pencereyi kapatır, menüleri ve panelleri yeniler |
| two_factor_required | Kod alanını gösterir: **Hesabınızda iki adımlı doğrulama açık. Kimlik doğrulama uygulamanızdaki 6 haneli kodu girin.** |
| invalid_credentials / missing_fields | **Kullanıcı adı/e-posta veya şifre hatalı. Hesabınızı bir sosyal ağ ile açtıysanız önce web sitesinde şifre oluşturun.** Şifreyi ve kodu temizler, kod alanını gizler |
| invalid_two_factor_code | **Doğrulama kodu hatalı.** Kodu seçer |
| too_many_attempts veya HTTP 429 | Bekleme ≥ 1 saat: **Çok fazla hatalı deneme yapıldı. Bir saat sonra tekrar deneyin veya web sitesinden giriş yapın.** · ≥ 1 gün: **…24 saat sonra…** · aksi hâlde: **upla.com.tr'ye çok fazla istek gönderildi. Biraz bekleyip tekrar deneyin.** |
| HTML 403 | **upla.com.tr bu bilgisayardan gelen istekleri geçici olarak engelledi (çok fazla hatalı deneme olabilir). Daha sonra tekrar deneyin.** |
| account_banned | **Bu hesap engellenmiş.** |
| account_awaiting_confirmation | **Hesabınız henüz onaylanmamış. E-postanıza gönderilen onay linkine tıklayın.** |
| account_awaiting_email | **Hesabınızın bir e-posta adresine ihtiyacı var. upla.com.tr'de giriş yapıp e-posta adresinizi ekleyin.** |
| account_not_valid | **Bu hesapla giriş yapılamıyor.** |
| invalid_key | **Bu bilgisayarın bağlantısı kaldırılmış (…). Tekrar giriş yapın.** |
| api_disabled | **upla.com.tr üye yüklemelerini şu anda kabul etmiyor.** |
| 404 / 405 (rota yok) | **upla.com.tr henüz uygulamadan girişi desteklemiyor. Gelişmiş seçenekten, upla.com.tr › Ayarlar › API sayfasından aldığınız anahtarı elle girebilirsiniz.** |
| HTML 2xx | **upla.com.tr giriş isteğine beklenmeyen bir sayfayla yanıt verdi (site bakımda olabilir). Daha sonra tekrar deneyin.** |
| HTTP 5xx | **upla.com.tr şu anda yanıt vermiyor (HTTP {0}). Lütfen daha sonra tekrar deneyin.** |
| Ağ hatası | **upla.com.tr'ye bağlanılamadı. İnternet bağlantınızı kontrol edin.** |
| Diğer | **Giriş yapılamadı: {0}** veya **upla.com.tr'den beklenmeyen bir yanıt alındı.** |

### 9.3 Çıkış yap

1. Soru simgeli Evet/Hayır, başlık **upla.com.tr hesabı**:
   - Giriş yapılmışsa: **upla.com.tr hesabınızdan çıkış yapılsın mı? Bu bilgisayarın bağlantısı sunucudan da silinir; sonraki yüklemeler misafir olarak yapılır.**
   - Elle girilmiş anahtarda: **Elle girilen API anahtarı bu bilgisayardan kaldırılsın mı? Sonraki yüklemeler misafir olarak yapılır.**
2. Hesap yerelde silinir; uygulama girişinde sunucudaki anahtar da silinir (`POST /upla-app/logout`).
3. Sunucuda silme başarısız olursa uyarı simgeli Evet/Hayır: **Bu bilgisayarda çıkış yapıldı ancak bağlantısı upla.com.tr'den kaldırılamadı ({0}). Kaldırılana kadar bu bağlantı hesabınıza yükleme yapabilir. "Bağlı cihazlar" sayfası açılsın mı?** Evet /upla-app/devices'ı (site uygulama girişini desteklemiyorsa /settings/api'yi) açar.

---

## 10. Geçmiş pencereleri

Kaynak: `ShareX.HistoryLib/Forms/HistoryForm.*`, `ImageHistoryForm.*`, `HistorySettingsForm.*`, `ImageHistorySettingsForm.*`, `HistoryImportForm.*`, `HistoryItemManager*.cs`, `HistoryLib Properties/Resources.tr.resx`; açan kod `TaskHelpers.OpenHistory/OpenImageHistory`. Geçmiş `<kişisel dizin>\History.json` dosyasındadır.

### 10.1 Geçmiş penceresi: "UpLa - Geçmiş"

- **Pencere:** iç alan 1184×661, modsuz. Başlık sayılarla güncellenir: "UpLa - Geçmiş (Toplam: {0} - Filtrelenmiş: {0} - <tür>: <sayı> …)". "Filtrelenmiş" yalnızca filtre varsa, türler en kalabalıktan aza.
- **Araç çubuğu:** **Ara:** (Search:) + arama kutusu (yer tutucu **Dosya ismi, pencere başlığı, işlem ismi vs.**) · **Ara** (Search) · **Gelişmiş arama...** (Advanced search...) · — · **Sık kullanılanlar** (Favorites; açıp kapanan düğme) · **İstatistikleri göster...** (Show stats...) · — · **Klasörü içe aktar...** (Import folder...) · **Ayarlar...** (Settings...).
- **Gelişmiş arama** paneli (**Gelişmiş arama** grubu): **Adres:** TXT · **Dosya adı:** TXT · **Sunucu:** CB + DD · **Dosya türü filtresi:** CB + DD · **Tarih:** CB + **Tarihten:** / **Tarihe:** tarih seçicileri · **Sıfırla** · **Kapat**.
- **Liste:** sütunlar tür simgesi (resim, metin, dosya, adres, yıldız), **Tarih** (Date), **Dosya adı** (Filename), **Adres** (URL). Sağda bir ayırıcının arkasında (550 px, hatırlanır) seçili resmin önizlemesi.
- **Fare ve klavye:** çift tık adresi (yoksa dosyayı) açar. F5 yeniler. Enter, Ctrl+Enter, Shift+Enter, Ctrl+C, Shift+C, Alt+C, Ctrl+Shift+C, Del, Shift+Del, Ctrl+U, Ctrl+E, Ctrl+P görev listesindekiyle aynı işi yapar (§1.14.6); Del öğeyi, Shift+Del dosyayı ve öğeyi siler.
- **İstatistikleri göster...:** "Geçmiş istatistikleri" (History stats) metin kutusu: **Toplam:**, **Geçmiş girdi sayıları:**, **Yıllık kullanım:**, **Dosya uzantıları:**, **Sunucular:**, **İşlem isimleri:**.

**Sağ tık menüsü** (`HistoryItemManager`):

| # | Türkçe (uygulamanın gösterdiği) | English | Not |
|---|---|---|---|
| 1 | **Aç** ▸ | Open | **Adres**, **Kısaltılmış adres**, **Küçük resim adresi**, **Silme adresi** (UpLa onay sorusuyla), —, **Dosya**, **Dizin** |
| 2 | **Kopyala** ▸ | Copy | **Adres**, **Kısaltılmış adres**, **Küçük resim adresi**, **Silme adresi**, —, **Dosya**, **Resim**, **Yazı**, —, **HTML link**, **HTML resim**, **HTML linkli resim**, —, **Forum (BBCode) link**, **Forum (BBCode) resim**, **Forum (BBCode) linkli resim**, —, **Markdown bağlantı**, **Markdown resim**, **Markdown bağlantılı resim**, —, **Dosya yolu**, **Dosya adı**, **Uzantılı dosya adı**, **Dizin**. Birden çok öğe seçiliyse metinlerin sonuna " (N)" eklenir. |
| — | | | |
| 3 | **Favorite** | Favorite | Çevrilmemiş (koddaki "TODO: Translate") |
| 4 | **Edit tag...** | Edit tag... | Çevrilmemiş |
| 5 | **Edit item...** | Edit item... | Çevrilmemiş |
| 6 | **Rename file...** | Rename file... | Çevrilmemiş |
| 7 | **Delete item...** | Delete item... | Çevrilmemiş |
| 8 | **Delete file & item...** | Delete file & item... | Çevrilmemiş |
| — | | | |
| 9 | **Resim önizleme...** | Image preview... | Resim dosyasıysa |
| 10 | **Dosyayı karşıya aktar** | Upload file | Dosya varsa |
| 11 | **Resimi düzenle...** | Edit image... | Resim dosyasıysa |
| 12 | **Ekrana sabitle** | Pin to screen | Resim dosyasıysa |

"Görüntüyü analiz et..." UpLa'da gizli (eylem verilmediği için). Bu menünün Türkçe metinleri görev listesindekinden biraz farklıdır ("HTML link" / "HTML bağlantı", "Uzantılı dosya adı" / "Dosya adı uzantısıyla birlikte").

### 10.2 Resim geçmişi penceresi: "UpLa - Resim geçmişi"

- **Pencere:** iç alan 994×661, modsuz. Başlık "UpLa - Resim geçmişi (Toplam: N - Filtrelenmiş: M)".
- **Araç çubuğu:** **Arama:** (Search:) + kutu · **Ara** · — · **Sık kullanılanlar** · **İstatistikleri göster...** · **Klasörü içe aktar...** · — · **Ayarlar...**.
- **Izgara:** küçük resimler (varsayılan 250×150); en çok 500 öğe yüklenir, aşağı kaydırınca daha fazlası yüklenir.
- **Fare ve klavye:** çift tık bütün filtrelenmiş resimlerle resim görüntüleyiciyi o resimden açar. F5 yeniler. Sağ tık ve kısayollar §10.1'deki gibi.

### 10.3 Geçmişin alt pencereleri

| Pencere | Öğeler |
|---|---|
| "UpLa - Geçmiş ayarları" (History settings) | **Arama girdisini hatırla** (Remember search input) ☐ · **Pencere durumunu hatırla** (Remember window state) ✓ |
| "UpLa - Resim geçmişi ayarları" (Image history settings) | **Küçük resim boyutu:** G px × Y px (250 × 150) · **Maksimum resim limiti:** (500) · **Arama girdisini hatırla** ☐ · **Eksik dosyaları filtrele** (Filter missing files) ☐ · **Pencere durumunu hatırla** ✓ · **Yalnızca görüntü dosyalarını göster** (Only show image files) ✓ · **Daha fazla görüntüyü otomatik yükle** (Automatically load more images) ✓ |
| "UpLa - Klasörü içe aktar" (Import folder) | **Klasör yolu:** + **Gözat...** · **Yalnızca görüntü dosyalarını içe aktar** (Only import image files) · **Yinelenen dosyaları atla** (Skip duplicate files) · **İçe aktar** (Import) |

---

## 11. Açılış, ilk çalıştırma ve kapanış

1. **Tek örnek.** UpLa argümansız ikinci kez başlatılırsa çalışan ana pencere öne gelir ve tepsi simgesi yenilenir. Dosya argümanlarıyla (Gönder menüsü, Gezgin'de "UpLa ile yükle") çalışan kopya dosyaları yükler.
2. **Açılış:**
   - Ayarlar `Belgeler\UpLa`'dan (taşınabilir sürümde `<exe klasörü>\UpLa`) okunur.
   - Dil "Otomatik": Windows'un dili kullanılır (Türkçe Windows'ta Türkçe).
   - Normal açılışta ana pencere **gösterilir, ortalanır ve öne getirilir**; kurulumun sonundaki çalıştırma da buna dahil.
   - Pencere şu durumların hepsinde **gizli kalır, yalnızca tepsi simgesi görünür:** açılış sessizdir (`-silent` argümanı, ki kurulumdaki varsayılan işaretli "Run UpLa when Windows starts" kısayolu bunu kullanır; Store StartupTask; Windows güncellemesinden sonraki yeniden başlatma; `SilentRun` ayarı) **ve** tepsi simgesi açıktır (`ShowTray` ✓).
   - **Hoş geldin veya ilk çalıştırma penceresi yok.**
   - Kısayollar kaydedilir; biri kaydedilemezse §7.5'teki uyarı.
   - Son 10 görev geri yüklenir (§1.14.4).
   - Kurulum ve taşınabilir sürümler GitHub'daki Agnostique/UpLa'yı günde en çok bir kez güncelleme için denetler.
   - Aksiyonlar araç çubuğu açılmaz (`ActionsToolbarRunAtStartup` ☐).
3. **İlk yükleme (UpLa):** her türlü yüklemenin ilkinden önce "upla.com.tr'ye otomatik yükleme" sorusu (§7.5). Bir kez sorulur (`ShowUploadWarning`).
4. **Kapanış:**
   - X düğmesi, Alt+F4 ve Esc, tepsi simgesi açıkken pencereyi **tepsiye gizler** ve ayarları kaydeder.
   - Yalnızca ilk seferde tepside **UpLa sistem tepsisine küçültüldü.** bildirimi (başlık UpLa, 8 sn).
   - Uygulamadan yalnızca tepsideki **Çıkış** ile çıkılır. Ekran kaydı sürüyorsa önce sorar (§7.5); **Evet** kaydı durdurur ama uygulamadan **çıkmaz**.
   - Tepsi simgesi kapalıysa X uygulamadan çıkar.
5. **Yükleme sırasında** başlık, görev çubuğu düğmesi ve tepsi simgesi ilerlemeyi gösterir.

---

## 12. Windows'taki hatalar ve tuhaflıklar (Mac'e kopyalanmamalı)

### 12.1 Yakalama sonrası ve Yükleme sonrası onay işaretleri kayık (UpLa'nın getirdiği hata)

**2.0.3'te düzeltildi** (`1ce7e55ff`): üç yerde de her menü öğesi kendi görev değerini `Tag`'inde taşır; onay işareti `HasFlag(öğenin değeri)` ile kurulur ve tıklama o değeri değiştirir. `windows-ref/` görüntülerindeki onaylar artık gerçek ayarları gösterir. Aşağıdaki açıklama 2.0.2'deki durumdur.

- `MainForm.SetMultiEnumChecked` (`MainForm.cs` 589–599) *i*. menü öğesini `HasFlag(1 << i)` ile işaretler. Bu yalnızca enum bitlerinde boşluk yoksa doğru çalışır.
- UpLa `AfterCaptureTasks`'tan `SaveThumbnailImageToFile` (bit 10) ve `AnalyzeImage` (bit 16), `AfterUploadTasks`'tan `UseURLShortener` (bit 1) üyelerini sildi ama diğerlerinin bit değerlerini korudu (`Enums.cs` 128–162). Bitlerde boşluk oluştu.
- **Ana pencere ve tepsi menülerinde** her açılışta:
  - Yakalama sonrası 11–20. öğeler bir önceki bitin durumunu gösterir. **"Resimi yükle", yükleme açık olduğu hâlde onaysız görünür** (DoOCR'nin durumunu gösterir); "Aksiyonları gerçekleştir" ve "Yazı tanı (OCR)" hep onaysız görünür.
  - Yükleme sonrası'nda "Adresi panoya kopyala" yerine **"Adresi aç" onaylı** görünür; "Adresi paylaş" hiç onaylı görünmez.
  - Tıklamak doğru ayarı değiştirir (öğenin kendi enum değeriyle), ama yanlış onay işareti tersine döner; işaret ile gerçek ayar ters yönlere gider.
- **Görev ayarları'ndaki kısayola özel menülerde ve Hızlı görev öğesi düzenleyicisinde** (`TaskSettingsForm.cs` 593–634, `QuickTaskInfoEditForm.cs` 51–92) tıklama da `1 << index` kullanır, yani **yanlış görevi değiştirir**: "Resimi yükle" OCR'yi, "Dosyayı sil" Yükleme öncesi penceresini açar; "Adresi panoya kopyala" Adresi paylaş'ı, "Adresi aç" Adresi panoya kopyala'yı değiştirir. Düğme metni gerçek bitlerden kurulduğu için bu kez yanlış görevleri listeler.
- "Yakalama sonrası" penceresi (§4.3) öğe etiketlerini kullandığından etkilenmez.
- **Mac'te:** her menü öğesi kendi enum değerine bağlanmalı. Windows'ta üç yer de düzeltilmeli (`1 << i` yerine öğenin değeri).

### 12.2 UpLa'da her zaman gri olan öğeler

Aç ▸ / Kopyala ▸'daki **Kısaltılmış adres**, **Küçük resim dosya** ve **Küçük resim**: UpLa'da adres kısaltıcı yok ve küçük resim dosyası kaydedilmiyor.

### 12.3 Görev ayarları'ndan sonra onay işaretleri yenilenmiyor

Ana pencere Yakalama sonrası, Yükleme sonrası ve hedef onaylarını yalnızca açılışta ve ilk yükleme sorusundaki "Hayır"dan sonra yeniden hesaplar. Görev ayarları'nda yapılan değişiklikler yeniden başlatana kadar bu menülere yansımaz (ShareX'ten gelen davranış).

### 12.4 Kütüğü karşıya yükleme her zaman başarısız

Hata ayıklama › **Kütüğü karşıya yükle...** metin yükler; upla.com.tr metni kabul etmediği için hep "desteklenmeyen tür" hatasıyla biter.

### 12.5 Diğer tuhaflıklar

- **Shift+Del** dosyaları sormadan siler; menüdeki **Yerel dosya sil...** önce sorar.
- **Yükleyici filtreleri:** açılır listede iki aynı "upla.com.tr" öğesi var; liste iç kimliği "Chevereto" gösterir.
- **Yükleme öncesi penceresi:** resimlerde iki aynı "upla.com.tr" radyo düğmesi.
- **Tema › Dışa aktar › Metin olarak yükle:** JSON metnini upla.com.tr'ye gönderir, reddedilir.
- **Uygulama ayarları › Yükleme › İkincil yükleyiciler:** tek hedef olduğundan anlamsız.
- **Görev ayarları › Gelişmiş › ProcessImagesDuringExtensionUpload:** tarayıcı uzantısı kaldırıldığı hâlde görünür.
- **İlk yükleme sorusu** "Yakalama sonrası görevler" menüsünden söz eder; menünün adı "Yakalama sonrası".
- **"Yükleme sonrası" penceresi** yalnızca tost da gösteriliyorsa açılır.
- **Çevrilmemiş metinler:** küçük resim tıklamasındaki "Would you like to open this file?"; geçmiş menüsündeki Favorite, Edit tag..., Edit item..., Rename file..., Delete item..., Delete file & item...; Gelişmiş özellik ızgaraları; efekt adları; hızlı görev ön ayar adları; Yükleme sonrası penceresindeki biçim adları.

---

## 13. Değer listeleri

### 13.1 Dosya adı değişkenleri (% öneki)

Kategori alt menüleri bu sırayla görünür; bütün öğeleri hariç tutulan kategori gösterilmez. Menünün sonunda ayırıcı ve **Kapat**.

| Kategori | Kod | Türkçe | English |
|---|---|---|---|
| **Pencere** (Window) | %t | Pencerenin başlığı | Title of window |
| | %pn | Pencerenin işlem ismi | Process name of window |
| **Tarih ve zaman** (Date and time) | %y | Güncel yıl | Year |
| | %yy | Güncel yıl (2 hane) | Year (2 digits) |
| | %mo | Güncel ay | Month |
| | %mon | Güncel ay adı (Yerel dil) | Month name (Local language) |
| | %mon2 | Güncel ay adı (İngilizce) | Month name (English) |
| | %w | Güncel hafta adı (Yerel dil) | Week name (Local language) |
| | %w2 | Güncel hafta adı (İngilizce) | Week name (English) |
| | %wy | Yılın haftası | Week of year |
| | %d | Güncel gün | Day |
| | %h | Güncel saat | Hour |
| | %mi | Güncel dakika | Minute |
| | %s | Güncel saniye | Second |
| | %ms | Güncel milisaniye | Millisecond |
| | %pm | AM/PM al | AM/PM |
| | %unix | Unix zaman imzası | Unix timestamp |
| **Artan** (Incremental) | %i | Otomatik artan sayı ({n} başa n kadar 0 ekler) | Auto increment number (0 pad left using {n}) |
| | %ia | Otomatik artan alfanumerik büyük küçük harfe duyarsız ({n} başa n kadar 0 ekler) | Auto increment alphanumeric case-insensitive |
| | %iAa | Otomatik artan alfanumerik büyük küçük harfe duyarlı ({n} başa n kadar 0 ekler) | Auto increment alphanumeric case-sensitive |
| | %ib | Otomatik artan {n} sayı tabanında alfanumerik (1 < n < 63) | Auto increment by base {n} using alphanumeric |
| | %ix | Otomatik artan heksadesimal ({n} başa n kadar 0 ekler) | Auto increment hexadecimal |
| **Rastgele** (Random) | %rn | Rastgele 0 ile 9 arasında sayı ({n} haneli) | Random number 0 to 9 (Repeat using {n}) |
| | %ra | Rastgele alfanumerik karakter ({n} haneli) | Random alphanumeric char (Repeat using {n}) |
| | %rna | Rastgele belirsiz olmayan alfanumerik karakter ({n} haneli) | Random non ambiguous alphanumeric char |
| | %rx | Rastgele heksadesimal karakter ({n} haneli) | Random hexadecimal char |
| | %guid | Rastgele GUID | Random GUID |
| | %radjective | Rastgele sıfat | Random adjective |
| | %ranimal | Rastgele hayvan | Random animal |
| | %remoji | Rastgele emoji ({n} kullanarak tekrarla) | Random emoji (Repeat using {n}) |
| | %rf | Rastgele satır dosyadan (Dosya adresi için {filepath} kullan) | Random line from a file |
| **Resim** (Image) | %width | Resim genişliği | Image width |
| | %height | Resim yüksekliği | Image height |
| **Bilgisayar** (Computer) | %un | Kullanıcı adı | User name |
| | %uln | Kullanıcı giriş adı | User login name |
| | %cn | Bilgisayar adı | Computer name |
| (kategorisiz, en sonda) | %n | Yeni satır | New line |

### 13.2 Piksel bilgisi değişkenleri ($ öneki; yalnızca İngilizce, kategorisiz)

$r255, $g255, $b255 (0-255) · $r1, $g1, $b1 (0-1; {n} ondalık, varsayılan 3) · $hex (küçük harf) · $rhex, $ghex, $bhex (00-ff) · $HEX (büyük harf) · $rHEX, $gHEX, $bHEX (00-FF) · $c100, $m100, $y100, $k100 (0-100) · $name (renk adı) · $x · $y · $n (yeni satır).

### 13.3 Tost konumları ve tıklama eylemleri

- **Konumlar:** Sol üst · Orta üst · Sağ üst · Sol orta · Orta merkez · Sağ orta · Sol alt · Orta alt · **Sağ alt** (varsayılan). (Top left … Bottom right)
- **Tıklama eylemleri:** **Uyarı penceresini kapat** (Close notification) · **Resimi düzenle** (Edit image) · **Resim kopyala** (Copy image) · **Dosya kopyala** (Copy file) · **Dosya yolunu kopyala** (Copy file path) · **Bağlantıyı kopyala** (Copy link) · **Dosya aç** (Open file) · **Klasör aç** (Open folder) · **Bağlantı aç** (Open link) · **Karşıya dosya yükle** (Upload file) · **Ekrana sabitle** (Pin to screen) · **Yerel dosyayı sil** (Delete file locally).

### 13.4 GIF kalitesi

| Türkçe | English |
|---|---|
| Varsayılan .NET işlemesi (Hızlı işleme fakat ortalama kalite) | Default .NET encoding (Fast encoding but average quality) |
| 256 renk (Yavaş işleme fakat daha iyi kalite) | Octree quantizer 256 colors (Slow encoding but better quality) |
| 16 renk (Daha düşük boyut fakat kötü kalite) | Octree quantizer 16 colors |
| 256 gri tonlarda renk | Palette quantizer grayscale 256 colors |

### 13.5 Bölge yakalama fare eylemleri

Hiçbir şey yapma (Do nothing) · Yakalamayı iptal et (Cancel capture) · Nesneyi sil veya yakalamayı iptal et (Remove shape or cancel capture) · Nesneyi sil (Remove shape) · Araç tipini değiştir (Swap tool type) · Tam ekran yakala (Capture fullscreen) · Aktif ekranı yakala (Capture active monitor) · Son bölgeyi yakala (Capture last region).

### 13.6 Otomatik silme süreleri (Hedef ayarları)

**Kapalı** (Never), 5 dakika, 15 dakika, 30 dakika, 1 saat, 3 saat, 6 saat, 12 saat, 1 gün, 2 gün, 3 gün, 4 gün, 5 gün, 6 gün, 1 hafta, 2 hafta, 3 hafta, 1 ay, 2 ay, 3 ay, 4 ay, 5 ay, 6 ay, 1 yıl. Saklanan değerler ISO süreleri: PT5M, PT15M, PT30M, PT1H, PT3H, PT6H, PT12H, P1D … P6D, P1W, P2W, P3W, P1M … P6M, P1Y.

### 13.7 Varsayılan temalar

Adlar çevrilmez. RGB sırası: Background / LightBackground / DarkBackground / Text / Border / Checker / Checker2 / Link / MenuHighlight / MenuHighlightBorder / MenuBorder / MenuCheckBackground / SeparatorLight / SeparatorDark.

| Tema | Renkler |
|---|---|
| **Dark** (varsayılan) | 39,39,39 / 46,46,46 / 34,34,34 / 231,233,234 / 31,31,31 / 46,46,46 / 39,39,39 / 166,212,255 / 46,46,46 / 63,63,63 / 63,63,63 / 51,51,51 / 44,44,44 / 31,31,31 |
| **Light** | 242,242,242 / 247,247,247 / 235,235,235 / 69,69,69 / 201,201,201 / 247,247,247 / 235,235,235 / 166,212,255 / 247,247,247 / 96,143,226 / 201,201,201 / 225,233,244 / 253,253,253 / 189,189,189 |
| **Night** | 42,47,56 / 52,57,65 / 28,32,38 / 235,235,235 / 28,32,38 / 60,60,60 / 50,50,50 / 166,212,255 / 30,34,40 / 116,129,152 / 22,26,31 / 56,64,75 / 56,64,75 / 22,26,31 |
| **Nord Dark** | 46,52,64 / 59,66,82 / 38,44,57 / 229,233,240 / 30,38,54 / 46,52,64 / 36,42,54 / 136,192,208 / 36,42,54 / 24,30,42 / 24,30,42 / 59,66,82 / 59,66,82 / 30,38,54 |
| **Nord Light** | 229,233,240 / 236,239,244 / 216,222,233 / 59,66,82 / 207,216,233 / 229,233,240 / 216,222,233 / 106,162,178 / 236,239,244 / 207,216,233 / 216,222,233 / 229,233,240 / 236,239,244 / 207,216,233 |
| **Dracula** | 40,42,54 / 68,71,90 / 36,38,48 / 248,248,242 / 33,35,43 / 40,42,54 / 36,38,48 / 98,114,164 / 36,38,48 / 255,121,198 / 33,35,43 / 45,47,61 / 45,47,61 / 33,35,43 |

### 13.8 Resim efektleri ("Ekle" menüsü)

Grup adları çevrilmiş, efekt adları İngilizce:
- **Çizimler** (Drawings): Background, Background image, Border, Checkerboard, Image, Particles, Text, Text watermark.
- **İşlemeler** (Manipulations): Auto crop, Canvas, Crop, Flip, Force proportions, Resize, Rotate, Rounded corners, Scale, Skew.
- **Düzenlemeler** (Adjustments): Alpha, Black & white, Brightness, Color matrix, Colorize, Contrast, Gamma, Grayscale, Hue, Inverse, Polaroid, Replace color, Saturation, Selective color, Sepia.
- **Filtreler** (Filters): Blur, Color depth, Convolution matrix, Edge detect, Emboss, Gaussian blur, Glow, Mean removal, Outline, Pixelate, Reflection, RGB split, Shadow, Sharpen, Slice, Smooth, Torn edge, Wave edge.

### 13.9 Yakalama sonrası görevler

§1.6'daki 20 öğe, aynı sırayla (görev ayarlarındaki menü düğmelerinde de aynı liste).

### 13.10 Yükleme sonrası görevler

§1.7'deki 5 öğe, aynı sırayla.

