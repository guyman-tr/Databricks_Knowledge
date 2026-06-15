# BI_DB_dbo.BI_DB_PositionPnL_UK_Instrument_Agg

> 8.66M-row accumulating instrument-level aggregation of the UK book for CySEC stock/ETF custody positions. Each row represents one instrument on one day, broken down by IsBuy, IsCreditReportValidCB, IsValidCustomer, and HedgeServerID. Entity = 'UK'. Sourced from #posFCA (same temp table as EU_Custody, NOT from the UK_Custody table) via `SP_BI_DB_PositionPnL_EU_Custody` (DELETE+INSERT by DateID). 839 dates from 2023-12-26 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_PositionPnL` (via #posFCA, aggregated by instrument) |
| **Writer SP** | `BI_DB_dbo.SP_BI_DB_PositionPnL_EU_Custody` (Guy Manova 2023-12-21) |
| **Refresh** | Daily, DELETE+INSERT by DateID (accumulating — retains historical dates) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | _Not_Mapped (no Generic Pipeline entry found) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is the **UK book companion** to `BI_DB_PositionPnL_EU_Custody_Instrument_Agg`. It provides instrument-level summaries for the UK custody book view. Despite the "UK" entity tag, the underlying data is identical to the EU aggregation — both are sourced from the same #posFCA temp table (CySEC stock/ETF positions). The Entity column ('EU' vs 'UK') distinguishes the two views for downstream reconciliation consumers.

Each row represents one instrument on one day, broken down by IsBuy, IsCreditReportValidCB, IsValidCustomer, and HedgeServerID. The grain is: **one row per (DateID, InstrumentID, IsBuy, IsCreditReportValidCB, IsValidCustomer, HedgeServerID)**.

The table accumulates via DELETE+INSERT by DateID, holding 8.66M rows across 839 dates from 2023-12-26 to 2026-04-12. Row counts are identical to the EU aggregation table.

**Important**: The UK_Instrument_Agg is sourced from #posFCA directly (the pre-anonymization temp table), NOT from `UK_Custody` (the post-anonymization table). This is an SP implementation detail — the aggregation values are the same either way since CID is not a GROUP BY key.

---

## 2. Business Logic

### 2.1 UK Entity Tagging

**What**: Marks all rows as 'UK' entity for the UK custody book view.
**Columns Involved**: Entity
**Rules**:
- Hardcoded to 'UK' for this table (vs 'EU' in EU_Custody_Instrument_Agg)
- Enables UNION queries across both books

### 2.2 Instrument-Level Aggregation

**What**: Sums position-level metrics to instrument level.
**Columns Involved**: PositionPnL, Amount, AmountInUnitsDecimal, NOP
**Rules**:
- SUM(PositionPnL), SUM(Amount), SUM(AmountInUnitsDecimal), SUM(NOP)
- Grouped by InstrumentID, Date, DateID, IsBuy, IsCreditReportValidCB, IsValidCustomer, HedgeServerID
- Values are mathematically identical to EU_Instrument_Agg (same source data, same GROUP BY)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution. CLUSTERED INDEX on DateID ASC. Always include DateID filter when querying historical data.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| UK book total NOP by date | `SELECT DateID, SUM(NOP) FROM ... GROUP BY DateID` |
| Compare EU vs UK totals | UNION ALL with EU_Instrument_Agg, GROUP BY Entity, DateID |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Resolve instrument name, symbol |
| BI_DB_PositionPnL_EU_Custody_Instrument_Agg | InstrumentID + DateID | Compare EU vs UK instrument exposure |

### 3.4 Gotchas

- **Values identical to EU_Instrument_Agg** — both aggregate the same #posFCA source data; differences indicate a data issue
- **No UC target** — Synapse-only table
- **Sourced from #posFCA, not UK_Custody** — the aggregation bypasses the anonymized UK_Custody table

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Description from documented upstream wiki (verbatim) |
| Tier 2 | Description from SP code analysis |
| Tier 3 | Description from data sampling / parameter inference |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Entity | varchar(10) | YES | Entity identifier for the custody book. Hardcoded to 'UK' for this table. The EU companion table uses 'EU'. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody) |
| 2 | InstrumentID | int | NO | Traded instrument. GROUP BY key. Only stocks/ETFs (InstrumentTypeID 5,6). FK to Dim_Instrument. Passthrough from BI_DB_PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 3 | PositionPnL | decimal(16,4) | YES | Aggregate unrealized P&L in USD. SUM of position-level PositionPnL for this instrument/date/group. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody, SUM) |
| 4 | Amount | money | NO | Aggregate position amount in USD. SUM of position-level Amount. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody, SUM) |
| 5 | AmountInUnitsDecimal | numeric(16,6) | YES | Aggregate size in instrument units. SUM of position-level AmountInUnitsDecimal. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody, SUM) |
| 6 | Date | date | YES | Snapshot calendar date. GROUP BY key. (Tier 3 — BI_DB_PositionPnL) |
| 7 | DateID | int | NO | Snapshot date as YYYYMMDD. Clustered index key and GROUP BY key. DELETE+INSERT granularity. (Tier 1 — BI_DB_PositionPnL) |
| 8 | NOP | money | YES | Aggregate net open position in USD. SUM of position-level NOP. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody, SUM) |
| 9 | IsBuy | int | YES | Long (1) vs short (0). GROUP BY key. Always 1 in practice (custody = BUY-only). (Tier 2 — BI_DB_PositionPnL) |
| 10 | UpdateDate | datetime | YES | Row load timestamp. GETDATE() at aggregation insert time. (Tier 3 — SP_BI_DB_PositionPnL_EU_Custody, GETDATE()) |
| 11 | IsCreditReportValidCB | int | YES | 1 if customer eligible for Client_Balance credit report validation. ETL-computed in Fact_SnapshotCustomer. GROUP BY key. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 12 | IsValidCustomer | int | YES | 1 if valid retail customer for analytics. ETL-computed in Fact_SnapshotCustomer. GROUP BY key. (Tier 2 — DWH_dbo.Fact_SnapshotCustomer) |
| 13 | HedgeServerID | int | YES | Hedge server for the position group. GROUP BY key. (Tier 2 — BI_DB_PositionPnL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| Entity | — | — | Hardcoded 'UK' |
| GROUP BY keys | #posFCA (BI_DB_PositionPnL + Fact_SnapshotCustomer) | Same names | Passthrough |
| SUM columns | #posFCA (BI_DB_PositionPnL) | Same names | SUM() aggregation |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
#posFCA (CySEC stock/ETF positions, same source as EU_Custody)
  |-- SP_BI_DB_PositionPnL_EU_Custody @date
  |-- DELETE WHERE DateID = @dateID
  |-- INSERT with GROUP BY, Entity='UK', UpdateDate=GETDATE()
  v
BI_DB_dbo.BI_DB_PositionPnL_UK_Instrument_Agg (8.66M rows, accumulating)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | FK — instrument details |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified.

---

## 7. Sample Queries

### 7.1 UK Book NOP Trend

```sql
SELECT DateID, SUM(NOP) AS TotalNOP
FROM BI_DB_dbo.BI_DB_PositionPnL_UK_Instrument_Agg
WHERE DateID >= 20260101
GROUP BY DateID
ORDER BY DateID
```

### 7.2 EU vs UK Combined Book by Instrument

```sql
SELECT Entity, InstrumentID, SUM(NOP) AS TotalNOP
FROM (
    SELECT * FROM BI_DB_dbo.BI_DB_PositionPnL_EU_Custody_Instrument_Agg WHERE DateID = 20260412
    UNION ALL
    SELECT * FROM BI_DB_dbo.BI_DB_PositionPnL_UK_Instrument_Agg WHERE DateID = 20260412
) combined
GROUP BY Entity, InstrumentID
ORDER BY TotalNOP DESC
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 6 T1, 5 T2, 1 T3, 0 T4, 0 T5 | Elements: 13/13, Logic: 7/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_PositionPnL_UK_Instrument_Agg | Type: Table | Production Source: BI_DB_PositionPnL via SP_BI_DB_PositionPnL_EU_Custody*
