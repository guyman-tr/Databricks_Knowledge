# EXW_FactBalance — Review Notes

Generated: 2026-04-20 | Reviewer: —

## Tier 2 Items (Derived — May Need Verification)

| # | Column | Description | Verification Needed |
|---|--------|-------------|---------------------|
| 1 | Balance | ISNULL(WalletBalances.Balance, 0) | Confirm semantics: does Balance=0 mean "account exists but empty" or "wallet has no position on this date"? These are different business states |
| 2 | BalanceUSD | ISNULL(Balance × AvgPrice, 0) | Confirm price join logic: dual condition `F.InstrumentID = P.InstrumentID OR F.CryptoId = P.InstrumentID` — does this ever produce duplicate price matches? |
| 3 | InstrumentID | NULL for some cryptos | Confirm which cryptos have NULL InstrumentID and whether this is expected long-term or a gap to be filled |
| 4 | RealCID | LEFT JOIN to EXW_DimUser | Confirm if NULL RealCID rows are expected in production analytics or should be treated as data quality issues |

## Open Questions

- **GCID declared bigint here, int in EXW_DimUser**: Is the bigint declaration intentional (anticipating ID growth) or a migration artifact? The implicit type cast on JOINs could have performance implications at 2.37B row scale.
- **HEAP on 2.37B rows**: No CCI or clustered index on the largest table in EXW_dbo. Was this intentional (INSERT performance trade-off) or is a CCI migration planned? Without CCI, all aggregation queries are doing raw HEAP scans.
- **Only one downstream consumer (eMoney_dbo.SP_EXW_FactBalance_EXT)**: Is EXW_FactBalance used directly in ad-hoc analyst queries from BI tools? If so, those won't appear in the SP reference scan.
- **6 excluded Bitcoin addresses**: The SP hardcodes 6 Bitcoin wallet addresses to exclude (legacy Beta wallets). Is this list complete and up to date? Are there newer wallets that should be excluded?
- **CopyFromLake view vs direct table**: The SP sources from `CopyFromLake.WalletDB_Wallet_V_BI_WalletBalances` — confirm this is the correct and current source (the SP header notes a 2024-04-07 migration "change join to take directly from balancetable"). Is the `V_BI_WalletBalances` view still the authoritative source or should it join WalletBalances directly?
- **UC Target**: Listed as `_Not_Migrated` — given this is the primary Wallet balance fact table at 2.37B rows, confirm whether a UC export is planned.

## No Reviewer Corrections at Time of Generation
