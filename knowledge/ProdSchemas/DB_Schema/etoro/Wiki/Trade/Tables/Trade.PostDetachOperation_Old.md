# Trade.PostDetachOperation_Old

> Deprecated memory-optimized table that captured position and mirror state snapshots when copied positions were detached from CopyTrader mirrors; replaced by Trade.PostDetachOperation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | PCL_PositionID |
| **Partition** | No (Memory-Optimized) |
| **Indexes** | 2 (1 PK nonclustered, 1 NC on StatusID) |

---

## 1. Business Meaning

**WHAT:** Trade.PostDetachOperation_Old is a deprecated memory-optimized In-Memory OLTP table that previously served as the queue for post-detach mirror operations. When a copied position was detached from its mirror (copy-trade tree), this table captured a snapshot of both the position state (PCL_* columns) and the mirror state (H_M_* columns) at the moment of detachment.

**WHY:** The table existed to decouple the fast detach path from the slower history-persistence path. Detaching a position must complete quickly; writing to History.Mirror and History.PositionChangeLog can be deferred. This OLD version has been superseded by Trade.PostDetachOperation, which uses the same conceptual structure but is the active implementation.

**HOW:** Data no longer flows through this table. It is empty and archived. The active version Trade.PostDetachOperation receives OUTPUT from detach procedures and is processed by Trade.PostDetachPositionFromMirror. Rows in this OLD table would have been inserted by detach procedures, processed by a background job, and then deleted after successful persistence to history tables.

---

## 2. Business Logic

### 2.1 PCL_ Prefix (Position Change Log)

**What**: Position state at the moment of detachment, intended for History.PositionChangeLog.

**Columns Involved**: `PCL_PositionID`, `PCL_Occurred`, `PCL_OrigParentPositionID`, `PCL_CID`, `PCL_ChangeTypeID`, `PCL_PrevTreeID`, `PCL_TreeID`, `PCL_PreviousIsSettled`, `PCL_IsSettled`, `PCL_PositionAmount`, `PCL_LimitRate`, `PCL_StopRate`, `PCL_LastOpConversionRate`, `PCL_ConversionRateID`, `PCL_ClientRequestGuid`, `PCL_IsTslEnabled`, `PCL_TreeUnits`, `PCL_MirrorRealizedEquity`, `PCL_ExecutedWithoutSettings`, `PCL_IsNoTakeProfit`, `PCL_IsNoStopLoss`

**Rules**:
- PCL_ChangeTypeID 5 = Position Transfer (detach)
- PCL_PrevTreeID and PCL_TreeID track the tree change from copy-trade tree to standalone
- PCL_PositionID is the primary key and identifies the detached position

**Diagram**:
```
Detach Event
    |
    v
+---------------------------+
| PostDetachOperation_Old   |
| PCL_* = Position snapshot |
| H_M_* = Mirror snapshot   |
| StatusID = 0 (pending)   |
+---------------------------+
    | (job processes)
    v
History.Mirror + History.PositionChangeLog
    |
    v
DELETE row
```

### 2.2 H_M_ Prefix (History.Mirror Snapshot)

**What**: Mirror state at the moment of detachment, intended for History.Mirror.

**Columns Involved**: `H_M_MirrorID`, `H_M_CID`, `H_M_ParentCID`, `H_M_ParentUserName`, `H_M_Amount`, `H_M_Occurred`, `H_M_IsActive`, `H_M_MirrorOperationID`, `H_M_IsOpenOpen`, `H_M_GuruTPV`, `H_M_MirrorSL`, `H_M_RealizedEquity`, `H_M_PauseCopy`, `H_M_MirrorSLPercentage`, `H_M_InitialInvestment`, `H_M_DepositSummary`, `H_M_WithdrawalSummary`, `H_M_SessionID`, `H_M_MIMOOperationTypeID`, `H_M_MirrorDividendID`, `H_M_ClientRequestGuid`

**Rules**:
- H_M_MirrorOperationID 10 = Position Transfer
- These columns map to History.Mirror for audit of mirror lifecycle

### 2.3 StatusID Processing

**What**: Tracks processing state for the queue consumer job.

**Rules**:
- 0 = Pending (default) -> row awaits processing
- Processed states follow (job-specific)
- Successful processing results in DELETE; failed rows may be retried with decremented StatusID

---

## 3. Data Overview

| PCL_PositionID | StatusID | Meaning |
|----------------|----------|---------|
| (empty) | - | Table is EMPTY (deprecated/archived). The active Trade.PostDetachOperation is in use. |

**Selection criteria**: This table is deprecated. No live data exists. When it was active, rows represented pending or failed detach snapshots awaiting persistence to history.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PCL_PositionID | bigint | NO | - | CODE-BACKED | Primary key. Position that was detached. |
| 2 | PCL_Occurred | datetime | YES | - | CODE-BACKED | When the detach occurred. |
| 3 | PCL_OrigParentPositionID | bigint | YES | - | CODE-BACKED | Original parent position before detach. |
| 4 | PCL_CID | int | YES | - | CODE-BACKED | Customer ID of the position owner. |
| 5 | PCL_ChangeTypeID | int | YES | - | CODE-BACKED | Change type: 5 = Position Transfer (detach). |
| 6 | PCL_PrevTreeID | bigint | YES | - | CODE-BACKED | Tree ID before detach. |
| 7 | PCL_TreeID | bigint | YES | - | CODE-BACKED | New tree ID after detach (standalone). |
| 8 | PCL_PreviousIsSettled | int | YES | - | CODE-BACKED | IsSettled before detach. |
| 9 | PCL_IsSettled | int | YES | - | CODE-BACKED | IsSettled after detach. |
| 10 | PCL_PositionAmount | money | YES | - | CODE-BACKED | Position amount at detach. |
| 11 | PCL_LimitRate | decimal(16,8) | YES | - | CODE-BACKED | Take-profit rate at detach. |
| 12 | PCL_StopRate | decimal(16,8) | YES | - | CODE-BACKED | Stop-loss rate at detach. |
| 13 | PCL_LastOpConversionRate | decimal(16,8) | YES | - | CODE-BACKED | Last operation conversion rate. |
| 14 | PCL_ConversionRateID | bigint | YES | - | CODE-BACKED | Conversion rate lookup ID. |
| 15 | PCL_ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client request correlation ID. |
| 16 | PCL_IsTslEnabled | bit | YES | - | CODE-BACKED | Trailing stop-loss enabled at detach. |
| 17 | PCL_TreeUnits | decimal(20,6) | YES | - | CODE-BACKED | Tree units at detach. |
| 18 | PCL_MirrorRealizedEquity | money | YES | - | CODE-BACKED | Mirror realized equity at detach. |
| 19 | PCL_ExecutedWithoutSettings | bit | YES | - | CODE-BACKED | Position executed without full settings. |
| 20 | H_M_MirrorID | int | YES | - | CODE-BACKED | Mirror ID for History.Mirror. |
| 21 | H_M_CID | int | YES | - | CODE-BACKED | CID for History.Mirror. |
| 22 | H_M_ParentCID | int | YES | - | CODE-BACKED | Parent CID (leader). |
| 23 | H_M_ParentUserName | varchar(50) | YES | - | CODE-BACKED | Parent user name. |
| 24 | H_M_Amount | decimal(16,8) | YES | - | CODE-BACKED | Mirror amount change. |
| 25 | H_M_Occurred | datetime | YES | - | CODE-BACKED | Mirror change timestamp. |
| 26 | H_M_IsActive | tinyint | YES | - | CODE-BACKED | Mirror active flag at detach. |
| 27 | H_M_MirrorOperationID | int | YES | - | CODE-BACKED | 10 = Position Transfer. |
| 28 | H_M_IsOpenOpen | bit | YES | - | CODE-BACKED | Open-open mirror flag. |
| 29 | H_M_GuruTPV | money | YES | - | CODE-BACKED | Guru TPV. |
| 30 | H_M_MirrorSL | money | YES | - | CODE-BACKED | Mirror stop-loss. |
| 31 | H_M_RealizedEquity | money | YES | - | CODE-BACKED | Mirror realized equity. |
| 32 | H_M_PauseCopy | bit | YES | - | CODE-BACKED | Pause copy flag. |
| 33 | H_M_MirrorSLPercentage | money | YES | - | CODE-BACKED | Mirror SL percentage. |
| 34 | H_M_InitialInvestment | money | YES | - | CODE-BACKED | Initial investment. |
| 35 | H_M_DepositSummary | money | YES | - | CODE-BACKED | Deposit summary. |
| 36 | H_M_WithdrawalSummary | money | YES | - | CODE-BACKED | Withdrawal summary. |
| 37 | H_M_SessionID | bigint | YES | - | CODE-BACKED | Session ID. |
| 38 | H_M_MIMOOperationTypeID | int | YES | - | CODE-BACKED | MIMO operation type. |
| 39 | H_M_MirrorDividendID | int | YES | - | CODE-BACKED | Mirror dividend ID. |
| 40 | H_M_ClientRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | Client request GUID. |
| 41 | StatusID | int | YES | 0 | CODE-BACKED | 0 = Pending (default); processed states follow. |
| 42 | PCL_IsNoTakeProfit | bit | YES | - | CODE-BACKED | No take-profit flag. |
| 43 | PCL_IsNoStopLoss | bit | YES | - | CODE-BACKED | No stop-loss flag. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PCL_PositionID | Trade.PositionTbl | Implicit | Position that was detached. |
| PCL_CID, H_M_CID | Customer.CustomerStatic | Implicit | Customer identifiers. |
| H_M_MirrorID | Trade.Mirror | Implicit | Source mirror for history. |
| H_M_ParentCID | Customer.CustomerStatic | Implicit | Parent (leader) customer. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (none) | - | - | Deprecated table; no active references. Active version is Trade.PostDetachOperation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PostDetachOperation_Old (table)
(No code-level dependencies - CREATE TABLE has no FROM/JOIN)
```

### 6.1 Objects This Depends On

No dependencies. Table structure only. Logical references to Trade.PostDetachOperation, Trade.Mirror, Trade.PositionTbl are documented in Section 5.

### 6.2 Objects That Depend On This

None. Deprecated table. Use Trade.PostDetachOperation instead.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (implicit) | NONCLUSTERED PK | PCL_PositionID ASC | - | - | Active |
| ix_StatusID | NONCLUSTERED | StatusID ASC | - | - | Active |

Memory-optimized: MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK | PRIMARY KEY | PCL_PositionID ASC (nonclustered) |
| DEFAULT | DEFAULT | StatusID = 0 |

---

## 8. Sample Queries

### 8.1 Verify table is empty (deprecated)

```sql
SELECT COUNT(*) AS RowCount
FROM   Trade.PostDetachOperation_Old WITH (NOLOCK);
```

### 8.2 Compare structure to active version

```sql
SELECT TOP 1 *
FROM   Trade.PostDetachOperation_Old WITH (NOLOCK);
```

### 8.3 Check for any orphaned data (should return 0)

```sql
SELECT PCL_PositionID, StatusID
FROM   Trade.PostDetachOperation_Old WITH (NOLOCK)
WHERE  StatusID = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 7.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 6/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 43 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + context*
*Sources: DDL, Trade.PostDetachOperation doc, Trade.Mirror doc | Corrections: 0 applied*
*Object: Trade.PostDetachOperation_Old | Type: Table | Source: etoro/Trade/Tables/PostDetachOperation_Old.sql*
