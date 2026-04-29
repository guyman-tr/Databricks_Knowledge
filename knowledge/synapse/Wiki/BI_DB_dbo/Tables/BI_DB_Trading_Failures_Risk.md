# BI_DB_dbo.BI_DB_Trading_Failures_Risk

> 27.7M-row trading execution monitoring table tracking both failed and succeeded position open/close events aggregated by date, instrument, error code, leverage type, copy/manual, direction, hedge server, and regulation. Sourced from Dealing_staging.PositionFail + DWH_dbo.Dim_Position via SP_Trading_Failures_Risk. Covers April 2024 to present. Daily DELETE+INSERT refresh.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Dealing_staging.PositionFailReal_History_PositionFail_DWH (failures) + DWH_dbo.Dim_Position (succeeds) via SP_Trading_Failures_Risk (author: Artyom Bogomolsky, 2024-08-14) |
| **Refresh** | Daily (DELETE+INSERT by @Date via OpsDB Service Broker, Priority 0) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk` |
| **UC Format** | parquet |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Append, 1440 min) |

---

## 1. Business Meaning

`BI_DB_Trading_Failures_Risk` is a risk monitoring table that provides a daily comparison of failed vs. succeeded trading executions on the eToro platform. Each row represents an aggregated bucket of either failures or successes for a specific combination of date, instrument, error code, leverage type (leveraged/not), copy/manual trade, open/close direction, hedge server, and regulation.

The table contains 27.7M rows from April 2024 to April 2026. Row distribution: Succeeded opens (12.4M), Succeeded closes (12.2M), Failed opens (2.4M), Failed closes (664K). The failure rate can be derived by comparing Failures vs. Succeeds rows for each dimension combination.

The ETL in `SP_Trading_Failures_Risk` combines two data streams:
1. **Failures**: From `Dealing_staging.PositionFailReal_History_PositionFail_DWH` — actual position execution failures. Open failures (FailTypeID=3) are enriched with `DB_Logs_History_OpenExecutionPlan` for copy-trade MirrorID/Amount. Close failures (FailTypeID=4) are enriched with `Dim_Position` for leverage/amount. Hierarchical failures (Level>0) and noise error codes (1043, 1044) are excluded.
2. **Succeeds**: From `DWH_dbo.Dim_Position` — positions that successfully opened or closed on @Date. ErrorCode=-1 (sentinel for success). Partial close children are excluded.

Both streams are aggregated to the same granularity (COUNT DISTINCT CID as Customers, COUNT orders/positions, SUM Amount/Volume) and UNIONed into a single table.

Regulation was added in October 2024 (SR-276909 by Adar); earlier rows have NULL RegulationID/Regulation.

---

## 2. Business Logic

### 2.1 Failure vs. Success Classification

**What**: Each row is either a 'Failures' or 'Succeeds' event bucket.
**Columns Involved**: `Type`, `ErrorCode`
**Rules**:
- Type='Failures': Real execution failures from PositionFail (FailTypeID 3 or 4)
- Type='Succeeds': Successfully opened/closed positions from Dim_Position
- ErrorCode: Actual error code for failures (e.g., 954, 1072); -1 sentinel for succeeds
- Excludes: hierarchical copy failures (Level>0), alignment failures (OrderID=0), noise codes (1043, 1044)

### 2.2 Leverage Type Classification

**What**: Positions classified by leverage usage.
**Columns Involved**: `Leverage_Type`
**Rules**:
- 'Leveraged': Leverage > 1
- 'Not Leveraged': Leverage = 1 (real stock/crypto, no leverage)

### 2.3 Copy vs. Manual Classification

**What**: Distinguishes copy-trading from manual trading.
**Columns Involved**: `Copy_Manual`
**Rules**:
- 'Copy': MirrorID > 0 (position was opened as part of a copy-trading relationship)
- 'Manual': MirrorID = 0 or NULL (user-initiated trade)

### 2.4 Volume Computation

**What**: Volume represents the leveraged notional value.
**Columns Involved**: `Volume`, `Amount`
**Rules**:
- Failures (Open): Amount * Leverage
- Failures (Close): Amount * Leverage (from Dim_Position)
- Succeeds (Open): InitialAmountCents/100 * Leverage
- Succeeds (Close): VolumeOnClose from Dim_Position

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with HEAP. Large table (27.7M rows) — always filter by Date for reasonable performance.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Daily failure rate | `GROUP BY Date, Type` then calculate Failures/(Failures+Succeeds) |
| Error code analysis | `WHERE Type = 'Failures' GROUP BY ErrorCode, Date` |
| Copy vs manual failure rate | `GROUP BY Copy_Manual, Type` |
| Instrument-level failures | `GROUP BY InstrumentID, Type WHERE Date = @Date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID = InstrumentID | Instrument name, type, ISIN |
| DWH_dbo.Dim_Regulation | RegulationID = ID | Full regulation details |

