-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.Orders
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.Orders.md
-- Layer: bronze
-- UC Target: main.dealing.bronze_etoro_history_orders
-- =============================================================================

-- ---- UC Target: main.dealing.bronze_etoro_history_orders (business_group=dealing) ----
ALTER TABLE main.dealing.bronze_etoro_history_orders SET TBLPROPERTIES (
    'comment' = 'Archive table for closed pending orders on eToro''s trading platform. When a pending order in Trade.Orders is removed (cancelled by client, cancelled by server, or filled/converted to a position), it is moved here atomically: inserted into History.Orders then deleted from Trade.Orders. Provides a complete historical record of all pending orders and their outcome (cancel reason or conversion type). Source: etoro.History.Orders on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.Orders.md).'
);

ALTER TABLE main.dealing.bronze_etoro_history_orders SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'Orders',
    'business_group' = 'dealing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN OrderID COMMENT 'Pending order identifier, allocated by Internal.GetOrderID sequence (not IDENTITY). Preserved from Trade.Orders on archival. Primary key. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN CID COMMENT 'Customer ID of the order owner. FK (implicit) to Customer.Customer.CID. Nullable for legacy rows where the customer context was lost. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN CurrencyID COMMENT 'Currency denomination of the order amount. FK (implicit) to Dictionary.Currency. Determines the account currency context for the order. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN ProviderID COMMENT 'Price provider/broker that was routing rates for this order. FK (implicit) to Trade.Provider. Only 1 distinct ProviderID in current data. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN OrderTypeID COMMENT 'Type/subtype of the pending order. Observed values: 0 (83%, standard), 15 (15%, likely market order), 4 (1.2%), 6, 5, 7. No FK constraint to a lookup table in this schema. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN InstrumentID COMMENT 'The trading instrument for the order. FK (implicit) to Trade.Instrument. 189 distinct instruments observed. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN Leverage COMMENT 'Leverage multiplier applied to the order (e.g., 1=no leverage, 2=2x, etc.). All recent rows have Leverage=1, consistent with the Free Stocks / no-leverage instrument rollout (FB 53719). (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN Amount COMMENT 'Order size in the account currency (USD for most accounts). Validated > 0 in Trade.OrdersAdd (RAISERROR 60078 if Amount <= 0). Stored as SQL Server money type (4 decimal places). (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN Units COMMENT 'Number of instrument units in the order. Passed directly from Trade.OrdersAdd @Units parameter. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN UnitMargin COMMENT 'Margin required per unit for this order. Integer value likely in cents. Exact derivation is system-internal. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN LotCountDecimal COMMENT 'Order size expressed in lots (decimal precision). Added in FB 47233. Complement to Units for fractional lot handling. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN RateFrom COMMENT 'Exchange rate at which the order was placed (the trigger/limit rate). Uses dbo.dtPrice UDT. For the most recent rows, RateFrom = 124.63 (InstrumentID=1144 price). (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN RateTo COMMENT 'Exchange rate at order close time. Uses dbo.dtPrice UDT. Compared against RateFrom to determine execution quality. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN IsBuy COMMENT 'Direction: 1=Buy (long), 0=Sell (short). Both directions observed in current data. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN ForexResultID COMMENT 'Legacy link to History.ForexResult. Hardcoded to -1 in Trade.OrdersAdd per the comment "ForexResultID is not being used anymore." All recent rows have ForexResultID=-1. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN GameID COMMENT 'Legacy game/contest identifier. Linked to the eToro gaming platform (Game schema). 0 or NULL for all modern trading orders; historically non-zero for contest/game participation. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN SpreadID COMMENT 'Spread configuration identifier applied to this order at placement time. Links to spread pricing rules. 0 for most rows. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN LoginID COMMENT 'Login account identifier associated with the order. Distinct from CID (customer); LoginID represents the specific trading account login. 0 for most rows. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN IsOverWeekend COMMENT 'Whether the order was opened over a weekend (and thus subject to weekend financing charges). Set in Trade.OrdersAdd. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN StopLosAmount COMMENT 'Stop-loss amount threshold in account currency units. Note the column name typo: "StopLos" vs "StopLoss" (consistent across Trade.Orders and History.Orders). 0 = no stop-loss amount set. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN TakeProfitAmount COMMENT 'Take-profit amount threshold in account currency units. 0 = no take-profit amount set. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN MarketSpreadPips COMMENT 'The market spread at order placement, measured in pips. Used for spread cost calculation. 0 for most rows. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN MarketSpreadCents COMMENT 'The market spread at order placement, measured in cents. Alternative spread representation for non-pip instruments. 0 for most rows. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN StopLosRate COMMENT 'The specific rate at which the stop-loss would trigger. Uses dbo.dtPrice UDT. NULL/0 if no stop-loss rate was set. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN TakeProfitRate COMMENT 'The specific rate at which the take-profit would trigger. Uses dbo.dtPrice UDT. NULL/0 if no take-profit rate was set. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN OpenOccurred COMMENT 'UTC timestamp when the order was originally placed (copied from Trade.Orders.OccurredTime at archival). Maps to the creation time in the live order table. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN CloseOcurred COMMENT 'UTC timestamp when the order was closed/archived (set to GETDATE() by Trade.OrdersClose). Note: column name has typo - "CloseOcurred" is missing an ''s'' (consistent with Trade.Orders DDL). (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN TradeRange COMMENT 'Maximum acceptable pip/tick deviation from the requested rate for order execution. Passed from Trade.OrdersAdd @TradeRange. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN ActionTypeID COMMENT 'Why the order was archived. FK WITH CHECK to Dictionary.OrdersActionType. Values: 1=ClientRemove (dominant), 2=ConvertedToPosition, 3=ManualBackOffice, 5=ConvertedToOrderForOpen. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN ParentOrderID COMMENT 'For copy-trading orders: the parent order in the REAL environment that this demo order was following. 0=no parent. ISNULL(@ParentOrderID,0) > 0 check in Trade.OrdersClose triggers Trade.DetachFromParentOrder logic for demo environments. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN LastOpPriceRate COMMENT 'The mid-price (Bid+Ask)/2 from Trade.CurrencyPrice at order-open time, for the order''s provider+instrument. Uses dbo.dtPrice UDT. Enables post-hoc reconstruction of the market price at order submission. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN LastOpPriceRateID COMMENT 'The Trade.CurrencyPrice.PriceRateID for the LastOpPriceRate snapshot. Allows exact rate record to be traced if the price history is retained. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN LastOpConversionRate COMMENT 'The USD conversion rate for the instrument''s quote currency at order-open time. 0 for major instruments (IsMajor=1) and USD-denominated instruments (SellCurrencyID=1). Enables PnL normalization to USD. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN LastOpConversionRateID COMMENT 'The Trade.CurrencyPrice.PriceRateID for the LastOpConversionRate snapshot. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN IsTslEnabled COMMENT 'Whether trailing stop-loss (TSL) was enabled for this order. DEFAULT=0 (disabled). Added in FB 34563. Values: 0=disabled, 1=enabled. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN AmountInUnitsDecimal COMMENT 'The order amount expressed in fractional units (decimal precision). Added in FB 47233 for instruments where amount/units conversion requires decimal precision. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN IsDiscounted COMMENT 'Whether a discounted spread was applied to this order. Added in FB 53719 (Free Stocks). Enables spread discount tracking for eligible customers. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN IsSettled COMMENT 'Whether the order has been settled (funds transferred/reconciled). true=settled (37%), false=not settled (35%), NULL=unknown/legacy (28%). Added in FB 53719. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN SettlementTypeID COMMENT 'The settlement method used. Observed values: 0=unsettled/cash, 1=settled (regular), 5=special settlement type. NULL for legacy rows. Added in FB 53719. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN IsNoStopLoss COMMENT 'Explicitly marks the order as having no stop-loss configured (as opposed to StopLosAmount=0 which could be ambiguous). NULL for older rows predating this column. (Tier 1 - upstream wiki, etoro.History.Orders)';
ALTER TABLE main.dealing.bronze_etoro_history_orders ALTER COLUMN IsNoTakeProfit COMMENT 'Explicitly marks the order as having no take-profit configured (as opposed to TakeProfitAmount=0 which could be ambiguous). NULL for older rows predating this column. (Tier 1 - upstream wiki, etoro.History.Orders)';

