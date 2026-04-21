---
object: EXW_dbo.EXW_Inventory_Snapshot_History
review_date: 2026-04-20
batch: 12
priority: LOW
---

# Review Notes — EXW_Inventory_Snapshot_History

## Tier 4 Items (Low Confidence — Needs Verification)

None. All columns are fully traced to SP_EXW_Inventory_Snapshot_History code with clear aggregation formulas.

## Open Questions for Reviewer

1. **CryptoID mapping completeness**: The 12 CryptoID values (1,2,3,4,6,8,18,19,21,23,27,64) were verified from live data. Are there any additional cryptos expected to be added in future that would change this list?

2. **Available vs FundingVerified semantics**: Verified wallets with `Available` > 0 are not assigned — is this the correct interpretation? The SP counts available wallets separately from allocated regardless of WalletStatus. Confirm the business meaning of "Available" for Pending vs Verified status wallets is the same.

3. **Created Daily = 0 for most days**: In the latest snapshot (2026-04-11), `Created Daily` is 0 for BTC, ETH, ADA, DOGE and all others except SOL. This suggests new address creation has largely stopped — is this intentional (decommissioning of wallet provisioning), or is there a separate creation process not captured here?

4. **SP run schedule**: SP_EXW_Inventory_Snapshot_History takes a @d parameter but has no apparent orchestration entry in SSDT. How/where is this SP scheduled in production? ADF or SQL Agent job?

## DDL Observations

- 14 out of 18 columns have spaces in their names — bracket quoting required in all SQL
- All columns are nullable despite being aggregate counts (INT NULL instead of INT NOT NULL with DEFAULT 0). The ISNULL(..., 0) in the SP ensures no NULLs are inserted for allocation/creation counters, but [UpdateDate] and [Date for Report] could theoretically be NULL
