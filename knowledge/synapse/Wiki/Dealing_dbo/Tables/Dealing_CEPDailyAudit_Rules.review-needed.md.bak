# Dealing_dbo.Dealing_CEPDailyAudit_Rules — Review Needed

> Items flagged for domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| | | | | | |

## Tier 4 (UNVERIFIED) Columns

- **UpdateDate** — Documented as `GETDATE()` at SP execution; confirm dashboards must use **`ChangeTime`** / **`Date`** for business timelines.

## Columns Needing Clarification

- **HedgeServerID** — Renamed from **`HedgeRuleActionTypeID`** in source; confirm **valid values**, **lookup table**, and operational meaning per ID.

## Structural Questions

- **Rule inventory** — Typical **active rule count** and **total** rule count for sanity-checking audit volume (~1K rows in sampled window).
- **Email / view path** — **`V_Dealing_CEPDailyAudit_Rules_Last180Days`** is referenced by **`SP_CEPDailyAudit_Emails`** (stub in some environments). Confirm whether **email notification** is **live**, **deprecated**, or **environment-specific**.
- **Atlassian / Confluence** — No Jira/Confluence hits in the generating run; if internal CEP runbooks exist, link them in a future documentation pass.
- **Weekly sibling** — Relationship and **reconciliation** expectations vs **`Dealing_CEPWeeklyAudit_Rules`** (weekly grain from **Sep 2021**).
