-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoneyClientBalance
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance
-- Resolved via: information_schema bulk query
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance SET TBLPROPERTIES (
    'comment' = ''
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BalanceDate` COMMENT 'Business date this row represents; equals @d input param (= yesterday relative to load). All rows for a given run share this date.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BalanceDateID` COMMENT 'Integer YYYYMMDD of BalanceDate; used as the DELETE key for idempotent daily reload.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` COMMENT 'Description';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `AccountId` COMMENT 'Tribe fiat account identifier. Distribution hash key. Each account has exactly one currency denomination (CurrencyIson).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `HolderId` COMMENT 'Tribe holder (customer) identifier. One holder may have multiple accounts (one per currency).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ProgramId` COMMENT 'Tribe program identifier. Maps to specific product configurations: 39=UK CARD GBP, 175=UK IBANO, 176=EU TEST IBANO, 177=EU IBANO, 178=UK FTD, 179=EU FTD, 180=UK GBP FOR UAE, 181=EU TEST BC, 182=EU Card, 183=Banking Circle AUD Account, 184=Banking Circle DKK Account, 185=Banking Circle DKK Test, 186=Banking Circle AUD Test.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Program` COMMENT 'Human-readable program label derived from ProgramId CASE expression. ''NA'' for any ProgramId not in the 13 hardcoded values.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `CurrencyIson` COMMENT 'ISO 4217 numeric currency code for this account (826=GBP, 978=EUR, 36=AUD, 208=DKK).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `AccountStatus` COMMENT 'Tribe account status shortcode: A=Active, S=Suspended, B=Blocked, P=Spend only, R=Receive only. Distribution (live): A=92.3%, S=6.5%, B=0.55%, P=0.53%, R=0.05%.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `AccountStatusDescription` COMMENT 'Full text description of AccountStatus: ''Active'', ''Suspended'', ''Blocked'', ''Spend only'', ''Receive only''.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Entity` COMMENT 'eToro legal entity derived from CurrencyIson via eMoney_EntityByCurrencyISO_MappingStatic: ''eToro Money UK'', ''eToro Money Malta'', ''eToro Money AUS''. ''New'' for 131 rows where CurrencyIson not in mapping table.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `HolderCurrency` COMMENT 'ISO alpha currency code for this account (GBP, EUR, AUD, DKK). NULL for ~966M pre-mapping rows (loaded before entity mapping was populated for all CurrencyIson values).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ReportingCurrency` COMMENT 'Entity reporting currency: GBP (UK), EUR (Malta, including DKK accounts), AUD (AUS). NULL for same ~966M pre-mapping rows.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` COMMENT 'Description';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `GCID` COMMENT 'eToro Global Customer ID. Resolved via eMoney_Dim_Account on ProviderCurrencyBalanceID (primary) or ProviderHolderID (fallback); GCID_Unique_Count=1 only. NULL for ~3.16M rows of unlinked Tribe accounts.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `CID` COMMENT 'eToro Customer ID paired with GCID.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `AccountSubProgram` COMMENT 'Sub-program label copied from eMoney_Dim_Account (e.g., ''IBAN EU Green'', ''IBAN EU Black'', ''Card Green EU''). NULL if GCID unresolved.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `IsExistingUser` COMMENT '1 if account resolved to an eToro DWH user (GCID IS NOT NULL); 0 otherwise. 99.7% of rows are 1. Post-load UPDATE backfills this for BalanceDateID >= 20250701 where initial resolution failed.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `IsTest` COMMENT '1 if this is a test account per eMoney_Dim_Account.IsTestAccount; 0 for confirmed production accounts; NULL for ~966M rows loaded before IsTest column addition (~Sep 2025).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `UpdateDate` COMMENT 'GETDATE() load timestamp.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `USDApproxRate` COMMENT 'Approximate USD conversion rate for this account''s holder currency, from DWH_dbo.Fact_CurrencyPriceWithSplit mid-price (Ask+Bid)/2, adjusted for quote direction (IsToUSD flag).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` COMMENT 'Description';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OpeningBalance` COMMENT 'Total account balance at business date open in holder currency. Cascades from prior day''s eMoneyClientBalance.ClosingBalanceBO (steady state) or ETL_AccountSnapshot.SettledBalance (first-fill fallback).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OpeningPositiveBalance` COMMENT 'Positive-only component of OpeningBalance; equals MAX(0, OpeningBalance). Used to track positive balance FX exposure separately from negative balances.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` COMMENT 'Description';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BankPayIns` COMMENT 'Sum of all inbound banking transfers: External Payment with positive HolderAmount (excl. TC=66) + TC=65 inbound return + TC=13/LoadSource=33 internal return.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BankPayOuts` COMMENT 'Sum of all outbound banking transfers: External Payment with negative HolderAmount (excl. TC=65) + TC=66 outbound return + TC=11/LoadSource=33.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Card_POS` COMMENT 'Sum of point-of-sale card transactions from ETL_SettlementsTransactions WHERE TransactionCode NOT IN (3,8).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Card_ATM` COMMENT 'Sum of ATM cash withdrawal transactions from ETL_SettlementsTransactions WHERE TransactionCode IN (3,8).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroDeposits` COMMENT 'Sum of eToro platform wallet loads: TC=1 (Load), LoadType=1 (eWallet), LoadSource IN (30=External client Wallet, 35=local currency debit, 25=eToro).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroCashouts` COMMENT 'Sum of eToro platform wallet unloads: TC=4 (Unload), LoadType=1 (eWallet), LoadSource IN (30,35,25).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroC2FDeposits` COMMENT 'Sum of crypto-to-fiat conversion loads: TC=1 (Load), LoadType=1 (eWallet), LoadSource=34 (Crypto).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BalanceAdjustments` COMMENT 'Sum of manual and API balance adjustments: TC IN (11=CREDIT_ADJUSTMENT, 13=DEBIT_ADJUSTMENT), LoadSource IN (31=GUI, 32=PM API).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ChargeBackAdjustments` COMMENT 'Sum of chargeback dispute credits: TC=79 (DISPUTE_CREDIT_ADJUSTMENT).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ATMFee` COMMENT 'Sum of ATM fee charges from ETL_SettlementsTransactions WHERE F0FeeName=''ATM fee''.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `FxFee` COMMENT 'Sum of FX conversion fees from ETL_SettlementsTransactions.FxFeeAmount.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OtherFee` COMMENT 'Sum of non-ATM settlement fees from ETL_SettlementsTransactions WHERE F0FeeName<>''ATM fee''.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` COMMENT 'Description';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceCalc` COMMENT 'DWH-computed closing balance: ROUND(OpeningBalance + BankPayIns + BankPayOuts + Card_POS + Card_ATM + EtoroDeposits + EtoroCashouts + EtoroC2FDeposits + BalanceAdjustments + ChargeBackAdjustments + ATMFee + FxFee + OtherFee, 2).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceBO` COMMENT 'Tribe back-office closing balance from ETL_AccountSnapshot.SettledBalance for DateID=@d_i (tomorrow''s file = today''s closing). Authoritative source of truth.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceGAP` COMMENT 'Reconciliation gap: ClosingBalanceCalc - ClosingBalanceBO. Near-zero expected. Systematic non-zero gaps trigger SP_eMoney_Client_Balance_Check_Exceptions_Gap alert.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OpeningBalanceGAP` COMMENT 'Opening balance gap: difference between prior day''s recorded closing balance and today''s opening balance from snapshot file. 0 if no prior eMoneyClientBalance row (first fill).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingNegativeBalanceBO` COMMENT 'Negative balance component of ClosingBalanceBO: CASE WHEN ClosingBalanceBO < 0 THEN ClosingBalanceBO ELSE 0 END.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `NegativeBalanceMovement` COMMENT 'Change in negative balance: OpeningNegativeBalance - ClosingNegativeBalanceBO. Used in positive balance closing calc to preserve correct total.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceBO` COMMENT 'Positive balance component of ClosingBalanceBO: CASE WHEN ClosingBalanceBO >= 0 THEN ClosingBalanceBO ELSE 0 END.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceCalc` COMMENT 'DWH-computed positive closing balance: ROUND(OpeningPositiveBalance + all 12 transaction components + NegativeBalanceMovement, 2).';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceGAP` COMMENT 'Positive balance reconciliation gap: ClosingPositiveBalanceCalc - ClosingPositiveBalanceBO.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `CheckCalc` COMMENT 'Internal consistency check: ClosingPositiveBalanceCalc + ClosingNegativeBalanceBO - ClosingBalanceBO. Should equal zero; non-zero indicates positive/negative decomposition error.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `TransOutOfDate` COMMENT 'Sum of HolderAmount from transactions where TransactionDateTime date != BalanceDate (late-arriving records from both settlements and activities). Tracks timing mismatch that contributes to ClosingBalanceGAP.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` COMMENT 'Description';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `CrossExchangeRate` COMMENT 'Holder-to-reporting-currency FX rate on business date (CrossExchangeRatePrev from prior day). 1 if HolderCurrency = ReportingCurrency. Source: BI_DB_dbo.External_Cmrdb_FxRate.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ExchangeRate` COMMENT 'Reporting-to-holder FX rate on business date (= PriceFromReportingCurrencyToHolderCurrencyBusnessDate). Inverse of CrossExchangeRate.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `PriceFX` COMMENT 'Day-over-day FX rate change: CrossExchangeRate2 - CrossExchangeRatePrev2. Used to compute FX gain/loss columns.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `FX` COMMENT 'FX gain/loss on total opening balance: OpeningBalance * PriceFX. Isolates currency revaluation from business activity.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `PositiveFX` COMMENT 'FX gain/loss on positive opening balance component: OpeningPositiveBalance * PriceFX.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `FXGAP` COMMENT 'FX reconciliation residual: ClosingBalanceBORepCur - OpeningBalanceRepCur - Delta (sum of all RepCur transaction flows) - FX. Near-zero expected; non-zero indicates rate sourcing inconsistency.';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` COMMENT 'Tier';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceBORepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OpeningBalanceRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OpeningPositiveBalanceRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BankPayInsRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BankPayOutsRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Card_POSRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Card_ATMRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroDepositsRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroCashoutsRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroC2FDepositsRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BalanceAdjustmentsRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ChargeBackAdjustmentsRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ATMFeeRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `FxFeeRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OtherFeeRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceCalcRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceGAPRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingNegativeBalanceBORepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `NegativeBalanceMovementRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceBORepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceCalcRepCur` COMMENT 'T2';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceGAPRepCur` COMMENT 'T2';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BalanceDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BalanceDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `AccountId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `HolderId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ProgramId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Program` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `CurrencyIson` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `AccountStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `AccountStatusDescription` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Entity` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `HolderCurrency` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ReportingCurrency` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `AccountSubProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `IsExistingUser` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `IsTest` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `USDApproxRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OpeningBalance` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OpeningPositiveBalance` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BankPayIns` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BankPayOuts` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Card_POS` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Card_ATM` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroDeposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroCashouts` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroC2FDeposits` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BalanceAdjustments` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ChargeBackAdjustments` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ATMFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `FxFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OtherFee` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceCalc` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceBO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceGAP` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OpeningBalanceGAP` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingNegativeBalanceBO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `NegativeBalanceMovement` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceBO` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceCalc` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceGAP` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `CheckCalc` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `TransOutOfDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `CrossExchangeRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ExchangeRate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `PriceFX` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `FX` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `PositiveFX` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `FXGAP` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Column` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceBORepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OpeningBalanceRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OpeningPositiveBalanceRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BankPayInsRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BankPayOutsRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Card_POSRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `Card_ATMRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroDepositsRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroCashoutsRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `EtoroC2FDepositsRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `BalanceAdjustmentsRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ChargeBackAdjustmentsRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ATMFeeRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `FxFeeRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `OtherFeeRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceCalcRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingBalanceGAPRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingNegativeBalanceBORepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `NegativeBalanceMovementRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceBORepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceCalcRepCur` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance ALTER COLUMN `ClosingPositiveBalanceGAPRepCur` SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 06:26:42 UTC
-- Batch deploy resume: eMoney_dbo deploy batch 1
-- Statements: 146/160 succeeded
-- Error: [COLUMN_NOT_FOUND_IN_TABLE] Column 'Column' not found in table 'main'.'bi_db'.'gold_sql_dp_prod_we_emoney_dbo_emoneyclientbalance''. SQLSTATE: 42703
-- ====================
