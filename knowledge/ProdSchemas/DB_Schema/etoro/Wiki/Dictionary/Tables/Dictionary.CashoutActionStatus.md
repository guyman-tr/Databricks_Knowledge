# Dictionary.CashoutActionStatus

> Lookup table defining the 3 states of cashout (withdrawal) actions — New, Processed, and Failed — tracking each step in the withdrawal processing pipeline.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CashoutActionStatusID (INT, PK NONCLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Row Count** | 3 (MCP verified) |
| **Indexes** | 2 active (PK nonclustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.CashoutActionStatus defines the lifecycle states for individual cashout (withdrawal) actions recorded in History.CashoutAction and History.WithdrawToFundingAction. Each cashout request generates one or more actions as it moves through the withdrawal pipeline — each action tracks a specific processing step (e.g., sending funds to the PSP, receiving confirmation, handling failures).

This is the cashout-side equivalent of Dictionary.PaymentActionStatus (which tracks deposit actions). When a withdrawal is initiated, a cashout action is created with status New (1). Upon successful processing by the PSP, it moves to Processed (2). If the PSP rejects or the action fails, it moves to Failed (3). Unlike PaymentActionStatus, this table has an explicit Failed state rather than a generic "Closed" state, reflecting the higher importance of distinguishing success from failure in withdrawal processing.

The table is heavily referenced across withdrawal procedures: Billing.CashoutProcess and its payment-method-specific variants (CashoutProcessToPayPal, CashoutProcessToCreditCard, etc.), plus the entire Billing.WithdrawToFunding* procedure family for newer withdrawal flows.

---

## 2. Business Logic

### 2.1 Cashout Action Lifecycle

**What**: The three states every cashout action passes through.

**Columns/Parameters Involved**: `CashoutActionStatusID`, `Name`

**Rules**:
- **New (1)**: Initial state when a cashout action is created. The withdrawal step has been recorded but not yet executed. Set by Billing.CashoutRequestAdd, Billing.WithdrawToFundingAdd, and related procedures.
- **Processed (2)**: The action was successfully executed — funds were sent to the PSP or customer confirmation was received. Terminal success state.
- **Failed (3)**: The action failed — PSP rejected the transaction, network timeout, or validation error. Terminal failure state. Triggers retry or manual intervention workflows.

**Diagram**:
```
Cashout Action Lifecycle:
  New (1) ──► Processed (2)     [success]
    │
    └──► Failed (3)             [PSP rejection, timeout, error]
```

### 2.2 Usage Across Withdrawal Flows

**What**: How CashoutActionStatusID is used in both legacy and modern withdrawal procedures.

**Columns/Parameters Involved**: `CashoutActionStatusID`

**Rules**:
- **Legacy flow** (Billing.CashoutProcess*): Payment-method-specific procedures (ToPayPal, ToCreditCard, ToWireTransfer, ToWesternUnion, ToNeteller) each accept @CashoutActionStatusID and INSERT into History.CashoutAction
- **Modern flow** (Billing.WithdrawToFunding*): Unified withdrawal pipeline — WithdrawToFundingAdd, WithdrawToFundingProcess, WithdrawToFundingReverse, WithdrawToFundingReject, WithdrawToFundingMatch all write CashoutActionStatusID into History.WithdrawToFundingAction
- **BackOffice**: WithdrawToFundingAdd and InProcessPaymentsToSendPCIVersion filter by CashoutActionStatusID=1 (New) for pending items

---

## 3. Data Overview

| CashoutActionStatusID | Name | Meaning |
|---|---|---|
| 1 | New | Cashout action has been created but not yet processed. Initial state for all withdrawal steps. Pending PSP execution. Queried by BackOffice for in-process payment reports (WHERE CashoutActionStatusID = 1). |
| 2 | Processed | Cashout action successfully completed. Funds sent to PSP or confirmation received. Terminal success state. No further processing needed for this action. |
| 3 | Failed | Cashout action failed. PSP rejection, network error, validation failure, or timeout. Terminal failure state. May trigger retry with a new action record or escalation to manual processing. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CashoutActionStatusID | int | NO | - | VERIFIED | Primary key identifying the action lifecycle state. 1=New (created, pending), 2=Processed (success), 3=Failed (error). Referenced by History.CashoutAction (explicit FK) and History.WithdrawToFundingAction (implicit). Written by all cashout processing procedures in legacy (CashoutProcess*) and modern (WithdrawToFunding*) flows. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable status name. Unique constraint prevents duplicates. Values: 'New', 'Processed', 'Failed'. Used in withdrawal monitoring, BackOffice reports, and debugging. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.CashoutAction | CashoutActionStatusID | Explicit FK (FK_DCAS → Dictionary.CashoutActionStatus) | Legacy cashout action history |
| History.WithdrawToFundingAction | CashoutActionStatusID | Implicit (column + index) | Modern withdrawal action history |
| History.vWithdrawToFundingAction | CashoutActionStatusID | View SELECT | View over withdrawal actions |
| Billing.TBL_Withdraw2Funding | CashoutActionStatusID | UDT column | Table-valued parameter for batch processing |
| Billing.CashoutProcess | @CashoutActionStatusID | Parameter INSERT | Legacy cashout processing |
| Billing.CashoutProcessToPayPal | @CashoutActionStatusID | Parameter INSERT | PayPal-specific cashout |
| Billing.CashoutProcessToCreditCard | @CashoutActionStatusID | Parameter INSERT | Credit card-specific cashout |
| Billing.CashoutProcessToWireTransfer | @CashoutActionStatusID | Parameter INSERT | Wire transfer-specific cashout |
| Billing.CashoutProcessToWesternUnion | @CashoutActionStatusID | Parameter INSERT | Western Union-specific cashout |
| Billing.CashoutProcessToNeteller | @CashoutActionStatusID | Parameter INSERT | Neteller-specific cashout |
| Billing.CashoutRequestAdd | - | INSERT | Creates initial cashout action |
| Billing.WithdrawToFundingAdd | - | INSERT | Creates withdrawal action (modern flow) |
| Billing.WithdrawToFundingProcess | - | INSERT | Processes withdrawal action |
| Billing.WithdrawToFundingReverse | - | INSERT | Records reversal action |
| Billing.WithdrawToFundingReject | - | INSERT | Records rejection action |
| Billing.WithdrawToFundingMatch | - | INSERT | Records matching action |
| Billing.InsertWithdraw2Funding | - | INSERT | Batch insert withdrawal actions |
| Billing.UpdateWithdraw2Funding | - | MERGE | Batch update withdrawal actions |
| Billing.SetWithdrawToFundingScheme | - | INSERT (LEAD over) | Sets withdrawal scheme with status tracking |
| Billing.PayoutProcess_CreateRecords | - | INSERT | Payout processing creates action records |
| BackOffice.InProcessPaymentsToSendPCIVersion | CashoutActionStatusID | WHERE = 1 | Filters for New (pending) actions |
| BackOffice.WithdrawToFundingAdd | - | INSERT | Back-office initiated withdrawal |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CashoutActionStatus (table)
  └── referenced by History.CashoutAction (FK)
  └── referenced by History.WithdrawToFundingAction (implicit)
  └── consumed by 20+ Billing/BackOffice withdrawal procedures
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.CashoutAction | Table | FK on CashoutActionStatusID |
| History.WithdrawToFundingAction | Table | Stores action status per withdrawal step |
| Billing.CashoutProcess | Stored Procedure | Legacy cashout processing |
| Billing.CashoutProcessToPayPal | Stored Procedure | PayPal cashout processing |
| Billing.CashoutProcessToCreditCard | Stored Procedure | Credit card cashout |
| Billing.WithdrawToFundingAdd | Stored Procedure | Modern withdrawal creation |
| Billing.WithdrawToFundingProcess | Stored Procedure | Modern withdrawal processing |
| Billing.WithdrawToFundingReverse | Stored Procedure | Withdrawal reversal |
| Billing.WithdrawToFundingReject | Stored Procedure | Withdrawal rejection |
| Billing.PayoutProcess_CreateRecords | Stored Procedure | Payout batch processing |
| BackOffice.InProcessPaymentsToSendPCIVersion | Stored Procedure | Pending action reporting |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCAS | NONCLUSTERED PK | CashoutActionStatusID ASC | - | - | Active |
| DCAS_NAME | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCAS | PRIMARY KEY | Unique action status identifier, FILLFACTOR 90, DICTIONARY filegroup |
| DCAS_NAME | UNIQUE INDEX | Ensures no duplicate status names, FILLFACTOR 90 |

---

## 8. Sample Queries

### 8.1 List all cashout action statuses
```sql
SELECT  CashoutActionStatusID,
        Name
FROM    Dictionary.CashoutActionStatus WITH (NOLOCK)
ORDER BY CashoutActionStatusID;
```

### 8.2 Count withdrawal actions by status
```sql
SELECT  dcas.Name           AS ActionStatus,
        COUNT(*)            AS ActionCount
FROM    History.WithdrawToFundingAction hwa WITH (NOLOCK)
JOIN    Dictionary.CashoutActionStatus dcas WITH (NOLOCK)
        ON hwa.CashoutActionStatusID = dcas.CashoutActionStatusID
GROUP BY dcas.Name
ORDER BY ActionCount DESC;
```

### 8.3 Find pending (New) cashout actions
```sql
SELECT  hwa.*
FROM    History.WithdrawToFundingAction hwa WITH (NOLOCK)
WHERE   hwa.CashoutActionStatusID = 1  -- New
ORDER BY hwa.InsertDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and codebase analysis across 22+ withdrawal processing procedures in Billing and BackOffice schemas.

---

*Generated: 2026-03-13 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 22 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CashoutActionStatus | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CashoutActionStatus.sql*
