# Wallet.DoesRequestExist

> Stored procedure that checks whether a specific request exists by matching CorrelationId, Gcid, CryptoId, and RequestTypeId. Returns the CorrelationId if found, empty result set otherwise.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CorrelationId or empty result |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Wallet.DoesRequestExist is a simple existence check that determines whether a wallet request matching an exact combination of CorrelationId, customer (Gcid), cryptocurrency, and request type already exists. This prevents duplicate request creation in the wallet pipeline - before initiating a new send, convert, or payment request, the application service checks if an identical request was already submitted.

The procedure returns the matching CorrelationId as a result set row if found, or an empty result set if no match exists. The calling application checks the row count to determine existence.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple exact-match SELECT on four columns against Wallet.Requests.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Cross-system correlation ID for the request. Acts as an idempotency key. |
| 2 | @Gcid | bigint | NO | - | CODE-BACKED | Global Customer ID. Must match the request's customer. |
| 3 | @CryptoId | int | NO | - | CODE-BACKED | Cryptocurrency ID (FK to Wallet.CryptoTypes). Must match the request's crypto. |
| 4 | @RequestTypeId | tinyint | NO | - | CODE-BACKED | Request type: 1=Send, 2=Payment, 4=Conversion, 6=Staking, 7=CryptoToFiat. Must match exactly. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Wallet.Requests | FROM | Exact-match lookup on CorrelationId, Gcid, CryptoId, RequestTypeId |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application services | - | EXEC | Idempotency check before request creation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.DoesRequestExist (procedure)
+-- Wallet.Requests (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Requests | Table | FROM - exact-match lookup with NOLOCK |

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

### 8.1 Check if a send request exists
```sql
EXEC Wallet.DoesRequestExist
    @CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @Gcid = 30351701,
    @CryptoId = 1,
    @RequestTypeId = 1  -- Send
```

### 8.2 Check if a conversion request exists
```sql
EXEC Wallet.DoesRequestExist
    @CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890',
    @Gcid = 30351701,
    @CryptoId = 1,
    @RequestTypeId = 4  -- Conversion
```

### 8.3 Equivalent inline query
```sql
SELECT r.CorrelationId
FROM Wallet.Requests r WITH (NOLOCK)
WHERE r.CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
  AND r.Gcid = 30351701 AND r.CryptoId = 1 AND r.RequestTypeId = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.DoesRequestExist | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.DoesRequestExist.sql*
