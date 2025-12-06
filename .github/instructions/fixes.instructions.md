---
description: Best practices for writing quick fixes with Dart 3.10+ analyzer plugin
applyTo: "lib/src/fixes/*.dart"
---

# Quick Fix Best Practices

Guidelines for creating quick fixes in this Dart 3.10+ analyzer plugin using `analyzer_plugin` and `analysis_server_plugin` APIs.

## Fix Structure

### Minimal Fix Template

```dart
import 'package:analysis_server_plugin/edit/dart/correction_producer.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Brief description of what this fix does.
///
/// Detailed explanation of the transformation, including what input
/// it handles and what output it produces. Use examples in dartdoc.
///
/// For example, converts `import 'package:myapp/feature_auth/data/auth_service.dart';`
/// to `import 'package:myapp/feature_auth/auth.dart';`.
class MyFix extends ResolvedCorrectionProducer {
  /// Creates a fix instance for the current resolution context.
  MyFix({required super.context});

  /// FixKind with unique ID, priority, and user-facing message.
  static const _fixKind = FixKind(
    'barrel_file_lints.fix.myFix',
    50, // Priority: 0-100, higher = shown first
    'Fix description shown to user',
  );

  @override
  CorrectionApplicability get applicability =>
      CorrectionApplicability.singleLocation;

  @override
  FixKind get fixKind => _fixKind;

  @override
  Future<void> compute(ChangeBuilder builder) async {
    final node = this.node;
    
    // Validate node type
    if (node is! ImportDirective) return;
    
    final uri = node.uri.stringValue;
    if (uri == null) return;
    
    // Calculate new URI
    final newUri = _calculateNewUri(uri);
    if (newUri == null) return;
    
    // Apply the fix
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(
        range.node(node.uri),
        "'$newUri'",
      );
    });
  }
  
  String? _calculateNewUri(String uri) {
    // Fix-specific logic here
    return null;
  }
}
```

## Core Principles

### 1. Fix Registration

Register fixes in `lib/barrel_file_lints.dart` with their corresponding rule:

```dart
@override
void register(PluginRegistry registry) {
  // Register rule
  registry.registerLintRule(MyRule());
  
  // Register fix for that rule's diagnostic code
  registry.registerFixForRule(MyRule.code, MyFix.new);
}
```

### 2. FixKind Priorities

Priority determines the order fixes are shown to users (0-100):

```dart
// Priority guidelines:
static const _fixKind = FixKind(
  'barrel_file_lints.fix.replaceWithBarrel',
  50, // Standard priority for most fixes
  'Replace with barrel file import',
);

static const _criticalFixKind = FixKind(
  'barrel_file_lints.fix.removeCritical',
  80, // Higher = shown first (critical/urgent fixes)
  'Remove blocking import',
);

static const _minorFixKind = FixKind(
  'barrel_file_lints.fix.simplifyPath',
  30, // Lower = shown later (nice-to-have improvements)
  'Simplify relative path',
);
```

**Priority ranges:**
- **80-100**: Critical/urgent fixes (breaking issues, security)
- **50-79**: Standard fixes (most common use case)
- **20-49**: Improvement fixes (nice-to-have)
- **0-19**: Style/preference fixes

### 3. Node Validation

**✅ DO:**
- Type-check nodes before casting
- Null-check all node properties
- Return early if fix can't apply
- Validate prerequisites before making changes

**❌ DON'T:**
- Force-cast without checking (`as`)
- Assume properties are non-null
- Apply changes to invalid nodes

```dart
// ✅ Good: Proper validation
@override
Future<void> compute(ChangeBuilder builder) async {
  final node = this.node;
  
  // Type check before casting
  if (node is! ImportDirective) return;
  
  // Null check properties
  final uri = node.uri.stringValue;
  if (uri == null) return;
  
  final element = node.element;
  if (element == null) return;
  
  // Now safe to proceed
  final newUri = _buildBarrelUri(uri);
  if (newUri == null) return; // Fix can't apply
  
  await _applyFix(builder, node, newUri);
}

// ❌ Bad: Unsafe assumptions
@override
Future<void> compute(ChangeBuilder builder) async {
  final node = this.node as ImportDirective; // ❌ May throw
  final uri = node.uri.stringValue!; // ❌ May throw
  
  await _applyFix(builder, node, uri); // ❌ Unsafe
}
```

### 4. URI Transformations

Support both naming conventions in all transformations:

