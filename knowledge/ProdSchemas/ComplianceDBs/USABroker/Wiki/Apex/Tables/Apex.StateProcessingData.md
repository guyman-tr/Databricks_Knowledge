# Apex.StateProcessingData

> Scheduling and retry metadata for the Apex state machine work queue, tracking when each customer should next be processed, whether they are currently being worked on, and error/retry counts for exponential backoff.

| Property | Value |
|----------|-------|
| **Schema** | Apex |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK) + 1 nonclustered (ErrorCount with includes) |

---

## 1. Business Meaning

Apex.StateProcessingData is the work queue metadata table for the Apex state machine. While Apex.State tracks WHAT state a customer is in, this table tracks WHEN they should next be processed, WHETHER they are currently being worked on, and HOW MANY times processing has been attempted or failed. It is the operational backbone of the background processing engine.

This table is essential because the Apex integration is event-driven with background processing. The GetWorkStates procedure queries this table to find customers ready for their next state transition, using exponential backoff on errors (doubling the wait time with each consecutive failure). Without it, the system cannot schedule, prioritize, or retry state machine transitions.

Data is always written atomically alongside Apex.State by the SaveState procedure (both tables are updated in a single transaction). GetWorkStates is the primary consumer - it selects customers where StateNextUpdatedDate has passed, InWork=0 (or timed out), and ErrorCount is below threshold, then marks them InWork=1 and increments ErrorCount (which is decremented on success by the application).

---

## 2. Business Logic

### 2.1 Work Queue with Exponential Backoff

**What**: GetWorkStates implements a work queue with exponential backoff on errors, preventing rapid retries of failing customers while ensuring healthy customers are processed promptly.

**Columns/Parameters Involved**: `StateNextUpdatedDate`, `InWork`, `LastUpdateDate`, `ErrorCount`, `RetryCount`

**Rules**:
- Items are eligible when StateNextUpdatedDate < now AND InWork=0 (or InWork=1 with timeout exceeded)
- Timeout calculation uses exponential backoff: WorkTimeoutSec * 2^ErrorCount (capped at 2^16 to avoid overflow)
- ErrorCount is incremented on pickup (pessimistic - assume failure); application decrements on success
- MaxErrorCount parameter (default 5) caps how many times a customer is retried before being abandoned
- TABLOCKX,XLOCK hints ensure serialized access to prevent duplicate processing
- Items are ordered by StateNextUpdatedDate ASC to process oldest first

**Diagram**:
```
GetWorkStates picks up items:
  StateNextUpdatedDate < NOW
  AND (InWork=0 OR (InWork=1 AND timeout expired))
  AND ErrorCount <= MaxErrorCount
      |
      v
  SET InWork=1, LastUpdateDate=NOW, ErrorCount+1
      |
      v
  Application processes state transition
      |
      +-- Success --> SaveState: ErrorCount-1, InWork=0, StateNextUpdatedDate=next
      +-- Failure --> Left as-is (ErrorCount already incremented)
                      Next pickup waits: WorkTimeoutSec * 2^ErrorCount
```

### 2.2 Stuck State Detection

**What**: StateNextUpdatedDate far in the future indicates intentional deferral, while InWork=true with old LastUpdateDate indicates a stuck/crashed processor.

**Columns/Parameters Involved**: `StateNextUpdatedDate`, `LastUpdateDate`, `InWork`

**Rules**:
- Observed: StateNextUpdatedDate set 1 year in the future (e.g., 2026 -> 2027) for long-deferred items
- ErrorCount=0 with RetryCount>0 indicates successful processing after retries (error count was decremented back to 0)
- The ix_StateProcessingData_ErrorCount index includes InWork, LastUpdateDate, StateNextUpdatedDate for efficient work queue queries

---

## 3. Data Overview

