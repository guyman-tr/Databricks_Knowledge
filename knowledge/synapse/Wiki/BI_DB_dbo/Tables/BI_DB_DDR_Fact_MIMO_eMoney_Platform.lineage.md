# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform` |
| **UC Target (Databricks)** | **Not found** — `SHOW TABLES IN main.bi_db LIKE '*mimo*'` returned only `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` (2026-05-14 MCP check). Intended/export name may still follow `gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_emoney_platform`; verify with governance index / lakebridge mapping before deploy. |
| **Primary Source** | `eMoney_dbo.eMoney_Fact_Transaction_Status` |
| **ETL SP** | `BI_DB_dbo.SP_DDR_Fact_MIMO_eMoney_Platform` |
| **Secondary Sources** | `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_Currency`, `eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static` |
| **Generated** | 2026-05-14 |

## Lineage Chain

```
eMoney_dbo.eMoney_Fact_Transaction_Status (settled TxStatusID = 2 rows, filtered by TxTypeID & TxStatusModificationDateID)
    + DWH_dbo.Dim_Customer (#FTDIBAN + FTD recovery UPDATE)
    + eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static (deposit CurrencyID path)
    + DWH_dbo.Dim_Currency (withdraw CurrencyID path)
          |
          |-- BI_DB_dbo.SP_DDR_Fact_MIMO_eMoney_Platform(@date):
          |       #FTDIBAN  (TxStatusID=2, TxTypeID IN (7,14) + Dim_Customer FTD join)
          |       #depositsIBAN (TxStatusModificationDateID=@dateID, TxStatusID=2, TxTypeID IN (7,5,14))
          |       UPDATE #depositsIBAN amounts from #FTDIBAN
          |       #cashoutIBAN (same DateID filter, TxStatusID=2, TxTypeID IN (8,6))
          |       UNION ALL -> dedupe ROW_NUMBER -> #MIMOIBAN
          |       DELETE WHERE DateID=@dateID -> INSERT
          |       FTD recovery UPDATE on target (DateID>=20250901, Deposit, IsFTD=0)
          v
BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Same column from source, possibly renamed |
| **ETL-computed** | `CASE`, literal, or expression in SP |
| **join-enriched** | Value from JOIN to another table |
| **coerce** | `ISNULL` / casting on INSERT |

### Columns

| DWH Column | Source Table | Source Column | Transform | Notes |
|-----------|-------------|---------------|-----------|-------|
| DateID | — | — | ETL-computed | `@dateID = CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)`; seeded `@dateID` into both legs |
| Date | — | — | ETL-computed | INSERT selects `@date` |
| RealCID | eMoney_Fact_Transaction_Status | CID | passthrough | `mfts.CID AS RealCID` |
| MIMOAction | — | — | ETL-computed | Literals `'Deposit'` / `'Withdraw'` |
| OrigIdentifier | — | — | ETL-computed | Literal `'TransactionID'` |
| TransactionID | eMoney_Fact_Transaction_Status | TransactionID | coerce | INSERT `ISNULL(i.TransactionID, -1)` |
| ReferenceNumber | eMoney_Fact_Transaction_Status | ReferenceNumber | coerce | INSERT `ISNULL(i.ReferenceNumber, -1)` |
| AmountUSD | eMoney_Fact_Transaction_Status | USDAmountApprox | ETL-computed | Deposits: `mfts.USDAmountApprox`; Withdrawals: `-1 * mfts.USDAmountApprox`; optional UPDATE from `#FTDIBAN` |
| AmountOrigCurrency | eMoney_Fact_Transaction_Status | LocalAmount | ETL-computed | Deposits: `LocalAmount`; Withdrawals: `-1 * LocalAmount` |
| FundingTypeID | eMoney_Fact_Transaction_Status | TxTypeID | ETL-computed | Deposits: `CASE WHEN mfts.TxTypeID IN (5) THEN 33 ELSE 0 END`; Withdrawals: `CASE WHEN mfts.TxTypeID IN (6) THEN 33 ELSE 0 END` |
| CurrencyID | eMoney_Currency_Instrument_Mapping_Static / Dim_Currency | SellCurrencyID / CurrencyID | join-enriched | Deposits: `SellCurrencyID` via `HolderCurrencyISO = CurrencyISO` (static mapping `BuyCurrencyID = 1`); Withdrawals: `Dim_Currency.CurrencyID` via `HolderCurrencyDesc = Abbreviation` |
| Currency | eMoney_Fact_Transaction_Status | HolderCurrencyDesc | passthrough | `mfts.HolderCurrencyDesc AS Currency` |
| IsFTD | #FTDIBAN + post UPDATE | — | ETL-computed + coerce | Deposits: `CASE WHEN f.TransactionID IS NOT NULL THEN 1 ELSE 0 END`; Withdrawals: `0`; INSERT `ISNULL(i.IsFTD,0)`; plus `UPDATE ... SET IsFTD=1` join `Dim_Customer` / `eMoney_Fact_Transaction_Status` (see SP) |
| IsInternalTransfer | eMoney_Fact_Transaction_Status | TxTypeID | ETL-computed + coerce | Deposits: `CASE WHEN mfts.TxTypeID IN (5) THEN 1 ELSE 0 END`; Withdrawals: `CASE WHEN mfts.TxTypeID IN (6) THEN 1 ELSE 0 END`; INSERT `ISNULL(...,0)` |
| IsRedeem | — | — | ETL-computed + coerce | Both legs: `NULL AS IsRedeem`; INSERT `ISNULL(i.IsRedeem, 0)` -> always **0** |
| TxTypeID | eMoney_Fact_Transaction_Status | TxTypeID | passthrough | Carried from `mfts` |
| IsTradeFromIBAN | eMoney_Fact_Transaction_Status | ReferenceNumber, TxTypeID, TxStatusModificationDateID | ETL-computed + coerce | Deposits: `case when left(ReferenceNumber,1) != 'P' and TxStatusModificationDateID >= 20240403 and TxTypeID = 5 then 1 else 0 end`; Withdrawals: `... TxTypeID = 6 ...`; INSERT `ISNULL(...,0)` |
| UpdateDate | — | — | ETL-computed | `GETDATE()` |
| IsCryptoToFiat | eMoney_Fact_Transaction_Status | TxTypeID | ETL-computed + coerce | Deposits: `CASE WHEN mfts.TxTypeID IN (14) THEN 1 ELSE 0 END`; Withdrawals: `0 AS IsCryptoToFiat`; INSERT `ISNULL(IsCryptoToFiat,0)` |
| IsRecurring | — | — | ETL-computed | INSERT literal `0 AS IsRecurring` |
| IsIBANQuickTransfer | — | — | ETL-computed | INSERT literal `0 AS IsIBANQuickTransfer` (SP header notes MoveMoneyReason=6 feature; **no** `MoveMoneyReasonID` predicate in body) |

## Summary

| Category | Count |
|----------|-------|
| Passthrough / rename | 4 |
| Join-enriched | 1 |
| ETL-computed / coerce | 16 |
| **Total columns** | **21** |
