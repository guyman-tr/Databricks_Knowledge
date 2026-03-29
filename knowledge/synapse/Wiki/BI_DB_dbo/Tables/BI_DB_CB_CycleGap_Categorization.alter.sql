-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_CB_CycleGap_Categorization
-- Generated: 2026-03-29 | scaffold_missing_uc_alter_files.py
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization
-- Resolved via: _generic_pipeline_mapping.json (sql_dp_prod_we)
-- =============================================================================

-- ---- Table Comment ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization SET TBLPROPERTIES (
    'comment' = 'BI_DB_dbo.BI_DB_CB_CycleGap_Categorization'
);

-- ---- Table Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization SET TAGS (
    'source_schema' = 'BI_DB_dbo',
    'source_system' = 'Synapse',
    'pipeline' = 'dwh-semantic-doc',
    'pipeline_version' = 'scaffold-uc-alter'
);

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CID COMMENT 'Customer ID. From BI_DB_Daily_CB_Gaps_All or BI_DB_Outliers_New (UNION). HASH distribution key. Only customers with non-zero gaps or outlier transitions appear. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All + BI_DB_Outliers_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN Date COMMENT 'Calendar date of the gap analysis. SP @date parameter. (Tier 2 — SP_CB_Gap_Categorization, @date)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN DateID COMMENT 'YYYYMMDD integer date key. Computed from @date parameter. Used for DELETE-INSERT scope and history joins. (Tier 2 — SP_CB_Gap_Categorization, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN DailyCBGap COMMENT 'Today''s client balance gap amount in USD. From BI_DB_Daily_CB_Gaps_All.Gap or BI_DB_Outliers_New.[Cycle Calculation] for outlier transitions. ISNULL default 0. A non-zero value means the customer''s actual balance differs from the expected balance. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All.Gap)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN PreviousCBGap COMMENT 'Sum of all historical gaps for this CID before the current date. SUM(BI_DB_Daily_CB_Gaps_All.Gap WHERE DateID < current). ISNULL default 0. Used to determine if today''s gap is new or a continuation. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All historical)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CashoutRequested COMMENT 'Total cashout position amount requested on this date. From BI_DB_CycleGap.COPosAmount. ISNULL(SUM,0). (Tier 2 — SP_CB_Gap_Categorization, BI_DB_CycleGap.COPosAmount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CashoutProcessed COMMENT 'Total cashout amount actually paid/processed on this date. From BI_DB_CycleGap.Payed. ISNULL(SUM,0). (Tier 2 — SP_CB_Gap_Categorization, BI_DB_CycleGap.Payed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN ClosingBalance COMMENT 'Customer''s closing balance on this date in USD. From BI_DB_Daily_CB_Gaps_All.ClosingBalance for regular gaps; from SUM(BI_DB_Client_Balance_CID_Level_New.ClosingBalance) for outlier transitions. ISNULL default 0. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All + BI_DB_Client_Balance_CID_Level_New)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CycleCalculation COMMENT 'The cycle-level gap calculation amount. Represents the gap computed within the current billing/settlement cycle. From BI_DB_Daily_CB_Gaps_All.CycleCalculation or BI_DB_Outliers_New.[Cycle Calculation]. ISNULL(MAX,0). (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All.CycleCalculation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CashoutGap COMMENT 'Gap between cashout requested and processed. From BI_DB_CycleGap.Gap. ISNULL(SUM,0). Non-zero means a cashout is pending or partially fulfilled. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_CycleGap.Gap)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN OutlierTransition COMMENT 'Type of outlier platform transition causing the gap. Values: "Etoro To DLT" (eToro to Digital Ledger Technology), "0" (no outlier), etc. From BI_DB_Outliers_New.Transition. Rows with OutlierTransition IS NOT NULL AND DailyCBGap = 0 are deleted (gap resolved by transition). (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Outliers_New.Transition)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN OutlierCycleCalculation COMMENT 'Cycle gap amount attributable specifically to the outlier transition. From BI_DB_Outliers_New.[Cycle Calculation]. ISNULL(SUM,0). Non-zero means the gap is explained by a platform transition, not a data error. (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Outliers_New.[Cycle Calculation])';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN PreviousPlayerStatus COMMENT 'Customer''s player status on the previous day. From Dim_PlayerStatus.Name via Fact_SnapshotCustomer (prev day). Values: "Normal", "Suspended", "Blocked", etc. Used to detect status transitions that might explain gaps. (Tier 2 — SP_CB_Gap_Categorization, Dim_PlayerStatus.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CurrentPlayerStatus COMMENT 'Customer''s player status on the current day. From Dim_PlayerStatus.Name via Fact_SnapshotCustomer (current day). Compare with PreviousPlayerStatus to detect transitions (e.g., Normal → Suspended). (Tier 2 — SP_CB_Gap_Categorization, Dim_PlayerStatus.Name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN RefundAsChargeback_CB COMMENT 'Chargeback refund amount recorded in the CB (Client Balance) system on this date. SUM of Fact_CustomerAction.Amount where ActionTypeID = 13. ISNULL default 0. When this differs from RefundAsChargeback_Prod, a chargeback timing gap exists. (Tier 2 — SP_CB_Gap_Categorization, Fact_CustomerAction.Amount)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN RefundAsChargeback_Prod COMMENT 'Chargeback refund amount in the production credit history on this date. SUM of etoro_History_Credit.TotalCashChange where CreditTypeID = 16. ISNULL default 0. Differences from RefundAsChargeback_CB indicate system sync delay. (Tier 2 — SP_CB_Gap_Categorization, etoro_History_Credit.TotalCashChange)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN TotalGap COMMENT 'Net gap after chargeback adjustment. Formula: ABS(DailyCBGap) - ABS(PreviousCBGap) + ABS(RefundAsChargeback_CB) - ABS(RefundAsChargeback_Prod). A TotalGap of 0 with non-zero DailyCBGap means the gap is fully explained by chargebacks or previous gaps closing. (Tier 2 — SP_CB_Gap_Categorization, computed)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN Liabilities COMMENT 'Total liabilities from V_Liabilities for this CID on this date. Used in Tableau for negative-liability categorization (e.g., gap explained by negative liability = chargeback loss). (Tier 2 — SP_CB_Gap_Categorization, V_Liabilities.Liabilities)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN Regulation COMMENT 'Regulation name for the customer. Passthrough from BI_DB_Daily_CB_Gaps_All.Regulation or BI_DB_Outliers_New.Regulation. All regulations included (not limited to ASIC). (Tier 2 — SP_CB_Gap_Categorization, BI_DB_Daily_CB_Gaps_All.Regulation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN IsCreditReportValidCB COMMENT 'Credit report validity flag from Fact_SnapshotCustomer. 1 = valid customer for CB reporting. Direct passthrough. (Tier 2 — SP_CB_Gap_Categorization, Fact_SnapshotCustomer.IsCreditReportValidCB)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN IsGermanBaFin COMMENT 'German BaFin flag. 1 if CID appears in V_GermanBaFin for this date. Regulatory overlap indicator. (Tier 2 — SP_CB_Gap_Categorization, V_GermanBaFin)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN UpdateDate COMMENT 'SP execution timestamp. GETDATE(). (Tier 3 — SP_CB_Gap_Categorization, GETDATE())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN DidRegulationTransfer COMMENT 'Flag: 1 if the CID had a regulation transfer on this date (from Fact_RegulationTransfer). Used for deduplication — when 1, the row was filtered out of #dailyGap to prevent double-counting cycle calculations. Added April 2021 to fix rare duplication bug found by Eva and Artemis. (Tier 2 — SP_CB_Gap_Categorization, Fact_RegulationTransfer)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN DailyCBGap SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN PreviousCBGap SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CashoutRequested SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CashoutProcessed SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN ClosingBalance SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CycleCalculation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CashoutGap SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN OutlierTransition SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN OutlierCycleCalculation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN PreviousPlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN CurrentPlayerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN RefundAsChargeback_CB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN RefundAsChargeback_Prod SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN TotalGap SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN Liabilities SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN IsCreditReportValidCB SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN IsGermanBaFin SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cb_cyclegap_categorization ALTER COLUMN DidRegulationTransfer SET TAGS ('pii' = 'none');
