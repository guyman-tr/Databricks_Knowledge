# History.WithdrawToFundingAction

> High-volume append-only audit log of every insert and update to Billing.WithdrawToFunding - captures the full payment processing pipeline history for each withdrawal-to-funding-method transaction, including payment provider responses, exchange rates, and routing XML.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | WithdrawToFundingActionID (INT, IDENTITY, CLUSTERED PK with PAGE compression) |
| **Partition** | No - stored on [HISTORY] filegroup with PAGE compression |
| **Indexes** | 7 active (CLUSTERED PK + 6 NC covering BW2F_ID, FundingID, ModificationDate, WithdrawID+FundingID combos) |

---

## 1. Business Meaning

History.WithdrawToFundingAction is the payment-gateway audit trail for eToro's withdrawal processing pipeline. Where History.WithdrawAction tracks the top-level cashout status lifecycle, this table tracks the lower-level payment processing detail - every action taken against a specific Billing.WithdrawToFunding record (BW2F_ID), which represents the pairing of a withdrawal request with a specific customer payment method (bank account, card, crypto wallet, etc.).

With 12.8 million rows spanning 2016 to present and new rows being inserted continuously, this is one of the largest and most active tables in the History schema. It is used by operations teams to trace payment processing failures, by finance for reconciliation of rejected/reversed payments, and by the CashoutTool and BO backend for "payment orders" screens showing processing history.

Each row captures one INSERT (new BW2F record) or UPDATE (status change on an existing BW2F record) to Billing.WithdrawToFunding, including the full XML routing blob (WithdrawData), financial details (Amount, ExchangeRate, BaseExchangeRate, ExchangeFee), provider identifiers (MerchantAccountID, SchemeId, ResponseID), and the resulting cashout statuses.

**Key architecture**: Rows are written by two helper procedures that manage Billing.WithdrawToFunding:
- `Billing.InsertWithdraw2Funding`: Inserts the new BW2F record, then immediately inserts the same data into History using OUTPUT from the insert.
- `Billing.UpdateWithdraw2Funding`: Updates the existing BW2F record, writing history via the same OUTPUT pattern.

---

## 2. Business Logic

### 2.1 Payment Order Processing Lifecycle

**What**: Each (WithdrawID, FundingID) pair has a Billing.WithdrawToFunding record (BW2F). Every INSERT or UPDATE to that record generates a row here, forming a complete action history of that payment order.

**Columns/Parameters Involved**: `WithdrawID`, `FundingID`, `BW2F_ID`, `CashoutActionStatusID`, `CashoutStatusID`, `ModificationDate`

**Rules**:
- `BW2F_ID` = the ID from Billing.WithdrawToFunding - the PK of the payment order being tracked
- `CashoutActionStatusID` distinguishes INSERT from UPDATE actions (see Section 2.2)
- Multiple rows per BW2F_ID are normal - one per status transition
- `CashoutStatusID` captures the cashout status at the time of the action (from Dictionary.CashoutStatus)
- The combination (BW2F_ID, ModificationDate DESC) gives the latest state for a payment order

**Typical lifecycle** (one BW2F_ID, multiple WTFA rows):
```
Action 1: CashoutActionStatusID=1, CashoutStatusID=1  (Pending) - payment order created
Action 2: CashoutActionStatusID=2, CashoutStatusID=11 (SentToBilling) - routed
Action 3: CashoutActionStatusID=2, CashoutStatusID=10 (SentToProvider) - dispatched
Action 4: CashoutActionStatusID=2, CashoutStatusID=8  (RejectedByProvider) - 62% end here
  or
Action 4: CashoutActionStatusID=2, CashoutStatusID=3  (Processed) - 5.4% end here
```

### 2.2 CashoutActionStatusID

**What**: Distinguishes the type of database operation that produced this history row.

**Columns/Parameters Involved**: `CashoutActionStatusID`

| Value | Meaning | Count | Pct |
|-------|---------|-------|-----|
| 0 | Legacy/unknown (pre-standardization) | 16,527 | 0.1% |
| 1 | INSERT - new payment order created | 1,408,524 | 11% |
| 2 | UPDATE - existing payment order status changed | 11,403,409 | 89% |

### 2.3 CashoutStatusID Distribution

**What**: The cashout status of the withdrawal at the moment this action was recorded.

**Columns/Parameters Involved**: `CashoutStatusID`

