---
object: BI_DB_dbo.BI_DB_CryptoMarketingList
type: Table
lineage_generated: 2026-04-23
writer_sp: SP_CryptoMarketingList
load_pattern: TRUNCATE + INSERT (full refresh daily, no date parameter — always reflects yesterday's state)
uc_target: _Not_Migrated
---

# Column Lineage — BI_DB_CryptoMarketingList

## ETL Pipeline

```
Date scope: @Date = yesterday, @BeginOfPeriod = 3 months prior

Opt-out identification:
  BI_DB_dbo.External_SettingsDB_Settings_CustomerData (ResourceId=5564, SelectedValue='2')
    └─ → #OptOut: GCIDs who have explicitly opted out
  DWH_dbo.Dim_Customer (IsValidCustomer=1, GCID NOT IN #OptOut)
    └─ → #OptIn: all valid customers who haven't opted out (IsOptIn='Yes')

Three segments (UNIONed into #final):

1. Holded Positions (Category='Holded Postions' — note SP typo):
   BI_DB_dbo.BI_DB_PositionPnL (DateID=yesterday, InstrumentTypeID=10)
     JOIN Dim_Customer (IsValidCustomer=1) + Dim_Instrument
     └─ CryptoHolded = CASE WHEN IsMajor='Yes' THEN InstrumentDisplayName ELSE 'No'
     └─ HoldedEligibleCoins = CASE WHEN InstrumentID IN (100000,100001,100002,100003,100005,100020) THEN 'Yes' ELSE 'No'
     └─ HoldedAbove = DATEDIFF(MONTH, Occurred, Date) bucketed: <1M, >1M, >2M, >3M, >4M, >5M

2. Opened/Closed Positions (Category='Opened/Closed Positions'):
   DWH_dbo.Dim_Position (InstrumentTypeID=10, open OR close in last 3M)
     JOIN Dim_Customer (IsValidCustomer=1) + Dim_Instrument
     └─ CryptoHolded='No', HoldedEligibleCoins='No', HoldedAbove='Not Holded'

3. Crypto Leads (Category='Crypto Leads'):
   DWH_dbo.Dim_Customer (FunnelFromID=57, RegisteredReal in last 3M)
     LEFT JOIN BI_DB_dbo.BI_DB_First5Actions WHERE FirstAction IS NULL
     └─ Customers from the Crypto acquisition funnel who have NOT yet made their first action
     └─ CryptoHolded='No', HoldedEligibleCoins='No', HoldedAbove='Not Holded'

All segments:
  JOIN Dim_Customer → HasWallet
  JOIN Dim_Country → Country
  JOIN Dim_Regulation → Regulation
  LEFT JOIN #holdings → CryptoHolded, HoldedEligibleCoins, HoldedAbove (only populated for Holded Positions)
  LEFT JOIN #OptIn → IsOptIn ('Yes' / 'No')
  ↓
TRUNCATE BI_DB_dbo.BI_DB_CryptoMarketingList + INSERT #final
  ↓
BI_DB_dbo.BI_DB_CryptoMarketingList
  (UC: _Not_Migrated)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|--------------|-----------|------|
| 1 | GCID | DWH_dbo.Dim_Customer | GCID | Direct passthrough — marketing group-level customer ID | Tier 2 |
| 2 | Regulation | DWH_dbo.Dim_Regulation | Name | JOIN via Dim_Customer.RegulationID → Dim_Regulation.ID | Tier 1 |
| 3 | Country | DWH_dbo.Dim_Country | Name | JOIN via Dim_Customer.CountryID → Dim_Country.CountryID | Tier 1 |
| 4 | IsOptIn | External_SettingsDB_Settings_CustomerData | SelectedValue | 'Yes' if NOT in opt-out list (ResourceId=5564, SelectedValue='2'); 'No' if opted out | Tier 2 |
| 5 | Category | SP literal | — | 'Holded Postions' (SP typo), 'Opened/Closed Positions', or 'Crypto Leads' — identifies which segment the row belongs to | Tier 2 |
| 6 | HasWallet | DWH_dbo.Dim_Customer | HasWallet | Direct passthrough — 0/1 flag for eToro Money wallet presence | Tier 2 |
| 7 | HoldedEligibleCoins | DWH_dbo.Dim_Instrument | InstrumentID | 'Yes' if InstrumentID IN (100000,100001,100002,100003,100005,100020); else 'No'. Only meaningful for 'Holded Postions' category | Tier 2 |
| 8 | UpdateDate | SP | GETDATE() | ETL run timestamp (at time of TRUNCATE+INSERT) | Propagation |
| 9 | CryptoHolded | DWH_dbo.Dim_Instrument | InstrumentDisplayName | CASE WHEN IsMajor='Yes' THEN InstrumentDisplayName ELSE 'No'. Only meaningful for Holded Positions; 'No' for other categories | Tier 2 |
| 10 | HoldedAbove | BI_DB_PositionPnL | Occurred + Date | DATEDIFF(MONTH, Occurred, Date) bucketed: 'Holded_Less_1_Month', 'Holded_Above_1_Month'–'Holded_Above_5_Month'. 'Not Holded' for non-holdings rows | Tier 2 |
