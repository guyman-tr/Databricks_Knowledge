-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_BillingWithdraw
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw SET TBLPROPERTIES (
    'comment' = '`Fact_BillingWithdraw` is the DWH''s primary withdrawal analytics table. It denormalizes three production tables into a single row per withdrawal-to-funding execution: 1. **Billing.Withdraw** (`bw`): The withdrawal request - customer ID, amount, status, fees, request date 2. **Billing.WithdrawToFunding** (`wtf`): The payment execution leg - processing currency, exchange rate, payment status, depot routing 3. **Billing.Funding** (`bf`): The funding instrument - payment method metadata extracted from XML The ETL uses `DWH_dbo.ExtractXMLValue()` to parse ~40 fields from the XML blobs (`wtf.WithdrawData` and `bf.FundingData`), flattening provider-specific payment details (card numbers, bank accounts, IBAN codes, etc.) into queryable columns. Many fields use a COALESCE pattern that tries the WithdrawToFunding XML first, falling back to the Funding XML when unavailable. After the main load, `SP_Fact_BillingWithdraw` enriches each day''s rows with `BankName` (issuing bank) and `CardCategory` from `Dim_CountryBin` matc'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw SET TAGS (
    'domain' = 'billing',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CID COMMENT 'Customer ID. FK to Customer.CustomerStatic. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN WithdrawID COMMENT 'Withdrawal request identifier. Primary key, IDENTITY starting at 1. HASH distribution key and clustered index column. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CurrencyID COMMENT 'Currency of the withdrawal amount. FK to Dictionary.Currency. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN FundingTypeID_Withdraw COMMENT 'Payment method type of the withdrawal request (Visa/Wire/Neteller/eToroMoney/etc.). 26 distinct values in production. Renamed from FundingTypeID to disambiguate from Billing.Funding''s FundingTypeID. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN RequestDate COMMENT 'Timestamp when the customer submitted the withdrawal request. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Amount_Withdraw COMMENT 'Gross withdrawal amount in CurrencyID denomination. Renamed from Amount to disambiguate from WithdrawToFunding Amount. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Commission COMMENT 'Broker commission on this withdrawal. DEFAULT=0. Typically 0 for retail customers. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Approved COMMENT 'Whether the withdrawal has received required approval. 1=Approved, 0=Pending approval. DEFAULT=0. DWH note: CAST from bit to int. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of the most recent status change or update on the withdrawal request. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ModificationDateID COMMENT 'Integer date key derived from ModificationDate: CONVERT(INT, CONVERT(VARCHAR, ModificationDate, 112)). Format YYYYMMDD. Used for partition-style filtering and the DELETE/INSERT ETL pattern. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Fee COMMENT 'Platform fee charged for this withdrawal. Subtracted from the gross Amount_Withdraw. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN FundingID COMMENT 'FK to Billing.Funding - the payment instrument to which the withdrawal is paid. NULL if no specific instrument selected. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CashoutReasonID COMMENT 'Internal reason code for the withdrawal decision (e.g., why cancelled or flagged). FK to Dim_CashoutReason. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ClientWithdrawReasonID COMMENT 'Customer-selected reason for the withdrawal (e.g., taking profits, funds needed, dissatisfied). FK to Dim_ClientWithdrawReason. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN AccountCurrencyID COMMENT 'Customer eToro account currency, if different from CurrencyID. Used when account and withdrawal currencies differ. FK to Dim_Currency. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CashoutStatusID_Withdraw COMMENT 'Withdrawal request-level status. FK to Dim_CashoutStatus. 10 distinct values: 1=Pending, 2=InProcess, 3=Processed, 4=Cancelled. Renamed from CashoutStatusID. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Comment COMMENT 'Operations comment on the withdrawal request. Free-text field populated by back-office staff. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN FlowID COMMENT 'Processing flow identifier. NULL=legacy, 0=standard, 2=eToroMoney (triggers MoveMoneyReasonID=5), 3=alternate (triggers MoveMoneyReasonID=6). (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN WithdrawTypeID COMMENT 'Withdrawal type classification. NULL=legacy (55%), 0=standard (41%), 1=special/alternate (3.7%), 2=second alternate (0.5%). Added 2024-08-22. (Tier 1 - Billing.Withdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CashoutStatusID_Funding COMMENT 'Execution-level status of the payment leg. FK to Dim_CashoutStatus. Values: 3=Processed (31.5%), 4=Canceled (67.7%), 14=Pending Review, 17=Partially Reversed. Renamed from CashoutStatusID. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ProcessCurrencyID COMMENT 'Currency used for the actual payment processing. May differ from withdrawal CurrencyID when cross-currency routing is applied. FK to Dim_Currency. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ExchangeRate COMMENT 'Exchange rate applied to convert from withdrawal currency to ProcessCurrencyID. NULL for same-currency payouts. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Amount_WithdrawToFunding COMMENT 'Payout amount in ProcessCurrencyID currency. Renamed from Amount. For refunds, the amount being refunded to the instrument. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ModificationDate_WithdrawToFunding COMMENT 'UTC timestamp of the most recent status change on the payment execution leg. Renamed from ModificationDate. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN DepositID COMMENT 'For refund legs (CashoutTypeID=2): references the source Billing.Deposit being refunded. Value 0 is null-equivalent for cashout legs. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CashoutTypeID COMMENT 'Categorizes the type of payment execution: 1=Cashout (standard withdrawal, 69%), 2=Refund (refund of a prior deposit, 31%). (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN VerificationCode COMMENT 'Verification code supplied or received during withdrawal processing. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ProcessorValueDate COMMENT 'Value date from the payment processor - when funds are considered available. Set for wire/ACH payouts; NULL for instant methods. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN DepotID COMMENT 'Which Billing.Depot (acquirer/gateway configuration) processed this payment leg. FK to Dim_BillingDepot. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ExchangeFee COMMENT 'Exchange fee in provider-specific integer units. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN WithdrawPaymentID COMMENT 'Surrogate primary key of the WithdrawToFunding execution leg. Renamed from ID. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BaseExchangeRate COMMENT 'Reference exchange rate before fee markup. Spread = ExchangeRate minus BaseExchangeRate. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ProtocolMIDSettingsID COMMENT 'MID configuration profile used for this payment leg. FK to Dim_BillingProtocolMIDSettingsID. Default=0. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CashoutModeID COMMENT 'Mode of withdrawal execution: 1=Standard (75.2%), NULL=legacy (17%), 2=Alternate e.g. eToroMoney/ACH (4%), 0=Unknown/fallback (3.8%). FK to Dim_CashoutMode. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN FundingTypeID_Funding COMMENT 'Payment method type of the funding instrument receiving the payout. Renamed from FundingTypeID on Billing.Funding. 34 distinct types (Visa/MC/Neteller/PayPal/Wire/eToroMoney/etc.). FK to Dim_FundingType. (Tier 1 - Billing.Funding)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN AccountIDAsString COMMENT 'Payment account identifier. COALESCE: prefers wtf.WithdrawData XML, falls back to bf.FundingData XML. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ACHBankAccountIDAsInteger COMMENT 'ACH bank account identifier for US bank transfers. Extracted from wtf.WithdrawData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BinCodeAsString COMMENT 'Bank Identification Number (first 6-8 digits of card). COALESCE from wtf/bf XML. CAST to INT for JOIN with Dim_CountryBin to populate BankName and CardCategory. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BinCountryIDAsInteger COMMENT 'Country associated with the BIN code. COALESCE from wtf/bf XML. FK to Dim_Country after CAST to INT. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BSBNumberAsString COMMENT 'Bank State Branch number for Australian bank transfers. Extracted from wtf.WithdrawData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CardTypeIDAsInteger COMMENT 'Card type identifier (Visa, Mastercard, etc.). COALESCE from wtf/bf XML. FK to Dim_CardType after CAST to INT. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CityAsString COMMENT 'City from the payment execution data. Extracted from wtf.WithdrawData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ClientAddressAsString COMMENT 'Client address from the payment execution data. Extracted from wtf.WithdrawData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ClientBankNameAsString COMMENT 'Client''s bank name. COALESCE from wtf/bf XML. Distinct from BankNameAsString (#67) which is from bf.FundingData only, and BankName (#82) which is post-load enrichment from Dim_CountryBin. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CountryIDAsInteger COMMENT 'Country identifier from payment data. COALESCE from wtf/bf XML. FK to Dim_Country after CAST to INT. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ExpirationDateAsString COMMENT 'Card expiration date as raw string from wtf.WithdrawData XML. Format varies by provider (MMYY, MM/YY, etc.). See ExpirationDateID (#69) for the normalized integer version. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ErrorCodeAsString COMMENT 'Provider error code if the payment leg failed or was rejected. Extracted from wtf.WithdrawData XML only. NULL for successful transactions. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN IBANCodeAsString COMMENT 'International Bank Account Number for SEPA/wire transfers. COALESCE from wtf/bf XML. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN InitialTransactionIDAsString COMMENT 'Initial transaction reference from the payment provider. Extracted from wtf.WithdrawData XML only. Links the withdrawal to the original deposit transaction for refund tracing. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN MD5AsString COMMENT 'MD5 hash of payment data for verification/deduplication. Extracted from wtf.WithdrawData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN PayeeNameAsString COMMENT 'Payee name from the payment execution. Extracted from wtf.WithdrawData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN PayerPurseAsString COMMENT 'E-wallet purse identifier (e.g., PayPal, Neteller purse ID). Extracted from wtf.WithdrawData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ReferenceNumberAsString COMMENT 'Provider reference number for the transaction. Extracted from wtf.WithdrawData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ResponseMessageAsString COMMENT 'Provider response message (success/failure details). Extracted from wtf.WithdrawData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ResponseTimeAsString COMMENT 'Provider response timestamp as string. Extracted from wtf.WithdrawData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN RoutingNumberAsString COMMENT 'Bank routing number for US bank transfers (ABA routing). COALESCE from wtf/bf XML. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN SecuredCardDataAsString COMMENT 'Secured/tokenized card data from the payment provider. COALESCE from wtf/bf XML. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN SortCodeAsString COMMENT 'Bank sort code for UK bank transfers. COALESCE from wtf/bf XML. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN SwiftCodeAsString COMMENT 'SWIFT/BIC code for international wire transfers. COALESCE from wtf/bf XML. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN AccountIDAsDecimal COMMENT 'Funding instrument account ID (decimal form). Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN AccountNameAsString COMMENT 'Account holder name on the funding instrument. Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN AccountTypeAsString COMMENT 'Account type (checking, savings, etc.). Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankAccountAsString COMMENT 'Bank account number for wire/bank transfers. Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankAddressAsString COMMENT 'Bank address for wire transfers. Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankCodeAsString COMMENT 'Bank code (national bank identifier). Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankDetailsAccountIDAsString COMMENT 'Bank details account reference. Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankIDAsInteger COMMENT 'Bank identifier (integer form). Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankIDAsString COMMENT 'Bank identifier (string form). Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankNameAsString COMMENT 'Bank name from the bf.FundingData XML. Distinct from the enriched BankName (#82) which comes from Dim_CountryBin BIN-code lookup, and ClientBankNameAsString (#44) which is COALESCE from wtf/bf. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CardNumberAsString COMMENT 'Masked card number (last 4 digits typically visible). Extracted from bf.FundingData XML only. Source column FundingData is masked with FUNCTION=''default()'' in production. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CryptoCodeAsString COMMENT 'Cryptocurrency code/address for crypto withdrawals. Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CustomerAddressAsString COMMENT 'Customer address from the funding instrument record. Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CustomerNameAsString COMMENT 'Customer name from the funding instrument record. Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN EmailAsString COMMENT 'Email address associated with the funding instrument (e.g., PayPal email). Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ExpirationDateID COMMENT 'Card expiration date as normalized integer key: 200000 + YY*100 + MM for valid dates; 190001 for NULL or strings shorter than 4 characters. NCI index on this column. Computed from bf.FundingData ExpirationDateAsString XML field. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN InstrumentIDAsInteger COMMENT 'Instrument identifier within the funding provider. Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN MaskedAccountIDAsString COMMENT 'Masked version of the account ID for display/audit. Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN PayerIDAsString COMMENT 'Payer identifier (e.g., PayPal Payer ID). Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN PurseAsString COMMENT 'E-wallet purse identifier from the funding instrument. Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN SecureIDAsDecimal COMMENT 'Secure identifier for payment verification. Extracted from bf.FundingData XML only. (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp (Synapse server time at INSERT via GETDATE()). (Tier 2 - SP_Fact_BillingWithdraw_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankName COMMENT 'Issuing bank name looked up from BIN code via post-load enrichment JOIN to Dim_CountryBin.IssuingBank. NULL when BinCodeAsString is NULL or BIN code not found. Distinct from BankNameAsString (#69) which comes from the funding XML. (Tier 2 - SP_Fact_BillingWithdraw)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CardCategory COMMENT 'Card category (Debit, Credit, Prepaid, etc.) looked up from BIN code via post-load enrichment JOIN to Dim_CountryBin.CardCategory. NULL when BIN code not found. (Tier 2 - SP_Fact_BillingWithdraw)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN WithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN FundingTypeID_Withdraw SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN RequestDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Amount_Withdraw SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Commission SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Approved SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ModificationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ModificationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Fee SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN FundingID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CashoutReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ClientWithdrawReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN AccountCurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CashoutStatusID_Withdraw SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Comment SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN FlowID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN WithdrawTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CashoutStatusID_Funding SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ProcessCurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN Amount_WithdrawToFunding SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ModificationDate_WithdrawToFunding SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CashoutTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN VerificationCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ProcessorValueDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN DepotID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ExchangeFee SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN WithdrawPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BaseExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ProtocolMIDSettingsID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CashoutModeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN FundingTypeID_Funding SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN AccountIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ACHBankAccountIDAsInteger SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BinCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BinCountryIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BSBNumberAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CardTypeIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CityAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ClientAddressAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ClientBankNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CountryIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ExpirationDateAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ErrorCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN IBANCodeAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN InitialTransactionIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN MD5AsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN PayeeNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN PayerPurseAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ReferenceNumberAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ResponseMessageAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ResponseTimeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN RoutingNumberAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN SecuredCardDataAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN SortCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN SwiftCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN AccountIDAsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN AccountNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN AccountTypeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankAccountAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankAddressAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankDetailsAccountIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CardNumberAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CryptoCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CustomerAddressAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CustomerNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN EmailAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN ExpirationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN InstrumentIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN MaskedAccountIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN PayerIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN PurseAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN SecureIDAsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN BankName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw ALTER COLUMN CardCategory SET TAGS ('pii' = 'none');
