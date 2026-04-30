# Trade.AdminPositionLog

> Audit log of all administrative position operations (open/close/compensate), tracking the request lifecycle from creation through execution or rejection.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | AdminPositionID (BIGINT IDENTITY, PK CLUSTERED) |
| **Partition** | No (DICTIONARY filegroup) |
| **Indexes** | 8 active (all PAGE compressed) |

---

## 1. Business Meaning

This table records every administrative position operation - positions opened or closed by internal tools, automated processes, or compensation workflows rather than by the customer directly. Each row is a log entry capturing the full context of the request: who initiated it, what instrument and amount, whether it succeeded or failed, and the resulting position ID.

Admin positions serve many business purposes: compensating customers for technical issues, stock dividend airdrops, corporate actions, ACATS transfers, staking rewards, operational adjustments, and more. Without this table, there would be no audit trail for these non-customer-initiated trading operations, making compliance reporting and error investigation impossible.

Rows are created by `Trade.AdminPositionCreate` which accepts a TVP (Table-Valued Parameter) of admin position requests, deduplicates by CID + RequestID, and inserts with an initial State. The State is then updated by `Trade.SetAdminPositionState` (to Placed/Filled) or `Trade.SetAdminPositionFailInfo` (to record failure details). Multiple reader procedures provide lookups by AdminPositionID, PositionID, RequestID, and CID.

---

## 2. Business Logic

### 2.1 Request State Machine

**What**: Each admin position request progresses through a defined lifecycle of states.

**Columns/Parameters Involved**: `State`, `ErrorCode`, `FailReason`

**Rules**:
- State 1 (Pending): Request created, not yet sent for execution
- State 2 (Placed): Request sent to execution engine - only valid if no other request for same CID+RequestID is already in State 2 or 3
- State 3 (Filled): Position successfully opened, `PositionID` populated
- State 4 (Rejected): Request failed, `ErrorCode` and `FailReason` populated
- Transition 1->2 is guarded: only one pending entry per CID+RequestID can be placed at a time
- Transition 1->4 bypasses Placed state when rejected before submission

**Diagram**:
```
[Pending (1)] --SetAdminPositionState(@NewState=2)--> [Placed (2)]
     |                                                      |
     |                                                      v
     |                                                [Filled (3)]
     |
     +----SetAdminPositionState(@NewState=4)----------> [Rejected (4)]
```

### 2.2 Deduplication Guard

**What**: The INSERT logic prevents duplicate admin positions for the same request.

**Columns/Parameters Involved**: `CID`, `AdminPositionRequestID`, `State`

**Rules**:
- `AdminPositionCreate` performs a LEFT JOIN to existing rows with same CID + AdminPositionRequestID where State IN (1,2,3)
- Only inserts rows where no active/completed match exists (IS NULL check)
- This prevents double-execution of the same compensation request

---

## 3. Data Overview

