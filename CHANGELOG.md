# Changelog

All notable changes are documented here. Format based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); versions follow
[Semantic Versioning](https://semver.org/) (pre-1.0).

## [0.2.2] - 2026-10-13
### Added
- `ROADMAP.md`: progress per milestone and section, what is done and what remains, known risks.
### Changed
- All documentation is English only; the Persian README was removed.

## [0.2.1] - 2026-10-13
### Added
- Open-source project files: README (English and Persian), LICENSE (MIT), CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, PRIVACY, docs (architecture, development, roadmap), issue and PR templates, Dependabot, editorconfig.
- CI publishes the outputs of every push to `main` as a rolling `nightly` pre-release (APK and Windows zip, version in the file name).
- Workflows that commit to `main` (format, bootstrap, rename) now start CI on the new commit.
### Changed
- Formatting check in CI is report-only; the Format workflow fixes it.
- CI no longer cancels a running build when a newer push arrives.

## [0.2.0] - 2026-10-12
### Added
- Drift database (notifications, source rules, settings) and repositories: atomic ingest with dedupe, removal marking, reconciliation, retention purge, delete-all.
- App renamed to Nudge; version shown in the app shell.
- Workflows: build_runner step, Format code, one-time rename.

## [0.1.1] - 2026-10-12
### Added
- Bootstrap workflow to generate platform folders without a local Flutter installation.

## [0.1.0] - 2026-10-12
### Added
- Domain model, notification mapper, ingest/dedupe policy, tests and CI.
