# AffiliateAdmin.GetAffiliateGroupByID

> Retrieves a single affiliate group's details and its list of viewer users by group ID.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns group details + viewer list (two result sets) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliateGroupByID is the detail-view procedure for the affiliate group management page. When an admin clicks on a specific group in the admin portal, this procedure fetches the group's name and manager assignment, plus the list of all users who have viewing permissions for that group.

This procedure exists because the group edit form needs both the group's core properties and its viewer list in a single call to populate the UI. The two-result-set pattern avoids separate API calls.

Data flow: The admin portal calls this with a single @ID (AffiliatesGroupsID). Result set 1 returns the group's ID, name, and ManagerUserID from AffiliateAdmin.AffiliatesGroups. Result set 2 returns all UserObjectIDs from AffiliateAdmin.AffiliateGroups_Viewers for that group.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple two-table read operation. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ID | int | NO | - | CODE-BACKED | AffiliatesGroupsID of the group to retrieve. Used to filter both AffiliatesGroups and AffiliateGroups_Viewers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | AffiliateAdmin.AffiliatesGroups | Read | Fetches group name and manager for the given ID |
| SELECT | AffiliateAdmin.AffiliateGroups_Viewers | Read | Fetches all viewer UserObjectIDs for the given group |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliateGroupByID (procedure)
+-- AffiliateAdmin.AffiliatesGroups (table)
+-- AffiliateAdmin.AffiliateGroups_Viewers (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.AffiliatesGroups | Table | SELECT for group details |
| AffiliateAdmin.AffiliateGroups_Viewers | Table | SELECT for viewer list |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get group details
```sql
EXEC AffiliateAdmin.GetAffiliateGroupByID @ID = 11;
-- Result 1: AffiliatesGroupsID, AffiliatesGroupsName, ManagerUserID
-- Result 2: UserObjectID (one row per viewer)
```

### 8.2 Manually query group with resolved viewer names
```sql
SELECT ag.AffiliatesGroupsID, ag.AffiliatesGroupsName,
       u.FirstName + ' ' + u.LastName AS ViewerName
FROM AffiliateAdmin.AffiliatesGroups ag WITH (NOLOCK)
JOIN AffiliateAdmin.AffiliateGroups_Viewers v WITH (NOLOCK) ON v.AffiliatesGroupsID = ag.AffiliatesGroupsID
JOIN AffiliateAdmin.Users u WITH (NOLOCK) ON u.UserObjectID = v.UserObjectID
WHERE ag.AffiliatesGroupsID = 11;
```

### 8.3 Find groups with no viewers assigned
```sql
SELECT ag.AffiliatesGroupsID, ag.AffiliatesGroupsName
FROM AffiliateAdmin.AffiliatesGroups ag WITH (NOLOCK)
LEFT JOIN AffiliateAdmin.AffiliateGroups_Viewers v WITH (NOLOCK) ON v.AffiliatesGroupsID = ag.AffiliatesGroupsID
WHERE v.UserObjectID IS NULL AND ag.AffiliatesGroupsID > 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-4500 (Gil, 30/6/2025).

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliateGroupByID | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliateGroupByID.sql*
