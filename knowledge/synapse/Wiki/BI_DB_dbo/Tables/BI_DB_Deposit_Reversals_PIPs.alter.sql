-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Deposit_Reversals_PIPs
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Deposit_Reversals_PIPs > 7,979-row deposit reversal PIPs table tracking chargebacks, refunds, reversed deposits, and their cancellations from 2023-03-01 to 2025-09-10. Populated daily by SP_Deposit_Reversals_PIPs via DELETE+INSERT, sourcing from Fact_BillingDeposit, Fact_CustomerAction (status history), Fact_SnapshotCustomer, and external rollback/credit tables. Computes reversal-specific PIPs by applying rollback amount ratios to base deposit PIPs from BI_DB_DepositWithdrawFee. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | SP_Deposit_Reversals_PIPs (Author: Guy Manova, 2024-02-16) - temporary solution replicating BO PIPs logic in Synapse | | **Refresh** | Daily (DELETE by DateID + INSERT) | | **Synapse Distribution** | HASH(CID) | | **Synapse Index** | CLUSTERED INDEX (Date ASC, CID ASC) | | **U'
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN DateID COMMENT 'Business date as YYYYMMDD integer, derived from @date parameter via CAST(CONVERT(VARCHAR(8), @date, 112) AS INT). (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN CID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Hash distribution key. Passthrough from Fact_BillingDeposit / Fact_SnapshotCustomer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN DepositWithdrawID COMMENT 'Source deposit ID from Fact_BillingDeposit.DepositID, renamed for schema compatibility with BI_DB_DepositWithdrawFee. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Occurred COMMENT 'Reversal event timestamp. CASE: rollback CreateDate when available, else credit.Occurred from External_etoro_history_credit_yesterday. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN CreditTypeID COMMENT 'Credit type from External_etoro_history_credit_yesterday. Reversal types: 11=Chargeback, 12=Refund, 16=ChargebackReversal, 32=ReverseDeposit. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN TransactionID COMMENT 'Synthetic identifier: CAST(DepositID AS VARCHAR(20)) + ''D''. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Date COMMENT 'Calendar date from @date parameter. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Customer COMMENT 'APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer.ExternalID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN TransactionType COMMENT 'Reversal category derived from (current, previous) deposit status matrix. 10 values: Refund, Chargeback, ChargebackReversal, CancelledRefund, NA, CancelledChargeback, ReversedDeposit, CancelledReversedDeposit, CancelledChargebackReversal, RefundReversal. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN PaymentMethod COMMENT 'Payment method name resolved via FundingID -> External_eToro_Billing_FundingPaymentDetailsForWithdraw -> Dim_FundingType.Name. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Amount COMMENT 'Rollback amount in original currency from External_etoro_Billing_DepositRollbackTracking.RollbackAmountInCurrency. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Currency COMMENT 'Ticker symbol. "USD", "EUR" for forex; "AAPL.US", "TSLA.US" for US stocks (format: TICKER.EXCHANGE); "BTC" for crypto. Unique across all instruments. Use this for human-readable instrument identification. Passthrough from Dim_Currency.Abbreviation via CurrencyID. (Tier 1 - Dictionary.Currency)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN ExchangeRate COMMENT 'Exchange rate from deposit currency to USD at processing time. Cannot be 0 in production. Passthrough from Fact_BillingDeposit.ExchangeRate. (Tier 1 - Billing.Deposit)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN AmountUSD COMMENT 'USD amount: COALESCE(RollbackAmountInUSD, ReturnedAmount) from rollback tracking / credit history. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN RegulationID COMMENT 'Customer''s regulatory jurisdiction from Fact_SnapshotCustomer at event date. 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, etc. FK to Dim_Regulation. (Tier 1 - Dictionary.Regulation)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN LabelID COMMENT 'Brand/label from Fact_SnapshotCustomer. FK to Dim_Label. Labels 26 and 30 excluded from valid customer segment. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN PlayerLevelID COMMENT 'Primary key identifying the loyalty tier. 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (excluded), 5=Silver, 6=Platinum Plus, 7=Diamond. 0=N/A (DWH ETL placeholder). IDs are NOT in rank order -- use Sort for ordering. FK from Dim_Customer. Excludes Internal in customer-facing queries: WHERE PlayerLevelID <> 4. Passthrough from Fact_SnapshotCustomer. (Tier 1 - Dictionary.PlayerLevel)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Regulation COMMENT 'Regulation short code resolved via Dim_Regulation.Name. (Tier 1 - Dictionary.Regulation)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Label COMMENT '**NOTE: maps to Dim_PlayerLevel.Name, NOT Dim_Label.Name** - SP quirk. Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. (Tier 1 - Dictionary.PlayerLevel)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN IsValidCustomer COMMENT '1 if customer is a valid retail customer for analytics (excludes demo, blocked countries, excluded labels). From Fact_SnapshotCustomer. (Tier 2 - SP_Fact_SnapshotCustomer)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp set to GETDATE() at SP execution. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN BaseExchangeRate COMMENT 'Reference exchange rate before fee markup. Fee spread = ExchangeRate - BaseExchangeRate. Passthrough from Fact_BillingDeposit. (Tier 1 - Billing.Deposit)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN ExchangeFee COMMENT 'Exchange fee from rollback tracking (named ConversionFee in the SP). (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN ExternalTransactionID COMMENT 'COALESCE(ReferenceNumber from rollback tracking, RefundVerificationCode from Fact_BillingDeposit). Provider-side reconciliation identifier. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Depot COMMENT 'Acquirer/gateway name resolved via Dim_BillingDepot.Name on DepotID. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN MIDValue COMMENT 'Merchant ID value. Complex CASE: FundingTypeID=2 -> BPMSValue; DepotID IN (78,79,80,4,75,86) -> merchant account Name; ELSE COALESCE chain from Dim_BillingProtocolMIDSettingsID and merchant routing. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Club COMMENT 'Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Passthrough from Dim_PlayerLevel.Name. (Tier 1 - Dictionary.PlayerLevel)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN PlayerStatus COMMENT 'Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. Passthrough from Dim_PlayerStatus.Name. (Tier 1 - Dictionary.PlayerStatus)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN PIPsCalculation COMMENT 'Reversal PIPs in USD: ROUND(base_deposit_PIPs, 2) × ROUND(RollbackAmountInCurrency / Amount, 32). Base PIPs from BI_DB_DepositWithdrawFee matched on DepositID. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN RegCountry COMMENT 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID. (Tier 1 - Dictionary.Country)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN RegCountryByIP COMMENT 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name via Dim_Customer.CountryIDByIP. (Tier 1 - Dictionary.Country)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN CardType COMMENT 'Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Renamed from `Name` in production. 0=None, 1=Visa, 2=Master Card, 3=Diners, 4=Amex, 5=Fire Pay, 6=JCB, 7=American Express, 8=Maestro, 9=Laser, 10=Switch, 11=UK Local Credit Card, 12=Discover, 13=Local Card, 14=China Union Pay, 15=Solo, 16=Cirrus, 17=GE Capital. Passthrough from Dim_CardType.CarTypeName. (Tier 1 - Dictionary.CardType)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN CardCategory COMMENT 'Card category label from Fact_BillingDeposit.CardCategory. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN BinCountry COMMENT 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country.Name via Fact_BillingDeposit.BinCountryIDAsInteger. (Tier 1 - Dictionary.Country)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN MOPCountry COMMENT 'Hardcoded literal ''NA'' - not populated in the current SP. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN IsGermanBaFin COMMENT 'Hardcoded NULL - not populated in the current SP. (Tier 2 - SP_Deposit_Reversals_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Entity COMMENT 'Merchant entity description. Complex CASE: FundingTypeID=2 -> BPMSDescription; DepotID IN (78,79,80,4,75,86) -> merchant BODescription; ELSE COALESCE chain. (Tier 2 - SP_Deposit_Reversals_PIPs)';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN DepositWithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN CreditTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN TransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Customer SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN TransactionType SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN PaymentMethod SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN LabelID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Label SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN BaseExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN ExchangeFee SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN ExternalTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Depot SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN MIDValue SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN PIPsCalculation SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN RegCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN RegCountryByIP SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN CardType SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN CardCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN BinCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN MOPCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN IsGermanBaFin SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_deposit_reversals_pips ALTER COLUMN Entity SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:46:52 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 76/76 succeeded
-- ====================
