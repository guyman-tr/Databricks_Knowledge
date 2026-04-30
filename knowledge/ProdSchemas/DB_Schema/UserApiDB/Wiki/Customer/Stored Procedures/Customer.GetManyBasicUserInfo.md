# Customer.GetManyBasicUserInfo

> Retrieves basic profile info for multiple customers from legacy dbo.Real_Customer table, with demo CID resolution via Customer.CustomerIdentification.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns basic info rows from legacy tables |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetManyBasicUserInfo is a batch reader for basic demographic data using the legacy dbo.Real_Customer table. It returns names, username, gender, language, birth date, and player level, plus the linked demo CID from Customer.CustomerIdentification. Unlike GetManyBasicInfo (which reads from Customer.BasicUserInfo), this procedure reads from the original denormalized Real_Customer table.

The procedure uses a table variable to build results, with a TRY/CATCH on the demo CID lookup so that if the demo link fails, the procedure still returns the core data with NULL for DemoCID.

---

## 2. Business Logic

### 2.1 Resilient Demo CID Lookup

**What**: The demo CID update is wrapped in TRY/CATCH so failures in Customer.CustomerIdentification do not block the core result.

**Columns/Parameters Involved**: `DemoCID`, `Customer.CustomerIdentification`

**Rules**:
- Core data is inserted first from Real_Customer
- Demo CID is updated in a separate step via JOIN to CustomerIdentification
- If the UPDATE fails (any exception), DemoCID remains NULL but the SP returns successfully

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of GCIDs to retrieve basic info for. |
| 2 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | RealCID (output) | int | YES | - | CODE-BACKED | CID from Real_Customer. |
| 4 | DemoCID (output) | int | YES | - | CODE-BACKED | Demo account CID. Updated from CustomerIdentification; NULL on failure. |
| 5 | FirstName (output) | nvarchar(50) | YES | - | CODE-BACKED | User's first name. |
| 6 | LastName (output) | nvarchar(50) | YES | - | CODE-BACKED | User's last name. |
| 7 | MiddleName (output) | nvarchar(50) | YES | - | CODE-BACKED | User's middle name. |
| 8 | UserName (output) | varchar(50) | YES | - | CODE-BACKED | Account username. |
| 9 | Gender (output) | char | YES | - | CODE-BACKED | User's gender. |
| 10 | LanguageID (output) | int | YES | - | CODE-BACKED | Preferred language. |
| 11 | BirthDate (output) | datetime | YES | - | CODE-BACKED | Date of birth. |
| 12 | PlayerLevelID (output) | int | YES | - | CODE-BACKED | Player level. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | dbo.Real_Customer | JOIN | Legacy customer record |
| GCID | Customer.CustomerIdentification | JOIN | Demo CID resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy batch basic info |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetManyBasicUserInfo (procedure)
+-- dbo.Real_Customer (table)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table | FROM - core basic data |
| Customer.CustomerIdentification | Table | JOIN - DemoCID resolution |

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

### 8.1 Get basic user info
```sql
DECLARE @ids dbo.IdList
INSERT @ids VALUES (1001), (1002)
EXEC Customer.GetManyBasicUserInfo @ids = @ids
```

### 8.2 Direct query equivalent
```sql
SELECT bui.GCID, bui.CID AS RealCID, bui.FirstName, bui.LastName, bui.MiddleName,
       bui.UserName, bui.Gender, bui.LanguageID, bui.BirthDate, bui.PlayerLevelID,
       ci.DemoCID
FROM dbo.Real_Customer bui WITH (NOLOCK)
JOIN @ids ids ON ids.Id = bui.GCID
LEFT JOIN Customer.CustomerIdentification ci WITH (NOLOCK) ON ci.GCID = bui.GCID
```

### 8.3 Compare with Customer schema version
```sql
-- GetManyBasicUserInfo reads from dbo.Real_Customer (legacy)
-- GetManyBasicInfo reads from Customer.BasicUserInfo (new)
-- Prefer GetManyBasicInfo for new development
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetManyBasicUserInfo | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetManyBasicUserInfo.sql*
