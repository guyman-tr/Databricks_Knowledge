# EXW_dbo.Hourly_WalletInventory — Review Needed

**Object**: EXW_dbo.Hourly_WalletInventory  
**Generated**: 2026-04-20  
**Review Priority**: Medium (TodayAllocationPace formula needs validation)

---

## Open Items

### RN-001 — TodayAllocationPace Formula Is Mathematically Inverted

**Category**: Business logic validation  
**Severity**: Medium

The SP formula is: `(AllocatedToday × DATEDIFF(HOUR, CAST(GETDATE() AS DATE), GETDATE())) / 24`

The SP comment says "pro rate hourly for the full day," implying the intent is to extrapolate today's partial-day allocation count to a full-day estimate. However:
- At hour 12 with AllocatedToday = 100: formula gives (100 × 12) / 24 = **50** (not 200)
- The correct full-day extrapolation is: AllocatedToday × 24 / hours_elapsed = 100 × 24/12 = **200**

The formula produces AllocatedToday × (hours_elapsed/24), which goes from 0 at midnight to AllocatedToday by end of day. This is not a useful "pace" metric. It may represent something else (e.g., a smoothed average), or it may be a bug from when the formula was written.

**Action needed**: Confirm with the SP author (Inessa?) what TodayAllocationPace is intended to represent. If it's meant to extrapolate to a full-day estimate, the formula should be `(AllocatedToday * 24) / NULLIF(DATEDIFF(HOUR, CAST(GETDATE() AS DATE), GETDATE()), 0)`. The wiki currently documents the formula as written and warns consumers not to use it for full-day extrapolation.

---

### RN-002 — ERC-20 Wallets Excluded — Coverage Gap for Token-Level Inventory

**Category**: Coverage / business completeness  
**Severity**: Medium

The `WHERE CryptoID = BlockchainCryptoId` filter excludes ERC-20 token wallets (USDC, LINK, COMP, AAVE, etc.) from Hourly_WalletInventory. Since ERC-20 tokens share the ETH blockchain address, ERC-20 wallet inventory = ETH wallet inventory (the wallet holds all ERC-20 tokens on the same address). The ETH row (CryptoID=2) in this table effectively covers ERC-20 token capacity.

**Action needed**: Confirm that Tableau consumers understand the ETH wallet count is the proxy for all ERC-20 token capacity. If anyone is looking for "USDC wallet inventory" they will find 0 rows and may incorrectly conclude no USDC wallets exist. Consider adding a note to ETH-related dashboard views.

---

### RN-003 — FundingVerified Status Is ETH-Only — Why?

**Category**: Documentation gap  
**Severity**: Low

Only ETH has a FundingVerified sub-pool (78,269 wallets, 77,660 allocated). FundingVerified wallets appear to be pre-funded with gas ETH (required for ERC-20 transactions). The business reason this status only applies to ETH (not other cryptos) is not documented.

**Action needed**: Confirm whether FundingVerified is an ETH-only concept by design (gas funding is ETH-specific) or whether other cryptos could theoretically have it. Document the answer in §2.2 WalletStatus Classification.

---

### RN-004 — Downstream Tableau Consumers Not Identified

**Category**: Lineage completeness  
**Severity**: Medium (change impact)

No SSDT stored procedures or views reference EXW_dbo.Hourly_WalletInventory. The specific Tableau workbooks and data sources consuming this table (for pool capacity monitoring) are not identified.

**Action needed**: Identify Tableau workbooks consuming this table, especially any alerting dashboards that trigger on `TotalFreeInventory` thresholds. Changing the WalletStatus value list or ERC-20 exclusion logic would impact those dashboards.

---

### RN-005 — #EXW_WalletInventory Intermediate Filter Is a No-Op

**Category**: Code quality / documentation accuracy  
**Severity**: Low (informational)

The temp table population query ends with `WHERE dd.CryptoID = dd.BlockchainCryptoId`. However, `dd.CryptoID` in the subquery refers to the raw `a.CryptoID = ct.CryptoID` from the JOIN `ct.CryptoID = wp.BlockchainCryptoId`, making this always true. The effective filter that excludes ERC-20 tokens is in the **final INSERT**: `FROM #EXW_WalletInventory WHERE CryptoID = BlockchainCryptoId`, where `CryptoID` is the derived CASE column containing CryptoIDERC when set.

**Action needed**: No wiki change needed (the effective behavior is correctly documented). This is a code-level observation for the SP maintainer.

---

*Review items: 5 | Blocking: 0 | Priority updates: RN-001 (TodayAllocationPace formula validation), RN-004 (Tableau lineage)*
