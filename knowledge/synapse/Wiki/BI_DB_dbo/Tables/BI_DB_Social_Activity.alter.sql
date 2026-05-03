-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Social_Activity
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Social_Activity > 1.27B-row social activity fact table tracking every user interaction on the eToro social feed from 2014 to September 2025 - posts, comments, likes, and shares - with message content, word counts, and customer identity resolution via Dim_Customer. Populated daily by SP_Social_Activity from the Streams microservice external table. Last loaded ActionDateID=20250904; no data after that date suggests the feed may be dormant or migrated. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table (Fact) | | **Production Source** | Streams microservice via SP_Social_Activity | | **Refresh** | Daily (1440 min) - DELETE+INSERT by ActionDateID | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDEX (ActionDateID ASC, RealCID ASC, PostID ASC, CommentID ASC) | | **UC Target** | `main.bi_db.gold_sql_dp_pro'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN ActionTypeID COMMENT 'Social action classification. 1=Post, 2=Comment, 3=Like, 4=Share, 5=Automatic Post (BI_DB_Social_Activity_Type). Derived via CASE on Streams TypeName: Discussion -> 1, Comment -> 2, Like -> 3, Discussion+SharedEntryId -> 4, other entry types -> 5. (Tier 2 - Streams_dbo_Entries_Social_Activity_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN ActionDate COMMENT 'Timestamp when the social action occurred. Passthrough from Streams OccurredAt field (renamed). (Tier 2 - Streams_dbo_Entries_Social_Activity_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN PostID COMMENT 'Identifier of the root post. For original posts: the entry Id; for comments and likes: the RootId (top-level post); for shares: the SharedEntryId (the shared post). GUID-based string format. (Tier 2 - Streams_dbo_Entries_Social_Activity_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN CommentID COMMENT 'Identifier of the comment. NULL for posts, likes-on-posts, and shares. For comments: the entry Id. For likes-on-comments: the ParentId (the liked comment). (Tier 2 - Streams_dbo_Entries_Social_Activity_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN Username COMMENT 'Customer username on the social feed. Derived from Streams Username with leading character stripped via SUBSTRING([Username], 2, 50). Matches Dim_Customer.UserName in lowercase. (Tier 2 - Streams_dbo_Entries_Social_Activity_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN RealCID COMMENT 'Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer via Username JOIN. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN MessageText COMMENT 'Full text content of the social post or comment. Passthrough from Streams MessageBody (renamed). NULL for Likes (ActionTypeID=3) and Shares (ActionTypeID=4). (Tier 2 - Streams_dbo_Entries_Social_Activity_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN MessageSize COMMENT 'Character length of the message text. Computed as LEN(MessageBody). NULL for Likes and Shares. (Tier 2 - Streams_dbo_Entries_Social_Activity_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN MessageWordNum COMMENT 'Approximate word count of the message text. Computed as LEN(MessageBody) - LEN(REPLACE(MessageBody, '' '', '''')) + 1 (space-delimited count). NULL for Likes and Shares. (Tier 2 - Streams_dbo_Entries_Social_Activity_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN ActionDateID COMMENT 'Integer date key in YYYYMMDD format. Computed from SP @dt parameter as CAST(CONVERT(varchar, @dt, 112) AS INT). Used as the clustered index lead column and the daily DELETE partition key. (Tier 2 - SP_Social_Activity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. Set to GETDATE() at insert time. NULL for rows loaded before UpdateDate was added to the SP. (Tier 2 - SP_Social_Activity)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN ParentID COMMENT 'Parent entry identifier in the Streams entry tree. For root posts: equals PostID (self-referencing). For comments: the direct parent entry. For likes/shares: the entry being liked or shared. Passthrough from Streams ParentId (renamed). (Tier 2 - Streams_dbo_Entries_Social_Activity_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN SubTypeName COMMENT 'Original Streams entry type name. Values: Discussion, CloseTrade, CopyCloseTrade, OpenOrder, OpenTrade, StartCopyTrader, StopCopyTrader, Comment, Like. Passthrough from Streams TypeName (renamed). (Tier 2 - Streams_dbo_Entries_Social_Activity_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN MediaTypeID COMMENT 'Rich media attachment type. Passthrough from Streams RichMediaScrapDataType (renamed). Mostly NULL; observed values include 5 and 6. (Tier 2 - Streams_dbo_Entries_Social_Activity_Daily)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN ActionID COMMENT 'Auto-generated surrogate primary key. IDENTITY(1,1). Monotonically increasing across all inserts. Not related to ActionTypeID or BI_DB_Social_Activity_Type.ActionID. (Tier 2 - SP_Social_Activity)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN ActionTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN ActionDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN PostID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN CommentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN Username SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN MessageText SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN MessageSize SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN MessageWordNum SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN ActionDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN ParentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN SubTypeName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN MediaTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_social_activity ALTER COLUMN ActionID SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 13:13:23 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 32/32 succeeded
-- ====================
