# Customer.SetBalanceChargeBack

> Processes a deposit chargeback: restores Credit, RealizedEquity, and TotalCash by the chargeback amount, logs CreditTypeID=11 credit record, triggers MIMO BSL recalculation, sends payment notification, and reports the net-effective amount to affiliate/piggybank tracking systems.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @Payment BIGINT (cents), @DepositID INT; @ErrOut OUTPUT; raises on error via THROW |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

A chargeback occurs when a customer's bank or card issuer reverses a deposit that was previously processed on eToro - typically due to a dispute or fraud claim. `SetBalanceChargeBack` is the database entry point for this reversal event.

Unlike `SetBalanceCashOut` (which decrements only `RealizedEquity`), a chargeback applies the amount to all three core balance fields: `Credit`, `RealizedEquity`, and `TotalCash`. The `@Payment` parameter is in cents (BIGINT) and can be negative (reversing a previously credited deposit) or positive (rare correction scenario).

After updating balances, the procedure:
1. Logs a `CreditTypeID=11` (Chargeback) credit record.
2. Inserts an entry into `Internal.ActionsToExecute_MIMOOperations` (ActionID=7) to trigger asynchronous BSL recalculation.
3. Adds the customer to `Trade.BSLUsersWhiteList` to suspend BSL enforcement during the MIMO window.
4. Sends a Service Broker message to `svcPayment` for downstream payment processing notification.
5. If the customer is a real (non-demo) account with PlayerLevelID != 4, notifies `Broker.QueuePiggyBankAdd` and `Broker.QueueAffiliateTraderCreditAdd` using a net-effective amount calculated via credit absorption logic.

---

## 2. Business Logic

### 2.1 Cent-to-Dollar Conversion

**What**: @Payment (BIGINT) in cents is converted to MONEY in dollars.

**Rules**:
- `@CreditChange = CAST(@Payment AS MONEY) / 100`
- All balance updates use @CreditChange (dollars).
- Note: @Payment is BIGINT (wider than the INT used in SetBalanceCashOut) to support large chargeback amounts.

### 2.2 Three-Field Balance Update

**What**: Unlike SetBalanceCashOut (RealizedEquity only), a chargeback modifies all three cash balance fields.

**Columns/Parameters Involved**: `Credit`, `RealizedEquity`, `TotalCash` in Customer.CustomerMoney

**Rules**:
- `Credit += @CreditChange` (can be negative for a chargeback deduction)
- `RealizedEquity += @CreditChange`
- `TotalCash += @CreditChange`
- ISNULL wrappers protect against NULL column values.

```
CustomerMoney after chargeback (negative @Payment scenario):
  Credit         -= chargeback amount
  RealizedEquity -= chargeback amount
  TotalCash      -= chargeback amount
  BSLRealFunds   - UNCHANGED (MIMO recalculates asynchronously)
```

### 2.3 MIMO BSL Recalculation Trigger

**What**: After a chargeback, the BSL threshold must be recalculated asynchronously.

**Columns/Parameters Involved**: `Internal.ActionsToExecute_MIMOOperations`, `Trade.BSLUsersWhiteList`

**Rules**:
- Inserts `ActionID=7, CreditTypeID=11, CreditID=@CreditID` XML record into `Internal.ActionsToExecute_MIMOOperations`.
- Inserts `(CID, CreditID)` into `Trade.BSLUsersWhiteList` - suspends BSL enforcement.
- MIMO pipeline calls `Customer.PostMIMOOperations` asynchronously.

### 2.4 Affiliate Credit Absorption Logic

**What**: For real accounts (not PlayerLevelID=4), the affiliate tracking systems receive a net-effective @Payment that accounts for partial credit absorption when a negative chargeback crosses the zero balance boundary.

**Columns/Parameters Involved**: `@Payment`, `@OldCredit`, `@IsReal`, `@PlayerLevelID`

