# Customer.GetBasicUserInfoByDemoCid

> Legacy variant: retrieves basic user profile data by demo account CID from dbo.Real_Customer joined with CustomerIdentification.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @demoCid (demo account lookup) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetBasicUserInfoByDemoCid is the legacy variant of GetBasicInfoByDemoCid. It retrieves a user's basic identity profile using their demo account CID, but reads from the legacy dbo.Real_Customer table rather than the newer Customer.BasicUserInfo.

This procedure exists alongside its newer counterpart (GetBasicInfoByDemoCid) for backward compatibility. Both return the same column set; the only difference is the data source table. The legacy variant uses Real_Customer which is a synonym/view of the original customer data structure.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple lookup by demo CID via legacy table.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @demoCid | int | NO | - | CODE-BACKED | Demo account Customer ID. Matched against CustomerIdentification.DemoCID. |

**Return Columns:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | GCID | Real_Customer | CODE-BACKED | Global Customer ID. |
| 2 | RealCID | Real_Customer.CID | CODE-BACKED | Legacy real account CID. |
| 3 | FirstName | Real_Customer | CODE-BACKED | First name. |
| 4 | LastName | Real_Customer | CODE-BACKED | Last name. |
| 5 | MiddleName | Real_Customer | CODE-BACKED | Middle name. |
| 6 | UserName | Real_Customer | CODE-BACKED | Platform username. |
| 7 | Gender | Real_Customer | CODE-BACKED | Gender: 'M'/'F'/'U'. |
| 8 | LanguageID | Real_Customer | CODE-BACKED | Preferred language. FK to Dictionary.Language. |
| 9 | BirthDate | Real_Customer | CODE-BACKED | Date of birth. |
| 10 | PlayerLevelID | Real_Customer | CODE-BACKED | eToro Club tier. FK to Dictionary.PlayerLevel. |
| 11 | DemoCID | CustomerIdentification | CODE-BACKED | Demo account CID (echoed back). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | dbo.Real_Customer | JOIN (READER) | Basic identity data source (legacy) |
| (body) | Customer.CustomerIdentification | JOIN (READER) | DemoCID-to-GCID resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by legacy services with demo CID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetBasicUserInfoByDemoCid (procedure)
+-- dbo.Real_Customer (table/synonym)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_Customer | Table/Synonym | JOIN - identity fields |
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

### 8.1 Look up user by demo CID (legacy)
```sql
EXEC Customer.GetBasicUserInfoByDemoCid @demoCid = 99999
```

### 8.2 Compare with newer variant
```sql
-- Both should return the same data
EXEC Customer.GetBasicInfoByDemoCid @demoCid = 99999
EXEC Customer.GetBasicUserInfoByDemoCid @demoCid = 99999
```

### 8.3 Resolve demo to real CID
```sql
SELECT CID, DemoCID, GCID FROM Customer.CustomerIdentification WITH (NOLOCK) WHERE DemoCID = 99999
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetBasicUserInfoByDemoCid | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetBasicUserInfoByDemoCid.sql*
