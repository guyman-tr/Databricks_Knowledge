# EXW_Wallet.CustomerWalletsView

> 1.78M-row CopyFromLake table containing customer crypto wallet assignments from the WalletDB production database. Tracks every active wallet-to-customer-to-crypto-asset mapping since June 2019, including blockchain addresses, provider wallet IDs, and activation status. Refreshed every 120 minutes via Generic Pipeline (Override/full snapshot) from `WalletDB.Wallet.CustomerWalletsView`.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | WalletDB.Wallet.CustomerWalletsView (production view joining Wallets + WalletPool + WalletAssets) |
| **Refresh** | Every 120 minutes, Override (full snapshot) via Generic Pipeline |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP (no clustered index) |
| **UC Target** | `wallet.bronze_walletdb_wallet_customerwalletsview` |
| **UC Format** | delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Bronze export (CopyFromLake) |

---

## 1. Business Meaning

`EXW_Wallet.CustomerWalletsView` is a denormalized snapshot of customer crypto wallet assignments, replicated from the production `WalletDB.Wallet.CustomerWalletsView` view every 2 hours via the Generic Pipeline (CopyFromLake, Override strategy). It contains 1,780,174 rows spanning from 2019-06-11 to present.

In production, the view is defined as a three-way JOIN across `Wallet.Wallets`, `Wallet.WalletPool`, and `Wallet.WalletAssets`, filtered to only active wallets (`WHERE w.IsActive = 1`). This means every row represents an active wallet-asset combination for a customer, with its corresponding blockchain address and provider wallet ID.

The table is a central reference for the EXW (eToroX / crypto wallet) domain. It is consumed by 14+ downstream stored procedures including `SP_EXW_WalletInventory`, `SP_EXW_Hourly`, `SP_EXW_FactBalance`, `SP_DimUser`, `SP_EXW_C2F_E2E`, `SP_AML_High_Risk_Wallet`, and others. Common use cases include resolving wallet ownership (GCID lookup by address), joining wallet metadata to transaction tables, and building wallet inventory reports.

The `Status` column is derived in the production view via a CASE expression on `IsActivated`: activated wallets get Status=0, non-activated get Status=5. The `etr_y`, `etr_ym`, `etr_ymd` columns and `SynapseUpdateDate` are added by the CopyFromLake pipeline infrastructure.

---

## 2. Business Logic

### 2.1 Wallet Activation Status Derivation

**What**: The Status column is computed from the IsActivated flag in the production view.
**Columns Involved**: Status, IsActivated
**Rules**:
- `CASE WHEN w.IsActivated = 1 THEN 0 ELSE 5 END` — activated wallets are Status 0, non-activated are Status 5
- In the live data: 1,772,855 rows (99.6%) have Status=0 (activated), 7,319 rows (0.4%) have Status=5 (not activated)
- Despite the WHERE clause filtering `IsActive = 1`, IsActivated can still be 0/false — IsActive and IsActivated are independent flags

### 2.2 Active Wallet Filter

**What**: The production view pre-filters to only active wallets.
**Columns Involved**: IsActive
**Rules**:
- The production view includes `WHERE w.IsActive = 1`, so every row in this table has `IsActive = 1` (True)
- This means deactivated wallets are excluded from this table entirely
- To find deactivated wallets, query `EXW_Wallet.Wallets` directly

### 2.3 Wallet-Asset-Address Resolution

**What**: Each row represents a unique combination of a wallet, a crypto asset, and a blockchain address.
**Columns Involved**: Id, CryptoId, Address, BlockchainCryptoId, WalletProviderId
**Rules**:
- `Id` (WalletId from Wallets) links to WalletPool for the blockchain address
- `CryptoId` (from WalletAssets) identifies the specific crypto asset held
- `BlockchainCryptoId` (from Wallets) identifies the blockchain network
- A single wallet (Id) can have multiple crypto assets (CryptoId values)
- WalletTypeId=5 dominates (1,780,070 rows of 1,780,174)

### 2.4 OmniBUS Wallet Identification

**What**: Wallets with Gcid=0 are eToro OmniBUS wallets (company-owned, not customer wallets).
**Columns Involved**: Gcid, Address
**Rules**:
- GCID=0 indicates an eToro corporate/omnibus wallet
- Used by support and compliance teams to verify if an external address belongs to eToro (Confluence: "How to check if the wallet address is an eToro OmniBUS")

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **Distribution**: ROUND_ROBIN — no hash key, data evenly distributed across all distributions
- **Index**: HEAP — no clustered index
- **Implication**: Full table scans on every query. For JOINs to other EXW_Wallet tables (which use HASH on WalletId), expect data movement. Consider filtering on Gcid or CryptoId early to reduce shuffle

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| How many wallets does a customer have? | `SELECT Gcid, COUNT(*) FROM EXW_Wallet.CustomerWalletsView WHERE Gcid = @gcid GROUP BY Gcid` |
| Which wallets hold a specific crypto? | `SELECT * FROM EXW_Wallet.CustomerWalletsView WHERE CryptoId = @cryptoId` |
| Is this address an eToro OmniBUS wallet? | `SELECT * FROM EXW_Wallet.CustomerWalletsView WHERE Address = @address` — if Gcid=0, it is OmniBUS |
| Wallet counts by blockchain | `SELECT BlockchainCryptoId, COUNT(*) FROM EXW_Wallet.CustomerWalletsView GROUP BY BlockchainCryptoId` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.WalletBalances | ON WalletId (via Id) | Get current crypto balances per wallet |
| EXW_Wallet.BlockchainCryptos | ON BlockchainCryptoId = Id | Resolve blockchain name from BlockchainCryptoId |
| EXW_Wallet.CryptoTypes | ON CryptoId = CryptoID | Resolve crypto asset name, symbol, and details |
| EXW_Wallet.TransactionsView | ON Id = WalletId | Link wallet to its send/receive transactions |
| DWH_dbo.Dim_Customer | ON Gcid = GCID | Enrich with customer demographics |

### 3.4 Gotchas

- **IsActive is always 1**: The production view filters `WHERE IsActive = 1`, so this column carries no discriminating information in this table
- **Status vs IsActivated**: Status is derived from IsActivated (0→Status 0, 0→Status 5). They are redundant but inversely mapped — check IsActivated for the raw flag
- **Address is PII-sensitive**: Contains actual blockchain public addresses. Handle with care in exports and reports
- **BlockchainProviderWalletId is PII-sensitive**: Provider-specific wallet identifier. Treat as sensitive
- **etr_y/etr_ym/etr_ymd are empty**: In the sampled data, these Generic Pipeline partition columns are empty strings, not NULL — they appear unused for this Override-strategy table
- **ROUND_ROBIN distribution**: JOINs to HASH-distributed tables (Wallets, WalletPool, WalletAssets) will incur data movement

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki (production source documentation) |
| Tier 2 | ETL-computed or pipeline-added column, transform visible in code |
| Tier 3 | Traceable to production source via code, but no upstream wiki exists |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Id | uniqueidentifier | YES | Wallet identifier. Renamed from Wallets.WalletId in the production view. Uniquely identifies the wallet assignment; used as JOIN key to WalletPool, WalletBalances, and transaction tables. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 2 | Gcid | int | YES | Global Customer ID. Identifies the customer who owns this wallet. GCID=0 indicates an eToro OmniBUS (corporate) wallet. FK to Dim_Customer. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 3 | CryptoId | int | YES | Crypto asset identifier from WalletAssets. Identifies the specific cryptocurrency held in the wallet (e.g., 1=BTC, 2=ETH, 21=XLM). FK to EXW_Wallet.CryptoTypes. (Tier 3 — WalletDB.Wallet.WalletAssets, no upstream wiki) |
| 4 | Address | varchar(max) | YES | Blockchain public address for the wallet. Renamed from WalletPool.PublicAddress. Format varies by blockchain (e.g., hex for ETH, base58 for BTC, bech32 for ADA). PII-sensitive. (Tier 3 — WalletDB.Wallet.WalletPool, no upstream wiki) |
| 5 | BlockchainProviderWalletId | varchar(max) | YES | Provider-specific wallet identifier from WalletPool.ProviderWalletId. Internal reference used by the blockchain custody provider (e.g., BitGo). PII-sensitive. (Tier 3 — WalletDB.Wallet.WalletPool, no upstream wiki) |
| 6 | Occurred | datetime2(7) | YES | Timestamp when the wallet asset was created or assigned. Sourced from WalletAssets.Occurred. Range: 2019-06-11 to present. (Tier 3 — WalletDB.Wallet.WalletAssets, no upstream wiki) |
| 7 | WalletTypeId | int | YES | Wallet type classification. 1=unknown, 2=unknown, 3=unknown, 4=unknown, 5=standard (99.99% of rows), 6=unknown, 7=unknown. 7 distinct values observed. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 8 | IsActive | bit | YES | Whether the wallet is active. Always 1 (True) in this table because the production view filters `WHERE w.IsActive = 1`. Deactivated wallets are excluded. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 9 | Status | int | YES | Wallet activation status derived from IsActivated. Computed in production view: `CASE WHEN w.IsActivated = 1 THEN 0 ELSE 5 END`. 0=activated (99.6%), 5=not activated (0.4%). (Tier 2 — WalletDB.Wallet.Wallets) |
| 10 | WalletRecordId | bigint | YES | Internal record identifier from Wallets.Id (renamed). Auto-incrementing surrogate key for the wallet record in the source Wallets table. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 11 | BlockchainCryptoId | int | YES | Blockchain network identifier from Wallets. Identifies which blockchain the wallet operates on (e.g., 1=Bitcoin, 2=Ethereum, 6=Litecoin, 18=Cardano, 21=Stellar). FK to EXW_Wallet.BlockchainCryptos. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 12 | WalletProviderId | int | YES | Custody provider identifier from WalletPool. Identifies the blockchain infrastructure provider managing the wallet (e.g., 1=BitGo, 2=Fireblocks). (Tier 3 — WalletDB.Wallet.WalletPool, no upstream wiki) |
| 13 | IsActivated | bit | YES | Whether the wallet has been activated by the customer. Source flag for the Status column derivation. 1=activated, 0=not yet activated. (Tier 3 — WalletDB.Wallet.Wallets, no upstream wiki) |
| 14 | etr_y | varchar(max) | YES | Generic Pipeline partition column — extraction year. Currently empty for this Override-strategy table. (Tier 2 — Generic Pipeline) |
| 15 | etr_ym | varchar(max) | YES | Generic Pipeline partition column — extraction year-month. Currently empty for this Override-strategy table. (Tier 2 — Generic Pipeline) |
| 16 | etr_ymd | varchar(max) | YES | Generic Pipeline partition column — extraction year-month-day. Currently empty for this Override-strategy table. (Tier 2 — Generic Pipeline) |
| 17 | SynapseUpdateDate | datetime | YES | Timestamp when the CopyFromLake pipeline last loaded this row into Synapse. All rows share the same value per load (full Override snapshot). Last observed: 2026-04-27 04:26:19. (Tier 2 — Generic Pipeline) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Id | Wallet.Wallets | WalletId | Rename |
| Gcid | Wallet.Wallets | Gcid | Passthrough |
| CryptoId | Wallet.WalletAssets | CryptoId | Passthrough |
| Address | Wallet.WalletPool | PublicAddress | Rename |
| BlockchainProviderWalletId | Wallet.WalletPool | ProviderWalletId | Rename |
| Occurred | Wallet.WalletAssets | Occurred | Passthrough |
| WalletTypeId | Wallet.Wallets | WalletTypeId | Passthrough |
| IsActive | Wallet.Wallets | IsActive | Passthrough (filtered WHERE = 1) |
| Status | Wallet.Wallets | IsActivated | CASE WHEN IsActivated = 1 THEN 0 ELSE 5 END |
| WalletRecordId | Wallet.Wallets | Id | Rename |
| BlockchainCryptoId | Wallet.Wallets | BlockchainCryptoId | Passthrough |
| WalletProviderId | Wallet.WalletPool | WalletProviderId | Passthrough |
| IsActivated | Wallet.Wallets | IsActivated | Passthrough |
| etr_y | Generic Pipeline | — | ETL partition (year) |
| etr_ym | Generic Pipeline | — | ETL partition (year-month) |
| etr_ymd | Generic Pipeline | — | ETL partition (year-month-day) |
| SynapseUpdateDate | Generic Pipeline | — | Load timestamp |

