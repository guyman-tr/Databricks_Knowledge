# BI_DB_dbo.BI_DB_PositionPnL_SWITCH

> Transient shadow table (always 0 rows) used exclusively by the partition-switching mechanism in SP_BI_DB_PositionPnL_SWITCH. Temporarily receives old partition data from BI_DB_PositionPnL during the daily swap, then is truncated. Schema is an exact clone of BI_DB_PositionPnL (39 columns). Not independently loaded or queried.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (infrastructure / partition-switch shadow) |
| **Production Source** | None (schema cloned from BI_DB_dbo.BI_DB_PositionPnL via SP_PositionPnL) |
| **Refresh** | Dropped and recreated each SP_PositionPnL run; truncated after each partition swap |
| | |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC, Date ASC, CID ASC, PositionID ASC) |
| **Synapse Partitions** | Daily by DateID (mirrors BI_DB_PositionPnL partition scheme) |
| **NCI** | IX_BI_DB_PositionPnL_SWITCH_CID on (DateID, CID) |
| | |
| **UC Target** | _Not_Migrated (infrastructure table, no UC export) |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

BI_DB_PositionPnL_SWITCH is a **partition-switching shadow table** — an infrastructure artifact with no independent business purpose. It exists solely to support the Synapse partition-swap pattern used by `SP_BI_DB_PositionPnL_SWITCH` when loading daily position P&L snapshots into `BI_DB_PositionPnL`.

The table is recreated from scratch on every `SP_PositionPnL` execution via `CREATE TABLE ... AS SELECT TOP 0 * FROM BI_DB_PositionPnL`, which clones the schema (all 39 columns) with matching distribution, clustered index, and partition scheme. During the switch operation:

1. The old partition data for the target DateID is swapped OUT of `BI_DB_PositionPnL` INTO this SWITCH table
2. New data from `BI_DB_PositionPnL_SWITCH_SINGLE` is swapped INTO `BI_DB_PositionPnL`
3. This SWITCH table is truncated (old data discarded)

After ETL completes, the table is always empty (0 rows). It is never queried by analysts or downstream procedures. It carries no persistent data and has no independent consumers.

---

## 2. Business Logic

### 2.1 Partition-Switching Shadow Pattern

**What**: Synapse partition swap requires a shadow table with an identical schema, distribution, index, and partition scheme to temporarily hold displaced partition data.

**Columns Involved**: All 39 columns (must match BI_DB_PositionPnL exactly)

**Rules**:
- The table is dropped and recreated on every SP_PositionPnL run
- Schema is cloned via `SELECT TOP 0 * FROM BI_DB_PositionPnL` (empty clone)
- Partition boundaries are dynamically read from `sys.partition_range_values` of the main table
- After the swap, `TRUNCATE TABLE BI_DB_dbo.BI_DB_PositionPnL_SWITCH` discards the old data
- The table must have identical HASH distribution (PositionID), clustered index, and partition scheme to the main table — otherwise the `ALTER TABLE ... SWITCH PARTITION` statement will fail

**Diagram**:
```
SP_PositionPnL daily run:
  1. Build #UnrealizedPnL (position P&L calculations)
  2. DROP + CREATE BI_DB_PositionPnL_SWITCH_SINGLE (empty clone of main table)
  3. DROP + CREATE BI_DB_PositionPnL_SWITCH (empty clone of main table)  <-- THIS TABLE
  4. INSERT into SWITCH_SINGLE from #UnrealizedPnL
  5. EXEC SP_BI_DB_PositionPnL_SWITCH:
     a. SWITCH PARTITION N: BI_DB_PositionPnL -> BI_DB_PositionPnL_SWITCH  (old data out)
     b. SWITCH PARTITION N: BI_DB_PositionPnL_SWITCH_SINGLE -> BI_DB_PositionPnL  (new data in)
     c. TRUNCATE BI_DB_PositionPnL_SWITCH  (discard old data)
  6. UPDATE DailyPnL on main table
```

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**HASH (PositionID)** with a CLUSTERED INDEX on (DateID, Date, CID, PositionID) — identical to BI_DB_PositionPnL. This matching is required for partition swap compatibility. A NONCLUSTERED INDEX on (DateID, CID) is created by SP_PositionPnL for the same reason.

### 3.1b UC (Databricks) Storage & Partitioning

Not migrated to Databricks. This is an infrastructure table with no analytical value.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| This table should never be queried directly | Query BI_DB_dbo.BI_DB_PositionPnL instead — it holds the persistent data |

### 3.3 Common JOINs

No JOINs — this table is never queried directly. All position P&L queries should target `BI_DB_dbo.BI_DB_PositionPnL`.

### 3.4 Gotchas

