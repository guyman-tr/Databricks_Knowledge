# Wallet.StuckTransactionsInTheBlockchinCountByCrypto

> Returns a count of stuck blockchain transactions grouped by cryptocurrency, summarizing how many sent transactions are in Pending (0) or Error (3) status beyond the threshold for monitoring dashboards.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns COUNT grouped by CryptoId for stuck transactions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the aggregated companion to StuckTransactionsInTheBlockchain. While that SP returns individual stuck transactions for investigation, this one returns a per-crypto count for dashboard display. The monitoring team and monitor service use this for quick health checks - a rising count for any crypto indicates a systemic issue with that blockchain network. Note: the SP name contains a legacy typo ("Blockchin" instead of "Blockchain").

---

## 2. Business Logic

### 2.1 Per-Crypto Stuck Count

**What**: Counts stuck transactions grouped by cryptocurrency.

**Rules**:
- Same status criteria: latest SentTransactionStatuses.StatusId IN (0, 3)
- Same age filter: DATEADD(MINUTE, @MaxMinutes, Occurred) < GETDATE()
- GROUP BY CryptoId, CryptoTypes.Name
- Simpler than the detail SP - no CustomerWalletsView/Outputs/Requests joins

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxMinutes | int | YES | 720 | VERIFIED | Threshold in minutes. Default 12 hours. |
| 2 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency. |
| 3 | Name (output) | varchar | NO | - | CODE-BACKED | Crypto display name (e.g., 'BTC', 'ETH'). |
| 4 | count (output) | int | NO | - | CODE-BACKED | Number of stuck transactions for this crypto. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.SentTransactions | Source | Stuck transactions |
| - | Wallet.SentTransactionStatuses | Subquery | Latest status |
| - | Wallet.CryptoTypes | JOIN | Crypto name |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MonitorTeam, MonitorUser | - | EXECUTE | Dashboard stuck counts |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StuckTransactionsInTheBlockchinCountByCrypto (procedure)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Wallet.CryptoTypes (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | Source |
| Wallet.SentTransactionStatuses | Table | Status subquery |
| Wallet.CryptoTypes | Table | Crypto name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MonitorTeam, MonitorUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get stuck counts by crypto
```sql
EXEC Wallet.StuckTransactionsInTheBlockchinCountByCrypto;
```

### 8.2 Custom threshold
```sql
EXEC Wallet.StuckTransactionsInTheBlockchinCountByCrypto @MaxMinutes = 60;
```

### 8.3 Get both summary and detail
```sql
EXEC Wallet.StuckTransactionsInTheBlockchinCountByCrypto; -- Summary counts
EXEC Wallet.StuckTransactionsInTheBlockchain; -- Individual details
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StuckTransactionsInTheBlockchinCountByCrypto | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StuckTransactionsInTheBlockchinCountByCrypto.sql*
