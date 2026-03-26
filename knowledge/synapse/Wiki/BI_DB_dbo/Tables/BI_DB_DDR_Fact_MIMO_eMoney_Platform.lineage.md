# Column Lineage: BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform

| Property | Value |
|----------|-------|
| **DWH Table** | `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `eMoney_dbo.eMoney_Fact_Transaction_Status` |
| **ETL SP** | `SP_DDR_Fact_MIMO_eMoney_Platform` |
| **Secondary Sources** | `DWH_dbo.Dim_Customer`, `DWH_dbo.Dim_Currency`, `eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static` |
| **Generated** | 2026-03-26 |

## Lineage Chain

```
eMoney_dbo.eMoney_Fact_Transaction_Status (settled IBAN transactions)
DWH_dbo.Dim_Customer (FTD reference + amount override)
DWH_dbo.Dim_Currency (currency ID for withdrawals)
eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static (currency ID for deposits)
  |
  |-- SP_DDR_Fact_MIMO_eMoney_Platform(@date):
  |     1. #FTDIBAN: FTD deposits from eMoney_Fact_Transaction_Status JOIN Dim_Customer
  |     2. #depositsIBAN: Date-filtered deposits (TxTypeID 7,5,14)
  |     3. UPDATE deposits with Dim_Customer FTD amount
  |     4. #cashoutIBAN: Date-filtered withdrawals (TxTypeID 8,6)
  |     5. UNION ALL → #MIMOIBANPREP → dedupe by TransactionID → #MIMOIBAN
  |     6. DELETE/INSERT by DateID
  |     7. FTD recovery UPDATE from Dim_Customer for DateID >= 20250901
  v
BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform (23.2M rows, transaction-level grain)
```

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is from source |
| **rename** | Same value, different column name |
| **ETL-computed** | Derived/calculated by SP logic |
| **join-enriched** | Joined from secondary source during ETL |
| **coerce** | ISNULL null-to-zero/default coercion applied |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| DateID | — | — | ETL-computed | `@dateID = CAST(CONVERT(VARCHAR(8), @date, 112) AS INT)` | SP parameter |
| Date | — | — | ETL-computed | `@date` parameter | SP parameter |
| RealCID | eMoney_Fact_Transaction_Status | CID | rename | `mfts.CID AS RealCID` | Renamed CID→RealCID |
| MIMOAction | — | — | ETL-computed | Literal: `'Deposit'` or `'Withdraw'` based on query branch | |
| OrigIdentifier | — | — | ETL-computed | Literal: `'TransactionID'` for all eMoney transactions | Always 'TransactionID' |
| TransactionID | eMoney_Fact_Transaction_Status | TransactionID | passthrough+coerce | `ISNULL(i.TransactionID, -1)` | -1 sentinel for NULLs |
| ReferenceNumber | eMoney_Fact_Transaction_Status | ReferenceNumber | passthrough+coerce | `ISNULL(i.ReferenceNumber, -1)` | Payment gateway reference |
| AmountUSD | eMoney_Fact_Transaction_Status | USDAmountApprox | rename | `mfts.USDAmountApprox AS AmountUSD`; deposits positive, withdrawals negated (`-1 * mfts.USDAmountApprox`); FTD amounts overridden from Dim_Customer | |
| AmountOrigCurrency | eMoney_Fact_Transaction_Status | LocalAmount | rename | `mfts.LocalAmount AS AmountOrigCurrency`; withdrawals negated | |
| FundingTypeID | eMoney_Fact_Transaction_Status | TxTypeID | ETL-computed | Deposits: `CASE WHEN TxTypeID IN (5) THEN 33 ELSE 0 END`; Withdrawals: `CASE WHEN TxTypeID IN (6) THEN 33 ELSE 0 END` | 33 = internal transfer type |
| CurrencyID | eMoney_Currency_Instrument_Mapping_Static / Dim_Currency | SellCurrencyID / CurrencyID | join-enriched | Deposits: `dc.SellCurrencyID` via `HolderCurrencyISO = CurrencyISO`; Withdrawals: `dc.CurrencyID` via `HolderCurrencyDesc = Abbreviation` | Different join paths per action |
| Currency | eMoney_Fact_Transaction_Status | HolderCurrencyDesc | passthrough | Direct: `mfts.HolderCurrencyDesc AS Currency` | ISO currency code |
| IsFTD | eMoney_Fact_Transaction_Status + Dim_Customer | TransactionID | ETL-computed+coerce | `CASE WHEN f.TransactionID IS NOT NULL THEN 1 ELSE 0 END`; `ISNULL(i.IsFTD, 0)`; + FTD recovery UPDATE for DateID >= 20250901 | Platform-level first deposit |
| IsInternalTransfer | eMoney_Fact_Transaction_Status | TxTypeID | ETL-computed+coerce | Deposits: `CASE WHEN TxTypeID IN (5) THEN 1 ELSE 0 END`; Withdrawals: `CASE WHEN TxTypeID IN (6) THEN 1 ELSE 0 END`; `ISNULL(...,0)` | TxTypeID 5/6 = internal transfers |
| IsRedeem | — | — | ETL-computed+coerce | `ISNULL(NULL, 0)` — always NULL in source, coerced to 0 | Placeholder; not populated for eMoney |
| TxTypeID | eMoney_Fact_Transaction_Status | TxTypeID | passthrough | Direct: `mfts.TxTypeID` | 5=internal in, 6=internal out, 7=deposit, 8=withdraw, 14=C2F |
| IsTradeFromIBAN | eMoney_Fact_Transaction_Status | ReferenceNumber + TxTypeID | ETL-computed+coerce | `CASE WHEN LEFT(ReferenceNumber,1) != 'P' AND TxStatusModificationDateID >= 20240403 AND TxTypeID = 5 THEN 1 ELSE 0 END` (deposits); `... AND TxTypeID = 6 ...` (withdrawals); `ISNULL(...,0)` | Reference-based IBAN trade detection |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL timestamp |
| IsCryptoToFiat | eMoney_Fact_Transaction_Status | TxTypeID | ETL-computed+coerce | `CASE WHEN TxTypeID IN (14) THEN 1 ELSE 0 END`; `ISNULL(...,0)` | TxTypeID 14 = crypto to fiat |
| IsRecurring | — | — | ETL-computed | Hardcoded `0` | Placeholder; eMoney does not track recurring |
| IsIBANQuickTransfer | — | — | ETL-computed | Hardcoded `0` | Placeholder; populated upstream but reset here |

## Summary

| Category | Count |
|----------|-------|
| **Passthrough** | 3 |
| **Passthrough+coerce** | 2 |
| **Rename** | 2 |
| **ETL-computed** | 7 |
| **ETL-computed+coerce** | 5 |
| **Join-enriched** | 1 |
| **Rename** | 1 |
| **Total** | 21 |
