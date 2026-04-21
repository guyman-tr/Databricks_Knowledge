---
object: EXW_dbo.EXW_Inventory_Snapshot_History
type: Table
writer_sp: EXW_dbo.SP_EXW_Inventory_Snapshot_History
upstream_source: EXW_dbo.EXW_WalletInventory (internal — no production DB upstream)
lineage_generated: 2026-04-20
---

# Column Lineage — EXW_dbo.EXW_Inventory_Snapshot_History

## ETL Chain

```
EXW_dbo.EXW_WalletInventory
  |-- SP_EXW_Inventory_Snapshot_History @d DATE ---|
  v
EXW_dbo.EXW_Inventory_Snapshot_History (daily snapshot)
  |-- UC Target: _Not_Migrated ---|
```

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|---------------|-----------|------|
| 1 | WalletStatus | EXW_WalletInventory | WalletStatus | Passthrough (GROUP BY key) | Tier 2 |
| 2 | BlockchainCryptoName | EXW_WalletInventory | BlockchainCryptoName | Passthrough (GROUP BY key) | Tier 2 |
| 3 | BlockchainCryptoId | EXW_WalletInventory | BlockchainCryptoId | Passthrough (GROUP BY key / HASH distribution key) | Tier 2 |
| 4 | Allocated Total | EXW_WalletInventory | Allocated, BlockchainCryptoId | SUM(CASE WHEN Allocated < @EndDate THEN 1 ELSE 0) — all wallets allocated up to @d | Tier 2 |
| 5 | Funded Free | EXW_WalletInventory | WalletStatus, Occupied, IsPromotionReady | SUM(CASE WHEN WalletStatus='FundingVerified' AND Occupied=0 AND IsPromotionReady=1 THEN 1 ELSE 0) | Tier 2 |
| 6 | Funded Occupied | EXW_WalletInventory | WalletStatus, Occupied, IsPromotionReady | SUM(CASE WHEN WalletStatus='FundingVerified' AND Occupied=1 AND IsPromotionReady=1 THEN 1 ELSE 0) | Tier 2 |
| 7 | Available | EXW_WalletInventory | Allocated | SUM(CASE WHEN Allocated IS NULL OR Allocated > @d THEN 1 ELSE 0) — wallets not yet assigned | Tier 2 |
| 8 | Date for Report | SP parameter | @d | Literal: @d (the input date) | Tier 2 |
| 9 | UpdateDate | SP runtime | GETDATE() | ETL load timestamp — not business data | Tier 2 |
| 10 | Total AllocatedOmnibuses | EXW_WalletInventory | Allocated, GCID | SUM(CASE WHEN Allocated < @EndDate AND GCID <= 0 THEN 1 ELSE 0) — omnibus wallets | Tier 2 |
| 11 | Total AllocatedToUsers | EXW_WalletInventory | Allocated, GCID | SUM(CASE WHEN Allocated < @EndDate AND GCID > 0 THEN 1 ELSE 0) — user wallets | Tier 2 |
| 12 | Total Created | EXW_WalletInventory | WalletID, Created | COUNT(DISTINCT WalletID) WHERE Created < @EndDate | Tier 2 |
| 13 | Allocated Daily | EXW_WalletInventory | WalletID, Allocated | COUNT(DISTINCT WalletID) WHERE Allocated = @d (exact date match) | Tier 2 |
| 14 | Created Daily | EXW_WalletInventory | WalletID, CreatedDateID | COUNT(DISTINCT WalletID) WHERE CreatedDateID = YYYYMMDD(@d) | Tier 2 |
| 15 | Allocated 7 days | EXW_WalletInventory | Allocated | SUM CASE Allocated BETWEEN @d-6 AND @d | Tier 2 |
| 16 | Allocated 30 days | EXW_WalletInventory | Allocated | SUM CASE Allocated BETWEEN @d-29 AND @d | Tier 2 |
| 17 | Created 7 days | EXW_WalletInventory | Created | SUM CASE Created BETWEEN @d-6 AND @d | Tier 2 |
| 18 | Created 30 days | EXW_WalletInventory | Created | SUM CASE Created BETWEEN @d-29 AND @d | Tier 2 |

## Notes

- All data aggregated from EXW_WalletInventory (internal wallet inventory master)
- No upstream production DB source — all Tier 2
- Grain: one row per (Date for Report, BlockchainCryptoName, BlockchainCryptoId, WalletStatus)
- GCID <= 0 = omnibus/system wallets; GCID > 0 = customer wallets
- SP is idempotent: DELETE WHERE [Date for Report] = @d before INSERT
