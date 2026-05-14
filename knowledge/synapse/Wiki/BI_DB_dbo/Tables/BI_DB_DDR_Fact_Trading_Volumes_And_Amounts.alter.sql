-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts > 793M-row daily trading volume and invested amount fact table tracking position open/close volumes, invested amounts, and transaction counts per customer, broken down by instrument type, settlement, copy-trade, leverage, and 8+ position flags. Sourced from `Function_Trading_Volume_PositionLevel` (which reads `Dim_Position`, `Dim_Instrument`, and multiple enrichment tables), aggregated by `SP_DDR_Fact_Trading_Volumes_And_Amounts` with daily DELETE/INSERT by DateID. | Property | Value | |----------|-------| | **Schema** | BI_DB_dbo | | **Object Type** | Table | | **Production Source** | `BI_DB_dbo.Function_Trading_Volume_PositionLevel` -> `DWH_dbo.Dim_Position` + `DWH_dbo.Dim_Instrument` | | **Refresh** | Daily (DELETE/INSERT by DateID) | | | | | **Synapse Distribution** | HASH(RealCID) | | **Synapse Index** | CLUSTERED COLUMNSTORE INDEX'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN DateID COMMENT 'Event calendar surrogate (`YYYYMMDD`). Determined inside **`Function_Trading_Volume_PositionLevel`** from **`Dim_Position.OpenDateID` / `CloseDateID`** union legs. PARTITION key for nightly reload. (`Tier 2 - Function_Trading_Volume_PositionLevel`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN Date COMMENT '`CONVERT(DATE, CONVERT(VARCHAR(8), ftv.DateID), 112)` - derived **DATE** companion to **`DateID`**. (`Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN RealCID COMMENT 'Global real-account **`CID`** surfaced as HASH key (`ftv.CID AS RealCID`). **Verbatim parity - `Fact_CustomerAction.md`**: *Real-account Customer ID. HASH distribution key. References `Dim_Customer.RealCID`. Each customer has one real CID.* (`Tier 1 - Customer.CustomerStatic`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InstrumentTypeID COMMENT '**Verbatim parity - `Dim_Instrument.md`**: *From IMD (InstrumentMetaData). Asset class: 1=Currencies, 2=Commodities, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. FK to Dictionary.CurrencyType.* (`Tier 1 - Trade.GetInstrument`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsSettled COMMENT '**Verbatim parity - `Dim_Position.md`**: *1 = real asset, 0 = CFD asset.* (`Tier 5 - Expert Review`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsCopy COMMENT 'TVF derivation **`CASE WHEN MirrorID > 0 THEN 1 ELSE 0`** on **`Dim_Position.MirrorID`** (`Function_Trading_Volume_PositionLevel.md` section 4 `#22`). (`Tier 2 - Function_Trading_Volume_PositionLevel`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsBuy COMMENT '**Verbatim parity - `Dim_Position.md`**: *1 = Long/Buy (profit when price rises), 0 = Short/Sell.* (`Tier 1 - Trade.PositionTbl`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsLeverage COMMENT '**`CASE WHEN Leverage > 1 THEN 1 ELSE 0 END`** in **`SP_DDR_Fact_Trading_Volumes_And_Amounts`** (GROUP BY duplication). Leverage originates from **`Dim_Position.Leverage`** (*“(1, 5, 10, …)”* · `Dim_Position.md` `#30`). (`Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsFuture COMMENT '**Verbatim grounding - `Dim_Instrument.md`**: *1=futures contract (instrument in Trade.InstrumentGroups WHERE GroupID=25), 0=not futures.* (`Tier 2 - SP_Dim_Instrument`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsCopyFund COMMENT '**1** when the position `PositionID` appears in `BI_DB_CopyFund_Positions` (Smart Portfolio / copy-fund trees). (`Tier 2 - BI_DB_CopyFund_Positions`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsOpenedFromIBAN COMMENT '**1/0 varchar** sentinel from **`BI_DB_Positions_Opened_From_IBAN`**. DDL mismatch vs `BIT` semantics - compare as strings. (`Tier 2 - BI_DB_Positions_Opened_From_IBAN`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsClosedToIBAN COMMENT 'Presence flag from **`BI_DB_Positions_Closed_To_IBAN`**. (`Tier 2 - BI_DB_Positions_Closed_To_IBAN`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsRecurring COMMENT 'Presence flag from **`BI_DB_RecurringInvestment_Positions`** auto-invest instrumentation. (`Tier 2 - BI_DB_RecurringInvestment_Positions`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsAirDrop COMMENT '**Verbatim - `Dim_Position.md` `#107`**: `1=position was created via an airdrop event (crypto). ETL-computed: JOIN to etoro_Trade_PositionAirdropLog. NULL=not an airdrop.` (`Tier 2 - SP_Dim_Position_DL_To_Synapse`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN VolumeOpen COMMENT '**`SUM`** of TVF **`VolumeOpen`** (**`CAST(Dim_Position.Volume BIGINT)` on qualifying opens** · `Dim_Position.md` **`Volume`** *ROUND(units × InitForexRate × USD conversion)*). (`Tier 2 - SP_Dim_Position_DL_To_Synapse`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN VolumeClose COMMENT '**`SUM`** of TVF **`VolumeClose`** (**`Dim_Position.VolumeOnClose`** *ROUND amount × `EndForexRate`* ). (`Tier 2 - SP_Dim_Position_DL_To_Synapse`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InvestedAmountOpen COMMENT '**`SUM`** of **`InitialAmountCents/100`** open leg (excluding partial-close children). **`InitialAmountCents`**: *Initial amount in cents… (`Tier 1 - Trade.PositionTbl`).* (`Tier 2 - Function_Trading_Volume_PositionLevel`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InvestedAmountClosed COMMENT '**`SUM`** of closed **`CAST(Amount AS FLOAT)`** legs. **`Amount`**: *Position size in currency… (`Tier 1 - Trade.PositionTbl`).* (`Tier 2 - Function_Trading_Volume_PositionLevel`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN TotalVolume COMMENT '**`SUM`** of **`VolumeOpen+VolumeClose`** intra-TVF totals (then aggregated). KPI for combined open+close persisted notionals same day slice. (`Tier 2 - Function_Trading_Volume_PositionLevel`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN NetInvestedAmount COMMENT '**`SUM`** of **`InvestedAmountOpen - InvestedAmountClosed`** from TVF. (`Tier 2 - Function_Trading_Volume_PositionLevel`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountOpenTransactions COMMENT '**`SUM`** (`CountOpenTransactions`) - excludes partial-close child opens (`Function_Trading_Volume_PositionLevel.md` `#13`). (`Tier 2 - Function_Trading_Volume_PositionLevel`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountCloseTransactions COMMENT '**`SUM`** per-close indicator column inside TVF. (`Tier 2 - Function_Trading_Volume_PositionLevel`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountTotalTransactions COMMENT '**`SUM`** (**open counter + close counter** per underlying row). (`Tier 2 - Function_Trading_Volume_PositionLevel`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN UpdateDate COMMENT 'ETL watermark **`GETDATE()`** captured at **`SP_DDR_Fact_Trading_Volumes_And_Amounts`** run. (`Tier 2 - SP_DDR_Fact_Trading_Volumes_And_Amounts`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsSQF COMMENT '`IsSQF` (SpotQuotedFuture flag) - 1 = instrument is a SpotQuotedFuture (smaller-contract variant of eToro RealFutures, traded on the CME). 0 = not. Source: `Function_Instrument_Snapshot_Enriched(@dateInt)` via membership in `Trade.InstrumentGroups` with `GroupID = 59`. (Tier 5 - user expert correction; previously mis-described as “Sustainable & Quality-Focused”)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsMarginTrade COMMENT '**Verbatim dictionary anchoring**: *`SettlementTypeID` … `Dictionary.SettlementTypes`: … **`5=MARGIN_TRADE`*** (`Dim_Position.md` `#115` excerpt). **`1`** when **`SettlementTypeID = 5`**, else **`0`** (TVF `CASE`). (`Tier 1 - Trade.PositionTbl`)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsC2P COMMENT 'Copy-to-portfolio migrated position (**1** when TVF **`LEFT JOIN`** to `BI_DB_dbo.V_C2P_Positions` matches **`PositionID`**, else **0**) - customer keeps economics after unlinking copy. (`Tier 2 - BI_DB_dbo.V_C2P_Positions`)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InstrumentTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsSettled SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsCopy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsLeverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsFuture SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsCopyFund SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsOpenedFromIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsClosedToIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsRecurring SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsAirDrop SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN VolumeOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN VolumeClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InvestedAmountOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN InvestedAmountClosed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN TotalVolume SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN NetInvestedAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountOpenTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountCloseTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN CountTotalTransactions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsSQF SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsMarginTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts ALTER COLUMN IsC2P SET TAGS ('pii' = 'none');