### 3.4 Gotchas

- **ErrorCode -1 = Success**: Not a real error — it's a sentinel value meaning the position succeeded
- **AirDrop_Type is unpopulated**: Column exists in DDL but is not populated by the SP INSERT
- **RegulationID/Regulation NULL before Oct 2024**: Regulation was added later; early data has NULLs
- **Customers is COUNT(DISTINCT CID)**: Not additive across dimension slices — re-aggregate from raw if needed
- **Volume units differ**: Open failures use Amount*Leverage (dollars*leverage), Close failures use Amount*Leverage from Dim_Position, Succeeds(Open) uses InitialAmountCents/100*Leverage — all should be in dollars but rounding/source differences possible
- **UC copy strategy is Append**: Historical corrections won't overwrite — the UC table grows monotonically

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream production wiki (verbatim) | Highest — verified by code-is-king pipeline |
| Tier 2 | SP code analysis | High — derived from ETL logic |
| Tier 5 | ETL metadata | Standard ETL infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | Event date. Failures: CAST(FailOccurred AS DATE). Succeeds: CAST(OpenOccurred/CloseOccurred AS DATE). Used as partition key for DELETE+INSERT. (Tier 2 — SP_Trading_Failures_Risk) |
| 2 | ErrorCode | int | YES | Execution error code. Failures: actual error code from PositionFail (e.g., 954, 1072). Succeeds: -1 (sentinel meaning success). Excludes noise codes 1043, 1044. (Tier 2 — SP_Trading_Failures_Risk) |
| 3 | InstrumentID | int | YES | Unique identifier for a tradeable financial instrument. FK to Dim_Instrument. From PositionFail/Dim_Position. (Tier 2 — SP_Trading_Failures_Risk) |
| 4 | Leverage_Type | varchar(50) | YES | Leverage classification. 'Leveraged' if Leverage>1, 'Not Leveraged' if Leverage=1. 2 distinct values. (Tier 2 — SP_Trading_Failures_Risk) |
| 5 | Copy_Manual | varchar(50) | YES | Trade origin classification. 'Copy' if MirrorID>0 (copy-trading), 'Manual' if MirrorID=0/NULL (user-initiated). 2 distinct values. (Tier 2 — SP_Trading_Failures_Risk) |
| 6 | ind_open_close | varchar(50) | YES | Trade direction. 'Open' for position opening events, 'Close' for position closing events. 2 distinct values. (Tier 2 — SP_Trading_Failures_Risk) |
| 7 | Type | varchar(50) | YES | Event outcome type. 'Failures' for execution failures, 'Succeeds' for successful executions. 2 distinct values. (Tier 2 — SP_Trading_Failures_Risk) |
| 8 | Customers | int | YES | COUNT(DISTINCT CID) of unique customers in this aggregation bucket. Not additive across dimension slices. (Tier 2 — SP_Trading_Failures_Risk) |
| 9 | Orders_Positions | bigint | YES | Count of orders (for failures) or positions (for succeeds) in this aggregation bucket. (Tier 2 — SP_Trading_Failures_Risk) |
| 10 | Amount | money | YES | Sum of investment amounts in this bucket. Failures: from PositionFail.Amount or OpenExecutionPlan.Amount. Succeeds (Open): InitialAmountCents/100. Succeeds (Close): Dim_Position.Amount. (Tier 2 — SP_Trading_Failures_Risk) |
| 11 | Volume | bigint | YES | Sum of leveraged volume (Amount * Leverage) in this bucket. Represents notional trading value. Succeeds (Close): uses VolumeOnClose from Dim_Position. (Tier 2 — SP_Trading_Failures_Risk) |
| 12 | HedgeServerID | int | YES | Hedge server that processed the execution. From PositionFail/Dim_Position. FK to hedge server dimension. (Tier 2 — SP_Trading_Failures_Risk) |
| 13 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() at SP execution time. (Tier 5 — ETL metadata) |
| 14 | RegulationID | int | YES | Regulatory entity ID from Dim_Customer.RegulationID. NULL for data before October 2024 (regulation added later by SR-276909). (Tier 2 — SP_Trading_Failures_Risk) |
| 15 | Regulation | varchar(30) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough via Dim_Customer.RegulationID → Dim_Regulation.Name. NULL before October 2024. (Tier 1 — Dictionary.Regulation) |
| 16 | AirDrop_Type | varchar(50) | YES | Column exists in DDL but is not populated by the current SP INSERT statement. Always NULL. (Tier 2 — SP_Trading_Failures_Risk) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | PositionFail / Dim_Position | FailOccurred / OpenOccurred / CloseOccurred | CAST AS DATE |
| ErrorCode | PositionFail / (literal) | ErrorCode / -1 | Passthrough / sentinel |
| InstrumentID | PositionFail / Dim_Position | InstrumentID | Passthrough |
| Leverage_Type | PositionFail / Dim_Position | Leverage | CASE >1 → 'Leveraged' |
| Copy_Manual | OpenExecutionPlan / Dim_Position | MirrorID | CASE >0 → 'Copy' |
| ind_open_close | (computed) | FailTypeID | 'Open' (3) or 'Close' (4) |
| Type | (computed) | — | 'Failures' or 'Succeeds' |
| Customers | (aggregation) | CID | COUNT(DISTINCT CID) |
| Orders_Positions | (aggregation) | OrderID / PositionID | COUNT |
| Amount | PositionFail / Dim_Position | Amount / InitialAmountCents | SUM |
| Volume | (computed) | Amount * Leverage | SUM |
| HedgeServerID | PositionFail / Dim_Position | HedgeServerID | Passthrough |
| UpdateDate | (ETL) | GETDATE() | ETL metadata |
| RegulationID | DWH_dbo.Dim_Customer | RegulationID | Passthrough |
| Regulation | DWH_dbo.Dim_Regulation | Name | Dim-lookup passthrough |
| AirDrop_Type | (unpopulated) | — | Not in SP INSERT |

