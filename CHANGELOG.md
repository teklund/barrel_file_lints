# Changelog

All notable changes to this project will be documented in this file.

## 0.1.0

- Initial release
- Two lint rules:
  - `avoid_internal_feature_imports` - Features must import other features via barrel files only
  - `avoid_core_importing_features` - Core module must not import from feature modules
- Quick fixes:
  - Replace internal import with barrel file import
  - Comment out feature import in core with TODO
- Support for both naming conventions:
  - `feature_xxx/` (underscore style)
  - `features/xxx/` (clean architecture style)
- Works with both absolute (`package:`) and relative (`../`) imports
- Test files are automatically excluded from checks
- Comprehensive test suite with 20 tests
