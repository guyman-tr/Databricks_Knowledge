# Wallet.UpdateAddressBalances_FOR_ERC20

> ERC-20 token-specific variant of UpdateAddressBalances with the same temporal balance versioning logic, handling token balance updates separately from base-chain balance updates.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE + INSERT into WalletBalances (ERC-20 token variant) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the ERC-20 token-specific variant of UpdateAddressBalances. While the base procedure handles native blockchain balances (BTC, ETH, etc.), this variant handles ERC-20 token balances (USDT, USDC, LINK, etc.) which share the same Ethereum wallet address but have different CryptoIds. The logic is identical - temporal versioning with change detection - but separated for ERC-20 tokens to handle their distinct provider reporting pipeline. The balance service uses this.

---

## 2. Business Logic

### 2.1 Same Temporal Pattern as Base Procedure

**What**: Identical temporal balance versioning with change detection, specific to ERC-20 tokens.

**Rules**:
- Same logic as UpdateAddressBalances: resolve BalanceAccountID, detect changes, temporal UPDATE + INSERT
- Separated because ERC-20 token balances come from a different provider API endpoint

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AddressBalances | Wallet.CurrentBalanceType | NO | - | VERIFIED | TVP of (BalanceAccountID, CryptoId, Balance) for ERC-20 tokens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| BalanceAccountID | Wallet.WalletAddresses | JOIN | Address resolution |
| - | Wallet.WalletBalances | UPDATE + INSERT | Temporal versioning |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser | - | EXECUTE | ERC-20 token balance ingestion |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.UpdateAddressBalances_FOR_ERC20 (procedure)
+-- Wallet.WalletAddresses (table)
+-- Wallet.WalletBalances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WalletAddresses | Table | BalanceAccountID resolution |
| Wallet.WalletBalances | Table | Temporal UPDATE + INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BalanceUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Update ERC-20 balances
```sql
DECLARE @balances Wallet.CurrentBalanceType;
INSERT INTO @balances VALUES ('BA-12345', 107, 1500.0); -- e.g., USDT token balance
EXEC Wallet.UpdateAddressBalances_FOR_ERC20 @AddressBalances = @balances;
```

### 8.2 Compare with base procedure
```sql
-- Native chain (BTC, ETH): EXEC Wallet.UpdateAddressBalances @AddressBalances = @balances;
-- ERC-20 tokens (USDT, LINK): EXEC Wallet.UpdateAddressBalances_FOR_ERC20 @AddressBalances = @balances;
```

### 8.3 Check token balances
```sql
SELECT wb.*, wa.BalanceAccountID FROM Wallet.WalletBalances wb WITH (NOLOCK)
    JOIN Wallet.WalletAddresses wa WITH (NOLOCK) ON wa.Id = wb.WalletAddressesId
WHERE wb.DateTo = '3000-01-01' AND wb.CryptoId = 107;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.UpdateAddressBalances_FOR_ERC20 | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.UpdateAddressBalances_FOR_ERC20.sql*
