-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_ApexRecon_Holdings
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings SET TBLPROPERTIES (
    'comment' = '`Dealing_ApexRecon_Holdings` is a **daily end-of-day holdings reconciliation** between eToro''s internal records and Apex Clearing (LP/custodian) for real stock positions. It compares the eToro dealing desk''s view of holdings (from Duco EOD reconciliation data) against Apex''s official custodian file for each instrument×HedgeServer combination. **Purpose**: Ensure that the number of shares eToro believes it holds at Apex matches what Apex reports. Discrepancies (`Etoro_Units != Apex_Units`) indicate settlement risk, failed trades, or data synchronization issues. The Dealing team reviews this daily for operational and regulatory compliance. **Scope**: Apex Clearing LP only (liquidity_provider=''Apex''). Stocks - Real activity (`activity=''Stocks - Real''`). HS/LP account mapping read from a Fivetran-synced Google Sheet (`External_Fivetran_dealing_active_hs_mappings`). RTH (Regular Trading Hours) instruments handled separately via a daylight-savings-adjusted allocation process. **Related tables in the same SP**: - `De'
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'daily',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'N/A',
    'synapse_index' = 'N/A',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Date COMMENT 'Reporting date (@Date parameter). Clustered index key. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN InstrumentID COMMENT 'Instrument identifier. FK to DWH_dbo.Dim_Instrument. NULL when Apex reports a position eToro cannot match to an InstrumentID. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN InstrumentDisplayName COMMENT 'User-facing instrument name. From Dim_Instrument or Apex file. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN ISINCode COMMENT 'International Securities Identification Number. From Dim_Instrument or eToro-side data. May be NULL if Apex provides only CUSIP. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Etoro_Units COMMENT 'eToro''s internal view of total shares held/hedged for this instrument×HS at EOD. From Dealing_Duco_EODRecon (and daylight savings supplement). NULL -> zero if NULLIF applied. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Apex_Units COMMENT 'Apex''s reported total shares in custody for this instrument×HS at EOD. From LP_APEX_EXT982_3EU (SUM of TradeQuantity). NULL when Apex has no holding. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Etoro_Rate COMMENT 'eToro''s EOD price for this instrument (from Dealing_Duco_EODRecon.eToroRate). Used for USD amount computation. NULLIF(0) applied. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Apex_Rate COMMENT 'Apex''s reported closing price (LP_APEX_EXT982_3EU.ClosingPrice). (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Etoro_Amount COMMENT 'eToro''s USD dollar value of holdings: `Etoro_Units × Etoro_Rate`. From Dealing_Duco_EODRecon.eToroUSDAmount. NULLIF(0) applied. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Apex_Amount COMMENT 'Apex''s reported market value in USD: `SUM(MarketValue)` from LP file. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN UpdateDate COMMENT 'ETL metadata: `GETDATE()` at SP run time. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN HedgeServerID COMMENT 'HedgeServer ID from HS/LP mapping (#Fivetran.hs_dealing_desk). Identifies which eToro dealing desk/hedge server this account belongs to. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Symbol COMMENT 'Apex ticker symbol (e.g., ''OPENW'', ''AUGO''). From Apex LP file or Dim_Instrument.Symbol. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Client_NOP COMMENT 'Client Net Open Position in USD: `SUM(ClientAmount)` from Dealing_Duco_EODRecon. Represents the total client-side exposure in this instrument (what clients hold). (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Client_NOP_Units COMMENT 'Client Net Open Position in shares: `SUM(ClientUnits)` from Dealing_Duco_EODRecon. Used for hedging diff calculation in Dealing_ApexRecon_Hedging. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN LastExecutionTime COMMENT 'Always NULL in current SP (column retained for legacy/future use). (Tier 3 - live data)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN CUSIP COMMENT 'CUSIP (Committee on Uniform Security Identification Procedures) identifier. 9-character US security identifier. Used for CUSIP-based matching between Apex and DWH. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Exchange COMMENT 'Exchange name from Dim_Instrument (e.g., ''Nasdaq'', ''NYSE''). Used to identify RTH instruments. (Tier 2 - SP_Apex_Recon)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN AccountNumber COMMENT 'Apex LP account number from #Fivetran mapping (lp_accounts). Identifies which specific Apex sub-account holds this position. (Tier 2 - SP_Apex_Recon)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN ISINCode SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Etoro_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Apex_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Etoro_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Apex_Rate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Etoro_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Apex_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Symbol SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Client_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Client_NOP_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN LastExecutionTime SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN CUSIP SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN Exchange SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings ALTER COLUMN AccountNumber SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 13:56:20 UTC
-- Batch deploy resume: Dealing_dbo deploy batch 1
-- Statements: 40/40 succeeded
-- ====================
