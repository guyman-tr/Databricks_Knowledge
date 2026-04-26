# BI_DB_dbo.BI_DB_ABook_Exposure_NOPHedged

> ABook hedging NOP (Net Open Position) exposure snapshot — the active operational ABook exposure table providing per-instrument, per-hedge-server, per-liquidity-account net exposure metrics. Unlike its dormant sibling tables (`BI_DB_ABook_Exposure`, `BI_DB_ABook_Exposure_History`), this table is fed by **Generic Pipeline #471** (hourly Override strategy) and exported to Unity Catalog. Net-only table — no `_unhedged` column pairs. Adds `LiquidityAccountID`/`LiquidityAccountName` and proxy-hedge instrument columns (`InstrumentIDToHedge`, `InstrumentID_Final`) not present in siblings. Currently **stale (last updated 2024-02-15)** despite active pipeline configuration.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table — ABook hedging NOP exposure snapshot (net-only, per liquidity account) |
| **Production Source** | Generic Pipeline #471 — Synapse Override feed, every 60 min |
| **Refresh** | Override (full replace per run); last updated 2024-02-15 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged` |
| **UC Format** | Parquet |
| **UC Partitioned By** | N/A |
| **UC Table Type** | External (Generic Pipeline managed) |
| **Row Count** | 15,178 (as of 2026-04-23; all from 2024-02-15) |
| **Related Tables** | BI_DB_ABook_Exposure (dormant, no LP columns), BI_DB_ABook_Exposure_History (dormant, DATE-clustered) |

---

## 1. Business Meaning

`BI_DB_ABook_Exposure_NOPHedged` is eToro's active ABook hedging exposure table — tracking the net open position (NOP) for each financial instrument per hedge server and liquidity provider account. The ABook represents positions that eToro has externally hedged with prime brokers and liquidity providers (LPs).

Key additions beyond the dormant sibling tables:
- **Liquidity Account granularity**: `LiquidityAccountID`/`LiquidityAccountName` identify which specific LP account (e.g., "APEX Traffix Account Real", "EMSX JPM Execution (CBH)") was used for the hedge. 44 distinct LP accounts observed in live data.
- **Proxy instrument hedging**: `InstrumentIDToHedge` captures when hedging is done via a substitute instrument (e.g., hedging a less-liquid stock via a correlated ETF). Most positions (85%) hedge with the same instrument (NULL). `InstrumentID_Final` is always resolved (COALESCE of InstrumentIDToHedge, InstrumentID).
- **Net-only metrics**: No `_unhedged` column pairs — this table records only the post-hedging state, not the gross exposure before hedging.

The table uses an **Override** strategy via Generic Pipeline #471: on each run, the full table is replaced with the current snapshot from the Synapse production system. This is not a historical archive — for historical ABook exposure data, `BI_DB_ABook_Exposure_History` would be the intended destination (currently dormant).

**Current state**: The table contains 15,178 rows, all from 2024-02-15 00:08:38 UTC — the pipeline appears to have stopped running over 2 years ago despite the Generic Pipeline configuration remaining active.

---

## 2. Business Logic

### 2.1 NOP Definition

**What**: NOP (Net Open Position) = total long positions minus total short positions, after hedging.

**Columns Involved**: `NOP`, `Long`, `Short`, `Nop_Units`

**Rules**:
- `NOP = Long − Short` (notional dollar value, numeric(38,6))
- `Nop_Units = Long_units − Short_units` in instrument units (numeric(38,2))
- Positive NOP = net long; Negative NOP = net short
- A-Book hedging target: minimize |NOP| — hedge the residual risk with the LP

### 2.2 Hedging State

**What**: Tracks what portion of the NOP has been hedged with the liquidity provider.

**Columns Involved**: `NOP`, `NOPHedged`

**Rules**:
- `NOPHedged` = dollar value of NOP successfully hedged externally
- `NOPHedged` can exceed `NOP` (over-hedging is possible, observed in live data: KRNY/USD NOPHedged=45.15 > NOP=43.47)
- When `LiquidityAccountID IS NULL`, `NOPHedged` is typically 0 (no LP assigned = unhedged)
- Residual unhedged risk ≈ NOP − NOPHedged (may be negative if over-hedged)

### 2.3 Proxy Instrument Hedging

**What**: Some instruments are hedged via a different (proxy) instrument.

**Columns Involved**: `InstrumentID`, `InstrumentIDToHedge`, `InstrumentID_Final`

**Rules**:
- `InstrumentIDToHedge` = instrument actually used for hedging (NULL = hedge same as `InstrumentID`)
- `InstrumentID_Final` = COALESCE(`InstrumentIDToHedge`, `InstrumentID`) — always populated
- 85% of rows have `InstrumentIDToHedge IS NULL` — direct hedging is the norm
- Proxy hedging is used when a direct market is unavailable or illiquid
- `InstrumentID_Final` is the key for joining to hedging execution data

### 2.4 Liquidity Account Granularity

**What**: Exposure is tracked per LP account, giving finer resolution than HedgeServerID alone.

**Columns Involved**: `LiquidityAccountID`, `LiquidityAccountName`, `HedgeServerID`

**Rules**:
- One HedgeServer can route to multiple LiquidityAccounts
- `LiquidityAccountID` references `External_etoro_Hedge_HedgeServerToLiquidityAccount`
- 25% of rows have NULL `LiquidityAccountID` — typically BBook or positions pending LP assignment
- `LiquidityAccountName` is de-normalized from LP account configuration (no live lookup needed)
- Top LP accounts: APEX Traffix (3,032 rows), EMSX JPM Execution (2,591), Horizon OMS Apex (1,254)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Date. Since Override strategy produces a single-date snapshot, DATE equality filters are optimal. All rows currently share the same date (2024-02-15). ROUND_ROBIN means multi-node aggregations may shuffle data — for large instrument aggregations, consider explicit distribution hints.

**Warning**: All 15,178 rows are from 2024-02-15 — data is over 2 years stale as of 2026-04-23. Use with caution for current ABook exposure.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current NOP by instrument | `SELECT InstrumentID, InstrumentName, InstrumentType, SUM(NOP) GROUP BY ...` |
| NOP by liquidity provider | `SELECT LiquidityAccountName, SUM(NOP) AS TotalNOP GROUP BY LiquidityAccountName ORDER BY ABS(SUM(NOP)) DESC` |
| Hedge coverage rate | `SELECT SUM(NOPHedged) / NULLIF(SUM(NOP), 0) AS HedgeRatio` |
| Unassigned exposure | `WHERE LiquidityAccountID IS NULL` — 3,735 rows without LP assignment |
| Proxy hedged instruments | `WHERE InstrumentIDToHedge IS NOT NULL AND InstrumentIDToHedge <> InstrumentID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| External_etoro_Hedge_HedgeServerToLiquidityAccount | `ON n.LiquidityAccountID = m.LiquidityAccountID` | LP account details (AltRatesLiquidityAccountID, temporal fields) |
| External_etoro_Trade_HedgeServer | `ON n.HedgeServerID = hs.HedgeServerID` | Hedge server name and configuration |
| DWH_dbo.Dim_Instrument | `ON n.InstrumentID = di.InstrumentID` | Full instrument metadata (InstrumentName truncated to 45 chars in this table) |
| DWH_dbo.Dim_Instrument (proxy) | `ON n.InstrumentID_Final = di.InstrumentID` | Metadata for the actual hedged instrument |
| BI_DB_ABook_Exposure_History | `ON n.HedgeServerID = h.HedgeServerID AND n.InstrumentID = h.InstrumentID AND h.DATE = @date` | Historical comparison (if History table is ever populated) |

### 3.4 Gotchas

- **Data stale since 2024-02-15** — all 15,178 rows share the same date. Do not treat as current exposure data.
- **Override strategy** — the table is a current-state snapshot, not historical. No multi-date history is stored here.
- **NOPHedged can exceed NOP** — over-hedging is possible and observed in live data. Hedge ratio can exceed 1.0.
- **NULL LiquidityAccountID** — 25% of rows (3,735) have no LP assigned. These are excluded from LP-level analysis.
- **NULL InstrumentIDToHedge** — 85% of rows (12,978) hedge with same instrument. `InstrumentID_Final` is always safe to use as the resolved hedge instrument key.
- **InstrumentName varchar(45)** — wider than siblings (varchar(41)) but may still truncate long display names. Join to Dim_Instrument for full names.
- **numeric(38,6) for dollar values** — very high precision; avoid SUM over all rows without CAST to prevent overflow.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream production wiki |
| Tier 2 | Derived from writer SP code (direct tracing) |
| Tier 3 | Inferred from column name, related table schemas, live data, and ABook domain context |
| Tier 4 | No source traceable — best-effort description |
| Tier 5 | Propagation column (ETL infrastructure) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Trading date of this exposure snapshot. Clustered index key — date equality queries are efficient. All rows currently dated 2024-02-15 (stale Override snapshot). (Tier 3 — column name + Generic Pipeline Override pattern + live data) |
| 2 | InstrumentID | int | YES | eToro instrument identifier. References DWH_dbo.Dim_Instrument.InstrumentID. (Tier 3 — Dim_Instrument pattern + SP_DailyNOP_ByInstrument context) |
| 3 | InstrumentIDToHedge | int | YES | Instrument used as hedge proxy when different from InstrumentID. NULL for 85% of rows — hedge placed on the same instrument. Populated when a substitute/proxy instrument is used for hedging (e.g., proxy ETF for less-liquid stock). (Tier 3 — column name + ABook proxy hedging domain + live data) |
| 4 | InstrumentID_Final | int | YES | Resolved instrument ID used for the actual hedge execution. = InstrumentIDToHedge when non-NULL, otherwise InstrumentID. Always populated — safe key for hedging execution joins. (Tier 3 — column name + ABook proxy hedge resolution pattern + live data) |
| 5 | InstrumentName | varchar(45) | YES | Instrument display name, truncated to 45 characters. Sourced from Dim_Instrument.InstrumentDisplayName. (Tier 3 — column name + Dim_Instrument pattern + live data: KRNY/USD, AVAX/USD, etc.) |
| 6 | InstrumentType | varchar(45) | YES | Instrument asset class/type (e.g., "Crypto", "Stocks", "Commodities"). Matches Dim_Instrument.InstrumentType taxonomy. (Tier 3 — column name + SP_DailyNOP_ByInstrument context) |
| 7 | HedgeServerID | int | YES | Identifier for the eToro ABook hedging engine or counterparty server. References External_etoro_Trade_HedgeServer.HedgeServerID. 38 distinct servers observed in live data. (Tier 3 — External_etoro_Trade_HedgeServer DDL + ABook domain) |
| 8 | LiquidityAccountID | int | YES | Integer identifier of the liquidity provider account used for hedging. References External_etoro_Hedge_HedgeServerToLiquidityAccount.LiquidityAccountID. NULL for 25% of rows (positions without assigned LP). 44 distinct accounts observed. (Tier 3 — External_etoro_Hedge_HedgeServerToLiquidityAccount DDL + live data) |
| 9 | LiquidityAccountName | varchar(100) | YES | Name of the liquidity provider account (e.g., "APEX Traffix Account Real 3EU05025 Real", "EMSX JPM Execution (CBH)"). De-normalized from LP account configuration. NULL when LiquidityAccountID is NULL. (Tier 3 — live data + LP account domain) |
| 10 | NOP | numeric(38,6) | YES | Net Open Position after applying external hedges — the residual ABook risk eToro carries with the liquidity provider. Relationship: NOP ≈ NOP_unhedged − NOPHedged. (Tier 3 — column name + ABook hedging model) |
| 11 | Nop_Units | numeric(38,2) | YES | Net NOP in instrument units after hedging. (Tier 3 — column name + ABook domain) |
| 12 | NOPHedged | numeric(38,6) | YES | Dollar value of NOP that has been successfully hedged externally with the liquidity provider. Can exceed NOP (over-hedging possible). When LiquidityAccountID IS NULL, typically 0. (Tier 3 — column name + ABook hedging model + live data) |
| 13 | OpenPositions | numeric(38,6) | YES | Net total open position after hedging in notional dollar value. (Tier 3 — column name + ABook domain) |
| 14 | Short | numeric(38,6) | YES | Net short position exposure in notional dollars after hedge orders. (Tier 3 — column name + ABook domain) |
| 15 | Long | numeric(38,6) | YES | Net long position exposure in notional dollars after hedge orders. (Tier 3 — column name + ABook domain) |
| 16 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last loaded. (Tier 5 — propagation) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Date | ABook hedging feed | Date | Trading date |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough |
| InstrumentIDToHedge | ABook proxy hedge mapping | InstrumentID | NULL = same instrument; populated = proxy |
| InstrumentID_Final | Derived | — | COALESCE(InstrumentIDToHedge, InstrumentID) |
| InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough / truncated to varchar(45) |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough |
| HedgeServerID | etoro Trade / HedgeServer system | HedgeServerID | Passthrough |
| LiquidityAccountID | External_etoro_Hedge_HedgeServerToLiquidityAccount | LiquidityAccountID | Passthrough |
| LiquidityAccountName | LP account configuration system | AccountName | De-normalized |
| NOP / NOPHedged / NOP metrics | ABook hedging engine | NOP calculations | Aggregated per instrument/server/LP |
| OpenPositions / Short / Long | ABook hedging engine | Position aggregations | Per instrument/server/LP |
| UpdateDate | ETL pipeline | — | Load timestamp |

