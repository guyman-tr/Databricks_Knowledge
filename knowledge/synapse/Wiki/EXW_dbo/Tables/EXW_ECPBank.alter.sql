-- =============================================================================
-- Databricks ALTER Script: EXW_dbo.EXW_ECPBank
-- UC Target: `_Not_Migrated`
-- Classification: Knowledge-only - Synapse function not exported as UC table/TVF
-- under gold_sql_dp_prod_we_* naming. No executable ALTER statements.
-- When a UC mapping exists, replace this file via generate-alter-dwh.
-- =============================================================================

-- Business summary (from wiki section 1, truncated):
-- EXW_ECPBank stores ECP Bank''s card settlement records for all Simplex-facilitated crypto purchases on eToro Wallet. ECP Bank was the acquiring bank (payment processor) that sat between Simplex and the card networks (Visa/Mastercard), handling the actual card charging and settlement for the eToro Gibraltar merchant account (merchant_no_ = 172000000006524 / "Simplex_etorox"). Each row represents one settled card transaction: 99.9% are purchases, with 25 credit refunds. Settlement currencies are GBP (46%) and EUR (54%). The `uti` field matches back to `EXW_SimplexMapping.uti` for approved transactions, and `acquirer_ref_` (the ARN) matches `EXW_SimplexChargebacks.ARN` for chargeback dispute tracing. The table contains 113,146 rows covering posting dates 20190201 to 20220920. It was loaded via Fivetran (evidenced by `_row`, `_fivetran_deleted`, `_fivetran_synced` columns) and is frozen sinc

