# Wallet.StoreAmlProviderUsers

> Registers a customer with an AML screening provider, inserting the provider-specific user ID only if the customer doesn't already have a record, ensuring one registration per customer.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into AmlProviderUsers with existence check |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure registers a customer's account with an AML screening provider (e.g., Chainalysis, Elliptic). The AML service calls this the first time a customer's transaction is screened, recording the provider's user ID for future reference. Only one record per Gcid is created - subsequent calls for the same customer are silently skipped.

---

## 2. Business Logic

### 2.1 Idempotent One-Per-Customer Insert

**What**: Only creates a record if the customer doesn't already exist in the table.

**Rules**:
- IF NOT EXISTS (AmlProviderUsers WHERE Gcid = @Gcid) THEN INSERT
- One record per customer regardless of how many providers exist
- Silently skips if customer already registered

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AmlProviderId | int | NO | - | VERIFIED | AML screening provider. FK to Dictionary.AmlProviders. |
| 2 | @Gcid | bigint | NO | - | VERIFIED | Customer to register. |
| 3 | @ProviderUserId | varchar(40) | NO | - | CODE-BACKED | Provider's customer reference ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.AmlProviderUsers | INSERT | Provider user registration |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser | - | EXECUTE | Customer AML registration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StoreAmlProviderUsers (procedure)
+-- Wallet.AmlProviderUsers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AmlProviderUsers | Table | INSERT with existence check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Register a customer with an AML provider
```sql
EXEC Wallet.StoreAmlProviderUsers @AmlProviderId = 1, @Gcid = 30351701, @ProviderUserId = 'prov-user-123';
```

### 8.2 Check if customer is registered
```sql
SELECT * FROM Wallet.AmlProviderUsers WITH (NOLOCK) WHERE Gcid = 30351701;
```

### 8.3 Direct equivalent
```sql
IF NOT EXISTS (SELECT * FROM Wallet.AmlProviderUsers WHERE Gcid = 30351701)
    INSERT INTO Wallet.AmlProviderUsers (AmlProviderId, Gcid, ProviderUserId, Occurred) VALUES (1, 30351701, 'prov-user-123', GETDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StoreAmlProviderUsers | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StoreAmlProviderUsers.sql*
