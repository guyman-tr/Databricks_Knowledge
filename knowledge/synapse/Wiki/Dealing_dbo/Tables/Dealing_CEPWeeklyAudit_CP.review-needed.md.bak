# Dealing_dbo.Dealing_CEPWeeklyAudit_CP — Review Needed

> Items flagged for domain expert review.

## Reviewer Corrections

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|
| | | | | | |

## Tier 4 (UNVERIFIED) Columns

- **UpdateDate** — Documented as `GETDATE()` at SP execution; confirm consumers must not treat it as the **business** event clock (**use `ChangeTime`** / week boundaries instead).

## Columns Needing Clarification

- **`ToDate` boundary** — Confirmed in docs as **Sunday 00:00:00** (not end-of-day). Validate against **downstream dashboards** and **any** reporting that assumed **inclusive Sunday EOD**.

## Structural Questions

- **No-change rows** — Confirm **standard filter** **`WHERE TypeOfChange IS NOT NULL`** for **official** change reports vs **operational** “week touched” checks.
- **`CPName` vs `CP_Name`** — **Weekly CP** uses **`CPName`**; **daily** **`Dealing_CEPDailyAudit_CP`** uses **`CP_Name`**. Confirm **intentional** vs **drift** and whether **aliases** should be standardized in views.
- **Atlassian / Confluence** — No Jira/Confluence hits in the generating run; link internal runbooks if available.
- **Historical cutover** — Confirm **Sep 2021** weekly start vs **Dec 2023** daily start messaging for **analyst onboarding**.
