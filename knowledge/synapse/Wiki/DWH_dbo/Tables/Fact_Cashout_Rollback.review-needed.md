# DWH_dbo.Fact_Cashout_Rollback — Review Needed

> Items flagged for offline domain expert review. The pipeline continues end-to-end; review happens asynchronously. Add corrections to `## Reviewer Corrections` and trigger a review-rerun to regenerate and re-deploy.

## Reviewer Corrections

> **Instructions**: Add corrections below. Each row becomes a Tier 5 (domain-expert confirmed)
> override on the next pipeline rerun. Use `glossary` in the Scope column if the term should
> also be added to `knowledge/glossary.md`.

| Column / Topic | Current (wrong) | Correction | Scope | Reviewer | Date |
|----------------|-----------------|------------|-------|----------|------|

## Tier 4 (UNVERIFIED) Columns

No Tier 4 (UNVERIFIED) columns. All 28 columns have Tier 1 or Tier 2 confidence.

## Columns Needing Clarification

| Column | Question | Evidence |
|--------|----------|----------|
| PaymentStatusID | The upstream wiki states this is "always 2" in production data. Does this hold true across all DWH data, or have newer flows introduced other values? | Upstream wiki: "Always 2 across all 7,349 rows (set from @CashoutStatusID parameter)." However, the column is typed as int and allows other Dictionary.PaymentStatus values. |
| RollbackReason | No Dictionary lookup table exists for this code. Can a domain expert confirm the meaning of values 0, 1, 3, and 4? | Upstream wiki: "0=default/unknown (1,170 rows), 1=standard (70 rows), 3=dominant (6,080 rows), 4=correction events (29 rows)." The meanings are inferred from distribution patterns. |
| NetUSDAmount | Despite the column name suggesting USD, the upstream wiki describes `WithdrawToFunding.Amount` as "payout amount in ProcessCurrencyID currency" — not necessarily USD. Is this column always in USD, or is it in the processing currency? | Production SP: `CAST(ISNULL(BWTF.Amount, 0) AS decimal(16, 2)) AS [Net $ Amount]`. The `$` in the alias suggests USD but the source column is ProcessCurrencyID-denominated. |
| Brand | This column is populated via XML parsing of `FundingData` for card type. For non-card payments, is this always NULL or can it have unexpected values? | Production SP: `DCTY.Name AS [Brand]` where DCTY is LEFT JOINed from Dictionary.CardType via XML-parsed CardTypeID. |

## Structural Questions

| Question | Context |
|----------|---------|
| What is the expected row count growth rate for this table? | The production source had 7,349 rows as of the upstream wiki generation date. Is rollback a rare event (hundreds/year) or common (thousands/day)? |
| Is there a plan to add a unique key or primary key to this DWH table? | The table currently has no uniqueness constraint — only a clustered index on CID for performance. Multiple rows can exist for the same combination of CID + WithdrawID. |
| Why does the ETL SP use `dateadd(day, 1, @CurrentDate)` in the INSERT WHERE clause but `@CurrentDate` in the DELETE? | The DELETE uses `ModificationDateID < convert(INT,convert(varchar, @CurrentDate, 112))` while the INSERT uses `StatusModificationTime < dateadd(day, 1, @CurrentDate)`. This means the INSERT captures one extra day compared to the DELETE window. Is this intentional to catch late-arriving data? |

## Tier 5 Re-Review Needed

> Tier 5 (domain expert) overrides whose underlying Tier 1–3 source has materially changed
> since the correction was made. The Tier 5 is still applied, but a domain expert should
> confirm it remains valid given the new upstream definition.

| Column | Tier 5 Correction | Was Based On (old Tier 1–3) | New Tier 1–3 | Change Summary |
|--------|-------------------|----------------------------|--------------|----------------|
