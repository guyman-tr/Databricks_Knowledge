# Customer.GetPrivateAggregatedInfo_NEW

> Optimized version of GetPrivateAggregatedInfo that uses Customer.CustomerIdentification as the primary join table for CID/GCID resolution, reducing reads on Real_Customer for the demo CID lookup path.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns private profile rows (optimized path) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetPrivateAggregatedInfo_NEW is an optimized version of Customer.GetPrivateAggregatedInfo. It returns identical output columns (40 fields including ExternalID, SalesForce IDs, AttributeID, WeekendFeePercentage) but uses a more efficient query structure.

The key optimization is in the demo CID resolution: instead of joining Real_Customer first and then doing an OUTER APPLY to CustomerIdentification, the _NEW version joins CustomerIdentification directly in the CID/GCID lookup step, then joins Real_Customer via GCID from the @demoCids table variable. This reduces redundant reads when many customers are queried. The SELECT is also unified into a single code path instead of three separate SELECT blocks.

---

## 2. Business Logic

### 2.1 Optimized Triple Lookup Mode

**What**: Same three modes as GetPrivateAggregatedInfo but with CustomerIdentification as the primary resolution table for CID/GCID modes.

**Columns/Parameters Involved**: `@isUsernames`, `@isGcid`, `@ids`, `@usernames`

**Rules**:
- @isUsernames=1: Still uses Real_Customer + OUTER APPLY CustomerIdentification (same as original)
- @isGcid=0: Now joins CustomerIdentification by CID directly (rc.DemoCID from CustomerIdentification)
- @isGcid=1: Now joins CustomerIdentification by GCID directly
- Single unified SELECT statement after resolution (instead of 3 duplicate SELECTs)
- SET NOCOUNT ON for reduced network traffic

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ids | dbo.IdList (TVP) | NO | - | CODE-BACKED | List of CIDs or GCIDs depending on @isGcid flag. |
| 2 | @usernames | dbo.UsernameList (TVP) | NO | - | CODE-BACKED | List of usernames. Used only when @isUsernames=1. |
| 3 | @isGcid | bit | NO | - | CODE-BACKED | Lookup mode: 0=by CID, 1=by GCID. |
| 4 | @isUsernames | bit | NO | - | CODE-BACKED | When 1, lookup by username. |
| 5-40 | (Same 36 output columns as GetPrivateAggregatedInfo) | - | - | - | CODE-BACKED | Identical output: GCID, RealCID, DemoCID, UserName, names, language, country, settings, bio, WhiteLabelID, privacy, guru/player status, ExternalID, account type, KYC, regulation, trading risk, email, registration, attribution, SalesForce IDs, WeekendFeePercentage. See GetPrivateAggregatedInfo for full descriptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ids | Customer.CustomerIdentification | JOIN | Primary CID/GCID resolution (optimized path) |
| GCID | dbo.Real_Customer | JOIN | Core customer data |
| CID | dbo.Real_BackOfficeCustomer | JOIN | Back-office data |
| CID | dbo.General_Settings | LEFT JOIN | Privacy settings |
| GCID | UserAttribution.UserAttributes | LEFT JOIN | User interest |
| CID | dbo.Publications | OUTER APPLY | Bio content |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Optimized login/admin profile retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetPrivateAggregatedInfo_NEW (procedure)
+-- Customer.CustomerIdentification (table)
+-- dbo.Real_Customer (table)
+-- dbo.Real_BackOfficeCustomer (table)
+-- dbo.General_Settings (table)
+-- UserAttribution.UserAttributes (table)
+-- dbo.Publications (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | JOIN - CID/GCID/DemoCID resolution |
| dbo.Real_Customer | Table | JOIN on GCID - core data |
| dbo.Real_BackOfficeCustomer | Table | JOIN on CID - back-office |
| dbo.General_Settings | Table | LEFT JOIN - settings |
| UserAttribution.UserAttributes | Table | LEFT JOIN - attribution |
| dbo.Publications | Table | OUTER APPLY - bio |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Reduces network chatter |
| TRY/CATCH on demo CID | Error handling | Same resilient demo lookup |

---

## 8. Sample Queries

### 8.1 Get private info by GCID (optimized)
```sql
DECLARE @ids dbo.IdList
DECLARE @usernames dbo.UsernameList
INSERT @ids VALUES (50001)
EXEC Customer.GetPrivateAggregatedInfo_NEW @ids=@ids, @usernames=@usernames, @isGcid=1, @isUsernames=0
```

### 8.2 Compare with original
```sql
-- GetPrivateAggregatedInfo_NEW: joins CustomerIdentification first, then Real_Customer
-- GetPrivateAggregatedInfo: joins Real_Customer first, then OUTER APPLY CustomerIdentification
-- Output is identical; _NEW is more efficient for CID/GCID lookup modes
```

### 8.3 Get private info by username (same path as original)
```sql
DECLARE @ids dbo.IdList
DECLARE @usernames dbo.UsernameList
INSERT @usernames VALUES ('johndoe123')
EXEC Customer.GetPrivateAggregatedInfo_NEW @ids=@ids, @usernames=@usernames, @isGcid=0, @isUsernames=1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 9/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 40 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetPrivateAggregatedInfo_NEW | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetPrivateAggregatedInfo_NEW.sql*
