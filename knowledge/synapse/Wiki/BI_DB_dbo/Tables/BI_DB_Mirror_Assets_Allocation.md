# BI_DB_dbo.BI_DB_Mirror_Assets_Allocation

> 6-row daily snapshot of copy-trading equity allocation by instrument type (Stocks, ETF, Crypto Currencies, Indices, Commodities, Currencies), comparing yesterday's total equity in CopyTrader mirrors against last week, last month, and year-to-date reference points. Part of the Risk Dashboard suite (SP_rsk_AgregatedRisk, Gil Alpert, 2023-10-12). Refreshed daily via SB_Daily, TRUNCATE + INSERT.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Internal DWH aggregation via SP_rsk_AgregatedRisk (Gil Alpert, 2023-10-12) |
| **Refresh** | Daily TRUNCATE + INSERT. SB_Daily, Priority 0 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX(Date ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **Row Count** | ~6 (one row per instrument type) |
| **Date Range** | Single snapshot (yesterday's date) |
| **Author** | Gil Alpert (2023-10-12), Adi F (2023-12-13) |

---

## 1. Business Meaning

This table powers the **asset allocation view of the Risk Dashboard** for CopyTrader (non-CopyFund) mirrors. It answers: "How is copy-trading equity distributed across asset classes today, and how has that distribution shifted since last week / last month / start of year?"

Each row represents one instrument type (Stocks, ETF, Crypto Currencies, Indices, Commodities, Currencies). The total_equity_copy value is the sum of (position investment amount + unrealized P&L) across all open CopyTrader positions in that asset class, restricted to valid customers (IsValidCustomer=1) and non-CopyFund mirrors (AccountTypeID<>9).

The table is **TRUNCATE + INSERT daily** — it always contains exactly 6 rows for yesterday's date. Historical data is not retained in this table. The same SP (SP_rsk_AgregatedRisk) also writes to BI_DB_rsk_DailyRiskAgg which retains the daily time series.

Stocks dominate at $1.13B, followed by ETF at $202M and Crypto at $43.7M. Currencies and Commodities are under $2M each.

---

## 2. Business Logic

### 2.1 CopyTrader Filter (Non-CopyFund)

**What**: Only CopyTrader mirrors are included — CopyFund (Smart Portfolio) mirrors are excluded.
**Columns Involved**: All total_equity_copy* columns.
**Rules**:
- Join BI_DB_PositionPnL to Dim_Mirror to Dim_Customer on ParentCID
- Filter: Dim_Customer.AccountTypeID <> 9 (excludes CopyFund/Smart Portfolio parent accounts)
- MirrorID <> 0 (excludes manual positions)

### 2.2 Four-Point Time Comparison

**What**: Each metric is calculated at four different dates for trend comparison.
**Columns Involved**: total_equity_copy, total_equity_copy_LW, total_equity_copy_LM, total_equity_copy_YTD
**Rules**:
- **Yesterday**: DateID = CONVERT(CHAR(8), DATEADD(DAY,-1,GETDATE()), 112)
- **Last Week start**: DateID = first day of the current week (Sunday)
- **Last Month start**: DateID = first day of the current month
- **YTD start**: DateID = Jan 1st of current year (YEAR(GETDATE()-1)*10000+101)

### 2.3 Equity Calculation

**What**: Total equity per asset class = investment amount + unrealized P&L.
**Columns Involved**: total_equity_copy* (all four).
**Rules**:
- SUM(Amount + PositionPnL) from BI_DB_PositionPnL
- Grouped by Dim_Instrument.InstrumentType

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN**: Appropriate for 6-row table. No JOIN benefit from hashing.
- **CLUSTERED INDEX(Date ASC)**: Only one date at a time, so the index is trivial.
- Always returns 6 rows — no need for WHERE filtering.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current asset allocation | `SELECT * FROM BI_DB_Mirror_Assets_Allocation ORDER BY total_equity_copy DESC` |
| Week-over-week change | `SELECT InstrumentType, total_equity_copy - total_equity_copy_LW AS wow_change` |
| YTD growth by asset class | `SELECT InstrumentType, total_equity_copy - total_equity_copy_YTD AS ytd_change, (total_equity_copy - total_equity_copy_YTD) / NULLIF(total_equity_copy_YTD, 0) * 100 AS ytd_pct` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_rsk_DailyRiskAgg | Date = Date | Full risk metrics (AUM, STD, covariance) for the same day |

### 3.4 Gotchas

- **Only yesterday's data**: TRUNCATE + INSERT means no historical rows. For time series, use BI_DB_rsk_DailyRiskAgg.
- **CopyTrader only**: Excludes CopyFund (Smart Portfolio). CopyFund is tracked separately in BI_DB_rsk_DailyRiskAgg.
- **Instrument type strings**: Values come from Dim_Instrument.InstrumentType (e.g., "Crypto Currencies" not "Crypto").
- **Equity includes unrealized P&L**: total_equity_copy = Amount + PositionPnL, which can swing with market movements.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | Derived from SP code analysis |
| Tier 5 | Standard ETL metadata column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Snapshot date (yesterday's date). The table always holds one day's worth of data. (Tier 2 — SP_rsk_AgregatedRisk) |
| 2 | InstrumentType | varchar(50) | NO | Asset class label from Dim_Instrument.InstrumentType. 6 values: Stocks, ETF, Crypto Currencies, Indices, Commodities, Currencies. (Tier 2 — SP_rsk_AgregatedRisk) |
| 3 | total_equity_copy | decimal(38,4) | YES | Total equity in CopyTrader mirrors for this instrument type on the snapshot date. SUM(Amount+PositionPnL) from BI_DB_PositionPnL where MirrorID<>0 and non-CopyFund. In USD. (Tier 2 — SP_rsk_AgregatedRisk) |
| 4 | total_equity_copy_LW | decimal(38,4) | YES | Same metric as total_equity_copy but calculated at the start of the current week (last Sunday). For week-over-week comparison. (Tier 2 — SP_rsk_AgregatedRisk) |
| 5 | total_equity_copy_LM | decimal(38,4) | YES | Same metric as total_equity_copy but calculated at the start of the current month. For month-over-month comparison. (Tier 2 — SP_rsk_AgregatedRisk) |
| 6 | total_equity_copy_YTD | decimal(38,4) | YES | Same metric as total_equity_copy but calculated at January 1st of the current year. For year-to-date comparison. (Tier 2 — SP_rsk_AgregatedRisk) |
| 7 | UpdateDate | datetime | NO | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — SP_rsk_AgregatedRisk) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-----------------|--------------|-----------|
| Date | BI_DB_PositionPnL | Date | Direct |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Via InstrumentID join |
| total_equity_copy | BI_DB_PositionPnL | Amount + PositionPnL | SUM grouped by InstrumentType, filtered to CopyTrader mirrors |
| total_equity_copy_LW/LM/YTD | BI_DB_PositionPnL | Amount + PositionPnL | Same SUM at different reference dates |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (daily position P&L)
  + DWH_dbo.Dim_Instrument (InstrumentType lookup)
  + DWH_dbo.Dim_Customer (IsValidCustomer=1 filter)
  + DWH_dbo.Dim_Mirror → Dim_Customer (AccountTypeID<>9 = non-CopyFund filter)
  |-- SP_rsk_AgregatedRisk @sd (TRUNCATE + INSERT) ---|
  v
BI_DB_dbo.BI_DB_Mirror_Assets_Allocation (6 rows, one per asset class)
  |-- Risk Dashboard visualization ---|
  v
Risk Dashboard (asset allocation view)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentType | DWH_dbo.Dim_Instrument.InstrumentType | Asset class classification |
| (source) | BI_DB_dbo.BI_DB_PositionPnL | Position-level P&L data |
| (source) | DWH_dbo.Dim_Mirror | Mirror relationship for CopyTrader filter |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers in the DWH. This table feeds the **Risk Dashboard** visualization layer.

---

## 7. Sample Queries

### 7.1 Current Asset Allocation with Percentages

```sql
SELECT InstrumentType,
       total_equity_copy,
       total_equity_copy * 100.0 / SUM(total_equity_copy) OVER () AS pct_allocation
FROM [BI_DB_dbo].[BI_DB_Mirror_Assets_Allocation]
ORDER BY total_equity_copy DESC
```

### 7.2 Week-over-Week and YTD Change

```sql
SELECT InstrumentType,
       total_equity_copy AS current_equity,
       total_equity_copy - total_equity_copy_LW AS wow_change,
       total_equity_copy - total_equity_copy_YTD AS ytd_change,
       CASE WHEN total_equity_copy_YTD <> 0
            THEN (total_equity_copy - total_equity_copy_YTD) / total_equity_copy_YTD * 100
       END AS ytd_pct_change
FROM [BI_DB_dbo].[BI_DB_Mirror_Assets_Allocation]
ORDER BY total_equity_copy DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 6 T2, 0 T3, 0 T4, 1 T5 | Elements: 7/7, Logic: 9/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_Mirror_Assets_Allocation | Type: Table | Production Source: SP_rsk_AgregatedRisk (internal aggregation)*
