---
name: wiki-review
description: Interactive conversational review of semantic wiki documentation. Use when the user says review, correct, approve, fix, what needs review, show unverified, or mentions a column/table they want to correct in the wiki. Walks through review items one at a time and writes corrections to the sidecar and glossary automatically.
---

# Wiki Review — Interactive Correction Skill

## Trigger Phrases

Activate when the user says any of:
- "review {TableName}" — full walkthrough of flagged items
- "correct {ColumnName}" or "fix {ColumnName}" — single column correction
- "what needs review?" or "review status" — summary across all tables
- "approve {ColumnName}" — mark as verified (promote to Tier 5)
- "dismiss {ColumnName}" — mark as not applicable / deprecated
- Any natural language correction like "CBH means Compute Before Hedge"

## Core Behavior

You are a **review assistant**. Your job is to make reviewing wiki documentation painless and conversational. The human should never need to edit a markdown table manually.

### Step 1: Locate Review Files

```
Sidecar pattern: knowledge/synapse/Wiki/{Schema}/Tables/{ObjectName}.review-needed.md
Glossary:        knowledge/glossary.md
Wiki:            knowledge/synapse/Wiki/{Schema}/Tables/{ObjectName}.md
ALTER script:    knowledge/synapse/Wiki/{Schema}/Tables/{ObjectName}.alter.sql
```

Read all `.review-needed.md` files to build the review queue. Use Glob: `knowledge/**//*.review-needed.md`

### Step 2: Present Items Conversationally

**DO NOT dump the entire sidecar.** Present ONE item at a time in this format:

```
Column: {ColumnName}
Tier: {current tier}
Current description: "{short excerpt}"
Question: {the pipeline's question}

What's your take? (correct / approve / skip / dismiss)
```

After the user responds, immediately write the correction and move to the next item.
If the user says "skip", move on silently. If "dismiss", mark as deprecated/N/A.

### Step 3: Write Corrections — IMMEDIATE PROPAGATION

When the user provides a correction, apply it to **all three targets simultaneously**:

1. **Wiki (.md)** — find the column in the Elements table (Section 4) and update the description
   in-place. Change the tier tag to `(Tier 5 — domain expert)`. Also update any references in
   Business Logic (Section 2), Query Advisory (Section 3), or Relationships (Section 6).

2. **ALTER script (.alter.sql)** — find the matching `ALTER TABLE ... ALTER COLUMN ... COMMENT`
   line and update the comment text to reflect the correction (respect 1024-char UC limit).
   Read the `-- UC Target:` and `-- Resolved via:` lines in the ALTER script header to confirm
   the UC target is validated. If the header says `INFERRED (unvalidated)`, warn the user:
   "The UC target for this table hasn't been validated against Unity Catalog yet. The ALTER
   script may be targeting a non-existent object." If Databricks is available, offer to run
   the UC Object Resolution algorithm from Phase 11 to fix the target before continuing.

3. **Sidecar (.review-needed.md)** — add a row to `## Reviewer Corrections`:

```markdown
| {Column/Topic} | {old value} | {user's correction} | {scope} | {user name from context} | {today's date} |
```

- Set `Scope = glossary` if the correction is a domain term (acronym, value map) that applies beyond this one table
- Set `Scope = table` if it's specific to this table/column

4. **Glossary** — if `Scope = glossary`, also add the entry to `knowledge/glossary.md` in the appropriate section (`## Acronyms & Terms` or `## Value Maps`)

5. **Confirm** — respond with a brief confirmation:
   ```
   Got it — {ColumnName} corrected. Updated wiki + ALTER script + sidecar{+ glossary}.
   Next: {next item preview} or "That's all for {TableName}!"
   ```

**Why all three?** The wiki and ALTER script give the user immediate feedback. The sidecar and
glossary ensure corrections survive a full pipeline rerun.

### Step 4: Status Summary

When the user asks "what needs review?" or "review status":

```
{TableName}: {N} items pending, {M} corrected, {K} approved
  - {tier 4 count} unverified columns
  - {clarification count} needing clarification
  - {structural count} structural questions
```

## Modes

### Full Review: "review Dim_Position"
1. Read the sidecar
2. Start with Tier 4 items (highest priority for correction)
3. Then clarification items
4. Then structural questions
5. After each: ask for next or stop

### Single Correction: "correct InitHedgeType" or "InitHedgeType means X"
1. Find the column in the wiki
2. Show current description
3. Apply correction to wiki + ALTER script + sidecar (+ glossary if domain-wide)
4. Done — no walkthrough

### Quick Correction: "CBH means Compute Before Hedge"
1. Detect this is a term/acronym correction
2. Search all wikis for where the term appears
3. Update every occurrence in wiki + ALTER script
4. Write to glossary + relevant sidecars
5. Done

### Approve: "approve PlatformTypeID — it's deprecated"
1. Update wiki description to include reviewer's note, set Tier 5
2. Update ALTER script comment
3. Add to sidecar corrections
4. Remove from Tier 4 section on next rerun

## Important Rules

- **Never show raw markdown tables** to the user — always conversational format
- **Always confirm** what you wrote and where
- **One item at a time** — don't overwhelm
- **Accept natural language** — the user shouldn't need to learn syntax
- **Infer scope** — if a term is clearly domain-wide (like an acronym), suggest `glossary` scope
- **Infer reviewer name** — use the git user name or OS username from context
- **Date** — use today's date automatically
- When the user provides a correction inline (e.g., "correct HedgeType — CBH is Compute Before Hedge"), apply it immediately without asking clarifying questions unless truly ambiguous
