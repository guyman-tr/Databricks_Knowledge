-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_CustomerAction
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Fact_CustomerAction` is the unified customer event log for the eToro platform. Every significant action a customer performs - opening a position, closing a position, depositing money, withdrawing, logging in, publishing a social post, receiving a fee, getting a bonus, registering an account - is captured as a single row in this table. It answers: "What did this customer do, when, and what were the financial details?" The table consolidates events from five distinct production sources into a single ActionTypeID-driven schema: 1. **Position opens** (ActionTypeID 1-3, 39): From `Trade.OpenPositionEndOfDay` via the Generic Pipeline + staging 2. **Position closes** (ActionTypeID 4-6, 28, 40): From `History.ClosePositionEndOfDay` via the Generic Pipeline + staging 3. **Credit/financial events** (ActionTypeID 7-13, 15-20, 27, 30, 32, 34-38, 42-45): From `History.Credit` (which unions `History.ActiveCredit` + archived Credit partition tables back to 2007) 4. **Logins** (ActionTypeID 14): From `STS_Audit_U...'
);

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction SET TAGS (
    'domain' = 'customer',
    'object_type' = 'fact',
    'source_schema' = 'DWH_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'HASH(RealCID)',
    'synapse_index' = 'CLUSTERED COLUMNSTORE + 4 nonclustered',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN HistoryID COMMENT 'Intended as a unique key but contains duplicates - NOT reliable as a primary/unique identifier. Do not use for JOINs, deduplication, or row identification. Has no practical use for analysts. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN GCID COMMENT 'Global Customer ID - the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DemoCID COMMENT 'Demo-account Customer ID. Always 0 in this table (real accounts only). (Tier 3 - ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Occurred COMMENT 'UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 - source-dependent)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IPNumber COMMENT 'IP address of the customer as a numeric value. Populated for logins and registrations. (Tier 1 - STS/Billing.Login)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsReal COMMENT 'Account type flag. Always 1 in this table (real accounts only). (Tier 3 - ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ActionTypeID COMMENT 'Event type classifier. References `DWH_dbo.Dim_ActionType.ActionTypeID` - JOIN for Name, Category, CategoryID. See Section 2.1 for full mapping. Key filter column - drives which other columns are populated. (Tier 1 - ETL-derived from CreditTypeID/source)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PlatformTypeID COMMENT 'Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms. (Tier 3 - ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN InstrumentID COMMENT 'FK to Trade.Instrument. Financial instrument being traded. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Amount COMMENT 'Position size in currency. Must be >= 0. Stored in dollars (PositionOpen divides by 100 from cents). (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Leverage COMMENT 'Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN NetProfit COMMENT 'Realized PnL. 0 when open; set on close. In position currency. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Commission COMMENT 'Open commission in dollars. PositionOpen stores @Commission/100 (cents to dollars). (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PositionID COMMENT 'Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CampaignID COMMENT 'Marketing campaign identifier. 0 if not campaign-related. References `DWH_dbo.Dim_Campaign.CampaignID` - JOIN for Code, Description, StartDate, EndDate, MaxBonusAmount, IsActive. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN BonusTypeID COMMENT 'Bonus type for bonus events (ActionTypeID=9). 0 for non-bonus events. References `DWH_dbo.Dim_BonusType.BonusTypeID` - JOIN for Name, IsWithdrawable, IsActive. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FundingTypeID COMMENT 'Payment method used for deposits/withdrawals. 0 for non-deposit events. References `DWH_dbo.Dim_FundingType.FundingTypeID` - JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN LoginID COMMENT 'Login session identifier from `Billing.Login`. 0 for non-login events. (Tier 1 - Billing.Login)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN MirrorID COMMENT 'FK to Trade.Mirror. 0/NULL = manual. Positive = copy-trade position. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN WithdrawID COMMENT 'Withdrawal request ID for cashout events. 0 for non-cashout events. (Tier 1 - History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DurationInSeconds COMMENT 'Duration of a login session in seconds. NULL for non-login events. (Tier 1 - Billing.Login)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PostID COMMENT 'Social post/comment GUID for social engagement events (ActionTypeID 21-26). NULL for non-social events. (Tier 1 - Social platform)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CaseID COMMENT 'CRM case identifier for ActionTypeID=31 (Open CRM Case). 0 otherwise. (Tier 1 - CRM)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN UpdateDate COMMENT 'UTC timestamp of the last DWH ETL update for this row. Set to `GETUTCDATE()` during each ETL run. (Tier 2 - ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DateID COMMENT 'Date of the action as integer YYYYMMDD. Derived from `Occurred`. Part of nonclustered indexes. (Tier 2 - ETL-computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN TimeID COMMENT 'Hour of the action (0-23). Derived from `DATEPART(HOUR, Occurred)`. (Tier 2 - ETL-computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN StatusID COMMENT 'Row status. Nearly always 1 (active). NULL for ~2M rows. (Tier 3 - ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PreviousOccurred COMMENT 'Deprecated/unused column. NULL for most rows - not reliably populated. Do not use. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CompensationReasonID COMMENT 'Compensation reason for compensation events (ActionTypeID=36) and position opens (for airdrop identification). References `BackOffice.CompensationReason`. 0 for non-compensation events. (Tier 1 - History.Credit, updated 2025-12-21)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN WithdrawPaymentID COMMENT 'Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL. (Tier 1 - History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionOnClose COMMENT 'Commission charged on close. DWH note: adjusted by SP_Dim_Position when position is reopened; CommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPlug COMMENT 'Deprecated/unused column. Always NULL. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DepositID COMMENT 'Deposit transaction identifier. NULL for non-deposit events. (Tier 1 - History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PostRootID COMMENT 'Root post ID for social engagement events. NULL for non-social events. (Tier 1 - Social platform)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommission COMMENT 'Full commission including spread. PositionOpen stores @FullCommission/100. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionOnClose COMMENT 'Full commission on close. DWH note: adjusted by SP_Dim_Position when position is reopened; FullCommissionOnCloseOrig stores the pre-adjustment value. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RedeemID COMMENT 'Billing.Redeem reference when position closed via redeem. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RedeemStatus COMMENT 'Redemption state. Billing.Redeem integration. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN SessionID COMMENT 'STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events. (Tier 1 - STS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsRedeem COMMENT 'Redeem flag. 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as `Dim_Position.IsRedeem` (via RedeemStatus mapping). (Tier 3 - ETL-derived)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RegulationIDOnOpen COMMENT 'Regulatory jurisdiction ID at time of position open. ETL-computed via JOIN to etoro_History_BackOfficeCustomer (customer''s regulation history). ISNULL(..., 0) when no regulation match found. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PlatformID COMMENT 'Product/platform identifier - badly named, actually references `Dim_Product.ProductID` (not a standalone platform enum). Resolves to Product, Platform, and SubPlatform via JOIN to `DWH_dbo.Dim_Product`. Only populated for ActionTypeID=14 (logins) and 41 (registrations). (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ReopenForPositionID COMMENT 'When position was reopened: references the erroneously closed PositionID. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsReOpen COMMENT '1=this position was reopened from ReopenForPositionID. ETL-computed: CASE WHEN ReopenForPositionID IS NOT NULL THEN 1. Default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionOnCloseOrig COMMENT 'Original CommissionOnClose before reopen adjustments. ETL: CASE WHEN ReopenForPositionID IS NOT NULL THEN CommissionOnClose ELSE 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionOnCloseOrig COMMENT 'Original FullCommissionOnClose before reopen. ETL default 0. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN OriginalPositionID COMMENT 'Original position ID for positions split by partial close. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPartialCloseParent COMMENT '1=this position was partially closed (is the parent in a partial close event). (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPartialCloseChild COMMENT '1=this position is the child (remainder) of a partial close event. Generally filter out child positions from most metrics on OPEN when aggregating, but not all (e.g., volume is already pro-rated so excluding these is wrong). NEVER filter these out on CLOSE. (Tier 5 - domain expert, SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN InitialUnits COMMENT 'Original unit count at open. Used for partial close ratio. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PaymentStatusID COMMENT 'Payment processing status for deposit/cashout events. NULL for non-payment events. References `DWH_dbo.Dim_PaymentStatus.PaymentStatusID` - JOIN for Name. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsDiscounted COMMENT '1=position received a discounted rate. DWH note: CAST from bit to int. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. (Tier 5 - Expert Review)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionByUnits COMMENT 'Prorated commission for partial close. Formula: (AmountInUnitsDecimal / InitialUnits) * Commission. Used for partial-close PnL. (Tier 1 - Trade.Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionByUnits COMMENT 'Prorated full commission for partial close. Same proration formula as CommissionByUnits applied to FullCommission. (Tier 1 - Trade.Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsFTD COMMENT 'First-Time Deposit flag: 1 = this is the customer''s first deposit. NULL for non-deposit events. (Tier 2 - ETL-computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CountryIDByIP COMMENT 'Country determined by IP geolocation. Populated for logins and registrations. References `DWH_dbo.Dim_Country.CountryID` - JOIN for country name. Also see `DWH_dbo.Dim_CountryIP` for IP-to-country resolution. (Tier 5 - domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsAnonymousIP COMMENT 'Anonymous IP flag: 1 = connection via anonymous proxy/VPN. NULL for most rows. (Tier 1 - IP geolocation)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ProxyType COMMENT 'Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections. (Tier 1 - STS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsFeeDividend COMMENT 'Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See Section 2.2 and DSM-1463. (Tier 2 - ETL-derived from Description)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsAirDrop COMMENT '1=position was created via an airdrop event (crypto). ETL-computed: JOIN to etoro_Trade_PositionAirdropLog. NULL=not an airdrop. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DividendID COMMENT 'Dividend event identifier for dividend-related fees. NULL for non-dividend events. (Tier 1 - Trade positions)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN MoveMoneyReasonID COMMENT 'Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. References `Dictionary.MoveMoneyReason`. (Tier 1 - History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN SettlementTypeID COMMENT 'Modern settlement classification. Dictionary.SettlementTypes: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Replaces IsSettled. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DLTOpen COMMENT 'DLT flag at open. Added 2024-06-02 (Ofir A). (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DLTClose COMMENT 'DLT flag at close. Added 2024-06-02. NULL for open positions and older positions. (Tier 2 - SP_Dim_Position_DL_To_Synapse)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN OpenMarkupByUnits COMMENT 'Prorated open markup for partial close. Formula: OpenMarkup * AmountInUnitsDecimal / InitialUnits. (Tier 1 - Trade.Position)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsBuy COMMENT '1 = Long/Buy (profit when price rises), 0 = Short/Sell. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CreditID COMMENT 'Reference to the source `History.Credit.CreditID`. Enables join back to credit history for audit. (Tier 1 - History.Credit, added 2025-07)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Description COMMENT 'Human-readable description. Populated mainly for ActionTypeID=35 (fees): "Over night fee", "Payment caused by dividend", "Weekend fee", "OpenTotalFees", "CloseTotalFees", "SDRT Charge". For ActionTypeID=32: "edit stop loss by customer". For deposits: "Processed By eToro.Payments.Deposit", etc. (Tier 1 - History.Credit, added 2024-08)';
-- ---- Column PII Tags ----
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN HistoryID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN GCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DemoCID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Occurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IPNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsReal SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ActionTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PlatformTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN NetProfit SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Commission SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CampaignID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN BonusTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN LoginID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN MirrorID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN WithdrawID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DurationInSeconds SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PostID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CaseID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN TimeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN StatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PreviousOccurred SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CompensationReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN WithdrawPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPlug SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PostRootID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RedeemID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RedeemStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN SessionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsRedeem SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RegulationIDOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PlatformID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ReopenForPositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsReOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionOnCloseOrig SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionOnCloseOrig SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN OriginalPositionID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPartialCloseParent SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPartialCloseChild SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN InitialUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PaymentStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsDiscounted SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CountryIDByIP SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsAnonymousIP SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ProxyType SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsFeeDividend SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsAirDrop SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DividendID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN MoveMoneyReasonID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN SettlementTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DLTOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DLTClose SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN OpenMarkupByUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CreditID SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 11:31:49 UTC
-- Batch deploy resume: DWH_dbo deploy batch 1
-- Statements: 143/143 succeeded
-- ====================
