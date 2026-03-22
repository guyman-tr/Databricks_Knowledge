---
object: Dealing_Commission_Assurance
schema: Dealing_dbo
type: Table
description: Monthly commission assurance report showing total traded units, units without commission, and estimated max revenue lost — segmented by instrument type (Currencies/Stocks/etc.) and trade type (Copy/Manual).
etl_sp: Dealing_dbo.SP_Rev_Assurance
frequency: Daily (accumulates month-to-date; monthly summary key)
status: Active (last row 2026-03 based on row count)
row_count: 612
distribution: ROUND_ROBIN
index: CLUSTERED (Month ASC)
batch: 14
quality: 8.0
---

# Dealing_Commission_Assurance

Monthly commission assurance monitoring table. Each row represents one **instrument type × trade type** combination for a given month-to-date window. Tracks what percentage of traded volume was executed **without commission** (e.g., due to zero-commission promotions, exempt accounts, or configuration errors) and estimates the maximum revenue exposure.

`SP_Rev_Assurance` also writes `Dealing_Commission_Assurance_By_Position` (position-level diff) and `Dealing_Rollover_Assurance` (rollover fee assurance).

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Source | `DWH_dbo.Dim_Position` | Positions opened/closed in current month with commission and units |
| Dimension | `DWH_dbo.Dim_Instrument` | InstrumentType lookup |
| Filter | `DWH_dbo.Dim_Customer` | PlayerLevelID ≠ 4 (exclude employees/test accounts) |
| Writer | `Dealing_dbo.SP_Rev_Assurance` | Daily, OpsDB Priority 0 |

**ETL logic**: SP parameters @date and @FirstDayOfMonth define the month window. Aggregates total and zero-commission units for positions opened OR closed within the month-to-date range.

## 1. Business Purpose

- Ensures eToro is collecting commissions correctly — a Ratio approaching 1.0 means almost no positions generated commission revenue
- `Max Rev Lost` = `NoCommission_Positions_Opened × $0.005` — a conservative proxy for revenue exposure (assumes $0.005/position as baseline)
- Segmented by Copy vs Manual trades to distinguish social trading from manual trading behavior
- Used by the Dealing team and Finance for monthly commission integrity reviews

## 2. Key Concepts

| Concept | Explanation |
|---------|-------------|
| Commission-free position | Position where `Commission = 0` (on open) or `CommissionOnClose = 0` |
| Copy vs Manual | `MirrorID > 0` = Copy trade, else Manual |
| Month key | `YYYY-MM` format (varchar(7)) |

## 3. Grain

One row per **Month × InstrumentType × Type (Copy/Manual)**. ~612 rows total = ~51 months × ~12 combinations.

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| Month | varchar(7) | Month key in `YYYY-MM` format (e.g., `2026-03`) | Tier 2 | Clustered index key; month-to-date, refreshed daily |
| InstrumentType | varchar(20) | Instrument type name (Currencies, Stocks, Commodities, Indices, Crypto, ETF) | Tier 2 | From `DWH_dbo.Dim_Instrument.InstrumentType` |
| Type | varchar(6) | Trade origin: `Copy` (MirrorID>0) or `Manual` | Tier 2 | Distinguishes social trading from direct trades |
| Total_Units | decimal(38,6) | Total AmountInUnitsDecimal for positions opened + closed in the month | Tier 2 | Sum of on-open + on-close units |
| Units_Without_Comm | decimal(38,6) | Total units for positions where commission = 0 (open or close) | Tier 2 | Commission-free volume; high values warrant investigation |
| Ratio | decimal(38,6) | `Units_Without_Comm / Total_Units` — fraction of commission-free trading | Tier 2 | 0.0 = all commissions collected; 1.0 = all commission-free |
| Max Rev Lost | numeric(14,3) | `NoCommission_Positions_Opened × $0.005` — proxy for max revenue exposure | Tier 2 | Not actual lost revenue; conservative estimate per-position |
| UpdateDate | datetime | ETL metadata: timestamp when row was last written | Tier 1 | ETL metadata (blacklist canonical) |

## 5. Common Query Patterns

```sql
-- Latest month summary: commission capture rate by instrument type
SELECT Month, InstrumentType, Type,
       CAST(Ratio * 100 AS DECIMAL(5,2)) AS CommissionFreePercent,
       [Max Rev Lost]
FROM Dealing_dbo.Dealing_Commission_Assurance
WHERE Month = FORMAT(GETDATE(), 'yyyy-MM')
ORDER BY [Max Rev Lost] DESC;

-- Monthly trend of commission-free ratio for Stocks
SELECT Month, Type, Ratio, [Max Rev Lost]
FROM Dealing_dbo.Dealing_Commission_Assurance
WHERE InstrumentType = 'Stocks'
ORDER BY Month DESC;
```

## 6. Data Quality & Caveats

- `Max Rev Lost` is an approximation — actual revenue lost depends on the specific spread/commission rate, not a flat $0.005
- Stocks Manual shows a very high ratio (~0.98) as of 2026-03 — this is expected if zero-commission real stock trading is the business model
- Row count is small (612 rows) so full scans are cheap — no partition filtering needed

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `Dealing_dbo.Dealing_Commission_Assurance_By_Position` | Position-level granularity; same SP, daily data, 90M+ rows |
| `Dealing_dbo.Dealing_Rollover_Assurance` | Third output of SP_Rev_Assurance — rollover fee integrity |
| `DWH_dbo.Dim_Position` | Primary source for position volume and commission fields |

## 8. Operational Notes

- **ETL**: `SP_Rev_Assurance` runs daily (OpsDB Priority 0). Deletes and reinserts rows for the current month on every run — month-to-date data is refreshed, not appended
- **Scheduling**: ProcessType 1 (SQL), ProcessName SB_Daily
- **No retention policy** documented — historical months appear to be kept indefinitely

---
*Quality score: 8.0/10 — Good coverage of business logic. Max Rev Lost calculation could be more precisely documented.*
