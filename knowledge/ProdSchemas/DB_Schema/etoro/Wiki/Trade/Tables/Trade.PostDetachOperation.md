# Trade.PostDetachOperation

> Memory-optimized queue for post-detach mirror operations; holds pending snapshot of position and mirror state until job persists to History.Mirror and History.PositionChangeLog.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID |
| **Partition** | No (Memory-Optimized) |
| **Indexes** | 2 |

---

## 1. Business Meaning

**WHAT:** Trade.PostDetachOperation is a memory-optimized In-Memory OLTP table that queues post-detach mirror operations. When positions are detached from a CopyTrader mirror (via DetachPositionsFromMirror, ChangeMirrorState, SetMirrorStopLossPercentage, ChangeMirrorAmountForMoe, UnRegisterMirror, RegisterMirror), the system INSERTs a row capturing the position change (PCL_*) and mirror snapshot (H_M_*). A background job (Post Detach Position From Mirror) runs Trade.PostDetachPositionFromMirror to process batches: INSERT into History.Mirror and History.PositionChangeLog_Active_BIGINT, then DELETE from PostDetachOperation.

**WHY:** Detaching positions from mirrors requires updating Trade.Position (TreeID, MirrorID, IsSettled), Trade.Mirror (RealizedEquity, WithdrawalSummary), and persisting to history tables. The detach operation must complete quickly; the history writes can be deferred. PostDetachOperation decouples the fast path (UPDATE position, OUTPUT into PostDetachOperation) from the slower path (job reads, inserts to History, deletes).

**HOW:** DetachPositionsFromMirror (and similar procs) OUTPUTs from UPDATE Trade.Mirror into PostDetachOperation, populating PCL_* (position change log) and H_M_* (History.Mirror) columns. StatusID defaults to 0 (pending). Trade.PostDetachPositionFromMirror selects TOP(@BatchSize) where StatusID=@StatusID (0=pending, -1=failed retry), inserts into History.Mirror and History.PositionChangeLog_Active_BIGINT, then DELETEs. On CATCH, StatusID is decremented for retry.

---

## 2. Business Logic

### 2.1 PCL_ Prefix (Position Change Log)

PCL_PositionID, PCL_Occurred, PCL_OrigParentPositionID, PCL_CID, PCL_ChangeTypeID (5=Position Transfer), PCL_PrevTreeID, PCL_TreeID, PCL_PreviousIsSettled, PCL_IsSettled, PCL_PositionAmount, PCL_LimitRate, PCL_StopRate, PCL_LastOpConversionRate, PCL_ConversionRateID, PCL_ClientRequestGuid, PCL_IsTslEnabled, PCL_TreeUnits, PCL_MirrorRealizedEquity, PCL_ExecutedWithoutSettings, PCL_IsNoTakeProfit, PCL_IsNoStopLoss. These map to History.PositionChangeLog_Active_BIGINT.

### 2.2 H_M_ Prefix (History.Mirror Snapshot)

H_M_MirrorID, H_M_CID, H_M_ParentCID, H_M_ParentUserName, H_M_Amount, H_M_Occurred, H_M_IsActive, H_M_MirrorOperationID (10=Position Transfer), H_M_IsOpenOpen, H_M_GuruTPV, H_M_MirrorSL, H_M_RealizedEquity, H_M_PauseCopy, H_M_MirrorSLPercentage, H_M_InitialInvestment, H_M_DepositSummary, H_M_WithdrawalSummary, H_M_SessionID, H_M_MIMOOperationTypeID, H_M_MirrorDividendID, H_M_ClientRequestGuid, H_M_MirrorCalculationType, H_M_MirrorTypeID, H_M_NetProfit, H_M_CloseMirrorActionType, H_M_ModificationDate, H_M_ReferenceID, H_M_ExternalOperationType, H_M_ReopenForMirrorID. These map to History.Mirror.

### 2.3 StatusID

0 = Pending (default). Negative = failed retry (job decrements on error). Successful processing DELETEs the row.

### 2.4 Jobs

etoro - Post Detach Position From Mirror - Pendings (StatusID=0). etoro - Post Detach Position From Mirror - Failed (StatusID<0 retry).

---

## 3. Data Overview

| PCL_PositionID | PCL_ChangeTypeID | H_M_MirrorID | H_M_MirrorOperationID | StatusID | Meaning |
|----------------|------------------|--------------|------------------------|----------|---------|
| 12345 | 5 | 100 | 10 | 0 | Pending: position 12345 detached, mirror 100, Position Transfer |
| - | - | - | - | -1 | Failed row awaiting retry |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | IDENTITY | CODE-BACKED | Primary key; auto-increment. |
| 2 | PCL_PositionID | bigint | YES | - | CODE-BACKED | Position that was detached. |
| 3 | PCL_Occurred | datetime | YES | - | CODE-BACKED | When detach occurred. |
| 4 | PCL_OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent position before detach. |
| 5 | PCL_CID | int | YES | - | CODE-BACKED | Customer ID. |
| 6 | PCL_ChangeTypeID | int | YES | - | CODE-BACKED | 5 = Position Transfer. |
| 7 | PCL_PrevTreeID | bigint | YES | - | CODE-BACKED | Tree ID before detach. |
| 8 | PCL_TreeID | bigint | YES | - | CODE-BACKED | New tree ID after detach. |
| 9 | PCL_PreviousIsSettled | int | YES | - | CODE-BACKED | IsSettled before. |
| 10 | PCL_IsSettled | int | YES | - | CODE-BACKED | IsSettled after. |
| 11 | PCL_PositionAmount | money | YES | - | CODE-BACKED | Position amount. |
| 12 | PCL_LimitRate | decimal(16,8) | YES | - | CODE-BACKED | Take-profit rate. |
| 13 | PCL_StopRate | decimal(16,8) | YES | - | CODE-BACKED | Stop-loss rate. |
| 14 | PCL_LastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Last conversion rate. |
| 15 | PCL_ConversionRateID | bigint | YES | - | CODE-BACKED | Conversion rate ID. |
| 16 | PCL_ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client request correlation. |
| 17 | PCL_IsTslEnabled | bit | YES | - | CODE-BACKED | Trailing stop-loss enabled. |
| 18 | PCL_TreeUnits | decimal(20,6) | YES | - | CODE-BACKED | Tree units. |
| 19 | PCL_MirrorRealizedEquity | money | YES | - | CODE-BACKED | Mirror realized equity after detach. |
| 20 | PCL_ExecutedWithoutSettings | bit | YES | - | CODE-BACKED | Executed without full settings. |
| 21 | PCL_IsNoTakeProfit | bit | YES | - | CODE-BACKED | No take-profit. |
| 22 | PCL_IsNoStopLoss | bit | YES | - | CODE-BACKED | No stop-loss. |
| 23 | H_M_MirrorID | int | YES | - | CODE-BACKED | Mirror ID for History.Mirror. |
| 24 | H_M_CID | int | YES | - | CODE-BACKED | CID for History.Mirror. |
| 25 | H_M_ParentCID | int | YES | - | CODE-BACKED | Parent CID. |
| 26 | H_M_ParentUserName | varchar(50) | YES | - | CODE-BACKED | Parent user name. |
| 27 | H_M_Amount | decimal(16,8) | YES | - | CODE-BACKED | Mirror amount change. |
| 28 | H_M_Occurred | datetime | YES | - | CODE-BACKED | Mirror change time. |
| 29 | H_M_IsActive | tinyint | YES | - | CODE-BACKED | Mirror active flag. |
| 30 | H_M_MirrorOperationID | int | YES | - | CODE-BACKED | 10 = Position Transfer. |
| 31 | H_M_IsOpenOpen | bit | YES | - | CODE-BACKED | Open-open mirror. |
| 32 | H_M_GuruTPV | money | YES | - | CODE-BACKED | Guru TPV. |
| 33 | H_M_MirrorSL | money | YES | - | CODE-BACKED | Mirror stop-loss. |
| 34 | H_M_RealizedEquity | money | YES | - | CODE-BACKED | Mirror realized equity. |
| 35 | H_M_PauseCopy | bit | YES | - | CODE-BACKED | Pause copy flag. |
| 36 | H_M_MirrorSLPercentage | money | YES | - | CODE-BACKED | Mirror SL percentage. |
| 37 | H_M_InitialInvestment | money | YES | - | CODE-BACKED | Initial investment. |
| 38 | H_M_DepositSummary | money | YES | - | CODE-BACKED | Deposit summary. |
| 39 | H_M_WithdrawalSummary | money | YES | - | CODE-BACKED | Withdrawal summary. |
| 40 | H_M_SessionID | bigint | YES | - | CODE-BACKED | Session ID. |
| 41 | H_M_MIMOOperationTypeID | int | YES | - | CODE-BACKED | MIMO operation type. |
| 42 | H_M_MirrorDividendID | int | YES | - | CODE-BACKED | Mirror dividend ID. |
| 43 | H_M_ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client request GUID. |
| 44 | H_M_MirrorCalculationType | int | YES | - | CODE-BACKED | Mirror calculation type. |
| 45 | H_M_MirrorTypeID | int | YES | - | CODE-BACKED | Mirror type. |
| 46 | H_M_NetProfit | money | YES | - | CODE-BACKED | Net profit. |
| 47 | H_M_CloseMirrorActionType | int | YES | - | CODE-BACKED | Close mirror action type. |
| 48 | H_M_MirrorOprationDB | varchar(50) | YES | - | CODE-BACKED | Source proc name (e.g. DetachPositionsFromMirror). |
| 49 | H_M_ModificationDate | datetime | NO | getutcdate() | CODE-BACKED | Modification timestamp. |
| 50 | StatusID | int | YES | 0 | CODE-BACKED | 0=pending, negative=retry. |
| 51 | H_M_ReferenceID | varchar(36) | YES | - | CODE-BACKED | Reference ID. |
| 52 | H_M_ExternalOperationType | int | YES | - | CODE-BACKED | External operation type. |
| 53 | H_M_ReopenForMirrorID | int | YES | - | CODE-BACKED | Reopen for mirror ID. |

