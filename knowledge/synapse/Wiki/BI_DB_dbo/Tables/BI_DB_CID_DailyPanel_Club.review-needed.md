# BI_DB_CID_DailyPanel_Club — Review Notes

## Items Requiring Human Verification

### HIGH — Functional Impact

1. **Deprecated fields still in DDL**: IsExpectedDowngrade, ExpectedDowngradePlayerLevelID, ExpectedDowngradeDate, ExpectedDowngradeTierLT, ExpectedDowngradeStartDate, MonthlyInterestPayments, and Classification are all hardcoded to 0 / NULL / '1900-01-01' in the SP. Confirm with data owners (Tom Boksenbojm) whether these columns should be dropped from the DDL or retained for backward compatibility with downstream consumers.

2. **Revenue methodology discontinuity (2023-08-23 branch change)**: Revenue was sourced from `Fact_CustomerAction` pre-2023 and from `BI_DB_DailyCommisionReport` post-2023. Any cross-date revenue trend analysis over this boundary may show a step-change artifact that is not a business signal. Document whether a reconciliation was done at the time of the switch.

3. **IsFundedCurrentTier equity basis change (2023-01-01)**: Pre-2023, `IsFundedCurrentTier` was based on `RealizedEquity` (includes CFD); post-2023, it is based on `RealizedEquityClub` (excludes CFD, adds eMoney/Moneyfarm). Historical `IsFundedCurrentTier=0` rows may mean something different than post-2023 rows — the denominator changed. Confirm if analysts using this field for historical comparisons are aware.

4. **TierChangeType dual spelling ('First Club' vs 'FirstClub')**: The SP writes both spellings depending on the BI_DB_ClubChangeLogProduct source data. Downstream consumers using `WHERE TierChangeType = 'FirstClub'` will miss ~68% of first-club events; `= 'First Club'` misses ~32%. Verify whether consuming dashboards/reports handle both spellings correctly.

### MEDIUM — Data Quality / Coverage

5. **Club-eligible population definition**: The table excludes customers whose first-and-only club event is an initial Bronze assignment (OldTier IS NULL AND CurrentTier=1). Confirm this is the intended scope for the table's consumers. Some users may expect "all Club members" = all customers at any tier, not just those who progressed beyond initial Bronze.

6. **Moneyfarm and IOB interest external tables**: These use try/catch — if the external table is missing (e.g., pipeline issue), the row still inserts with Moneyfarm=0 and DailyCalculationInterest=0 with no error signal in the output table. Confirm whether monitoring exists for when these external tables fail to populate.

7. **eMoneyBalance uses most-recent EOD balance by GCID (not necessarily today's)**: The query `WHERE DateId <= @ddINT` + ROW_NUMBER ORDER BY DateId DESC means that if eMoney has a gap for a particular GCID on @Date, the previous available balance is carried forward. Confirm this is intentional (use last available balance vs. 0 for missing days).

8. **ROUND_ROBIN distribution with 1.6B rows**: ROUND_ROBIN on a 1.6B row table with no distribution key means CID-level joins will require data movement. Check whether any high-frequency CID-join queries (e.g., AM dashboards) hit this table directly and whether HASH distribution on CID would improve performance.

### LOW — Documentation Gaps

9. **FTCDate / IsFTC in older data (pre-2020-01-01)**: The table starts 2020-01-01 but BI_DB_ClubChangeLogProduct has data back to 2007. FTCDate and IsFTC values for customers whose first promotion occurred before 2020-01-01 should be populated correctly (the SP reads from BI_DB_ClubChangeLogProduct without date limits on the outer apply). Verify no edge cases for very old customers.

10. **AccountManagerID**: Sourced from `Fact_SnapshotCustomer.AccountManagerID`. No FK wiki found for the target AM dimension table. Confirm which dimension table holds AM attributes and whether an AM wiki exists.

11. **No UC migration**: This table has `UC Target: _Not_Migrated`. Confirm if migration is planned or permanently excluded from UC.
