-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_Crypto_NOP_CID
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_Crypto_NOP_CID'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Date COMMENT 'As-of business date; SP `@Date`. Live samples **2026-03-19**. (Tier 2 -- SP_Crypto_NOP, @Date)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Regulation COMMENT 'Regulation name from `Dim_Regulation.Name` via `#fsc`. Live 7-day: **CySEC**, **FCA**, **FinCEN+FINRA**, **FSA Seychelles**, **ASIC & GAML** lead by row count. (Tier 2 -- SP_Crypto_NOP, Dim_Regulation.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Label COMMENT 'Label from `Dim_Label.Name` via `#fsc`. (Tier 2 -- SP_Crypto_NOP, Dim_Label.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN CID COMMENT 'Customer identifier (`Fact_SnapshotCustomer` / position `CID`). Live samples show populated integer **CID** values. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.CID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Real_NOP COMMENT 'Sum of NOP for settled real positions. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.NOP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN CFD_NOP COMMENT 'Sum of NOP for CFD positions. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.NOP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Total_NOP COMMENT '`SUM(NOP_CFD) + SUM(NOP_Real)`; TRS held in **TRS_NOP**. (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Real_Units COMMENT 'Real units (`IsSettled = 1`). (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Real_Invested_Amount COMMENT 'Sum of `InitialAmount` where `IsSettled = 1`. (Tier 2 -- SP_Crypto_NOP, Dim_Position.InitialAmountCents)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN CFD_Invested_Amount COMMENT 'Sum of `InitialAmount` where `IsSettled = 0`. (Tier 2 -- SP_Crypto_NOP, Dim_Position.InitialAmountCents)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Total_Invested_Amount COMMENT 'Sum of `InitialAmount` across settlement types at grain. (Tier 2 -- SP_Crypto_NOP, Dim_Position.InitialAmountCents)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN UpdateDate COMMENT '`GETDATE()` on insert. (Tier 3 -- SP_Crypto_NOP, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN IsBuy COMMENT 'Position direction. (Tier 2 -- SP_Crypto_NOP, Dim_Position.IsBuy)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN EquityReal COMMENT 'Rounded sum of real equity. (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN EquityCFD COMMENT 'Rounded sum of CFD equity. (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN InstrumentName COMMENT 'Crypto pair name from position / `Dim_Instrument`; **fixed width** -- expect trailing spaces in raw T-SQL output and trim in consuming apps. (Tier 2 -- SP_Crypto_NOP, Dim_Instrument.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN MifidCategorizationID COMMENT 'From `Fact_SnapshotCustomer`. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.MifidCategorizationID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN MifidCategorization COMMENT 'From `Dim_MifidCategorization.Name`. (Tier 2 -- SP_Crypto_NOP, Dim_MifidCategorization.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN AccountTypeID COMMENT 'From `Fact_SnapshotCustomer`. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.AccountTypeID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN AccountType COMMENT 'From `Dim_AccountType.Name`. (Tier 2 -- SP_Crypto_NOP, Dim_AccountType.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN PlayerLevelID COMMENT 'From `Fact_SnapshotCustomer`. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.PlayerLevelID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Club COMMENT 'From `Dim_PlayerLevel.Name`. (Tier 2 -- SP_Crypto_NOP, Dim_PlayerLevel.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN PlayerStatusID COMMENT 'From `Fact_SnapshotCustomer`. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.PlayerStatusID)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN PlayerStatus COMMENT 'From `Dim_PlayerStatus.Name`. (Tier 2 -- SP_Crypto_NOP, Dim_PlayerStatus.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN IsGermanBaFin COMMENT 'German BaFin flag from `V_GermanBaFin`. (Tier 2 -- SP_Crypto_NOP, V_GermanBaFin)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN IsCreditReportValidCB COMMENT 'From `Fact_SnapshotCustomer`. (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.IsCreditReportValidCB)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN TRS_NOP COMMENT 'NOP where `SettlementTypeID = 2`. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.NOP)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN TRS_Units COMMENT 'Units where `SettlementTypeID = 2`. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN TRS_Invested_Amount COMMENT 'Sum of `InitialAmount` for TRS. (Tier 2 -- SP_Crypto_NOP, Dim_Position.InitialAmountCents)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN EquityTRS COMMENT 'Rounded sum of TRS equity. (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN CFD_Units COMMENT 'CFD units. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Total_Units COMMENT 'All units. (Tier 2 -- SP_Crypto_NOP, BI_DB_PositionPnL.AmountInUnitsDecimal)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN TanganyStatus COMMENT 'Tangany dictionary label via `Dim_Customer.TanganyStatusID`; frequently **NULL** in live samples. (Tier 2 -- SP_Crypto_NOP, External_UserApiDB_Dictionary_TanganyStatus.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Real_Units_Staking_OptIn COMMENT 'Staking opt-in slice of real units (ETH vs non-ETH branch); live rows show complement vs **Real_Units_Staking_OptOut**. (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Real_Units_Staking_OptOut COMMENT 'Staking opt-out slice of real units. (Tier 2 -- SP_Crypto_NOP, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN IsDLTUser COMMENT 'DLT flag from snapshot (`DltStatusID = 4`). (Tier 2 -- SP_Crypto_NOP, Fact_SnapshotCustomer.DltStatusID)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Label SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Real_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN CFD_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Total_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Real_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Real_Invested_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN CFD_Invested_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Total_Invested_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN IsBuy SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN EquityReal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN EquityCFD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN InstrumentName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN MifidCategorizationID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN MifidCategorization SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN AccountTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN AccountType SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN PlayerLevelID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN PlayerStatusID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN PlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN IsGermanBaFin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN TRS_NOP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN TRS_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN TRS_Invested_Amount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN EquityTRS SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN CFD_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Total_Units SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN TanganyStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Real_Units_Staking_OptIn SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN Real_Units_Staking_OptOut SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_crypto_nop_cid ALTER COLUMN IsDLTUser SET TAGS ('pii' = 'none');