### 5.2 ETL Pipeline

```
WalletDB (production, WalletDB server)
  |-- Wallet.Wallets + Wallet.WalletPool + Wallet.WalletAssets
  |-- Production VIEW: Wallet.CustomerWalletsView
  |     (3-way JOIN, WHERE IsActive=1, Status=CASE on IsActivated)
  |
  |-- Generic Pipeline (Bronze export, Override, every 120 min) ---|
  v
Bronze/WalletDB/Wallet/CustomerWalletsView/ (Data Lake, delta)
  |
  |-- CopyFromLake ---|
  v
CopyFromLake_staging.[EXW_Wallet.CustomerWalletsView] (13 columns)
  |
  |-- Staging-to-target load (adds etr_y/etr_ym/etr_ymd, SynapseUpdateDate) ---|
  v
EXW_Wallet.CustomerWalletsView (1.78M rows, 17 columns)
  |
  |-- Generic Pipeline (Bronze export, Override, delta) ---|
  v
wallet.bronze_walletdb_wallet_customerwalletsview (UC Bronze)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---|---|---|
| Gcid | DWH_dbo.Dim_Customer | Customer dimension — resolves GCID to customer profile |
| CryptoId | EXW_Wallet.CryptoTypes | Crypto asset dictionary — resolves to asset name, symbol, InstrumentId |
| BlockchainCryptoId | EXW_Wallet.BlockchainCryptos | Blockchain network dictionary — resolves to blockchain name |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Join Condition | Purpose |
|---|---|---|
| EXW_Wallet.EXW_CustomerWalletsView (view) | Mirrors this table's production source logic | Synapse view replicating the production view definition |
| EXW_dbo.SP_EXW_WalletInventory | `cw` alias, JOIN on wallet/crypto keys | Builds the wallet inventory report |
| EXW_dbo.SP_EXW_Hourly | `cw.Id = vb.WalletId AND cw.CryptoId = vb.CryptoId` | Hourly wallet balance and transaction aggregation |
| EXW_dbo.SP_EXW_FactBalance | `CW` alias | Wallet balance fact table population |
| EXW_dbo.SP_EXW_UserCalculatedBalance | `t.Gcid = s.GCID` | User-level balance calculation |
| EXW_dbo.SP_EXW_FinanceReportsBalancesNew | `SELECT * INTO #CustomerWalletsView` | Finance reports balance aggregation |
| EXW_dbo.SP_DimUser | `W.GCID` | EXW user dimension enrichment with wallet data |
| EXW_dbo.SP_EXW_Transactions_Monthly | `T` alias | Monthly transaction aggregation |
| EXW_dbo.SP_EXW_InternalWallet | `cw` alias | Internal wallet identification |
| EXW_dbo.SP_EXW_FirstTimeWalletsAndUsers | `vw` alias, filtered by Occurred | First-time wallet creation tracking |
| EXW_dbo.SP_EXW_FactRedeemTransactions | `cw.Id = st.WalletId` | Redemption transaction processing |
| EXW_dbo.SP_EXW_FCA_UserLogin | `cwv.Occurred < @date` | FCA regulatory login tracking |
| EXW_dbo.SP_EXW_EthFeeSent_Blockchain | `ev.Address = eft.ReciverAddress` | Ethereum fee matching by address |
| EXW_dbo.SP_EXW_C2F_E2E | `cv.Gcid = er.Gcid AND cv.CryptoId = er.CryptoId` | Crypto-to-fiat end-to-end flow |
| EXW_dbo.SP_EXW_WalletEntity | `FROM CustomerWalletsView` | Legal entity assignment for wallets |
| EXW_dbo.SP_EXW_CompensationClosingCountries | Via EXW_CustomerWalletsView | Compensation closing country analysis |
| BI_DB_dbo.SP_AML_High_Risk_Wallet | `cwv` alias | AML high-risk wallet detection |