| AdminPositionID | CID | InstrumentID | OpenActionType | State | AmountInUnits | UserName | Meaning |
|---|---|---|---|---|---|---|---|
| 14633774 | 24713264 | 100001 | 13 (ACATS_IN) | 3 (Filled) | 0.01 | 24713264 | Automated ACATS transfer in - crypto position successfully opened via external brokerage transfer |
| 14633770 | 24713264 | 100001 | 13 (ACATS_IN) | 3 (Filled) | 0.01 | 24713264 | Another ACATS-IN for same customer - recurring automated asset transfers from external broker |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AdminPositionID | bigint IDENTITY(3747184,1) | NO | - | CODE-BACKED | Auto-generated surrogate key. IDENTITY seed 3747184 indicates this table was re-seeded after data migration from AdminPositionLogOLD. |
| 2 | AdminPositionRequestID | uniqueidentifier | YES | - | CODE-BACKED | Correlation GUID grouping multiple admin position entries from the same batch request. Used for deduplication (CID + RequestID prevents duplicate execution) and for lookups via `GetAdminPositionLogByRequestID`. |
| 3 | CID | int | NO | - | CODE-BACKED | Customer identifier for the account receiving the admin position. Implicit FK to Customer.CustomerStatic. Indexed for lookup performance. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument for the position. Implicit FK to Trade.Instrument. |
| 5 | OpenActionType | int | NO | - | VERIFIED | Why this admin position was created. Maps to Dictionary.OpenPositionActionType: 0=Customer, 1=Hierarchical Open, 2=Reopen, 3=Open Open, 4=Stock Dividend, 5=Corporate Action, 6=Technical Issue, 7=Operational position adjustment, 8=Add Funds, 9=Reinvestment, 10=Admin, 11=Stacking, 12=Promotion, 13=ACATS_IN, 14=ReedemForNFT, 15=Technical, 16=Alignment, 17=Recurring Investment. Most common: 11 (Stacking). |
| 6 | AdminPositionEventID | uniqueidentifier | YES | - | CODE-BACKED | Event correlation ID for the position creation event in the distributed system. Indexed for event-based lookups. |
| 7 | AmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Number of units/shares for the position. NULL when amount is specified in monetary terms instead. |
| 8 | Amount | money | YES | - | CODE-BACKED | Monetary amount for the position. NULL when amount is specified in units instead. Mutually exclusive with AmountInUnits for most action types. |
| 9 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server assigned to execute this position. Implicit FK to Trade.HedgeServer. NULL for positions that don't require hedging. |
| 10 | RequestOccurred | datetime | NO | - | CODE-BACKED | UTC timestamp when the admin position request was created. Indexed for time-range queries and monitoring. |
| 11 | UserName | varchar(100) | YES | - | CODE-BACKED | Username of the operator who initiated the request. For automated processes, often contains the CID as a string. |
| 12 | ExecutionOccurred | datetime | YES | - | CODE-BACKED | UTC timestamp when the position was actually executed (filled). NULL for pending or rejected requests. Indexed for execution monitoring. |
| 13 | PositionID | bigint | YES | - | CODE-BACKED | The resulting position ID in Trade.PositionTbl after successful execution. NULL until State=3 (Filled). Indexed for reverse lookups from position to admin request. |
| 14 | State | int | NO | - | VERIFIED | Current lifecycle state: 1=Pending (created), 2=Placed (sent to execution), 3=Filled (succeeded), 4=Rejected (failed). Source: Dictionary.AdminPositionState. Most rows are State 4 (Rejected, 63%) or State 3 (Filled, 35%). |
| 15 | FailReason | varchar(8000) | YES | - | CODE-BACKED | Human-readable error description when State=4 (Rejected). Set by `SetAdminPositionFailInfo`. NULL for non-failed requests. |
| 16 | ErrorCode | int | YES | - | CODE-BACKED | Numeric error code when State=4 (Rejected). Set by `SetAdminPositionState` or `SetAdminPositionFailInfo`. NULL for non-failed requests. |
| 17 | Cusip | varchar(100) | YES | - | NAME-INFERRED | CUSIP identifier for US securities. Used for ACATS transfers and US regulatory reporting. |
| 18 | ApexID | varchar(100) | YES | - | NAME-INFERRED | Apex Clearing account/transaction identifier for US brokerage integration. |
| 19 | Rate | decimal(16,6) | YES | - | CODE-BACKED | Execution rate/price for the position. NULL until execution occurs. |
| 20 | RateTime | datetime | YES | - | CODE-BACKED | Timestamp of the rate used for execution. May differ from ExecutionOccurred if rate was captured earlier. |
| 21 | CheckBalance | bit | NO | - | CODE-BACKED | Whether to validate the customer has sufficient balance before opening the position. 0=Skip balance check (common for compensations), 1=Enforce balance check. |
| 22 | IsComputeForHedge | bit | NO | - | CODE-BACKED | Whether this position should be included in hedge exposure calculations. 0=Exclude from hedging, 1=Include in hedging. |
| 23 | IsFunded | bit | NO | - | CODE-BACKED | Whether this is a funded (real asset) position vs a CFD. 1=Funded/real, 0=CFD. |
| 24 | CompensationReasonID | int | NO | - | CODE-BACKED | Reason code for the compensation or admin action. Sourced from Dictionary.CorporateAction.CompensationReasonID in airdrop flows. Most common: 91 (91% of rows). |
| 25 | ValidatePositionWorth | bit | NO | - | CODE-BACKED | Whether to validate minimum position value before opening. 0=Skip validation, 1=Enforce minimum worth check. |
| 26 | CompensationCreditID | bigint | YES | - | NAME-INFERRED | Credit entry ID linking this admin position to a compensation credit record. Added after AdminPositionLogOLD was archived (not present in OLD table). |
| 27 | OrderID | bigint | YES | - | CODE-BACKED | Associated order ID in Trade.Orders for this admin position. Added after AdminPositionLogOLD was archived. Indexed for order-based lookups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit FK | Customer receiving the admin position |
| InstrumentID | Trade.Instrument | Implicit FK | Financial instrument being traded |
| HedgeServerID | Trade.HedgeServer | Implicit FK | Hedge server executing the position |
| OpenActionType | Dictionary.OpenPositionActionType | Implicit Lookup | Why this admin operation was performed |
| State | Dictionary.AdminPositionState | Implicit Lookup | Current lifecycle state of the request |
| PositionID | Trade.PositionTbl | Implicit FK | Resulting position after successful execution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.AdminPositionCreate | @adminPositionTbl | WRITER | Bulk-inserts admin position requests from TVP |
| Trade.SetAdminPositionState | @AdminPositionID | MODIFIER | Updates State to Placed/Rejected |
| Trade.SetAdminPositionFailInfo | @AdminPositionID | MODIFIER | Records failure details |
| Trade.GetAdminPositionLogByAdminPositionID | AdminPositionID | READER | Lookup by admin position ID |
| Trade.GetAdminPositionLogByPositionID | PositionID | READER | Reverse lookup from position |
| Trade.GetAdminPositionLogByRequestID | AdminPositionRequestID | READER | Lookup by request correlation ID |
| Trade.GetAdminPositionsWithCID | CID | READER | All admin positions for a customer |
| Trade.GetAdminPositionsWithoutCID | - | READER | Admin positions without CID filter |
| Trade.AdminPositionOpen | - | READER | Position open workflow |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no hard dependencies (no explicit FKs defined in DDL).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.AdminPositionCreate | Stored Procedure | WRITER - inserts admin position log entries |
| Trade.SetAdminPositionState | Stored Procedure | MODIFIER - updates State column |
| Trade.SetAdminPositionFailInfo | Stored Procedure | MODIFIER - sets FailReason and ErrorCode |
| Trade.GetAdminPositionLogByAdminPositionID | Stored Procedure | READER |
| Trade.GetAdminPositionLogByPositionID | Stored Procedure | READER |
| Trade.GetAdminPositionLogByRequestID | Stored Procedure | READER |
| Trade.GetAdminPositionsWithCID | Stored Procedure | READER |
| Trade.GetAdminPositionsWithoutCID | Stored Procedure | READER |
| Trade.AdminPositionOpen | Stored Procedure | READER - checks existing state |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Trade_AdminPositionLog_AdminPositionID | CLUSTERED PK | AdminPositionID ASC | - | - | Active (PAGE compressed) |
| IX_AdminPositionLog_AdminPositionEventID | NC | AdminPositionEventID ASC | - | - | Active (PAGE compressed) |
| IX_AdminPositionLog_AdminPositionRequestID_CID | NC | AdminPositionRequestID ASC, CID ASC | - | - | Active (PAGE compressed) |
| IX_AdminPositionLog_CID | NC | CID ASC | - | - | Active (PAGE compressed) |
| IX_AdminPositionLog_OpenActionType | NC | OpenActionType ASC | - | - | Active (PAGE compressed) |
| IX_AdminPositionLog_OrderID | NC | OrderID ASC | - | - | Active (FILLFACTOR 100) |
| IX_AdminPositionLog_PositionID | NC | PositionID ASC | - | - | Active (PAGE compressed) |
| IX_AdminPositionLog_RequestOccurred | NC | RequestOccurred ASC | - | - | Active (PAGE compressed) |
| IX_ExecutionOccurred | NC | ExecutionOccurred ASC | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None (no CHECK, DEFAULT, or UNIQUE constraints defined).

