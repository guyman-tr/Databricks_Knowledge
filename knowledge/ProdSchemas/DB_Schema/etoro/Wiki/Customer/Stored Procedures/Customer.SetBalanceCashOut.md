# Customer.SetBalanceCashOut

> Processes a cashout (withdrawal) request: decrements CustomerMoney.RealizedEquity, logs the credit history record, triggers the BSL MIMO pipeline, adds the customer to BSL whitelist, and notifies the payment queue.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @Payment INT (cents), @WithdrawID INT; raises on error via THROW |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a customer submits a withdrawal request and it is approved for processing, `SetBalanceCashOut` executes the balance changes. Unlike a deposit (which increases Credit), a cashout decrements `RealizedEquity` only - not the `Credit` field. This asymmetry reflects that a cashout reduces the customer's realized value (funds actually leaving the platform) while Credit (available trading balance) is managed separately by the downstream payment finalization flow.

After updating the balance, the procedure: (1) logs a CreditTypeID=2 (Cashout) credit record, (2) inserts a pending action into `Internal.ActionsToExecute_MIMOOperations` to trigger the PostMIMOOperations BSL recalculation asynchronously, (3) adds the customer to `Trade.BSLUsersWhiteList` to suspend BSL enforcement during the MIMO window, and (4) sends a Service Broker message to `svcPayment` with withdrawal and fee amounts for downstream payment processing.

---

## 2. Business Logic

### 2.1 Cent-to-Dollar Conversion

**What**: @Payment is in cents (integer); converted to dollars before use.

**Rules**:
- `@CashoutAmount = CAST(@Payment AS MONEY) / 100`
- All balance updates use @CashoutAmount (dollars).

### 2.2 RealizedEquity-Only Decrement

**What**: A cashout reduces RealizedEquity but NOT Credit - this is intentional.

**Columns/Parameters Involved**: `RealizedEquity` in Customer.CustomerMoney

**Rules**:
- Only `RealizedEquity -= @CashoutAmount` is executed in the UPDATE.
- `Credit` is not changed here - the credit reduction is handled by the payment processing system that finalizes the withdrawal.
- `Payment = 0` is passed to SetBalanceInsertCredit_Native (reflects zero immediate credit change in the history record at this step).
- The OUTPUT clause captures OldRealizedEquity, NewRealizedEquity, Credit, TotalCash, BonusCredit, BSLRealFunds.

### 2.3 MIMO Pipeline Trigger

**What**: After a cashout, the BSL threshold must be recalculated. This is done asynchronously via the MIMO pipeline.

**Columns/Parameters Involved**: `Internal.ActionsToExecute_MIMOOperations`, `Trade.BSLUsersWhiteList`

**Rules**:
- Inserts record to `Internal.ActionsToExecute_MIMOOperations` with ActionID=7 (PostOperation on MIMO), CreditTypeID=2, CreditID from the new credit record.
- Inserts `(CID, CreditID)` to `Trade.BSLUsersWhiteList` - suspends BSL enforcement while MIMO recalculation is pending.
- The MIMO pipeline will call `Customer.PostMIMOOperations` asynchronously to update BSLRealFunds and remove from whitelist.

### 2.4 Payment Queue Notification

**What**: If the cashout amount > 0, sends a withdrawal notification to svcPayment.

