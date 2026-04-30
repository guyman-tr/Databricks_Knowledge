# Customer.SetBalanceDeposit

> Processes a customer deposit: verifies the deposit is not already handled (idempotency), updates Credit/RealizedEquity/TotalCash, logs CreditTypeID=1, triggers MIMO BSL recalculation (production only), updates monthly quota, sends payment and offline notifications, and reports the first-time deposit (FTD) to affiliate tracking.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INTEGER, @Payment INTEGER (cents), @DepositID INTEGER; @ErrOut OUTPUT; RAISERROR 60030 if already processed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`SetBalanceDeposit` is the central database entry point when a customer's deposit is approved and credited to their eToro account. It is the most complex single-deposit procedure in the Customer schema.

The procedure performs:
1. **Idempotency check**: Reads `Billing.Deposit.IsSetBalanceCompleted` before opening a transaction. If already processed, raises error 60030 ("Deposit already handled") and returns immediately - preventing double-crediting on retry.
2. **IBAN internal transfer detection**: If the deposit is from an IBAN internal transfer (FlowID IN (1,2), FundingTypeID=33), overrides `@MoveMoneyReasonID = 5`.
3. **Three-field balance update**: Credit, RealizedEquity, and TotalCash all increase by the deposit amount.
4. **MIMO trigger** (production only): Inserts into `Internal.ActionsToExecute_MIMOOperations` with `CheckBonus="1"` - triggers async BSL and bonus recalculation by `PostMIMOOperations`.
5. **Monthly quota update**: Calls `Billing.UpdateMonthlyProcessingQuota`.
6. **Payment notification**: Sends deposit event to `svcPayment` via Service Broker.
7. **Offline notification**: Sends template-7 (deposit) notification to customers not currently logged in.
8. **First-time deposit (FTD) detection**: Uses `sp_getapplock` for concurrency safety, then checks `Billing.Deposit` for prior FTDs. Calls `Broker.QueueAffiliateTraderCreditAdd` with `IsFirstDeposit` flag - only for FTDs since December 2024.

PiggyBank tracking was removed in December 2024.

---

## 2. Business Logic

### 2.1 Pre-Transaction Idempotency Check

**What**: Before opening the transaction, verifies the deposit has not already been processed.

**Columns/Parameters Involved**: `Billing.Deposit.IsSetBalanceCompleted`, `@DepositID`

**Rules**:
- `SELECT @OrigIsSetBalanceCompleted = IsSetBalanceCompleted FROM Billing.Deposit WHERE DepositID = @DepositID`
- If `@OrigIsSetBalanceCompleted = 1`: `RAISERROR(60030, 16, 1, 'Deposit already handled')` and `RETURN 60030`.
- Prevents balance double-credit on any retry or duplicate invocation.

### 2.2 IBAN Internal Transfer Override

**What**: Automatically classifies IBAN internal transfers with a specific MoveMoneyReasonID.

**Rules**:
- `IF EXISTS(SELECT 1 FROM Billing.Deposit d JOIN Billing.Funding f ON d.FundingID = f.FundingID WHERE d.DepositID = @DepositID AND d.FlowID IN (1,2) AND f.FundingTypeID = 33)`: `SET @MoveMoneyReasonID = 5`
- Caller-supplied @MoveMoneyReasonID is overridden for IBAN internal transfers.

### 2.3 Three-Field Balance Increment

**What**: All three cash balance fields are increased by the deposit amount.

**Columns/Parameters Involved**: `Credit`, `RealizedEquity`, `TotalCash`

**Rules**:
- `@CreditChange = CAST(@Payment AS MONEY) / 100`
- `Credit += @CreditChange`
- `RealizedEquity += @CreditChange`
- `TotalCash += @CreditChange`
- `BSLRealFunds` is NOT updated here - handled asynchronously by PostMIMOOperations via MIMO trigger.

### 2.4 MIMO BSL Recalculation Trigger (Production Only)

**What**: Queues async BSL + bonus recalculation, but only on production (not demo).

**Columns/Parameters Involved**: `Internal.ActionsToExecute_MIMOOperations`, `Maintenance.Feature`

**Rules**:
- `IF EXISTS(SELECT 1 FROM Maintenance.Feature WHERE FeatureID = 22 AND CAST(Value AS INT) = 1)`: insert into MIMO operations.
- XML: `<Root><CreditID Value="{id}"/><CreditTypeID Value="1"/><CID Value="{cid}"/><CheckBonus Value="1"/></Root>`
- Demo databases (FeatureID=22 Value=0) do NOT get MIMO trigger - design decision added January 2022 (DBA-913).
- Always inserts into `Trade.BSLUsersWhiteList` regardless of environment.

### 2.5 Monthly Processing Quota Update

**What**: Reports the deposit amount to the monthly quota tracking system.

**Rules**:
- `EXEC Billing.UpdateMonthlyProcessingQuota @DepositID, @CreditChange`
- Added May 2018 for PSP quota monitoring.

### 2.6 Payment Notification

**What**: Sends deposit event to svcPayment and a secondary message.

**Rules**:
- Format 1: `"{CID};1;{DepositID};{Payment};{NewCredit*100};{datetime};{RealizedEquity};0;"` -> svcPayment via Service Broker.
- `END CONVERSATION @Handle` after send.
- Format 2 (2nd message for internal tracking): `"5;{CID};{CreditChange}"`.

### 2.7 First-Time Deposit (FTD) Detection

**What**: Determines if this is the customer's first ever deposit for affiliate commission purposes.

**Columns/Parameters Involved**: `Billing.Deposit.IsFTD`, `@IsFirstDeposit`

**Rules**:
- Uses `sp_getapplock @Resource=@CID, @LockMode='Exclusive'` to prevent race conditions on simultaneous deposits.
- `IF NOT EXISTS(SELECT 1 FROM Billing.Deposit WHERE CID=@CID AND DepositID <> @DepositID AND IsFTD=1)`: @IsFirstDeposit=1.
- `Broker.QueueAffiliateTraderCreditAdd` called ONLY when `@IsFirstDeposit = 1` (changed December 2024).
- PiggyBank (`Broker.QueuePiggyBankAdd`) was removed December 2024.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID receiving the deposit. |
| 2 | @Payment | INTEGER | NO | - | VERIFIED | Deposit amount in CENTS. Divided by 100 for dollars. Example: 100000 = $1,000.00 deposit. |
| 3 | @Description | VARCHAR(255) | YES | NULL | CODE-BACKED | Human-readable description stored in the credit history record. |
| 4 | @PositionID | BIGINT | YES | NULL | CODE-BACKED | Position reference if the deposit is linked to a specific position event. Rarely used for standard deposits. |
| 5 | @DepositID | INTEGER | YES | NULL | CODE-BACKED | Deposit transaction ID from Billing.Deposit. Used for idempotency check, FTD detection, quota update, and credit record linkage. |
| 6 | @ErrOut | NVARCHAR(4000) | YES | '' (OUTPUT) | CODE-BACKED | OUTPUT: error details on failure. Format: "SP - Schema.Proc | ERROR_NUMBER: ... ERROR_MESSAGE: ...". Used by THROW 60000 error propagation. |
| 7 | @MoveMoneyReasonID | INT | YES | NULL | CODE-BACKED | Internal money movement reason code. Automatically overridden to 5 for IBAN internal transfers (FundingTypeID=33). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @DepositID | Billing.Deposit | READ | Idempotency check (IsSetBalanceCompleted), FTD detection (IsFTD), IBAN detection (FlowID) |
| @DepositID | Billing.Funding | READ | IBAN transfer detection (FundingTypeID=33) |
| @CID | Customer.CustomerMoney | MODIFIER | UPDATE Credit, RealizedEquity, TotalCash += deposit amount |
| @CID | Customer.CustomerStatic | READ | IsReal, ProviderID, CountryID, GCID, tracking fields for affiliate reporting |
| @CID | Customer.SetBalanceInsertCredit_Native | Caller (EXEC) | Logs CreditTypeID=1 deposit credit record |
| - | Maintenance.Feature | READ | FeatureID=22 (production flag) - controls MIMO trigger |
| @CID | Internal.ActionsToExecute_MIMOOperations | INSERT | Queues async BSL + bonus recalculation (production only) |
| @CID, @CreditID | Trade.BSLUsersWhiteList | INSERT | Suspends BSL enforcement during MIMO window |
| @DepositID | Billing.UpdateMonthlyProcessingQuota | Caller (EXEC) | Updates PSP monthly quota tracking |
| - | svcPayment (Service Broker) | SEND | Notifies payment queue of deposit event |
| @CID | Customer.CustomerStatic | READ | IsReal check for offline notification |
| @CID | Customer.Login | READ | Checks if customer is currently logged in (offline notification) |
| @CID | Customer.SendMessage | Caller (EXEC) | Sends template-7 deposit notification to offline customers |
| @CID | Customer.SendEvent | Caller (EXEC) | Sends event-9 (zero balance alert) if NewCredit <= 0 |
| @CID | Broker.QueueAffiliateTraderCreditAdd | Caller (EXEC) | Reports first-time deposit to affiliate tracking (FTD only since Dec 2024) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller | Central balance router delegates CreditTypeID=1 (Deposit) events here |
| Billing deposit pipeline | External | Caller | Called when a deposit is approved and ready to be credited |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceDeposit (procedure)
+-- Billing.Deposit (table) [READ IsSetBalanceCompleted, IsFTD, FlowID]
+-- Billing.Funding (table) [READ FundingTypeID for IBAN detection]
+-- Customer.CustomerMoney (table) [UPDATE Credit, RealizedEquity, TotalCash]
+-- Customer.CustomerStatic (table) [READ IsReal, tracking fields, GCID]
+-- Customer.SetBalanceInsertCredit_Native (procedure) [INSERT credit CreditTypeID=1]
|     +-- History.ActiveCreditRecentMemoryBucket (table)
+-- Maintenance.Feature (table) [READ FeatureID=22 production flag]
+-- Internal.ActionsToExecute_MIMOOperations (table) [INSERT MIMO+bonus trigger, production only]
+-- Trade.BSLUsersWhiteList (table) [INSERT BSL whitelist entry]
+-- Billing.UpdateMonthlyProcessingQuota (procedure) [monthly quota update]
+-- Customer.Login (table) [READ offline check]
+-- Customer.SendMessage (procedure) [template-7 offline notification]
+-- Customer.SendEvent (procedure) [zero-balance alert, conditional]
+-- Broker.QueueAffiliateTraderCreditAdd (procedure) [FTD affiliate reporting, FTD only]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | SELECT - IsSetBalanceCompleted (idempotency), IsFTD (affiliate), FlowID (IBAN) |
| Billing.Funding | Table | SELECT - FundingTypeID for IBAN internal transfer detection |
| Customer.CustomerMoney | Table | UPDATE - Credit, RealizedEquity, TotalCash += deposit |
| Customer.CustomerStatic | Table | SELECT - IsReal, ProviderID, CountryID, GCID, tracking fields |
| Customer.SetBalanceInsertCredit_Native | Procedure | EXEC - inserts CreditTypeID=1 deposit record |
| Maintenance.Feature | Table | SELECT - FeatureID=22 production environment flag |
| Internal.ActionsToExecute_MIMOOperations | Table | INSERT - MIMO + bonus recalculation trigger (production only) |
| Trade.BSLUsersWhiteList | Table | INSERT - suspends BSL during MIMO window |
| Billing.UpdateMonthlyProcessingQuota | Procedure | EXEC - monthly PSP quota tracking |
| Customer.Login | Table | SELECT - offline check for notification |
| Customer.SendMessage | Procedure | EXEC - offline deposit notification (template 7) |
| Customer.SendEvent | Procedure | EXEC - zero balance alert (conditional) |
| Broker.QueueAffiliateTraderCreditAdd | Procedure | EXEC - FTD affiliate reporting |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalance | Procedure | Calls this for CreditTypeID=1 (Deposit) events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RAISERROR(60030) | Idempotency guard | If IsSetBalanceCompleted=1, deposit was already processed. RAISERROR + RETURN prevents double-credit. |
| sp_getapplock for FTD | Concurrency | Exclusive lock on CID before FTD check prevents race condition on simultaneous first deposits |
| MIMO trigger: production only | Design | Maintenance.Feature FeatureID=22 gates the MIMO insert - demo databases skip BSL recalculation (DBA-913) |
| Affiliate reporting: FTD only | Changed Dec 2024 | QueueAffiliateTraderCreditAdd now called only when IsFirstDeposit=1. Non-FTDs no longer reported. |
| PiggyBank removed | Dec 2024 | Broker.QueuePiggyBankAdd removed from deposit flow. |
| Template 7 (not 6) | Notification | Deposit uses template 7; compensation/bonus use template 6. |
| @MoveMoneyReasonID auto-override | IBAN | Value 5 is automatically set for IBAN internal transfers regardless of caller's supplied value. |

