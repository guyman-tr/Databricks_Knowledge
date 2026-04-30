# Hedge.KPIInstrumentLog

> Periodic per-instrument trading volume KPI log: captures customer position volume vs. hedge account volume per (HedgeServer, Instrument) for each time window; written to the primary DB via linked-server synonym by Hedge.InsertKPIData running on the secondary.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | ID int IDENTITY (NONCLUSTERED PK + CLUSTERED on ID) |
| **Partition** | No |
| **Indexes** | 3 active (NONCLUSTERED PK on ID, CLUSTERED on ID, NONCLUSTERED on EndTime) |

---

## 1. Business Meaning

Hedge.KPIInstrumentLog stores periodic trading volume KPI snapshots at the (HedgeServer, Instrument) level. For each configured time window (@startTime to @endTime), one row is inserted per active (HedgeServer, Instrument) pair, comparing:
- **TotalUnitsCustomers**: The total position units transacted by customers (excludes test users with PlayerLevelID=4).
- **TotalUnitsAccount**: The total units executed through the hedge account (from ExecutionRequestBreakdownLog and ExecutionLog fills).

This per-instrument comparison enables analysis of hedge efficiency: whether the account-side volume is in line with customer-side volume for each instrument. A large discrepancy (TotalUnitsAccount > TotalUnitsCustomers) may indicate over-hedging or volume mismatch.

**Write path**: `Hedge.InsertKPIData` runs on the **secondary database** and inserts into `dbo.RW_KPIInstrumentLog`, a synonym pointing to `[AO-REAL-DB].[etoro].[Hedge].[KPIInstrumentLog]` (the primary DB via linked server). This is why this table is **empty in the current environment** (secondary replica) - all writes go to the primary.

**Dedup guard**: InsertKPIData checks `NOT EXISTS (SELECT * FROM Hedge.KPIInstrumentLog WHERE StartTime=@startTime AND HedgeServerID=... AND InstrumentID=...)` before inserting, preventing duplicate rows for the same period.

A companion table, `Hedge.KPIServerLog`, captures server-level financial KPIs (PnL, hedge cost, HBC latency) for the same time windows.

---

## 2. Business Logic

### 2.1 Customer vs. Account Volume Comparison

**What**: TotalUnitsCustomers and TotalUnitsAccount represent the two sides of the hedging volume equation.

**Columns/Parameters Involved**: `TotalUnitsCustomers`, `TotalUnitsAccount`, `InstrumentID`

**Rules**:
- `TotalUnitsCustomers`: Sum of AmountInUnitsDecimal from Trade.PositionTbl (open) + History.Position (closed/opened) for the period, excluding test customers (PlayerLevelID=4). Aggregated by (HedgeServerID, InstrumentID).
- `TotalUnitsAccount`: Sum of units from Hedge.ExecutionRequestBreakdownLog (all orders sent) UNION Hedge.ExecutionLog (OrderState=4 fills only). Aggregated by (HedgeServerID, InstrumentID).
- InstrumentID=0 appears when a volume record has no matching instrument (NULL resolved to 0 via ISNULL).
- The difference (TotalUnitsAccount - TotalUnitsCustomers) is the over/under-hedge volume for that instrument in the window.

### 2.2 HedgeServerMode

**What**: Captures the hedge strategy mode active on the server at KPI calculation time.

**Columns/Parameters Involved**: `HedgeServerMode`, `HedgeServerID`

**Rules**:
- HedgeServerMode = HedgeStrategyModeID from Trade.HedgeServer at the time of calculation.
- Enables filtering KPI data by strategy mode in historical analysis.

### 2.3 NONCLUSTERED PK + Separate CLUSTERED Index (Same Column)

**What**: Unusual index pattern: both the PK and the clustered index are on ID.

**Rules**:
- The NONCLUSTERED PK constraint is on ID, but there is also a separate CLUSTERED index (Idx_Hedge_KPIInstrumentLog) on ID. This means the physical ordering IS by ID (clustered) but the PK is technically nonclustered.
- PAGE compression applied to both the table and all indexes.
- NC index on EndTime supports time-range queries.

---

## 3. Data Overview

0 rows in this environment (secondary DB - writes go to primary [AO-REAL-DB] via synonym)

*Expected row structure:*

