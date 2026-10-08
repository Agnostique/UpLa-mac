# UpLa for Mac

**Türkçe:** [upla.com.tr](https://upla.com.tr) için macOS uygulaması. Ekran görüntüsü ve ekran kaydı alır, upla.com.tr'ye yükler ve bağlantıyı panoya kopyalar. Uygulama geliştirme aşamasında; plan için [PLAN.md](PLAN.md) dosyasına bakın. Windows sürümü: https://github.com/Agnostique/UpLa

**English:** The macOS app of [upla.com.tr](https://upla.com.tr). It takes screenshots and screen recordings, uploads them to upla.com.tr and copies the link to the clipboard. The app is in development; see [PLAN.md](PLAN.md). The Windows version is at https://github.com/Agnostique/UpLa

## Mac'te derleme

macOS 14 veya daha yenisi ve Xcode 16 gerekir.

1. XcodeGen'i kurun: `brew install xcodegen`
2. Misafir yükleme anahtarı için `cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig` komutunu çalıştırıp dosyayı doldurun. Bu dosya git'e eklenmez; anahtar olmadan da derlenir, o zaman yüklemek için giriş yapmak gerekir.
3. `xcodegen generate`
4. `open UpLa.xcodeproj`, ardından UpLa şemasını çalıştırın (⌘R). Signing & Capabilities bölümünde kendi (Personal) Team'inizi seçerseniz Ekran Kaydı izni derlemeler arasında korunur.

## CI derlemesini deneme

1. GitHub'da Actions › "Build UpLa for Mac" altında son başarılı çalışmayı açın ve **UpLa-mac** dosyasını indirin.
2. Zip'i açın ve `UpLa.app`'i Uygulamalar klasörüne taşıyın.
3. Uygulama noter onaylı (notarized) değildir: ilk açılışta sağ tıklayıp **Aç**'ı seçin veya Terminal'de `xattr -dr com.apple.quarantine /Applications/UpLa.app` çalıştırın.
4. İstendiğinde Sistem Ayarları › Gizlilik ve Güvenlik › Ekran ve Sistem Sesi Kaydı bölümünde UpLa'ya izin verin, sonra UpLa'yı kapatıp yeniden açın.
5. Her test derlemesi farklı imzalandığı için Ekran Kaydı iznini ve anahtar zinciri erişimini yeniden isteyebilir.

## Build on a Mac

Needs macOS 14 or later and Xcode 16.

1. Install XcodeGen: `brew install xcodegen`
2. For the guest upload key, run `cp Config/Secrets.example.xcconfig Config/Secrets.xcconfig` and fill it in. The file is not added to git; the app also builds without it, and then uploads need a sign-in.
3. `xcodegen generate`
4. `open UpLa.xcodeproj` and run the UpLa scheme (⌘R). Choose your own (Personal) Team under Signing & Capabilities to keep the Screen Recording permission between builds.

## Try a CI build

1. On GitHub, open the latest successful run under Actions › "Build UpLa for Mac" and download the **UpLa-mac** artifact.
2. Unzip it and move `UpLa.app` to the Applications folder.
3. The app is not notarized: the first time, right-click it and choose **Open**, or run `xattr -dr com.apple.quarantine /Applications/UpLa.app` in Terminal.
4. When asked, allow UpLa in System Settings › Privacy & Security › Screen & System Audio Recording, then quit and reopen UpLa.
5. Each test build is signed differently, so it may ask again for the Screen Recording permission and for keychain access.

License: GNU General Public License v3, see [LICENSE](LICENSE).
