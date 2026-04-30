# Wallet.GetLastSyncRun

> Stored procedure that returns the most recent transaction sync run timestamps (previous and next cursor) for a wallet provider.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 1 TransactionsSyncRuns row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.GetLastSyncRun retrieves the most recent sync cursor for a specific wallet provider. The wallet system periodically syncs blockchain transactions from external providers, and each sync run records a "previous" and "next" cursor position. This procedure returns the latest cursor so the next sync can resume from where it left off.

---

## 2. Business Logic

No complex business logic. SELECT TOP 1 of Prev and Next from TransactionsSyncRuns filtered by WalletProviderId, ordered by Id DESC (most recent).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletProviderId | bigint | NO | - | CODE-BACKED | Wallet provider identifier to get the last sync cursor for. |
| 2 | Prev | varchar | YES | - | CODE-BACKED | The previous sync cursor position. Marks where the last completed sync started. |
| 3 | Next | varchar | YES | - | CODE-BACKED | The next sync cursor position. Marks where the next sync should begin. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WalletProviderId | Wallet.TransactionsSyncRuns | FROM | Latest sync cursor lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Transaction sync service | - | EXEC | Resume point for blockchain sync |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetLastSyncRun (procedure)
+-- Wallet.TransactionsSyncRuns (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.TransactionsSyncRuns | Table | FROM - TOP 1 by Id DESC |

### 6.2 Objects That Depend On This

No database object dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get last sync run for a provider
```sql
EXEC Wallet.GetLastSyncRun @WalletProviderId = 1
```

### 8.2 See sync history for a provider
```sql
SELECT TOP 10 Id, Prev, Next FROM Wallet.TransactionsSyncRuns WITH (NOLOCK)
WHERE WalletProviderId = 1 ORDER BY Id DESC
```

### 8.3 Check all providers' last sync
```sql
SELECT wp.Name, tsr.*
FROM Dictionary.WalletProvider wp WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 Prev, Next FROM Wallet.TransactionsSyncRuns tsr WITH (NOLOCK)
    WHERE tsr.WalletProviderId = wp.Id ORDER BY tsr.Id DESC
) tsr
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetLastSyncRun | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetLastSyncRun.sql*
