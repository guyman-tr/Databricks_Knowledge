# History.MirrorToReopen

> Audit log recording the outcome of mirror reopen operations - captures whether each re-copy attempt succeeded or failed, which new mirror was created on success, and the full error context on failure.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Composite PK: (ReopenOperationID, ClosedMirrorID) - CLUSTERED |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK on ReopenOperationID+ClosedMirrorID) |

---

## 1. Business Meaning

History.MirrorToReopen records the result of every mirror reopen operation - the feature that allows a customer's copy relationship to be automatically re-established after it was closed (typically by the Mirror Stop Loss engine or by admin action). When a mirror is closed, the customer may have requested it to be reopened once their balance recovers or a cooldown period elapses.

The reopen flow:
1. A reopen request is queued in Trade.MirrorToReopen (the active queue) with ReopenOperationID and ClosedMirrorID
2. `Trade.MirrorReopen` (or `Trade.MirrorsReopen` for batch) processes the request: validates the conditions, calls Trade.RegisterMirror to create the new copy relationship
3. Regardless of success or failure, Trade.MirrorReopen writes a result row here via INSERT...SELECT FROM Trade.MirrorToReopen and then deletes the record from the active queue

Result=1 (success): ReopenMirrorID is populated with the new mirror's ID; NewMirrorSL captures the adjusted stop-loss if it needed to be recalculated.
Result=0 (failure): FailReason captures the specific error from the CATCH block.

With 0 rows in the test environment, this feature is used infrequently - only when customers have specifically configured auto-reopen behavior.

---

## 2. Business Logic

### 2.1 Reopen Queue to Archive - Success and Failure Both Archived

**What**: Unlike typical success/failure paired tables, both outcomes of a reopen attempt write to this single table. The Result column distinguishes success from failure. In both cases, the source row is deleted from Trade.MirrorToReopen.

**Columns/Parameters Involved**: `Result`, `ReopenMirrorID`, `FailReason`, `ClosedMirrorID`, `ReopenOperationID`

**Rules**:
- Result=1 (success): Trade.RegisterMirror succeeded, new mirror created. ReopenMirrorID = the new mirror's ID. Trade.Mirror.ReopenForMirrorID is set to @ClosedMirrorID, linking the new and old mirrors.
- Result=0 (failure): Exception caught in CATCH block. FailReason = CONCAT('Trade.ReopenMirror Failed: ', @ErrorMessage). ReopenMirrorID may be NULL or 0 (ReopenMirrorID was attempted but failed in the transaction that was rolled back).
- In BOTH cases: Trade.MirrorToReopen is deleted after the result is written here. The active queue never retains a record once processed.
- ExecutionOccurred DEFAULT getutcdate() = when the row was inserted into History.MirrorToReopen (i.e., when the reopen was processed)

**Diagram**:
```
Customer requested auto-reopen for ClosedMirrorID=789:
  Trade.MirrorToReopen: ReopenOperationID=5, CID=12345, ClosedMirrorID=789, RequestOccurred=2024-06-01

  Trade.MirrorReopen(@ReopenOperationID=5, @CID=12345, @ClosedMirrorID=789):
    Validates: mirror not in Trade.Mirror, original in History.Mirror with OperationID=2
    Calls Trade.RegisterMirror -> creates MirrorID=999 (new copy)
    Sets Trade.Mirror.ReopenForMirrorID=789

    SUCCESS path:
      INSERT History.MirrorToReopen: ReopenOperationID=5, CID=12345, ClosedMirrorID=789,
        ReopenMirrorID=999, RequestReopenOccurred=2024-06-01, Result=1, NewMirrorSL=NULL (SL unchanged)
      DELETE Trade.MirrorToReopen WHERE ClosedMirrorID=789 AND ReopenOperationID=5

    FAILURE path:
      INSERT History.MirrorToReopen: ReopenOperationID=5, CID=12345, ClosedMirrorID=789,
        ReopenMirrorID=NULL, RequestReopenOccurred=2024-06-01, Result=0,
        FailReason='Trade.ReopenMirror Failed: Mirror exists in Trade.Mirror'
      DELETE Trade.MirrorToReopen WHERE ClosedMirrorID=789 AND ReopenOperationID=5
```

### 2.2 NewMirrorSL - Stop-Loss Adjustment on Reopen

