# History.Netting_History

> SQL Server temporal history table automatically maintained by the database engine, recording every past state of Hedge.Netting - the real-time net hedge position table that tracks eToro's aggregated exposure per instrument per liquidity account.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite: (SysEndTime, SysStartTime) - temporal history clustered index |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED on SysEndTime ASC, SysStartTime ASC) |

---

## 1. Business Meaning

History.Netting_History is the temporal history backing table for Hedge.Netting. It is automatically populated by SQL Server's SYSTEM_VERSIONING mechanism whenever rows in Hedge.Netting are updated or deleted.

Hedge.Netting maintains eToro's current net hedge position per (LiquidityAccountID, InstrumentID, ValueDate) triplet. As customers open and close positions, the hedge system continuously re-calculates and updates the net exposure for each instrument. Each update to Hedge.Netting creates a new history row here, capturing the prior net position before it changed.

This history serves two critical purposes:
1. **Hedge audit**: Regulators and internal risk can trace exactly what hedge positions were maintained at any point in time.
2. **Reconciliation**: Comparing historical hedge state against executed hedge orders helps identify discrepancies in hedging coverage.

With 1,376,933 rows, this is a high-frequency table - each customer trade that changes the net hedge position for an instrument generates a history snapshot. The live data shows LiquidityAccountID=10, InstrumentID=1211 (Alibaba US) was updated every few minutes on 2026-02-07, with net long exposure of ~10,030 units at average rate ~309.25.

---

## 2. Business Logic

### 2.1 Net Position Tracking - Aggregated Hedge Exposure

**What**: Hedge.Netting maintains one row per (LiquidityAccountID, InstrumentID, ValueDate), representing the aggregated (netted) hedge position eToro holds at the liquidity provider level. Each time a customer trade changes the exposure, Hedge.Netting is updated and the old state is archived here.

**Columns/Parameters Involved**: `LiquidityAccountID`, `InstrumentID`, `Units`, `IsBuy`, `AvgRate`, `ValueDate`

**Rules**:
- Units: the net quantity hedged (decimal(16,2)) - a single row represents the total aggregated exposure
- IsBuy: TRUE = net long hedge (eToro is net long this instrument via the liquidity provider), FALSE = net short
- AvgRate: the volume-weighted average rate of the current hedge position
- ValueDate: the settlement date for the hedge (T+2 for FX, T+1 for some assets)
- Each update to Hedge.Netting (as positions change) generates one history row here via temporal versioning
- HedgeServerID identifies which hedging server instance manages this position

**Example from data (InstrumentID=1211 on 2026-02-07)**:
```
21:06:42 -> Hedge state: 10,054.54 units BUY @ 309.57 (SysEndTime: 21:07:59)
21:07:59 -> Hedge state: 10,029.54 units BUY @ 309.57 (SysEndTime: 21:11:45)  -- ~25 units removed
21:11:45 -> Hedge state: 10,030.54 units BUY @ 309.25 (SysEndTime: 21:12:24)  -- ~1 unit added, rate changed
```
This 3-minute sequence shows active hedge management with position adjustments every few minutes.

### 2.2 ExecTime vs UpdateTime vs SysStartTime

**What**: Three timestamps are tracked for each hedge state: ExecTime (when the hedge was executed with the liquidity provider), UpdateTime (when the Hedge.Netting row was last modified), and SysStartTime (when the temporal row became current).

**Rules**:
- ExecTime: when the hedge trade was executed in the market - may predate the Netting row update
- UpdateTime: when the hedge server last updated the Netting row (may equal ExecTime or differ by processing latency)
- SysStartTime: the temporal versioning timestamp - when this particular row state became current in Hedge.Netting
- The gap between ExecTime and SysStartTime reveals processing latency in the hedging pipeline

---

## 3. Data Overview

1,376,933 rows (high-frequency active table).

