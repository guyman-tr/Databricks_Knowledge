-- =============================================================================
-- Databricks ALTER Script: bronze etoro.Billing.FundingPaymentDetailsForWithdraw
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md
-- Layer: bronze
-- UC Target: main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw
-- =============================================================================

-- ---- UC Target: main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw (business_group=billing) ----
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw SET TBLPROPERTIES (
    'comment' = 'Funding-instrument-only projection with country resolution that surfaces payment instrument details and a computed PaymentDetails field for withdrawal investigation, without joining to any withdrawal transaction table. Source: etoro.Billing.FundingPaymentDetailsForWithdraw on the etoro production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/DB_Schema/etoro/Wiki/Billing/Views/Billing.FundingPaymentDetailsForWithdraw.md).'
);

ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'etoro',
    'source_schema' = 'Billing',
    'source_table' = 'FundingPaymentDetailsForWithdraw',
    'business_group' = 'billing',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw ALTER COLUMN FundingID COMMENT 'Payment instrument PK. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.FundingPaymentDetailsForWithdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw ALTER COLUMN FundingTypeID COMMENT 'Payment method type. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.FundingPaymentDetailsForWithdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw ALTER COLUMN ManagerID COMMENT 'Operations manager who created/modified this instrument. NULL=self-registered. (Tier 1 - upstream wiki, etoro.Billing.FundingPaymentDetailsForWithdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw ALTER COLUMN IsBlocked COMMENT '1=instrument blocked. 0=active. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.FundingPaymentDetailsForWithdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw ALTER COLUMN BlockedDescription COMMENT 'Reason for block. NULL if not blocked. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.FundingPaymentDetailsForWithdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw ALTER COLUMN BlockedAt COMMENT 'When blocked. NULL if not blocked. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.FundingPaymentDetailsForWithdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw ALTER COLUMN FundingData COMMENT 'FundingData XML CAST to NVARCHAR(4000). Subject to DDM masking. (Tier 1 - upstream wiki, etoro.Billing.FundingPaymentDetailsForWithdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw ALTER COLUMN IsRefundExcluded COMMENT '1=excluded from automatic refund. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.FundingPaymentDetailsForWithdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw ALTER COLUMN DocumentRequired COMMENT '1=KYC documentation required. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.FundingPaymentDetailsForWithdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw ALTER COLUMN DateCreated COMMENT 'UTC timestamp of instrument registration. From Billing.Funding. (Tier 1 - upstream wiki, etoro.Billing.FundingPaymentDetailsForWithdraw)';
ALTER TABLE main.billing.bronze_etoro_billing_fundingpaymentdetailsforwithdraw ALTER COLUMN PaymentDetails COMMENT 'Computed human-readable payment account identifier from FundingData XML with country name from Dictionary.Country. WireTransfer (type 2) includes country name (unlike FundingPaymentDetailsForDeposit). eToroMoney (type 33) is commented out. Covers more types than the deposit variant: adds 20, 21, 22, 28, 34, 35. (Tier 1 - upstream wiki, etoro.Billing.FundingPaymentDetailsForWithdraw)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 10:35:25 UTC
-- Bronze deploy: etoro batch 1
-- ====================
