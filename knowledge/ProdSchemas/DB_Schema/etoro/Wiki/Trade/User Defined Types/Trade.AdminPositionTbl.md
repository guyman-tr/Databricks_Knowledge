# Trade.AdminPositionTbl

> A table-valued parameter type for passing batches of admin-initiated position creation requests to Trade.AdminPositionCreate - used for compensations, corrections, and manual position management by internal staff.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | AdminPositionID (bigint), AdminPositionRequestID (uniqueidentifier) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

Trade.AdminPositionTbl is a table-valued parameter (TVP) type that carries admin-initiated position creation requests as a batch. Admin positions are special operations not triggered by normal user trading - they include compensations for platform errors, manual corrections by support staff, and regulatory adjustments. Each row represents one admin position request with full metadata for tracking and execution.

This type exists to enable bulk processing of admin operations. Without it, each admin position would require a separate procedure call. Operations staff use internal tools to populate this TVP and pass it to Trade.AdminPositionCreate, which processes the batch and creates or updates positions accordingly.

Data flow: Internal admin tools or batch jobs populate the TVP from a queue or manual entry, then call Trade.AdminPositionCreate. The procedure validates each row, applies business rules, and creates positions in the Trade schema. State, FailReason, and ErrorCode track execution outcome.

---

## 2. Business Logic

### 2.1 Admin Position Lifecycle

**What**: Each row represents an admin position request that moves through request, execution, and state tracking.

**Columns/Parameters Involved**: `AdminPositionRequestID`, `State`, `RequestOccurred`, `ExecutionOccurred`, `FailReason`, `ErrorCode`

**Rules**:
- RequestOccurred marks when the admin initiated the request; ExecutionOccurred when the system processed it
- State holds the current status; FailReason and ErrorCode capture failure details when State indicates failure
- AdminPositionRequestID links this row to a tracking record; AdminPositionID identifies the created position after success

