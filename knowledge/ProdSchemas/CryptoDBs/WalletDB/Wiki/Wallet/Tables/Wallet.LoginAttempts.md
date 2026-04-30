# Wallet.LoginAttempts

> Audit log of customer login attempts to the crypto wallet, recording successes and failures for security monitoring, fraud detection, and compliance auditing.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (int, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table records every login attempt to the crypto wallet application. Each row captures the customer, whether the attempt succeeded, and a correlation ID for tracing across services. With ~25.4M rows, it is one of the highest-volume audit tables, reflecting the frequency of wallet access.

The table serves security and compliance purposes. Security monitoring uses it to detect brute-force login attempts (multiple failures for the same Gcid). Compliance requires a full audit trail of wallet access for regulatory reporting. The `Wallet.HasUserLoggedIn` procedure uses this table to verify a customer has authenticated before allowing wallet operations.

Rows are created by `Wallet.InsertLoginAttempt` each time a user attempts to access the wallet. The CorrelationId links the login event to the broader request context for end-to-end tracing.

---

## 2. Business Logic

### 2.1 Login Success Tracking

**What**: Each attempt is flagged as successful or failed for security monitoring.

**Columns/Parameters Involved**: `Gcid`, `IsSuccessful`, `Timestamp`

**Rules**:
- IsSuccessful=1: Authentication passed, user granted wallet access
- IsSuccessful=0: Authentication failed (wrong credentials, expired token, etc.)
- Multiple failed attempts in sequence for the same Gcid may trigger security lockout
- The `HasUserLoggedIn` procedure checks for at least one successful login

---

## 3. Data Overview

| Id | Gcid | IsSuccessful | Timestamp | Meaning |
|---|---|---|---|---|
| 29233218 | 23673525 | true | 2026-04-14 16:41 | Successful wallet login - user can now view balances and perform transactions |
| 29233217 | 26457640 | true | 2026-04-14 16:41 | Another successful login within seconds - high concurrent wallet usage |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID of the user attempting to log in. Indexed for per-user login history queries. |
| 3 | IsSuccessful | bit | NO | - | CODE-BACKED | Whether the login attempt succeeded: 1=successful authentication, 0=failed authentication. Used by security monitoring to detect brute-force patterns. |
| 4 | Timestamp | datetime2(7) | NO | - | CODE-BACKED | When the login attempt occurred. Used for time-based security analysis (rate limiting, attack detection). |
| 5 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Request correlation ID linking this login event to the broader service call chain. Unique constraint. Enables end-to-end tracing of the authentication flow. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertLoginAttempt | - | Writer | Records login attempts |
| Wallet.HasUserLoggedIn | - | Reader | Checks if a user has ever logged in |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertLoginAttempt | Stored Procedure | Records login attempts |
| Wallet.HasUserLoggedIn | Stored Procedure | Checks login history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_LoginAttempts | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_LoginAttempts__CorrelationId | NC UNIQUE | CorrelationId ASC | - | - | Active |
| nci_LoginAttempts_Gcid_IsSuccessful | NC | Gcid, IsSuccessful | - | - | Active |

### 7.2 Constraints

None (beyond PK and unique indexes).

---

## 8. Sample Queries

### 8.1 Check if a user has logged in successfully
```sql
SELECT TOP 1 1 AS HasLoggedIn
FROM Wallet.LoginAttempts WITH (NOLOCK)
WHERE Gcid = 23673525 AND IsSuccessful = 1
```

### 8.2 Recent failed login attempts
```sql
SELECT TOP 20 Gcid, Timestamp, CorrelationId
FROM Wallet.LoginAttempts WITH (NOLOCK)
WHERE IsSuccessful = 0
ORDER BY Timestamp DESC
```

### 8.3 Login frequency per customer
```sql
SELECT Gcid, COUNT(*) AS TotalAttempts,
    SUM(CASE WHEN IsSuccessful = 1 THEN 1 ELSE 0 END) AS Successes,
    SUM(CASE WHEN IsSuccessful = 0 THEN 1 ELSE 0 END) AS Failures
FROM Wallet.LoginAttempts WITH (NOLOCK)
WHERE Timestamp > DATEADD(DAY, -7, GETUTCDATE())
GROUP BY Gcid
HAVING SUM(CASE WHEN IsSuccessful = 0 THEN 1 ELSE 0 END) > 5
ORDER BY Failures DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.LoginAttempts | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.LoginAttempts.sql*
