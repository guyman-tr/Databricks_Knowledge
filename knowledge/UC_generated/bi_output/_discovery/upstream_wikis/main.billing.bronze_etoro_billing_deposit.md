---
object_fqn: main.billing.bronze_etoro_billing_deposit
object_type: EXTERNAL
producer_kind: bronze_tier1_inheritance
generator: tools/uc_pipelines/generate_wiki.py
object: main.billing.bronze_etoro_billing_deposit
schema: billing
framework: uc-pipeline-doc
table_type: EXTERNAL
format: null
column_count: 47
row_count: null
generated_at: '2026-05-18T10:58:32Z'
upstreams:
- etoro.Billing.Deposit
writer:
  kind: bronze_tier1_inheritance
  path: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md
  source_database: etoro
  source_schema: Billing
  source_table: Deposit
  source_repo: DB_Schema
  datalake_path: Bronze/etoro/Billing/Deposit
  copy_strategy: Override
  source_code_snapshot: null
tier_breakdown:
  tier1_columns: 47
  tier2_columns: 0
  tier3_columns: 0
  tier4_columns: 0
  tier5_columns: 0
  unverified_columns: 0
---

# bronze_etoro_billing_deposit

> Bronze ingest in `main.billing` (1:1 passthrough of `etoro.Billing.Deposit`). 47 of 47 columns inherited from Tier 1 source wiki; 0 columns null-with-provenance.

| Property | Value |
|----------|-------|
| **UC Object** | `main.billing.bronze_etoro_billing_deposit` |
| **Type** | EXTERNAL |
| **Format** | n/a |
| **Owner** | fb0e925c-48b1-48f5-a619-6579d42fb7d4 |
| **Row count** | n/a |
| **Column count** | 47 |
| **Generated** | 2026-05-18 |
| **Created** | Tue Feb 17 08:14:28 UTC 2026 |

---

## 1. What it is

Bronze ingest table populated from production source `etoro.Billing.Deposit` (`DB_Schema` repo). This UC object is a 1:1 passthrough of the source table; no transform is applied during ingest. All column descriptions are inherited byte-for-byte from the Tier 1 source wiki at `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md`.

- Lake path: `Bronze/etoro/Billing/Deposit`
- Copy strategy: `Override`
- Source database: `etoro` (`DB_Schema`)
- Source schema/table: `Billing.Deposit`
- 47 of 47 columns inherited; 0 columns null-with-provenance.

---

## 2. Transform Logic

Pure ingest passthrough — no UC-side transform. The producer is the generic bronze ingest pipeline (Synapse/lake → UC), not a notebook or SP authored in this repo. Refer to the Tier 1 source wiki for the canonical column semantics.

---

