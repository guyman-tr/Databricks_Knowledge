-- =============================================================================
-- Databricks ALTER Script: DWH_dbo.Fact_Deposit_Fees
-- Generated: 2026-05-14 15:04:32 UTC | _tmp_phase1_remediation.py
-- UC Target: main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees
-- =============================================================================

-- ---- Table Comment ----
-- (table comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN CID COMMENT 'Customer ID. Primary customer identifier. CLUSTERED INDEX key for customer-centric query access. Foreign key pattern to customer dimension. (Tier 2 - SP_Fact_Deposit_Fees_DL_To_Synapse passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositID COMMENT 'Billing deposit identifier. Links to Billing.Deposit in production and to DWH_dbo.Fact_BillingDeposit in DWH. Use as the canonical deposit row identifier. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN AffiliateID COMMENT 'Affiliate partner identifier at time of deposit. Links to DWH_dbo.Dim_Affiliate. NULL for organic (non-affiliate) customers. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN OldPaymentID COMMENT 'Legacy payment system identifier. Historical key from pre-migration payment processing. [UNVERIFIED] (Tier 4 - inferred from column name)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN FundingID COMMENT 'Funding method type integer (19 types observed). Numeric FK to funding type classification. Corresponds to FundingMethod text label. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN UserName COMMENT 'Customer username (display name). PCI-safe (no card data). [UNVERIFIED] (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositStatus COMMENT 'Final deposit status at last load. Values (live): Approved(99.9%), Refund, Chargeback, ChargebackReversal, Decline, ReversedDeposit, RefundReversal, New, Technical. (Tier 3 - live data sampling)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN StatusModificationTime COMMENT 'Timestamp of last status change. Used to derive ModificationDateID. Primary ETL filter timestamp. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN ModificationDateID COMMENT 'ETL-computed date key: convert(int, convert(varchar, dateadd(day,datediff(day,0,StatusModificationTime),0), 112)). Format: YYYYMMDD. Efficient date-range filter key. (Tier 2 - SP_Fact_Deposit_Fees_DL_To_Synapse computed column)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositTime COMMENT 'Original deposit submission timestamp. Range in DWH: 2020-03-05 to 2024-06-30. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN FirstApprovedTime COMMENT 'Timestamp of first approval status. For re-approved deposits, this captures the initial approval. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositValueDate COMMENT 'Value date for accounting purposes - when funds are formally recognized. May differ from DepositTime for wire transfers where settlement takes 1-3 business days. (Tier 4 - Confluence, Deposit issues)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN UpdateDate COMMENT 'ETL load timestamp: getdate() at time SP ran. Range: 2023-11-28 to 2024-07-01. (Tier 2 - SP_Fact_Deposit_Fees_DL_To_Synapse computed: getdate())';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositAmount COMMENT 'Deposit amount in the customer''s currency (see Currency column). Primary deposit value. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Currency COMMENT 'Customer''s deposit currency code (USD, EUR, GBP, CLP, etc.). (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositCollarAmount COMMENT 'Collar-adjusted deposit amount used in fee calculation. When exchange rate fluctuation limits (collars) apply, this caps the fee base to protect against rate volatility. (Tier 4 - Confluence, Conversion fee Revenue Calculation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN BaseExchangeRate COMMENT 'Market exchange rate BEFORE fee deduction. The PIP fee is embedded as a spread: BaseExchangeRate minus FeeinPIPs/10000 = ExchangeRate. Used in the formula: PIP_in_USD = DepositAmount * (BaseExchangeRate - ExchangeRate). (Tier 4 - Confluence, Deposit conversion fee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN ExchangeRate COMMENT 'Exchange rate AFTER fee deduction (BaseExchangeRate minus PIP spread). This is the actual rate applied to the customer''s deposit - the fee is embedded in this rate difference. (Tier 4 - Confluence, Deposit conversion fee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN FeeinPIPs COMMENT 'Deposit fee expressed in PIPs (price interest points). A pip is 1/10000 of the base currency unit. Zero for fee-free deposits. (Tier 2 - SP_Fact_Deposit_Fees_DL_To_Synapse + BackOffice.BillingDepositsPCIVersion changelog: OPSE-236)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN PIPsinUSD COMMENT 'USD monetary value of FeeinPIPs at deposit exchange rate. NULL for some zero-fee rows. (Tier 2 - SP passthrough + BackOffice changelog: OPSE-236)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN TotalRollbackDollarAmount COMMENT 'Total USD amount rolled back for chargeback/refund scenarios. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN TotalRollbackAmount COMMENT 'Total rollback amount in deposit currency. (Tier 2 - SP passthrough)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN FundingMethod COMMENT 'Payment method name. Values (live): CreditCard(63.3%), PayPal(17.6%), eToroMoney(12.8%), iDEAL, Giropay, WireTransfer, PWMB, Trustly, ACH, MoneyBookers, Przelewy24, POLI, Neteller, RapidTransfer, OpenBanking, EtoroOptions, Payoneer, OnlineBanking, TestDeposit. (Tier 3 - live data distribution)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Depot COMMENT 'Payment gateway/processor name (WorldPay, Checkout, Tribe, IXOPAY-Nuvei, etc.). Each FundingMethod may route through multiple depots. (Tier 3 - live data sampling)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN MID COMMENT 'Merchant ID code for the payment processor. Used for settlement reconciliation. (Tier 2 - SP passthrough; BackOffice changelog: MIMOPS-4487)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN MIDName COMMENT 'Human-readable MID description. Added per MIMOPS-4487 (select mid description as mid name instead of regulation name). (Tier 2 - BackOffice SP changelog MIMOPS-4487)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN PaymentDetails COMMENT 'Additional payment-method-specific details (e.g., iDEAL bank name, Przelewy24 reference, Trustly account info). Content varies by FundingMethod. (Tier 2 - BackOffice SP changelog MIMOPS-2100, MIMOPS-2825)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN ExternalTransactionID COMMENT 'Payment processor''s own transaction reference ID. Used for cross-system reconciliation. (Tier 2 - SP passthrough; MIMOPSA-14499)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN TransactionID_Internal COMMENT 'eToro internal transaction reference. [UNVERIFIED] (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN ResponseCode COMMENT 'Payment processor response code (acquirer response). Used in decline/error analysis. (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN TransactionResponse COMMENT 'Full processor response message or description. (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Threedsresponse COMMENT '3D Secure authentication result (e.g., Unspecified, Authenticated, NotRequired). From Dictionary.ThreeDsResponseTypes. (Tier 3 - live data sampling)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Threedsparameters COMMENT 'Raw 3DS authentication parameters/payload from payment processor. PCI-redacted. (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositRiskStatus COMMENT 'Risk management status assigned to the deposit. From Dictionary.RiskManagementStatus. (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Riskstatus COMMENT 'Additional risk status field (distinct from DepositRiskStatus - may be processor-side risk score). (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN RollbackReason COMMENT 'Reason for chargeback/refund/rollback. Values include: Fraud, etc. Added per MIMOPSA-09421. (Tier 2 - BackOffice SP changelog MIMOPSA-09421 + live data)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN CountryByRegIP COMMENT 'Customer''s country determined by registration IP address. Used for regulatory routing and conversion fee schedule selection (fees vary by country/currency). (Tier 4 - Confluence, Conversion fee Revenue Calculation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN CustomerStatus COMMENT 'Customer account status at time of deposit. [UNVERIFIED] (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN CustomerLevel COMMENT 'Customer tier/level at time of deposit (e.g., Silver, Gold, Platinum). [UNVERIFIED] (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN AccountManager COMMENT 'Assigned account manager name at time of deposit. [UNVERIFIED] (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Regulation COMMENT 'Regulatory jurisdiction for this customer''s account. Values (live): CySEC(53.5%), FCA(30.8%), ASIC&GAML(7.7%), FinCEN+FINRA(3.8%), FSA Seychelles(3.7%), FSRA, ASIC, FinCEN, BVI, eToroUS. (Tier 3 - live data distribution)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN WhiteLabel COMMENT 'White-label brand for this customer. Predominantly "eToro". (Tier 3 - live data sampling)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Brand COMMENT 'Payment card network brand (Visa, Master Card, Maestro, American Express, etc.). Corresponds to Dim_CardType.CarTypeName. (Tier 3 - live data sampling)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN CardCategory COMMENT 'Card category classification (Debit, Credit, Prepaid). Conversion fee schedule differs between Debit/Credit Cards and other payment methods per eToro fee table. (Tier 4 - Confluence, Conversion fee Revenue Calculation)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN FTD COMMENT 'First Time Deposit flag. Identifies whether this is the customer''s first ever deposit. FTD is a key business event - triggers affiliate commission payouts and customer lifecycle classification. (Tier 4 - Confluence, Deposit conversion fee)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Funnel COMMENT 'Customer acquisition funnel label. From Dictionary.Funnel. [UNVERIFIED] (Tier 4 - inferred)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositType COMMENT 'Deposit type classification. NULL for most rows in live data. [UNVERIFIED] (Tier 4 - inferred)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN CID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN AffiliateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN OldPaymentID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN FundingID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN UserName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN StatusModificationTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN ModificationDateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN FirstApprovedTime SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositValueDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositCollarAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN BaseExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN ExchangeRate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN FeeinPIPs SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN PIPsinUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN TotalRollbackDollarAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN TotalRollbackAmount SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN FundingMethod SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Depot SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN MID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN MIDName SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN PaymentDetails SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN ExternalTransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN TransactionID_Internal SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN ResponseCode SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN TransactionResponse SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Threedsresponse SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Threedsparameters SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositRiskStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Riskstatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN RollbackReason SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN CountryByRegIP SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN CustomerStatus SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN CustomerLevel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN AccountManager SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Regulation SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN WhiteLabel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Brand SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN CardCategory SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN FTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN Funnel SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_dwh_dbo_fact_deposit_fees ALTER COLUMN DepositType SET TAGS ('pii' = 'none');

