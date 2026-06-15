-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DailyCommisionReport_Instrument_Agg > Instrument-level daily aggregation of BI_DB_DailyCommisionReport. Each row summarises all commission, volume, and fee metrics for a single Date × Instrument × CustomerSegment combination - no individual CID present. Holds ~43.9M rows covering 102 trading dates (2026 YTD as of 2026-04-22, ~430K rows/date) and is refreshed daily by SP_DailyCommisionReport via a DELETE WHERE DateID + INSERT pattern (incremental, history preserved). Migrated to Unity Catalog Gold (Append strategy). | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | SP_DailyCommisionReport - reads BI_DB_dbo.BI_DB_DailyCommisionReport | | **Refresh** | Daily incremental: DELETE WHERE DateID=@DateID then INSERT grouped rows | | **Synapse Distribution** | ROUND_ROBIN | | **Synapse Index** | CLUSTERED INDE'
);

-- ---- Table Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN InstrumentID COMMENT 'Financial instrument integer key. GROUP BY pass-through. JOIN to Dim_Instrument for instrument metadata. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Instrument COMMENT 'Instrument name/symbol (e.g., AAPL, BTC/USD, EURUSD). GROUP BY pass-through from parent. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN InstrumentTypeID COMMENT 'Instrument type integer key. GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN InstrumentType COMMENT 'Instrument type label. Observed values: Currencies, Commodities, Indices, Stocks, Crypto Currencies, ETF. GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Region COMMENT 'Marketing region label (e.g., Western Europe, LATAM, Asia Pacific). GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Club COMMENT 'Customer club/tier label (Diamond, Platinum Plus, Platinum, Gold, Silver, Bronze, etc.) representing trading volume or loyalty tier. GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN FullDate COMMENT 'Calendar date of the trading activity (YYYY-MM-DD). GROUP BY pass-through; redundant with DateID. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN DateID COMMENT 'Trading date in YYYYMMDD integer format. Primary clustering key and incremental DELETE key. Always filter on this column for best performance. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN VolumeOnOpen COMMENT 'SUM of USD trading volume for positions opened on DateID within this instrument×segment combination. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN VolumeOnClose COMMENT 'SUM of USD trading volume for positions closed on DateID within this instrument×segment combination. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RollOverFee COMMENT 'SUM of overnight rollover / carry fees charged on DateID. Positive = eToro collected; negative = eToro paid. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN FullCommissions COMMENT 'SUM of gross full commission (net + all fees). Used for MIFID best-execution regulatory reporting. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Commissions COMMENT 'SUM of net eToro commission (spread-based revenue, net-to-company). Primary revenue KPI. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UpdateDate COMMENT 'ETL execution timestamp (`GETDATE()` at SP run time). Marks when this batch was written; not a business date. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Label COMMENT 'Customer segment label (e.g., ''eToro'', ''Proprietary''). GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN PlayerStatusID COMMENT 'Integer player status key. GROUP BY pass-through. JOIN to a player-status lookup for name resolution. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN PlayerStatus COMMENT 'Player status name (e.g., Normal, Blocked). GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN AccountStatusID COMMENT 'Integer account status key. GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN AccountStatusName COMMENT 'Account status label. GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN AccountTypeID COMMENT 'Integer account type key (1=Personal, 2=Corporate, 14=SMSF, etc.). GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN AccountType COMMENT 'Account type name (Personal, Corporate, etc.). GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsOutlier COMMENT '**Always NULL.** Legacy column inherited from parent DDL; statistical outlier flag that was never activated. Do not use. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Transition COMMENT '**Always NULL.** Legacy column inherited from parent DDL; regulatory transition label that was never populated. Do not use. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsGermanBaFIN COMMENT '**Always NULL.** Legacy column inherited from parent DDL; BaFIN (German financial regulator) flag superseded by the Regulation dimension. Do not use. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsEtoroTradingCID COMMENT 'Flag for internal eToro housekeeping / proprietary trading accounts (1=yes). Excludes these from external customer revenue analysis. GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsGlenEagleAccount COMMENT 'Flag for Glen Eagle Securities subsidiary accounts (1=yes). GROUP BY pass-through for regulatory entity separation. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN eToroTradingGroupUser COMMENT 'eToro trading group identifier string for internal group accounts. GROUP BY pass-through. NULL for standard retail customers. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RegulationIDPrev COMMENT '**Always NULL.** Legacy column tracking a customer''s prior regulatory jurisdiction ID; never activated. Do not use. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RegulationPrev COMMENT '**Always NULL.** Legacy column tracking a customer''s prior regulatory jurisdiction label; never activated. Do not use. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsCreditReportValidCBPrev COMMENT '**Always NULL.** Legacy column tracking prior Client_Balance validity (CB = Client_Balance, NOT CreditBureau); never activated. Do not use. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN US_State COMMENT 'US state or province short name (e.g., ''CA'', ''NY''). NULL for non-US customers. GROUP BY pass-through for US state-level regulatory and reporting splits. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN CommissionOnClose COMMENT 'SUM of raw commission on positions closed on DateID. Float type (not money). Represents the gross spread captured at close before adjustments. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN CommissionByUnitsAtClose COMMENT '**Always NULL.** Legacy column from a historical decomposition of CommissionOnClose by unit count; the decomposition was never implemented in the SP. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnrealizedCommissionNew COMMENT '**Always NULL.** Legacy column intended to track commission accrued on newly opened positions; never populated. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnrealizedCommissionOldClosing COMMENT '**Always NULL.** Legacy column intended to track previously accrued commission released on close; never populated. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RealizedCommission COMMENT '**Always NULL.** Legacy column for net realized commission decomposition; never activated. Distinct from CommissionOnClose (which is populated). (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnrealizedCommissionChange COMMENT 'SUM of daily delta in unrealized spread commission (change in the mark-to-market commission accrual). Used by SP_EY_Audit_Opened_Positions for EY audit open-position commission reporting. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN FullCommissionOnClose COMMENT 'SUM of gross full commission on positions closed on DateID (MIFID reporting basis). Float type. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN FullCommissionByUnitsAtClose COMMENT '**Always NULL.** Legacy decomposition of FullCommissionOnClose by unit count; never implemented. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnrealizedFullCommissionNew COMMENT '**Always NULL.** Legacy column for unrealized full commission on new positions; never populated. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnrealizedFullCommissionOldClosing COMMENT '**Always NULL.** Legacy column for unrealized full commission released on close; never populated. (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RealizedFullCommission COMMENT 'SUM of gross realized full commission (positions closed on DateID, MIFID basis). (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnealizedFullCommissionChange COMMENT '**Always NULL.** Legacy column for unrealized full commission daily delta; never populated. **DDL typo: column name is "Un*e*alized" (missing ''r'') - this is the persisted production schema name.** (Tier 4 - Legacy/Deprecated)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsBuy COMMENT 'Position direction flag. 1=long (buy), 0=short (sell). GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsLeverage COMMENT 'Leverage indicator. 1=position opened with leverage > 1x, 0=1x (no leverage). GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsLeverageMoreThen20 COMMENT 'High-leverage flag. 1=position leverage exceeds 20x. Note spelling: "MoreThen" (not "MoreThan") is the persisted DDL name. GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsAirDrop COMMENT 'Crypto airdrop flag. 1=position was created from a cryptocurrency airdrop event. GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN SettlementTypeID COMMENT 'Position settlement type. Observed values: 0=CFD, 1=Real asset, 5=Margin trade. GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsValidCustomer COMMENT 'Valid customer quality flag (1=passes validation criteria for revenue reporting). GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsCreditReportValidCB COMMENT 'Financial-customer flag for Client_Balance reports (CB = Client_Balance, NOT CreditBureau). GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Regulation COMMENT 'Regulatory jurisdiction label (e.g., CySEC, FCA, ASIC, FSAS, GLOBAL). GROUP BY pass-through. 12 distinct values observed in 2026 YTD. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsSettled COMMENT 'Settlement completion flag. 1=real/settled position (actual asset transferred), 0=CFD (contract for difference). GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RollOverFee_SDRT COMMENT 'SUM of UK Stamp Duty Reserve Tax charged on UK equity positions. Zero for non-UK-equity instruments. Float type. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN TradingFees COMMENT 'SUM of composite trading fees (AdminFee + SpotAdjustFee + TicketFee + TicketFeeByPercent). Convenience pre-aggregation of the four individual fee components. Float type. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsDLTUser COMMENT 'Distributed ledger technology (DLT) / blockchain user flag (1=yes). GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN TicketFee COMMENT 'SUM of per-ticket transaction fees (fixed fee per trade). (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN TicketFeeByPercent COMMENT 'SUM of percentage-based ticket fees (fee as percentage of trade value). (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN AdminFee COMMENT 'SUM of administration / Islamic finance fees (Sharia-compliant swap-free account charge). (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN SpotAdjustFee COMMENT 'SUM of spot price adjustment fees (correction applied when the transaction price differs from spot). (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN InvestedAmountOpen COMMENT 'SUM of USD invested amount for positions opened on DateID. Reflects capital deployed (not notional/leveraged amount). (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN CountUU COMMENT 'SUM of unique-user count values from parent rows. Represents total customer-activity events within this instrument×segment combination. Note: customers appearing in multiple segment rows on the same day are counted multiple times at this aggregation level. (Tier 2 - SP_DailyCommisionReport)';
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsMarginTrade COMMENT 'Margin-funded position flag (1=position funded by eToro margin; SettlementTypeID=5). Added 2025-10-23. GROUP BY pass-through. (Tier 2 - SP_DailyCommisionReport)';

-- ---- Column PII Tags ----
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Instrument SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN FullDate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN VolumeOnOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN VolumeOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RollOverFee SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN FullCommissions SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Commissions SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Label SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN AccountStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN AccountStatusName SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN AccountType SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsOutlier SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Transition SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsGermanBaFIN SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsEtoroTradingCID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsGlenEagleAccount SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN eToroTradingGroupUser SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RegulationIDPrev SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RegulationPrev SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsCreditReportValidCBPrev SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN US_State SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN CommissionOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN CommissionByUnitsAtClose SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnrealizedCommissionNew SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnrealizedCommissionOldClosing SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RealizedCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnrealizedCommissionChange SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN FullCommissionOnClose SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN FullCommissionByUnitsAtClose SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnrealizedFullCommissionNew SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnrealizedFullCommissionOldClosing SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RealizedFullCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN UnealizedFullCommissionChange SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsLeverage SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsLeverageMoreThen20 SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsAirDrop SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN SettlementTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsValidCustomer SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN RollOverFee_SDRT SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN TradingFees SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsDLTUser SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN TicketFee SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN TicketFeeByPercent SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN AdminFee SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN SpotAdjustFee SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN InvestedAmountOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN CountUU SET TAGS ('pii' = 'none');
ALTER TABLE main.general.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailycommisionreport_instrument_agg ALTER COLUMN IsMarginTrade SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 12:34:54 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 9
-- Statements: 126/126 succeeded
-- ====================
