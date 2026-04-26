# Review Needed — BI_DB_dbo.BI_DB_Reg_UK_Compliance_Professional_OptUp

**Generated**: 2026-04-21 | **Batch**: 12 | **Quality**: 9.0/10

## Tier 4/5 Items Requiring Review

No Tier 4 or Tier 5 items — all 22 columns are Tier 2/3 with strong SP code authority.

## Questions for Domain Expert

### 1. ApproprietnessTest column — always empty string
- The SP inserts `'' AS ApproprietnessTest` — this is a hardcoded empty string. The column name (note typo: "Approprietness" not "Appropriateness") suggests it was intended to capture an appropriateness test result for MiFID II purposes. Reviewer should confirm: (a) Was this column ever populated? (b) Is there a plan to populate it from a source system? (c) If not, should it be dropped from the table?

### 2. AVGNotionalAmount denominator includes both opened and closed legs
- `AVGNotionalAmount` = SUM(Amount×Leverage) / SUM(TotalPositions) where the denominator counts each position in whichever UNION leg it appears. A position opened more than 12 months ago but closed within 12 months is counted once (closed leg). A position opened within 12 months but not yet closed is counted once (opened leg). A position opened AND closed within 12 months is counted twice (both legs). Reviewer should confirm whether this double-count is intentional or whether the average should count each unique PositionID only once.

### 3. NetProfit scope — closed positions only
- `NetProfit` is the SUM of realized P&L on positions *closed* in the last 12 months — it excludes unrealized P&L on currently open positions. The `MTMEquity` column captures the unrealized component. Reviewer should confirm that downstream consumers understand this split (realized vs. unrealized) and are not summing NetProfit + MTMEquity to get total returns without understanding the different time windows and position scopes.

### 4. @PnLDate vs. @1yearagoid time window mismatch
- `MTMEquity` uses `@PnLDate = GETDATE() - 1` (yesterday's snapshot) while position activity columns use `@1yearagoid = DATEADD(year, -1, GETDATE())` (12-month window). This means a row can have MTMEquity from yesterday's snapshot but OpenedPositions from a different time window. The two metrics are not co-temporal — MTMEquity reflects open positions yesterday; activity counts reflect everything opened/closed in the past year. Reviewer should confirm this is acceptable for the professional opt-up use case.

### 5. PassedSuitabilityTest — fetched but not inserted
- `#Tests` fetches `fd.PassedSuitabilityTest` from `BI_DB_CIDFirstDates` but does not insert it into the final table. Per the CIDFirstDates wiki, `PassedSuitabilityTest` was nullified in 2022-02-22 and contains only NULL. This is a dead column in the SP SELECT. Reviewer should confirm this was intentional removal and the field is not needed.

### 6. Multi-row per CID behavior — downstream consumer awareness
- The table has one row per CID × Holding type (avg 2.27 rows per customer). Downstream queries that treat this as a one-row-per-customer table (without GROUP BY CID) will produce inflated counts. Reviewer should confirm all consuming reports aggregate correctly at the CID level.

## No ALTER Script Generated

ALTER script deferred to `/generate-alter-dwh` pass. UC Target = `_Not_Migrated`, so no ALTER will be generated unless UC migration occurs.
