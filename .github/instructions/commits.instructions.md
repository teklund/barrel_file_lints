---
description: Commit message conventions using Conventional Commits
---

# Commit Guidelines

This project follows Conventional Commits for all commits and PR titles.

**Important:** We use **squash merge** for all PRs to master. Individual commit messages in feature branches are helpful during development but will be squashed into a single commit on merge. Focus on writing a clear PR title that follows Conventional Commits format.

## Format

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Types

| Type         | Usage                                      |
| ------------ | ------------------------------------------ |
| **feat**     | New feature                                |
| **fix**      | Bug fix                                    |
| **docs**     | Documentation changes                      |
| **style**    | Code style/formatting (no logic changes)   |
| **refactor** | Code restructuring (no bug fix or feature) |
| **perf**     | Performance improvements                   |
| **test**     | Adding or updating tests                   |
| **build**    | Build system or dependency changes         |
| **ci**       | CI configuration changes                   |
| **chore**    | Maintenance tasks                          |
| **revert**   | Revert previous commit                     |

## Common Scopes

Use feature names or areas from this analyzer plugin. Examples:

- **rules**: Lint rules
- **fixes**: Quick fixes
- **utils**: Utility functions
- **config**: Configuration
- **deps**: Dependencies
- **docs**: Documentation

## Examples

```bash
# Features
feat(rules): add avoid_self_barrel_import rule
feat(fixes): implement simplify_relative_path quick fix

# Bug fixes
fix(rules): handle null uri in avoid_internal_feature_imports
fix(fixes): correct offset calculation in replace_with_barrel_import

# Refactoring
refactor(utils): extract feature detection to shared utility
refactor(rules): simplify visitor pattern implementation

# Testing
test(rules): add coverage for relative imports
test(fixes): verify quick fix handles edge cases

# Dependencies
chore(deps): update analyzer to ^9.0.0
chore(deps): upgrade analyzer_testing to ^0.1.7

# Documentation
docs: update README with configuration examples
docs: add CHANGELOG entry for new rules
```

## Breaking Changes

Add `!` after type/scope and include BREAKING CHANGE footer:

```bash
feat(rules)!: change avoid_internal_feature_imports diagnostic message format

BREAKING CHANGE: Error messages now include feature name in format.
Migration: Update tests to match new diagnostic message format.
```

## Rules

1. Use imperative mood ("add" not "added" or "adds")
2. Don't capitalize first letter
3. No period at end
4. Keep subject under 100 characters (50 preferred, 100 max)
5. Explain what and why (not how)

## Best Practices

### Atomic Commits

- One logical change per commit
- Commit often (small, focused changes)
- Each commit should leave codebase in working state

### Good vs Bad Examples

```bash
# ✅ Good: Clear and specific
fix(rules): prevent null pointer when uri is missing
feat(fixes): add quick fix for converting relative to package imports

# ❌ Bad: Vague and unclear
fix: bug fixes
feat: improvements
```

### When to Add Body

- Complex changes requiring explanation
- Breaking changes with migration steps
- Non-obvious solutions

```bash
feat(rules)!: change internal directory detection pattern

BREAKING CHANGE: Now detects additional internal directories beyond data/ and ui/.
Adds support for domain/, presentation/, infrastructure/ directories.

Migration:
- Update tests to expect new directories in diagnostics
- Review suppressed warnings for newly detected patterns
```

---

## Human Reference

These resources are for human readers only (Copilot does not follow external links):

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)

---

**Last Updated:** 2025-12-03
