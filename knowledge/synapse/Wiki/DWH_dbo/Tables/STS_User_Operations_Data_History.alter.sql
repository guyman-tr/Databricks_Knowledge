-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.STS_User_Operations_Data_History
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.STS_User_Operations_Data_History > Historical log of every STS (Security Token Service) authentication and session event - logins, logouts, token exchanges, and re-authentications - capturing client device, IP, application, and session identifiers for each customer interaction. | Property | Value | |----------|-------| | **Schema** | DWH_dbo | | **Object Type** | Table (Fact-like History) | | **Row Count** | Billions (daily partitioned, data from 2021-08 onward) | | **Production Source** | `STS_Audit.StsAudit.UserOperations` (via `DWH_staging.STS_Audit_UserOperationsData`) | | **Refresh** | Daily append (midnight ETL via partition SWITCH) | | | | | **Synapse Distribution** | HASH(Gcid) | | **Synapse Index** | CLUSTERED INDEX (DateID ASC) | | **Synapse Partitioning** | RANGE LEFT on DateID - per-day partitions from 2022-01-01 through 2026-02-28 | | | | | **UC Target** | `dwh.gold_'
);

-- ---- Table Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history SET TAGS (
    'source_schema' = 'DWH_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN Gcid COMMENT 'Global Customer ID - unique cross-platform identifier linking Real and Demo accounts for the same person. Distribution key. (Tier 2 - SP_Fact_CustomerAction_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN RealCid COMMENT 'Real-money account Customer ID. NULL when the session is Demo-only. (Tier 2 - SP_Fact_CustomerAction_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN DemoCid COMMENT 'Virtual/demo account Customer ID. NULL when the session is Real-only. (Tier 2 - SP_Fact_CustomerAction_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ApplicationIdentifier COMMENT 'Client application that initiated the session. Known values: `retoro` (web/generic), `retoroios` (iOS app), `retoroandroid` (Android app). (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ApplicationVersion COMMENT 'Build version of the client application, e.g. `340.0.10`, `355.0.1`. (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ClientIp COMMENT 'IPv4 address of the client at the time of the session event. (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ClientName COMMENT 'Server-side service name that processed the authentication request. Consistently `STS.WebAPI` across all observed data. (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN CreatedAt COMMENT 'Timestamp when the authentication/session event occurred in the STS service. This is the business event time (not the ETL load time). (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN UserAgent COMMENT 'Full HTTP User-Agent string from the client browser or mobile WebView. Contains OS, browser, and app metadata. May be NULL for some mobile token exchanges. (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN AccessTokenHashed COMMENT 'Hashed authentication access token for security audit trail. Not reversible. Sparsely populated. (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ClientDeviceId COMMENT 'UUID-format device identifier (e.g. `3c24d4e9-8ef0-405f-...`). Populated primarily for mobile app sessions; typically NULL or empty for web. (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ParentSessionId COMMENT 'Session ID of the parent session for linked/chained sessions. Value `0` indicates a root session (no parent). Enables session chain tracing. (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN AccountTypeName COMMENT 'Account context for the session: `Real` (live trading) or `Demo` (virtual portfolio). (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN LoginTypeName COMMENT 'Type of authentication event. Known values: `Login` (new session), `Authenticate` (credential re-validation), `TokenExchange` (token refresh), `Logout` (session end). (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN SessionId COMMENT 'Unique session identifier assigned by the STS service. Monotonically increasing. (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN GatewayAppId COMMENT 'Identifier of the API gateway application that routed the request. Commonly `1` or `2`. NULL for some Logout events. (Tier 2 - STS_Audit_UserOperationsData)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN DateID COMMENT 'Date partition key in YYYYMMDD integer format (e.g. `20210901`). Computed in ETL from the `@Yesterday` parameter: `CONVERT(INT, CONVERT(VARCHAR, DATEADD(DAY, DATEDIFF(DAY, 0, @Yesterday), 0), 112))`. Clustered index and partition column. (Tier 2 - SP_Fact_CustomerAction_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN UpdateDate COMMENT 'Timestamp when this row was loaded into the DWH, set to `GETDATE()` during ETL execution. Not the business event time. (Tier 2 - SP_Fact_CustomerAction_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ProxyType COMMENT 'Type of proxy detected for the client IP connection (e.g. VPN, TOR). Sparsely populated - NULL in most observed rows. Added after initial table creation. (Tier 3 - data sampling inference)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN CountryISOCode COMMENT 'ISO country code resolved from the ClientIp address. Sparsely populated - NULL in most observed rows. Added after initial table creation. (Tier 3 - data sampling inference)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN AdditionalData COMMENT 'Extensible JSON or free-text field for additional session metadata. Sparsely populated. (Tier 3 - data sampling inference)';

-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN Gcid SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN RealCid SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN DemoCid SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ApplicationIdentifier SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ApplicationVersion SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ClientIp SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ClientName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN CreatedAt SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN UserAgent SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN AccessTokenHashed SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ClientDeviceId SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ParentSessionId SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN AccountTypeName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN LoginTypeName SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN SessionId SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN GatewayAppId SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN ProxyType SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN CountryISOCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_sts_user_operations_data_history ALTER COLUMN AdditionalData SET TAGS ('pii' = 'none');
