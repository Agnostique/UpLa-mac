# Windows ile birebir arayüz (parite)

Kullanıcı, Mac uygulamasının Windows'taki UpLa ile aynı menülere, pencerelere ve metinlere sahip olmasını istedi (2026-10-10). Bu klasör o işin belgeleri. Belgeler ve görüntüler Windows'taki Claude Code oturumunda hazırlandı.

| Dosya | İçerik |
| --- | --- |
| [`windows-arayuz-envanteri.md`](windows-arayuz-envanteri.md) | Windows UpLa'nın kullanıcıya görünen her şeyi, uygulamadaki sırasıyla: ana pencere, bütün menüler, tepsi menüsü, kısayollar, görev akışı, araçlar, ekran kaydı, bildirimler, ayar pencereleri, hesap, geçmiş, Windows hataları (§12) ve değer listeleri (§13). Türkçe ve İngilizce metinler harfi harfine. |
| [`mac-parite-plani.md`](mac-parite-plani.md) | Hedef Mac arayüzü (§2), macOS'e uyarlanan yerler (§3), 412 öğelik parite matrisi (§4), beş aşama (§5), yalnızca Windows'ta kalanlar (§6), macOS API eşlemesi (§7), çalışma düzeni (§8) ve kararlar (§9). |
| [`windows-ref/`](windows-ref/) | Windows 2.0.3'ün 53 ekran görüntüsü (Türkçe); dizin aşağıda. |

## Durum

- **Kararlar:** kullanıcı plan §9'daki 22 önerinin hepsini kabul etti (2026-10-10). Kısa özeti aşağıda.
- **Sıra:**
  1. PR #3 (ekran kaydı) MacBook'ta test edilir; kullanıcı onaylarsa birleştirilir.
  2. Aşama 1 (plan §5) güncel `main` üzerinden başlar. İlk PR: metin aktarma betiği, `TaskSettings` / `ApplicationConfig` / `HotkeysConfig` modelleri, `MenuBuilder`.
  3. Her alt adım ayrı dal ve PR (`parity/1-temel`, `parity/1-ana-pencere`, …). Birleştirme kararı her zaman kullanıcının.
- **Windows tarafı:**
  - 2.0.3 onay işareti hatasını düzeltti (envanter §12.1).
  - Yazım hataları ve çevrilmemiş metinler (karar 6) Windows deposunun `main` dalında düzeltildi (`92748c3ad`). Henüz bir sürümde çıkmadı.
  - Metin betiği metinleri `main`'den alır; ayrı bir düzeltme tablosu gerekmez.

## Kararların özeti (ayrıntısı plan §9'da)

