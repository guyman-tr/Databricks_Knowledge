# Wallet.InsertLoginAttempt

> Records a customer's wallet login attempt with idempotency protection via CorrelationId, tracking both successful and failed authentication events for the billing notification service.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.LoginAttempts with idempotency |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a customer's login attempt to the wallet platform. Each attempt captures the customer ID, success/failure flag, timestamp, and correlation ID. The billing notification service calls this to maintain an audit trail of authentication events. Idempotent: duplicate inserts with the same CorrelationId are silently skipped.

---

## 2. Business Logic

### 2.1 Idempotent Insert

**What**: Prevents duplicate login attempt records.

**Rules**:
- WHERE NOT EXISTS (SELECT 1 FROM LoginAttempts WHERE CorrelationId = @CorrelationId)
- If the same CorrelationId is submitted twice, the second insert is silently skipped (no error)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Customer who attempted login. |
| 2 | @IsSuccessful | bit | NO | - | CODE-BACKED | 1=successful login, 0=failed attempt. |
| 3 | @Timestamp | datetime2(7) | NO | - | CODE-BACKED | When the login attempt occurred. |
| 4 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Idempotency key. Prevents duplicate records. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.LoginAttempts | INSERT | Login audit record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BillingNotificationUser | - | EXECUTE | Login event recording |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertLoginAttempt (procedure)
+-- Wallet.LoginAttempts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LoginAttempts | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BillingNotificationUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a successful login
```sql
EXEC Wallet.InsertLoginAttempt @Gcid = 30351701, @IsSuccessful = 1, @Timestamp = '2026-04-15 10:00:00', @CorrelationId = 'NEW-GUID';
```

### 8.2 Record a failed login
```sql
EXEC Wallet.InsertLoginAttempt @Gcid = 30351701, @IsSuccessful = 0, @Timestamp = '2026-04-15 10:01:00', @CorrelationId = 'ANOTHER-GUID';
```

### 8.3 Check recent login attempts
```sql
SELECT * FROM Wallet.LoginAttempts WITH (NOLOCK) WHERE Gcid = 30351701 ORDER BY Timestamp DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertLoginAttempt | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertLoginAttempt.sql*
