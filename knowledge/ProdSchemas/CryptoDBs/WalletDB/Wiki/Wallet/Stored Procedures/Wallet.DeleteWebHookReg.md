# Wallet.DeleteWebHookReg

> Deletes all webhook registration records for a given wallet, removing the wallet from blockchain event notification subscriptions.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes from Wallet.WebHookReg |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure removes webhook registrations for a wallet. Webhooks are used to receive real-time blockchain event notifications (e.g., incoming transactions, confirmation updates) from blockchain providers. When a wallet is deactivated, migrated, or its webhook configuration needs to be refreshed, existing registrations are deleted.

Without this procedure, stale webhook registrations would accumulate, causing the system to receive notifications for wallets that are no longer active and wasting processing resources.

The procedure deletes ALL registrations for the given WalletId - it is a complete cleanup, not a selective removal.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Single DELETE operation by WalletId. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WalletId | uniqueidentifier | NO | - | CODE-BACKED | The wallet whose webhook registrations should be removed. All registrations for this wallet are deleted. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DELETE target | Wallet.WebHookReg | Deleter | Removes all webhook registrations for the wallet |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application webhook services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.DeleteWebHookReg (procedure)
  └── Wallet.WebHookReg (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.WebHookReg | Table | DELETE target (note: this table is not in the Wallet schema SSDT project - may be in a different schema or external) |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Unconditional DELETE by WalletId.

---

## 8. Sample Queries

### 8.1 Check existing webhook registrations for a wallet
```sql
SELECT * FROM Wallet.WebHookReg WITH (NOLOCK)
WHERE WalletId = '4B26D85F-BF00-4E27-9166-4F8AF2D599D6'
```

### 8.2 Count webhook registrations per wallet
```sql
SELECT WalletId, COUNT(*) AS RegCount
FROM Wallet.WebHookReg WITH (NOLOCK)
GROUP BY WalletId
ORDER BY RegCount DESC
```

### 8.3 Find wallets with webhook notifications but no registrations
```sql
SELECT DISTINCT whn.WalletId
FROM Wallet.WebHookNotifications whn WITH (NOLOCK)
LEFT JOIN Wallet.WebHookReg whr WITH (NOLOCK) ON whr.WalletId = whn.WalletId
WHERE whr.WalletId IS NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.DeleteWebHookReg | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.DeleteWebHookReg.sql*
