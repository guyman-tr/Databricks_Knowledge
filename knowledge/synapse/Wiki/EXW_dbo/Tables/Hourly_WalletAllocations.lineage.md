# EXW_dbo.Hourly_WalletAllocations — Column Lineage

**Object**: EXW_dbo.Hourly_WalletAllocations  
**Type**: Table  
**Generated**: 2026-04-20  
**ETL Writer**: EXW_dbo.SP_EXW_Hourly (TRUNCATE + INSERT, runs hourly, 7-day rolling window on Occurred)  
**Primary Source**: EXW_Wallet.CustomerWalletsView (row-level SELECT * with 7-day window)  
**Scope**: Customer wallet allocation events where Occurred >= last 7 days. Row-level — not aggregated.

---

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|--------------|---------------|-----------|------|
| 1 | ID | EXW_Wallet.CustomerWalletsView | Id (uniqueidentifier) | Passthrough. DWH note: nvarchar(1000) in EXW vs uniqueidentifier in source (GUID serialized as string). Aliased: `Id AS [ID]`. | Tier 1 |
| 2 | GCID | EXW_Wallet.CustomerWalletsView | Gcid (bigint) | Passthrough. DWH note: int in EXW DDL vs bigint in source — potential truncation for very large GCIDs, though none observed in practice. Aliased: `Gcid AS [GCID]`. | Tier 1 |
| 3 | CryptoID | EXW_Wallet.CustomerWalletsView | CryptoId (int) | Passthrough. Aliased: `CryptoId AS [CryptoID]`. | Tier 1 |
| 4 | Address | EXW_Wallet.CustomerWalletsView | Address (nvarchar(512)) | Passthrough. | Tier 1 |
| 5 | BlockchainProviderWalletId | EXW_Wallet.CustomerWalletsView | BlockchainProviderWalletId (nvarchar(100)) | Passthrough. DWH note: nvarchar(1000) in EXW DDL vs nvarchar(100) in source. | Tier 1 |
| 6 | Occurred | EXW_Wallet.CustomerWalletsView | Occurred (datetime2(7)) | Passthrough. DWH note: datetime in EXW DDL vs datetime2(7) in source (precision reduction). Filter anchor: `WHERE Occurred >= last 7 days`. | Tier 1 |
| 7 | WalletTypeId | EXW_Wallet.CustomerWalletsView | WalletTypeId (tinyint) | Passthrough. DWH note: int in EXW DDL vs tinyint in source. In practice always 5 (Customer) within a 7-day allocation window. | Tier 1 |
| 8 | IsActive | EXW_Wallet.CustomerWalletsView | IsActive (bit) | Passthrough. Always 1 in CustomerWalletsView (view enforces IsActive=1). DWH note: int in EXW DDL vs bit in source. | Tier 1 |
| 9 | Status | EXW_Wallet.CustomerWalletsView | Status (int, computed in view) | Passthrough. Status is computed in CustomerWalletsView: CASE WHEN IsActivated=1 THEN 0 ELSE 5 END. 96.9% are 0 (active); 3.1% are 5 (pending). | Tier 1 |
| 10 | WalletRecordId | EXW_Wallet.CustomerWalletsView | WalletRecordId (bigint) | Passthrough. Aliased from Wallet.Wallets.Id (auto-incrementing surrogate key). | Tier 1 |
| 11 | BlockchainCryptoId | EXW_Wallet.CustomerWalletsView | BlockchainCryptoId (int) | Passthrough. Determines blockchain network; may differ from CryptoID for ERC-20 tokens (e.g., USDC: CryptoID=107, BlockchainCryptoId=2/ETH). | Tier 1 |
| 12 | WalletProviderId | EXW_Wallet.CustomerWalletsView | WalletProviderId (int) | Passthrough. 1=BitGo, 2=CUG. | Tier 1 |
| 13 | ReportDate | ETL | n/a | CAST(GETDATE() AS DATE) — the SP run date. Same for all rows in a single run. | Tier 2 |
| 14 | AllocationDate | ETL | n/a | CAST(GETDATE() AS DATE) — hardcoded to the SP run date. **NOT the actual wallet allocation date** (use CAST(Occurred AS DATE) for the actual allocation date). Always equals ReportDate. See review-needed. | Tier 2 |
| 15 | UpdateDate | ETL | n/a | GETDATE() at INSERT time — exact SP run timestamp. | Tier 2 |
| 16 | CrytpoType | ETL (derived) | CryptoId, BlockchainCryptoId | CASE WHEN CryptoId = BlockchainCryptoId THEN 'MainCryptos' ELSE 'ERCCryptos' END. Note: column name contains typo 'CrytpoType' (Crytpo not Crypto) — preserved from DDL. | Tier 2 |

