# Wallet.GetWalletsByMultiGcids

> Returns wallets for multiple customer-crypto pairs with optional inclusion of rejected/pending wallet creation requests, providing a comprehensive wallet status view for AML, back-office, and balance services.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallets + optional rejected creation requests by GcidAndCryptoIds TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns wallet information for multiple customer-crypto pairs in a single call. It has two parts: (1) existing wallets from CustomerWalletsView matched against the TVP, and (2) optionally, rejected or pending wallet creation requests for customer-crypto pairs that don't have a wallet yet. The second part only runs when @IncludeRejectedWallets = 1.

Three services consume this: AML (checking wallet status across customer portfolios), back-office API (multi-customer wallet display), and balance service (bulk wallet resolution).

---

## 2. Business Logic

### 2.1 Rejected Wallet Request Inclusion

**What**: When @IncludeRejectedWallets = 1, includes wallet creation requests that failed or are pending, for customer-crypto pairs with no actual wallet.

**Columns/Parameters Involved**: `@IncludeRejectedWallets`, `Requests.RequestTypeId`, `RequestStatuses`

**Rules**:
- Only includes RequestTypeId = 0 (CreateWallet) requests
- Excludes pairs that already have an existing wallet (LEFT JOIN CustomerWalletsView IS NULL)
- Returns only the most recent request per Gcid+CryptoId (MAX(Id))
- Status mapping: RequestStatusId=2 (Failed) checks DetailsJson error codes:
  - WL.0102, WL.0105 -> Status 4 (specific rejection reasons)
  - Other failures -> Status 2 (general failure)
  - Non-failure -> Status 1 (pending/in-progress)
- Rejected wallets have NULL Id, Address, ProviderWalletId (no actual wallet exists)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GcidAndCryptoIds | Wallet.GcidAndCryptoIds | NO | - | VERIFIED | TVP of (Gcid, CryptoId) pairs to look up. |
| 2 | @IncludeRejectedWallets | bit | YES | 0 | VERIFIED | When 1, includes rejected/pending wallet creation requests for pairs without wallets. |
| 3 | Id (output) | uniqueidentifier | YES | - | CODE-BACKED | Wallet ID. NULL for rejected wallet requests. |
| 4 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 5 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. |
| 6 | Address (output) | nvarchar(512) | YES | - | CODE-BACKED | Wallet address. NULL for rejected. |
| 7 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference. NULL for rejected. |
| 8 | WalletStatus (output) | int | YES | - | VERIFIED | For existing wallets: from CustomerWalletsView.Status. For rejected: derived from request status (1=pending, 2=failed, 4=specific rejection). |
| 9 | RecordId (output) | bigint | YES | - | CODE-BACKED | Internal wallet record ID. NULL for rejected. |
| 10 | BlockchainCryptoId (output) | int | YES | - | CODE-BACKED | Base-chain crypto. NULL for rejected. |
| 11 | Occurred (output) | datetime2(7) | YES | - | CODE-BACKED | Wallet creation time or request status timestamp. |
| 12 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Provider ID. NULL for rejected. |
| 13 | IsActivated (output) | bit | YES | - | CODE-BACKED | Whether wallet is activated. Always 1 for rejected (placeholder). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GcidAndCryptoIds | Wallet.CustomerWalletsView | JOIN | Existing wallet lookup |
| RequestTypeId=0 | Wallet.Requests | JOIN | Failed creation requests |
| RequestId | Wallet.RequestStatuses | JOIN | Latest request status |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser | - | EXECUTE | Multi-customer wallet status check |
| BackApiUser | - | EXECUTE | Multi-customer wallet display |
| BalanceUser | - | EXECUTE | Bulk wallet resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsByMultiGcids (procedure)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.Requests (table)
+-- Wallet.RequestStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | Existing wallet lookup |
| Wallet.Requests | Table | Failed creation request lookup |
| Wallet.RequestStatuses | Table | Latest request status |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser, BackApiUser, BalanceUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get wallets for multiple customers
```sql
DECLARE @ids Wallet.GcidAndCryptoIds;
INSERT INTO @ids VALUES (30351701, 1), (30351701, 19), (18134253, 1);
EXEC Wallet.GetWalletsByMultiGcids @GcidAndCryptoIds = @ids;
```

### 8.2 Include rejected wallet creation requests
```sql
DECLARE @ids Wallet.GcidAndCryptoIds;
INSERT INTO @ids VALUES (30351701, 1), (30351701, 107);
EXEC Wallet.GetWalletsByMultiGcids @GcidAndCryptoIds = @ids, @IncludeRejectedWallets = 1;
```

### 8.3 Identify rejected vs existing
```sql
-- Rows with Id IS NULL are rejected/pending wallet creation requests
-- Rows with Id IS NOT NULL are existing wallets
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsByMultiGcids | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsByMultiGcids.sql*
