---
description: Best practices for writing tests in this Dart 3.10+ analyzer plugin
applyTo: "test/**/*_test.dart"
---

# Testing Best Practices

Guidelines for writing comprehensive tests for lint rules, quick fixes, and utilities in this analyzer plugin.

## Test Framework

This project uses:

- **analyzer_testing** ^0.1.7 - For rule integration tests
- **test** ^1.24.0 - Core testing framework
- **test_reflective_loader** ^0.4.0 - Test discovery and organization

**Important:** The `runTests` tool does NOT work with `analyzer_testing`. Always use `dart test` command.

## Test Structure

### Directory Organization

```
test/
├── src/
│   ├── rules/           # Rule tests (analyzer_testing)
│   │   ├── avoid_core_importing_features_test.dart
│   │   ├── avoid_internal_feature_imports_test.dart
│   │   └── ...
│   └── fixes/           # Quick fix tests
│       ├── quick_fixes_test.dart          # Registration & logic
│       └── quick_fix_application_test.dart # Full integration
└── utils/               # Utility and CLI tests
    └── cli_check_cycles_test.dart
```

## Rule Tests (analyzer_testing)

### Minimal Rule Test Template

```dart
/// Tests for my_rule
///
/// Test organization:
/// - Valid cases: No diagnostics expected
/// - Invalid cases: Diagnostics expected with exact locations
/// - Coverage: Both naming conventions, edge cases, relative imports

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MyRuleTest);
  });
}

@reflectiveTest
class MyRuleTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = MyRule();
    super.setUp();
  }

  // ==========================================================================
  // Valid cases - no diagnostics expected
  // ==========================================================================

  Future<void> test_validCase_description() async {
    newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/auth.dart';

class HomePage {}
''');

    await assertNoDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
    );
  }

  // ==========================================================================
  // Invalid cases - diagnostics expected
  // ==========================================================================

  Future<void> test_invalidCase_description() async {
    newFile('$testPackageRootPath/lib/feature_auth/data/auth_service.dart', '''
class AuthService {}
''');

    newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/auth_service.dart';

class HomePage {}
''');

    await assertDiagnosticsInFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      [
        lint(25, 58), // offset (character position), length
      ],
    );
  }
}
```

### Critical Rule Testing Patterns

#### 1. Test Both Naming Conventions

**✅ DO:** Test `feature_xxx/` and `features/xxx/` for every rule

```dart
Future<void> test_underscoreStyle_feature() async {
  // Test with feature_auth/ pattern
  newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''...''');
  await assertNoDiagnosticsInFile('...');
}

Future<void> test_slashStyle_feature() async {
  // Test with features/auth/ pattern
  newFile('$testPackageRootPath/lib/features/auth/auth.dart', '''...''');
  await assertNoDiagnosticsInFile('...');
}
```

#### 2. Test Valid and Invalid Cases

**Valid cases** ensure the rule doesn't have false positives:

```dart
Future<void> test_allowsSameFeatureImports() async {
  newFile('$testPackageRootPath/lib/feature_auth/data/service.dart', '''
class AuthService {}
''');

  newFile('$testPackageRootPath/lib/feature_auth/ui/login_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/service.dart';

class LoginPage {}
''');

  // Should NOT trigger diagnostic (same feature)
  await assertNoDiagnosticsInFile(
    '$testPackageRootPath/lib/feature_auth/ui/login_page.dart',
  );
}
```

**Invalid cases** ensure the rule catches violations:

```dart
Future<void> test_flagsCrossFeatureInternalImport() async {
  newFile('$testPackageRootPath/lib/feature_auth/data/service.dart', '''
class AuthService {}
''');

  newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/service.dart';

class HomePage {}
''');

  // SHOULD trigger diagnostic (cross-feature internal import)
  await assertDiagnosticsInFile(
    '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
    [
      lint(25, 55), // offset, length
    ],
  );
}
```

#### 3. Test Relative Imports

```dart
Future<void> test_relativeImport_parentDirectory() async {
  newFile('$testPackageRootPath/lib/feature_auth/data/service.dart', '''
class AuthService {}
''');

  newFile('$testPackageRootPath/lib/feature_home/ui/home_page.dart', '''
// ignore: unused_import
import '../../feature_auth/data/service.dart';

class HomePage {}
''');

  await assertDiagnosticsInFile(
    '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
    [
      lint(25, 48), // offset, length
    ],
  );
}
```

#### 4. Test Edge Cases

```dart
Future<void> test_deepNestedImport() async {
  // Test imports from deeply nested directories
}

Future<void> test_barrelFileItself() async {
  // Test imports of the barrel file itself
}

Future<void> test_nullUri() async {
  // Test handling of null URIs (defensive coding)
}

Future<void> test_malformedUri() async {
  // Test handling of malformed import strings
}
```

#### 5. Test File Exclusions

