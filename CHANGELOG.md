# Changelog

All notable changes to this project will be documented in this file.

## 1.0.0 - 2025-11-24

### Added

- Initial stable release
- Two lint rules:
  - `avoid_internal_feature_imports` - Features must import other features via barrel files only
  - `avoid_core_importing_features` - Core module must not import from feature modules
- Quick fixes with IDE integration:
  - Replace internal import with barrel file import
  - Comment out feature import in core with TODO
- Support for both naming conventions:
  - `feature_xxx/` (underscore style)
  - `features/xxx/` (clean architecture style)
- Works with both absolute (`package:`) and relative (`../`) imports
- Test files automatically excluded from checks
- Comprehensive test suite (47 tests across 7 test files)
- Full CI/CD pipeline with GitHub Actions
- Complete documentation and examples
