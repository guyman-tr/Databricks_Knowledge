-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_Trading_Platform
-- Generated: 2026-05-14 14:29:17 UTC | _tmp_create_missing_alters.py
-- Target: Unity Catalog column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform
-- =============================================================================

-- ---- Table Comment ----
-- (table-level comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN DateID COMMENT 'Ledger business date partition key duplicated from `@date`. `CAST(CONVERT(varchar(8),@date,112) AS int)` seeded into `#depositsTP`/`#cashoutTP`, carried through UNION. DELETE partition uses same `@dateID`. (Tier 2 - SP_DDR_Fact_MIMO_Trading_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN Date COMMENT 'Calendar counterpart to `DateID`; INSERT selects `@date`. (Tier 2 - SP_DDR_Fact_MIMO_Trading_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN RealCID COMMENT 'Global Real Customer Identifier on the ledger row (`fca.RealCID`). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN MIMOAction COMMENT 'Stable label `''Deposit''` or `''Withdraw''` from UNION halves. (Tier 2 - SP_DDR_Fact_MIMO_Trading_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN OrigIdentifier COMMENT 'Literal discriminator `''DepositID''` vs `''WithdrawPaymentID''` aligning `TransactionID` grain. (Tier 2 - SP_DDR_Fact_MIMO_Trading_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN TransactionID COMMENT '`DepositID` for deposits (`ActionTypeID` 7/44) OR `WithdrawPaymentID` for withdraw rows (`ActionTypeID` 8/45). ROW_NUMBER dedupes collisions. (Tier 2 - Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN AmountUSD COMMENT '`fca.Amount` from `Fact_CustomerAction WHERE ActionTypeID IN (7,44)` (deposits) or `IN (8,45)` (withdrawals) at `@dateID`. (Tier 2 - Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN AmountOrigCurrency COMMENT 'Deposit: `fbd.Amount`. Withdraw: `COALESCE(bddwf.Amount, ROUND( ROUND(fbw.Amount_WithdrawToFunding,6) / NULLIF(ROUND(fbw.ExchangeRate,6),0), 6))` with joins defined in `#cashoutTP`. (Tier 2 - Fact_BillingDeposit / Fact_BillingWithdraw)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN FundingTypeID COMMENT 'Deposit: `fbd.FundingTypeID`. Withdraw: `fbw.FundingTypeID_Funding`. Type of funding instrument powering the payout leg. Deposit description reference: Fact_BillingDeposit column #17 semantics. Withdraw description reference: `FundingTypeID_Funding` semantics in `Fact_BillingWithdraw`. (Tier 2 - Fact_BillingDeposit / Billing.Funding)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN CurrencyID COMMENT 'Deposit: `fbd.CurrencyID` - “Currency of the deposit amount…” (Billing upstream). Withdraw: `fbw.ProcessCurrencyID` - “Currency used for the actual payment processing…” (Billing.WithdrawToFunding upstream). Same column merges both semantics via SP branch. (Tier 1 - upstream wiki, Billing.Deposit / Billing.WithdrawToFunding)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN Currency COMMENT 'Ticker symbol (`dc.Abbreviation`) joined on `CurrencyID`/`ProcessCurrencyID`. `"USD","EUR"` forex; equities/crypto codes per dictionary. Passthrough from `Dim_Currency`. (Tier 1 - Dictionary.Currency)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsFTD COMMENT 'Deposits: `CASE WHEN dc1.FTDTransactionID = fca.DepositID THEN 1 ELSE 0` with `JOIN Dim_Customer dc1 … FTDPlatformID=1`. Withdraw half forces `IsFTD=0` inside UNION despite `fca.IsFTD` select in `#cashoutTP`. INSERT `ISNULL`; late recoveries via `UPDATE` against `Dim_Customer` FTD linkage (`DateID>=20250901`). (Tier 2 - SP_DDR_Fact_MIMO_Trading_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsInternalTransfer COMMENT '`CASE WHEN FundingTypeID = 33 THEN 1 ELSE 0` (deposit branch on `fbd.FundingTypeID`; withdraw branch on `fbw.FundingTypeID_Funding`). Mirrors IBAN/quick-transfer interplay described in changelog. (Tier 2 - SP_DDR_Fact_MIMO_Trading_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsRedeem COMMENT '**Transfer-to-coin / transfercoin flag on Money-Out.** Withdraw leg reads `fca.IsRedeem` with `WHERE fca.ActionTypeID IN (8,45)`. Deposit UNION hard-codes literal `0` after `#depositsTP` seeded `NULL`. INSERT applies `ISNULL(IsRedeem,0)`. Interpret `1` as customer movement from TP fiat wallet into on-chain/crypto custody - not “redeem to bank.” Cross-surface: revenue TVF **`Function_Revenue_TransferCoinFee`** documents `Fact_CustomerAction` rows **`ActionTypeID = 30` AND `IsRedeem = 1`** for TransferCoinFee commissions tied to transfercoin redemption. (Tier 2 - Fact_CustomerAction)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN UpdateDate COMMENT 'ETL watermark `GETDATE()` on INSERT. (Tier 2 - SP_DDR_Fact_MIMO_Trading_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsIBANTrade COMMENT 'Deposit: `CASE WHEN fca.ActionTypeID = 44 THEN 1 ELSE 0`; Withdraw: `CASE WHEN fca.ActionTypeID = 45 THEN 1 ELSE 0`. Flags sweep-style IBAN internal deposit/withdraw events. (Tier 2 - SP_DDR_Fact_MIMO_Trading_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsCryptoToFiat COMMENT 'Explicit literal `0` - reserved column (C2F captured on other DDR MIMO siblings). `INSERT SELECT … , 0 AS IsCryptoToFiat`. (Tier 2 - SP_DDR_Fact_MIMO_Trading_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsRecurring COMMENT '`1=deposit is part of a recurring schedule (OUTER APPLY on Billing.RecurringDeposit). 0=one-time deposit.` carries only on deposit UNION; `''Withdraw''` half injects literal `0`. Final `INSERT` uses `ISNULL(t.IsRecurring,0)`. (Tier 2 - SP_Fact_BillingDeposit_DL_To_Synapse)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsIBANQuickTransfer COMMENT 'Internal transfer discriminator `CASE WHEN fca.MoveMoneyReasonID = 6 THEN 1 ELSE 0` on both halves (SP changelog `20250611`). (Tier 2 - SP_DDR_Fact_MIMO_Trading_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN Fact_CustomerAction COMMENT 'Authoritative ledger rows for ledger actions filtered by IDs';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN Downstream COMMENT 'AllPlatforms + DDR panel TVFs/views';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN MIMOAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN OrigIdentifier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN TransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN AmountOrigCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN FundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN CurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsInternalTransfer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsRedeem SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsIBANTrade SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsCryptoToFiat SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsRecurring SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN IsIBANQuickTransfer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN Fact_CustomerAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_trading_platform ALTER COLUMN Downstream SET TAGS ('pii' = 'none');

