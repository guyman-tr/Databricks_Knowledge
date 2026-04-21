# EXW_dbo.New_UsersAndWallets_Inventory — Review Needed

**Generated**: 2026-04-20 | **Quality**: 8.6/10 | **Phase 16 evaluator**: Pending

## Tier 4 Items (Low-Confidence — Reviewer Verification Needed)

None — all columns are Tier 1 or Tier 2 with clear SP traceability.

## Open Questions for Reviewer

1. **UpdateDate DDL type**: DDL declares `UpdateDate [date] NULL` but SP inserts `GETDATE()` (datetime). Verify whether GETDATE() is implicitly CAST to DATE on insert, or whether the DDL was updated independently.
2. **Relationship to EXW_FirstTimeWalletsAndUsers**: `SP_EXW_FirstTimeWalletsAndUsers` reads this table as the source for `UserJoinDate` and `WalletJoinDate`. Confirm whether this table is the ONLY source for those dates, or whether alternative date computation paths exist for edge cases.
3. **174 CryptoIDs**: The crypto count (174) is lower than in EXW_FactTransactions (which includes ERC-20 tokens) due to the ERC-20 exclusion inherited from EXW_WalletInventory. Confirm that downstream monthly analytics (EXW_FirstTimeWalletsAndUsers) correctly handles this scope.
4. **Full rebuild risk**: This table is fully rebuilt daily (TRUNCATE + INSERT). If EXW_WalletInventory has backfill corrections, historical WalletJoinDate values may change silently. Confirm whether BI reports consuming this table are aware of this re-write behaviour.

## Carry-Forward Notes

- WalletJoinDate and UserJoinDate both trace to WalletDB.Wallet.WalletAssets.Occurred via EXW_WalletInventory.Allocated (Tier 1 — WalletDB.Wallet.CustomerWalletsView).
- The WHERE GCID>0 filter in SP aligns this table's scope with EXW_DimUser (699,694 GCIDs).
