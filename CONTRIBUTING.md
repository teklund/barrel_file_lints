# Contributing to Barrel File Lints

Thank you for your interest in contributing! This document provides guidelines for contributing to this project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Workflow](#development-workflow)
- [Commit Message Convention](#commit-message-convention)
- [Making Changes](#making-changes)
- [Project Structure](#project-structure)
- [Writing Lint Rules](#writing-lint-rules)
- [Writing Quick Fixes](#writing-quick-fixes)
- [Testing Guidelines](#testing-guidelines)
- [Submitting Changes](#submitting-changes)
- [Reporting Issues](#reporting-issues)
- [Getting Help](#getting-help)

## Code of Conduct

Be respectful and constructive. We're all here to make better tools.

## Getting Started

### Prerequisites

- [Dart SDK](https://dart.dev/get-dart) 3.10.0 or higher
- Git
- A code editor (VS Code, IntelliJ, Android Studio)

### Development Setup

1. **Fork the repository** on GitHub
2. **Clone your fork** locally:

   ```bash
   git clone https://github.com/YOUR_USERNAME/barrel_file_lints.git
   cd barrel_file_lints
   ```

3. **Install dependencies**:

   ```bash
   dart pub get
   ```

4. **Set up commit message validation** (optional but recommended):

   ```bash
   cp .github/commit-msg .git/hooks/commit-msg
   chmod +x .git/hooks/commit-msg
   ```

5. **Verify the setup** by running tests:

   ```bash
   dart test
   ```

## Development Workflow

### Running Tests

```bash
# Run all tests
dart test

# Run specific test file
dart test test/avoid_internal_feature_imports_test.dart

# Run with coverage
dart test --coverage=coverage
```

### Code Analysis

```bash
# Run analyzer
dart analyze

# Check formatting
dart format --output=none --set-exit-if-changed .

# Fix formatting
dart format .
```

## Commit Message Convention

This project follows [Conventional Commits](https://www.conventionalcommits.org/). All commit messages and PR titles must follow this format:

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

### Types

- **feat**: New feature
- **fix**: Bug fix
- **docs**: Documentation only changes
- **style**: Code style changes (formatting, semicolons, etc.)
- **refactor**: Code refactoring (no functional changes)
- **perf**: Performance improvements
- **test**: Adding or updating tests
- **build**: Build system or dependencies
- **ci**: CI/CD configuration changes
- **chore**: Other maintenance tasks
- **revert**: Revert a previous commit

### Examples

```bash
feat: add support for feature_xxx directory pattern
fix(parser): handle relative imports correctly
docs: update README with installation steps
test: add edge case tests for nested features
ci: add commit linting workflow
```

### Breaking Changes

For breaking changes, add `!` after type or add `BREAKING CHANGE:` in footer:

```bash
feat!: redesign plugin API
```

or

```bash
feat: redesign plugin API

BREAKING CHANGE: Plugin.register() now requires PluginRegistry parameter
```

### Making Changes

1. **Create a branch** for your changes:

   ```bash
   git checkout -b feature/your-feature-name
   # or
   git checkout -b fix/issue-description
   ```

2. **Write your code**:
   - Follow the existing code style
   - Add tests for new features
   - Update documentation as needed

3. **Test your changes**:

   ```bash
   dart test
   dart analyze
   dart format .
   ```

4. **Commit your changes** (following Conventional Commits format):

   ```bash
   git add .
   git commit -m "feat: add new feature"
   # or
   git commit -m "fix: resolve issue with..."
   ```

5. **Push to your fork**:

   ```bash
   git push origin your-branch-name
   ```

6. **Create a Pull Request** on GitHub

## Project Structure

```
barrel_file_lints/
├── lib/
│   ├── main.dart              # Plugin entry point
│   └── barrel_file_lints.dart # Rules & quick fixes
├── test/
│   ├── avoid_internal_feature_imports_test.dart
│   ├── avoid_core_importing_features_test.dart
│   ├── relative_imports_test.dart
│   ├── additional_internal_directories_test.dart
│   ├── test_file_variations_test.dart
│   ├── edge_cases_test.dart
│   └── quick_fixes_test.dart
└── .github/
    └── workflows/
        ├── ci.yml
        └── publish.yml
```

## Writing Lint Rules

When adding a new lint rule:

1. **Define the LintCode** with a static constant:

   ```dart
   class MyNewRule extends AnalysisRule {
     static const LintCode code = LintCode(
       'my_new_rule',
       "Error message",
       correctionMessage: 'How to fix it',
     );
   }
   ```

2. **Implement the visitor**:

   ```dart
   @override
   void registerNodeProcessors(
     RuleVisitorRegistry registry,
     RuleContext context,
   ) {
     registry.addImportDirective(this, _MyVisitor(this, context));
   }
   ```

3. **Add tests** in `test/my_new_rule_test.dart`

4. **Update README.md** with documentation

## Writing Quick Fixes

Quick fixes should:

1. Extend `ResolvedCorrectionProducer`
2. Have a unique `FixKind` identifier
3. Be registered with `registerFixForRule()`
4. Include tests verifying the fix

## Testing Guidelines

- **Test both valid and invalid cases**
- **Cover edge cases** (null values, empty strings, etc.)
- **Test both naming conventions** (`feature_xxx/` and `features/xxx/`)
- **Test exclusions** (test files, etc.)
- **Use descriptive test names**: `test_descriptiveName` format

## Documentation

- Update README.md for user-facing changes
- Update CHANGELOG.md following [Keep a Changelog](https://keepachangelog.com/)
- Add inline documentation for complex code
- Include code examples in documentation

## Submitting Changes

### Before Submitting

1. **Format your code**:

   ```bash
   dart format .
   ```

2. **Run linter**:

   ```bash
   dart analyze --fatal-infos
   ```

3. **Run tests**:

   ```bash
   dart test
   ```

4. **Check test coverage** (optional):

   ```bash
   dart test --coverage=coverage
   ```

### Pull Request Process

1. **Push your changes** to your fork:

   ```bash
   git push origin feature/your-feature-name
   ```

2. **Create a Pull Request** on GitHub with:
   - Clear title following Conventional Commits format
   - Description of changes
   - Reference any related issues
   - Screenshots/examples if applicable

3. **Respond to feedback** and make requested changes

4. **Ensure CI passes** - all tests and checks must pass

### Pull Request Checklist

Your PR should:

- [ ] Follow Conventional Commits format in title
- [ ] Include clear description of changes
- [ ] Add tests for new functionality
- [ ] Pass all existing tests
- [ ] Pass `dart analyze --fatal-infos` with no issues
- [ ] Be properly formatted (`dart format`)
- [ ] Update relevant documentation (README, CHANGELOG)
- [ ] Reference related issues

## Release Process

Releases are handled by maintainers:

1. Update version in `pubspec.yaml`
2. Update `CHANGELOG.md`
3. Create a Git tag
4. GitHub Actions will automatically publish to pub.dev

## Reporting Issues

### Bug Reports

When reporting bugs, please include:

1. **Environment information**:
   - Dart SDK version (`dart --version`)
   - IDE and version (VS Code, IntelliJ, etc.)
   - Operating system

2. **Steps to reproduce**:
   - Exact code that triggers the issue
   - Expected behavior
   - Actual behavior

3. **Additional context**:
   - Error messages and stack traces
   - Relevant `analysis_options.yaml` configuration
   - Screenshots if helpful

### Feature Requests

When requesting features:

1. **Describe the problem** the feature would solve
2. **Propose a solution** or approach
3. **Consider alternatives** and their trade-offs
4. **Provide code examples** of how it would be used

## Getting Help

- 📖 Check the [README](README.md) for usage instructions
- 🐛 Search [existing issues](https://github.com/teklund/barrel_file_lints/issues) before creating new ones
- 💬 Ask questions in [Discussions](https://github.com/teklund/barrel_file_lints/discussions)
- 🏷️ Want to contribute but not sure where? Check issues labeled `good first issue`

## Resources

- [Dart Analyzer Plugin Guide](https://github.com/dart-lang/sdk/blob/main/pkg/analysis_server_plugin/doc/writing_a_plugin.md)
- [Dart Style Guide](https://dart.dev/guides/language/effective-dart/style)
- [Writing Tests](https://dart.dev/guides/testing)
- [Conventional Commits](https://www.conventionalcommits.org/)

## Recognition

Contributors will be acknowledged in:

- CHANGELOG.md for their contributions
- GitHub contributors list

Thank you for contributing to Barrel File Lints! 🎉
