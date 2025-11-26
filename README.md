# Barrel File Lints

[![pub package](https://img.shields.io/pub/v/barrel_file_lints.svg)](https://pub.dev/packages/barrel_file_lints)
[![CI](https://github.com/teklund/barrel_file_lints/workflows/CI/badge.svg)](https://github.com/teklund/barrel_file_lints/actions)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![codecov](https://codecov.io/gh/teklund/barrel_file_lints/branch/master/graph/badge.svg)](https://codecov.io/gh/teklund/barrel_file_lints)

A Dart 3.10+ analyzer plugin that enforces barrel file import rules for feature-based Flutter architecture.

> **Note:** This plugin requires Dart SDK 3.10.0 or later. Make sure to restart your IDE after installation for the plugin to take effect.

## Table of Contents

- [What are Barrel Files?](#what-are-barrel-files)
- [Why Use This Plugin?](#why-use-this-plugin)
- [Features](#features)
- [Getting Started](#getting-started)
- [Rules](#rules)
- [CLI Tool: Cycle Detection](#cli-tool-cycle-detection)
- [Suppressing Warnings](#suppressing-warnings)
- [Architecture Pattern](#architecture-pattern)
- [Troubleshooting](#troubleshooting)
- [How It Works](#how-it-works)
- [Contributing](#contributing)
- [License](#license)

## What are Barrel Files?

A **barrel file** re-exports the public API of a feature module as a single entry point:

```dart
// feature_auth/auth.dart (barrel file)
export 'data/auth_service.dart';
export 'ui/login_page.dart';
```

This enforces encapsulation and provides clear feature boundaries.

### Trade-offs

**Benefits:**

- Clear architectural boundaries between features
- Explicit public API for each module
- Easier to refactor internal implementations
- Prevents tight coupling

**Considerations:**

- In very large projects, barrel files can impact analyzer performance ([Dart SDK #50369](https://github.com/dart-lang/sdk/issues/50369))
- May introduce false dependency edges
- This plugin is designed for feature-level barrel files (coarse-grained), not component-level exports (fine-grained), which minimizes performance impact

## Why Use This Plugin?

Automatically prevents developers from bypassing barrel files and importing internal feature files directly. Catches violations in your IDE and CI/CD pipeline with zero runtime overhead.

## Features

- Native Dart 3.10 analyzer plugin with IDE integration (VS Code, Android Studio, IntelliJ)
- Works with `dart analyze` and `flutter analyze` for CI/CD
- Configurable rules with automatic quick fixes
- Supports `feature_xxx/` and `features/xxx/` naming conventions

## Getting Started

### Installation

1. Add to `pubspec.yaml`:

   ```yaml
   dev_dependencies:
     barrel_file_lints: ^1.0.0
   ```

2. Install dependencies:

   ```bash
   dart pub get
   # or
   flutter pub get
   ```

3. Restart your IDE for the plugin to take effect.

### Configuration

Enable the rules you want in `analysis_options.yaml`:

```yaml
plugins:
  barrel_file_lints:
    diagnostics:
      # Enforce barrel file imports between features
      avoid_internal_feature_imports: true
      
      # Prevent core module from depending on features
      avoid_core_importing_features: true
      
      # Prevent files from importing their own barrel
      # Set to false if you prefer allowing self-barrel imports
      avoid_self_barrel_import: true
      
      # Prevent barrels from exporting other features
      avoid_cross_feature_barrel_exports: true
      
      # Detect immediate circular dependencies between barrels
      # Use CLI tool for transitive cycle detection
      avoid_barrel_cycle: true
```

**Note:** Rules are disabled by default. Explicitly enable the rules that match your architecture needs.

**Verify it's working** by running `dart analyze` or `flutter analyze`.

## Rules

### `avoid_internal_feature_imports`

Features must import other features via their barrel file only. Supports both `feature_xxx/` and `features/xxx/` naming patterns.

```dart
// ✅ Correct
import 'package:myapp/feature_auth/auth.dart';

// ❌ Wrong - internal imports
import 'package:myapp/feature_auth/data/auth_service.dart';
```

**Quick Fix:** Automatically replaces internal imports with barrel file imports.

### `avoid_core_importing_features`

Core module must not import feature modules to maintain architectural independence.

```dart
// In lib/core/some_file.dart

// ✅ Correct
import 'package:myapp/common/widgets.dart';

// ❌ Wrong - core depending on feature
import 'package:myapp/feature_auth/auth.dart';
```

**Quick Fix:** Comments out the import with a TODO for refactoring.

### `avoid_self_barrel_import`

Files within a feature should not import their own feature's barrel file or use unnecessarily complex relative paths within the same feature. This prevents circular dependencies and enforces direct imports within feature boundaries.

```dart
// In lib/feature_auth/data/auth_service.dart

// ✅ Correct - direct import within same feature
import 'package:myapp/feature_auth/data/user_repository.dart';
import 'extensions/auth_extensions.dart';

// ❌ Wrong - importing own barrel (circular dependency risk)
import 'package:myapp/feature_auth/auth.dart';

// ❌ Wrong - unnecessarily complex relative path within same feature
import '../../feature_auth/data/extensions/auth_extensions.dart';
```

**Quick Fixes:**

- **Remove self-barrel import**: Removes the circular import when importing own barrel
- **Simplify relative path**: Converts redundant paths like `'../../feature_auth/data/file.dart'` → `'file.dart'` or `'data/file.dart'`

### `avoid_cross_feature_barrel_exports`

Barrel files must only export files from their own feature folder. This enforces proper feature boundaries and prevents coupling between features through re-exports.

```dart
// In lib/feature_auth/auth.dart (barrel file)

// ✅ Correct - exporting own feature's files
export 'data/auth_service.dart';
export 'ui/login_page.dart';

// ❌ Wrong - exporting from different feature
export '../feature_users/data/user.dart';

// ❌ Wrong - exporting from outside feature
export '../common/widgets.dart';
```

**Quick Fix:** Removes the cross-feature export directive.

### `avoid_barrel_cycle`

Barrel files should not create immediate circular dependencies where two barrels export each other.

```dart
// In lib/feature_auth/auth.dart
// ❌ Wrong - exports feature_profile barrel
export '../feature_profile/profile.dart';

// In lib/feature_profile/profile.dart
// ❌ Wrong - exports feature_auth barrel (creates cycle)
export '../feature_auth/auth.dart';
```

This rule detects **immediate 2-node cycles** during development. For detecting **transitive cycles** (A → B → C → A), use the [CLI tool](#cli-tool-cycle-detection).

## CLI Tool: Cycle Detection

For comprehensive cycle detection beyond immediate 2-node cycles, use the included CLI tool:

```bash
# Check for all circular dependencies
dart run barrel_file_lints:check_cycles

# Specify a custom directory
dart run barrel_file_lints:check_cycles --lib-dir=packages/my_package/lib

# Verbose output
dart run barrel_file_lints:check_cycles --verbose
```

### CI/CD Integration

Add to your CI pipeline to prevent circular dependencies:

```yaml
# .github/workflows/ci.yml
- name: Check barrel file cycles
  run: dart run barrel_file_lints:check_cycles
```

See [bin/README.md](bin/README.md) for detailed documentation.

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

Enforces feature-based architecture with barrel files:

```text
lib/
├── core/                 # Core utilities (no feature imports allowed)
├── common/               # Shared widgets/utilities
└── feature_auth/         # Feature modules
    ├── auth.dart         # Barrel file (public API)
    ├── data/             # Internal implementation
    └── ui/               # Internal implementation
```

**Rules:**

1. Features import other features via barrel files only (`feature_a/a.dart`)
2. Core cannot import features (maintains independence)
3. Files within same feature use direct imports (not own barrel)
4. Barrel files only export from their own feature folder
5. Test files are excluded from checks

## Troubleshooting

**Plugin not detected?**

- Run `dart pub get` and restart your IDE
- Verify with `dart analyze --verbose` (should list `barrel_file_lints`)

**No diagnostics?**

- Check rules are enabled in `analysis_options.yaml`
- Verify Dart SDK ^3.10.0: `dart --version`
- Test files are excluded by design

## How It Works

The plugin uses Dart's native analyzer plugin API (introduced in Dart 3.10) to:

1. Register lint rules with the analysis server
2. Visit import directives in your code
3. Check if imports violate barrel file patterns
4. Report diagnostics in your IDE and CLI

**Performance:** The plugin adds negligible overhead to analysis time since it only inspects import directives, not the entire AST.

## Contributing

Contributions welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, guidelines, and how to submit pull requests.

## License

MIT License - see [LICENSE](LICENSE) for details.

## Related

- [Dart Analyzer Plugins](https://dart.dev/tools/analyzer-plugins) - Official documentation
- [Feature-based Architecture](https://codewithandrea.com/articles/flutter-project-structure/) - Architecture pattern overview
