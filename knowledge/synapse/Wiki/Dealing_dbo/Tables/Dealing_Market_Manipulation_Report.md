# Dealing_dbo.Dealing_Market_Manipulation_Report

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_Market_Manipulation_Report |
| **Type** | Table |
| **Distribution** | HASH (`CID`) |
| **Index** | CLUSTERED on `Date` |
| **Columns** | 18 |
| **Primary Source** | Multi-source: DWH_dbo.Dim_Position, DWH_dbo.V_Liabilities, BI_DB_dbo.BI_DB_PositionPnL, BI_DB_dbo.BI_DB_CopyDailyData |
| **ETL SP** | `Dealing_dbo.SP_Market_Manipulation_Report` |
| **Refresh** | Daily per @dd date |
| **PII** | YES — contains CID, UserName, Country, Manager |
| **Tags** | dealing, market-manipulation, compliance, surveillance, pnl, nop, equity, guru, top-traders |

---

## 1. Business Meaning

`Dealing_Market_Manipulation_Report` is a **daily multi-KPI surveillance dashboard** for the Dealing/Trading team. Unlike `Dealing_ManipulationReport_RealStocks` (which focuses on stock-level manipulation signals), this table focuses on **customer-level financial extremes**: who had the highest/lowest PnL, the most equity, the largest NOP (Net Open Position), and the most profitable short-duration trades.

The table is used by the dealing desk for daily morning review to identify customers and instruments with potentially anomalous profit/loss or open-position activity across all trading periods (yesterday, WTD, MTD, YTD).

**Scope**: All instrument types (not limited to stocks). Manual positions only (MirrorID=0). Valid customers with equity ≥ $100 only. Positions opened from start of year and closed within 48–96 hours (see duration rules).

Each row is one customer (or instrument) ranked within a specific KPI segment for the reporting date. A customer can appear in many KPI rows if they rank in multiple segments simultaneously. NOP-based KPIs (`YDay_NOP_*`) have NULL CID (instrument-only rows).

**SP Author**: Amir Gurewitz (2019); last modified 2025-07-15 (SR-323278, fix divide-by-zero).

---

## 2. Business Logic

### ETL Pattern — Daily Delete + Insert per Date

`SP_Market_Manipulation_Report(@dd)` processes multiple leaderboard segments:

#### Customer Universe (`#temp`)

All valid customers (`IsValidCustomer=1`) with yesterday equity (Liabilities + ActualNWA) ≥ $100, from `V_Liabilities`. Pre-loads customer attributes: Club, Desk, Region, Country, Manager, Regulation. Top 100 by equity also stored in `#Equity`.

#### Position Universe (`#positions`)

Joins `#temp` to `Dim_Position` (with `Dim_Instrument` and `BI_DB_PositionPnL` for open position P&L). Filters:
- `OpenDateID >= StartOfYear` (year-to-date positions only)
- `MirrorID = 0` (manual positions only)
- Duration filter (short-duration closed positions OR positions opened on @dd):
  - Closed positions opened before yesterday: duration ≤ 96h (Monday), 72h (Tuesday), 48h (other weekdays) — handles weekend carry-over
  - Positions opened on or after yesterday: either open (`CloseDateID=0`) OR closed yesterday (`CloseDateID=@dd`)

#### PnL Aggregation (`#CIDs`)

Per customer: `YDay_PnL`, `WTD_PnL`, `MTD_PnL`, `YTD_PnL` (raw PnL) and corresponding `RealizedGain` (PnL / InvestedAmount ratio). These feed into 12 PnL-based KPI segments.

#### NOP Computation (`#All_Positions`, `#Nop_*`)

For all currently open positions (CloseDateID=0, MirrorID=0, valid customers): computes Net Open Position (NOP) in USD using last 60-min candle price, signed by direction:
```
NOP = SUM(AmountInUnitsDecimal × price × (2×IsBuy-1) × FX_conversion_to_USD)
```
Top 100 by NOP stored in `#Nop_Instruments` (all instruments) and `#Nop_Stocks` (stocks only); top 100 customer×instrument NOP in `#Nop_CIDs` and `#Nop_CIDs_Stocks`.

#### Short-Duration Trades (`#10Min`)

Customers with profitable positions having duration ≤ 10 minutes (`Is10MinDuration=1` AND `NetProfit>0`). Top 100 by `YDay_NetProfit` (yesterday) and `WTD_NetProfit` (week-to-date).

#### Guru (Popular Investor) PnL (`#GuruPnL`, `#Guru_PnL_Final`)

From `BI_DB_CopyDailyData` (CopyType='PI'), computes the change in cumulative `CopyPnL` for Popular Investors: `YDay_PnL = CopyPnL[@dd] - CopyPnL[@dd-1]`, `WTD_PnL = CopyPnL[@dd] - CopyPnL[StartOfWeek]`. Top 100 ranked.

### KPI Segments

| KPI | Population | Sort Field | Ranks |
|-----|-----------|------------|-------|
| `PnLs_YDay_Gain` | All valid customers | YDay_RealizedGain DESC | Top 100 |
| `PnLs_WTD_Gain` | All valid customers | WTD_RealizedGain DESC | Top 100 |
| `PnLs_MTD_Gain` | All valid customers | MTD_RealizedGain DESC | Top 100 |
| `PnLs_YTD_Gain` | All valid customers | YTD_RealizedGain DESC | Top 100 |
| `PnLs_YDay_Profit` | All valid customers | YDay_PnL DESC | Top 100 |
| `PnLs_YDay_Loss` | All valid customers | YDay_PnL ASC | Top 100 (worst losses) |
| `PnLs_WTD_Profit` | All valid customers | WTD_PnL DESC | Top 100 |
| `PnLs_WTD_Loss` | All valid customers | WTD_PnL ASC | Top 100 |
| `PnLs_MTD_Profit` | All valid customers | MTD_PnL DESC | Top 100 |
| `PnLs_MTD_Loss` | All valid customers | MTD_PnL ASC | Top 100 |
| `PnLs_YTD_Profit` | All valid customers | YTD_PnL DESC | Top 100 |
| `PnLs_YTD_Loss` | All valid customers | YTD_PnL ASC | Top 100 |
| `YDay_Equity` | Customers with equity ≥ $100 | YDay_Equity DESC | Top 100 |
| `YDay_NOP_Instruments` | Open positions, all instruments | Total NOP DESC | Top 100 (no CID) |
| `YDay_NOP_Stocks` | Open positions, stocks only | Total NOP DESC | Top 100 (no CID) |
| `YDay_NOP_By_Inst_CID` | Open positions, all instruments | Per-customer NOP DESC | Top 100 |
| `YDay_NOP_By_Stock_CID` | Open positions, stocks only | Per-customer NOP DESC | Top 100 |
| `10Min_Trades_YDay` | Profitable trades ≤10 min duration | YDay_NetProfit DESC | Top 100 |
| `10Min_Trades_WTD` | Profitable trades ≤10 min duration | WTD_NetProfit DESC | Top 100 |
| `GURU_YDay_Profit` | Popular Investors (CopyType='PI') | YDay_PnL DESC | Top 100 |
| `GURU_WTD_Profit` | Popular Investors (CopyType='PI') | WTD_PnL DESC | Top 100 |

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `DWH_dbo.Dim_Position` | `PositionID, CID` | Position universe (PnL, duration, NOP) |
| `DWH_dbo.Dim_Customer` | `RealCID` | Valid customer filter + demographics |
| `DWH_dbo.Dim_Country` | `CountryID` | Country name enrichment |
| `DWH_dbo.Dim_Manager` | `ManagerID` | Account manager name |
| `DWH_dbo.Dim_Regulation` | `DWHRegulationID` | Regulation name |
| `DWH_dbo.Dim_PlayerLevel` | `PlayerLevelID` | Club tier |
| `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument metadata (type, display name) |
| `DWH_dbo.V_Liabilities` | `CID, DateID` | Yesterday equity (Liabilities + ActualNWA) |
| `DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted` | `InstrumentID` | Last price for NOP calc |
| `BI_DB_dbo.BI_DB_PositionPnL` | `PositionID, DateID` | Open position mark-to-market PnL |
| `BI_DB_dbo.BI_DB_CopyDailyData` | `CID, DateID` | Guru (Popular Investor) daily copy PnL |
| `BI_DB_dbo.BI_DB_CIDFirstDates` | `CID` | Guru metadata (Desk, Region, Country, Manager) |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Market_Manipulation_Report)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NOT NULL | Reporting date. Matches `@dd` SP parameter. Clustered index key. (Tier 2 — SP_Market_Manipulation_Report) |
| 2 | KPI | varchar(50) | NOT NULL | The surveillance segment type. 20+ distinct values — see KPI table above. Determines which fields are populated: PnL KPIs use Equity/PnL/Gain/CID; NOP KPIs use InstrumentName/NOP/CID (instrument-only rows have NULL CID). (Tier 2 — SP_Market_Manipulation_Report) |
| 3 | Equity | money | YES | Yesterday's equity (Liabilities + ActualNWA in USD) from V_Liabilities. Populated for PnLs_* and YDay_Equity KPIs; NULL for others. (Tier 2 — SP_Market_Manipulation_Report) |
| 4 | PnL | money | YES | Net profit/loss for the reporting period (YDay/WTD/MTD/YTD depending on KPI). In USD. For 10Min KPIs, this is the net profit from short-duration trades only. For GURU KPIs, this is copy PnL delta. NULL for NOP and equity KPIs. (Tier 2 — SP_Market_Manipulation_Report) |
| 5 | Gain | decimal(16,8) | YES | Realized gain rate: `PnL / InvestedAmount`. Populated only for PnLs_*_Gain KPIs. NULL for all other KPIs. (Tier 2 — SP_Market_Manipulation_Report) |
| 6 | InstrumentName | varchar(max) | YES | Instrument display name. Populated only for NOP-based KPIs (`YDay_NOP_*`). NULL for PnL, equity, and trade-duration KPIs. From Dim_Instrument.InstrumentDisplayName. (Tier 2 — SP_Market_Manipulation_Report) |
| 7 | PositionID | bigint | YES | Individual position ID. NULL in all current KPI segments (legacy column, not populated in active SP). (Tier 3 — live data) |
| 8 | NOP | money | YES | Net Open Position value in USD. Populated for NOP-based KPIs only. Computed as `SUM(units × price × direction × FX_rate)` across all open positions. Positive = net long; negative = net short. NULL for all other KPIs. (Tier 2 — SP_Market_Manipulation_Report) |
| 9 | RN | int | YES | Rank within the KPI segment. Always 1–100 (top 100 per KPI). For PnLs_*_Loss, RN=1 = largest loss. For NOP, RN=1 = highest NOP. (Tier 2 — SP_Market_Manipulation_Report) |
| 10 | CID | bigint | YES | Customer account ID. NULL for instrument-only NOP KPIs (`YDay_NOP_Instruments`, `YDay_NOP_Stocks`). **PII field.** (Tier 2 — SP_Market_Manipulation_Report) |
| 11 | UserName | varchar(max) | YES | eToro username. **PII field.** NULL for instrument-only NOP rows. (Tier 2 — SP_Market_Manipulation_Report) |
| 12 | Club | varchar(100) | YES | Customer's eToro club/tier (Bronze, Silver, Gold, Platinum, Platinum Plus). From Dim_PlayerLevel. **PII field.** (Tier 2 — SP_Market_Manipulation_Report) |
| 13 | Desk | varchar(100) | YES | Customer's sales desk assignment from Dim_Country. **PII field.** (Tier 2 — SP_Market_Manipulation_Report) |
| 14 | Region | varchar(100) | YES | Customer's sales region from Dim_Country. **PII field.** (Tier 2 — SP_Market_Manipulation_Report) |
| 15 | Country | varchar(100) | YES | Customer's country of residence. **PII field.** (Tier 2 — SP_Market_Manipulation_Report) |
| 16 | Manager | varchar(100) | YES | Account manager (FirstName + LastName) from Dim_Manager. **PII field.** (Tier 2 — SP_Market_Manipulation_Report) |
| 17 | Regulation | varchar(100) | YES | Regulatory entity name from Dim_Regulation. (Tier 2 — SP_Market_Manipulation_Report) |
| 18 | UpdateDate | datetime | NOT NULL | ETL metadata: `GETDATE()` at time SP ran. Not a business timestamp. (Tier 2 — SP_Market_Manipulation_Report) |

---

## 5. Usage Notes

**KPI-aware querying**: Always filter on both `Date` and `KPI`. A single customer can appear in 10+ KPI rows for the same date. Avoid cross-KPI aggregation (SUM(PnL) across all KPIs will double-count).

**NOP vs PnL rows**: NOP KPIs (`YDay_NOP_Instruments`, `YDay_NOP_Stocks`) have NULL CID — they are instrument-level aggregates. NOP CID KPIs (`YDay_NOP_By_Inst_CID`, `YDay_NOP_By_Stock_CID`) have both InstrumentName and CID populated.

**PositionID is always NULL**: The SP does not populate PositionID in any current output segment. Do not rely on this column.

**Guru PnL vs regular PnL**: GURU_* rows use copy PnL change (from `BI_DB_CopyDailyData`), not direct trading PnL. These represent Popular Investors' performance as seen by their copiers, not their own account P&L.

**Duration filter for weekends**: For Monday reporting, closed positions are included if duration ≤ 96 hours (catches Friday opens). For Tuesday: ≤ 72 hours. Other weekdays: ≤ 48 hours.

**Distribution on CID**: HASH(CID) — efficient for joins on CID. NOP instrument rows (NULL CID) will all hash to the same distribution bucket; this is a minor skew risk for the NULL bucket.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Dim_Position (Trade.PositionTbl), V_Liabilities, BI_DB_PositionPnL, BI_DB_CopyDailyData |
| **Refresh** | Daily per date via `SP_Market_Manipulation_Report(@dd)` |
| **SP Author** | Amir Gurewitz (2019); last modified 2025-07-15 (SR-323278) |
| **PII** | YES — CID, UserName, Country, Manager, Club, Desk, Region |
| **Compliance** | Daily dealing desk surveillance — top/bottom performers, largest positions |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 5/5 | Sample up to 2026-03-10 (active) |
| SP Logic | 4/5 | Full SP traced; 20+ KPI values documented |
| Upstream Wiki | 2/5 | Multi-source; no single production source; V_Liabilities undocumented |
| Business Context | 2/5 | Atlassian MCP unavailable; purpose inferred from SP logic |
| **Total** | **7.6/10** | |

---

*Generated: 2026-03-21 | Batch 4 | Schema: Dealing_dbo*
