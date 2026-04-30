# Wallet.GetAdaSlidingWindowFigures

> Generates a 24-hour sliding window report of ADA (Cardano) sent transaction amounts broken down by hour, plus total sent and pending redeem amounts, used for operational monitoring and liquidity management.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns hourly ADA send amounts + totals + pending redeems |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is an operational monitoring tool specifically for ADA (Cardano, CryptoId=18). It provides a sliding 24-hour view of outgoing ADA transaction volumes broken down by hour, the total sent amount, and the total pending redemption amount. Operations teams use this to monitor ADA withdrawal velocity, detect unusual spikes, and ensure sufficient liquidity in hot wallets.

Without this procedure, the operations team would lack real-time visibility into ADA outflows, risking hot wallet depletion and delayed withdrawals. ADA appears to have specific monitoring needs, likely due to its UTXO model and epoch-based staking mechanics which affect liquidity management.

The procedure is parameterless - it always looks at the last 24 hours and always targets CryptoId=18 (ADA). It excludes transactions in terminal failure statuses (4, 5, 6) from the sent calculation and counts pending (status=0) redemptions separately.

---

## 2. Business Logic

### 2.1 Hourly Sent Amount Calculation

**What**: Aggregates sent transaction output amounts by day/hour, excluding failed transactions.

**Columns/Parameters Involved**: SentTransactions, SentTransactionOutputs, SentTransactionStatuses

**Rules**:
- Looks back 24 hours from GETDATE()
- Filters to CryptoId = 18 (ADA)
- Excludes transactions whose latest status is IN (4, 5, 6) - these are terminal failure states
- Groups by Day + Hour for hourly granularity
- Amounts come from SentTransactionOutputs (individual outputs per transaction)

### 2.2 Three-Section Output

**What**: Returns hourly data, total sent, and pending redeems in a single result set.

**Columns/Parameters Involved**: Union of 3 queries

**Rules**:
- Sequence 1: Hourly breakdown (Day, Hour padded to 2 chars, Amount)
- Sequence 2: Total sent across the 24-hour window
- Sequence 3: Pending redemptions (status=0) amount = SUM(RequestedAmount - eToroFeeAmount)
- ISNULL wrapper on pending redeems returns '0' if none exist
- Ordered by Sequence, then Day, then Hour

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | - | Parameterless procedure. Hardcoded to CryptoId=18 (ADA) and last 24 hours. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Day | varchar | NO | - | CODE-BACKED | Date portion (YYYY-MM-DD format) for hourly rows, or label ("Total sent", "Pending redeems") for summary rows. |
| 2 | Hour | varchar | NO | - | CODE-BACKED | Hour of day (00-23, zero-padded) for hourly rows, or empty string for summary rows. |
| 3 | Units | decimal(36,0) | NO | - | CODE-BACKED | ADA amount in lovelace (whole units). For hourly rows: sum of sent outputs that hour. For "Total sent": 24h aggregate. For "Pending redeems": net redemption amount (requested minus fee). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.SentTransactions | Reader | Source of sent transaction data |
| - | Wallet.SentTransactionOutputs | Reader | Source of sent amounts (per output) |
| - | Wallet.SentTransactionStatuses | Reader | Filters out failed transactions |
| - | Wallet.Redemptions | Reader | Source of pending redemption amounts |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by operations monitoring tools.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAdaSlidingWindowFigures (procedure)
  ├── Wallet.SentTransactions (table)
  ├── Wallet.SentTransactionOutputs (table)
  ├── Wallet.SentTransactionStatuses (table)
  └── Wallet.Redemptions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.SentTransactions | Table | SELECT - sent transactions in last 24h |
| Wallet.SentTransactionOutputs | Table | JOIN - amounts per transaction |
| Wallet.SentTransactionStatuses | Table | Subquery - latest status filter |
| Wallet.Redemptions | Table | SELECT - pending redemption totals |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses temp tables #SentTransactions and #Sums for intermediate calculations
- DROP TABLE IF EXISTS for temp table cleanup
- Hardcoded CryptoId = 18 and DATEADD(DAY, -1, GETDATE())
- UNION ALL combines three result sections
- CAST to DECIMAL(36,0) for amount display

---

## 8. Sample Queries

### 8.1 Execute the monitoring report
```sql
EXEC Wallet.GetAdaSlidingWindowFigures
```

### 8.2 Manual check of recent ADA sent transactions
```sql
SELECT TOP 20 st.Id, st.Occurred, sto.Amount, st.CryptoId
FROM Wallet.SentTransactions st WITH (NOLOCK)
JOIN Wallet.SentTransactionOutputs sto WITH (NOLOCK) ON sto.SentTransactionId = st.Id
WHERE st.CryptoId = 18 AND st.Occurred > DATEADD(DAY, -1, GETDATE())
ORDER BY st.Id DESC
```

### 8.3 Pending ADA redemptions
```sql
SELECT Id, RequestingGCID, RequestedAmount, eToroFeeAmount,
       RequestedAmount - eToroFeeAmount AS NetAmount
FROM Wallet.Redemptions WITH (NOLOCK)
WHERE CryptoId = 18 AND RedemptionStatus = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAdaSlidingWindowFigures | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAdaSlidingWindowFigures.sql*
