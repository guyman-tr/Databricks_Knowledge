# BI_DB_dbo.BI_DB_ABook_Exposure_History

> ABook hedging NOP (Net Open Position) exposure historical daily log — DATE-clustered archive companion to `BI_DB_ABook_Exposure` (the current-state snapshot). Tracks per-instrument, per-hedge-server exposure metrics across trading dates, both before hedging (unhedged) and after hedging (net). Currently **empty (0 rows as of 2026-04-23)** — no active writer SP in the SSDT project; not registered in OpsDB. The active operational successor is `BI_DB_ABook_Exposure_NOPHedged` (different schema, hourly Generic Pipeline to UC). The companion `BI_DB_ABook_Exposure` (same schema, HedgeServerID-clustered) serves as the current-state snapshot.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — ABook hedging exposure historical log |
| **Production Source** | Unknown — no Generic Pipeline, no SSDT SP, no OpsDB registration |
| **Refresh** | None active — table currently empty |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DATE ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23) |
| **Related Tables** | BI_DB_ABook_Exposure (same schema, HedgeServerID-clustered), BI_DB_ABook_Exposure_NOPHedged (different schema, hourly UC pipeline) |

---

## 1. Business Meaning

`BI_DB_ABook_Exposure_History` is the DATE-clustered historical log for eToro's ABook hedging exposure — archiving daily snapshots of the net open position (NOP) risk per financial instrument per hedge server, both before and after external hedging operations.

In eToro's trading model, the **ABook** refers to positions that are externally hedged with liquidity providers/prime brokers via the hedging engine. Each `HedgeServerID` represents a distinct hedging counterparty or hedging engine instance. For each instrument and date, the table records:
- **Unhedged exposure** (suffix `_unhedged`): the gross position from all customer trades before any hedging
- **Net exposure** (no suffix): the residual position after hedge orders have been placed with the counterparty
- **NOPHedged**: the dollar value of the NOP that has been successfully hedged externally

The table architecture follows a historical-log pattern (DATE-clustered = designed for date-range queries over time), with `BI_DB_ABook_Exposure` as the HedgeServerID-clustered current-state snapshot companion.

**Why the table is empty**: The active operational exposure table is now `BI_DB_ABook_Exposure_NOPHedged`, which has a distinct schema (adds `LiquidityAccountID`, `LiquidityAccountName`, `InstrumentIDToHedge`, `InstrumentID_Final`) and is exported to the data lake hourly via Generic Pipeline #471. Both `BI_DB_ABook_Exposure` and `BI_DB_ABook_Exposure_History` appear to have been superseded and their feeding processes discontinued.

---

## 2. Business Logic

### 2.1 Hedged vs. Unhedged Exposure Pairs

**What**: Each position metric has two versions — the gross (pre-hedge) and the net (post-hedge) exposure.

**Columns Involved**: All paired `{metric}_unhedged` vs `{metric}` columns

**Rules**:
- `NOP_unhedged` = sum of all customer long positions minus short positions, before any external hedges
- `NOP` = residual NOP after hedge orders placed — the true A-Book risk eToro carries
- `NOPHedged` = dollar value of NOP externally hedged with the liquidity provider
- Relationship: `NOP ≈ NOP_unhedged − NOPHedged`
- Same logic applies to `OpenPositions`, `Short`, `Long`
- All NOP values are in notional dollar terms (numeric(38,6))
- `Nop_Units` / `Nop_Units_unhedged` = same metrics but in instrument units (shares, contracts) — numeric(38,2)

### 2.2 HedgeServer and Date Granularity

**What**: Data is tracked per hedge server per trading date — each counterparty or hedging engine instance has separate exposure rows per day.

**Columns Involved**: `HedgeServerID`, `DATE`

