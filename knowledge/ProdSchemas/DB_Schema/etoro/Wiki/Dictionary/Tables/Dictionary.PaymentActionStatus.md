# Dictionary.PaymentActionStatus

> Lookup table defining the 3-state lifecycle of payment actions — New, InProcess, and Closed — tracking each payment operation from initiation through completion.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PaymentActionStatusID (INT, PK NONCLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Row Count** | 3 (MCP verified) |
| **Indexes** | 2 active (PK nonclustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.PaymentActionStatus defines the lifecycle states for individual payment actions recorded in History.PaymentAction and History.DepositAction. A payment action represents a single step in a payment transaction — such as a pre-authorization, purchase, refund, or cancellation. Each action progresses through these three statuses as it is created, processed, and finalized.

When a deposit is initiated (Billing.DepositAdd), a payment action is created with status New (1). As the PSP (Payment Service Provider) processes the action, it transitions to InProcess (2). Once the action completes — whether successfully or with a failure — it moves to Closed (3). This simple state machine is the backbone of payment action tracking and audit trails.

The table is heavily referenced across the Billing schema: deposit processing, cancellation, rollback, and PayPal flows all write PaymentActionStatusID into action history records.

---

## 2. Business Logic

### 2.1 Payment Action Lifecycle

**What**: The three-stage lifecycle every payment action passes through.

**Columns/Parameters Involved**: `PaymentActionStatusID`, `Name`

**Rules**:
- **New (1)**: Initial state when a payment action is first created. The action has been recorded but processing has not yet begun. Set by Billing.PaymentActionAdd, Billing.DepositAdd, and related procedures.
- **InProcess (2)**: The action is actively being processed by the PSP or internal systems. Transitional state between creation and completion.
- **Closed (3)**: Terminal state — the action has completed processing. This applies regardless of whether the outcome was success or failure; the action itself is finalized. Used explicitly in Billing.DepositsCancelByLastDays and Billing.PaymentByPayPalProcess when closing out actions.

**Diagram**:
```
Payment Action Lifecycle:
  New (1) ──► InProcess (2) ──► Closed (3)
    │                              ▲
    └──────────────────────────────┘
         (direct close on cancel/reject)
```

### 2.2 Usage in Deposit Flows

**What**: How PaymentActionStatusID is set across different deposit operations.

**Columns/Parameters Involved**: `PaymentActionStatusID`

**Rules**:
- **Billing.DepositAdd**: Creates initial payment action with status 1 (New)
- **Billing.DepositUpdate**: Updates action status via @PaymentActionStatusID parameter
- **Billing.DepositCancel / BackOffice.DepositCancel**: Writes action with appropriate closing status
- **Billing.DepositRollback**: Records rollback action with closing status
- **Billing.DepositsCancelByLastDays**: Bulk cancellation sets status to 3 (Closed)
- **Billing.PaymentByPayPalProcess**: PayPal postback closes action with status 3

---

## 3. Data Overview

| PaymentActionStatusID | Name | Meaning |
|---|---|---|
| 1 | New | Payment action has been created but not yet sent to PSP for processing. Initial state for all payment actions. Deposit add procedures insert actions with this status. |
| 2 | InProcess | Payment action is actively being processed by the PSP or internal payment engine. Intermediate state between creation and finalization. |
| 3 | Closed | Payment action processing is complete. Terminal state regardless of success/failure. Bulk cancellation and PayPal postback flows explicitly set this status. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentActionStatusID | int | NO | - | VERIFIED | Primary key identifying the action lifecycle state. 1=New (created), 2=InProcess (being processed), 3=Closed (finalized). Referenced by History.PaymentAction (explicit FK) and History.DepositAction. Written by all deposit/payment action procedures in the Billing schema. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable status name. Unique constraint prevents duplicates. Values: 'New', 'InProcess', 'Closed'. Used in payment dashboards, audit reports, and debugging. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PaymentAction | PaymentActionStatusID | Explicit FK (FK_DPAS_HPMA) | Every payment action record stores its lifecycle state |
| History.DepositAction | PaymentActionStatusID | Implicit | Deposit-specific action history tracks status |
| Billing.PaymentActionAdd | @PaymentActionStatusID | Parameter | Creates new payment actions with specified status |
| Billing.PaymentActionUpdate | @PaymentActionStatusID | Parameter | Updates existing payment action status |
| Billing.DepositAdd | PaymentActionStatusID | INSERT literal 1 | New deposits start with status New |
| Billing.DepositUpdate | @PaymentActionStatusID | Parameter | Deposit updates write new action status |
| Billing.DepositProcess | PaymentActionStatusID | INSERT | Deposit processing writes action status |
| Billing.DepositActionAdd | @PaymentActionStatusID | Parameter | Adds deposit action with specified status |
| Billing.DepositCancel | PaymentActionStatusID | INSERT | Cancellation records action with closing status |
| Billing.DepositRollback | PaymentActionStatusID | INSERT | Rollback records action status |
| Billing.DepositPendingCancel | PaymentActionStatusID | INSERT | Pending cancellation writes action status |
| Billing.DepositsCancelByLastDays | PaymentActionStatusID | INSERT literal 3 | Bulk cancel sets status to Closed |
| Billing.PaymentByPayPalProcess | PaymentActionStatusID | INSERT literal 3 | PayPal postback closes action |
| BackOffice.DepositCancel | PaymentActionStatusID | INSERT | Back-office cancellation writes action status |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.PaymentActionStatus (table)
  └── referenced by History.PaymentAction (FK_DPAS_HPMA)
  └── referenced by History.DepositAction (implicit)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PaymentAction | Table | FK constraint on PaymentActionStatusID |
| History.DepositAction | Table | Stores PaymentActionStatusID per deposit action |
| Billing.PaymentActionAdd | Stored Procedure | Creates actions with specified status |
| Billing.PaymentActionUpdate | Stored Procedure | Updates action status |
| Billing.DepositAdd | Stored Procedure | New deposit → status 1 |
| Billing.DepositUpdate | Stored Procedure | Updates deposit action status |
| Billing.DepositProcess | Stored Procedure | Processes deposit action status |
| Billing.DepositCancel | Stored Procedure | Cancel → writes closing status |
| Billing.DepositRollback | Stored Procedure | Rollback → writes status |
| Billing.DepositsCancelByLastDays | Stored Procedure | Bulk cancel → status 3 |
| Billing.PaymentByPayPalProcess | Stored Procedure | PayPal close → status 3 |
| BackOffice.DepositCancel | Stored Procedure | Back-office cancel |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPAS | NONCLUSTERED PK | PaymentActionStatusID ASC | - | - | Active |
| DPAS_NAME | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPAS | PRIMARY KEY | Unique action status, FILLFACTOR 90, DICTIONARY filegroup |
| DPAS_NAME | UNIQUE INDEX | Ensures no duplicate status names, FILLFACTOR 90 |

---

## 8. Sample Queries

### 8.1 List all payment action statuses
```sql
SELECT  PaymentActionStatusID,
        Name
FROM    Dictionary.PaymentActionStatus WITH (NOLOCK)
ORDER BY PaymentActionStatusID;
```

### 8.2 Count payment actions by status
```sql
SELECT  dpas.Name           AS ActionStatus,
        COUNT(*)            AS ActionCount
FROM    History.PaymentAction hpa WITH (NOLOCK)
JOIN    Dictionary.PaymentActionStatus dpas WITH (NOLOCK)
        ON hpa.PaymentActionStatusID = dpas.PaymentActionStatusID
GROUP BY dpas.Name
ORDER BY ActionCount DESC;
```

### 8.3 Find open (non-closed) payment actions
```sql
SELECT  hpa.*
FROM    History.PaymentAction hpa WITH (NOLOCK)
WHERE   hpa.PaymentActionStatusID < 3
ORDER BY hpa.InsertDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and extensive codebase analysis of Billing schema procedures.

---

*Generated: 2026-03-13 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PaymentActionStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PaymentActionStatus.sql*
