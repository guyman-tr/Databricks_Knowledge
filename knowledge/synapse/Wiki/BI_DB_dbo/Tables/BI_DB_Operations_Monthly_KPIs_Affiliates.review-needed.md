# Review Needed: BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Affiliates

## Tier 4 / Low-Confidence Items

No Tier 4 columns in this table. All columns traced to Fact_BillingWithdraw wiki (Tier 1) or SP code analysis (Tier 2).

## Reviewer Questions

1. **ReqCyTime vs RequestDate — are these truly identical?** The SP assigns `bw.RequestDate AS ReqCyTime`. If this was originally intended as a Cyprus-timezone-adjusted timestamp (UTC+2 or UTC+3), the conversion is missing. Confirm with Operations whether ReqCyTime is supposed to differ from RequestDate.

2. **ModCyTime vs ModificationDate — same question.** The SP assigns `bw.ModificationDate_WithdrawToFunding AS ModCyTime`. Same value as ModificationDate. Were these columns originally intended to carry timezone-adjusted values for monitoring in Cyprus business hours?

3. **Pre-2021 SLA CASE block is dead code.** The SP duplicates the SLA computation in two CASE blocks with a `>= '2021-01-01'` / `< '2021-01-01'` split. Since the rolling window covers only the past 6 months, the pre-2021 block never executes. Is this intentional preservation for re-run scenarios, or can it be removed?

4. **ModificationDate naming ambiguity.** This column maps to `ModificationDate_WithdrawToFunding` (the payment processing leg date), not `Billing.Withdraw.ModificationDate`. The column name is misleading and has caused confusion in past analyses. Is there a plan to rename it to `ProcessorModificationDate` or similar?

5. **WD_ID_SLA per payment leg — de-duplication scope.** WD_ID_SLA is the MIN across all legs of a WithdrawID, repeated on each leg row. If an analyst groups by WithdrawID for a withdrawal-level SLA view, they should use `MAX(WD_ID_SLA)` or `MIN(WD_ID_SLA)` rather than a direct GROUP BY count. Confirm this is the intended usage pattern with the Operations team.

## Known Anomalies

- `RequestDay` DDL type is `datetime` but SP inserts `DATEPART(dw, RequestDate)` (an int) — implicit conversion stores day-of-week as a 1900-01-0N datetime. Always cast to int before arithmetic.
- `FundingID` is NULL for eToroMoney (FundingTypeID=33) withdrawals — 52%+ of rows. JOINs to Billing.Funding will miss majority of rows.
- Pre-2021 SLA CASE block in SP is inert with the 6-month rolling window but adds ~150 lines of dead code and maintenance risk.
- Only 2 rows in current data fail SLA/SLA48 (WD_ID_SLA='OverallNotSLA'). Near-perfect SLA compliance may mask issues if the window is insufficient or if thresholds are too permissive.
