-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.ETL_SettlementsTransactions
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions SET TBLPROPERTIES (
    'comment' = 'eMoney_dbo.ETL_SettlementsTransactions **Schema**: eMoney_dbo | **UC Target**: `bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions` **Row count**: ~3.0M (2020-11-17 -> 2026-05-06; daily refresh active) | **Refresh**: daily (Override generic pipeline) **Distribution**: ROUND_ROBIN (default) | **Type**: USER_TABLE **Writer**: `eMoney_dbo.SP_eMoney_Reconciliation_ETLs` (Section: "Reconciliation Table 02 - Settlement Transactions") ---'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions SET TAGS (
    'source_schema' = 'eMoney_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FileName COMMENT 'Source settlement file name from Tribe (often NULL - replaced with NULL in 2025-12-21 SP update).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN WorkDate COMMENT 'Tribe processing timestamp for the settlement event.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN IssuerIdentificationNumber COMMENT 'Tribe-side issuer identification number.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ProgramName COMMENT 'Card program (e.g., ''eToro Money UK GBP'', ''eToro Money EU'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ProgramId COMMENT 'Tribe-side program identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ProductName COMMENT 'Card product label (e.g., ''eToro Money 459688 Consumer Debit Visa'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ProductId COMMENT 'Tribe-side product identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SubProductId COMMENT 'Sub-product identifier within the product family.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN HolderId COMMENT 'Tribe-side holder (customer) identifier. Joins to `FiatAccount.HolderId` -> eToro `Gcid`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN AccountId COMMENT 'Tribe-side account identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BankAccountId COMMENT 'Tribe-side bank-account identifier (if linked).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardNumber COMMENT 'Masked card PAN (e.g., ''4596XX...XX1234''). PII.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardNumberId COMMENT 'Tribe surrogate ID for the card - joins to `ETL_CardSnapshot`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardRequestId COMMENT 'Originating card-request identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Bin COMMENT 'Card BIN (first 6 digits of PAN).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCode COMMENT 'Tribe transaction code (numeric).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCodeDescription COMMENT 'Text label (e.g., ''POS'', ''ATM'', ''REFUND'', ''CHARGEBACK'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionDateTime COMMENT 'Original card-present transaction timestamp.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionAmount COMMENT 'Signed amount in transaction currency (negative = debit, positive = credit/refund).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCurrencyCode COMMENT 'Numeric ISO 4217 of the transaction currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCurrencyAlpha COMMENT 'Alpha-3 ISO of the transaction currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransLink COMMENT 'Tribe-side link/reference for related transactions (e.g., refund -> original auth).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TraceId COMMENT 'Tribe trace identifier for reconciliation.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCodeIdentifier COMMENT 'Secondary numeric grouping code.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN HolderAmount COMMENT 'Amount in holder-account base currency (after FX).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN HolderCurrencyAlpha COMMENT 'Alpha-3 ISO of holder currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxRate COMMENT 'FX rate applied (transaction -> holder currency).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FeeGroupId COMMENT 'Fee-group identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FeeGroupName COMMENT 'Fee-group label.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxFeeAmount COMMENT 'FX-conversion fee amount.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxFeeName COMMENT 'FX-fee label.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxFeeCurrency COMMENT 'FX-fee currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxFeeReason COMMENT 'FX-fee reason / category.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN F0FeeName COMMENT 'Base-service / interchange-related fee label.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN F0FeeAmount COMMENT 'F0-fee amount.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN F0FeeCurrency COMMENT 'Numeric ISO of the F0 fee currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN F0FeeReason COMMENT 'F0-fee reason / category.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BillRateAmount COMMENT 'Conversion rate from transaction currency to billing currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BillingDate COMMENT 'Date the transaction was/will be posted to the billing cycle.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BillingAmount COMMENT 'Billing-currency amount (post-FX).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BillingCurrencyCode COMMENT 'Numeric ISO of the billing currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BillingCurrencyAlpha COMMENT 'Alpha-3 ISO of the billing currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementAmount COMMENT 'Network-side settlement amount in settlement currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementCurrencyCode COMMENT 'Numeric ISO of the settlement currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementCurrencyAlpha COMMENT 'Alpha-3 ISO of the settlement currency (e.g., ''GBP'', ''EUR'', ''USD'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementConversionRate COMMENT 'Transaction -> settlement currency conversion rate (string for precision).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardPresent COMMENT 'Card-present indicator (Y/N or text).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionId COMMENT 'Tribe primary transaction identifier (provider-unique).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionClass COMMENT 'Transaction class label (''POS'', ''ATM'', etc.).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Action COMMENT 'Direction label (''Debit'', ''Credit'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Network COMMENT 'Card network (typically ''Visa'' for eToro Money).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionDescription COMMENT 'Free-text description from Tribe.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN EntryModeCode COMMENT 'EMV entry-mode code.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN EntryModeCodeDescription COMMENT 'Text label for `EntryModeCode`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN LoadType COMMENT 'Tribe load-type code.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN LoadSource COMMENT 'Tribe load-source code.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Suspicious COMMENT 'Risk-engine suspicious-flag label.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN RiskRuleCodes COMMENT 'Comma-separated risk-rule codes triggered.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MarkTransactionAsSuspicious COMMENT 'Risk action - mark as suspicious.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN NotifyCardholderBySendingTAIsNotification COMMENT 'Risk action - send TAIS notification to cardholder.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ChangeCardStatusToRisk COMMENT 'Risk action - auto-change card status to RISK.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ChangeAccountStatusToSuspended COMMENT 'Risk action - auto-suspend account.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN RejectTransaction COMMENT 'Risk action - auto-reject.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardExpirationDatePresent COMMENT 'Auth verification - card expiration date present.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN OnlinePIN COMMENT 'Auth verification - online PIN.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN OfflinePIN COMMENT 'Auth verification - offline PIN.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ThreeDomainSecure COMMENT 'Auth verification - 3DS.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Cvv2 COMMENT 'Auth verification - CVV2.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MagneticStripe COMMENT 'Auth verification - magnetic stripe.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN AVS COMMENT 'Auth verification - Address Verification Service.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN PhoneNumber COMMENT 'Auth verification - phone number.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Signature COMMENT 'Auth verification - signature.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MtiCode COMMENT 'ISO 8583 Message Type Indicator (e.g., 100, 200, 220).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MessageReasonCode COMMENT 'ISO 8583 sub-code clarifying the message reason.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN AuthorizationCode COMMENT 'Visa authorization code (6-char) issued by the issuer for the original auth.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN HolderCurrencyCode COMMENT 'Numeric ISO of holder-account currency (paired with `HolderCurrencyAlpha`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxFeeCode COMMENT 'Tribe-side FX fee code.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN F0FeeCode COMMENT 'Tribe-side F0 fee code.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ReconciliationDate COMMENT 'Visa-network reconciliation date for the settlement batch.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementDate COMMENT 'Date funds settled between acquirer and issuer (Visa scheme).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantNumber COMMENT 'Visa-assigned merchant identifier (acquirer-side MID).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Merchant COMMENT 'Merchant identifier (often duplicate of MerchantName or acquirer''s merchant code).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantName COMMENT 'Merchant display name (raw, often padded with trailing spaces - e.g., ''SAINSBURYS S/MKTS         '').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantAddress COMMENT 'Merchant address line.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantCity COMMENT 'Merchant city.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantPostcode COMMENT 'Merchant postal/ZIP code (numeric - note: not all postcodes fit; UK alphanumeric postcodes may be NULL/truncated here).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantCountryCodeAlpha COMMENT 'Alpha-3 ISO 3166 merchant country code (e.g., ''GBR'', ''USA'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantCountryName COMMENT 'Full merchant country name (e.g., ''United Kingdom'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Mcc COMMENT 'Merchant Category Code (ISO 18245 4-digit; e.g., 5411 = Grocery, 5812 = Restaurants).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardInputMode COMMENT 'POS terminal input mode code (chip, contactless, mag-stripe, manual, etc.).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardholderAuthenticationMethod COMMENT 'Cardholder authentication method label (PIN / Signature / 3DS / None).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN PosDataDe22 COMMENT 'Visa Data Element 22 - POS data code (packed conditions: chip, PIN, etc.).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN PosDataDe61 COMMENT 'Visa Data Element 61 - terminal capabilities.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN AcquirerId COMMENT 'Acquirer institution identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN AcquirerReferenceNumber COMMENT 'ARN - 23-character Visa Acquirer Reference Number (uniquely identifies a transaction across the lifecycle for chargeback/dispute).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN InterchangeFeeAmount COMMENT 'Interchange fee amount (issuer-acquirer).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN InterchangeFeeCurrency COMMENT 'Interchange fee currency (numeric ISO).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN InterchangeFeeDirection COMMENT 'Interchange direction (''IRF Issuer Pays'' / ''IRF Issuer Receives'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN InterchangeRateDesignator COMMENT 'Visa rate-designator code (IRD - e.g., ''Z3'' for consumer signature credit).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CycleNumber COMMENT 'Visa settlement cycle number.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CycleFileId COMMENT 'Visa settlement cycle file identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ECIIndicator COMMENT 'Electronic Commerce Indicator (1=secure 3DS, 5=secure non-3DS, 7=non-secure CNP).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FunctionCode COMMENT 'Visa function code.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementFlag COMMENT 'Settlement flag (0/1 indicating settled vs pending).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCodeQualifier COMMENT 'Visa Transaction Code Qualifier (TCQ).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BusinessFormatCode COMMENT 'Visa Business Format Code (BFC) indicating business segment.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ParentTransactionId COMMENT 'Parent transaction identifier (for refunds/chargebacks pointing to original purchase).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN DisputeId COMMENT 'Tribe-side dispute identifier (NULL for non-disputed transactions).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ExternalDisputeId COMMENT 'External (Visa-network) dispute identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ActualAuthorizationId COMMENT 'Identifier linking to the original authorization (joins back to `ETL_AccountsActivities`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FirstAuthorizationDate COMMENT 'Date/time of the original first authorization (for multi-clearing scenarios).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ChipData COMMENT 'Bit flag - chip data present in the auth message.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Date COMMENT 'Calendar date of the transaction (DATE part of `TransactionDateTime`). Use for date-range filtering.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN DateID COMMENT 'YYYYMMDD integer of `Date`. Joins to `DWH_dbo.Dim_Date.DateID`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN UpdateDate COMMENT 'Batch insert timestamp (`GETDATE()`).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Created COMMENT 'Tribe-side row creation timestamp. **Primary key for incremental load** (max(Created) drives the next-load watermark).';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FileName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN WorkDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN IssuerIdentificationNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ProgramName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ProgramId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ProductName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ProductId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SubProductId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN HolderId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN AccountId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BankAccountId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardNumberId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardRequestId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Bin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCodeDescription SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionDateTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCurrencyCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCurrencyAlpha SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransLink SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TraceId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCodeIdentifier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN HolderAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN HolderCurrencyAlpha SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FeeGroupId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FeeGroupName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxFeeAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxFeeName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxFeeCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxFeeReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN F0FeeName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN F0FeeAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN F0FeeCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN F0FeeReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BillRateAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BillingDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BillingAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BillingCurrencyCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BillingCurrencyAlpha SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementCurrencyCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementCurrencyAlpha SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardPresent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionClass SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Action SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Network SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionDescription SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN EntryModeCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN EntryModeCodeDescription SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN LoadType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN LoadSource SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Suspicious SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN RiskRuleCodes SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MarkTransactionAsSuspicious SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN NotifyCardholderBySendingTAIsNotification SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ChangeCardStatusToRisk SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ChangeAccountStatusToSuspended SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN RejectTransaction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardExpirationDatePresent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN OnlinePIN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN OfflinePIN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ThreeDomainSecure SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Cvv2 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MagneticStripe SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN AVS SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN PhoneNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Signature SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MtiCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MessageReasonCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN AuthorizationCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN HolderCurrencyCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FxFeeCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN F0FeeCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ReconciliationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Merchant SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantAddress SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantCity SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantPostcode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantCountryCodeAlpha SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN MerchantCountryName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Mcc SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardInputMode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CardholderAuthenticationMethod SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN PosDataDe22 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN PosDataDe61 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN AcquirerId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN AcquirerReferenceNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN InterchangeFeeAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN InterchangeFeeCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN InterchangeFeeDirection SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN InterchangeRateDesignator SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CycleNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN CycleFileId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ECIIndicator SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FunctionCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN SettlementFlag SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN TransactionCodeQualifier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN BusinessFormatCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ParentTransactionId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN DisputeId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ExternalDisputeId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ActualAuthorizationId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN FirstAuthorizationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN ChipData SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_settlementstransactions ALTER COLUMN Created SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 11:33:08 UTC
-- Batch deploy resume: eMoney_dbo deploy batch 5
-- Statements: 234/234 succeeded
-- ====================
