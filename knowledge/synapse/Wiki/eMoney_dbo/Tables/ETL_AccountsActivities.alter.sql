-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.ETL_AccountsActivities
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities SET TBLPROPERTIES (
    'comment' = 'eMoney_dbo.ETL_AccountsActivities **Schema**: eMoney_dbo | **UC Target**: `bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities` **Row count**: ~30.5M (2020-11-06 -> 2026-05-06; daily refresh active) | **Refresh**: daily (Override generic pipeline) **Distribution**: ROUND_ROBIN (default) | **Type**: USER_TABLE **Writer**: `eMoney_dbo.SP_eMoney_Reconciliation_ETLs` (Section: "Reconciliation Table 04 - Account Activities") ---'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities SET TAGS (
    'source_schema' = 'eMoney_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FileName COMMENT 'Source file name from the Tribe feed (often NULL - most transactions are real-time, not file-based).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN WorkDate COMMENT 'Transaction processing date/time on the Tribe side (provider-local time).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN IssuerIdentificationNumber COMMENT 'BIN-like issuer identifier - identifies the eMoney program issuer (Tribe-side IIN).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ProgramName COMMENT 'Human-readable program name (e.g., ''eToro Money UK GBP'', ''eToro Money EU Account'', ''Banking Circle - AUD - Account'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ProgramId COMMENT 'Tribe-side program identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ProductName COMMENT 'Card / account product label (e.g., ''eToro Money 459688 Consumer Debit Visa''). NULL for non-card programs.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ProductId COMMENT 'Tribe-side product identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN SubProductId COMMENT 'Sub-product identifier (e.g., specific card variant within a product family).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN HolderId COMMENT 'Tribe-side holder (customer) identifier. Links via `FiatAccount.HolderId` to eToro `Gcid`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN AccountId COMMENT 'Tribe-side account identifier (a holder may have multiple accounts).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BankAccountId COMMENT 'Tribe-side internal bank account identifier (NULL when not bank-related).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalBankAccountId COMMENT 'Tribe-side identifier for the external counterparty bank account.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BankAccountNumber COMMENT 'Domestic account number (UK/AU style). PII.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BankAccountSortCode COMMENT 'UK sort code (6-digit) of the holder''s eMoney bank account. PII.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BankAccountIban COMMENT 'IBAN of the holder''s eMoney bank account (EU programs). PII.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BankAccountBic COMMENT 'BIC/SWIFT of the holder''s eMoney bank account. PII.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CardNumber COMMENT 'Masked card PAN (typically ''4596XX...XX1234''). PII. NULL for non-card transactions.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CardNumberId COMMENT 'Tribe-side surrogate ID for the card number - joins to `ETL_CardSnapshot.CardNumberId`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CardRequestId COMMENT 'Tribe-side card-request identifier (originating card creation request).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Bin COMMENT 'Bank Identification Number (first 6 digits of PAN) for the card.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionCode COMMENT 'Tribe transaction code - numeric code for the transaction type.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionCodeDescription COMMENT 'Text label for the transaction code (e.g., ''POS'', ''UNLOAD'', ''EPM_INBOUND'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionDateTime COMMENT 'Transaction occurrence timestamp (provider-local time).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionAmount COMMENT 'Signed amount in transaction currency (negative = debit, positive = credit).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionCurrencyCode COMMENT 'Numeric ISO 4217 currency code of the transaction.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionCurrencyAlpha COMMENT 'Alpha-3 ISO 4217 currency code of the transaction (e.g., ''GBP'', ''EUR'', ''AUD'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransLink COMMENT 'Tribe-side link/reference identifier for related transactions (e.g., refund -> original).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TraceId COMMENT 'Tribe-side trace identifier (for transaction reconciliation).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionCodeIdentifier COMMENT 'Secondary numeric code grouping similar TransactionCodes.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN HolderAmount COMMENT 'Transaction amount in the holder-account base currency (after FX).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN HolderCurrencyAlpha COMMENT 'Alpha-3 ISO of the holder-account base currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FxRate COMMENT 'FX rate from transaction currency to holder currency applied to derive `HolderAmount`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FeeGroupId COMMENT 'Tribe-side fee-group identifier - identifies the fee schedule applied.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FeeGroupName COMMENT 'Human-readable fee-group label.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FxFeeAmount COMMENT 'FX-conversion fee amount (NULL when no FX fee).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FxFeeName COMMENT 'FX-fee label / type.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FxFeeCurrency COMMENT 'Currency in which the FX fee is denominated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FxFeeReason COMMENT 'Reason / category for the FX fee.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN F0FeeName COMMENT 'F0 (base service / interchange) fee label.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN F0FeeAmount COMMENT 'F0 fee amount.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN F0FeeCurrency COMMENT 'Numeric ISO currency code of the F0 fee.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN F0FeeReason COMMENT 'Reason / category for the F0 fee.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BillRateAmount COMMENT 'Conversion rate from transaction currency to billing currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BillingDate COMMENT 'Date the transaction is/was posted to the billing cycle.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BillingAmount COMMENT 'Amount charged in billing currency (post-FX, post-fee where applicable).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BillingCurrencyCode COMMENT 'Numeric ISO code of the billing currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BillingCurrencyAlpha COMMENT 'Alpha-3 ISO of the billing currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN SettlementAmount COMMENT 'Network-side settlement amount in settlement currency (after Visa/Mastercard rules).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN SettlementCurrencyCode COMMENT 'Numeric ISO code of the settlement currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN SettlementCurrencyAlpha COMMENT 'Alpha-3 ISO of the settlement currency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN SettlementConversionRate COMMENT 'Conversion rate from transaction -> settlement currency (string for precision).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CardPresent COMMENT 'Card-present indicator (Y/N or text label).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionId COMMENT 'Tribe-side primary transaction identifier (provider-unique).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionClass COMMENT 'Tribe transaction class label (e.g., ''POS'', ''ATM'', ''Unknown'', ''Internal'').';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Action COMMENT 'Direction/action label (''Debit'', ''Credit'', etc.).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Network COMMENT 'Payment network (''Visa'', ''Mastercard'', ''Internal Payment'', ''External Payment'', etc.).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionDescription COMMENT 'Free-text transaction description from Tribe.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EntryModeCode COMMENT 'EMV entry-mode code (chip, contactless, mag-stripe, manual, etc.).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EntryModeCodeDescription COMMENT 'Text label for `EntryModeCode`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ReferenceNumber COMMENT 'Provider reference number (often the card-acquirer ARN).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CountryIson COMMENT 'Numeric ISO country code of the transaction location.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN LoadType COMMENT 'Tribe load-type code (when transaction is a wallet load - distinguishes load source).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN LoadSource COMMENT 'Tribe load-source code (specific load channel).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EpmMethodId COMMENT 'EPM (External Payment Mechanism) method identifier - used for SEPA, Faster Payments, etc.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EpmTransactionId COMMENT 'EPM-specific transaction identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalEpmTransactionId COMMENT 'External (counterparty / scheme) EPM transaction identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EpmTransactionType COMMENT 'EPM transaction type code (Inbound / Outbound / Reversal / etc.).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EpmTransactionStatusCode COMMENT 'EPM status code (Pending / Settled / Failed / Returned / etc.).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EpmMandateId COMMENT 'EPM mandate identifier (for direct-debit mandates).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Reference COMMENT 'Free-text reference field (often counterparty-supplied).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionIdentifier COMMENT 'Provider/scheme transaction identifier (e.g., end-to-end ID for SEPA).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EndToEndIdentifier COMMENT 'SEPA end-to-end identifier.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Suspicious COMMENT 'Provider-side suspicious-flag label.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN RiskRuleCodes COMMENT 'Comma-separated list of risk-engine rule codes triggered by this transaction.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BalanceAdjustmentType COMMENT 'Tribe internal balance-adjustment type code.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN MarkTransactionAsSuspicious COMMENT 'Risk action - flag the transaction as suspicious.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN NotifyCardholderBySendingTAIsNotification COMMENT 'Risk action - send TAIS (Transaction Alerts) notification to cardholder.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ChangeCardStatusToRisk COMMENT 'Risk action - automatically change card status to RISK.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ChangeAccountStatusToSuspended COMMENT 'Risk action - automatically suspend account.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN RejectTransaction COMMENT 'Risk action - reject the transaction (transaction was declined).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CardExpirationDatePresent COMMENT 'Auth verification flag - was card expiration date present in the auth message.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN OnlinePIN COMMENT 'Auth verification flag - online PIN verified.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN OfflinePIN COMMENT 'Auth verification flag - offline PIN verified.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ThreeDomainSecure COMMENT 'Auth verification flag - 3DS authenticated.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Cvv2 COMMENT 'Auth verification flag - CVV2 verified.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN MagneticStripe COMMENT 'Auth verification flag - magnetic stripe used.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN AVS COMMENT 'Auth verification flag - Address Verification Service result valid.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN PhoneNumber COMMENT 'Auth verification flag - phone number verified.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Signature COMMENT 'Auth verification flag - signature verified.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Date COMMENT 'Calendar date of the transaction (DATE part of `TransactionDateTime`). Use for partition / date-range filtering.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN DateID COMMENT 'YYYYMMDD integer of `Date`. Joins to `DWH_dbo.Dim_Date.DateID`.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN UpdateDate COMMENT 'Batch insert timestamp (`GETDATE()` at write).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Created COMMENT 'Tribe-side row creation timestamp. **Primary key for incremental load** (max(Created) drives next-load watermark).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN InternalIbanCountry COMMENT 'Country code of the internal eMoney IBAN.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalIban COMMENT 'Counterparty IBAN. PII.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalBban COMMENT 'Counterparty BBAN. PII.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalAccountName COMMENT 'Counterparty account holder name. PII.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalAccountNumber COMMENT 'Counterparty account number (domestic). PII.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalSortCode COMMENT 'Counterparty sort code (UK). PII.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalBic COMMENT 'Counterparty BIC/SWIFT. PII.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN OriginatorId COMMENT 'Direct-debit originator identifier (UK).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN OriginatorName COMMENT 'Direct-debit originator name.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN OriginatorServiceUserNumber COMMENT 'UK Direct Debit Service User Number (SUN) of the originator.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionReferenceNumber COMMENT 'Provider transaction reference number (separate from `ReferenceNumber` - used by EPM).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ActualEndToEndIdentifier COMMENT 'Actual SEPA / FP end-to-end identifier as received from the counterparty.';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FileName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN WorkDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN IssuerIdentificationNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ProgramName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ProgramId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ProductName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ProductId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN SubProductId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN HolderId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN AccountId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BankAccountId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalBankAccountId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BankAccountNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BankAccountSortCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BankAccountIban SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BankAccountBic SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CardNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CardNumberId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CardRequestId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Bin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionCodeDescription SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionDateTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionCurrencyCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionCurrencyAlpha SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransLink SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TraceId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionCodeIdentifier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN HolderAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN HolderCurrencyAlpha SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FxRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FeeGroupId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FeeGroupName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FxFeeAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FxFeeName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FxFeeCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN FxFeeReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN F0FeeName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN F0FeeAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN F0FeeCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN F0FeeReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BillRateAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BillingDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BillingAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BillingCurrencyCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BillingCurrencyAlpha SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN SettlementAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN SettlementCurrencyCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN SettlementCurrencyAlpha SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN SettlementConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CardPresent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionClass SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Action SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Network SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionDescription SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EntryModeCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EntryModeCodeDescription SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ReferenceNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CountryIson SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN LoadType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN LoadSource SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EpmMethodId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EpmTransactionId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalEpmTransactionId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EpmTransactionType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EpmTransactionStatusCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EpmMandateId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Reference SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionIdentifier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN EndToEndIdentifier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Suspicious SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN RiskRuleCodes SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN BalanceAdjustmentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN MarkTransactionAsSuspicious SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN NotifyCardholderBySendingTAIsNotification SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ChangeCardStatusToRisk SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ChangeAccountStatusToSuspended SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN RejectTransaction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN CardExpirationDatePresent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN OnlinePIN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN OfflinePIN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ThreeDomainSecure SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Cvv2 SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN MagneticStripe SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN AVS SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN PhoneNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Signature SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN Created SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN InternalIbanCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalIban SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalBban SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalAccountName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalAccountNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalSortCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ExternalBic SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN OriginatorId SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN OriginatorName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN OriginatorServiceUserNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN TransactionReferenceNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_etl_accountsactivities ALTER COLUMN ActualEndToEndIdentifier SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 11:30:14 UTC
-- Batch deploy resume: eMoney_dbo deploy batch 5
-- Statements: 212/212 succeeded
-- ====================
