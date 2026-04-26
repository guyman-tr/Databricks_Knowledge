# BI_DB_dbo.BI_DB_Compensation_Activity_Data_Regulation

> 7-row previous-month trading activity summary by regulatory entity — counts position open/close events and unique active traders across all eToro regulations for the prior calendar month, powering compliance activity reporting.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CustomerAction + Dim_Customer + Dim_Instrument via SP_Compensation_Activity_Data |
| **Refresh** | Monthly — TRUNCATE + INSERT; scope = previous calendar month (computed from GETDATE()) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Author** | Lior Ben Dor (2021-07-12); MAS regulation added Oskar Harhalakis (2025-12-03) |

---

## 1. Business Meaning

This table is a **previous-month cross-regulation trading activity summary**. Each row represents one regulatory entity and reports the total count of position open/close events (split by Real Stocks/ETF and CFD), the number of unique customers who traded, and the count of real crypto positions — all for the previous calendar month.

The data is refreshed daily by `SP_Compensation_Activity_Data`, which truncates and reloads based on the calendar month prior to GETDATE(). Running multiple times in the same month produces identical results.

Regulations included: CySEC (EU), FCA (UK), FSA Seychelles, ASIC and ASIC&GAML (Australia, combined), US, FSRA (UAE), MAS (Singapore), and Internal (eToro staff accounts). The 'Other' catch-all is excluded. ASIC (RegulationID=4) and ASIC&GAML (RegulationID=10) are merged into a single row.

As of 2026-04-13 (covering March 2026): **7 rows**. Active trader distribution: CySEC 479,867 (59.7%), FCA 219,911 (27.4%), FSA Seychelles 48,469 (6.0%), ASIC and ASIC&GAML 42,082 (5.2%), US 11,178 (1.4%), Internal 887 (0.1%), MAS 530 (0.1%). FSRA absent (no active traders in March 2026). Total active traders across all regulations: ~803,054.

---

## 2. Business Logic

### 2.1 Position Event Scope

**What**: All counts are derived from position open and close events in the previous calendar month.
**Columns Involved**: `RealStocksETFTransactions`, `CFDTransactions`, `ActiveTraderCount`, `RealCryptoPositionCount`
**Rules**:
- Source: `DWH_dbo.Fact_CustomerAction` filtered to `ActionType.CategoryID IN (17, 18)` — PositionClose (17) and PositionOpen (18)
- Date filter: `DateID >= YYYYMM01 AND DateID < YYYYMM+1-01` (previous full calendar month)
- RealStocksETFTransactions: `COUNT(*)` where `Dim_Instrument.InstrumentTypeID IN (5, 6)` AND `IsSettled = 1`
- CFDTransactions: `COUNT(*)` where `IsSettled = 0` (all instrument types)
- ActiveTraderCount: `COUNT(DISTINCT RealCID)` across all position events (CategoryID IN 17,18)
- RealCryptoPositionCount: `COUNT(DISTINCT PositionID)` where `InstrumentTypeID = 10` AND `IsSettled = 1`

### 2.2 Regulation Grouping Logic

**What**: Customers are assigned to regulation buckets via a CASE expression — not by joining Dim_Regulation.Name directly.
**Columns Involved**: `Regulation`
**Rules**:
- RegulationID=2 AND IsValidCustomer=1 → 'FCA'
- RegulationID IN (10,4) AND IsValidCustomer=1 → 'ASIC and ASIC&GAML' (two production regulations merged)
- RegulationID=1 AND IsValidCustomer=1 → 'CySEC'
- RegulationID=9 AND IsValidCustomer=1 → 'FSA Seychelles'
- RegulationID IN (6,7,8) AND IsValidCustomer=1 → 'US'
- RegulationID=11 AND IsValidCustomer=1 → 'FSRA'
- RegulationID=13 AND IsValidCustomer=1 → 'MAS'
- Region='eToro' AND IsValidCustomer=0 → 'Internal' (eToro staff accounts)
- All others → 'Other' (excluded from output via WHERE Regulation <> 'Other')

### 2.3 Previous-Month Scope

