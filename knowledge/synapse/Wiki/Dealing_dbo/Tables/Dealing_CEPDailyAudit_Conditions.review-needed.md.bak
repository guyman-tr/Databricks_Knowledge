# Dealing_dbo.Dealing_CEPDailyAudit_Conditions — Review Needed

> Items flagged for domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| | | | | | |

## Tier 4 (UNVERIFIED) Columns

- **UpdateDate** — Documented as `GETDATE()` at SP execution; confirm dashboards must use **`ChangeTime`** / **`Date`** for business timelines.

## Columns Needing Clarification

- **`RuleID` / `RuleName` / `HedgeServerID`** — Confirm resolution when a condition’s CP maps to **multiple rules** (row multiplication vs canonical reporting).
- **`Value`** — Confirm typical formats (numeric strings, enums, multi-value) and any **parsing** standards for analytics.

## Structural Questions

- **Property vocabulary** — What are the most common **`Property`** values in production? A short **controlled vocabulary** appendix would help analysts.
- **Concurrent changes** — When multiple attributes change on the **same condition** and **same date**, confirm expected **row granularity** vs **single consolidated** row.
- **Atlassian** — No Jira/Confluence hits in the generating run; link internal **CEP** runbooks if they exist.
- **Weekly sibling** — Confirm aggregation rules vs **`Dealing_CEPWeeklyAudit_Conditions`**.
