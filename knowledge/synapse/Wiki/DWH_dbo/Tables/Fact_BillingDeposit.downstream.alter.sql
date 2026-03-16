-- =============================================================================
-- Databricks Deep Lineage Column Comment Propagation: DWH_dbo.Fact_BillingDeposit
-- Generated: 2026-03-16 | dwh-semantic-doc pipeline (deep lineage)
--
-- Source (UC): main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit
-- Source (Synapse): DWH_dbo.Fact_BillingDeposit
--
-- Target tables (21):
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals  (TABLE, 9 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport  (TABLE, 1 cols)
--   main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints  (TABLE, 1 cols)
--   main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee  (TABLE, 9 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard  (TABLE, 9 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits  (TABLE, 91 cols)
--   main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips  (TABLE, 8 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions  (TABLE, 2 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms  (TABLE, 4 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts  (TABLE, 1 cols)
--   main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips  (TABLE, 8 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints  (TABLE, 1 cols)
--   main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca  (TABLE, 1 cols)
--   main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification  (TABLE, 1 cols)
-- Target views (1):
--   main.bi_output.vg_fact_billingdeposit_for_genie  (VIEW, 135 cols)
-- =============================================================================

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals (TABLE, 9 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `Amount` COMMENT 'Deposit amount in deposit currency. Capped at +/-99,999,999 in ETL (fix 2025-04-17). (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `ExchangeRate` COMMENT 'Conversion rate from deposit currency to USD. Used to compute AmountUSD. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `AmountUSD` COMMENT 'USD equivalent. ETL-computed: Amount * ExchangeRate. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `BaseExchangeRate` COMMENT 'Base conversion rate before exchange fee markup. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `ExchangeFee` COMMENT 'Exchange fee in basis points. Common: 0=no fee, 150=1.5%, 50=0.5%. (Tier 2 — live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `CardCategory` COMMENT 'Card tier (CLASSIC, STANDARD, PLATINUM, etc.). ETL-enriched from Dim_CountryBin. Note: STANDART typo exists. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `MOPCountry` COMMENT 'Country of payment method. ETL-enriched from CountryIDAsString via Dim_Country. ~14.5% populated. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals ALTER COLUMN `DepositID` COMMENT 'Unique deposit transaction ID. Distribution key + clustered index. Effectively the PK. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_newbonusreport ALTER COLUMN `ManagerID` COMMENT 'Manager/account manager ID. 98.9% populated. (Tier 2 — live data)';

-- main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints (TABLE, 1 columns)
ALTER TABLE main.finance.gold_sql_dp_prod_we_bi_db_dbo_bi_db_finance_audit_auxillary_datapoints ALTER COLUMN `Amount` COMMENT 'Deposit amount in deposit currency. Capped at +/-99,999,999 in ETL (fix 2025-04-17). (Tier 3 — SP code)';

-- main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata (TABLE, 1 columns)
ALTER TABLE main.dwh.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_monthlypanel_fulldata ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis ALTER COLUMN `IsFTD` COMMENT 'First Time Deposit flag: 1=first deposit for this CID, 0=subsequent. 8% are FTD. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee (TABLE, 9 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `Amount` COMMENT 'Deposit amount in deposit currency. Capped at +/-99,999,999 in ETL (fix 2025-04-17). (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `ExchangeRate` COMMENT 'Conversion rate from deposit currency to USD. Used to compute AmountUSD. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `AmountUSD` COMMENT 'USD equivalent. ETL-computed: Amount * ExchangeRate. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `BaseExchangeRate` COMMENT 'Base conversion rate before exchange fee markup. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `ExchangeFee` COMMENT 'Exchange fee in basis points. Common: 0=no fee, 150=1.5%, 50=0.5%. (Tier 2 — live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `CardCategory` COMMENT 'Card tier (CLASSIC, STANDARD, PLATINUM, etc.). ETL-enriched from Dim_CountryBin. Note: STANDART typo exists. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `MOPCountry` COMMENT 'Country of payment method. ETL-enriched from CountryIDAsString via Dim_Country. ~14.5% populated. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee ALTER COLUMN `DepositID` COMMENT 'Unique deposit transaction ID. Distribution key + clustered index. Effectively the PK. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_fulldata ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard (TABLE, 9 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `DepositID` COMMENT 'Unique deposit transaction ID. Distribution key + clustered index. Effectively the PK. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `AmountUSD` COMMENT 'USD equivalent. ETL-computed: Amount * ExchangeRate. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `PaymentDate` COMMENT 'When the payment was initiated by the customer. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `ModificationDate` COMMENT 'Timestamp of last modification. Primary date column for filtering. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `PaymentStatusID` COMMENT 'Payment lifecycle: 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE. FK to Dim_PaymentStatus. Key filter: =2 for approved. (Tier 2 — Dim lookup)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `IsFTD` COMMENT 'First Time Deposit flag: 1=first deposit for this CID, 0=subsequent. 8% are FTD. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `ProcessorValueDate` COMMENT 'Payment processor settlement date. ~29% populated. (Tier 2 — live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_money_in_new_management_dashboard ALTER COLUMN `ModificationDateID` COMMENT 'Date key YYYYMMDD from ModificationDate. FK to Dim_Date. ETL-computed. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits (TABLE, 91 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `DepositID` COMMENT 'Unique deposit transaction ID. Distribution key + clustered index. Effectively the PK. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `FundingType` COMMENT 'Funding type name from FundingData XML. String version of FundingTypeID. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `ModificationDate` COMMENT 'Timestamp of last modification. Primary date column for filtering. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `IsFTD` COMMENT 'First Time Deposit flag: 1=first deposit for this CID, 0=subsequent. 8% are FTD. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `ModificationDateID` COMMENT 'Date key YYYYMMDD from ModificationDate. FK to Dim_Date. ETL-computed. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `FundingID` COMMENT 'Funding instrument ID. FK to staging etoro_Billing_Funding. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `AccountBalanceAsDecimal` COMMENT 'Account balance from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `AccountHolderAsString` COMMENT 'Account holder name from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `AccountIDAsDecimal` COMMENT 'Account ID from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `ACHBankAccountIDAsInteger` COMMENT 'ACH bank account ID from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `Address1AsString` COMMENT 'Address line 1 from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `Address2AsString` COMMENT 'Address line 2 from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `AdviseAsString` COMMENT '[UNVERIFIED] Payment advisory message from PaymentData XML. (Tier 4 — column name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `AvailableBalanceAsDecimal` COMMENT 'Available balance from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BankCodeAsString` COMMENT 'Bank code (string) from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BankIDAsInteger` COMMENT 'Bank ID from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BillNumberAsString` COMMENT 'Bill/invoice number from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BuildingNumberAsString` COMMENT 'Building number (address) from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CardHolderPhoneNumberBodyAsString` COMMENT 'Card holder phone number (body) from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CardHolderPhoneNumberPrefixAsString` COMMENT 'Card holder phone prefix from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CardNumberAsString` COMMENT 'Card number (masked/partial) from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CityAsString` COMMENT 'City from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CountryIDAsString` COMMENT 'Country identifier (string) from PaymentData XML. Used to derive MOPCountry via Dim_Country. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CountryNameAsString` COMMENT 'Country name from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CreatedAtAsString` COMMENT 'Creation timestamp from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CurrentBalanceAsDecimal` COMMENT 'Current balance from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CustomerIDAsString` COMMENT 'Customer ID from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `EmailAsString` COMMENT 'Customer email from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `EndPointIDAsString` COMMENT 'Payment endpoint ID from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `ErrorCodeAsString` COMMENT 'Error code from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `ErrorTypeAsString` COMMENT 'Error type from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `FirstNameAsString` COMMENT 'Customer first name from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `IBANCodeAsString` COMMENT 'IBAN from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `InitialTransactionIDAsString` COMMENT 'Initial/original transaction ID from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `IPAsString` COMMENT 'IP address (string) from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `LanguageIDAsInteger` COMMENT 'Language ID from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `LastNameAsString` COMMENT 'Customer last name from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `MD5AsString` COMMENT '[UNVERIFIED] MD5 hash from PaymentData XML. Purpose unclear. (Tier 4 — column name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PayerAsString` COMMENT 'Payer name from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PayerBusiness` COMMENT 'Payer business name from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PayerIDAsString` COMMENT 'Payer ID from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PayerPurseAsString` COMMENT 'Payer e-wallet purse from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PayerStatus` COMMENT 'Payer status from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PaymentAmountAsDecimal` COMMENT 'Payment amount from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PaymentDateAsDateTime` COMMENT 'Payment date from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PaymentGuaranteeAsString` COMMENT '[UNVERIFIED] Payment guarantee indicator from PaymentData XML. (Tier 4 — column name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PaymentModeAsInteger` COMMENT '[UNVERIFIED] Payment mode ID from PaymentData XML. (Tier 4 — column name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PaymentProviderTransactionStatusAsString` COMMENT 'Transaction status from payment provider, from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PaymentStatusAsInteger` COMMENT 'Payment status (integer) from PaymentData XML. Provider''s own status code. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PaymentTypeAsString` COMMENT 'Payment type from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PlaidItemIDAsString` COMMENT 'Plaid item ID from PaymentData XML. Used for ACH/Plaid integrations. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PlaidNamesAsString` COMMENT 'Plaid account holder names from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PlatformIDAsInteger` COMMENT 'Platform ID (string) from PaymentData XML. Different from PlatformID column. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PromotionCodeAsString` COMMENT 'Promotion/coupon code from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PSPCodeAsString` COMMENT 'Payment Service Provider code from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `RapidFirstNameAsString` COMMENT 'RapidTransfer first name from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `RapidLastNameAsString` COMMENT 'RapidTransfer last name from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `ResponseMessageAsString` COMMENT 'Provider response message from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `ResponseTimeAsString` COMMENT 'Provider response time from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `SecretKeyAsString` COMMENT '[UNVERIFIED] Secret key from PaymentData XML. Potential security concern. (Tier 4 — column name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `ThreeDsAsJson` COMMENT '3D Secure response data as JSON from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `ThreeDsResponseType` COMMENT '3D Secure response type from PaymentData XML. Values include ''1''. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `TokenAsString` COMMENT 'Payment token from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `TransactionIDAsString` COMMENT 'Transaction ID from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `ZipCodeAsString` COMMENT 'Zip/postal code from PaymentData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `AccountTypeAsString` COMMENT 'Account type from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BankAccountAsString` COMMENT 'Bank account number from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BankAddressAsString` COMMENT 'Bank address from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BankCodeAsDecimal` COMMENT 'Bank code (numeric) from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BankDetailsAccountIDAsString` COMMENT 'Bank details account ID from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BankIDAsString` COMMENT 'Bank ID (string) from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BankNameAsString` COMMENT 'Bank name from FundingData XML. Raw provider value (vs BankName which is enriched from Dim_CountryBin). (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BICCodeAsString` COMMENT 'BIC/SWIFT code from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BinCodeAsString` COMMENT 'Card BIN code (first 6-8 digits) from FundingData XML. Used to JOIN Dim_CountryBin for BankName + CardCategory. (Tier 5 — domain expert)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BinCountryIDAsInteger` COMMENT 'Country ID from BIN lookup, from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CardTypeIDAsInteger` COMMENT 'Card network: 1=Visa, 2=MasterCard, 3=Diners. From FundingData XML. FK to Dim_CardType. (Tier 2 — Dim lookup)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CIDAsString` COMMENT '[UNVERIFIED] Customer ID as string from FundingData XML. May differ from CID column. (Tier 4 — column name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `ClientBankNameAsString` COMMENT 'Client bank name from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CountryIDAsInteger` COMMENT 'Country ID from payment provider response, from FundingData XML. FK to Dim_Country. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CustomerAddressAsString` COMMENT 'Customer address from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `CustomerNameAsString` COMMENT 'Customer name from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `MaskedAccountIDAsString` COMMENT 'Masked payment account ID from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `PurseAsString` COMMENT 'E-wallet purse identifier from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `RoutingNumberAsString` COMMENT 'Bank routing number from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `SecuredCardDataAsString` COMMENT '[UNVERIFIED] Encrypted/hashed card data from FundingData XML. (Tier 4 — column name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `SecureIDAsDecimal` COMMENT 'Secure ID from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `SortCodeAsString` COMMENT 'Bank sort code from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `SwiftCodeAsString` COMMENT 'SWIFT/BIC code from FundingData XML. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `BaseExchangeRate` COMMENT 'Base conversion rate before exchange fee markup. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_v_bi_db_alldeposits ALTER COLUMN `DepotID` COMMENT 'Payment processor/depot: 87=CyberSource, 92=Checkout.com, 12=PayPal, 88=eToroMoney. FK to Dim_BillingDepot. (Tier 2 — Dim lookup)';

-- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips (TABLE, 8 columns)
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN `Amount` COMMENT 'Deposit amount in deposit currency. Capped at +/-99,999,999 in ETL (fix 2025-04-17). (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN `ExchangeRate` COMMENT 'Conversion rate from deposit currency to USD. Used to compute AmountUSD. (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN `AmountUSD` COMMENT 'USD equivalent. ETL-computed: Amount * ExchangeRate. (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN `BaseExchangeRate` COMMENT 'Base conversion rate before exchange fee markup. (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN `ExchangeFee` COMMENT 'Exchange fee in basis points. Common: 0=no fee, 150=1.5%, 50=0.5%. (Tier 2 — live data)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN `CardCategory` COMMENT 'Card tier (CLASSIC, STANDARD, PLATINUM, etc.). ETL-enriched from Dim_CountryBin. Note: STANDART typo exists. (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN `MOPCountry` COMMENT 'Country of payment method. ETL-enriched from CountryIDAsString via Dim_Country. ~14.5% populated. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions (TABLE, 2 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `Amount` COMMENT 'Deposit amount in deposit currency. Capped at +/-99,999,999 in ETL (fix 2025-04-17). (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions ALTER COLUMN `IsRecurring` COMMENT 'Recurring deposit: 1=yes(0.9%), 0=no(55.6%), NULL=pre-feature. From etoro_Billing_RecurringDeposit. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ltv_bi_actual ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms (TABLE, 4 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN `AmountUSD` COMMENT 'USD equivalent. ETL-computed: Amount * ExchangeRate. (Tier 3 — SP code)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN `FundingTypeID` COMMENT 'Payment method: 1=CreditCard, 2=WireTransfer, 3=PayPal, 8=Skrill, 28=OnlineBanking, 29=ACH, 33=eToroMoney, 34=iDEAL, 35=Trustly. FK to Dim_FundingType. (Tier 2 — Dim lookup)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN `CurrencyID` COMMENT 'Deposit currency: 1=USD, 2=EUR, 3=GBP, 5=AUD, 6=CHF + 28 others. FK to Dim_Currency. (Tier 2 — Dim lookup)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms ALTER COLUMN `IsRecurring` COMMENT 'Recurring deposit: 1=yes(0.9%), 0=no(55.6%), NULL=pre-feature. From etoro_Billing_RecurringDeposit. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_compliance_illegal_trades_alerts ALTER COLUMN `AmountUSD` COMMENT 'USD equivalent. ETL-computed: Amount * ExchangeRate. (Tier 3 — SP code)';

-- main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips (TABLE, 8 columns)
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN `Amount` COMMENT 'Deposit amount in deposit currency. Capped at +/-99,999,999 in ETL (fix 2025-04-17). (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN `ExchangeRate` COMMENT 'Conversion rate from deposit currency to USD. Used to compute AmountUSD. (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN `AmountUSD` COMMENT 'USD equivalent. ETL-computed: Amount * ExchangeRate. (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN `BaseExchangeRate` COMMENT 'Base conversion rate before exchange fee markup. (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN `ExchangeFee` COMMENT 'Exchange fee in basis points. Common: 0=no fee, 150=1.5%, 50=0.5%. (Tier 2 — live data)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN `CardCategory` COMMENT 'Card tier (CLASSIC, STANDARD, PLATINUM, etc.). ETL-enriched from Dim_CountryBin. Note: STANDART typo exists. (Tier 3 — SP code)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN `MOPCountry` COMMENT 'Country of payment method. ETL-enriched from CountryIDAsString via Dim_Country. ~14.5% populated. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositusersfirsttouchpoints ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';

-- main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates (TABLE, 1 columns)
ALTER TABLE main.pii_data.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cid_dailypanel_club ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_sar_report_fca ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';

-- main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification (TABLE, 1 columns)
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_aml_singapore_risk_classification ALTER COLUMN `CID` COMMENT 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';

-- main.bi_output.vg_fact_billingdeposit_for_genie (VIEW, 135 columns)
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CID` IS 'Customer ID (FK to Dim_Customer.RealCID). The customer who initiated the deposit. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CurrencyID` IS 'Deposit currency: 1=USD, 2=EUR, 3=GBP, 5=AUD, 6=CHF + 28 others. FK to Dim_Currency. (Tier 2 — Dim lookup)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`Commission` IS 'Commission charged on the deposit, in deposit currency. Typically 0. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`Approved` IS '[DEPRECATED] Legacy approval flag. 99.99% NULL. Use PaymentStatusID instead. (Tier 3 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ModificationDate` IS 'Timestamp of last modification. Primary date column for filtering. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ModificationDateID` IS 'Date key YYYYMMDD from ModificationDate. FK to Dim_Date. ETL-computed. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`FundingID` IS 'Funding instrument ID. FK to staging etoro_Billing_Funding. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ExchangeRate` IS 'Conversion rate from deposit currency to USD. Used to compute AmountUSD. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`DepositID` IS 'Unique deposit transaction ID. Distribution key + clustered index. Effectively the PK. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ProcessorValueDate` IS 'Payment processor settlement date. ~29% populated. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`DepotID` IS 'Payment processor/depot: 87=CyberSource, 92=Checkout.com, 12=PayPal, 88=eToroMoney. FK to Dim_BillingDepot. (Tier 2 — Dim lookup)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`SecuredCardDataAsString` IS '[UNVERIFIED] Encrypted/hashed card data from FundingData XML. (Tier 4 — column name)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BinCodeAsString` IS 'Card BIN code (first 6-8 digits) from FundingData XML. Used to JOIN Dim_CountryBin for BankName + CardCategory. (Tier 5 — domain expert)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BinCountryIDAsInteger` IS 'Country ID from BIN lookup, from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CardTypeIDAsInteger` IS 'Card network: 1=Visa, 2=MasterCard, 3=Diners. From FundingData XML. FK to Dim_CardType. (Tier 2 — Dim lookup)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PaymentStatusID` IS 'Payment lifecycle: 1=New, 2=Approved, 3=Decline, 4=Technical, 5=InProcess, 6=Canceled, 11=Chargeback, 12=Refund, 13=Pending, 35=DeclineByRRE. FK to Dim_PaymentStatus. Key filter: =2 for approved. (Tier 2 — Dim lookup)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ManagerID` IS 'Manager/account manager ID. 98.9% populated. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`RiskManagementStatusID` IS 'Risk check result: 1=Success, 2-69=various decline reasons. FK to Dim_RiskManagementStatus. 95.2% NULL. (Tier 2 — Dim lookup)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`Amount` IS 'Deposit amount in deposit currency. Capped at +/-99,999,999 in ETL (fix 2025-04-17). (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PaymentDate` IS 'When the payment was initiated by the customer. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`IPAddress` IS 'Customer''s IP address stored as numeric. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ClearingHouseEffectiveDate` IS 'Clearing house settlement date. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`IsFTD` IS 'First Time Deposit flag: 1=first deposit for this CID, 0=subsequent. 8% are FTD. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`RefundVerificationCode` IS '[UNVERIFIED] Verification code for refund processing. (Tier 4 — column name)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`MatchStatusID` IS 'Electronic verification: 0=None(97.4%), 2=Verified, 3=NotVerified. FK to Dim_EvMatchStatus. (Tier 2 — Dim lookup)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BonusStatusID` IS 'Bonus status: NULL=61.4%, 0=none(38.3%), 1=active, 2=expired. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BonusAmount` IS 'Bonus amount credited. 99.98% NULL. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BonusErrorCode` IS 'Error code from bonus processing. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ExTransactionID` IS 'External transaction ID from payment provider. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`FundingTypeID` IS 'Payment method: 1=CreditCard, 2=WireTransfer, 3=PayPal, 8=Skrill, 28=OnlineBanking, 29=ACH, 33=eToroMoney, 34=iDEAL, 35=Trustly. FK to Dim_FundingType. (Tier 2 — Dim lookup)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`IsRefundExcluded` IS '1=excluded from refund eligibility (1.3%), 0=eligible. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`DocumentRequired` IS '1=document required for deposit (56.7%), 0=not required. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ExpirationDateID` IS 'Card expiration YYYYMM. 190001=missing/invalid. ETL-computed from ExpirationDateAsString. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CountryIDAsInteger` IS 'Country ID from payment provider response, from FundingData XML. FK to Dim_Country. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`StateIDAsInteger` IS 'State/province ID from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BankIDAsInteger` IS 'Bank ID from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`AccountNameAsString` IS 'Account holder name from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`AccountTypeAsString` IS 'Account type from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BankAccountAsString` IS 'Bank account number from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BankAddressAsString` IS 'Bank address from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BankCodeAsDecimal` IS 'Bank code (numeric) from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BankDetailsAccountIDAsString` IS 'Bank details account ID from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BankIDAsString` IS 'Bank ID (string) from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BankNameAsString` IS 'Bank name from FundingData XML. Raw provider value (vs BankName which is enriched from Dim_CountryBin). (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BICCodeAsString` IS 'BIC/SWIFT code from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CIDAsString` IS '[UNVERIFIED] Customer ID as string from FundingData XML. May differ from CID column. (Tier 4 — column name)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`v` IS 'ClientBankNameAsString (TRUNCATED ALIAS BUG). Client bank name from FundingData XML. ETL code: ExtractXMLValue(''ClientBankNameAsString'', FundingData) aliased as ''v''. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CustomerAddressAsString` IS 'Customer address from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CustomerNameAsString` IS 'Customer name from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`FundingType` IS 'Funding type name from FundingData XML. String version of FundingTypeID. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`MaskedAccountIDAsString` IS 'Masked payment account ID from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PurseAsString` IS 'E-wallet purse identifier from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`RoutingNumberAsString` IS 'Bank routing number from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`SecureIDAsDecimal` IS 'Secure ID from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`SortCodeAsString` IS 'Bank sort code from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`AccountBalanceAsDecimal` IS 'Account balance from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`AccountHolderAsString` IS 'Account holder name from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`AccountIDAsDecimal` IS 'Account ID from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ACHBankAccountIDAsInteger` IS 'ACH bank account ID from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`Address1AsString` IS 'Address line 1 from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`Address2AsString` IS 'Address line 2 from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`AdviseAsString` IS '[UNVERIFIED] Payment advisory message from PaymentData XML. (Tier 4 — column name)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`AvailableBalanceAsDecimal` IS 'Available balance from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BankCodeAsString` IS 'Bank code (string) from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BillNumberAsString` IS 'Bill/invoice number from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BuildingNumberAsString` IS 'Building number (address) from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CardHolderPhoneNumberBodyAsString` IS 'Card holder phone number (body) from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CardHolderPhoneNumberPrefixAsString` IS 'Card holder phone prefix from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CardNumberAsString` IS 'Card number (masked/partial) from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CityAsString` IS 'City from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CountryIDAsString` IS 'Country identifier (string) from PaymentData XML. Used to derive MOPCountry via Dim_Country. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CountryNameAsString` IS 'Country name from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CreatedAtAsString` IS 'Creation timestamp from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CurrentBalanceAsDecimal` IS 'Current balance from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CustomerIDAsString` IS 'Customer ID from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`EmailAsString` IS 'Customer email from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`EndPointIDAsString` IS 'Payment endpoint ID from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ErrorCodeAsString` IS 'Error code from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ErrorTypeAsString` IS 'Error type from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`FirstNameAsString` IS 'Customer first name from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`IBANCodeAsString` IS 'IBAN from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`InitialTransactionIDAsString` IS 'Initial/original transaction ID from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`IPAsString` IS 'IP address (string) from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`LanguageIDAsInteger` IS 'Language ID from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`LastNameAsString` IS 'Customer last name from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`MD5AsString` IS '[UNVERIFIED] MD5 hash from PaymentData XML. Purpose unclear. (Tier 4 — column name)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PayerAsString` IS 'Payer name from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PayerBusiness` IS 'Payer business name from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PayerIDAsString` IS 'Payer ID from PaymentData/FundingData XML (COALESCE). (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PayerPurseAsString` IS 'Payer e-wallet purse from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PayerStatus` IS 'Payer status from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PaymentAmountAsDecimal` IS 'Payment amount from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PaymentDateAsDateTime` IS 'Payment date from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PaymentGuaranteeAsString` IS '[UNVERIFIED] Payment guarantee indicator from PaymentData XML. (Tier 4 — column name)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PaymentModeAsInteger` IS '[UNVERIFIED] Payment mode ID from PaymentData XML. (Tier 4 — column name)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PaymentProviderTransactionStatusAsString` IS 'Transaction status from payment provider, from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PaymentStatusAsInteger` IS 'Payment status (integer) from PaymentData XML. Provider''s own status code. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PaymentTypeAsString` IS 'Payment type from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PlaidItemIDAsString` IS 'Plaid item ID from PaymentData XML. Used for ACH/Plaid integrations. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PlaidNamesAsString` IS 'Plaid account holder names from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PlatformIDAsInteger` IS 'Platform ID (string) from PaymentData XML. Different from PlatformID column. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PromotionCodeAsString` IS 'Promotion/coupon code from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PSPCodeAsString` IS 'Payment Service Provider code from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`RapidFirstNameAsString` IS 'RapidTransfer first name from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`RapidLastNameAsString` IS 'RapidTransfer last name from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ResponseMessageAsString` IS 'Provider response message from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ResponseTimeAsString` IS 'Provider response time from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`SecretKeyAsString` IS '[UNVERIFIED] Secret key from PaymentData XML. Potential security concern. (Tier 4 — column name)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ThreeDsAsJson` IS '3D Secure response data as JSON from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ThreeDsResponseType` IS '3D Secure response type from PaymentData XML. Values include ''1''. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`TokenAsString` IS 'Payment token from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`TransactionIDAsString` IS 'Transaction ID from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ZipCodeAsString` IS 'Zip/postal code from PaymentData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BaseExchangeRate` IS 'Base conversion rate before exchange fee markup. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ExchangeFee` IS 'Exchange fee in basis points. Common: 0=no fee, 150=1.5%, 50=0.5%. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ProtocolMIDSettingsID` IS 'Merchant ID/protocol settings config. FK to Dim_BillingProtocolMIDSettingsID. (Tier 2 — Dim lookup)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`FunnelID` IS 'Deposit funnel: 36=Default(93.8%), 9=Cashier, 43=GCC. FK to Dim_Funnel. (Tier 2 — Dim lookup)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`AmountUSD` IS 'USD equivalent. ETL-computed: Amount * ExchangeRate. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`SessionID` IS 'Session ID for the deposit attempt. Always populated. Used to resolve PlatformID. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PlatformID` IS '[UNVERIFIED] Internal platform ID from Fact_CustomerAction (ActionTypeID=14). Values: 111, 105, 117 etc. Does NOT map to Dim_Platform. 40.6% NULL. (Tier 4 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`MOPCountry` IS 'Country of payment method. ETL-enriched from CountryIDAsString via Dim_Country. ~14.5% populated. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`SwiftCodeAsString` IS 'SWIFT/BIC code from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ClientBankNameAsString` IS 'Client bank name from FundingData XML. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`BankName` IS 'Issuing bank name. ETL-enriched from Dim_CountryBin by BinCodeAsString. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`CardCategory` IS 'Card tier (CLASSIC, STANDARD, PLATINUM, etc.). ETL-enriched from Dim_CountryBin. Note: STANDART typo exists. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`PaymentGeneration` IS 'Payment system generation: NULL=pre-feature, 0=legacy, 1=new. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`ProcessRegulationID` IS 'Regulatory entity: 1=CySEC, 2=FCA, 8=FinCEN+FINRA, 9=FSA Seychelles, 10=ASIC&GAML. FK to Dim_Regulation. 63.7% NULL. (Tier 2 — Dim lookup)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`MerchantAccountID` IS 'Merchant account for processing. 49.4% NULL. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`IsSetBalanceCompleted` IS 'Balance update status: 1=completed, 0=not completed, NULL=pre-feature. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`RoutingReasonID` IS 'Payment routing reason: 1=default, 3/5/6/7=various rules. 67.9% NULL. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`IsRecurring` IS 'Recurring deposit: 1=yes(0.9%), 0=no(55.6%), NULL=pre-feature. From etoro_Billing_RecurringDeposit. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`FlowID` IS 'Deposit flow: 1=standard, 2/3=alternative. 95.7% NULL. (Tier 2 — live data)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`IsAftSupportedAsBool` IS 'AFT supported flag. Added 2025-03-02. ~14% populated. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`IsAftEligibleAsBool` IS 'AFT eligible flag. Added 2025-03-02. ~14% populated. (Tier 3 — SP code)';
COMMENT ON COLUMN main.bi_output.vg_fact_billingdeposit_for_genie.`IsAftProcessedAsBool` IS 'AFT processed flag. Added 2025-03-02. ~14% populated. (Tier 3 — SP code)';