**What**: If the original stop-loss amount would exceed the current account balance (Amount <= OldMirrorSL), Trade.MirrorReopen recalculates the stop-loss as a percentage of the current amount. NewMirrorSL captures this adjusted value.

**Columns/Parameters Involved**: `NewMirrorSL`, `ClosedMirrorID`

**Rules**:
- NewMirrorSL IS NULL: the original stop-loss amount was preserved unchanged (@OldMirrorSL = @MirrorSL used in RegisterMirror)
- NewMirrorSL IS NOT NULL: the stop-loss was recalculated as ROUND((Amount * MirrorSLPercentage)/100, 2) because Amount <= OldMirrorSL
- This only happens when @AllowUpdateMirrorSL=1 was passed to Trade.MirrorReopen
- The new SL is based on the original MirrorSLPercentage from History.Mirror (the % rate, not the fixed amount)

---

## 3. Data Overview

No data in test environment (0 rows). Mirror reopen operations are infrequent - they require specific customer configuration and appropriate account conditions. In production, rows represent the complete processing history of all reopen requests.

| ReopenOperationID | CID | ClosedMirrorID | ReopenMirrorID | NewMirrorSL | RequestReopenOccurred | ExecutionOccurred | Result | FailReason | Meaning |
|---|---|---|---|---|---|---|---|---|---|
| 5 | 12345 | 789012 | 900001 | NULL | 2024-06-01 10:00 | 2024-06-01 10:00:15 | 1 | NULL | Successful reopen. New mirror 900001 was created. SL unchanged (NULL). Executed 15s after request. |
| 6 | 67890 | 456789 | NULL | NULL | 2024-06-02 08:30 | 2024-06-02 08:30:01 | 0 | Trade.ReopenMirror Failed: Mirror exists in Trade.Mirror | Failed: mirror was already active when reopen was attempted. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReopenOperationID | int | NO | - | CODE-BACKED | The identifier of the reopen operation request from Trade.MirrorToReopen. Part of the composite PK. Identifies the specific reopen operation instance - a customer may have multiple reopen operations for the same ClosedMirrorID over time. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID of the copier whose mirror was reopened. Sourced from Trade.MirrorToReopen at archival time. References Customer.CustomerStatic.CID (no FK enforced). |
| 3 | ClosedMirrorID | int | NO | - | CODE-BACKED | The original mirror that was closed and being reopened. Part of the composite PK. References History.Mirror (the closed mirror record) and Trade.Mirror.ReopenForMirrorID (after successful reopen, the new mirror has ReopenForMirrorID=ClosedMirrorID). |
| 4 | ReopenMirrorID | int | YES | - | CODE-BACKED | The new mirror ID created upon successful reopen. NULL on failure (the RegisterMirror transaction was rolled back). On success, this ID exists in Trade.Mirror (with ReopenForMirrorID=ClosedMirrorID) and can be used to track the new copy relationship. |
| 5 | NewMirrorSL | money | YES | - | CODE-BACKED | The recalculated stop-loss amount for the new mirror, if adjustment was needed. NULL when the original SL was preserved (original SL amount fit within the current balance). NOT NULL when the amount was recalculated as (Amount * MirrorSLPercentage/100) because Amount <= OldMirrorSL. |
| 6 | RequestReopenOccurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the reopen was originally requested (from Trade.MirrorToReopen.RequestOccurred). Represents the original request time, not the execution time. The gap between RequestReopenOccurred and ExecutionOccurred represents processing latency. |
| 7 | ExecutionOccurred | datetime | NO | getutcdate() | CODE-BACKED | UTC timestamp when Trade.MirrorReopen processed this request and wrote the result to History. DEFAULT getutcdate() applied at INSERT time. The "processing time" timestamp as opposed to the "request time" in RequestReopenOccurred. |
| 8 | Result | tinyint | NO | - | CODE-BACKED | Outcome of the reopen attempt: 1=success (new mirror created, ReopenMirrorID populated), 0=failure (error occurred, FailReason populated). Allows filtering success vs failure without parsing FailReason. |
| 9 | FailReason | varchar(max) | YES | - | CODE-BACKED | Error description when Result=0. Format: 'Trade.ReopenMirror Failed: {ERROR_MESSAGE()}' from the CATCH block. NULL when Result=1. Common reasons: "Mirror exists in Trade.Mirror" (mirror still active), "Reopen Mirror exists in Trade.Mirror" (reopen already happened), "Mirror not exists in History.Mirror" (original close not found), "Insufficient Funds", "The Amount is lower then MSL Amount" (when AllowUpdateMirrorSL=0). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ClosedMirrorID | History.Mirror | Implicit | References the original closed mirror (MirrorOperationID=2 = UnRegister). Trade.MirrorReopen validates this before proceeding. No FK enforced. |
| ReopenMirrorID | Trade.Mirror | Implicit | References the new mirror created upon successful reopen. No FK enforced - history rows persist after mirror changes. |
| CID | Customer.CustomerStatic | Implicit | References the copier. No FK enforced. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.MirrorReopen | (INSERT in success and error paths) | Writer | Inserts result row and deletes from Trade.MirrorToReopen |
| Trade.MirrorsReopen | (calls Trade.MirrorReopen) | Indirect writer | Batch reopen that calls Trade.MirrorReopen for each queued reopen operation |
| Trade.ReopenOperationCancel | ClosedMirrorID | Reader | Checks if a reopen has already been processed before cancelling a pending request |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MirrorToReopen (table)
  - No code-level dependencies (leaf table)
  - Source: Trade.MirrorToReopen (active queue) via Trade.MirrorReopen
    - Trade.MirrorReopen: INSERT History.MirrorToReopen (both success and failure)
                          DELETE Trade.MirrorToReopen (always, after INSERT)