- **Always empty**: This table is truncated at the end of every partition switch. If you find data in it, the ETL failed mid-execution — investigate SP_BI_DB_PositionPnL_SWITCH.
- **Dropped and recreated**: SP_PositionPnL drops this table on every run. Do not add constraints, indexes, or grants that you expect to persist.
- **Schema must match main table**: Any DDL change to BI_DB_PositionPnL must be mirrored here (and in SWITCH_SINGLE). In practice, SP_PositionPnL handles this automatically by cloning the schema dynamically.
- **Not a data table**: Do not include this table in data catalogs, reporting, or downstream ETL. It is infrastructure only.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★☆☆ | Tier 2 | `(Tier 2 — BI_DB_PositionPnL)` | Schema cloned from BI_DB_PositionPnL; descriptions inherited from upstream wiki |

All columns are schema-cloned from `BI_DB_PositionPnL`. Descriptions below are inherited from the `BI_DB_PositionPnL` wiki. No data ever persists in this table.

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | CID | int | YES | Customer identifier for the position. (Tier 2 — BI_DB_PositionPnL) |
| 2 | PositionID | bigint | NO | Unique position key; Synapse distribution key. (Tier 2 — BI_DB_PositionPnL) |
| 3 | InstrumentID | int | NO | Traded instrument identifier. (Tier 2 — BI_DB_PositionPnL) |
| 4 | MirrorID | int | YES | Copy-trading mirror link when applicable. (Tier 2 — BI_DB_PositionPnL) |
| 5 | Commission | money | NO | Opening commission in dollars. (Tier 2 — BI_DB_PositionPnL) |
| 6 | InitForexRate | numeric(16,8) | NO | Open rate; split-adjusted in SP when position spans a split. (Tier 2 — BI_DB_PositionPnL) |
| 7 | SpreadedPipBid | numeric(16,8) | YES | Bid with spread at open. (Tier 2 — BI_DB_PositionPnL) |
| 8 | SpreadedPipAsk | numeric(16,8) | YES | Ask with spread at open. (Tier 2 — BI_DB_PositionPnL) |
| 9 | PositionPnL | decimal(16,4) | YES | Unrealized P&L in USD; from PnLInDollars (replaces legacy formula). (Tier 2 — BI_DB_PositionPnL) |
| 10 | Price | numeric(38,6) | YES | Per-unit price-move expression multiplied by USD conversion factor. (Tier 2 — BI_DB_PositionPnL) |
| 11 | HedgeServerID | int | YES | Hedge server for the position. (Tier 2 — BI_DB_PositionPnL) |
| 12 | Amount | money | NO | Position amount in USD; rewound via Dim_PositionChangeLog when changes occur after snapshot date. (Tier 2 — BI_DB_PositionPnL) |
| 13 | AmountInUnitsDecimal | numeric(16,6) | YES | Size in instrument units; split-adjusted and rewound from partial-close log when applicable. (Tier 2 — BI_DB_PositionPnL) |
| 14 | LimitRate | numeric(16,8) | NO | Take-profit rate. (Tier 2 — BI_DB_PositionPnL) |
| 15 | StopRate | numeric(16,8) | NO | Stop-loss rate; rewound to PreviousStopRate when edited after snapshot date. (Tier 2 — BI_DB_PositionPnL) |
| 16 | IsBuy | bit | NO | Long (1) vs short (0). (Tier 2 — BI_DB_PositionPnL) |
| 17 | Occurred | datetime | NO | Position open timestamp (OpenOccurred from Dim_Position). (Tier 2 — BI_DB_PositionPnL) |
| 18 | Date | date | YES | Snapshot calendar date. (Tier 2 — BI_DB_PositionPnL) |
| 19 | DateID | int | NO | Snapshot date as YYYYMMDD integer; partition key. (Tier 2 — BI_DB_PositionPnL) |
| 20 | UpdateDate | datetime | YES | Row load timestamp at insert (GETDATE()). (Tier 2 — BI_DB_PositionPnL) |
| 21 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. Rewound via PositionChangeLog when applicable. (Tier 2 — BI_DB_PositionPnL) |
| 22 | NOP | money | YES | Net open position in USD from units multiplied by pair rate, direction, and conversion factor. (Tier 2 — BI_DB_PositionPnL) |
| 23 | DailyPnL | decimal(16,4) | YES | Day-over-day change: PositionPnL minus prior day PositionPnL. (Tier 2 — BI_DB_PositionPnL) |
| 24 | Leverage | int | YES | Position leverage multiplier. (Tier 2 — BI_DB_PositionPnL) |
| 25 | RateBid | numeric(36,12) | YES | EOD bid from Fact_CurrencyPriceWithSplit, split-adjusted. (Tier 2 — BI_DB_PositionPnL) |
| 26 | RateAsk | numeric(36,12) | YES | EOD ask from Fact_CurrencyPriceWithSplit, split-adjusted. (Tier 2 — BI_DB_PositionPnL) |
| 27 | USD_CR | money | YES | End-of-day USD conversion rate from Dim_Position.CurrentConversionRate. (Tier 2 — BI_DB_PositionPnL) |
| 28 | SettlementTypeID | int | YES | Settlement type from Dim_Position. (Tier 2 — BI_DB_PositionPnL) |
| 29 | EstimateCloseFeeForCFD | numeric(19,8) | YES | Estimated close fee for CFD from production PnL inputs. (Tier 2 — BI_DB_PositionPnL) |
| 30 | EstimateCloseFeeOnOpenByUnits | numeric(19,8) | YES | Estimated close fee per units-at-open path. (Tier 2 — BI_DB_PositionPnL) |
| 31 | EstimateCloseFeeOnOpen | numeric(19,8) | YES | Estimated close fee from open parameters. (Tier 2 — BI_DB_PositionPnL) |
| 32 | Close_PnLInDollars | decimal(19,4) | YES | Official close-price P&L in dollars from Dim_Position. (Tier 2 — BI_DB_PositionPnL) |
| 33 | Close_CalculationRate | decimal(18,8) | YES | Rate used for close P&L calculation. (Tier 2 — BI_DB_PositionPnL) |
| 34 | Close_ConversionRate | decimal(18,8) | YES | FX conversion at close for regulated P&L. (Tier 2 — BI_DB_PositionPnL) |
| 35 | Close_PriceType | int | YES | Close price type indicator from upstream PnL. (Tier 2 — BI_DB_PositionPnL) |
| 36 | CurrentCalculationRate | numeric(18,8) | YES | Max-date calculation rate for last-bid style P&L. (Tier 2 — BI_DB_PositionPnL) |
| 37 | CurrentConversionRate | numeric(18,8) | YES | Conversion rate paired with current calculation rate. (Tier 2 — BI_DB_PositionPnL) |
| 38 | Close_NOP | numeric(18,8) | YES | NOP using close rates: AmountInUnitsDecimal * Close_CalculationRate * Close_ConversionRate. (Tier 2 — BI_DB_PositionPnL) |
| 39 | Current_NOP | numeric(18,8) | YES | NOP using current rates: AmountInUnitsDecimal * CurrentCalculationRate * CurrentConversionRate. (Tier 2 — BI_DB_PositionPnL) |

---

## 5. Lineage

### 5.1 Production Sources

This table has no independent production source. Its schema is dynamically cloned from `BI_DB_PositionPnL` on every ETL run. Data transiently passes through during partition swaps but is immediately truncated.

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| All 39 columns | BI_DB_dbo.BI_DB_PositionPnL | Same column names | Schema clone via SELECT TOP 0; data passes through transiently during partition swap |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position + Fact_CurrencyPriceWithSplit + Dim_HistorySplitRatio + Dim_PositionChangeLog + Dim_Instrument
  |-- SP_PositionPnL @dt ---|
  v
#UnrealizedPnL (temp table with calculated P&L)
  |-- INSERT INTO BI_DB_PositionPnL_SWITCH_SINGLE ---|
  v
BI_DB_dbo.BI_DB_PositionPnL_SWITCH_SINGLE (staging for new daily partition)
  |-- SP_BI_DB_PositionPnL_SWITCH ---|
  |   Step 1: SWITCH old partition OUT of BI_DB_PositionPnL -> BI_DB_PositionPnL_SWITCH  <-- THIS TABLE
  |   Step 2: SWITCH new partition IN from SWITCH_SINGLE -> BI_DB_PositionPnL
  |   Step 3: TRUNCATE BI_DB_PositionPnL_SWITCH  <-- always empty after
  v
BI_DB_dbo.BI_DB_PositionPnL (main table, daily partition replaced)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None. This table does not participate in JOINs or FK relationships.

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.SP_PositionPnL | DDL (DROP/CREATE) | Creates this table as an empty schema clone of BI_DB_PositionPnL |
| BI_DB_dbo.SP_BI_DB_PositionPnL_SWITCH | ALTER TABLE SWITCH | Receives old partition data, then is truncated |

---

## 7. Sample Queries

### 7.1 Verify shadow table is empty after ETL

```sql
-- Should always return 0 rows; non-zero indicates a failed partition swap
SELECT COUNT(*) AS orphan_rows
FROM [BI_DB_dbo].[BI_DB_PositionPnL_SWITCH];
```

### 7.2 Check schema parity with main table

```sql
-- Compare column count between SWITCH and main table
SELECT 'SWITCH' AS tbl, COUNT(*) AS col_count
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'BI_DB_dbo' AND TABLE_NAME = 'BI_DB_PositionPnL_SWITCH'
UNION ALL
SELECT 'MAIN', COUNT(*)
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_SCHEMA = 'BI_DB_dbo' AND TABLE_NAME = 'BI_DB_PositionPnL';
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped -- regen harness mode.)

---

*Generated: 2026-04-29 | Quality: 8.0/10 | Phases: 11/11*
*Tiers: 0 T1, 39 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 39/39, Logic: 8/10, Relationships: 8/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_PositionPnL_SWITCH | Type: Table (infrastructure) | Production Source: Schema cloned from BI_DB_PositionPnL via SP_PositionPnL*