| CashoutStatusID | Status Name | Count | Pct | Notes |
|-----------------|------------|-------|-----|-------|
| 8 | RejectedByProvider | 8,005,915 | 62% | Dominant - most payment attempts fail at provider |
| 11 | SentToBilling | 892,931 | 7% | Routed to billing system |
| 14 | PendingReview | 819,857 | 6% | Under compliance review |
| 3 | Processed | 693,476 | 5% | Successfully paid |
| 4 | Canceled | 558,412 | 4% | Canceled before payment |
| 10 | SentToProvider | 507,224 | 4% | Dispatched to external provider |
| 12 | ReceivedByBilling | 428,700 | 3% | Billing confirmed receipt |
| 2 | InProcess | 377,965 | 3% | Being processed |
| 6 | (other) | 88,775 | 1% | - |
| 9 | PendingByProvider | 97,045 | 1% | Awaiting provider confirmation |
| others | Various | ~375,000 | 3% | 13=Failed, 17=PartialReverse, 15=UnderReview, etc. |

### 2.4 WithdrawData - Payment Method XML

**What**: XML blob containing payment-method-specific routing data required by the payment provider. Structure varies by funding type.

**Columns/Parameters Involved**: `WithdrawData`

**Rules**:
- Each FundingType has its own XML schema (referenced via Dictionary.GetXMLSchema in comments)
- Common fields include IBAN, account number, BIC, sort code, beneficiary name, country, address
- Crypto/platform fields include GCID, PlatformAccountID
- Wire/confirmation fields include ConfirmationNumberAsString

**Examples**:
```xml
<!-- Bank wire (SEPA) -->
<Withdraw><PayeeNameAsString>...</PayeeNameAsString><IBANCodeAsString>SE45...</IBANCodeAsString>
         <CountryIDAsInteger>196</CountryIDAsInteger></Withdraw>

<!-- UK bank account -->
<Withdraw><SortCodeAsString>041335</SortCodeAsString><IbanAsString>GB69...</IbanAsString>
         <AccountNumberAsString>11201119</AccountNumberAsString><BicAsString>MRMI...</BicAsString></Withdraw>

<!-- Internal/confirmation -->
<Withdraw><ConfirmationNumberAsString>1740278</ConfirmationNumberAsString></Withdraw>
```

### 2.5 Exchange Rate Fields

**What**: Capture the FX rate and fee applied when the withdrawal is processed in a currency different from the customer's account currency.

**Columns/Parameters Involved**: `BaseExchangeRate`, `ExchangeRate`, `ExchangeFee`, `RefundAmountInDepositCurrency`, `ProcessCurrencyID`

**Rules**:
- `BaseExchangeRate` = raw market exchange rate (dbo.dtPrice precision)
- `ExchangeRate` = effective rate applied (base + fee) (dbo.dtPrice precision)
- `ExchangeFee` = FX fee in basis points (100 = 1%)
- `RefundAmountInDepositCurrency` = amount expressed in deposit currency after conversion
- NULL when ProcessCurrencyID = account currency (no FX needed)

---

## 3. Data Overview

| WTFAID | WithdrawID | FundingID | BW2F_ID | CashoutActionStatusID | CashoutStatusID | MerchantAccountID | Amount | Meaning |
|--------|------------|-----------|---------|----------------------|-----------------|------------------|--------|---------|
| 12848111 | 1740278 | 2161814 | 1373515 | 1 (Insert) | 14 (PendingReview) | NULL | 145 | New payment order created, under review |
| 12848110 | 1740275 | 4160804 | 1373514 | 1 (Insert) | 14 (PendingReview) | NULL | 25 | New SEPA payment order, pending review |
| 12848109 | 1740274 | 4160802 | 1373513 | 2 (Update) | 3 (Processed) | 64 | 30 | Payment processed via merchant 64 with FX |
| 12848108 | 1740274 | 4160802 | 1373513 | 2 (Update) | 3 (Processed) | 64 | 30 | Duplicate status update same second |
| 12848107 | 1740274 | 4160802 | 1373513 | 2 (Update) | 10 (SentToProvider) | 64 | 30 | Pre-processing step for same withdrawal |

Note: 3 rows for the same BW2F_ID=1373513 show the lifecycle steps of one payment order.

