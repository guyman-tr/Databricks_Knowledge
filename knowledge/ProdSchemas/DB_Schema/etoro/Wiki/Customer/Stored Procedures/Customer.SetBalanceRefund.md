# Customer.SetBalanceRefund

> Processes a deposit refund: credits Credit, RealizedEquity, and TotalCash by the refund amount, logs CreditTypeID=12 (Refund), triggers MIMO BSL recalculation, sends payment notification, and reports the net-effective amount to PiggyBank and affiliate tracking (Type=5, real accounts only).

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT, @Payment BIGINT (cents), @DepositID INT, @DepositRollbackID INT; @ErrOut OUTPUT; raises on error via THROW |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetBalanceRefund` handles the case where eToro (not the bank) initiates the return of deposit funds to a customer. Refunds differ from chargebacks in source: a refund is eToro-initiated (e.g., customer requested account closure or trading terms refund), while a chargeback is bank-initiated (e.g., disputed transaction). Both result in the same three-field balance change but use distinct CreditTypeIDs (12=Refund, 11=ChargeBack) for audit differentiation.

The procedure is structurally identical to `SetBalanceChargeBack` with these differences:
- `CreditTypeID = 12` (Refund) vs 11 (ChargeBack)
- Affiliate event type `Type=5` (Refund) vs `Type=4` (ChargeBack)
- PiggyBank reporting still active (`Broker.QueuePiggyBankAdd`) - not yet removed from refund flow as of March 2026
- Note: the Service Broker payment message contains a hardcoded `11` in the `@DataAffected` string - this appears to be a historical copy-paste from `SetBalanceChargeBack` and represents a known discrepancy.

---

## 2. Business Logic

### 2.1 Cent-to-Dollar Conversion

**What**: @Payment (BIGINT) in cents converted to MONEY dollars.

**Rules**:
- `@CreditChange = CAST(@Payment AS MONEY) / 100`

### 2.2 Three-Field Balance Update

**What**: Credit, RealizedEquity, and TotalCash all increased by the refund amount.

**Rules**:
- `Credit += @CreditChange`
- `RealizedEquity += @CreditChange`
- `TotalCash += @CreditChange`
- ISNULL wrappers protect against NULL.

### 2.3 MIMO BSL Recalculation Trigger

**What**: Queues async BSL recalculation (without bonus check, unlike Deposit/Compensation).

**Rules**:
- XML: `<Root><CreditID Value="{id}"/><CreditTypeID Value="12"/><CID Value="{cid}"/></Root>`
- No `CheckBonus="1"` flag (unlike Deposit and Compensation).
- INSERT into `Internal.ActionsToExecute_MIMOOperations` and `Trade.BSLUsersWhiteList`.

### 2.4 Affiliate Credit Absorption Logic

**What**: For real accounts (IsReal=1, PlayerLevelID != 4), computes net-effective payment for affiliate tracking.

**Rules**:
- Same credit absorption formula as SetBalanceChargeBack (see that doc for full table).
- Calls `Broker.QueuePiggyBankAdd` with `Type=5` (Refund).
- Calls `Broker.QueueAffiliateTraderCreditAdd` with `Type=5`, `IsFirstDeposit=0`, `CreditID=@CreditID`, `GCID=@GCID`.

### 2.5 Known Discrepancy in Payment Message

**What**: The Service Broker payment message hardcodes `11` (ChargeBack) instead of `12` (Refund).

**Rules**:
- `@DataAffected = CAST(@CID AS VARCHAR) + ';' + CAST(11 AS VARCHAR) + ';...'` - uses `11`, not `12`.
- This is a known historical copy-paste artifact from when RefundSetBalance was based on ChargeBack code.
- The credit record itself correctly uses CreditTypeID=12.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID receiving the refund. |
| 2 | @Payment | BIGINT | NO | - | VERIFIED | Refund amount in CENTS. BIGINT. Divided by 100 for dollars. Typically positive (funds returned to customer). |
| 3 | @Description | VARCHAR(255) | NO | - | CODE-BACKED | Human-readable description of the refund reason, stored in the credit history. |
| 4 | @DepositID | INT | NO | - | CODE-BACKED | Original deposit ID being refunded. Links the credit record to the source deposit transaction. |
| 5 | @ManagerID | INT | NO | - | CODE-BACKED | Admin/manager who authorized the refund. Stored in the credit record. |
| 6 | @DepositRollbackID | INT | NO | - | CODE-BACKED | Rollback tracking reference for this deposit reversal. Passed to SetBalanceInsertCredit_Native. |
| 7 | @ErrOut | NVARCHAR(4000) | YES | '' (OUTPUT) | CODE-BACKED | OUTPUT: error details on failure. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.CustomerMoney | MODIFIER | UPDATE Credit, RealizedEquity, TotalCash += refund amount |
| @CID | Customer.CustomerStatic | READ | IsReal, ProviderID, CountryID, GCID, PlayerLevelID |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs CreditTypeID=12 refund credit record |
| @CID | Internal.ActionsToExecute_MIMOOperations | INSERT | Queues async BSL recalculation (no CheckBonus) |
| @CID, @CreditID | Trade.BSLUsersWhiteList | INSERT | Suspends BSL enforcement during MIMO window |
| @CID | Customer.SendEvent | Caller (EXEC) | Sends event-9 (zero balance alert) if NewCredit <= 0 |
| - | svcPayment (Service Broker) | SEND | Notifies payment queue of refund event (note: message hardcodes CreditTypeID=11) |
| - | Broker.QueuePiggyBankAdd | Caller (EXEC) | Reports refund to PiggyBank (Type=5, real accounts only) |
| - | Broker.QueueAffiliateTraderCreditAdd | Caller (EXEC) | Reports refund to affiliate tracking (Type=5, real accounts only) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central balance router delegates CreditTypeID=12 (Refund) events here |
| Billing refund pipeline | External | Caller | Called when an eToro-initiated deposit refund is processed |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceRefund (procedure)
+-- Customer.CustomerMoney (table) [UPDATE Credit, RealizedEquity, TotalCash]
+-- Customer.CustomerStatic (table) [READ IsReal, tracking fields, GCID]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit CreditTypeID=12]
|     +-- History.ActiveCreditRecentMemoryBucket (table)
+-- Internal.ActionsToExecute_MIMOOperations (table) [INSERT MIMO trigger]
+-- Trade.BSLUsersWhiteList (table) [INSERT BSL whitelist entry]
+-- Customer.SendEvent (procedure) [zero-balance alert, conditional]
+-- Broker.QueuePiggyBankAdd (procedure) [PiggyBank tracking, real accounts only]
+-- Broker.QueueAffiliateTraderCreditAdd (procedure) [affiliate tracking, real accounts only]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerMoney | Table | UPDATE - Credit, RealizedEquity, TotalCash |
| Customer.CustomerStatic | Table | SELECT - IsReal, ProviderID, CountryID, GCID, PlayerLevelID |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts CreditTypeID=12 refund record |
| Internal.ActionsToExecute_MIMOOperations | Table | INSERT - MIMO BSL recalculation trigger |
| Trade.BSLUsersWhiteList | Table | INSERT - suspends BSL during MIMO window |
| Customer.SendEvent | Procedure | EXEC - zero balance alert (conditional) |
| Broker.QueuePiggyBankAdd | Procedure | EXEC - PiggyBank reporting (real accounts only) |
| Broker.QueueAffiliateTraderCreditAdd | Procedure | EXEC - affiliate tracking (real accounts only) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for CreditTypeID=12 (Refund) events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CreditTypeID=12 (Refund) | Hardcoded | Distinguishes refunds (eToro-initiated) from chargebacks (bank-initiated, CreditTypeID=11) |
| Payment message CreditType=11 bug | Known issue | @DataAffected hardcodes 11 (ChargeBack) in Service Broker message - copy-paste artifact. Credit record correctly uses 12. |
| PiggyBank still active | 2026 state | Unlike Deposit (removed Dec 2024), refunds still report to Broker.QueuePiggyBankAdd with Type=5 |
| Affiliate Type=5 | Classification | Type 5 = Refund event type in Broker.QueuePiggyBankAdd and QueueAffiliateTraderCreditAdd taxonomies |
| No CheckBonus in MIMO | Design | Refunds do not trigger bonus recalculation (unlike Deposit and Compensation) |

---

## 8. Sample Queries

### 8.1 Find all refunds for a customer

```sql
SELECT
    acb.CreditID,
    acb.Payment AS RefundAmountUSD,
    acb.DepositID,
    acb.DepositRollbackID,
    acb.Credit AS CreditAfterRefund,
    acb.RealizedEquity AS EquityAfterRefund,
    acb.Description,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 12
ORDER BY acb.Occurred DESC
```

### 8.2 Compare deposit and its refund

```sql
DECLARE @DepositID INT = 77777;

SELECT
    acb.CreditTypeID,
    ct.Name AS EventType,
    acb.Payment AS AmountUSD,
    acb.RealizedEquity,
    acb.Occurred
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = acb.CreditTypeID
WHERE acb.DepositID = @DepositID
    AND acb.CreditTypeID IN (1, 12)  -- 1=Deposit, 12=Refund
ORDER BY acb.Occurred
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8.5/10, Logic: 8.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceRefund | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceRefund.sql*
