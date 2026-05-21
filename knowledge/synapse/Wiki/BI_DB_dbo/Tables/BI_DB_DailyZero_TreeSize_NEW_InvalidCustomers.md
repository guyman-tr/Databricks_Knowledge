# BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers

> 6.18M-row daily zero P&L and tree-size bucket aggregate for **invalid customers only** (IsValidCustomer=0), spanning 2021-01-02 to 2025-06-29. Written by SP_DailyZero_TreeSize_NEW_InvalidCustomers from Dim_Position, BI_DB_PositionPnL, Fact_SnapshotCustomer, and dimension lookups. Companion to BI_DB_DailyZero_TreeSize_NEW (valid customers). Data gap: no 2024 rows; only ~20K rows in 2025 vs ~2.5M/year in 2021-2022.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | SP_DailyZero_TreeSize_NEW_InvalidCustomers (Dim_Position + BI_DB_PositionPnL + Fact_SnapshotCustomer + dims) |
| **Refresh** | Daily (DELETE+INSERT for @start date) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | `_Not_Migrated` (not in Generic Pipeline mapping; sister table maps to `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new`) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers aggregates daily zero P&L, commissions, NOP, and tree-size exposure buckets for positions held by **invalid customers** (IsValidCustomer=0 in Fact_SnapshotCustomer -- demo accounts, blocked countries, or excluded labels). It mirrors the structure of its sister table BI_DB_DailyZero_TreeSize_NEW but isolates the non-valid customer segment for separate risk and compliance analysis. 6.18M rows from 2021-01-02 to 2025-06-29 (years: 2021=2.51M, 2022=2.88M, 2023=766K, 2025=20K; no 2024 data). Written by SP_DailyZero_TreeSize_NEW_InvalidCustomers via DELETE+INSERT per date.

---

## 2. Business Logic

### 2.1 Zero P&L Reconciliation

**What**: Decomposes daily position P&L into realized and unrealized zero components.

**Columns Involved**: `RealizedZero`, `ChangeInUnrealizedZero`, `TotalZero`, `RealizedCommission`

**Rules**:
- Realized: positions closed on @RepDate. CalculatedZero = NetProfit - prior-day PositionPnL + FullCommissionOnClose - FullCommissionByUnits (or NetProfit + FullCommissionOnClose for same-day open+close).
- Unrealized: positions open through @RepDate. CalculatedZero = DailyPnL (+ FullCommissionByUnits for same-day opens).
- TotalZero = RealizedZero + ChangeInUnrealizedZero.
- RealizedCommission = SUM(TotalCommission) from both indicators.

### 2.2 Tree-Size Bucketing

**What**: Classifies position/tree exposure into categorical size buckets.

**Columns Involved**: `TreeSize_Units`, `TreeSize_USD`

**Rules**:
- If TreeID has a tree aggregate, bucket uses tree-level totals; otherwise individual position values.
- Units thresholds: Smaller, 10+, 25+, 50+, 100+, 250+, 500+, 1K+, 5K+, 10K+, 50K+, 100K+, 500K+, 1M+, 2M+.
- USD thresholds: Smaller, 1K+, 10K+, 100K+, 250K+, 500K+, 1000K+.

---

## 3. Query Advisory

### 3.1 Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Date. Always filter by Date for efficient seeks.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Daily zero for a date | `WHERE Date = '2023-06-15'` |
| Zero by regulation | `GROUP BY Regulation WHERE Date = @dt` |
| Total NOP by instrument | `GROUP BY InstrumentID WHERE Date = @dt` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_DailyZero_TreeSize_NEW | Same grain columns | Compare valid vs invalid customer zero |
| DWH_dbo.Dim_Instrument | ON InstrumentID (note: 1000 = Stocks/ETF rollup) | Resolve non-rolled-up instruments |

### 3.4 Gotchas

- **Invalid customers only**: SP filters `WHERE b.IsValidCustomer = 0`. All rows have IsValidCustomer=0. For valid customers, use the sister table BI_DB_DailyZero_TreeSize_NEW.
- **Stocks/ETF rollup**: InstrumentID=1000 aggregates all stocks and ETFs; InstrumentType and InstrumentName are set to 'Stocks/ETF'.
- **RiskIndex, RiskGroup, DepositGroup are empty strings**: Inserted as '' placeholders -- not functionally populated.
- **Sparse 2025 data**: Only ~20K rows exist for 2025 vs ~2.5M-2.9M for 2021-2022 and ~766K for 2023. No 2024 data at all. Possible ETL gap or table deprecation. Verify SP is still running before using for 2025 analysis.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag | Meaning |
|------|-----|---------|
| Tier 1 | `(Tier 1 — source)` | Upstream wiki verbatim (dim-lookup passthrough or Fact_SnapshotCustomer passthrough) |
| Tier 2 | `(Tier 2 — SP)` | ETL-computed or aggregated in SP_DailyZero_TreeSize_NEW_InvalidCustomers |
| Tier 3 | `(Tier 3 — ETL)` | ETL housekeeping |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | Report date for the daily run (@RepDate in SP). One day of data per DELETE+INSERT cycle. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 2 | HedgeServerID | int | NO | FK to Trade.HedgeServer. Hedge server managing this position. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 3 | Copy | int | NO | Copy trade role: 1 if MirrorID > 0 (copier), -1 if OrigParentPositionID > 0 (copied), 0 = direct. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 4 | InstrumentID | int | NO | Instrument identifier; 1000 = synthetic rollup for all stocks/ETFs (InstrumentTypeID IN (5,6)). (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 5 | RiskIndex | int | NO | Placeholder -- inserted as empty string, effectively 0. Reserved for future risk indexing. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 6 | TreeSize_Units | varchar(50) | NO | Bucket label from position or tree-aggregated AmountInUnitsDecimal: Smaller, 10+, 25+, 50+, 100+, 250+, 500+, 1K+, 5K+, 10K+, 50K+, 100K+, 500K+, 1M+, 2M+. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 7 | TreeSize_USD | varchar(50) | NO | Bucket label from position or tree-aggregated NOP in USD: Smaller, 1K+, 10K+, 100K+, 250K+, 500K+, 1000K+. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 8 | Leverage | int | NO | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 9 | RiskGroup | nvarchar(50) | YES | Placeholder -- inserted as empty string. Not functionally populated. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 10 | DepositGroup | nvarchar(50) | YES | Placeholder -- inserted as empty string. Not functionally populated. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 11 | RealizedCommission | money | YES | SUM of total commissions (ISNULL(FullCommissionOnClose, CommissionOnClose) minus FullCommissionByUnits for non-same-day positions) across realized and unrealized indicators. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 12 | RealizedZero | money | YES | SUM of CalculatedZero for positions closed on the report date (Indicator='Realized'). Represents realized zero P&L component. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 13 | ChangeInUnrealizedZero | money | YES | SUM of CalculatedZero for positions still open on the report date (Indicator='UnRealized'). Represents daily change in unrealized zero. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 14 | TotalZero | money | YES | SUM of all CalculatedZero (realized + unrealized). Equals RealizedZero + ChangeInUnrealizedZero. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 15 | NOP | money | YES | SUM of net open position in USD from BI_DB_PositionPnL. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 16 | OpenPositions | money | YES | SUM of signed open position (NOP * direction: positive for long, negative for short). (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 17 | Nop_Units | money | YES | SUM of AmountInUnitsDecimal from BI_DB_PositionPnL for open positions. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 18 | VolumeAtOpen | money | YES | SUM of Volume for positions opened on the report date; 0 for positions opened earlier. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 19 | VolumeAtClose | money | YES | SUM of VolumeOnClose for positions closed on the report date; 0 for positions still open. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 20 | UpdateDate | datetime | YES | ETL load timestamp set to GETDATE() at insert time. (Tier 3 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 21 | IsCFD | tinyint | YES | CFD flag reconciled from Dim_Position.IsSettled and BI_DB_PositionPnL.IsSettled: 1=CFD, 0=Real. When the two sources disagree, Dim_Position takes precedence for the inverse logic. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 22 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID. (Tier 1 — Dictionary.Regulation) |
| 23 | MifID | int | YES | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. Renamed from Fact_SnapshotCustomer.MifidCategorizationID. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 24 | InstrumentType | varchar(50) | YES | Asset class label; 'Stocks/ETF' when InstrumentTypeID IN (5,6), otherwise from Dim_Instrument.InstrumentType. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 25 | InstrumentName | varchar(50) | YES | Instrument display name; 'Stocks/ETF' when InstrumentTypeID IN (5,6), otherwise from Dim_Instrument.Name. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 26 | OpenPositionValue | money | YES | SUM of (Amount + PositionPnL) from BI_DB_PositionPnL for open positions. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 27 | Country | varchar(50) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough via Fact_SnapshotCustomer.CountryID. (Tier 1 — Dictionary.Country) |
| 28 | PlayerLevel | varchar(100) | YES | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerLevelID. (Tier 1 — Dictionary.PlayerLevel) |
| 29 | GuruStatus | nvarchar(100) | YES | Human-readable PI tier name. Values: No, Certified, Cadet, Rising Star, Champion, Elite, Elite Pro, Removed, Rejected. Used in BackOffice customer views, Trade procedures, and SalesForce integration. Dim-lookup passthrough via Fact_SnapshotCustomer.GuruStatusID. (Tier 1 — Dictionary.GuruStatus) |
| 30 | Long_OP | decimal(18,6) | YES | SUM of NOP for long positions (IsBuy=1). (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 31 | Short_OP | decimal(18,6) | YES | SUM of NOP for short positions (IsBuy=0). (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 32 | SettlementType | varchar(10) | YES | Settlement classification derived from IsCFD and SettlementTypeID: 'Real' if not CFD, else 'CFD' (default/SettlementTypeID=0), 'TRS' (SettlementTypeID=2), or 'CMT' (SettlementTypeID=3). Values: Real=3.36M, CFD=2.82M, TRS=1.2K. (Tier 2 — SP_DailyZero_TreeSize_NEW_InvalidCustomers) |
| 33 | IsValidCustomer | int | YES | 1 if the customer is a valid retail customer for analytics purposes. ETL-computed from PlayerLevelID, LabelID, CountryID. Approx 98% of current rows = 1 in Fact_SnapshotCustomer. Always 0 in this table (SP filters WHERE IsValidCustomer=0). (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 34 | IsCreditReportValidCB | int | YES | 1 if customer is eligible for CreditBureau credit report validation. ETL-computed. Passthrough from Fact_SnapshotCustomer. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| Date | SP parameter | @start / @RepDate | Report date |
| HedgeServerID | DWH_dbo.Dim_Position | HedgeServerID | Passthrough |
| Copy | DWH_dbo.Dim_Position | MirrorID, OrigParentPositionID | CASE: 1/-1/0 |
| InstrumentID | DWH_dbo.Dim_Position + Dim_Instrument | InstrumentID, InstrumentTypeID | CASE: 1000 for stocks/ETF |
| Leverage | DWH_dbo.Dim_Position | Leverage | Passthrough |
| IsCFD | Dim_Position + BI_DB_PositionPnL | IsSettled | CASE reconciliation |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup via FSC.RegulationID |
| MifID | DWH_dbo.Fact_SnapshotCustomer | MifidCategorizationID | Rename |
| Country | DWH_dbo.Dim_Country | Name | Dim-lookup via FSC.CountryID |
| PlayerLevel | DWH_dbo.Dim_PlayerLevel | Name | Dim-lookup via FSC.PlayerLevelID |
| GuruStatus | DWH_dbo.Dim_GuruStatus | GuruStatusName | Dim-lookup via FSC.GuruStatusID |
| IsValidCustomer | DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer | Passthrough (always 0) |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | IsCreditReportValidCB | Passthrough |
| NOP, OpenPositions, Nop_Units, OpenPositionValue, Long_OP, Short_OP | BI_DB_dbo.BI_DB_PositionPnL | NOP, Amount, PositionPnL, AmountInUnitsDecimal | SUM aggregations |
| RealizedZero, ChangeInUnrealizedZero, TotalZero, RealizedCommission | SP computed | NetProfit, DailyPnL, commissions, prior-day PositionPnL | Realized/unrealized split + SUM |
| TreeSize_Units, TreeSize_USD | SP computed | AmountInUnitsDecimal, NOP (tree-aggregated) | CASE bucket thresholds |
| SettlementType | Dim_Position + BI_DB_PositionPnL | IsSettled, SettlementTypeID | CASE: Real/CFD/TRS/CMT |
| VolumeAtOpen, VolumeAtClose | DWH_dbo.Dim_Position | Volume, VolumeOnClose | Conditional on OpenDateID/CloseDateID = @RepDateINT |
| UpdateDate | SP | N/A | GETDATE() |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (open + closed on @dt)
BI_DB_dbo.BI_DB_PositionPnL (DateID = @RepDateINT)
DWH_dbo.Fact_SnapshotCustomer (WHERE IsValidCustomer = 0)
DWH_dbo.Dim_Range (SCD2 date filter)
DWH_dbo.Dim_Instrument / Dim_Regulation / Dim_Country / Dim_PlayerLevel / Dim_GuruStatus
  |-- SP_DailyZero_TreeSize_NEW_InvalidCustomers @start --|
  |   #Positions -> #Pos_with_Vol -> #TreeSize -> #NewPositions -> #Realized + #UnRealized -> #Final
  |   DELETE WHERE Date = @start; INSERT aggregated rows
  v
BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers (6.18M rows)
```

SP processes one date per invocation. Builds temp tables for positions, enriches with PositionPnL NOP/DailyPnL, computes tree-size buckets, splits into realized/unrealized, unions, and aggregates by GROUP BY dimensions.

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument lookup (1000 = Stocks/ETF rollup) |
| HedgeServerID | DWH_dbo.Dim_Position | Hedge server |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| (none identified) | - | No downstream consumers found in repo |

---

## 7. Sample Queries

### 7.1 Daily total zero by regulation for a specific date

```sql
SELECT Regulation,
       SUM(TotalZero) AS total_zero,
       SUM(NOP) AS total_nop
FROM BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers
WHERE Date = '2023-06-15'
GROUP BY Regulation
ORDER BY total_zero DESC;
```

### 7.2 Monthly zero trend with settlement type breakdown

```sql
SELECT DATEADD(MONTH, DATEDIFF(MONTH, 0, Date), 0) AS month_start,
       SettlementType,
       SUM(RealizedZero) AS realized,
       SUM(ChangeInUnrealizedZero) AS unrealized,
       SUM(TotalZero) AS total
FROM BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers
WHERE Date >= '2023-01-01'
GROUP BY DATEADD(MONTH, DATEDIFF(MONTH, 0, Date), 0), SettlementType
ORDER BY month_start, SettlementType;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode).

---

*Generated: 2026-04-28 | Quality: 8.5/10 | Phases: 11/14*
*Tiers: 9 T1, 24 T2, 1 T3, 0 T4 | Elements: 34/34, Logic: 8/10, Relationships: 6/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW_InvalidCustomers | Type: Table | Production Source: SP_DailyZero_TreeSize_NEW_InvalidCustomers*
