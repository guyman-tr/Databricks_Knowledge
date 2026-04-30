# Customer.GetManyBasicInfo

> Retrieves basic profile info for multiple customers from Customer schema tables - names, gender, language, birth date, player level, and linked demo CID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns basic info rows for a GCID list |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyBasicInfo is a batch reader that retrieves basic demographic profile data for multiple customers from the Customer schema tables (Customer.BasicUserInfo and Customer.CustomerIdentification). This is the "new-style" basic info getter that reads from the normalized Customer schema rather than the legacy dbo.Real_Customer table.

This procedure provides the essential identity fields needed for display purposes: names, gender, language, birth date, player level, and the linked demo CID. It is lighter-weight than the aggregated info procedures.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Batch read by GCID list.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to retrieve basic info for. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | RealCID (output) | int | YES | - | CODE-BACKED | CID of the real account. From Customer.CustomerIdentification. |
| 4 | FirstName (output) | nvarchar | YES | - | CODE-BACKED | User's first name. |
| 5 | LastName (output) | nvarchar | YES | - | CODE-BACKED | User's last name. |
| 6 | MiddleName (output) | nvarchar | YES | - | CODE-BACKED | User's middle name. |
| 7 | UserName (output) | varchar | YES | - | CODE-BACKED | Account username. |
| 8 | Gender (output) | char | YES | - | CODE-BACKED | User's gender. |
| 9 | LanguageID (output) | int | YES | - | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 10 | BirthDate (output) | datetime | YES | - | CODE-BACKED | Date of birth. |
| 11 | PlayerLevelID (output) | int | YES | - | CODE-BACKED | Player level. FK to Dictionary.PlayerLevel. |
| 12 | DemoCID (output) | int | YES | - | CODE-BACKED | Demo account CID. From Customer.CustomerIdentification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | Customer.BasicUserInfo | INNER JOIN | Basic profile data |
| GCID | Customer.CustomerIdentification | INNER JOIN | RealCID and DemoCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Batch basic info retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyBasicInfo (procedure)
+-- Customer.BasicUserInfo (table)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BasicUserInfo | Table | INNER JOIN on GCID - basic profile data |
| Customer.CustomerIdentification | Table | INNER JOIN on GCID - CID mapping |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get basic info for multiple customers
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002), (1003)
EXEC Customer.GetManyBasicInfo @ids = @ids
```

### 8.2 Direct query equivalent
```sql
SELECT cc.GCID, ci.CID AS RealCID, cc.FirstName, cc.LastName, cc.MiddleName,
       cc.UserName, cc.Gender, cc.LanguageID, cc.BirthDate, cc.PlayerLevelID, ci.DemoCID
FROM Customer.BasicUserInfo cc WITH (NOLOCK)
JOIN @ids i ON cc.GCID = i.Id
JOIN Customer.CustomerIdentification ci WITH (NOLOCK) ON cc.GCID = ci.GCID
```

### 8.3 Get basic info with language name
```sql
SELECT cc.GCID, cc.FirstName, cc.LastName, l.Name AS LanguageName
FROM Customer.BasicUserInfo cc WITH (NOLOCK)
JOIN @ids i ON cc.GCID = i.Id
LEFT JOIN Dictionary.Language l WITH (NOLOCK) ON cc.LanguageID = l.LanguageID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyBasicInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyBasicInfo.sql*