**What**: The SP always loads the previous calendar month, not the current month.
**Columns Involved**: All activity counts
**Rules**:
- `@startdate = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) - 1, 0)` — first day of prior month
- `@enddate = DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))` — exclusive end = first day of current month
- No date parameter — computed from GETDATE() at runtime

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN / HEAP — 7 rows. This is a summary export table; all analytics should be done on the source (Fact_CustomerAction) for large-scale analysis. Joins and GROUP BYs on this table are trivially cheap.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|----------------------|
| Total position activity by regulation | `SELECT Regulation, RealStocksETFTransactions + ISNULL(CFDTransactions,0) AS total FROM ...` |
| Regulations ranked by active trader count | `SELECT Regulation, ActiveTraderCount ORDER BY ActiveTraderCount DESC` |
| Real crypto engagement by regulation | `SELECT Regulation, RealCryptoPositionCount, ActiveTraderCount, CAST(RealCryptoPositionCount AS FLOAT)/ActiveTraderCount AS crypto_rate FROM ...` |
| Check if FSRA has any traders | `SELECT * WHERE Regulation = 'FSRA'` (returns no rows if absent) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| DWH_dbo.Dim_Regulation | `Regulation = Dim_Regulation.Name` (approximate — ASIC merged) | Decode regulation metadata |

### 3.4 Gotchas

- **ASIC merged**: 'ASIC and ASIC&GAML' combines two distinct Dim_Regulation IDs (4=ASIC, 10=ASIC&GAML). Cannot be split further from this table.
- **FSRA absent when no activity**: If FSRA had no active traders in the period, no row is returned. Do not assume 7 rows always present.
- **NULL = no activity, not missing data**: NULL in CFDTransactions (US regulation) means no CFD positions opened/closed — CFDs are not available for US customers.
- **Previous month only**: Table always reflects one prior month. Do not use for current-month or multi-month trend analysis.
- **Not per-customer**: This is an aggregate table. For individual customer trading data, use Fact_CustomerAction directly.
- **UpdateDate precision**: GETDATE() at ETL run time.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (no transformation) |
| Tier 2 | Derived from ETL SP code, DWH wiki, or staging DDL |
| Tier 3 | Inferred from column name, data pattern, or business context |
| Tier 4 | Best available — no source traceable |
| Propagation | ETL infrastructure column (GETDATE(), row metadata) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Regulation | varchar(250) | YES | Regulatory entity label. Values: 'CySEC', 'FCA', 'FSA Seychelles', 'ASIC and ASIC&GAML', 'US', 'FSRA', 'MAS', 'Internal'. Derived via CASE on Dim_Customer.RegulationID + Dim_Country.Region; 'Other' excluded. ASIC (RegulationID=4) and ASIC&GAML (RegulationID=10) are merged into one label. (Tier 2 — SP_Compensation_Activity_Data) |
| 2 | RealStocksETFTransactions | int | YES | Count of position open and close events (ActionType CategoryID IN 17,18) for real stocks and ETF instruments (InstrumentTypeID IN 5,6, IsSettled=1) in the previous month. NULL for regulations with no real stock/ETF activity. March 2026 range: 250 (Internal) to 53,764,696 (CySEC). (Tier 2 — SP_Compensation_Activity_Data) |
| 3 | CFDTransactions | int | YES | Count of position open and close events (ActionType CategoryID IN 17,18) for CFD positions (IsSettled=0) in the previous month. NULL for regulations without CFD access (e.g., US). March 2026 range: 2,605 (MAS) to 13,110,518 (CySEC). (Tier 2 — SP_Compensation_Activity_Data) |
| 4 | ActiveTraderCount | int | YES | Count of distinct customers (COUNT DISTINCT RealCID) who had at least one position open or close event (CategoryID IN 17,18) in the previous month. March 2026: CySEC 479,867 (largest), MAS 530 (smallest). (Tier 2 — SP_Compensation_Activity_Data) |
| 5 | RealCryptoPositionCount | int | YES | Count of distinct real crypto positions (COUNT DISTINCT PositionID where InstrumentTypeID=10, IsSettled=1, CategoryID IN 17,18) opened or closed in the previous month. NULL for regulations with no real crypto activity (e.g., MAS). March 2026 range: 3,960 (Internal) to 990,423 (CySEC). (Tier 2 — SP_Compensation_Activity_Data) |
| 6 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Regulation | DWH_dbo.Dim_Customer + Dim_Country | RegulationID + Region | CASE expression; ASIC+ASIC&GAML merged; Internal = Region='eToro' AND IsValidCustomer=0 |
| RealStocksETFTransactions | DWH_dbo.Fact_CustomerAction + Dim_Instrument | PositionID | COUNT WHERE InstrumentTypeID IN (5,6) AND IsSettled=1 AND CategoryID IN (17,18) |
| CFDTransactions | DWH_dbo.Fact_CustomerAction | PositionID | COUNT WHERE IsSettled=0 AND CategoryID IN (17,18) |
| ActiveTraderCount | DWH_dbo.Fact_CustomerAction | RealCID | COUNT DISTINCT WHERE CategoryID IN (17,18) |
| RealCryptoPositionCount | DWH_dbo.Fact_CustomerAction + Dim_Instrument | PositionID | COUNT DISTINCT WHERE InstrumentTypeID=10 AND IsSettled=1 AND CategoryID IN (17,18) |
| UpdateDate | ETL | GETDATE() | Runtime timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CustomerAction (CategoryID IN 17,18 = PositionOpen/PositionClose)
  + DWH_dbo.Dim_Instrument (InstrumentTypeID: 5,6=RealStocks/ETF, 10=RealCrypto)
  + DWH_dbo.Dim_Customer (RegulationID → CASE mapping)
  + DWH_dbo.Dim_Country (Region='eToro' → Internal)
  + DWH_dbo.Dim_ActionType (CategoryID filter)
    → #Positions    (RealStocksETF / CFD split by regulation)
    → #ActiveTraders (COUNT DISTINCT RealCID)
    → #RealCryptoPositions (COUNT DISTINCT PositionID, InstrumentTypeID=10)
    → #final (LEFT JOIN all three, WHERE Regulation <> 'Other')
    |-- SP_Compensation_Activity_Data (previous month) TRUNCATE+INSERT ---|
    v
