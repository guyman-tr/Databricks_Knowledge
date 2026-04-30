# Hedge.GetHBCEstimationsDiscrepencies_Child_ss

> Snapshot-server variant of the HBC discrepancy child check: identical logic to _Child but writes the cursor back to a snapshot-isolation Feature table (dbo.Feature_SS) on [AO-REAL-DB] instead of Maintenance.Feature; "_ss" = snapshot server.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @LastTime, @TimeRangeSeconds, @MaxTime - caller-supplied time window (IN parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHBCEstimationsDiscrepencies_Child_ss is the snapshot-isolation variant of the _Child discrepancy procedure. It performs the same HBC lot reconciliation check (HBCExecutionLog vs Trade.GetPositionData position lots) but writes the @MaxTime cursor back to a different Feature table: `dbo.Feature_SS` on `[AO-REAL-DB]` via OPENQUERY, rather than the standard `Maintenance.Feature`.

The "_ss" suffix indicates this variant is used when the execution context is a SQL Server snapshot isolation (SNAPSHOT) read session or a snapshot-isolation secondary replica. The Feature_SS table is a separate tracking table maintained under snapshot isolation semantics, preventing the cursor write from conflicting with snapshot read transactions.

The reconciliation logic and output are identical to _Child. The only difference is the target of the cursor advancement: `[AO-REAL-DB].etoro.dbo.Feature_SS` vs `[AO-REAL-DB].etoro.Maintenance.Feature`.

---

## 2. Business Logic

### 2.1 Snapshot Isolation Cursor Separation

**What**: The cursor (FeatureID 43 value) is written to a dedicated snapshot-isolation Feature table rather than the main Maintenance.Feature table.

**Columns/Parameters Involved**: `@MaxTime`, `dbo.Feature_SS`

**Rules**:
- The commented-out line shows the pre-snapshot approach: `UPDATE [AZR-N-REAL-DB-3_SS].[etoro].Maintenance.Feature SET Value = @MaxTime where FeatureID = 43`.
- Current approach: `UPDATE Openquery([AO-REAL-DB], 'SELECT Value FROM [etoro].dbo.Feature_SS where FeatureID = 43') SET [Value] = @MaxTime`.
- Feature_SS is a separate Feature-like table operating under snapshot isolation. It tracks the same FeatureID 43 cursor but for the SS execution path.
- This prevents the snapshot reader from conflicting with the cursor write to the main Maintenance.Feature table (which may be in a non-snapshot transaction).

### 2.2 Identical Reconciliation Logic to _Child

**What**: All discrepancy detection logic is identical to GetHBCEstimationsDiscrepencies_Child.

**Rules**:
- Same JOIN: HBCExecutionLog -> Trade.GetPositionData (full view) -> Customer.Customer.
- Same WHERE filter: IsSuccess=1, time window, HedgeServerID match, PlayerLevelID <> 4, position timing.
- Same GROUP BY and discrepancy detection: ExecutionAmountInLots <> SumLotDecimal.
- Same output columns: NotificationTime, HedgeServerID, InstrumentID, AmountInLots, IsBuy, IsOpen, Description.
- No OPTION(RECOMPILE); no temp table indexes (same as _Child, unlike parent).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LastTime | datetime | NO | - | CODE-BACKED | Start of the analysis window. Caller-supplied from Feature_SS FeatureID 43 (snapshot isolation tracking cursor). |
| 2 | @TimeRangeSeconds | int | NO | - | CODE-BACKED | Lookback window width in seconds. Caller-supplied from Feature_SS FeatureID 42. |
| 3 | @MaxTime | datetime | NO | - | CODE-BACKED | End of the analysis window. Caller-computed and passed IN. Written back to dbo.Feature_SS FeatureID 43 via OPENQUERY at end to advance the SS cursor. |

**Output Columns** (identical to GetHBCEstimationsDiscrepencies_Child):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | NotificationTime | datetime | NO | - | CODE-BACKED | EndTime of the discrepant execution. Inherited from _Child. |
| 5 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server of the discrepant execution. Inherited from _Child. |
| 6 | InstrumentID | int | NO | - | CODE-BACKED | Instrument with the lot mismatch. Inherited from _Child. |
| 7 | AmountInLots | decimal | YES | - | CODE-BACKED | SumLotDecimal - ExecutionAmountInLots (lot gap). Inherited from _Child. |
| 8 | IsBuy | bit | NO | - | CODE-BACKED | Customer position direction. Inherited from _Child. |
| 9 | IsOpen | bit | NO | - | CODE-BACKED | Opening (1) vs closing (0) hedge. Inherited from _Child. |
| 10 | Description | varchar | NO | - | CODE-BACKED | Diagnostic string. Inherited from _Child. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExecutionID join | Hedge.HBCExecutionLog | Lookup / Read | Same as _Child. |
| InitExecutionID/EndExecutionID join | Trade.GetPositionData | Cross-schema Lookup | Same as _Child - full position view. |
| CID join | Customer.Customer | Cross-schema Lookup | Same as _Child - PlayerLevelID filter. |
| OPENQUERY write | dbo.Feature_SS on [AO-REAL-DB] | Cross-server Write | Advances snapshot isolation cursor (FeatureID 43) after processing. Different table from _Child variant. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HedgeAlertService (external) | @LastTime, @TimeRangeSeconds, @MaxTime | Caller | Called when the execution context uses snapshot isolation; tracks cursor in Feature_SS. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHBCEstimationsDiscrepencies_Child_ss (procedure)
├── Hedge.HBCExecutionLog (table)
├── Trade.GetPositionData (view) [cross-schema]
├── Customer.Customer (table) [cross-schema]
└── dbo.Feature_SS on [AO-REAL-DB] (table) [via OPENQUERY - snapshot isolation cursor write]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HBCExecutionLog | Table | Same join as _Child. |
| Trade.GetPositionData | View | Same full position view as _Child. |
| Customer.Customer | Table | Same PlayerLevelID filter as _Child. |
| dbo.Feature_SS (linked server) | Table | Write-only via OPENQUERY: advances snapshot FeatureID 43 cursor. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| HedgeAlertService (external) | Application | SS-path caller; reads from Feature_SS before calling and resets it after. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Runtime temp table**: `#executions` - no NC indexes (same as _Child).

**Change history** (from DDL comments):
- 2015-07-07 (Adi, FB:26726): Modified WHERE clause for IsOpened column; BIT cast.

---

## 8. Sample Queries

### 8.1 Execute the SS variant with manual window params

```sql
DECLARE @LastTime DATETIME = '2026-03-19 00:00:00';
DECLARE @TimeRangeSeconds INT = 30;
DECLARE @MaxTime DATETIME = DATEADD(second, -@TimeRangeSeconds, GETUTCDATE());

EXEC Hedge.GetHBCEstimationsDiscrepencies_Child_ss
    @LastTime         = @LastTime,
    @TimeRangeSeconds = @TimeRangeSeconds,
    @MaxTime          = @MaxTime;
```

### 8.2 Verify the SS cursor table state

```sql
-- Run on the primary replica or via OPENQUERY
SELECT FeatureID, Value AS CursorValue
FROM   [AO-REAL-DB].[etoro].dbo.Feature_SS
WHERE  FeatureID IN (42, 43);
```

### 8.3 Compare _Child vs _Child_ss for the same window

```sql
-- Verify both variants produce the same discrepancy rows for a given window
DECLARE @L DATETIME = DATEADD(hour, -2, GETUTCDATE());
DECLARE @R INT = 30;
DECLARE @M DATETIME = DATEADD(second, -@R, GETUTCDATE());
EXEC Hedge.GetHBCEstimationsDiscrepencies_Child    @L, @R, @M;
EXEC Hedge.GetHBCEstimationsDiscrepencies_Child_ss @L, @R, @M;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | HBC reconciliation family; _Child_ss is the snapshot-isolation cursor variant. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 sister variants analyzed | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHBCEstimationsDiscrepencies_Child_ss | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHBCEstimationsDiscrepencies_Child_ss.sql*
