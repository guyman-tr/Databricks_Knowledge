# EXW_dbo.EXW_FirstTimeWalletsAndUsers — Review Needed

**Generated**: 2026-04-20 | **Batch**: 5 | **Type**: Table

## Tier 4 / Unverified Items

No Tier 4 or Tier 5 columns. All 13 columns resolved to T2.

## Open Questions for Reviewer

1. **New_UsersAndWallets_Inventory source**: This is the primary source for UserJoinDate, WalletJoinDate, GCID, CryptoName, CryptoID. New_UsersAndWallets_Inventory is not yet documented (Pending in batch queue). Verify: (a) how UserJoinDate vs WalletJoinDate are defined there — is UserJoinDate the date of first wallet opening overall, or first registration in the platform? (b) Is there a backfill for pre-Wallet-launch users?

2. **CryptoNameERC vs CryptoName alignment**: In cases where CryptoID = BlockchainCryptoId (L1 tokens like BTC, ETH), CryptoNameERC and CryptoName should be identical. For ERC-20 tokens they diverge. Confirm this is expected and whether analysts should always use CryptoName for blockchain-level grouping.

3. **Negative NewUsers count**: Can NewUsers be 0 for rows where NewWallets > 0? (Yes — this is by design: 'OldCID' users open new crypto wallets.) Confirm analysts are aware that NewUsers=0 is valid and common for crypto adoption events.

4. **StateCode encoding**: In EXW_FirstTimeWalletsAndUsers, StateCode = DWH_dbo.Dim_State_and_Province.ShortName. This differs from EXW_30DayBalanceExtract where StateCode = EXW_DimUser.UserRegionID. Confirm this inconsistency exists and whether standardization is needed.

5. **Consumer coverage**: No SP consumers found in SSDT. Verify whether BI_DB_dbo SPs or Power BI reports reference this table.

## Cross-Object Consistency

- RealUser values match EXW_DimUser_Enriched.UserType documented in Batch 2 ✓
- Country/Regulation from EXW_DimUser match values in other EXW tables ✓
- FullDateID encoding (YYYYMMDD) matches pattern across all EXW date ID columns ✓

## No ALTER Script

ALTER script deferred to /generate-alter-dwh. UC Target = `_Not_Migrated`.
