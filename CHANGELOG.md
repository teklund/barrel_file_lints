# Changelog

All notable changes to this project will be documented in this file.

This project follows [Conventional Commits](https://www.conventionalcommits.org/) and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.5] - 2025-12-05

### New Features

- **feat(rules)**: add `avoid_relative_barrel_imports` rule to encourage package imports over relative imports for cross-feature barrel files
- **feat(rules)**: add `avoid_flutter_in_domain` rule to enforce framework independence in domain/data layers
- **feat(rules)**: add `avoid_improper_layer_import` rule to enforce clean architecture layer boundaries (UI → Data → Domain)
- **feat(quickfix)**: add `ConvertToPackageImport` quick fix to automatically convert relative barrel imports to package imports
- **feat(quickfix)**: add `UseLayerSpecificBarrel` quick fix to suggest layer-specific barrel imports (e.g., `xxx_data.dart` instead of `xxx.dart`)

### Improvements

- **perf**: significantly improved analysis performance with cached regex patterns and early test file exits
- **fix(rules)**: `avoid_self_barrel_import` now correctly detects split barrel self-imports and allows cross-layer imports within the same feature
- **fix(rules)**: `avoid_improper_layer_import` now flags monolithic barrel usage in data/domain layers and suggests split barrels

### Breaking Changes

- **BREAKING**: removed `avoid_barrel_cycle` rule due to performance concerns (synchronous file I/O caused 150-1250ms overhead)
  - Use CLI tool instead: `dart run barrel_file_lints:check_cycles` (detects both immediate and transitive cycles)
  - Integrate into CI/CD for comprehensive cycle detection without impacting real-time analysis

### Documentation

- Add comprehensive documentation for all rules and split barrel architecture
- Add "Setting Up Split Barrel Files" guide to README

## [1.0.4] - 2025-11-26

- **feat(rules)**: add `avoid_cross_feature_barrel_exports` rule to ensure barrel files only export from their own feature folder
- **feat(cli)**: add `check_cycles` CLI tool for detecting circular dependencies (both immediate and transitive: A → B → C → A)
- **feat(quickfix)**: add quick fix to remove cross-feature exports from barrel files
- **feat(quickfix)**: add `RemoveSelfBarrelImport` quick fix for circular self-imports
- **feat(quickfix)**: add `SimplifyRelativePath` quick fix for redundant relative paths within same feature
- **fix(rules)**: `avoid_self_barrel_import` now correctly handles relative imports at different directory depths

## [1.0.3] - 2025-11-25

- **feat(rules)**: add `avoid_self_barrel_import` rule to prevent circular dependencies
- **feat(rules)**: extend internal directory detection to include common Flutter/Dart patterns: `/services/`, `/repositories/`, `/providers/`, `/bloc/`, `/cubit/`, `/notifiers/`, `/widgets/`, `/utils/`, `/config/`, `/helpers/`
- **fix(config)**: `analysis_options.yaml` now uses root-level `plugins:` (Dart 3.10+ standard)

## [1.0.2] - 2025-11-24

- Improved documentation and API coverage

## [1.0.1] - 2025-11-24

- Improved CI/CD and publishing workflows

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
