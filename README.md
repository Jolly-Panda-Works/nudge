# Unified Inbox - M1 / بخش ۱: اسکلت، دامنه، mapper و منطق dedupe (v0.1.1)

## مسیر A: بدون نصب Flutter (فقط GitHub)
1. در GitHub یک repository خالی بسازید (مثلا `unified-inbox`).
2. zip را باز کنید و **محتوای** پوشه `unified_inbox` را در ریشه repo آپلود کنید
   (با `git push` یا درگ‌ودراپ در صفحه repo؛ پوشه `.github` حتما باید آپلود شود).
3. تب **Actions** > workflow با نام **Bootstrap platforms** > **Run workflow**.
   این workflow یک‌بار پوشه‌های `android/` و `windows/` را می‌سازد، کد را format می‌کند،
   نتیجه را commit می‌کند، سپس analyze و test اجرا می‌کند.
4. بعد از پایان موفق، `git pull` کنید (یا همان repo را در GitHub ادامه دهید).
5. تب Actions > **CI** > **Run workflow**؛ در پایان از بخش Artifacts می‌توانید
   `android-debug-apk` و `windows-release` را دانلود کنید.
6. اگر مرحله‌ای قرمز شد، متن خطای همان step را برای من بفرستید.

نکته: commit هایی که با GITHUB_TOKEN انجام می‌شوند CI را خودکار اجرا نمی‌کنند؛ به همین دلیل مرحله ۵ دستی است.

## مسیر B: با Flutter محلی
Flutter 3.35.0 (stable)، JDK 17، Android SDK؛ برای ویندوز Visual Studio 2022 با «Desktop development with C++».
```bash
flutter create . --platforms=android,windows --project-name unified_inbox --org app.unifiedinbox
rm -f test/widget_test.dart
flutter pub get && dart format . && flutter analyze && flutter test
```

## Git
```bash
git add . && git commit -m "feat(domain): add notification model, mapper and ingest policy"
```
متن کامل commit ها در `COMMIT_MESSAGE.txt` است.

## وضعیت
- پیاده‌سازی‌شده (با تست واحد): mapper، تشخیص redacted، hash محتوا، تصمیم dedupe، فیلتر allow/blocklist.
- هنوز نیست: دیتابیس، سرویس Kotlin، UI صندوق ورودی، share/import (بخش‌های ۲ تا ۵).
- بررسی‌نشده: اجرای واقعی تست‌ها و build (در محیط تولید این فایل Flutter در دسترس نبود).
