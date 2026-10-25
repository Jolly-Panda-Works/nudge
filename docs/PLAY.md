# Getting Nudge onto phones through Google Play

## Why Google Play
Android 15-era Play Protect blocks apps that are installed from a browser, a messaging app or a file manager (so-called sideloading) when the app asks for notification access. The screen says "App blocked to protect your device" and has no "Install anyway" button. Nudge exists to read notifications, so every sideloaded build is affected. An app installed from Google Play is not. The simplest route that works on any phone is Google Play's **internal testing track**: up to 100 testers (you and anyone you add), no public listing, and updates arrive through the Play Store like any other app.

What you need: a Google account, a one-time developer registration fee (US$25 at the time of writing) with identity verification, and a computer or a phone browser. Internal testing does not need Google's review of the store listing; the "closed test with 12 testers for 14 days" rule only applies to a *public* release from a personal account created after November 2023.

## Step 1 - make the upload key (once)
Play needs a bundle signed with a real key (not the debug key). Create it with the script in this repository. If you have no JDK on your computer, use GitHub Codespaces (free tier, runs in the browser):
1. On the repository page: Code > Codespaces > Create codespace on main.
2. In its terminal run: `bash tools/make_keystore.sh`
3. It prints three values. In the repository: Settings > Secrets and variables > Actions > New repository secret, and add `NUDGE_KEYSTORE_BASE64`, `NUDGE_KEYSTORE_PASSWORD` and `NUDGE_KEY_ALIAS` (the fourth, `NUDGE_KEY_PASSWORD`, is optional).
4. Keep the `.jks` file and the password somewhere safe (a password manager), then delete the codespace.
Google can reset a lost *upload* key later because Play App Signing keeps the real signing key, so this is recoverable; still, do not commit the file or paste the values into chats or issues.

## Step 2 - let CI build the bundle
Push to `main`. When the secrets exist, the Android job also builds `..._android.aab` and attaches it to the release. (Without the secrets it builds only the debug-signed APKs, and no bundle.) Check the Android job summary: `targetSdkVersion` must meet Google's current minimum for new apps; if it does not, tell the maintainer.

## Step 3 - create the app in Play Console
1. Register at play.google.com/console (personal account; Google verifies your identity).
2. Create app: name *Nudge*, default language, *App*, *Free*; accept the declarations.
3. Left menu: Testing > Internal testing > Create new release. When asked, enrol in **Play App Signing** (accept) and upload the `.aab` from the GitHub release. Add release notes and save, then roll out to internal testing.
4. Internal testing > Testers: create a list with your Google account email (and anyone else), save, and copy the **opt-in link**.
5. On the phone, signed in with that Google account, open the link, accept, and install from the Play Store.
Every later push to `main` makes a new bundle with a higher version code; upload it as a new internal release and the testers are updated by Play.

## Step 4 - what Play will ask for later (not needed for internal testing)
These matter only if the app is ever offered to the public, but the answers are worth knowing now:
- **Privacy policy URL:** the repository's PRIVACY.md (for example `https://github.com/Jolly-Panda-Works/nudge/blob/main/PRIVACY.md`).
- **Data safety:** everything stays on the device and the app asks for no internet permission; check the `uses-permission` lines in the Android job summary before answering "no data collected or shared".
- **Notification access:** declared as the core purpose; the app shows a disclosure and asks for consent before opening Android's Notification Access screen.
- **Exact alarms** (`SCHEDULE_EXACT_ALARM`): reminders and alarms are the stated reason; Play asks for a declaration.
- **Calendar permissions** (`READ_CALENDAR`, `WRITE_CALENDAR`): only used after the user turns on "Show device calendars".
- Content rating questionnaire, target audience and ads (none). Store listing texts, the 512 x 512 icon and the 1024 x 500 feature graphic are drafted in [play/listing.md](play/listing.md) and `assets/branding/`; you take the screenshots on a phone.

## If something goes wrong
- *The upload is refused because the bundle is signed in debug mode*: the secrets were missing or wrong when CI ran; check the "Prepare the signing key" step.
- *The version code was already used*: every upload needs a higher number than any earlier one; CI uses the run number, so just push again.
- *The phone says the app is not available*: the Google account on the phone must be in the tester list and must have opened the opt-in link.