| LiquidityAccountID | InstrumentID | Units | IsBuy | AvgRate | ValueDate | ExecTime | SysStartTime | SysEndTime |
|---|---|---|---|---|---|---|---|---|
| 10 | 1211 | 10030.54 | 1 | 309.25031638 | 2026-02-09 | 2026-02-07 21:11:45 | 2026-02-07 21:11:45 | 2026-02-07 21:12:24 | Net long 10,030 units Alibaba US. ValueDate T+2. SysEndTime-SysStartTime = 39s (updated again 39s later). |
| 10 | 1211 | 10029.54 | 1 | 309.57165927 | 2026-02-09 | 2026-02-07 21:07:59 | 2026-02-07 21:07:59 | 2026-02-07 21:11:45 | Net 10,029.54 units, avg rate slightly higher. Valid for ~3.75 minutes before next update. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LiquidityAccountID | int | NO | - | CODE-BACKED | The liquidity provider account holding this hedge position. FK to Trade.LiquidityAccounts (enforced on Hedge.Netting, not in history). Part of the composite PK on the live table. Examples: LiquidityAccountID=10 = specific broker/LP account. |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | The financial instrument being hedged. Part of the live table's composite PK (LiquidityAccountID, InstrumentID, ValueDate). References Trade.Instrument/History.Instrument (no FK in history). |
| 3 | Units | decimal(16,2) | YES | - | CODE-BACKED | The net number of units hedged at the liquidity provider for this (account, instrument, value date) combination. Positive values represent a net open position. The netting aggregates all customer positions to a single number. NULL theoretically possible but not expected. |
| 4 | IsBuy | bit | NO | - | CODE-BACKED | The direction of the net hedge: TRUE (1) = net long (eToro is long via the LP), FALSE (0) = net short. Represents the dominant direction of eToro's aggregate customer exposure for this instrument. |
| 5 | AvgRate | dbo.dtPrice | YES | - | CODE-BACKED | The volume-weighted average execution rate for the current net hedge position. dbo.dtPrice is a UDT (decimal) for price values. Used to calculate the cost basis of the hedge and to compute hedge P&L. Changes with each new hedge execution. |
| 6 | ValueDate | date | NO | - | CODE-BACKED | The settlement date for this hedge position. For FX instruments: T+2 settlement. Part of the live table's composite PK - multiple value dates may exist for the same (LiquidityAccountID, InstrumentID) pair. |
| 7 | ExecTime | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp when the hedge was executed at the liquidity provider. May differ from UpdateTime and SysStartTime due to processing pipeline latency. NULL if execution time was not captured. |
| 8 | UpdateTime | datetime2(7) | YES | - | CODE-BACKED | UTC timestamp when the Hedge.Netting row was last modified. Tracks when the hedging server updated the netting position. May equal ExecTime for immediate updates or differ by processing latency. |
| 9 | HedgeServerID | int | NO | - | CODE-BACKED | The identifier of the hedge server instance that manages this position. References the hedging infrastructure component responsible for executing and managing the hedge orders at this liquidity provider. |
| 10 | SysStartTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this row version became current in Hedge.Netting. Populated automatically by SQL Server SYSTEM_VERSIONING (GENERATED ALWAYS AS ROW START). |
| 11 | SysEndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this hedge state was superseded. The interval [SysStartTime, SysEndTime) represents how long this particular net position existed before being updated. Short intervals indicate high-frequency position changes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LiquidityAccountID | Trade.LiquidityAccounts | Implicit | FK enforced on Hedge.Netting; not in history. Identifies the LP account. |
| InstrumentID | Trade.Instrument | Implicit | References the instrument being hedged. No FK in history. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.Netting | SYSTEM_VERSIONING | Writer (automatic) | Live temporal table - SQL Server archives old states here on UPDATE/DELETE |

---

## 6. Dependencies

```
History.Netting_History (table)
  - No code-level dependencies (temporal history leaf table)
  - Source: Hedge.Netting (live temporal table, SYSTEM_VERSIONING = ON)
    - Updated by: hedging microservices/applications (not stored procedures)
    - Referenced by: History.LiquidityAccounts [done], History.Instrument [done]
```

### 6.1 Objects This Depends On

No dependencies. Populated automatically by temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.Netting | Table | Live temporal table - this is its HISTORY_TABLE |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Netting_History | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

PAGE compression applied.

### 7.2 Constraints

No constraints on history table. Hedge.Netting live table: CLUSTERED PK on (LiquidityAccountID, InstrumentID, ValueDate), FK to Trade.LiquidityAccounts, NC index on InstrumentID.

---

## 8. Sample Queries

### 8.1 Historical hedge position for an instrument on a specific date

```sql
SELECT LiquidityAccountID, InstrumentID, Units, IsBuy, AvgRate, ValueDate, ExecTime, HedgeServerID
FROM [Hedge].[Netting]
FOR SYSTEM_TIME AS OF '2026-02-07 21:00:00'
WHERE InstrumentID = 1211
ORDER BY LiquidityAccountID
```

### 8.2 Full state change history for a specific hedge position

```sql
SELECT LiquidityAccountID, InstrumentID, Units, IsBuy, AvgRate, ValueDate,
       ExecTime, UpdateTime, HedgeServerID, SysStartTime, SysEndTime,
       DATEDIFF(SECOND, SysStartTime, SysEndTime) AS ValidForSec
FROM [History].[Netting_History] WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND LiquidityAccountID = @LiquidityAccountID
ORDER BY SysStartTime ASC
```

### 8.3 High-frequency position changes (hedge instability analysis)

```sql
SELECT InstrumentID, LiquidityAccountID,
       COUNT(*) AS StateChanges,
       MIN(DATEDIFF(SECOND, SysStartTime, SysEndTime)) AS MinDurationSec,
       AVG(DATEDIFF(SECOND, SysStartTime, SysEndTime)) AS AvgDurationSec
FROM [History].[Netting_History] WITH (NOLOCK)
WHERE SysStartTime >= DATEADD(HOUR, -1, GETUTCDATE())
GROUP BY InstrumentID, LiquidityAccountID
ORDER BY StateChanges DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed (written by hedging application, not SPs) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.Netting_History | Type: Table | Source: etoro/etoro/History/Tables/History.Netting_History.sql*
