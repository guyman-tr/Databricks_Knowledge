# Review Needed: BI_DB_dbo.BI_DB_Equity_Real_Crypto_Stocks_Total_Cash_by_Regulation

Generated: 2026-04-22 | Reviewer: —

## Tier 4 Items (Unverified — Human Review Required)

None — all columns are Tier 2 (SP code verified).

## Questions for SME

1. **TotalCash_Calc formula**: The formula excludes real crypto and real stocks equity (`EquityRealCrypto`, `EquityRealStocks`). Is this intentional — i.e., is `TotalCash_Calc` specifically "cash + CFD equity" as a regulatory concept? Or should it include real assets for a true total wealth view?

2. **UK-only scope**: This table covers only United Kingdom customers (`Country='United Kingdom'`). Is there a companion table for other regions, or is this exclusively for FCA/BVI/NFA UK regulatory reporting?

3. **NFA regulation presence**: NFA (US regulator) appearing for "United Kingdom" customers (3% of rows) may indicate customers registered in the UK but trading under NFA jurisdiction. Please confirm this is expected.

4. **IsGermanBaFin always 0**: Confirmed in live data — every row has IsGermanBaFin=0. Is this column inherited from the parent table schema for consistency, or was BaFin expected to appear at some point?

5. **PlayerStatus 'Trade & MIMO Blocked' (42,434 rows)**: Large count. Is this a specific compliance/risk status or was it introduced at a particular date?

## Corrections Log

No corrections applied.

## Pipeline Flags

- **UC Target**: _Not_Migrated — no Unity Catalog migration planned as of 2026-04-22.
- **UpdateDate range**: 2022-06-09 to 2026-04-13 — table has been active for ~4 years.
- **Row count**: 263,369 (moderate — expected for UK regulatory slice).