---

## 8. Sample Queries

### 8.1 Get admin position log for a specific customer
```sql
SELECT  apl.AdminPositionID,
        apl.CID,
        i.InstrumentDisplayName,
        oat.OpenPositionActionName,
        aps.State AS StateName,
        apl.AmountInUnits,
        apl.RequestOccurred,
        apl.ExecutionOccurred,
        apl.PositionID
FROM    Trade.AdminPositionLog apl WITH (NOLOCK)
JOIN    Trade.Instrument i WITH (NOLOCK) ON apl.InstrumentID = i.InstrumentID
JOIN    Dictionary.OpenPositionActionType oat WITH (NOLOCK) ON apl.OpenActionType = oat.ID
JOIN    Dictionary.AdminPositionState aps WITH (NOLOCK) ON apl.State = aps.Id
WHERE   apl.CID = @CID
ORDER BY apl.RequestOccurred DESC
```

### 8.2 Find failed admin positions with error details
```sql
SELECT  apl.AdminPositionID,
        apl.CID,
        apl.InstrumentID,
        apl.ErrorCode,
        apl.FailReason,
        apl.RequestOccurred
FROM    Trade.AdminPositionLog apl WITH (NOLOCK)
WHERE   apl.State = 4
        AND apl.RequestOccurred >= DATEADD(DAY, -1, GETUTCDATE())
ORDER BY apl.RequestOccurred DESC
```

### 8.3 Check if a request was already processed (dedup check)
```sql
SELECT  apl.AdminPositionID,
        apl.State,
        aps.State AS StateName
FROM    Trade.AdminPositionLog apl WITH (NOLOCK)
JOIN    Dictionary.AdminPositionState aps WITH (NOLOCK) ON apl.State = aps.Id
WHERE   apl.CID = @CID
        AND apl.AdminPositionRequestID = @RequestID
        AND apl.State IN (1, 2, 3)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 9.3/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 21 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AdminPositionLog | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.AdminPositionLog.sql*
