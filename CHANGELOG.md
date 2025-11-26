# Changelog

All notable changes to this project will be documented in this file.

This project follows [Conventional Commits](https://www.conventionalcommits.org/) and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- **feat(rules)**: add `avoid_cross_feature_barrel_exports` rule to ensure barrel files only export from their own feature folder
- **feat(quickfix)**: add quick fix to remove cross-feature exports from barrel files
- **fix(rules)**: `avoid_self_barrel_import` now correctly detects relative imports to own barrel file (e.g., `import '../trip.dart'` from `feature_trip/ui/file.dart`)
- **test**: add 15 comprehensive tests for the new barrel exports rule
- **test**: add 2 tests for relative barrel imports detection
- **refactor**: split monolithic barrel_file_lints.dart (517 lines) into modular structure with separate directories for rules, fixes, and utilities

## [1.0.3] - 2025-11-25

- **feat(rules)**: add `avoid_self_barrel_import` rule to prevent circular dependencies by blocking files from importing their own feature's barrel file
- **feat(config)**: add configuration presets in README (Strict, Moderate, Conservative modes)
- **feat(rules)**: extend internal directory detection: `/services/`, `/repositories/`, `/providers/`, `/bloc/`, `/cubit/`, `/notifiers/`, `/widgets/`, `/utils/`, `/config/`, `/helpers/`
- **fix(config)**: `analysis_options.yaml` now uses root-level `plugins:` (Dart 3.10+ standard)
- **docs**: streamline README from 281 to 257 lines by merging Quick Fixes into Rules section
- **docs**: add barrel file trade-offs section and configuration best practices

## [1.0.2] - 2025-11-24

- **docs**: enhance dartdoc comments on internal classes and members to improve API documentation coverage

## [1.0.1] - 2025-11-24

- **ci**: simplify publish workflow to use official Dart publish action
- **ci**: improve CI/CD workflows with better verification and quality checks

## [1.0.0] - 2025-11-24

- **feat**: initial stable release
- **feat(rules)**: add `avoid_internal_feature_imports` rule - features must import other features via barrel files only
- **feat(rules)**: add `avoid_core_importing_features` rule - core module must not import from feature modules
- **feat(quickfix)**: add quick fix to replace internal import with barrel file import
- **feat(quickfix)**: add quick fix to comment out feature import in core with TODO
- **feat**: support both naming conventions: `feature_xxx/` (underscore) and `features/xxx/` (clean architecture)
- **feat**: support both absolute (`package:`) and relative (`../`) imports
- **feat**: automatically exclude test files from checks
- **test**: add comprehensive test suite (47 tests across 7 test files)
- **ci**: add full CI/CD pipeline with GitHub Actions
- **docs**: add complete documentation and examples
