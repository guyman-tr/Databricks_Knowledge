# Wallet.GetDoubleSpendRedeems

> Detects redemption records that have been associated with multiple sent transactions (potential double-spend), by analyzing the RedemptionsHistory for duplicate SendRequestCorrelationIds and verifying the associated sent transactions were confirmed on-chain.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns redemptions with multiple confirmed send correlations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a fraud/anomaly detection tool that identifies redemptions which were processed more than once on the blockchain. A "double spend redeem" occurs when a single redemption request resulted in multiple blockchain transactions, each confirmed (status=2). This could indicate a system bug, race condition, or intentional exploitation.

Without this procedure, operations could not detect and remediate double-spend redemptions, leading to financial losses from duplicate payouts.

The procedure uses a complex nested query: it finds redemptions in RedemptionsHistory that have more than one distinct SendRequestCorrelationId within the lookback period, then verifies each associated sent transaction was confirmed on-chain (latest SentTransactionStatus = 2) AND produced a matching received transaction (indicating on-chain confirmation).

---

## 2. Business Logic

### 2.1 Double-Spend Detection Criteria

**What**: Identifies redemptions with multiple confirmed blockchain sends.

**Columns/Parameters Involved**: RedemptionsHistory, SentTransactions, ReceivedTransactions, SentTransactionStatuses

**Rules**:
- Lookback window: @DaysBack (default 7 days)
- Must have more than 1 distinct SendRequestCorrelationId in RedemptionsHistory
- Each send must have latest SentTransactionStatus = 2 (confirmed)
- Each send must have a matching ReceivedTransaction (same BlockchainTransactionId) confirming on-chain execution
- Returns the current Redemptions row for each detected double-spend

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DaysBack | int | YES | 7 | CODE-BACKED | Number of days to look back for double-spend detection. Defaults to 7. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Redemptions | Reader | Returns the flagged redemption records |
| - | RedemptionsHistory | Reader | Detects multiple send correlations per redemption |
| - | Wallet.SentTransactions | Reader | Verifies blockchain send execution |
| - | Wallet.ReceivedTransactions | Reader | Verifies on-chain confirmation |
| - | Wallet.SentTransactionStatuses | Reader | Checks send transaction is confirmed (status=2) |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetDoubleSpendRedeems (procedure)
  ├── Wallet.Redemptions (table)
  ├── RedemptionsHistory (table)
  ├── Wallet.SentTransactions (table)
  ├── Wallet.ReceivedTransactions (table)
  └── Wallet.SentTransactionStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | Final SELECT source |
| RedemptionsHistory | Table | Double-spend detection (GROUP BY HAVING) |
| Wallet.SentTransactions | Table | Blockchain send verification |
| Wallet.ReceivedTransactions | Table | On-chain confirmation check |
| Wallet.SentTransactionStatuses | Table | Send status verification (status=2) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON
- Complex nested subqueries with GROUP BY HAVING COUNT(DISTINCT) > 1
- Correlated subquery for latest sent transaction status
- No NOLOCK hints on some tables (may indicate intentional consistency reads)

---

## 8. Sample Queries

### 8.1 Detect double-spend redeems in last 7 days
```sql
EXEC Wallet.GetDoubleSpendRedeems
```

### 8.2 Detect with custom lookback
```sql
EXEC Wallet.GetDoubleSpendRedeems @DaysBack = 30
```

### 8.3 Manual check for redemptions with multiple sends
```sql
SELECT rh.Id, COUNT(DISTINCT rh.SendRequestCorrelationId) AS SendCount
FROM RedemptionsHistory rh WITH (NOLOCK)
WHERE rh.SendRequestCorrelationId IS NOT NULL
  AND rh.BeginDate >= DATEADD(DAY, -7, GETDATE())
GROUP BY rh.Id
HAVING COUNT(DISTINCT rh.SendRequestCorrelationId) > 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetDoubleSpendRedeems | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetDoubleSpendRedeems.sql*
