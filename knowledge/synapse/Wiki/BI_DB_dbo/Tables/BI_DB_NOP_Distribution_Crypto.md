# BI_DB_NOP_Distribution_Crypto

> Daily snapshot of open CFD Crypto positions (Leverage 1–2, InstrumentTypeID=10) with customer segmentation (Club, Regulation, Country). One row per open position per RelevanceDate. Tiered retention: daily for last 31 days, then Sunday-only and end-of-month snapshots archived indefinitely.

**Schema**: BI_DB_dbo | **Object Type**: Table | **Quality**: 8.9/10

---

## Properties

| Property | Value |
|---|---|
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED COLUMNSTORE INDEX |
| **Row Count** | ~397M rows |
| **RelevanceDate Range** | 2021-10-31 to 2026-04-12 (303 distinct dates) |
| **Distinct CIDs (RealCID)** | ~606K |
| **Rows on 2026-04-12** | ~898K |
| **Retention Mix** | ~79% Sunday snapshots, ~18% EOM snapshots, ~3% recent daily |
| **Leverage Coverage** | Leverage=1 (~96%), Leverage=2 (~4%) |
| **Writer SP** | SP_NOP_Distribution_Crypto |
| **Write Pattern** | Partial-delete + INSERT (tiered retention — see Business Logic) |
| **UC Status** | Not Migrated |

---

## Business Context

`BI_DB_NOP_Distribution_Crypto` tracks eToro's exposure to open crypto CFD positions. The table answers: *"How many customers hold open BTC/ETH/SOL/etc. positions today, what is the NOP exposure, and how are those positions distributed across Club tiers, regulatory jurisdictions, and countries?"*

The table is scoped to:
- **Crypto only** (Dim_Instrument.InstrumentTypeID = 10)
- **Low-leverage CFD** (Leverage 1 or 2) — excludes high-leverage speculative positions
- **Open positions only** (IsSettled = 0 in BI_DB_PositionPnL)
- **Valid customers** (Fact_SnapshotCustomer.IsValidCustomer = 1)

Downstream use cases include:
- Risk team: daily NOP exposure by Regulation (CySEC vs FCA vs ASIC) and Club tier
- Compliance: crypto holding concentration by country or regulation
- Finance: unrealized P&L (PositionPnL) aggregation by cohort

The table uses a **tiered retention policy** to balance storage and historical coverage: daily granularity for the most recent 31 days, then weekly (Sunday) and end-of-month snapshots for longer-term trend analysis.

---

## Business Logic

### 2.1 Tiered Retention Policy
The DELETE step in SP_NOP_Distribution_Crypto implements a two-tier archive strategy:

```sql
DELETE WHERE (RelevanceDate <= DATEADD(DAY,-31,@Date) AND WeekDayNum != 1 AND EndOfMonth='N')
          OR RelevanceDate = @Date
```

**Interpretation:**
- **Last 31 days**: All daily snapshots are retained (no deletions in this window).
- **Older than 31 days**: Only **Sunday** (WeekDayNum=1) and **end-of-month** (EndOfMonth='Y') snapshots survive. All other daily rows are purged on the next run.
- **Same-day cleanup**: `RelevanceDate = @Date` ensures idempotency — if the SP re-runs on the same day, the prior day's data is removed first.

Consequence: Out of 303 distinct dates, ~79% are Sundays and ~18% are EOM days, with only ~3% being the most recent 31 daily snapshots.

### 2.2 Crypto Scope — InstrumentTypeID=10
The Dim_Instrument JOIN filters `InstrumentTypeID=10` (Crypto Currencies). This is a strict filter — FX, stocks, indices, and other instruments are excluded regardless of what BI_DB_PositionPnL contains.

Leverage is further restricted to **1 or 2** (`Leverage IN (1,2)`). Crypto positions at higher leverage are not in scope of this table. Given the 96% Leverage=1 share, the vast majority of crypto NOP is non-leveraged (real asset exposure).

### 2.3 RealCID vs CID
BI_DB_PositionPnL uses column `CID` (platform-internal customer ID). Fact_SnapshotCustomer uses `RealCID`. The SP joins `#pop p1 ON p1.RealCID = p.CID` — in this context RealCID and CID are the same value, representing the real (non-demo) account. The output column is named `RealCID` to align with Fact_SnapshotCustomer conventions.

