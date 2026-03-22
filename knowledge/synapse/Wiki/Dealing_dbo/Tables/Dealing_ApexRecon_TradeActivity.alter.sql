-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_ApexRecon_TradeActivity
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity SET TBLPROPERTIES (
    'comment' = '**Daily trade activity reconciliation between eToro and Apex Clearing** for real stocks. Each row compares eToro''s trade execution units and average rate against Apex''s reported trade activity for the same instrument, direction, and liquidity account on the given date. Discrepancies (Etoro_Units ≠ Apex_Units, Etoro_Rate ≠ Apex_Rate) trigger investigation. This is one of three Apex reconciliation tables written by `SP_Apex_Recon` (alongside `Dealing_ApexRecon_Holdings` and `Dealing_ApexRecon_Hedging`). **Row grain**: `Date` + `LiquidityAccountID` + `InstrumentID` + `IsBuy` direction.'
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity SET TAGS (
    'domain' = 'trading',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'unknown',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Date COMMENT 'Report date for the trade activity reconciliation. (Tier 2 -- SP_Apex_Recon, @Date)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN InstrumentID COMMENT 'eToro instrument identifier. (Tier 2 -- SP_Apex_Recon, Dealing_Duco_ActivityRecon.InstrumentID)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN InstrumentDisplayName COMMENT 'Instrument display name. (Tier 2 -- SP_Apex_Recon, DWH_dbo.Dim_Instrument.InstrumentDisplayName)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN ISINCode COMMENT 'ISIN code for broker-side matching. (Tier 2 -- SP_Apex_Recon, Dealing_Duco_ActivityRecon.ISINCode)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN LiquidityAccountID COMMENT 'Apex liquidity account identifier. (Tier 2 -- SP_Apex_Recon, Fivetran hedge server/LA mapping)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN IsBuy COMMENT 'Trade direction: 1=buy, 0=sell. (Tier 2 -- SP_Apex_Recon, derived from Buy/Sell column in ActivityRecon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Etoro_Units COMMENT 'Total units traded on the eToro/LP side (from Duco ActivityRecon). (Tier 2 -- SP_Apex_Recon, Dealing_Duco_ActivityRecon.eToro_Units)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Apex_Units COMMENT 'Total units reported by Apex for the same instrument/direction. (Tier 2 -- SP_Apex_Recon, Dealing_staging.LP_APEX_EXT872_3EU_217314.Units)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Etoro_Rate COMMENT 'Weighted average execution rate on the eToro side. (Tier 2 -- SP_Apex_Recon, Dealing_Duco_ActivityRecon.eToro_AvgRate)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Apex_Rate COMMENT 'Weighted average rate reported by Apex. (Tier 2 -- SP_Apex_Recon, Dealing_staging.LP_APEX_EXT872_3EU_217314.Rate)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Etoro_Amount COMMENT 'Trade value on the eToro side in USD. (Tier 2 -- SP_Apex_Recon, Dealing_Duco_ActivityRecon.eToroUSDAmount)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Apex_Amount COMMENT 'Trade value reported by Apex in USD. (Tier 2 -- SP_Apex_Recon, Dealing_staging.LP_APEX_EXT872_3EU_217314.Amount)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN UpdateDate COMMENT 'Batch execution timestamp (GETDATE()). (Tier 3 -- SP_Apex_Recon, GETDATE())';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN HedgeServerID COMMENT 'Hedge server associated with the Apex LP account. (Tier 2 -- SP_Apex_Recon, Fivetran HS mapping)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN AccountNumber COMMENT 'Apex account number (alphanumeric broker identifier, e.g., 3EW35324). (Tier 2 -- SP_Apex_Recon, Dealing_staging.LP_APEX_EXT872_3EU_217314.AccountNumber)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN ISINCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN LiquidityAccountID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Etoro_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Apex_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Etoro_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Apex_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Etoro_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN Apex_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity ALTER COLUMN AccountNumber SET TAGS ('pii' = 'none');
