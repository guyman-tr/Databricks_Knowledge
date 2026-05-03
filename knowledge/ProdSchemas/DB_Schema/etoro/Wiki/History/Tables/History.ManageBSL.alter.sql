-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.ManageBSL
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ManageBSL.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_managebsl
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_managebsl (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_managebsl SET TBLPROPERTIES (
    'comment' = 'Archive of processed Bonus Safety Level (BSL) alert messages - records moved from Trade.ManageBSL after acknowledgment, preserving the complete lifecycle (warning, block, unblock) of BSL events for bonus-holding customer accounts. Source: etoro.History.ManageBSL on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.ManageBSL.md).'
);

ALTER TABLE main.general.bronze_etoro_history_managebsl SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'ManageBSL',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN ID COMMENT 'The BSL message ID, copied from Trade.ManageBSL.ID via DELETE...OUTPUT INTO. Matches the IDENTITY value assigned when the message was created in the active queue. Clustered PK here. Not an IDENTITY in this table (values are carried over from the source). (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN MessageType COMMENT 'BSL action type: 1=Warning (equity approaching threshold, customer notified), 2=Block (equity breached threshold, account blocked from new positions), 3=Unblock (account restored). The archival eligibility rules differ by type: Block/Unblock (2,3) are archived immediately after ack; Warning (1) is archived only after 24 hours. (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN WarningType COMMENT 'Sub-classification within the MessageType. Provides granular warning levels or trigger categories (e.g., different percentage thresholds below which warnings are triggered). Exact values and meanings are defined in the BSL engine application code. (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN CID COMMENT 'Customer ID of the account that triggered the BSL event. References Customer.CustomerStatic.CID (no FK enforced). The financial snapshot columns capture this customer''s account state at the moment the alert was generated. (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN BonusCredit COMMENT 'The total bonus credit amount in the customer''s account at time of the BSL alert. Money type (decimal(19,4)). This is the "liability" the BSL system is protecting - the bonus that could be lost if equity falls to zero. (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN RealizedEquity COMMENT 'The customer''s realized equity (cash balance + realized P&L from closed positions) at time of alert. Does not include open position P&L. Compared against BonusCredit to determine BSL breach status. (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN UnRealizedEquity COMMENT 'The customer''s unrealized P&L from open positions at time of alert. Combined with RealizedEquity to give total account equity. Negative values indicate open positions currently in loss. (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN BSLRealFunds COMMENT 'The calculated "real funds" value used by the BSL engine for threshold comparison. Represents the portion of equity attributable to real (non-bonus) funds. The formula accounts for the relationship between equity, bonus, and realized/unrealized components. (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN TimeMessageInsertedToQueue COMMENT 'UTC timestamp when the BSL message was first inserted into Trade.ManageBSL (the active queue). This is the moment the BSL engine detected the threshold breach. DEFAULT getutcdate() applied at source insert time; copied verbatim here. (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN TimeMessageWasRecieved COMMENT 'UTC timestamp when the BSL consumer service dequeued and received this message for processing. NULL if the message was never dequeued (unlikely for archived messages). The gap between InsertedToQueue and Recieved measures BSL processing latency. Note: column name has a typo ("Recieved" not "Received"). (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN TimeMessageWasAck COMMENT 'UTC timestamp when the BSL consumer service acknowledged the message (confirmed action taken). NOT NULL for all rows in this archive table (archival eligibility requires non-null ack). Gap between Recieved and Ack measures action execution time. (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
ALTER TABLE main.general.bronze_etoro_history_managebsl ALTER COLUMN ExecutionID COMMENT 'Links this BSL event to a specific BSL engine execution run (Trade.CheckBSL @ExecutionID). Multiple BSL messages may share the same ExecutionID if they were generated in the same BSL engine pass. NULL for messages created outside an explicit execution context. (Tier 1 - upstream wiki, etoro.History.ManageBSL)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
