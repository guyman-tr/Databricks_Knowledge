---
object: Dealing_CEPDailyAudit_CP
schema: Dealing_dbo
review_status: pending
generated: 2026-03-21
quality_score: 8.0
---

# Review Needed — Dealing_CEPDailyAudit_CP

## Automated Flags

| Flag | Severity | Detail |
|------|----------|--------|
| varchar(max) columns | Low | RuleName, CPName, TypeOfChange, Comments, LoginName are all varchar(max) — suitable for audit log but no compression benefit in CCI; confirm this is intentional |
| 314 rows total | Info | Very sparse table — confirm expected volume. Is this all changes since Dec 2023 deployment? |

## Questions for Reviewer

1. What is the full list of valid `TypeOfChange` values? From SP source: `New Compound Property`, `Name Change`, `Compound Property Deleted`. Are there others?
2. `LoginName` uses `COALESCE(AppLoginName, PreviousAppLoginName)` — does this always identify the correct user, or are there edge cases where it's NULL?
3. Is the CEP system the eToro in-house hedging engine? Any documentation on how Compound Properties relate to trading decisions?
4. Why does SP_CEPDailyAudit use a `@Date` parameter rather than running against all historical changes — is it called daily via Service Broker?

## Reviewer Corrections

<!-- Add corrections here -->
