# Review Needed: BI_DB_dbo.BI_DB_LTV_Predictions

## Items Requiring Human Review

### 1. Region Column: Dim_Country.Region vs. MarketingRegionManualName
**What**: The SP uses `dc1.Region` from Dim_Country. The wiki documents this as the automated `etoro.Dictionary.MarketingRegion.Name` (NOT `MarketingRegionManualName`).
**Why**: Sibling table BI_DB_LiveAcquisitionDashboard_Daily uses `MarketingRegionManualName` from Dim_Country. The LTV model explicitly uses `.Region`. The two tables may have subtly different region labels for edge-case countries.
**Action**: Verify by comparing `SELECT DISTINCT Region FROM BI_DB_LTV_Predictions` against `SELECT DISTINCT Region FROM Dim_Country`. If they match the automated column (not manual override), the wiki is correct.

### 2. LTV_Revenue_Multipliers Coverage for NULL LTV Rows
**What**: Rows with `Current_ACC_Revenue = 0` or missing multiplier entries produce `LTV_1Y/3Y/8Y = 0.0`. The wiki notes this but does not quantify coverage.
**Why**: The sample shows several rows with `LTV_8Y_VolFix = 0.0` and empty FirstFundedMonth/Seniority (legacy depositors without FirstNewFundedDate).
**Action**: Quantify the proportion of zero-LTV rows and document whether these represent a known data quality issue or expected population.

### 3. BI_DB_CIDFirstDates and BI_DB_CID_DailyCluster Wikis Not Yet Documented
**What**: Two key upstream inputs — `BI_DB_CIDFirstDates` and `BI_DB_CID_DailyCluster` — are referenced in the lineage but their wikis have not been written.
**Why**: These tables were not included in the current or prior batch schedule.
**Action**: Prioritize these in a future batch to complete the LTV lineage chain.

## Auto-Passed Items

| Check | Result |
|-------|--------|
| All 16 columns documented | PASS |
| RealCID traced to Customer.CustomerStatic (Tier 1) | PASS |
| UpdateDate uses Propagation tier | PASS |
| Rolling DELETE+INSERT (not TRUNCATE) semantics documented | PASS |
| 30-day cadence rule explained | PASS |
| Predicted vs. actual LTV switchover at milestones documented | PASS |
| Volatility fix clamping logic [0.5, 2.0] documented | PASS |
| Self-referential table read in VolFix noted in lineage | PASS |
| LTV_8Y_GroupLevel post-INSERT UPDATE mechanism documented | PASS |
| EquityTier NULL handling documented in Gotchas | PASS |
