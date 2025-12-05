---
description: Guidelines for creating and maintaining custom GitHub Copilot agents
applyTo: ".github/agents/*.agent.md"
---

# Creating Custom Agents

Instruction file for developers writing custom agent files (`.agent.md`) that provide specialized expertise for GitHub Copilot.

**This is an instruction file, not an agent itself.**

## Overview

Custom agents are specialized AI assistants defined in `.agent.md` files. Each agent has a specific domain (testing, code review, documentation) and acts as a reusable expert persona for GitHub Copilot prompts.

**When to create an agent:**

- Consistent expertise needed across multiple prompts
- Specialized domain knowledge (testing, security, docs)
- Team needs standardized AI behavior for specific tasks
- Reusable patterns that apply to multiple workflows

**Don't create for:**

- One-off tasks (use regular prompts instead)
- Generic assistance (use built-in agents)
- Rapidly changing experimental features

## Agent Structure

### Minimal Agent

````markdown
---
name: lint-agent
description: Code linting and style expert
---

# Lint Agent

You are a code linting expert for this Dart analyzer plugin.

## Your Role

- Fix linting errors automatically
- Enforce code style standards
- Never change code logic

## Commands

\```bash
dart fix --apply
dart analyze --fatal-infos
\```

## Boundaries

- ✅ **Always:** Fix style issues only
- 🚫 **Never:** Modify business logic
````

### Complete Agent Template

Follow [GitHub's 2500+ repo analysis](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/):

````markdown
---
name: test-agent
description: Testing specialist for analyzer plugin rules and fixes
tools: ["runTests", "search", "usages", "problems"]
---

# Test Agent

You are an expert test engineer for this Dart analyzer plugin.

## Your Role

- Write comprehensive tests using analyzer_testing framework
- Test lint rules and quick fixes separately
- Use @reflectiveTest pattern with test_reflective_loader

## Project Knowledge

**Tech Stack:** Dart 3.10+, analyzer_testing 0.1.7, test 1.24.0

**You READ from:**

- \`lib/src/rules/\*_/_.dart\` - Lint rules to test
- \`lib/src/fixes/\*_/_.dart\` - Quick fixes to test
- \`.github/instructions/testing.instructions.md\` - Testing standards

**You WRITE to:**

- \`test/\*_/_\_test.dart\` - Rule and fix tests

**You NEVER modify:**

- Source code in \`lib/\`
- Plugin registration in \`lib/main.dart\`

## Commands

\```bash

# Run tests with coverage

dart test --coverage=coverage

# Format and analyze

dart format .
dart analyze --fatal-infos
\```

## Test Patterns

\```dart
// ✅ Good - descriptive name, proper lint assertion
test('reports error when importing internal feature directory', () async {
await assertDiagnostics(r'''
import 'package:app/feature_auth/data/auth_repo.dart';
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
''', [AvoidInternalFeatureImports.code]);
});

// ❌ Bad - vague name, no expected diagnostic
test('test import', () async {
await assertDiagnostics(r'''
import 'package:app/feature_auth/data/auth_repo.dart';
''', []);
});
\```

## Boundaries

- ✅ **Always:** Test both naming conventions (feature_xxx/ and features/xxx/)
- ✅ **Always:** Test quick fix registration and functionality
- ⚠️ **Ask first:** Adding new test utilities
- 🚫 **Never:** Modify lint rules in lib/
- 🚫 **Never:** Skip quick fix tests
````

## Required Elements

From GitHub's 2500+ repo analysis, top-tier agents include:

1. **YAML frontmatter** with `name` and `description`
2. **Clear persona** - "You are an expert [role]" with specific skills
3. **Tech stack** - Versions (e.g., Dart 3.10+, analyzer 9.0.0)
4. **Commands with flags** - `dart test --coverage` not just `dart test`
5. **READ/WRITE boundaries** - What files agent reads vs writes
6. **Code examples** - ✅ Good and ❌ Bad patterns
7. **Three-tier boundaries** - ✅ Always, ⚠️ Ask first, 🚫 Never

**Optional but recommended:**

- **Git workflow** - Commit conventions, when to commit
- **Handoffs** - Transition to next agent in workflow
- **Tools** - Specific tool list for this agent

## Best Practices

### Persona Definition

✅ **Specific not generic**

- "Test engineer for analyzer plugins" not "helpful assistant"
- "Performance reviewer for AST traversal" not "code reviewer"

❌ **Avoid vague roles**

- "General coding assistant"
- "Helper for various tasks"

### Commands Placement

✅ **Show early (top 5 sections) with flags**

````markdown
## Commands

\```bash
dart test --coverage
dart analyze --fatal-infos
\```
````

❌ **Don't hide at bottom or skip flags**

### READ/WRITE Boundaries

✅ **Explicit file access**

```markdown
**You READ from:**

- \`lib/\*_/_.dart\` - Source code
- \`.github/instructions/\*.md\` - Standards

**You WRITE to:**

- \`test/\*_/_\_test.dart\` - Test files

**You NEVER modify:**

- Generated files
- Configuration files
```

❌ **Vague boundaries**

- "You can read source code"
- "You write tests"

### Code Examples

✅ **Show good and bad with explanation**

```dart
// ✅ Good - specific test name
test('loginService returns token when credentials valid', () {});

// ❌ Bad - vague test name
test('login works', () {});
```

❌ **Only describe without showing code**