1. **Dock simgesi** yalnızca ana pencere açıkken; Uygulama ayarları'nda "Dock'ta simge göster" seçeneği.
2. **Ana pencere** normal açılışta görünür, oturum açılışında (giriş öğesi) gizli kalır.
3. **Menü çubuğu simgesi:** tıklama ayarları Windows'taki gibi; varsayılan sol tık menüyü açar.
4. **Görünüm:** macOS açık / koyu görünümü; Tema sayfasında yalnızca Sistem / Açık / Koyu.
5. **İkonlar:** Windows'taki Fugue ikonları (CC BY 3.0); menü çubuğunda UpLa logosu.
6. **Metinler:** Windows'un yazım hataları kopyalanmaz (iki uygulamada da düzeltilir); çevrilmemiş metinler Türkçe olur (gelişmiş özellik, efekt ve hızlı görev ön ayar adları ile "Yükleme sonrası" penceresindeki biçim adları Windows'ta da İngilizce kalır); "..." yerine "…"; "bu bilgisayar".
7. **Windows'ta işlevsiz öğeler** (hep gri olanlar, ikincil yükleyiciler, yükleyici filtreleri, Metin olarak yükle, Kütüğü karşıya yükle) Mac'te gösterilmez.
8. **Varsayılan kısayollar:** ⌥⇧⌘3 Tüm ekranı yakala, ⌥⇧⌘4 Bölge yakala, ⌥⇧⌘5 Aktif pencereyi yakala, ⌥⇧⌘6 Ekran kaydetme başlat/durdur, ⌥⇧⌘7 Ekran kaydetme (GIF) başlat/durdur (Aşama 4).
9. **Varsayılan görevler ve dosyalar** Windows'taki gibi (Yakalama sonrası: panoya kopyala + kaydet + yükle; ad `%ra{10}`; klasör `Belgeler/UpLa/Screenshots/yyyy-MM`); mevcut kullanıcıların kendi seçtikleri korunur.
10. **Henüz yapılmamış öğeler** yayınlanan sürümde gizli.
11. **Menüler** tıklayınca kapanır (macOS davranışı); gerekirse sonra.
12. **Bildirim:** varsayılan Windows tostu; Görev ayarları › Uyarılar'da Mac'e özgü "macOS bildirimi kullan".
13. **Sesler** varsayılan açık, ShareX'in ses dosyalarıyla.
14. **Araç sırası (Aşama 3):** OCR, QR kod, Ekrana sabitle, Ekrandan renk seçici, Resim görüntüleyici, Resim birleştirici, Resim güzelleştirici, Cetvel, Renk seçici, Resim efektleri.
15. **Resim düzenleyici:** önce temel set (Dikdörtgen, Ok, Yazı, Kademe, Vurgula, Bulanıklaştır, Mozaikle, Resmi kırp, geri al, kaydet, kopyala, yükle).
16. **Hakkında:** Windows düzeni; doğru atıf ("ShareX'in arayüzünü ve metinlerini örnek alır"); yalnızca gerçekten kullanılan bileşenler.
17. **Bölge yakalama:** Aşama 4'te kendi ekranımız varsayılan; macOS seçimi Mac'e özgü seçenek olarak kalır.
18. **Sürüm numarası:** Mac kendi numarasıyla ("UpLa 1.0").
19. **Dağıtım:** Developer ID + notarization.
20. **Windows düzeltmeleri:** onay işareti hatası (2.0.3'te yapıldı) ve metinler (`main`'de yapıldı, sonraki sürümde çıkacak).
21. **Mac'e özgü fazlalar** (menü çubuğu simgesine dosya bırakma, "Geçmişi Temizle…") kalır; "Geçmişi Temizle…" Geçmiş ayarlarına taşınır.
22. **Başlangıç:** önce PR #3, sonra Aşama 1'in ilk PR'ı.

## Ekran görüntüleri (`windows-ref/`)

**Nasıl alındı:** UpLa 2.0.3'ün taşınabilir bir kopyası, temiz profille (varsayılan ayarlar, giriş yapılmamış), Türkçe arayüz ve varsayılan "Dark" tema; Windows 11, %150 ölçek. Görüntüler piksel; WinForms yazı tipine göre de ölçeklediğinden 1,5'e bölmek yalnızca yaklaşık nokta verir. Tasarım ölçüleri envanterde.

- Kişisel klasör yolları maskelendi: 10-04 ve 13'te yol, gerçek kurulumdaki gibi `C:\Users\<kullanıcı>\Documents\UpLa…` diye yazıldı.
- 18–20 için profile örnek bir "son görev" eklendi: çizilmiş bir resim, sahte adres `https://upla.com.tr/i/Ornek`. Hiçbir şey yüklenmedi, ekran yakalanmadı.
- Görüntülerdeki metinler envanterle aynı. Windows'un yazım hataları ("Resimi", "Adresden" …) görüntülerde duruyor; bunlar Windows `main`'de düzeltildi ve Mac'e kopyalanmaz (karar 6).

