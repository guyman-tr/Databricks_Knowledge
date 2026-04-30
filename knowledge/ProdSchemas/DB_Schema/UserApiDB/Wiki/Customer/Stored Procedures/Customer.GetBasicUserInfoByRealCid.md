# Customer.GetBasicUserInfoByRealCid

> Legacy variant: retrieves basic user profile data by legacy real account CID from dbo.Real_Customer joined with CustomerIdentification.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @realCid (legacy CID lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetBasicUserInfoByRealCid is the legacy variant of GetBasicInfoByRealCid. It retrieves a user's basic identity profile by their legacy CID, reading from dbo.Real_Customer rather than Customer.BasicUserInfo. Returns a single row.

This procedure exists alongside its newer counterpart for backward compatibility with older integration points that use the legacy CID.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple single-user lookup by legacy CID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @realCid | int | NO | - | CODE-BACKED | Legacy real account Customer ID. Matched against Real_Customer.CID. |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | GCID | Real_Customer | CODE-BACKED | Global Customer ID. |
| 2 | FirstName | Real_Customer | CODE-BACKED | First name. |
| 3 | LastName | Real_Customer | CODE-BACKED | Last name. |
| 4 | MiddleName | Real_Customer | CODE-BACKED | Middle name. |
| 5 | UserName | Real_Customer | CODE-BACKED | Platform username. |
| 6 | Gender | Real_Customer | CODE-BACKED | Gender. |
| 7 | LanguageID | Real_Customer | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 8 | BirthDate | Real_Customer | CODE-BACKED | Date of birth. |
| 9 | PlayerLevelID | Real_Customer | CODE-BACKED | eToro Club tier. FK to Dictionary.PlayerLevel. |
| 10 | DemoCID | CustomerIdentification | CODE-BACKED | Demo account CID. |
| 11 | RealCID | Real_Customer.CID | CODE-BACKED | Legacy CID echoed back. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | dbo.Real_Customer | JOIN (READER) | Identity data source (legacy) |
| (body) | Customer.CustomerIdentification | JOIN (READER) | CID-to-GCID and DemoCID resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by legacy CID-based services |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBasicUserInfoByRealCid (procedure)
+-- dbo.Real_Customer (table/synonym)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table/Synonym | JOIN - identity fields |
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

None.

---

## 8. Sample Queries

### 8.1 Look up by real CID (legacy)
```sql
EXEC Customer.GetBasicUserInfoByRealCid @realCid = 54321
```

### 8.2 Resolve CID to GCID
```sql
SELECT GCID, CID, DemoCID FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE CID = 54321
```

### 8.3 Compare legacy and new variants
```sql
EXEC Customer.GetBasicInfoByRealCid @realCid = 54321
EXEC Customer.GetBasicUserInfoByRealCid @realCid = 54321
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetBasicUserInfoByRealCid | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetBasicUserInfoByRealCid.sql*
