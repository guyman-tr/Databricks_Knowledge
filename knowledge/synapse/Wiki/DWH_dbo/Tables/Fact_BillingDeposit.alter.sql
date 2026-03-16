-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_BillingDeposit
-- Generated: 2026-03-15 | Updated: 2026-03-15 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
-- Resolved via: information_schema search
-- Synapse Source: DWH_dbo.Fact_BillingDeposit
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit SET TBLPROPERTIES (
    'comment' = 'Central deposit fact table recording every monetary deposit attempt by eToro customers. Each row = one deposit transaction (approved or declined). Key filter: PaymentStatusID=2 for approved deposits. Source: etoroDB.Billing.Deposit + Billing.Funding via SP_Fact_BillingDeposit_DL_To_Synapse. Daily incremental by ModificationDateID. 136 columns including ~70 XML-extracted payment provider response fields. Synapse: HASH(DepositID), CLUSTERED INDEX(DepositID). UC: Delta, partitioned by etr_y/etr_ym/etr_ymd. Column ''v'' is actually ClientBankNameAsString (truncated alias bug). AmountUSD = Amount * ExchangeRate.'
);

-- ---- Table Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit SET TAGS (
    'domain' = 'billing',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'source_server' = 'sql_dp_prod_we',
    'refresh_frequency' = 'daily',
    'sla' = 'D+1 03:00',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(DepositID)',
    'synapse_index' = 'CLUSTERED INDEX(DepositID)',
    'uc_format' = 'delta',
    'uc_partitioned_by' = 'etr_y, etr_ym, etr_ymd',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase',
    'semantic_grade' = '4'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CID COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CurrencyID COMMENT 'Deposit currency: 1=USD, 2=EUR, 3=GBP, 5=AUD, 6=CHF + 28 others. FK to Dim_Currency. (Tier 2 — Dim lookup)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Commission COMMENT 'Commission charged on the deposit, in deposit currency. Typically 0. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Approved COMMENT '[DEPRECATED] Legacy approval flag. 99.99% NULL. Use PaymentStatusID instead. (Tier 3 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ModificationDate COMMENT 'Timestamp of last modification. Primary date column for filtering. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ModificationDateID COMMENT 'Date key YYYYMMDD from ModificationDate. FK to Dim_Date. ETL-computed. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FundingID COMMENT 'Funding instrument ID. FK to staging etoro_Billing_Funding. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExchangeRate COMMENT 'Conversion rate from deposit currency to USD. Used to compute AmountUSD. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN DepositID COMMENT 'Unique deposit transaction ID. Distribution key + clustered index. Effectively the PK. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ProcessorValueDate COMMENT 'Payment processor settlement date. ~29% populated. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN DepotID COMMENT 'Payment processor/depot: 87=CyberSource, 92=Checkout.com, 12=PayPal, 88=eToroMoney. FK to Dim_BillingDepot. (Tier 2 — Dim lookup)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN SecuredCardDataAsString COMMENT '[UNVERIFIED] Encrypted/hashed card data from FundingData XML. (Tier 4 — column name)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BinCodeAsString COMMENT 'Card BIN code (first 6-8 digits) from FundingData XML. Used to JOIN Dim_CountryBin for BankName + CardCategory. (Tier 5 — domain expert)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BinCountryIDAsInteger COMMENT 'Country ID from BIN lookup, from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CardTypeIDAsInteger COMMENT 'Card network: 1=Visa, 2=MasterCard, 3=Diners. From FundingData XML. FK to Dim_CardType. (Tier 2 — Dim lookup)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentStatusID COMMENT 'Payment lifecycle: 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE. FK to Dim_PaymentStatus. Key filter: =2 for approved. (Tier 2 — Dim lookup)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ManagerID COMMENT 'Manager/account manager ID. 98.9% populated. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RiskManagementStatusID COMMENT 'Risk check result: 1=Success, 2-69=various decline reasons. FK to Dim_RiskManagementStatus. 95.2% NULL. (Tier 2 — Dim lookup)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Amount COMMENT 'Deposit amount in deposit currency. Capped at +/-99,999,999 in ETL (fix 2025-04-17). (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentDate COMMENT 'When the payment was initiated by the customer. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IPAddress COMMENT 'Customer''s IP address stored as numeric. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ClearingHouseEffectiveDate COMMENT 'Clearing house settlement date. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsFTD COMMENT 'First Time Deposit flag: 1=first deposit for this CID, 0=subsequent. 8% are FTD. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RefundVerificationCode COMMENT '[UNVERIFIED] Verification code for refund processing. (Tier 4 — column name)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN MatchStatusID COMMENT 'Electronic verification: 0=None(97.4%), 2=Verified, 3=NotVerified. FK to Dim_EvMatchStatus. (Tier 2 — Dim lookup)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BonusStatusID COMMENT 'Bonus status: NULL=61.4%, 0=none(38.3%), 1=active, 2=expired. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BonusAmount COMMENT 'Bonus amount credited. 99.98% NULL. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BonusErrorCode COMMENT 'Error code from bonus processing. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExTransactionID COMMENT 'External transaction ID from payment provider. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FundingTypeID COMMENT 'Payment method: 1=CreditCard, 2=WireTransfer, 3=PayPal, 8=Skrill, 28=OnlineBanking, 29=ACH, 33=eToroMoney, 34=iDEAL, 35=Trustly. FK to Dim_FundingType. (Tier 2 — Dim lookup)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsRefundExcluded COMMENT '1=excluded from refund eligibility (1.3%), 0=eligible. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN DocumentRequired COMMENT '1=document required for deposit (56.7%), 0=not required. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Pre-2020 records show 2020-02-09 (migration date). (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExpirationDateID COMMENT 'Card expiration YYYYMM. 190001=missing/invalid. ETL-computed from ExpirationDateAsString. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CountryIDAsInteger COMMENT 'Country ID from payment provider response, from FundingData XML. FK to Dim_Country. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN StateIDAsInteger COMMENT 'State/province ID from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BankIDAsInteger COMMENT 'Bank ID from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AccountNameAsString COMMENT 'Account holder name from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AccountTypeAsString COMMENT 'Account type from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BankAccountAsString COMMENT 'Bank account number from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BankAddressAsString COMMENT 'Bank address from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BankCodeAsDecimal COMMENT 'Bank code (numeric) from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BankDetailsAccountIDAsString COMMENT 'Bank details account ID from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BankIDAsString COMMENT 'Bank ID (string) from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BankNameAsString COMMENT 'Bank name from FundingData XML. Raw provider value (vs BankName which is enriched from Dim_CountryBin). (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BICCodeAsString COMMENT 'BIC/SWIFT code from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CIDAsString COMMENT '[UNVERIFIED] Customer ID as string from FundingData XML. May differ from CID column. (Tier 4 — column name)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN `v` COMMENT 'ClientBankNameAsString (TRUNCATED ALIAS BUG). Client bank name from FundingData XML. ETL code: ExtractXMLValue(''ClientBankNameAsString'', FundingData) aliased as ''v''. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CustomerAddressAsString COMMENT 'Customer address from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CustomerNameAsString COMMENT 'Customer name from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FundingType COMMENT 'Funding type name from FundingData XML. String version of FundingTypeID. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN MaskedAccountIDAsString COMMENT 'Masked payment account ID from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PurseAsString COMMENT 'E-wallet purse identifier from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RoutingNumberAsString COMMENT 'Bank routing number from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN SecureIDAsDecimal COMMENT 'Secure ID from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN SortCodeAsString COMMENT 'Bank sort code from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AccountBalanceAsDecimal COMMENT 'Account balance from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AccountHolderAsString COMMENT 'Account holder name from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AccountIDAsDecimal COMMENT 'Account ID from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ACHBankAccountIDAsInteger COMMENT 'ACH bank account ID from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Address1AsString COMMENT 'Address line 1 from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Address2AsString COMMENT 'Address line 2 from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AdviseAsString COMMENT '[UNVERIFIED] Payment advisory message from PaymentData XML. (Tier 4 — column name)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AvailableBalanceAsDecimal COMMENT 'Available balance from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BankCodeAsString COMMENT 'Bank code (string) from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BillNumberAsString COMMENT 'Bill/invoice number from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BuildingNumberAsString COMMENT 'Building number (address) from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CardHolderPhoneNumberBodyAsString COMMENT 'Card holder phone number (body) from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CardHolderPhoneNumberPrefixAsString COMMENT 'Card holder phone prefix from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CardNumberAsString COMMENT 'Card number (masked/partial) from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CityAsString COMMENT 'City from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CountryIDAsString COMMENT 'Country identifier (string) from PaymentData XML. Used to derive MOPCountry via Dim_Country. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CountryNameAsString COMMENT 'Country name from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CreatedAtAsString COMMENT 'Creation timestamp from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CurrentBalanceAsDecimal COMMENT 'Current balance from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CustomerIDAsString COMMENT 'Customer ID from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN EmailAsString COMMENT 'Customer email from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN EndPointIDAsString COMMENT 'Payment endpoint ID from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ErrorCodeAsString COMMENT 'Error code from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ErrorTypeAsString COMMENT 'Error type from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FirstNameAsString COMMENT 'Customer first name from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IBANCodeAsString COMMENT 'IBAN from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN InitialTransactionIDAsString COMMENT 'Initial/original transaction ID from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IPAsString COMMENT 'IP address (string) from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN LanguageIDAsInteger COMMENT 'Language ID from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN LastNameAsString COMMENT 'Customer last name from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN MD5AsString COMMENT '[UNVERIFIED] MD5 hash from PaymentData XML. Purpose unclear. (Tier 4 — column name)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PayerAsString COMMENT 'Payer name from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PayerBusiness COMMENT 'Payer business name from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PayerIDAsString COMMENT 'Payer ID from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PayerPurseAsString COMMENT 'Payer e-wallet purse from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PayerStatus COMMENT 'Payer status from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentAmountAsDecimal COMMENT 'Payment amount from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentDateAsDateTime COMMENT 'Payment date from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentGuaranteeAsString COMMENT '[UNVERIFIED] Payment guarantee indicator from PaymentData XML. (Tier 4 — column name)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentModeAsInteger COMMENT '[UNVERIFIED] Payment mode ID from PaymentData XML. (Tier 4 — column name)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentProviderTransactionStatusAsString COMMENT 'Transaction status from payment provider, from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentStatusAsInteger COMMENT 'Payment status (integer) from PaymentData XML. Provider''s own status code. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentTypeAsString COMMENT 'Payment type from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PlaidItemIDAsString COMMENT 'Plaid item ID from PaymentData XML. Used for ACH/Plaid integrations. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PlaidNamesAsString COMMENT 'Plaid account holder names from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PlatformIDAsInteger COMMENT 'Platform ID (string) from PaymentData XML. Different from PlatformID column. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PromotionCodeAsString COMMENT 'Promotion/coupon code from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PSPCodeAsString COMMENT 'Payment Service Provider code from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RapidFirstNameAsString COMMENT 'RapidTransfer first name from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RapidLastNameAsString COMMENT 'RapidTransfer last name from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ResponseMessageAsString COMMENT 'Provider response message from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ResponseTimeAsString COMMENT 'Provider response time from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN SecretKeyAsString COMMENT '[UNVERIFIED] Secret key from PaymentData XML. Potential security concern. (Tier 4 — column name)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ThreeDsAsJson COMMENT '3D Secure response data as JSON from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ThreeDsResponseType COMMENT '3D Secure response type from PaymentData XML. Values include ''1''. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN TokenAsString COMMENT 'Payment token from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN TransactionIDAsString COMMENT 'Transaction ID from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ZipCodeAsString COMMENT 'Zip/postal code from PaymentData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BaseExchangeRate COMMENT 'Base conversion rate before exchange fee markup. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ExchangeFee COMMENT 'Exchange fee in basis points. Common: 0=no fee, 150=1.5%, 50=0.5%. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ProtocolMIDSettingsID COMMENT 'Merchant ID/protocol settings config. FK to Dim_BillingProtocolMIDSettingsID. (Tier 2 — Dim lookup)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FunnelID COMMENT 'Deposit funnel: 36=Default(93.8%), 9=Cashier, 43=GCC. FK to Dim_Funnel. (Tier 2 — Dim lookup)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AmountUSD COMMENT 'USD equivalent. ETL-computed: Amount * ExchangeRate. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN SessionID COMMENT 'Session ID for the deposit attempt. Always populated. Used to resolve PlatformID. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PlatformID COMMENT '[UNVERIFIED] Internal platform ID from Fact_CustomerAction (ActionTypeID=14). Values: 111, 105, 117 etc. Does NOT map to Dim_Platform. 40.6% NULL. (Tier 4 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN MOPCountry COMMENT 'Country of payment method. ETL-enriched from CountryIDAsString via Dim_Country. ~14.5% populated. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN SwiftCodeAsString COMMENT 'SWIFT/BIC code from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ClientBankNameAsString COMMENT 'Client bank name from FundingData XML. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BankName COMMENT 'Issuing bank name. ETL-enriched from Dim_CountryBin by BinCodeAsString. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CardCategory COMMENT 'Card tier (CLASSIC, STANDARD, PLATINUM, etc.). ETL-enriched from Dim_CountryBin. Note: STANDART typo exists. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PaymentGeneration COMMENT 'Payment system generation: NULL=pre-feature, 0=legacy, 1=new. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ProcessRegulationID COMMENT 'Regulatory entity: 1=CySEC, 2=FCA, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML. FK to Dim_Regulation. 63.7% NULL. (Tier 2 — Dim lookup)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN MerchantAccountID COMMENT 'Merchant account for processing. 49.4% NULL. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsSetBalanceCompleted COMMENT 'Balance update status: 1=completed, 0=not completed, NULL=pre-feature. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RoutingReasonID COMMENT 'Payment routing reason: 1=default, 3/5/6/7=various rules. 67.9% NULL. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsRecurring COMMENT 'Recurring deposit: 1=yes(0.9%), 0=no(55.6%), NULL=pre-feature. From etoro_Billing_RecurringDeposit. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FlowID COMMENT 'Deposit flow: 1=standard, 2/3=alternative. 95.7% NULL. (Tier 2 — live data)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsAftSupportedAsBool COMMENT 'AFT supported flag. Added 2025-03-02. ~14% populated. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsAftEligibleAsBool COMMENT 'AFT eligible flag. Added 2025-03-02. ~14% populated. (Tier 3 — SP code)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IsAftProcessedAsBool COMMENT 'AFT processed flag. Added 2025-03-02. ~14% populated. (Tier 3 — SP code)';

-- ---- UC-Only Partition Columns (not in Synapse) ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN etr_y COMMENT 'Year partition column (UC/Databricks-layer). Filter for partition pruning. (Tier 3 — UC metadata)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN etr_ym COMMENT 'Year-month partition column (UC/Databricks-layer). (Tier 3 — UC metadata)';

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN etr_ymd COMMENT 'Year-month-day partition column (UC/Databricks-layer). Most granular partition. (Tier 3 — UC metadata)';

-- ---- Column PII Tags ----
-- PII direct: names, emails, addresses, phone numbers, card data, bank accounts, IPs, tokens, etc.
-- CID is pseudonymous identifier → pii = 'none'.
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN SecuredCardDataAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CardNumberAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN EmailAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN FirstNameAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN LastNameAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CustomerNameAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CustomerAddressAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Address1AsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN Address2AsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IPAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IPAddress SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN IBANCodeAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BankAccountAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CardHolderPhoneNumberBodyAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CardHolderPhoneNumberPrefixAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN ZipCodeAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN CityAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AccountHolderAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN AccountNameAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RapidFirstNameAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN RapidLastNameAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN SecretKeyAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN TokenAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN MD5AsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN BICCodeAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN SwiftCodeAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PayerAsString SET TAGS ('pii' = 'direct');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit ALTER COLUMN PayerIDAsString SET TAGS ('pii' = 'direct');

-- Downstream propagation: see Fact_BillingDeposit.downstream.alter.sql
