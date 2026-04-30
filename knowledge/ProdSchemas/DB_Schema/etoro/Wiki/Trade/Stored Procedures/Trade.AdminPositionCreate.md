# Trade.AdminPositionCreate

> Creates administrative position records in Trade.AdminPositionLog from a TVP, with deduplication to prevent duplicate requests for the same CID + AdminPositionRequestID combination that are already in progress.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @adminPositionTbl (Trade.AdminPositionTbl TVP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure logs **administrative position creation requests** into `Trade.AdminPositionLog`. Admin positions are positions opened by operations or back-office staff rather than by customers directly - used for compensations, corrections, or manual interventions. Each request is tracked with a unique `AdminPositionRequestID` to prevent duplicate processing.

Without this procedure, operations staff would have no auditable way to batch-create admin positions. The deduplication logic prevents the same request from being logged twice if the caller retries due to timeouts or failures.

The caller populates a `Trade.AdminPositionTbl` TVP with the position details (CID, InstrumentID, amounts, rates, etc.) and calls this procedure. The procedure copies input to a temp table with a clustered index on AdminPositionRequestID, then inserts only rows whose CID + AdminPositionRequestID combination does not already exist in AdminPositionLog with State IN (1, 2, 3) - meaning pending, in-progress, or completed states are protected from re-insertion.

---

## 2. Business Logic

### 2.1 Deduplication via State Check

**What**: Prevents duplicate admin position requests by checking existing State values.

**Columns/Parameters Involved**: `AdminPositionRequestID`, `CID`, `State`

**Rules**:
- LEFT JOIN to AdminPositionLog on CID + AdminPositionRequestID where State IN (1, 2, 3)
- Only inserts rows where the LEFT JOIN finds no match (APL.AdminPositionRequestID IS NULL)
- State values 1, 2, 3 represent active/in-progress states; requests in these states are protected
- State 0 or 4+ presumably represent failed/cancelled states and allow re-submission

### 2.2 OUTPUT Clause for Caller Feedback

**What**: Returns the newly created AdminPositionID and AdminPositionRequestID pairs.

**Columns/Parameters Involved**: `AdminPositionID` (identity), `AdminPositionRequestID`

**Rules**:
- OUTPUT inserted.AdminPositionID, inserted.AdminPositionRequestID returns the mapping to the caller
- Allows the caller to track which request IDs resulted in actual log entries

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @adminPositionTbl | Trade.AdminPositionTbl (TVP) | NO | READONLY | CODE-BACKED | Table-valued parameter with admin position request details. Key columns: AdminPositionRequestID (unique request ID), CID (customer), InstrumentID, OpenActionType, AmountInUnits, Amount, HedgeServerID, UserName (ops user), PositionID (target position if applicable), Rate, Cusip, ApexID, CompensationReasonID, OrderID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Trade.AdminPositionLog | INSERT (with dedup) | Creates admin position log entries for requests not already in active states |
| @adminPositionTbl | Trade.AdminPositionTbl | Parameter (TVP) | Input type definition for admin position data |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Admin API / Operations tool) | - | Caller | Called to create admin position records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AdminPositionCreate (procedure)
+-- Trade.AdminPositionLog (table)
+-- Trade.AdminPositionTbl (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionLog | Table | INSERT with deduplication - target for admin position records |
| Trade.AdminPositionTbl | User Defined Type | READONLY TVP parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Temp table index | Performance | Creates clustered index IX_AdminPositionCreate_AdminPositionRequestID on #InputTbl for efficient JOIN |

---

## 8. Sample Queries

### 8.1 Check recent admin position log entries

```sql
SELECT  TOP 20 AdminPositionID, AdminPositionRequestID, CID, InstrumentID,
        State, OpenActionType, Amount, AmountInUnits, UserName, RequestOccurred
FROM    Trade.AdminPositionLog WITH (NOLOCK)
ORDER BY AdminPositionID DESC;
```

### 8.2 Find admin positions by state

```sql
SELECT  AdminPositionID, CID, InstrumentID, State, FailReason
FROM    Trade.AdminPositionLog WITH (NOLOCK)
WHERE   State NOT IN (1, 2, 3)
ORDER BY AdminPositionID DESC;
```

### 8.3 Check for duplicate request IDs

```sql
SELECT  AdminPositionRequestID, CID, COUNT(*) AS EntryCount
FROM    Trade.AdminPositionLog WITH (NOLOCK)
GROUP BY AdminPositionRequestID, CID
HAVING COUNT(*) > 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AdminPositionCreate | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AdminPositionCreate.sql*
