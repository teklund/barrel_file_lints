---
description: Guidelines for creating and maintaining instruction files
applyTo: ".github/instructions/*.instructions.md"
---

# Creating Instruction Files

## Overview

Instruction files help AI assistants and developers maintain consistency across the codebase. They define common guidelines that automatically influence code generation and development tasks.

## When to Create Instructions

**Create when:**

- Consistent patterns exist across multiple files
- Team repeatedly makes the same mistakes
- New developers struggle with specific areas
- Critical architectural patterns must be followed

**Don't create for:**

- One-off implementations
- Self-evident standard patterns
- Rapidly changing experimental features
- Well-documented external libraries (link instead)

## File Structure

Follow VS Code's recommended format with YAML frontmatter. See the Template section below for a complete example.

### Required Elements

1. **YAML Frontmatter** - `description`, optional `name`, and optional `applyTo` glob pattern
2. **Title** - Clear, specific heading
3. **Overview** - 1-2 paragraphs explaining purpose and when to use
4. **Patterns** - Practical code examples
5. **Best Practices** - Concise do's and don'ts

### Optional Elements

- Common mistakes and solutions
- Troubleshooting tips
- Before/after examples
- Human Reference section at bottom for external links (Copilot doesn't follow links)

## Writing Guidelines

### Keep Instructions Short and Self-Contained

Each instruction should be a single, simple statement. Write instructions as a single paragraph, each on a new line, or separated by blank lines for legibility.

❌ Verbose: "When implementing lint rules, it's important to understand that we use the visitor pattern..."
✅ Concise: "Use visitor pattern for lint rules. Extend SimpleAstVisitor for AST traversal."

Per VS Code docs: *"Short, imperative rules are more effective than long paragraphs."*

### Be Specific and Practical

❌ Abstract: "Error handling should consider user experience."

✅ Specific with code:

```dart
// Check for null before accessing node properties
final uri = node.uri.stringValue;
if (uri == null) return;

// Use static regex patterns (compile once)
static final _featurePattern = RegExp(r'feature_([^/]+)');
```

### Use Generic, Best-Practice Examples

**Prefer common, recognizable patterns over project-specific classes:**

❌ Project-specific examples from other projects: `UserProfileNotifier`, `TripSearchApi`

✅ Generic examples: `MyRule`, `MyVisitor`, `MyQuickFix`, `ServiceImpl`

Generic examples are:

- Easier to understand for new developers
- Applicable across different projects
- More maintainable over time
- Better for demonstrating patterns

**When to use project-specific examples:**

- Explaining a unique pattern specific to this codebase
- Referencing actual files when troubleshooting
- Documenting legacy code that needs migration

### Show, Don't Tell

❌ "Follow naming conventions."

✅ "Pattern: `avoid_feature_pattern.dart` (e.g., `avoid_internal_feature_imports.dart`)"

### Use Markdown for Clarity

- **Bold** for emphasis
- `Code` for technical terms
- Lists for multiple points
- Code blocks for examples

## Length Guidelines

Keep instructions concise - shorter is better. Per GitHub's guidance, files exceeding ~1,000 lines tend to produce inconsistent results. If a file grows large, split into multiple topic-specific files.

## Code Examples

### Good Examples

✅ Complete and runnable
✅ Focused on specific pattern
✅ Include comments explaining key points

### Avoid

❌ Incomplete snippets without context
❌ 50+ line examples when pattern is simple
❌ Pseudo-code or placeholders

## Common Mistakes

**Over-documenting variations**
❌ Listing every possible value
✅ Document the pattern once with examples

**Copying external docs**
❌ Pasting official docs verbatim
✅ Summarize and adapt to project

**Duplicating content**
❌ Repeating info across files
✅ Reference other instruction files to keep them clean and focused

**Generic advice**
❌ "Follow best practices"
✅ "Use static `LintCode` with unique identifier. Check null on `node.uri.stringValue`."

## Checklist

Before submitting:

- [ ] Clear scope and purpose
- [ ] Short and focused
- [ ] Real code examples
- [ ] Follows existing structure
- [ ] Reflects current codebase
- [ ] Listed in README.md
- [ ] Tested with AI assistant

## Updating Instructions

1. Verify patterns still match codebase
2. Remove obsolete content
3. Add new patterns
4. Simplify where possible
5. Update code examples
6. Update "Last Updated" date

## File Naming

Pattern: `{topic}.instructions.md`

Examples:

- `rules.instructions.md` - Lint rule patterns
- `fixes.instructions.md` - Quick fix patterns
- `testing.instructions.md` - Test patterns

Rules:

- Use kebab-case
- Be specific but concise
- Prefer domain over technology names
- Always end with `.instructions.md`

## Organizing Instructions

### README.md Entry

Add new instructions to `README.md` under appropriate category:

- Meta - Creating instructions, agents, prompts
- Core - Rules, fixes, utilities
- Testing - Unit tests, coverage
- Process - Commits, workflows
- Documentation - README, CHANGELOG

### Using applyTo Patterns

Use glob patterns to auto-apply instructions:

```yaml
---
applyTo: "**/*.dart"  # All Dart files
applyTo: "lib/**/ui/**/*.dart"  # UI files only
applyTo: "test/**/*_test.dart"  # Test files
---
```

Specific patterns are better than `**/*` for performance.

## Template

```markdown
---
description: Brief description of what this covers
applyTo: "file/pattern/**/*.dart"
---

# Title

Brief overview (1-2 paragraphs).

## Pattern Name

Code example:

```dart
// Example with comments
class Example {
  void method() {
    // Implementation
  }
}
```

## Best Practices

- ✅ Do this
- ✅ Do that
- ❌ Don't do this

---

**Last Updated:** Month Year

## Maintenance

**Review quarterly** for accuracy

**Update immediately when:**

- Patterns change in codebase
- Major refactors affect instructions
- AI struggles to follow guidance

**Deprecate instructions by:**

1. Adding deprecation notice at top
2. Referencing replacement if applicable
3. Updating README.md
4. Removing after 3 months

## VS Code Integration

Store instructions in `.github/instructions/` folder for:

- Automatic workspace context
- Version control
- Team sharing

Enable with: `github.copilot.chat.codeGeneration.useInstructionFiles`

Use `applyTo` glob patterns to target specific files automatically.

---

## Human Reference

These resources are for human readers only (Copilot does not follow external links):

- [VS Code Custom Instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions)
- [GitHub Blog: Master Your Instructions Files](https://github.blog/ai-and-ml/unlocking-the-full-power-of-copilot-code-review-master-your-instructions-files/)
- [Awesome Copilot Examples](https://github.com/github/awesome-copilot)

---

**Last Updated:** 2025-12-05