```dart
// ✅ Good: Handles both patterns
String? _buildBarrelUri(String uri) {
  // Try underscore pattern: feature_xxx/
  final underscoreMatch = RegExp(r'^(.*?)(feature_([^/]+))/.+$')
      .firstMatch(uri);
  if (underscoreMatch != null) {
    final prefix = underscoreMatch.group(1)!;
    final featureDir = underscoreMatch.group(2)!;
    final featureName = underscoreMatch.group(3)!;
    return '$prefix$featureDir/$featureName.dart';
  }
  
  // Try slash pattern: features/xxx/
  final slashMatch = RegExp(r'^(.*?)(features/([^/]+))/.+$')
      .firstMatch(uri);
  if (slashMatch != null) {
    final prefix = slashMatch.group(1)!;
    final featureDir = slashMatch.group(2)!;
    final featureName = slashMatch.group(3)!;
    return '$prefix$featureDir/$featureName.dart';
  }
  
  return null; // Can't build barrel URI
}
```

### 5. Change Application

Use ChangeBuilder correctly:

```dart
// ✅ Good: Proper change application
@override
Future<void> compute(ChangeBuilder builder) async {
  final node = this.node;
  if (node is! ImportDirective) return;
  
  final newUri = _calculateNewUri(node);
  if (newUri == null) return;
  
  await builder.addDartFileEdit(file, (builder) {
    // Replace just the URI string (between quotes)
    builder.addSimpleReplacement(
      range.node(node.uri),
      "'$newUri'",
    );
  });
}

// For removing entire statements
await builder.addDartFileEdit(file, (builder) {
  builder.addDeletion(range.node(node));
});

// For commenting out
await builder.addDartFileEdit(file, (builder) {
  builder.addSimpleInsertion(
    node.offset,
    '// TODO: Refactor - ',
  );
});
```

### 6. Feature Extraction

Use shared utilities for consistency:

```dart
import 'package:barrel_file_lints/src/utils/feature_pattern_utils.dart';

// ✅ Good: Use shared utility
String? _buildBarrelUri(String uri) {
  final feature = extractFeature(uri);
  if (feature == null) return null;
  
  // Build barrel URI using extracted feature info
  return _buildUri(uri, feature.featureDir, feature.featureName);
}

// ❌ Bad: Duplicate extraction logic
String? _buildBarrelUri(String uri) {
  // ❌ Duplicating pattern matching logic
  final match = RegExp(r'feature_([^/]+)').firstMatch(uri);
  // ...
}
```

## Fix Types

### 1. Simple Replacement

Replace one string with another:

```dart
// Example: Replace internal import with barrel
await builder.addDartFileEdit(file, (builder) {
  builder.addSimpleReplacement(
    range.node(node.uri),
    "'$newBarrelUri'",
  );
});
```

### 2. Deletion

Remove a statement entirely:

```dart
// Example: Remove invalid export
await builder.addDartFileEdit(file, (builder) {
  builder.addDeletion(range.node(node));
});
```

### 3. Insertion

Add new text at a position:

```dart
// Example: Comment out problematic import
await builder.addDartFileEdit(file, (builder) {
  builder.addSimpleInsertion(
    node.offset,
    '// TODO: Refactor dependency - ',
  );
});
```

### 4. Complex Transformation

Multiple changes in sequence:

```dart
await builder.addDartFileEdit(file, (builder) {
  // Replace import
  builder.addSimpleReplacement(
    range.node(node.uri),
    "'$newUri'",
  );
  
  // Add comment explaining the change
  builder.addSimpleInsertion(
    node.offset,
    '// Fixed by barrel_file_lints\n',
  );
});
```

## Package vs Relative Imports

Handle both import styles:

```dart
String _convertToPackageImport(String relativeUri, String currentFile) {
  // Determine package name from pubspec or file structure
  final packageName = _getPackageName(currentFile);
  
  // Calculate the target file's package path
  final targetPath = _resolveRelativePath(currentFile, relativeUri);
  
  // Build package URI
  return 'package:$packageName/$targetPath';
}

String _convertToRelativeImport(String packageUri, String currentFile) {
  // Extract file path from package URI
  final filePath = packageUri.replaceFirst('package:', '');
  
  // Calculate relative path from current file
  final relativePath = _calculateRelativePath(currentFile, filePath);
  
  return relativePath;
}
```

## Testing Quick Fixes

Test that fixes:

