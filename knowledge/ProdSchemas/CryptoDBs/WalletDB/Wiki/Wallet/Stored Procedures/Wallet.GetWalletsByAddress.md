# Wallet.GetWalletsByAddress

> Looks up wallets by a list of blockchain addresses with address normalization (stripping protocol prefixes), returning wallet details for each matching address for the eligibility and redeem persistor services.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns wallet rows by normalized address match from NvarcharListType TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure resolves wallets from a list of blockchain addresses. Addresses are first normalized using the `Wallet.NormalizeAddressByAddress` function (which strips protocol prefixes and query parameters) before matching against `WalletAddresses.NormalizedAddress`. This ensures consistent matching regardless of address format variations. The eligibility service uses this for address ownership verification, and the redeem persistor uses it for destination wallet resolution.

---

## 2. Business Logic

### 2.1 Address Normalization Before Matching

**What**: Incoming addresses are normalized before lookup to handle format variations.

**Columns/Parameters Involved**: `@Addresses`, `Wallet.NormalizeAddressByAddress()`, `WalletAddresses.NormalizedAddress`

**Rules**:
- Input addresses are processed through NormalizeAddressByAddress function
- Normalized addresses stored in a temp table with case-insensitive collation (SQL_Latin1_General_CP1_CI_AS)
- Matched against WalletAddresses.NormalizedAddress (computed PERSISTED column)
- Handles protocol prefixes (e.g., 'bitcoin:1ABC...' -> '1ABC...')

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Addresses | Wallet.NvarcharListType | NO | - | VERIFIED | TVP containing blockchain addresses to look up. |
| 2 | Id (output) | uniqueidentifier | NO | - | CODE-BACKED | Internal wallet ID. |
| 3 | Gcid (output) | bigint | NO | - | CODE-BACKED | Customer ID. |
| 4 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. |
| 5 | Address (output) | nvarchar(512) | NO | - | CODE-BACKED | Matched address from WalletAddresses. |
| 6 | BlockchainProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference (backward compat). |
| 7 | ProviderWalletId (output) | nvarchar | YES | - | CODE-BACKED | Provider reference alias. |
| 8 | RecordId (output) | bigint | YES | - | CODE-BACKED | Internal wallet record ID. |
| 9 | BlockchainCryptoId (output) | int | YES | - | CODE-BACKED | Base-chain crypto. |
| 10 | WalletProviderId (output) | int | YES | - | CODE-BACKED | Wallet provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Addresses | Wallet.WalletAddresses.NormalizedAddress | JOIN | Normalized address matching |
| WalletId | Wallet.CustomerWalletsView | JOIN | Wallet details |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| EligibilityUser | - | EXECUTE | Address ownership verification |
| RedeemPersistorUser | - | EXECUTE | Destination wallet resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetWalletsByAddress (procedure)
+-- Wallet.WalletAddresses (table)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.NormalizeAddressByAddress (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletAddresses | Table | Address lookup |
| Wallet.CustomerWalletsView | View | Wallet details |
| Wallet.NormalizeAddressByAddress | Function | Address normalization |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| EligibilityUser, RedeemPersistorUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Look up wallets by addresses
```sql
DECLARE @addrs Wallet.NvarcharListType;
INSERT INTO @addrs VALUES ('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa'), ('bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4');
EXEC Wallet.GetWalletsByAddress @Addresses = @addrs;
```

### 8.2 Direct equivalent
```sql
SELECT cw.Id, cw.Gcid, cw.CryptoId, wa.Address
FROM Wallet.WalletAddresses wa WITH (NOLOCK)
    JOIN Wallet.CustomerWalletsView cw WITH (NOLOCK) ON cw.Id = wa.WalletId
WHERE wa.NormalizedAddress = Wallet.NormalizeAddressByAddress('1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa');
```

### 8.3 Check if an address is known
```sql
SELECT COUNT(*) FROM Wallet.WalletAddresses WITH (NOLOCK) WHERE NormalizedAddress = '1a1zp1ep5qgefi2dmptftl5slmv7divfna';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetWalletsByAddress | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetWalletsByAddress.sql*
