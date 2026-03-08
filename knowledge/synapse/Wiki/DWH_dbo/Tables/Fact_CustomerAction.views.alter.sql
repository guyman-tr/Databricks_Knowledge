-- =============================================================================
-- Databricks View Column Comment Propagation: Fact_CustomerAction
-- Generated: 2026-03-08 | dwh-semantic-doc pipeline
-- 
-- Propagates column descriptions from Fact_CustomerAction to downstream UC views.
-- Uses COMMENT ON COLUMN syntax (required for views; ALTER TABLE does not work).
--
-- Source: main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction
-- Synapse: DWH_dbo.Fact_CustomerAction
--
-- Target views:
--   main.bi_output_stg.v_semantic_fact_customeraction  (77/79 cols)
--   main.data_rooms.vw_fact_customeraction              (41/45 cols)
--
-- Total: 118 COMMENT ON COLUMN statements
-- =============================================================================

-- ---- main.bi_output_stg.v_semantic_fact_customeraction (77/79 columns matched) ----
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.HistoryID IS 'Intended as unique key but contains duplicates — NOT reliable. Never use for JOINs, deduplication, or row identification.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.GCID IS 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.RealCID IS 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.DemoCID IS 'Demo-account Customer ID. Always 0 in this table (real accounts only).';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.Occurred IS 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IPNumber IS 'IP address as numeric value. Populated for logins and registrations.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsReal IS 'Account type flag. Always 1 in this table (real accounts only).';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.ActionTypeID IS 'Event type classifier. References Dim_ActionType.ActionTypeID — JOIN for Name, Category, CategoryID. Key filter: determines which other columns are populated. 1-3,39=position opens, 4-6,28,40=closes, 7=deposit, 8=cashout, 9=bonus, 14=login, 35=fees, 41=registration.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.PlatformTypeID IS 'Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.InstrumentID IS 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.Amount IS 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.Leverage IS 'Leverage multiplier for position events. 0=non-position event. 1=no leverage (real ownership). Same meaning as Dim_Position.Leverage.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.NetProfit IS 'Realized P&L for position closes in USD. 0 for opens and non-position events. Same meaning as Dim_Position.NetProfit.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.Commission IS 'eToro markup (spread) at position open in USD. 0 for non-position events. Same meaning as Dim_Position.Commission.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.PositionID IS 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.CampaignID IS 'Marketing campaign identifier. 0 if not campaign-related. References Dim_Campaign.CampaignID — JOIN for Code, Description, StartDate, EndDate, MaxBonusAmount, IsActive.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.BonusTypeID IS 'Bonus type for bonus events (ActionTypeID=9). 0 for non-bonus. References Dim_BonusType.BonusTypeID — JOIN for Name, IsWithdrawable, IsActive.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.FundingTypeID IS 'Payment method for deposits/withdrawals. 0 for non-deposit events. References Dim_FundingType.FundingTypeID — JOIN for Name, IsNewStyle, IsSingleFunding, IsCashoutActive.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.LoginID IS 'Login session identifier from Billing.Login. 0 for non-login events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.MirrorID IS 'Copy-trade relationship ID. 0=manual action, >0=copy-trade. Same meaning as Dim_Position.MirrorID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.WithdrawID IS 'Withdrawal request ID for cashout events. 0 for non-cashout events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.DurationInSeconds IS 'Login session duration in seconds. NULL for non-login events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.PostID IS 'Social post/comment GUID for social engagement events (ActionTypeID 21-26). NULL for non-social events. Dead data — no longer updated.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.CaseID IS 'CRM case identifier for ActionTypeID=31 (Open CRM Case). 0 otherwise.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.UpdateDate IS 'UTC timestamp of last DWH ETL update for this row.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.DateID IS 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.TimeID IS 'Hour of action (0-23). Derived from DATEPART(HOUR, Occurred).';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.StatusID IS 'Row status. Nearly always 1 (active). NULL for ~2M rows.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.PreviousOccurred IS 'Deprecated/unused column. NULL for most rows — not reliably populated. Do not use.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.CompensationReasonID IS 'Compensation reason for compensation events (ActionTypeID=36) and position opens (airdrop identification). References BackOffice.CompensationReason. 0 for non-compensation events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.WithdrawPaymentID IS 'Payment processing ID for cashout/withdrawal events. 0 for non-cashout events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.CommissionOnClose IS 'eToro markup (spread) at position close. 0 for opens and non-position events. For reopened positions: adjusted = new - original. Same meaning as Dim_Position.CommissionOnClose.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsPlug IS 'Deprecated/unused column. Always NULL.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.DepositID IS 'Deposit transaction identifier. NULL for non-deposit events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.PostRootID IS 'Root post ID for social engagement events. NULL for non-social events. Dead data — no longer updated.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.FullCommission IS 'Full spread at position open = market spread + eToro markup. NULL for non-position events. Same meaning as Dim_Position.FullCommission.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.FullCommissionOnClose IS 'Full spread at position close. NULL for non-position events. For reopened positions: adjusted. Same meaning as Dim_Position.FullCommissionOnClose.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.RedeemID IS 'Crypto redemption transaction reference. NULL when not a redeem. Same meaning as Dim_Position.RedeemID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.RedeemStatus IS 'Crypto redemption status: 0=N/A, 1=Pending, 6=Closed by redeem, 20=Terminated, 21=FailedToCancel. Same meaning as Dim_Position.RedeemStatus.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.SessionID IS 'STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsRedeem IS 'Redeem flag: 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as Dim_Position.IsRedeem.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.RegulationIDOnOpen IS 'Regulatory jurisdiction at position open. 0=None, 1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 9=FSA Seychelles. NULL for non-position events. Same meaning as Dim_Position.RegulationIDOnOpen. Refs Dim_Regulation.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.PlatformID IS 'Product/platform identifier — badly named, actually references Dim_Product.ProductID (not a standalone platform enum). JOIN to Dim_Product for Product, Platform, SubPlatform. Only populated for ActionTypeID=14 (logins) and 41 (registrations).';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.ReopenForPositionID IS 'For reopened positions: the PositionID of the original closed position. Same meaning as Dim_Position.ReopenForPositionID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsReOpen IS 'Reopen flag: 1=position created by reopening a previously closed position. Same meaning as Dim_Position.IsReOpen.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.CommissionOnCloseOrig IS 'Original CommissionOnClose before reopen adjustment. Same meaning as Dim_Position.CommissionOnCloseOrig.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.FullCommissionOnCloseOrig IS 'Original FullCommissionOnClose before reopen adjustment. Same meaning as Dim_Position.FullCommissionOnCloseOrig.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.OriginalPositionID IS 'For partial-close children: parent PositionID. When OriginalPositionID != PositionID, this is a partial-close child. Same meaning as Dim_Position.OriginalPositionID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsPartialCloseParent IS 'Flag: 1=has had partial-close children. Set by SP_Fact_CustomerAction_IsParitalCloseParent. Same meaning as Dim_Position.IsPartialCloseParent.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsPartialCloseChild IS 'Flag: 1=created by partial close. Filter out (ISNULL(IsPartialCloseChild,0)=0) when counting positions. Same meaning as Dim_Position.IsPartialCloseChild.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.InitialUnits IS 'Original unit count at position open. Never updated on partial close. Same meaning as Dim_Position.InitialUnits.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.PaymentStatusID IS 'Payment processing status for deposit/cashout events. NULL for non-payment events. References Dim_PaymentStatus.PaymentStatusID — JOIN for Name.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsDiscounted IS 'Discounted pricing flag: 0=standard, 1=discounted (VIP/partner). Same meaning as Dim_Position.IsDiscounted.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsSettled IS 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.CommissionByUnits IS 'Commission prorated by units: (AmountInUnitsDecimal/InitialUnits)*Commission. Same meaning as Dim_Position.CommissionByUnits.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.FullCommissionByUnits IS 'Full spread prorated by units: (AmountInUnitsDecimal/InitialUnits)*FullCommission. Same meaning as Dim_Position.FullCommissionByUnits.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsFTD IS 'First-Time Deposit flag: 1=this is the customer''s first deposit. NULL for non-deposit events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.CountryIDByIP IS 'Country determined by IP geolocation. Populated for logins and registrations. References Dim_Country.CountryID — JOIN for country name.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsAnonymousIP IS 'Anonymous IP flag: 1=connection via anonymous proxy/VPN. NULL for most rows.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.ProxyType IS 'Proxy classification: DCH=datacenter, VPN=VPN, PUB=public proxy, SES=session proxy, TOR=Tor exit node, WEB=web proxy. NULL for non-proxy connections.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsFeeDividend IS 'Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See DSM-1463.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsAirDrop IS 'Airdrop flag: 1=position created by eToro on behalf of customer (staking, promotions, compensations). Same meaning as Dim_Position.IsAirDrop.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.DividendID IS 'Dividend event identifier for dividend-related fees. NULL for non-dividend events.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.MoveMoneyReasonID IS 'Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. Refs Dictionary.MoveMoneyReason.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.SettlementTypeID IS 'Settlement mechanism: 0=CFD, 1=Real asset, 2=TRS, 3=CMT (crypto settled), 4=REAL_FUTURES, 5=MARGIN_TRADE. NULL for non-position events. Same meaning as Dim_Position.SettlementTypeID.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.etr_y IS 'Partition column: year (string). Added by Databricks gold-layer ETL for partition pruning. Derived from event date.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.etr_ym IS 'Partition column: year-month (string). Added by Databricks gold-layer ETL for partition pruning. Derived from event date.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.etr_ymd IS 'Partition column: year-month-day (string). Added by Databricks gold-layer ETL for partition pruning. Derived from event date. Finest grain for partition filter.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.DLTOpen IS 'DLT (German crypto broker) flag at open: 1=opened on DLT platform, 0/NULL=not DLT. Same meaning as Dim_Position.DLTOpen.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.DLTClose IS 'DLT (German crypto broker) flag at close: 1=closed on DLT platform. Same meaning as Dim_Position.DLTClose.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.OpenMarkupByUnits IS 'Open markup prorated by units: OpenMarkup * AmountInUnitsDecimal / InitialUnits. Same meaning as Dim_Position.OpenMarkupByUnits.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.Description IS 'Human-readable description. Mainly for ActionTypeID=35 (fees): "Over night fee", "Payment caused by dividend", "Weekend fee", "OpenTotalFees", "CloseTotalFees", "SDRT Charge". Also for deposits, stop-loss edits.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.IsBuy IS 'Trade direction: True=Buy/Long, False=Sell/Short. NULL for non-position events. Same meaning as Dim_Position.IsBuy.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.CreditID IS 'Reference to source History.Credit.CreditID. Enables join back to credit history for audit.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.OpenDateID IS 'Open date as YYYYMMDD int. DWH-computed from OpenOccurred. Indexed.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.CloseDateID IS 'Close date as YYYYMMDD int. 0=still open. Part of clustered index. Key filter for open vs closed.';
COMMENT ON COLUMN main.bi_output_stg.v_semantic_fact_customeraction.VolumeOnClose IS 'Close volume = rounded(Units * Price * ConversionRate) at close. Same formula as Volume but at close-time values. Pro-rated for partial close.';