---

## Source Objects

| Source Object | Access Method | Role |
|--------------|---------------|------|
| EXW_Wallet.CustomerWalletsView | SELECT * WHERE Occurred >= last 7 days | Primary source: one row per customer-crypto wallet allocation in the window. Includes ERC-20 tokens (unlike Hourly_WalletInventory). |

---

## T1 Copy Verification

| DWH Column | Upstream Text (Wallet.CustomerWalletsView.md) |
|-----------|----------------------------------------------|
| ID | "The wallet's universal business key (aliased from Wallets.WalletId). Used as the primary identifier across the entire wallet system — referenced by SentTransactions, ReceivedTransactions, Conversions, Payments, Redemptions, and all balance/transaction lookups." |
| GCID | "Global Customer ID of the wallet owner. For customer wallets (type 5, 99.99% of rows), this is the real user. For system wallets (types 1-4, 6-7), this is a service account. Gcid=0 conventionally indicates omnibus/system wallets." |
| CryptoID | "The cryptocurrency asset visible in this wallet. FK to Wallet.CryptoTypes.CryptoID. Combined with Gcid for the standard wallet lookup pattern: WHERE Gcid = @gcid AND CryptoId = @cryptoId." |
| Address | "Blockchain public address associated with this wallet. Users send/receive crypto at this address. Format varies by blockchain: BTC starts with 1/3/bc1, ETH starts with 0x, SOL is base58. Aliased from Wallet.WalletPool.PublicAddress. May be NULL during initial creation before address generation completes." |
| BlockchainProviderWalletId | "External wallet identifier assigned by the custody provider (BitGo or CUG). Used for all API interactions with the provider. Aliased from Wallet.WalletPool.ProviderWalletId." |
| Occurred | "Timestamp when this crypto asset was first added to the wallet (when the user first acquired this crypto). From Wallet.WalletAssets.Occurred. Used for portfolio age tracking and ordering." |
| WalletTypeId | "Operational purpose of the wallet: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer (99.99%), 6=C2F, 7=StakingRefund. FK to Dictionary.WalletTypes." |
| IsActive | "Whether this wallet is currently operational. Always 1 in this view (WHERE filter), but included for schema compatibility. 1=active, 0=deactivated (excluded by view)." |
| Status | "Computed activation status: 0=Created/Active (wallet fully operational, IsActivated=1), 5=Pending activation (awaiting blockchain confirmation, IsActivated=0). Computed in view: CASE WHEN w.IsActivated = 1 THEN 0 ELSE 5 END. 99.6% of rows are Status=0." |
| WalletRecordId | "Auto-incrementing surrogate key from the base Wallets table. Aliased from Wallet.Wallets.Id. Useful for ordering by creation sequence." |
| BlockchainCryptoId | "The blockchain network this wallet operates on. FK to Wallet.BlockchainCryptos.Id. Determines which blockchain the Address belongs to. May differ from CryptoId for multi-token blockchains (e.g., ERC-20 tokens share the ETH blockchain)." |
| WalletProviderId | "Custody provider: 1=BitGo (97.5% of wallets, multi-sig), 2=CUG (2.5%, MPC-based, newer blockchains like SOL). FK to Dictionary.WalletProvider." |

---

## ETL Pipeline

```
WalletDB.Wallet.CustomerWalletsView (production — active customer wallet assignments)
  |-- EXW_Wallet.CustomerWalletsView (Synapse live view) --|
  |-- SP_EXW_Hourly: SELECT * WHERE Occurred >= last 7 days --|
  |-- + CAST(GETDATE() AS DATE) AS reportdate/allocationdate --|
  |-- + CASE WHEN CryptoId = BlockchainCryptoId THEN 'MainCryptos' ELSE 'ERCCryptos' END --|
  v
EXW_dbo.Hourly_WalletAllocations
  (9,877 rows, 44 cryptos, 3,178 customers, 7-day window, HASH(GCID), HEAP)
  UC Target: _Not_Migrated (operational KPI, Synapse-only)
```

---

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 12 | ID, GCID, CryptoID, Address, BlockchainProviderWalletId, Occurred, WalletTypeId, IsActive, Status, WalletRecordId, BlockchainCryptoId, WalletProviderId |
| Tier 2 | 4 | ReportDate, AllocationDate, UpdateDate, CrytpoType |
| Tier 3 | 0 | — |

**Upstream wiki**: CryptoDBs/WalletDB/Wiki/Wallet/Views/Wallet.CustomerWalletsView.md (12 T1 columns verified verbatim)
