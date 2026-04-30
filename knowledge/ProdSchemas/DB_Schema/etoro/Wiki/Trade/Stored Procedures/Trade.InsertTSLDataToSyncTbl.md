# Trade.InsertTSLDataToSyncTbl

> Batch-inserts trailing stop-loss (TSL) sync records from a TVP into Trade.SyncTSL, registering new TSL state rows for positions with trailing stop enabled.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TSLInfo TVP (Trade.SyncTSLTblType) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InsertTSLDataToSyncTbl is the write endpoint for the Trailing Stop Loss (TSL) synchronization pipeline. When a customer enables trailing stop on a position or when TSL state needs to be refreshed (e.g., after a position is copied or modified), the current TSL parameters - stop loss price, the next threshold that will trigger an adjustment, the manual version counter, and direction - must be written to Trade.SyncTSL. This table propagates TSL state across replicated database instances so that all subscribers have consistent trailing stop data.

Without this procedure, TSL state changes would not be persisted or replicated. The TSL adjustment logic and sync consumers depend on Trade.SyncTSL having up-to-date rows per position. This procedure accepts a batch of position TSL updates in a single call via the Trade.SyncTSLTblType TVP, minimizing round trips from the calling service.

Data flow: Trading or synchronization services accumulate TSL updates for one or more positions, build a Trade.SyncTSLTblType TVP, and call this procedure. The INSERT assigns Status=0 (New) and DateInserted=GETUTCDATE() defaults from Trade.SyncTSL. A sync consumer then transitions rows to Status=2 (Synced/Active) as they are propagated to subscribers. When positions close or TSL is flushed, rows are updated to Status=3 by Trade.FlushTSLForInstrumentID or Trade.FlushTSLForSpecificTree.

---

## 2. Business Logic

### 2.1 TVP Bulk-Insert with Exception Propagation

**What**: All TSL rows in the TVP are inserted in one statement. Any error is re-thrown to the caller (not silently swallowed).

**Columns/Parameters Involved**: `@TSLInfo`, all five TSL columns

**Rules**:
- INSERT selects all five columns from @TSLInfo: PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy.
- Status defaults to 0 (New) and DateInserted defaults to GETUTCDATE() from Trade.SyncTSL - these are NOT passed via the TVP.
- ID is allocated from Trade.SequenceSyncTSL sequence (NOT replicated, guaranteeing unique IDs across subscriber instances).
- THROW in the CATCH block re-raises any SQL error to the caller - unlike InsertTradonomyContract (which silently returns -1), this procedure lets the caller handle the exception.
- NOCOUNT ON suppresses row-count messages.

**Diagram**:
```
@TSLInfo (Trade.SyncTSLTblType TVP)
  PositionID | StopLoss | SLManualVer | NextThresHold | IsBuy
      |
      v
INSERT Trade.SyncTSL (PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy)
  <- ID: NEXT VALUE FOR Trade.SequenceSyncTSL (auto)
  <- Status: 0 (New, auto default)
  <- DateInserted: GETUTCDATE() (auto default)
      |
      v
[Success: rows inserted with Status=0]
[Error: THROW - exception propagates to caller]
      |
      v
Sync consumer reads Status=0 rows -> promotes to Status=2
Position close / FlushTSL -> updates to Status=3
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TSLInfo | Trade.SyncTSLTblType | NO | - | CODE-BACKED | READONLY TVP. Each row carries PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy for one position's TSL state. See Trade.SyncTSLTblType for element details. Trade.SyncTSL adds Status=0 and DateInserted defaults automatically. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @TSLInfo | Trade.SyncTSLTblType | Parameter (TVP) | Source of TSL state rows to insert |
| INSERT target | Trade.SyncTSL | Writer | TSL sync rows are written here with Status=0 (New) |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called from trading or sync services that track TSL position changes (PROD_BIadmins.sql references it for EXECUTE permission grant).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InsertTSLDataToSyncTbl (procedure)
├── Trade.SyncTSLTblType (type) - TVP parameter type
└── Trade.SyncTSL (table) - INSERT target
      ├── Trade.SequenceSyncTSL (sequence) - ID default
      └── dbo.dtPrice (type) - StopLoss, NextThresHold types
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.SyncTSLTblType | User Defined Type | TVP parameter @TSLInfo |
| Trade.SyncTSL | Table | INSERT target - TSL sync rows written here |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD_BIadmins (permissions) | Security | EXECUTE permission granted to BI admin role |
| Trading / sync services | External | Calls this procedure when TSL state changes for positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Session setting | Suppresses row-count messages |
| THROW on error | Design | Exceptions propagate to the caller unchanged - differs from other Insert procedures that return -1 silently |

---

## 8. Sample Queries

### 8.1 Insert TSL state for a single position

```sql
DECLARE @TSLInfo Trade.SyncTSLTblType;
INSERT INTO @TSLInfo (PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy)
VALUES (2152972353, 41612.82, 1, 104027.11, 1);

EXEC Trade.InsertTSLDataToSyncTbl @TSLInfo = @TSLInfo;
```

### 8.2 Insert TSL state for multiple positions in one call

```sql
DECLARE @TSLInfo Trade.SyncTSLTblType;
INSERT INTO @TSLInfo (PositionID, StopLoss, SLManualVer, NextThresHold, IsBuy)
VALUES
    (100001, 1.1000, 0, 1.1100, 1),
    (100002, 2.5000, 2, 2.4900, 0),
    (100003, 150.25, 1, 155.00, 1);

EXEC Trade.InsertTSLDataToSyncTbl @TSLInfo = @TSLInfo;
```

### 8.3 Verify inserted TSL rows by Status

```sql
SELECT s.ID, s.PositionID, s.StopLoss, s.SLManualVer, s.NextThresHold, s.IsBuy, s.Status, s.DateInserted
FROM Trade.SyncTSL s WITH (NOLOCK)
WHERE s.Status = 0
ORDER BY s.DateInserted DESC;
-- Status=0 rows are newly inserted, awaiting sync propagation
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InsertTSLDataToSyncTbl | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InsertTSLDataToSyncTbl.sql*
