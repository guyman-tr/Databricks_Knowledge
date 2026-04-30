# Dictionary.TransferStatus

> Lookup table defining the lifecycle states of money transfer transactions, from initial creation through processing to final resolution (success, failure, or cancellation).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.TransferStatus is the canonical reference table for transfer lifecycle states in the MoneyTransfer system. Each row defines a discrete stage that a money transfer can occupy during its journey from creation to completion. The table enables the system to classify, filter, and report on transfers by their current processing state.

Without this table, the system would rely on magic numbers scattered across stored procedures, making status logic opaque and maintenance-prone. The centralized lookup provides a single authoritative source for status names and descriptions, used by both operational queries and monitoring dashboards.

Rows are static reference data - they are not created or modified by application procedures. The Monitoring schema's `GetLastTransfersStatusesInPercentage` procedure LEFT JOINs to this table to produce status distribution reports across all defined statuses (including those with zero current transfers). Billing procedures reference TransferStatusID values directly via hardcoded integer constants rather than joining to this table.

---

## 2. Business Logic

### 2.1 Transfer Lifecycle State Machine

**What**: Defines the progression of a money transfer from creation through to terminal state.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- Status 0 (New) is the entry point - `Billing.CreateTransfer` inserts with `TransferStatusID = 0`
- The happy path follows: New(0) -> Init(1) -> Pending(2) -> Sent(9) -> Received(10)
- Failure branches diverge from intermediate states: Technical(4), Cancel(7), Fail(8)
- Status 10 (Received) is a hard terminal state - `Billing.UpdateTransferStatus` throws error 50000 if attempting to change a transfer already in Received status
- Statuses 9 (Sent) and 10 (Received) are both treated as "success" states in queries like `GetLastSuccessTransferDataByCid` which uses `WHERE TransferStatusID IN (9,10)`
- Status 10 (Received) alone is the definitive "successful" check in `GetDepotIdOfLastSuccessfulTransferByCid` which uses `WHERE TransferStatusID = 10`

**Diagram**:
```
New(0) --> Init(1) --> Pending(2) --> Sent(9) --> Received(10) [TERMINAL SUCCESS]
              |            |
              |            +--> Technical(4) [TERMINAL FAILURE]
              |            |
              +--> Cancel(7) [TERMINAL]
              |
              +--> Fail(8) [TERMINAL FAILURE]

Note: IDs 3, 5, 6 are unassigned (gaps in sequence - possibly deprecated)
```

---

## 3. Data Overview

