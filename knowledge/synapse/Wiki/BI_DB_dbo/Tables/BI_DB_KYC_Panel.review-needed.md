# Review Needed: BI_DB_dbo.BI_DB_KYC_Panel

## Known Anomalies

- **`RegulatgionName` column typo**: Column is named `[RegulatgionName]` (extra 'g' in "Regulation"). This is a persistent typo in both the DDL and SP code — the SP references `[RegulatgionName]` explicitly. The column cannot be renamed without altering both table and SP. Consumers must use square-bracket quoting: `[BI_DB_KYC_Panel].[RegulatgionName]`.

- **`DaysFromFTD_Group` is temporally unstable**: Computed as `DATEDIFF(DAY, FTD_Date, GETDATE()-1)`. A customer who deposited 7 days ago will have DaysFromFTD_Group='1-7' today and '8-14' tomorrow. This column changes every run — it is NOT a stable classification. It must not be used in time-series comparisons or as a join key.

- **`Total_Points_Assessment_142_146` sentinel -100**: The value -100 is a sentinel meaning "this customer has Assessment_Type ≠ 'AnswerID_142_146'". Failure to filter by Assessment_Type before aggregating this column will produce nonsensical averages (most of the table has -100).

- **GCID as distribution key, not RealCID/CID**: Unusually, this table distributes on GCID (UserApiDB's identifier) rather than the standard RealCID. Joins from Dim_Customer and fact tables must use `RealCID` (= `BI_DB_KYC_Panel.RealCID`), not GCID.

- **OpsDB false dependency**: OpsDB dependency table lists `SP_Regulation_Change_Abuse → BI_DB_KYC_Panel`. Code-level inspection of SP_Regulation_Change_Abuse confirms zero references to BI_DB_KYC_Panel. This is a stale or operational scheduling artifact — the dependency does NOT exist at the data level.

- **FTD_Date = '1900-01-01' for non-depositors**: Rather than NULL, non-depositor customers have FTD_Date set to the sentinel date '1900-01-01'. Queries must filter `WHERE FTD_Date > '1900-01-01'` or `WHERE IsFTD = 1` to restrict to depositors.

- **Q15/Q26 multi-select `_AnswerID` columns**: For multi-select questions Q15 and Q26, the `_AnswerID` column contains only the last/primary answer ID — not a complete representation of all selections. Use the `_AnswerText` (STRING_AGG) columns for full multi-select analysis.

## Tier 3 / Low-Confidence Items

- **`Age_On_Reg`**: Confident this is age at registration from Dim_Customer, but the exact computation (BirthDate vs. RegisteredReal) was not verified in SP code. Marked T3.

## Reviewer Questions

1. **Assessment_Type generation boundaries**: Are the answer ID ranges (84-87, 101-104, 142-146) stable? Could new questionnaire versions add ranges beyond 146? If so, Assessment_Type='N/A' could be masking a new fourth generation rather than "no assessment".

2. **Q23 vs. Q33/Q34/Q35 relationship**: Is Q23 a separate assessment question from the experience questions (Q33/Q34/Q35)? The Assessment_Type logic appears to derive from Q23_AnswerID range, while Experience_Level derives from Q33/Q34/Q35. Confirm whether Q23 and the Q33/Q34/Q35 cluster are from different questionnaire sections or the same form.

3. **Q50 vulnerable client scope**: Q50 (FCA Consumer Duty vulnerable client) appears for FCA-regulated customers only. Will this column ever be populated for non-FCA customers, or should queries always filter `WHERE [RegulatgionName] = 'FCA'` when analyzing Q50?

4. **Q30/Q36/Q40 US-only questions**: Q30 (FINRA), Q36 (US permanent residency), Q40 (W9 certification) appear to be US-regulated-only questions. Confirm: are these questions ever presented to non-US customers? If non-US customers can never answer these, the flags will always be NULL/0 for those populations.

5. **`BI_DB_Scored_Appropriateness_Negative_Market` CFD source**: The CFD_Status and related columns come from this table via LEFT JOIN. Does this table have daily coverage for all customers, or only customers who have been explicitly evaluated? The 16.9% NULL rate in CFD_Status suggests a significant unassessed population — confirm whether this is "never evaluated" or "evaluation not completed yet".

6. **Deposit/Revenue/Equity 7/14/30-day windows**: These come from BI_DB_First5Actions. Are they cumulative totals from FTD (days 0-7, 0-14, 0-30) or rolling windows? The naming suggests since-FTD windows, but the 14-day and 30-day figures should be >= 7-day figures if cumulative.

7. **Post-insert NULL-answer delete scope**: The SP deletes rows "where ALL KYC answers are NULL". What is the scope of "all KYC answers" — all Q* columns, or just the core assessment columns (Q33/Q34/Q35)? A customer who answered only Q30 (FINRA) but no assessment questions would be deleted if the SP checks core assessment columns only.
