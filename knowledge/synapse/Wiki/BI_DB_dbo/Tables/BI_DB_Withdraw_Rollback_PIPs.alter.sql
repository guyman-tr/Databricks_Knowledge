-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs > 149-row cashout rollback PIPs table recording withdrawal rollback and cancelled-rollback events with merchant ID attribution, customer snapshot attributes, and PIPs (payment processing) calculations. Populated daily by SP_Withdraw_Rollback_PIPs from Billing.CashoutRollbackTracking joined to Fact_BillingWithdraw and dimension tables. Data from 2024-01-05 to present. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | etoro.Billing.CashoutRollbackTracking via External_etoro_Billing_CashoutRollbackTracking + DWH_dbo.Fact_BillingWithdraw + DWH_dbo.Fact_CustomerAction (ActionTypeID=42) | | **Refresh** | Daily via SP_Withdraw_Rollback_PIPs @Date | | **Synapse Distribution** | HASH(CID) | | **Synapse Index** | CLUSTERED INDEX (Date ASC, CID ASC) | | **UC Target** | _Pending_ | | **UC '
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN DateID COMMENT 'Business date as YYYYMMDD for the SP run (@StartDateInt). (Tier 2 - SP_Withdraw_Rollback_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN CID COMMENT 'Customer ID (RealCID) from the cashout rollback tracking source. HASH distribution key. (Tier 3 - Billing.CashoutRollbackTracking, no upstream wiki)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN DepositWithdrawID COMMENT 'Withdrawal request ID (WithdrawID from rollback tracking). Identifies the original cashout request that was rolled back. (Tier 3 - Billing.CashoutRollbackTracking, no upstream wiki)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Occurred COMMENT 'Timestamp of the rollback status modification (ModificationDate from CashoutRollbackTracking). (Tier 3 - Billing.CashoutRollbackTracking, no upstream wiki)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN CreditTypeID COMMENT 'Hardcoded to 33 (cashout rollback credit type). Not sourced from production data in this SP. (Tier 2 - SP_Withdraw_Rollback_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN TransactionID COMMENT 'Synthetic identifier: CAST(WithdrawPaymentID AS VARCHAR(30)) + ''W''. Matches the TransactionID convention in BI_DB_DepositWithdrawFee for reconciliation. (Tier 2 - SP_Withdraw_Rollback_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Date COMMENT 'Calendar date of the rollback status modification. Derived: CAST(ModificationDate AS DATE). (Tier 2 - External_etoro_Billing_CashoutRollbackTracking)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Customer COMMENT 'APEX broker external ID. Decimal(38,0) to accommodate APEX very large numeric ID format. Passthrough from Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN TransactionType COMMENT 'Rollback event classification. CASE on CashoutStatusID: Reversed/Partially Reversed=''CashoutRollback'' (71%), Processed=''CancelledCashoutRollback'' (29%), else ''NA''. (Tier 2 - SP_Withdraw_Rollback_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN PaymentMethod COMMENT 'Payment method name. COALESCE of Dim_FundingType.Name via FundingTypeID_Funding (actual instrument), falling back to FundingTypeID_Withdraw (requested method). (Tier 2 - Fact_BillingWithdraw / Dim_FundingType)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Amount COMMENT 'Rollback amount in original currency (RollbackAmountInCurrency from CashoutRollbackTracking). May be negative. (Tier 3 - Billing.CashoutRollbackTracking, no upstream wiki)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Currency COMMENT 'Ticker symbol. "USD", "EUR", "AAPL.US". UNIQUE constraint in production. The primary identifier used in UIs and APIs. Passthrough from Dim_Currency via Fact_BillingWithdraw.ProcessCurrencyID. (Tier 1 - Dictionary.Currency)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN ExchangeRate COMMENT 'Exchange rate on the rollback event from CashoutRollbackTracking. (Tier 3 - Billing.CashoutRollbackTracking, no upstream wiki)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN AmountUSD COMMENT 'Rollback amount in USD (RollbackAmountInUSD from CashoutRollbackTracking). May be negative. (Tier 3 - Billing.CashoutRollbackTracking, no upstream wiki)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN RegulationID COMMENT 'Customer''s regulatory jurisdiction at the time of the event. Sourced from Fact_SnapshotCustomer via Dim_Range point-in-time lookup. (Tier 2 - Fact_SnapshotCustomer)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN LabelID COMMENT 'Internal segment label. FK to Dictionary.Label. LabelID=26 = BonusOnly customer (triggers IsHedged=0). Default=0. Passthrough from Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN PlayerLevelID COMMENT 'Customer player-level tier. FK to DWH_dbo.Dim_PlayerLevel. Per dictionary (verified 2026-05-13): 0=N/A, 1=Bronze, 2=Platinum, 3=Gold, 4=Internal (in-house / eToro-employee accounts), 5=Silver, 6=Platinum Plus, 7=Diamond. NOT a Popular Investor signal (PI is tracked by GuruStatusID). NOT a demo flag (demo is AccountTypeID=2). Default=0. (Tier 2 - DWH_dbo.Dim_PlayerLevel)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Regulation COMMENT 'Short code for the regulation. Values match production Dictionary.Regulation.Name. Dim-lookup passthrough via Fact_SnapshotCustomer.RegulationID. (Tier 1 - Dictionary.Regulation)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Label COMMENT 'Brand name displayed in BackOffice interfaces, reports, and internal systems. Dim-lookup passthrough via Dim_Label.LabelID. (Tier 1 - Dictionary.Label)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN IsValidCustomer COMMENT 'DWH-computed: 1 when PlayerLevelID!=4 AND LabelID NOT IN (30,26) AND CountryID!=250. Used in reporting to filter out non-standard customers. Passthrough from Dim_Customer. (Tier 2 - Dim_Customer)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN UpdateDate COMMENT 'Row load timestamp (GETDATE() at insert). (Tier 2 - SP_Withdraw_Rollback_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN BaseExchangeRate COMMENT 'Reference exchange rate before fee markup. Conditionally inverted (1/rate) for reciprocal forex pairs where USD is the buy-side currency; otherwise passthrough from Fact_BillingWithdraw. (Tier 2 - Fact_BillingWithdraw)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN ExchangeFee COMMENT 'Exchange fee in provider-specific integer units. Passthrough from Fact_BillingWithdraw. (Tier 1 - Billing.WithdrawToFunding)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN ExternalTransactionID COMMENT 'Provider reference number from the rollback tracking record (ReferenceNumber). (Tier 3 - Billing.CashoutRollbackTracking, no upstream wiki)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Depot COMMENT 'Human-readable depot name (e.g., ''MoneyBookers USD'', ''Neteller'', ''Wire''). Unique across all depots. Used in admin dashboards, routing logs, and discrepancy reports. Dim-lookup passthrough via Fact_BillingWithdraw.DepotID. (Tier 1 - Billing.Depot)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN MIDValue COMMENT 'Resolved Merchant ID string. Complex depot-specific cascade: credit card depots use BackOffice merchant details, wire uses BPMS Value, others fall back through WTF MerchantAccount, BPMS MerchantAccount, MapMerchantCodeToMid. (Tier 2 - SP_Withdraw_Rollback_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Club COMMENT 'Tier display name: Bronze, Silver, Gold, Platinum, Platinum Plus, Diamond, Internal, N/A. Used in BackOffice reporting JOINs and customer-facing UI. Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerLevelID. (Tier 1 - Dictionary.PlayerLevel)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN PlayerStatus COMMENT 'Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Dim-lookup passthrough via Fact_SnapshotCustomer.PlayerStatusID. (Tier 1 - Dictionary.PlayerStatus)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN PIPsCalculation COMMENT 'Rollback PIPs in USD. Computed as pro-rated share of original withdrawal PIPs (RollbackAmount/Amount * original PIPs), with fallback to legacy formula using BaseExchangeRate. Negated when RollbackAmount > 0. NULL when original PIPs record not found. (Tier 2 - Fact_BillingWithdraw / BI_DB_DepositWithdrawFee)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN RegCountry COMMENT 'Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country via Dim_Customer.CountryID. (Tier 1 - Dictionary.Country)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN RegCountryByIP COMMENT 'Full country name in English. Dim-lookup passthrough from Dim_Country via Dim_Customer.CountryIDByIP. (Tier 1 - Dictionary.Country)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN CardType COMMENT 'Card brand name. Unique constraint prevents duplicates in production. Used in payment UI, transaction records, and fraud reporting. Dim-lookup passthrough from Dim_CardType via Dim_CountryBin.CardTypeID from Fact_BillingWithdraw.BinCodeAsString. (Tier 1 - Dictionary.CardType)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN CardCategory COMMENT 'Not populated for rollbacks. Hardcoded ''NA''. (Tier 2 - SP_Withdraw_Rollback_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN BinCountry COMMENT 'Not populated for rollbacks. Hardcoded ''NA''. (Tier 2 - SP_Withdraw_Rollback_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN MOPCountry COMMENT 'Not populated for rollbacks. Hardcoded ''NA''. (Tier 2 - SP_Withdraw_Rollback_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN IsGermanBaFin COMMENT 'Not populated for rollbacks. Hardcoded NULL. (Tier 2 - SP_Withdraw_Rollback_PIPs)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Entity COMMENT 'Resolved MID entity/merchant name. Complex depot-specific cascade: credit card depots use BackOffice merchant BODescription, wire uses BPMS Description, others fall back through WTF MerchantAccount, BPMS MerchantAccount, DR2 regulation name. (Tier 2 - SP_Withdraw_Rollback_PIPs)';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN DepositWithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN CreditTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN TransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Customer SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN TransactionType SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN PaymentMethod SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN RegulationID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN LabelID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Label SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN BaseExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN ExchangeFee SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN ExternalTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Depot SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN MIDValue SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN PIPsCalculation SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN RegCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN RegCountryByIP SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN CardType SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN CardCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN BinCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN MOPCountry SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN IsGermanBaFin SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_withdraw_rollback_pips ALTER COLUMN Entity SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:15:49 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 76/76 succeeded
-- ====================