| ID | OccurredInsert | StartTime | EndTime | HedgeServerID | HedgeServerMode | InstrumentID | TotalUnitsCustomers | TotalUnitsAccount |
|---|---|---|---|---|---|---|---|---|
| (auto) | (GETUTCDATE()) | 2016-08-29 07:00 | 2016-08-29 07:05 | 1 | 2 | 1 | 50000 | 52000 |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY(1,1) NOT FOR REPLICATION | NO | - | CODE-BACKED | Auto-increment surrogate key. NONCLUSTERED PK + also CLUSTERED (via separate index). NOT FOR REPLICATION prevents identity increment on replication. |
| 2 | OccurredInsert | datetime | NO | GETUTCDATE() | CODE-BACKED | DB server UTC timestamp when the KPI row was inserted. DEFAULT GETUTCDATE(). Records when the KPI calculation ran, not the period it covers. |
| 3 | StartTime | datetime | NO | - | CODE-BACKED | Start of the KPI measurement period. Provided by the caller (@startTime). Typically aligns to a fixed interval boundary (e.g., 5-minute intervals). Used for dedup check. |
| 4 | EndTime | datetime | NO | - | CODE-BACKED | End of the KPI measurement period. Provided by the caller (@endTime). NC index on EndTime for time-range queries. |
| 5 | HedgeServerID | int | NO | - | CODE-BACKED | The hedge server this KPI covers. References Trade.HedgeServer (implicit, no FK). |
| 6 | HedgeServerMode | int | NO | - | CODE-BACKED | The HedgeStrategyModeID of the server at KPI calculation time. Enables strategy-mode filtering in historical analysis. |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | The instrument this KPI row covers. 0 = unmatched/null instrument (ISNULL default). Implicit reference to Trade.Instrument. |
| 8 | TotalUnitsCustomers | bigint | YES | - | CODE-BACKED | Total position units transacted by real customers (excluding PlayerLevelID=4 test users) in the period, for this instrument+server. Sum of AmountInUnitsDecimal from PositionTbl + History.Position. |
| 9 | TotalUnitsAccount | bigint | YES | - | CODE-BACKED | Total units executed through the hedge account in the period. Sum from ExecutionRequestBreakdownLog + ExecutionLog (OrderState=4 fills). Comparing to TotalUnitsCustomers reveals over/under-hedging. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| HedgeServerID | Trade.HedgeServer | Implicit (no DDL FK) | Hedge server this KPI covers |
| InstrumentID | Trade.Instrument | Implicit (no DDL FK) | Instrument being measured |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InsertKPIData | @startTime + HedgeServerID + InstrumentID | Writer (via synonym) | Writes via dbo.RW_KPIInstrumentLog synonym -> [AO-REAL-DB]. Checks local table for dedup. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.KPIInstrumentLog (table)
  - Written by: Hedge.InsertKPIData via dbo.RW_KPIInstrumentLog synonym
  - Synonym target: [AO-REAL-DB].[etoro].[Hedge].[KPIInstrumentLog]
  - Companion: Hedge.KPIServerLog (server-level KPIs for same periods)
```

---

### 6.1 Objects This Depends On

No DDL dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InsertKPIData | Procedure | Writes via synonym; checks local table for dedup |
| dbo.RW_KPIInstrumentLog | Synonym | Points to [AO-REAL-DB].[etoro].[Hedge].[KPIInstrumentLog] |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Hedge_KPIInstrumentLog | NONCLUSTERED PK | ID ASC | - | - | Active (PAGE compression, MAIN filegroup) |
| Idx_Hedge_KPIInstrumentLog | CLUSTERED | ID ASC | - | - | Active (PAGE compression, MAIN filegroup) |
| Idx_Hedge_KPIInstrumentLog_EndTime | NONCLUSTERED | EndTime ASC | - | - | Active (PAGE compression, MAIN filegroup) |

Note: Both PK (NONCLUSTERED) and CLUSTERED index exist on ID - the CLUSTERED index controls physical ordering; the PK enforces uniqueness.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Hedge_KPIInstrumentLog | PRIMARY KEY (NONCLUSTERED) | ID - unique per KPI row |
| Df_Hedge_KPIInstrumentLog_OccurredInsert | DEFAULT | OccurredInsert = GETUTCDATE() |

---

## 8. Sample Queries

### 8.1 Volume comparison by instrument (run on primary DB)
```sql
SELECT HedgeServerID, InstrumentID,
       StartTime, EndTime,
       TotalUnitsCustomers, TotalUnitsAccount,
       TotalUnitsAccount - TotalUnitsCustomers AS VolumeDiscrepancy
FROM Hedge.KPIInstrumentLog WITH (NOLOCK)
WHERE EndTime > DATEADD(hour, -1, GETUTCDATE())
  AND HedgeServerID = 1
ORDER BY ABS(TotalUnitsAccount - TotalUnitsCustomers) DESC;
```

### 8.2 High-discrepancy instruments over a period
```sql
SELECT InstrumentID,
       SUM(TotalUnitsAccount - TotalUnitsCustomers) AS TotalDiscrepancy
FROM Hedge.KPIInstrumentLog WITH (NOLOCK)
WHERE StartTime >= '2024-01-01'
  AND StartTime < '2024-02-01'
GROUP BY InstrumentID
HAVING ABS(SUM(TotalUnitsAccount - TotalUnitsCustomers)) > 10000
ORDER BY ABS(SUM(TotalUnitsAccount - TotalUnitsCustomers)) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for Hedge.KPIInstrumentLog.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,3,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (InsertKPIData) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.KPIInstrumentLog | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.KPIInstrumentLog.sql*
