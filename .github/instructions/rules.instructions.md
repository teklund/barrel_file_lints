---
description: Best practices for writing analyzer plugin lint rules with Dart 3.10+
applyTo: "lib/src/rules/*.dart"
---

# Lint Rule Best Practices

Guidelines for creating lint rules in this Dart 3.10+ analyzer plugin using the `analysis_server_plugin` API.

## Rule Structure

### Minimal Rule Template

```dart
import 'package:analyzer/analysis_rule/analysis_rule.dart';
import 'package:analyzer/analysis_rule/rule_context.dart';
import 'package:analyzer/analysis_rule/rule_visitor_registry.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/error.dart';

/// Brief description of what this rule enforces.
///
/// Detailed explanation including why this rule exists, what it prevents,
/// and how it improves code quality. Include examples in dartdoc.
///
/// For example, instead of importing
/// `package:myapp/feature_auth/data/auth_service.dart`, use the barrel file
/// `package:myapp/feature_auth/auth.dart`.
class MyRule extends AnalysisRule {
  /// Creates a rule instance with default configuration.
  MyRule()
      : super(
          name: 'my_rule_name',
          description: 'One-line description for configuration',
        );

  /// Diagnostic code reported when violation detected.
  static const LintCode code = LintCode(
    'my_rule_name',
    'User-facing error message with context',
    correctionMessage: 'Actionable suggestion: Use barrel import instead',
  );

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    // Register visitor for specific AST node types
    registry.addImportDirective(this, _MyRuleVisitor(this, context));
  }
}

/// Visitor that detects violations of this rule.
class _MyRuleVisitor extends SimpleAstVisitor<void> {
  _MyRuleVisitor(this.rule, this.context);

  final MyRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    // Implement detection logic here
    // Report violations with context.reportError()
  }
}
```

## Core Principles

### 1. Performance First

**✅ DO:**

- Cache regex patterns as static/top-level constants
- Use early returns to avoid unnecessary processing
- Check simple conditions before expensive operations
- Exit early for test files (fastest check)

**❌ DON'T:**

- Create new regex patterns on each invocation
- Perform synchronous file I/O (causes 150-1250ms overhead)
- Do deep AST traversal when not needed
- Process test files (waste of time)

```dart
// ✅ Good: Cached regex, early exit
class MyRule extends AnalysisRule {
  static final _featurePattern = RegExp(r'feature_([^/]+)');

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addImportDirective(this, _Visitor(this, context));
  }
}

class _Visitor extends SimpleAstVisitor<void> {
  _Visitor(this.rule, this.context);

  final MyRule rule;
  final RuleContext context;

  @override
  void visitImportDirective(ImportDirective node) {
    final uri = node.uri.stringValue;
    if (uri == null) return; // Early exit

    // Fast test file check
    final filePath = context.getResolvedUnitResult().path;
    if (_isTestFile(filePath)) return;

    // Now do expensive checks
    if (_featurePattern.hasMatch(uri)) {
      // Process...
    }
  }

  static bool _isTestFile(String path) =>
      path.contains('/test/') ||
      path.contains('/test_driver/') ||
      path.contains('/integration_test/') ||
      path.endsWith('_test.dart');
}

// ❌ Bad: Regex created on every call
void visitImportDirective(ImportDirective node) {
  final pattern = RegExp(r'feature_([^/]+)'); // ❌ Recreated each time
  if (pattern.hasMatch(uri)) {
    // ...
  }
}
```

### 2. Null Safety on AST Nodes

**✅ DO:**

- Always null-check node properties before accessing
- Use null-aware operators (?., ??)
- Provide fallback values for null cases
- Return early on null

**❌ DON'T:**

- Assume node properties are non-null
- Access nested properties without checking each level

```dart
// ✅ Good: Proper null checking
@override
void visitImportDirective(ImportDirective node) {
  final uri = node.uri.stringValue;
  if (uri == null) return; // Guard against null

  final element = node.element;
  if (element == null) return;

  // Safe to use uri and element now
  processImport(uri, element);
}

// ❌ Bad: Assumes non-null
@override
void visitImportDirective(ImportDirective node) {
  final uri = node.uri.stringValue!; // ❌ May throw
  processImport(uri); // ❌ Unsafe
}
```

### 3. Support Both Naming Conventions

**Always support:**

- `feature_xxx/` (underscore style)
- `features/xxx/` (clean architecture style)

```dart
// ✅ Good: Handles both patterns
static final _underscorePattern = RegExp(r'feature_([^/]+)');
static final _slashPattern = RegExp(r'features/([^/]+)');

String? extractFeatureName(String uri) {
  final underscoreMatch = _underscorePattern.firstMatch(uri);
  if (underscoreMatch != null) {
    return underscoreMatch.group(1);
  }

  final slashMatch = _slashPattern.firstMatch(uri);
  if (slashMatch != null) {
    return slashMatch.group(1);
  }

  return null;
}

// ❌ Bad: Only handles one pattern
static final _pattern = RegExp(r'feature_([^/]+)'); // ❌ Misses features/xxx/
```

### 4. Error Messages

**✅ DO:**

- Make messages actionable and specific
- Include the problematic import/export
- Suggest the correct alternative
- Use consistent tone and style

**❌ DON'T:**

- Use vague messages like "Invalid import"
- Omit context about what's wrong
- Use technical jargon without explanation

```dart
// ✅ Good: Clear, actionable message
static const LintCode code = LintCode(
  'avoid_internal_feature_imports',
  "Import '{0}' accesses internal feature implementation. "
      "Use the barrel file instead.",
  correctionMessage: "Replace with 'package:myapp/{1}/{2}.dart'",
);

// Report with context
context.reportError(
  rule.diagnosticCode,
  node,
  errorData: [
    uri, // {0} - shows what's wrong
    featureName, // {1} - helps build fix
    featureName, // {2} - shows correct way
  ],
);

// ❌ Bad: Vague, unhelpful
static const LintCode code = LintCode(
  'bad_import',
  'Invalid import detected', // ❌ Not actionable
);
```

### 5. Test File Exclusions

**Always exclude:**

- `test/` directory
- `test_driver/` directory
- `integration_test/` directory
- Files ending with `_test.dart`

```dart
// ✅ Good: Comprehensive test exclusion
static bool _isTestFile(String path) =>
    path.contains('/test/') ||
    path.contains('/test_driver/') ||
    path.contains('/integration_test/') ||
    path.endsWith('_test.dart');

@override
void visitImportDirective(ImportDirective node) {
  final filePath = context.getResolvedUnitResult().path;
  if (_isTestFile(filePath)) return; // Exit early

  // Rule logic here
}
```

### 6. Internal Directory Detection

Support all common internal directories:

```dart
// ✅ Good: Comprehensive internal directory list
static bool _isInternalImport(String uri) =>
    uri.contains('/data/') ||
    uri.contains('/ui/') ||
    uri.contains('/domain/') ||
    uri.contains('/presentation/') ||
    uri.contains('/infrastructure/') ||
    uri.contains('/application/') ||
    uri.contains('/models/') ||
    uri.contains('/services/') ||
    uri.contains('/repositories/') ||
    uri.contains('/providers/') ||
    uri.contains('/bloc/') ||
    uri.contains('/cubit/') ||
    uri.contains('/notifiers/') ||
    uri.contains('/widgets/') ||
    uri.contains('/utils/') ||
    uri.contains('/helpers/') ||
    uri.contains('/config/') ||
    uri.contains('/exceptions/') ||
    uri.contains('/extensions/');
```

## Registration

Rules are registered in `lib/barrel_file_lints.dart`:

```dart
@override
void register(PluginRegistry registry) {
  registry.registerLintRule(MyRule());
}
```

## Testing

Every rule MUST have tests covering:

1. **Valid cases** - No diagnostics expected
2. **Invalid cases** - Diagnostics expected with exact offsets
3. **Both naming conventions** - `feature_xxx/` and `features/xxx/`
4. **Edge cases** - Test files, relative imports, deep nesting
5. **Same feature** - Imports within same feature (usually allowed)

See `test/*_test.dart` for examples using `analyzer_testing` framework.

## Common Pitfalls

### ❌ File I/O in Hot Path

```dart
// ❌ BAD: Synchronous file I/O causes 150-1250ms overhead
@override
void visitImportDirective(ImportDirective node) {
  final file = File(path);
  if (file.existsSync()) { // ❌ Blocks analyzer
    final content = file.readAsStringSync(); // ❌ Very slow
    // ...
  }
}
```

**Solution:** Use CLI tools for file operations (see `bin/check_cycles.dart`)

### ❌ Deep AST Traversal

```dart
// ❌ BAD: Visiting entire tree
@override
void visitCompilationUnit(CompilationUnit node) {
  node.visitChildren(this); // ❌ Too broad
}
```

**Solution:** Register specific node types you need

### ❌ Not Caching Utilities

```dart
// ❌ BAD: Recreating helper on each call
void visitImportDirective(ImportDirective node) {
  final helper = FeatureHelper(); // ❌ Recreated
  helper.extractFeature(uri);
}
```

**Solution:** Import from `lib/src/utils/` for shared functionality

## Documentation

Add dartdoc comments to:

- The rule class (explain what and why)
- The `LintCode` constant (user-facing message)
- Complex helper methods

Example:

```dart
/// Enforces barrel file imports between features.
///
/// Prevents direct imports into a feature's internal implementation and
/// maintains feature encapsulation by requiring barrel file imports.
/// Supports both `feature_xxx/` (underscore) and `features/xxx/` (clean
/// architecture) naming conventions.
///
/// For example, instead of importing
/// `package:myapp/feature_auth/data/auth_service.dart`, use the barrel file
/// `package:myapp/feature_auth/auth.dart`.
class AvoidInternalFeatureImports extends AnalysisRule {
  // ...
}
```

## Related

- Quick fixes: See `.github/instructions/fixes.instructions.md`
- Testing: See test files in `test/` directory
- Utils: See `lib/src/utils/feature_pattern_utils.dart`

---

**Last Updated:** December 2025