**Rules**:
- `HedgeServerID` matches `BI_DB_dbo.External_etoro_Trade_HedgeServer.HedgeServerID`
- One instrument can appear multiple times for different HedgeServerIDs on the same date
- `DATE` is the trading date — the clustered index key designed for historical date-range queries
- For any given date, this table should reflect the end-of-day exposure state archived from `BI_DB_ABook_Exposure`

### 2.3 NOP Definition

**What**: NOP (Net Open Position) = total long positions minus total short positions.

**Columns Involved**: `NOP`, `NOP_unhedged`, `Long`, `Short`, `Nop_Units`, `Long_unhedged`, `Short_unhedged`

**Rules**:
- `NOP = Long − Short` (notional dollar value)
- `Nop_Units = Nop_Units (long) − Nop_Units (short)` in instrument units
- Positive NOP = net long; Negative NOP = net short
- A-Book hedging target: minimize |NOP| — hedge the residual risk

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on DATE. Designed for historical date-range queries (e.g., exposure over a date range). For per-server historical queries, a full table scan is required. Given the table is empty, no current query optimizations are relevant.

**Warning**: The table is currently empty. Any query returns 0 rows. Use `BI_DB_ABook_Exposure_NOPHedged` for current operational ABook exposure data.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Historical NOP trend by instrument | `SELECT DATE, InstrumentID, SUM(NOP) GROUP BY DATE, InstrumentID ORDER BY DATE` |
| Daily hedge efficiency over time | `SELECT DATE, SUM(NOP_unhedged), SUM(NOPHedged), SUM(NOPHedged)/NULLIF(SUM(NOP_unhedged),0) AS HedgeRatio GROUP BY DATE` |
| Exposure on a specific date | `WHERE DATE = '2024-01-01'` — clustered index on DATE makes this efficient |
| Long/Short trend by server | `GROUP BY DATE, HedgeServerID, InstrumentID ORDER BY DATE` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| External_etoro_Trade_HedgeServer | `ON h.HedgeServerID = hs.HedgeServerID` | Hedge server name and configuration |
| DWH_dbo.Dim_Instrument | `ON h.InstrumentID = di.InstrumentID` | Full instrument metadata |
| BI_DB_ABook_Exposure | `ON h.HedgeServerID = a.HedgeServerID AND h.InstrumentID = a.InstrumentID` | Historical vs. current-state comparison |
| BI_DB_ABook_Exposure_NOPHedged | `ON h.HedgeServerID = n.HedgeServerID AND h.InstrumentID = n.InstrumentID AND h.DATE = n.Date` | Cross-reference with active successor table |

### 3.4 Gotchas

