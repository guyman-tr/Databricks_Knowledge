# Customer.BasicUserInfo (UDT)

> Table-valued parameter type for bulk updating basic user profile data including language, gender, and player level.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | GCID (user identifier column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.BasicUserInfo is a table-valued parameter (TVP) type for passing batches of basic user profile updates. It carries the minimal set of fields for bulk profile changes: language preference, gender, and eToro Club level (player level). Used by Customer.Bulk_UpdateBasicUserInfo.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Data transport type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | YES | - | CODE-BACKED | Global Customer ID - unique user identifier. |
| 2 | languageId | int | YES | - | CODE-BACKED | User's preferred language. Maps to Dictionary.Language.LanguageID. |
| 3 | gender | char(1) | YES | - | CODE-BACKED | User's gender: 'M'=Male, 'F'=Female, 'U'=Undisclosed. |
| 4 | level | int | YES | - | CODE-BACKED | eToro Club membership tier. Maps to Dictionary.PlayerLevel.PlayerLevelID. 1=Bronze through 7=Diamond. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.Bulk_UpdateBasicUserInfo | @BulkUpdateTable parameter | Parameter Type | TVP for bulk basic info updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.Bulk_UpdateBasicUserInfo | Stored Procedure | Uses as READONLY parameter type |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate
```sql
DECLARE @Updates Customer.BasicUserInfo
INSERT INTO @Updates (GCID, languageId, level) VALUES (12345, 1, 3)
EXEC Customer.Bulk_UpdateBasicUserInfo @BulkUpdateTable = @Updates
```

### 8.2 Bulk language change
```sql
DECLARE @Updates Customer.BasicUserInfo
INSERT INTO @Updates (GCID, languageId) SELECT GCID, 25 FROM Customer.BasicUserInfo WITH (NOLOCK) WHERE LanguageID = 1
```

### 8.3 Inspect contents
```sql
DECLARE @Data Customer.BasicUserInfo
INSERT INTO @Data (GCID, gender) VALUES (1, 'M'), (2, 'F')
SELECT * FROM @Data
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: Customer.BasicUserInfo | Type: User Defined Type | Source: UserApiDB/UserApiDB/Customer/User Defined Types/Customer.BasicUserInfo.sql*
