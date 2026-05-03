-- =============================================================================
-- Databricks ALTER Script: bronze MoneyBusDB.MoneyBus.TransferLimits
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md
-- Layer: bronze
-- UC Target: main.billing.bronze_moneybusdb_moneybus_transferlimits
-- =============================================================================

-- ---- UC Target: main.billing.bronze_moneybusdb_moneybus_transferlimits (business_group=billing) ----
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits SET TBLPROPERTIES (
    'comment' = 'Configuration table defining minimum and maximum transfer amounts allowed between account types, with optional filtering by country, player level, flow, and currency. Source: MoneyBusDB.MoneyBus.TransferLimits on the MoneyBusDB production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/PaymentsDBs/MoneyBusDB/Wiki/MoneyBus/Tables/MoneyBus.TransferLimits.md).'
);

ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'MoneyBusDB',
    'source_schema' = 'MoneyBus',
    'source_table' = 'TransferLimits',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN CountryID COMMENT 'Country filter for the limit rule. NULL means the rule applies to all countries. When set, restricts this limit to users in the specified country. Currently all rows have NULL (global rules). (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.TransferLimits)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN DebitAccountTypeID COMMENT 'Source account type being debited: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See Account Type. (Dictionary.AccountTypes). Defines the "from" side of the transfer direction. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.TransferLimits)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN CreditAccountTypeID COMMENT 'Destination account type being credited: 1=Trading, 2=Options, 3=IBAN, 4=MoneyFarm. See Account Type. (Dictionary.AccountTypes). Defines the "to" side of the transfer direction. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.TransferLimits)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN MinAmount COMMENT 'Minimum transfer amount allowed in the specified currency. Currently set to 1 for all rules - prevents zero-amount transfers. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.TransferLimits)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN MaxAmount COMMENT 'Maximum transfer amount allowed in the specified currency. Ranges from 50,000 (flow-specific restriction) to 100,000,000 (default). The application rejects transfers exceeding this. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.TransferLimits)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN CurrencyID COMMENT 'Currency the limit applies to. Each currency requires its own limit row because acceptable ranges differ by currency denomination. Maps to an external currency reference. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.TransferLimits)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN PlayerLevelID COMMENT 'Player/user tier level filter. NULL means the rule applies to all levels. When set, allows different transfer limits for VIP vs. standard users. Currently all rows have NULL (uniform limits). (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.TransferLimits)';
ALTER TABLE main.billing.bronze_moneybusdb_moneybus_transferlimits ALTER COLUMN FlowID COMMENT 'Business flow identifier. NULL means "default for all flows." When specified (e.g., FlowID=2), applies a more specific limit that overrides the default. One row uses FlowID=2 with a lower MaxAmount, indicating a restricted flow type. (Tier 1 - upstream wiki, MoneyBusDB.MoneyBus.TransferLimits)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:41:14 UTC
-- Bronze deploy: MoneyBusDB batch 1
-- ====================
