# Customer.GetBasicInfoByRealCid

> Retrieves basic user profile data (name, username, gender, language, DOB, player level) by looking up a user's legacy real account CID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @realCid (legacy CID lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetBasicInfoByRealCid retrieves a user's basic identity profile using their legacy real account CID as the lookup key. This serves integrations and older services that still operate with the legacy CID identifier rather than the newer GCID.

This procedure is part of the GetBasicInfo* family using the newer Customer.BasicUserInfo table. It JOINs with Customer.CustomerIdentification to match CID to GCID and return the basic profile along with the DemoCID.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-user lookup by CID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @realCid | int | NO | - | CODE-BACKED | Legacy real account Customer ID. Matched against CustomerIdentification.CID. |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | GCID | BasicUserInfo | CODE-BACKED | Global Customer ID. |
| 2 | FirstName | BasicUserInfo | CODE-BACKED | First name. |
| 3 | LastName | BasicUserInfo | CODE-BACKED | Last name. |
| 4 | MiddleName | BasicUserInfo | CODE-BACKED | Middle name. |
| 5 | UserName | BasicUserInfo | CODE-BACKED | Platform username. |
| 6 | Gender | BasicUserInfo | CODE-BACKED | Gender: 'M'/'F'/'U'. |
| 7 | LanguageID | BasicUserInfo | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 8 | BirthDate | BasicUserInfo | CODE-BACKED | Date of birth. |
| 9 | PlayerLevelID | BasicUserInfo | CODE-BACKED | eToro Club tier. FK to Dictionary.PlayerLevel. |
| 10 | DemoCID | CustomerIdentification | CODE-BACKED | Demo account CID. |
| 11 | RealCID | CustomerIdentification.CID | CODE-BACKED | Legacy CID echoed back. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Customer.BasicUserInfo | JOIN (READER) | Basic identity data source |
| (body) | Customer.CustomerIdentification | JOIN (READER) | CID-to-GCID resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by legacy CID-based services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBasicInfoByRealCid (procedure)
+-- Customer.BasicUserInfo (table)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BasicUserInfo | Table | JOIN - identity fields |
| Customer.CustomerIdentification | Table | JOIN - CID resolution |

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

### 8.1 Look up user by real CID
```sql
EXEC Customer.GetBasicInfoByRealCid @realCid = 54321
```

### 8.2 Verify CID-to-GCID resolution
```sql
SELECT ci.GCID, ci.CID, ci.DemoCID, bi.UserName
FROM Customer.CustomerIdentification ci WITH (NOLOCK)
JOIN Customer.BasicUserInfo bi WITH (NOLOCK) ON bi.GCID = ci.GCID
WHERE ci.CID = 54321
```

### 8.3 Find user with both real and demo accounts
```sql
SELECT ci.CID, ci.DemoCID, bi.UserName
FROM Customer.CustomerIdentification ci WITH (NOLOCK)
JOIN Customer.BasicUserInfo bi WITH (NOLOCK) ON bi.GCID = ci.GCID
WHERE ci.CID = 54321 AND ci.DemoCID IS NOT NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetBasicInfoByRealCid | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetBasicInfoByRealCid.sql*
