-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.V_Fact_CustomerAction_for_generic
-- Generated: 2026-05-07 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic SET TBLPROPERTIES (
    'comment' = 'DWH_dbo.V_Fact_CustomerAction_for_generic > **8-date test/sample view** over `DWH_dbo.Fact_CustomerAction` - `SELECT * FROM Fact_CustomerAction WHERE DateID IN (20220819, 20220825, 20220826, 20220827, 20220901, 20220902, 20230120, 20230926)`. The "_for_generic" suffix indicates this view was built specifically as a fixed-data sample for **generic-pipeline testing** (small, deterministic, reproducible). Production analytics that need customer-action data should query the parent `Fact_CustomerAction` directly - not this view. | Property | Value | |----------|-------| | **Schema** | DWH_dbo | | **Object Type** | View - test/sample over Fact_CustomerAction | | **Production Source** | `DWH_dbo.Fact_CustomerAction` (the canonical fact) | | **Refresh** | None - static date-list filter; rows change only if Fact_CustomerAction is back-filled for those 8 dates | | **Date Coverage** | 8 hand-picked'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic SET TAGS (
    'source_schema' = 'DWH_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN HistoryID COMMENT 'Surrogate primary key - one row per customer-action event. Inherited from Fact_CustomerAction. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN GCID COMMENT 'Global Customer ID. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN RealCID COMMENT 'Real customer ID - joins to `Dim_Customer.RealCID`. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DemoCID COMMENT 'Demo (paper-trading) customer ID, when applicable. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN Occurred COMMENT 'Action timestamp. Date component matches DateID. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IPNumber COMMENT 'IP address of the action (numeric form). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsReal COMMENT 'Real (1) vs Demo (0) account flag. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN ActionTypeID COMMENT 'FK to `Dim_ActionType` - decodes to action label (Trade Open, Cashout, Login, Deposit, etc.). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PlatformTypeID COMMENT 'FK to `Dim_PlatformType` - Web, Mobile, OpenAPI, etc. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN InstrumentID COMMENT 'FK to `Dim_Instrument` - the asset traded, when ActionType is trade-related. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN Amount COMMENT 'Action amount in customer currency. Semantics depend on ActionType. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN Leverage COMMENT 'Position leverage (1, 2, 5, 10, ...). 1 for non-leveraged. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN NetProfit COMMENT 'Net profit/loss on the action. Used heavily by DDR rollup. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN Commission COMMENT 'Commission charged on the action (post-discount). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PositionID COMMENT 'FK to the position the action belongs to (when applicable). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CampaignID COMMENT 'Marketing campaign ID, when the action is attributed to a campaign. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN BonusTypeID COMMENT 'FK to `Dim_BonusType` - type of bonus credited (when ActionType is a bonus event). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN FundingTypeID COMMENT 'FK to `Dim_FundingType` - funding method (when ActionType is deposit-related). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN LoginID COMMENT 'Login session ID - one per session. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN MirrorID COMMENT 'Copy-trading mirror ID - populated for copy-related actions. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN WithdrawID COMMENT 'FK to the withdraw record, when ActionType = Cashout/Withdraw. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DurationInSeconds COMMENT 'Duration of the action in seconds (e.g. session length, position open duration). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PostID COMMENT 'FK to `eToro.Post` - for social actions (post, like, comment). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CaseID COMMENT 'Customer-support case identifier, when relevant. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DateID COMMENT 'Date encoded as YYYYMMDD - joins to `Dim_Date.DateKey`. **In this view, only 8 distinct values: 20220819, 20220825, 20220826, 20220827, 20220901, 20220902, 20230120, 20230926.** (Tier 2 + view filter)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN TimeID COMMENT 'Time-of-day encoded as integer (HHMMSS). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN StatusID COMMENT 'Action status (e.g. complete/pending/failed) - interpretation per ActionType. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PreviousOccurred COMMENT 'Timestamp of the previous action of the same kind for this customer (used for inter-action duration). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CompensationReasonID COMMENT 'FK to `Dim_CompensationReason` for compensation-typed actions. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN WithdrawPaymentID COMMENT 'FK to the withdraw payment record. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CommissionOnClose COMMENT 'Commission charged at position close (vs CommissionOnOpen). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsPlug COMMENT 'True for "plug" / corrective entries inserted by support to fix data issues. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DepositID COMMENT 'FK to the deposit record, for deposit-typed actions. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PostRootID COMMENT 'Root identifier for thread-level post grouping. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN FullCommission COMMENT 'Commission before any customer-specific discount. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN FullCommissionOnClose COMMENT 'FullCommission charged at close. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN RedeemID COMMENT 'FK to the redeem record, for redemption-typed actions. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN RedeemStatus COMMENT 'Status of the redemption. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN SessionID COMMENT 'Session identifier - narrower than LoginID in some pipelines. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsRedeem COMMENT 'Boolean flag (0/1) for "this action is a redemption". (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN RegulationIDOnOpen COMMENT 'Regulation ID at the time of position open (for regulation-aware reporting). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PlatformID COMMENT 'FK to platform (older field - see PlatformTypeID for the modern axis). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN ReopenForPositionID COMMENT 'If this action re-opens a previously closed position, FK to the original. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsReOpen COMMENT 'Boolean flag (0/1) - paired with ReopenForPositionID. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CommissionOnCloseOrig COMMENT 'CommissionOnClose in the customer''s original currency (pre-conversion). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN FullCommissionOnCloseOrig COMMENT 'FullCommissionOnClose in the customer''s original currency. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN OriginalPositionID COMMENT 'FK to the originating position when the action is derived (split, partial close, etc). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsPartialCloseParent COMMENT 'Boolean - this action is the parent of a partial-close split. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsPartialCloseChild COMMENT 'Boolean - this action is the child of a partial-close split. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN InitialUnits COMMENT 'Position size in units at action time. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PaymentStatusID COMMENT 'FK to `Dim_PaymentStatus` (when payment-typed action). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsDiscounted COMMENT 'Boolean - commission was discounted (FullCommission != Commission). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsSettled COMMENT 'Boolean - settlement complete on the underlying broker side. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CommissionByUnits COMMENT 'Per-unit commission rate applied. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN FullCommissionByUnits COMMENT 'Per-unit gross commission rate. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsFTD COMMENT 'Boolean - this action is the customer''s First-Time Deposit. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CountryIDByIP COMMENT 'Country derived from the IP at action time. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsAnonymousIP COMMENT 'Boolean - IP is anonymized/proxied. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN ProxyType COMMENT 'Proxy classification when the IP is proxied. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsFeeDividend COMMENT 'Boolean - action is a dividend-fee recognition. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsAirDrop COMMENT 'Boolean - action is a crypto airdrop. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DividendID COMMENT 'FK to dividend record (when IsFeeDividend or dividend-related). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN MoveMoneyReasonID COMMENT 'FK to `Dim_MoveMoneyReason` - categorical reason for an internal money move. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN SettlementTypeID COMMENT 'Settlement type classification. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DLTOpen COMMENT 'Distributed-Ledger-Technology (crypto wallet) flag at open. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DLTClose COMMENT 'Distributed-Ledger-Technology flag at close. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN OpenMarkupByUnits COMMENT 'Markup added to per-unit price at open (markup vs raw spread). (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN Description COMMENT 'Free-text description of the action - used sparingly for narrative annotation. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsBuy COMMENT 'Boolean - buy (1) vs sell (0) for trade-typed actions. (Tier 2)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CreditID COMMENT 'FK to a credit record, for credit-typed actions. (Tier 2)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN HistoryID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DemoCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IPNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsReal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN ActionTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PlatformTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN NetProfit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN Commission SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CampaignID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN BonusTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN FundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN LoginID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN MirrorID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN WithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DurationInSeconds SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PostID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CaseID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN TimeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PreviousOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CompensationReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN WithdrawPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CommissionOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsPlug SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PostRootID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN FullCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN FullCommissionOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN RedeemID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN RedeemStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN SessionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsRedeem SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN RegulationIDOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PlatformID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN ReopenForPositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsReOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CommissionOnCloseOrig SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN FullCommissionOnCloseOrig SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN OriginalPositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsPartialCloseParent SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsPartialCloseChild SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN InitialUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN PaymentStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsDiscounted SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CommissionByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN FullCommissionByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CountryIDByIP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsAnonymousIP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN ProxyType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsFeeDividend SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsAirDrop SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DividendID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN MoveMoneyReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN SettlementTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DLTOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN DLTClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN OpenMarkupByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN Description SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_v_fact_customeraction_for_generic ALTER COLUMN CreditID SET TAGS ('pii' = 'none');
