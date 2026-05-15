-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_RiskMatrix_V2
-- Generated: 2026-05-14 | speckit regen
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2
-- Resolved via: gap CSV + wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 SET TBLPROPERTIES (
    'comment' = 'Dealing NOP stress grid: baseline UnitsNOP plus 48 shock columns (UnitsNOP±X%) with snapshot pricing, leverage, regulation, hedge-server slice. 87642 rows; single PositionsTime/UpdateDate instant 2024-06-02 (frozen snapshot). No SSDT writer SP found; join DWH_dbo.Dim_Instrument for instrument semantics.'
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 SET TAGS (
    'domain' = 'dealing',
    'object_type' = 'table',
    'source_schema' = 'Dealing_dbo',
    'refresh_frequency' = 'stale_snapshot',
    'source_system' = 'Synapse',
    'synapse_distribution' = 'ROUND_ROBIN',
    'synapse_index' = 'HEAP',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = '15-phase'
);

-- ---- Column Comments ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN PositionsTime COMMENT 'Hedge / NOP snapshot timestamp. Live data shows one instant `2024-06-02 08:01:49.697` covering all rows (`MIN`=`MAX`). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN HedgeServerID COMMENT 'Hedge-book / LP server slice key from the snapshot (**32** distinct IDs in live data). Exact server catalog mapping not documented in SSDT. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentID COMMENT 'Primary key from Trade.Instrument. Identifies the tradeable instrument pair. (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentName COMMENT 'Computed: TDCUR_BUY.Abbreviation + ''/'' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). DWH snapshot column `InstrumentName` stores this pattern for the grain row. (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentType COMMENT 'ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN IsBuy COMMENT 'Side flag with live distinct values **0** and **1** only (`SELECT DISTINCT IsBuy`). **1** = buy / long, **0** = sell / short for this snapshot encoding (boolean intent; column is `int`, not `bit`). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Leverage COMMENT 'Leverage tier applied in the NOP shock grid (**11** observed values in live data: `1,2,5,10,20,25,30,50,100,200,400`). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Regulation COMMENT 'Regulation / license bucket text (**11** labels in snapshot, e.g. CySEC **24,440** rows / FCA **20,418** / FSA Seychelles **16,425** … “None” **3** rows). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Region COMMENT '**Unused in live snapshot** - **87,642 / 87,642** rows have `NULL` or empty string (`Region IS NULL OR LTRIM(RTRIM(ISNULL(Region,'''')))=''''` checklist query). DDL placeholder only until populated. (Tier 5 - Expert Review)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Bid COMMENT 'Bid price at snapshot time (`decimal(16,6)` per SSDT DDL). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Ask COMMENT 'Ask price at snapshot time (`decimal(16,6)` per SSDT DDL). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN ConversionRate COMMENT 'FX rate applied in the scenario engine toward USD (sample shows `1.000000` for USD-quoted names and fractional values for GBX names). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UnitsNOP COMMENT 'Baseline net-open-position units prior to shocks; **zero NULLs** in live table (`SUM(CASE WHEN UnitsNOP IS NULL THEN 1 END)=0`). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+1%` COMMENT 'NOP after **+1%** price shock; **zero NULLs** in stress spot-check (`SUM(CASE WHEN UnitsNOP+1% IS NULL THEN 1 END)=0`). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+2%` COMMENT 'NOP after **+2%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+3%` COMMENT 'NOP after **+3%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+4%` COMMENT 'NOP after **+4%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+5%` COMMENT 'NOP after **+5%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+6%` COMMENT 'NOP after **+6%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+7%` COMMENT 'NOP after **+7%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+8%` COMMENT 'NOP after **+8%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+9%` COMMENT 'NOP after **+9%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+10%` COMMENT 'NOP after **+10%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+15%` COMMENT 'NOP after **+15%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+20%` COMMENT 'NOP after **+20%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+25%` COMMENT 'NOP after **+25%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+30%` COMMENT 'NOP after **+30%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+40%` COMMENT 'NOP after **+40%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+50%` COMMENT 'NOP after **+50%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+60%` COMMENT 'NOP after **+60%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+70%` COMMENT 'NOP after **+70%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+80%` COMMENT 'NOP after **+80%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+90%` COMMENT 'NOP after **+90%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+100%` COMMENT 'NOP after **+100%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+200%` COMMENT 'NOP after **+200%** price shock (extreme upside tail). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+300%` COMMENT 'NOP after **+300%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+400%` COMMENT 'NOP after **+400%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+900%` COMMENT 'NOP after **+900%** price shock (extreme upside tail). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-1%` COMMENT 'NOP after ** - 1%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-2%` COMMENT 'NOP after ** - 2%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-3%` COMMENT 'NOP after ** - 3%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-4%` COMMENT 'NOP after ** - 4%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-5%` COMMENT 'NOP after ** - 5%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-6%` COMMENT 'NOP after ** - 6%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-7%` COMMENT 'NOP after ** - 7%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-8%` COMMENT 'NOP after ** - 8%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-9%` COMMENT 'NOP after ** - 9%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-10%` COMMENT 'NOP after ** - 10%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-15%` COMMENT 'NOP after ** - 15%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-20%` COMMENT 'NOP after ** - 20%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-25%` COMMENT 'NOP after ** - 25%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-30%` COMMENT 'NOP after ** - 30%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-40%` COMMENT 'NOP after ** - 40%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-50%` COMMENT 'NOP after ** - 50%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-60%` COMMENT 'NOP after ** - 60%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-70%` COMMENT 'NOP after ** - 70%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-80%` COMMENT 'NOP after ** - 80%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-90%` COMMENT 'NOP after ** - 90%** price shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-99%` COMMENT 'NOP after ** - 99%** price shock (**not** the same grid as  - 100%). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-100%` COMMENT 'NOP after ** - 100%** (full wipe) shock. (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UpdateDate COMMENT 'Load / publish timestamp for the snapshot rows. Live data shows one instant `2024-06-02 08:02:49.217` covering all rows (`MIN`=`MAX`). (Tier 2 - Dealing_dbo.Dealing_RiskMatrix_V2)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN IsSettled COMMENT '**`{0,1}` flag only** - meanings such as “real asset vs CFD” were **historical folklore** without SSDT proof. Treat as **unverified categorical** pending dealing risk SMEs. Distinct `{0,1}` (live MCP). (Tier 5 - Expert Review)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN PositionsTime SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Region SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Bid SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN Ask SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN ConversionRate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UnitsNOP SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+1%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+2%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+3%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+4%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+5%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+6%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+7%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+8%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+9%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+10%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+15%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+20%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+25%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+30%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+40%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+50%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+60%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+70%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+80%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+90%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+100%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+200%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+300%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+400%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP+900%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-1%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-2%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-3%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-4%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-5%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-6%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-7%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-8%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-9%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-10%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-15%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-20%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-25%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-30%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-40%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-50%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-60%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-70%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-80%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-90%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-99%` SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_riskmatrix_v2 ALTER COLUMN `UnitsNOP-100%` SET TAGS ('pii' = 'none');

