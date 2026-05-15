-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_CIDFirstDates_metric_view
-- Generated: 2026-05-14 15:33:13 UTC
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view
-- =============================================================================

-- ---- Table Comment ----

-- ---- Table Tags ----

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN CustomerID COMMENT 'Platform customer surrogate aligned with `BI_DB_CIDFirstDates.CID`: "Customer ID - platform-internal primary key... Mapped from Dim_Customer.RealCID." **UC rename:** `CustomerID`. (Tier 1 - Customer.CustomerStatic via BI_DB_CIDFirstDates)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN UserName COMMENT 'Customer eToro login / display identifier; PII. Existing UC metadata states "From Dim_Customer.UserName" path. Ground with Dim_Customer join described in CIDFirstDates pipeline. (Tier 2 - SP_CIDFirstDates, Dim_Customer)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN ClubName COMMENT 'eToro Club tier display label equivalent to base column `Club` ("Tier display name: Bronze...") in `BI_DB_CIDFirstDates`; **presentation rename** `ClubName`. (Tier 1 - Dictionary.PlayerLevel via BI_DB_CIDFirstDates.Club)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN `registered date` COMMENT 'Customer registration timestamp column `registered` on `BI_DB_CIDFirstDates` exposed with spaced identifier in UC METRIC_VIEW. (Tier 2 - Dim_Customer / SP_CIDFirstDates)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN `Total Credit` COMMENT 'Metric alias of `Credit`: nightly `ISNULL(V_Liabilities.Credit, 0)` snapshot per section 2.6. (Databricks stores as METRIC datatype; DDL-style `decimal(29,4)` for Elements parsing.) (Tier 1 - Fact_SnapshotEquity via V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN `Total Realized Equity` COMMENT 'Metric alias of `RealizedEquity`: nightly `ISNULL(V_Liabilities.RealizedEquity, 0)` snapshot per section 2.6. (Tier 1 - Fact_SnapshotEquity via V_Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN `Last Deposit Amount` COMMENT 'Mirrors `BI_DB_CIDFirstDates.LastDepositAmount`: "Most recent deposit amount in USD (Amount * ExchangeRate)." (Tier 2 - Fact_BillingDeposit via SP_CIDFirstDates)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN CustomerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN ClubName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN `registered date` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN `Total Credit` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN `Total Realized Equity` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_metric_view ALTER COLUMN `Last Deposit Amount` SET TAGS ('pii' = 'none');

