# Dictionary.CryptoLiquidityWalletType

> Lookup table defining the types of crypto liquidity wallets used for managing crypto asset holdings across exchanges, dedicated wallets, and OTC desks.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

eToro holds crypto assets in different types of external wallets depending on the liquidity provider relationship. This table classifies those wallet types: Exchange wallets (at crypto exchanges like Binance/Coinbase), dedicated Wallet addresses (hot/cold wallets under eToro's control), and OTC (over-the-counter) desk accounts for large block trades.

Without this table, the system would have no way to distinguish between the different custody and trading venues where crypto assets are held. This distinction matters for risk management, reconciliation, and regulatory reporting — exchange wallets have different risk profiles than OTC desk accounts.

No procedures or views in the etoro SSDT project reference this table directly, suggesting it is consumed by application-layer services managing crypto liquidity infrastructure.

---

## 2. Business Logic

### 2.1 Wallet Type Risk/Purpose Hierarchy

**What**: Different wallet types serve different purposes in the crypto liquidity infrastructure.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- Exchange (0) wallets are held at third-party crypto exchanges — used for standard market orders and carry exchange counterparty risk
- Wallet (1) wallets are dedicated blockchain addresses controlled by eToro — used for holding/transferring assets with self-custody risk
- OTC (2) accounts are at over-the-counter trading desks — used for large block trades that would cause excessive slippage on exchanges

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | Exchange | Wallet held at a third-party crypto exchange (e.g., Binance, Coinbase) — used for standard market/limit order execution with exchange order book liquidity |
| 1 | Wallet | Dedicated blockchain wallet address under eToro's control — used for asset custody, transfers between venues, and cold storage of reserves |
| 2 | OTC | Account at an over-the-counter trading desk — used for large block trades (typically >$100K equivalent) to avoid market impact and slippage on public exchanges |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key identifying the wallet type. 0=Exchange, 1=Wallet, 2=OTC. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable wallet type name for configuration and monitoring interfaces. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

No direct SQL consumers found in the etoro SSDT project. Likely consumed by application-layer crypto liquidity services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CryptoLiquidityWalletType (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT project.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCryptoLiquidityWalletType | CLUSTERED | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all wallet types
```sql
SELECT  ID,
        Name
FROM    Dictionary.CryptoLiquidityWalletType WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Resolve wallet type for liquidity wallets (conceptual)
```sql
SELECT  w.WalletID,
        wt.Name AS WalletType,
        w.ProviderName
FROM    Trade.CryptoLiquidityWallet w WITH (NOLOCK)
        JOIN Dictionary.CryptoLiquidityWalletType wt WITH (NOLOCK) ON w.WalletTypeID = wt.ID
```

### 8.3 Combine wallet type with balance source
```sql
SELECT  wt.Name AS WalletType,
        wbs.Name AS BalanceSource
FROM    Dictionary.CryptoLiquidityWalletType wt WITH (NOLOCK)
        CROSS JOIN Dictionary.CryptoLiquidityWalletBalanceSourceType wbs WITH (NOLOCK)
ORDER BY wt.ID, wbs.ID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CryptoLiquidityWalletType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CryptoLiquidityWalletType.sql*
