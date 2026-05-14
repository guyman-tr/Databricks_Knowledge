-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Fact_PnL
-- Generated: 2026-05-03 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DDR_Fact_PnL > 8.8B-row granular daily P&L fact table tracking unrealized PnL changes and realized net profit per customer × instrument type × position flags since 2015. Sourced from `Function_PnL_Single_Day` (which reads `BI_DB_PositionPnL`, `Dim_Position`, `Dim_Instrument`), aggregated by `SP_DDR_Fact_PnL` with daily DELETE/INSERT by DateID. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | Multiple - `BI_DB_PositionPnL`, `Dim_Position`, `Dim_Instrument` via `Function_PnL_Single_Day` TVF | | **Refresh** | Daily (DELETE/INSERT by DateID) | | | | | **Synapse Distribution** | HASH(RealCID) | | **Synapse Index** | CLUSTERED COLUMNSTORE INDEX | | | | | **UC Target** | _Pending - resolved during write-objects_ | | **UC Format** | _Pending - resolved during write-objects_ | | **UC Partitioned By** | _Pend'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN DateID COMMENT 'Calendar key in **`YYYYMMDD`** integer form. Matches the TVF’s `DateID` and the SP’s **`@dateID`**. (Tier 2 - Function_PnL_Single_Day)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN Date COMMENT 'Calendar **`date`** for the load: **`@date AS [Date]`** in `SP_DDR_Fact_PnL`. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN RealCID COMMENT 'Real-account Customer ID. HASH distribution key. References **`Dim_Customer.RealCID`**. Each customer has one real CID. BI_DB transform: column name **`RealCID`**; TVF source column is **`CID`** (same semantics as **`Dim_Position.CID`**). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN InstrumentTypeID COMMENT 'From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType. Join-enriched via **`Dim_Instrument`** in **`SP_DDR_Fact_PnL`**. (Tier 1 - Trade.GetInstrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsCopy COMMENT '**`CASE WHEN frfc.MirrorID > 0 THEN 1 ELSE 0 END`**. **1** = copy-trade child path (see **`MirrorID`** semantics in `Dim_Position`). (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsSettled COMMENT '1 = real asset, 0 = CFD asset. (Tier 5 - Expert Review)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN UnrealizedPnLChange COMMENT '**`SUM(frfc.UnrealizedPnLChange)`** from **`Function_PnL_Single_Day`**, where per-position change comes from **`BI_DB_PositionPnL`** prior vs current snapshot **`CASE`** (`UnrealizedPnLEnd - UnrealizedPnLStart` with NULL guards). (Tier 2 - BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN NetProfit COMMENT '**`SUM(frfc.NetProfit)`** over the group. Base measure: Realized PnL. 0 when open; set on close. In position currency. (Tier 2 - Trade.PositionTbl)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN CountPositions COMMENT '**`COUNT(frfc.PositionID)`** - count of TVF position rows in each aggregate bucket. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp: **`GETDATE()`** at SP run. (Tier 2 - SP_DDR_Fact_PnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsFuture COMMENT '1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures. 243 flagged as futures. **`ISNULL(frfc.IsFuture,0)`** in SP. (Tier 2 - SP_Dim_Instrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsLeveraged COMMENT '**`CASE WHEN frfc.Leverage > 1 THEN 1 ELSE 0 END`**. Derived from position **Leverage**: Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 2 - Trade.PositionTbl)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsBuy COMMENT '1 = Long/Buy (profit when price rises), 0 = Short/Sell. DWH note: **`bit`** in **`Dim_Position`**; here **int** from TVF/Synapse path. (Tier 1 - Trade.PositionTbl)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsCopyFund COMMENT 'Smart Portfolio / Fund position flag from TVF: **`CASE WHEN cpt.PositionID IS NOT NULL THEN 1 ELSE 0 END`** with **`LEFT JOIN BI_DB_CopyFund_Positions`**. **`ISNULL(...,0)`** in SP. (Tier 2 - Function_PnL_Single_Day)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsSQF COMMENT '**`IsSQF` (SpotQuotedFuture flag) - 1 = instrument is a SpotQuotedFuture (smaller-contract variant of eToro RealFutures, traded on the CME / Chicago Mercantile Exchange). 0 = not an SQF instrument. Source: **`Function_Instrument_Snapshot_Enriched(@dateInt)`** via membership in **`Trade.InstrumentGroups`** with **`GroupID = 59`**. **`ISNULL(frfc.IsSQF, 0)`** per SP. (Tier 5 - user expert correction; previously mis-described as "Sustainable & Quality-Focused")';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN UnrealizedPnLChange SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN NetProfit SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN CountPositions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsFuture SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsLeveraged SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsCopyFund SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl ALTER COLUMN IsSQF SET TAGS ('pii' = 'none');

