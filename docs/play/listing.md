# Google Play listing: texts and graphics

Drafts for the store listing (not needed for internal testing). **Check every sentence against the app on a phone before publishing**: nothing in this repository has been verified on a device yet, and a listing must not promise what the app does not do.

## Graphics (in `assets/branding/`)
| Play field | File | Size |
|---|---|---|
| App icon | `play_icon_512.png` | 512 x 512, full square (Play applies its own mask) |
| Feature graphic | `play_feature_1024x500.png` | 1024 x 500 |
| Screenshots | take them on a phone | at least 2, phone, portrait or landscape |

The icon and graphics are original (drawn by `tools/make_icons.py`). Suggested screenshots: the inbox with a few notifications, the notification details with Create task, the task list, the month view in Persian (right to left), the month view in English, the week view, Settings > Calendars, and a dark-theme screen. Use a test phone with no private notifications visible.

## English
**Name:** Nudge

**Short description (80 characters at most):**
Turn notifications into tasks and reminders, with a calendar you enjoy.

**Full description:**
Nudge keeps the notifications your phone gives it in one inbox, and turns any of them into a task or a timed reminder with one tap.

- A notification inbox: it collects the notifications Android shares with Nudge after you allow Notification Access, and keeps them until you delete them or set a retention period.
- Tasks and reminders: create a task from a notification, set a date and time, snooze, complete or archive. A reminder alerts you at the time you chose, with a Snooze button.
- Back to the source: open the original notification when it is still there, or the app it came from.
- A calendar: month, week, day and agenda views, in the Jalali (Persian) or Gregorian calendar, with Persian right-to-left layout and light and dark themes.
- Your device calendars (optional): turn on "Show device calendars" to see the events of your Google or Samsung calendars next to your tasks, and to add, edit or delete events and put a task into your calendar.
- Persian and English: the whole app is available in both languages.
- Your data stays with you: everything is stored on the device, Nudge does not use the internet, and you can export or delete your data in Settings.

What Nudge cannot do: it only sees notifications Android shares with it after you allow access; it cannot read notifications from before that, and content that Android hides stays hidden. It does not use Accessibility services.

## Persian (فارسی)
**نام:** Nudge

**توضیح کوتاه (حداکثر ۸۰ نویسه):**
اعلان‌ها را به وظیفه و یادآور تبدیل کنید، با تقویمی که دوستش دارید.

**توضیح کامل:**
Nudge اعلان‌هایی را که گوشی در اختیارش می‌گذارد در یک صندوق نگه می‌دارد و با یک لمس هر کدام را به وظیفه یا یادآور زمان‌دار تبدیل می‌کند.

- صندوق اعلان‌ها: بعد از اینکه دسترسی به اعلان‌ها را بدهید، اعلان‌هایی را که اندروید با Nudge به اشتراک می‌گذارد جمع می‌کند و تا زمانی که حذفشان کنید یا مدت نگهداری تعیین کنید نگه می‌دارد.
- وظیفه و یادآور: از هر اعلان وظیفه بسازید، تاریخ و ساعت بگذارید، به تعویق بیندازید، انجام دهید یا بایگانی کنید. یادآور در زمان انتخابی با دکمه‌ی تعویق هشدار می‌دهد.
- بازگشت به منبع: اعلان اصلی را، تا وقتی هست، یا برنامه‌ای را که از آن آمده باز کنید.
- تقویم: نمای ماه، هفته، روز و برنامه، با تقویم شمسی یا میلادی، چیدمان راست‌به‌چپ فارسی و تم روشن و تیره.
- تقویم‌های دستگاه (اختیاری): با روشن‌کردن «نمایش تقویم‌های دستگاه»، رویدادهای تقویم گوگل یا سامسونگ را کنار وظایف ببینید، رویداد اضافه، ویرایش یا حذف کنید و وظیفه را به تقویم ببرید.
- فارسی و انگلیسی: کل برنامه به هر دو زبان است.
- داده‌های شما پیش خودتان می‌ماند: همه‌چیز روی دستگاه ذخیره می‌شود، Nudge از اینترنت استفاده نمی‌کند و در تنظیمات می‌توانید داده‌هایتان را برون‌بری یا حذف کنید.

آنچه Nudge نمی‌تواند: فقط اعلان‌هایی را می‌بیند که اندروید پس از اجازه‌ی شما با آن به اشتراک می‌گذارد؛ اعلان‌های پیش از آن را نمی‌تواند بخواند و محتوایی که اندروید پنهان می‌کند پنهان می‌ماند. از سرویس دسترس‌پذیری (Accessibility) استفاده نمی‌کند.

## Other fields
- Category: Productivity. Free. No ads. No in-app purchases.
- Contact email and privacy policy URL: see docs/PLAY.md.
- Content rating, target audience and the Data safety form: answer from docs/PLAY.md and PRIVACY.md.
