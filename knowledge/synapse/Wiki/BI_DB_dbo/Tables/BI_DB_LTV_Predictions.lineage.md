# Lineage: BI_DB_dbo.BI_DB_LTV_Predictions

## Source Chain

| Hop | Object | Type | Role |
|-----|--------|------|------|
| 0 | BI_DB_LTV_Predictions | Synapse Table | Documentation target; also self-referenced for volatility fix |
| 1 | SP_LTV_Multiplier_Model | Synapse SP | Primary writer — rolling DELETE + INSERT, daily (every 30-day customer milestone) |
| 2 | DWH_dbo.Dim_Customer | Synapse Table | Customer eligibility filter, CountryID, IsDepositor, IsValidCustomer |
| 2 | DWH_dbo.Dim_Country | Synapse Table | Region label from Dictionary.MarketingRegion |
| 2 | BI_DB_dbo.BI_DB_CIDFirstDates | Synapse Table | FirstNewFundedDate — 30-day cadence anchor |
| 2 | BI_DB_dbo.BI_DB_CID_DailyCluster | Synapse Table | ClusterDetail behavioral segment |
| 2 | DWH_dbo.Fact_SnapshotEquity | Synapse Table | RealizedEquity → EquityTier (1/2/3) |
| 2 | DWH_dbo.Dim_Range | Synapse Table | Date range resolution for Fact_SnapshotEquity |
| 2 | DWH_dbo.Dim_Position | Synapse Table | Last position open date → MonthsSinceLastPosOpen |
| 2 | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData | Synapse Table | ACC revenue for recent customers (DateID-based) |
| 2 | BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData | Synapse Table | ACC revenue for older customers + actuals at 12/36/96-month milestones |
| 2 | BI_DB_dbo.BI_DB_LTV_Revenue_Multipliers | Synapse Table | Revenue ratio multipliers per (Seniority × MonthsSinceLastActive) |
| 2 | BI_DB_dbo.BI_DB_LTV_Predictions | Synapse Table (self) | 12-month rolling group average LTV — volatility fix denominator (#MovingAVGPerGroup) |

## T1 Copy Verification

| Column | Source Wiki File | Source Description Copied | Verified |
|--------|-----------------|--------------------------|---------|
| RealCID | DWH_dbo/Tables/Dim_Customer.md row 1 | "Customer ID - platform-internal primary key..." (Tier 1 — Customer.CustomerStatic) | ✓ |

T1 columns: 1 / 16 total. All other 15 columns are SP-computed or dimension-derived (Tier 2/Propagation).

## Upstream Production Sources

| Column(s) | Production Source | Via |
|-----------|------------------|-----|
| RealCID | Customer.CustomerStatic | DWH_dbo.Dim_Customer.RealCID |
| Region | etoro.Dictionary.MarketingRegion | DWH_dbo.Dim_Country.Region |
| EquityTier | Fact_SnapshotEquity.RealizedEquity | DWH_dbo.Fact_SnapshotEquity → CASE bucketing |
| MonthsSinceLastPosOpen | DWH_dbo.Dim_Position | MAX(OpenOccurred) → DATEDIFF |
| Seniority, FirstFundedMonth | BI_DB_dbo.BI_DB_CIDFirstDates.FirstNewFundedDate | DATEDIFF / EOMONTH |
| ClusterDetail | BI_DB_dbo.BI_DB_CID_DailyCluster | Date-range JOIN on CID |
| Current_ACC_Revenue, LTV_1Y/3Y/8Y | BI_DB_dbo.BI_DB_CID_DailyPanel_FullData / BI_DB_CID_MonthlyPanel_FullData | Revenue aggregation + multiplier model |
| LTV_*_VolFix | BI_DB_dbo.BI_DB_LTV_Predictions (self) | 12-month rolling group average |
| LTV_8Y_GroupLevel | BI_DB_dbo.BI_DB_LTV_Predictions (post-INSERT UPDATE) | AVG(LTV_8Y_VolFix) per group |
| UpdateDate | ETL | GETDATE() |

## UC Target

`_Not_Migrated` — no entry found in `main.general.bronze_opsdb_dbo_vw_unitycatalog_mapping_tables`.
