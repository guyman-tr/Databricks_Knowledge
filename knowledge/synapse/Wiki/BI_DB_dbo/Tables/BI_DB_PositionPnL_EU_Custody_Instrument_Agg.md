# BI_DB_dbo.BI_DB_PositionPnL_EU_Custody_Instrument_Agg

> 8.66M-row accumulating instrument-level aggregation of the EU (CySEC) stock/ETF custody book. Each row represents one instrument on one day, broken down by IsBuy, IsCreditReportValidCB, IsValidCustomer, and HedgeServerID. Sourced from `BI_DB_PositionPnL_EU_Custody` via `SP_BI_DB_PositionPnL_EU_Custody` (DELETE+INSERT by DateID). 839 dates from 2023-12-26 to present.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_PositionPnL_EU_Custody` (aggregated by instrument) |
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

This table provides a **pre-aggregated instrument-level summary** of the EU (CySEC) stock/ETF custody book. Instead of querying the 20.5M-row position-level `BI_DB_PositionPnL_EU_Custody` table and aggregating at query time, consumers can read this table directly for instrument-level NOP, PnL, Amount, and units.

Each row represents one instrument on one day, further broken down by IsBuy direction, credit-reporting flags (IsCreditReportValidCB, IsValidCustomer), and HedgeServerID. The grain is: **one row per (DateID, InstrumentID, IsBuy, IsCreditReportValidCB, IsValidCustomer, HedgeServerID)**.

Unlike the position-level EU_Custody table (which is TRUNCATEd daily), this aggregation table **accumulates** — it uses DELETE+INSERT by DateID, preserving historical dates. Currently holds 8.66M rows across 839 dates from 2023-12-26 to 2026-04-12.

The companion `BI_DB_PositionPnL_UK_Instrument_Agg` table holds the equivalent aggregation for the UK book (Entity = 'UK'), sourced from the same #posFCA temp table but with Entity hardcoded to 'UK'.

---

## 2. Business Logic

### 2.1 Instrument-Level Aggregation

**What**: Sums position-level metrics to instrument level for the EU custody book.
**Columns Involved**: PositionPnL, Amount, AmountInUnitsDecimal, NOP
**Rules**:
- SUM(PositionPnL) — total unrealized P&L per instrument per day
- SUM(Amount) — total position amount in USD per instrument per day
- SUM(AmountInUnitsDecimal) — total instrument units per instrument per day
- SUM(NOP) — total net open position in USD per instrument per day

### 2.2 Entity Tagging

**What**: Marks all rows as 'EU' entity.
**Columns Involved**: Entity
**Rules**:
- Hardcoded to 'EU' for this table
- The UK_Instrument_Agg companion uses 'UK'
- Enables UNION queries across both books when needed

### 2.3 Accumulating History

**What**: Retains historical dates unlike the position-level table.
**Columns Involved**: DateID
**Rules**:
- DELETE WHERE DateID = @dateID before INSERT (idempotent re-run for a given date)
- Historical dates are preserved — 839 dates available
- Start date aligns with the SP creation (2023-12-21, first data 2023-12-26)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution. CLUSTERED INDEX on DateID ASC — efficient for date-range scans. Since this table accumulates, always include a DateID filter to avoid scanning all 839 dates.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|----------------------|
| EU custody NOP by instrument today | `SELECT InstrumentID, SUM(NOP) FROM ... WHERE DateID = <today> GROUP BY InstrumentID` |
| Historical EU book size trend | `SELECT DateID, SUM(Amount), SUM(NOP) FROM ... GROUP BY DateID ORDER BY DateID` |
| Compare EU vs UK books | `SELECT Entity, SUM(NOP) FROM (SELECT * FROM EU_Instrument_Agg UNION ALL SELECT * FROM UK_Instrument_Agg) GROUP BY Entity` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Resolve instrument name, symbol, type |
| BI_DB_PositionPnL_UK_Instrument_Agg | InstrumentID + DateID | Compare EU vs UK instrument-level exposure |

### 3.4 Gotchas

- **IsBuy is always 1** — real stock custody is BUY-only; the GROUP BY key adds no segmentation in practice
- **No UC target** — this table is not exported to the data lake; use the Synapse table directly
- **Entity is always 'EU'** — use UK_Instrument_Agg for the UK book, not a WHERE filter on Entity
- **UpdateDate is GETDATE()** — reflects when the aggregation ran, not when positions were opened

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
| 1 | Entity | varchar(10) | YES | Entity identifier for the custody book. Hardcoded to 'EU' for this table. The UK companion table uses 'UK'. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody) |
| 2 | InstrumentID | int | NO | Traded instrument. GROUP BY key. Only stocks/ETFs (InstrumentTypeID 5,6). FK to Dim_Instrument. Passthrough from BI_DB_PositionPnL_EU_Custody. (Tier 1 — BI_DB_PositionPnL) |
| 3 | PositionPnL | decimal(16,4) | YES | Aggregate unrealized P&L in USD. SUM of position-level PositionPnL from EU_Custody for this instrument/date/group. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody, SUM) |
| 4 | Amount | money | NO | Aggregate position amount in USD. SUM of position-level Amount from EU_Custody. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody, SUM) |
| 5 | AmountInUnitsDecimal | numeric(16,6) | YES | Aggregate size in instrument units. SUM of position-level AmountInUnitsDecimal from EU_Custody. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody, SUM) |
| 6 | Date | date | YES | Snapshot calendar date. GROUP BY key. (Tier 1 — BI_DB_PositionPnL) |
| 7 | DateID | int | NO | Snapshot date as YYYYMMDD. Clustered index key and GROUP BY key. DELETE+INSERT granularity. (Tier 1 — BI_DB_PositionPnL) |
| 8 | NOP | money | YES | Aggregate net open position in USD. SUM of position-level NOP from EU_Custody. (Tier 2 — SP_BI_DB_PositionPnL_EU_Custody, SUM) |
| 9 | IsBuy | int | YES | Long (1) vs short (0). GROUP BY key. Always 1 in practice (custody = BUY-only). Note: type is int here vs bit in EU_Custody. (Tier 1 — BI_DB_PositionPnL) |
| 10 | UpdateDate | datetime | YES | Row load timestamp. GETDATE() at aggregation insert time (not inherited from source). (Tier 3 — SP_BI_DB_PositionPnL_EU_Custody, GETDATE()) |
| 11 | IsCreditReportValidCB | int | YES | 1 if customer eligible for CreditBureau credit report validation. ETL-computed in Fact_SnapshotCustomer. GROUP BY key. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 12 | IsValidCustomer | int | YES | 1 if valid retail customer for analytics. ETL-computed in Fact_SnapshotCustomer. GROUP BY key. (Tier 1 — DWH_dbo.Fact_SnapshotCustomer) |
| 13 | HedgeServerID | int | YES | Hedge server for the position group. GROUP BY key. 16 distinct values. (Tier 1 — BI_DB_PositionPnL) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| Entity | — | — | Hardcoded 'EU' |
| InstrumentID, Date, DateID, IsBuy, IsCreditReportValidCB, IsValidCustomer, HedgeServerID | BI_DB_PositionPnL_EU_Custody | Same names | GROUP BY keys (passthrough) |
| PositionPnL, Amount, AmountInUnitsDecimal, NOP | BI_DB_PositionPnL_EU_Custody | Same names | SUM() aggregation |
| UpdateDate | — | — | GETDATE() |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL_EU_Custody (20.5M rows, single day)
  |-- SP_BI_DB_PositionPnL_EU_Custody @date
  |-- DELETE WHERE DateID = @dateID
  |-- INSERT with GROUP BY InstrumentID, Date, DateID, IsBuy, IsCreditReportValidCB, IsValidCustomer, HedgeServerID
  |-- SUM(PositionPnL, Amount, AmountInUnitsDecimal, NOP), Entity='EU', UpdateDate=GETDATE()
  v
BI_DB_dbo.BI_DB_PositionPnL_EU_Custody_Instrument_Agg (8.66M rows, accumulating)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | FK — instrument details, type, symbol |

### 6.2 Referenced By (other objects point to this)

No known downstream consumers identified.

---

## 7. Sample Queries

### 7.1 Daily EU Custody Book Total NOP

```sql
SELECT DateID, SUM(NOP) AS TotalNOP, SUM(PositionPnL) AS TotalPnL
FROM BI_DB_dbo.BI_DB_PositionPnL_EU_Custody_Instrument_Agg
WHERE DateID >= 20260401
GROUP BY DateID
ORDER BY DateID
```

### 7.2 Top Instruments by NOP on Latest Date

```sql
SELECT TOP 20
    agg.InstrumentID, di.SymbolFull,
    SUM(agg.NOP) AS TotalNOP,
    SUM(agg.Amount) AS TotalAmount
FROM BI_DB_dbo.BI_DB_PositionPnL_EU_Custody_Instrument_Agg agg
JOIN DWH_dbo.Dim_Instrument di ON agg.InstrumentID = di.InstrumentID
WHERE agg.DateID = 20260412
GROUP BY agg.InstrumentID, di.SymbolFull
ORDER BY TotalNOP DESC
```

---

## 8. Atlassian Knowledge Sources

No relevant Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 6 T1, 5 T2, 1 T3, 0 T4, 1 T5 | Elements: 13/13, Logic: 7/10, Completeness: 10/10*
*Object: BI_DB_dbo.BI_DB_PositionPnL_EU_Custody_Instrument_Agg | Type: Table | Production Source: BI_DB_PositionPnL_EU_Custody via SP_BI_DB_PositionPnL_EU_Custody*
