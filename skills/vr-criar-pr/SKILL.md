---
name: vr-criar-pr
description: Create a pull request from the current context, Jira task, and implemented fix using GitHub MCP or GitHub CLI, then update the Jira documentation field with a release-friendly description.
version: 1.5.0
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
7. As the final action, fill the Jira field "Post-mortem" with a technical bug analysis on the main (parent) task only.

## Required Inputs

This skill may be invoked in forms such as:

```text
/vr-criar-pr
```

```text
/vr-criar-pr PPV-286
```

Interpretation rules:

- If the user provides a task code after the command, treat it as the branch task code to be used for branch naming when required.
- The Jira task from the current context remains the main task for the PR description title unless explicitly unknown.
- If the main context task is unknown and needed for the PR description title, ask the user.
- If the user runs only `/vr-criar-pr`, do not attempt PR creation; instead, provide brief usage instructions and explain how to invoke the skill with a Jira task code.
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
- `main-4-7`, `main-*` (versioned release branches)
- `master`
- `stable-4-4`
- `stable-*`
- any other obviously protected, release, or generic branch

Do not create the PR immediately.

**Automatic sub-task branch resolution:**

Before asking the user for a branch name, attempt automatic resolution using the main Jira task's sub-tasks.

1. Read the main Jira task from the current context and inspect its sub-tasks.
2. Match the current base branch to the corresponding sub-task and target base branch:

   | Current branch | Sub-task summary pattern | Target base branch |
   |----------------|--------------------------|--------------------|
   | `stable-*` | contains **"LTS"** | the current `stable-*` branch |
   | `main-X-Y` (e.g., `main-4-7`) | matches **"MAIN X.Y"** with the same version (e.g., "MAIN 4.7") | `main-X-Y` (e.g., `main-4-7`) |
   | `main` | contains **"MAIN"** with **no** version suffix | `main` |

3. **Versioned MAIN handling:** when a sub-task summary matches the pattern **"MAIN X.Y"** (e.g., "MAIN 4.7"), the target base branch is the versioned branch `main-x-y`, obtained by replacing the dot with a dash (`4.7` → `4-7`) and prefixing `main-` (result: `main-4-7`). Before using it, verify the branch exists in the repository:
   - Check with `git ls-remote --heads origin main-4-7` (or `git branch -a --list "*main-4-7"`), or via the GitHub MCP branch listing.
   - If the branch exists, use it as the target base branch.
   - If the branch does **not** exist, warn the user and ask whether to fall back to `main` or use another branch. Do not silently create the sub-task branch from `main` when a versioned base was expected.
4. **Disambiguation:** a summary containing "MAIN" followed by a version number (e.g., "MAIN 4.7") is a *versioned* MAIN sub-task and must NOT be treated as the plain "MAIN" sub-task. The plain "MAIN" sub-task is the one whose summary contains "MAIN" with no version number and maps to the `main` branch. When both exist (e.g., "MAIN" and "MAIN 4.7"), pick the one matching the current base branch.
5. Use the resolved sub-task's issue key as the new branch name (e.g., `PPV-501`).
6. Before creating the branch, run `git pull` on the target base branch to ensure it is up to date.
7. Create the new branch from the updated target base branch.

If no matching sub-task is found, fall back to asking the user which branch name should be created.

Example A — LTS:

- Current branch: `stable-4-4`
- Main Jira task: `PPV-262`
- Sub-tasks: `PPV-285` (summary: "MAIN - VREncerramento - ..."), `PPV-286` (summary: "LTS - VREncerramento - ...")
- Resolved branch: `PPV-286` (because current branch is `stable-*` and sub-task contains "LTS")
- Commands: `git pull` → `git checkout -b PPV-286`

Example B — versioned MAIN:

- Current branch: `main-4-7`
- Main Jira task: `PPV-498`
- Sub-tasks: `PPV-500` ("MAIN - VRMaster - ..."), `PPV-501` ("MAIN 4.7 - VRMaster - ..."), `PPV-502` ("LTS - VRMaster - ...")
- Resolved sub-task: `PPV-501` (summary matches "MAIN 4.7", which maps to base branch `main-4-7`)
- Verify branch `main-4-7` exists, then: `git checkout main-4-7` → `git pull` → `git checkout -b PPV-501`

### Rule 2: Current branch already contains a task code

If the current branch already contains a task code, even if it is different from the main Jira task in the current context:

- Do not force branch renaming.
- Open the PR using the current branch.
- Keep following the PR template rules from this skill.
- Preserve the main Jira task from the current context in the PR description title section.

### Rule 3: Explicit task code provided in the command

If the user invokes the skill with something like:

```text
/vr-criar-pr PPV-286
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

### Step 2.1: Commit changes

Before creating the PR, commit all staged or pending changes.

The commit message **must** start with the sub-task code (the branch task code), followed by a short description of the change using a conventional tag.

Format:

```text
{sub-task-code} [{tag}] {short description}
```

Supported tags:

| Tag | Uso |
|-----|-----|
| `fix` | Correção de bug |
| `feat` | Nova funcionalidade |
| `refactor` | Reestruturação sem mudança de comportamento |
| `docs` | Alteração em documentação |
| `chore` | Tarefa de manutenção |

Examples:

```text
PPV-282 [fix] protege loop de processamento contra exceções e refatora executor para scheduler
PPV-285 [feat] adiciona validação de cupom no fluxo de encerramento
PPV-286 [refactor] extrai lógica de cálculo fiscal para classe dedicada
```

Rules:

- The sub-task code is the task code from the current branch name (e.g., `PPV-286` if the branch is `PPV-286`).
- If the branch does not contain a task code, use the task code provided in the command or resolved from the sub-task logic.
- The description must be concise and written in lowercase.
- Do not use generic messages like "fix bug" or "update code".

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

### Step 10: Replicate changes to other sub-tasks

After the PR is created successfully for the current sub-task, replicate the same code changes to the remaining sub-tasks of the main Jira task.

**Applicability condition:**

This step only applies when the sub-task used for the current PR is identified as **MAIN** or **LTS** (i.e., its summary contains "MAIN" or "LTS"). If the current sub-task does not match either pattern, skip this step entirely.

**Workflow:**

1. Read the main Jira task's sub-tasks list.
2. Identify all other sub-tasks whose summary contains **"MAIN"** (with or without a version) or **"LTS"** (excluding the one already used in the current PR).
3. For each remaining qualifying sub-task:
   a. Determine its target base branch:
      - If the sub-task summary matches **"MAIN X.Y"** (e.g., "MAIN 4.7") → base branch is the versioned branch `main-x-y` (e.g., `main-4-7`; replace the dot with a dash and prefix `main-`). Verify the branch exists first; if it does not exist, warn the user and ask whether to fall back to `main` or skip that sub-task.
      - If the sub-task summary contains **"MAIN"** with **no** version → base branch is `main`.
      - If the sub-task summary contains **"LTS"** → base branch is the `stable-*` branch (use the same `stable-*` branch from the repository context; if multiple exist, ask the user).
   b. Switch to the target base branch and run `git pull`.
   c. Create a new branch using the sub-task's issue key (e.g., `PPV-285`).
   d. Apply the same code changes (use `git cherry-pick` from the commit(s) of the original PR branch, or re-apply the diff).
   e. If cherry-pick conflicts occur, attempt automatic resolution. If unresolvable, report the conflict to the user and skip that sub-task.
   f. Commit the changes following the same commit message format (Step 2.1), using the new sub-task code.
   g. Push the branch.
   h. Check whether a PR already exists for this branch; if yes, skip PR creation and report the existing PR.
   i. Create a PR following the same template rules (Steps 5–7), using the new sub-task code for the PR title and the main Jira task for the body `<h1>`.
   j. Update the Jira documentation field for the new sub-task following Step 8–9 rules.

4. After processing all sub-tasks, return to the original branch.

**Important rules:**

- Only replicate to sub-tasks that contain "MAIN" or "LTS" in their summary.
- Do not replicate to sub-tasks that have already been completed (status "Done" or "Closed" in Jira).
- If a sub-task already has an open PR, skip it and report the existing PR URL.
- The PR description and documentation content should be the same across all sub-tasks since they represent the same fix applied to different branches.

### Step 11: Fill the Post-mortem field on the main task

As the **final action** — after all PRs have been created and every sub-task documentation field has been updated — fill the Jira field **"Post-mortem"** (`customfield_10074`) on the **main (parent) Jira task only**.

**Scope rule:**

- Fill this field **only on the main Jira task from the current context** (the parent of the sub-tasks, e.g., `PPV-498`).
- **Never** fill the Post-mortem field on the sub-tasks (e.g., `PPV-500`, `PPV-501`, `PPV-502`). It is a single record for the whole fix.

**Jira API requirements:**

- The field identifier is `customfield_10074`.
- The field type is `textarea`, the same as **Informações de Documentação** (`customfield_10037`).
- When calling the Jira MCP `editJiraIssue` tool, set `contentFormat: "adf"` and provide a valid ADF document.

**Content — concise technical bug analysis (for the development team, not end users):**

Unlike **Informações de Documentação** (written in end-user language), the Post-mortem is a **technical** analysis aimed at the development/engineering team. Base it on the inspected diff, commits, and the Jira description/analysis. Write in Portuguese (pt-BR), keep it **short and easy to understand**, and include these sections:

- **Causa raiz:** the real technical cause of the defect, identified from the code and the fix.
- **Solução aplicada:** what was changed to fix it (technical description; classes, queries, methods, or flows may be referenced here).
- **Impacto:** what was affected, the scope, and the severity of the problem.
- **Prevenção:** how to avoid recurrence (tests added, validations, monitoring, follow-ups) when applicable.

Style requirements:

- Be **concise** — ideally one or two short sentences per section; do not write long paragraphs.
- Use **simple, clear language** that any developer can understand quickly. Avoid unnecessary jargon; when a technical term is required, keep it direct.
- Focus on the essentials of each section — no filler, no repetition of the Jira description.

Unlike the documentation field, the Post-mortem does **not** use literal HTML tags or `[[...]]` wiki markup — use normal ADF formatting (bold labels via the `strong` mark are fine).

**ADF content structure:**

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "Causa raiz: ", "marks": [{ "type": "strong" }] },
        { "type": "text", "text": "{descrição técnica da causa raiz}" }
      ]
    },
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "Solução aplicada: ", "marks": [{ "type": "strong" }] },
        { "type": "text", "text": "{o que foi alterado no código}" }
      ]
    },
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "Impacto: ", "marks": [{ "type": "strong" }] },
        { "type": "text", "text": "{áreas afetadas e severidade}" }
      ]
    },
    {
      "type": "paragraph",
      "content": [
        { "type": "text", "text": "Prevenção: ", "marks": [{ "type": "strong" }] },
        { "type": "text", "text": "{como evitar reincidência}" }
      ]
    }
  ]
}
```

**Idempotency:** if the Post-mortem field is already filled on the main task, do not overwrite it silently — show the current content and ask the user whether to replace it.

## Output Expectations

At the end of the execution, report:

1. Which branch was used or created, and which base branch it was created from (including the versioned `main-x-y` case when applicable).
2. Which Jira task was used as the main PR description title.
3. Whether the PR was created successfully.
4. Whether the Jira documentation field was updated successfully.
5. Any point that required user confirmation.
6. Which sub-tasks were replicated successfully and their PR URLs.
7. Which sub-tasks were skipped (already done, already have PR, or conflict) and why.
8. Whether the Post-mortem field was filled on the main task.

## Decision Rules

### Ask the user before proceeding when:

- The user runs only `/vr-criar-pr` without a Jira task code.
- The current branch is `main`, `main-*`, `master`, `stable-*`, or another protected/generic branch and no matching sub-task (LTS/MAIN/MAIN X.Y) can be found automatically.
- A sub-task matches the **"MAIN X.Y"** pattern but the versioned base branch `main-x-y` does not exist in the repository (ask whether to fall back to `main` or use another branch).
- The main Jira task from the current context is unknown but required for the PR description title.
- The application name or menu path required for **Informações de Documentação** cannot be inferred reliably.
- The **Post-mortem** field is already filled on the main task and would be overwritten.
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
- If the user invoked only `/vr-criar-pr`, the skill returned usage instructions instead of opening a PR.
- If no code change is visible, the user was asked whether they want to proceed using only the Jira description.
- If a sub-task matched the **"MAIN X.Y"** pattern, the versioned base branch `main-x-y` was verified to exist and used as the base for the branch and PR (or the user was asked when it was missing).
- If the current sub-task is MAIN, MAIN X.Y, or LTS, changes were replicated to the other qualifying sub-tasks.
- Sub-tasks that are already Done/Closed or already have an open PR were skipped during replication.
- The Jira field **Post-mortem** (`customfield_10074`) was filled on the main task only, using `contentFormat: "adf"` and a technical bug analysis, and never on the sub-tasks.