| GCID | StateNextUpdatedDate | LastUpdateDate | InWork | RetryCount | ErrorCount | Meaning |
|------|---------------------|----------------|--------|------------|------------|---------|
| 20708 | 2026-05-30 | 2025-05-30 | false | 3 | 0 | Deferred 1 year into future. ErrorCount=0 after 3 retries means eventually succeeded. Not currently being processed. |
| 60520 | 2026-11-17 | 2025-11-17 | false | 2 | 0 | Also deferred 1 year. 2 retries, now stable. Customer in InitiateAutoAppeal state. |
| 75188 | 2027-04-08 | 2026-04-08 | false | 2 | 0 | Deferred to Apr 2027. Customer in NotifyTradingCompleted state - waiting for trading notification. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | VERIFIED | Global Customer ID. Primary key. FK to Apex.State(GCID). One processing record per customer, always paired with a State row. |
| 2 | StateNextUpdatedDate | datetime2(7) | YES | - | VERIFIED | UTC timestamp of when this customer should next be picked up for processing. NULL or past date means eligible immediately. Future date means intentionally deferred. GetWorkStates filters on this < NOW. |
| 3 | LastUpdateDate | datetime2(7) | YES | - | VERIFIED | UTC timestamp of when this record was last processed (picked up by GetWorkStates). Used in timeout calculation: if InWork=1 and LastUpdateDate + timeout < NOW, the item is considered stuck and eligible for re-pickup. |
| 4 | InWork | bit | NO | 0 | VERIFIED | Whether a worker is currently processing this customer's state transition. Set to 1 by GetWorkStates on pickup, set to 0 by SaveState on completion. If 1 with old LastUpdateDate, indicates a crashed/stuck worker. |
| 5 | RetryCount | int | NO | 0 | CODE-BACKED | Cumulative count of processing attempts. Incremented by the application. Unlike ErrorCount, this is not decremented - it tracks total attempts over the lifetime. |
| 6 | ErrorCount | int | NO | 0 | VERIFIED | Current consecutive error count. Incremented by GetWorkStates on pickup (pessimistic), decremented by application on success. Used for exponential backoff: wait = WorkTimeoutSec * 2^ErrorCount. Capped at MaxErrorCount (default 5) - items exceeding this are not picked up. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| GCID | Apex.State | FK | Must have a corresponding State row |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Apex.SaveState | @GCID | Writer | Atomically updates alongside State in a transaction |
| Apex.GetState | @GCID | Reader | JOINs with State for combined retrieval |
| Apex.GetWorkStates | - | Reader/Writer | Work queue processor - reads eligible items and marks InWork |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Apex.StateProcessingData (table)
└── Apex.State (table) [FK target]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Apex.State | Table | FK on GCID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Apex.SaveState | Stored Procedure | Writer - atomic update with State |
| Apex.GetState | Stored Procedure | Reader - JOINed with State |
| Apex.GetWorkStates | Stored Procedure | Reader/Writer - work queue processor |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_StateProcessingData | CLUSTERED PK | GCID ASC | - | - | Active |
| ix_StateProcessingData_ErrorCount | NONCLUSTERED | ErrorCount ASC | InWork, LastUpdateDate, StateNextUpdatedDate | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_StateProcessingData | PRIMARY KEY | Clustered on GCID |
| FK_StateProcessingData_State | FOREIGN KEY | GCID -> Apex.State(GCID) |
| DF_StateProcessingData_InWork | DEFAULT | InWork = 0 |
| DF_StateProcessingData_RetryCount | DEFAULT | RetryCount = 0 |
| DF_StateProcessingData_ErrorCount | DEFAULT | ErrorCount = 0 |

---

## 8. Sample Queries

### 8.1 Find customers eligible for processing now

```sql
SELECT sp.GCID, s.ApexStateID, ds.Name AS StateName,
       sp.StateNextUpdatedDate, sp.ErrorCount, sp.RetryCount
FROM Apex.StateProcessingData sp WITH (NOLOCK)
INNER JOIN Apex.State s WITH (NOLOCK) ON s.GCID = sp.GCID
INNER JOIN Dictionary.State ds WITH (NOLOCK) ON ds.ApexStateID = s.ApexStateID
WHERE (sp.StateNextUpdatedDate < GETUTCDATE() OR sp.StateNextUpdatedDate IS NULL)
  AND sp.InWork = 0
  AND sp.ErrorCount <= 5
ORDER BY sp.StateNextUpdatedDate ASC;
```

### 8.2 Find stuck workers (InWork=1 for more than 30 minutes)

```sql
SELECT sp.GCID, s.ApexStateID, ds.Name AS StateName,
       sp.LastUpdateDate, sp.ErrorCount,
       DATEDIFF(MINUTE, sp.LastUpdateDate, GETUTCDATE()) AS MinutesStuck
FROM Apex.StateProcessingData sp WITH (NOLOCK)
INNER JOIN Apex.State s WITH (NOLOCK) ON s.GCID = sp.GCID
INNER JOIN Dictionary.State ds WITH (NOLOCK) ON ds.ApexStateID = s.ApexStateID
WHERE sp.InWork = 1
  AND DATEDIFF(MINUTE, sp.LastUpdateDate, GETUTCDATE()) > 30;
```

### 8.3 Error count distribution

```sql
SELECT ErrorCount, COUNT(*) AS CustomerCount
FROM Apex.StateProcessingData WITH (NOLOCK)
GROUP BY ErrorCount
ORDER BY ErrorCount;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Apex.StateProcessingData | Type: Table | Source: USABroker/Apex/Tables/Apex.StateProcessingData.sql*