```dart
Future<void> test_ignoresTestFiles() async {
  newFile('$testPackageRootPath/lib/feature_auth/data/service.dart', '''
class AuthService {}
''');

  // Test file in test/ directory
  newFile('$testPackageRootPath/test/feature_home/home_test.dart', '''
// ignore: unused_import
import 'package:test/feature_auth/data/service.dart';

void main() {}
''');

  // Should NOT trigger diagnostic (test file excluded)
  await assertNoDiagnosticsInFile(
    '$testPackageRootPath/test/feature_home/home_test.dart',
  );
}
```

### Understanding analyzer_testing API

#### `newFile(path, content)`

Creates a file in the test virtual file system:

```dart
newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''
class AuthService {}
''');
```

#### `assertNoDiagnosticsInFile(path)`

Verifies no lint warnings in the file:

```dart
await assertNoDiagnosticsInFile(
  '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
);
```

#### `assertDiagnosticsInFile(path, diagnostics)`

Verifies expected lint warnings:

```dart
await assertDiagnosticsInFile(
  '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
  [
    lint(25, 58), // offset (0-based), length
  ],
);
```

**Finding offset/length:**

1. Count characters from file start to import URI opening quote (0-based)
2. Count characters in the entire import URI string including quotes

Example:

```dart
'''
// ignore: unused_import\\n    // Line 1: 24 chars including newline
import 'package:test/feature_auth/data/service.dart';  // Line 2
//      ^--- offset 25 (count from start of file)
//      <---------- 58 characters ---------->
// Count the string 'package:test/feature_auth/data/service.dart' = 58 chars
'''
```

## Quick Fix Tests

### Test Organization

Two types of quick fix tests:

1. **Registration & Logic Tests** (`quick_fixes_test.dart`)

   - Verify fixes are registered
   - Test URI transformation logic
   - No file system needed

2. **Integration Tests** (`quick_fix_application_test.dart`)
   - Verify fixes are offered
   - Test actual code transformations
   - Uses analyzer_testing file system

### Registration Test Template

```dart
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test/test.dart';

void main() {
  group('Quick Fix Registration', () {
    test('MyFix is registered with plugin', () {
      final plugin = BarrelFileLintPlugin();
      expect(plugin, isNotNull);
    });

    test('MyFix class exists and is accessible', () {
      expect(MyFix, isNotNull);
      expect(MyRule.code.name, 'my_rule_name');
    });
  });

  group('Fix Logic - URI Transformations', () {
    test('transforms underscore style correctly', () {
      const input = 'package:test/feature_auth/data/service.dart';
      const expected = 'package:test/feature_auth/auth.dart';

      // Test the regex pattern used in the fix
      final match = RegExp(r'^(.*?)(feature_([^/]+))/.+$').firstMatch(input);
      expect(match, isNotNull);

      if (match != null) {
        final prefix = match.group(1)!;
        final featureDir = match.group(2)!;
        final featureName = match.group(3)!;
        final result = '$prefix$featureDir/$featureName.dart';
        expect(result, expected);
      }
    });

    test('transforms slash style correctly', () {
      const input = 'package:test/features/auth/data/service.dart';
      const expected = 'package:test/features/auth/auth.dart';

      final match = RegExp(r'^(.*?)(features/([^/]+))/.+$').firstMatch(input);
      expect(match, isNotNull);

      if (match != null) {
        final prefix = match.group(1)!;
        final featureDir = match.group(2)!;
        final featureName = match.group(3)!;
        final result = '$prefix$featureDir/$featureName.dart';
        expect(result, expected);
      }
    });

    test('handles relative imports', () {
      const input = '../feature_auth/data/service.dart';
      const expected = '../feature_auth/auth.dart';

      // Test relative path transformation
      final match = RegExp(r'^(\.\./)+(feature_([^/]+))/.+$').firstMatch(input);
      expect(match, isNotNull);
    });

    test('returns null for non-feature imports', () {
      const input = 'package:test/common/utils.dart';

      final match = RegExp(r'^(.*?)(feature_([^/]+))/.+$').firstMatch(input);
      expect(match, isNull); // Should not match
    });
  });
}
```

### Integration Test Template

```dart
/// Tests verifying quick fixes produce correct code transformations
///
/// Uses analyzer_testing file system to:
/// 1. Create files with violations
/// 2. Verify diagnostics are reported
/// 3. Verify fixes are available
/// 4. Apply fixes and validate results

import 'package:analyzer_testing/analysis_rule/analysis_rule.dart';
import 'package:barrel_file_lints/barrel_file_lints.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MyFixApplicationTest);
  });
}

@reflectiveTest
class MyFixApplicationTest extends AnalysisRuleTest {
  @override
  void setUp() {
    rule = MyRule();
    super.setUp();
  }

  Future<void> test_fixAppliesCorrectly() async {
    // Create files with violations
    newFile('$testPackageRootPath/lib/feature_auth/data/service.dart', '''
class AuthService {}
''');

    final testFile = newFile(
      '$testPackageRootPath/lib/feature_home/ui/home_page.dart',
      '''
// ignore: unused_import
import 'package:test/feature_auth/data/service.dart';

class HomePage {}
''',
    );

    // Verify diagnostic is present
    await assertDiagnosticsInFile(
      testFile.path,
      [
        lint(25, 58), // offset, length
      ],
    );

    // Apply fix and verify result
    // Note: Full fix application requires IDE integration
    // This test verifies the infrastructure is correct
  }
}
```

