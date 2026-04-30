# Customer.GetBasicInfoByDemoCid

> Retrieves basic user profile data (name, username, gender, language, DOB, player level) by looking up a user's demo account CID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @demoCid (demo account lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetBasicInfoByDemoCid retrieves a user's basic identity profile using their demo account CID as the lookup key. This enables services that only have a demo CID (e.g., from demo trading activity) to resolve the user's real identity and profile data.

This procedure is part of the GetBasicInfo* family - four procedures that return the same basic profile columns but accept different lookup keys (DemoCID, Names, RealCID, Username). It uses the newer Customer.BasicUserInfo table directly rather than the legacy dbo.Real_Customer.

The procedure JOINs Customer.BasicUserInfo with Customer.CustomerIdentification to resolve DemoCID to GCID and retrieve the basic profile fields.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple lookup returning basic identity fields by demo CID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @demoCid | int | NO | - | CODE-BACKED | Demo account Customer ID to look up. Matched against CustomerIdentification.DemoCID. |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | GCID | BasicUserInfo | CODE-BACKED | Global Customer ID. |
| 2 | RealCID | CustomerIdentification.CID | CODE-BACKED | Legacy real account CID. |
| 3 | FirstName | BasicUserInfo | CODE-BACKED | First name. |
| 4 | LastName | BasicUserInfo | CODE-BACKED | Last name. |
| 5 | MiddleName | BasicUserInfo | CODE-BACKED | Middle name. |
| 6 | UserName | BasicUserInfo | CODE-BACKED | Platform username. |
| 7 | Gender | BasicUserInfo | CODE-BACKED | Gender: 'M'/'F'/'U'. |
| 8 | LanguageID | BasicUserInfo | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 9 | BirthDate | BasicUserInfo | CODE-BACKED | Date of birth. |
| 10 | PlayerLevelID | BasicUserInfo | CODE-BACKED | eToro Club tier. FK to Dictionary.PlayerLevel. |
| 11 | DemoCID | CustomerIdentification | CODE-BACKED | Demo account CID (echoed back). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.BasicUserInfo | JOIN (READER) | Basic identity data source |
| (body) | Customer.CustomerIdentification | JOIN (READER) | DemoCID-to-GCID resolution and RealCID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by services with demo CID context |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBasicInfoByDemoCid (procedure)
+-- Customer.BasicUserInfo (table)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BasicUserInfo | Table | JOIN - basic identity fields |
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

### 8.1 Look up user by demo CID
```sql
EXEC Customer.GetBasicInfoByDemoCid @demoCid = 99999
```

### 8.2 Verify demo CID resolution
```sql
SELECT ci.GCID, ci.CID, ci.DemoCID, bi.UserName
FROM Customer.CustomerIdentification ci WITH (NOLOCK)
JOIN Customer.BasicUserInfo bi WITH (NOLOCK) ON bi.GCID = ci.GCID
WHERE ci.DemoCID = 99999
```

### 8.3 Find all demo accounts with basic info
```sql
SELECT TOP 10 ci.DemoCID, bi.GCID, bi.UserName, bi.FirstName, bi.LastName
FROM Customer.CustomerIdentification ci WITH (NOLOCK)
JOIN Customer.BasicUserInfo bi WITH (NOLOCK) ON bi.GCID = ci.GCID
WHERE ci.DemoCID IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetBasicInfoByDemoCid | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetBasicInfoByDemoCid.sql*
