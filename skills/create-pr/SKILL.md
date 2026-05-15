---
name: create-pr
description: Create a pull request from the current context, Jira task, and implemented fix using GitHub MCP or GitHub CLI, then update the Jira documentation field with a release-friendly description.
version: 1.2.0
---

# Create PR

Framework for creating a pull request based on the current task context, the Jira issue description, and the fix already applied in the current branch, then updating the Jira task documentation field with a concise end-user-facing summary.

## When to Use This Skill

- You already implemented the fix and want to open a pull request.
- You have a Jira task in the current context.
- You want the PR description to follow a fixed template.
- You want to update Jira documentation information for release notes or fix publication.
- You want the branch naming logic to adapt to the current branch and requested task code.

## Primary Objective

Using the current repository context, the Jira task, and the implemented fix:

1. Identify the current branch and current task context.
2. Determine whether a new branch must be created before opening the PR.
3. Detect whether a PR already exists for the current branch and avoid creating a duplicate.
4. Create the pull request using GitHub MCP or GitHub CLI.
5. Use the PR description template exactly as defined in this skill.
6. Update the Jira field "Informações de Documentação" with a short, end-user-oriented description of the fix.

## Required Inputs

This skill may be invoked in forms such as:

```text
/create-pr
```

```text
/create-pr PPV-286
```

Interpretation rules:

- If the user provides a task code after the command, treat it as the branch task code to be used for branch naming when required.
- The Jira task from the current context remains the main task for the PR description title unless explicitly unknown.
- If the main context task is unknown and needed for the PR description title, ask the user.
- If the user runs only `/create-pr`, do not attempt PR creation; instead, provide brief usage instructions and explain how to invoke the skill with a Jira task code.
- If there is no visible implementation related to the requested task in the current branch, ask the user whether they want to proceed using only the Jira description of the main task.
- If the user confirms, generate the PR from the Jira description of the main task only.
- If the user does not confirm, stop and ask for guidance.

## Mandatory Data Sources

Use the following sources before creating the PR:

1. Current repository context.
2. Current git branch.
3. Jira task in the active context.
4. Jira issue description.
5. Implemented fix visible in the current diff, commits, or changed files.

Do not create the PR body only from Jira text when code changes are visible. Always inspect the actual changes applied in the branch to describe what was altered.

## Branch Rules

### Rule 1: Protected or generic current branches

If the current branch is something like:

- `main`
- `master`
- `stable-4-4`
- `stable-*`
- any other obviously protected, release, or generic branch

Do not create the PR immediately.

**Automatic sub-task branch resolution:**

Before asking the user for a branch name, attempt automatic resolution using the main Jira task's sub-tasks:

1. Read the main Jira task from the current context and inspect its sub-tasks.
2. If the current branch matches `stable-*`:
   - Find the sub-task whose summary contains the text **"LTS"**.
   - Use that sub-task's issue key as the branch name (e.g., `PPV-286`).
3. If the current branch is `main`:
   - Find the sub-task whose summary contains the text **"MAIN"**.
   - Use that sub-task's issue key as the branch name (e.g., `PPV-285`).
4. Before creating the branch, run `git pull` on the current base branch to ensure it is up to date.
5. Create the new branch from the updated base branch.

If no matching sub-task is found, fall back to asking the user which branch name should be created.

Example:

- Current branch: `stable-4-4`
- Main Jira task: `PPV-262`
- Sub-tasks: `PPV-285` (summary: "MAIN - VREncerramento - ..."), `PPV-286` (summary: "LTS - VREncerramento - ...")
- Resolved branch: `PPV-286` (because current branch is `stable-*` and sub-task contains "LTS")
- Commands: `git pull` → `git checkout -b PPV-286`

### Rule 2: Current branch already contains a task code

If the current branch already contains a task code, even if it is different from the main Jira task in the current context:

- Do not force branch renaming.
- Open the PR using the current branch.
- Keep following the PR template rules from this skill.
- Preserve the main Jira task from the current context in the PR description title section.

### Rule 3: Explicit task code provided in the command

If the user invokes the skill with something like:

```text
/create-pr PPV-286
```

then:

- Use `PPV-286` as the task code for the branch that must be created, when branch creation is required.
- If no code-related solution exists in the current context, ask the user whether they want to proceed using only the Jira description of the main task.
- If the user confirms, create the PR using only the Jira description of the main task.
- If the current context task is unknown, ask the user before creating the PR.
- Keep the PR description title using the main Jira task from the current context.

Validation requirement:

- The branch / PR creation flow must use `PPV-286` as the branch task identifier when branch creation is needed.
- The `<h1 align="center">...</h1>` title inside the PR description template must contain the main Jira task from the current context.

## PR Creation Workflow

### Step 1: Identify context

Collect:

- Current branch name.
- Main Jira task from the current context.
- Optional task code provided in the command.
- Repository default or target base branch when available.
- Changed files, commits, or diff summary representing the applied fix.

### Step 2: Decide branch strategy

Apply the branch rules defined above.

If a new branch must be created, create it before creating the PR.

### Step 3: Inspect the implemented fix

Before writing the PR description:

- Inspect changed files.
- Inspect commit messages when useful.
- Inspect the current diff when useful.
- Identify what was actually changed in the code.
- Identify important business-rule variations and nearby impacted areas for tests.

If there is no code change related to the requested task, do not invent implementation details; use the Jira description only after the user confirms that they want to proceed this way.

### Step 4: Read Jira task

Use Jira MCP to read the task description and capture:

- Problem summary.
- Affected functional area.
- Expected behavior.
- Business terms useful for end-user communication.

### Step 5: Check for existing PR

Before creating a new PR:

- Check whether an open pull request already exists for the current head branch.
- If an open PR exists, stop and report the existing PR URL instead of creating a duplicate.
- If the branch has no open PR, continue with creation.

### Step 6: Build PR description

Create the PR body using exactly this structure:

```markdown
<h1 align="center">{tarefa-jira}</h1>

***
# Descrição do Bug

**Descrição do problema:**
<!--Descreva brevemente o bug que está sendo corrigido-->
-

***
# Mudanças propostas

**O que foi alterado:**
<!-- Liste as mudanças feitas no código para corrigir o bug -->
-

***
# Testes

**Informações complementares de teste:**
<!-- Adcione aqui variações da regra de negócio e lugares que podem ser afetados com a solução aplicada -->
-
```

Template rules:

- Replace `{tarefa-jira}` with the main Jira task from the current context.
- In **Descrição do Bug**, summarize the problem in a concise way based on Jira and the current context.
- In **Mudanças propostas**, describe the actual implemented changes when they exist; if there is no implemented code change, use the Jira description only after the user confirms that they want to proceed.
- In **Testes**, write content specifically for a human QA tester who will read this section to guide their testing. The text must include:
  - Clear scenarios to reproduce the bug and validate the fix.
  - Business-rule variations that should be tested (e.g., different store types, tax regimes, edge cases).
  - Specific areas, screens, or flows that may be affected by the change and should be regression-tested.
  - Pre-conditions or data setup needed for the test (e.g., "use a Simples Nacional store", "ensure there are pending cupons").
  - Expected results for each scenario so the QA can confirm pass/fail.
  - Use plain, non-technical language focused on functional behavior — avoid referencing class names, methods, or implementation details.

### Step 7: Create the PR

Preferred order:

1. Use GitHub MCP if available and suitable for PR creation.
2. Otherwise use GitHub CLI.

If using GitHub CLI, use commands compatible with `gh pr create`, supplying at least:

- title
- body
- base branch when needed
- head branch when needed

**PR title rule:**

The PR title (`--title`) must use the task code extracted from the current branch name (e.g., if the branch is `PPV-286`, the title starts with `PPV-286`). This is different from the `<h1 align="center">...</h1>` inside the PR body, which uses the main Jira task from the current context.

Example:

- Branch: `PPV-286`
- Main Jira task in context: `PPV-262`
- PR title: `PPV-286 - VREncerramento - Finalização de Consistência - Conferencia de Cupom`
- PR body `<h1>`: `<h1 align="center">PPV-262</h1>`

### Step 8: Update Jira documentation field

After creating the PR, update the Jira field **"Informações de Documentação"** (`customfield_10037`).

Use a short description written for end users, not developers.

**Jira API requirements:**

- The field identifier is `customfield_10037`.
- When calling the Jira MCP `editJiraIssue` tool, always set `contentFormat: "adf"`.
- The field value must be an Atlassian Document Format (ADF) document.

**ADF content structure:**

The ADF document must reproduce the following visual structure, preserving all HTML-like formatting intent:

```text
<font size=4><b>[[Manual do sistema {Nome da Aplicação} {Modulo da aplicação quando houver} | {Nome da Aplicação} > {Caminho do menu (quando houver)} > {Caminho do menu (quando houver)}]]</b></font>
- {Descrição sobre a correção}
```

To achieve this in ADF, construct the document as follows (the HTML tags are included as literal text content, not as ADF marks):

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "<font size=4><b>[[Manual do sistema {Nome da Aplicação} {Modulo} | {Nome da Aplicação} > {Caminho} > {Caminho}]]</b></font>"
        }
      ]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "- {Descrição sobre a correção}"
        }
      ]
    }
  ]
}
```

Example rendered content:

```text
<font size=4><b>[[Manual do sistema VR Master SPED Fiscal | VRMaster > Fiscal > Arquivos Magnéticos > SPED Fiscal]]</b></font>
- Ajustado o processamento para que a funcionalidade considere corretamente a regra esperada durante a geração das informações.
```

Corresponding ADF example:

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "<font size=4><b>[[Manual do sistema VR Master SPED Fiscal | VRMaster > Fiscal > Arquivos Magnéticos > SPED Fiscal]]</b></font>"
        }
      ]
    },
    {
      "type": "paragraph",
      "content": [
        {
          "type": "text",
          "text": "- Ajustado o processamento para que a funcionalidade considere corretamente a regra esperada durante a geração das informações."
        }
      ]
    }
  ]
}
```

**Important:** The HTML tags (`<font size=4>`, `<b>`, `</b>`, `</font>`), the `[[...]]` brackets, and the pipe `|` separator are all part of the literal text content in the ADF text nodes. Do NOT use ADF `marks` (like `{"type": "strong"}`) for the bold formatting — the HTML tags themselves must appear as visible text in the field.

### Step 9: Write the documentation text appropriately

When filling **Informações de Documentação**:

- Use language appropriate for end users.
- Do not mention classes, methods, commits, technical debt, refactoring, or implementation details.
- Describe the corrected behavior clearly and briefly.
- Mention the application and module/menu path when that information can be inferred from Jira or current context.
- If the menu path or application name cannot be determined reliably, ask the user before updating the field.

## Output Expectations

At the end of the execution, report:

1. Which branch was used or created.
2. Which Jira task was used as the main PR description title.
3. Whether the PR was created successfully.
4. Whether the Jira documentation field was updated successfully.
5. Any point that required user confirmation.

## Decision Rules

### Ask the user before proceeding when:

- The user runs only `/create-pr` without a Jira task code.
- The current branch is `main`, `master`, `stable-*`, or another protected/generic branch and no matching sub-task (LTS/MAIN) can be found automatically.
- The main Jira task from the current context is unknown but required for the PR description title.
- The application name or menu path required for **Informações de Documentação** cannot be inferred reliably.
- There is no visible implementation related to the requested task in the current branch.

### Do not proceed silently when:

- Jira MCP is unavailable for reading or updating the issue.
- GitHub MCP and GitHub CLI are both unavailable for PR creation.
- The branch logic is ambiguous.
- The current fix has not been inspected from the repository changes.

## Validation Checklist

Before finishing, ensure that:

- The PR was created from the correct branch.
- The PR title (`--title`) uses the task code from the current branch name, not the main Jira task from context.
- The PR description body follows the exact template structure.
- The PR body `<h1 align="center">...</h1>` title section uses the main Jira task from the current context.
- If the command provided another task code such as `PPV-286`, that code was used only for branch naming when applicable.
- The Jira field **Informações de Documentação** (`customfield_10037`) was updated with end-user-friendly language.
- The Jira update used `contentFormat: "adf"` and the field value is a valid ADF document.
- The Jira documentation text includes the `[[...]]` wiki-link markup with bold formatting in the ADF structure.
- An existing open PR was checked before creating a new one.
- If the user invoked only `/create-pr`, the skill returned usage instructions instead of opening a PR.
- If no code change is visible, the user was asked whether they want to proceed using only the Jira description.

## Example Scenarios

### Scenario 1: Current branch is task branch

Context:

- Current branch: `feature/PPV-262-ajuste-conferencia`
- Current Jira task in context: `PPV-262`
- Command: `/create-pr`

Expected behavior:

- Use current branch.
- Check whether a PR already exists.
- Create PR using inspected changes.
- Use `PPV-262` in the PR description title template.
- Update Jira documentation field.

### Scenario 2: Current branch is stable branch with automatic sub-task resolution

Context:

- Current branch: `stable-4-4`
- Current Jira task in context: `PPV-262`
- PPV-262 sub-tasks: `PPV-285` ("MAIN - VREncerramento - ..."), `PPV-286` ("LTS - VREncerramento - ...")
- Command: `/create-pr`

Expected behavior:

- Detect current branch is `stable-*`.
- Read PPV-262 sub-tasks and find `PPV-286` (contains "LTS").
- Run `git pull` on `stable-4-4`.
- Create branch `PPV-286` from `stable-4-4`.
- Continue with PR creation using `PPV-286` branch.
- PR title uses `PPV-286`.
- PR body `<h1>` uses `PPV-262`.

### Scenario 3: Current branch is main with automatic sub-task resolution

Context:

- Current branch: `main`
- Current Jira task in context: `PPV-262`
- PPV-262 sub-tasks: `PPV-285` ("MAIN - VREncerramento - ..."), `PPV-286` ("LTS - VREncerramento - ...")
- Command: `/create-pr`

Expected behavior:

- Detect current branch is `main`.
- Read PPV-262 sub-tasks and find `PPV-285` (contains "MAIN").
- Run `git pull` on `main`.
- Create branch `PPV-285` from `main`.
- Continue with PR creation using `PPV-285` branch.
- PR title uses `PPV-285`.
- PR body `<h1>` uses `PPV-262`.

### Scenario 4: Explicit branch task code provided

Context:

- Current branch: `stable-4-4`
- Current Jira task in context: `PPV-262`
- Command: `/create-pr PPV-286`

Expected behavior:

- Run `git pull` on `stable-4-4`.
- Create branch using `PPV-286`.
- Create PR from that branch.
- If no code-related solution exists in the current context, ask the user whether they want to proceed using only the Jira description of the main task.
- If the user confirms, build the PR body from the Jira description of the main task only.
- Keep `<h1 align="center">PPV-262</h1>` in the PR description template.
- Update Jira documentation field for the main task in context.

### Scenario 5: Only command entered

Context:

- Command: `/create-pr`

Expected behavior:

- Do not create PR.
- Show the user how to use the skill.
- Explain that a Jira task code can be passed after the command.

## Usage Instructions When No Task Is Provided

If the user runs only `/create-pr`, respond with something like:

- This skill creates a PR from the current Jira context and branch.
- To use it, run `/create-pr PPV-286` or `/create-pr` after opening a branch tied to the task.
- If the branch is protected or generic, the skill will ask which branch should be created.

## Authoring Notes

This skill is designed for repositories where fixes are developed from Jira-driven tasks and where the release-fix documentation in Jira must be updated as part of the delivery flow.