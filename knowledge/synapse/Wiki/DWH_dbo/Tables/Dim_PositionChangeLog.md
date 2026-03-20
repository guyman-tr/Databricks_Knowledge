# DWH_dbo.Dim_PositionChangeLog

> Position lifecycle change audit log recording every event that modifies a position's amount, stop-loss rate, settlement status, or lot count -- enabling reconstruction of position state at any point in time.

| Property | Value |
|----------|-------|
| **Schema** | DWH_dbo |
| **Object Type** | Table |
| **Production Source** | etoro.History.PositionChangeLog |
| **Refresh** | Daily (incremental via SP_Dim_PositionChangeLog_DL_To_Synapse @dt) |
| | |
| **Synapse Distribution** | HASH (PositionID) |
| **Synapse Index** | CLUSTERED INDEX (OccurredDateID ASC) |
| | |
| **UC Target** | `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog` |
| **UC Format** | Delta |
| **UC Partitioned By** | OccurredDateID (daily or monthly range) |
| **UC Table Type** | Managed |

---

## 1. Business Meaning

Dim_PositionChangeLog is the audit trail for position state changes. Every time a position's amount, stop-loss rate, settlement flag, or lot count is modified after the initial open, a change log entry is created. This allows analysts to reconstruct the exact state of a position at any historical point in time.

Key use cases:
- **IsSettled tracking**: When a stock position transitions to "settled" status, the log records PreviousIsSettled vs IsSettled. The SP_Dim_Position_DL_To_Synapse ETL reads this table to backfill the correct IsSettled value on Dim_Position.
- **Amount corrections**: When a position's Amount or StopRate changes (e.g., partial close, margin call adjustment), the log records PreviousAmount and AmountChanged. The Dim_Position ETL uses ChangeTypeID=12 entries to apply cumulative amount corrections.
- **Initial open event**: ChangeTypeID=0 records the initial position open event -- used to detect the first appearance of a position in the changelog (primarily for hedge server tracking in SP_Dim_Position_DL_To_Synapse).

Data source is `etoro_History_PositionChangeLog` loaded daily via DELETE (yesterday+) then INSERT (from yesterday). As of 2025-01-05, ALL ChangeTypeIDs are loaded (previously restricted to IDs 1, 5, 11, 12, 13 only).

---

## 2. Business Logic

### 2.1 Change Types

**What**: Classification of what kind of position modification occurred.

**Columns Involved**: `ChangeTypeID`

**Rules**:
- ChangeTypeID=0: Initial open event (position first appears in changelog). Used to find OpenDateID for new positions entering the hedge server snapshot.
- ChangeTypeID=1: Rate/SL-TP change (StopRate or LimitRate modification).
- ChangeTypeID=2: Unspecified change -- seen in live data (requires domain expert clarification).
- ChangeTypeID=5: Added 2024-04-30 -- purpose requires clarification.
- ChangeTypeID=11: Partial close related event.
- ChangeTypeID=12: Amount adjustment -- summed cumulatively to correct Dim_Position.Amount for same-day modifications.
- ChangeTypeID=13: Purpose requires clarification.
- Before 2025-01-05: Only IDs 1, 5, 11, 12, 13 were loaded. ChangeTypeID=0, 2, and others were excluded. Historical rows for these types before 2025-01-05 may be absent.

**Note**: No upstream wiki exists enumerating the official ChangeTypeID names. Values above are inferred from SP code. All should be treated as Tier 4 [UNVERIFIED] until confirmed by domain expert.

### 2.2 State Tracking (Before/After Columns)

**What**: Each row captures the before and after state for the changed metric.

**Columns Involved**: `PreviousAmount`, `AmountChanged`, `NewAmount`, `PreviousStopRate`, `StopRate`, `PreviousIsSettled`, `IsSettled`, `PreviousAmountInUnits`, `AmountInUnits`, `PreviousLotCountDecimal`, `LotCountDecimal`

**Rules**:
- Each change captures the previous value, the delta (AmountChanged), and the new value.
- `AmountChanged` = NewAmount - PreviousAmount (can be negative for reductions).
- Multiple rows can exist per PositionID on the same day (same OccurredDateID) -- particularly for ChangeTypeID=12 (amount adjustments), which are summed via SUM(AmountChanged) GROUP BY PositionID in the Dim_Position ETL.
- `PreviousIsSettled` / `IsSettled` are cast to int (0/1) from bit in staging. NULL is possible if the event didn't involve a settlement change.
- The **most recent** changelog event for a PositionID at ChangeTypeID=0 (ROW_NUMBER by Occurred ASC, rn=1) is used in the Dim_Position ETL to correct IsSettled for open positions.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**HASH (PositionID)**: Co-located with Dim_Position for efficient JOINs on PositionID. Date-range queries should also include OccurredDateID.

