# Customer.GetBasicUserInfo

> Legacy-path version of GetBasicInfo, reading from Real_Customer dbo view plus CustomerIdentification for CID mapping.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid (input param) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetBasicUserInfo is the legacy equivalent of GetBasicInfo. Reads from Real_Customer (dbo synonym/view) instead of Customer.BasicUserInfo directly. Returns the same output: GCID, RealCID, name, username, gender, language, birthdate, player level, and DemoCID. The difference is the data source path through the legacy view layer.

---

## 2. Business Logic

No complex business logic. SELECT with INNER JOIN, NOLOCK hints.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |

Output: GCID, RealCID, FirstName, LastName, MiddleName, UserName, Gender, LanguageID, BirthDate, PlayerLevelID, DemoCID.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Real_Customer (dbo) | SELECT FROM | Legacy customer view |
| - | Customer.CustomerIdentification | INNER JOIN | CID/DemoCID mapping |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBasicUserInfo (procedure)
  +-- Real_Customer (dbo synonym/view)
  +-- Customer.CustomerIdentification (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Real_Customer | dbo synonym/view | SELECT FROM |
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

### 8.1 Get basic user info (legacy path)
```sql
EXEC Customer.GetBasicUserInfo @gcid = 12345
```

### 8.2 Compare with modern path
```sql
EXEC Customer.GetBasicUserInfo @gcid = 12345  -- legacy
EXEC Customer.GetBasicInfo @gcid = 12345      -- modern
```

### 8.3 Direct query
```sql
SELECT cc.GCID, cc.CID AS RealCID, cc.FirstName, cc.LastName, cc.UserName, CI.DemoCID
FROM Real_Customer cc WITH (NOLOCK) JOIN Customer.CustomerIdentification CI WITH (NOLOCK) ON cc.GCID = CI.GCID
WHERE cc.GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.GetBasicUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetBasicUserInfo.sql*
