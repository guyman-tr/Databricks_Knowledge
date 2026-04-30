# Registration.InsertAffiliateIfNotExists

> Creates an affiliate record in Real database only if it doesn't exist (simplified variant without demo insert).

| Property | Value |
|----------|-------|
| **Schema** | Registration |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @affiliateId + @affiliateStatusId (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Registration.InsertAffiliateIfNotExists is the simplified version that only inserts into Real_Affiliate (no Demo_Affiliate sync). The demo code was removed per FB 47518 (2017). Idempotent - does nothing if affiliate already exists.

---

## 2. Business Logic

IF NOT EXISTS in Real_Affiliate: INSERT with AffiliateID, AffiliateStatusID, ManagerID=NULL.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @affiliateId | int (IN) | NO | - | CODE-BACKED | Affiliate ID. |
| 2 | @affiliateStatusId | int (IN) | NO | - | CODE-BACKED | Initial status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.Real_Affiliate | INSERT (synonym) | Real affiliate only |

### 5.2 Referenced By (other objects point to this)

Registration flow.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Registration.InsertAffiliateIfNotExists (procedure)
  +-- dbo.Real_Affiliate (synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Affiliate | Synonym | INSERT |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Create affiliate
```sql
EXEC Registration.InsertAffiliateIfNotExists @affiliateId = 500, @affiliateStatusId = 1
```

### 8.2 Compare variants
```sql
-- Real-only:
EXEC Registration.InsertAffiliateIfNotExists @affiliateId = 500, @affiliateStatusId = 1
-- Real+Demo:
EXEC Registration.InsertAffiliateIfNotExist1 @affiliateId = 500, @affiliateStatusId = 1
```

### 8.3 Idempotent
```sql
EXEC Registration.InsertAffiliateIfNotExists @affiliateId = 500, @affiliateStatusId = 1 -- Creates
EXEC Registration.InsertAffiliateIfNotExists @affiliateId = 500, @affiliateStatusId = 1 -- No-op
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Registration.InsertAffiliateIfNotExists | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Registration/Stored Procedures/Registration.InsertAffiliateIfNotExists.sql*