---

## 8. Sample Queries

### 8.1 Find all deposits for a customer with FTD flag

```sql
SELECT
    acb.CreditID,
    acb.DepositID,
    acb.Payment AS DepositAmountUSD,
    acb.Credit AS CreditAfterDeposit,
    acb.RealizedEquity AS EquityAfterDeposit,
    acb.MoveMoneyReasonID,
    acb.Description,
    acb.Occurred,
    bd.IsFTD
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
LEFT JOIN Billing.Deposit bd WITH (NOLOCK) ON bd.DepositID = acb.DepositID
WHERE acb.CID = 12345
    AND acb.CreditTypeID = 1
ORDER BY acb.Occurred
```

### 8.2 Check idempotency status for a deposit

```sql
SELECT
    DepositID,
    CID,
    IsSetBalanceCompleted,
    IsFTD,
    Amount,
    FlowID
FROM Billing.Deposit WITH (NOLOCK)
WHERE DepositID = 77777
```

### 8.3 Total deposits by customer for current month with FTD detection

```sql
SELECT
    acb.CID,
    COUNT(*) AS DepositCount,
    SUM(acb.Payment) AS TotalDepositedUSD,
    MIN(acb.Occurred) AS FirstDepositDate,
    MAX(acb.Occurred) AS LastDepositDate
FROM History.ActiveCreditBucket_VW acb WITH (NOLOCK)
WHERE acb.CreditTypeID = 1
    AND acb.Occurred >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETUTCDATE()), 0)
GROUP BY acb.CID
ORDER BY TotalDepositedUSD DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Multi-Currency Balance API](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14028570661/Multi-Currency+Balance+API) | Confluence | MIMO pipeline context for deposit flow; BSL recalculation pipeline triggered by deposit events. |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceDeposit | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceDeposit.sql*