## Example Scenarios

### Scenario 1: Current branch is task branch

Context:

- Current branch: `feature/PPV-262-ajuste-conferencia`
- Current Jira task in context: `PPV-262`
- Command: `/vr-criar-pr`

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
- Command: `/vr-criar-pr`

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
- Command: `/vr-criar-pr`

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
- Command: `/vr-criar-pr PPV-286`

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

- Command: `/vr-criar-pr`

Expected behavior:

- Do not create PR.
- Show the user how to use the skill.
- Explain that a Jira task code can be passed after the command.

### Scenario 6: Replication to other sub-tasks after PR creation

Context:

- Current branch: `main`
- Current Jira task in context: `PPV-262`
- PPV-262 sub-tasks: `PPV-285` ("MAIN - VREncerramento - ..."), `PPV-286` ("LTS - VREncerramento - ...")
- Command: `/vr-criar-pr`

Expected behavior:

- Detect current branch is `main`.
- Resolve sub-task `PPV-285` (contains "MAIN") and create branch `PPV-285` from `main`.
- Create PR for `PPV-285` (Steps 1–9 as normal).
- **Step 10 triggers:** Current sub-task `PPV-285` is identified as "MAIN", so replication applies.
- Find remaining qualifying sub-task: `PPV-286` (contains "LTS").
- Check if `PPV-286` is Done/Closed → if not, proceed.
- Switch to the `stable-4-4` branch (LTS target), run `git pull`.
- Create branch `PPV-286` from `stable-4-4`.
- Cherry-pick the commit(s) from `PPV-285`.
- Commit with message: `PPV-286 [fix] ...` (same description).
- Push and create PR for `PPV-286` targeting `stable-4-4`.
- Update Jira documentation field for `PPV-286`.
- Return to the original branch.
- Report both PRs created successfully.

### Scenario 7: Versioned MAIN sub-task (MAIN 4.7) and Post-mortem

Context:

- Current branch: `main-4-7`
- Current Jira task in context: `PPV-498`
- PPV-498 sub-tasks: `PPV-500` ("MAIN - VRMaster - ..."), `PPV-501` ("MAIN 4.7 - VRMaster - ..."), `PPV-502` ("LTS - VRMaster - ...")
- Command: `/vr-criar-pr`

Expected behavior:

- Detect current branch is a versioned release branch (`main-4-7`).
- Resolve the sub-task whose summary matches "MAIN 4.7" → `PPV-501`.
- Verify branch `main-4-7` exists; use it as the base branch.
- Run `git pull` on `main-4-7` and create branch `PPV-501` from it.
- Create PR for `PPV-501` targeting `main-4-7`.
- PR title uses `PPV-501`; PR body `<h1>` uses `PPV-498`.
- **Step 10 triggers** (current sub-task contains "MAIN"): replicate to the other qualifying sub-tasks (`PPV-500` → base `main`, `PPV-502` → base `stable-*`), following their own base-branch rules.
- **Step 11 (final):** fill the **Post-mortem** field (`customfield_10074`) with a technical bug analysis on the main task `PPV-498` only — not on `PPV-500`, `PPV-501`, or `PPV-502`.

## Usage Instructions When No Task Is Provided

If the user runs only `/vr-criar-pr`, respond with something like:

- This skill creates a PR from the current Jira context and branch.
- To use it, run `/vr-criar-pr PPV-286` or `/vr-criar-pr` after opening a branch tied to the task.
- If the branch is protected or generic, the skill will ask which branch should be created.

## Authoring Notes

This skill is designed for repositories where fixes are developed from Jira-driven tasks and where the release-fix documentation in Jira must be updated as part of the delivery flow.
