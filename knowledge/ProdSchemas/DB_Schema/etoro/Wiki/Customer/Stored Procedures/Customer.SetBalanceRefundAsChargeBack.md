# Customer.SetBalanceRefundAsChargeBack

> Processes a refund that is administratively treated as a chargeback: credits Credit, RealizedEquity, and TotalCash, logs CreditTypeID=16 (RefundAsChargeBack), triggers MIMO BSL recalculation, sends payment notification, and reports to PiggyBank/affiliate tracking with Type=4 (ChargeBack type).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @Payment BIGINT (cents), @DepositID INT, @DepositRollbackID INT; @ErrOut OUTPUT; raises on error via THROW |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetBalanceRefundAsChargeBack` handles a hybrid scenario: a refund that is processed using chargeback accounting conventions. This occurs when an eToro-initiated refund needs to be reported to affiliate systems as a chargeback event (Type=4) rather than a regular refund (Type=5). The credit type (CreditTypeID=16) distinguishes these events in the credit history from both regular refunds (12) and bank chargebacks (11).

The balance logic is identical to `SetBalanceRefund`: three-field update (Credit + RealizedEquity + TotalCash). Key differences are:
- CreditTypeID=16 in the credit record.
- Affiliate events use `Type=4` (matching ChargeBack, not Type=5 for Refund).
- The payment message to svcPayment correctly uses CreditTypeID=16.

**Known code anomalies**:
1. `@Payment` passed to `SetBalanceInsertCredit_Native` uses `ISNULL(@CreditID, 0)` instead of `ISNULL(@CreditChange, 0)` - the CreditID variable is NULL at the time of the call (CreditID hasn't been generated yet), so effectively passes 0. This means the credit record's `Payment` column is always 0 rather than the actual amount. This is a known copy-paste bug.
2. The MIMO XML contains `CreditTypeID Value="12"` (Refund) instead of `"16"` (RefundAsChargeBack) - another copy-paste artifact from `SetBalanceRefund`.

---

## 2. Business Logic

### 2.1 Cent-to-Dollar Conversion

**Rules**:
- `@CreditChange = CAST(@Payment AS MONEY) / 100`

### 2.2 Three-Field Balance Update

**Rules**:
- `Credit += @CreditChange`
- `RealizedEquity += @CreditChange`
- `TotalCash += @CreditChange`
- ISNULL wrappers used.

### 2.3 Credit Record with @Payment Bug

**What**: Logs CreditTypeID=16 (RefundAsChargeBack) credit event.

**Rules**:
- `@CreditTypeID = 16` (hardcoded)
- `@Payment = ISNULL(@CreditID, 0)` - **bug**: passes 0 because @CreditID is NULL at this point; should be `@CreditChange`.
- `@TotalCashChange = @CreditChange` (correctly reflects the cash change).
- Returns `@CreditID OUTPUT`.

### 2.4 MIMO Trigger with Type Mismatch

**Rules**:
- XML: `<Root><CreditID Value="{id}"/><CreditTypeID Value="12"/><CID Value="{cid}"/></Root>` - **copy-paste artifact**: uses 12 (Refund) instead of 16 (RefundAsChargeBack). PostMIMOOperations receives CreditTypeID=12 for BSL recalculation.
- INSERT into `Internal.ActionsToExecute_MIMOOperations` and `Trade.BSLUsersWhiteList`.

### 2.5 Affiliate Notification (Type=4, ChargeBack convention)

**Rules**:
- Same credit absorption logic as SetBalanceChargeBack / SetBalanceRefund.
- `QueuePiggyBankAdd` with `Type=4` (ChargeBack event type).
- `QueueAffiliateTraderCreditAdd` with `Type=4`, `IsFirstDeposit=0`, `CreditID=@CreditID`, `GCID=@GCID`.
- Only for real accounts (IsReal=1) with PlayerLevelID != 4.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID receiving the refund-as-chargeback. |
| 2 | @Payment | BIGINT | NO | - | VERIFIED | Refund amount in CENTS. BIGINT. Divided by 100 for dollars. |
| 3 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Description stored in credit history. |
| 4 | @DepositID | INT | NO | - | CODE-BACKED | Original deposit being refunded. |
| 5 | @ManagerID | INT | NO | - | CODE-BACKED | Admin/manager who authorized the event. |
| 6 | @DepositRollbackID | INT | NO | - | CODE-BACKED | Rollback tracking reference. Passed to SetBalanceInsertCredit_Native. |
| 7 | @ErrOut | NVARCHAR(4000) | YES | '' (OUTPUT) | CODE-BACKED | OUTPUT: error details on failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | UPDATE Credit, RealizedEquity, TotalCash |
| @CID | Customer.CustomerStatic | READ | IsReal, tracking fields, GCID, PlayerLevelID |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs CreditTypeID=16 refund-as-chargeback record |
| @CID | Internal.ActionsToExecute_MIMOOperations | INSERT | Queues async BSL recalculation (MIMO XML shows type 12 due to copy-paste bug) |
| @CID, @CreditID | Trade.BSLUsersWhiteList | INSERT | Suspends BSL enforcement during MIMO window |
| @CID | Customer.SendEvent | Caller (EXEC) | Sends event-9 (zero balance alert) if NewCredit <= 0 |
| - | svcPayment (Service Broker) | SEND | Notifies payment queue (DataAffected correctly uses CreditTypeID=16) |
| - | Broker.QueuePiggyBankAdd | Caller (EXEC) | PiggyBank reporting, Type=4 |
| - | Broker.QueueAffiliateTraderCreditAdd | Caller (EXEC) | Affiliate tracking, Type=4 |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central balance router delegates CreditTypeID=16 (RefundAsChargeBack) events here |
| Billing refund-as-chargeback pipeline | External | Caller | Called when a refund needs chargeback-style affiliate accounting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceRefundAsChargeBack (procedure)
+-- Customer.CustomerMoney (table) [UPDATE Credit, RealizedEquity, TotalCash]
+-- Customer.CustomerStatic (table) [READ IsReal, tracking fields]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit CreditTypeID=16]
|     +-- History.ActiveCreditRecentMemoryBucket (table)
+-- Internal.ActionsToExecute_MIMOOperations (table) [INSERT MIMO trigger]
+-- Trade.BSLUsersWhiteList (table) [INSERT BSL whitelist entry]
+-- Customer.SendEvent (procedure) [zero-balance alert, conditional]
+-- Broker.QueuePiggyBankAdd (procedure) [PiggyBank, Type=4]
+-- Broker.QueueAffiliateTraderCreditAdd (procedure) [affiliate, Type=4]
```

