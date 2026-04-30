# Wallet.GetAllWebHookReg

> Returns all webhook registration records, providing the complete list of wallets subscribed to blockchain event notifications with their callback URLs and confirmation thresholds.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all rows from Wallet.WebHookReg |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all active webhook registrations. Webhooks allow the system to receive real-time notifications from blockchain providers when events occur on registered wallet addresses (e.g., incoming transaction detected, transaction confirmed). Each registration specifies a callback URL and the number of blockchain confirmations required before notification.

Without this procedure, the system could not load the webhook registry at startup or for cache refresh, leaving wallet event subscriptions unknown.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple full-table SELECT.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Registration ID. |
| 2 | WalletId | uniqueidentifier | NO | - | CODE-BACKED | The wallet subscribed to notifications. |
| 3 | Created | datetime | NO | - | CODE-BACKED | When the registration was created. |
| 4 | Url | nvarchar | NO | - | CODE-BACKED | Callback URL for event notifications. |
| 5 | NumberOfConfirmation | int | NO | - | CODE-BACKED | Minimum blockchain confirmations before triggering the webhook callback. Higher values = more security, longer wait. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.WebHookReg | Reader | Source of registration data |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetAllWebHookReg (procedure)
  └── Wallet.WebHookReg (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WebHookReg | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Full table dump with no filtering or pagination.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Wallet.GetAllWebHookReg
```

### 8.2 Count registrations per wallet
```sql
SELECT WalletId, COUNT(*) AS RegCount
FROM Wallet.WebHookReg WITH (NOLOCK)
GROUP BY WalletId
HAVING COUNT(*) > 1
```

### 8.3 Find registrations by confirmation threshold
```sql
SELECT WalletId, Url, NumberOfConfirmation
FROM Wallet.WebHookReg WITH (NOLOCK)
WHERE NumberOfConfirmation > 6
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetAllWebHookReg | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetAllWebHookReg.sql*
