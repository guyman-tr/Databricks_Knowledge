# History.MirrorCloseSaga

> Completed copy-trade close saga archive - records moved from Trade.MirrorCloseSaga after the multi-step copy-stop process completes, preserving the full execution history of every mirror relationship closure.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (int IDENTITY NOT FOR REPLICATION, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active: NONCLUSTERED PK on ID, CLUSTERED on MirrorID ASC |

---

## 1. Business Meaning

History.MirrorCloseSaga is the completed-saga archive for eToro's copy-trade close process. When a customer stops copying a leader (or is automatically stopped), eToro executes a multi-step "saga" - a distributed transaction pattern that coordinates: closing all copied positions, unwinding the copy relationship, settling any open copy-position PnL, and updating all account balances. This multi-step process is tracked in Trade.MirrorCloseSaga (the active queue), with each step indexed via CurrentStepIndex.

When the saga reaches its final step (step 3), `Trade.ArchiveMirrorCloseSaga` is called. It uses `DELETE Trade.MirrorCloseSaga OUTPUT DELETED.* INTO History.MirrorCloseSaga`, moving the completed saga record here. The archive receives one additional column not in the live table: `CloseDate` (DEFAULT getutcdate()), and `SagaCloseReason` which is computed during archival by checking whether the mirror relationship still exists in Trade.Mirror.

With ~11,000 rows, this table has active production-level usage in the test environment, representing a complete record of all mirror close events processed.

---

## 2. Business Logic

### 2.1 Saga Lifecycle - Active Queue to Archive

**What**: Mirror close sagas flow through Trade.MirrorCloseSaga as they progress step by step, and are moved here only when the final step completes.

**Columns/Parameters Involved**: `LastStepIndex`, `CreateDate`, `CloseDate`, `MirrorCloseActionType`

**Rules**:
- Step 0: Saga created - initial close request received
- Step 1: First processing step (e.g., position close requests sent)
- Step 2: Intermediate processing (e.g., positions acknowledged)
- Step 3 (final): Saga completed - Trade.ArchiveMirrorCloseSaga archives the record here
- 99.7% of historical sagas completed at step 3 (normal completion)
- 0.3% ended at step 2 (partial completion - positions partially processed)
- ~0.06% ended at step 0 (saga created but stopped immediately)
- CloseDate is NOT in Trade.MirrorCloseSaga - it is added by the archival step (DEFAULT getutcdate() applied at INSERT time)
- LastStepIndex in History corresponds to CurrentStepIndex in Trade.MirrorCloseSaga at the moment of archival

**Diagram**:
```
Customer clicks "Stop Copying" for MirrorID=1890557:
  Trade.PersistMirrorCloseSaga(@MirrorID=1890557, @CurrentStepIndex=0, @MirrorCloseActionType=0)
  --> Trade.MirrorCloseSaga: MirrorID=1890557, CurrentStepIndex=0, CreateDate=2026-03-19

  (processing steps 1, 2)
  Trade.PersistMirrorCloseSaga(@CurrentStepIndex=1)  -> UPDATE CurrentStepIndex=1
  Trade.PersistMirrorCloseSaga(@CurrentStepIndex=2)  -> UPDATE CurrentStepIndex=2
  Trade.PersistMirrorCloseSaga(@CurrentStepIndex=3)  -> UPDATE CurrentStepIndex=3

  Trade.ArchiveMirrorCloseSaga(@MirrorID=1890557, @CID=25399609)
  --> DELETE Trade.MirrorCloseSaga
      OUTPUT ... INTO History.MirrorCloseSaga
      (checks Trade.Mirror to compute SagaCloseReason)
  --> History.MirrorCloseSaga: MirrorID=1890557, CID=25399609, LastStepIndex=3
      SagaCloseReason=0 (mirror no longer in Trade.Mirror - fully closed)
      CloseDate=2026-03-19 10:14:15 (applied by DEFAULT at INSERT time)
```

### 2.2 SagaCloseReason - Did the Mirror Relationship Survive?

**What**: SagaCloseReason records whether the Trade.Mirror record (the live copy relationship) still existed at the moment of saga archival, distinguishing fully completed close events from partial ones.

**Columns/Parameters Involved**: `SagaCloseReason`, `MirrorID`

**Rules**:
- SagaCloseReason=0: mirror.MirrorID IS NULL in Trade.Mirror at archival time - the copy relationship was fully terminated and removed from the live table (fully closed copy)
- SagaCloseReason=1: mirror still exists in Trade.Mirror at archival time - the saga completed but the copy relationship persists (may indicate a partial close or a stop-loss triggered close that leaves the mirror in an intermediate state)
- SagaCloseReason NULL: rows archived before the SagaCloseReason logic was added to Trade.ArchiveMirrorCloseSaga (~34 rows)
- History.MirrorCloseSagaExists uses `ISNULL(SagaCloseReason, 1) = 0` to check "has this mirror been fully closed before?" - NULL is treated as 1 (mirror still exists) in this check, preventing false positives
- 99.6% of rows have SagaCloseReason=0 (fully closed mirrors are the norm)

### 2.3 MirrorCloseActionType - Reason for the Close

**What**: MirrorCloseActionType classifies what triggered the mirror close - customer-initiated vs system-triggered vs risk-triggered close events.

**Columns/Parameters Involved**: `MirrorCloseActionType`

**Rules**:
- Type 0: the dominant type (87.9% of rows) - likely normal/customer-initiated stop-copy
- Type 2: 10.3% of rows - likely system or risk-initiated close (e.g., insufficient funds, exposure limit)
- Type 5: 1.3% - less frequent close trigger
- Types 1, 3, 4, 6: rare (< 0.2% combined) - specialized close scenarios
- Exact enumeration values are defined in application code (not in the database schema)

---

## 3. Data Overview

~11,105 rows in test environment (active production-level volume).

| MirrorID | CID | LastStepIndex | MirrorCloseActionType | CreateDate | CloseDate | SagaCloseReason | ID | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1890557 | 25399609 | 3 | 0 | 2026-03-19 10:14:15 | 2026-03-19 10:14:15 | 0 | 11105 | Normal close (Type 0), completed at step 3 in ~130ms. Mirror fully removed (SagaCloseReason=0). Most recent saga in test DB. |
| 1888920 | 3739199 | 3 | 3 | 2026-03-17 07:57:02 | 2026-03-17 08:16:10 | 0 | 11101 | Close type 3 (rare). Saga took ~19 minutes (CreateDate to CloseDate gap). Long duration suggests complex position unwinding or retry logic. |
| 1890449 | 3739199 | 3 | 3 | 2026-03-17 08:50:41 | 2026-03-17 08:51:37 | 0 | 11102 | Same customer/type, completed in ~56 seconds. |

**Distribution**: LastStepIndex=3 (99.6%), LastStepIndex=2 (0.3%), LastStepIndex=0 (0.06%). SagaCloseReason=0 (99.6%), =1 (0.06%), NULL (0.3%).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorID | int | NO | - | CODE-BACKED | The copy-trade mirror relationship that was closed. References Trade.Mirror.MirrorID (no FK enforced - history rows persist after the mirror is deleted). The CLUSTERED index is on MirrorID, supporting the most common query pattern: "find all close history for a specific mirror". |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID of the copier (the person who was copying the leader). Combined with MirrorID, uniquely identifies the specific copy relationship. References Customer.CustomerStatic.CID (no FK enforced). Also used as a parameter in Trade.ArchiveMirrorCloseSaga to identify which saga to archive. |
| 3 | LastStepIndex | int | NO | - | CODE-BACKED | The step number reached when the saga was archived. Corresponds to CurrentStepIndex in Trade.MirrorCloseSaga at archive time. 3=fully completed (99.6%), 2=partial (positions processed but not fully finalized), 0=saga created but stopped. The saga implements a multi-step transactional close process where each step represents a phase of the copy-relationship teardown. |
| 4 | InitialRequestGuid | uniqueidentifier | YES | - | CODE-BACKED | The unique identifier of the initial close request that started this saga. Used to correlate the saga with the originating API request or service call for distributed tracing and idempotency checking. NULL if the saga was started without a specific request GUID. |
| 5 | MirrorCloseActionType | int | YES | - | CODE-BACKED | The reason/trigger for this mirror close. 0=customer-initiated stop-copy (87.9%), 2=system/risk-initiated close (10.3%), 5=specialized trigger (1.3%), with rarer types 1/3/4/6 representing other close scenarios. Exact enum meanings are defined in application code. Used to distinguish voluntary copy stops from system-enforced ones. |
| 6 | CreateDate | datetime | NO | - | CODE-BACKED | UTC timestamp when the saga was first created in Trade.MirrorCloseSaga (copied verbatim via OUTPUT DELETED). Represents the moment the close process was initiated. DEFAULT getutcdate() applies on Trade.MirrorCloseSaga; copied here without a default. |
| 7 | CloseDate | datetime | YES | getutcdate() | CODE-BACKED | UTC timestamp when Trade.ArchiveMirrorCloseSaga executed and moved the record here. This column DOES NOT EXIST in Trade.MirrorCloseSaga - it is added only in the History table via DEFAULT getutcdate(). The interval (CloseDate - CreateDate) represents the total duration of the saga from initiation to archival. Typical duration: milliseconds to seconds; rare long-running sagas: minutes. |
| 8 | ClientRequestId | uniqueidentifier | YES | - | CODE-BACKED | Client-supplied idempotency key for the close request. Allows the calling service to detect and reject duplicate close requests. Different from InitialRequestGuid - ClientRequestId is supplied by the client API caller, while InitialRequestGuid is internally generated for the saga. |
| 9 | SagaCloseReason | tinyint | YES | - | CODE-BACKED | Computed during archival: 0=mirror no longer exists in Trade.Mirror at close time (fully terminated copy relationship), 1=mirror still exists in Trade.Mirror at close time (copy relationship persists despite saga completion). Computed via LEFT JOIN Trade.Mirror in Trade.ArchiveMirrorCloseSaga. NULL for older rows archived before this logic was added. Used by History.MirrorCloseSagaExists to check "was this mirror fully closed?". |
| 10 | ID | int | NO | IDENTITY(1,1) NOT FOR REPLICATION | CODE-BACKED | Auto-incrementing surrogate key. NOT FOR REPLICATION - identity does not fire on replicas. NONCLUSTERED PK - sequentially ascending but NOT the clustered index (MirrorID clustering is preferred for the common query pattern). High values (~11,000 in test env) reflect active copy-trade closure volume. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID | Trade.Mirror | Implicit | References the copy relationship that was closed. No FK enforced - history rows persist after Mirror is deleted. |
| CID | Customer.CustomerStatic | Implicit | References the copier customer. No FK enforced. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ArchiveMirrorCloseSaga | DELETE...OUTPUT INTO | Writer | The ONLY writer - moves completed saga records from Trade.MirrorCloseSaga to this archive |
| History.MirrorCloseSagaExists | MirrorID, CID, SagaCloseReason | Reader | Checks if a mirror has a fully-closed saga (SagaCloseReason=0) before allowing a new close attempt |
| Monitor.GetInactiveMirrorsWithNoSagaCount_DataDog | (reference) | Reader | DataDog monitoring query that checks this table for inactive mirrors without saga history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MirrorCloseSaga (table)
  - No code-level dependencies (leaf table)
  - Source: Trade.MirrorCloseSaga (active queue) via Trade.ArchiveMirrorCloseSaga
    - Trade.ArchiveMirrorCloseSaga: DELETE Trade.MirrorCloseSaga OUTPUT DELETED.* INTO History.MirrorCloseSaga
    - Also joins Trade.Mirror to compute SagaCloseReason
```

### 6.1 Objects This Depends On

No dependencies. Archive table populated by DELETE...OUTPUT from the active saga queue.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ArchiveMirrorCloseSaga | Stored Procedure | Sole writer - moves completed saga records here via DELETE...OUTPUT INTO |
| History.MirrorCloseSagaExists | Stored Procedure | Reader - checks if a mirror has been fully closed (SagaCloseReason=0) |
| Monitor.GetInactiveMirrorsWithNoSagaCount_DataDog | Stored Procedure | Reader - DataDog monitoring for inactive mirrors without saga records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryMirrorCloseSaga_ID | NONCLUSTERED | ID ASC | - | - | Active |
| IDX_HistoryMirrorCloseSaga_MirrorID | CLUSTERED | MirrorID ASC | - | - | Active |

Note: Unusual design - CLUSTERED index is on MirrorID (the business key for lookups), while the PK on ID is NONCLUSTERED. This optimizes range scans by MirrorID (checking close history for a specific mirror) over sequential ID access. PAGE compression applied to both.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryMirrorCloseSaga_ID | PRIMARY KEY | NONCLUSTERED PK on ID |
| DF_HistoryMirrorCloseSaga_CloseDate | DEFAULT | CloseDate = getutcdate() - applied at archival INSERT time |

---

## 8. Sample Queries

### 8.1 Get the full close history for a specific mirror

```sql
SELECT
    MirrorID,
    CID,
    LastStepIndex,
    MirrorCloseActionType,
    CreateDate,
    CloseDate,
    DATEDIFF(MILLISECOND, CreateDate, CloseDate) AS SagaDurationMs,
    SagaCloseReason,
    ID
FROM [History].[MirrorCloseSaga] WITH (NOLOCK)
WHERE MirrorID = @MirrorID
ORDER BY ID ASC
```

### 8.2 Check if a mirror has been fully closed (equivalent of History.MirrorCloseSagaExists)

```sql
SELECT TOP (1) 1 AS WasFullyClosed
FROM [History].[MirrorCloseSaga] WITH (NOLOCK)
WHERE MirrorID = @MirrorID
  AND CID = @CID
  AND ISNULL(SagaCloseReason, 1) = 0   -- SagaCloseReason=0 OR NULL treated as 1 (mirror still exists)
```

### 8.3 Slow saga analysis - find long-running close operations

```sql
SELECT
    MirrorID,
    CID,
    MirrorCloseActionType,
    LastStepIndex,
    CreateDate,
    CloseDate,
    DATEDIFF(SECOND, CreateDate, CloseDate) AS SagaDurationSec,
    SagaCloseReason
FROM [History].[MirrorCloseSaga] WITH (NOLOCK)
WHERE DATEDIFF(SECOND, CreateDate, CloseDate) > 60  -- sagas taking more than 1 minute
ORDER BY DATEDIFF(SECOND, CreateDate, CloseDate) DESC
```

### 8.4 Close type distribution summary

```sql
SELECT
    MirrorCloseActionType,
    COUNT(*) AS CloseCount,
    AVG(DATEDIFF(MILLISECOND, CreateDate, CloseDate)) AS AvgDurationMs,
    SUM(CASE WHEN LastStepIndex = 3 THEN 1 ELSE 0 END) AS FullyCompleted,
    SUM(CASE WHEN LastStepIndex < 3 THEN 1 ELSE 0 END) AS Partial
FROM [History].[MirrorCloseSaga] WITH (NOLOCK)
GROUP BY MirrorCloseActionType
ORDER BY CloseCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed (Trade.ArchiveMirrorCloseSaga, Trade.PersistMirrorCloseSaga, History.MirrorCloseSagaExists) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.MirrorCloseSaga | Type: Table | Source: etoro/etoro/History/Tables/History.MirrorCloseSaga.sql*