-- ---- main.data_rooms.vw_fact_customeraction (41/45 columns matched) ----
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.ActionTypeID IS 'Event type classifier. References Dim_ActionType.ActionTypeID — JOIN for Name, Category, CategoryID. Key filter: determines which other columns are populated. 1-3,39=position opens, 4-6,28,40=closes, 7=deposit, 8=cashout, 9=bonus, 14=login, 35=fees, 41=registration.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.HistoryID IS 'Intended as unique key but contains duplicates — NOT reliable. Never use for JOINs, deduplication, or row identification.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.GCID IS 'Global Customer ID — platform-wide unique customer identifier. References Dim_Customer.GCID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.RealCID IS 'Real-account Customer ID. HASH distribution key. References Dim_Customer.RealCID. Always include in WHERE/JOIN for optimal performance.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.Occurred IS 'UTC timestamp when action occurred. For position opens: open time. For logins: login time. For credits: credit record time.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.IsReal IS 'Account type flag. Always 1 in this table (real accounts only).';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.PlatformTypeID IS 'Legacy platform type. 0=default (most rows), 99=STS source. Values 1-9 for specific platforms.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.InstrumentID IS 'Financial instrument. References Dim_Instrument. 0 for non-position events. Same meaning as Dim_Position.InstrumentID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.Amount IS 'Event amount in USD. For position opens: invested amount. For deposits: deposit amount. For fees: fee amount (negative).';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.Leverage IS 'Leverage multiplier for position events. 0=non-position event. 1=no leverage (real ownership). Same meaning as Dim_Position.Leverage.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.NetProfit IS 'Realized P&L for position closes in USD. 0 for opens and non-position events. Same meaning as Dim_Position.NetProfit.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.Commission IS 'eToro markup (spread) at position open in USD. 0 for non-position events. Same meaning as Dim_Position.Commission.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.PositionID IS 'Position identifier for position events. 0 for non-position events. Same meaning as Dim_Position.PositionID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.MirrorID IS 'Copy-trade relationship ID. 0=manual action, >0=copy-trade. Same meaning as Dim_Position.MirrorID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.WithdrawID IS 'Withdrawal request ID for cashout events. 0 for non-cashout events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.DurationInSeconds IS 'Login session duration in seconds. NULL for non-login events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.UpdateDate IS 'UTC timestamp of last DWH ETL update for this row.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.DateID IS 'Date of action as YYYYMMDD integer. Derived from Occurred. Part of nonclustered indexes — key filter column.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.TimeID IS 'Hour of action (0-23). Derived from DATEPART(HOUR, Occurred).';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.CompensationReasonID IS 'Compensation reason for compensation events (ActionTypeID=36) and position opens (airdrop identification). References BackOffice.CompensationReason. 0 for non-compensation events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.WithdrawPaymentID IS 'Payment processing ID for cashout/withdrawal events. 0 for non-cashout events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.CommissionOnClose IS 'eToro markup (spread) at position close. 0 for opens and non-position events. For reopened positions: adjusted = new - original. Same meaning as Dim_Position.CommissionOnClose.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.DepositID IS 'Deposit transaction identifier. NULL for non-deposit events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.FullCommission IS 'Full spread at position open = market spread + eToro markup. NULL for non-position events. Same meaning as Dim_Position.FullCommission.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.FullCommissionOnClose IS 'Full spread at position close. NULL for non-position events. For reopened positions: adjusted. Same meaning as Dim_Position.FullCommissionOnClose.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.RedeemID IS 'Crypto redemption transaction reference. NULL when not a redeem. Same meaning as Dim_Position.RedeemID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.RedeemStatus IS 'Crypto redemption status: 0=N/A, 1=Pending, 6=Closed by redeem, 20=Terminated, 21=FailedToCancel. Same meaning as Dim_Position.RedeemStatus.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.SessionID IS 'STS session identifier for logins and position opens. For manual opens: from login session. For copy opens: from mirror session. NULL for other events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.IsRedeem IS 'Redeem flag: 0=not a redeem, 1=is a redeem. NULL for non-position events. Same meaning as Dim_Position.IsRedeem.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.RegulationIDOnOpen IS 'Regulatory jurisdiction at position open. 0=None, 1=CySEC, 2=FCA, 4=ASIC, 5=BVI, 9=FSA Seychelles. NULL for non-position events. Same meaning as Dim_Position.RegulationIDOnOpen. Refs Dim_Regulation.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.PlatformID IS 'Product/platform identifier — badly named, actually references Dim_Product.ProductID (not a standalone platform enum). JOIN to Dim_Product for Product, Platform, SubPlatform. Only populated for ActionTypeID=14 (logins) and 41 (registrations).';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.ReopenForPositionID IS 'For reopened positions: the PositionID of the original closed position. Same meaning as Dim_Position.ReopenForPositionID.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.IsReOpen IS 'Reopen flag: 1=position created by reopening a previously closed position. Same meaning as Dim_Position.IsReOpen.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.IsSettled IS 'Real ownership flag: 1=settled (owns asset), 0=CFD. NULL for non-position events. ETL fallback: IsBuy=1 AND Leverage=1 AND InstrumentTypeID IN (10,5,6) => 1. Same meaning as Dim_Position.IsSettled.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.IsFTD IS 'First-Time Deposit flag: 1=this is the customer''s first deposit. NULL for non-deposit events.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.IsFeeDividend IS 'Fee sub-type for ActionTypeID=35: 1=overnight/weekend fee, 2=dividend, 3=SDRT, 4=ticket fees (OpenTotalFees/CloseTotalFees). NULL for non-fee events. See DSM-1463.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.IsAirDrop IS 'Airdrop flag: 1=position created by eToro on behalf of customer (staking, promotions, compensations). Same meaning as Dim_Position.IsAirDrop.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.MoveMoneyReasonID IS 'Reason for money movement: 1=Adjustment, 5=InternalTransfer Trade, 6=InternalTransfer, 8=Recurring Deposit, 9=Recurring Investment. Refs Dictionary.MoveMoneyReason.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.etr_y IS 'Partition column: year (string). Added by Databricks gold-layer ETL for partition pruning. Derived from event date.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.etr_ym IS 'Partition column: year-month (string). Added by Databricks gold-layer ETL for partition pruning. Derived from event date.';
COMMENT ON COLUMN main.data_rooms.vw_fact_customeraction.etr_ymd IS 'Partition column: year-month-day (string). Added by Databricks gold-layer ETL for partition pruning. Derived from event date. Finest grain for partition filter.';