**CLUSTERED INDEX (OccurredDateID)**: Efficient for date-range scans on when changes occurred. Always include an OccurredDateID range filter.

### 3.1b UC (Databricks) Storage & Partitioning

**In Databricks**, this table lands as `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_positionchangelog`. Always filter on OccurredDateID for partition pruning.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| All changes for a specific position | WHERE PositionID = X ORDER BY Occurred |
| Settlement changes on a date | WHERE OccurredDateID = YYYYMMDD AND PreviousIsSettled IS NOT NULL |
| Amount-adjusted positions | WHERE ChangeTypeID = 12 AND OccurredDateID = YYYYMMDD |
| Initial open events | WHERE ChangeTypeID = 0 AND OccurredDateID = YYYYMMDD |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | ON PositionID | Enrich position with change history |
| DWH_dbo.Dim_Customer | ON CID | Customer-level change analysis |

### 3.4 Gotchas

- **Multiple rows per position per day**: A position can have many changelog entries on the same day. Do NOT assume one row per (PositionID, OccurredDateID).
- **Historical completeness gap**: Before 2025-01-05, only ChangeTypeIDs 1, 5, 11, 12, 13 were loaded. Earlier history for ChangeTypeIDs 0, 2, etc. is missing.
- **ChangeTypeID values are undocumented**: No official lookup table for ChangeTypeID exists in DWH. The meanings above are inferred from SP code patterns.
- **AmountChanged may be 0**: Seen in live data -- a row with AmountChanged=0 may represent a rate-only change (StopRate update) with no amount modification.
- **PreviousIsSettled can be NULL**: If the change event didn't involve settlement status, both IsSettled and PreviousIsSettled may be NULL.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| *** | Tier 2 - Synapse SP code | (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| * | Tier 4 - Inferred from name/code | (Tier 4 - [UNVERIFIED]) |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | PositionID | bigint | NO | FK to Dim_Position.PositionID. Distribution key -- co-located with Dim_Position for efficient JOINs. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 2 | CID | int | YES | Customer ID who owns the position. Nullable (some system positions may not have CID). (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 3 | Occurred | datetime | NO | Exact timestamp when the position change occurred. Passthrough from etoro_History_PositionChangeLog. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 4 | OccurredDateID | int | YES | ETL-computed YYYYMMDD int from Occurred. Clustered index key. Always filter on this for performance. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 5 | ChangeTypeID | tinyint | YES | Type of change event. Known codes: 0=Initial open, 1=Rate change, 2=Unknown, 5=Unknown (added 2024), 11=Partial close event, 12=Amount adjustment, 13=Unknown. No official lookup table in DWH. (Tier 4 - [UNVERIFIED]) |
| 6 | PreviousAmount | money | NO | Position amount (USD) before this change. NOT NULL -- always captured. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 7 | AmountChanged | money | NO | Change in amount (can be positive or negative). AmountChanged = NewAmount - PreviousAmount. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 8 | NewAmount | numeric(16,8) | YES | Position amount after this change. Nullable -- may be absent for non-amount change types. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 9 | PreviousIsSettled | int | YES | Settlement status before this change (0=not settled, 1=settled). Cast from bit staging column. NULL if this event didn't involve settlement change. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 10 | IsSettled | int | YES | Settlement status after this change. Cast from bit staging column. Used by Dim_Position ETL to backfill IsSettled corrections. NULL if no settlement change. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 11 | PreviousStopRate | numeric(16,8) | NO | Stop-loss rate before this change. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 12 | StopRate | numeric(16,8) | NO | Stop-loss rate after this change. NOT NULL. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 13 | PreviousAmountInUnits | numeric(16,6) | YES | Unit count (shares/coins) before this change. Added for futures/unit-based positions. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 14 | AmountInUnits | numeric(16,6) | YES | Unit count after this change. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 15 | LotCountDecimal | decimal(38,18) | YES | New lot count after change. Added 2024-11-07 (Inbal BML) for futures project. NULL for older records. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 16 | PreviousLotCountDecimal | decimal(38,18) | YES | Lot count before this change. Added 2024-11-07. NULL for older records. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |
| 17 | UpdateDate | datetime | NO | ETL load timestamp (GETDATE()). Not from production source. (Tier 2 - SP_Dim_PositionChangeLog_DL_To_Synapse) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Table | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| PositionID | etoro_History_PositionChangeLog | PositionID | passthrough |
| CID | etoro_History_PositionChangeLog | CID | passthrough |
| Occurred | etoro_History_PositionChangeLog | Occurred | passthrough |
| OccurredDateID | -- | Occurred | ETL-computed: CAST(CONVERT(VARCHAR(8), Occurred, 112) AS INT) |
| ChangeTypeID | etoro_History_PositionChangeLog | ChangeTypeID | passthrough |
| PreviousAmount | etoro_History_PositionChangeLog | PreviousAmount | passthrough |
| AmountChanged | etoro_History_PositionChangeLog | AmountChanged | passthrough |
| NewAmount | etoro_History_PositionChangeLog | NewAmount | passthrough |
| PreviousIsSettled | etoro_History_PositionChangeLog | PreviousIsSettled | ETL: CAST(PreviousIsSettled AS INT) |
| IsSettled | etoro_History_PositionChangeLog | IsSettled | ETL: CAST(IsSettled AS INT) |
| PreviousStopRate | etoro_History_PositionChangeLog | PreviousStopRate | passthrough |
| StopRate | etoro_History_PositionChangeLog | StopRate | passthrough |
| PreviousAmountInUnits | etoro_History_PositionChangeLog | PreviousAmountInUnits | passthrough |
| AmountInUnits | etoro_History_PositionChangeLog | AmountInUnits | passthrough |
| LotCountDecimal | etoro_History_PositionChangeLog | LotCountDecimal | passthrough |
| PreviousLotCountDecimal | etoro_History_PositionChangeLog | PreviousLotCountDecimal | passthrough |
| UpdateDate | -- | -- | ETL-computed: GETDATE() |

