# BI_DB_dbo.BI_DB_RollOverFee_ByInstrument

> 23M-row daily instrument×regulation×customer-type revenue aggregation (2017-08-06 to 2026-04-12). Each row summarises all commission and fee metrics for one instrument × regulation × IsValidCustomer × IsCreditReportValidCB × IsDLTUser × IsMarginTrade combination on a given date. Written daily by `SP_DailyCommisionReport` as a GROUP BY satellite of `BI_DB_DailyCommisionReport`.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_DailyCommisionReport` (itself from `DWH_dbo.Fact_CustomerAction` via revenue TVFs) |
| **Refresh** | Daily — `SP_DailyCommisionReport @Date` — DELETE WHERE DateID=@DateID + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | ~23M total; ~7K rows per daily run (YTD 2026 sample) |
| **Date Range** | 2017-08-06 to 2026-04-12 |
| **Writer SP** | `BI_DB_dbo.SP_DailyCommisionReport` (same SP writes 10+ sibling tables) |

---

## 1. Business Meaning

`BI_DB_RollOverFee_ByInstrument` is a daily **by-instrument revenue aggregation** produced as part of the `SP_DailyCommisionReport` batch. It collapses the position-grain `BI_DB_DailyCommisionReport` (179K rows/date) into a compact instrument-segment summary (≈7K rows/date) by grouping on: FullDate × InstrumentType × Instrument × IsValidCustomer × IsCreditReportValidCB × Regulation × IsDLTUser × IsMarginTrade.

The aggregation preserves 9 fee dimensions:
- **RollOverFee** — overnight/Islamic holding fee aggregate per instrument/regulation/customer-type
- **FullCommissions / Commissions** — gross and net spread commission
- **RollOverFee_SDRT** — UK Stamp Duty Reserve Tax component of rollovers (added Oct 2023)
- **TradingFees** — combined ticket + admin fee aggregate (added Feb 2024)
- **TicketFee / TicketFeeByPercent** — flat and percentage-based per-trade ticket fees
- **AdminFee / SpotAdjustFee** — niche fees (>97% zero; used for specific instrument/regulation edge cases)

**Distribution (2026 YTD)**:
- InstrumentType: Stocks 79%, ETF 13%, Crypto 5%, Currencies 1%, Commodities 1%, Indices 1%, NA <0.1%
- Regulation: CySEC 40%, FCA 20%, FSA Seychelles 14%, ASIC & GAML 11%, FSRA 9%, BVI 4%, FinCEN+FINRA 3%, others <1%
- IsValidCustomer/IsCreditReportValidCB: True/True 96%, False/False 6%, False/True 0.02%
- IsDLTUser: 0 (standard) 87%, 1 (DLT) 13%
- IsMarginTrade: 0 (standard) 99.4%, 1 (margin) 0.6%

This table is a **revenue reporting companion** to `BI_DB_DailyCommisionReport` — analysts use it when they need fee breakdowns at instrument level rather than position level.

---

## 2. Business Logic

### 2.1 Aggregation Grain

**What**: Each row represents the total of all fee metrics for one distinct combination of instrument, regulation, and customer eligibility segment for one date.

**Columns Involved**: FullDate, DateID, InstrumentType, Instrument, IsValidCustomer, IsCreditReportValidCB, Regulation, IsDLTUser, IsMarginTrade

**Rules**:
- GROUP BY all 9 dimension columns from `BI_DB_DailyCommisionReport`
- WHERE DateID = @DateID (current day only)
- Preceding DELETE WHERE DateID = @DateID enables idempotent daily reload

### 2.2 Fee Metric Hierarchy

**What**: Nine fee types are aggregated with SUM; all ISNULL-protected to 0.

**Columns Involved**: RollOverFee, FullCommissions, Commissions, RollOverFee_SDRT, TradingFees, TicketFee, TicketFeeByPercent, AdminFee, SpotAdjustFee

**Rules**:
- `Commissions` = SUM(net commission from TVF_Revenue_Commissions) — the net eToro spread take
- `FullCommissions` = SUM(gross commission including full spread) — used for MiFID regulatory reporting
- `RollOverFee` = SUM(overnight/Islamic holding fee) — key overnight P&L driver
- `RollOverFee_SDRT` = SUM(UK Stamp Duty Reserve Tax on rollovers for UK Stock positions) — ≈0 for non-UK equities
- `TradingFees` = SUM(TicketFee + AdminFee per parent column) — always 0 for Currencies/Crypto
- `TicketFeeByPercent` = percentage-based ticket fee for crypto (added 2025-10-23 in parent SP)
- `AdminFee` = 97.7% zero — applies to specific account types/agreements
- `SpotAdjustFee` = 99.97% zero — spot price adjustment edge case

### 2.3 ETL History and Column Additions

**What**: The SP has been extended over time; some columns have shorter history.

**Columns Involved**: RollOverFee_SDRT, TradingFees, IsDLTUser, IsMarginTrade

**Rules**:
- RollOverFee_SDRT populated from 2023-10-31 onward (before that: always 0.0)
- TradingFees added 2024-02-25 (before that: always 0.0)
- IsDLTUser added 2024-07-30 (before that: always 0 i.e. non-DLT)
- IsMarginTrade added 2025-10-23 (before that: always 0)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution — no skew risk. CLUSTERED INDEX (DateID ASC) makes date-range queries efficient. For full-table scans (e.g., summing by InstrumentType), add WHERE DateID BETWEEN range to leverage the clustered index.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total rollover fee by instrument type for a month | `WHERE DateID BETWEEN YYYYMM01 AND YYYYMMdd AND IsValidCustomer=1 GROUP BY InstrumentType` |
| Compare valid vs. invalid customer revenue | `GROUP BY IsValidCustomer, IsCreditReportValidCB` with SUM(FullCommissions) |
| DLT user revenue contribution | `WHERE IsDLTUser=1 GROUP BY InstrumentType, Regulation` |
| UK SDRT exposure | `WHERE Regulation='FCA' AND RollOverFee_SDRT <> 0` |
| Margin trade fee contribution | `WHERE IsMarginTrade=1` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_DailyCommisionReport | DateID + InstrumentType + Instrument + Regulation | Drill down to position-grain for detail |
| DWH_dbo.Dim_Instrument | Instrument name lookup | Add InstrumentID for linking to position data |

### 3.4 Gotchas

- **AdminFee and SpotAdjustFee are nearly always zero** — do not include in generic revenue totals unless specifically needed
- **RollOverFee_SDRT history starts 2023-10-31** — pre-2023 rows always show 0.0; do not compare historical totals without filtering date
- **NA InstrumentType rows** — 32 rows with InstrumentType='NA' in 2026 YTD; legacy/edge case positions not resolved to type
- **FullCommissions vs Commissions** — FullCommissions is the MiFID regulatory gross figure; Commissions is the net eToro take; never mix them in the same SUM
- **IsValidCustomer=False rows are included** — the parent table preserves all customers; filter `WHERE IsValidCustomer=1` for business revenue reporting excluding demo/invalid
- **UpdateDate is GETDATE() at ETL time** — not the business date; use FullDate/DateID for business date filtering

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki (DB_Schema / DWH_dbo wiki) |
| Tier 2 | Derived from SP code analysis, function tracing, or ETL logic |
| Tier 3 | Inferred from column name, sample data, or structural context |
| Tier 4 | Ghost column, legacy, or insufficient evidence |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | FullDate | date | YES | Reporting date — the @Date SP input parameter. Groups the delete/insert cycle. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 2 | DateID | int | YES | YYYYMMDD integer encoding of FullDate. Clustered index key. GROUP BY passthrough from parent. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 3 | InstrumentType | varchar(100) | YES | Instrument asset-class label — Stocks, ETF, Crypto Currencies, Currencies, Commodities, Indices, or NA. GROUP BY passthrough from Dim_Instrument.InstrumentType via parent. Stocks is the dominant category. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 4 | Instrument | varchar(100) | YES | Instrument display name (e.g., EUR/USD, AAPL, BTC/USD). GROUP BY passthrough from Dim_Instrument.Name via parent. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 5 | RollOverFee | money | YES | Total overnight/Islamic holding fee for this instrument-regulation-customer segment on the reporting date. SUM(RollOverFee) from BI_DB_DailyCommisionReport. Primary fee metric. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 6 | UpdateDate | datetime | NO | ETL execution timestamp — GETDATE() at insert time. NOT the business date; use FullDate for business date filtering. (Tier 2 — SP_DailyCommisionReport) |
| 7 | FullCommissions | money | YES | Gross full commission — SUM(ISNULL(FullCommissions,0)). Includes full spread-embedded gross commission. Used for MiFID regulatory revenue reporting. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 8 | Commissions | money | YES | Net commission — SUM(ISNULL(Commissions,0)). Net eToro spread take after adjustments. Primary P&L metric for internal revenue tracking. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 9 | IsValidCustomer | bit | YES | 1 if customer is a valid eToro customer (non-demo, depositor, active) as of @Date. GROUP BY passthrough from Fact_SnapshotCustomer via parent. Most revenue reporting filters WHERE IsValidCustomer=1. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 10 | IsCreditReportValidCB | bit | YES | Credit report validity flag for US credit bureau reporting — from Fact_SnapshotCustomer. Typically equals IsValidCustomer (0.02% rows show False/True divergence). (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 11 | Regulation | varchar(50) | YES | Regulatory jurisdiction label as of @Date (CySEC, FCA, FSA Seychelles, ASIC & GAML, FSRA, BVI, FinCEN+FINRA, MAS, eToroUS, etc.) — from BI_DB_Client_Balance_CID_Level_New.ToRegulation via parent. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 12 | RollOverFee_SDRT | float | YES | UK Stamp Duty Reserve Tax component embedded in rollover fees — applies to UK equity positions. SUM(RollOverFee_SDRT) from parent. Added 2023-10-31; always 0.0 before that date. Near-zero for non-FCA regulations. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 13 | TradingFees | float | YES | Combined trading fee aggregate — SUM(TradingFees) from parent. Per SP change history: TradingFee = TicketFee + AdminFee (where AdminFee is non-zero). Added 2024-02-25. Always 0.0 before that date. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 14 | IsDLTUser | int | YES | Distributed Ledger Technology (real-asset crypto) user flag — 1=DLT user, 0=standard. GROUP BY passthrough from BI_DB_Client_Balance_CID_Level_New. Added to parent 2024-07-30. Minority of rows are DLT=1. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 15 | TicketFee | money | YES | Per-trade flat ticket fee — SUM(ISNULL(TicketFee,0)) from parent. Applied to specific instruments and account types; zero for most standard CFD trades. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 16 | TicketFeeByPercent | money | YES | Percentage-based ticket fee variant for crypto instruments — SUM(ISNULL(TicketFeeByPercent,0)) from parent. Introduced in parent SP 2025-10-23. Non-zero primarily for Crypto Currencies segment. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 17 | AdminFee | money | YES | Administrative fee aggregate — SUM(ISNULL(AdminFee,0)). Applicable to specific agreement types. 97.7% of rows are 0. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 18 | SpotAdjustFee | money | YES | Spot price adjustment fee aggregate — SUM(ISNULL(SpotAdjustFee,0)). 99.97% of rows are 0; edge case for certain instrument pricing adjustments. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |
| 19 | IsMarginTrade | int | YES | 1 if SettlementTypeID=5 (margin-funded positions via Fact_CustomerAction). GROUP BY passthrough from parent. Added 2025-10-23. Rare flag — margin positions are a small fraction of overall volume. (Tier 2 — SP_DailyCommisionReport via BI_DB_DailyCommisionReport) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Immediate Source | Upstream Source | Transform |
|---------------|-----------------|-----------------|-----------|
| FullDate, DateID | BI_DB_DailyCommisionReport | @Date parameter | GROUP BY passthrough |
| InstrumentType | BI_DB_DailyCommisionReport | DWH_dbo.Dim_Instrument | GROUP BY passthrough |
| Instrument | BI_DB_DailyCommisionReport | DWH_dbo.Dim_Instrument.Name | GROUP BY passthrough |
| RollOverFee | BI_DB_DailyCommisionReport | Function_Revenue_RolloverFee via Fact_CustomerAction | SUM aggregate |
| FullCommissions | BI_DB_DailyCommisionReport | Function_Revenue_FullCommissions | SUM aggregate |
| Commissions | BI_DB_DailyCommisionReport | Function_Revenue_Commissions | SUM aggregate |
| IsValidCustomer | BI_DB_DailyCommisionReport | DWH_dbo.Fact_SnapshotCustomer | GROUP BY passthrough |
| IsCreditReportValidCB | BI_DB_DailyCommisionReport | DWH_dbo.Fact_SnapshotCustomer | GROUP BY passthrough |
| Regulation | BI_DB_DailyCommisionReport | BI_DB_Client_Balance_CID_Level_New.ToRegulation | GROUP BY passthrough |
| RollOverFee_SDRT | BI_DB_DailyCommisionReport | SDRT fee logic (added 2023-10-31) | SUM aggregate |
| TradingFees | BI_DB_DailyCommisionReport | TicketFee+AdminFee combined | SUM aggregate |
| IsDLTUser | BI_DB_DailyCommisionReport | BI_DB_Client_Balance_CID_Level_New | GROUP BY passthrough |
| IsMarginTrade | BI_DB_DailyCommisionReport | Fact_CustomerAction.SettlementTypeID=5 | GROUP BY passthrough |

### 5.2 ETL Pipeline

```
etoro production DB
  Fact_CustomerAction (ActionTypeID IN 1,2,3,4,5,6,28,39,40)
  + Dim_Instrument + Dim_Position
  |-- Revenue TVFs: Function_Revenue_Commissions, Function_Revenue_FullCommissions,
  |   Function_Revenue_RolloverFee, Function_Revenue_TicketFee, etc. --|
  v
BI_DB_dbo.BI_DB_DailyCommisionReport
  (~179K rows/date, position-grain revenue fact)
  |-- SP_DailyCommisionReport @Date
  |   GROUP BY InstrumentType × Instrument × Regulation × IsValidCustomer
  |              × IsCreditReportValidCB × IsDLTUser × IsMarginTrade --|
  v
BI_DB_dbo.BI_DB_RollOverFee_ByInstrument
  (~7K rows/date — by-instrument daily revenue aggregation)
  |-- UC: Not Migrated --|
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| (all columns) | BI_DB_dbo.BI_DB_DailyCommisionReport | Direct upstream: this table is a GROUP BY aggregation of the parent |
| InstrumentType, Instrument | DWH_dbo.Dim_Instrument | Instrument dimension (via parent) |
| IsValidCustomer, IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer | Customer validity flags (via parent) |
| Regulation | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | ToRegulation label (via parent) |

### 6.2 Referenced By

No downstream dependencies found in OpsDB or SSDT repo. This is a **reporting leaf** — consumed by analysts and dashboards directly, not by other SPs.

---

## 7. Sample Queries

### Total Rollover Fee by Instrument Type (Valid Customers, Latest Date)
```sql
SELECT InstrumentType,
       SUM(RollOverFee) AS TotalRolloverFee,
       SUM(FullCommissions) AS TotalFullCommissions,
       SUM(Commissions) AS TotalNetCommissions
FROM [BI_DB_dbo].[BI_DB_RollOverFee_ByInstrument]
WHERE DateID = 20260412
  AND IsValidCustomer = 1
GROUP BY InstrumentType
ORDER BY TotalRolloverFee DESC;
```

### UK SDRT Exposure by Instrument (Monthly)
```sql
SELECT InstrumentType, Instrument,
       SUM(RollOverFee_SDRT) AS TotalSDRT,
       SUM(RollOverFee) AS TotalRollover
FROM [BI_DB_dbo].[BI_DB_RollOverFee_ByInstrument]
WHERE DateID BETWEEN 20260401 AND 20260412
  AND Regulation = 'FCA'
  AND RollOverFee_SDRT <> 0
GROUP BY InstrumentType, Instrument
ORDER BY TotalSDRT DESC;
```

### DLT vs Standard User Revenue Comparison (YTD 2026)
```sql
SELECT IsDLTUser,
       SUM(TicketFee + TicketFeeByPercent) AS TotalTicketFees,
       SUM(Commissions) AS TotalCommissions,
       SUM(RollOverFee) AS TotalRolloverFees,
       COUNT(*) AS RowCount
FROM [BI_DB_dbo].[BI_DB_RollOverFee_ByInstrument]
WHERE DateID >= 20260101 AND IsValidCustomer = 1
GROUP BY IsDLTUser;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table. Documentation derived from SSDT SP code analysis and live data sampling.

---

*Generated: 2026-04-22 | Quality: 8.8/10 | Phases: 14/14*
*Tiers: 0 T1, 19 T2, 0 T3, 0 T4 | Elements: 19/19, Logic: 3 subsections*
*Object: BI_DB_dbo.BI_DB_RollOverFee_ByInstrument | Type: Table | Production Source: BI_DB_DailyCommisionReport (via Fact_CustomerAction + revenue TVFs)*
