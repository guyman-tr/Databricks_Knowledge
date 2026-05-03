-- =============================================================================
-- Databricks ALTER Script: bronze fiktivo.dbo.tblaff_PaymentDetails
-- Generated: 2026-04-30 | tools/uc_bronze/generate_bronze_alters.py
-- Source wiki: knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md
-- Layer: bronze
-- UC Targets (2):
--   main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked
--   main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails
-- =============================================================================

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked SET TBLPROPERTIES (
    'comment' = 'Affiliate payment method configurations storing bank, PayPal, Neteller, Skrill, credit card, and wire transfer details for commission payouts. Source: fiktivo.dbo.tblaff_PaymentDetails on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_PaymentDetails',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN PaymentDetailsID COMMENT 'Primary key. Referenced by tblaff_Affiliates.PaymentDetailsID/PaymentDetails2ID/PaymentDetails3ID and tblaff_PaymentHistory.PaymentDetailsID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN PaymentMethodID COMMENT 'Payment method selector. See Payment Methods: 1=None, 2=PayPal, 3=Wire Transfer, 4=eToro Trading Account, 5=Neteller, 6=Skrill, 7=Webmoney, 8=Credit Card, 9=China Union Pay. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN Amount COMMENT 'Payment amount or limit associated with this payment detail record. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN PayPalAccount COMMENT 'PayPal email address for PayPal payments (PaymentMethodID=2). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WireBeneficiary COMMENT 'Wire transfer beneficiary name (PaymentMethodID=3). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WireBankName COMMENT 'Wire transfer bank name. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WireBankAddress COMMENT 'Wire transfer bank address. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WireBranchNumber COMMENT 'Wire transfer branch/routing number. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WireAccountNumber COMMENT 'Wire transfer account number. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WireSwiftCode COMMENT 'Wire transfer SWIFT/BIC code for international routing. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WireIBAN COMMENT 'Wire transfer IBAN (International Bank Account Number). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN Username COMMENT 'General username field for e-wallet services. Indexed for lookups. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN NetellerAccount COMMENT 'Neteller account ID (PaymentMethodID=5). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN NetellerEmail COMMENT 'Neteller registered email address. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN MoneybookersAccount COMMENT 'Skrill (formerly Moneybookers) account ID (PaymentMethodID=6). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WebMoneyAccount COMMENT 'WebMoney account ID (PaymentMethodID=7). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WebMoneyPurseID COMMENT 'WebMoney purse identifier for specific currency wallets. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN CreditCardNumber COMMENT 'Credit card number (PaymentMethodID=8). MASKED with partial display (all X''s). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN CreditCardExpMonth COMMENT 'Credit card expiration month (01-12). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN CreditCardExpYear COMMENT 'Credit card expiration year (4-digit). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN PayeeID COMMENT 'External payee identifier for payment processor integration. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN IntermediaryBankName COMMENT 'Intermediary/correspondent bank name for international wire transfers. MASKED. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN IntermediaryBankAddress COMMENT 'Intermediary bank address. MASKED. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN IntermediaryAccountNumber COMMENT 'Account number at the intermediary bank. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN IntermediarySwiftCode COMMENT 'SWIFT code of the intermediary bank. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN IntermediaryIBAN COMMENT 'IBAN at the intermediary bank. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN VerifiedBy COMMENT 'FK to dbo.tblaff_User.UserID. Admin user who verified these payment details. NULL = unverified. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN VerifiedOn COMMENT 'Timestamp when payment details were verified. NULL = unverified. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN ChinaUnionPayBeneficiaryFullName COMMENT 'China UnionPay beneficiary full name (PaymentMethodID=9). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN ChinaUnionPayBankName COMMENT 'China UnionPay bank name. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN ChinaUnionPayBankAddress COMMENT 'China UnionPay bank address. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN ChinaUnionPayBranchNumber COMMENT 'China UnionPay branch number. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN ChinaUnionPayAccountNumber COMMENT 'China UnionPay account number. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WireSortCode COMMENT 'UK sort code for domestic wire transfers. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WireBankCountryID COMMENT 'Country of the wire transfer bank. References tblaff_Country for bank location. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked ALTER COLUMN WireRoutingNumber COMMENT 'US ABA routing number for domestic wire transfers. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';

-- ---- UC Target: main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails (business_group=BI_DB) ----
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails SET TBLPROPERTIES (
    'comment' = 'Affiliate payment method configurations storing bank, PayPal, Neteller, Skrill, credit card, and wire transfer details for commission payouts. Source: fiktivo.dbo.tblaff_PaymentDetails on the fiktivo production database, ingested via the Generic Pipeline (Override strategy, 1440-minute refresh). Doc source: Tier 1 wiki (knowledge/ProdSchemas/ExperianceDBs/fiktivo/Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md).'
);

ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails SET TAGS (
    'layer' = 'bronze',
    'source_system' = 'SQL Server',
    'source_database' = 'fiktivo',
    'source_schema' = 'dbo',
    'source_table' = 'tblaff_PaymentDetails',
    'business_group' = 'BI_DB',
    'pipeline' = 'generic_pipeline',
    'doc_source' = 'tier1_wiki',
    'doc_generated' = '2026-04-30',
    'copy_strategy' = 'Override',
    'refresh_minutes' = '1440'
);

-- Column Comments
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN PaymentDetailsID COMMENT 'Primary key. Referenced by tblaff_Affiliates.PaymentDetailsID/PaymentDetails2ID/PaymentDetails3ID and tblaff_PaymentHistory.PaymentDetailsID. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN PaymentMethodID COMMENT 'Payment method selector. See Payment Methods: 1=None, 2=PayPal, 3=Wire Transfer, 4=eToro Trading Account, 5=Neteller, 6=Skrill, 7=Webmoney, 8=Credit Card, 9=China Union Pay. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN Amount COMMENT 'Payment amount or limit associated with this payment detail record. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN PayPalAccount COMMENT 'PayPal email address for PayPal payments (PaymentMethodID=2). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WireBeneficiary COMMENT 'Wire transfer beneficiary name (PaymentMethodID=3). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WireBankName COMMENT 'Wire transfer bank name. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WireBankAddress COMMENT 'Wire transfer bank address. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WireBranchNumber COMMENT 'Wire transfer branch/routing number. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WireAccountNumber COMMENT 'Wire transfer account number. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WireSwiftCode COMMENT 'Wire transfer SWIFT/BIC code for international routing. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WireIBAN COMMENT 'Wire transfer IBAN (International Bank Account Number). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN Username COMMENT 'General username field for e-wallet services. Indexed for lookups. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN NetellerAccount COMMENT 'Neteller account ID (PaymentMethodID=5). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN NetellerEmail COMMENT 'Neteller registered email address. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN MoneybookersAccount COMMENT 'Skrill (formerly Moneybookers) account ID (PaymentMethodID=6). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WebMoneyAccount COMMENT 'WebMoney account ID (PaymentMethodID=7). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WebMoneyPurseID COMMENT 'WebMoney purse identifier for specific currency wallets. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN CreditCardNumber COMMENT 'Credit card number (PaymentMethodID=8). MASKED with partial display (all X''s). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN CreditCardExpMonth COMMENT 'Credit card expiration month (01-12). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN CreditCardExpYear COMMENT 'Credit card expiration year (4-digit). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN PayeeID COMMENT 'External payee identifier for payment processor integration. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN IntermediaryBankName COMMENT 'Intermediary/correspondent bank name for international wire transfers. MASKED. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN IntermediaryBankAddress COMMENT 'Intermediary bank address. MASKED. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN IntermediaryAccountNumber COMMENT 'Account number at the intermediary bank. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN IntermediarySwiftCode COMMENT 'SWIFT code of the intermediary bank. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN IntermediaryIBAN COMMENT 'IBAN at the intermediary bank. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN VerifiedBy COMMENT 'FK to dbo.tblaff_User.UserID. Admin user who verified these payment details. NULL = unverified. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN VerifiedOn COMMENT 'Timestamp when payment details were verified. NULL = unverified. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN ChinaUnionPayBeneficiaryFullName COMMENT 'China UnionPay beneficiary full name (PaymentMethodID=9). (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN ChinaUnionPayBankName COMMENT 'China UnionPay bank name. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN ChinaUnionPayBankAddress COMMENT 'China UnionPay bank address. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN ChinaUnionPayBranchNumber COMMENT 'China UnionPay branch number. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN ChinaUnionPayAccountNumber COMMENT 'China UnionPay account number. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WireSortCode COMMENT 'UK sort code for domestic wire transfers. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WireBankCountryID COMMENT 'Country of the wire transfer bank. References tblaff_Country for bank location. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
ALTER TABLE main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails ALTER COLUMN WireRoutingNumber COMMENT 'US ABA routing number for domestic wire transfers. (Tier 1 - upstream wiki, fiktivo.dbo.tblaff_PaymentDetails)';
-- == LAST EXECUTION ==
-- Timestamp: 2026-05-03 09:51:26 UTC
-- Bronze deploy: fiktivo batch 1
-- ====================
