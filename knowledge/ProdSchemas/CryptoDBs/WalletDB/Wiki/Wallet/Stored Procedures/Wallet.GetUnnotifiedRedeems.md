# Wallet.GetUnnotifiedRedeems

> Identifies completed or permanently failed redemption send transactions that have not been notified back to the billing system within a configurable timeout, supporting terminal-status notification for the redeem scheduler.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns sent transactions for SentToExecuter redemptions in terminal status |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure finds redemption-related sent transactions that have reached a terminal blockchain status (Verified, PermanentError, WavedError, or Timeout) but haven't been notified back to the billing/trading system within the configurable timeout. This is the complement to `Wallet.GetUnnotifiedRedeemRequests` - while that SP finds redemptions that failed before creating a blockchain transaction, this SP finds redemptions where the blockchain transaction completed (or permanently failed) but the notification hasn't been sent.

The redeem scheduler uses this to ensure all terminal-state redemption transactions are reported back to the billing system for position reconciliation.

---

## 2. Business Logic

### 2.1 Terminal Status Detection for Redemption Sends

**What**: Finds sent transactions that reached a terminal blockchain status but haven't been notified.

**Columns/Parameters Involved**: `RedemptionStatus`, `SentTransactionStatuses.StatusId`, `Dictionary.TransactionStatus.Name`

**Rules**:
- Starts with Redemptions WHERE RedemptionStatus = 2 (SentToExecuter)
- JOINs to SentTransactions via CorrelationId (these have a blockchain tx, unlike the sibling SP)
- CROSS APPLY gets latest SentTransactionStatuses with Dictionary.TransactionStatus name
- Filters for terminal statuses: 'Verified', 'PermanentError', 'WavedError', 'Timeout'
- Time filter: status occurred more than @ExecuterMaxProcessingTimeMinutes ago
- Returns the sent transaction details for notification

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExecuterMaxProcessingTimeMinutes | int | NO | - | VERIFIED | Maximum time in minutes before a terminal-status transaction is flagged as unnotified. |
| 2 | Id (output) | bigint | NO | - | CODE-BACKED | Sent transaction ID. FK to Wallet.SentTransactions.Id. |
| 3 | BlockchainTransactionId (output) | nvarchar(100) | NO | - | CODE-BACKED | On-chain transaction hash. |
| 4 | VerificationEndTime (output) | datetime2(7) | YES | - | CODE-BACKED | When the terminal status was reached (aliased from LastStatusOccurred). |
| 5 | StatusId (output) | tinyint | NO | - | VERIFIED | Terminal blockchain status: 2=Verified (success), 5=PermanentError, 6=WavedError, 4=Timeout. See [Transaction Status](../../_glossary.md#transaction-status). |
| 6 | CryptoId (output) | int | NO | - | CODE-BACKED | Cryptocurrency of the sent transaction. FK to Wallet.CryptoTypes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedemptionStatus=2 | Wallet.Redemptions | Filter | SentToExecuter redemptions |
| SendRequestCorrelationId | Wallet.SentTransactions.CorrelationId | JOIN | Links to the actual blockchain tx |
| SentTransactionId | Wallet.SentTransactionStatuses | CROSS APPLY | Latest terminal status |
| StatusId | Dictionary.TransactionStatus.Name | JOIN | Human-readable status filter |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| RedeemSchedulerUser | - | EXECUTE | Terminal-status notification processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetUnnotifiedRedeems (procedure)
+-- Wallet.Redemptions (table)
+-- Wallet.SentTransactions (table)
+-- Wallet.SentTransactionStatuses (table)
+-- Dictionary.TransactionStatus (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Redemptions | Table | Source of SentToExecuter redemptions |
| Wallet.SentTransactions | Table | JOIN for blockchain transaction details |
| Wallet.SentTransactionStatuses | Table | CROSS APPLY for terminal status check |
| Dictionary.TransactionStatus | Table | JOIN for status name filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| RedeemSchedulerUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Find unnotified terminal redeems older than 30 minutes
```sql
EXEC Wallet.GetUnnotifiedRedeems @ExecuterMaxProcessingTimeMinutes = 30;
```

### 8.2 Full redemption notification pipeline
```sql
-- Step 1: Find failed redemptions without blockchain tx
EXEC Wallet.GetUnnotifiedRedeemRequests @ExecuterMaxProcessingTimeMinutes = 30;
-- Step 2: Find completed/failed redemptions with blockchain tx (this SP)
EXEC Wallet.GetUnnotifiedRedeems @ExecuterMaxProcessingTimeMinutes = 30;
```

### 8.3 Direct diagnostic query
```sql
SELECT st.Id, st.BlockchainTransactionId, st.CryptoId,
    sts.LastStatusOccurred, sts.StatusId, sts.LastStatusName
FROM Wallet.Redemptions re WITH (NOLOCK)
    JOIN Wallet.SentTransactions st WITH (NOLOCK) ON st.CorrelationId = re.SendRequestCorrelationId
    CROSS APPLY (
        SELECT TOP 1 sts.Occurred LastStatusOccurred, sts.StatusId, ts.Name LastStatusName
        FROM Wallet.SentTransactionStatuses sts WITH (NOLOCK)
            JOIN Dictionary.TransactionStatus ts WITH (NOLOCK) ON ts.Id = sts.StatusId
        WHERE sts.SentTransactionId = st.Id ORDER BY sts.Id DESC
    ) sts
WHERE re.RedemptionStatus = 2
    AND sts.LastStatusName IN ('Verified', 'PermanentError', 'WavedError', 'Timeout');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetUnnotifiedRedeems | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetUnnotifiedRedeems.sql*
