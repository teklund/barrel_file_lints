---
description: Guidelines for creating and maintaining GitHub Copilot prompt files
applyTo: ".github/prompts/*.prompt.md,.github/prompts.md"
---

# GitHub Copilot Prompt Files

Guidelines for creating reusable prompt files for GitHub Copilot Chat.

**Related:** copilot-instructions.md for general Copilot guidelines, instructions.instructions.md for instruction file patterns

## Quick Reference

**Creating prompt files:**

- File location: `.github/prompts/*.prompt.md`
- Use custom agents when appropriate (`code-review-agent`, `test-agent`, `docs-agent`)
- Reference agents with #file:../agents/test.agent.md (example)
- Use variables for user input: `${input:name:description}`
- Document in `prompts.md` after creation

## File Structure

### Minimal Prompt (Agent Only)

```markdown
---
agent: test-agent
description: "Write tests following best practices"
name: "write-tests"
---

You are using the test-agent expertise from #file:../agents/test.agent.md

## Context

Target: ${input:target:File or feature to test}

## Instructions

1. Read the target file
2. Apply test-agent patterns
3. Create comprehensive tests

## Output Format

- Test plan
- Implementation
- Run commands
```

### Full Prompt (All Options)

````markdown
---
agent: code-review-agent
description: "Comprehensive pre-PR review"
name: "pr-review"
argument-hint: "branch=<branch-name> focus=<area>"
---

Brief introduction.

## Context

Workspace: ${workspaceFolder}
Branch: ${input:branch:Branch name (empty for current)}
Focus: ${input:focus:Specific area to emphasize (optional)}

## Instructions

Detailed, structured instructions.

## Output Format

Define expected response structure.

## Example Usage

```bash
/pr-review
/pr-review branch=feature/new-payment focus=security
```
````

````markdown
## Header Fields (YAML Frontmatter)

All fields are optional:

```yaml
---
description: "Brief description" # Shown in slash command menu
name: "custom-command-name" # Defaults to filename without extension
argument-hint: "Hint text" # Shown in chat input field
agent: "code-review-agent" # ask, edit, agent, or custom agent name
model: "gpt-4" # Specific model (defaults to current)
tools:
  ["tool-name"] # Built-in, MCP, or extension tools
  # Use 'server-name/*' for all MCP server tools
---
```
````

**Agent field:**

- `ask` - Ask agent (answering questions, no tools)
- `edit` - Edit agent (code modifications)
- `agent` - Default agent with tool access
- `code-review-agent` - Custom agent name (e.g., for code review)
- `test-agent` - Custom agent name (e.g., for testing)
- `docs-agent` - Custom agent name (e.g., for documentation)
- Omit to use current agent (defaults to `agent` if tools specified)

## Variables

### Built-in Variables

```markdown
${workspaceFolder}              # /Users/user/project
${workspaceFolderBasename} # project
${file}                         # /Users/user/project/lib/main.dart
${fileBasename} # main.dart
${fileDirname}                  # /Users/user/project/lib
${selection} # Current editor selection
${selectedText} # Selected text content
```

### Input Variables

```markdown
${input:variableName}                              # Basic
${input:variableName:Placeholder description} # With hint
```

### Tool References

Reference tools in prompt body using the format:

````markdown
#tool:search to reference a specific tool
#tool:githubRepo as an example for GitHub repository tool
````

**Note:** Tools must be listed in the `tools` frontmatter field to be available.

**Best practices:**

- Use camelCase for variable names
- Provide clear placeholder text
- Mark optional variables explicitly
- Handle empty values in prompt logic

**Examples:**

```markdown
Branch: ${input:branch:Current branch name (leave empty for current)}
Scope: ${input:scope:What to review? (file path or leave empty)}
Focus: ${input:focus:Any specific concern? (optional)}
```

## Custom Agents

### When to Use Agents

**Use custom agents for:**

- ✅ Specialized domains (code review, testing, docs)
- ✅ Consistent expertise across multiple prompts
- ✅ Complex rules and patterns
- ✅ Single source of truth for standards

**Use default agent for:**

- ✅ Simple, one-off prompts
- ✅ General tasks without domain expertise
- ✅ Quick utilities

### Referencing Agents

```markdown
---
agent: test-agent
---

You are using test-agent expertise from #file:../agents/test.agent.md

Apply your testing knowledge with these additional requirements:

- [Specific prompt instructions]
```

**Benefits:**

- Agent provides domain expertise
- Prompt provides task-specific context
- Single source of truth (update agent once)
- Consistent quality across prompts

## Common Patterns

### Code Review Prompt

```markdown
---
agent: code-review-agent
description: "Review code for quality"
---

Apply your code review expertise from #file:../agents/code-review.agent.md

## Context

Scope: ${input:scope:What to review?}

## Review Approach

[Specific focus areas for this review type]

## Output Format

**Quick Summary** - Overall assessment
**Issues Found** - Problems with line numbers
**Approved** - Yes/No with reasoning
```

### Test Creation Prompt

```markdown
---
agent: test-agent
description: "Create tests following best practices"
---

Apply your testing expertise from #file:../agents/test.agent.md

## Context

Target: ${input:target:File or class to test}
Type: ${input:type:unit/widget/golden/integration}

## Test Strategy

[Auto-detect or specific requirements]

## Output Format

**Test Plan** - What will be tested
**Implementation** - Complete test file
**Run Command** - How to execute
```

### Documentation Prompt

```markdown
---
agent: docs-agent
description: "Create or update documentation"
---

Apply your documentation expertise from #file:../agents/docs.agent.md

## Context

Target: ${input:target:What to document?}
Format: ${input:format:README/guide/API docs}

## Requirements

[Specific documentation standards]
```

## Best Practices

### Structure

**DO:**

- ✅ Use `.prompt.md` extension (required for VS Code)
- ✅ Add YAML frontmatter with `description` (optional but recommended)
- ✅ Reference custom agents with #file:../agents/test.agent.md (example)
- ✅ Organize with clear `##` sections
- ✅ Use Markdown formatting (lists, code blocks, emphasis)
- ✅ Place variables inline where values belong

**DON'T:**

- ❌ Duplicate agent expertise in prompt (reference it)
- ❌ Hardcode values that should be variables
- ❌ Use vague variable names
- ❌ Forget to document in `prompts.md`

### Content Quality

**DO:**

- ✅ Clearly describe what the prompt should accomplish
- ✅ Define expected output format
- ✅ Provide examples of expected input and output
- ✅ Use Markdown links to reference custom instructions (avoid duplication)
- ✅ Take advantage of built-in variables like `${selection}`

**DON'T:**

- ❌ Be overly verbose (reference instruction files)
- ❌ Duplicate content from agents or instructions
- ❌ Use ambiguous instructions
- ❌ Forget edge cases

### Variable Design

**DO:**

- ✅ Use meaningful names (`branchName` not `x`)
- ✅ Provide clear descriptions with examples
- ✅ Mark optional variables explicitly
- ✅ Handle empty/invalid values

**DON'T:**

- ❌ Use spaces in variable names
- ❌ Skip placeholder descriptions
- ❌ Assume variables are always filled
- ❌ Over-complicate variable logic

### Documentation

**DO:**

- ✅ Add to "Available Prompts" in `prompts.md`
- ✅ Describe variables and their purpose
- ✅ Show example usage scenarios
- ✅ Explain when to use vs other prompts
- ✅ Update when prompt behavior changes

**DON'T:**

- ❌ Skip documenting new prompts
- ❌ Use outdated examples
- ❌ Forget to mention agent usage
- ❌ Over-explain obvious functionality

## Tool List Priority

When both custom agents and prompt files specify tools, the priority order is:

