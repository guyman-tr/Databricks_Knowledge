-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.BlockedCustomerOperations
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.BlockedCustomerOperations.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_history_blockedcustomeroperations
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_history_blockedcustomeroperations (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_history_blockedcustomeroperations SET TBLPROPERTIES (
    'comment' = 'Completed-block archive: each row records one trading restriction that was lifted, capturing the full block interval (start, end), the operation restricted, and the reason it was applied. Source: etoro.History.BlockedCustomerOperations on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.BlockedCustomerOperations.md).'
);

ALTER TABLE main.general.bronze_etoro_history_blockedcustomeroperations SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'BlockedCustomerOperations',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_history_blockedcustomeroperations ALTER COLUMN CID COMMENT 'Customer ID of the customer whose operation was blocked. Implicit FK to Customer.Customer. PK component - with OperationTypeID and BlockStart, uniquely identifies one block interval. (Tier 1 - upstream wiki, etoro.History.BlockedCustomerOperations)';
ALTER TABLE main.general.bronze_etoro_history_blockedcustomeroperations ALTER COLUMN OperationTypeID COMMENT 'The trading operation that was blocked. FK to Dictionary.OperationTypesForBlocking(OperationTypeID). Values in production history: 1=Copy User, 2=Copied, 3=Public Portfolio Visible, 11=Manual Unregister Mirror, 21=Manual Execution Block, 23=SmartCopyUnblock. Full lookup: 1=Copy User, 2=Copied, 3=Public Portfolio Visible, 4=Trading, 5=Position Open, 6=Manual Position Close, 7=Manual Open Exit Order, 8=Open Entry Order, 9=Open Order, 10=Open Open, 11=Manual Unregister Mirror, 12=Manual Edit SL, 13=Manual Edit TP, 14=Manual Edit TSL, 15=Manual Close Entry Order, 16=Manual Close Exit Order, 17=Order Close, 18=Manual Edit Mirror SL, 19=Manual Edit Mirror SL Percentage, 20=Manual Pause Copy, 21=Manual Execution Block, 22=Internal Instruments Allowed, 23=SmartCopyUnblock, 24=Detach Position. PK component. (Tier 1 - upstream wiki, etoro.History.BlockedCustomerOperations)';
ALTER TABLE main.general.bronze_etoro_history_blockedcustomeroperations ALTER COLUMN BlockStart COMMENT 'UTC timestamp when the block was first applied. Copied from Customer.BlockedCustomerOperations.Occurred when the block is lifted. PK component. (Tier 1 - upstream wiki, etoro.History.BlockedCustomerOperations)';
ALTER TABLE main.general.bronze_etoro_history_blockedcustomeroperations ALTER COLUMN BlockEnd COMMENT 'UTC timestamp when the block was lifted. Set to GETUTCDATE() by Customer.OperationUnBlockForCID at the moment of unblocking. Duration of restriction = BlockEnd - BlockStart. Default value in DDL is getutcdate() but in practice always set explicitly by the unblock procedure. (Tier 1 - upstream wiki, etoro.History.BlockedCustomerOperations)';
ALTER TABLE main.general.bronze_etoro_history_blockedcustomeroperations ALTER COLUMN BlockReasonID COMMENT 'The reason the block was applied. FK to Dictionary.BlockUnBlockReason(ID). 26 possible values: 1=Requested by BO Admin, 2=High Risk Score, 3=Employee Account, 4=OPT OUT, 5=OPT IN, 6=Not Verified, 7=Verified, 8=Requested by KYC, 9=Liquidation, 10=Liquidation Remove, 11=Manual Execution Block, 12=Manual Execution Block Remove, 13=AUM Limit, 14=Regulation, 15=Non-responsive, 16=Abusive trading, 17=Low Equity, 18=Breach of community Guidelines, 19=Non-launched CopyFund, 20=CopyFund not accepting new investors, 21=Max ($30M AUM) Popular Investors, 22=Max copiers / investors reached, 23=Max AUM per tier, 24=UkCryptoAllowed, 25=CfdAllowed, 26=GermanyCryptoAllowed. (Dictionary.BlockUnBlockReason) (Tier 1 - upstream wiki, etoro.History.BlockedCustomerOperations)';
ALTER TABLE main.general.bronze_etoro_history_blockedcustomeroperations ALTER COLUMN UnBlockReasonID COMMENT 'Intended to capture why the block was lifted, but always equals BlockReasonID due to a known data quality issue in Customer.OperationUnBlockForCID: "because no have data in Customer.BlockedCustomerOperations at field UnBlockReasonID then I put BlockReasonID!" Do not rely on this field to understand unblock reason - it mirrors BlockReasonID. FK to Dictionary.BlockUnBlockReason(ID). (Tier 1 - upstream wiki, etoro.History.BlockedCustomerOperations)';
ALTER TABLE main.general.bronze_etoro_history_blockedcustomeroperations ALTER COLUMN BlockRequestGUID COMMENT 'GUID correlating this block event to an external system request (e.g., a risk service call or back-office action that triggered the block). Nullable - not all blocks originate from external GUID-tracked requests. (Tier 1 - upstream wiki, etoro.History.BlockedCustomerOperations)';
ALTER TABLE main.general.bronze_etoro_history_blockedcustomeroperations ALTER COLUMN UnBlockRequestGUID COMMENT 'GUID correlating the unblock event to the external system request that triggered it. Nullable - populated only when the unblock was initiated by an external system that provided a request GUID. (Tier 1 - upstream wiki, etoro.History.BlockedCustomerOperations)';