### 5.2 ETL Pipeline

```
etoro ABook hedging engine (external hedging system)
  |-- Unknown feed (no Generic Pipeline source SP) --|
  v
BI_DB_dbo.BI_DB_ABook_Exposure_NOPHedged (15,178 rows — 2024-02-15, stale)
  |-- Generic Pipeline #471 (Override, every 60 min, SynapseSourceWithoutSecret) --|
  v
Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_ABook_Exposure_NOPHedged/ (Azure Data Lake, parquet)
  |-- Unity Catalog managed --|
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged (UC Gold table)

Reference data:
  External_etoro_Hedge_HedgeServerToLiquidityAccount ← Bronze/etoro/Hedge/HedgeServerToLiquidityAccount
  External_etoro_History_HedgeServerToLiquidityAccount ← Bronze/etoro/History/HedgeServerToLiquidityAccount
  External_etoro_Trade_HedgeServer ← Bronze/etoro/Trade/HedgeServer
  DWH_dbo.Dim_Instrument ← instrument metadata

Dormant sibling tables (same hedging system, no active pipeline):
  BI_DB_ABook_Exposure (0 rows — EMPTY)
  BI_DB_ABook_Exposure_History (0 rows — EMPTY)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| HedgeServerID | External_etoro_Trade_HedgeServer | Hedge server configuration (IP, mode, strategy) |
| LiquidityAccountID | External_etoro_Hedge_HedgeServerToLiquidityAccount | LP account details (AltRatesLiquidityAccountID, temporal validity) |
| InstrumentID / InstrumentID_Final | DWH_dbo.Dim_Instrument | Instrument metadata (full name, type, asset class) |
| Schema sibling | BI_DB_ABook_Exposure | Dormant current-state snapshot (no LP columns, no proxy hedge columns) |
| Historical archive | BI_DB_ABook_Exposure_History | Dormant DATE-clustered historical log |

### 6.2 Referenced By

No downstream consumers identified in the SSDT BI_DB_dbo stored procedures or views. The UC table `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged` may have downstream Databricks consumers not visible in this SSDT scan.

---

## 7. Sample Queries

### Current exposure by liquidity provider

```sql
SELECT
    LiquidityAccountName,
    COUNT(DISTINCT InstrumentID) AS instrument_count,
    SUM(NOP) AS TotalNOP,
    SUM(NOPHedged) AS TotalHedged,
    CAST(SUM(NOPHedged) AS FLOAT) / NULLIF(SUM(NOP), 0) AS HedgeRatio
