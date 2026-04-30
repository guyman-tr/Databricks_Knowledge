# dbo.Monitor_Omnibus_Alert

> Monitoring view that displays current balances of all omnibus (pool) wallets across all cryptocurrencies, used for operational alerts on omnibus fund levels.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | Base tables: Wallet.CustomerWalletsView, Wallet.WalletBalances |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This view provides a real-time monitoring dashboard of omnibus (pool) wallet balances across all supported cryptocurrencies. Omnibus wallets (identified by Gcid=0) are shared platform wallets used for consolidating customer funds by operation type (Redeem, Funding, Payment, Conversion, C2F, StakingRefund). Monitoring their balances is critical for ensuring the platform has sufficient liquidity for operations.

Without this view, operations teams would need to manually query multiple tables to check omnibus wallet health. The view joins customer wallet data with balance snapshots and enriches with wallet type names and crypto names for immediate human readability. It is the data source for the `Monitoring.GetMonitorOmnibusAlert` stored procedure, which likely feeds alerting dashboards.

The view filters to `Gcid = 0` (omnibus wallets) and joins to the latest balance (DateTo = '3000', the SCD Type 2 "current" marker), providing a point-in-time snapshot of all active omnibus wallet balances.

---

## 2. Business Logic

### 2.1 Omnibus Wallet Identification

**What**: The view isolates omnibus/pool wallets by filtering on Gcid = 0.

**Columns/Parameters Involved**: `Gcid` (from Wallet.CustomerWalletsView)

**Rules**:
- Gcid = 0 identifies omnibus wallets (platform-owned, not customer-owned)
- Each omnibus wallet has a WalletTypeId indicating its purpose: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer, 6=C2F, 7=StakingRefund
- The view shows one row per omnibus wallet per cryptocurrency

### 2.2 Current Balance Retrieval

**What**: The view joins to the latest (current) balance snapshot using the SCD Type 2 "far future" EndDate pattern.

**Columns/Parameters Involved**: `Balance`, `DateFrom` (from Wallet.WalletBalances)

**Rules**:
- `DateTo = '3000'` filters to only the current active balance record
- `Balance` is the current crypto balance in native units
- `DateFrom` (aliased as LastUpdated) shows when the balance was last changed

---

## 3. Data Overview

| OmnibusType | Address | CryptoName | Balance | LastUpdated | WalletTypeId | Meaning |
|---|---|---|---|---|---|---|
| Redeem | 339kMy4j... | BTC | 30.87 | 2026-04-15 | 1 | Main BTC redemption omnibus wallet with ~31 BTC - highest balance, actively processing redemptions |
| Funding | 3ENhxrVV... | BTC | 0.05 | 2021-11-15 | 3 | BTC funding omnibus - very low balance, last updated 2021 suggests this path is no longer active |
| Payment | 38w4dPuG... | BTC | 0.008 | 2022-09-28 | 4 | BTC payment omnibus - minimal residual balance, payment path appears dormant |
| Conversion | 3MrvPSmf... | BTC | 0.004 | 2023-07-03 | 2 | BTC conversion omnibus - near-zero balance |
| C2F | 3LVWZzKH... | BTC | 0.005 | 2023-02-14 | 6 | BTC crypto-to-fiat omnibus - minimal residual balance |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OmnibusType | (derived) | NO | - | VERIFIED | Wallet type display name from Dictionary.WalletTypes: "Redeem", "Conversion", "Funding", "Payment", "Customer", "C2F", "StakingRefund". Source: `Dictionary.WalletTypes.Name` via JOIN on WalletTypeId. |
| 2 | Address | nvarchar | NO | - | CODE-BACKED | Blockchain public address of the omnibus wallet. Source: `Wallet.CustomerWalletsView.Address`. The on-chain address where pooled funds are held. |
| 3 | Id | uniqueidentifier | NO | - | CODE-BACKED | Wallet identifier (GUID). Source: `Wallet.CustomerWalletsView.Id`. Internal unique ID for the omnibus wallet. |
| 4 | CryptoID | int | NO | - | CODE-BACKED | Cryptocurrency identifier. Source: `Wallet.CryptoTypes.CryptoID`. Maps to crypto: 1=BTC, 2=ETH, 3=BCH, 4=XRP, etc. |
| 5 | CryptoName | varchar | NO | - | CODE-BACKED | Cryptocurrency display name. Source: `Wallet.CryptoTypes.Name`. Human-readable crypto name (BTC, ETH, etc.). |
| 6 | Balance | decimal | NO | - | VERIFIED | Current balance of the omnibus wallet in native crypto units. Source: `Wallet.WalletBalances.Balance` filtered to the current record (DateTo='3000'). This is the key metric for alerting. |
| 7 | LastUpdated | datetime2 | NO | - | CODE-BACKED | Timestamp when the balance was last changed. Source: `Wallet.WalletBalances.DateFrom`. Stale dates may indicate inactive omnibus wallets. |
| 8 | WalletTypeId | tinyint | NO | - | CODE-BACKED | Wallet type ID: 1=Redeem, 2=Conversion, 3=Funding, 4=Payment, 5=Customer, 6=C2F, 7=StakingRefund. Source: `Wallet.CustomerWalletsView.WalletTypeId`. (Dictionary.WalletTypes) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (base table) | Wallet.CustomerWalletsView | JOIN | Provides wallet address, ID, Gcid, CryptoId, WalletTypeId |
| (base table) | Wallet.WalletBalances | JOIN | Provides Balance and DateFrom (LastUpdated) for current record |
| WalletTypeId | Dictionary.WalletTypes | JOIN | Provides OmnibusType display name |
| CryptoID | Wallet.CryptoTypes | JOIN | Provides CryptoName display name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Monitoring.GetMonitorOmnibusAlert | - | READER | Reads all rows from this view for alerting |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.Monitor_Omnibus_Alert (view)
  +-- Wallet.CustomerWalletsView (view)
  +-- Wallet.WalletBalances (table)
  +-- Dictionary.WalletTypes (table)
  +-- Wallet.CryptoTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | JOINed - provides wallet master data (Address, Id, Gcid, CryptoId, WalletTypeId) |
| Wallet.WalletBalances | Table | JOINed on WalletId and CryptoId with DateTo='3000' filter - provides current balance |
| Dictionary.WalletTypes | Table | JOINed on WalletTypeId - provides wallet type display name |
| Wallet.CryptoTypes | Table | JOINed on CryptoID - provides cryptocurrency display name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Monitoring.GetMonitorOmnibusAlert | Stored Procedure | Reads from this view with NOLOCK |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view (not indexed).

### 7.2 Constraints

None. View has no SCHEMABINDING.

---

## 8. Sample Queries

### 8.1 Check all omnibus wallet balances
```sql
SELECT OmnibusType, CryptoName, Balance, LastUpdated, Address
FROM dbo.Monitor_Omnibus_Alert WITH (NOLOCK)
ORDER BY CryptoName, OmnibusType
```

### 8.2 Find omnibus wallets not updated recently (potential issues)
```sql
SELECT OmnibusType, CryptoName, Balance, LastUpdated,
       DATEDIFF(DAY, LastUpdated, GETDATE()) AS DaysSinceUpdate
FROM dbo.Monitor_Omnibus_Alert WITH (NOLOCK)
WHERE DATEDIFF(DAY, LastUpdated, GETDATE()) > 30
ORDER BY DaysSinceUpdate DESC
```

### 8.3 Total omnibus balance by crypto in USD-equivalent context
```sql
SELECT CryptoName, COUNT(*) AS WalletCount,
       SUM(Balance) AS TotalBalance
FROM dbo.Monitor_Omnibus_Alert WITH (NOLOCK)
GROUP BY CryptoName
ORDER BY TotalBalance DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 8.8/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.Monitor_Omnibus_Alert | Type: View | Source: WalletDB/dbo/Views/dbo.Monitor_Omnibus_Alert.sql*
