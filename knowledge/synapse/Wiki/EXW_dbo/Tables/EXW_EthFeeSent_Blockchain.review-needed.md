# EXW_dbo.EXW_EthFeeSent_Blockchain — Review Needed

**Generated**: 2026-04-20 | **Batch**: 5 | **Type**: Table

## Tier 4 / Unverified Items

No Tier 4 or Tier 5 columns. All 19 columns resolved to T1 or T2.

## Open Questions for Reviewer

1. **EXW_ETH_FeeData_Blockchain source**: This is the primary source for txhash, date_time, txn_fee_eth, historical_price_eth, contract_address, and method. EXW_ETH_FeeData_Blockchain is not yet documented (Pending in batch queue). Verify that the column names and meanings are consistent with the Etherscan import format.

2. **GCIDUnion bigint**: GCIDUnion is typed as bigint in the DDL while GCID is int. The CASE expression in the SP combines GCID (int) and CustomerWalletsView.Gcid (likely int). Verify whether bigint is an intentional safeguard or a type mismatch that could cause implicit cast overhead on JOINs.

3. **'Not Exist on Wallet' rows (8,978)**: These are Etherscan-logged transactions without a matching record in EXW_FactTransactions. Confirm whether this represents an expected gap or a data quality issue. If systematic, it may indicate a class of ETH transactions (e.g., contract interactions not tracked as wallet transactions) that should be handled differently.

4. **date_time as nvarchar(256)**: The raw Etherscan timestamp is stored as a string, not cast to datetime. Confirm this is intentional (preserving exact Etherscan output format) and whether a datetime cast column should be added.

5. **Consumer coverage**: No SP consumers found in SSDT. Verify whether any Power BI reports, SSRS reports, or Excel queries reference this table directly.

## Cross-Object Consistency

- Activity values match TransactionTypeID mapping in EXW_FactTransactions ✓
- Country/Regulation enrichment via snapshot matches pattern in EXW_FinanceReportsBalancesNew ✓
- GCIDUnion omnibus resolution matches pattern in SP_EXW_FinanceReportsBalancesNew ✓

## No ALTER Script

ALTER script deferred to /generate-alter-dwh. UC Target = `_Not_Migrated`.
