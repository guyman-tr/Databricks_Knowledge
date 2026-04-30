# Wallet.StoreLimitExceed

> Records a spending limit exceedance event when a transaction request exceeds the customer's configured crypto or periodic spending limits, resolving the timezone from name to ID.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into LimitExceeds with timezone resolution |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records when a customer's transaction request exceeds spending limits. The back-office API, conversion service, and limitations service call this to create an audit trail of limit exceedances. Each record captures the requested amount vs the configured limit, USD exchange rate, whether it was a periodic exceedance, and the time context. The timezone name is resolved to its Dictionary ID for storage.

---

## 2. Business Logic

### 2.1 Timezone Resolution

**What**: Resolves timezone name to Dictionary.TimeZones ID.

**Rules**:
- If @TimeZone IS NOT NULL, resolves @TimezoneId from Dictionary.TimeZones WHERE Name = @TimeZone
- TimezoneId is stored in LimitExceeds for time-window reference

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Request that exceeded the limit. |
| 2 | @Gcid | bigint | NO | - | VERIFIED | Customer. |
| 3 | @CryptoId | int | NO | - | VERIFIED | Cryptocurrency. |
| 4 | @TransactionTypeId | tinyint | NO | - | VERIFIED | Transaction type that was limited. |
| 5 | @RequestAmount | decimal(36,18) | NO | - | CODE-BACKED | Amount the customer requested. |
| 6 | @RequestAmountUSD | decimal(36,18) | NO | - | CODE-BACKED | Requested amount in USD equivalent. |
| 7 | @CryptoLimitationAmount | decimal(36,18) | NO | - | CODE-BACKED | Configured crypto limit that was exceeded. |
| 8 | @USDRate | decimal(36,18) | NO | - | CODE-BACKED | USD exchange rate at time of request. |
| 9 | @IsPeriodicExceed | bit | NO | - | CODE-BACKED | Whether this was a periodic (rolling window) limit exceedance. |
| 10 | @PeriodicSentAmount | decimal(36,18) | NO | - | CODE-BACKED | Amount already sent in the current period. |
| 11 | @SentSince | datetime2(7) | NO | - | CODE-BACKED | Start of the periodic window. |
| 12 | @TimeZone | nvarchar(100) | YES | - | CODE-BACKED | Timezone name for the periodic window. Resolved to TimezoneId. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.LimitExceeds | INSERT | Limit exceedance record |
| @TimeZone | Dictionary.TimeZones | Lookup | Timezone resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser, ConversionUser, LimitationsUser | - | EXECUTE | Limit exceedance recording |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StoreLimitExceed (procedure)
+-- Wallet.LimitExceeds (table)
+-- Dictionary.TimeZones (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LimitExceeds | Table | INSERT target |
| Dictionary.TimeZones | Table | Timezone resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser, ConversionUser, LimitationsUser | Service Accounts | EXECUTE grants |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a limit exceedance
```sql
EXEC Wallet.StoreLimitExceed @CorrelationId='GUID', @Gcid=30351701, @CryptoId=1, @TransactionTypeId=1, @RequestAmount=2.0, @RequestAmountUSD=130000, @CryptoLimitationAmount=1.0, @USDRate=65000, @IsPeriodicExceed=1, @PeriodicSentAmount=0.8, @SentSince='2026-04-14', @TimeZone='UTC';
```

### 8.2 Check recent limit exceedances
```sql
SELECT * FROM Wallet.LimitExceeds WITH (NOLOCK) WHERE Gcid = 30351701 ORDER BY Id DESC;
```

### 8.3 Count exceedances by crypto
```sql
SELECT CryptoId, COUNT(*) FROM Wallet.LimitExceeds WITH (NOLOCK) WHERE Occurred > DATEADD(DAY, -7, GETDATE()) GROUP BY CryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StoreLimitExceed | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StoreLimitExceed.sql*
