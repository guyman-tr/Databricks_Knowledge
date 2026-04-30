# Trade.GetAdminPositionLogByAdminPositionID

> Retrieves a single admin position log entry by its unique AdminPositionID.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all columns from Trade.AdminPositionLog for a specific admin position |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a specific admin position log record by its primary key (AdminPositionID). Admin positions are manually-initiated position operations performed by back-office administrators or automated compensation systems - such as opening a position for a customer as part of a compensation workflow, funding an account position, or opening a hedging position.

The procedure exists to support the admin position management UI and audit workflows. When an admin or support agent needs to review the details of a specific admin position operation (including its execution state, fail reason, and related identifiers), this procedure provides the complete record.

Data flows from Trade.AdminPositionLog, which stores the full lifecycle of admin-initiated position operations including the request, execution, and outcome.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple primary key lookup returning all columns from Trade.AdminPositionLog.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AdminPositionID | BIGINT | NO | - | CODE-BACKED | Primary key of the admin position log entry to retrieve. |

**Output columns (all from Trade.AdminPositionLog):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | AdminPositionID | BIGINT | NO | - | CODE-BACKED | Unique identifier of the admin position operation. |
| 3 | AdminPositionRequestID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | GUID linking this log entry to the originating admin request. Multiple log entries may share the same request ID for batch operations. |
| 4 | CID | INT | YES | - | CODE-BACKED | Customer ID for whom the admin position was created. |
| 5 | InstrumentID | INT | YES | - | CODE-BACKED | Financial instrument of the admin position. |
| 6 | OpenActionType | INT | YES | - | CODE-BACKED | Type of admin open action (e.g., compensation, manual open, hedge). |
| 7 | AdminPositionEventID | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Event identifier linking to the broader admin action event. |
| 8 | AmountInUnits | DECIMAL | YES | - | CODE-BACKED | Number of units for the admin position. |
| 9 | Amount | MONEY | YES | - | CODE-BACKED | Monetary amount for the admin position. |
| 10 | HedgeServerID | INT | YES | - | CODE-BACKED | Hedge server that executed the position. |
| 11 | RequestOccurred | DATETIME | YES | - | CODE-BACKED | When the admin request was submitted. |
| 12 | UserName | VARCHAR | YES | - | CODE-BACKED | Admin user who initiated the request. |
| 13 | ExecutionOccurred | DATETIME | YES | - | CODE-BACKED | When the position was actually executed/filled. |
| 14 | PositionID | BIGINT | YES | - | CODE-BACKED | The resulting trading position ID (NULL if not yet executed or failed). |
| 15 | State | INT | YES | - | CODE-BACKED | Current state of the admin position operation. |
| 16 | FailReason | VARCHAR | YES | - | CODE-BACKED | Human-readable reason if the operation failed. |
| 17 | ErrorCode | INT | YES | - | CODE-BACKED | Numeric error code if the operation failed. |
| 18 | Cusip | VARCHAR | YES | - | CODE-BACKED | CUSIP identifier for US securities (DMA/real stock operations). |
| 19 | ApexID | VARCHAR | YES | - | CODE-BACKED | Apex Clearing identifier for DMA operations. |
| 20 | Rate | DECIMAL | YES | - | CODE-BACKED | Execution rate/price for the position. |
| 21 | RateTime | DATETIME | YES | - | CODE-BACKED | Time of the rate/price used for execution. |
| 22 | CheckBalance | BIT | YES | - | CODE-BACKED | Whether balance validation was required before opening. |
| 23 | IsComputeForHedge | BIT | YES | - | CODE-BACKED | Whether this position contributes to hedge calculations. |
| 24 | IsFunded | BIT | YES | - | CODE-BACKED | Whether the position is funded (has actual money backing). |
| 25 | CompensationReasonID | INT | YES | - | CODE-BACKED | Reason for compensation if this is a compensation position. FK to BackOffice.CompensationReason. |
| 26 | ValidatePositionWorth | BIT | YES | - | CODE-BACKED | Whether the position's worth should be validated before processing. |
| 27 | CompensationCreditID | BIGINT | YES | - | CODE-BACKED | Link to the credit record if this position was opened as part of compensation. |
| 28 | OrderID | BIGINT | YES | - | CODE-BACKED | Associated order ID if the admin position went through the order pipeline. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.AdminPositionLog | Direct Read | Reads admin position log entries |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | - |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAdminPositionLogByAdminPositionID (procedure)
└── Trade.AdminPositionLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionLog | Table | SELECT with NOLOCK - primary key lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SQL repo | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Look up a specific admin position

```sql
EXEC Trade.GetAdminPositionLogByAdminPositionID @AdminPositionID = 12345;
```

### 8.2 Find admin positions by state

```sql
SELECT  AdminPositionID,
        CID,
        State,
        FailReason,
        RequestOccurred
FROM    Trade.AdminPositionLog WITH (NOLOCK)
WHERE   State != 0
    AND RequestOccurred >= DATEADD(DAY, -1, GETUTCDATE());
```

### 8.3 Find admin positions with their resulting trades

```sql
SELECT  apl.AdminPositionID,
        apl.CID,
        apl.InstrumentID,
        apl.PositionID,
        apl.Rate,
        apl.UserName,
        apl.RequestOccurred
FROM    Trade.AdminPositionLog apl WITH (NOLOCK)
WHERE   apl.PositionID IS NOT NULL
    AND apl.CID = 12345678
ORDER BY apl.RequestOccurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 5/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 28 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAdminPositionLogByAdminPositionID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAdminPositionLogByAdminPositionID.sql*
