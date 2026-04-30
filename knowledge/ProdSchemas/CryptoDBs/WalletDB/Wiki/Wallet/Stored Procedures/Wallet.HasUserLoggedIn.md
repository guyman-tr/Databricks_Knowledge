# Wallet.HasUserLoggedIn

> Stored procedure that checks whether a customer has ever successfully logged into the wallet system, returning 1 (yes) or 0 (no).

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns int (1=has logged in, 0=never logged in) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.HasUserLoggedIn determines whether a customer (identified by Gcid) has ever had a successful login recorded in the `Wallet.LoginAttempts` table. This is used by the application layer to distinguish first-time users from returning users, potentially triggering onboarding flows or welcome screens in the wallet UI.

The check uses `ISNULL(SELECT TOP 1 1 ... WHERE IsSuccessful=1, 0)` to return a scalar 1 or 0 as a single-row result set. It only considers successful logins (`IsSuccessful=1`) - failed login attempts are ignored.

---

## 2. Business Logic

No complex business logic. Simple EXISTS-equivalent check: has the user ever had `IsSuccessful=1` in Wallet.LoginAttempts.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. Identifies the customer to check login history for. |
| 2 | Result | int | NO | - | CODE-BACKED | Single-column result: 1 if any successful login exists for this Gcid, 0 otherwise. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid | Wallet.LoginAttempts | FROM | Checks for successful login records (IsSuccessful=1) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | First-time user detection for onboarding flows |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.HasUserLoggedIn (procedure)
+-- Wallet.LoginAttempts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LoginAttempts | Table | FROM - checks for successful login records |

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

### 8.1 Check if customer has logged in
```sql
EXEC Wallet.HasUserLoggedIn @Gcid = 30351701
```

### 8.2 Equivalent inline query
```sql
SELECT ISNULL((SELECT TOP 1 1 FROM Wallet.LoginAttempts WITH (NOLOCK) WHERE Gcid = 30351701 AND IsSuccessful = 1), 0) AS HasLoggedIn
```

### 8.3 Find customers who never logged in
```sql
SELECT DISTINCT w.Gcid
FROM Wallet.Wallets w WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Wallet.LoginAttempts la WITH (NOLOCK)
    WHERE la.Gcid = w.Gcid AND la.IsSuccessful = 1
)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.HasUserLoggedIn | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.HasUserLoggedIn.sql*