---

## 7. Sample Queries

### 7.1 Customer Wallet Portfolio

```sql
SELECT
    cwv.Gcid,
    ct.DisplayName AS CryptoName,
    bc.Name AS BlockchainName,
    cwv.Address,
    cwv.Occurred AS WalletCreated,
    cwv.Status,
    cwv.IsActivated
FROM EXW_Wallet.CustomerWalletsView cwv
JOIN EXW_Wallet.CryptoTypes ct ON cwv.CryptoId = ct.CryptoID
JOIN EXW_Wallet.BlockchainCryptos bc ON cwv.BlockchainCryptoId = bc.Id
WHERE cwv.Gcid = @gcid
ORDER BY cwv.Occurred;
```

### 7.2 Wallet Count by Blockchain Network

```sql
SELECT
    bc.Name AS Blockchain,
    COUNT(*) AS WalletCount,
    COUNT(DISTINCT cwv.Gcid) AS UniqueCustomers
FROM EXW_Wallet.CustomerWalletsView cwv
JOIN EXW_Wallet.BlockchainCryptos bc ON cwv.BlockchainCryptoId = bc.Id
GROUP BY bc.Name
ORDER BY WalletCount DESC;
```

### 7.3 Non-Activated Wallets (Status=5)

```sql
SELECT
    cwv.Gcid,
    cwv.Id AS WalletId,
    cwv.CryptoId,
    cwv.Occurred,
    cwv.WalletProviderId
FROM EXW_Wallet.CustomerWalletsView cwv
WHERE cwv.Status = 5
ORDER BY cwv.Occurred DESC;
```

---

## 8. Atlassian Knowledge Sources

- [How to check if the wallet address is an eToro OmniBUS](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/11272519879) — Confirms `SELECT * FROM Wallet.CustomerWalletsView WHERE Address=''` usage; GCID=0 means eToro OmniBUS wallet
- [eToro Crypto wallet on BackOffice (BO)](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/12460916944) — Describes wallet UI and relationship to crypto positions
- [Introduction - eToro crypto wallet](https://etoro-jira.atlassian.net/wiki/spaces/CS/pages/1137410256) — Business context for wallet send/receive functionality

---

*Generated: 2026-04-30 | Phases: 11/14*
*Tiers: 0 T1, 5 T2, 12 T3, 0 T4 | Elements: 17/17, Logic: 4/10*
*Object: EXW_Wallet.CustomerWalletsView | Type: Table (CopyFromLake) | Production Source: WalletDB.Wallet.CustomerWalletsView*
