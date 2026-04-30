# Dictionary.TransactionStatuses

> Lookup table defining the top-level lifecycle states of money transfer transactions in the MoneyBus payment system.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (int, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.TransactionStatuses defines the high-level outcome categories for money transfer transactions. Every transaction in the MoneyBus system is assigned one of these five statuses throughout its lifecycle. The statuses represent a simple state machine: transactions start as InProcess and terminate in one of four final states (Success, Decline, Technical, or Canceled).

This table is the parent classification layer for the transaction lifecycle. While Dictionary.TransactionStatusReasons provides granular sub-states (e.g., HoldInitiated, CreditDecline), this table captures the top-level outcome that determines whether a transaction succeeded, failed, or was aborted. The MoneyBus alert system (ALERT_ConsecutiveTransactionFailuresAlert) JOINs this table to resolve status names for failure monitoring.

Data flow: This is a static reference table maintained via schema migrations. It is read by the alert procedure to display human-readable status names, and implicitly referenced by every transaction procedure that writes or filters on StatusID. The ID column is NOT IDENTITY - values are explicitly assigned, indicating these are well-known, stable identifiers.

---

## 2. Business Logic

### 2.1 Transaction Status State Machine

**What**: Transactions follow a deterministic lifecycle from creation to terminal state, with InProcess as the only non-terminal status.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- A transaction is created with StatusID=1 (InProcess) and remains there while fund movements are in flight
- StatusID=2 (Success) is the only positive terminal state - all hold/debit/credit steps completed
- StatusID=3 (Decline) means a business-rule rejection (hold failed, validation failed)
- StatusID=4 (Technical) means a system/infrastructure failure (timeout, connectivity)
- StatusID=5 (Canceled) means explicit cancellation (user, backoffice, or abort workflow)
- The ALERT procedure filters for StatusID=2 (Success) in the last 24 hours to detect consecutive failures

**Diagram**:
```
                    +---> [2] Success  (terminal - all steps completed)
                    |
[1] InProcess ------+---> [3] Decline  (terminal - business rule rejection)
                    |
                    +---> [4] Technical (terminal - system/infra failure)
                    |
                    +---> [5] Canceled  (terminal - explicit cancellation)
```

### 2.2 Parent-Child Status Hierarchy

**What**: TransactionStatuses is the parent tier; TransactionStatusReasons is the child tier providing step-level detail within each status.

**Columns/Parameters Involved**: `ID` (this table), `TransactionStatusID` (Dictionary.TransactionStatusReasons)

**Rules**:
- Each TransactionStatusReason maps to exactly one TransactionStatus via TransactionStatusID
- InProcess (1) has the most sub-reasons (Created, Held, Debited, Credited, various Initiated states, CreditDecline, DebitDecline)
- Decline (3) has HoldDecline and ValidateDecline (non-recoverable failures)
- Canceled (5) has HoldCanceled and ReconciliationAborted
- Success (2) and Technical (4) each have a single matching reason

---

## 3. Data Overview

| ID | Name | Meaning |
|----|------|---------|
| 1 | InProcess | Transaction is actively being processed through the hold-debit-credit pipeline. This is the only non-terminal state - the transaction may still succeed, fail, or be canceled depending on provider responses |
| 2 | Success | All fund movement steps completed successfully. The creditor account has been credited and the debitor account has been debited. Terminal positive outcome |
| 3 | Decline | Transaction rejected by business rules or payment provider. Typically triggered by insufficient funds (HoldDecline) or pre-execution validation failure (ValidateDecline). Terminal negative outcome |
| 4 | Technical | Transaction failed due to system-level error such as timeout, network connectivity, or unexpected exception. Distinguished from Decline because it is not a business-rule rejection. Terminal failure |
| 5 | Canceled | Transaction explicitly aborted - either by user request, backoffice intervention, or automated abort workflow (e.g., stale transaction cleanup via ReconciliationAborted). Terminal cancellation |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | VERIFIED | Primary key identifying each transaction status. Explicitly assigned (not IDENTITY). Referenced as StatusID in MoneyBus.Transactions and as TransactionStatusID in Dictionary.TransactionStatusReasons. Values: 1=InProcess, 2=Success, 3=Decline, 4=Technical, 5=Canceled. See [Transaction Status](../../_glossary.md#transaction-status) for full business definitions. |
| 2 | Name | nvarchar(50) | NO | - | CODE-BACKED | Human-readable status label. JOINed by ALERT_ConsecutiveTransactionFailuresAlert to display status names in alert output. Used for reporting and debugging visibility. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MoneyBus.Transactions | StatusID | Implicit Lookup | Current top-level lifecycle state of the transaction |
| Dictionary.TransactionStatusReasons | TransactionStatusID | Implicit FK | Parent status that each granular reason maps to |
| MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert | StatusID | JOIN | Resolves StatusID to Name for alert reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.TransactionStatusReasons | Table | TransactionStatusID references TransactionStatuses.ID (parent-child hierarchy) |
| MoneyBus.Transactions | Table | StatusID references TransactionStatuses.ID |
| MoneyBus.ALERT_ConsecutiveTransactionFailuresAlert | Stored Procedure | JOINs to resolve StatusID to human-readable Name |
| MoneyBus.TransactionAdd | Stored Procedure | Receives @StatusID parameter and INSERTs into Transactions |
| MoneyBus.TransactionUpdate | Stored Procedure | Receives @StatusID parameter and UPDATEs Transactions.StatusID |
| MoneyBus.TransactionsGetByParams | Stored Procedure | Filters by @StatusID when querying transactions |
| MoneyBus.UserTransactionsGet | Stored Procedure | Filters by @StatusID when querying user transactions |
| MoneyBus.TransactionStatusReasonsGet | Stored Procedure | Reads from TransactionStatusReasons which references this table |

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

### 8.1 List all transaction statuses
```sql
SELECT ID, Name
FROM Dictionary.TransactionStatuses WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Count transactions by status
```sql
SELECT ts.Name AS Status, COUNT(*) AS TransactionCount
FROM MoneyBus.Transactions t WITH (NOLOCK)
INNER JOIN Dictionary.TransactionStatuses ts WITH (NOLOCK) ON ts.ID = t.StatusID
GROUP BY ts.Name
ORDER BY TransactionCount DESC
```

### 8.3 View status reasons with their parent status
```sql
SELECT ts.Name AS ParentStatus, tsr.ID AS ReasonID, tsr.Name AS ReasonName
FROM Dictionary.TransactionStatusReasons tsr WITH (NOLOCK)
INNER JOIN Dictionary.TransactionStatuses ts WITH (NOLOCK) ON ts.ID = tsr.TransactionStatusID
ORDER BY ts.ID, tsr.ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.9/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.TransactionStatuses | Type: Table | Source: MoneyBusDB/Dictionary/Tables/Dictionary.TransactionStatuses.sql*