BI_DB_dbo.BI_DB_Compensation_Activity_Data_Regulation (7 rows, March 2026)
    |-- UC: _Not_Migrated ---|
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Regulation (source) | DWH_dbo.Dim_Customer | RegulationID used for regulation CASE grouping |
| Regulation (source) | DWH_dbo.Dim_Country | Region='eToro' for Internal bucket |
| All counts | DWH_dbo.Fact_CustomerAction | Position open/close events source |
| Instrument type filters | DWH_dbo.Dim_Instrument | InstrumentTypeID 5,6,10 for RealStocks/ETF/Crypto |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified in SSDT (compliance reporting export table).

---

## 7. Sample Queries

### Cross-regulation activity overview for current loaded month

```sql
SELECT Regulation,
       ActiveTraderCount,
       ISNULL(RealStocksETFTransactions, 0) + ISNULL(CFDTransactions, 0) AS TotalTransactions,
       RealStocksETFTransactions,
       CFDTransactions,
       RealCryptoPositionCount
FROM [BI_DB_dbo].[BI_DB_Compensation_Activity_Data_Regulation]
ORDER BY ActiveTraderCount DESC;
```

### Real crypto engagement rate by regulation

```sql
SELECT Regulation,
       ActiveTraderCount,
       RealCryptoPositionCount,
       CAST(RealCryptoPositionCount AS FLOAT) / NULLIF(ActiveTraderCount, 0) AS crypto_positions_per_trader
FROM [BI_DB_dbo].[BI_DB_Compensation_Activity_Data_Regulation]
WHERE RealCryptoPositionCount IS NOT NULL
ORDER BY crypto_positions_per_trader DESC;
```

### Regulations with CFD activity (excluding US-style no-CFD regulations)

```sql
SELECT Regulation,
       CFDTransactions,
       ActiveTraderCount,
       CAST(CFDTransactions AS FLOAT) / NULLIF(ActiveTraderCount, 0) AS cfd_per_trader
FROM [BI_DB_dbo].[BI_DB_Compensation_Activity_Data_Regulation]
WHERE CFDTransactions IS NOT NULL
ORDER BY CFDTransactions DESC;
```

---

## 8. Atlassian Knowledge Sources

No Confluence/Jira sources found for this object. SP comment: table populated by SP_Compensation_Activity_Data (Lior Ben Dor, 2021-07-12); MAS regulation added by Oskar Harhalakis (2025-12-03).

---

*Generated: 2026-04-23 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 1 Propagation | Elements: 6/6, Logic: 9/10*
*Object: BI_DB_dbo.BI_DB_Compensation_Activity_Data_Regulation | Type: Table | Production Source: SP_Compensation_Activity_Data*