1. **Prompt file tools** - Tools specified in prompt's `tools` field (highest priority)
2. **Custom agent tools** - Tools from the referenced agent
3. **Default agent tools** - Default tools for selected agent (lowest priority)

**Example:**

```yaml
---
agent: code-review-agent
tools: ["git", "github"] # These override agent's default tools
---
```

## Testing & Maintenance

### Testing New Prompts

1. **Test in editor** - Open prompt file and press play button in editor title area
2. **Test in chat** - Type `/` followed by prompt name
3. **Test with variables** - Try different input combinations
4. **Test empty values** - Ensure graceful handling
5. **Refine based on results** - Iterate on prompt based on actual output

### Iterating Prompts

**When to update:**

- Results don't match expectations
- New patterns emerge in codebase
- Team feedback suggests improvements
- Agent expertise is updated

**Update process:**

1. Modify prompt file
2. Test thoroughly
3. Update documentation in `prompts.md`
4. Commit with descriptive message
5. Notify team of changes

### Maintenance Checklist

- [ ] Prompt file follows structure guidelines
- [ ] Agent reference is correct (if used)
- [ ] Variables have clear descriptions
- [ ] Output format is well-defined
- [ ] Examples are accurate and helpful
- [ ] Documented in `prompts.md`
- [ ] Tested with various inputs
- [ ] Team reviewed and approved

## Common Issues

### Prompt not appearing

- Enable `chat.promptFiles` in VS Code settings
- Verify `.prompt.md` extension
- Check YAML frontmatter syntax (if used)
- Ensure file is in `.github/prompts/` directory
- Restart VS Code

### Variables not working

- Use exact syntax: `${input:name:description}`
- No spaces in variable names (use camelCase)
- Clear, helpful description after second colon
- Test with both filled and empty values

### Poor results

- Be more specific in instructions
- Reference relevant agents
- Add concrete examples
- Break complex prompts into smaller ones
- Iterate based on actual usage

### Agent expertise not applied

- Verify agent reference uses #file:../agents/test.agent.md (example format)
- Check agent file exists
- Ensure frontmatter has correct `agent` field
- Prompt should explicitly reference agent

## Examples

### Minimal Review Prompt

```markdown
---
agent: code-review-agent
description: "Quick code review"
---

Apply code-review-agent expertise from #file:../agents/code-review.agent.md

Review: ${input:scope:What to review?}

Focus on critical issues. Provide concise, actionable feedback.
```

### Comprehensive Test Prompt

````markdown
---
agent: test-agent
description: "Write comprehensive tests"
name: "write-tests"
argument-hint: "target=<file> type=<unit|widget|golden>"
---

Apply test-agent expertise from #file:../agents/test.agent.md

## Context

Target: ${input:target:File or class to test}
Type: ${input:type:unit/widget/golden/integration/auto}

## Strategy

- Auto-detect test type if "auto"
- Cover happy path and errors
- Use appropriate mocking
- Follow test pyramid

## Output

**Test Plan** - Scenarios to cover
**Implementation** - Complete test file
**Run Command** - How to execute

## Usage Examples

```bash
/tests target=lib/feature_auth/data/auth_service.dart
/tests target=UserPage type=widget
```
````

## Related Files

- `.github/prompts/*.prompt.md` - Individual prompt files
- `.github/prompts.md` - Prompt catalog and quick reference
- `.github/agents/*.md` - Custom agent definitions
- `.github/copilot-instructions.md` - General Copilot guidelines
- `.github/INSTRUCTIONS.md` - Index of all instruction files

## External Resources

- [GitHub Docs: Your first prompt file](https://docs.github.com/en/copilot/tutorials/customization-library/prompt-files/your-first-prompt-file)
- [VS Code: Prompt files](https://code.visualstudio.com/docs/copilot/customization/prompt-files)
- [GitHub: Awesome Copilot Customizations](https://github.com/github/awesome-copilot/blob/main/docs/README.prompts.md)

---

**Last Updated:** 2025-12-05
