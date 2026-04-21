# EXW_dbo.EXW_30DayBalanceExtract — Column Lineage

**Object Type**: Table
**Schema**: EXW_dbo
**Generated**: 2026-04-20
**Pipeline Phase**: 10B

## Table Definition Summary

Rolling 30-day extract of EXW_FinanceReportsBalancesNew enriched with EXW_DimUser geographic attributes. Writer: SP_EXW_30DayBalanceExtract (no date parameter). Strategy: TRUNCATE TABLE, then INSERT. Window: BalanceDateID >= GETDATE()-31. HASH(GCID), HEAP.

Key enrichments vs source table: Region, UserRegion_State (State), UserRegionID (StateCode), ComplianceClosureEvent — all from EXW_DimUser. CryptoId/CryptoName mapped to blockchain-level IDs; CryptoIdERC/CryptoNameERC preserve ERC-level originals.

52.7M rows, 689,733 GCIDs, 31 dates (rolling window; currently 2026-03-12 to 2026-04-11).

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Confidence |
|---|--------|---------------|---------------|-----------|------------|
| 1 | FullDate | EXW_dbo.EXW_FinanceReportsBalancesNew | BalanceDate | Alias rename | Tier 2 — SP_EXW_30DayBalanceExtract |
| 2 | FullDateID | EXW_dbo.EXW_FinanceReportsBalancesNew | BalanceDateID | Alias rename | Tier 2 — SP_EXW_30DayBalanceExtract |
| 3 | GCID | EXW_dbo.EXW_FinanceReportsBalancesNew | GCID | Direct passthrough | Tier 2 — SP_EXW_30DayBalanceExtract |
| 4 | RealCID | EXW_dbo.EXW_FinanceReportsBalancesNew | RealCID | Direct passthrough | Tier 1 — Customer.CustomerStatic |
| 5 | CryptoId | EXW_Wallet.CryptoTypes | BlockchainCryptoId | JOIN CryptoTypes WHERE CryptoID=BlockchainCryptoId — blockchain-level crypto ID (deduped) | Tier 2 — SP_EXW_30DayBalanceExtract |
| 6 | CryptoName | EXW_Wallet.CryptoTypes | Name | Blockchain-level crypto name (WHERE CryptoID=BlockchainCryptoId) | Tier 2 — SP_EXW_30DayBalanceExtract |
| 7 | InstrumentID | EXW_Wallet.CryptoTypes | InstrumentId | JOIN on EXW_FinanceReportsBalancesNew.CryptoID | Tier 2 — SP_EXW_30DayBalanceExtract |
| 8 | WalletID | EXW_dbo.EXW_FinanceReportsBalancesNew | WalletID | Direct passthrough | Tier 2 — SP_EXW_30DayBalanceExtract |
| 9 | Balance | EXW_dbo.EXW_FinanceReportsBalancesNew | Balance | Direct passthrough | Tier 2 — SP_EXW_30DayBalanceExtract |
| 10 | BalanceUSD | EXW_dbo.EXW_FinanceReportsBalancesNew | BalanceUSD | Direct passthrough | Tier 2 — SP_EXW_30DayBalanceExtract |
| 11 | FactBalance_UpdateDate | EXW_dbo.EXW_FinanceReportsBalancesNew | UpdateDate | Alias rename — preserves source table's UpdateDate (not ETL run time) | Tier 2 — SP_EXW_30DayBalanceExtract |
| 12 | CryptoIdERC | EXW_dbo.EXW_FinanceReportsBalancesNew | CryptoID | Alias rename — original ERC-level crypto ID from source | Tier 2 — SP_EXW_30DayBalanceExtract |
| 13 | CryptoNameERC | EXW_dbo.EXW_FinanceReportsBalancesNew | CryptoName | Alias rename — original ERC-level crypto name | Tier 2 — SP_EXW_30DayBalanceExtract |
| 14 | Country | EXW_dbo.EXW_FinanceReportsBalancesNew | Country | Direct passthrough | Tier 2 — SP_EXW_30DayBalanceExtract |
| 15 | CountryID | EXW_dbo.EXW_FinanceReportsBalancesNew | CountryID | Direct passthrough | Tier 2 — SP_EXW_30DayBalanceExtract |
| 16 | Region | EXW_dbo.EXW_DimUser | Region | LEFT JOIN EXW_DimUser ON GCID — not in EXW_FinanceReportsBalancesNew | Tier 2 — SP_EXW_30DayBalanceExtract |
| 17 | Regulation | EXW_dbo.EXW_FinanceReportsBalancesNew | Regulation | Direct passthrough | Tier 2 — SP_EXW_30DayBalanceExtract |
| 18 | PlayerLevelID | EXW_dbo.EXW_FinanceReportsBalancesNew | PlayerLevelID | Direct passthrough | Tier 2 — SP_EXW_30DayBalanceExtract |
| 19 | Club | EXW_dbo.EXW_FinanceReportsBalancesNew | Club | Direct passthrough | Tier 2 — SP_EXW_30DayBalanceExtract |
| 20 | RealUser | EXW_dbo.EXW_FinanceReportsBalancesNew + EXW_DimUser | IsTestAccount, IsValidCustomer | CASE: IsTestAccount=1→'TestUser', IsValidCustomer=0→'eTorian', else→'RealUser' | Tier 2 — SP_EXW_30DayBalanceExtract |
| 21 | StateCode | EXW_dbo.EXW_DimUser | UserRegionID | LEFT JOIN EXW_DimUser ON GCID — state/region code; NULL for non-US users | Tier 2 — SP_EXW_30DayBalanceExtract |
| 22 | State | EXW_dbo.EXW_DimUser | UserRegion_State | LEFT JOIN EXW_DimUser ON GCID — full state/region name; NULL for non-US users | Tier 2 — SP_EXW_30DayBalanceExtract |
| 23 | UpdateDate | (computed) | — | GETDATE() at SP run time | Tier 2 — SP_EXW_30DayBalanceExtract |
| 24 | ComplianceClosureEvent | EXW_dbo.EXW_DimUser | ComplianceClosureEvent | LEFT JOIN EXW_DimUser ON GCID — compliance closure flag; not in EXW_FinanceReportsBalancesNew | Tier 2 — SP_EXW_30DayBalanceExtract |

## Source Objects

| Source Object | Relationship | Notes |
|---------------|-------------|-------|
| EXW_dbo.EXW_FinanceReportsBalancesNew | Primary source (FROM clause) | Filter: BalanceDateID >= GETDATE()-31; provides 22 of 24 columns |
| EXW_dbo.EXW_DimUser | LEFT JOIN on GCID | Adds Region, StateCode (UserRegionID), State (UserRegion_State), ComplianceClosureEvent |
| EXW_Wallet.CryptoTypes | LEFT JOIN on CryptoID | Maps ERC CryptoId to blockchain-level BlockchainCryptoId and Name; also provides InstrumentId |

## UC Lineage

UC Target: `_Not_Migrated`
No UC entity exists for this table. Documentation is for knowledge purposes only.
