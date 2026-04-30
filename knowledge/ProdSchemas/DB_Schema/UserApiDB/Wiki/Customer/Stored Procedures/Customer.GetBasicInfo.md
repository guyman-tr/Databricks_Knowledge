# Customer.GetBasicInfo

> Returns basic user identity plus CID/DemoCID mapping by joining BasicUserInfo with CustomerIdentification.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetBasicInfo retrieves basic user profile data plus the CID mapping. Joins Customer.BasicUserInfo (for identity data) with Customer.CustomerIdentification (for RealCID and DemoCID). Returns GCID, RealCID, FirstName, LastName, MiddleName, UserName, Gender, LanguageID, BirthDate, PlayerLevelID, DemoCID.

---

## 2. Business Logic

No complex business logic. SELECT with INNER JOIN on GCID, using NOLOCK hints.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |

Output: GCID, RealCID (aliased CID), FirstName, LastName, MiddleName, UserName, Gender, LanguageID, BirthDate, PlayerLevelID, DemoCID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.BasicUserInfo | SELECT FROM | Identity data |
| - | Customer.CustomerIdentification | INNER JOIN | CID/DemoCID mapping |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBasicInfo (procedure)
  +-- Customer.BasicUserInfo (table) [done]
  +-- Customer.CustomerIdentification (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BasicUserInfo | Table | SELECT FROM |
| Customer.CustomerIdentification | Table | INNER JOIN |

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

### 8.1 Get basic info
```sql
EXEC Customer.GetBasicInfo @gcid = 12345
```

### 8.2 Direct query equivalent
```sql
SELECT cc.GCID, ci.CID AS RealCID, cc.FirstName, cc.LastName, cc.UserName, cc.BirthDate, ci.DemoCID
FROM Customer.BasicUserInfo cc WITH (NOLOCK) JOIN Customer.CustomerIdentification ci WITH (NOLOCK) ON cc.GCID = ci.GCID
WHERE cc.GCID = 12345
```

### 8.3 With language name
```sql
DECLARE @Result TABLE (GCID INT, RealCID INT, FirstName NVARCHAR(50), LastName NVARCHAR(50), MiddleName NVARCHAR(50), UserName VARCHAR(20), Gender CHAR(1), LanguageID INT, BirthDate DATETIME, PlayerLevelID INT, DemoCID INT)
INSERT INTO @Result EXEC Customer.GetBasicInfo @gcid = 12345
SELECT r.*, l.Name AS Language FROM @Result r JOIN Dictionary.Language l WITH (NOLOCK) ON r.LanguageID = l.LanguageID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetBasicInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetBasicInfo.sql*
