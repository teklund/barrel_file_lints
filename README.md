# Barrel File Lints

[![pub package](https://img.shields.io/pub/v/barrel_file_lints.svg)](https://pub.dev/packages/barrel_file_lints)
[![CI](https://github.com/teklund/barrel_file_lints/workflows/CI/badge.svg)](https://github.com/teklund/barrel_file_lints/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![codecov](https://codecov.io/gh/teklund/barrel_file_lints/branch/master/graph/badge.svg)](https://codecov.io/gh/teklund/barrel_file_lints)

A Dart 3.10+ analyzer plugin that enforces barrel file import rules for feature-based Flutter architecture.

## Features

- **Native Dart 3.10 analyzer plugin** - No third-party packages needed
- **IDE integration** - Works in VS Code, Android Studio, IntelliJ
- **CI/CD support** - Works with `dart analyze` and `flutter analyze`
- **Configurable** - Enable/disable individual rules
- **Multiple naming conventions** - Supports both `feature_xxx/` and `features/xxx/` patterns

## Rules

### `avoid_internal_feature_imports`

Features must import other features via their barrel file, not internal files.

Supports both naming conventions:

**Underscore style (`feature_xxx/`):**

```dart
// ✅ Correct
import 'package:myapp/feature_auth/auth.dart';

// ❌ Wrong
import 'package:myapp/feature_auth/data/auth_service.dart';
import 'package:myapp/feature_auth/ui/login_page.dart';
```

**Clean architecture style (`features/xxx/`):**

```dart
// ✅ Correct
import 'package:myapp/features/auth/auth.dart';

// ❌ Wrong
import 'package:myapp/features/auth/data/auth_service.dart';
import 'package:myapp/features/auth/presentation/login_page.dart';
```

**Quick Fix:** Replace with barrel file import - automatically converts internal imports to their barrel file equivalent.

### `avoid_core_importing_features`

Core module must not import from feature modules (maintains core independence).

```dart
// In lib/core/some_file.dart

// ✅ Correct - core imports from common
import 'package:myapp/common/widgets.dart';

// ✅ Correct - core imports external packages
import 'package:dio/dio.dart';

// ❌ Wrong - core depending on feature (either style)
import 'package:myapp/feature_auth/auth.dart';
import 'package:myapp/features/auth/auth.dart';
```

**Quick Fix:** Comment out import - adds a TODO comment to remind you to refactor the dependency out of core.

## Quick Fixes

Both rules include IDE quick fixes that appear when you hover over the error:

| Rule | Quick Fix | Description |
|------|-----------|-------------|
| `avoid_internal_feature_imports` | Replace with barrel file import | Converts `feature_auth/data/service.dart` → `feature_auth/auth.dart` |
| `avoid_core_importing_features` | Comment out import | Comments the import with a TODO for refactoring |

### Example

Before quick fix:

```dart
import 'package:myapp/feature_auth/data/auth_service.dart';
```

After applying "Replace with barrel file import":

```dart
import 'package:myapp/feature_auth/auth.dart';
```

## Installation

### From pub.dev

```yaml
# pubspec.yaml
dev_dependencies:
  barrel_file_lints: ^1.0.0
```

### From Git

```yaml
# pubspec.yaml
dev_dependencies:
  barrel_file_lints:
    git:
      url: https://github.com/user/barrel_file_lints.git
      ref: main
```

## Configuration

Enable the plugin in your `analysis_options.yaml`:

```yaml
analyzer:
  plugins:
    barrel_file_lints:
      diagnostics:
        avoid_internal_feature_imports: true
        avoid_core_importing_features: true
```

Or if using a local path:

```yaml
analyzer:
  plugins:
    barrel_file_lints:
      path: packages/barrel_file_lints
      diagnostics:
        avoid_internal_feature_imports: true
        avoid_core_importing_features: true
```

## Usage

Run analysis:

```bash
flutter analyze
# or
dart analyze
```

## Suppressing Warnings

Suppress for a single line:

```dart
// ignore: barrel_file_lints/avoid_internal_feature_imports
import 'package:myapp/feature_auth/data/auth_service.dart';
```

Suppress for an entire file:

```dart
// ignore_for_file: barrel_file_lints/avoid_internal_feature_imports
```

## Architecture Pattern

This plugin enforces a feature-based architecture pattern with two supported naming conventions:

### Underscore Style (`feature_xxx/`)

```text
lib/
├── core/                 # Core utilities (no feature imports)
├── common/               # Shared widgets/utilities
└── feature_auth/         # Feature modules
    ├── auth.dart         # 🔑 Barrel file (public API)
    ├── data/             # Internal: APIs, repos, services, models
    └── ui/               # Internal: Pages, widgets, dialogs
```

### Clean Architecture Style (`features/xxx/`)

```text
lib/
├── core/                 # Core utilities (no feature imports)
├── common/               # Shared widgets/utilities
└── features/
    └── auth/             # Feature modules
        ├── auth.dart     # 🔑 Barrel file (public API)
        ├── data/         # Internal: repositories, data sources
        ├── domain/       # Internal: entities, use cases
        ├── presentation/ # Internal: pages, widgets, blocs
        └── application/  # Internal: services
```

### Import Rules

1. **Features import other features via barrel files only**
   - `feature_a/` can import `feature_b/b.dart`
   - `features/a/` can import `features/b/b.dart`
   - Cannot import internal paths like `data/`, `ui/`, `domain/`, etc.

2. **Core is independent**
   - `core/` cannot import from any `feature_*/` or `features/*/`
   - Features depend on core, not vice versa

3. **Internal imports within same feature are allowed**
   - `feature_a/ui/page.dart` can import `feature_a/data/service.dart`
   - `features/a/presentation/page.dart` can import `features/a/domain/entity.dart`

4. **Test files are excluded**
   - Files in `test/`, `test_driver/`, `integration_test/` are not checked
   - Files ending with `_test.dart` are not checked
   - Tests need direct access to internal implementations

## Requirements

- Dart SDK ^3.10.0
- Flutter 3.38+

## How It Works

The plugin uses Dart's native analyzer plugin API (introduced in Dart 3.10) to:

1. Register lint rules with the analysis server
2. Visit import directives in your code
3. Check if imports violate barrel file patterns
4. Report diagnostics in your IDE and CLI

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new rules
4. Submit a pull request

## License

MIT License - see [LICENSE](LICENSE) for details.

## Related

- [Dart Analyzer Plugins](https://dart.dev/tools/analyzer-plugins) - Official documentation
- [Feature-based Architecture](https://codewithandrea.com/articles/flutter-project-structure/) - Architecture pattern overview
