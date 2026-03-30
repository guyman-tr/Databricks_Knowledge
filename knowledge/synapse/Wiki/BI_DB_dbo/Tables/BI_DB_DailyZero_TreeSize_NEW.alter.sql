-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Date COMMENT 'Report date for the daily run (equals **@RepDate** / **@start** in the SP). (Tier 2 -- SP_DailyZero_TreeSize_NEW, @RepDate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN HedgeServerID COMMENT 'Hedge server from **Dim_Position**. Groups exposure by hedging infrastructure. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.HedgeServerID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Copy COMMENT 'Copy trade role: **1** if **MirrorID** > 0, **-1** if **OrigParentPositionID** > 0, else **0**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.MirrorID / OrigParentPositionID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN InstrumentID COMMENT 'Instrument id; **1000** when **InstrumentTypeID** in (5,6) (stocks/ETF rollup). (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.InstrumentID / Dim_Instrument)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN RiskIndex COMMENT 'Placeholder in current ETL (inserted as empty string literal, effectively **0**). Reserved for future risk indexing. (Tier 2 -- SP_DailyZero_TreeSize_NEW, literal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN TreeSize_Units COMMENT 'Bucket label from **AmountInUnitsDecimal** or tree-aggregated units (e.g. **10K+**, **1M+**, **Smaller**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, computed bucket)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN TreeSize_USD COMMENT 'Bucket label from **OpenPosition** (USD) or tree-aggregated USD size (e.g. **100K+**, **1000K+**, **Smaller**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, computed bucket)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Leverage COMMENT 'Position leverage from **Dim_Position**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.Leverage)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN RiskGroup COMMENT 'Placeholder; inserted as empty string in current SP. (Tier 2 -- SP_DailyZero_TreeSize_NEW, literal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN DepositGroup COMMENT 'Placeholder; inserted as empty string in current SP. (Tier 2 -- SP_DailyZero_TreeSize_NEW, literal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN RealizedCommission COMMENT 'Sum of commission components (**FullCommissionOnClose** minus **FullCommissionByUnits** when applicable, or on-open close commission). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #Realized / #UnRealized TotalCommission)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN RealizedZero COMMENT 'Portion of **CalculatedZero** from closed positions on the report date (**Indicator** = **Realized**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #Realized.CalculatedZero)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN ChangeInUnrealizedZero COMMENT 'Portion of **CalculatedZero** from open / marked positions (**Indicator** = **UnRealized**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #UnRealized.CalculatedZero)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN TotalZero COMMENT '**RealizedZero** + **ChangeInUnrealizedZero** (sum of **CalculatedZero**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, computed aggregate)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN NOP COMMENT 'Sum of net open position exposure (**NOP** from **BI_DB_PositionPnL** for the report **DateID**, signed by buy/sell). (Tier 2 -- SP_DailyZero_TreeSize_NEW, BI_DB_PositionPnL.NOP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN OpenPositions COMMENT 'Sum of **OpenPosition** (directional NOP). (Tier 2 -- SP_DailyZero_TreeSize_NEW, BI_DB_PositionPnL.NOP x IsBuy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Nop_Units COMMENT 'Sum of **NOP_Units** (**AmountInUnitsDecimal** at mark from **PositionPnL** path). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #Pos_with_Vol.NOP_Units)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN VolumeAtOpen COMMENT 'Trading volume for positions opened on the report **DateID**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.Volume)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN VolumeAtClose COMMENT 'Volume on close for positions closed on the report **DateID**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.VolumeOnClose)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN UpdateDate COMMENT 'Load timestamp. (Tier 3 -- SP_DailyZero_TreeSize_NEW, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN IsCFD COMMENT '**1** when position is treated as CFD-like per **IsSettled** vs **BI_DB_PositionPnL.IsSettled** rules; **0** for **Real** cash-settled path. (Tier 2 -- SP_DailyZero_TreeSize_NEW, computed from Dim_Position / BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Regulation COMMENT 'Regulation name from **Dim_Regulation** via **Fact_SnapshotCustomer**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Regulation.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN MifID COMMENT 'MiFID categorization id from snapshot customer (**MifidCategorizationID**). (Tier 2 -- SP_DailyZero_TreeSize_NEW, Fact_SnapshotCustomer.MifidCategorizationID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN InstrumentType COMMENT 'Instrument type label; **Stocks/ETF** for instrument types 5 and 6. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Instrument.InstrumentType)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN InstrumentName COMMENT 'Instrument name; **Stocks/ETF** for types 5 and 6. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Instrument.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN OpenPositionValue COMMENT 'Sum of **Amount + PositionPnL** from **BI_DB_PositionPnL** (mark value). (Tier 2 -- SP_DailyZero_TreeSize_NEW, BI_DB_PositionPnL)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Country COMMENT 'Customer country from **Dim_Country** on snapshot **CountryID**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Country.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN PlayerLevel COMMENT 'Player level name from **Dim_PlayerLevel**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_PlayerLevel.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN GuruStatus COMMENT 'Guru program status from **Dim_GuruStatus**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_GuruStatus.GuruStatusName)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Long_OP COMMENT 'Aggregated long-side open position (NOP contribution). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #Pos_with_Vol.Long_OP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Short_OP COMMENT 'Aggregated short-side open position (NOP contribution). (Tier 2 -- SP_DailyZero_TreeSize_NEW, #Pos_with_Vol.Short_OP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN SettlementType COMMENT '**Real** vs **CFD** / **TRS** / **CMT** from **SettlementTypeID** when not **Real** path. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Position.SettlementTypeID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN IsIslamic COMMENT '**Islamic** when **WeekendFeePrecentage** = 0 on **Dim_Customer**, else **Not Islamic**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Customer.WeekendFeePrecentage)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN IsDLTUser COMMENT '**1** when **DltStatusID** = 4 on customer, else **0**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Dim_Customer.DltStatusID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN TicketFees COMMENT 'Sum of ticket-fee actions from **Fact_CustomerAction** (fee/dividend type 4) for the report **DateID**. (Tier 2 -- SP_DailyZero_TreeSize_NEW, Fact_CustomerAction.Amount)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN HedgeServerID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Copy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN RiskIndex SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN TreeSize_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN TreeSize_USD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN RiskGroup SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN DepositGroup SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN RealizedCommission SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN RealizedZero SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN ChangeInUnrealizedZero SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN TotalZero SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN OpenPositions SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Nop_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN VolumeAtOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN VolumeAtClose SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN IsCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN MifID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN OpenPositionValue SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN PlayerLevel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN GuruStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Long_OP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN Short_OP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN SettlementType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN IsIslamic SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN IsDLTUser SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_dailyzero_treesize_new ALTER COLUMN TicketFees SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 16:00:18 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 1
-- Statements: 72/72 succeeded
-- ====================
