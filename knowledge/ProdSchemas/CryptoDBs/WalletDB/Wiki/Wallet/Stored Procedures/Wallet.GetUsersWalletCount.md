# Wallet.GetUsersWalletCount

> Returns the total number of wallets owned by a customer, used by the back-office API for customer overview displays and eligibility checks.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar wallet count by Gcid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure counts the total number of wallets a customer owns across all cryptocurrencies. It queries CustomerWalletsView filtered by Gcid and returns a scalar count. The back-office API uses this for customer dashboard displays and to determine eligibility for operations that depend on wallet count. Executes with EXECUTE AS OWNER for elevated permissions.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple COUNT aggregation on CustomerWalletsView by Gcid.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Global Customer ID to count wallets for. |
| 2 | WalletsCount (output) | int | NO | - | CODE-BACKED | Total number of wallets the customer owns across all cryptos. 0 if no wallets. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid | Wallet.CustomerWalletsView.Gcid | COUNT | Wallet count aggregation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Customer dashboard wallet count |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetUsersWalletCount (procedure)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.CustomerWalletsView | View | COUNT by Gcid |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses EXECUTE AS OWNER impersonation context.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Count wallets for a customer
```sql
EXEC Wallet.GetUsersWalletCount @Gcid = 30351701;
```

### 8.2 Direct equivalent
```sql
SELECT COUNT(Id) AS WalletsCount FROM Wallet.CustomerWalletsView WHERE Gcid = 30351701;
```

### 8.3 Count with crypto breakdown
```sql
SELECT CryptoId, COUNT(*) AS WalletCount
FROM Wallet.CustomerWalletsView WITH (NOLOCK)
WHERE Gcid = 30351701
GROUP BY CryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetUsersWalletCount | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetUsersWalletCount.sql*