| ID | Name | Description | Meaning |
|----|------|-------------|---------|
| 0 | New | NULL | Initial state when a transfer record is first created via `Billing.CreateTransfer`. No processing has begun - the transfer exists only as a database record. |
| 1 | Init | NULL | Transfer initialization has started. Provider setup and funding source validation are underway. Intermediate state before the transfer enters the payment processing pipeline. |
| 2 | Pending | NULL | Transfer has been validated and submitted for processing. Awaiting confirmation from the payment provider or destination system. The system is waiting on an external response. |
| 4 | Technical | NULL | Transfer encountered a technical infrastructure error (connectivity, timeout, system issue) distinct from a business-logic rejection. May warrant investigation by operations team. |
| 7 | Cancel | NULL | Transfer was cancelled before completion - either by user request or by a system rule. Terminal state; the transfer will not proceed and no funds were moved. |
| 8 | Fail | NULL | Transfer failed during processing due to a business-level rejection (insufficient funds, invalid destination, compliance block). Terminal failure - requires user to retry with corrected data. |
| 9 | Sent | NULL | Transfer has been dispatched to the destination provider. Funds are in transit but receipt has not yet been confirmed. Near-terminal success state. |
| 10 | Received | NULL | Transfer completed successfully - funds confirmed at destination. Hard terminal state: `UpdateTransferStatus` blocks any further status changes to prevent accidental reopening. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | VERIFIED | Unique identifier for each transfer status. Auto-incremented but with intentional gaps (3, 5, 6 unassigned). Used as the FK target by `Billing.Transfers.TransferStatusID` and `History.Transfers.TransferStatusID`. Values: 0=New, 1=Init, 2=Pending, 4=Technical, 7=Cancel, 8=Fail, 9=Sent, 10=Received. See [Transfer Status](../../_glossary.md#transfer-status) for full business definitions. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable label for the status. Used in monitoring queries (`Monitoring.GetLastTransfersStatusesInPercentage`) as the display name in status distribution reports. Values are single-word English descriptors matching the business lifecycle stage. |
| 3 | Description | varchar(100) | YES | - | CODE-BACKED | Optional extended description of the status. Currently NULL for all 8 rows - status meanings are conveyed through Name values and are well-understood from SP logic (e.g., code comment `TransferStatusID = 10 --Received` in `UpdateTransferStatus`). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Transfers | TransferStatusID | Implicit FK (Lookup) | Current lifecycle status of each transfer. Set to 0 on creation, updated by UpdateTransferStatus. Indexed alongside CurrencyID for query performance. |
| History.Transfers | TransferStatusID | Implicit FK (Lookup) | System-versioned history of Billing.Transfers - preserves the TransferStatusID at each point in time for audit trail. |
| Monitoring.GetLastTransfersStatusesInPercentage | ts.ID = BT.TransferStatusID | Direct JOIN | LEFT JOINs to produce percentage distribution of transfer statuses within a configurable time window. Uses all status rows to show zero-count statuses. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Transfers | Table | TransferStatusID column references this lookup (implicit FK) |
| History.Transfers | Table | TransferStatusID column references this lookup (system-versioned copy) |
| Billing.CreateTransfer | Stored Procedure | Sets TransferStatusID = 0 (New) on INSERT |
| Billing.UpdateTransferStatus | Stored Procedure | Updates TransferStatusID; blocks changes from status 10 (Received) |
| Billing.GetDepotIdOfLastSuccessfulTransferByCid | Stored Procedure | Filters by TransferStatusID = 10 (Received = success) |
| Billing.GetLastDepotIdForTransferStatusesByCid | Stored Procedure | Filters by dynamic list of allowed TransferStatusID values |
| Billing.GetLastSuccessTransferDataByCid | Stored Procedure | Filters by TransferStatusID IN (9,10) (success states) |
| Billing.GetTransferByExReference | Stored Procedure | Returns TransferStatusID in result set |
| Billing.GetTransferByReferenceID | Stored Procedure | Returns TransferStatusID in result set |
| Billing.GetTransfersByCID | Stored Procedure | Returns TransferStatusID in result set |
| Monitoring.GetLastTransfersStatusesInPercentage | Stored Procedure | JOINs directly to get status Name for distribution report |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK (unnamed) | CLUSTERED | ID ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all transfer statuses
```sql
SELECT ID, Name, Description
FROM Dictionary.TransferStatus WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Get transfer count per status for a time window
```sql
SELECT ts.Name AS Status, COUNT(bt.TransferID) AS TransferCount
FROM Dictionary.TransferStatus ts WITH (NOLOCK)
LEFT JOIN Billing.Transfers bt WITH (NOLOCK) ON ts.ID = bt.TransferStatusID
    AND bt.CreateDate >= DATEADD(HOUR, -1, GETUTCDATE())
GROUP BY ts.Name
ORDER BY TransferCount DESC
```

### 8.3 Find all successful transfers for a customer
```sql
SELECT bt.TransferID, bt.ReferenceID, bt.Amount, bt.CurrencyID,
       ts.Name AS StatusName, bt.CreateDate, bt.ModificationDate
FROM Billing.Transfers bt WITH (NOLOCK)
JOIN Dictionary.TransferStatus ts WITH (NOLOCK) ON bt.TransferStatusID = ts.ID
WHERE bt.CID = @CID AND bt.TransferStatusID IN (9, 10)
ORDER BY bt.TransferID DESC
```

---

## 9. Atlassian Knowledge Sources

No dedicated Atlassian sources found for this object. General MoneyTransfer pages exist but do not describe the TransferStatus lookup table specifically.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 10.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 11 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TransferStatus | Type: Table | Source: MoneyTransfer/Dictionary/Tables/Dictionary.TransferStatus.sql*
