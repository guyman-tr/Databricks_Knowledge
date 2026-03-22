-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Dim_PlayerStatus
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus SET TBLPROPERTIES (
    'comment' = 'Dim_PlayerStatus defines 16 distinct account restriction states in the eToro platform, each encoding a granular permission matrix controlling what a user can and cannot do. Unlike Dim_AccountStatus (binary open/closed), PlayerStatus provides fine-grained control over trading, deposits, withdrawals, social features, and copy-trading. This enables compliance and fraud teams to surgically restrict specific capabilities without full account lockout. The data originates from `etoro.Dictionary.PlayerStatus` on the etoroDB-REAL production SQL Server. The Generic Pipeline exports this table daily (Override) to the data lake, and `SP_Dictionaries_DL_To_Synapse` loads it via TRUNCATE + INSERT, plus a separate sentinel INSERT for ID=0 (N/A placeholder). The ETL adds 4 computed columns (DWHPlayerStatusID, StatusID, UpdateDate, InsertDate) and **drops 2 production columns** (`CanCopy` and `GetsInterest`). PlayerStatusID is stored in Dim_Customer and is read by virtually every user-facing operation -- login, trading, fu...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus SET TAGS (
    'domain' = 'customer',
    'object_type' = 'dimension',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'REPLICATE',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN PlayerStatusID COMMENT 'Primary key identifying the restriction state. 0=N/A (sentinel), 1=Normal, 2=Blocked, 3=Chat Blocked, 4=Blocked Upon Request, 5=Warning, 6=Under Investigation, 7=Scalpers Block, 8=PayPal Investigation, 9=Trade & MIMO Blocked, 10=Deposit Blocked, 11=Social Index, 12=Copy Block, 13=Pending Verification, 14=Failed Verification, 15=Block Deposit & Trading. FK from Dim_Customer. (Tier 1 - upstream wiki, Dictionary.PlayerStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN Name COMMENT 'Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. (Tier 1 - upstream wiki, Dictionary.PlayerStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN IsBlocked COMMENT 'Master block flag. 1 for statuses 2, 4, 6, 7, 8, 14 -- ALL capabilities disabled including login. 0 for statuses where individual CanX flags control granular permissions. Checked by login and order entry procedures. (Tier 1 - upstream wiki, Dictionary.PlayerStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanEditPosition COMMENT 'Whether the user can modify existing position parameters (SL/TP/trailing stop). False when IsBlocked=1 and for close-only statuses (9, 13, 15). (Tier 1 - upstream wiki, Dictionary.PlayerStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanOpenPosition COMMENT 'Whether the user can open new trading positions. False when IsBlocked=1 and for close-only statuses (9, 13, 15). True for all active/warning/partial statuses. (Tier 1 - upstream wiki, Dictionary.PlayerStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanClosePosition COMMENT 'Whether the user can close existing positions. True even for most restricted statuses -- regulators require users to be able to exit. Only IsBlocked=1 statuses set this to False. (Tier 1 - upstream wiki, Dictionary.PlayerStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanDeposit COMMENT 'Whether the user can add funds to their account. False for full-block statuses (IsBlocked=1), close-only statuses (9, 15), status 10 (Deposit Blocked), and status 11 (Social Index). (Tier 1 - upstream wiki, Dictionary.PlayerStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanRequestWithdraw COMMENT 'Whether the user can request withdrawals. False for full-block statuses (IsBlocked=1), close-only statuses (9, 13, 15), and status 11 (Social Index). (Tier 1 - upstream wiki, Dictionary.PlayerStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanLogin COMMENT 'Whether the user can authenticate and access the platform. False when IsBlocked=1. True for all partial-restriction statuses -- wind-down users can view their portfolio. (Tier 1 - upstream wiki, Dictionary.PlayerStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanChatAndPost COMMENT 'Whether the user can post to the social feed or chat. False when IsBlocked=1 and for status 3 (Chat Blocked). True for all other statuses including close-only. (Tier 1 - upstream wiki, Dictionary.PlayerStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanBeCopied COMMENT 'Whether other users can start copying this user''s trades. False when IsBlocked=1. Used to hide restricted users from the CopyTrader marketplace. Note: CanCopy (whether THIS user can copy others) is NOT loaded into DWH. (Tier 1 - upstream wiki, Dictionary.PlayerStatus)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN DWHPlayerStatusID COMMENT 'DWH surrogate key -- always equals PlayerLevelID (redundant copy). Set by ETL: SELECT [PlayerStatusID] AS [DWHPlayerStatusID]. 0 for the ID=0 sentinel. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN StatusID COMMENT 'Hardcoded to 1 (active) for all rows by the ETL. Not derived from production source. Standard DWH ETL convention for SP_Dictionaries_DL_To_Synapse-loaded tables. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp -- GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel. Does not reflect production data modification time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN InsertDate COMMENT 'ETL load timestamp -- GETDATE() for production rows; @ddate (midnight) for ID=0 sentinel. Does not reflect production insert time. (Tier 2 - SP_Dictionaries_DL_To_Synapse)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN Name SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN IsBlocked SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanEditPosition SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanOpenPosition SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanClosePosition SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanDeposit SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanRequestWithdraw SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanLogin SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanChatAndPost SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN CanBeCopied SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN DWHPlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ALTER COLUMN InsertDate SET TAGS ('pii' = 'none');
