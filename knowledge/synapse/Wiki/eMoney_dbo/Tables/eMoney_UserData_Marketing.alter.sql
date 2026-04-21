-- =============================================================================
-- Databricks ALTER Script: eMoney_dbo.eMoney_UserData_Marketing
-- Generated: 2026-04-21 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing
-- Resolved via: information_schema bulk query
-- Classification: Non-standard
-- =============================================================================

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing SET TBLPROPERTIES (
    'comment' = '`eMoney_UserData_Marketing` is a **customer-grain daily snapshot** designed for the marketing automation team. Each row represents **one eligible eToro Money customer** with their current product state and key engagement signals. The table answers: "For each eTM customer right now - what product are they on, have they used their card or IBAN, and have they transacted recently?" This makes it the primary table for email/campaign targeting logic that segments customers by engagement level. Population: 2,010,838 customers. Excludes: - GCID=0 (cancelled accounts) - IsTestAccount=1 (test/internal accounts) - CurrencyBalanceStatusID=4 (Blocked balances) - Secondary accounts (only GCID_Unique_Count=1 - primary account per customer) `Date_Inserted` is the eTM account creation date (from `eMoney_Dim_Account.AccountCreateDate`) - NOT the date the row was inserted into this table. All rows are replaced on each TRUNCATE+INSERT cycle. **Program distribution**: IBAN 95.4%, Card 4.6%. The dominant product is IBAN Standar...'
);

ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing SET TAGS (
    'domain' = 'general',
    'object_type' = 'table',
    'source_schema' = 'eMoney_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(RealCID)',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `GCID` COMMENT 'Global Customer ID. Identifies the customer across all eToro platforms (trading, crypto, fiat). Part of the unique constraint with AccountGuid. Used in Confluence queries as the primary customer lookup key. (Tier 1 - dbo.FiatAccount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `RealCID` COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Renamed from RealCID in DWH_dbo.Dim_Customer. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `Date_Inserted` COMMENT 'eTM account creation date (eMoney_Dim_Account.AccountCreateDate). Despite the name, this is NOT when the row was inserted into this table - the table is fully replaced on each TRUNCATE+INSERT. Ranges from 2020-11-09 (first eTM accounts) to 2026-04-12. (Tier 2 - SP_eMoney_UserData_Marketing via eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `Program` COMMENT 'Account program display name for AccountProgramID, resolved from eMoney_Dictionary_AccountProgram. Values: ''iban'' (95.4%), ''card'' (4.6%). (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `CardId` COMMENT 'Auto-incrementing surrogate primary key. Referenced by FiatCardStatuses.CardId, FiatCardInstances (implicit), and CardsProvidersMapping.CardId. NULL if the customer has no card. (Tier 1 - dbo.FiatCards)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `CardUsage` COMMENT '1 if the customer has any eTM card transaction (TxTypeID IN 1,2,3,4,9 in eMoney_Dim_Transaction); 0 otherwise. Lifetime flag, not recency-bounded. (Tier 2 - SP_eMoney_UserData_Marketing via eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `IBANUsage` COMMENT '1 if the customer has any IBAN/bank transfer transaction (TxTypeID IN 5,6,7,8,13 in eMoney_Dim_Transaction); 0 otherwise. Lifetime flag. (Tier 2 - SP_eMoney_UserData_Marketing via eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `LastCardStatus` COMMENT 'Current card status. ''NotOrdered'' if CardCreateDate IS NULL (no card issued); otherwise reflects eMoney_Dim_Account.CardStatus. Values: NotOrdered, NotActivated, Activated, Expired, Blocked, Stolen, Lost, Risk, Suspended (9 values). Note: ''NotOrdered'' is an SP-injected sentinel absent from eMoney_Dictionary_CardStatus. (Tier 2 - SP_eMoney_UserData_Marketing via eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `IBANUsed` COMMENT '**DUPLICATE of IBANUsage** - CASE WHEN IBANUsage=1 THEN 1 ELSE 0 END, always identical to IBANUsage. Use IBANUsage instead. (Tier 2 - SP_eMoney_UserData_Marketing)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `HasTransactionsLast3Months` COMMENT '1 if the customer has any eTM transaction with TxLocalDateID in the past 90 days (from SP run date); 0 otherwise. The only recency-bounded flag in this table. (Tier 2 - SP_eMoney_UserData_Marketing via eMoney_Dim_Transaction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `CardCreatedDate` COMMENT 'Date portion of CardCreateTime. DWH-derived: CAST(CardCreateTime AS DATE). NULL if no card issued. (Tier 2 - SP_eMoney_Dim_Account)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `UpdateDate` COMMENT 'ETL run timestamp (GETDATE() at time of SP execution). All rows share the same UpdateDate (TRUNCATE+INSERT makes all rows simultaneous). Used for idempotency check: if MAX(UpdateDate) >= today, SP skips. (Tier 2 - SP_eMoney_UserData_Marketing)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `SubProgram` COMMENT 'Sub-program display name for AccountSubProgramID, resolved from eMoney_dbo.SubPrograms (16 active programs across UK/EU/AUS regions). Values (15 distinct): IBAN EU Green (64%), IBAN Standard UK (28%), Card Standard UK (3%), IBAN Green AUS (2%), IBAN EU Black (1%), Card Black EU, Card Premium UK, Card Green EU, IBAN Black AUS, IBAN LIMITED EU, IBAN Green DKK, Card Premium UAE, IBAN Black DKK, IBAN LIMITED UK, NULL. (Tier 2 - SP_eMoney_Dim_Account)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `GCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `RealCID` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `Date_Inserted` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `Program` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `CardId` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `CardUsage` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `IBANUsage` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `LastCardStatus` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `IBANUsed` SET TAGS ('pii' = 'direct');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `HasTransactionsLast3Months` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `CardCreatedDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `UpdateDate` SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_userdata_marketing ALTER COLUMN `SubProgram` SET TAGS ('pii' = 'none');
