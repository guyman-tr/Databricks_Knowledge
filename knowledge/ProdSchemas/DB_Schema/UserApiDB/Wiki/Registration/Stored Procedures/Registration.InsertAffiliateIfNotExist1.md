# Registration.InsertAffiliateIfNotExist1

> Creates an affiliate record in both Real and Demo databases if it doesn't exist (variant with demo insert).

| Property | Value |
|----------|-------|
| **Schema** | Registration |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @affiliateId + @affiliateStatusId (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Registration.InsertAffiliateIfNotExist1 is a variant of InsertAffiliateIfNotExists that also inserts into the Demo_Affiliate synonym (Demo database). If the affiliate doesn't exist in Real_Affiliate, inserts there first. Then attempts Demo_Affiliate insert in a TRY/CATCH (returns -1 on demo failure). This variant maintains Real+Demo affiliate sync.

---

## 2. Business Logic

### 2.1 Dual Database Insert

**Rules**:
- IF NOT EXISTS in Real_Affiliate: INSERT
- IF NOT EXISTS in Demo_Affiliate: INSERT (TRY/CATCH, returns -1 on failure)
- ManagerID set to NULL for both

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @affiliateId | int (IN) | NO | - | CODE-BACKED | Affiliate ID to create. |
| 2 | @affiliateStatusId | int (IN) | NO | - | CODE-BACKED | Initial affiliate status. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.Real_Affiliate | INSERT (synonym) | Real affiliate |
| - | dbo.Demo_Affiliate | INSERT (synonym) | Demo affiliate |

### 5.2 Referenced By (other objects point to this)

Registration flow.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Registration.InsertAffiliateIfNotExist1 (procedure)
  +-- dbo.Real_Affiliate (synonym)
  +-- dbo.Demo_Affiliate (synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Affiliate | Synonym | INSERT |
| dbo.Demo_Affiliate | Synonym | INSERT |

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
EXEC Registration.InsertAffiliateIfNotExist1 @affiliateId = 500, @affiliateStatusId = 1
```

### 8.2 Idempotent call
```sql
EXEC Registration.InsertAffiliateIfNotExist1 @affiliateId = 500, @affiliateStatusId = 1
-- Second call does nothing (IF NOT EXISTS)
```

### 8.3 Check result
```sql
SELECT * FROM Real_Affiliate WITH (NOLOCK) WHERE AffiliateID = 500
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Registration.InsertAffiliateIfNotExist1 | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Registration/Stored Procedures/Registration.InsertAffiliateIfNotExist1.sql*
