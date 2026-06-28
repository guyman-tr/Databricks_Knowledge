# Billing.Deposit

> Core deposit transaction ledger; each row records one deposit attempt by a customer using a registered payment instrument, from initial submission through provider processing, approval, and post-processing tracking.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | DepositID (PRIMARY KEY CLUSTERED, IDENTITY(1,1), NOT FOR REPLICATION) |
| **Row Count** | ~7,677,001 rows |
| **Partition** | No - filegroup MAIN; TEXTIMAGE on MAIN |
| **Indexes** | 1 CLUSTERED PK; 13 NC; 3 XML (PRIMARY/PATH/PROPERTY/VALUE); total 17 |

---

## 1. Business Meaning

`Billing.Deposit` is the authoritative transaction ledger for all customer deposit activity on eToro. Every attempt to add funds to an eToro account - whether approved, declined, pending, charged back, or refunded - produces one row here. The table captures the full lifecycle: the payment instrument used (`FundingID`), the currency and amount, the provider's response data in XML format, routing decisions (which depot/MID processed the deposit), risk management outcome, and the final payment status.

Without this table, eToro has no record of incoming money. All customer account credits, first-time deposit tracking, fraud detection, compliance reporting, chargeback management, and payment provider reconciliation depend on it. The balance top-up system (`Billing.AmountAdd`) is triggered from deposit records, and marketing attribution (FTD events, AppsFlyer, Pixel, RabbitMQ) relies on this table to identify qualifying events.

Data flows as follows: the cashier application calls `Billing.DepositAdd` to INSERT a new row (typically with status 1=New or 5=InProcess or 13=Pending). The payment provider processes the transaction externally, then `Billing.DepositProcess` is called to approve the deposit - which updates status to 2=Approved, credits the customer's account via `Billing.AmountAdd`, and sets the IsFTD flag if applicable. Status update procedures (`UpdateDepositPaymentStatusId`, `DepositCancel`, `DepositRollback`) handle decline and reversal paths. Every UPDATE and DELETE is captured in `History.Deposit` via trigger for audit and reconciliation.

---

## 2. Business Logic

### 2.1 Deposit Lifecycle - Status State Machine

**What**: Deposits follow a defined state machine enforced by `Dictionary.PaymentStatusStateMachine`. Transitions are validated before any status change is committed.

**Columns Involved**: `PaymentStatusID`, `DepositID`, `ModificationDate`, `ManagerID`

**Rules**:
- `DepositProcess` validates via `Dictionary.PaymentStatusStateMachine` that the transition from the current status to 2=Approved is legal for the given `FundingTypeID`
- Approved (2) is the only terminal success state - it triggers `Billing.AmountAdd` to credit the customer account
- Declined states (3, 8-25, 31-35) are terminal failure states set either by the risk engine or provider response
- Pending (13) and InProcess (5) are intermediate waiting states for offline/bank-wire deposits
- Chargeback (11), Refund (12), RefundAsChargeback (26), ChargebackReversal (37), RefundReversal (38), ReversedDeposit (39) represent post-settlement reversals

**Diagram**:
```
New(1) / InProcess(5) / Pending(13)
          |
          v
    [PaymentStatusStateMachine validates]
          |
    Approved? --YES--> PaymentStatusID=2 (Approved)
          |                    |
         NO                    v
          |            Billing.AmountAdd -> customer account credited
          v                    |
  Decline States(3,8-35)       v
  (terminal failure)     IsFTD evaluated
                               |
                         History.DepositAction logged

Post-approval reversals:
Approved(2) --> Chargeback(11) / Refund(12) / ChargebackReversal(37) / RefundReversal(38)
```

### 2.2 First-Time Deposit (FTD) Detection

**What**: The IsFTD flag identifies whether this deposit was the customer's first ever approved deposit on eToro, which drives marketing attribution, bonus eligibility, and regulatory reporting.

**Columns Involved**: `IsFTD`, `CID`, `DepositID`, `DepositTypeID`

**Rules**:
- Set during `Billing.DepositProcess` (only called on Approved path): checks if any other deposit for the same CID has `IsFTD=1`; if none found, marks this deposit as FTD
- `Dictionary.DepositType.ApplyFtd` gate: if `DepositTypeID=4` (MoneyTransfer, internal transfer), `ApplyFtd=false` - these deposits cannot be FTD regardless of history
- All other deposit types (Regular=1, CvvFree=2, Recurring=3, RecurringInvestment=5) have `ApplyFtd=true`
- Once IsFTD=1 exists for a CID, no subsequent deposits for that CID can have IsFTD=1 (monotonic - only one FTD per customer ever)
- Used by scheduled tasks: `GetScheduledTaskRabbitMqFtdEntities`, `GetScheduledTaskAppsFlyerEntities`, `GetScheduledTaskPixelEntities` to fire FTD events to marketing platforms

### 2.3 Amount, Currency, and Exchange Rate

**What**: Deposits are recorded in the customer's chosen deposit currency and converted to USD for account crediting. The system stores both the original currency amount and the exchange metadata.

**Columns Involved**: `Amount`, `CurrencyID`, `ExchangeRate`, `BaseExchangeRate`, `ExchangeFee`, `ExchangeFeeInUSD`, `ExchangeFeePercentage`, `FeeConfigurationID`

**Rules**:
- Application passes `Amount` in CENTS (integer); `DepositAdd` divides by 100 on INSERT: `CAST(@Amount AS MONEY) / 100`
- `ExchangeRate` cannot be 0 - enforced in `DepositAdd` (`IF @ExchangeRate = 0 RAISERROR`)
- `DepositProcess` calculates USD-equivalent for AmountAdd: `CAST(ROUND(ISNULL(@NewAmount, Amount) * @ExchangeRate * 100, 0) AS INTEGER)` (result in cents, currency hardcoded to USD=1)
- `BaseExchangeRate` stores the reference rate before fees, enabling fee-amount extraction
- `ExchangeFeeInUSD` and `ExchangeFeePercentage` store the explicit fee amounts for reconciliation and reporting (added PAYIL-8913/8926)
- `FeeConfigurationID` links to fee configuration profiles (added 2026-02-08 by Zipi L., PAYIL)
- Offline/wire deposits (`IsSingleFunding=1` or `FundingTypeID=17`) require `@NewAmount`, `@NewCurrencyID`, and `@ProcessorValueDate` to be supplied at process time

### 2.4 Routing: Depot, MID, and Merchant Account

**What**: Each deposit is routed through a specific payment depot (acquirer configuration), MID settings profile, and merchant account. These routing decisions determine which payment processor handles the transaction.

**Columns Involved**: `DepotID`, `ProtocolMIDSettingsID`, `MerchantAccountID`, `RoutingReasonID`, `ProcessRegulationID`

**Rules**:
- `DepotID` identifies which `Billing.Depot` (acquirer/gateway configuration) processed the deposit; validated at insert time in `DepositAdd` via join to `Billing.DepotToCurrency` to confirm the depot supports the requested currency
- `ProtocolMIDSettingsID` references `Billing.ProtocolMIDSettings` - the specific MID (Merchant ID) configuration profile. Updated during `DepositProcess` if `@ProtocolMIDSettingsID` is supplied. Default=0 means no specific MID was assigned
- `MerchantAccountID` references `Billing.MerchantAccountRouting` - the merchant account entity used for this transaction (regulatory/entity routing)
- `RoutingReasonID` (values 0-8, ~31% NULL for legacy records) records why a specific routing path was chosen (e.g., 3=most common routing, 1=second most common)
- `ProcessRegulationID` identifies the regulatory entity that processed this deposit (1=Cyprus ~63%, 2=UK ~16%, plus 10+ others for AU, ASIC, etc.)

### 2.5 XML PaymentData Validation

**What**: `PaymentData` stores the provider-specific transaction response XML, validated at INSERT time against a schema keyed to the funding type.

**Columns Involved**: `PaymentData`, `FundingID`, `CurrencyID`

**Rules**:
- Schema name is constructed as `'Deposit' + FundingType.Name` and looked up in `Dictionary.GetXMLSchema`
- CLR function `CLR.ParseXML(@xmlSchema, @xmlValue)` validates the XML; invalid XML raises error and aborts the INSERT
- Four XML secondary indexes (BDEP_XMLPATH, BDEP_XMLPROPERTY, BDEP_XMLVALUE) support XQuery on `PaymentData`
- XML schema varies by payment type: credit cards include auth codes/AVS results; wire transfers include reference numbers; e-wallets include provider transaction IDs

### 2.6 DR Processing Status

**What**: DRStatusID tracks whether this deposit record has been processed through the DR (Delayed Revenue / Deferred Revenue) pipeline, used for regulatory and financial reporting.

**Columns Involved**: `DRStatusID`, `DRDate`

**Rules**:
- 0=Not processed (default, 94.5% of records) - deposit not yet sent to DR pipeline
- 1=Processed (4.5%) - successfully processed through DR
- 3=In Progress (1%) - DR processing in flight
- 2=Error (<0.01%) - DR processing failed
- `DRDate` records when DR processing occurred; NULL when DRStatusID=0

### 2.7 Trigger-Maintained Audit History

**What**: Every modification and deletion of a deposit row is automatically captured in `History.Deposit` for audit, reconciliation, and dispute resolution.

**Columns Involved**: All columns, `ModificationDate`

**Rules**:
- Trigger `Tr_Billing_Deposit_UpdateDelete` fires AFTER UPDATE or DELETE
- Copies the DELETED row (pre-change state) to `History.Deposit` with all fields
- `ModificationDate` is updated on every status change, enabling timeline reconstruction
- History does NOT capture INSERTs (initial state is the live row itself)
- History.DepositAction separately tracks status transitions with PaymentActionTypeID=2 (Purchase) and PaymentActionStatusID values (1=New, 3=Closed)

---

## 3. Data Overview