### 5.2 ETL Pipeline

```
etoro.History.PositionChangeLog
  -> Generic Pipeline (daily, Override/full-load)
  -> Bronze/etoro/History/PositionChangeLog/
  -> DWH_staging.etoro_History_PositionChangeLog
  -> SP_Dim_PositionChangeLog_DL_To_Synapse (DELETE yesterday+ then INSERT)
  -> DWH_dbo.Dim_PositionChangeLog
```

| Step | Object | Description |
|------|--------|-------------|
| Source | etoro.History.PositionChangeLog | Production position change audit (etoroDB-REAL) |
| Lake | Bronze/etoro/History/PositionChangeLog/ | Daily full-load via Generic Pipeline |
| Staging | DWH_staging.etoro_History_PositionChangeLog | Raw staging import |
| ETL Step 1 | SP_Dim_PositionChangeLog_DL_To_Synapse | DELETE FROM Dim_PositionChangeLog WHERE OccurredDateID >= @YesterdayID |
| ETL Step 2 | SP_Dim_PositionChangeLog_DL_To_Synapse | INSERT from staging WHERE Occurred >= @Yesterday (all ChangeTypeIDs as of 2025-01-05) |
| Target | DWH_dbo.Dim_PositionChangeLog | 17 cols, HASH(PositionID) + CCI on OccurredDateID |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Target Object | Join Column | Description |
|--------------|-------------|-------------|
| DWH_dbo.Dim_Position | PositionID | The position this log entry belongs to |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| DWH_dbo.SP_Dim_Position_DL_To_Synapse | PositionID | Reads IsSettled corrections and Amount adjustments to apply to Dim_Position |
| DWH_dbo.SP_Dim_Position_PositionHedgeServerChangeLog | PositionID | Reads initial open events (ChangeTypeID=0) for hedge server snapshot initialization |

---

## 7. Sample Queries

### 7.1 All changes for a specific position

```sql
SELECT  PositionID, Occurred, ChangeTypeID,
        PreviousAmount, AmountChanged, NewAmount,
        PreviousIsSettled, IsSettled,
        PreviousStopRate, StopRate
FROM    [DWH_dbo].[Dim_PositionChangeLog]
WHERE   PositionID = 3358743021
  AND   OccurredDateID BETWEEN 20260101 AND 20260310
ORDER BY Occurred;
```

### 7.2 Settlement status changes on a specific date

```sql
SELECT  PositionID, CID, Occurred, PreviousIsSettled, IsSettled
FROM    [DWH_dbo].[Dim_PositionChangeLog]
WHERE   OccurredDateID = 20260310
  AND   PreviousIsSettled IS NOT NULL
  AND   PreviousIsSettled <> IsSettled
ORDER BY Occurred;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Quality: 7.5/10 (***) | Phases: 14/14 (full pipeline)*
*Tiers: 0 T1, 16 T2, 0 T3, 1 T4 [UNVERIFIED] (ChangeTypeID mapping), 0 T5 | Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10*
*Object: DWH_dbo.Dim_PositionChangeLog | Type: Table | Production Source: etoro.History.PositionChangeLog*