---

### 6.1 Objects This Depends On

Identical to `Customer.SetBalanceRefund` with CreditTypeID=16 instead of 12.

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - Credit, RealizedEquity, TotalCash |
| Customer.CustomerStatic | Table | SELECT - IsReal, tracking fields |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts CreditTypeID=16 record |
| Internal.ActionsToExecute_MIMOOperations | Table | INSERT - MIMO trigger |
| Trade.BSLUsersWhiteList | Table | INSERT - BSL whitelist |
| Customer.SendEvent | Procedure | EXEC - zero-balance alert |
| Broker.QueuePiggyBankAdd | Procedure | EXEC - PiggyBank (Type=4) |
| Broker.QueueAffiliateTraderCreditAdd | Procedure | EXEC - affiliate tracking (Type=4) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for CreditTypeID=16 (RefundAsChargeBack) events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CreditTypeID=16 | Classification | RefundAsChargeBack: eToro-initiated refund processed with chargeback accounting conventions |
| @Payment = ISNULL(@CreditID, 0) bug | Known defect | Credit record Payment column always 0; @CreditID is NULL at time of EXEC. TotalCashChange is correct. |
| MIMO XML CreditTypeID=12 bug | Known defect | PostMIMOOperations receives type 12 instead of 16 - copy-paste from SetBalanceRefund |
| Affiliate Type=4 | Classification | Uses ChargeBack affiliate type (4), not Refund (5) - reflects the "as chargeback" nature |

---

## 8. Sample Queries

### 8.1 Find RefundAsChargeBack events for a customer

```sql
SELECT
    acb.CreditID,
    acb.Payment AS PaymentInRecord,  -- note: always 0 due to bug
    acb.TotalCashChange AS ActualAmountRefunded,  -- use this for actual amount
    acb.DepositID,
    acb.DepositRollbackID,
    acb.Credit AS CreditAfterRefund,
    acb.Description,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 16
ORDER BY acb.Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceRefundAsChargeBack | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceRefundAsChargeBack.sql*
