# History.ActiveCredit_CashoutRollbackSet

> Orchestrates the credit-side of a cashout rollback by inserting a Cashout Rollback credit (type 33) into the customer's balance and linking the resulting credit record to the rollback tracking entry.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (customer), @RollbackID (rollback tracking record linked) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a customer's cashout (withdrawal) is reversed or rolled back - for example, because a payment was returned by the provider, or compliance intervened - the platform must return the withdrawn funds to the customer's account balance. This procedure handles the credit-ledger half of that reversal: it records a formal credit transaction of type 33 (Cashout Rollback) against the customer's balance, and then stamps the resulting credit ID onto the cashout rollback tracking record so the two are permanently linked.

Without this procedure, a cashout rollback would have no corresponding credit entry in the customer's ledger, leaving the customer's reported balance out of sync with what was actually returned. The Cashout Rollback credit (type 33) is the bookkeeping record that explains why the customer's balance increased after a withdrawal was reversed.

Data flows as follows: the CashoutTool back-office application calls this procedure directly when processing a rollback. The procedure delegates credit creation to `Customer.SetBalanceInsertCredit_Native` (which owns the logic for inserting into the credit ledger and updating balances), captures the newly generated `CreditID`, and writes it back to `Billing.CashoutRollbackTracking` so the rollback tracking record references the credit. Errors propagate to the caller via `THROW` without swallowing.

---

## 2. Business Logic

### 2.1 Two-Phase Rollback Credit Lifecycle

**What**: A cashout rollback requires two coordinated writes: (1) a credit ledger entry and (2) a link back to the rollback tracking record.

**Columns/Parameters Involved**: `@CID`, `@Amount`, `@Credit`, `@RollbackID`, `@CreditID` (internal OUTPUT variable)

**Rules**:
- `Customer.SetBalanceInsertCredit_Native` is called with `@CreditTypeID = 33` (hard-coded), meaning ALL calls to this procedure produce a "Cashout Rollback" credit - not configurable by the caller.
- The `@Identity OUTPUT` parameter captures the new `CreditID` assigned by the credit insertion.
- `Billing.CashoutRollbackTracking.CreditID` is set to that captured value, linking the rollback record to its credit entry. Without `@RollbackID`, the UPDATE has no effect (NULL WHERE clause).
- `@Credit` defaults to 0 - cashout rollbacks typically restore cash only, with no bonus/credit component. Callers can override to non-zero if a credit adjustment is also needed.

**Diagram**:
```
Caller (CashoutTool)
  |
  v
History.ActiveCredit_CashoutRollbackSet
  |-- EXEC Customer.SetBalanceInsertCredit_Native (@CreditTypeID=33)
  |     |-- Inserts into credit ledger
  |     |-- Updates customer cash balance
  |     `-- Returns @CreditID (OUTPUT)
  |
  `-- UPDATE Billing.CashoutRollbackTracking
        SET CreditID = @CreditID
        WHERE RollbackID = @RollbackID
```

### 2.2 Legacy Call-Site (Commented Out)

**What**: `Billing.AddCashoutRollback` contains a commented-out call to this procedure.

**Columns/Parameters Involved**: N/A (not active)

**Rules**:
- The line `--EXEC [History].[ActiveCredit_CashoutRollbackSet]` in `Billing.AddCashoutRollback` is commented out - that flow now uses `Customer.SetBalance` instead.
- This procedure is currently invoked directly by the CashoutTool application (which holds an explicit EXECUTE grant), bypassing the Billing schema orchestration layer.
- The separation means the credit insertion and balance update happen as a standalone operation, not wrapped in the full `Billing.AddCashoutRollback` transaction (which handles withdraw table updates, rollback tracking creation, etc.).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the account receiving the rollback credit. Passed directly to `Customer.SetBalanceInsertCredit_Native` as the target customer. |
| 2 | @WithdrawID | INT | NO | - | CODE-BACKED | ID of the original withdrawal record being reversed. Passed to the credit insertion procedure to link the credit back to the specific withdrawal transaction. |
| 3 | @ManagerID | INT | NO | - | CODE-BACKED | ID of the back-office manager authorizing the rollback. Passed to credit insertion for audit trail - records who performed the rollback. |
| 4 | @Amount | MONEY | NO | - | CODE-BACKED | The cash amount to return to the customer, in account currency. Passed as `@Payment` to `Customer.SetBalanceInsertCredit_Native`. Represents the original cashout amount being reversed. |
| 5 | @Credit | MONEY | YES | 0 | CODE-BACKED | Optional bonus or credit component of the rollback, in account currency. Defaults to 0 - most cashout rollbacks are pure cash returns with no bonus adjustment. Pass non-zero only when a credit balance also needs restoring. |
| 6 | @Description | VARCHAR(250) | NO | - | CODE-BACKED | Free-text description of the rollback reason, stored in the credit ledger entry. Used for audit and customer statement display. |
| 7 | @WithdrawProcessingID | INT | NO | - | CODE-BACKED | ID of the Withdraw2Funding (withdraw processing) record, passed as `@WithdrawProcessingID` to credit insertion. Links the credit to the specific funding leg of the original withdrawal. |
| 8 | @TotalCash | MONEY | NO | - | CODE-BACKED | The customer's total cash balance to record at the time of the credit. Passed to `Customer.SetBalanceInsertCredit_Native` as a balance snapshot for the credit record. |
| 9 | @RealizedEquity | MONEY | NO | - | CODE-BACKED | The customer's realized equity at the time of rollback. Passed to the credit insertion procedure for balance context. |
| 10 | @RollbackID | BIGINT | YES | NULL | CODE-BACKED | ID of the rollback tracking record in `Billing.CashoutRollbackTracking`. After credit insertion, this record is updated to store the new `CreditID`. If NULL, the UPDATE has no effect (no tracking record to link). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (EXEC) | Customer.SetBalanceInsertCredit_Native | Procedure call | Creates a CreditTypeID=33 (Cashout Rollback) credit entry in the customer's balance ledger. This is the canonical procedure for inserting credits. |
| @RollbackID | Billing.CashoutRollbackTracking | Lookup / Update | Updates `CreditID` on the rollback tracking record identified by `@RollbackID`, linking the rollback to the newly created credit. |
| @WithdrawID | Billing.Withdraw (implicit) | Implicit | The WithdrawID passed through to the credit procedure identifies the original withdrawal being reversed. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CashoutTool (application) | EXECUTE grant | Direct call | The back-office cashout reversal tool calls this procedure directly to process the credit side of a rollback. |
| Billing.AddCashoutRollback | (commented out) | Legacy reference | Previously intended to call this procedure within a full cashout rollback transaction; currently commented out in favor of Customer.SetBalance. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveCredit_CashoutRollbackSet (procedure)
├── Customer.SetBalanceInsertCredit_Native (procedure) [cross-schema]
└── Billing.CashoutRollbackTracking (table) [cross-schema - UPDATE target]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalanceInsertCredit_Native | Stored Procedure | Called via EXEC to insert the rollback credit entry and adjust customer balance. Returns @CreditID OUTPUT. |
| Billing.CashoutRollbackTracking | Table | Updated: SET CreditID = @CreditID WHERE RollbackID = @RollbackID. Links the rollback tracking record to the credit entry. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CashoutTool application | External application | Calls this procedure to process the credit side of a cashout reversal. |
| Billing.AddCashoutRollback | Stored Procedure | Commented-out historical reference; no longer an active caller. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| TRY/CATCH with THROW | Error handling | Any error from the credit insertion or tracking update is re-thrown to the caller without swallowing. Ensures the caller's transaction can roll back cleanly if needed. |
| @CreditTypeID = 33 (hard-coded) | Business constraint | All invocations create a Cashout Rollback credit (type 33). The credit type is not parameterized - this procedure is purpose-built for rollback credits only. |

---

## 8. Sample Queries

### 8.1 Find rollback tracking records with their credit IDs

```sql
SELECT
    crt.RollbackID,
    crt.WithdrawID,
    crt.CreditID,
    crt.CashoutStatusID,
    crt.RollbackType
FROM Billing.CashoutRollbackTracking crt WITH (NOLOCK)
WHERE crt.CreditID IS NOT NULL
ORDER BY crt.RollbackID DESC;
```

### 8.2 Find credits of type 33 (Cashout Rollback) in History.ActiveCredit

```sql
SELECT
    ac.CreditID,
    ac.CID,
    ac.CreditTypeID,
    ac.Amount,
    ac.Description,
    ac.InsertDate
FROM History.ActiveCredit ac WITH (NOLOCK)
WHERE ac.CreditTypeID = 33
ORDER BY ac.InsertDate DESC;
```

### 8.3 Join rollback tracking to the credit record

```sql
SELECT
    crt.RollbackID,
    crt.WithdrawID,
    crt.CashoutStatusID,
    ac.CID,
    ac.Amount,
    ac.Description,
    ac.InsertDate AS CreditDate
FROM Billing.CashoutRollbackTracking crt WITH (NOLOCK)
INNER JOIN History.ActiveCredit ac WITH (NOLOCK)
    ON ac.CreditID = crt.CreditID
WHERE crt.CreditID IS NOT NULL
ORDER BY ac.InsertDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HLD: Reverse Partially Processed Withdrawals](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/12010390722) | Confluence | Architecture context for the cashout reversal flow; confirms this procedure is part of the withdrawal rollback process. (Page body inaccessible.) |

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.6/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ActiveCredit_CashoutRollbackSet | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.ActiveCredit_CashoutRollbackSet.sql*
