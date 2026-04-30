# Customer.SignGDPR

> Records a customer's GDPR consent signature with timestamp.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Customer.GDPRSignature |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SignGDPR records when a customer signs the GDPR (General Data Protection Regulation) consent. This is a regulatory requirement for EU users - the platform must record explicit consent and the timestamp of that consent. Each call creates a new signature record (no upsert - historical trail of all signatures).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple INSERT.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @SignDate | datetime | NO | - | CODE-BACKED | When the customer signed the GDPR consent. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Customer.GDPRSignature | INSERT | GDPR consent record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | GDPR consent flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SignGDPR (procedure)
+-- Customer.GDPRSignature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.GDPRSignature | Table | INSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Compliance flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Record GDPR signature
```sql
EXEC Customer.SignGDPR @gcid=12345, @SignDate=GETUTCDATE()
```

### 8.2 Check if signed
```sql
SELECT * FROM Customer.GDPRSignature WITH (NOLOCK) WHERE GCID = 12345
```

### 8.3 Get latest signature
```sql
SELECT TOP 1 * FROM Customer.GDPRSignature WITH (NOLOCK) WHERE GCID = 12345 ORDER BY SignDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.SignGDPR | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.SignGDPR.sql*