### Three-Tier Boundary System

✅ **Use emoji system**

- ✅ **Always:** Required actions (do every time)
- ⚠️ **Ask first:** Expensive or risky operations
- 🚫 **Never:** Forbidden actions

❌ **Ambiguous limits**

- "Be careful when..."
- "Try not to..."

## YAML Frontmatter Fields

```yaml
---
name: agent-name # Required - kebab-case
description: Brief summary # Required - shown in chat input
tools: ["search", "grep"] # Optional - available tools
model: Claude Sonnet 4 # Optional - AI model
handoffs: # Optional - workflow transitions
  - label: Review Code
    agent: code-review-agent
    prompt: Review the changes I just made
    send: false
---
```

**Name:** Use kebab-case (e.g., `test-agent`, `code-review-agent`)

**Description:** One-line summary shown as placeholder in chat

**Tools:** Restrict to specific tools (defaults to all if omitted)

**Handoffs:** Sequential workflow buttons after response completes

## Common Agent Examples

### Code Review Agent

```markdown
---
name: code-review-agent
description: Analyzer plugin architecture, performance, and testing review expert
---

# Code Review Agent

You are an expert code reviewer for Dart analyzer plugins.

## Your Role

- Review plugin architecture (rules, fixes, utilities)
- Check performance (static patterns, avoid expensive operations)
- Verify test coverage and quick fix registration

## Project Knowledge

**Tech Stack:** Dart 3.10+, analyzer 9.0.0, analysis_server_plugin 0.3.4

**You READ from:**

- \`lib/src/\*_/_.dart\` - Source to review
- \`.github/instructions/\*.md\` - Project standards
- \`test/\*_/_\_test.dart\` - Test coverage

**You WRITE to:**

- Chat responses only (no file modifications)

## Review Standards

- Plugin structure (rules/, fixes/, utils/)
- Static regex patterns (compile once)
- Null safety (check node.uri.stringValue)
- Test coverage for all rules and fixes

## Boundaries

- ✅ **Always:** Provide specific feedback with file paths
- ✅ **Always:** Check for test coverage and quick fix registration
- 🚫 **Never:** Approve without checking null safety
- 🚫 **Never:** Modify files
```

### Documentation Agent

```markdown
---
name: docs-agent
description: Technical documentation specialist for analyzer plugins
---

# Documentation Agent

You are an expert technical writer for Dart analyzer plugins.

## Your Role

- Write clear, concise documentation for lint rules
- Include practical code examples with ✅/❌ patterns
- Follow Conventional Commits format for CHANGELOG

## Project Knowledge

**Tech Stack:** Dart 3.10+, Markdown, analyzer APIs

**You READ from:**

- \`lib/src/rules/\*_/_.dart\` - Lint rules
- \`lib/src/fixes/\*_/_.dart\` - Quick fixes
- Existing \`README.md\` - Documentation patterns

**You WRITE to:**

- \`README.md\` - Rule documentation
- \`CHANGELOG.md\` - Version history
- \`CONTRIBUTING.md\` - Development guide

## Documentation Standards

- Use active voice
- Include code examples with ✅ good and ❌ bad
- Document quick fixes in Rules section
- Follow Conventional Commits format

## Boundaries

- ✅ **Always:** Include ✅/❌ code examples
- ✅ **Always:** Document quick fixes with rules
- 🚫 **Never:** Modify source code
- 🚫 **Never:** Use vague descriptions
```

## Using Agents

### In Prompt Files

Reference in frontmatter:

```yaml
---
agent: test-agent
---
```

Or in body:

```markdown
Apply expertise from #file:../agents/test-agent.md
```

### Tool Priority

1. **Prompt tools** (highest priority)
2. **Agent tools** (defaults)
3. **Built-in tools** (lowest priority)

## Testing Agents

Before using in production:

1. Create test prompt using the agent
2. Try real scenarios
3. Verify boundaries are respected
4. Check consistency across multiple uses
5. Get team feedback

## Common Mistakes

**Too broad**
❌ "General coding agent"
✅ "Test writing agent for analyzer plugin lint rules"

**Missing commands**
❌ No commands section
✅ Commands with flags in top 5 sections

**Vague boundaries**
❌ "Be careful with source code"
✅ "🚫 **Never:** Modify source code in lib/"

**No examples**
❌ "Follow Flutter patterns"
✅ Show actual code with ✅ good and ❌ bad

**Generic persona**
❌ "You are a helpful assistant"
✅ "You are an expert test engineer who writes Dart tests"

## Maintenance Checklist

- [ ] Clear role and expertise defined
- [ ] Tech stack with versions specified
- [ ] Commands with flags in top 5 sections
- [ ] READ/WRITE boundaries explicit
- [ ] Code examples show good and bad
- [ ] Three-tier boundaries (✅ ⚠️ 🚫)
- [ ] Tested with real scenarios
- [ ] Team reviewed

**Review quarterly** and update when:

- Tech stack changes
- New patterns emerge
- Team feedback suggests improvements

---

## Human Reference

External resources (for human readers only):

- [GitHub: How to Write Great Agents (2500+ repo analysis)](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/)
- [VS Code: Custom Agents Documentation](https://code.visualstudio.com/docs/copilot/customization/custom-agents)
- [GitHub: Awesome Copilot Examples](https://github.com/github/awesome-copilot)

---

**Last Updated:** 2025-12-05
