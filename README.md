# Nudge v0.2.0 - M1 / بخش ۲: دیتابیس Drift و repository ها

نسخه‌ی zip و اپ در نام دیده می‌شود: `Nudge_M1-S2_v0.2.0.zip`، و داخل اپ متن `Nudge v0.2.0`.

## نصب این بخش (فقط GitHub، بدون Flutter محلی)
1. محتوای پوشه‌ی `nudge` داخل zip را روی ریشه‌ی repo کپی کنید (overwrite) و push کنید.
2. بعد از push، workflow ی **Format code** خودکار اجرا می‌شود و فرمت کد را commit می‌کند
   (چون من فرمت‌کننده‌ی Dart را اجرا نمی‌کنم). CI ی همان push ممکن است روی مرحله‌ی format قرمز شود؛ طبیعی است.
3. `git pull` کنید، سپس تب Actions > **CI** > Run workflow.
4. فقط یک‌بار: Actions > **Rename app to Nudge** > Run workflow.
   این workflow نام نمایشی اندروید/ویندوز را Nudge و شناسه‌ی اندروید را `app.nudge.nudge` می‌کند.
   بعد از پایان دوباره `git pull` و سپس CI را دستی اجرا کنید.
5. اگر مرحله‌ای قرمز شد، متن خطای همان step را بفرستید.

## Git
خط اول `GIT_COMMIT.txt` را به‌عنوان عنوان commit استفاده کنید (بقیه‌ی فایل توضیح commit است).

## چه چیزی اضافه شد
- جدول‌های Drift: `notifications`، `source_rules`، `app_settings` (زمان‌ها UTC و میلی‌ثانیه).
- `DriftNotificationRepository`: ingest اتمیک با منطق dedupe بخش ۱، علامت‌گذاری حذف‌شده،
  reconcile بعد از اتصال listener (`markRemovedExcept`)، پاکسازی بر اساس سن، حذف همه، stream صندوق ورودی.
- `DriftCaptureSettingsRepository`: allow/blocklist، فیلتر ongoing و group summary، مدت نگهداری.
- هیچ PendingIntent یا متن اعلان در لاگ نوشته نمی‌شود.
- فایل‌های `*.g.dart` در repo نیستند؛ CI آن‌ها را با `build_runner` می‌سازد.

## وضعیت
- پیاده‌سازی‌شده با تست: repository ها روی SQLite درون‌حافظه.
- بررسی‌نشده: نسخه‌ی دقیق drift (اولین resolve در CI)، اجرای واقعی روی دستگاه، فرایند rename (workflow جدید).
- هنوز نیست: سرویس Kotlin (بخش ۳)، UI صندوق ورودی (بخش ۴)، share/import و export/delete از UI (بخش ۵).
