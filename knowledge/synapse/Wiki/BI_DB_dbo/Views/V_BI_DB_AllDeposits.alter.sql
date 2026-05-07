-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.V_BI_DB_AllDeposits
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.V_BI_DB_AllDeposits > 126-column passthrough view over `BI_DB_dbo.BI_DB_AllDeposits`. The base table uses bracketed column names with spaces and special characters (e.g. `[Amount In Orig Curr]`, `[Country (customer)]`). The view exists to expose the same columns under SQL-friendly identifiers - spaces/special chars replaced with underscores - so that downstream UC consumers and SQL clients without bracket-quoting can query without escaping. **For full business logic, lineage, and ETL details, see the parent table wiki: [`BI_DB_AllDeposits.md`](../Tables/BI_DB_AllDeposits.md).** | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | View - alias layer over BI_DB_AllDeposits | | **Production Source** | `BI_DB_dbo.BI_DB_AllDeposits` (which is fed by `DWH_dbo.Fact_BillingDeposit` via `SP_AllDeposits`) | | **Refresh** | Inherits from base table - da'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CID COMMENT 'Customer identifier - joins to `DWH_dbo.Dim_Customer.RealCID` and to other deposits/MIMO panels. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN DepositID COMMENT 'Surrogate primary key of the deposit (one row per dedup''d deposit attempt). FK from `Fact_BillingDeposit`. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN FundingType COMMENT 'Funding method label (`''eToroMoney''`, `''CreditCard''`, `''BankWire''`, `''PayPal''`, `''ACH''`, `''Skrill''`, `''Neteller''`, ...). Resolved from `Dim_FundingType` via `Fact_BillingDeposit.FundingTypeID`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Amount_In_Orig_Curr COMMENT 'Deposit amount in the customer''s local/funding currency. Renamed from base column `[Amount In Orig Curr]`. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Amount_in_USD COMMENT 'Deposit amount converted to USD using the day''s FX rate. Renamed from base column `[Amount in $]`. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Currency COMMENT 'ISO currency code of `Amount_In_Orig_Curr` (`''USD''`, `''EUR''`, `''GBP''`, ...). Resolved from `Dim_Currency` via `Fact_BillingDeposit.CurrencyID`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ModificationDate COMMENT 'UTC timestamp of the most recent modification to this deposit row in the source. Used for incremental ETL detection. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Deposit_Time COMMENT 'UTC timestamp when the deposit was submitted. Renamed from `[Deposit Time]`. NOT the approval time. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Month COMMENT '`MONTH(ModificationDate)`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Day COMMENT '`DAY(ModificationDate)`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Year COMMENT '`YEAR(ModificationDate)`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentStatus COMMENT 'Deposit-state label resolved from `Dim_PaymentStatus`. Top values (2026): `Approved` (83%), `Decline` (6%), `DeclineByRRE` (2%), `Pending` (2%), `InProcess` (2%). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Country_customer COMMENT 'Customer''s registration country. Renamed from `[Country (customer)]`. Resolved via `Dim_Customer.CountryID` -> `Dim_Country.Name`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN FirstDepositDate COMMENT 'Date of customer''s first ever approved deposit. NULL for never-deposited customers. Drives `Category` logic. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Funnel COMMENT 'Marketing funnel name at deposit time. Resolved from `Dim_Funnel` via `Fact_BillingDeposit.FunnelID`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN FunnelFrom COMMENT 'Original acquisition funnel of the customer account. Resolved from `Dim_Funnel` via `Dim_Customer.FunnelFromID`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BINCountry COMMENT 'Country of card issuance, derived from BIN lookup. Resolved from `Dim_Country` WHERE `CountryID = BinCountryIDAsInteger`. NULL for non-card. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Provider COMMENT 'Payment provider/gateway/acquirer name. Resolved from `Dim_BillingDepot.Name` via `Fact_BillingDeposit.DepotID`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardType COMMENT 'Card type label (`''Visa''`, `''Mastercard''`, ...). Resolved from `Dim_CardType`. NULL for non-card. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardSubType COMMENT 'Card subtype (`''Classic''`, `''Gold''`, `''Platinum''`, ...). Resolved from `Dim_CountryBin` via `BinCodeAsString`. NULL for non-card. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN IsFTD COMMENT 'First-Time-Deposit flag. 1 = customer''s very first approved deposit (drives marketing attribution). 0 = repeat or ineligible. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Country_By_Reg_IP COMMENT 'Country inferred from registration IP. Renamed from `[Country By Reg IP]`. Resolved via `Dim_Customer.CountryIDByIP` -> `Dim_Country.Name`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Deposit_Risk_Status COMMENT 'Risk-management decision label for this deposit. Renamed from `[Deposit Risk Status]`. Resolved from `Dim_RiskManagementStatus`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN RiskStatus COMMENT 'Customer-level risk classification at ETL time. Resolved from `Dim_RiskStatus` via `Dim_Customer.RiskStatusID`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN External_Transaction_ID COMMENT 'External (PSP) transaction identifier. Renamed from `[External Transaction ID]`. Used for provider-side reconciliation. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Region COMMENT 'eToro marketing region for the customer''s country. Resolved from `External_etoro_Dictionary_MarketingRegion`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Affiliate_ID COMMENT 'Affiliate partner ID responsible for customer acquisition. Renamed from `[Affiliate ID]`. NULL for organic. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Account_Manager COMMENT 'Full name of assigned AM (`FirstName + '' '' + LastName`). Renamed from `[Account Manager]`. NULL when unassigned. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BinCode COMMENT 'Card BIN as bigint (first 6-8 digits). NULL for non-card. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Bank_name_by_Bincode COMMENT 'Issuing bank name from BIN lookup. Renamed from `[Bank name by Bincode]`. NULL for non-card. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Regulation COMMENT 'Regulatory entity at deposit time (`''CySEC''`, `''FCA''`, `''ASIC & GAML''`, ...). Resolved from `Dim_Regulation` via `Dim_Customer.RegulationID`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN DesignatedRegulation COMMENT 'Designated (preferred) regulatory entity for the customer. May differ from `Regulation`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Category COMMENT 'Deposit category for marketing attribution: `''FTD''` / `''REDEPOSIT''` / `''LEAD''`. Logic: IsFTD=1 -> FTD; FirstDepositDate not null -> REDEPOSIT; else LEAD. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN MID COMMENT 'Merchant ID configuration value for payment routing. Resolved from `External_etoro_Billing_ProtocolMIDSettings`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp (`GETDATE()` at SP_AllDeposits run). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Response COMMENT 'Payment-gateway response name for the latest `DepositAction` row (`''Approved''`, `''Do Not Honor''`, ...). Resolved via `Synapse_Table_etoro_History_DepositAction` -> `External_etoro_Dictionary_Response`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ModificationDateID COMMENT 'YYYYMMDD form of `ModificationDate`. CLUSTERED index key in base. Joins to `Dim_Date.DateKey`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankCode COMMENT 'Bank code for the payment instrument. Alias of `BankCodeAsString` (renamed for readability). (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PSPCode COMMENT 'Payment service provider code. Alias of `PSPCodeAsString` (renamed for readability). Duplicate of #91 for API compatibility. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN FundingID COMMENT 'Payment instrument identifier (card/account/wallet) used for this deposit. Joins to `Billing.Funding`. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AccountBalanceAsDecimal COMMENT 'Account balance from payment provider. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AccountHolderAsString COMMENT 'Account holder name. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AccountIDAsDecimal COMMENT 'Account identifier (numeric string). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ACHBankAccountIDAsInteger COMMENT 'ACH bank account reference ID. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Address1AsString COMMENT 'Billing address line 1. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Address2AsString COMMENT 'Billing address line 2. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AdviseAsString COMMENT 'Payment-provider advisory message. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AvailableBalanceAsDecimal COMMENT 'Available balance from provider. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankCodeAsString COMMENT 'Bank code (string form). Duplicate of `BankCode` (#38) for API compatibility. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankIDAsInteger COMMENT 'Bank identifier integer (string form). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BillNumberAsString COMMENT 'Bill / invoice number. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BuildingNumberAsString COMMENT 'Building number in address. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardHolderPhoneNumberBodyAsString COMMENT 'Cardholder phone number body. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardHolderPhoneNumberPrefixAsString COMMENT 'Cardholder phone number prefix. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardNumberAsString COMMENT 'Card number (masked). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CityAsString COMMENT 'Billing city. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CountryIDAsString COMMENT 'Country identifier string from PSP payload. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CountryNameAsString COMMENT 'Country name from payment XML. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CreatedAtAsString COMMENT 'Payment instrument creation timestamp (string form). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CurrentBalanceAsDecimal COMMENT 'Current balance from provider. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CustomerIDAsString COMMENT 'Customer ID string from payment data (PSP-side identifier). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN EmailAsString COMMENT 'Customer email from payment instrument. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN EndPointIDAsString COMMENT 'Payment-provider endpoint identifier. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ErrorCodeAsString COMMENT 'Provider error code on decline. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ErrorTypeAsString COMMENT 'Provider error type classification. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN FirstNameAsString COMMENT 'Cardholder/account-holder first name. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN IBANCodeAsString COMMENT 'IBAN for wire/SEPA transfers. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN InitialTransactionIDAsString COMMENT 'Initial transaction ID for recurring payments. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN IPAsString COMMENT 'Customer IP from payment data (string form). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN LanguageIDAsInteger COMMENT 'Language ID from payment data. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN LastNameAsString COMMENT 'Cardholder/account-holder last name. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN MD5AsString COMMENT 'MD5 hash from payment provider (integrity / dedup). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PayerAsString COMMENT 'Payer name (PayPal / e-wallet). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PayerBusiness COMMENT 'Payer business name (PayPal). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PayerIDAsString COMMENT 'Payer identifier string. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PayerPurseAsString COMMENT 'Payer purse / wallet ID. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PayerStatus COMMENT 'Payer verification status. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentAmountAsDecimal COMMENT 'Amount from payment XML (string form). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentDateAsDateTime COMMENT 'Payment date from XML (string form). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentGuaranteeAsString COMMENT 'Payment guarantee code. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentModeAsInteger COMMENT 'Payment processing mode (string form). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentProviderTransactionStatusAsString COMMENT 'Status string from provider (raw). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentStatusAsInteger COMMENT 'Status integer from provider (string form). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentTypeAsString COMMENT 'Payment type label from provider. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PlaidItemIDAsString COMMENT 'Plaid (ACH) item identifier. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PlaidNamesAsString COMMENT 'Plaid account-holder names. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PlatformIDAsInteger COMMENT 'Platform from payment XML - separate from any DWH PlatformID. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PromotionCodeAsString COMMENT 'Promotion / voucher code used. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PSPCodeAsString COMMENT 'Payment service provider code. Duplicate of `PSPCode` (#39). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN RapidFirstNameAsString COMMENT 'Rapid (payout) first name. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN RapidLastNameAsString COMMENT 'Rapid (payout) last name. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ResponseMessageAsString COMMENT 'Provider response message. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ResponseTimeAsString COMMENT 'Provider response time (string form). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN SecretKeyAsString COMMENT 'Provider secret key (masked / reference). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ThreeDsAsJson COMMENT 'Raw 3DS authentication data as JSON string - TRUNCATED to 100 chars in this table. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ThreeDsResponseType COMMENT '3DS outcome ID as string. Cast to INT to JOIN `Dim_ThreeDsResponseTypes`. 15 possible values (0-14). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN TokenAsString COMMENT 'Payment token from tokenization service. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN TransactionIDAsString COMMENT 'Provider transaction ID string. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ZipCodeAsString COMMENT 'Billing postal/ZIP code. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AccountIDAsString COMMENT 'Always NULL - hardcoded NULL in `SP_AllDeposits` (kept for schema compatibility). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AccountTypeAsString COMMENT 'Bank account type (`''checking''`, `''savings''`). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankAccountAsString COMMENT 'Bank account number (masked). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankAddressAsString COMMENT 'Bank address. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankCodeAsDecimal COMMENT 'Bank code as numeric string. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankDetailsAccountIDAsString COMMENT 'Bank details account identifier. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankIDAsString COMMENT 'Bank identifier string. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankNameAsString COMMENT 'Name of the bank. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BICCodeAsString COMMENT 'SWIFT / BIC code for wire transfers. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BinCodeAsString COMMENT 'Card BIN (string form) - see also `BinCode` (#29) for bigint form. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BinCountryIDAsInteger COMMENT 'Country ID of card BIN - used to resolve `BINCountry` via `Dim_Country`. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardTypeIDAsInteger COMMENT 'Card type ID - used to resolve `CardType` via `Dim_CardType`. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CIDAsString COMMENT 'Customer ID as string (XML cross-check field). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ClientBankNameAsString COMMENT 'Client''s bank name. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CountryIDAsInteger COMMENT 'Customer country from payment data (integer as string). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CustomerAddressAsString COMMENT 'Customer''s billing address. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CustomerNameAsString COMMENT 'Customer name from payment instrument. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ExpirationDateAsString COMMENT 'Card expiration date as raw string from XML. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN MaskedAccountIDAsString COMMENT 'Masked account/card identifier for display. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PurseAsString COMMENT 'E-wallet purse / account ID. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN RoutingNumberAsString COMMENT 'US ACH routing number. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN SecuredCardDataAsString COMMENT 'Tokenized card data reference. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN SecureIDAsDecimal COMMENT 'Secure transaction ID (numeric string). (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN SortCodeAsString COMMENT 'UK bank sort code. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN SwiftCodeAsString COMMENT 'SWIFT code for wire transfers. (Tier 3)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BaseExchangeRate COMMENT 'Reference exchange rate before fee markup; fee spread = `ExchangeRate - BaseExchangeRate`. (Tier 1)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN DepotID COMMENT 'Acquirer/gateway configuration ID. Validated at insert against `DepotToCurrency` in production. Numeric - see `Provider` for resolved name. (Tier 1)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN FundingType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Amount_In_Orig_Curr SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Amount_in_USD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ModificationDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Deposit_Time SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Month SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Day SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Year SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Country_customer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN FirstDepositDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Funnel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN FunnelFrom SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BINCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Provider SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardSubType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN IsFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Country_By_Reg_IP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Deposit_Risk_Status SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN RiskStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN External_Transaction_ID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Affiliate_ID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Account_Manager SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BinCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Bank_name_by_Bincode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN DesignatedRegulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Category SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN MID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Response SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ModificationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PSPCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN FundingID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AccountBalanceAsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AccountHolderAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AccountIDAsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ACHBankAccountIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Address1AsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN Address2AsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AdviseAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AvailableBalanceAsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BillNumberAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BuildingNumberAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardHolderPhoneNumberBodyAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardHolderPhoneNumberPrefixAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardNumberAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CityAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CountryIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CountryNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CreatedAtAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CurrentBalanceAsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CustomerIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN EmailAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN EndPointIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ErrorCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ErrorTypeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN FirstNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN IBANCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN InitialTransactionIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN IPAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN LanguageIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN LastNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN MD5AsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PayerAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PayerBusiness SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PayerIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PayerPurseAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentAmountAsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentDateAsDateTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentGuaranteeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentModeAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentProviderTransactionStatusAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentStatusAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PaymentTypeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PlaidItemIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PlaidNamesAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PlatformIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PromotionCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PSPCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN RapidFirstNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN RapidLastNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ResponseMessageAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ResponseTimeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN SecretKeyAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ThreeDsAsJson SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ThreeDsResponseType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN TokenAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN TransactionIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ZipCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AccountIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN AccountTypeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankAccountAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankAddressAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankCodeAsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankDetailsAccountIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BankNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BICCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BinCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BinCountryIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CardTypeIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ClientBankNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CountryIDAsInteger SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CustomerAddressAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN CustomerNameAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN ExpirationDateAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN MaskedAccountIDAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN PurseAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN RoutingNumberAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN SecuredCardDataAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN SecureIDAsDecimal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN SortCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN SwiftCodeAsString SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN BaseExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN DepotID SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-07 10:50:31 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 13
-- Statements: 254/254 succeeded
-- ====================
