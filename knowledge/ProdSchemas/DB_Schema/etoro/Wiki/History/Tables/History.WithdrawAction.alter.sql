-- =============================================================================
-- Databricks ALTER Script: bronze etoro.History.WithdrawAction
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_history_withdrawaction
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_history_withdrawaction (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction SET TBLPROPERTIES (
    'comment' = 'Immutable audit log of every status change in the withdrawal (cashout) lifecycle - each row records one state transition for a withdrawal request, capturing who acted, what status was set, the financial details, and when it occurred. Source: etoro.History.WithdrawAction on the etoro production database, ingested via the Generic Pipeline (Append strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/History/Tables/History.WithdrawAction.md).'
);

ALTER TABLE main.billing.bronze_etoro_history_withdrawaction SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'History',
    'source_table' = 'WithdrawAction',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Append',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN WithdrawActionID COMMENT 'Auto-incrementing surrogate PK. IDENTITY NOT FOR REPLICATION. Sequential within each withdrawal''s action history. NONCLUSTERED PK on HISTORY filegroup. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN WithdrawID COMMENT 'The withdrawal request this action belongs to. FK to Billing.Withdraw(WithdrawID). Multiple rows per WithdrawID form the complete lifecycle. Included in the NC index on ModificationDate for efficient joins. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN CashoutStatusID COMMENT 'The cashout status recorded at this action. FK to Dictionary.CashoutStatus. See Section 2.2 for full value map. Leading indicator of which lifecycle stage this row captures. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN ManagerID COMMENT 'Back-office manager who performed this action. FK to BackOffice.Manager. NULL = no manager involved (fully automated). 0 = automated system action. > 0 = specific manager''s action (approve, reject, set commission). (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN Commission COMMENT 'Commission amount captured at this action step. Defaults to 0. Set by BackOffice.WithdrawRequestSetCommission when a manager assigns a commission to the withdrawal. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN Approved COMMENT 'Whether this action represents an approval decision: 1=approved, 0=not approved. Approved=1 with ManagerID=0 indicates automated approval. Used with BackOffice.WithdrawRequestApprove. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN ModificationDate COMMENT 'UTC timestamp when this action was recorded. Leading column of NC index IDX_HistoryWithdrawAction_ModificationDate - supports time-range queries for reconciliation and reporting. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN Comment COMMENT 'Human-readable description of this action. Common values: "Initiated by user request", "Automation - Manual Approval". Set by the calling procedure or manager note. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN SessionID COMMENT 'Customer session identifier at the time of the withdrawal action. NULL for automated/system actions. Provides traceability back to the specific user session. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN CashoutReasonID COMMENT 'Reason category for this cashout action. Default value 16 = "Requested by User" (95.8% of rows). Larger values (12, 18, 19) indicate system-generated or special-case reasons. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN ClientPersonalID COMMENT 'Customer personal identification document reference captured at withdrawal time (e.g., for KYC compliance). Added in 2019 (ticket 10864). Typically NULL for automated flows. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN FundingID COMMENT 'References the funding method (payment instrument) used for this withdrawal. Links to the customer''s stored payment method record. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN FundingTypeID COMMENT 'Type of funding/payment method: 1=bank transfer, 2=credit card, 33=crypto/stock redemption (inferred from data). Determines the payment processing pathway. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN Amount COMMENT 'Withdrawal amount in the withdrawal''s currency at time of this action. May differ from the original request amount for partial/reversed withdrawals. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN CurrencyID COMMENT 'Currency of the withdrawal amount. 1=USD in dominant records. References Dictionary/currency lookup. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN Fee COMMENT 'Withdrawal fee charged at time of this action. 0 = fee-free withdrawal (e.g., automatic stock/crypto redemption). Common value: $5 for bank wire withdrawals. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN AccountCurrencyID COMMENT 'Customer account currency at time of action. 1=USD, 2=other currency (observed in data). Used for currency conversion when account currency differs from withdrawal currency. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN ExTransactionID COMMENT 'External payment provider transaction reference number. Populated for auto-processed withdrawals (e.g., crypto/stock redemptions via FundingTypeID=33). NULL for manual/bank wire flows pending external processing. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN WithdrawTypeID COMMENT 'Type classification of the withdrawal: 0=unclassified, 1=automatic/direct (e.g., stock redemption). NULL for certain flow types. Application-defined enum. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
ALTER TABLE main.billing.bronze_etoro_history_withdrawaction ALTER COLUMN FlowID COMMENT 'Processing flow identifier: 0=legacy/unset, 2=automatic stock/crypto redemption flow. NULL for older records or manual processes. Determines which processing pipeline handles the withdrawal. (Tier 1 - upstream wiki, etoro.History.WithdrawAction)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
