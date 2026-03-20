# DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot

> SCD Type 2 snapshot table tracking the history of hedge server assignments per position -- each row represents a date range during which a position was assigned to a specific HedgeServerID, with ToDate=20991231 indicating the current active assignment.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.Trade.PositionsHedgeServerChangeLog |
| **Refresh** | Daily (incremental via SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse @dt) |
| | |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED INDEX (PositionID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot` |
| **UC Format** | Delta |
| **UC Partitioned By** | None (sparse) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_PositionHedgeServerChangeLog_Snapshot tracks which hedge server (HedgeServerID) was responsible for executing and managing each position during any given date range. A hedge server is the execution venue or broker-side system where a position is "hedged" (i.e., covered with a liquidity provider). Positions can move between hedge servers during their lifetime.

This table uses an SCD Type 2 pattern:
- **FromDate**: The YYYYMMDD date from which HedgeServerID was active for this position.
- **ToDate**: The YYYYMMDD date to which HedgeServerID was active. ToDate=20991231 indicates the current/active assignment.
- A position moving from HedgeServer A to HedgeServer B generates two rows: (PositionID, ServerA, FromDate=OpenDate, ToDate=yesterday) and (PositionID, ServerB, FromDate=today, ToDate=20991231).

**Predecessor table**: The original `Dim_PositionHedgeServerChangeLog` table was replaced by this snapshot variant. The `_Snapshot` suffix indicates the SCD2 approach vs. the original raw-log approach. `Dim_PositionHedgeServerChangeLog` no longer exists in Synapse.

This table is used by SP_Dim_Position_DL_To_Synapse when populating `InitHedgeType` and `EndHedgeType` on Dim_Position (via SP_Dim_Position_HedgeType_Real and SP_Dim_Position_HedgeType_History).

---

## 2. Business Logic

### 2.1 SCD Type 2 Active-Record Pattern

**What**: Each position has one or more rows representing consecutive HedgeServerID assignments.

**Columns Involved**: `PositionID`, `HedgeServerID`, `FromDate`, `ToDate`

**Rules**:
- **Current assignment**: `WHERE ToDate = 20991231` -- gives the active hedge server for each position.
- **Historical assignment on a date**: `WHERE FromDate <= @dateID AND ToDate >= @dateID` -- point-in-time hedge server lookup.
- **Single initial assignment**: Most positions have a single row (never changed hedge server): FromDate=OpenDateID, ToDate=20991231.
- **After hedge server change**: The old row gets ToDate=dateBeforeChange. A new row is inserted with FromDate=changeDate, ToDate=20991231.
- **New positions**: On first appearance in PositionsHedgeServerChangeLog, two rows may be inserted: one for the pre-change period (OpenDateID -> OccurredDateID-1, using FromHedgeServerID) and one for the post-change period (OccurredDateID -> 20991231, using ToHedgeServerID).
- Both FromDate and ToDate are YYYYMMDD ints (e.g., 20260226). Use `CAST(CAST(FromDate AS VARCHAR(8)) AS DATE)` to convert.

### 2.2 ETL Pattern

**What**: Daily incremental update to maintain the SCD2 records.

**Rules**:
1. DELETE rows with FromDate >= yesterday (re-process yesterday's data).
2. Set ToDate=20991231 on the most recent row per PositionID (repair any open-ended records).
3. Load yesterday's hedge server changes from etoro_Trade_PositionsHedgeServerChangeLog (via Ext_Dim_Position_PositionHedgeServerChangeLog).
4. Deduplicate: Remove duplicates keeping only the most recent per PositionID (ROW_NUMBER by OccurredDate DESC).
5. For positions already in Snapshot: Close old row (ToDate=yesterday), insert new active row (FromDate=today, ToDate=20991231).
6. For new positions: Insert initial row (FromDate=OpenDateID, ToDate=OccurredDateID-1) + active row (FromDate=OccurredDateID, ToDate=20991231).

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**HASH (PositionID)**: Co-located with Dim_Position for efficient JOINs. A JOIN between Dim_PositionHedgeServerChangeLog_Snapshot and Dim_Position on PositionID benefits from co-location.

**CLUSTERED INDEX (PositionID)**: Efficient for lookups by PositionID. When querying current active records (`WHERE ToDate=20991231`), this is efficient.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionhedgeserverchangelog_snapshot`. No partitioning needed unless the table grows very large. Z-ORDER on PositionID is beneficial.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Current hedge server for a position | WHERE PositionID = X AND ToDate = 20991231 |
| Hedge server for a position on a date | WHERE PositionID = X AND FromDate <= YYYYMMDD AND ToDate >= YYYYMMDD |
| All positions on a specific hedge server today | WHERE HedgeServerID = 84 AND ToDate = 20991231 |
| Positions that changed hedge servers | Positions with more than 1 row |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | ON PositionID AND CloseDateID BETWEEN FromDate AND ToDate | Match position to its hedge server at close date |
| DWH_dbo.Dim_Position | ON PositionID AND ToDate = 20991231 | Get current hedge server |

### 3.4 Gotchas

- **ToDate=20991231 = active row**: This sentinel value (year 2099) means "no end date known yet" -- the current active assignment. NOT a real date.
- **FromDate/ToDate are int YYYYMMDD**: Cannot use standard date comparisons directly. Use `BETWEEN` with int values.
- **UpdateDate is 2026-02-27**: The table is 20+ days stale as of 2026-03-19. This is more stale than other DWH tables (which are stale to 2026-03-11). Check whether the SP runs independently from the main ETL.
- **Dim_PositionHedgeServerChangeLog does NOT exist**: The original table without `_Snapshot` suffix was dropped. Do not reference the old name.
- **Not all positions appear**: Only positions that have had a hedge server change event appear here. Positions that were assigned to one server from open to close and never changed may have only one row, or no rows if no change event was ever logged.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| **** | Tier 1 - Upstream wiki | (Tier 1 — Trade.PositionsHedgeServerChangeLog) |
| *** | Tier 2 - Synapse SP code | (Tier 2 — SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse) |
| ** | Tier 3 - MCP live data | (Tier 3 — MCP live data) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | NO | The position that was moved between hedge servers. References Trade.PositionTbl.PositionID (implicit - no declared FK). Part of composite PK with OperationSummaryID. A position can appear multiple times if moved across different operations. (Tier 1 — Trade.PositionsHedgeServerChangeLog) |
| 2 | HedgeServerID | int | NO | The hedge server ID the position was moved to. After this operation, Trade.PositionTbl.HedgeServerID equals this value for the affected position. (Tier 1 — Trade.PositionsHedgeServerChangeLog) |
| 3 | FromDate | int | YES | Start date of this hedge server assignment (YYYYMMDD int). For initial position open: equals OpenDateID. For subsequent changes: equals the date the change took effect. (Tier 2 — SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse) |
| 4 | ToDate | int | YES | End date of this hedge server assignment (YYYYMMDD int). 20991231=currently active. For closed/changed records: the last day this assignment was valid (inclusive). (Tier 2 — SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse) |
| 5 | UpdateDate | datetime | YES | ETL load timestamp (GETDATE()). All rows share same timestamp per daily ETL run. Last seen: 2026-02-27. (Tier 2 — SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Table | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| PositionID | etoro_Trade_PositionsHedgeServerChangeLog | PositionID | passthrough |
| HedgeServerID | etoro_Trade_PositionsHedgeServerChangeLog | FromHedgeServerID / ToHedgeServerID | ETL-computed: FromHedgeServerID for pre-change rows, ToHedgeServerID for post-change rows |
| FromDate | Dim_Position | OpenDateID | ETL-computed: OpenDateID for pre-change rows; OccurredDateID for post-change rows |
| ToDate | -- | -- | ETL-computed: OccurredDateID-1 for pre-change rows; 20991231 for active rows |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.Trade.PositionsHedgeServerChangeLog
  -> Generic Pipeline (daily)
  -> DWH_staging.etoro_Trade_PositionsHedgeServerChangeLog
  -> DWH_dbo.Ext_Dim_Position_PositionHedgeServerChangeLog (staging buffer)
  -> SP_Dim_Position_PositionHedgeServerChangeLog (via SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse)
  -> DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot (SCD2 upsert)
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.Trade.PositionsHedgeServerChangeLog | Production hedge server change events |
| Staging | DWH_staging.etoro_Trade_PositionsHedgeServerChangeLog | Raw staging |
| Ext | DWH_dbo.Ext_Dim_Position_PositionHedgeServerChangeLog | Loaded from staging: PositionID, OccurredDate, FromHedgeServerID, ToHedgeServerID |
| ETL | SP_Dim_PositionHedgeServerChangeLog_DL_To_Synapse | DELETE-then-rebuild for yesterday; update ToDate on open records; call SP_Dim_Position_PositionHedgeServerChangeLog |
| ETL (inner SP) | SP_Dim_Position_PositionHedgeServerChangeLog | Deduplicates ext table; closes old active rows; inserts new rows for changed/new positions |
| Target | DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot | 5 cols, SCD2 pattern |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Position | PositionID | Position being tracked |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Dim_Position_PositionHedgeServerChangeLog | PositionID | Reads active rows to update ToDate when server changes |
| DWH_dbo.SP_Dim_Position_HedgeType_Real | PositionID | Derives InitHedgeType for open positions |
| DWH_dbo.SP_Dim_Position_HedgeType_History | PositionID | Derives EndHedgeType for closed positions |

---

## 7. Sample Queries

### 7.1 Current hedge server for a specific position

```sql
SELECT PositionID, HedgeServerID, FromDate, ToDate
FROM   [DWH_dbo].[Dim_PositionHedgeServerChangeLog_Snapshot]
WHERE  PositionID = 3268434767
  AND  ToDate = 20991231;
```

### 7.2 Point-in-time hedge server for a position

```sql
SELECT PositionID, HedgeServerID, FromDate, ToDate
FROM   [DWH_dbo].[Dim_PositionHedgeServerChangeLog_Snapshot]
WHERE  PositionID = 3268434767
  AND  FromDate <= 20260310
  AND  ToDate   >= 20260310;
```

### 7.3 All positions currently on a specific hedge server

```sql
SELECT PositionID, FromDate
FROM   [DWH_dbo].[Dim_PositionHedgeServerChangeLog_Snapshot]
WHERE  HedgeServerID = 84
  AND  ToDate = 20991231
ORDER BY FromDate DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 (***) | Phases: 14/14 (full pipeline)*
*Tiers: 2 T1, 3 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: DWH_dbo.Dim_PositionHedgeServerChangeLog_Snapshot | Type: Table | Production Source: etoro.Trade.PositionsHedgeServerChangeLog*