**Rules**:
- Queries `History.ActiveCreditBucket_VW` for the same CID+WithdrawID to calculate @WithdrawlAmount (sum of CreditTypeID=9 TotalCashChange) and @FeeAmount (sum of CreditTypeID=15 TotalCashChange).
- Payment data format: `"{CID};2;{WithdrawlAmount};{FeeAmount};{WithdrawID};{datetime};{NewRealizedEquity};{CashoutReasonID};0;"`.
- Sent via Service Broker BEGIN DIALOG ... SEND to svcPayment.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the account being cashed out. |
| 2 | @Payment | INT | NO | - | VERIFIED | Cashout amount in CENTS (integer). Divided by 100 to get dollars. Example: 10000 = $100.00 withdrawal. |
| 3 | @WithdrawID | INT | NO | - | CODE-BACKED | Withdrawal request ID from the Billing schema. Links the credit record and payment notification to the specific withdrawal event. |
| 4 | @ManagerID | INT | NO | - | CODE-BACKED | Admin/manager ID who authorized or processed the cashout. Stored in credit record for traceability. |
| 5 | @Description | VARCHAR(255) | YES | NULL | CODE-BACKED | Human-readable description stored in the credit history record. |
| 6 | @WithdrawProcessingID | INT | NO | - | CODE-BACKED | Processing batch/reference ID for this withdrawal batch. Passed to SetBalanceInsertCredit_Native for withdrawal batch tracking. |
| 7 | @BonusCredit | MONEY | NO | - | CODE-BACKED | Current bonus credit amount, captured before the update (passed in by caller). Stored in the credit record as a snapshot of the bonus credit at cashout time. |
| 8 | @CashoutReasonID | INT | YES | '' | CODE-BACKED | Reason code for the cashout (added FB 34882, 17/02/2016). Included in the payment queue message. Default is '' (implicitly 0). |
| 9 | @MoveMoneyReasonID | INT | YES | NULL | CODE-BACKED | Internal money movement reason code for additional classification. Added for multi-currency/internal transfer tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | UPDATE RealizedEquity -= cashout amount |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs CreditTypeID=2 cashout credit record |
| @CID | Internal.ActionsToExecute_MIMOOperations | INSERT | Queues async BSL recalculation (ActionID=7) |
| @CID, @CreditID | Trade.BSLUsersWhiteList | INSERT | Suspends BSL enforcement during MIMO window |
| @CID, @WithdrawID | History.ActiveCreditBucket_VW | READ | Calculates total withdrawal + fee amounts for payment notification |
| @CID | Customer.SendEvent | Caller (EXEC) | Sends event-9 (zero balance alert) if Credit <= 0 |
| - | svcPayment (Service Broker) | SEND | Notifies payment queue of cashout event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central balance router delegates CreditTypeID=2 to this procedure |
| Billing withdrawal pipeline | External | Caller | Called when withdrawal request is approved for processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceCashOut (procedure)
+-- Customer.CustomerMoney (table) [UPDATE RealizedEquity]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit CreditTypeID=2]
|     +-- History.ActiveCreditRecentMemoryBucket (table)
+-- Internal.ActionsToExecute_MIMOOperations (table) [INSERT MIMO trigger]
+-- Trade.BSLUsersWhiteList (table) [INSERT BSL whitelist entry]
+-- History.ActiveCreditBucket_VW (view) [READ withdrawal+fee amounts]
+-- Customer.SendEvent (procedure) [conditional zero-balance event]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - decrements RealizedEquity |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts CreditTypeID=2 cashout record |
| Internal.ActionsToExecute_MIMOOperations | Table | INSERT - queues async MIMO BSL recalculation |
| Trade.BSLUsersWhiteList | Table | INSERT - suspends BSL during MIMO window |
| History.ActiveCreditBucket_VW | View | SELECT - reads withdrawal/fee amounts |
| Customer.SendEvent | Procedure | EXEC - zero balance alert (conditional) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for CreditTypeID=2 (Cashout) events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @Payment = INT (cents) | Unit convention | Unlike SetBalanceBonus (@BonusInCents MONEY), this uses INT for cents. Converted via CAST(@Payment AS MONEY)/100. |
| @Payment = 0 in SetBalanceInsertCredit_Native | Design | Credit field is not changed at cashout initiation - the actual credit deduction happens when the withdrawal is finalized. |
| MIMO pipeline mandatory | Design | Every cashout must trigger BSL recalculation. Failure here would leave the customer on the whitelist indefinitely. |

---

## 8. Sample Queries

### 8.1 Find recent cashouts for a customer with withdrawal amounts

```sql
SELECT
    acb.CreditID,
    acb.CreditTypeID,
    acb.WithdrawID,
    acb.RealizedEquity AS RealizedEquityAfterCashout,
    acb.TotalCashChange,
    acb.Description,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 2
ORDER BY acb.Occurred DESC
```

### 8.2 Check if a customer is pending MIMO reconciliation after cashout

```sql
SELECT
    w.CID,
    w.CreditID,
    cm.BSLRealFunds,
    cm.RealizedEquity,
    atm.ActionID,
    atm.Status,
    atm.CurrentTry
FROM Trade.BSLUsersWhiteList w WITH (NOLOCK)
JOIN Customer.CustomerMoney cm WITH (NOLOCK) ON cm.CID = w.CID
LEFT JOIN Internal.ActionsToExecute_MIMOOperations atm WITH (NOLOCK)
    ON atm.Params LIKE '%CreditID Value="' + CAST(w.CreditID AS VARCHAR) + '"%'
WHERE w.CID = 12345
```

### 8.3 Total cashout amounts by customer for current month

```sql
SELECT
    acb.CID,
    SUM(ABS(acb.TotalCashChange)) AS TotalWithdrawn,
    COUNT(*) AS CashoutCount
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CreditTypeID = 2
    AND acb.Occurred >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETUTCDATE()), 0)
GROUP BY acb.CID
ORDER BY TotalWithdrawn DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Multi-Currency Balance API](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14028570661/Multi-Currency+Balance+API) | Confluence | MIMO pipeline context for cashout; new Trading.BalanceService will replace SP-based cashout entry points. |
| [Multi-Currency Database Schema Changes](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14019264620/Multi-Currency+Database+Schema+Changes) | Confluence | RealizedEquity is account-level (USD) - consistent with cashout decrementing RealizedEquity as an account-wide value. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceCashOut | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceCashOut.sql*