### 5.2 ETL Pipeline

```
Dealing_staging.PositionFailReal_History_PositionFail_DWH (position execution failures)
  + CopyFromLake.DB_Logs_History_OpenExecutionPlan (open execution plans)
  + Dealing_staging.External_DB_Logs_History_CloseExecutionPlan (close execution plans)
  + DWH_dbo.Dim_Position (succeeded opens/closes + close failure enrichment)
  + DWH_dbo.Dim_Customer (CID→RegulationID)
  + DWH_dbo.Dim_Regulation (RegulationID→Name)
  |-- SP_Trading_Failures_Risk @Date --|
  |-- Step 1: Get failures (Open FailTypeID=3 + Close FailTypeID=4) --|
  |-- Step 2: Aggregate failures by 8 dimensions --|
  |-- Step 3: Get succeeded positions from Dim_Position (opened + closed on @Date) --|
  |-- Step 4: UNION failures + succeeds --|
  |-- DELETE+INSERT by @Date --|
  v
BI_DB_dbo.BI_DB_Trading_Failures_Risk (27.7M rows)
  |-- Generic Pipeline (Append, parquet, 1440 min) --|
  v
trading.gold_sql_dp_prod_we_bi_db_dbo_bi_db_trading_failures_risk
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Financial instrument dimension |
| RegulationID | DWH_dbo.Dim_Regulation (ID) | Regulation dimension |
| HedgeServerID | Dealing infrastructure | Hedge server routing |

### 6.2 Referenced By (other objects point to this)

No consumer SPs found referencing this table.

---

## 7. Sample Queries

### 7.1 Daily failure rate trend

```sql
SELECT Date,
       SUM(CASE WHEN Type = 'Failures' THEN Orders_Positions ELSE 0 END) AS failures,
       SUM(CASE WHEN Type = 'Succeeds' THEN Orders_Positions ELSE 0 END) AS succeeds,
       CAST(SUM(CASE WHEN Type = 'Failures' THEN Orders_Positions ELSE 0 END) AS FLOAT)
       / NULLIF(SUM(Orders_Positions), 0) AS failure_rate
FROM BI_DB_dbo.BI_DB_Trading_Failures_Risk
WHERE Date >= DATEADD(DAY, -30, GETDATE())
GROUP BY Date
ORDER BY Date
```

### 7.2 Top error codes by volume

```sql
SELECT ErrorCode, SUM(Orders_Positions) AS total_orders, SUM(Amount) AS total_amount
FROM BI_DB_dbo.BI_DB_Trading_Failures_Risk
WHERE Type = 'Failures' AND Date >= DATEADD(DAY, -7, GETDATE())
GROUP BY ErrorCode
ORDER BY total_orders DESC
```

### 7.3 Copy vs manual failure comparison

```sql
SELECT Date, Copy_Manual, ind_open_close,
       SUM(CASE WHEN Type = 'Failures' THEN Orders_Positions ELSE 0 END) AS failures,
       SUM(CASE WHEN Type = 'Succeeds' THEN Orders_Positions ELSE 0 END) AS succeeds
FROM BI_DB_dbo.BI_DB_Trading_Failures_Risk
WHERE Date = @Date
GROUP BY Date, Copy_Manual, ind_open_close
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 1 T1, 14 T2, 0 T3, 0 T4, 1 T5 | Elements: 16/16, Logic: 8/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_Trading_Failures_Risk | Type: Table | Production Source: PositionFail + Dim_Position via SP_Trading_Failures_Risk*
