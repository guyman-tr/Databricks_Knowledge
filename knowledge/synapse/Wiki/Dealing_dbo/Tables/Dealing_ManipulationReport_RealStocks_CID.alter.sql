-- =============================================================================
-- Databricks ALTER Script: Dealing_dbo.Dealing_ManipulationReport_RealStocks_CID
-- Generated: 2026-03-22 | 15-phase pipeline
-- Target: Unity Catalog table comment + column comments (1024 char limit)
-- UC Target: main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid
-- Resolved via: Wiki property table
-- Classification: Standard
-- =============================================================================

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid SET TBLPROPERTIES (
    'comment' = '`Dealing_ManipulationReport_RealStocks_CID` is the **customer-level breakdown** of the daily market manipulation surveillance report for real stocks and ETFs. While `Dealing_ManipulationReport_RealStocks` flags instruments with suspicious aggregate activity, this table identifies the **specific customers (CIDs)** within those instruments whose individual trading patterns are anomalous. **Scope**: Same universe as the parent table — real assets (IsSettled=1), Stocks and ETFs (InstrumentTypeID IN 5,6), manual positions only (MirrorID=0), valid customers in regulated jurisdictions (RegulationID IN 1,2,4). Weekdays only. Each row represents **one customer flagged for anomalous activity in one instrument** on the reporting date. A customer can appear multiple times if they traded multiple flagged instruments. **Flagging criteria**: A customer×instrument combination is flagged when either: 1. The customer accounts for more than **50% of all trades** in that instrument that day (`NumberOfTrades / AllTrades > 0.5`) 2'
);

ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid SET TAGS (
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
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Date COMMENT 'The reporting date. Matches `@dd` parameter. Clustered index key. Weekdays only. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN CID COMMENT 'Customer ID — the flagged customer''s account identifier. FK to DWH_dbo.Dim_Customer. **PII field.** (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN UserName COMMENT 'The customer''s eToro username. **PII field.** Sourced from Dim_Customer or Fact_SnapshotCustomer via #All_Positions_Data. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Country COMMENT 'Customer''s country of residence. From Fact_SnapshotCustomer → Dim_Country. **PII field.** (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Manager COMMENT 'Account manager assigned to this customer. From Fact_SnapshotCustomer → Dim_Manager. **PII field.** Used by compliance team to route flagged customers to their managers. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Regulation COMMENT 'Regulatory entity for this customer. From Dim_Regulation.Name. Values: ''CySEC'', ''FCA'', or other regulators with RegulationID IN (1,2,4). (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Club COMMENT 'Customer''s eToro club/player level (e.g., ''Bronze'', ''Silver'', ''Gold'', ''Platinum'', ''Platinum Plus''). From Dim_PlayerLevel. Used for customer segmentation in compliance review. (Tier 3 — live data)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN InstrumentID COMMENT 'The instrument in which the customer was flagged. FK to DWH_dbo.Dim_Instrument. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN InstrumentDisplayName COMMENT 'User-facing name of the flagged instrument (e.g., ''Mastercard'', ''Aon plc''). From Dim_Instrument.InstrumentDisplayName. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN InstrumentType COMMENT '''Stocks'' or ''ETF''. From Dim_Instrument.InstrumentType. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN NumberOfTrades COMMENT 'Count of positions this customer opened in this instrument on `Date` (positions with OpenDateID = @dd, excluding partial-close children). The customer''s individual trade count — numerator for both flagging thresholds. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN AllTrades COMMENT 'Total count of positions opened by ALL customers in this instrument on `Date` (same filter). Represents the total market activity in this instrument today. Denominator for `PercentOfTotalTrades`. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN AvgDailyOpen COMMENT '30-day trailing average of daily position opens for this instrument, from `#AvgDailyKPIs`. Computed as `OpenVolume30Days / 30`. Denominator for `PercentOfAvg30Days`. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Volume COMMENT 'Total USD trading volume (opens + closes) for this customer in this instrument on `Date`. Sum of Dim_Position.Volume across all positions. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Units COMMENT 'Total shares traded by this customer in this instrument on `Date`. Sum of AmountInUnitsDecimal across positions. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN PercentOfAvg30Days COMMENT '`NumberOfTrades / AvgDailyOpen` — how many times the customer''s trade count exceeds the 30-day average. Value > 2 triggers the second flagging condition. E.g., 2.5 means the customer alone opened 2.5× the typical daily activity for this instrument. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN PercentOfTotalTrades COMMENT '`NumberOfTrades / AllTrades` — the fraction of today''s total instrument trades attributable to this customer. Value > 0.5 triggers the first flagging condition. E.g., 1.0 = customer was the only trader in this instrument today. (Tier 2 — SP_ManipulationReport_RealStocks)';
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN UpdateDate COMMENT 'ETL metadata: `GETDATE()` at time SP ran. Not a business timestamp. (Tier 2 — SP_ManipulationReport_RealStocks)';

-- ---- Column PII Tags ----
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Country SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Manager SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Club SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN InstrumentID SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN InstrumentDisplayName SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN InstrumentType SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN NumberOfTrades SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN AllTrades SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN AvgDailyOpen SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Volume SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN Units SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN PercentOfAvg30Days SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN PercentOfTotalTrades SET TAGS ('pii' = 'none');
ALTER TABLE main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_manipulationreport_realstocks_cid ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