---

## 5. Relationships

### 5.1 References To

| Column | Target | Relationship |
|--------|--------|---------------|
| PCL_PositionID | Trade.PositionTbl | Logical |
| PCL_CID, H_M_CID | Customer.CustomerStatic | Logical |
| H_M_MirrorID | Trade.Mirror | Logical |
| H_M_ParentCID | Customer.CustomerStatic | Logical |

### 5.2 Referenced By

- Trade.DetachPositionsFromMirror (OUTPUT INTO)
- Trade.ChangeMirrorState (INSERT)
- Trade.ChangeMirrorAmountForMoe (INSERT)
- Trade.SetMirrorStopLossPercentage (INSERT)
- Trade.UnRegisterMirror (INSERT)
- Trade.RegisterMirror (INSERT)
- Trade.PostDetachPositionFromMirror (SELECT, UPDATE StatusID, DELETE)

---

## 6. Dependencies

### 6.0 Dependency Chain

PostDetachOperation <- Trade.Mirror, Trade.PositionTbl, Customer.CustomerMoney. -> History.Mirror, History.PositionChangeLog_Active_BIGINT.

### 6.1 Objects This Depends On

- Trade.Mirror (source of H_M_*)
- Trade.PositionTbl (source of PCL_*)
- Customer.CustomerMoney (balance context)

### 6.2 Objects That Depend On This

- History.Mirror (INSERT target)
- History.PositionChangeLog_Active_BIGINT (INSERT target)
- Trade.PostDetachPositionFromMirror
- Trade.DetachFromParentPosition (detach workflow)

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Columns | Notes |
|------------|------|---------|-------|
| PK (implicit) | NONCLUSTERED PK | ID ASC | Primary key. |
| ix_StatusID | NONCLUSTERED | StatusID ASC | For batch selection by status. |
| - | - | - | MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA. |

### 7.2 Constraints

| Constraint | Type | Definition |
|------------|------|------------|
| PK | PRIMARY KEY | ID ASC (nonclustered) |
| DEFAULT | DEFAULT | H_M_ModificationDate = getutcdate() |
| DEFAULT | DEFAULT | StatusID = 0 |

---

## 8. Sample Queries

```sql
SELECT TOP 5 ID, PCL_PositionID, PCL_CID, PCL_ChangeTypeID, H_M_MirrorID, StatusID
FROM   Trade.PostDetachOperation WITH (NOLOCK);
```

```sql
SELECT StatusID, COUNT(*) AS Cnt
FROM   Trade.PostDetachOperation WITH (NOLOCK)
GROUP BY StatusID;
```

```sql
SELECT TOP 10 ID, PCL_PositionID, H_M_MirrorOprationDB, H_M_ModificationDate
FROM   Trade.PostDetachOperation WITH (NOLOCK)
WHERE  StatusID = 0
ORDER BY ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 8.5/10 | Sources: DDL, DetachPositionsFromMirror, PostDetachPositionFromMirror, ChangeMirrorState, ChangeMirrorAmountForMoe, SetMirrorStopLossPercentage, UnRegisterMirror, RegisterMirror*