| Dosya | Ne gösterir | Envanter |
| --- | --- | --- |
| `01-ana-pencere.png` | Ana pencere, boş liste: sol panel ve kısayol tablosu | §1.1, §1.2, §1.14.1 |
| `02-yakala-menusu.png` | Yakala ▸ | §1.3 |
| `02b-yakala-gecikme.png` | Yakala › Ekran görüntüsü gecikmesi ▸ | §1.3 |
| `03-yukle-menusu.png` | Yükle ▸ (ana pencerede 3 öğe) | §1.4 |
| `04-araclar-menusu.png` | Araçlar ▸ | §1.5 |
| `05-yakalama-sonrasi-menusu.png` | Yakalama sonrası ▸, varsayılan onaylar (kalın = seçili) | §1.6 |
| `05b-resim-efekti-ekle.png` | Yakalama sonrası › Resim efekti ekle ▸ (tek ön ayar "Name") | §1.6 |
| `06-yukleme-sonrasi-menusu.png` | Yükleme sonrası ▸ | §1.7 |
| `07-hedefler-menusu.png` | Hedefler ▸ | §1.8 |
| `07b-hedefler-resim-yukleyici.png` | Hedefler › Resim yükleyici ▸ | §1.8 |
| `07c-hedefler-dosya-yukleyici.png` | Hedefler › Resim yükleyici › Dosya yükleyici ▸ | §1.8 |
| `08-giris-yap-menusu.png` | Hesap düğmesi "Giriş yap" ▸ (misafir) | §1.10 |
| `09-hata-ayiklama-menusu.png` | Hata ayıklama ▸ | §1.12 |
| `10-uygulama-ayarlari-01-genel.png` … `-12-gelismis.png` | Uygulama ayarları, ağacın 12 düğümü sırayla: Genel, Tema, Entegrasyon, Yollar, Ayarlar, Ana pencere, Pano biçimleri, Yükleme, Geçmiş, Yazdırma, Vekil Sunucu, Gelişmiş | §8.1 |
| `11-gorev-ayarlari-01-uyarilar.png` … `-14-gelismis.png` | Görev ayarları, 14 sayfa: Uyarılar, Resim, Efekt, Yakalama, Bölge yakala (pencere uzatılarak tamamı), Ekran kaydedici, OCR, Dosya adlandırma, Panodan yükleme, Yükleyici filtreleri, Araçlar, Aksiyon, Dizinleri takip et, Gelişmiş. "Genel" ve "Yükleme" düğümleri ilk çocuklarına atlar, kendi sayfaları yok | §8.2 |
| `12-kisayol-ayarlari.png` | Kısayol ayarları, 5 varsayılan kısayol | §8.3, §3.1 |
| `13-hedef-ayarlari.png` | Hedef ayarları › upla.com.tr (misafir) | §8.4 |
| `14-hakkinda.png` | Hakkında | §1.13 |
| `15-gecmis.png` | Geçmiş (boş) | §10.1 |
| `16-resim-gecmisi.png` | Resim geçmişi (boş) | §10.2 |
| `17-tepsi-menusu.png` | Tepsi menüsü (Mac'te menü çubuğu menüsü) | §2.2 |
| `17b-tepsi-yukle.png` | Tepsi › Yükle ▸ (5 öğe; ana penceredekinden fazlası var) | §2.2, §2.3 |
| `17c-tepsi-is-akislari.png` | Tepsi › İş akışları ▸ (kısayollar) | §2.2 |
| `18-gorev-kucuk-resim.png` | Görev alanı, küçük resim görünümü, bir görevle | §1.14.2 |
| `19-gorev-liste.png` | Görev alanı, liste görünümü, aynı görev ("Geçmiş" durumu) | §1.14.3, §1.14.4 |
| `20-gorev-sag-tik-menusu.png` | Görev sağ tık menüsü (resim dosyası ve adresi olan görev) | §1.15 |
| `20b-gorev-ac.png` | Görev › Aç ▸ | §1.15 |
| `20c-gorev-kopyala.png` | Görev › Kopyala ▸ ("Sayfa linki" varsayılanında resim türevleri gri) | §1.15 |
| `20d-gorev-adresi-paylas.png` | Görev › Adresi paylaş ▸ | §1.15 |

Çekilmeyenler: bölge yakalama ekranı ve resim düzenleyici (tam ekran, yakalama gerektirir), giriş penceresi (sunucuya istek atar), araç pencereleri. Bunlar envanterde metin olarak var (§4.7, §4.8, §5, §9); gerekirse Windows oturumundan istenir.
