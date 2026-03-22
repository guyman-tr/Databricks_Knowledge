# Dealing_dbo.Dealing_CEPDailyAudit_CPToRule — Review Needed

> Items flagged for domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| | | | | | |

## Tier 4 (UNVERIFIED) Columns

- **UpdateDate** — Treated as `GETDATE()` at SP execution; confirm reporting standards forbid using it as business time.

## Columns Needing Clarification

- **IsTrue** — Confirm business meaning when **`0`** vs **`1`** in complex rules (exclusion vs inclusion), including nested CP logic if applicable.
- **HedgeServerID** — Confirm authoritative **lookup** (valid values, dimension table, display names).
- **HedgeServerID sourcing** — Wiki states linkage via rules log / `HedgeRuleActionTypeID`-style sourcing in lineage; validate naming for stakeholder docs.

## Structural Questions

- **Row volume** — ~32K rows vs low hundreds in `Dealing_CEPDailyAudit_CP`: confirm this reflects **healthy operational churn** (many rules × CPs) vs data duplication.
- **`varchar(max)`** audit columns — storage / CCI strategy confirmation.
- **Weekly sibling** — `Dealing_CEPWeeklyAudit_CPToRule` aggregation rules vs daily grain (document separately).