| DepositID | CID | PaymentStatusID | Amount | IsFTD | Meaning |
|-----------|-----|-----------------|--------|-------|---------|
| 10780413 | 25463722 | 2 (Approved) | 100 GBP | true | Successful first-time deposit via credit card. FTD=true triggered marketing attribution events (AppsFlyer, Pixel). Customer account credited with USD equivalent. |
| 10780411 | 25463718 | 2 (Approved) | 100 EUR | false | Repeat deposit approved. MerchantAccountID=64 indicates specific regulatory entity routing; RoutingReasonID=NULL suggests legacy or auto-routing. |
| 10780414 | 25463725 | 5 (InProcess) | 100 USD | false | Deposit submitted but awaiting provider confirmation (e.g., 3DS challenge, ACH pending). DepositProcess not yet called; customer account not yet credited. |
| ~5.6M rows | - | 2 (Approved) | varies | - | Approved deposits constitute 73% of all records - the core money-in events that fund customer trading accounts. |
| ~782K rows | - | 35 (DeclineByRRE) | varies | - | Real-time risk engine (RRE) declined these deposits before provider processing. These represent blocked fraud/risk attempts filtered at the eToro layer before reaching acquirers. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Auto-incremented deposit identifier. NOT FOR REPLICATION - identity values are server-local and not replicated. Referenced by History.Deposit, History.DepositAction, Billing.ScheduledTaskState, and all deposit-centric SPs. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID. FK to Customer.CustomerStatic (FK_CCST_BDEP). Identifies which eToro customer made this deposit. Indexed as part of multiple composite indexes (BDEP_PAYMENTDATE, BDEP_TRANSACTION, Idx_Billing_Deposit_CID_PaymentStatusID, etc.) for per-customer queries. |
| 3 | FundingID | int | NO | - | CODE-BACKED | Payment instrument used for this deposit. FK to Billing.Funding (FK_BFND_BDEP). Identifies the specific credit card, bank account, or e-wallet registered by this customer. Indexed (BDEP_FUNDING). See Billing.Funding for payment instrument details. |
| 4 | CurrencyID | int | NO | - | CODE-BACKED | Currency in which the deposit was made. FK to Dictionary.Currency (FK_DCUR_BDEP). Validated at insert time against Billing.DepotToCurrency to confirm the depot supports this currency. Indexed (i_CureenyID). 1=USD, 2=EUR, 3=GBP, 4=AUD, 5=GBP, etc. |
| 5 | PaymentStatusID | int | NO | - | CODE-BACKED | Current payment status. FK to Dictionary.PaymentStatus (FK_DPMS_BDEP). Transitions validated by Dictionary.PaymentStatusStateMachine. Values: 1=New, 2=Approved (73%), 3=Decline (7.6%), 4=Technical, 5=InProcess, 6=Canceled, 7=Confirmed, 8=DeclineBlockCard, 9=DeclineBadBins, 10=DeclineMemberLimits, 11=Chargeback, 12=Refund, 13=Pending (4.1%), 14=DeclinedBlockedPayPal, 15=DeclinedBlockedNeteller, 18=DeclinedBlockedCountry, 19=DeclinedHighRiskCID, 20=DeclinedOverTheLimit, 25=MultipleDepositsAggregatedAmount, 26=RefundAsChargeback, 27=MigratedToDepositTable, 31=DeclineBinConflictCountry, 32=DeclineSecurityValidation, 33=DeclineFtdOverTheLimit, 34=DeclineHighRiskCountry, 35=DeclineByRRE (10.2%), 36=PendingReview, 37=ChargebackReversal, 38=RefundReversal, 39=ReversedDeposit. Indexed (IX_BillingDeposit_PaymentStatusID, IX_BillingDeposit_PaymentStatusIDFundingID, IX_BillingDeposit_PaymentStatusID_ModificationDate, Idx_Billing_Deposit_CID_PaymentStatusID). |
| 6 | ManagerID | int | YES | NULL | CODE-BACKED | Operations manager who processed or last modified this deposit. 0=system/automated processing (no human operator). FK to BackOffice.Manager (FK_BMAN_BDEP). Set during DepositProcess if @ManagerID > 0 overrides the stored value. |
| 7 | RiskManagementStatusID | int | YES | NULL | CODE-BACKED | Result of the risk management pre-check performed before processing. FK to Dictionary.RiskManagementStatus (FK_DRMS_BDEP). NULL=no risk check recorded (most approved deposits). Key decline values: 1=Success, 2=CardIsBlocked, 3=BinInBlackList, 4=MemberLimit, 5=FundingTypeLimit, 10=DeclinedBlackListCountry, 11=DeclinedHighRiskDeposit, 12=OverTheLimit, 18=LoginToRegCountryConflict, 21=BinToRegCountryConflict, 22=FTDOverDailyLimit, 32-35=KYCLevel0-3, 47=ML, 49=CustomerToFundingViolation, 55=ThreeDsVerificationFail, 67=SiftWorkFlow, 69=BusinessRuleRisk. 69 distinct risk reason codes. |
| 8 | Amount | money | NO | - | CODE-BACKED | Deposit amount in the deposit currency (CurrencyID). Stored as MONEY type (4 decimal places). Passed by the application in CENTS as bigint and divided by 100 on INSERT in DepositAdd: `CAST(@Amount AS MONEY) / 100`. For offline/wire deposits, may be updated during DepositProcess with @NewAmount. |
| 9 | ExchangeRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Exchange rate from deposit currency to USD, applied at processing time. Cannot be 0 (enforced in DepositAdd). Used in DepositProcess: `Amount * ExchangeRate * 100` to compute USD cents for AmountAdd. For USD deposits, ExchangeRate=1.0. |
| 10 | PaymentDate | datetime | NO | - | CODE-BACKED | UTC timestamp when the deposit record was created (set to GETUTCDATE() in DepositAdd). Represents the deposit submission time, not the approval time. Indexed (BDEP_PAYMENTDATE composite, Idx_Billing_Deposit_PaymentDate). |
| 11 | ModificationDate | datetime | YES | NULL | CODE-BACKED | UTC timestamp of the most recent modification to this record. Set to GETUTCDATE() on INSERT (equals PaymentDate initially) and updated on every status change. Used by data pipeline queries (BDEP_ModificationDate index) to detect changed records incrementally. |
| 12 | TransactionID | char(6) | NO | - | CODE-BACKED | Short internal transaction identifier, unique per customer (unique index BDEP_TRANSACTION on CID+TransactionID). Generated in DepositAdd as a 6-char uppercase hex substring of a GUID: `SUBSTRING(CONVERT(VARCHAR(36), NEWID()), 30, 6)`. Collision-checked per CID before insert. Not the external provider transaction ID (that is ExTransactionID). |
| 13 | IPAddress | numeric(18, 0) | YES | NULL | CODE-BACKED | Customer's IP address at time of deposit, stored as a numeric integer (IPv4 encoded as 32-bit integer). Used for fraud detection - geographic inconsistency checks (IPConflict=RiskManagementStatusID 48). NULL for some older or backend-initiated deposits. Included in AppsFlyer scheduled task index. |
| 14 | Approved | bit | YES | NULL | CODE-BACKED | Legacy approval flag, superseded by PaymentStatusID=2. NULL for most modern records. Not updated by current code paths (DepositProcess sets PaymentStatusID, not this flag). Retained for backward compatibility with older reporting queries. |
| 15 | Commission | money | NO | 0 | NAME-INFERRED | Commission amount charged on this deposit. Defaults to 0. Not set by DepositAdd (no parameter for it); may be populated by specific commission-based deposit flows or back-office tools. |
| 16 | PaymentData | xml | YES | NULL | CODE-BACKED | Provider-specific payment response XML. Schema varies by FundingType and is validated against `Dictionary.GetXMLSchema` (schema name: 'Deposit' + FundingType.Name) via CLR.ParseXML on every INSERT and UPDATE. Contains auth codes, AVS results, provider transaction IDs, card data (for CC), wire reference numbers (for bank transfers), etc. Primary XML index BDEP_XMLPRIMARY + three secondary XML indexes (BDEP_XMLPATH, BDEP_XMLPROPERTY, BDEP_XMLVALUE) enable XQuery. |
| 17 | ClearingHouseEffectiveDate | datetime | YES | NULL | CODE-BACKED | The value date assigned by the clearing house for this deposit (when funds are considered settled by the clearing institution). Set for wire/ACH deposits; NULL for instant payment methods. Used in Conversion Rate Management window for wire processing. |
| 18 | OldPaymentID | int | YES | NULL | NAME-INFERRED | Reference to a payment record in a legacy system (pre-migration). Used during the historical data migration that moved records with PaymentStatusID=27 (MigratedToDepositTable) from the old payment system. NULL for all modern deposits. |
| 19 | IsFTD | bit | NO | 0 | CODE-BACKED | Whether this deposit was the customer's First Time Deposit (their very first approved deposit on eToro). Set by DepositProcess: 1=FTD only if no prior IsFTD=1 exists for this CID AND DepositType.ApplyFtd=true. 0=repeat deposit (or deposit type that cannot be FTD, e.g., MoneyTransfer). 60.6% of deposits are FTD=true (reflecting that many customers deposit exactly once). Used by marketing scheduled tasks (AppsFLyer, Pixel, RabbitMQ FTD events). Indexed (Idx_Billing_Deposit_IsFTD_CID). |
| 20 | ProcessorValueDate | datetime | YES | NULL | CODE-BACKED | The value date provided by the payment processor, indicating when funds are credited on the processor side. Mandatory for offline/wire deposits (DepositProcess validates: IsSingleFunding=1 or FundingTypeID=17 must supply this). NULL for online/instant deposits where the processor date equals PaymentDate. |
| 21 | RefundVerificationCode | varchar(50) | YES | NULL | NAME-INFERRED | Verification code supplied or received during a refund operation. Set by DepositUpdateRefundDetails. Used to correlate refund requests with provider-side refund confirmations. NULL for non-refunded deposits. |
| 22 | DepotID | int | YES | NULL | CODE-BACKED | Identifies which Billing.Depot (acquirer/processor configuration) handled this deposit. Validated at INSERT time: Billing.DepotToCurrency must confirm the depot supports the requested CurrencyID. May be updated during DepositProcess via @NewDepotID for offline deposits routed to a different depot after initial placement. No explicit FK constraint. See Billing.Depot (documented) for depot configurations. |
| 23 | MatchStatusID | tinyint | NO | 0 | CODE-BACKED | PSP reconciliation match status. Default 0=Unmatched (99.9999% of records). 3=Matched (6 live records) - deposit has been matched to a provider-side settlement record via PSPMatchToEtoro/PSPMatchToEtoro2. Used for payment provider reconciliation workflows. |
| 24 | FunnelID | int | YES | NULL | CODE-BACKED | Marketing funnel identifier for this deposit. FK to Dictionary.Funnel (FK_BD_DF). Tracks which acquisition funnel the customer came through at time of deposit. Most deposits have FunnelID=36. Used in deposit reporting for funnel-level conversion analysis. |
| 25 | Code | varchar(50) | YES | NULL | NAME-INFERRED | Provider-specific code or reference associated with this deposit (e.g., provider confirmation code, voucher code). Distinct from TransactionID (internal) and ExTransactionID (provider transaction ID). NULL for most deposits. |
| 26 | ExTransactionID | varchar(50) | YES | NULL | CODE-BACKED | External (provider) transaction ID returned by the payment processor. Set during DepositProcess via @ExTransactionID parameter. Used for provider-side reconciliation and dispute resolution. Indexed (BDEP_ExTransactionID). Also accessible via Billing.GetDepositByExTransactionID. |
| 27 | CampaignCodeID | int | YES | NULL | CODE-BACKED | Campaign that was active for this customer at deposit time. FK to BackOffice.Campaign (FK_Billing_Deposit_CampaignCodeID). Links deposit revenue to acquisition campaigns for marketing ROI calculation. NULL = no campaign associated. |
| 28 | BonusStatusID | int | YES | NULL | CODE-BACKED | Status of any bonus associated with this deposit. FK to Dictionary.BonusStatus (FK_Billing_Deposit_BonusStatusID). Values: 0=New (default, no bonus pending), 1=Approved (bonus credited), 2=Declined (bonus request rejected), 3=Reverted (bonus reversed). Only 239 non-zero records in live data. |
| 29 | BonusAmount | money | YES | NULL | CODE-BACKED | Bonus amount credited or attempted in connection with this deposit. Populated alongside BonusStatusID when a promotional bonus is associated with the deposit. NULL when no bonus applies. |
| 30 | BonusErrorCode | int | YES | NULL | NAME-INFERRED | Error code returned by the bonus processing system when a bonus request fails (BonusStatusID=2). Identifies the specific reason for bonus decline. NULL when bonus succeeds or is not attempted. |
| 31 | SessionID | bigint | YES | NULL | CODE-BACKED | Application session ID at time of deposit. Passed through from the cashier application session context. Carried into History.DepositAction for session-level audit trail. NULL for backend/non-browser-session deposits. |
| 32 | DepositTypeID | int | YES | NULL | CODE-BACKED | Type of deposit. FK to Dictionary.DepositType (referenced in DepositProcess). Values: NULL=legacy pre-type-classification, 0=unknown, 1=Regular (standard card/e-wallet deposit, 43.4%), 2=CvvFree (card deposit without CVV), 3=Recurring (scheduled recurring payment), 4=MoneyTransfer (internal transfer, cannot be FTD), 5=RecurringInvestment (recurring investment, 0.7%). ApplyFtd column in DepositType determines IsFTD eligibility. |
| 33 | StatusReasonID | int | NO | 0 | CODE-BACKED | Additional reason code for the current payment status. Default 0=no specific reason. Values in use: 1, 2=3rd most common (64K records), 3=2nd most common (189K records). Updated by UpdateDepositStatusReasonID. Provides sub-classification of decline/approval reasons beyond PaymentStatusID. |
| 34 | DRStatusID | int | NO | 0 | CODE-BACKED | Delayed Revenue (DR) processing pipeline status. Default 0=Not processed (94.5%). 1=DR Processed (4.5%), 3=DR In Progress (1%), 2=DR Error (<0.01%). Tracks whether this deposit has been processed through the DR financial reporting pipeline for regulatory/revenue recognition purposes. |
| 35 | DRDate | datetime | YES | NULL | CODE-BACKED | UTC timestamp when DR processing completed. NULL when DRStatusID=0 (not yet processed). Set when DRStatusID transitions to 1 (Processed). |
| 36 | ProtocolMIDSettingsID | int | NO | 0 | CODE-BACKED | References Billing.ProtocolMIDSettings - the specific Merchant ID (MID) configuration profile used for this deposit's processing. Default 0=no specific MID assigned. Updated during DepositProcess if @ProtocolMIDSettingsID > 0. Determines which merchant account / acquirer configuration was active for this specific transaction. Added by Ran Ovadia (FB: 52829, 24/10/2018). |
| 37 | ExchangeFee | int | YES | NULL | CODE-BACKED | Exchange fee charged for currency conversion, in basis points or a provider-specific integer encoding. Added by Adi (19/02/2019). Carried through from DepositAdd/@ExchangeFee parameter into History.DepositAction. Complemented by ExchangeFeeInUSD and ExchangeFeePercentage for full fee decomposition. |
| 38 | BaseExchangeRate | dbo.dtPrice | YES | NULL | CODE-BACKED | The reference exchange rate before any fee markup is applied. Added by Adi (19/09/2019). Enables computation of the fee spread: `ExchangeRate - BaseExchangeRate = spread charged to customer`. Used in BI reports (BI_Deposit_PIPS_Report, BI_Deposit_State_Report). |
| 39 | PaymentGeneration | int | NO | 0 | CODE-BACKED | Payment processing generation/API version used for this deposit. Values: 0=Generation 0 (legacy, 7.7%), 1=Generation 1 (current, 92%). Added by Adi (19/04/2020). Distinguishes deposits processed through the new payment service infrastructure from older legacy paths. Carried into History.DepositAction. |
| 40 | ProcessRegulationID | int | YES | NULL | CODE-BACKED | Regulatory entity/jurisdiction that processed this deposit. Values: 1=Cyprus/EU (~63%), 2=UK/FCA (~16%), 4=Australia (~2.5%), 7-14=other regulated jurisdictions. Added by Shay Oren (DBA-646, 05/09/2021). Determines applicable regulatory rules (position limits, leverage caps, reporting requirements). Referenced by GetCustomerRegulationByDepositId. |
| 41 | MerchantAccountID | int | YES | NULL | CODE-BACKED | References Billing.MerchantAccountRouting - the merchant account legal entity used for this deposit (for multi-entity regulatory routing). Added by Shay Oren (DBA-646). NULL=legacy or auto-routed. Populated by GetMerchantValuesByDeposit. See Billing.MerchantAccountRouting for entity configurations. |
| 42 | IsSetBalanceCompleted | bit | NO | 0 | CODE-BACKED | Whether the balance set/credit operation (`Billing.AmountAdd`) for this deposit has been completed. Set by IsSetBalanceCompleted=1 after AmountAdd succeeds. Used in reconciliation to identify deposits where account crediting completed vs. those pending retry. Added by Shay Oren (DBA-646). |
| 43 | RoutingReasonID | int | YES | NULL | CODE-BACKED | Reason code explaining why this specific routing path (DepotID + MerchantAccountID) was selected. NULL=legacy/no routing reason recorded (~31%). Values 1-8 in use; 3=most common (~29%), 1=second (~20%), 5=third (~14%). Added by Shabtay E. (PAYUS-3061, 15/06/2021). Enables routing analytics and debugging of routing algorithm decisions. |
| 44 | FlowID | int | YES | NULL | CODE-BACKED | Identifies the deposit flow/UX path used. NULL=legacy or default flow (98.9%). 1=new flow (0.97%), 3=specific flow variant (0.01%). Added by Dor Iz (18/04/2024, PAYIL-8362). Enables A/B testing of deposit UX flows and funnel analytics per flow variant. |
| 45 | ExchangeFeeInUSD | money | YES | NULL | CODE-BACKED | Exchange fee expressed in USD absolute amount. Complements ExchangeFee (which may be in provider-specific units) with a USD-normalized value for standardized reporting. Added for PAYIL-8913/8926 (Elrom B., 25/09/2024). |
| 46 | ExchangeFeePercentage | decimal(10,2) | YES | NULL | CODE-BACKED | Exchange fee as a percentage of the deposit amount (0.00-100.00). Enables direct comparison of fee rates across currencies and deposit types. Added for PAYIL-8913/8926 (Elrom B., 25/09/2024). |
| 47 | FeeConfigurationID | int | YES | NULL | CODE-BACKED | References a fee configuration profile that determined the exchange fee for this deposit. Enables retrospective lookup of which fee rules applied at deposit time. Added by Zipi L. (2026-02-08, PAYIL). NULL for deposits processed before fee configuration framework was introduced. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (FK_CCST_BDEP) | Every deposit belongs to a registered eToro customer |
| FundingID | Billing.Funding | FK (FK_BFND_BDEP) | The payment instrument used for this deposit |
| CurrencyID | Dictionary.Currency | FK (FK_DCUR_BDEP) | Denomination currency of the deposit amount |
| PaymentStatusID | Dictionary.PaymentStatus | FK (FK_DPMS_BDEP) | Current processing state of the deposit |
| RiskManagementStatusID | Dictionary.RiskManagementStatus | FK (FK_DRMS_BDEP) | Risk engine decision code |
| BonusStatusID | Dictionary.BonusStatus | FK (FK_Billing_Deposit_BonusStatusID) | Status of promotional bonus for this deposit |
| FunnelID | Dictionary.Funnel | FK (FK_BD_DF) | Acquisition funnel context |
| CampaignCodeID | BackOffice.Campaign | FK (FK_Billing_Deposit_CampaignCodeID) | Marketing campaign attribution |
| ManagerID | BackOffice.Manager | FK (FK_BMAN_BDEP) | Operations staff who processed this deposit |
| DepotID | Billing.Depot | Implicit | Acquirer/gateway configuration used |
| ProtocolMIDSettingsID | Billing.ProtocolMIDSettings | Implicit | MID configuration profile |
| MerchantAccountID | Billing.MerchantAccountRouting | Implicit | Merchant entity for regulatory routing |
| DepositTypeID | Dictionary.DepositType | Implicit (via DepositProcess JOIN) | Deposit type classification and FTD eligibility |
| ProcessRegulationID | Dictionary.Regulation | Implicit | Regulatory jurisdiction |
| RoutingReasonID | (lookup, undocumented) | Implicit | Routing decision reason |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Deposit | DepositID | Trigger-maintained | Pre-change audit row inserted by Tr_Billing_Deposit_UpdateDelete on every UPDATE/DELETE |
| History.DepositAction | DepositID | Write (DepositAdd/DepositProcess) | Status transition audit trail |
| Billing.ScheduledTaskState | DepositID | Write (DepositAdd) | Tracks scheduled task processing state per deposit |
| Billing.DepositRollbackTracking | DepositID | FK | Rollback operation tracking |
| Billing.DepositHourlyAverage | DepositID | Aggregation source | Hourly deposit volume statistics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.Deposit (table)
  - No code-level dependencies (CREATE TABLE with FK targets only)
  - FK targets (structural, not code dependencies):
    Customer.CustomerStatic (table)
    Billing.Funding (table)
    Dictionary.Currency (table)
    Dictionary.PaymentStatus (table)
    Dictionary.RiskManagementStatus (table)
    Dictionary.BonusStatus (table)
    Dictionary.Funnel (table)
    BackOffice.Campaign (table)
    BackOffice.Manager (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK on CID (FK_CCST_BDEP) |
| Billing.Funding | Table | FK on FundingID (FK_BFND_BDEP) |
| Dictionary.Currency | Table | FK on CurrencyID (FK_DCUR_BDEP) |
| Dictionary.PaymentStatus | Table | FK on PaymentStatusID (FK_DPMS_BDEP) |
| Dictionary.RiskManagementStatus | Table | FK on RiskManagementStatusID (FK_DRMS_BDEP) |
| Dictionary.BonusStatus | Table | FK on BonusStatusID |
| Dictionary.Funnel | Table | FK on FunnelID (FK_BD_DF) |
| BackOffice.Campaign | Table | FK on CampaignCodeID |
| BackOffice.Manager | Table | FK on ManagerID (FK_BMAN_BDEP) |
| dbo.dtPrice | User Defined Type | Type for ExchangeRate and BaseExchangeRate columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Deposit | Table | Audit copy of every modified/deleted row (trigger) |
| History.DepositAction | Table | Status transition log written by DepositAdd and DepositProcess |
| Billing.ScheduledTaskState | Table | Per-deposit task tracking rows created by DepositAdd |
| Billing.DepositAdd | Procedure | Writer - INSERTs new deposit row |
| Billing.DepositProcess | Procedure | Modifier - approves deposit, updates status/IsFTD/amounts |
| Billing.DepositCancel | Procedure | Modifier - cancels pending deposit |
| Billing.DepositRollback | Procedure | Modifier - rolls back approved deposit |
| Billing.UpdateDepositPaymentStatusId | Procedure | Modifier - standalone status update |
| Billing.GetDeposit | Procedure | Reader - retrieves deposit by various criteria |
| Billing.GetDepositByID | Procedure | Reader - retrieves single deposit by DepositID |
| Billing.GetCustomerLastDeposit | Procedure | Reader - latest deposit per customer |
| Billing.GetScheduledTaskAppsFlyerEntities | Procedure | Reader - FTD events for AppsFlyer integration |
| Billing.GetScheduledTaskPixelEntities | Procedure | Reader - FTD events for tracking pixels |
| Billing.GetScheduledTaskRabbitMqFtdEntities | Procedure | Reader - FTD events for RabbitMQ marketing queue |
| Billing.vDeposit | View | View over Billing.Deposit for reporting |
| Billing.FundingDataForDeposit | View | Joins deposit with funding data |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BDEP | CLUSTERED PK | DepositID ASC | - | - | Active; FILLFACTOR=90; DATA_COMPRESSION=PAGE |
| BDEP_ExTransactionID | NC | ExTransactionID ASC | - | - | Active; DATA_COMPRESSION=PAGE |
| BDEP_FUNDING | NC | FundingID ASC | - | - | Active; FILLFACTOR=90; DATA_COMPRESSION=PAGE |
| BDEP_ModificationDate | NC | ModificationDate ASC, CID ASC | - | - | Active; DATA_COMPRESSION=PAGE |
| BDEP_PAYMENTDATE | NC | CID ASC, PaymentDate DESC | FundingID, CurrencyID, PaymentStatusID, Amount, ExchangeRate | - | Active; FILLFACTOR=90; DATA_COMPRESSION=PAGE |
| BDEP_TRANSACTION | UNIQUE NC | CID ASC, TransactionID ASC | - | - | Active; FILLFACTOR=90; DATA_COMPRESSION=PAGE |
| IX_BillingDeposit_PaymentStatusID | NC | PaymentStatusID ASC, PaymentDate ASC | CID | - | Active |
| IX_BillingDeposit_PaymentStatusIDFundingID | NC | FundingID ASC, PaymentStatusID ASC, PaymentDate ASC | - | - | Active |
| IX_BillingDeposit_PaymentStatusID_ModificationDate | NC | PaymentStatusID ASC, ModificationDate ASC | - | - | Active; FILLFACTOR=95 |
| Idx_Billing_Deposit_CID_PaymentStatusID | NC | CID ASC, PaymentStatusID ASC | DepositID, FundingID, Amount, ExchangeRate, IsFTD | - | Active; FILLFACTOR=90; DATA_COMPRESSION=PAGE |
| Idx_Billing_Deposit_IsFTD_CID | NC | IsFTD ASC, CID ASC | Amount, PaymentDate, CurrencyID, ExchangeRate, ModificationDate | - | Active; FILLFACTOR=90 |
| Idx_Billing_Deposit_PaymentDate | NC | PaymentDate ASC | CID | - | Active; FILLFACTOR=90; DATA_COMPRESSION=PAGE |
| i_CureenyID | NC | CurrencyID ASC | - | - | Active (note: typo in index name - "Cureeny" vs "Currency") |
| ix_BillingDepositCoveringForBillingGetScheduledTaskAppsFlyerEntities | NC FILTERED | DepositID ASC | Amount, ExchangeRate, IsFTD, IPAddress, CurrencyID, PaymentStatusID, CID | PaymentStatusID=(2) | Active; FILLFACTOR=95 - dedicated covering index for AppsFlyer FTD task |
| ix_BillingDeposit_Covering1 | NC | DepositID, CID, FundingID, CurrencyID, Amount, DepotID, ModificationDate, PaymentStatusID | - | - | Active; FILLFACTOR=90; DATA_COMPRESSION=PAGE |
| BDEP_XMLPRIMARY | PRIMARY XML | PaymentData | - | - | Active |
| BDEP_XMLPATH | XML PATH | PaymentData | - | - | Active |
| BDEP_XMLPROPERTY | XML PROPERTY | PaymentData | - | - | Active |
| BDEP_XMLVALUE | XML VALUE | PaymentData | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BDEP | PRIMARY KEY CLUSTERED | One row per DepositID |
| BDEP_COMMISSION | DEFAULT (0) | Commission defaults to 0 |
| BDEP_IsFTD | DEFAULT (0) | IsFTD defaults to 0 (not FTD) until DepositProcess sets it |
| DF_Deposit_MatchStatusID | DEFAULT (0) | MatchStatusID defaults to 0 (Unmatched) |
| DF_BillingDepositStatusReasonID | DEFAULT (0) | StatusReasonID defaults to 0 |
| Df_Billing_Deposit_DRStatusID | DEFAULT (0) | DRStatusID defaults to 0 (Not processed) |
| BDEP_ProtocolMIDSettingsID | DEFAULT (0) | ProtocolMIDSettingsID defaults to 0 |
| DF_BillingDeposit_PaymentGeneration | DEFAULT (0) | PaymentGeneration defaults to 0 (Gen0) |
| DF__Deposit__IsSetBalanceCompleted | DEFAULT (0) | IsSetBalanceCompleted defaults to 0 (not completed) |
| FK_CCST_BDEP | FK | CID -> Customer.CustomerStatic(CID) |
| FK_BFND_BDEP | FK | FundingID -> Billing.Funding(FundingID) |
| FK_DCUR_BDEP | FK | CurrencyID -> Dictionary.Currency(CurrencyID) |
| FK_DPMS_BDEP | FK | PaymentStatusID -> Dictionary.PaymentStatus(PaymentStatusID) |
| FK_DRMS_BDEP | FK | RiskManagementStatusID -> Dictionary.RiskManagementStatus(RiskManagementStatusID) |
| FK_BD_DF | FK | FunnelID -> Dictionary.Funnel(FunnelID) |
| FK_BMAN_BDEP | FK | ManagerID -> BackOffice.Manager(ManagerID) |
| FK_Billing_Deposit_BonusStatusID | FK | BonusStatusID -> Dictionary.BonusStatus(BonusStatusID) |
| FK_Billing_Deposit_CampaignCodeID | FK | CampaignCodeID -> BackOffice.Campaign(CampaignID) |

---

## 8. Sample Queries

### 8.1 Get recent approved deposits for a customer with funding type

```sql
SELECT
    d.DepositID,
    d.PaymentDate,
    d.Amount,
    d.CurrencyID,
    d.ExchangeRate,
    d.IsFTD,
    d.DepositTypeID,
    d.ProcessRegulationID,
    ps.Name AS PaymentStatus,
    f.FundingTypeID
FROM Billing.Deposit d WITH (NOLOCK)
JOIN Dictionary.PaymentStatus ps WITH (NOLOCK)
    ON d.PaymentStatusID = ps.PaymentStatusID
JOIN Billing.Funding f WITH (NOLOCK)
    ON d.FundingID = f.FundingID
WHERE d.CID = @CID
  AND d.PaymentStatusID = 2  -- Approved only
ORDER BY d.PaymentDate DESC
```

### 8.2 Find all deposits declined by the risk engine with reason codes

```sql
SELECT
    d.DepositID,
    d.CID,
    d.PaymentDate,
    d.Amount,
    d.CurrencyID,
    ps.Name AS PaymentStatus,
    rms.Name AS RiskManagementStatus,
    d.ProcessRegulationID,
    d.RoutingReasonID
FROM Billing.Deposit d WITH (NOLOCK)
JOIN Dictionary.PaymentStatus ps WITH (NOLOCK)
    ON d.PaymentStatusID = ps.PaymentStatusID
LEFT JOIN Dictionary.RiskManagementStatus rms WITH (NOLOCK)
    ON d.RiskManagementStatusID = rms.RiskManagementStatusID
WHERE d.PaymentStatusID = 35  -- DeclineByRRE
  AND d.PaymentDate >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY d.PaymentDate DESC
```

### 8.3 FTD analysis - first deposits by regulation and deposit type

```sql
SELECT
    d.ProcessRegulationID,
    dt.DepositType,
    COUNT(*) AS FTDCount,
    SUM(d.Amount * d.ExchangeRate) AS TotalUSDEquivalent,
    AVG(d.Amount * d.ExchangeRate) AS AvgUSDEquivalent
FROM Billing.Deposit d WITH (NOLOCK)
LEFT JOIN Dictionary.DepositType dt WITH (NOLOCK)
    ON d.DepositTypeID = dt.DepositTypeID
WHERE d.IsFTD = 1
  AND d.PaymentStatusID = 2
  AND d.PaymentDate >= DATEADD(MONTH, -1, GETUTCDATE())
GROUP BY d.ProcessRegulationID, dt.DepositType
ORDER BY FTDCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [PSP Demo](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/965574752/PSP+Demo) | Confluence | PSP integration patterns and deposit flow context in MIMO Group space |
| [Funding Type Updates](https://etoro-jira.atlassian.net/wiki/spaces/MG/pages/949092542/Funding+Type+Updates) | Confluence | Deposit processing by funding type in MIMO Group space |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 43 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 1,2,3,4,5,6,8,9,10,11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 2 analyzed (DepositAdd, DepositProcess) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.Deposit | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.Deposit.sql*
