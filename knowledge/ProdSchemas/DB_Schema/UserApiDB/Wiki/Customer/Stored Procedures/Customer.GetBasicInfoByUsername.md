# Customer.GetBasicInfoByUsername

> Retrieves basic user profile data by username (case-insensitive) from the legacy Real_Customer table, joined with CustomerIdentification for CID resolution.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @username (username lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetBasicInfoByUsername retrieves a user's basic identity profile by their platform username. Usernames are unique on the platform, so this returns at most one row. The matching is case-insensitive via LOWER().

This procedure is part of the GetBasicInfo* family but uniquely uses dbo.Real_Customer (legacy table) rather than Customer.BasicUserInfo. This may be because the legacy table has an optimized index on the LOWER(UserName) column that the newer table lacks.

---

## 2. Business Logic

### 2.1 Case-Insensitive Username Matching

**What**: Username comparison uses LOWER() for case-insensitive matching.

**Columns/Parameters Involved**: `@username`

**Rules**:
- Both stored and input values are lowered before comparison
- Usernames are unique, so at most one row is returned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @username | varchar(20) | NO | - | CODE-BACKED | Username to look up. Case-insensitive via LOWER(). Max 20 characters. |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | GCID | Real_Customer | CODE-BACKED | Global Customer ID. |
| 2 | RealCID | Real_Customer.CID | CODE-BACKED | Legacy real account CID. |
| 3 | FirstName | Real_Customer | CODE-BACKED | First name. |
| 4 | LastName | Real_Customer | CODE-BACKED | Last name. |
| 5 | MiddleName | Real_Customer | CODE-BACKED | Middle name. |
| 6 | Gender | Real_Customer | CODE-BACKED | Gender: 'M'/'F'/'U'. |
| 7 | LanguageID | Real_Customer | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 8 | BirthDate | Real_Customer | CODE-BACKED | Date of birth. |
| 9 | PlayerLevelID | Real_Customer | CODE-BACKED | eToro Club tier. FK to Dictionary.PlayerLevel. |
| 10 | UserName | Real_Customer | CODE-BACKED | Platform username (stored casing). |
| 11 | DemoCID | CustomerIdentification | CODE-BACKED | Demo account CID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | dbo.Real_Customer | JOIN (READER) | Basic identity data source (legacy) |
| (body) | Customer.CustomerIdentification | JOIN (READER) | DemoCID resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by username-based lookup services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBasicInfoByUsername (procedure)
+-- dbo.Real_Customer (table/synonym)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table/Synonym | JOIN - username matching and identity fields |
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

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row count messages |

---

## 8. Sample Queries

### 8.1 Look up user by username
```sql
EXEC Customer.GetBasicInfoByUsername @username = 'traderx'
```

### 8.2 Case-insensitive username lookup
```sql
EXEC Customer.GetBasicInfoByUsername @username = 'TraderX'
-- Same result as 'traderx' due to LOWER() comparison
```

### 8.3 Verify username resolution
```sql
SELECT GCID, CID, UserName FROM dbo.Real_Customer WITH (NOLOCK) WHERE LOWER(UserName) = LOWER('traderx')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetBasicInfoByUsername | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetBasicInfoByUsername.sql*
