---
name: vr-analisa-bug
description: Analyze a Jira task using the Jira MCP, classify the bug by complexity, inspect the current repository code to identify the real affected implementation path, and produce either a lightweight or structured correction analysis. Stop immediately if the Jira MCP is unavailable.
---

# Bug Analyzer

Framework for analyzing bug reports from Jira, understanding the failure context, adapting the depth of analysis to the bug complexity, and inspecting the current repository code before proposing the most likely correction path.

## When to Use This Skill

- You received a Jira issue key such as `PPV-262`
- You need to understand a bug before changing code
- You want the analysis effort to match the actual complexity of the problem
- You want the agent to inspect the repository code instead of stopping at a high-level plan

## Mandatory Preconditions

Before starting the analysis:

1. Verify that the Jira MCP is available and operational.
2. If the Jira MCP is not available, do not continue.
3. Clearly state that the request is being stopped because the Jira MCP is required for this skill.
4. If the Jira issue key is missing or invalid, stop and report the issue.
5. Confirm that the current repository is accessible for code inspection.
6. If repository files cannot be inspected, state that the analysis will be limited to Jira understanding only.

## Output Language (MANDATORY)

- **The bug analysis delivered to the user MUST be written in Brazilian Portuguese (pt-BR).**
- This applies to the entire analysis output: problem summary, understanding, code findings, hypotheses, investigation plan, correction plan, confidence level, and any closing questions or suggestions.
- Technical identifiers stay as-is: code symbols, class/method/file names, file paths, log snippets, Jira keys, commit hashes, and command lines are not translated.
- Internal reasoning and tool usage may be in any language, but the **final response shown to the user must be in pt-BR**.
- This rule is non-negotiable and overrides any default tendency to answer in English.

## Primary Objective

Given a Jira task identifier in the format `{tarefa-jira}`, use the Jira MCP and the current repository to:

1. Read the issue description and relevant Jira metadata.
2. Understand the reported problem, expected behavior, impacted flow, and available evidence.
3. Consider any extra information provided by the user together with the command.
4. Classify the bug as low, medium, or high complexity.
5. Inspect the current repository to locate the most likely implementation path related to the bug.
6. Identify the probable code points, classes, methods, event handlers, flows, or rules involved.
7. Produce either a lightweight or structured analysis depending on complexity.

## Non-Negotiable Rule: Inspect the Code

Do not stop at Jira summarization when repository code is available.

Before presenting the correction approach, inspect the current codebase to find concrete implementation evidence such as:

- Candidate classes and methods
- Event listeners and action handlers
- Methods that execute the affected flow
- Calls to persistence, integration, or export routines
- Branches or conditions related to the reported behavior
- Existing code paths in other modules that implement the expected behavior correctly

If a similar correct flow exists elsewhere in the repository, compare both paths and use that comparison in the analysis.

If no relevant code can be found, explicitly say that the code inspection was inconclusive.

## Input Format

Supported invocation patterns:

```text
/vr-analisa-bug PPV-262
```

```text
/vr-analisa-bug PPV-262 Informação adicional: O fluxo manual que está na descrição da tarefa se refere ao fluxo executado pelo VRMaster
```

Interpretation rules:

- The first argument after `/vr-analisa-bug` is the Jira issue key.
- Any remaining text must be treated as complementary context from the user.
- User-provided complementary context must refine the analysis, never replace the Jira task as the primary source.

## Analysis Workflow

### Step 1: Validate Access

- Confirm the Jira MCP is available.
- If unavailable, stop immediately and report that analysis cannot proceed.
- Confirm the Jira issue key is present and appears valid.
- Confirm repository files are accessible for inspection.

### Step 2: Read Jira Task

Collect, when available:

- Issue key
- Title / summary
- Description
- Issue type
- Priority
- Status
- Reporter / assignee when relevant
- Comments or linked context that materially improve understanding
- Acceptance criteria, reproduction steps, expected behavior, and actual behavior

### Step 3: Separate Facts from Interpretation

Organize the task content into three groups:

- **Confirmed facts** — explicit information from Jira
- **Reasonable inferences** — conclusions strongly suggested by the Jira content or user context
- **Unknowns / pending questions** — information missing from the task that blocks higher-confidence analysis

Do not present inferences as confirmed facts.

### Step 4: Incorporate Additional User Context

If the command includes extra notes after `{tarefa-jira}`:

