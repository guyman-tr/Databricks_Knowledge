---
object: BI_DB_dbo.BI_DB_Cross_Selling_Monthly
type: Table
lineage_generated: 2026-04-23
writer_sp: SP_Cross_Selling_Monthly
load_pattern: DELETE WHERE DateKey=@date_int + INSERT (EOM-only, runs only when @date = EOMONTH(@date))
uc_target: _Not_Migrated
---

# Column Lineage — BI_DB_Cross_Selling_Monthly

## ETL Pipeline

```
SP guard: IF @date = EOMONTH(@date) → ABORT if not last day of month
  ↓
DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Country
  └─ Population: IsValidCustomer=1, IsDepositor=1, SCD2 current record → #CIDs (RealCID, Country, Region)
DWH_dbo.V_Liabilities (DateID=@date_int)
  └─ Equity = ActualNWA + Liabilities → High_Bronze+ (equity >= $1,000)
BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData (@beginning_of_Month)
  └─ EOM_Club, ClusterDetail (beginning-of-month snapshot)
DWH_dbo.Dim_Position + Dim_Instrument (open at @date, MirrorID=0)
  └─ ETF_HoldEOM (InstrumentTypeID=6, IsSettled=1)
  └─ Real_Crypto (InstrumentTypeID=10, IsSettled=1) [Hold branch]
  └─ Real_Non_US_Stocks (InstrumentTypeID=5, non-US exchange) [Hold branch]
  └─ Real_US_Stocks (InstrumentTypeID=5, US exchanges) [Hold branch]
DWH_dbo.Dim_Mirror (open at @date)
  └─ Smart_Portfolios_HoldEOM (MirrorTypeID=4)
  └─ Copy_Trader_HoldEOM (MirrorTypeID≠4)
DWH_dbo.Dim_Position + Dim_Instrument (@StartOpenDate..@date, MirrorID=0)
  └─ @StartOpenDate = DATEADD(month, -2, @beginning_of_Month)  ← 2-month window (note: column says "3M")
  └─ CFD_ActiveOpen3M (IsSettled=0, position opened in last 2M)
  └─ Real_Crypto (InstrumentTypeID=10) [ActiveOpen3M branch]
  └─ Real_Non_US_Stocks (InstrumentTypeID=5, non-US) [ActiveOpen3M branch]
  └─ Real_US_Stocks (InstrumentTypeID=5, US exchanges) [ActiveOpen3M branch]
DWH_dbo.Fact_CustomerAction (ActionTypeID IN 15,17, @StartOpenDate..@date)
  └─ Copy actions in last 2M → Smart_Portfolios_HoldEOM (ActiveOpen3M branch)
eMoney_dbo.eMoney_Dim_Account (IsValidETM=1, GCID_Unique_Count=1)
  └─ Filter for eligible eMoney accounts
DWH_dbo.Fact_CustomerAction (ActionTypeID=44, @StartOpenDate..@date AND DateID>=20240401)
  └─ eMoney IBAN trades in last 2M → eMoney_ActiveOpen3M
  ↓
SP_Cross_Selling_Monthly (@date, EOM-only)
  DELETE WHERE DateKey=@date_int + INSERT WHERE Total_Products>0
  ↓
BI_DB_dbo.BI_DB_Cross_Selling_Monthly
  (UC: _Not_Migrated)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|--------------|-----------|------|
| 1 | DateKey | SP computed | @date_int | CAST(CONVERT(VARCHAR(8), @date, 112) AS INT) | Tier 2 |
| 2 | FullDate | SP param | @date | Direct passthrough | Tier 2 |
| 3 | CID | Fact_SnapshotCustomer | RealCID | Direct passthrough via #CIDs → #AllProducrs → #final | Tier 1 |
| 4 | Country | Dim_Country | Name | Passthrough via JOIN on CountryID | Tier 1 |
| 5 | Region | Dim_Country | MarketingRegionManualName | Passthrough via JOIN on CountryID | Tier 3 |
| 6 | EOM_Club | BI_DB_CID_MonthlyPanel_FullData | EOM_Club | Passthrough from beginning-of-month snapshot | Tier 1 |
| 7 | ClusterDetail | BI_DB_CID_MonthlyPanel_FullData | ClusterDetail | Passthrough from beginning-of-month snapshot | Tier 2 |
| 8 | High_Bronze+ | V_Liabilities | ActualNWA + Liabilities | CASE WHEN Equity >= 1000 THEN 1 ELSE 0 | Tier 2 |
| 9 | ETF_HoldEOM | Dim_Position + Dim_Instrument | InstrumentTypeID=6, IsSettled=1 | Open ETF positions at EOM date (MirrorID=0) | Tier 2 |
| 10 | Smart_Portfolios_HoldEOM | Dim_Mirror | MirrorTypeID=4 | Open CopyPortfolio mirrors at EOM date | Tier 2 |
| 11 | Copy_Trader_HoldEOM | Dim_Mirror | MirrorTypeID≠4 | Open non-Portfolio copy mirrors at EOM date | Tier 2 |
| 12 | CFD_ActiveOpen3M | Dim_Position + Dim_Instrument | IsSettled=0 | COUNT CFD positions opened in last 2M (window = DATEADD(month,-2,EOM_start)) | Tier 2 |
| 13 | Real_Crypto | Dim_Position + Dim_Instrument | InstrumentTypeID=10, IsSettled=1 | 1 if HoldEOM OR ActiveOpen2M (union logic) | Tier 2 |
| 14 | Real_Non_US_Stocks | Dim_Position + Dim_Instrument | InstrumentTypeID=5, non-US exchange | 1 if HoldEOM OR ActiveOpen2M | Tier 2 |
| 15 | Real_US_Stocks | Dim_Position + Dim_Instrument | InstrumentTypeID=5, US exchanges | 1 if HoldEOM OR ActiveOpen2M | Tier 2 |
| 16 | eMoney_ActiveOpen3M | Fact_CustomerAction | ActionTypeID=44, from Apr 2024 | 1 if eMoney IBAN trade in last 2M (and after Apr 2024) | Tier 2 |
| 17 | Total_Products | Derived | All 8 product cols | SUM of ETF_HoldEOM + Smart_Portfolios_HoldEOM + Copy_Trader_HoldEOM + CFD_ActiveOpen3M + Real_Crypto + Real_Non_US_Stocks + Real_US_Stocks + eMoney_ActiveOpen3M | Tier 2 |
| 18 | UpdateDate | SP | GETDATE() | ETL run timestamp | Propagation |