### 2.4 WeekDayNum Reference
`DayNumberOfWeek_Sun_Start` from Dim_Date: 1=Sunday, 2=Monday, ..., 7=Saturday. The retention policy checks `WeekDayNum != 1` to identify non-Sunday rows for purge. Confirmed: 2026-04-12 (Sunday) has WeekDayNum=1 in live data.

---

## Column Elements

### Identity & Customer

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 1 | RealCID | int | YES | Tier 2 | Real (funded) customer ID. The primary customer identifier in the DWH ecosystem. FK to Dim_Customer (if exists). Sourced from Fact_SnapshotCustomer.RealCID. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 2 | GCID | int | YES | Tier 2 | Group Customer ID. Cross-product identity key linking the same person across eToro products/entities. Sourced from Fact_SnapshotCustomer.GCID. |

### Snapshot Key

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 3 | RelevanceDate | date | YES | Tier 2 | Snapshot date — the @Date SP parameter. Date for which open positions were captured. All rows for a given date reflect positions open as of that day's BI_DB_PositionPnL snapshot (DateID=@DateID). |

### Customer Segmentation

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 4 | Club | varchar(50) | YES | Tier 1 | Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 - upstream wiki, Dictionary.PlayerLevel) |
| 5 | Regulation | varchar(50) | YES | Tier 1 | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. (Tier 1 - upstream wiki, Dictionary.Regulation). Values observed: CySEC (~93%), FSA Seychelles (~6%), FSRA, ASIC & GAML, FCA, ASIC, MAS, BVI, FinCEN. |
| 6 | Country | varchar(50) | YES | Tier 1 | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. (Tier 1 - Dictionary.Country upstream wiki) |

### Position Details

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 7 | PositionID | bigint | YES | Tier 2 | Unique position key from BI_DB_PositionPnL. Identifies the specific open position. Not unique within this table — the same PositionID appears once per RelevanceDate it is open. |
| 8 | Positiontype | varchar(50) | YES | Tier 2 | Direction of the position. CASE WHEN IsBuy=1 THEN 'Buy' ELSE 'Sell'. Values: 'Buy', 'Sell'. |
| 9 | InstrumentID | int | YES | Tier 2 | Traded instrument ID (crypto only). FK to Dim_Instrument (InstrumentTypeID=10). Examples observed: 100000 (BTC), 100017 (ADA), 100037 (DOT), 100043 (DOGE). |
| 10 | BuyCurrency | varchar(50) | YES | Tier 2 | Text abbreviation of the crypto asset's BuyCurrencyID — denormalized from Dictionary.Currency.Abbreviation via Dim_Instrument JOIN. Examples: BTC, ETH, XRP, SOL, ADA, DOGE. Top currencies by open positions (2026-04-12): BTC 30%, ETH 14%, XRP 7%, SOL 7%. (Tier 2 — SP_Dim_Instrument) |
| 11 | Leverage | int | YES | Tier 2 | Position leverage. Filter: only 1 or 2 in scope. Leverage=1 (~96%) = non-leveraged CFD crypto; Leverage=2 (~4%) = 2× leveraged. |
| 12 | NOP | money | YES | Tier 2 | Net open position value in USD. Units × pair rate × direction × FX conversion from BI_DB_PositionPnL. Represents the broker's exposure for this position. |
| 13 | Amount | money | YES | Tier 2 | Position amount in USD. Customer's invested capital for this position, rewound via PositionChangeLog when applicable. |
| 14 | PositionPnL | money | YES | Tier 2 | Unrealized P&L in USD as of RelevanceDate. From BI_DB_PositionPnL.PositionPnL (sourced from PnLInDollars). Negative = unrealized loss; positive = unrealized gain. |

### Position Lifecycle

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 15 | OpenDate | date | YES | Tier 2 | Date the position was opened. CAST(BI_DB_PositionPnL.Occurred AS Date) — date component of the open timestamp. |
| 16 | DaysAge | int | YES | Tier 2 | Number of calendar days the position has been open as of RelevanceDate. DATEDIFF(DAY, Occurred, @Date). Sample: median ~700 days (many long-held crypto positions from 2021–2022). |
| 17 | WeekDayNum | int | YES | Tier 2 | Day-of-week number for RelevanceDate (Sunday-start: 1=Sunday, 7=Saturday). From Dim_Date.DayNumberOfWeek_Sun_Start. Used by the deletion logic to identify Sunday snapshots to retain. |
| 18 | EndOfMonth | varchar(20) | YES | Tier 2 | Whether RelevanceDate is the last day of its calendar month. From Dim_Date.IsLastDayOfMonth. Values: 'Y' or 'N'. Used by deletion logic to retain month-end snapshots. |

### ETL Control

| # | Column | Type | Nullable | Tier | Description |
|---|--------|------|----------|------|-------------|
| 19 | UpdateDate | datetime | YES | Tier 2 | Timestamp when SP_NOP_Distribution_Crypto inserted this row (GETDATE()). Reflects SP execution time, not RelevanceDate. |

---

## Data Profile

| Metric | Value | Source |
|--------|-------|--------|
| Total rows | ~397M | MCP COUNT_BIG 2026-04-22 |
| RelevanceDate range | 2021-10-31 to 2026-04-12 | MCP MIN/MAX |
| Distinct dates | 303 | MCP COUNT DISTINCT |
| Distinct CIDs (RealCID) | ~606K | MCP COUNT DISTINCT |
| Sunday rows | ~312M (79%) | MCP flag counts |
| EOM rows | ~73M (18%) | MCP flag counts |
| Recent daily (non-Sun/EOM) | ~12M (3%) | MCP derived |
| Leverage=1 | ~382M (96%) | MCP flag counts |
| Leverage=2 | ~14M (4%) | MCP flag counts |
| Top BuyCurrency (2026-04-12) | BTC 30%, ETH 14%, XRP 7%, SOL 7% | MCP GROUP BY |
| Top Club (2026-04-12) | Bronze 24%, Gold 22%, Platinum Plus 21% | MCP GROUP BY |
| Top Regulation (2026-04-12) | CySEC ~93%, FSA Seychelles ~6% | MCP GROUP BY |

---

## Gotchas

1. **Tiered retention — not a full daily history**: Queries spanning more than 31 days will see gaps. Only Sundays and end-of-month dates exist before the 31-day window. Do not assume one row per CID per calendar day for historical analysis.

2. **ROUND_ROBIN + CCI — no row-level locality for CID queries**: Distribution is ROUND_ROBIN. Filtering by RealCID will full-scan all distributions. For large-scale CID-based queries, the CCI compression provides savings but no distribution pruning.

3. **DaysAge can be very large**: Sample data shows positions open for 1,789 days (~4.9 years). DaysAge reflects how long each position has been held, not the age of the snapshot row. Old crypto positions from 2021–2022 remain open with very high DaysAge.

4. **WeekDayNum=1 is Sunday (not Monday)**: The column is DayNumberOfWeek_**Sun_Start**. 1=Sunday. Analysts assuming ISO-8601 (Monday=1) will misinterpret this. The retention logic keeps WeekDayNum=1 rows (Sundays).

5. **Regulation coverage**: CySEC dominates (~93% of rows on any given date). UK customers (FCA, ~0.2%) have proportionally very low crypto NOP representation — consistent with FCA crypto CFD restrictions.

6. **PositionPnL predominantly negative in sample**: 4 of 5 sample positions showed negative PositionPnL. This reflects mark-to-market losses on crypto positions opened in 2021 (crypto downturn period) still open years later.

---

## Related Objects

| Object | Relationship |
|--------|-------------|
| BI_DB_dbo.BI_DB_PositionPnL | Upstream source for position data (daily EOD snapshot) |
| DWH_dbo.Dim_Instrument | Crypto filter (InstrumentTypeID=10) and BuyCurrency lookup |
| DWH_dbo.Fact_SnapshotCustomer | Customer segmentation source (RealCID, GCID, Club, Regulation, Country) |
| DWH_dbo.Dim_Date | WeekDayNum and EndOfMonth for retention logic |
| BI_DB_dbo.SP_NOP_Distribution_Crypto | Writer SP (SB_Daily, P20) |