```

### 6.1 Objects This Depends On

No dependencies. Free-standing audit log.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.MirrorReopen | Stored Procedure | Writer - inserts one row per processed reopen attempt (both success and failure) |
| Trade.MirrorsReopen | Stored Procedure | Indirect writer via Trade.MirrorReopen |
| Trade.ReopenOperationCancel | Stored Procedure | Reader - checks processing history before cancelling |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_MirrorToReopen | CLUSTERED | ReopenOperationID ASC, ClosedMirrorID ASC | - | - | Active |

FILLFACTOR=95. PAGE compression applied. On [HISTORY] filegroup.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_MirrorToReopen | PRIMARY KEY | Clustered composite PK (ReopenOperationID, ClosedMirrorID) |
| DF_MirrorToReopen_Occurred | DEFAULT | ExecutionOccurred = getutcdate() |

Note: Trade.MirrorToReopen (source queue, on [MAIN] filegroup) has the same composite PK structure.

---

## 8. Sample Queries

### 8.1 Get all reopen history for a specific closed mirror

```sql
SELECT
    ReopenOperationID,
    CID,
    ClosedMirrorID,
    ReopenMirrorID,
    NewMirrorSL,
    RequestReopenOccurred,
    ExecutionOccurred,
    DATEDIFF(SECOND, RequestReopenOccurred, ExecutionOccurred) AS ProcessingTimeSec,
    Result,
    FailReason
FROM [History].[MirrorToReopen] WITH (NOLOCK)
WHERE ClosedMirrorID = @ClosedMirrorID
ORDER BY ExecutionOccurred ASC
```

### 8.2 Success rate and failure reason analysis

```sql
SELECT
    Result,
    COUNT(*) AS Count,
    LEFT(FailReason, 100) AS FailReasonSample,
    COUNT(*) AS FrequencyOfThisReason
FROM [History].[MirrorToReopen] WITH (NOLOCK)
GROUP BY Result, LEFT(FailReason, 100)
ORDER BY Result DESC, Count DESC
```

### 8.3 Reopen operations with stop-loss adjustments

```sql
SELECT
    htr.ClosedMirrorID,
    htr.CID,
    htr.ReopenMirrorID,
    htr.NewMirrorSL,
    htr.ExecutionOccurred,
    tm.MirrorSL AS CurrentMirrorSL
FROM [History].[MirrorToReopen] htr WITH (NOLOCK)
JOIN [Trade].[Mirror] tm WITH (NOLOCK) ON tm.MirrorID = htr.ReopenMirrorID
WHERE htr.Result = 1
  AND htr.NewMirrorSL IS NOT NULL   -- SL was adjusted during reopen
ORDER BY htr.ExecutionOccurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.MirrorReopen, Trade.ReopenOperationCancel) | App Code: 0 repos | Corrections: 0 applied*
*Object: History.MirrorToReopen | Type: Table | Source: etoro/etoro/History/Tables/History.MirrorToReopen.sql*