**Rules**:
- Only applies when `IsReal = 1` AND `PlayerLevelID != 4`.
- Effective payment for affiliate reporting is recalculated:

| Condition | Effective Payment |
|-----------|------------------|
| @Payment < 0 AND @OldCredit >= 0 | min(0, @OldCredit*100 + @Payment) - only the portion driving balance below zero |
| @Payment < 0 AND @OldCredit < 0 | @Payment - full negative impact (already in deficit) |
| @Payment > 0 AND @OldCredit >= 0 | 0 - positive chargeback on positive balance, no affiliate impact |
| @Payment > 0 AND @OldCredit < 0 | min(@Payment, -@OldCredit*100) - only amount recovering from negative |

- Calls `Broker.QueuePiggyBankAdd` with `Type=4` (Chargeback event type).
- Calls `Broker.QueueAffiliateTraderCreditAdd` with `Type=4`, `CreditID=@CreditID`.

### 2.5 Service Broker Payment Notification

**What**: Sends chargeback event data to svcPayment.

**Rules**:
- Format: `"{CID};11;{Payment};{NewCredit*100};{BonusCredit};"`.
- Sent via `BEGIN DIALOG ... SEND ON CONVERSATION ... TO SERVICE 'svcPayment'`.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the account being charged back. |
| 2 | @Payment | BIGINT | NO | - | VERIFIED | Chargeback amount in CENTS. BIGINT (wider than INT used in cashout). Divided by 100 for dollars. Typically negative for a standard chargeback (funds removed from account); positive for a correction. |
| 3 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Human-readable description of the chargeback reason, stored in the credit history record. |
| 4 | @DepositID | INT | NO | - | CODE-BACKED | ID of the original deposit being reversed (from Billing schema). Links the credit record to the source deposit transaction. |
| 5 | @ManagerID | INT | NO | - | CODE-BACKED | Admin/manager who authorized the chargeback processing. Stored in the credit record for traceability. |
| 6 | @DepositRollbackID | INT | NO | - | CODE-BACKED | Rollback tracking reference for this deposit reversal. Passed to SetBalanceInsertCredit_Native as DepositRollbackID for cross-system linkage. |
| 7 | @ErrOut | NVARCHAR(4000) | YES | '' (OUTPUT) | CODE-BACKED | OUTPUT parameter receiving error details on failure. Format: "SP - Schema.ProcName | ERROR_NUMBER: ... ERROR_MESSAGE: ...". Passed through to SendEvent call. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | UPDATE Credit, RealizedEquity, TotalCash += chargeback amount |
| @CID | Customer.CustomerStatic | READ | Reads IsReal, ProviderID, CountryID, SerialID, PlayerLevelID for affiliate tracking |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs CreditTypeID=11 chargeback credit record |
| @CID | Internal.ActionsToExecute_MIMOOperations | INSERT | Queues async BSL recalculation (ActionID=7) |
| @CID, @CreditID | Trade.BSLUsersWhiteList | INSERT | Suspends BSL enforcement during MIMO window |
| @CID | Customer.SendEvent | Caller (EXEC) | Sends event-9 (zero balance alert) if NewCredit <= 0 |
| - | svcPayment (Service Broker) | SEND | Notifies payment queue of chargeback event |
| - | Broker.QueuePiggyBankAdd | Caller (EXEC) | Reports chargeback to piggybank tracking (Type=4, real accounts only) |
| - | Broker.QueueAffiliateTraderCreditAdd | Caller (EXEC) | Reports chargeback to affiliate tracking (Type=4, real accounts only) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central balance router delegates CreditTypeID=11 (Chargeback) events here |
| Billing chargeback pipeline | External | Caller | Invoked when a payment processor reversal is received after deposit processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceChargeBack (procedure)
+-- Customer.CustomerMoney (table) [UPDATE Credit, RealizedEquity, TotalCash]
+-- Customer.CustomerStatic (table) [READ IsReal, ProviderID, CountryID, PlayerLevelID]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit CreditTypeID=11]
|     +-- History.ActiveCreditRecentMemoryBucket (table)
+-- Internal.ActionsToExecute_MIMOOperations (table) [INSERT MIMO trigger]
+-- Trade.BSLUsersWhiteList (table) [INSERT BSL whitelist entry]
+-- Customer.SendEvent (procedure) [zero-balance alert, conditional]
+-- Broker.QueuePiggyBankAdd (procedure) [affiliate tracking, conditional]
+-- Broker.QueueAffiliateTraderCreditAdd (procedure) [affiliate tracking, conditional]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - Credit, RealizedEquity, TotalCash += chargeback amount |
| Customer.CustomerStatic | Table | SELECT - IsReal, ProviderID, CountryID, SerialID, PlayerLevelID for affiliate tracking |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts CreditTypeID=11 chargeback record |
| Internal.ActionsToExecute_MIMOOperations | Table | INSERT - queues async MIMO BSL recalculation |
| Trade.BSLUsersWhiteList | Table | INSERT - suspends BSL during MIMO window |
| Customer.SendEvent | Procedure | EXEC - zero balance alert (conditional) |
| Broker.QueuePiggyBankAdd | Procedure | EXEC - piggybank event queue (real accounts, not PlayerLevel 4) |
| Broker.QueueAffiliateTraderCreditAdd | Procedure | EXEC - affiliate credit tracking queue (real accounts, not PlayerLevel 4) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for CreditTypeID=11 (Chargeback) events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| @Payment = BIGINT (cents) | Unit convention | Wider than INT - accommodates large chargeback amounts; divided by 100 for dollars |
| Three-field balance update | Design | Credit + RealizedEquity + TotalCash all modified - chargeback reverses the full deposit impact |
| Credit absorption logic | Affiliate accounting | Net-effective payment calculated to report only the portion of chargeback crossing the zero boundary - prevents double-counting of affiliate commission adjustments |
| PlayerLevelID != 4 guard | Affiliate filter | PlayerLevel 4 (VIP/special accounts) excluded from affiliate tracking even on chargebacks |
| MIMO mandatory | Design | Every chargeback must trigger BSL recalculation via MIMO pipeline |

