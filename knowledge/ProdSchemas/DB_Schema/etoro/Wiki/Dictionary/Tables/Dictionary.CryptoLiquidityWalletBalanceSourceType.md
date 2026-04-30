# Dictionary.CryptoLiquidityWalletBalanceSourceType

> Lookup table defining the methods used to determine the balance of crypto liquidity wallets — whether from an API call, a local balance record, or no source (none).

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ID (PK) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

eToro maintains crypto liquidity wallets at external exchanges and OTC providers. To track how much crypto is held in each wallet, the system can query the balance from different sources. This table defines those sources: no source (None), the liquidity provider's API (API), or an internally maintained balance record (Balance).

Without this table, the system would have no standardized way to classify how a wallet's balance was determined. This is important for reconciliation — an API-sourced balance is the most reliable (real-time from the provider), while a Balance-sourced value is computed internally and may drift from the actual holdings.

No procedures or views in the etoro SSDT project reference this table directly, suggesting it is consumed by application-layer services that manage crypto liquidity wallet operations.

---

## 2. Business Logic

### 2.1 Balance Source Reliability Hierarchy

**What**: The source of a wallet balance indicates its reliability and freshness.

**Columns/Parameters Involved**: `ID`, `Name`

**Rules**:
- None (0) indicates the wallet balance source has not been configured or is unknown
- API (1) means the balance is fetched in real-time from the liquidity provider's REST/WebSocket API — most reliable
- Balance (2) means the balance is computed internally from transaction history — may drift from actual holdings

---

## 3. Data Overview

| ID | Name | Meaning |
|---|---|---|
| 0 | None | No balance source configured — the wallet balance is not being tracked or the source has not been assigned yet |
| 1 | API | Balance is fetched directly from the external crypto exchange or OTC provider's API — considered the authoritative real-time source for reconciliation |
| 2 | Balance | Balance is computed internally from the running sum of deposits, withdrawals, and trades — may drift from actual holdings if transactions are missed or delayed |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Primary key identifying the balance source type. 0=None, 1=API, 2=Balance. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Human-readable source type name used in configuration and monitoring displays. |

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
Dictionary.CryptoLiquidityWalletBalanceSourceType (table)
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
| PK_DictionaryCryptoLiquidityWalletBalanceSourceType | CLUSTERED | ID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all wallet balance source types
```sql
SELECT  ID,
        Name
FROM    Dictionary.CryptoLiquidityWalletBalanceSourceType WITH (NOLOCK)
ORDER BY ID
```

### 8.2 Identify API-sourced wallets (conceptual)
```sql
SELECT  w.WalletID,
        wbs.Name AS BalanceSource
FROM    Trade.CryptoLiquidityWallet w WITH (NOLOCK)
        JOIN Dictionary.CryptoLiquidityWalletBalanceSourceType wbs WITH (NOLOCK) ON w.BalanceSourceTypeID = wbs.ID
WHERE   wbs.Name = 'API'
```

### 8.3 Audit balance source distribution (conceptual)
```sql
SELECT  wbs.Name AS BalanceSource,
        COUNT(*) AS WalletCount
FROM    Trade.CryptoLiquidityWallet w WITH (NOLOCK)
        JOIN Dictionary.CryptoLiquidityWalletBalanceSourceType wbs WITH (NOLOCK) ON w.BalanceSourceTypeID = wbs.ID
GROUP BY wbs.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CryptoLiquidityWalletBalanceSourceType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CryptoLiquidityWalletBalanceSourceType.sql*
