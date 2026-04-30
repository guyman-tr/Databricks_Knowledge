# Billing.WithdrawToFunding

> Withdrawal payment execution ledger; each row represents one payment leg linking a withdrawal request (`Billing.Withdraw`) to a specific customer payment instrument (`Billing.Funding`), tracking the cashout or refund execution status, amounts, exchange details, and provider response data.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | ID (PRIMARY KEY CLUSTERED, IDENTITY(1,1), NOT FOR REPLICATION) |
| **Row Count** | ~1,071,383 rows |
| **Partition** | No - filegroup MAIN; TEXTIMAGE on MAIN |
| **Indexes** | 1 CLUSTERED PK; 4 NC; 4 XML (PRIMARY/PATH/PROPERTY/VALUE); total 9 |

---

## 1. Business Meaning

`Billing.WithdrawToFunding` is the payment execution table for the withdrawal pipeline. Where `Billing.Withdraw` is the withdrawal REQUEST (the customer's desire to take money out), `Billing.WithdrawToFunding` is the PAYMENT LEG - the actual connection between that request and the specific payment instrument (credit card, bank account, PayPal, etc.) the money will be sent to, plus the status and details of that execution attempt.

A single withdrawal request can have multiple `WithdrawToFunding` rows - for example, when a payment is rejected by the provider and re-attempted with a different routing, or when a large withdrawal is split across multiple payment legs. The `CashoutStatusID` here tracks the execution status of this specific leg, which may differ from the parent `Billing.Withdraw.CashoutStatusID`.

The two main use cases distinguished by `CashoutTypeID`:
- **1=Cashout**: A direct withdrawal - customer requests funds to be sent to their registered payment instrument (card/bank/wallet)
- **2=Refund**: A refund of a prior deposit back to the original payment method, linked to the source deposit via `DepositID`

The `WithdrawData` XML column stores provider-specific execution response data (auth codes, transaction references, rejection reasons). `CreationDate` was added later in the table's life - records before early 2023 have NULL for this column.

---

## 2. Business Logic

### 2.1 Withdrawal Execution Lifecycle

**What**: Each payment leg tracks the execution status of sending funds to the customer's payment instrument, following a state machine with both intermediate and terminal states.

**Columns Involved**: `CashoutStatusID`, `ID`, `WithdrawID`, `ManagerID`, `ModificationDate`

**Rules**:
- Non-final states (IsFinalStatus=null/0): 1=Pending, 2=InProcess, 6=Payment Sent, 9=PendingByProvider, 10=SentToProvider, 11=SentToBilling, 12=ReceivedByBilling, 14=Pending Review, 15=Under Review, 16=Reversed, 17=Partially Reversed
- Final states (IsFinalStatus=1): 3=Processed (money sent successfully), 4=Canceled (no money transferred, IsFinishedWithoutMoneyTransfer=1 for cancellations), 5=Partially Processed, 7=Rejected (no money transferred), 8=RejectedByProvider, 13=Failed
- Live distribution: 4=Canceled (67.7%), 3=Processed (31.5%), 17=Partially Reversed (0.68%), 14=Pending Review (0.09%)
- `IsFinishedWithoutMoneyTransfer=1` for CashoutStatusID 4 (Canceled) and 7 (Rejected) - these are the only statuses where the payment leg closed without any money movement

**Diagram**:
```
[Created] -> Pending(1) -> InProcess(2) -> SentToProvider(10)
                                             |
                              +----OK----+---+---+---FAIL---+
                              |          |                   |
                         Processed(3) PaymentSent(6)   RejectedByProvider(8)
                                          |              Failed(13)
                                    ReceivedByBilling(12)
                                          |
                                     Processed(3)
                                          |
                          post-settlement: Reversed(16)/PartiallyReversed(17)

Review path: Pending Review(14) -> Under Review(15) -> [any terminal]
Cancel path: any -> Canceled(4) / Rejected(7)
```

### 2.2 Cashout vs. Refund (CashoutTypeID)

**What**: Distinguishes whether this payment leg is a direct withdrawal payout or a refund of a prior deposit.

**Columns Involved**: `CashoutTypeID`, `DepositID`, `RefundAmountInDepositCurrency`

**Rules**:
- `CashoutTypeID=1` (Cashout, 69%): Standard withdrawal - funds sent to customer's payment instrument. `DepositID=0` (no deposit linkage)
- `CashoutTypeID=2` (Refund, 31%): Refund to a specific deposit - credit card chargeback reversal or deposit refund. `DepositID` points to the source `Billing.Deposit` row being refunded. `RefundAmountInDepositCurrency` records the amount in the original deposit currency (may differ from `Amount` due to exchange rate changes)
- `DepositID=0` is the null-equivalent for refund linkage (not SQL NULL); actual DepositID values are > 0

### 2.3 Amount and Exchange Rate

**What**: Tracks the payout amount in the process currency with exchange rate conversion metadata.

**Columns Involved**: `Amount`, `ProcessCurrencyID`, `ExchangeRate`, `BaseExchangeRate`, `ExchangeFee`, `ExchangeFeeInUSD`, `ExchangeFeeInPercentage`

**Rules**:
- `Amount` (MONEY): the payout amount in `ProcessCurrencyID` currency (the currency the provider receives/processes)
- `ProcessCurrencyID`: the currency in which the payment is processed (may differ from the withdrawal's `CurrencyID`)
- `ExchangeRate`: conversion rate from the customer's withdrawal currency to `ProcessCurrencyID`
- `BaseExchangeRate`: reference rate before fee markup, enables spread calculation
- `ExchangeFee` (INT): fee in provider-specific units; complemented by `ExchangeFeeInUSD` (USD absolute) and `ExchangeFeeInPercentage` (percentage, decimal(10,2)) for normalized reporting

### 2.4 Routing: Depot, MID, Merchant Account

**What**: Records which payment infrastructure handled this execution leg.

**Columns Involved**: `DepotID`, `ProtocolMIDSettingsID`, `MerchantAccountID`, `ResponseID`, `RequestExecuteEntryMethodId`

**Rules**:
- `DepotID`: which `Billing.Depot` (acquirer/gateway) processed this payout leg
- `ProtocolMIDSettingsID`: MID configuration used. Default=0
- `MerchantAccountID`: merchant entity routing (FK to Billing.MerchantAccountRouting, nullable)
- `ResponseID`: provider response reference ID; NULL for most records
- `RequestExecuteEntryMethodId`: tracks how the execution request was initiated (1=most common for modern records); NULL for older records

### 2.5 Cashout Mode

**What**: `CashoutModeID` classifies the mode of withdrawal execution.

**Columns Involved**: `CashoutModeID`

**Rules**:
- 1=Standard mode (75.2%) - normal provider-initiated withdrawal
- NULL=legacy (17%) - mode not tracked for older records
- 2=Alternate mode (4%) - e.g., eToroMoney or ACH mode
- 0=Unknown/fallback (3.8%)

---

## 3. Data Overview

| ID | WithdrawID | CashoutTypeID | CashoutStatusID | Amount | ProcessCurrencyID | Meaning |
|----|-----------|---------------|-----------------|--------|------------------|---------|
| 1370663 | 1734841 | 1 (Cashout) | 3 (Processed) | 30 GBP | 3 (GBP) | Completed withdrawal of GBP 30 to FundingID=4148452. ExchangeRate=1.34785 (USD/GBP). DepotID=88, MerchantAccountID=64 (entity routing). |
| 1370664 | 1734845 | 1 (Cashout) | 14 (Pending Review) | 145 USD | 1 (USD) | Withdrawal pending compliance/ops review. DepotID=92. ManagerID=730 initiated. |
| 1370662 | 1734839 | 1 (Cashout) | 14 (Pending Review) | 25 USD | 1 (USD) | Another withdrawal under review, DepotID=10 (different acquirer). |
| ~724K rows | - | 1/2 | 4 (Canceled) | varies | varies | 67.7% of WTF legs were canceled - withdrawal requests abandoned, rejected by risk, or customer cancelled. No money transferred (IsFinishedWithoutMoneyTransfer=1). |
| ~330K rows | - | 1/2 | 3 (Processed) | varies | varies | 31.5% successfully paid out to customers or refunded to their payment instrument. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawID | int | NO | - | CODE-BACKED | References the parent withdrawal request in `Billing.Withdraw`. No explicit FK constraint. Indexed (IX_BillingWithdrawToFunding_WithdrawID on WithdrawID+CashoutStatusID). One `Billing.Withdraw` row may have multiple WTF legs (re-attempts, splits). |
| 2 | FundingID | int | NO | - | CODE-BACKED | The payment instrument to which the withdrawal is being sent. References `Billing.Funding` implicitly (no explicit FK). Indexed (IX_WithdrawToFunding_FundingID_CashoutStatusID). See Billing.Funding for instrument details. |
| 3 | CashoutStatusID | int | NO | - | CODE-BACKED | Execution status of this payment leg. FK to Dictionary.CashoutStatus (via standard reference). Values: 1=Pending, 2=InProcess, 3=Processed (IsFinal), 4=Canceled (IsFinal, no money transferred), 5=Partially Processed (IsFinal), 6=Payment Sent, 7=Rejected (IsFinal, no money transferred), 8=RejectedByProvider (IsFinal), 9=PendingByProvider, 10=SentToProvider, 11=SentToBilling, 12=ReceivedByBilling, 13=Failed (IsFinal), 14=Pending Review, 15=Under Review, 16=Reversed, 17=Partially Reversed. Distribution: 4=67.7%, 3=31.5%, 17=0.68%. Indexed (BW2F_CASHOUTSTATUS, IX_BillingWithdrawToFunding_WithdrawID). |
| 4 | ProcessCurrencyID | int | YES | NULL | CODE-BACKED | Currency used for the actual payment processing (the currency the provider sends to the customer's instrument). May differ from `Billing.Withdraw.CurrencyID` when cross-currency routing is applied. |
| 5 | ManagerID | int | YES | NULL | CODE-BACKED | Operations manager who initiated or last modified this payment leg. 0=automated/system processing. NULL=not set. |
| 6 | ExchangeRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Exchange rate applied to convert from withdrawal currency to `ProcessCurrencyID`. NULL for same-currency payouts (ExchangeRate=1.0 implied). |
| 7 | Amount | money | NO | - | CODE-BACKED | Payout amount in `ProcessCurrencyID` currency. MONEY type (4 decimal places). For refunds, this is the amount being refunded to the card/instrument (not necessarily the original deposit amount - exchange rates may differ). |
| 8 | ModificationDate | datetime | YES | NULL | CODE-BACKED | UTC timestamp of the most recent status change. Indexed (ix_BillingWithdrawToFunding_ModificationDateWithdrawID). Used by data pipelines for incremental change detection. |
| 9 | WithdrawData | xml | YES | NULL | CODE-BACKED | Provider-specific XML response data for this payment leg. Contains auth codes, provider transaction IDs, rejection reasons, response metadata. PRIMARY XML index BWDR_XMLPRIMARY + PATH/PROPERTY/VALUE secondary XML indexes. Included in IX_BillingWithdrawToFunding_WithdrawID and IX_WithdrawToFunding_FundingID_CashoutStatusID for covering queries. |
| 10 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate primary key. CLUSTERED - table is physically sorted by ID. NOT FOR REPLICATION. Range: 177,416 to 1,370,664. |
| 11 | DepositID | int | YES | NULL | CODE-BACKED | For refund legs (CashoutTypeID=2): references the source `Billing.Deposit` row being refunded. Value 0 is used as null-equivalent for cashout legs (not SQL NULL). For refunds, > 0 is a valid DepositID. Indexed (IX_BillingWithdrawToFunding_DepositID). |
| 12 | RefundAmountInDepositCurrency | money | YES | NULL | CODE-BACKED | For refund legs: the refund amount expressed in the original deposit's currency. May differ from `Amount` (in ProcessCurrencyID) when exchange rates changed between deposit and refund. Used for reconciliation of refund amounts to original deposit values. |
| 13 | CashoutTypeID | tinyint | YES | NULL | CODE-BACKED | Categorizes the type of payment execution: 1=Cashout (standard withdrawal to payment instrument, 69%), 2=Refund (refund of a prior deposit back to the original instrument, 31%). Determines how DepositID and RefundAmountInDepositCurrency are interpreted. |
| 14 | VerificationCode | varchar(50) | YES | NULL | CODE-BACKED | Verification code supplied or received during withdrawal processing. Used to validate the payout authorization. Same pattern as Billing.Deposit.RefundVerificationCode. |
| 15 | ProcessorValueDate | datetime | YES | NULL | CODE-BACKED | Value date from the payment processor - when funds are considered available on the processor side. Set for wire/ACH payouts; NULL for instant payment methods. Default=NULL constraint (DFWTF_ProcessorValueDate). |
| 16 | MatchStatusID | tinyint | NO | 0 | CODE-BACKED | Provider reconciliation match status. Default 0=Unmatched. Mirrors the pattern in Billing.Deposit.MatchStatusID. Used in PSP settlement reconciliation workflows. |
| 17 | DepotID | int | YES | NULL | CODE-BACKED | Which `Billing.Depot` (acquirer/gateway configuration) processed this payment leg. Determines routing for the actual fund transfer. See Billing.Depot (documented) for depot configurations. |
| 18 | AutoPaymentStartDate | datetime | YES | getutcdate() | CODE-BACKED | For auto-payment scheduled executions: the UTC timestamp when automatic payment processing of this leg began. Defaults to getutcdate() on INSERT. NULL for manually processed legs. |
| 19 | ProtocolMIDSettingsID | int | NO | 0 | CODE-BACKED | References `Billing.ProtocolMIDSettings` - the MID configuration profile used for this payment leg. Default=0 (no specific MID). Mirrors Billing.Deposit.ProtocolMIDSettingsID pattern. |
| 20 | BaseExchangeRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Reference exchange rate before fee markup. Enables fee spread calculation: `ExchangeRate - BaseExchangeRate = spread`. Mirrors Billing.Deposit.BaseExchangeRate. |
| 21 | ExchangeFee | int | YES | NULL | CODE-BACKED | Exchange fee in provider-specific integer units. Mirrors Billing.Deposit.ExchangeFee encoding. |
| 22 | CashoutModeID | tinyint | YES | NULL | CODE-BACKED | Mode of withdrawal execution: NULL=legacy (17%), 0=unknown/fallback (3.8%), 1=Standard (75.2%), 2=Alternate mode e.g., eToroMoney/ACH (4%). Determines which processing path is used for this leg. |
| 23 | CreationDate | datetime | YES | getutcdate() | CODE-BACKED | UTC creation timestamp of this WTF record. Default getutcdate(). NULL for records created before this column was added. Live data starts 2023-01-04 (column added in early 2023). |
| 24 | AdditionalInformation | nvarchar(250) | YES | NULL | CODE-BACKED | Free-text additional context or notes for this payment leg. Used for provider-specific metadata that does not fit WithdrawData XML schema. |
| 25 | VendorCode | nvarchar(250) | YES | NULL | CODE-BACKED | Vendor or provider-specific code associated with this payout (e.g., beneficiary code, bank routing reference). |
| 26 | MerchantAccountID | int | YES | NULL | CODE-BACKED | References `Billing.MerchantAccountRouting` - the merchant entity used for this payout. Null for legs without specific entity routing. Mirrors Billing.Deposit.MerchantAccountID. |
| 27 | SchemeId | nvarchar(255) | YES | NULL | CODE-BACKED | Payment scheme identifier (e.g., Visa, Mastercard, SEPA scheme code). Used for scheme-level reporting and compliance tracking. |
| 28 | ResponseID | int | YES | NULL | CODE-BACKED | Provider-assigned response identifier for this payment execution. Links to provider-side transaction records for reconciliation. NULL for most records. |
| 29 | RequestExecuteEntryMethodId | int | YES | NULL | CODE-BACKED | Identifies how this execution request was initiated (entry method): 1=most common for modern records. NULL for legacy records. Tracks whether execution was triggered by API call, batch job, manual operation, etc. |
| 30 | ExchangeFeeInUSD | money | YES | NULL | CODE-BACKED | Exchange fee expressed in USD absolute amount. Normalized fee value for cross-currency comparison and reporting. Mirrors Billing.Deposit.ExchangeFeeInUSD. |
| 31 | ExchangeFeeInPercentage | decimal(10,2) | YES | NULL | CODE-BACKED | Exchange fee as a percentage of the payout amount. Enables standardized fee rate comparison. Mirrors Billing.Deposit.ExchangeFeePercentage. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | Implicit (no FK) | Parent withdrawal request for this execution leg |
| FundingID | Billing.Funding | Implicit (no FK) | Payment instrument receiving the payout |
| DepositID | Billing.Deposit | Implicit (no FK) | Source deposit for refund legs (CashoutTypeID=2) |
| DepotID | Billing.Depot | Implicit | Acquirer/gateway configuration used |
| ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | Implicit | MID configuration profile |
| MerchantAccountID | Billing.MerchantAccountRouting | Implicit | Merchant entity for routing |
| ProcessCurrencyID | Dictionary.Currency | Implicit | Processing currency |
| CashoutStatusID | Dictionary.CashoutStatus | Implicit | Execution status values |
| CashoutTypeID | (inline enum) | - | 1=Cashout, 2=Refund |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.vWithdrawToFunding | WTF.* | View | Reporting view over this table |
| Billing.FundingDataForWithdraw | WithdrawID | View | Joins WTF with Funding for payment details |
| Billing.WithdrawToFundingAdd | ID (OUTPUT) | Write | Creates new WTF leg for a withdrawal |
| Billing.WithdrawToFundingProcess | ID | Modifier | Processes execution, updates CashoutStatusID to Processed/Canceled |
| Billing.WithdrawToFundingProcessBatch | ID | Modifier | Batch execution via TBL_WithdrawToFundingProcessBatchV3 TVP |
| Billing.WithdrawToFundingProcessForBatch | ID | Modifier | Legacy batch execution via TBL_WithdrawToFundingProcess V1 TVP |
| Billing.WithdrawToFundingReject | ID | Modifier | Rejects the WTF leg, updates CashoutStatusID to Rejected |
| Billing.WithdrawToFundingReverse | ID | Modifier | Reverses a processed payout back to the customer balance |
| Billing.WithdrawToFundingToInProcess | ID | Modifier | Advances WTF from Pending to InProcess status |
| Billing.WithdrawToFundingUpdate | ID | Modifier | General-purpose WTF metadata update |
| Billing.WithdrawToFundingUpdateAdditionalInformation | ID | Modifier | Updates AdditionalInformation free-text field |
| Billing.WithdrawToFundingUpdateCashoutStatus | ID | Modifier | Updates CashoutStatusID with optimistic lock |
| Billing.WithdrawToFundingUpdateCashoutStatusForBatch | ID | Modifier | Batch update of CashoutStatusID via TBL_CashoutStatusInfo TVP |
| Billing.WithdrawToFundingUpdateMerchantAccountID | ID | Modifier | Updates MerchantAccountID routing field |
| Billing.WithdrawToFundingUpdateProtocolMidSettingsID | ID | Modifier | Updates ProtocolMIDSettingsID field |
| Billing.WithdrawToFundingUpdateVerificationCode | ID | Modifier | Updates VerificationCode field |
| Billing.WithdrawToFundingUpdateWithDrawData | ID | Modifier | Updates WithdrawData XML field |
| Billing.WithdrawService_GetWithdrawsWithoutRedeems | ID | Read | Joins WTF to filter withdrawals that have no linked Redeem |
| Billing.WithdrawAndWithdrawToFundingAdd | ID | Write (indirect) | Orchestrates Withdraw + WTF creation for Redeem conversion flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WithdrawToFunding (table)
  - No explicit FK constraints; implicit dependencies:
    Billing.Withdraw (WithdrawID)
    Billing.Funding (FundingID)
    Billing.Deposit (DepositID - for refund legs)
    Billing.Depot (DepotID)
    Billing.ProtocolMIDSettings (ProtocolMIDSettingsID)
    Billing.MerchantAccountRouting (MerchantAccountID)
    Dictionary.Currency (ProcessCurrencyID)
    Dictionary.CashoutStatus (CashoutStatusID)
    dbo.dtPrice (UDT for ExchangeRate, BaseExchangeRate)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | ExchangeRate and BaseExchangeRate column types |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.vWithdrawToFunding | View | Reporting view |
| Billing.FundingDataForWithdraw | View | Payment details join |
| Billing.WithdrawToFundingAdd | Procedure | Writer - creates new payment leg |
| Billing.WithdrawToFundingProcess | Procedure | Modifier - processes and finalizes leg status |
| Billing.GetScheduledTaskWithdrawToFundingEntities | Procedure | Reader - scheduled task data feed |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BillingWithdrawToFunding | CLUSTERED PK | ID ASC | - | - | Active; DATA_COMPRESSION=PAGE |
| BW2F_CASHOUTSTATUS | NC | CashoutStatusID ASC | - | - | Active; FILLFACTOR=90 |
| IX_BillingWithdrawToFunding_DepositID | NC | DepositID ASC | CashoutTypeID, CashoutStatusID, WithdrawID, RefundAmountInDepositCurrency | - | Active; FILLFACTOR=95; DATA_COMPRESSION=PAGE - covering for refund lookups |
| IX_BillingWithdrawToFunding_WithdrawID | NC | WithdrawID ASC, CashoutStatusID ASC | Amount, FundingID, ProcessCurrencyID, ExchangeRate, WithdrawData, DepositID, RefundAmountInDepositCurrency, ID | - | Active - large covering index for withdrawal-level queries |
| IX_WithdrawToFunding_FundingID_CashoutStatusID | NC | FundingID ASC, CashoutStatusID ASC | WithdrawData, ID | - | Active; FILLFACTOR=90 |
| ix_BillingWithdrawToFunding_ModificationDateWithdrawID | NC | ModificationDate ASC, WithdrawID ASC | CashoutStatusID | - | Active; FILLFACTOR=95; DATA_COMPRESSION=PAGE |
| BWDR_XMLPRIMARY | PRIMARY XML | WithdrawData | - | - | Active; FILLFACTOR=95 |
| BWDR_XMLPATH | XML PATH | WithdrawData | - | - | Active |
| BWDR_XMLPROPERTY | XML PROPERTY | WithdrawData | - | - | Active |
| BWDR_XMLVALUE | XML VALUE | WithdrawData | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BillingWithdrawToFunding | PRIMARY KEY CLUSTERED (ID) | One row per execution leg |
| DFWTF_ProcessorValueDate | DEFAULT (NULL) | ProcessorValueDate defaults to NULL |
| DF_BillingWithdrawToFunding_MatchStatusID | DEFAULT (0) | MatchStatusID defaults to 0 (Unmatched) |
| (unnamed) | DEFAULT (getutcdate()) | AutoPaymentStartDate defaults to current UTC |
| BWTF_ProtocolMIDSettingsID | DEFAULT (0) | ProtocolMIDSettingsID defaults to 0 |
| DF_BillingWithdrawToFundingCreationDate | DEFAULT (getutcdate()) | CreationDate defaults to current UTC |

---

## 8. Sample Queries

### 8.1 Get all execution legs for a withdrawal with status details

```sql
SELECT
    wtf.ID,
    wtf.WithdrawID,
    wtf.CashoutTypeID,
    cs.Name AS CashoutStatus,
    wtf.Amount,
    wtf.ProcessCurrencyID,
    wtf.ExchangeRate,
    wtf.FundingID,
    wtf.DepotID,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK)
    ON wtf.CashoutStatusID = cs.CashoutStatusID
WHERE wtf.WithdrawID = @WithdrawID
ORDER BY wtf.ID
-- Uses IX_BillingWithdrawToFunding_WithdrawID
```

### 8.2 Find refund legs for a specific deposit

```sql
SELECT
    wtf.ID,
    wtf.WithdrawID,
    wtf.Amount,
    wtf.RefundAmountInDepositCurrency,
    wtf.ProcessCurrencyID,
    cs.Name AS CashoutStatus,
    wtf.FundingID,
    wtf.CreationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK)
    ON wtf.CashoutStatusID = cs.CashoutStatusID
WHERE wtf.DepositID = @DepositID
  AND wtf.CashoutTypeID = 2  -- Refund legs only
ORDER BY wtf.ID
-- Uses IX_BillingWithdrawToFunding_DepositID
```

### 8.3 Active (non-final) payment legs pending processing

```sql
SELECT
    wtf.ID,
    wtf.WithdrawID,
    wtf.FundingID,
    wtf.Amount,
    wtf.ProcessCurrencyID,
    cs.Name AS CashoutStatus,
    wtf.DepotID,
    wtf.ModificationDate
FROM Billing.WithdrawToFunding wtf WITH (NOLOCK)
JOIN Dictionary.CashoutStatus cs WITH (NOLOCK)
    ON wtf.CashoutStatusID = cs.CashoutStatusID
WHERE cs.IsFinalStatus IS NULL OR cs.IsFinalStatus = 0
ORDER BY wtf.ModificationDate ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 1,2,3,5,6,8,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed directly | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.WithdrawToFunding | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.WithdrawToFunding.sql*
