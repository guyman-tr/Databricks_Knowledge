# Wallet.InsertMissingReceivedTransactionDoneStatus

> Retroactively adds 'Done' status records to received transactions that are missing them, identified by customer Gcid and sender address, used by the wallet middleware for data consistency repair.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into ReceivedTransactionStatuses for missing Done statuses |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a data repair tool that adds missing 'Done' status (StatusId=1) to received transactions. Sometimes a received transaction's status progression is interrupted, leaving it without a final Done status. The wallet middleware service identifies these cases and calls this procedure to add the missing status retroactively.

The procedure finds all received transactions from a customer's wallet (via Wallets table) where the sender address matches @WalletAddress AND the latest status is not already Done. For each qualifying transaction, it inserts a new Done status event into ReceivedTransactionStatuses.

---

## 2. Business Logic

### 2.1 Selective Status Insertion

**What**: Only adds Done status to transactions that don't already have it as their latest status.

**Columns/Parameters Involved**: `@Gcid`, `@WalletAddress`, `ReceivedTransactionStatuses.StatusId`

**Rules**:
- Joins ReceivedTransactions to Wallets ON WalletId = WalletId (links to customer via Gcid)
- Filters by NormalizedSenderAddress = @WalletAddress
- CROSS APPLY gets the latest StatusId (TOP 1 ORDER BY Occurred DESC)
- Only inserts where latest StatusId <> 1 (not already Done)
- StatusIdToAdd = 1 (Done)
- Empty @DetailsJson treated as NULL

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Customer whose received transactions to check. |
| 2 | @WalletAddress | nvarchar(512) | NO | - | VERIFIED | Sender address to filter received transactions. Matched against NormalizedSenderAddress. |
| 3 | @DetailsJson | varchar(max) | YES | NULL | CODE-BACKED | Optional JSON details for the status record. Empty string treated as NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid | Wallet.Wallets.Gcid | JOIN | Customer wallet resolution |
| WalletId | Wallet.ReceivedTransactions | JOIN | Received transactions for the wallet |
| ReceivedTransactionId | Wallet.ReceivedTransactionStatuses | CROSS APPLY + INSERT | Latest status check + Done insertion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| WalletMiddlewareUser | - | EXECUTE | Data consistency repair |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertMissingReceivedTransactionDoneStatus (procedure)
+-- Wallet.ReceivedTransactions (table)
+-- Wallet.ReceivedTransactionStatuses (table)
+-- Wallet.Wallets (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.ReceivedTransactions | Table | Source of transactions to check |
| Wallet.ReceivedTransactionStatuses | Table | Status check + INSERT target |
| Wallet.Wallets | Table | Customer-to-wallet resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| WalletMiddlewareUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Fix missing Done statuses for a customer's received transactions
```sql
EXEC Wallet.InsertMissingReceivedTransactionDoneStatus
    @Gcid = 30351701,
    @WalletAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa';
```

### 8.2 With details JSON
```sql
EXEC Wallet.InsertMissingReceivedTransactionDoneStatus
    @Gcid = 30351701,
    @WalletAddress = '1A1zP1eP5QGefi2DMPTfTL5SLmv7DivfNa',
    @DetailsJson = '{"reason":"manual repair","ticket":"CRYP-1234"}';
```

### 8.3 Find transactions missing Done status
```sql
SELECT rt.Id, rt.NormalizedSenderAddress, ts.StatusId AS LatestStatus
FROM Wallet.ReceivedTransactions rt
    JOIN Wallet.Wallets w ON rt.WalletId = w.WalletId
    CROSS APPLY (SELECT TOP 1 rts.StatusId FROM Wallet.ReceivedTransactionStatuses rts WHERE rts.ReceivedTransactionId = rt.Id ORDER BY rts.Occurred DESC) ts
WHERE w.Gcid = 30351701 AND ts.StatusId <> 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertMissingReceivedTransactionDoneStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertMissingReceivedTransactionDoneStatus.sql*
