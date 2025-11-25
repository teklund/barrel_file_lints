# GitHub Copilot Instructions for Barrel File Lints

## Project Overview

This is a Dart 3.10+ analyzer plugin that enforces barrel file import rules for feature-based Flutter architecture. It uses the native `analysis_server_plugin` API (not custom_lint).

## Key Technologies

- **Dart SDK**: ^3.10.0 (minimum requirement)
- **analysis_server_plugin**: ^0.3.4 (native analyzer plugin API, not custom_lint)
- **analyzer**: ^9.0.0 (must match Dart SDK version - lockstep with 3.10.0)
- **analyzer_plugin**: ^0.13.11 (utilities for plugin development)
- **Testing**: analyzer_testing ^0.1.7, test ^1.24.0, test_reflective_loader ^0.4.0

## Architecture Patterns

### Feature Structure Supported

```
lib/
├── feature_xxx/          # Underscore style
│   ├── xxx.dart         # Barrel file
│   ├── data/
│   ├── ui/
│   └── models/
└── features/xxx/         # Clean architecture style
    ├── xxx.dart         # Barrel file
    ├── domain/
    ├── presentation/
    └── infrastructure/
```

### Core Principles

1. **Features import other features ONLY via barrel files**
2. **Core module must never import from features**
3. **Test files are always excluded from checks**
4. **Both naming conventions must be supported**

## Code Style

- Use Dart 3.10+ features (records, patterns, etc.)
- Follow `package:lints/recommended.yaml`
- Constructor-first organization in classes
- Prefer expression bodies for simple getters
- Use cascades for multiple operations on same object
- Static const for LintCode definitions

## Lint Rule Structure

```dart
class MyRule extends AnalysisRule {
  /// Constructor with description
  MyRule() : super(name: '...', description: '...');

  /// Static LintCode constant
  static const LintCode code = LintCode(...);

  @override
  LintCode get diagnosticCode => code;

  @override
  void registerNodeProcessors(
    RuleVisitorRegistry registry,
    RuleContext context,
  ) {
    registry.addImportDirective(this, _MyVisitor(this, context));
  }
}
```

## Quick Fix Structure

```dart
class MyQuickFix extends ResolvedCorrectionProducer {
  /// Static FixKind with unique ID, priority, and message
  static final fixKind = FixKind('my_fix', 50, "Fix description");

  @override
  Future<void> compute(ChangeBuilder builder) async {
    // Use builder to apply edits to the file
    await builder.addDartFileEdit(file, (builder) {
      builder.addSimpleReplacement(range, 'new code');
    });
  }
}

// Register in Plugin.register():
registry.registerFixForRule(MyRule.code, MyQuickFix.new);
```

## Testing Approach

- Use `analyzer_testing` package for rule tests
- Use `test_reflective_loader` for test discovery
- Test both naming conventions (`feature_xxx/` and `features/xxx/`)
- Test relative imports (`../`, `../../`)
- Test internal directories (data/, ui/, domain/, presentation/, etc.)
- Test exclusions (test files, test_driver/, integration_test/)
- Test quick fixes verify they're registered and functional

## Important Context

- **lib/main.dart** is REQUIRED per official docs (Analysis Server entry point)
  - Must have top-level `plugin` variable
  - Example: `final plugin = BarrelFileLintPlugin();`
  - Analysis Server generates code that imports this and references `plugin`
- **lib/barrel_file_lints.dart** contains all implementation
- Plugin registration happens in `BarrelFileLintPlugin.register(PluginRegistry)`
  - Use `registry.registerLintRule(rule)` for rules
  - Use `registry.registerFixForRule(code, producer)` for quick fixes
- Rules and quick fixes are separate concerns
- Feature detection uses regex: `feature_([^/]+)` and `features/([^/]+)`
- Cannot use `print()` for debugging - write to log files instead

## Common Patterns

### Feature Extraction

```dart
final underscoreMatch = RegExp(r'feature_([^/]+)').firstMatch(path);
final slashMatch = RegExp(r'features/([^/]+)').firstMatch(path);
```

### Test File Detection

```dart
bool _isTestFile(String path) =>
    path.contains('/test/') ||
    path.contains('/test_driver/') ||
    path.contains('/integration_test/') ||
    path.endsWith('_test.dart');
```

### Internal Import Detection

```dart
bool _isInternalImport(String uri) =>
    uri.contains('/data/') ||
    uri.contains('/ui/') ||
    uri.contains('/domain/') ||
    uri.contains('/presentation/') ||
    // ... etc
```

## Workflows

- **ci.yml**: Format, analyze, test, coverage, publish dry-run, pana
- **publish.yml**: Tag-triggered automated publishing with version verification
- **lint_pr.yml**: PR title validation (Conventional Commits)
- **commit_lint.yml**: Commit message validation

## Conventional Commits

All commits and PR titles must follow:

- `feat:` - New features
- `fix:` - Bug fixes
- `docs:` - Documentation
- `test:` - Tests
- `refactor:` - Refactoring
- `style:` - Formatting
- `chore:` - Maintenance
- `ci:` - CI/CD changes
- `perf:` - Performance
- `build:` - Build system

## When Making Changes

1. Always run tests: `dart test`
2. Always analyze: `dart analyze --fatal-infos`
3. Always format: `dart format .`
4. Update CHANGELOG.md for user-facing changes following Conventional Commits format
5. Follow existing patterns and structure
6. Test both naming conventions
7. Consider backward compatibility

## CHANGELOG.md Format

The CHANGELOG.md follows [Conventional Commits](https://www.conventionalcommits.org/) format with [Semantic Versioning](https://semver.org/):

- Version format: `## [1.0.3] - YYYY-MM-DD`
- Each entry uses conventional commit format: `**type(scope)**: description`
- Types: `feat`, `fix`, `docs`, `test`, `refactor`, `style`, `chore`, `ci`, `perf`, `build`
- Breaking changes: Use `**BREAKING**` prefix or note in description
- Keep entries concise and descriptive
- Link to issues/PRs when relevant (e.g., `([#123](url))`)

**Commit Messages:** Use same [Conventional Commits](https://www.conventionalcommits.org/) format:
- Format: `type(scope): description`
- Breaking changes: Add `!` after type/scope or `BREAKING CHANGE:` in footer
- Example: `feat(rules): add avoid_self_barrel_import rule`

Example changelog:
```markdown
## [1.0.3] - 2025-11-25

- **feat(rules)**: add `avoid_self_barrel_import` rule to prevent circular dependencies
- **feat(config)**: add configuration presets in README
- **fix(config)**: `analysis_options.yaml` now uses root-level `plugins:`
- **docs**: streamline README by merging Quick Fixes into Rules section
```

## Documentation Standards

- Public APIs need dartdoc comments
- Include examples in dartdoc for complex APIs
- Keep README.md up to date with features
- CONTRIBUTING.md explains development workflow
