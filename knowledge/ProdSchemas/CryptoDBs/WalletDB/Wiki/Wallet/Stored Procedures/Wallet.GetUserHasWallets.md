# Wallet.GetUserHasWallets

> Returns a boolean indicator (1/0) for whether a customer has any wallets in the system, used by the balance service for fast existence checks before wallet operations.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar 1/0 by Gcid existence in CustomerWalletsView |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs a fast existence check to determine whether a customer has any wallets in the system. It uses an EXISTS subquery on CustomerWalletsView, returning 1 if any wallets exist for the given Gcid, or 0 otherwise. The balance service uses this as a guard check before performing wallet-related operations.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple EXISTS check on CustomerWalletsView by Gcid.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Global Customer ID to check for wallet existence. |
| 2 | (scalar result) | int | NO | - | CODE-BACKED | 1 = customer has at least one wallet, 0 = no wallets found. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid | Wallet.CustomerWalletsView.Gcid | EXISTS check | Wallet existence verification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BalanceUser | - | EXECUTE | Pre-operation wallet existence check |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetUserHasWallets (procedure)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | EXISTS check by Gcid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BalanceUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Check if customer has wallets
```sql
EXEC Wallet.GetUserHasWallets @Gcid = 30351701;
```

### 8.2 Direct equivalent
```sql
IF EXISTS (SELECT 1 FROM Wallet.CustomerWalletsView WHERE Gcid = 30351701) SELECT 1 ELSE SELECT 0;
```

### 8.3 Count wallets if they exist
```sql
SELECT COUNT(*) FROM Wallet.CustomerWalletsView WITH (NOLOCK) WHERE Gcid = 30351701;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetUserHasWallets | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetUserHasWallets.sql*
