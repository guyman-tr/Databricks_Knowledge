# dbo.GetAffiliatePushInformationByAffiliateID_NogaJunk0226

> Returns the affiliate group name and the name of the assigned affiliate manager for a given affiliate using legacy table references (marked as junk/deprecated as of February 2026).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AffiliateID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure was the "push" counterpart to GetAffiliatePullInformationByAffiliateID, originally returning the affiliate's group name and manager name for display or downstream push to external systems. The "_NogaJunk0226" suffix was added in February 2026 when this SP was superseded by a version using the new AffiliateAdmin.AffiliatesGroups schema (PART-5531). The procedure still references the legacy tables (dbo.tblaff_AffiliatesGroups, dbo.tblaff_User) using three-part naming (fiktivo.dbo...) which is an anti-pattern. It should be treated as deprecated and not used in new development. Original work by Gonen Frim (Nov 2015), updated by Geri Reshef (Jan 2016, ticket 33411).

---

## 2. Business Logic

- JOINs tblaff_Affiliates to tblaff_AffiliatesGroups on AffiliatesGroupsID, then LEFT JOINs tblaff_User on ManagerUserID.
- References tables using the three-part fiktivo.dbo.* naming convention, which will break in cross-database or linked-server contexts.
- Returns AffiliatesGroupsName (as groupName) and tblaff_User.Name (as AffiliateManagerName).
- No NOCOUNT, no SET ANSI_NULLS, no explicit transaction.
- The "_NogaJunk0226" suffix signals this is retained only for backward compatibility or comparison purposes.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @AffiliateID | INT | IN | (required) | High | Affiliate whose group and manager name are being fetched |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | fiktivo.dbo.tblaff_Affiliates | Read | Core affiliate record |
| JOIN | fiktivo.dbo.tblaff_AffiliatesGroups | Read | Legacy group table (deprecated, superseded by AffiliateAdmin.AffiliatesGroups) |
| LEFT JOIN | fiktivo.dbo.tblaff_User | Read | Legacy user table for manager name |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetAffiliatePushInformationByAffiliateID_NogaJunk0226
  ├── dbo.tblaff_Affiliates          (READ, legacy 3-part name)
  ├── dbo.tblaff_AffiliatesGroups    (READ, DEPRECATED legacy table)
  └── dbo.tblaff_User                (READ, legacy user table)
```

### 6.1 Objects This Depends On

| Object | Type | Usage |
|--------|------|-------|
| dbo.tblaff_Affiliates | Table | Core affiliate record |
| dbo.tblaff_AffiliatesGroups | Table | DEPRECATED - legacy groups table (use AffiliateAdmin.AffiliatesGroups) |
| dbo.tblaff_User | Table | DEPRECATED - legacy user/manager table (use AffiliateAdmin.Users) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes
N/A for stored procedure.

### 7.2 Constraints
N/A for stored procedure.

---

## 8. Sample Queries

```sql
-- Retrieve group and manager for affiliate 12345 (legacy, use with caution)
EXEC dbo.GetAffiliatePushInformationByAffiliateID_NogaJunk0226 @AffiliateID = 12345;

-- Preferred modern equivalent using new schema
SELECT ag.AffiliatesGroupsName AS groupName,
       CONCAT(U.FirstName, ' ', U.LastName) AS AffiliateManagerName
FROM dbo.tblaff_Affiliates A WITH (NOLOCK)
LEFT JOIN AffiliateAdmin.AffiliatesGroups ag WITH (NOLOCK) ON ag.AffiliatesGroupsID = A.AffiliatesGroupsID
LEFT JOIN AffiliateAdmin.Users U WITH (NOLOCK) ON U.UserObjectID = ag.ManagerUserID
WHERE A.AffiliateID = 12345;

-- Comparison call for migration validation
EXEC dbo.GetAffiliatePushInformationByAffiliateID_NogaJunk0226 @AffiliateID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.
*(Author notes: Gonen Frim, 30/11/2015; Geri Reshef, 14/01/2016, ticket 33411. Renamed to _NogaJunk0226 per PART-5531 migration in Feb 2026.)*

---

*Generated: 2026-04-12 | Quality: 7.8/10*
*Object: dbo.GetAffiliatePushInformationByAffiliateID_NogaJunk0226 | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetAffiliatePushInformationByAffiliateID_NogaJunk0226.sql*
