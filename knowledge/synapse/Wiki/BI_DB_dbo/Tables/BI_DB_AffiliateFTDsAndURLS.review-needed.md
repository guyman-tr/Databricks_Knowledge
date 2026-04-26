# Review Needed: BI_DB_dbo.BI_DB_AffiliateFTDsAndURLS

Generated: 2026-04-21 | Batch 13 #3

## Tier 4 Items (Low Confidence — Needs Verification)

_No Tier 4 items. All columns resolved to Tier 1, Tier 2, or Tier 5._

## Open Questions for Reviewers

1. **FTDs_Total / Registration_Total off-by-one (ELSE 0 bug)**: The SP computes totals using `COUNT(DISTINCT CASE WHEN cast(fd.FirstDepositDate as date)=@Date THEN fd.CID ELSE 0 END)`. Using `ELSE 0` instead of `ELSE NULL` means COUNT DISTINCT always includes the value 0 as one distinct entry, even when no clients had an FTD on @Date. This inflates both `FTDs_Total` and `Registration_Total` by 1 for rows where the relevant event did not occur on @Date (confirmed: all 29,564 registration-only rows have FTDs_Total=1, not 0). Is this a known accepted behavior or a bug that needs fixing?

2. **SP INSERT/SELECT column order mismatch**: The SP's INSERT column list (lines 119–146) lists `FTDs_FSRA` at position 12 and `FTDs_FSA_Seychelles` at position 13. But the SELECT list (lines 149–178) has `FTDs_FSA_Seychelles` at position 12 and `FTDs_FSRA` at position 13. This means `FTDs_FSA_Seychelles` and `FTDs_FSRA` values are swapped in the INSERT. Reviewer should verify whether FTDs_FSA_Seychelles and FTDs_FSRA contain the correct values or are transposed in the stored data.

3. **Dead join (BI_DB_CIDFirstDates fd1)**: The SP joins `BI_DB_CIDFirstDates fd1 ON fd1.CID = da.TradingAccount_RealCID` but `fd1` is never referenced in the SELECT or WHERE clause. This appears to be a dead join carried from an earlier version of the SP. Does it affect correctness? It may cause row multiplication if `da.TradingAccount_RealCID` matches multiple CIDFirstDates rows. Confirm whether this join should be removed.

4. **Channel filter scope**: This SP filters `fd.Channel = 'Affiliate'` only — it does NOT include 'Introducing Agents'. The affiliate monthly tables (Objects #1 and #2) include both channels. Is this intentional — i.e., IB-channel data is excluded from this URL/FTD tracking report?

5. **Registration_FCA type is INT (not BIGINT)**: All other Registration_* columns are BIGINT. Registration_FCA is INT in the DDL. Confirm whether this is intentional or a type inconsistency from the column being added separately.

6. **29,564 rows with FirstDepositDate = 1900-01-01**: These are rows where the affiliate had a client register on @Date but no FTD existed (BI_DB_CIDFirstDates.FirstDepositDate = 1900-01-01 sentinel). Confirm whether these rows should be retained or filtered during INSERT (e.g., only insert rows where at least one meaningful event occurred).

7. **Multiple rows per affiliate per day**: Because the GROUP BY includes both FTD date and Registration date, an affiliate can produce multiple rows for the same @Date run if clients had events on different underlying dates. Downstream consumers of this table should be aware of this and sum appropriately, not just SELECT DISTINCT on AffiliateID + Date.

## Correction Notes

- **SP frequency change**: SP was changed from **monthly to daily** on 2025-02-17 by Pavlina Masoura. Historical rows (pre-Feb 2025) were loaded at monthly grain; daily grain applies only to subsequent loads. Rows loaded under the monthly SP may not accurately reflect individual days within a month.
- **DDL column count**: DDL defines 29 columns total. The SP INSERT/SELECT only references 27 named columns. Column 28 and 29 (Registration_FCA and Registration_FSRA from DDL) are present in both INSERT and SELECT. All 29 DDL columns are populated.