## Utility and CLI Tests

### CLI Test Template

```dart
/// Tests for CLI utility
///
/// Tests command-line tools that don't use analyzer_testing

import 'dart:io';
import 'package:test/test.dart';

void main() {
  group('CLI Tool', () {
    test('detects cycles correctly', () {
      // Test CLI logic
      expect(detectCycle(['a', 'b', 'a']), isTrue);
      expect(detectCycle(['a', 'b', 'c']), isFalse);
    });

    test('handles file not found', () {
      // Test error handling
      expect(
        () => processFile('nonexistent.dart'),
        throwsA(isA<FileSystemException>()),
      );
    });

    test('parses command line arguments', () {
      // Test argument parsing
      final args = parseArgs(['--verbose', 'lib/']);
      expect(args.verbose, isTrue);
      expect(args.path, 'lib/');
    });
  });
}
```

## Test Coverage Requirements

Every new rule or fix MUST have tests covering:

### For Rules

- ✅ **Valid cases** (no false positives)

  - Same feature imports
  - Barrel file imports
  - Non-feature imports
  - Test file imports (excluded)

- ✅ **Invalid cases** (catches violations)

  - Cross-feature internal imports
  - Direct internal imports
  - Both naming conventions
  - Package and relative imports

- ✅ **Edge cases**
  - Deeply nested paths
  - Null/malformed URIs
  - Barrel file self-imports
  - Root-level imports

### For Quick Fixes

- ✅ **Registration**

  - Fix is registered with rule
  - Fix class is accessible
  - FixKind metadata is correct

- ✅ **Logic**

  - URI transformations work correctly
  - Both naming conventions handled
  - Package and relative imports supported
  - Invalid cases return null

- ✅ **Integration** (if possible)
  - Fix is offered for diagnostics
  - Applied fix produces valid code
  - Fix handles edge cases gracefully

## Running Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/src/rules/my_rule_test.dart

# Run with coverage
dart test --coverage

# Run tests matching pattern
dart test --name "underscore style"

# Verbose output
dart test --reporter expanded
```

## Common Test Pitfalls

### ❌ Not Using testPackageRootPath

```dart
// ❌ BAD: Hardcoded path
newFile('/lib/feature_auth/auth.dart', '''...''');

// ✅ GOOD: Use testPackageRootPath
newFile('$testPackageRootPath/lib/feature_auth/auth.dart', '''...''');
```

### ❌ Wrong Offset/Length

```dart
// ❌ BAD: Incorrect offset calculation
lint(10, 10), // Wrong offset

// ✅ GOOD: Count carefully from file content
lint(25, 58), // Matches actual import location (offset 25, length 58)
```

### ❌ Forgetting Both Naming Conventions

```dart
// ❌ BAD: Only tests one pattern
test('feature import works', () {
  // Only tests feature_xxx/
});

// ✅ GOOD: Tests both patterns
test('feature import works - underscore style', () { });
test('feature import works - slash style', () { });
```

### ❌ Not Testing Relative Imports

```dart
// ❌ BAD: Only tests package imports
test('invalid import', () {
  // import 'package:test/...'
});

// ✅ GOOD: Tests both import styles
test('invalid package import', () { });
test('invalid relative import', () { });
```

### ❌ Not Testing Test File Exclusion

```dart
// ❌ BAD: Assumes test files are excluded
// No test verifying exclusion

// ✅ GOOD: Explicitly tests exclusion
test('ignores test files', () {
  newFile('$testPackageRootPath/test/my_test.dart', '''...''');
  await assertNoDiagnosticsInFile('...');
});
```

## Test Documentation

Add descriptive comments to test classes:

```dart
/// Tests for avoid_internal_feature_imports rule
///
/// Test organization:
/// - Valid cases: Same-feature imports, barrel imports, test files
/// - Invalid cases: Cross-feature internal imports (both naming conventions)
/// - Edge cases: Relative imports, deeply nested paths, null URIs
///
/// Coverage: All internal directory patterns, both feature styles,
/// package and relative imports
@reflectiveTest
class AvoidInternalFeatureImportsTest extends AnalysisRuleTest {
  // ...
}
```

## Test Naming Conventions

Use clear, descriptive test names:

```dart
// ✅ GOOD: Clear what's being tested
Future<void> test_allowsSameFeatureInternalImports() async { }
Future<void> test_flagsCrossFeatureInternalImports() async { }
Future<void> test_underscoreStyle_barrelImport() async { }
Future<void> test_slashStyle_relativeImport() async { }

// ❌ BAD: Vague test names
Future<void> test_import1() async { }
Future<void> test_works() async { }
```

## Related

- Rules: See `.github/instructions/rules.instructions.md`
- Fixes: See `.github/instructions/fixes.instructions.md`
- Test framework: `analyzer_testing` package documentation
- Test discovery: `test_reflective_loader` package

---

**Last Updated:** December 2025
