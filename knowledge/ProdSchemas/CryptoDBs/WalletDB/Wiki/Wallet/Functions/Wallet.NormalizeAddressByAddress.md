# Wallet.NormalizeAddressByAddress

> Scalar function that normalizes a blockchain address by stripping query parameters (everything after '?'), used for consistent address matching across different address format representations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns nvarchar(512) - normalized address |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.NormalizeAddressByAddress normalizes blockchain addresses by removing query string parameters that appear after a `?` character. Many blockchain protocols encode routing metadata in the address URL - for example, XRP destination tags (`?dt=12345`), Stellar memo IDs, and EOS memo fields. These suffixes are important for routing but should not affect address identity matching.

This function exists because the same logical blockchain address can appear with different query parameters in different contexts (e.g., a receive address with `?dt=100` and a send reference with `?dt=200`). Without normalization, address lookups would fail to match these as the same underlying address.

The function is called by `Wallet.GetWalletsByAddress` and `Wallet.GetWalletsByAddress_temp` to normalize user-provided address input before searching for matching wallets. It complements the `NormalizedAddress` computed column on `Wallet.WalletAddresses`, which performs a more comprehensive normalization that also handles protocol prefixes.

---

## 2. Business Logic

### 2.1 Query Parameter Stripping

**What**: Removes everything after the first `?` character from a blockchain address string to produce a canonical base address.

**Columns/Parameters Involved**: `@Address`

**Rules**:
- If `@Address` contains a `?` character, returns only the substring before it
- If `@Address` does not contain `?`, returns the full address unchanged
- Uses `CHARINDEX('?', @Address)` to locate the delimiter and `SUBSTRING` to extract the prefix
- Does NOT handle protocol prefixes (e.g., `bitcoin:`) - that is handled separately by computed columns on WalletAddresses

**Diagram**:
```
@Address input: "rN7GFkTz5jxSMb9HF?dt=12345"
                 |                  |
                 +-- base address --+-- query params (stripped)
                 |
                 v
Result: "rN7GFkTz5jxSMb9HF"
```

---

## 3. Data Overview

N/A for scalar function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Address | nvarchar(512) | YES | - | CODE-BACKED | Raw blockchain address string, potentially including query parameters (e.g., `?dt=12345` for XRP destination tags, `?memo=abc` for Stellar). Sourced from user input or wallet address columns. |
| 2 | RETURN | nvarchar(512) | YES | - | CODE-BACKED | The base blockchain address with query parameters removed. Used for address matching in wallet lookup procedures like `Wallet.GetWalletsByAddress`. Returns the address unchanged if no `?` is present. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.GetWalletsByAddress | Item (from input TVP) | Function Call | Normalizes each address from the input list before searching for matching wallets |
| Wallet.GetWalletsByAddress_temp | Item (from input TVP) | Function Call | Same usage pattern - temp/development variant |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.GetWalletsByAddress | Stored Procedure | Normalizes input addresses before wallet lookup |
| Wallet.GetWalletsByAddress_temp | Stored Procedure | Same usage - temp variant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for scalar function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Normalize an XRP address with destination tag
```sql
SELECT Wallet.NormalizeAddressByAddress('rN7GFkTz5jxSMb9HF?dt=12345')
-- Returns: 'rN7GFkTz5jxSMb9HF'
```

### 8.2 Address without parameters passes through unchanged
```sql
SELECT Wallet.NormalizeAddressByAddress('bc1q7ugqn4ssrcv0p2z4kt0abc123')
-- Returns: 'bc1q7ugqn4ssrcv0p2z4kt0abc123'
```

### 8.3 Normalize addresses from received transactions for matching
```sql
SELECT
    rt.Id,
    rt.SenderAddress,
    Wallet.NormalizeAddressByAddress(rt.SenderAddress) AS NormalizedSender
FROM Wallet.ReceivedTransactions rt WITH (NOLOCK)
WHERE rt.CryptoId = 4  -- XRP (commonly uses destination tags)
ORDER BY rt.Id DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.NormalizeAddressByAddress | Type: Scalar Function | Source: WalletDB/Wallet/Functions/Wallet.NormalizeAddressByAddress.sql*
