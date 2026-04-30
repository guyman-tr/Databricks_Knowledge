# dbo.AdaReceives

> Temporary staging table holding raw Cardano (ADA) receive transaction data imported from an external source, using generic column names.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | None (no PK defined) |
| **Partition** | No |
| **Indexes** | 0 active |

---

## 1. Business Meaning

This table stores raw ADA (Cardano) receive transaction records, likely imported from a blockchain provider export or ad-hoc query. The generic column names (`column1` through `column6`) indicate this was a quick data import rather than a designed schema - the source data was loaded without mapping to meaningful column names.

The table serves as a staging area for ADA receive reconciliation or investigation. Without it, operators would lack a static reference of incoming ADA transactions for cross-referencing against the Wallet schema's `ReceivedTransactions` records.

No stored procedures, views, or functions reference this table. It is an orphaned artifact with no active data flow - rows were inserted via bulk import or ad-hoc script.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 4.

---

## 3. Data Overview

| column1 | column2 | column3 | column4 | column5 | column6 | Meaning |
|---------|---------|---------|---------|---------|---------|---------|
| 286 | faa8d034... | DD954C8B-... | ada | 100 | addr1qynah... | ADA receive of 100 ADA to a customer wallet, identified by blockchain transaction hash |
| 287 | df778299... | DD954C8B-... | ada | 137 | addr1qynah... | Second receive to the same wallet (same GUID), 137 ADA - different blockchain transaction |
| 288 | 1fe274aa... | BFCBB9F5-... | ada | 169 | addr1q8xjvv... | Receive to a different customer wallet, 169 ADA at a different Cardano address |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | column1 | bigint | NO | - | CODE-BACKED | Sequential record identifier. Based on sample data, appears to be a row ID from the source system (values 286, 287, 288...). |
| 2 | column2 | nvarchar(100) | NO | - | CODE-BACKED | Blockchain transaction hash. A 64-character hexadecimal string uniquely identifying the on-chain ADA transaction. |
| 3 | column3 | nvarchar(50) | NO | - | CODE-BACKED | Wallet identifier (GUID format). Maps to the internal wallet ID in the Wallet schema - likely Wallet.CustomerWallets.WalletId or BlockchainProviderWalletId. |
| 4 | column4 | nvarchar(50) | NO | - | CODE-BACKED | Cryptocurrency name/ticker. All sampled values are "ada", confirming this table is ADA-specific. |
| 5 | column5 | decimal(30,6) | NO | - | CODE-BACKED | Transaction amount in native ADA units. The receive amount credited to the wallet address. |
| 6 | column6 | nvarchar(150) | NO | - | CODE-BACKED | Cardano blockchain receive address (Bech32 format starting with `addr1q`). The destination address where ADA was received. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (no FK constraints).

### 5.2 Referenced By (other objects point to this)

No other objects reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

None.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find all receives for a specific wallet
```sql
SELECT column1 AS Id, column2 AS TxHash, column5 AS Amount, column6 AS Address
FROM dbo.AdaReceives WITH (NOLOCK)
WHERE column3 = 'DD954C8B-ABD3-470D-B241-FA332478E0D3'
ORDER BY column1
```

### 8.2 Total ADA received per wallet
```sql
SELECT column3 AS WalletId, COUNT(*) AS TxCount, SUM(column5) AS TotalADA
FROM dbo.AdaReceives WITH (NOLOCK)
GROUP BY column3
ORDER BY TotalADA DESC
```

### 8.3 Find large receive transactions
```sql
SELECT column1 AS Id, column2 AS TxHash, column3 AS WalletId,
       column5 AS Amount, column6 AS Address
FROM dbo.AdaReceives WITH (NOLOCK)
WHERE column5 > 1000
ORDER BY column5 DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 5.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AdaReceives | Type: Table | Source: WalletDB/dbo/Tables/dbo.AdaReceives.sql*