- Merge them into the analysis as supplemental context
- Use them to disambiguate terms, flows, systems, or operational details
- Explicitly call out where the user context clarified or changed the interpretation of the Jira description
- If the user context conflicts with Jira, highlight the conflict instead of silently choosing one source

### Step 5: Classify Complexity

Classify the bug as **Low**, **Medium**, or **High** complexity before deciding the analysis depth.

Use **Low complexity** when most of the following are true:

- Reproduction steps are clear
- Expected and actual behavior are explicit
- The affected flow is short and localized
- There is a probable correction point or small affected area
- There are few unknowns and no major contradictions

Use **Medium complexity** when one or more of the following are true:

- The issue is understandable, but the cause is not obvious
- Multiple components or screens may be involved
- There are some missing details or more than one plausible cause
- The bug may depend on data, sequence of actions, or environment

Use **High complexity** when one or more of the following are true:

- The issue is intermittent, ambiguous, or contradictory
- Multiple plausible root causes exist
- The problem spans several modules, integrations, threads, or environments
- The issue has unclear reproduction or weak evidence
- The risk of confirmation bias is high

Always state the chosen complexity and justify it briefly.

### Step 6: Inspect the Codebase

Inspect the current repository before concluding.

At minimum:

1. Search for domain terms from the Jira issue title and description.
2. Search for classes, methods, screens, actions, or flows related to the reported behavior.
3. Search for the expected correct behavior in related modules or equivalent manual flows.
4. Compare the automatic flow with the reference flow when both exist.
5. Identify concrete files, classes, and methods that are most likely involved.

When reporting findings, cite concrete code locations whenever possible.

### Step 7: Choose the Analysis Mode

After code inspection, decide whether the issue should stay in **Low-complexity mode** or be escalated to **Structured mode**.

If code inspection reveals unexpected branching, multiple candidate paths, missing traceability, or contradictions with Jira assumptions, escalate the issue to Structured mode even if the Jira description initially looked simple.

## Low-Complexity Mode

If the bug remains classified as **Low** after code inspection, keep the analysis lightweight but code-aware.

### Low-Complexity Output

Include only:

1. **Problem summary** — concise description of the bug
2. **Code findings** — concrete files, classes, methods, handlers, or flows inspected
3. **Most likely affected area** — code point most likely responsible
4. **Suggested correction approach** — likely implementation direction based on the inspected code
5. **Validation steps** — how to confirm the issue is fixed
6. **Regression checks** — nearby simple behaviors that should be retested
7. **Confidence level** — High / Medium / Low with short justification

### Low-Complexity Rules

- Prefer a concise response
- Do not generate multiple formal hypotheses unless clearly necessary
- Do not over-engineer the plan
- Base the correction approach on inspected code, not only on Jira wording

## Structured Mode

If the bug is classified as **Medium** or **High**, or if code inspection increases uncertainty, use a deeper and more systematic analysis.

### Structured Hypothesis Categories

Use one or more of these failure categories:

1. **Logic error** — wrong condition, missing branch, invalid workflow transition, incorrect calculation
2. **Data issue** — null or empty values, invalid data format, stale data, inconsistent persistence, conversion issues
3. **State problem** — screen state mismatch, timing issue, event ordering problem, stale in-memory data, improper synchronization
4. **Integration failure** — external dependency, file exchange, service boundary, contract mismatch, failed communication
5. **Resource issue** — locked file, unavailable device, memory pressure, thread contention, performance degradation
6. **Environment/configuration** — locale, timezone, OS behavior, permissions, feature flag, environment-specific setup

### Structured Output

Include:

1. **Problem summary** — concise description of the bug
2. **Current understanding** — confirmed facts, inferences, and unknowns
3. **Code findings** — concrete files, classes, methods, and flow comparisons
4. **Initial hypotheses** — 2 to 5 hypotheses ranked by plausibility
5. **Likely affected areas** — screens, actions, modules, classes, data flows, integrations, or configuration points
6. **Investigation steps** — ordered steps to confirm or eliminate hypotheses
7. **Proposed fix direction** — what kind of correction is likely needed
8. **Validation plan** — how to verify the bug is fixed
9. **Regression checks** — nearby flows or behaviors that may break after the correction
10. **Confidence level** — High / Medium / Low with justification

## Build Validation Preference

When testing the build to validate that the codebase compiles correctly:

