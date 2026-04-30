# Billing.BI_GetDepositPreviousStatus

> Scalar function that returns the BI display label of the deposit status *before* a given credit event, by finding the preceding credit record for the same deposit and calling Billing.BI_GetDepositStatus on it. Overrides 'Deposit' to 'Approved' for historical context.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(50) - previous deposit status label |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.BI_GetDepositPreviousStatus` answers the question "what was this deposit's status before the current credit event?" It is the temporal companion to `Billing.BI_GetDepositStatus` - instead of returning the *current* deposit status, it resolves the *prior* status.

The function finds the most recent credit record for the same deposit that occurred before the given `@CreditID` (by querying `History.ActiveCredit` with `CreditID < @CreditID ORDER BY CreditID DESC`), then delegates to `Billing.BI_GetDepositStatus` to get that prior state's label.

One key override applies: if the prior state resolves to `'Deposit'` (i.e., the previous event was a standard initial deposit credit), the function returns `'Approved'` instead. This reflects the business reality that a deposit that was subsequently charged back or refunded was in an "Approved" state beforehand - "Deposit" is the raw credit type name, but for state transition reporting, the previous state before a reversal is logically "Approved".

**Use in BI State Reports**: This function enables deposit state-transition tracking. For example, a chargeback credit record (CreditTypeID=11) can be annotated with "previous state: Approved" to show that the deposit was approved before the chargeback occurred. This is displayed in `Billing.BI_Deposit_State_Report` and related BI workflows.

**Note**: Depends on `History.ActiveCredit` in EtoroArchive - not queryable via standard MCP read-only user.

---

## 2. Business Logic

### 2.1 Prior Credit Lookup in History.ActiveCredit

**What**: Finds the immediately preceding credit event for the same deposit, ordered by CreditID descending.

**Columns/Parameters Involved**: `@CID`, `@DepositID`, `@CreditID`

**Rules**:
- Queries: `SELECT TOP(1) CreditTypeID, DepositRollbackID FROM History.ActiveCredit WHERE DepositID = @DepositID AND CID = @CID AND CreditID < @CreditID ORDER BY CreditID DESC`
- `CreditID < @CreditID`: ensures only events that happened *before* the current event are considered
- `TOP(1) ORDER BY CreditID DESC`: gets the *immediately* preceding event (highest CreditID still less than current)
- If no prior credit record exists (first event), @CreditTypeID and @DepositRollbackID remain NULL -> BI_GetDepositStatus(NULL, NULL) returns NULL or a fallback label
- Returns NULL if the deposit has no prior credit events in History.ActiveCredit

### 2.2 Delegation to BI_GetDepositStatus

**What**: The prior CreditTypeID and DepositRollbackID are passed to BI_GetDepositStatus to get the status label.

**Columns/Parameters Involved**: `@CreditTypeID`, `@DepositRollbackID`, `@DepositPreviousStatus`

**Rules**:
- Calls `[Billing].[BI_GetDepositStatus](@CreditTypeID, @DepositRollbackID)` with values from the prior credit record
- Returns all the same possible labels: 'Approved', 'Chargeback', 'Refund', 'RefundAsChargeback', 'ChargebackReversal', 'RefundReversal', 'ReversedDeposit', or CreditType name
- NULL inputs to BI_GetDepositStatus (no prior record found) will produce NULL or a fallback

### 2.3 'Deposit' -> 'Approved' Override

**What**: When the previous state label is 'Deposit', it is overridden to 'Approved'.

**Columns/Parameters Involved**: `@DepositPreviousStatus`

**Rules**:
- `IF LTRIM(RTRIM(@DepositPreviousStatus)) = 'Deposit' -> SET @DepositPreviousStatus = 'Approved'`
- 'Deposit' is what BI_GetDepositStatus returns when CreditTypeID=1 (standard deposit credit, no rollback)
- In the context of a *prior* state, a standard deposit being the predecessor means the deposit was approved/active
- The label 'Deposit' is misleading for a prior-state display; 'Approved' correctly conveys "the deposit was in a live/approved state before this event"
- This override only applies to the 'Deposit' label; all other labels pass through unchanged

---

## 3. Data Overview

N/A for Scalar Function. Example calling context:

| @CID | @DepositID | @CreditID | Prior CreditTypeID | Result | Meaning |
|------|------------|-----------|-------------------|--------|---------|
| 12345 | 67890 | 500 | 1 (Deposit) | 'Approved' | The deposit was in Approved state before CreditID=500. 'Deposit' -> 'Approved' override applied. |
| 12345 | 67890 | 600 | 11 (Chargeback) | 'Chargeback' | Before CreditID=600, the deposit had already been charged back. |
| 12345 | 67890 | 700 | NULL (no prior) | NULL | CreditID=700 is the first event - no prior status exists. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID. Used to scope the History.ActiveCredit lookup to the correct customer's deposit events. Must match the customer owning @DepositID. |
| 2 | @DepositID | int | NO | - | CODE-BACKED | Deposit identifier. The specific deposit whose prior credit status is being looked up in History.ActiveCredit. |
| 3 | @CreditID | bigint | NO | - | CODE-BACKED | The current credit event ID (bigint). The lookup finds the most recent prior credit with CreditID strictly less than this value, ensuring temporal ordering. |
| RETURN | varchar(50) | - | YES | - | CODE-BACKED | Human-readable prior deposit status label. Possible values: 'Approved' (includes override from 'Deposit'), 'Chargeback', 'Refund', 'RefundAsChargeback', 'ChargebackReversal', 'RefundReversal', 'ReversedDeposit', or any CreditType name as fallback. NULL if no prior credit record exists for this deposit. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID, @CID, CreditID | History.ActiveCredit (EtoroArchive) | Lookup (SELECT TOP(1), WHERE CreditID < @CreditID) | Prior credit records for the deposit |
| @CreditTypeID, @DepositRollbackID | Billing.BI_GetDepositStatus | Delegate (function call) | Resolves prior CreditTypeID+RollbackID to status label |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.BI_Deposit_State_Report | Previous status column | Caller | BI state report that shows deposit state transitions |
| Billing.BI_GetDeposit_TransactionType | @CID, @DepositID, @CreditID | Caller | Transaction type function that uses prior status for transition classification |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.BI_GetDepositPreviousStatus (function)
├── History.ActiveCredit (table, EtoroArchive cross-database)
└── Billing.BI_GetDepositStatus (function)
    ├── Billing.DepositRollbackTracking (table)
    ├── Dictionary.PaymentStatus (table)
    └── Dictionary.CreditType (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCredit | Table (EtoroArchive) | Looks up the most recent prior credit record (CreditID < @CreditID) for the deposit |
| Billing.BI_GetDepositStatus | Scalar Function | Delegates status label resolution to this function with the prior CreditTypeID and RollbackID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.BI_Deposit_State_Report | Stored Procedure | Calls per credit row to populate the "previous status" column in BI state reports |
| Billing.BI_GetDeposit_TransactionType | Scalar Function | Calls to determine the prior state for transaction type classification |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Scalar Function. The inner query on History.ActiveCredit (EtoroArchive) uses: `WHERE DepositID = @DepositID AND CID = @CID AND CreditID < @CreditID ORDER BY CreditID DESC` - performance depends on History.ActiveCredit having a composite index on (DepositID, CID, CreditID). This function is called once per credit row in BI_Deposit_State_Report - N+1 execution pattern for large result sets.

### 7.2 Constraints

Not schema-bound (cross-database dependency on EtoroArchive). The function is a scalar UDF - invoked once per row in callers, which may cause performance issues for large credit history datasets. The WITH(NOLOCK) hint on History.ActiveCredit prevents read locks but allows dirty reads. LTRIM/RTRIM applied to 'Deposit' comparison - defensive against whitespace in BI_GetDepositStatus return values.

---

## 8. Sample Queries

### 8.1 Get previous status for a specific credit event

```sql
SELECT Billing.BI_GetDepositPreviousStatus(@CID, @DepositID, @CreditID) AS PreviousStatus
```

### 8.2 Use in state transition report (typical calling pattern)

```sql
SELECT
    HC.CreditID,
    HC.DepositID,
    HC.CID,
    Billing.BI_GetDepositStatus(HC.CreditTypeID, HC.DepositRollbackID) AS CurrentStatus,
    Billing.BI_GetDepositPreviousStatus(HC.CID, HC.DepositID, HC.CreditID) AS PreviousStatus
FROM History.ActiveCredit HC WITH (NOLOCK)
WHERE HC.DepositID = @DepositID
ORDER BY HC.CreditID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,2,5,7,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.BI_GetDepositPreviousStatus | Type: Scalar Function | Source: etoro/etoro/Billing/Functions/Billing.BI_GetDepositPreviousStatus.sql*
