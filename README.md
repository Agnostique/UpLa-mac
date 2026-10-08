# UpLa for Mac

**Türkçe:** [upla.com.tr](https://upla.com.tr) için macOS uygulaması. Ekran görüntüsü ve ekran kaydı alır, upla.com.tr'ye yükler ve bağlantıyı panoya kopyalar. Uygulama geliştirme aşamasında; plan için [PLAN.md](PLAN.md) dosyasına bakın. Windows sürümü: https://github.com/Agnostique/UpLa

**English:** The macOS app of [upla.com.tr](https://upla.com.tr). It takes screenshots and screen recordings, uploads them to upla.com.tr and copies the link to the clipboard. The app is in development; see [PLAN.md](PLAN.md). The Windows version is at https://github.com/Agnostique/UpLa

## Mac'te derleme

macOS 14 veya daha yenisi ve Xcode 16 gerekir.

1. XcodeGen'i kurun: `brew install xcodegen`
2. Misafir yükleme anahtarı için `cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig` komutunu çalıştırıp dosyayı doldurun. Bu dosya git'e eklenmez; anahtar olmadan da derlenir, o zaman yüklemek için giriş yapmak gerekir.
3. İsteğe bağlı ama önerilir: `cp Config/Signing.example.xcconfig Config/Signing.xcconfig` komutunu çalıştırıp kendi (Personal) Team kimliğinizi `DEVELOPMENT_TEAM` satırına yazın (Xcode › Settings › Accounts). Böylece Ekran Kaydı izni ve anahtar zinciri erişimi derlemeler arasında korunur. Bu dosya da git'e eklenmez. Team'i yalnızca Xcode'daki Signing & Capabilities bölümünde seçerseniz bir sonraki `xcodegen generate` bu seçimi siler.
4. `xcodegen generate`
5. `open UpLa.xcodeproj`, ardından UpLa şemasını çalıştırın (⌘R).
6. Yerel bir test sitesiyle denemek için (yalnızca Debug derlemeleri): Product › Scheme › Edit Scheme › Run › Arguments bölümünde `UPLA_DEBUG_BASE_URL` değişkenini işaretleyip adresi girin. Yalnızca bu Mac'teki veya yerel ağdaki adresler kabul edilir; test sitesinin girişi gerçek girişten ayrı tutulur.

## CI derlemesini deneme

1. GitHub'da Actions › "Build UpLa for Mac" altında son başarılı çalışmayı açın ve **UpLa-mac** dosyasını indirin.
2. Zip'i açın ve `UpLa.app`'i Uygulamalar klasörüne taşıyın.
3. Uygulama noter onaylı (notarized) değildir. macOS 15 ve sonrası: uygulamayı bir kez açmayı deneyin, ardından Sistem Ayarları › Gizlilik ve Güvenlik bölümünde **Yine de Aç**'ı seçin (macOS 14'te: sağ tıklayıp **Aç**). Ya da Terminal'de `xattr -dr com.apple.quarantine /Applications/UpLa.app` çalıştırın.
4. İstendiğinde Sistem Ayarları › Gizlilik ve Güvenlik › Ekran ve Sistem Sesi Kaydı bölümünde UpLa'ya izin verin, sonra UpLa'yı kapatıp yeniden açın.
5. Her test derlemesi farklı imzalandığı için Ekran Kaydı iznini ve anahtar zinciri erişimini yeniden isteyebilir.

## Build on a Mac

Needs macOS 14 or later and Xcode 16.

1. Install XcodeGen: `brew install xcodegen`
2. For the guest upload key, run `cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig` and fill it in. The file is not added to git; the app also builds without it, and then uploads need a sign-in.
3. Optional but recommended: run `cp Config/Signing.example.xcconfig Config/Signing.xcconfig` and enter your own (Personal) Team ID on the `DEVELOPMENT_TEAM` line (Xcode › Settings › Accounts). macOS then keeps the Screen Recording permission and the keychain access between builds. This file is not added to git either. A team chosen only under Signing & Capabilities in Xcode is reset by the next `xcodegen generate`.
4. `xcodegen generate`
5. `open UpLa.xcodeproj` and run the UpLa scheme (⌘R).
6. To try a local test site (Debug builds only): in Product › Scheme › Edit Scheme › Run › Arguments, tick `UPLA_DEBUG_BASE_URL` and enter its address. Only addresses on this Mac or the local network are accepted, and the test site's sign-in is kept apart from the real one.

## Try a CI build

1. On GitHub, open the latest successful run under Actions › "Build UpLa for Mac" and download the **UpLa-mac** artifact.
2. Unzip it and move `UpLa.app` to the Applications folder.
3. The app is not notarized. macOS 15 and later: try to open it once, then choose **Open Anyway** in System Settings › Privacy & Security (macOS 14: right-click it and choose **Open**). Or run `xattr -dr com.apple.quarantine /Applications/UpLa.app` in Terminal.
4. When asked, allow UpLa in System Settings › Privacy & Security › Screen & System Audio Recording, then quit and reopen UpLa.
5. Each test build is signed differently, so it may ask again for the Screen Recording permission and for keychain access.

License: GNU General Public License v3, see [LICENSE](LICENSE).
