# Customer.GetBasicUserInfoByNames

> Legacy variant: retrieves basic user profile data for users matching first and last name (case-insensitive) from dbo.Real_Customer.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @firstName + @lastName (name search) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetBasicUserInfoByNames is the legacy variant of GetBasicInfoByNames. It searches for users by first and last name with case-insensitive matching, reading from dbo.Real_Customer rather than Customer.BasicUserInfo. Can return multiple rows since names are not unique.

This procedure exists alongside its newer counterpart for backward compatibility. The returned FirstName and LastName columns contain the INPUT parameters, not the stored database values.

---

## 2. Business Logic

### 2.1 Case-Insensitive Name Matching

**What**: Name comparison uses LOWER() for case-insensitive matching.

**Columns/Parameters Involved**: `@firstName`, `@lastName`

**Rules**:
- Both stored and input values are lowered before comparison
- Multiple users may match
- Returned FirstName/LastName are the input parameters, not stored values

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @firstName | nvarchar(50) | NO | - | CODE-BACKED | First name to search. Case-insensitive via LOWER(). |
| 2 | @lastName | nvarchar(50) | NO | - | CODE-BACKED | Last name to search. Case-insensitive via LOWER(). |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | GCID | Real_Customer | CODE-BACKED | Global Customer ID. |
| 2 | RealCID | Real_Customer.CID | CODE-BACKED | Legacy CID. |
| 3 | DemoCID | CustomerIdentification | CODE-BACKED | Demo account CID. |
| 4 | FirstName | @firstName param | CODE-BACKED | Input first name. |
| 5 | LastName | @lastName param | CODE-BACKED | Input last name. |
| 6 | MiddleName | Real_Customer | CODE-BACKED | Middle name. |
| 7 | UserName | Real_Customer | CODE-BACKED | Platform username. |
| 8 | Gender | Real_Customer | CODE-BACKED | Gender. |
| 9 | LanguageID | Real_Customer | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 10 | BirthDate | Real_Customer | CODE-BACKED | Date of birth. |
| 11 | PlayerLevelID | Real_Customer | CODE-BACKED | eToro Club tier. FK to Dictionary.PlayerLevel. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | dbo.Real_Customer | JOIN (READER) | Name matching and identity (legacy) |
| (body) | Customer.CustomerIdentification | JOIN (READER) | CID/DemoCID resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by legacy name search services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBasicUserInfoByNames (procedure)
+-- dbo.Real_Customer (table/synonym)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table/Synonym | JOIN - name matching and identity |
| Customer.CustomerIdentification | Table | JOIN - DemoCID resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Search by name (legacy)
```sql
EXEC Customer.GetBasicUserInfoByNames @firstName = N'John', @lastName = N'Smith'
```

### 8.2 Compare with newer variant
```sql
EXEC Customer.GetBasicInfoByNames @firstName = N'John', @lastName = N'Smith'
EXEC Customer.GetBasicUserInfoByNames @firstName = N'John', @lastName = N'Smith'
```

### 8.3 Name search via Real_Customer directly
```sql
SELECT GCID, CID, UserName, FirstName, LastName
FROM dbo.Real_Customer WITH (NOLOCK)
WHERE LOWER(FirstName) = LOWER(N'John') AND LOWER(LastName) = LOWER(N'Smith')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetBasicUserInfoByNames | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetBasicUserInfoByNames.sql*