## 3. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | DepositID | INT | YES | Primary key. Auto-incremented deposit identifier. NOT FOR REPLICATION - identity values are server-local and not replicated. Referenced by History.Deposit, History.DepositAction, Billing.ScheduledTaskState, and all deposit-centric SPs (Tier 1 — inherited from etoro.Billing.Deposit). |
| 1 | CID | INT | YES | Customer ID. FK to Customer.CustomerStatic (FK_CCST_BDEP). Identifies which eToro customer made this deposit. Indexed as part of multiple composite indexes (BDEP_PAYMENTDATE, BDEP_TRANSACTION, Idx_Billing_Deposit_CID_PaymentStatusID, etc.) for per-customer queries (Tier 1 — inherited from etoro.Billing.Deposit). |
| 2 | FundingID | INT | YES | Payment instrument used for this deposit. FK to Billing.Funding (FK_BFND_BDEP). Identifies the specific credit card, bank account, or e-wallet registered by this customer. Indexed (BDEP_FUNDING). See Billing.Funding for payment instrument details (Tier 1 — inherited from etoro.Billing.Deposit). |
| 3 | CurrencyID | INT | YES | Currency in which the deposit was made. FK to Dictionary.Currency (FK_DCUR_BDEP). Validated at insert time against Billing.DepotToCurrency to confirm the depot supports this currency. Indexed (i_CureenyID). 1=USD, 2=EUR, 3=GBP, 4=AUD, 5=GBP, etc (Tier 1 — inherited from etoro.Billing.Deposit). |
| 4 | PaymentStatusID | INT | YES | Current payment status. FK to Dictionary.PaymentStatus (FK_DPMS_BDEP). Transitions validated by Dictionary.PaymentStatusStateMachine. Values: 1=New, 2=Approved (73%), 3=Decline (7.6%), 4=Technical, 5=InProcess, 6=Canceled, 7=Confirmed, 8=DeclineBlockCard, 9=DeclineBadBins, 10=DeclineMemberLimits, 11=Chargeback, 12=Refund, 13=Pending (4.1%), 14=DeclinedBlockedPayPal, 15=DeclinedBlockedNeteller, 18=DeclinedBlockedCountry, 19=DeclinedHighRiskCID, 20=DeclinedOverTheLimit, 25=MultipleDepositsAggregatedAmount, 26=RefundAsChargeback, 27=MigratedToDepositTable, 31=DeclineBinConflictCountry, 32=DeclineSecurityValidation, 33=DeclineFtdOverTheLimit, 34=DeclineHighRiskCountry, 35=DeclineByRRE (10.2%), 36=PendingReview, 37=ChargebackReversal, 38=RefundReversal, 39=ReversedDeposit. Indexed (IX_BillingDeposit_PaymentStatusID, IX_BillingDeposit_PaymentStatusIDFundingID, IX_BillingDeposit_PaymentStatusID_ModificationDate, Idx_Billing_Deposit_CID_PaymentStatusID) (Tier 1 — inherited from etoro.Billing.Deposit). |
| 5 | ManagerID | INT | YES | Operations manager who processed or last modified this deposit. 0=system/automated processing (no human operator). FK to BackOffice.Manager (FK_BMAN_BDEP). Set during DepositProcess if @ManagerID > 0 overrides the stored value (Tier 1 — inherited from etoro.Billing.Deposit). |
| 6 | RiskManagementStatusID | INT | YES | Result of the risk management pre-check performed before processing. FK to Dictionary.RiskManagementStatus (FK_DRMS_BDEP). NULL=no risk check recorded (most approved deposits). Key decline values: 1=Success, 2=CardIsBlocked, 3=BinInBlackList, 4=MemberLimit, 5=FundingTypeLimit, 10=DeclinedBlackListCountry, 11=DeclinedHighRiskDeposit, 12=OverTheLimit, 18=LoginToRegCountryConflict, 21=BinToRegCountryConflict, 22=FTDOverDailyLimit, 32-35=KYCLevel0-3, 47=ML, 49=CustomerToFundingViolation, 55=ThreeDsVerificationFail, 67=SiftWorkFlow, 69=BusinessRuleRisk. 69 distinct risk reason codes (Tier 1 — inherited from etoro.Billing.Deposit). |
| 7 | Amount | DECIMAL | YES | Deposit amount in the deposit currency (CurrencyID). Stored as MONEY type (4 decimal places). Passed by the application in CENTS as bigint and divided by 100 on INSERT in DepositAdd: `CAST(@Amount AS MONEY) / 100`. For offline/wire deposits, may be updated during DepositProcess with @NewAmount (Tier 1 — inherited from etoro.Billing.Deposit). |
| 8 | ExchangeRate | DECIMAL | YES | Exchange rate from deposit currency to USD, applied at processing time. Cannot be 0 (enforced in DepositAdd). Used in DepositProcess: `Amount * ExchangeRate * 100` to compute USD cents for AmountAdd. For USD deposits, ExchangeRate=1.0 (Tier 1 — inherited from etoro.Billing.Deposit). |
| 9 | PaymentDate | TIMESTAMP | YES | UTC timestamp when the deposit record was created (set to GETUTCDATE() in DepositAdd). Represents the deposit submission time, not the approval time. Indexed (BDEP_PAYMENTDATE composite, Idx_Billing_Deposit_PaymentDate) (Tier 1 — inherited from etoro.Billing.Deposit). |
| 10 | ModificationDate | TIMESTAMP | YES | UTC timestamp of the most recent modification to this record. Set to GETUTCDATE() on INSERT (equals PaymentDate initially) and updated on every status change. Used by data pipeline queries (BDEP_ModificationDate index) to detect changed records incrementally (Tier 1 — inherited from etoro.Billing.Deposit). |
| 11 | TransactionID | STRING | YES | Short internal transaction identifier, unique per customer (unique index BDEP_TRANSACTION on CID+TransactionID). Generated in DepositAdd as a 6-char uppercase hex substring of a GUID: `SUBSTRING(CONVERT(VARCHAR(36), NEWID()), 30, 6)`. Collision-checked per CID before insert. Not the external provider transaction ID (that is ExTransactionID) (Tier 1 — inherited from etoro.Billing.Deposit). |
| 12 | IPAddress | DECIMAL | YES | Customer's IP address at time of deposit, stored as a numeric integer (IPv4 encoded as 32-bit integer). Used for fraud detection - geographic inconsistency checks (IPConflict=RiskManagementStatusID 48). NULL for some older or backend-initiated deposits. Included in AppsFlyer scheduled task index (Tier 1 — inherited from etoro.Billing.Deposit). |
| 13 | Approved | BOOLEAN | YES | Legacy approval flag, superseded by PaymentStatusID=2. NULL for most modern records. Not updated by current code paths (DepositProcess sets PaymentStatusID, not this flag). Retained for backward compatibility with older reporting queries (Tier 1 — inherited from etoro.Billing.Deposit). |
| 14 | Commission | DECIMAL | YES | Commission amount charged on this deposit. Defaults to 0. Not set by DepositAdd (no parameter for it); may be populated by specific commission-based deposit flows or back-office tools (Tier 1 — inherited from etoro.Billing.Deposit). |
| 15 | PaymentData | STRING | YES | Provider-specific payment response XML. Schema varies by FundingType and is validated against `Dictionary.GetXMLSchema` (schema name: 'Deposit' + FundingType.Name) via CLR.ParseXML on every INSERT and UPDATE. Contains auth codes, AVS results, provider transaction IDs, card data (for CC), wire reference numbers (for bank transfers), etc. Primary XML index BDEP_XMLPRIMARY + three secondary XML indexes (BDEP_XMLPATH, BDEP_XMLPROPERTY, BDEP_XMLVALUE) enable XQuery (Tier 1 — inherited from etoro.Billing.Deposit). |
| 16 | ClearingHouseEffectiveDate | TIMESTAMP | YES | The value date assigned by the clearing house for this deposit (when funds are considered settled by the clearing institution). Set for wire/ACH deposits; NULL for instant payment methods. Used in Conversion Rate Management window for wire processing (Tier 1 — inherited from etoro.Billing.Deposit). |
| 17 | OldPaymentID | INT | YES | Reference to a payment record in a legacy system (pre-migration). Used during the historical data migration that moved records with PaymentStatusID=27 (MigratedToDepositTable) from the old payment system. NULL for all modern deposits (Tier 1 — inherited from etoro.Billing.Deposit). |
| 18 | IsFTD | BOOLEAN | YES | Whether this deposit was the customer's First Time Deposit (their very first approved deposit on eToro). Set by DepositProcess: 1=FTD only if no prior IsFTD=1 exists for this CID AND DepositType.ApplyFtd=true. 0=repeat deposit (or deposit type that cannot be FTD, e.g., MoneyTransfer). 60.6% of deposits are FTD=true (reflecting that many customers deposit exactly once). Used by marketing scheduled tasks (AppsFLyer, Pixel, RabbitMQ FTD events). Indexed (Idx_Billing_Deposit_IsFTD_CID) (Tier 1 — inherited from etoro.Billing.Deposit). |
| 19 | ProcessorValueDate | TIMESTAMP | YES | The value date provided by the payment processor, indicating when funds are credited on the processor side. Mandatory for offline/wire deposits (DepositProcess validates: IsSingleFunding=1 or FundingTypeID=17 must supply this). NULL for online/instant deposits where the processor date equals PaymentDate (Tier 1 — inherited from etoro.Billing.Deposit). |
| 20 | RefundVerificationCode | STRING | YES | Verification code supplied or received during a refund operation. Set by DepositUpdateRefundDetails. Used to correlate refund requests with provider-side refund confirmations. NULL for non-refunded deposits (Tier 1 — inherited from etoro.Billing.Deposit). |
| 21 | DepotID | INT | YES | Identifies which Billing.Depot (acquirer/processor configuration) handled this deposit. Validated at INSERT time: Billing.DepotToCurrency must confirm the depot supports the requested CurrencyID. May be updated during DepositProcess via @NewDepotID for offline deposits routed to a different depot after initial placement. No explicit FK constraint. See Billing.Depot (documented) for depot configurations (Tier 1 — inherited from etoro.Billing.Deposit). |
| 22 | MatchStatusID | INT | YES | PSP reconciliation match status. Default 0=Unmatched (99.9999% of records). 3=Matched (6 live records) - deposit has been matched to a provider-side settlement record via PSPMatchToEtoro/PSPMatchToEtoro2. Used for payment provider reconciliation workflows (Tier 1 — inherited from etoro.Billing.Deposit). |
| 23 | FunnelID | INT | YES | Marketing funnel identifier for this deposit. FK to Dictionary.Funnel (FK_BD_DF). Tracks which acquisition funnel the customer came through at time of deposit. Most deposits have FunnelID=36. Used in deposit reporting for funnel-level conversion analysis (Tier 1 — inherited from etoro.Billing.Deposit). |
| 24 | Code | STRING | YES | Provider-specific code or reference associated with this deposit (e.g., provider confirmation code, voucher code). Distinct from TransactionID (internal) and ExTransactionID (provider transaction ID). NULL for most deposits (Tier 1 — inherited from etoro.Billing.Deposit). |
| 25 | ExTransactionID | STRING | YES | External (provider) transaction ID returned by the payment processor. Set during DepositProcess via @ExTransactionID parameter. Used for provider-side reconciliation and dispute resolution. Indexed (BDEP_ExTransactionID). Also accessible via Billing.GetDepositByExTransactionID (Tier 1 — inherited from etoro.Billing.Deposit). |
| 26 | CampaignCodeID | INT | YES | Campaign that was active for this customer at deposit time. FK to BackOffice.Campaign (FK_Billing_Deposit_CampaignCodeID). Links deposit revenue to acquisition campaigns for marketing ROI calculation. NULL = no campaign associated (Tier 1 — inherited from etoro.Billing.Deposit). |
| 27 | BonusStatusID | INT | YES | Status of any bonus associated with this deposit. FK to Dictionary.BonusStatus (FK_Billing_Deposit_BonusStatusID). Values: 0=New (default, no bonus pending), 1=Approved (bonus credited), 2=Declined (bonus request rejected), 3=Reverted (bonus reversed). Only 239 non-zero records in live data (Tier 1 — inherited from etoro.Billing.Deposit). |
| 28 | BonusAmount | DECIMAL | YES | Bonus amount credited or attempted in connection with this deposit. Populated alongside BonusStatusID when a promotional bonus is associated with the deposit. NULL when no bonus applies (Tier 1 — inherited from etoro.Billing.Deposit). |
| 29 | BonusErrorCode | INT | YES | Error code returned by the bonus processing system when a bonus request fails (BonusStatusID=2). Identifies the specific reason for bonus decline. NULL when bonus succeeds or is not attempted (Tier 1 — inherited from etoro.Billing.Deposit). |
| 30 | SessionID | LONG | YES | Application session ID at time of deposit. Passed through from the cashier application session context. Carried into History.DepositAction for session-level audit trail. NULL for backend/non-browser-session deposits (Tier 1 — inherited from etoro.Billing.Deposit). |
| 31 | DepositTypeID | INT | YES | Type of deposit. FK to Dictionary.DepositType (referenced in DepositProcess). Values: NULL=legacy pre-type-classification, 0=unknown, 1=Regular (standard card/e-wallet deposit, 43.4%), 2=CvvFree (card deposit without CVV), 3=Recurring (scheduled recurring payment), 4=MoneyTransfer (internal transfer, cannot be FTD), 5=RecurringInvestment (recurring investment, 0.7%). ApplyFtd column in DepositType determines IsFTD eligibility (Tier 1 — inherited from etoro.Billing.Deposit). |
| 32 | StatusReasonID | INT | YES | Additional reason code for the current payment status. Default 0=no specific reason. Values in use: 1, 2=3rd most common (64K records), 3=2nd most common (189K records). Updated by UpdateDepositStatusReasonID. Provides sub-classification of decline/approval reasons beyond PaymentStatusID (Tier 1 — inherited from etoro.Billing.Deposit). |
| 33 | DRStatusID | INT | YES | Delayed Revenue (DR) processing pipeline status. Default 0=Not processed (94.5%). 1=DR Processed (4.5%), 3=DR In Progress (1%), 2=DR Error (<0.01%). Tracks whether this deposit has been processed through the DR financial reporting pipeline for regulatory/revenue recognition purposes (Tier 1 — inherited from etoro.Billing.Deposit). |
| 34 | DRDate | TIMESTAMP | YES | UTC timestamp when DR processing completed. NULL when DRStatusID=0 (not yet processed). Set when DRStatusID transitions to 1 (Processed) (Tier 1 — inherited from etoro.Billing.Deposit). |
| 35 | ProtocolMIDSettingsID | INT | YES | References Billing.ProtocolMIDSettings - the specific Merchant ID (MID) configuration profile used for this deposit's processing. Default 0=no specific MID assigned. Updated during DepositProcess if @ProtocolMIDSettingsID > 0. Determines which merchant account / acquirer configuration was active for this specific transaction. Added by Ran Ovadia (FB: 52829, 24/10/2018) (Tier 1 — inherited from etoro.Billing.Deposit). |
| 36 | ExchangeFee | INT | YES | Exchange fee charged for currency conversion, in basis points or a provider-specific integer encoding. Added by Adi (19/02/2019). Carried through from DepositAdd/@ExchangeFee parameter into History.DepositAction. Complemented by ExchangeFeeInUSD and ExchangeFeePercentage for full fee decomposition (Tier 1 — inherited from etoro.Billing.Deposit). |
| 37 | BaseExchangeRate | DECIMAL | YES | The reference exchange rate before any fee markup is applied. Added by Adi (19/09/2019). Enables computation of the fee spread: `ExchangeRate - BaseExchangeRate = spread charged to customer`. Used in BI reports (BI_Deposit_PIPS_Report, BI_Deposit_State_Report) (Tier 1 — inherited from etoro.Billing.Deposit). |
| 38 | PaymentGeneration | INT | YES | Payment processing generation/API version used for this deposit. Values: 0=Generation 0 (legacy, 7.7%), 1=Generation 1 (current, 92%). Added by Adi (19/04/2020). Distinguishes deposits processed through the new payment service infrastructure from older legacy paths. Carried into History.DepositAction (Tier 1 — inherited from etoro.Billing.Deposit). |
| 39 | ProcessRegulationID | INT | YES | Regulatory entity/jurisdiction that processed this deposit. Values: 1=Cyprus/EU (~63%), 2=UK/FCA (~16%), 4=Australia (~2.5%), 7-14=other regulated jurisdictions. Added by Shay Oren (DBA-646, 05/09/2021). Determines applicable regulatory rules (position limits, leverage caps, reporting requirements). Referenced by GetCustomerRegulationByDepositId (Tier 1 — inherited from etoro.Billing.Deposit). |
| 40 | MerchantAccountID | INT | YES | References Billing.MerchantAccountRouting - the merchant account legal entity used for this deposit (for multi-entity regulatory routing). Added by Shay Oren (DBA-646). NULL=legacy or auto-routed. Populated by GetMerchantValuesByDeposit. See Billing.MerchantAccountRouting for entity configurations (Tier 1 — inherited from etoro.Billing.Deposit). |
| 41 | IsSetBalanceCompleted | BOOLEAN | YES | Whether the balance set/credit operation (`Billing.AmountAdd`) for this deposit has been completed. Set by IsSetBalanceCompleted=1 after AmountAdd succeeds. Used in reconciliation to identify deposits where account crediting completed vs. those pending retry. Added by Shay Oren (DBA-646) (Tier 1 — inherited from etoro.Billing.Deposit). |
| 42 | RoutingReasonID | INT | YES | Reason code explaining why this specific routing path (DepotID + MerchantAccountID) was selected. NULL=legacy/no routing reason recorded (~31%). Values 1-8 in use; 3=most common (~29%), 1=second (~20%), 5=third (~14%). Added by Shabtay E. (PAYUS-3061, 15/06/2021). Enables routing analytics and debugging of routing algorithm decisions (Tier 1 — inherited from etoro.Billing.Deposit). |
| 43 | FlowID | INT | YES | Identifies the deposit flow/UX path used. NULL=legacy or default flow (98.9%). 1=new flow (0.97%), 3=specific flow variant (0.01%). Added by Dor Iz (18/04/2024, PAYIL-8362). Enables A/B testing of deposit UX flows and funnel analytics per flow variant (Tier 1 — inherited from etoro.Billing.Deposit). |
| 44 | ExchangeFeeInUSD | DECIMAL | YES | Exchange fee expressed in USD absolute amount. Complements ExchangeFee (which may be in provider-specific units) with a USD-normalized value for standardized reporting. Added for PAYIL-8913/8926 (Elrom B., 25/09/2024) (Tier 1 — inherited from etoro.Billing.Deposit). |
| 45 | ExchangeFeePercentage | DECIMAL | YES | Exchange fee as a percentage of the deposit amount (0.00-100.00). Enables direct comparison of fee rates across currencies and deposit types. Added for PAYIL-8913/8926 (Elrom B., 25/09/2024) (Tier 1 — inherited from etoro.Billing.Deposit). |
| 46 | FeeConfigurationID | INT | YES | References a fee configuration profile that determined the exchange fee for this deposit. Enables retrospective lookup of which fee rules applied at deposit time. Added by Zipi L. (2026-02-08, PAYIL). NULL for deposits processed before fee configuration framework was introduced (Tier 1 — inherited from etoro.Billing.Deposit). |

---

## 4. Lineage

### 4.1 Upstream UC Objects

| Upstream | Role | Wiki |
|----------|------|------|
| `etoro.Billing.Deposit` | Primary | `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` |

### 4.2 Pipeline ASCII Diagram

```
etoro.Billing.Deposit
        │
        ▼
main.billing.bronze_etoro_billing_deposit   ←── this object
        │
        ▼
main.bi_output.bi_output_finance_tables_bi_db_positions_opened_from_iban
main.bi_output.bi_output_operations_yoni_davideresta_alerts
```

### 4.3 Cross-check vs system.access.column_lineage

`parsed=0 runtime=0 mismatches=0` — see `.lineage.md` `## Cross-check` section for per-column detail.

---

## 5. Sample Queries & Common JOINs

### 5.1 Sample queries

> Sample queries are not auto-generated in this pack; refer to `knowledge/skills/_de_existing/` and `system.query.history` for analyst usage.

### 5.2 Common JOIN partners

| JOIN to | Condition | Purpose |
|---------|-----------|---------|
| (none discovered from upstream JOINs in `.lineage.md`) | — | — |

### 5.3 Gotchas

- See `.review-needed.md` for parser warnings, UNVERIFIED columns, and any Tier-4 sample-only candidates.

---

## 6. Deploy / UC ALTER provenance