- **Prefer Gradle over Maven.** If the repository contains both `build.gradle` (or `build.gradle.kts`) and `pom.xml`, always use Gradle commands (`./gradlew build`, `gradle build`) instead of Maven (`mvn compile`, `mvn package`).
- If only `pom.xml` is present (no Gradle wrapper or build file), fall back to Maven.
- Use the Gradle wrapper (`./gradlew` or `gradlew.bat`) when available.

## Java Swing Investigation Heuristics

When the repository or context indicates a Java Swing application, prioritize checking:

- Event listeners, action handlers, and UI-triggered workflows
- Table models, form bindings, value conversion, and field validation
- Dialog interactions, focus changes, keyboard shortcuts, and component state transitions
- Background workers, timers, EDT usage, and cross-thread UI updates
- File operations, printer interactions, local configuration, and desktop-specific resources
- Data synchronization between UI state and domain/application state

If the issue appears to be a desktop-flow bug, prefer checking event ordering, stale screen state, invalid component enable/disable rules, or EDT/thread misuse before assuming external integration failure.

## Output Structure

Use one of the following response formats depending on complexity. **Regardless of the chosen format, the response must be written in Brazilian Portuguese (pt-BR)** — see "Output Language (MANDATORY)".

### Format A: Low complexity

#### 1. Jira task analyzed
- Issue key
- Title
- Status / priority when available

#### 2. Problem understanding
- Confirmed facts from Jira
- Additional user context, if provided
- Gaps that still matter

#### 3. Code findings
- Files, classes, methods, or handlers inspected
- Equivalent reference flow if found
- Most likely affected implementation point

#### 4. Correction approach
- Suggested correction direction based on the inspected code
- Validation steps
- Simple regression checks

#### 5. Confidence level
- High / Medium / Low
- Short justification

### Format B: Medium or high complexity

#### 1. Jira task analyzed
- Issue key
- Title
- Status / priority when available

#### 2. Problem understanding
- Confirmed facts from Jira
- Additional user context, if provided
- Inferences
- Gaps or ambiguities that remain

#### 3. Code findings
- Concrete files, classes, methods, and flow comparisons

#### 4. Initial hypotheses
- 2 to 5 hypotheses with category and rationale

#### 5. Investigation plan
- Ordered list of technical checks

#### 6. Correction plan
- Proposed fix direction
- Validation steps
- Regression checks
- Risks and impacted areas

#### 7. Confidence level
- High / Medium / Low
- Short justification

## Decision Rules

### Stop Conditions

Stop immediately when:

- Jira MCP is unavailable
- The Jira task cannot be accessed through the Jira MCP
- The provided issue key is invalid or missing

### Quality Rules

- **Always deliver the final analysis to the user in Brazilian Portuguese (pt-BR)** — see the "Output Language (MANDATORY)" section
- Prefer facts from Jira over assumptions
- Explicitly separate confirmed information from inference
- Match the analysis depth to the bug complexity
- Inspect the codebase before proposing the correction path when repository access exists
- Use concise and implementation-oriented language
- Do not continue with speculative analysis if the core Jira context cannot be retrieved
- Do not skip the MCP availability check
- Avoid heavyweight investigation structure for clearly simple issues
- Do not state that a hypothesis is confirmed unless the available evidence clearly supports it
- Do not present only a high-level plan when concrete code evidence can be inspected

## Example Behavior

### Example 1

Input:

```text
/vr-analisa-bug PPV-262
```

Expected behavior:

- Read Jira task `PPV-262` via Jira MCP
- Classify the bug complexity
- Inspect the repository code related to the issue
- If simple, return a lightweight but code-based correction analysis
- If not simple, return a structured investigation and correction analysis grounded in code findings

### Example 2

Input:

```text
/vr-analisa-bug PPV-262 Informação adicional: O fluxo manual que está na descrição da tarefa se refere ao fluxo executado pelo VRMaster
```

Expected behavior:

- Read Jira task `PPV-262` via Jira MCP
- Use the additional note to clarify that the manual flow refers to VRMaster
- Inspect code for both the automatic and reference manual flows when possible
- Reclassify complexity if code inspection changes the understanding
- Return either a lightweight or structured analysis depending on the complexity and code findings

## Authoring Notes

This skill is designed to work as a pre-implementation analysis step. Its purpose is to improve problem understanding and fix planning before code changes begin, without forcing heavyweight analysis on simple issues.

It is especially useful for desktop applications and Java Swing codebases where some bugs are highly localized while others depend on UI events, local state, user interaction sequences, or environment-specific behavior.
