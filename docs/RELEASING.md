# Releasing

## Where builds come from
| You do this | CI does this | Where the output is |
|---|---|---|
| Push to any branch | analyze, test, build APK and Windows zip | Artifacts of that run, named `Nudge_v<version>_<branch>-<commit>_...`, kept 14 days |
| Push to `main` | the same, plus publishes the rolling `nightly` pre-release | Artifacts (30 days) and the **nightly** release, replaced on every push |
| Push a tag `v<version>` | the same, plus publishes a permanent release | A GitHub release named `Nudge v<version>` with the APK, the Windows zip, `SHA256SUMS.txt` and the changelog section as notes |
| Open a pull request from a fork | analyze, test, build | Artifacts of that run (no release) |

Pull requests from branches of this repository are not run twice: the branch push already covers them.

## Cutting a release
1. On a branch, bump `version:` in `pubspec.yaml` and `appVersion` in `lib/app_info.dart` (a test keeps them equal) and add a `## [x.y.z]` section to `CHANGELOG.md`.
2. Merge to `main` and wait for CI to pass.
3. Create the tag `v<version>` on that commit. Either:
   - `git tag v0.5.1 && git push origin v0.5.1`, or
   - on GitHub: Releases > Draft a new release > choose or create the tag > Publish. CI then attaches the files to that release.
4. CI checks that the tag matches the version in `pubspec.yaml` and fails otherwise. Versions starting with `0.` are published as pre-releases.

## Notes
- All builds are debug-signed. A signed release build needs a keystore stored as repository secrets and is not set up yet.
- Re-running a tag build attaches the files again and overwrites the previous ones.
- A tag should point at a commit that is on `main`; CI does not enforce this.
