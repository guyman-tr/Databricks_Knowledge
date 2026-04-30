# Customer.GetBasicInfoByNames

> Retrieves basic user profile data for users matching a given first name and last name (case-insensitive), returning all matches from Customer.BasicUserInfo.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @firstName + @lastName (name search) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetBasicInfoByNames looks up users by first and last name. Unlike the other GetBasicInfo* procedures that return a single user by unique key, this can return multiple users since names are not unique. It supports case-insensitive matching via LOWER().

This procedure serves name-based user search scenarios - customer support agents looking up a user by name, compliance investigations, or duplicate detection. It is part of the GetBasicInfo* family using the newer Customer.BasicUserInfo table.

The procedure JOINs Customer.BasicUserInfo with Customer.CustomerIdentification, filtering by LOWER(FirstName) = LOWER(@firstName) AND LOWER(LastName) = LOWER(@lastName). Note that the FirstName and LastName returned are the input parameters, not the stored values.

---

## 2. Business Logic

### 2.1 Case-Insensitive Name Matching

**What**: Names are compared using LOWER() for case-insensitive matching.

**Columns/Parameters Involved**: `@firstName`, `@lastName`

**Rules**:
- Both stored and input values are lowered before comparison
- Multiple users may match (names are not unique)
- The returned FirstName/LastName are the INPUT parameters, not the stored database values

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @firstName | nvarchar(50) | NO | - | CODE-BACKED | First name to search for. Case-insensitive via LOWER(). |
| 2 | @lastName | nvarchar(50) | NO | - | CODE-BACKED | Last name to search for. Case-insensitive via LOWER(). |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | GCID | BasicUserInfo | CODE-BACKED | Global Customer ID. |
| 2 | RealCID | CustomerIdentification.CID | CODE-BACKED | Legacy real account CID. |
| 3 | DemoCID | CustomerIdentification | CODE-BACKED | Demo account CID. |
| 4 | FirstName | @firstName param | CODE-BACKED | Input first name (not stored value). |
| 5 | LastName | @lastName param | CODE-BACKED | Input last name (not stored value). |
| 6 | MiddleName | BasicUserInfo | CODE-BACKED | Middle name. |
| 7 | UserName | BasicUserInfo | CODE-BACKED | Platform username. |
| 8 | Gender | BasicUserInfo | CODE-BACKED | Gender: 'M'/'F'/'U'. |
| 9 | LanguageID | BasicUserInfo | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 10 | BirthDate | BasicUserInfo | CODE-BACKED | Date of birth. |
| 11 | PlayerLevelID | BasicUserInfo | CODE-BACKED | eToro Club tier. FK to Dictionary.PlayerLevel. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.BasicUserInfo | JOIN (READER) | Name matching and basic identity |
| (body) | Customer.CustomerIdentification | JOIN (READER) | CID/DemoCID resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by name-based user search services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBasicInfoByNames (procedure)
+-- Customer.BasicUserInfo (table)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BasicUserInfo | Table | JOIN - name matching and identity fields |
| Customer.CustomerIdentification | Table | JOIN - CID/DemoCID resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Search users by name
```sql
EXEC Customer.GetBasicInfoByNames @firstName = N'John', @lastName = N'Smith'
```

### 8.2 Verify name search results
```sql
SELECT bi.GCID, bi.UserName, bi.FirstName, bi.LastName
FROM Customer.BasicUserInfo bi WITH (NOLOCK)
WHERE LOWER(bi.FirstName) = LOWER(N'John') AND LOWER(bi.LastName) = LOWER(N'Smith')
```

### 8.3 Count users with same name
```sql
SELECT COUNT(*) AS MatchCount
FROM Customer.BasicUserInfo WITH (NOLOCK)
WHERE LOWER(FirstName) = LOWER(N'John') AND LOWER(LastName) = LOWER(N'Smith')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetBasicInfoByNames | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetBasicInfoByNames.sql*