---

## 8. Sample Queries

### 8.1 Find chargebacks for a customer

```sql
SELECT
    acb.CreditID,
    acb.Payment AS ChargebackAmountUSD,
    acb.DepositID,
    acb.DepositRollbackID,
    acb.Credit AS CreditAfterChargeback,
    acb.RealizedEquity AS RealizedEquityAfterChargeback,
    acb.Description,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 11
ORDER BY acb.Occurred DESC
```

### 8.2 Compare original deposit and its chargeback

```sql
DECLARE @DepositID INT = 77777;

SELECT
    acb.CreditTypeID,
    ct.Name AS EventType,
    acb.Payment AS AmountUSD,
    acb.RealizedEquity AS EquityAfterEvent,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = acb.CreditTypeID
WHERE acb.DepositID = @DepositID
    AND acb.CreditTypeID IN (1, 11)  -- 1=Deposit, 11=Chargeback
ORDER BY acb.Occurred
```

### 8.3 Check MIMO pipeline for a chargeback

```sql
SELECT
    w.CID,
    w.CreditID,
    atm.ActionID,
    atm.Status,
    atm.CurrentTry,
    cm.BSLRealFunds
FROM Trade.BSLUsersWhiteList w WITH (NOLOCK)
JOIN Customer.CustomerMoney cm WITH (NOLOCK) ON cm.CID = w.CID
LEFT JOIN Internal.ActionsToExecute_MIMOOperations atm WITH (NOLOCK)
    ON atm.Params LIKE '%CreditID Value="' + CAST(w.CreditID AS VARCHAR) + '"%'
WHERE w.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceChargeBack | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceChargeBack.sql*