| Column | Description source | Tier | Cited as |
|--------|--------------------|------|----------|
| DepositID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| CID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| FundingID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| CurrencyID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| PaymentStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| ManagerID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| RiskManagementStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| Amount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| ExchangeRate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| PaymentDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| ModificationDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| TransactionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| IPAddress | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| Approved | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| Commission | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| PaymentData | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| ClearingHouseEffectiveDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| OldPaymentID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| IsFTD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| ProcessorValueDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| RefundVerificationCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| DepotID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| MatchStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| FunnelID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| Code | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| ExTransactionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| CampaignCodeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| BonusStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| BonusAmount | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| BonusErrorCode | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| SessionID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| DepositTypeID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| StatusReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| DRStatusID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| DRDate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| ProtocolMIDSettingsID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| ExchangeFee | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| BaseExchangeRate | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| PaymentGeneration | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| ProcessRegulationID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| MerchantAccountID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| IsSetBalanceCompleted | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| RoutingReasonID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| FlowID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| ExchangeFeeInUSD | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| ExchangeFeePercentage | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |
| FeeConfigurationID | upstream wiki `knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Tables/Billing.Deposit.md` (bronze passthrough) | 1 | (Tier 1 — inherited from etoro.Billing.Deposit) |

---

## 7. Tier Legend

- **Tier 1** — column inherited byte-for-byte from a documented Tier-1 upstream wiki (passthrough).
- **Tier 5** — null-with-provenance: column present in bronze ingest but not yet documented in the Tier 1 source wiki (schema drift or post-ingest addition).

*Generated: 2026-05-18 | Tiers: 47 T1, 0 T2, 0 T3, 0 T4, 0 T5, 0 U | Elements: 47/47 | Source: bronze_tier1_inheritance*
