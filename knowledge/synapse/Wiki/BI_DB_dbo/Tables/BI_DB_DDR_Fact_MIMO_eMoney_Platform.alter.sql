-- =============================================================================
-- Databricks ALTER Script: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
-- Generated: 2026-05-14 14:29:17 UTC | _tmp_create_missing_alters.py
-- Target: Unity Catalog column comments (1024 char limit)
-- UC Target: main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform
-- =============================================================================

-- ---- Table Comment ----
-- (table-level comment intentionally omitted; regen tool only manages column comments)

-- ---- Column Comments ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN DateID COMMENT 'Business partition key for daily reload. `CAST(CONVERT(VARCHAR(8),@date,112) AS INT)` seeded into both deposit/withdraw temp sets; `DELETE` targets the same key. (Tier 2 - SP_DDR_Fact_MIMO_eMoney_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN Date COMMENT 'Calendar date parameter `@date` materialized on insert. (Tier 2 - SP_DDR_Fact_MIMO_eMoney_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN RealCID COMMENT 'Global Real Customer Identifier on the ledger row (`mfts.CID` aliased as `RealCID`). (Tier 1 - Customer.CustomerStatic)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN MIMOAction COMMENT '`''Deposit''` from `#depositsIBAN` or `''Withdraw''` from `#cashoutIBAN`. (Tier 2 - SP_DDR_Fact_MIMO_eMoney_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN OrigIdentifier COMMENT 'Literal discriminator `''TransactionID''` for DDR grain labeling. (Tier 2 - SP_DDR_Fact_MIMO_eMoney_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN TransactionID COMMENT 'eMoney `TransactionID` with INSERT coercion `ISNULL(i.TransactionID, -1)`. (Tier 2 - eMoney_Fact_Transaction_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN ReferenceNumber COMMENT 'Provider / bank reference from `mfts.ReferenceNumber`; INSERT coerces NULL to `-1`. (Tier 2 - eMoney_Fact_Transaction_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN AmountUSD COMMENT '`USDAmountApprox` (deposits positive; withdraw leg multiplied by `-1`); FTD rows may take `USDAmountApprox` from `#FTDIBAN` via `UPDATE`. (Tier 2 - eMoney_Fact_Transaction_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN AmountOrigCurrency COMMENT '`LocalAmount` with the same sign rule as `AmountUSD`. (Tier 2 - eMoney_Fact_Transaction_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN FundingTypeID COMMENT '`CASE WHEN mfts.TxTypeID IN (5) THEN 33 ELSE 0 END` on deposits; `CASE WHEN mfts.TxTypeID IN (6) THEN 33 ELSE 0 END` on withdrawals - join `Dim_FundingType` to decode. (Tier 2 - SP_DDR_Fact_MIMO_eMoney_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN CurrencyID COMMENT 'Primary key. Universal instrument identifier. 0=NULL placeholder, 1-8=major forex currencies, ~1000+=stocks (AAPL, GOOG, etc.), ~100000+=crypto (BTC, ETH). Referenced by virtually all DWH fact tables. Legacy name: eToro originated as forex-only. Deposit path: `SellCurrencyID` from `eMoney_Currency_Instrument_Mapping_Static` on `HolderCurrencyISO = CurrencyISO` (`BuyCurrencyID = 1`). Withdraw path: `Dim_Currency.CurrencyID` on `HolderCurrencyDesc = Abbreviation`. (Tier 1 - Dictionary.Currency)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN Currency COMMENT 'Passthrough `mfts.HolderCurrencyDesc` display string from eMoney (not `Dim_Currency.Abbreviation` join). (Tier 2 - eMoney_Fact_Transaction_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsFTD COMMENT 'Deposits: `CASE WHEN f.TransactionID IS NOT NULL THEN 1 ELSE 0 END` against `#FTDIBAN`; withdraws forced `0` in temp; INSERT `ISNULL(i.IsFTD,0)`; late `UPDATE` for `DateID>=20250901` per SP. (Tier 2 - SP_DDR_Fact_MIMO_eMoney_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsInternalTransfer COMMENT 'Deposits: `CASE WHEN mfts.TxTypeID IN (5) THEN 1 ELSE 0 END`. Withdrawals: `CASE WHEN mfts.TxTypeID IN (6) THEN 1 ELSE 0 END`. INSERT `ISNULL(...,0)`. **Differs from TP**, which keys off `FundingTypeID=33` on billing facts - here TxType drives the flag directly. (Tier 2 - SP_DDR_Fact_MIMO_eMoney_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsRedeem COMMENT '`#depositsIBAN` / `#cashoutIBAN` both assign `NULL AS IsRedeem`; final INSERT applies `ISNULL(i.IsRedeem, 0)`, so the persisted value is always **0**. Column exists for **DDR / `UNION ALL` schema parity** with `BI_DB_DDR_Fact_MIMO_Trading_Platform`, where `IsRedeem` can surface **transfer-to-coin / transfercoin** semantics from `Fact_CustomerAction` (`ActionTypeID IN (8,45)` withdraw path) and cross-checks **`Function_Revenue_TransferCoinFee`** (`ActionTypeID = 30 AND IsRedeem = 1`). **This eMoney SP never reads `Fact_CustomerAction.IsRedeem`** - do **not** apply TP/Fact_CustomerAction “redeem” narratives or “eMoney balance redeemed to bank account” wording here. (Tier 2 - SP_DDR_Fact_MIMO_eMoney_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN TxTypeID COMMENT 'Transaction type identifier. 1=CardPayment, 2=Contactless, 3=OnlinePayment, 4=CashWithdrawal, 5=TransferReceived, 6=Transfer, 7=PaymentReceived, 8=Payment, 9=Refund, 10=Fee, 11=CreditBA, 12=DebitBA, 13=DirectDebit, 14=CryptoToFiat (15=CryptoToFiat via dictionary). Passthrough `mfts.TxTypeID` for filtered settled rows. (Tier 2 - eMoney_Fact_Transaction_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsTradeFromIBAN COMMENT 'Deposits: `case when left(ReferenceNumber,1) != ''P'' and TxStatusModificationDateID >= 20240403 and TxTypeID = 5 then 1 else 0 end`. Withdrawals: `case when left(ReferenceNumber,1) != ''P'' and TxStatusModificationDateID >= 20240403 and TxTypeID = 6 then 1 else 0 end`. INSERT `ISNULL(i.IsTradeFromIBAN,0)`. (Tier 2 - SP_DDR_Fact_MIMO_eMoney_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN UpdateDate COMMENT '`GETDATE()` stamp on INSERT. (Tier 2 - SP_DDR_Fact_MIMO_eMoney_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsCryptoToFiat COMMENT 'Deposit leg: `CASE WHEN mfts.TxTypeID IN (14) THEN 1 ELSE 0 END`. Withdraw leg: `0 AS IsCryptoToFiat`. INSERT: `ISNULL(IsCryptoToFiat,0)`. (Tier 2 - eMoney_Fact_Transaction_Status)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsRecurring COMMENT 'Literal `0` on INSERT (`0 AS IsRecurring`) - recurring schedules are tracked on TP/billing, not here. (Tier 2 - SP_DDR_Fact_MIMO_eMoney_Platform)';
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsIBANQuickTransfer COMMENT 'Literal `0` on INSERT (`0 AS IsIBANQuickTransfer`). SP changelog references **MoveMoneyReason = 6** for eMoney “Internal Transfer”, but **no** `MoveMoneyReasonID` filter exists in SQL - downstream AllPlatforms prose may assume behavior this SP does not implement. (Tier 4 - SP_DDR_Fact_MIMO_eMoney_Platform)';

-- ---- Column PII Tags ----
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN DateID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN Date SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN RealCID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN MIMOAction SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN OrigIdentifier SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN TransactionID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN ReferenceNumber SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN AmountUSD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN AmountOrigCurrency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN FundingTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN CurrencyID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN Currency SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsFTD SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsInternalTransfer SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsRedeem SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN TxTypeID SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsTradeFromIBAN SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN UpdateDate SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsCryptoToFiat SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsRecurring SET TAGS ('pii' = 'none');
ALTER TABLE main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform ALTER COLUMN IsIBANQuickTransfer SET TAGS ('pii' = 'none');

