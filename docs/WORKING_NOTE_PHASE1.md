# Careerly — Faz 1 çalışma notu

Tarih: 2026-10-02

## Kapsam

Bu not, mevcut çalışma ağacını değiştirmeden başlangıç durumunu kaydeder. Önceden
var olan tracked/untracked değişiklikler korunmuştur; reset, checkout, clean veya
toplu silme uygulanmamıştır.

## Başlangıç durumu

- 87 tracked dosya modified durumda.
- 80 dosya untracked durumda.
- `git diff --check` ek whitespace hatası bildirmedi.
- Flutter projesi Dart SDK `^3.13.3` ve Riverpod, GoRouter, Dio,
  SharedPreferences, file_picker, PDF/printing bağımlılıklarını kullanıyor.
- Backend Python `>=3.11`, FastAPI, SQLAlchemy, Alembic, PyMuPDF ve
  python-docx kullanıyor.

## Doğrulama

- Backend testleri: `62 passed`.
- Backend Ruff: 9 mevcut uyarı/hata; çoğu import düzeni, modern type annotation
  ve kullanılmayan import seviyesinde.
- `flutter analyze`, `flutter test` ve Flutter sürüm sorgusu, Flutter SDK’nın
  `/Users/efeardaaric/development/flutter/bin/cache` altında engine cache dosyalarına
  yazamaması nedeniyle çalışmadı (`Operation not permitted`). Bu nedenle Flutter
  derleme/analyzer sonucu henüz doğrulanmış değildir.

## Faz 1 kararı

Bu fazda derlemeyi veya temel çalışmayı engellediği doğrulanmış bir proje kodu
hatası bulunmadığından uygulama kodu değiştirilmedi. Flutter SDK izin problemi
çözülmeden Flutter tarafında güvenilir düzeltme yapılmayacaktır.

## Sonraki faz

Faz 2’de sign-out sonrası CV, analiz, Job Match, başvuru ve Builder verilerinin
kullanıcılar arasında sızmamasını sağlayacak local state izolasyonu ele alınacaktır.