FROM [BI_DB_dbo].[BI_DB_ABook_Exposure_NOPHedged]
WHERE LiquidityAccountID IS NOT NULL
GROUP BY LiquidityAccountName
ORDER BY ABS(SUM(NOP)) DESC;
```

### Top unhedged exposure instruments

```sql
SELECT
    InstrumentID,
    InstrumentName,
    InstrumentType,
    SUM(NOP) AS NetNOP,
    SUM(NOPHedged) AS HedgedNOP,
    SUM(NOP) - SUM(NOPHedged) AS ResidualExposure
FROM [BI_DB_dbo].[BI_DB_ABook_Exposure_NOPHedged]
GROUP BY InstrumentID, InstrumentName, InstrumentType
ORDER BY ABS(SUM(NOP) - SUM(NOPHedged)) DESC;
```

### Proxy hedged instruments

```sql
SELECT
    InstrumentID,
    InstrumentName,
    InstrumentIDToHedge,
    InstrumentID_Final,
    HedgeServerID,
    SUM(NOP) AS NOP
FROM [BI_DB_dbo].[BI_DB_ABook_Exposure_NOPHedged]
WHERE InstrumentIDToHedge IS NOT NULL
GROUP BY InstrumentID, InstrumentName, InstrumentIDToHedge, InstrumentID_Final, HedgeServerID
ORDER BY InstrumentID;
```

### Check table freshness

```sql
SELECT
    COUNT(*) AS row_count,
    MIN([Date]) AS earliest_date,
    MAX([Date]) AS latest_date,
    MAX(UpdateDate) AS last_updated
FROM [BI_DB_dbo].[BI_DB_ABook_Exposure_NOPHedged];
-- Returns 15,178 rows, all from 2024-02-15 as of 2026-04-23
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found directly. Generic Pipeline #471 is the documented data movement mechanism.

---

*Generated: 2026-04-23 | Quality: 7.5/10 | Phases: 10/14 (P7/P9/P9B-writer-SP/P10 partially skipped — no writer SP)*
*Tiers: 0 T1, 0 T2, 15 T3, 0 T4, 1 T5 | Elements: 16/16 | Object: BI_DB_dbo.BI_DB_ABook_Exposure_NOPHedged | Type: Table | Production Source: Generic Pipeline #471 (Override, 60 min)*
*Note: Active Generic Pipeline (#471) with UC target. Data stale since 2024-02-15 despite active pipeline config. Net-only ABook exposure with LP account granularity and proxy instrument hedging. Quality 7.5 — live data confirmed, pipeline documented; penalized for no writer SP and stale data.*
