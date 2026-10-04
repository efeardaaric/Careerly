# Careerly — referans tasarım entegrasyonu

## Uygulanan tasarım

Referansın açık zemin, kömür rengi metin, sarı ana aksiyon, siyah kapsül navigasyon, mint analiz yüzeyi ve renkli şablon kartları uygulamaya kod üzerinden taşındı. Ortak tema ve bileşenler bütün ekranları etkiler; ana sayfa, oluşturucu ve analiz sonucu ayrıca yeni yerleşimlerle güncellendi. Referanstaki fotoğraflar, hayali kullanıcılar ve şablon adetleri kopyalanmadı. Galeri mevcut dört gerçek CvTemplateId seçeneğine bağlıdır; küçük görseller soyut yerleşim illüstrasyonudur, dışa aktarılan PDF'nin birebir önizlemesi değildir.

Referans açık tema olduğu için uygulama artık açık temayı kullanır. Mevcut darkTheme tanımı korunur fakat etkin değildir. Backend, oturum izolasyonu ve analiz/puanlama algoritması bu çalışma kapsamında değiştirilmedi. Çalışma ağacındaki mevcut değişiklikler korunmuştur.

## Bu çalışmada değiştirilen / eklenen kaynaklar

- `lib/app/app.dart`: açık referans temasının etkinleştirilmesi.
- `lib/app/theme/app_theme.dart`: palet, tipografi, yüzeyler, butonlar, alanlar, dialog/bottom-sheet stilleri.
- `lib/core/widgets/app_button.dart`: aksiyon boyutları ve yükleme göstergesi.
- `lib/core/widgets/app_states.dart`: seçim kartları.
- `lib/core/widgets/careerly_identity.dart`: marka başlığı, bölüm etiketleri ve boş durumlar.
- `lib/core/widgets/processing_stage_view.dart`: mint işleme yüzeyi, kaydırma ve erişilebilir iptal.
- `lib/core/widgets/resume_template_gallery.dart`: yeni yatay/grid galeri, soyut CV görselleri, çalışan arama.
- `lib/features/home/presentation/home_shell.dart`: siyah-sarı kapsül alt navigasyon.
- `lib/features/home/presentation/home_screen.dart`: profil satırı, galeri, hızlı araçlar, mint CV kartı ve şablon akışı.
- `lib/features/cv_builder/presentation/builder_screen.dart`: aranabilir galeri ve seçili şablonla kuruluma geçiş.
- `lib/features/analyze/presentation/analysis_result_screen.dart`: gerçek CV kalite skorunu gösteren mint sonuç paneli.
- `lib/features/analyze/presentation/widgets/cv_score_indicator.dart`: açık skor görünümü.
- `lib/features/language/presentation/language_screen.dart`: küçük ekranlarda kaydırma.
- `lib/features/splash/presentation/splash_screen.dart`: sarı marka işareti.
- `lib/app/localization/l10n/app_en.arb`, `app_tr.arb`: oluşturucu açıklamaları.
- `lib/app/localization/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_tr.dart`: Flutter tarafından yeniden üretilen yerelleştirmeler.
- `test/widgets/reference_brand_layout_test.dart`: şablon arama/seçim ve dar ekran/büyük yazı testleri.

## Doğrulama

- Değiştirilen Dart kaynakları `dart format` ile biçimlendirildi.
- `flutter gen-l10n`: başarılı.
- `flutter analyze --no-pub`: hata/uyarı yok.
- `flutter test --no-pub`: 89 test geçti.
- `git diff --check`: başarılı.
- Xcode Debug iOS Simulator build: başarılı; güncel build yüklendi ve çalıştırıldı.
- Ana sayfa, oluşturucu, analiz yükleme, işler ve profil ekranları simülatörde görsel olarak kontrol edildi.
- Xcode Release fiziksel iPhone build: başarılı.
- Güncel Release uygulaması bağlı fiziksel iPhone'a başarıyla yüklendi. Otomatik başlatma cihaz kilitli olduğu için reddedildi (`FBSOpenApplicationErrorDomain`, `Locked`). Cihazın kilidini açıp Careerly'yi açmak gerekir.

## Sınırlar / kalan kontroller

PDF testlerinde internetten font indirme ve Helvetica'nın Türkçe karakter desteğiyle ilgili mevcut uyarılar görüldü; testler geçti. Bu UI çalışması PDF font altyapısını değiştirmez.

Her ekranın bütün veri/hata/premium durumları fiziksel cihazda manuel gezilmedi. Referansın tasarım dili uygulanmıştır; görselin piksel-piksel kopyası veya fotoğraflı yeni PDF şablon sistemi yapılmamıştır.
