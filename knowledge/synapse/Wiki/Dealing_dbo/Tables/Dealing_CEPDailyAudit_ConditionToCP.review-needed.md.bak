# Dealing_dbo.Dealing_CEPDailyAudit_ConditionToCP — Review Needed

> Items flagged for domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| | | | | | |

## Tier 4 (UNVERIFIED) Columns

- **UpdateDate** — Documented as `GETDATE()` at SP execution; confirm dashboards must use **`ChangeTime`** / **`Date`** for business timelines.

## Columns Needing Clarification

- **RuleID / RuleName / HedgeServerID** when a CP maps to **multiple rules** — confirm expected **row multiplication** per event and standard de-duplication for incident reports.

## Structural Questions

- **Multi-rule fan-out** — Does one condition add/remove always produce **one row per attached rule**, or are there cases where a **single canonical row** is preferred? Operational guidance for analysts.
- **Atlassian / Confluence** — No Jira/Confluence hits in the generating run; if internal CEP runbooks exist, link them in a future documentation pass.
- **Weekly sibling** — Relationship to `Dealing_CEPWeeklyAudit_ConditionToCP` (aggregation rules) should be confirmed by Dealing.