Total rows: 12,828,460 | Date range: 2016-09-27 to 2026-03-21

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawToFundingActionID | INT IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing surrogate PK. IDENTITY NOT FOR REPLICATION. Sequential action identifier across all payment orders. CLUSTERED PK with PAGE compression on HISTORY filegroup. |
| 2 | WithdrawID | INT | NO | - | CODE-BACKED | The withdrawal request this payment action belongs to. Implicit FK to Billing.Withdraw. Multiple rows per WithdrawID if the withdrawal has multiple payment attempts or status transitions. |
| 3 | FundingID | INT | NO | - | CODE-BACKED | The customer's payment method (funding instrument) used in this action. Implicit FK to Billing.Funding. NC index ix_HistoryWithdrawToFundingAction_FundingID supports lookup of all actions for a funding method. |
| 4 | CashoutStatusID | INT | NO | - | CODE-BACKED | The cashout status at the time of this action. Implicit FK to Dictionary.CashoutStatus. 8=RejectedByProvider dominates at 62%. See Section 2.3 for full distribution. |
| 5 | CashoutActionStatusID | INT | NO | - | CODE-BACKED | Type of operation that produced this row: 0=legacy, 1=insert (new BW2F), 2=update (status change). See Section 2.2. Used in NC indexes as leading column for INSERT vs UPDATE partitioning. |
| 6 | ProcessCurrencyID | INT | NO | - | CODE-BACKED | Currency in which the payment was processed. Implicit FK to Dictionary.Currency. 1=USD most common. Drives FX conversion logic (BaseExchangeRate, ExchangeRate, ExchangeFee). |
| 7 | ManagerID | INT | YES | NULL | CODE-BACKED | Back-office manager who triggered this action. Implicit FK to BackOffice.Manager. 0=automated system action. NULL for some legacy rows. NC index ix_HistoryWithdrawToFundingAction_ModificationDate INCLUDES ManagerID. |
| 8 | Amount | MONEY | NO | - | CODE-BACKED | Withdrawal amount at the time of this action in the withdrawal's currency. May differ from original request amount for partial or reversed withdrawals. |
| 9 | ModificationDate | DATETIME | NO | - | CODE-BACKED | UTC timestamp of this action. Leading column in IX_WTFA_ModDate_Withdraw_Funding (time-range queries) and IX_WTFA_Withdraw_Funding_Latest (latest-state lookup). |
| 10 | Remark | VARCHAR(250) | YES | NULL | CODE-BACKED | Human-readable note about this action. Example: "Payout processed by provider". Often NULL for automated actions. |
| 11 | WithdrawData | XML | YES | NULL | CODE-BACKED | Payment-method-specific XML blob containing routing details (IBAN, BIC, sort code, account number, country, etc.) required by the payment provider. Schema varies by FundingType. See Section 2.4 for examples. |
| 12 | BW2F_ID | INT | YES | NULL | CODE-BACKED | The PK of the Billing.WithdrawToFunding record this action tracks. Central link to the payment order. NC index on (CashoutActionStatusID, BW2F_ID, ModDate) and (BW2F_ID, CashoutActionStatusID) for efficient payment-order lookups. |
| 13 | MatchStatusID | TINYINT | YES | NULL (DEFAULT) | CODE-BACKED | Reconciliation match status for this payment action. Default NULL. 0=unmatched, other values indicate match state with provider records. |
| 14 | ProtocolMIDSettingsID | INT | NO | 0 (HWTF_ProtocolMIDSettingsID) | CODE-BACKED | Payment protocol/merchant settings identifier. Default 0. Implicit FK to History.ProtocolMIDSettings. Identifies which payment protocol configuration was used. |
| 15 | AdditionalInformation | NVARCHAR(250) | YES | NULL | CODE-BACKED | Supplemental provider-specific information about this payment action. Often empty string ("") for automated actions. |
| 16 | MerchantAccountID | INT | YES | NULL | CODE-BACKED | Payment processing merchant account used for this action. NULL for actions not requiring a merchant account (e.g., internal routing steps). |
| 17 | BaseExchangeRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Raw market exchange rate at time of payment. NULL when no FX conversion needed. Uses dbo.dtPrice precision type (numeric(16,8)). |
| 18 | ExchangeFee | INT | YES | NULL | CODE-BACKED | FX fee in basis points applied to the base exchange rate. 100 = 1% fee. NULL when no FX conversion. |
| 19 | ExchangeRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Effective exchange rate applied (BaseExchangeRate + ExchangeFee adjustment). NULL when no FX conversion. |
| 20 | RefundAmountInDepositCurrency | MONEY | YES | NULL | CODE-BACKED | The withdrawal amount expressed in the customer's original deposit currency after FX conversion. Used for refund/reversal reconciliation. |
| 21 | CashoutTypeID | TINYINT | YES | NULL | CODE-BACKED | Classification of the cashout processing type: 1=automatic/standard. NULL for legacy or manual flow records. |
| 22 | CashoutModeID | TINYINT | YES | NULL | CODE-BACKED | Processing mode identifier: 1=standard mode. NULL for legacy records. Determines which processing pathway was used. |
| 23 | SchemeId | NVARCHAR(255) | YES | NULL | CODE-BACKED | Payment scheme identifier (added 2021, PAYUS-3900). Identifies the payment network or scheme used by the provider. NULL for older records or flows not using scheme routing. |
| 24 | ResponseID | INT | YES | NULL | CODE-BACKED | External payment provider response/transaction identifier (added 2021, PAYUA-2822). Links to provider's response record for reconciliation. NULL for older records. |
| 25 | RequestExecuteEntryMethodId | INT | YES | NULL | CODE-BACKED | Method identifier for how the payment request was executed. 1=standard. NULL for older records or alternate flows. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | Implicit FK | The withdrawal request this payment action traces. |
| FundingID | Billing.Funding | Implicit FK | The customer payment instrument (bank, card, wallet) used. |
| CashoutStatusID | Dictionary.CashoutStatus | Implicit FK | Status at the time of this action. |
| BW2F_ID | Billing.WithdrawToFunding | Implicit FK | The specific payment order record (BW2F) being tracked. |
| ManagerID | BackOffice.Manager | Implicit FK | Manager who triggered action when non-zero and non-null. |
| ProtocolMIDSettingsID | History.ProtocolMIDSettings | Implicit FK | Payment protocol configuration used. |
| ProcessCurrencyID | Dictionary.Currency | Implicit FK | Currency of the payment processing. |
| MerchantAccountID | Billing.MerchantAccount | Implicit FK | Merchant account used for processing. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.InsertWithdraw2Funding | BW2F_ID | Writer (INSERT via OUTPUT) | Primary writer - inserts on every new BW2F record |
| Billing.UpdateWithdraw2Funding | BW2F_ID | Writer (INSERT on UPDATE) | Inserts history rows on every BW2F status update |
| History.WithdrawToFundingAction_InsertedChangedFunding | WithdrawToFundingActionID | Companion table | Captures FundingID changes for actions in this table |
| BackOffice.GetPaymentOrderHistory | BW2F_ID | Reader | Retrieves full action history for a payment order |
| BackOffice.GetPaymentOrders | BW2F_ID | Reader | Payment orders listing with history |
| Billing.BI_Cashout_State_Report | - | Reader | BI cashout state reporting |
| dbo.InProcessCashouts_FromDate_ForDWH | - | Reader | DWH reconciliation of in-process cashouts |
| Monitor.AlertStuckWithdraws | - | Reader | Monitoring for stuck withdrawal payment orders |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.WithdrawToFundingAction (table)
  (leaf - no code-level DDL dependencies)
  No explicit FK constraints in DDL
  Implicit refs: Billing.Withdraw, Billing.Funding, Billing.WithdrawToFunding,
                 Dictionary.CashoutStatus, BackOffice.Manager
