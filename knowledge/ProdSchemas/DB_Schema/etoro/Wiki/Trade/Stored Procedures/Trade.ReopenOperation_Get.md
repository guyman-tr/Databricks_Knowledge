# Trade.ReopenOperation_Get

> Returns all pending and completed reopen operations ordered from newest to oldest, providing an admin/ops view of the position reopen operation queue.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns full Trade.ReopenOperation dataset |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.ReopenOperation_Get retrieves the full list of position reopen operations from Trade.ReopenOperation, ordered newest-first. It exposes the key administrative fields needed to review, approve, or monitor reopen operations without exposing internal execution state or XML aggregation fields.

This procedure exists as the standard read path for back-office and ops tooling to list all reopen operations. It returns only the informational/decision columns (timing, user, rate parameters, execution flags) rather than the full row, making it suitable for UI listing screens without the overhead of AggregatedData XML.

Data flow: Called by back-office UI tools to populate reopen operation management screens. Returns all rows - there is no paging or filtering; callers are expected to filter/page in the application layer. No parameters. Companion procedures handle the write path: Trade.ReopenOperationAdd (create), Trade.ReopenOperationCancel (cancel), Trade.ReopenOperationValidation (validate), Trade.ReopenOperationSendApprovalRequest (approve), Trade.ReopenOperationSendResult (result notification).

---

## 2. Business Logic

### 2.1 Newest-First Ordering

**What**: Results are returned in descending ReopenOperationID order so the most recent operations appear first.

**Columns/Parameters Involved**: `ReopenOperationID`

**Rules**:
- ORDER BY ReopenOperationID DESC - IDENTITY column, so higher ID = newer operation.
- No WHERE filter - all operations are returned (both pending IsExecuted=0 and completed IsExecuted=1/2).
- Callers must apply their own filters if needed (e.g., pending only).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters.

**Output columns (result set):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ReopenOperationID | int | NO | - | CODE-BACKED | Primary key of the reopen operation. IDENTITY column; higher value = more recently created. Used to identify the operation across the reopen workflow. |
| 2 | Occurred | datetime | NO | - | CODE-BACKED | When the reopen operation was created. From Trade.ReopenOperation - records when the operation was initiated. |
| 3 | ValidateUserBalance | bit | NO | - | CODE-BACKED | Whether to validate the customer's balance before reopening. 1=validate balance; 0=skip balance check. Inherited from Trade.ReopenOperation. |
| 4 | UserName | nvarchar | YES | - | CODE-BACKED | The back-office or automated user who created this reopen operation. From Trade.ReopenOperation.UserName. |
| 5 | RequestedStopRate | money | YES | - | CODE-BACKED | Optional requested stop-loss rate for the reopened positions. NULL if no specific stop rate was requested. From Trade.ReopenOperation. |
| 6 | RequestedLimitRate | money | YES | - | CODE-BACKED | Optional requested take-profit rate for the reopened positions. NULL if no specific limit rate was requested. From Trade.ReopenOperation. |
| 7 | CompensateOnStopLossDelta | bit | NO | - | CODE-BACKED | Whether to compensate customers for the delta if their stop loss changed. 1=compensate; 0=no compensation. From Trade.ReopenOperation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (query) | Trade.ReopenOperation | Reader (SELECT) | Returns key columns from all reopen operation rows ordered newest-first. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by back-office/ops tooling for reopen operation management UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.ReopenOperation_Get (procedure)
└── Trade.ReopenOperation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ReopenOperation | Table | SELECT - reads ReopenOperationID, Occurred, ValidateUserBalance, UserName, RequestedStopRate, RequestedLimitRate, CompensateOnStopLossDelta ordered by ReopenOperationID DESC. |

### 6.2 Objects That Depend On This

No dependents found. Called directly by back-office application tools.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure to list all reopen operations

```sql
EXEC Trade.ReopenOperation_Get;
-- Returns all reopen operations newest-first
```

### 8.2 Equivalent direct query with pending filter

```sql
SELECT ReopenOperationID, Occurred, ValidateUserBalance, UserName,
       RequestedStopRate, RequestedLimitRate, CompensateOnStopLossDelta
FROM Trade.ReopenOperation WITH (NOLOCK)
WHERE IsExecuted = 0
ORDER BY ReopenOperationID DESC;
-- Pending operations only (procedure returns all - filter here)
```

### 8.3 Get most recent 10 operations with execution status

```sql
SELECT TOP 10
    ro.ReopenOperationID, ro.Occurred, ro.UserName, ro.IsExecuted,
    ro.ValidateUserBalance, ro.RequestedStopRate, ro.RequestedLimitRate,
    ro.CompensateOnStopLossDelta
FROM Trade.ReopenOperation ro WITH (NOLOCK)
ORDER BY ro.ReopenOperationID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ReopenOperation_Get | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.ReopenOperation_Get.sql*
