# dbo.Wallets

> SCD Type 2 history table preserving temporal snapshots of wallet records, tracking wallet lifecycle changes including activation status and wallet type assignments.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, no PK constraint) |
| **Partition** | No |
| **Indexes** | 1 active (ix_Wallets CLUSTERED on EndDate, BeginDate) |

---

## 1. Business Meaning

This table is the temporal history of wallet records in the eToro crypto wallet system. Each row represents a point-in-time snapshot of a wallet's state, using the SCD Type 2 pattern (BeginDate/EndDate) to track how wallet attributes change over time. When a wallet's IsActive or IsActivated status changes, a new version row is created and the previous row's EndDate is closed.

The table captures the fundamental wallet entity: the association between a customer (Gcid), a blockchain cryptocurrency (BlockchainCryptoId), and a wallet type (WalletTypeId). Wallets are the core building block of the crypto custody system - each customer has one or more wallets, each for a specific cryptocurrency.

With 7,211 rows and data spanning from April 2018, this table is relatively small, suggesting it tracks only historical versions from early system operations or a specific subset of wallets. The live wallet data resides in the Wallet schema (Wallet.CustomerWallets). The overwhelming majority of wallets (99.97%) are WalletTypeId=5 (Customer), with only 2 being WalletTypeId=1 (Redeem). Notable: some wallets have negative GCIDs (-1, -2) or zero, indicating system/omnibus wallets.

---

## 2. Business Logic

### 2.1 Wallet Types and System Wallets

**What**: Wallets are classified by type, with special GCID values indicating system-owned wallets.

**Columns/Parameters Involved**: `Gcid`, `WalletTypeId`, `IsActive`, `IsActivated`

**Rules**:
- WalletTypeId from Dictionary.WalletTypes: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer, 6=C2F, 7=StakingRefund
- Gcid = 0: Omnibus/pool wallet (shared system wallet)
- Gcid < 0: Internal system wallets (e.g., -1, -2 are special platform wallets)
- Gcid > 0: Customer wallets (normal user wallets)
- IsActive and IsActivated are separate flags - a wallet can be activated (blockchain address generated) but not active (deactivated for compliance or migration)

### 2.2 Temporal Versioning (SCD Type 2)

**What**: Every change to a wallet's attributes creates a new temporal version.

**Columns/Parameters Involved**: `Id`, `BeginDate`, `EndDate`

**Rules**:
- Same pattern as all dbo history tables: BeginDate/EndDate range defines version validity
- Current version has EndDate close to the next change timestamp
- All historical versions are preserved for audit and reconciliation

---

## 3. Data Overview

| Id | WalletId | Gcid | BlockchainCryptoId | WalletTypeId | IsActive | IsActivated | Meaning |
|---|---|---|---|---|---|---|---|
| 26680 | E85D43D0-... | -1 | 1 (BTC) | 5 (Customer) | true | true | System wallet (Gcid=-1) for BTC, fully active - likely a platform operational wallet |
| 46748 | 8F4396FB-... | -2 | 1 (BTC) | 5 (Customer) | true | true | Second system wallet (Gcid=-2) for BTC - possibly a secondary operational wallet |
| 26556 | 57A4AE35-... | 0 | 3 (BCH) | 1 (Redeem) | true | true | Omnibus/pool wallet (Gcid=0) for BCH of type Redeem - used for consolidating redemption funds |
| 173922 | D7E9D690-... | 9355864 | 4 (XRP) | 5 (Customer) | true | true | Customer wallet for XRP, fully active and activated |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | - | CODE-BACKED | Wallet record identifier. Groups all temporal versions of the same wallet. Multiple rows share the same Id with different BeginDate/EndDate ranges as wallet attributes change. |
| 2 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | Unique wallet GUID. The primary identifier for the wallet across the platform. Links to Wallet.CustomerWallets and other Wallet schema tables. |
| 3 | Gcid | bigint | NO | - | VERIFIED | Global Customer ID. Identifies the wallet owner: positive values = customer wallets, 0 = omnibus/pool wallets, negative values (-1, -2) = internal system/platform operational wallets. |
| 4 | BlockchainCryptoId | int | NO | - | CODE-BACKED | Cryptocurrency this wallet holds. Maps to Wallet.CryptoTypes: 1=BTC, 2=ETH, 3=BCH, 4=XRP, etc. Each wallet is for a single cryptocurrency. |
| 5 | WalletTypeId | tinyint | NO | - | VERIFIED | Wallet type classification: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer, 6=C2F, 7=StakingRefund. (Dictionary.WalletTypes). 99.97% of wallets are type 5 (Customer). |
| 6 | IsActive | bit | NO | - | CODE-BACKED | Whether the wallet is currently active in the system. A wallet can be deactivated for compliance, migration, or customer account closure while retaining its blockchain address. |
| 7 | Occurred | datetime2(7) | NO | - | CODE-BACKED | Timestamp when the wallet event (creation or state change) originally occurred. This is the business event time, distinct from BeginDate which is the version validity start. |
| 8 | BeginDate | datetime2(7) | NO | - | CODE-BACKED | SCD Type 2 version start timestamp. When this particular snapshot of the wallet's state became effective. |
| 9 | EndDate | datetime2(7) | NO | - | CODE-BACKED | SCD Type 2 version end timestamp. When the next version was created (closing this version). |
| 10 | IsActivated | bit | NO | - | CODE-BACKED | Whether the wallet has been activated on the blockchain (i.e., has a generated address). Separate from IsActive: a wallet is activated when its blockchain address is provisioned, but may later be deactivated (IsActive=false) without losing its address. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WalletTypeId | Dictionary.WalletTypes | Lookup | Wallet classification: 1=Redeem through 7=StakingRefund |
| BlockchainCryptoId | Wallet.CryptoTypes | Implicit | Cryptocurrency held by this wallet (1=BTC, 2=ETH, etc.) |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in dbo schema code scan.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_Wallets | CLUSTERED | EndDate, BeginDate | - | - | Active |

Data compression: PAGE.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get current wallet snapshot (latest version)
```sql
SELECT Id, WalletId, Gcid, BlockchainCryptoId, WalletTypeId,
       IsActive, IsActivated, Occurred
FROM dbo.Wallets WITH (NOLOCK)
WHERE EndDate > GETDATE()
```

### 8.2 Full history for a specific wallet
```sql
SELECT Id, WalletId, Gcid, BlockchainCryptoId, WalletTypeId,
       IsActive, IsActivated, BeginDate, EndDate
FROM dbo.Wallets WITH (NOLOCK)
WHERE WalletId = 'E85D43D0-B7D6-488A-8184-764187DF294B'
ORDER BY BeginDate
```

### 8.3 Wallet type distribution with readable names
```sql
SELECT wt.Name AS WalletType, COUNT(*) AS Cnt
FROM dbo.Wallets w WITH (NOLOCK)
JOIN Dictionary.WalletTypes wt WITH (NOLOCK) ON wt.Id = w.WalletTypeId
GROUP BY wt.Name
ORDER BY Cnt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 7.6/10 (Elements: 8/10, Logic: 7/10, Relationships: 5/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.Wallets | Type: Table | Source: WalletDB/dbo/Tables/dbo.Wallets.sql*
