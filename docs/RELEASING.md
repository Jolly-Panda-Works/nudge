# Releasing

Every push is built. What you get depends on where you push.

| You push to | Version | Where the output is |
|---|---|---|
| `main` | `MAJOR.MINOR.<run number>`, for example `0.5.123` | A permanent GitHub release `v0.5.123` with the APK, the Windows zip, `SHA256SUMS.txt` and generated notes |
| a tag `vX.Y.Z` | exactly `X.Y.Z` | A permanent GitHub release for that tag (files are attached if the release already exists) |
| any other branch | `MAJOR.MINOR.0-dev.<run number>` | Artifacts of the run only, named `Nudge_v0.5.0-dev.45_<branch>-<commit>_...`, kept 14 days |
| a pull request from a fork | like a branch | Artifacts of the run only |

`MAJOR.MINOR` comes from `version:` in `pubspec.yaml`. To start a new release line, bump the minor (or major) number there. The run number only ever grows, so each release has a unique version and the Android version code increases with every build.

The version is built into the app: CI passes `--build-name`, `--build-number` and `--dart-define=NUDGE_VERSION=<version>`, so Settings > About shows exactly the version of the file you installed.

## Details worth knowing
- **Builds do not wait for the tests.** Analysis and tests run in parallel and show red or green on the commit, but a failing test never blocks the APK or the release. To require green tests before building, add `verify` to `needs:` of the `android` and `windows` jobs in `ci.yml`.
- **The release is created as soon as the Android build succeeds.** The Windows zip is attached when its build also succeeded; otherwise the release notes say so.
- **Only the newest release is kept.** Each push to `main` gets the next version and tag automatically, becomes the "Latest" release, and every older release and its tag are deleted. Releases made from a tag you pushed yourself (`vX.Y.Z`) are marked as kept and are not deleted.
- **Pull requests from branches of this repository** are not built twice: the branch push already covers them.
- Android files are release builds split per architecture (`arm64-v8a` for recent phones, `armeabi-v7a` for old 32-bit ones), a fraction of the size of the earlier universal debug APK. They are still signed with the debug key, which CI generates fresh on each run, so an update may need an uninstall first until a keystore is set up.
- **Signing.** The Android application id is `com.jollypanda.nudge`. Create the release key once with `bash tools/make_keystore.sh` (needs a JDK), keep the `.jks` file and its password safe, and add the printed values as repository secrets: `NUDGE_KEYSTORE_BASE64`, `NUDGE_KEYSTORE_PASSWORD`, `NUDGE_KEY_ALIAS` (and optionally `NUDGE_KEY_PASSWORD`). With them, every APK is signed with the same key, so updates install over each other. If the key is lost, installed copies can only be replaced after uninstalling. Without the secrets the build falls back to the debug key and the release notes say so.
- Older notes below that mention debug signing apply only when the secrets are missing. All builds were debug-signed before 0.8.1. A signed release build needs a keystore stored as repository secrets and is not set up yet.
- Tags created by the workflow itself (for `main` releases) do not start another run. Tags you push yourself do.

## Cutting a named version
1. Merge what you want to ship to `main` and wait for it to build.
2. Create the tag `vX.Y.Z` on that commit: `git tag v0.6.0 && git push origin v0.6.0`, or on GitHub: Releases > Draft a new release > choose or create the tag > Publish. CI then builds that commit and attaches the files to the release.
3. Add a `## [X.Y.Z]` section to `CHANGELOG.md` for the notes you want to keep with the repository.

## If the APK will not install
Android says what is wrong; the exact message decides:
- **"App not installed as package conflicts with an existing package"** (or "signatures do not match"): an older Nudge is installed that was signed with another key. Uninstall it (Settings > Apps > Nudge) and install again. Builds made before 0.16.2 each had a different key; from 0.16.2 on they share one (kept in the Actions cache) so updates work. A release key from the secrets (see Signing above) is the permanent fix.
- **"App not compatible" or "There was a problem parsing the package"**: use the `arm64-v8a` file; `armeabi-v7a` is only for old 32-bit phones and many new phones cannot run it.
- **"Blocked by Play Protect"**: tap "More details" > "Install anyway". The app is signed with a debug key, so Play Protect does not know it.
- **The Settings switch for Notification Access is grey** after installing: Android 13 and later restrict sideloaded apps; open Settings > Apps > Nudge > the three dots > "Allow restricted settings".
The Android job summary lists each APK's package name, version, SDK levels and ABIs, and its log prints the final manifest.
- **Still "App not installed"?** Install the file with a tool that shows the real reason, for example the free "SAI (Split APKs Installer)" app, or `adb install -r file.apk` from a computer; they print a code such as `INSTALL_FAILED_UPDATE_INCOMPATIBLE` (another signature: uninstall Nudge first), `INSTALL_FAILED_VERSION_DOWNGRADE`, `INSTALL_FAILED_NO_MATCHING_ABIS` (wrong file: use arm64-v8a) or `INSTALL_PARSE_FAILED_...` (a broken manifest). Send that code, the phone model and the Android version, plus the Android job summary of the same run.
