# Customer.GetRelatedUsersByPhone

> Finds up to 20 customers with the same phone number from Customer.ContactUserInfo - fraud detection for shared phone numbers.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns TOP 20 GCID + Phone |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRelatedUsersByPhone finds customers who share the same phone number, which may indicate related or duplicate accounts. Multiple accounts with the same phone number can be a sign of fraud or multi-accounting. This is the Customer schema version; GetRelatedUsersByPhoneOLD uses the legacy dbo.Real_Customer table.

Returns TOP 20 results to keep the response manageable.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple exact phone match with TOP 20.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @phone | varchar(max) | NO | - | CODE-BACKED | Phone number to search for exact matches. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | Phone (output) | varchar | YES | - | CODE-BACKED | Phone number (echoed, confirms match). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @phone | Customer.ContactUserInfo | Exact match | Phone number matching |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Phone-based fraud detection |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRelatedUsersByPhone (procedure)
+-- Customer.ContactUserInfo (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ContactUserInfo | Table | FROM - phone exact match |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find accounts with same phone
```sql
EXEC Customer.GetRelatedUsersByPhone @phone = '+972501234567'
```

### 8.2 Direct query equivalent
```sql
SELECT TOP 20 GCID, Phone FROM Customer.ContactUserInfo WITH (NOLOCK) WHERE Phone = @phone
```

### 8.3 Compare with legacy
```sql
-- GetRelatedUsersByPhone: Customer.ContactUserInfo (new)
-- GetRelatedUsersByPhoneOLD: dbo.Real_Customer (legacy)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.6/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetRelatedUsersByPhone | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRelatedUsersByPhone.sql*