**Diagram**:
```
Request (State=0?) -> Execution (State=1?) -> Success (PositionID set) / Failure (FailReason, ErrorCode set)
```

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AdminPositionID | bigint | YES | - | CODE-BACKED | Admin position record ID. Populated after successful creation; NULL when row is a new request. |
| 2 | AdminPositionRequestID | uniqueidentifier | YES | - | CODE-BACKED | Request tracking ID. Links this row to the originating admin request for audit trail. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer ID - the trading account receiving the admin position. References Customer.CustomerTbl. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | Instrument being traded. References Instrument.InstrumentTbl. |
| 5 | OpenActionType | int | NO | - | CODE-BACKED | How the position was opened. Lookup to operation/action type dictionary. |
| 6 | AdminPositionEventID | uniqueidentifier | YES | - | CODE-BACKED | Event ID for correlation with admin position event logging. |
| 7 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Position size in units (e.g., shares, lots). |
| 8 | Amount | money | YES | - | CODE-BACKED | Position size in currency amount. Alternative to units for amount-based instruments. |
| 9 | HedgeServerID | int | YES | - | CODE-BACKED | Which hedge server handles this position. Used for routing. |
| 10 | RequestOccurred | datetime | YES | - | CODE-BACKED | Timestamp when the admin initiated the request. |
| 11 | UserName | varchar(100) | YES | - | CODE-BACKED | Admin user who initiated the request. For audit. |
| 12 | ExecutionOccurred | datetime | YES | - | CODE-BACKED | Timestamp when the system executed the position creation. |
| 13 | PositionID | bigint | YES | - | CODE-BACKED | Created position ID after success. NULL until execution completes. References Trade.PositionTbl. |
| 14 | State | int | NO | - | CODE-BACKED | Request/execution state. 0=pending, 1=executed, 2=failed (typical; exact values from dictionary). |
| 15 | FailReason | varchar(100) | YES | - | CODE-BACKED | Human-readable failure reason when State indicates failure. |
| 16 | ErrorCode | int | YES | - | CODE-BACKED | System error code for programmatic handling of failures. |
| 17 | Cusip | varchar(100) | YES | - | ATLASSIAN-ONLY | CUSIP identifier for US securities. Used when instrument is identified by CUSIP. |
| 18 | ApexID | varchar(100) | YES | - | CODE-BACKED | Apex clearing broker account ID for US stock positions. |
| 19 | Rate | decimal(16,6) | YES | - | CODE-BACKED | Execution rate/price for the position. |
| 20 | RateTime | datetime | YES | - | CODE-BACKED | Timestamp when Rate was captured. |
| 21 | CheckBalance | bit | NO | - | CODE-BACKED | 1 = validate customer balance before creation; 0 = skip balance check (e.g., compensation). |
| 22 | IsComputeForHedge | bit | NO | - | CODE-BACKED | 1 = include in hedge computation; 0 = exclude from hedge calculations. |
| 23 | IsFunded | bit | NO | - | CODE-BACKED | 1 = position is funded; 0 = unfunded or pending funding. |
| 24 | CompensationReasonID | int | NO | - | CODE-BACKED | Reason for compensation/admin action. Lookup to compensation reason dictionary. |
| 25 | ValidatePositionWorth | bit | NO | - | CODE-BACKED | 1 = validate position value rules; 0 = skip worth validation. |
| 26 | OrderID | bigint | YES | - | CODE-BACKED | Associated order ID if this admin position links to an order. References Trade.OrderTbl. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerTbl | Implicit | Customer receiving the admin position |
| InstrumentID | Instrument.InstrumentTbl | Implicit | Instrument being traded |
| PositionID | Trade.PositionTbl | Implicit | Created position after success |
| OrderID | Trade.OrderTbl | Implicit | Linked order if applicable |
| HedgeServerID | Dictionary/Config | Lookup | Hedge server routing |
| OpenActionType | Dictionary | Lookup | Action type classification |
| CompensationReasonID | Dictionary | Lookup | Compensation reason |
| State | Dictionary | Lookup | Request state |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.AdminPositionCreate | @AdminPositions (or similar) | Parameter (TVP) | Consumes TVP to create admin positions in batch |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionCreate | Stored Procedure | READONLY parameter for batch admin position creation |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate AdminPositionTbl for a single compensation

```sql
DECLARE @AdminPositions Trade.AdminPositionTbl;
INSERT INTO @AdminPositions (CID, InstrumentID, OpenActionType, AmountInUnits, Amount,
    RequestOccurred, UserName, State, CheckBalance, IsComputeForHedge, IsFunded,
    CompensationReasonID, ValidatePositionWorth)
VALUES (12345, 789, 3, 100.0, 5000.00, GETUTCDATE(), 'admin@etoro.com', 0, 1, 1, 1, 2, 1);

EXEC Trade.AdminPositionCreate @AdminPositions = @AdminPositions;
```

### 8.2 Populate AdminPositionTbl from a staging table

```sql
DECLARE @AdminPositions Trade.AdminPositionTbl;
INSERT INTO @AdminPositions (AdminPositionRequestID, CID, InstrumentID, OpenActionType,
    AmountInUnits, Amount, RequestOccurred, UserName, State, CheckBalance,
    IsComputeForHedge, IsFunded, CompensationReasonID, ValidatePositionWorth)
SELECT  AdminPositionRequestID, CID, InstrumentID, OpenActionType, AmountInUnits, Amount,
        RequestOccurred, UserName, 0, 1, 1, 1, CompensationReasonID, 1
FROM    Staging.AdminPositionQueue WITH (NOLOCK)
WHERE   Processed = 0;

EXEC Trade.AdminPositionCreate @AdminPositions = @AdminPositions;
```

### 8.3 Pass empty TVP for procedure validation

```sql
DECLARE @AdminPositions Trade.AdminPositionTbl;
EXEC Trade.AdminPositionCreate @AdminPositions = @AdminPositions;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 9/10, Logic: 7/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 22 CODE-BACKED, 4 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AdminPositionTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.AdminPositionTbl.sql*
