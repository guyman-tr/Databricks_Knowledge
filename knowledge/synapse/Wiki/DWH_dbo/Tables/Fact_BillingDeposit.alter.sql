-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_BillingDeposit
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Fact_BillingDeposit` is the DWH''s authoritative record of every deposit attempt on the eToro platform — approved, declined, pending, charged back, or refunded. With 73.9M rows, it is the primary billing analytics table, used for FTD (First Time Deposit) attribution, payment provider performance, fraud analysis, exchange revenue reporting, regulatory compliance segmentation, and customer lifecycle analytics. The table combines data from three production sources: 1. **`Billing.Deposit`** — the core deposit ledger (direct passthrough for 35 columns) 2. **`Billing.Funding`** — payment instrument details (FundingTypeID, IsRefundExcluded, DocumentRequired, AFT flags) 3. **`Billing.RecurringDeposit`** — recurring deposit configuration (OUTER APPLY for IsRecurring flag) Additionally, ~91 columns are extracted from XML blobs stored in `Billing.Deposit.PaymentData` and `Billing.Deposit.FundingData` using the DWH UDF `ExtractXMLValue`. These cover payment-method-specific fields that vary by funding type (cre...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit SET TAGS (
    'domain' = 'billing',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH (DepositID)',
    'synapse_index' = 'CLUSTERED (DepositID ASC) + NC (PaymentStatusID ASC, ExpirationDateID ASC)',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN DepositID COMMENT 'Primary distribution key (HASH). Uniquely identifies each deposit attempt. PK in production (Billing.Deposit.DepositID IDENTITY). Clustered index key in DWH. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CID COMMENT 'Customer ID. Identifies the eToro customer who made this deposit. References DWH_dbo.Dim_Customer. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentStatusID COMMENT 'Current deposit status. Key values: 1=New, 2=Approved (73%), 3=Decline, 5=InProcess, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE (10.2%). Full 39-value enum in upstream wiki. NC index key. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsFTD COMMENT 'First Time Deposit flag. 1=this was the customer''s very first approved deposit (drives marketing attribution). 0=repeat deposit or ineligible type. ~60.6% of deposits are FTD=1 in Billing.Deposit. Stored as int in DWH (vs. bit in production). (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentDate COMMENT 'UTC timestamp when the deposit was submitted (set at INSERT in production). Not the approval time. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of the most recent modification to this deposit record. Used by ETL for incremental detection. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RiskManagementStatusID COMMENT 'Result of the pre-processing risk management check. 69 distinct risk reason codes. NULL=no risk check recorded. Key codes: 1=Success, 35=DeclineByRRE, 47=ML, 49=CustomerToFundingViolation. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN MatchStatusID COMMENT 'PSP reconciliation match status. Default 0=Unmatched; 3=Matched. Used for provider reconciliation workflows. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Amount COMMENT 'Deposit amount in the deposit currency (CurrencyID). As of 2025-04-17, capped via CASE expression in ETL to prevent extreme outlier values from distorting aggregations. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CurrencyID COMMENT 'Currency of the deposit amount. References DWH_dbo.Dim_Currency. 1=USD, 2=EUR, 3=GBP, etc. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExchangeRate COMMENT 'Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BaseExchangeRate COMMENT 'Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Added by Adi (19/09/2019). (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExchangeFee COMMENT 'Exchange fee in provider-specific integer encoding (basis points). Added by Adi (19/02/2019). (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Commission COMMENT 'Commission charged on this deposit. Default 0 in production. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AmountUSD COMMENT 'Deposit amount converted to USD. DWH-computed: Amount × ExchangeRate. Not from production source — pre-computed in ETL for reporting convenience. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FundingID COMMENT 'Payment instrument (credit card, bank account, e-wallet) used for this deposit. References Billing.Funding. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FundingTypeID COMMENT 'Type of payment instrument. Sourced from Billing.Funding.FundingTypeID (not from Billing.Deposit directly). Categorizes the deposit by payment method (credit card, wire, ACH, etc.). (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN DepotID COMMENT 'Acquirer/gateway configuration used for this deposit. Validated at insert against DepotToCurrency in production. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ProtocolMIDSettingsID COMMENT 'Merchant ID configuration profile. Default 0=no specific MID. Added 2018-10-24. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN MerchantAccountID COMMENT 'Merchant account legal entity for regulatory routing. Added with DBA-646. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RoutingReasonID COMMENT 'Reason code for routing path selection. Values 1-8; 3=most common (~29%). ~31% NULL for legacy records. Added PAYUS-3061, 2021-06-15. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ProcessRegulationID COMMENT 'Regulatory entity/jurisdiction: 1=Cyprus/EU (~63%), 2=UK/FCA (~16%), 4=AU (~2.5%), others for ASIC etc. Added DBA-646, 2021-09-05. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FlowID COMMENT 'Deposit UX flow variant. NULL=default (98.9%), 1=new flow (0.97%), 3=specific variant. Added PAYIL-8362, 2024-04-18. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Approved COMMENT 'Legacy approval flag, superseded by PaymentStatusID=2. NULL for most modern records. Retained for backward compatibility. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ProcessorValueDate COMMENT 'Value date from the payment processor. Mandatory for offline/wire deposits. NULL for instant payment methods. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ClearingHouseEffectiveDate COMMENT 'Settlement date assigned by the clearing house. NULL for instant payment methods. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExTransactionID COMMENT 'External (payment provider) transaction ID. Used for provider-side reconciliation and dispute resolution. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RefundVerificationCode COMMENT 'Verification code for refund correlation. Set by UpdateRefundDetails. NULL for non-refunded deposits. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IPAddress COMMENT 'Customer IP address at deposit time, as a 32-bit integer. Used for fraud detection. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN SessionID COMMENT 'Application session ID. Used for PlatformID enrichment via Fact_CustomerAction JOIN (second ETL pass). (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ManagerID COMMENT 'Operations manager who processed this deposit. 0=automated. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FunnelID COMMENT 'Marketing funnel ID. FK to Dictionary.Funnel. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentGeneration COMMENT 'Payment infrastructure generation: 0=Gen0 (7.7%), 1=Gen1 (92%). Added 2020-04-19. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ModificationDateID COMMENT 'ETL key. Integer YYYYMMDD derived from ModificationDate (CONVERT(INT, date)). Used for rolling-window DELETE+INSERT. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExpirationDateID COMMENT 'Integer date ID derived from ExpirationDateAsString XML attribute via a complex formula in SP. Represents card expiration date as YYYYMMDD. NC index key. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. GETDATE() at SP execution. Not from production. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BonusStatusID COMMENT 'Promotional bonus status. Values: 0=New, 1=Approved, 2=Declined, 3=Reverted. Only 239 non-zero records in production. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BonusAmount COMMENT 'Bonus amount credited with this deposit. NULL when no bonus applies. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BonusErrorCode COMMENT 'Error code when bonus processing fails (BonusStatusID=2). NULL when bonus succeeds or not attempted. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PlatformID COMMENT 'Device/platform the customer used for this deposit. NOT from Billing.Deposit — enriched via second ETL pass: JOIN Fact_CustomerAction ON SessionID WHERE ActionTypeID=14. NULL if no matching session action found. References DWH_dbo.Dim_Platform. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsRecurring COMMENT '1=deposit is part of a recurring schedule (OUTER APPLY on Billing.RecurringDeposit). 0=one-time deposit. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsSetBalanceCompleted COMMENT '1=account crediting (Billing.AmountAdd) completed for this deposit. Added DBA-646. (Tier 1 — upstream wiki, Billing.Deposit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsRefundExcluded COMMENT 'Whether this deposit is excluded from refund eligibility. Sourced from Billing.Funding.IsRefundExcluded. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN DocumentRequired COMMENT 'Whether documentation was required for this deposit/funding instrument. Sourced from Billing.Funding.DocumentRequired. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsAftSupportedAsBool COMMENT 'Whether Account Funding Transaction (AFT) is supported by this funding instrument. Sourced from Billing.Funding. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsAftEligibleAsBool COMMENT 'Whether this deposit was eligible for AFT processing. Sourced from Billing.Funding. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsAftProcessedAsBool COMMENT 'Whether this deposit was actually processed via AFT. Sourced from Billing.Funding or Billing.Deposit. (Tier 2 — SP_Fact_BillingDeposit_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ModificationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RiskManagementStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN MatchStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BaseExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExchangeFee SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Commission SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FundingID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN DepotID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ProtocolMIDSettingsID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN MerchantAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RoutingReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ProcessRegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FlowID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Approved SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ProcessorValueDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ClearingHouseEffectiveDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RefundVerificationCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IPAddress SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN SessionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ManagerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FunnelID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentGeneration SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ModificationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExpirationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BonusStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BonusAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BonusErrorCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PlatformID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsRecurring SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsSetBalanceCompleted SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsRefundExcluded SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN DocumentRequired SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsAftSupportedAsBool SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsAftEligibleAsBool SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsAftProcessedAsBool SET TAGS ('pii' = 'none');
