# BI_DB_dbo.BI_DB_ABook_Exposure

> ABook hedging NOP (Net Open Position) exposure snapshot table tracking per-instrument, per-hedge-server exposure metrics — both before hedging (unhedged) and after hedging (net). Currently **empty (0 rows as of 2026-04-23)** — no active writer SP in the SSDT project; not registered in OpsDB. The active operational successor is `BI_DB_ABook_Exposure_NOPHedged` (different schema, hourly Generic Pipeline to UC). The companion `BI_DB_ABook_Exposure_History` (same schema, DATE-clustered) serves as the historical daily log.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — ABook hedging exposure snapshot |
| **Production Source** | Unknown — no Generic Pipeline, no SSDT SP, no OpsDB registration |
| **Refresh** | None active — table currently empty |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (HedgeServerID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |
| **Row Count** | 0 (as of 2026-04-23) |
| **Related Tables** | BI_DB_ABook_Exposure_History (same schema, DATE-clustered), BI_DB_ABook_Exposure_NOPHedged (different schema, hourly UC pipeline) |

---

## 1. Business Meaning

`BI_DB_ABook_Exposure` was a snapshot table for eToro's ABook hedging exposure — tracking the net open position (NOP) risk per financial instrument per hedge server, both before and after external hedging operations.

In eToro's trading model, the **ABook** refers to positions that are externally hedged with liquidity providers/prime brokers via the hedging engine. Each `HedgeServerID` represents a distinct hedging counterparty or hedging engine instance. For each instrument, the table records:
- **Unhedged exposure** (suffix `_unhedged`): the gross position from all customer trades before any hedging
- **Net exposure** (no suffix): the residual position after hedge orders have been placed with the counterparty
- **NOPHedged**: the dollar value of the NOP that has been successfully hedged externally

The table architecture follows a current-state pattern (HedgeServerID-clustered = designed for current-state lookups by server), with `BI_DB_ABook_Exposure_History` as the DATE-clustered historical log.

**Why the table is empty**: The active operational exposure table is now `BI_DB_ABook_Exposure_NOPHedged`, which has a distinct schema (adds `LiquidityAccountID`, `LiquidityAccountName`, `InstrumentIDToHedge`, `InstrumentID_Final`) and is exported to the data lake hourly via Generic Pipeline #471. The base `BI_DB_ABook_Exposure` appears to have been superseded and its feeding process discontinued.

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

### 2.2 HedgeServer Granularity

**What**: Data is tracked per hedge server — each counterparty or hedging engine instance has separate exposure rows.

**Columns Involved**: `HedgeServerID`, `DATE`

**Rules**:
- `HedgeServerID` matches `BI_DB_dbo.External_etoro_Trade_HedgeServer.HedgeServerID`
- One instrument can appear multiple times for different HedgeServerIDs on the same date
- The CLUSTERED INDEX on HedgeServerID supports efficient per-server queries
- `DATE` is the trading date — for current-state snapshots, this would typically be today's date

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

ROUND_ROBIN with CLUSTERED INDEX on HedgeServerID. Designed for per-server current-state lookups. For multi-server aggregations, a full table scan is required. Given the table is empty, no current query optimizations are relevant.

**Warning**: The table is currently empty. Any query returns 0 rows. Use `BI_DB_ABook_Exposure_NOPHedged` for current operational ABook exposure data.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total unhedged NOP by instrument | `SELECT InstrumentID, SUM(NOP_unhedged) GROUP BY InstrumentID` |
| Hedge efficiency | `SELECT NOP_unhedged, NOP, NOPHedged, (NOPHedged / NULLIF(NOP_unhedged, 0)) AS HedgeRatio` |
| Top exposure instruments | `ORDER BY ABS(NOP_unhedged) DESC` |
| Long/Short breakdown by server | `GROUP BY HedgeServerID, InstrumentID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| External_etoro_Trade_HedgeServer | `ON a.HedgeServerID = hs.HedgeServerID` | Hedge server name and configuration |
| DWH_dbo.Dim_Instrument | `ON a.InstrumentID = di.InstrumentID` | Full instrument metadata |
| BI_DB_ABook_Exposure_History | `ON a.HedgeServerID = h.HedgeServerID AND a.InstrumentID = h.InstrumentID AND h.DATE = @date` | Current vs. historical comparison |
| BI_DB_ABook_Exposure_NOPHedged | `ON a.HedgeServerID = n.HedgeServerID AND a.InstrumentID = n.InstrumentID` | Cross-reference with active successor table |

### 3.4 Gotchas

- **Table is currently empty** — 0 rows as of 2026-04-23. Use `BI_DB_ABook_Exposure_NOPHedged` for current ABook exposure.
- **Not in UC pipeline** — unlike `BI_DB_ABook_Exposure_NOPHedged` (which is exported hourly to `bi_db.gold...`), this table has no UC target.
- **_unhedged suffix = gross** — columns with `_unhedged` suffix are gross/pre-hedge. Columns without suffix are net/post-hedge. NOPHedged is the delta.
- **numeric(38,6) for dollar values** — very high precision; avoid SUM over large datasets without CAST to prevent overflow.
- **InstrumentName varchar(41)** — narrow field; long instrument display names may be truncated. Join to Dim_Instrument for full names.

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
| 1 | HedgeServerID | int | YES | Identifier for the eToro ABook hedging engine or counterparty server. References External_etoro_Trade_HedgeServer.HedgeServerID. Clustered index key — per-server lookups are efficient. (Tier 3 — External_etoro_Trade_HedgeServer DDL + ABook domain) |
| 2 | InstrumentID | int | YES | eToro instrument identifier. References DWH_dbo.Dim_Instrument.InstrumentID. (Tier 3 — Dim_Instrument pattern + SP_DailyNOP_ByInstrument context) |
| 3 | InstrumentName | varchar(41) | YES | Instrument display name. Likely truncated from Dim_Instrument.InstrumentDisplayName to 41 characters. (Tier 3 — column name + BI_DB_ABook_Exposure_NOPHedged schema comparison) |
| 4 | InstrumentType | varchar(41) | YES | Instrument asset class/type (e.g., "Crypto", "Stocks", "Commodities"). Matches Dim_Instrument.InstrumentType taxonomy. (Tier 3 — column name + SP_DailyNOP_ByInstrument context) |
| 5 | DATE | date | YES | Trading date of this exposure snapshot. For a current-state table, this would be today's date; for historical rows, the trading date. (Tier 3 — column name + ABook snapshot pattern) |
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
| 16 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last loaded. (Tier 5 — propagation) |
| 17 | NOPHedged | numeric(38,6) | YES | Dollar value of NOP that has been successfully hedged externally with the liquidity provider. Relationship: NOP ≈ NOP_unhedged − NOPHedged. Named column in BI_DB_ABook_Exposure_NOPHedged (same concept). (Tier 3 — column name + BI_DB_ABook_Exposure_NOPHedged schema) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| HedgeServerID | etoro Trade / HedgeServer system | HedgeServerID | Passthrough |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough |
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
BI_DB_dbo.BI_DB_ABook_Exposure (0 rows — EMPTY as of 2026-04-23)

Related active pipeline (different schema):
  BI_DB_ABook_Exposure_NOPHedged → Generic Pipeline #471 (60 min, Override)
    → Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_ABook_Exposure_NOPHedged/
    → UC: bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged

Historical log (same schema, DATE-clustered):
  BI_DB_ABook_Exposure_History (separate table — daily history of this table's content)

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
| Schema sibling | BI_DB_ABook_Exposure_History | DATE-clustered historical log of this table |
| Active successor | BI_DB_ABook_Exposure_NOPHedged | Active exposure table with liquidity account detail (hourly UC pipeline) |

### 6.2 Referenced By

No downstream consumers identified in the SSDT BI_DB_dbo stored procedures or views.

---

## 7. Sample Queries

### Current exposure by instrument (when populated)

```sql
SELECT
    InstrumentID,
    InstrumentName,
    InstrumentType,
    SUM(NOP_unhedged) AS GrossNOP,
    SUM(NOP) AS NetNOP,
    SUM(NOPHedged) AS HedgedNOP,
    SUM(NOP_unhedged) - SUM(NOPHedged) AS ResidualRisk
FROM [BI_DB_dbo].[BI_DB_ABook_Exposure]
GROUP BY InstrumentID, InstrumentName, InstrumentType
ORDER BY ABS(SUM(NOP_unhedged)) DESC;
```

### Hedge efficiency per server

```sql
SELECT
    a.HedgeServerID,
    hs.SystemName AS HedgeServerName,
    SUM(a.NOP_unhedged) AS GrossNOP,
    SUM(a.NOPHedged) AS HedgedNOP,
    CAST(SUM(a.NOPHedged) AS FLOAT) / NULLIF(SUM(a.NOP_unhedged), 0) AS HedgeRatio
FROM [BI_DB_dbo].[BI_DB_ABook_Exposure] a
LEFT JOIN [BI_DB_dbo].[External_etoro_Trade_HedgeServer] hs
    ON a.HedgeServerID = hs.HedgeServerID
GROUP BY a.HedgeServerID, hs.SystemName
ORDER BY HedgeRatio ASC;
```

### Check table state

```sql
SELECT
    COUNT(*) AS row_count,
    MIN(DATE) AS earliest_date,
    MAX(DATE) AS latest_date,
    MAX(UpdateDate) AS last_updated
FROM [BI_DB_dbo].[BI_DB_ABook_Exposure];
-- Returns 0 rows as of 2026-04-23
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found. This table has no active pipeline documentation.

---

*Generated: 2026-04-23 | Quality: 7.0/10 | Phases: 6/14 (P3/P5/P6/P7/P9/P9B/P10 skipped — empty table, no writer SP)*
*Tiers: 0 T1, 0 T2, 16 T3, 0 T4, 1 T5 | Elements: 17/17 | Object: BI_DB_dbo.BI_DB_ABook_Exposure | Type: Table | Production Source: Unknown (ABook hedging engine — discontinued)*
*Note: Table is currently empty (0 rows). Active successor is BI_DB_ABook_Exposure_NOPHedged (hourly UC pipeline). Quality 7.0 — penalized for empty table and no writer SP, but columns well-characterized by domain knowledge (ABook NOP hedging model).*
