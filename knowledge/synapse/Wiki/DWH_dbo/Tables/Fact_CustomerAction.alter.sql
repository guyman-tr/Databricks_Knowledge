-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_CustomerAction
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
-- Resolved via: information_schema bulk query
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction SET TBLPROPERTIES (
    'comment' = '`DWH_dbo.Fact_CustomerAction` is the unified customer event log for the eToro platform. Every significant action a customer performs — opening a position, closing a position, depositing money, withdrawing, logging in, publishing a social post, receiving a fee, getting a bonus, registering an account — is captured as a single row in this table. It answers: "What did this customer do, when, and what were the financial details?" The table consolidates events from five distinct production sources into a single ActionTypeID-driven schema: 1. **Position opens** (ActionTypeID 1-3, 39): From `Trade.OpenPositionEndOfDay` via the Generic Pipeline + staging 2. **Position closes** (ActionTypeID 4-6, 28, 40): From `History.ClosePositionEndOfDay` via the Generic Pipeline + staging 3. **Credit/financial events** (ActionTypeID 7-13, 15-20, 27, 30, 32, 34-38, 42-45): From `History.Credit` (which unions `History.ActiveCredit` + archived Credit partition tables back to 2007) 4. **Logins** (ActionTypeID 14): From `STS_Audit_U...'
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
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN HistoryID COMMENT 'Intended as a unique key but contains duplicates — NOT reliable as a primary/unique identifier. Do not use for JOINs, deduplication, or row identification. Has no practical use for analysts. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN GCID COMMENT 'Global Customer ID — the platform-wide unique customer identifier. References `Dim_Customer.GCID`. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID. (Tier 1 — Customer.CustomerStatic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DemoCID COMMENT 'Demo-account Customer ID. Always 0 in this table (real accounts only). (Tier 3 — ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Occurred COMMENT 'UTC timestamp when the action occurred. For position opens: when position was opened. For logins: login time. For credits: when the credit was recorded. (Tier 1 — source-dependent)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IPNumber COMMENT 'IP address of the customer as a numeric value. Populated for logins and registrations. (Tier 1 — STS/Billing.Login)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsReal COMMENT 'Account type flag. Always 1 in this table (real accounts only). (Tier 3 — ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ActionTypeID COMMENT 'Event type classifier. References `DWH_dbo.Dim_ActionType.ActionTypeID` — JOIN for Name, Category, CategoryID. See Section 2.1 for full mapping. Key filter column — drives which other columns are populated. (Tier 1 — ETL-derived from CreditTypeID/source)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PlatformTypeID COMMENT 'Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms. (Tier 3 — ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN InstrumentID COMMENT 'Financial instrument. References `Dim_Instrument`. 0 for non-position events. Same meaning as `Dim_Position.InstrumentID`. (Tier 1 — Trade.OpenPositionEndOfDay / History.ClosePositionEndOfDay)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Amount COMMENT 'Event amount in account currency (USD). For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative). (Tier 1 — source-dependent)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Leverage COMMENT 'Leverage multiplier for position events. 0 for non-position events. 1=no leverage. Same meaning as `Dim_Position.Leverage`. (Tier 1 — Trade.OpenPositionEndOfDay)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN NetProfit COMMENT 'Realized P&L for position closes. 0 for opens and non-position events. Same meaning as `Dim_Position.NetProfit`. (Tier 1 — History.ClosePositionEndOfDay)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN Commission COMMENT 'eToro markup (spread) at position open, in account currency. 0 for non-position events. Same meaning as `Dim_Position.Commission`. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PositionID COMMENT 'Position identifier for position events. 0 for non-position events. Same meaning as `Dim_Position.PositionID`. (Tier 1 — Trade positions)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CampaignID COMMENT 'Marketing campaign identifier. 0 if not campaign-related. References `DWH_dbo.Dim_Campaign.CampaignID` — JOIN for Code, Description, StartDate, EndDate, MaxBonusAmount, IsActive. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN BonusTypeID COMMENT 'Bonus type for bonus events (ActionTypeID=9). 0 for non-bonus events. References `DWH_dbo.Dim_BonusType.BonusTypeID` — JOIN for Name, IsWithdrawable, IsActive. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FundingTypeID COMMENT 'Payment method used for deposits/withdrawals. 0 for non-deposit events. References `DWH_dbo.Dim_FundingType.FundingTypeID` — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN LoginID COMMENT 'Login session identifier from `Billing.Login`. 0 for non-login events. (Tier 1 — Billing.Login)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN MirrorID COMMENT 'Copy-trade relationship ID. 0=manual action, >0=action within a copy-trade. Same meaning as `Dim_Position.MirrorID`. (Tier 1 — Trade positions)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN WithdrawID COMMENT 'Withdrawal request ID for cashout events. 0 for non-cashout events. (Tier 1 — History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DurationInSeconds COMMENT 'Duration of a login session in seconds. NULL for non-login events. (Tier 1 — Billing.Login)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PostID COMMENT 'Social post/comment GUID for social engagement events (ActionTypeID 21-26). NULL for non-social events. (Tier 1 — Social platform)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CaseID COMMENT 'CRM case identifier for ActionTypeID=31 (Open CRM Case). 0 otherwise. (Tier 1 — CRM)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN UpdateDate COMMENT 'UTC timestamp of the last DWH ETL update for this row. Set to `GETUTCDATE()` during each ETL run. (Tier 2 — ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DateID COMMENT 'Date of the action as integer YYYYMMDD. Derived from `Occurred`. Part of nonclustered indexes. (Tier 2 — ETL-computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN TimeID COMMENT 'Hour of the action (0-23). Derived from `DATEPART(HOUR, Occurred)`. (Tier 2 — ETL-computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN StatusID COMMENT 'Row status. Nearly always 1 (active). NULL for ~2M rows. (Tier 3 — ETL-assigned)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PreviousOccurred COMMENT 'Deprecated/unused column. NULL for most rows — not reliably populated. Do not use. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CompensationReasonID COMMENT 'Compensation reason for compensation events (ActionTypeID=36) and position opens (for airdrop identification). References `BackOffice.CompensationReason`. 0 for non-compensation events. (Tier 1 — History.Credit, updated 2025-12-21)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN WithdrawPaymentID COMMENT 'Payment processing ID for cashout/withdrawal events. 0 for non-cashout events. Used to deduplicate WithdrawProcessingID rows in the ETL. (Tier 1 — History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionOnClose COMMENT 'eToro markup (spread) at position close. 0 for opens and non-position events. For reopened positions: adjusted = new - original. Same meaning as `Dim_Position.CommissionOnClose`. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPlug COMMENT 'Deprecated/unused column. Always NULL. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DepositID COMMENT 'Deposit transaction identifier. NULL for non-deposit events. (Tier 1 — History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PostRootID COMMENT 'Root post ID for social engagement events. NULL for non-social events. (Tier 1 — Social platform)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommission COMMENT 'Full spread at position open = market spread + eToro markup. NULL for non-position events. Same meaning as `Dim_Position.FullCommission`. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionOnClose COMMENT 'Full spread at position close. NULL for non-position events. For reopened positions: adjusted. Same meaning as `Dim_Position.FullCommissionOnClose`. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RedeemID COMMENT 'Crypto redemption transaction reference. NULL when not a redeem. Same meaning as `Dim_Position.RedeemID`. (Tier 1 — Billing.Redeem)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RedeemStatus COMMENT 'Crypto redemption status: 0=N/A, 1=Pending, 6=Closed by redeem, 20=Terminated, 21=FailedToCancel. Same meaning as `Dim_Position.RedeemStatus`. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN SessionID COMMENT 'STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events. (Tier 1 — STS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsRedeem COMMENT 'Redeem flag. 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as `Dim_Position.IsRedeem` (via RedeemStatus mapping). (Tier 3 — ETL-derived)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN RegulationIDOnOpen COMMENT 'Regulatory jurisdiction at position open time. Same mapping as `Dim_Position.RegulationIDOnOpen`: 0=None, 1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 9=FSA Seychelles, etc. NULL for non-position events. (Tier 2 — BackOffice.Customer)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PlatformID COMMENT 'Product/platform identifier — badly named, actually references `Dim_Product.ProductID` (not a standalone platform enum). Resolves to Product, Platform, and SubPlatform via JOIN to `DWH_dbo.Dim_Product`. Only populated for ActionTypeID=14 (logins) and 41 (registrations). (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ReopenForPositionID COMMENT 'For reopened positions: the PositionID of the original closed position. Same meaning as `Dim_Position.ReopenForPositionID`. (Tier 1 — Trade positions)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsReOpen COMMENT 'Reopen flag: 1 = position created by reopening. Same meaning as `Dim_Position.IsReOpen`. (Tier 1 — Trade positions)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionOnCloseOrig COMMENT 'Original CommissionOnClose before reopen adjustment. Same meaning as `Dim_Position.CommissionOnCloseOrig`. (Tier 2 — ETL reopen logic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionOnCloseOrig COMMENT 'Original FullCommissionOnClose before reopen adjustment. Same meaning as `Dim_Position.FullCommissionOnCloseOrig`. (Tier 2 — ETL reopen logic)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN OriginalPositionID COMMENT 'For partial-close children: the parent PositionID. When `OriginalPositionID ≠ PositionID`, this is a partial-close child. Same meaning as `Dim_Position.OriginalPositionID`. (Tier 2 — ETL-derived)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPartialCloseParent COMMENT 'Flag: 1 = this position has had partial close children. Set by `SP_Fact_CustomerAction_IsParitalCloseParent`. Same meaning as `Dim_Position.IsPartialCloseParent`. (Tier 2 — post-load SP)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsPartialCloseChild COMMENT 'Flag: 1 = this position was created by partial close. Filter out when counting positions. Same meaning as `Dim_Position.IsPartialCloseChild`. (Tier 2 — ETL-derived)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN InitialUnits COMMENT 'Original unit count at position open. Same meaning as `Dim_Position.InitialUnits`. (Tier 1 — Trade positions)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN PaymentStatusID COMMENT 'Payment processing status for deposit/cashout events. NULL for non-payment events. References `DWH_dbo.Dim_PaymentStatus.PaymentStatusID` — JOIN for Name. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsDiscounted COMMENT 'Discounted pricing flag: 0=standard, 1=discounted (VIP/partner). Same meaning as `Dim_Position.IsDiscounted`. (Tier 1 — Trade.PositionTreeInfo)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsSettled COMMENT 'Real ownership flag: 1=settled (customer owns asset), 0=CFD. NULL for non-position events. The ETL also derives IsSettled when source is NULL: `IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) → 1`. Same meaning as `Dim_Position.IsSettled`. (Tier 1 — Trade positions, with ETL fallback)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CommissionByUnits COMMENT 'Commission prorated by units: `(AmountInUnitsDecimal / InitialUnits) * Commission`. Same meaning as `Dim_Position.CommissionByUnits`. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN FullCommissionByUnits COMMENT 'Full spread prorated by units. Same meaning as `Dim_Position.FullCommissionByUnits`. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsFTD COMMENT 'First-Time Deposit flag: 1 = this is the customer''s first deposit. NULL for non-deposit events. (Tier 2 — ETL-computed)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CountryIDByIP COMMENT 'Country determined by IP geolocation. Populated for logins and registrations. References `DWH_dbo.Dim_Country.CountryID` — JOIN for country name. Also see `DWH_dbo.Dim_CountryIP` for IP-to-country resolution. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsAnonymousIP COMMENT 'Anonymous IP flag: 1 = connection via anonymous proxy/VPN. NULL for most rows. (Tier 1 — IP geolocation)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN ProxyType COMMENT 'Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections. (Tier 1 — STS)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsFeeDividend COMMENT 'Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See Section 2.2 and DSM-1463. (Tier 2 — ETL-derived from Description)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsAirDrop COMMENT 'Airdrop flag: 1 = position created by eToro on behalf of customer. Same meaning as `Dim_Position.IsAirDrop`. (Tier 5 — domain expert, via Trade.PositionAirdropLog)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DividendID COMMENT 'Dividend event identifier for dividend-related fees. NULL for non-dividend events. (Tier 1 — Trade positions)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN MoveMoneyReasonID COMMENT 'Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. References `Dictionary.MoveMoneyReason`. (Tier 1 — History.Credit)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN SettlementTypeID COMMENT 'Settlement mechanism: 0=CFD, 1=Real asset, 2/4/5=other. NULL for non-position events. Same meaning as `Dim_Position.SettlementTypeID`. (Tier 1 — Trade positions)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DLTOpen COMMENT 'DLT (German crypto broker) flag at open: 0=not executed via DLT broker, 1=opened on DLT broker platform. NULL for non-position events. Same meaning as `Dim_Position.DLTOpen`. (Tier 5 — domain expert, added 2024-06)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN DLTClose COMMENT 'DLT broker flag at close: 1=closed on DLT broker platform. Same meaning as `Dim_Position.DLTClose`. (Tier 5 — domain expert, added 2024-06)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN OpenMarkupByUnits COMMENT 'Open markup prorated by units: `OpenMarkup * AmountInUnitsDecimal / InitialUnits`. Same meaning as `Dim_Position.OpenMarkupByUnits`. (Tier 5 — domain expert)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN IsBuy COMMENT 'Trade direction: True=Buy (long), False=Sell (short). NULL for non-position events. Same meaning as `Dim_Position.IsBuy`. (Tier 1 — Trade positions, added 2024-09)';
ALTER TABLE main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction ALTER COLUMN CreditID COMMENT 'Reference to the source `History.Credit.CreditID`. Enables join back to credit history for audit. (Tier 1 — History.Credit, added 2025-07)';

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
