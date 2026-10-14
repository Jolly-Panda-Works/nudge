# Contributing to Nudge

Thanks for helping! Please read the [Code of Conduct](CODE_OF_CONDUCT.md) first.

## Ground rules (from the product spec)
- No Accessibility Service, root access or hidden APIs to bypass platform restrictions.
- Never fabricate deep links or claim an exact conversation can always be reopened.
- Never write notification bodies or tokens to logs, test output or CI logs.
- Do not copy Samsung's (or any vendor's) proprietary assets or exact UI.
- Do not store `PendingIntent`s; they are not durable.
- Keep milestones independently testable, and in docs and PRs distinguish implemented features from mocked UI and unverified assumptions.

## Workflow
1. Open an issue (bug or feature) before large changes.
2. Branch from `main`, keep PRs focused.
3. Add or update tests. Domain logic must have unit tests; storage code uses in-memory SQLite.
4. Make sure `flutter analyze` and `flutter test` pass (CI runs them). If you generated code: `dart run build_runner build`.
5. Formatting: run `dart format .`; the **Format code** workflow also fixes it on `main`.

## Branches and builds
Work on a branch. Every push to any branch is built by CI, and the APK and Windows zip are attached to that run as artifacts named with the branch and commit, so you can try your change without touching `main`. Merge to `main` through a pull request. Releases are made by tagging; see [docs/RELEASING.md](docs/RELEASING.md).

## Commit messages
[Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `test:`, `ci:`, `chore:`, `refactor:`, optionally with a scope, e.g. `feat(data): add retention purge`.

## Versioning
Semantic versioning, pre-1.0. The version lives in `pubspec.yaml` (`version: x.y.z+build`) and in `lib/app_info.dart` (`appVersion`, a test keeps them equal). Bump the minor version for a new feature section and the patch version for fixes or docs/CI changes, and add an entry to `CHANGELOG.md`.

## Pinned toolchain
Flutter **3.35.0** is pinned in `pubspec.yaml` and the workflows. Please do not change it inside an unrelated PR.