```

### 6.1 Objects This Depends On

No hard DDL dependencies (no FK constraints in CREATE TABLE DDL).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.InsertWithdraw2Funding | Stored Procedure | WRITER - inserts on new BW2F record creation |
| Billing.UpdateWithdraw2Funding | Stored Procedure | WRITER - inserts on BW2F update |
| History.WithdrawToFundingAction_InsertedChangedFunding | Table | Companion - FundingID change tracking |
| BackOffice.GetPaymentOrderHistory | Stored Procedure | READER |
| BackOffice.GetPaymentOrders | Stored Procedure | READER |
| BackOffice.GetPaymentOrders_Withdraw | Stored Procedure | READER |
| Billing.GetPaymentOrdersByIds | Stored Procedure | READER |
| Billing.BI_Cashout_State_Report | Stored Procedure | READER - BI reporting |
| Billing.GetRollbackedPaymentOrdersReport | Stored Procedure | READER |
| Billing.WithdrawToFundingMatch | Stored Procedure | READER/WRITER |
| dbo.InProcessCashouts_FromDate_ForDWH | Stored Procedure | READER - DWH |
| Monitor.AlertStuckWithdraws | Stored Procedure | READER - monitoring |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HWFA | CLUSTERED PK | WithdrawToFundingActionID ASC | - | - | Active (PAGE compression, FILLFACTOR=90) |
| IX_HistoryWithdrawToFundingAction_BW2F_ID | NONCLUSTERED | CashoutActionStatusID ASC, BW2F_ID ASC, ModificationDate ASC | - | - | Active (PAGE compression, FILLFACTOR=95) |
| IX_HistoryWithdrawToFundingAction_BW2F_IDCashoutActionStatusID | NONCLUSTERED | BW2F_ID ASC, CashoutActionStatusID ASC | - | - | Active (PAGE compression, FILLFACTOR=95) |
| IX_WTFA_ModDate_Withdraw_Funding | NONCLUSTERED | ModificationDate ASC, WithdrawID ASC, FundingID ASC, WithdrawToFundingActionID ASC | CashoutStatusID, Amount | - | Active |
| IX_WTFA_Withdraw_Funding_Latest | NONCLUSTERED | WithdrawID ASC, FundingID ASC, ModificationDate DESC, WithdrawToFundingActionID DESC | CashoutStatusID, Amount | - | Active |
| IX_WithdrawToFundingAction_ashoutStatusID | NONCLUSTERED | CashoutStatusID ASC, BW2F_ID ASC | WithdrawID, ManagerID, ModificationDate | - | Active (PAGE compression, FILLFACTOR=95) |
| ix_HistoryWithdrawToFundingAction_FundingID | NONCLUSTERED | FundingID ASC, ModificationDate ASC | ManagerID, CashoutStatusID | - | Active (PAGE compression, FILLFACTOR=95) |
| ix_HistoryWithdrawToFundingAction_ModificationDate | NONCLUSTERED | ModificationDate ASC | ManagerID, FundingID, CashoutStatusID | - | Active (PAGE compression, FILLFACTOR=95) |

Note: IX_WTFA_Withdraw_Funding_Latest (WithdrawID, FundingID, ModDate DESC) with INCLUDE is optimized for the "get latest action for this withdrawal's funding method" pattern - the most common operational query.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HWFA | PRIMARY KEY CLUSTERED | WithdrawToFundingActionID |
| DF_HistoryWithdrawToFundingAction_MatchStatusID | DEFAULT | MatchStatusID = NULL |
| HWTF_ProtocolMIDSettingsID | DEFAULT | ProtocolMIDSettingsID = 0 |

No FK constraints - all relationships are implicit.

---

## 8. Sample Queries

### 8.1 Full payment processing history for a specific withdrawal
```sql
SELECT
    wtfa.WithdrawToFundingActionID,
    wtfa.BW2F_ID,
    wtfa.FundingID,
    wtfa.CashoutActionStatusID,
    cs.Name AS CashoutStatus,
    wtfa.Amount,
    wtfa.MerchantAccountID,
    wtfa.Remark,
    wtfa.ModificationDate
FROM History.WithdrawToFundingAction wtfa WITH (NOLOCK)
INNER JOIN Dictionary.CashoutStatus cs WITH (NOLOCK)
    ON wtfa.CashoutStatusID = cs.CashoutStatusID
WHERE wtfa.WithdrawID = 1740274
ORDER BY wtfa.ModificationDate;
```

### 8.2 Latest payment action for each active withdrawal (uses optimal index)
```sql
SELECT wtfa.WithdrawID, wtfa.FundingID, wtfa.CashoutStatusID, wtfa.Amount, wtfa.ModificationDate
FROM History.WithdrawToFundingAction wtfa WITH (NOLOCK)
WHERE wtfa.WithdrawID = 1740274
    AND wtfa.FundingID = 4160802
ORDER BY wtfa.ModificationDate DESC, wtfa.WithdrawToFundingActionID DESC;
```

### 8.3 Rejected payment orders summary by date
```sql
SELECT CAST(wtfa.ModificationDate AS DATE) AS ActionDate,
       COUNT(*) AS RejectedCount,
       SUM(wtfa.Amount) AS TotalAmount
FROM History.WithdrawToFundingAction wtfa WITH (NOLOCK)
WHERE wtfa.CashoutStatusID = 8  -- RejectedByProvider
    AND wtfa.ModificationDate >= DATEADD(DAY, -30, GETUTCDATE())
GROUP BY CAST(wtfa.ModificationDate AS DATE)
ORDER BY ActionDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 25 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12+ analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.WithdrawToFundingAction | Type: Table | Source: etoro/etoro/History/Tables/History.WithdrawToFundingAction.sql*