- **Table is currently empty** — 0 rows as of 2026-04-23. Use `BI_DB_ABook_Exposure_NOPHedged` for current ABook exposure.
- **Not in UC pipeline** — unlike `BI_DB_ABook_Exposure_NOPHedged` (which is exported hourly to `bi_db.gold...`), this table has no UC target.
- **_unhedged suffix = gross** — columns with `_unhedged` suffix are gross/pre-hedge. Columns without suffix are net/post-hedge. NOPHedged is the delta.
- **numeric(38,6) for dollar values** — very high precision; avoid SUM over large datasets without CAST to prevent overflow.
- **InstrumentName varchar(41)** — narrow field; long instrument display names may be truncated. Join to Dim_Instrument for full names.
- **DATE is clustered index key** — unlike the sibling `BI_DB_ABook_Exposure` (clustered on HedgeServerID), this table clusters on DATE for time-series queries.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from writer SP code (direct tracing) |
| Tier 3 | Inferred from column name, related table schemas, and ABook domain context |
| Tier 4 | No source traceable — best-effort description |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | HedgeServerID | int | YES | Identifier for the eToro ABook hedging engine or counterparty server. References External_etoro_Trade_HedgeServer.HedgeServerID. (Tier 3 — External_etoro_Trade_HedgeServer DDL + ABook domain) |
| 2 | InstrumentID | int | YES | eToro instrument identifier. References DWH_dbo.Dim_Instrument.InstrumentID. (Tier 3 — Dim_Instrument pattern + SP_DailyNOP_ByInstrument context) |
| 3 | InstrumentName | varchar(41) | YES | Instrument display name. Likely truncated from Dim_Instrument.InstrumentDisplayName to 41 characters. (Tier 3 — column name + BI_DB_ABook_Exposure_NOPHedged schema comparison) |
| 4 | InstrumentType | varchar(41) | YES | Instrument asset class/type (e.g., "Crypto", "Stocks", "Commodities"). Matches Dim_Instrument.InstrumentType taxonomy. (Tier 3 — column name + SP_DailyNOP_ByInstrument context) |
| 5 | DATE | date | YES | Trading date of this historical exposure record. Clustered index key — date-range queries are efficient. (Tier 3 — column name + ABook historical log pattern) |
| 6 | NOP_unhedged | numeric(38,6) | YES | Gross Net Open Position in notional dollar value — raw exposure from all customer long/short positions before any external hedge orders are placed. Positive = net long, Negative = net short. (Tier 3 — column name + ABook domain: NOP = Long − Short) |
| 7 | NOP | numeric(38,6) | YES | Net Open Position after applying external hedges — the residual ABook risk eToro carries with the liquidity provider. Relationship: NOP ≈ NOP_unhedged − NOPHedged. (Tier 3 — column name + ABook hedging model) |
| 8 | Nop_Units_unhedged | numeric(38,2) | YES | Gross NOP expressed in instrument units (shares, contracts, etc.) before hedging. Less precision (38,2) than dollar NOP as units are coarser. (Tier 3 — column name + BI_DB_ABook_Exposure_NOPHedged schema) |
| 9 | Nop_Units | numeric(38,2) | YES | Net NOP in instrument units after hedging. (Tier 3 — column name + ABook domain) |
| 10 | OpenPositions_unhedged | numeric(38,6) | YES | Gross total open position size (long + short) before external hedges in notional dollar value. (Tier 3 — column name + ABook domain) |
| 11 | OpenPositions | numeric(38,6) | YES | Net total open position after hedging in notional dollar value. (Tier 3 — column name + ABook domain) |
| 12 | Short_unhedged | numeric(38,6) | YES | Gross total short position exposure in notional dollars before hedging. (Tier 3 — column name + ABook domain) |
| 13 | Short | numeric(38,6) | YES | Net short position exposure in notional dollars after hedge orders. (Tier 3 — column name + ABook domain) |
| 14 | Long_unhedged | numeric(38,6) | YES | Gross total long position exposure in notional dollars before hedging. (Tier 3 — column name + ABook domain) |
| 15 | Long | numeric(38,6) | YES | Net long position exposure in notional dollars after hedge orders. (Tier 3 — column name + ABook domain) |
| 16 | NOPHedged | numeric(38,6) | YES | Dollar value of NOP that has been successfully hedged externally with the liquidity provider. Relationship: NOP ≈ NOP_unhedged − NOPHedged. Named column in BI_DB_ABook_Exposure_NOPHedged (same concept). (Tier 3 — column name + BI_DB_ABook_Exposure_NOPHedged schema) |
| 17 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last loaded. (Tier 5 — propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| HedgeServerID | etoro Trade / HedgeServer system | HedgeServerID | Passthrough |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough / truncated |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough |
| DATE | ABook hedging feed | Date | Trading date |
| NOP_unhedged/NOP/NOPHedged | ABook hedging engine | NOP calculations | Aggregated per instrument/server |
| All exposure metrics | ABook hedging engine | Position aggregations | Long−Short NOP, Open positions |
| UpdateDate | ETL pipeline | — | Load timestamp |

### 5.2 ETL Pipeline

```
etoro ABook hedging engine (external hedging system)
  |-- Unknown feed (no Generic Pipeline, no External Table, no SSDT SP) --|
  v
BI_DB_dbo.BI_DB_ABook_Exposure (0 rows — EMPTY as of 2026-04-23, current-state snapshot)
  |-- Likely append to BI_DB_ABook_Exposure_History (daily historical archive) --|
  v
BI_DB_dbo.BI_DB_ABook_Exposure_History (0 rows — EMPTY as of 2026-04-23, DATE-clustered log)

Related active pipeline (different schema):
  BI_DB_ABook_Exposure_NOPHedged → Generic Pipeline #471 (60 min, Override)
    → Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_ABook_Exposure_NOPHedged/
    → UC: bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged

HedgeServer reference data:
  External_etoro_Trade_HedgeServer ← Bronze/etoro/Trade/HedgeServer (parquet)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| HedgeServerID | External_etoro_Trade_HedgeServer | Hedge server configuration (IP, mode, strategy) |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata (name, type, asset class) |
| Schema sibling | BI_DB_ABook_Exposure | HedgeServerID-clustered current-state snapshot of this table |
| Active successor | BI_DB_ABook_Exposure_NOPHedged | Active exposure table with liquidity account detail (hourly UC pipeline) |

### 6.2 Referenced By

No downstream consumers identified in the SSDT BI_DB_dbo stored procedures or views.

---

## 7. Sample Queries

### Historical NOP trend by instrument

```sql
SELECT
    DATE,
    InstrumentID,
    InstrumentName,
    InstrumentType,
    SUM(NOP_unhedged) AS GrossNOP,
    SUM(NOP) AS NetNOP,
    SUM(NOPHedged) AS HedgedNOP
FROM [BI_DB_dbo].[BI_DB_ABook_Exposure_History]
GROUP BY DATE, InstrumentID, InstrumentName, InstrumentType
ORDER BY DATE DESC, ABS(SUM(NOP_unhedged)) DESC;
```

### Daily hedge efficiency over time

```sql
SELECT
    h.DATE,
    a.HedgeServerID,
    hs.SystemName AS HedgeServerName,
    SUM(h.NOP_unhedged) AS GrossNOP,
    SUM(h.NOPHedged) AS HedgedNOP,
    CAST(SUM(h.NOPHedged) AS FLOAT) / NULLIF(SUM(h.NOP_unhedged), 0) AS HedgeRatio
FROM [BI_DB_dbo].[BI_DB_ABook_Exposure_History] h
LEFT JOIN [BI_DB_dbo].[External_etoro_Trade_HedgeServer] hs
    ON h.HedgeServerID = hs.HedgeServerID
GROUP BY h.DATE, h.HedgeServerID, hs.SystemName
ORDER BY h.DATE DESC;
```

### Check table state

```sql
SELECT
    COUNT(*) AS row_count,
    MIN(DATE) AS earliest_date,
    MAX(DATE) AS latest_date,
    MAX(UpdateDate) AS last_updated
FROM [BI_DB_dbo].[BI_DB_ABook_Exposure_History];
-- Returns 0 rows as of 2026-04-23
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. This table has no active pipeline documentation.

---

*Generated: 2026-04-23 | Quality: 7.0/10 | Phases: 6/14 (P3/P5/P6/P7/P9/P9B/P10 skipped — empty table, no writer SP)*
*Tiers: 0 T1, 0 T2, 16 T3, 0 T4, 1 T5 | Elements: 17/17 | Object: BI_DB_dbo.BI_DB_ABook_Exposure_History | Type: Table | Production Source: Unknown (ABook hedging engine — discontinued)*
*Note: Table is currently empty (0 rows). DATE-clustered historical log companion to BI_DB_ABook_Exposure (HedgeServerID-clustered). Active successor is BI_DB_ABook_Exposure_NOPHedged (hourly UC pipeline). Quality 7.0 — penalized for empty table and no writer SP, but columns well-characterized by domain knowledge (ABook NOP hedging model) and verbatim sibling wiki.*
