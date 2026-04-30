# Customer.GetBasicUserInfoByUsername

> Legacy variant: retrieves basic user profile data by username (case-insensitive) from dbo.Real_Customer using the optimized UserName_LOWER column.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @username (username lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetBasicUserInfoByUsername is the legacy variant of GetBasicInfoByUsername. It retrieves a user's basic identity profile by their platform username from dbo.Real_Customer. Usernames are unique, returning at most one row.

This procedure uses the pre-computed UserName_LOWER column in Real_Customer for efficient case-insensitive matching (comparing LOWER(@username) against the stored lowercase value), rather than applying LOWER() to both sides at query time. This is more performant for indexed lookups.

---

## 2. Business Logic

### 2.1 Optimized Case-Insensitive Username Matching

**What**: Uses the pre-computed UserName_LOWER column for efficient case-insensitive matching.

**Columns/Parameters Involved**: `@username`, `UserName_LOWER`

**Rules**:
- The input is lowered via LOWER(@username)
- Compared against the pre-computed Real_Customer.UserName_LOWER column
- This avoids per-row LOWER() computation, enabling index seeks

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @username | varchar(20) | NO | - | CODE-BACKED | Username to look up. Lowered and matched against UserName_LOWER column. Max 20 characters. |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | GCID | Real_Customer | CODE-BACKED | Global Customer ID. |
| 2 | RealCID | Real_Customer.CID | CODE-BACKED | Legacy CID. |
| 3 | FirstName | Real_Customer | CODE-BACKED | First name. |
| 4 | LastName | Real_Customer | CODE-BACKED | Last name. |
| 5 | MiddleName | Real_Customer | CODE-BACKED | Middle name. |
| 6 | Gender | Real_Customer | CODE-BACKED | Gender. |
| 7 | LanguageID | Real_Customer | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 8 | BirthDate | Real_Customer | CODE-BACKED | Date of birth. |
| 9 | PlayerLevelID | Real_Customer | CODE-BACKED | eToro Club tier. FK to Dictionary.PlayerLevel. |
| 10 | UserName | Real_Customer | CODE-BACKED | Platform username (original casing). |
| 11 | DemoCID | CustomerIdentification | CODE-BACKED | Demo account CID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | dbo.Real_Customer | JOIN (READER) | Username matching via UserName_LOWER and identity data |
| (body) | Customer.CustomerIdentification | JOIN (READER) | DemoCID resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by legacy username lookup services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBasicUserInfoByUsername (procedure)
+-- dbo.Real_Customer (table/synonym)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table/Synonym | JOIN - username matching via UserName_LOWER |
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

### 8.1 Look up by username (legacy)
```sql
EXEC Customer.GetBasicUserInfoByUsername @username = 'traderx'
```

### 8.2 Case-insensitive matching
```sql
EXEC Customer.GetBasicUserInfoByUsername @username = 'TraderX'
-- Internally matches against UserName_LOWER = 'traderx'
```

### 8.3 Verify UserName_LOWER index usage
```sql
SELECT GCID, CID, UserName FROM dbo.Real_Customer WITH (NOLOCK) WHERE UserName_LOWER = LOWER('traderx')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetBasicUserInfoByUsername | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetBasicUserInfoByUsername.sql*
