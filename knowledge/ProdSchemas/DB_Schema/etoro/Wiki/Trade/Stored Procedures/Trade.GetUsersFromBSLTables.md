# Trade.GetUsersFromBSLTables

> Retrieves BSL (Balance Stop Loss) event history from both the live Trade.ManageBSL and archived History.ManageBSL tables, with a flag indicating whether the customer is currently blocked due to BSL.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate + @ToDate + @OperationID - time range and optional operation type filter |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUsersFromBSLTables` provides a unified view of BSL (Balance Stop Loss) events across both the live operational table (`Trade.ManageBSL`) and the historical archive (`History.ManageBSL`). BSL is eToro's automated risk protection mechanism that closes a customer's positions when their equity falls below a minimum threshold, protecting them from going into negative balance.

This procedure is used for reporting and investigation: given a time window and optional operation type filter, it returns who was hit by BSL events, what type of event it was, their total equity at the time, and whether they are currently still blocked (BlockReasonID=9, OperationTypeID=21 in Customer.BlockedCustomerOperations).

The UNION ALL across live + history tables ensures complete coverage - older events are moved to the History table over time but must be accessible together for audit trails.

---

## 2. Business Logic

### 2.1 Live + Historical BSL Event Union

**What**: Combines current and archived BSL records in a single result.

**Rules**:
- `Trade.ManageBSL`: current/recent BSL events
- `History.ManageBSL`: archived BSL events (older records moved here)
- UNION ALL (not UNION): preserves duplicates if any exist; both tables have identical column structure
- Both filtered by: `TimeMessageInsertedToQueue >= @FromDate AND < @ToDate AND (MessageType = @OperationID OR @OperationID IS NULL)`
- Default @FromDate = '20170501' (eToro BSL feature launch date), @ToDate = '20500101' (effectively unlimited)

### 2.2 Operation Type Filter

**What**: Optional filter on BSL event type.

**Rules**:
- `@OperationID IS NULL` = return all event types
- `@OperationID = N` = return only events of that MessageType/OperationID
- MessageType values are defined in `Dictionary.BSLMessageTypes` (e.g., warning, closure event, etc.)

### 2.3 TotalEquity Computation

**What**: Total equity at the time of the BSL event.

**Rules**:
- `RealizedEquity + UnRealizedEquity AS TotalEquity`
- Computed from the stored values at time of BSL event (point-in-time snapshot)
- BSLRealFunds: real (non-bonus) fund component at the time of the event

### 2.4 IsCurrentlyBlocked Flag

**What**: Whether the customer is CURRENTLY blocked due to BSL.

**Rules**:
- `LEFT JOIN Customer.BlockedCustomerOperations BCO ON BCO.CID = O.CID AND BCO.BlockReasonID = 9 AND BCO.OperationTypeID = 21`
- BlockReasonID=9: BSL block reason (specific to BSL-triggered blocks)
- OperationTypeID=21: copy trade block (BSL triggers a block on copy trading)
- `IsCurrentlyBlocked = IIF(BCO.CID IS NULL, 0, 1)`: 1 if currently blocked, 0 if block has been removed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | YES | '20170501' | CODE-BACKED | Start of time range for BSL event lookup. Defaults to BSL feature launch date (May 2017). ISNULL applied in WHERE. |
| 2 | @ToDate | DATETIME | YES | '20500101' | CODE-BACKED | End of time range (exclusive: <@ToDate). Defaults to far-future date (effectively no upper limit). |
| 3 | @OperationID | INT | YES | NULL | CODE-BACKED | Optional BSL MessageType filter. NULL = all event types. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | CID | INT | NO | - | CODE-BACKED | Customer who experienced the BSL event. |
| 5 | MessageType | INT | NO | - | CODE-BACKED | BSL event type code. FK to Dictionary.BSLMessageTypes.ID. |
| 6 | BSLOperation | VARCHAR | NO | - | CODE-BACKED | BSL event type description from Dictionary.BSLMessageTypes.MessageTypeDecstiption (note: typo in column name - "Desctition"). |
| 7 | WarningType | INT | YES | - | CODE-BACKED | Warning level/type for BSL warning events. |
| 8 | TimeMessageInsertedToQueue | DATETIME | NO | - | CODE-BACKED | Timestamp when the BSL event was triggered. |
| 9 | TotalEquity | MONEY | NO | - | CODE-BACKED | Customer's total equity (RealizedEquity + UnRealizedEquity) at time of BSL event. |
| 10 | BSLRealFunds | MONEY | YES | - | CODE-BACKED | Real (non-bonus) funds component at time of BSL event. |
| 11 | IsCurrentlyBlocked | BIT | NO | - | CODE-BACKED | 1 = customer currently has a BSL block (BlockReasonID=9, OperationTypeID=21 in BlockedCustomerOperations); 0 = block removed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CTE (live) | Trade.ManageBSL | FROM | Live/current BSL event records |
| CTE (archived) | History.ManageBSL | FROM | Archived BSL event records |
| JOIN | Dictionary.BSLMessageTypes | INNER JOIN | BSL operation type description |
| LEFT JOIN | Customer.BlockedCustomerOperations | LEFT JOIN | Current block status (BSL-specific: BlockReasonID=9, OperationTypeID=21) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (BSL reporting / support tools) | @FromDate, @ToDate | EXEC caller | BSL event investigation and audit |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUsersFromBSLTables (procedure)
+-- Trade.ManageBSL (table)
+-- History.ManageBSL (table)
+-- Dictionary.BSLMessageTypes (table)
+-- Customer.BlockedCustomerOperations (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ManageBSL | Table | Live BSL event records |
| History.ManageBSL | Table | Archived BSL event records |
| Dictionary.BSLMessageTypes | Table | BSL operation type name resolution |
| Customer.BlockedCustomerOperations | Table | Current BSL block status check |

### 6.2 Objects That Depend On This

No documented dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TimeMessageInsertedToQueue >= @FromDate | Range filter | ISNULL to '20170501' if not provided |
| TimeMessageInsertedToQueue < @ToDate | Range filter | Exclusive upper bound |
| BlockReasonID = 9 | Block filter | BSL-specific block reason |
| OperationTypeID = 21 | Block filter | Copy trade operation type for BSL blocks |

---

## 8. Sample Queries

### 8.1 All BSL events in the last 30 days
```sql
EXEC Trade.GetUsersFromBSLTables
    @FromDate = DATEADD(DAY, -30, GETUTCDATE()),
    @ToDate = GETUTCDATE(),
    @OperationID = NULL
```

### 8.2 Filter to a specific BSL operation type
```sql
EXEC Trade.GetUsersFromBSLTables
    @FromDate = '2026-01-01',
    @ToDate = '2026-03-17',
    @OperationID = 1  -- Replace with actual MessageType value
```

### 8.3 Check available BSL message types
```sql
SELECT ID, MessageTypeDecstiption FROM Dictionary.BSLMessageTypes WITH (NOLOCK)
ORDER BY ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. BSL history query not separately documented in TRAD/DB Confluence.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUsersFromBSLTables | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUsersFromBSLTables.sql*
