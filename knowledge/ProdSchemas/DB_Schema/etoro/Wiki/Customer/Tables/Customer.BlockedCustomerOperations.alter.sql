-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Customer.BlockedCustomerOperations
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.BlockedCustomerOperations.md
-- Layer: bronze
-- UC Target: main.general.bronze_etoro_customer_blockedcustomeroperations
-- =============================================================================

-- ---- UC Target: main.general.bronze_etoro_customer_blockedcustomeroperations (business_group=general) ----
ALTER TABLE main.general.bronze_etoro_customer_blockedcustomeroperations SET TBLPROPERTIES (
    'comment' = 'Active trading restrictions table storing per-customer operation blocks, managed by the Trading Restriction Service and consumed by real-time trade execution to enforce account-level limitations. Source: etoro.Customer.BlockedCustomerOperations on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Customer/Tables/Customer.BlockedCustomerOperations.md).'
);

ALTER TABLE main.general.bronze_etoro_customer_blockedcustomeroperations SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Customer',
    'source_table' = 'BlockedCustomerOperations',
    'business_group' = 'general',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.general.bronze_etoro_customer_blockedcustomeroperations ALTER COLUMN CID COMMENT 'Customer ID - identifies which customer is restricted. Part of composite PK. References CID in Customer.CustomerStatic. (Tier 1 - upstream wiki, etoro.Customer.BlockedCustomerOperations)';
ALTER TABLE main.general.bronze_etoro_customer_blockedcustomeroperations ALTER COLUMN OperationTypeID COMMENT 'The trading operation being blocked: 1=CopyUser, 2=Copied, 3=PublicPortfolioVisible, 4=Trading, 5=PositionOpen, 6=ManualPositionClose, 7=ManualOpenExitOrder, 8=OpenEntryOrder, 9=OpenOrder, 10=OpenOpen, 11=ManualUnregisterMirror, 12=ManualEditSL, 13=ManualEditTP, 14=ManualEditTSL, 15=ManualCloseEntryOrder, 16=ManualCloseExitOrder, 17=CloseOrder, 18=ManualEditMirrorSL, 19=ManualEditMirrorSLPercentage, 20=ManualPauseCopy, 21=ManualExecutionBlock. FK to Dictionary.OperationTypesForBlocking. (Source: Trading Restriction Service TDD - Confluence TRAD) (Tier 1 - upstream wiki, etoro.Customer.BlockedCustomerOperations)';
ALTER TABLE main.general.bronze_etoro_customer_blockedcustomeroperations ALTER COLUMN Occurred COMMENT 'UTC timestamp when the block was applied. Default = GETUTCDATE(). Used in History.BlockedCustomerOperations as BlockStart for audit trails. (Tier 1 - upstream wiki, etoro.Customer.BlockedCustomerOperations)';
ALTER TABLE main.general.bronze_etoro_customer_blockedcustomeroperations ALTER COLUMN BlockReasonID COMMENT 'Why this block was applied: 1=RequestedByBOAdmin, 2=HighRiskScore, 3=EmployeeAccount, 4=OPT_OUT, 5=OPT_IN, 6=NotVerified, 7=Verified, 8=RequestedByKYC, 9=Liquidation, 10=LiquidationRemove, 11=ManualExecutionBlock, 12=ManualExecutionBlockRemove, 13=AumLimit, 14=Regulation, 15=NonResponsive, 16=AbusiveTrading, 17=LowEquity, 18=BreachComunityGuidelines, 19=NonLaunchedCopyFund, 20=NotAcceptUsersCopyFund, 21=AumLimitPopular, 22=MaxCopiers, 23=MaxAumPerTier. FK to Dictionary.BlockUnBlockReason. (Source: Trading Restriction Service TDD + Dictionary.BlockUnBlockReason.md) (Tier 1 - upstream wiki, etoro.Customer.BlockedCustomerOperations)';
ALTER TABLE main.general.bronze_etoro_customer_blockedcustomeroperations ALTER COLUMN RequestGUID COMMENT 'Unique identifier from the originating restriction request. Set by the Trading Restriction Service application and passed through Trade.CustomerRestrictionsSet. Used for idempotency, distributed tracing, and audit correlation. NULL for older blocks predating GUID tracking. (Tier 1 - upstream wiki, etoro.Customer.BlockedCustomerOperations)';

