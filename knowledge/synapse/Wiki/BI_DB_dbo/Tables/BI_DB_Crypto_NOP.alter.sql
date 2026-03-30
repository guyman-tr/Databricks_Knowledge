-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Crypto_NOP
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Crypto_NOP'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Date COMMENT 'As-of business date for the load; equals SP parameter `@Date`. Live samples show daily loads through **2026-03-19**. (Tier 2 -- SP_Crypto_NOP, @Date)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Regulation COMMENT 'Regulation name from `Dim_Regulation.Name` via `Fact_SnapshotCustomer.RegulationID` in `#fsc`. Live 7-day data: highest row counts **CySEC**, **FCA**, **FSA Seychelles**, **ASIC & GAML**, **FSRA**, **FinCEN+FINRA**, **BVI**, **ASIC**, **FinCEN**, **eToroUS**. (Tier 2 -- SP_Crypto_NOP, Dim_Regulation.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Label COMMENT 'Broker / entity label from `Dim_Label.Name` via `Fact_SnapshotCustomer.LabelID`. Live 7-day: **eToro** dominates; smaller volumes include **eToroRussia**, **ILQ**, **Royal-CM**, **JCLyons**, **eToroUSA**, **Dealing**, **ICMarkets**, **eToroChina**, **RetailFX**. (Tier 2 -- SP_Crypto_NOP, Dim_Label.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN InstrumentID COMMENT 'Crypto instrument key; filtered to `Dim_Instrument.InstrumentTypeID = 10` in `#pnl_posDist`. (Tier 2 -- SP_Crypto_NOP, Dim_Instrument.InstrumentID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN InstrumentName COMMENT 'Instrument display name from `BI_DB_PositionPnL` / `Dim_Instrument.Name`. Live 7-day row counts top instruments include **BTC/USD**, **ETH/USD**, **XRP/USD**, **ADA/USD**, **SOL/USD**, **DOGE/USD**, **XLM/USD**, **TRX/USD**, **SHIBxM/USD**, **LINK/USD**. (Tier 2 -- SP_Crypto_NOP, Dim_Instrument.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Real_NOP COMMENT 'Sum of NOP on settled real positions (`IsSettled = 1`) from `#pos_new`. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.NOP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN CFD_NOP COMMENT 'Sum of NOP on CFD positions (`IsSettled = 0`). (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.NOP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Total_NOP COMMENT '`SUM(NOP_CFD) + SUM(NOP_Real)` at instrument grain; does not add TRS into this field. (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Real_Units COMMENT 'Sum of `AmountInUnitsDecimal` where `IsSettled = 1`. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN CFD_Units COMMENT 'Sum of `AmountInUnitsDecimal` where `IsSettled = 0`. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Total_Units COMMENT 'Sum of all `AmountInUnitsDecimal` for the grain. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN EOD_Bid_Price COMMENT 'End-of-day bid (spreaded) from `Fact_CurrencyPriceWithSplit.BidSpreaded` for the instrument on `@DateID`; `MAX` in aggregate. (Tier 2 -- SP_Crypto_NOP, Fact_CurrencyPriceWithSplit.BidSpreaded)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN UpdateDate COMMENT 'Row load timestamp. `GETDATE()` at insert. (Tier 3 -- SP_Crypto_NOP, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Leverage COMMENT 'Position leverage from `BI_DB_PositionPnL` / `#pos`. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.Leverage)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN EquityCFD COMMENT 'Rounded sum of CFD equity (`Amount + PositionPnL` when `IsSettled = 0`). (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN EquityReal COMMENT 'Rounded sum of real equity (`Amount + PositionPnL` when `IsSettled = 1`). (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN IsBuy COMMENT 'Position direction from open snapshot (`Dim_Position` / `#pos`). Live 7-day: rows with **IsBuy** = 1 greatly exceed **IsBuy** = 0. (Tier 2 -- SP_Crypto_NOP, Dim_Position.IsBuy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN MifidCategorizationID COMMENT 'MiFID categorization key from `Fact_SnapshotCustomer`. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.MifidCategorizationID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN MifidCategorization COMMENT 'MiFID categorization name from `Dim_MifidCategorization.Name`. (Tier 2 -- SP_Crypto_NOP, Dim_MifidCategorization.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN AccountTypeID COMMENT 'Account type key from `Fact_SnapshotCustomer`. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.AccountTypeID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN AccountType COMMENT 'Account type name from `Dim_AccountType.Name`. (Tier 2 -- SP_Crypto_NOP, Dim_AccountType.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN PlayerLevelID COMMENT 'Player level key from `Fact_SnapshotCustomer`. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.PlayerLevelID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Club COMMENT 'Club name from `Dim_PlayerLevel.Name`. (Tier 2 -- SP_Crypto_NOP, Dim_PlayerLevel.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN PlayerStatusID COMMENT 'Player status key from `Fact_SnapshotCustomer`. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.PlayerStatusID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN PlayerStatus COMMENT 'Player status name from `Dim_PlayerStatus.Name`. (Tier 2 -- SP_Crypto_NOP, Dim_PlayerStatus.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN IsGermanBaFin COMMENT '`1` if customer appears in `BI_DB_dbo.V_GermanBaFin` for `@DateID`. (Tier 2 -- SP_Crypto_NOP, V_GermanBaFin)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN IsCreditReportValidCB COMMENT 'Credit report validity flag from `Fact_SnapshotCustomer`. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.IsCreditReportValidCB)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Total_NOP_ReversedUnits COMMENT '`Total_NOP / BidSpreaded` when `Dim_Instrument.InstrumentTypeID = 10`, else 0; **BidSpreaded** from **#reversed_units** (USD leg price). Often **NULL** in live samples when the reversed-pair price is missing. (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN CountryName COMMENT 'Country from `Dim_Country.Name` via `Fact_SnapshotCustomer.CountryID`. (Tier 2 -- SP_Crypto_NOP, Dim_Country.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN NewUsers COMMENT '`1` when `Dim_Customer.RegisteredReal >= ''2022-02-08''`, else `0`. (Tier 2 -- SP_Crypto_NOP, Dim_Customer.RegisteredReal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN BuyCurrency COMMENT 'Instrument buy currency from `Dim_Instrument.BuyCurrency` (joined on final insert); live rows show codes such as **STRK**, **BONKxM** aligned to the pair. (Tier 2 -- SP_Crypto_NOP, Dim_Instrument.BuyCurrency)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN TRS_NOP COMMENT 'Sum of NOP where `SettlementTypeID = 2`. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.NOP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN TRS_Units COMMENT 'Sum of units where `SettlementTypeID = 2`. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN EquityTRS COMMENT 'Rounded sum of TRS equity (`Amount + PositionPnL` when `SettlementTypeID = 2`). (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN TanganyStatus COMMENT 'Custodian status label from `External_UserApiDB_Dictionary_TanganyStatus.Name` via `Dim_Customer.TanganyStatusID`. Live 7-day: mostly **NULL**; non-null top values **Inactive**, **MicaCustomer**, **Customer**, **Internal**, **ConsentCustomer**. (Tier 2 -- SP_Crypto_NOP, External_UserApiDB_Dictionary_TanganyStatus.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Real_Units_Staking_OptIn COMMENT 'Subset of real units per crypto staking enrolment rules (branch differs for ETH/USD vs other pairs); live rows show split vs **Real_Units_Staking_OptOut** summing to **Real_Units** where applicable. (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Real_Units_Staking_OptOut COMMENT 'Complement slice of real units for staking opt-in/out logic. (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN IsDLTUser COMMENT 'DLT user flag: `1` if `DltStatusID = 4` on snapshot customer, else `0`. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.DltStatusID)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Label SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Real_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN CFD_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Total_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Real_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN CFD_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Total_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN EOD_Bid_Price SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Leverage SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN EquityCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN EquityReal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN MifidCategorizationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN MifidCategorization SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN AccountType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN IsGermanBaFin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Total_NOP_ReversedUnits SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN CountryName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN NewUsers SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN BuyCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN TRS_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN TRS_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN EquityTRS SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN TanganyStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Real_Units_Staking_OptIn SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN Real_Units_Staking_OptOut SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop ALTER COLUMN IsDLTUser SET TAGS ('pii' = 'none');

-- == LAST EXECUTION ==
-- Timestamp: 2026-03-30 15:58:19 UTC
-- Batch deploy resume: BI_DB_dbo deploy batch 1
-- Statements: 78/78 succeeded
-- ====================
