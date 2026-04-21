-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_Card_Monthly_Snapshot
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot SET TBLPROPERTIES (
    'comment' = '`eMoney_Card_Monthly_Snapshot` is the monthly end-of-month customer panel for eToro Money debit card funnel tracking. **Grain**: one row per (SnapShotDate, CID) - one row per eligible customer per EOM month. As of 2026-03-31, the table holds 566,088,274 rows across 27 EOM snapshots (2024-01-31 to 2026-03-31), with the monthly eligible population growing from 17.1M customers in January 2024 to 24.9M in March 2026. **Who is included**: Every customer present in `DWH_dbo.Fact_SnapshotCustomer` at the EOM date with `IsValidCustomer=1` who resides in one of the 34 eTM rollout countries (filtered via `eMoney_dbo.eMoney_Dim_Country_Rollout`). This is the broad eligible universe - not just card holders. In March 2026, approximately 99.65% of rows have NULL `CardCreateDate`, meaning the overwhelming majority of rows represent eTM-eligible customers who do not have a debit card. **Card funnel signal hierarchy**: - `FMI_Date IS NOT NULL` -> customer has funded their eTM wallet (~0.29% of Mar 2026 rows) - `CardCreateDa...'
);

ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot SET TAGS (
    'domain' = 'finance',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(CID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapShotDateID` COMMENT 'YYYYMMDD integer representing the end-of-month date for this row (e.g., 20240131). Derived from the while-loop variable @StartDateDailyID. Used as the partition key in the DELETE+INSERT idempotency pattern. Filter on this column or SnapShotDate when querying a single month. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapShotDate` COMMENT 'Calendar end-of-month date for this row (e.g., 2024-01-31). Derived from the while-loop variable @StartDateDaily. Range: 2024-01-31 to 2026-03-31 (27 distinct values). Preferred filter column over SnapShotDateID for readability. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `CID` COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `GCID` COMMENT 'Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. DWH note: passthrough via Fact_SnapshotCustomer.GCID. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapshotCountryID` COMMENT 'Numeric country code at the EOM snapshot date. Sourced from DWH_dbo.Fact_SnapshotCustomer.CountryID - the point-in-time country recorded at that EOM. Decoded to text via SnapshotCountry. May differ from current CountryID for customers who have relocated. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapshotPlayerLevelID` COMMENT 'Club tier ID at the EOM snapshot date. Sourced from DWH_dbo.Fact_SnapshotCustomer.PlayerLevelID - the point-in-time club tier recorded at that EOM. Decoded to text via SnapshotClub. May differ from current club for customers who have changed tier since that EOM. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapshotClub` COMMENT 'Club tier name at the EOM snapshot date - JOIN decode of SnapshotPlayerLevelID via DWH_dbo.Dim_PlayerLevel.Name. Mar 2026 distribution: Bronze=97.5%, Silver=0.9%, Gold=0.8%, Platinum=0.4%, Platinum Plus=0.3%. Point-in-time; use for historical cohort analysis. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapshotCountry` COMMENT 'Country name at the EOM snapshot date - JOIN decode of SnapshotCountryID via DWH_dbo.Dim_Country.Name. Mar 2026 top 5: United Kingdom (4.9M), France (3.9M), Germany (3.6M), Italy (2.9M), Spain (1.7M). 34 distinct countries. Point-in-time; use for historical cohort analysis. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `AccountSubProgram` COMMENT 'eToro Money account sub-program classification. LEFT JOIN from eMoney_Dim_Account.AccountSubProgram on GCID_Unique_Count=1. NULL for customers not in the account dimension or with multiple eMoney accounts. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `FMI_Date` COMMENT 'Date of the customer''s first settled money-in transaction in eToro Money. Sourced from eMoney_Card_Instance_Summary.FMI_Date (originally derived in eMoney_Panel_FirstDates from eMoney_Dim_Transaction). NULL for customers who have never funded. (Tier 2 - eMoney_Card_Instance_Summary)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `CardCreateDate` COMMENT 'Date the customer''s most recently created card was issued (FiatCards.Created). MAX(eMoney_Card_Instance_Summary.CardCreateDate) per CID. NULL for the majority of rows (~99.65%) where the customer has not applied for a debit card. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `LastInstanceActivationDate` COMMENT 'Date the customer''s most recently activated card instance was activated. MAX(eMoney_Card_Instance_Summary.InstanceActivationDate) per CID. NULL for customers who have never activated a card. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `LastInstanceTxAfterActivationCount` COMMENT 'Count of settled card transactions on the customer''s most recently active card instance. MAX(eMoney_Card_Instance_Summary.TxAfterActivationCount) per CID. NULL for customers with no card data. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `FirstInstanceCreatedDate` COMMENT 'Date the customer''s first-ever card instance was issued. MIN(InstanceCreatedDate) via ROW_NUMBER() ASC from eMoney_Card_Instance_Summary. NULL for customers with no card status history recorded. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `FirstInstanceActivationDate` COMMENT 'Date the customer first activated any card instance. MIN(InstanceActivationDate) via ROW_NUMBER() from eMoney_Card_Instance_Summary. NULL for customers who have never activated a card. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `FirstTxAfterActivationCount` COMMENT 'Count of settled card transactions on the customer''s first (oldest) activated card instance. TxAfterActivationCount for the instance with ROW_NUMBER=1 ordered by InstanceCreatedDate ASC. NULL for customers with no card instances. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Tx1_AfterFirst` COMMENT 'Date of the customer''s 1st settled card transaction after first card activation (FirstInstanceActivationDate). Derived from eMoney_Dim_Transaction (TxTypeID IN [1,2,3,4], IsTxSettled=1). Not snapshot-bounded - same value across all EOM rows once the event occurs. NULL if no settled card transaction after first activation. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Tx2_AfterFirst` COMMENT 'Date of the customer''s 2nd settled card transaction after first card activation. NULL if fewer than 2 settled card transactions after first activation. Not snapshot-bounded. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Tx1_AfterLast` COMMENT 'Date of the customer''s 1st settled card transaction after most recent card activation (LastInstanceActivationDate). Not snapshot-bounded. NULL if no settled card transaction after last activation. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Tx2_AfterLast` COMMENT 'Date of the customer''s 2nd settled card transaction after most recent card activation. NULL if fewer than 2 settled card transactions after last activation. Not snapshot-bounded. (Tier 2 - eMoney_Dim_Transaction)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Country` COMMENT 'Customer''s CURRENT country name at SP execution time. Derived via DWH_dbo.Dim_Customer (current CountryID) JOIN DWH_dbo.Dim_Country.Name. Identical across all EOM snapshot rows for the same customer - does not change per snapshot. Use SnapshotCountry for historical attribution. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Club` COMMENT 'Customer''s CURRENT club tier name at SP execution time. Derived via DWH_dbo.Dim_Customer (current PlayerLevelID) JOIN DWH_dbo.Dim_PlayerLevel.Name. Identical across all EOM snapshot rows for the same customer - does not change per snapshot. Use SnapshotClub for historical attribution. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `UpdateDate` COMMENT 'Timestamp when this snapshot batch was written by the SP. Set to GETDATE() at INSERT time. All rows for the same SnapShotDateID from the same SP run share the same UpdateDate. Not a business event timestamp. (Tier 2 - SP_eMoney_Card_Monthly_Snapshot)';

-- ---- Column PII Tags ----
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapShotDateID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapShotDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `CID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapshotCountryID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapshotPlayerLevelID` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapshotClub` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `SnapshotCountry` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `AccountSubProgram` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `FMI_Date` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `CardCreateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `LastInstanceActivationDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `LastInstanceTxAfterActivationCount` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `FirstInstanceCreatedDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `FirstInstanceActivationDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `FirstTxAfterActivationCount` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Tx1_AfterFirst` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Tx2_AfterFirst` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Tx1_AfterLast` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Tx2_AfterLast` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Country` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `Club` SET TAGS ('pii' = 'none');
ALTER TABLE main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_monthly_snapshot ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
