# Changelog

All notable changes to this project will be documented in this file.

This project follows [Conventional Commits](https://www.conventionalcommits.org/) and adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

- **feat(rules)**: add `avoid_relative_barrel_imports` rule to discourage relative imports for cross-feature barrel files
- **feat(quickfix)**: add `ConvertToPackageImport` quick fix to automatically convert relative barrel imports to package imports
- **feat(rules)**: enhance `avoid_improper_layer_import` to flag monolithic barrel usage in data/domain layers, suggesting split barrels instead
- **fix(rules)**: enhance `avoid_self_barrel_import` to detect split barrel self-imports (xxx_data.dart, xxx_domain.dart, xxx_ui.dart) and only flag when a layer imports its own split barrel (e.g., data/ importing auth_data.dart), allowing cross-layer imports within same feature
- **test**: add 12 comprehensive tests for `avoid_relative_barrel_imports` covering both naming conventions and edge cases
- **test**: add 3 tests for monolithic barrel detection in data/domain/ui layers
- **test**: add 19 tests for split barrel self-import detection covering:
  - All three layers (data, domain, ui) with both naming conventions (`feature_xxx/` and `features/xxx/`)
  - Both package and relative imports for violations
  - Allowed cross-layer imports (data→domain, ui→domain, ui→data) with both import styles
  - Domain layer correctly blocked from importing ui/data barrels (verified by `avoid_improper_layer_import` rule)

## [1.0.5] - 2025-12-05

- **feat(rules)**: add `avoid_flutter_in_domain` rule to enforce framework independence in domain/data layers by preventing Flutter imports
- **feat(rules)**: add `avoid_improper_layer_import` rule to enforce clean architecture layer boundaries (UI → Data → Domain)
- **feat(quickfix)**: add quick fix to suggest layer-specific barrel imports (e.g., `xxx_data.dart` instead of `xxx.dart`) when available
- **docs**: add comprehensive documentation and examples for new rules
- **docs**: add "Setting Up Split Barrel Files" guide to README

## [1.0.4] - 2025-11-26

- **feat(rules)**: add `avoid_cross_feature_barrel_exports` rule to ensure barrel files only export from their own feature folder
- **feat(rules)**: add `avoid_barrel_cycle` rule to detect immediate circular dependencies between barrel files
- **feat(cli)**: add `check_cycles` CLI tool for detecting transitive circular dependencies (A → B → C → A)
- **feat(quickfix)**: add quick fix to remove cross-feature exports from barrel files
- **feat(quickfix)**: add `RemoveSelfBarrelImport` quick fix for circular self-imports
- **feat(quickfix)**: add `SimplifyRelativePath` quick fix for redundant relative paths within same feature
- **fix(rules)**: `avoid_self_barrel_import` now correctly handles relative imports at different directory depths (e.g., `import '../item.dart'` from `feature_store/data/models/legacy/` correctly distinguishes between barrel and sibling files)
- **test**: add 5 tests for relative import depth detection to verify barrel vs sibling file distinction
- **test**: add 6 tests for barrel cycle detection (immediate 2-node cycles)
- **test**: add 18 comprehensive tests for cross-feature barrel exports rule
- **docs**: reorganize README structure for better UX (Installation and Configuration before Rules)
- **docs**: consolidate Installation and Configuration Presets into unified "Getting Started" section
- **docs**: simplify configuration to single example with inline comments (removed redundant Strict/Moderate/Conservative presets)
- **docs**: update example.md to include all 5 rules with violation examples
- **docs**: add CLI tool documentation and CI/CD integration examples
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
