# Registration.GetRegistrationDataForUsersWithoutDemo

> Retrieves full registration data for users who failed demo account creation, for retry processing. Returns random batch.

| Property | Value |
|----------|-------|
| **Schema** | Registration |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @batchSize (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Registration.GetRegistrationDataForUsersWithoutDemo retrieves users from dbo.Register_Demo_Fail whose demo accounts still need to be created. Joins with Real_Customer, Real_BackOfficeCustomer, and dbo.State for the complete registration payload. LEFT JOINs Demo_Customer to verify demo is still missing (dc.GCID IS NULL). Returns random order (ORDER BY NEWID()) for distributed processing.

---

## 2. Business Logic

### 2.1 Failed Demo Retry Pattern

**Rules**:
- Reads from Register_Demo_Fail to find CIDs with failed demo creation
- Joins Real_Customer for full registration data
- LEFT JOIN Demo_Customer WHERE dc.GCID IS NULL confirms demo still missing
- Random order prevents contention on retry

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @batchSize | int (IN) | NO | - | CODE-BACKED | Max records to return per batch. |

Output: Full registration payload (40+ columns from Real_Customer + Real_BackOfficeCustomer).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.Register_Demo_Fail | FROM | Failed demo queue |
| - | dbo.Real_Customer | JOIN (synonym) | Registration data |
| - | dbo.Real_BackOfficeCustomer | JOIN (synonym) | Back-office data |
| - | dbo.State | JOIN (synonym) | State name |
| - | dbo.Demo_Customer | LEFT JOIN (synonym) | Verify demo missing |

### 5.2 Referenced By (other objects point to this)

Demo registration retry service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Registration.GetRegistrationDataForUsersWithoutDemo (procedure)
  +-- dbo.Register_Demo_Fail (table) [done]
  +-- dbo.Real_Customer (synonym)
  +-- dbo.Real_BackOfficeCustomer (synonym)
  +-- dbo.State (synonym)
  +-- dbo.Demo_Customer (synonym)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Register_Demo_Fail | Table | FROM |
| 4 dbo synonyms | Synonyms | JOINs |

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

### 8.1 Get retry batch
```sql
EXEC Registration.GetRegistrationDataForUsersWithoutDemo @batchSize = 100
```

### 8.2 Small batch
```sql
EXEC Registration.GetRegistrationDataForUsersWithoutDemo @batchSize = 10
```

### 8.3 Check pending count
```sql
SELECT COUNT(*) FROM dbo.Register_Demo_Fail WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Registration.GetRegistrationDataForUsersWithoutDemo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Registration/Stored Procedures/Registration.GetRegistrationDataForUsersWithoutDemo.sql*