1. **Are registered correctly** with rules
2. **Transform code correctly** (before/after verification)
3. **Handle both naming conventions**
4. **Produce valid, compilable code**
5. **Work with package and relative imports**

```dart
// Example from test/quick_fixes_test.dart
test('ReplaceWithBarrelImport fix transforms code correctly', () {
  final before = "import 'package:test/feature_auth/data/service.dart';";
  final after = "import 'package:test/feature_auth/auth.dart';";
  
  // Verify transformation logic
  expect(transformUri(before), equals(after));
});
```

## Common Patterns

### Pattern: Convert Relative to Package

```dart
String? _convertToPackageImport(String relativeUri) {
  if (!relativeUri.startsWith('../')) return null;
  
  // Extract feature from relative path
  final featureMatch = RegExp(r'\.\./(feature_\w+|\w+)/(\w+)\.dart')
      .firstMatch(relativeUri);
  if (featureMatch == null) return null;
  
  final featureDir = featureMatch.group(1)!;
  final featureName = featureMatch.group(2)!;
  
  return 'package:$packageName/$featureDir/$featureName.dart';
}
```

### Pattern: Simplify Redundant Path

```dart
String? _simplifyPath(String uri) {
  // Match patterns like: ../../feature_auth/data/file.dart
  // When we're already in: feature_auth/ui/
  // Simplify to: ../data/file.dart
  
  final pattern = RegExp(r'(\.\./)*(\w+)/(.+)$');
  final match = pattern.firstMatch(uri);
  if (match == null) return null;
  
  // Calculate minimum path needed
  return _calculateMinimalPath(uri, currentFeature);
}
```

### Pattern: Replace with Layer-Specific Barrel

```dart
String? _useLayerBarrel(String uri, String layer) {
  final feature = extractFeature(uri);
  if (feature == null) return null;
  
  // Build layer-specific barrel: feature_xxx/xxx_data.dart
  return 'package:$packageName/${feature.featureDir}/'
      '${feature.featureName}_$layer.dart';
}
```

## Error Handling

Fixes should fail gracefully:

```dart
// ✅ Good: Graceful failure
@override
Future<void> compute(ChangeBuilder builder) async {
  try {
    final newUri = _buildUri(node);
    if (newUri == null) return; // Can't apply fix
    
    await _applyChange(builder, newUri);
  } catch (e) {
    // Log error but don't throw - analyzer handles gracefully
    return;
  }
}

// ❌ Bad: Throws exceptions
@override
Future<void> compute(ChangeBuilder builder) async {
  final newUri = _buildUri(node)!; // ❌ May throw
  await _applyChange(builder, newUri); // ❌ May fail
}
```

## Documentation

Add dartdoc comments to:
- The fix class (explain transformation)
- Complex helper methods
- Any non-obvious logic

Example:

```dart
/// Replaces internal feature imports with barrel file imports.
///
/// Maintains feature encapsulation by using public barrel APIs. For example,
/// converts `import 'package:myapp/feature_auth/data/auth_service.dart';` to
/// `import 'package:myapp/feature_auth/auth.dart';`.
class ReplaceWithBarrelImport extends ResolvedCorrectionProducer {
  // ...
}
```

## Common Pitfalls

### ❌ Not Handling Both Import Styles

```dart
// ❌ BAD: Only handles package imports
String? _buildBarrelUri(String uri) {
  if (!uri.startsWith('package:')) return null; // ❌ Misses relative
  // ...
}
```

**Solution:** Check for both `package:` and `../` patterns

### ❌ Not Validating Result

```dart
// ❌ BAD: Doesn't verify the fix is valid
await builder.addDartFileEdit(file, (builder) {
  builder.addSimpleReplacement(
    range.node(node.uri),
    "'$newUri'", // ❌ What if newUri is malformed?
  );
});
```

**Solution:** Validate newUri before applying

### ❌ Incorrect Range

```dart
// ❌ BAD: Wrong range
builder.addSimpleReplacement(
  range.node(node), // ❌ Replaces entire import directive
  "'$newUri'",
);
```

**Solution:** Use `range.node(node.uri)` for just the URI string

## Related

- Rules: See `.github/instructions/rules.instructions.md`
- Testing: See `test/quick_fixes_test.dart` and `test/quick_fix_application_test.dart`
- Utils: See `lib/src/utils/feature_pattern_utils.dart`

---

**Last Updated:** December 2025
