# dbo.tblaff_AffiliatesGroups

> Organizational groups that partition affiliates for management assignment, reporting segmentation, and access control scoping.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | AffiliatesGroupsID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

This table defines the organizational groups into which affiliates are segmented. Each group represents a portfolio or channel segment (e.g., "Affiliates", "Media", "SEM", "SEO") managed by a specific admin user. Groups are the primary access control boundary - admin users in tblaff_User have their AffiliatesGroups column set to a comma-separated list of group IDs they can manage.

Without this table, the platform could not segment affiliates into manageable portfolios or assign dedicated account managers. Groups appear throughout the system: in affiliate assignment, in reporting filters, and in the Channels denormalized lookup. Group 1 ("* VIEW ALL GROUPS *") is a special sentinel representing unrestricted access.

The table has a trigger (tblaff_AffiliatesGroups_UTrig, currently DISABLED) that was designed to sync manager changes to Dynamics CRM via Service Broker. Managed by admin users with AffiliateGroups_* permissions.

---

## 2. Business Logic

### 2.1 Sentinel Group

**What**: Group 1 is a system-reserved entry that represents "all groups" in access control contexts.

**Columns/Parameters Involved**: `AffiliatesGroupsID`, `AffiliatesGroupsName`

**Rules**:
- AffiliatesGroupsID = 1 with name "* VIEW ALL GROUPS *" is not a real group
- When tblaff_User.AffiliatesGroups contains "1", it means the user can see all groups
- Real affiliate groups start from ID 2 ("Affiliates" is the default per tblaff_Affiliates.AffiliatesGroupsID DEFAULT 2)

---

## 3. Data Overview

| AffiliatesGroupsID | AffiliatesGroupsName | ManagerUserID | Meaning |
|--------------------|--------------------|--------------|---------|
| 1 | * VIEW ALL GROUPS * | NULL | System sentinel - not a real group. Represents unrestricted group access for admin users. |
| 2 | Affiliates | 0 | Default affiliate group. New affiliates are assigned here (DEFAULT constraint on tblaff_Affiliates). No dedicated manager (0). |
| 4 | SEM | 7 | Paid search (SEM) affiliate channel managed by UserID 7. Groups affiliates acquired through search marketing. |
| 5 | SEO | 80 | Organic search (SEO) affiliate channel managed by UserID 80. Groups affiliates from organic search partnerships. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AffiliatesGroupsID | int | NO | IDENTITY(1,1) | CODE-BACKED | Primary key. Referenced by tblaff_Affiliates.AffiliatesGroupsID, tblaff_Country.AffiliatesGroupsID, dbo.Channels.AffiliatesGroupsID, and tblaff_AffiliateGroups_Viewers. ID=1 is the "view all" sentinel. |
| 2 | AffiliatesGroupsName | nvarchar(50) | NO | - | CODE-BACKED | Display name of the group (e.g., "Affiliates", "Media", "SEM"). Shown in admin UI dropdowns, reports, and affiliate portal. MASKED (dynamic data masking) in non-privileged contexts. |
| 3 | AccountManagerName | nvarchar(50) | YES | - | CODE-BACKED | Display name of the assigned account manager. MASKED. Denormalized from tblaff_User for quick display. May be blank if no manager assigned. |
| 4 | AccountManagerEmail | nvarchar(50) | YES | - | CODE-BACKED | Email of the assigned account manager. MASKED. Used in Dynamics CRM sync trigger for group manager change notifications. |
| 5 | AccountManagerImagePath | nvarchar(200) | YES | - | NAME-INFERRED | URL/path to the account manager's profile photo. Displayed in the affiliate portal alongside the group contact information. |
| 6 | ManagerUserID | int | YES | - | CODE-BACKED | FK to dbo.tblaff_User.UserID. The admin user responsible for this group. 0 or NULL = no dedicated manager. Used in the Dynamics CRM sync trigger. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ManagerUserID | [dbo.tblaff_User](dbo.tblaff_User.md) | Implicit FK | Admin user assigned as group manager. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.tblaff_Affiliates | AffiliatesGroupsID | Implicit FK | Each affiliate belongs to exactly one group. |
| dbo.tblaff_Country | AffiliatesGroupsID | Implicit FK | Default group for affiliates from a specific country. |
| dbo.Channels | AffiliatesGroupsID | Implicit FK | Denormalized group reference. |
| dbo.tblaff_AffiliateGroups_Viewers | AffiliatesGroupsID | Implicit FK | Controls which admin users can view this group. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no hard dependencies (ManagerUserID is implicit).

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | AffiliatesGroupsID implicit FK |
| dbo.tblaff_Country | Table | AffiliatesGroupsID implicit FK |
| dbo.Channels | Table | AffiliatesGroupsID implicit FK |
| dbo.UpdateInsertAffiliateGroup | Stored Procedure | WRITER/MODIFIER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AffiliatesGroups | CLUSTERED PK | AffiliatesGroupsID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| tblaff_AffiliatesGroups_UTrig | TRIGGER (UPDATE) | Dynamics CRM sync on manager change (DISABLED). Sends XML via Service Broker when ManagerUserID changes. |

---

## 8. Sample Queries

### 8.1 List all real groups with their managers
```sql
SELECT ag.AffiliatesGroupsID, ag.AffiliatesGroupsName, u.Name AS ManagerName
FROM dbo.tblaff_AffiliatesGroups ag WITH (NOLOCK)
LEFT JOIN dbo.tblaff_User u WITH (NOLOCK) ON ag.ManagerUserID = u.UserID
WHERE ag.AffiliatesGroupsID > 1
ORDER BY ag.AffiliatesGroupsName
```

### 8.2 Count affiliates per group
```sql
SELECT ag.AffiliatesGroupsName, COUNT(a.AffiliateID) AS AffiliateCount
FROM dbo.tblaff_AffiliatesGroups ag WITH (NOLOCK)
LEFT JOIN dbo.tblaff_Affiliates a WITH (NOLOCK) ON ag.AffiliatesGroupsID = a.AffiliatesGroupsID
WHERE ag.AffiliatesGroupsID > 1
GROUP BY ag.AffiliatesGroupsName
ORDER BY AffiliateCount DESC
```

### 8.3 Find groups without assigned managers
```sql
SELECT AffiliatesGroupsID, AffiliatesGroupsName
FROM dbo.tblaff_AffiliatesGroups WITH (NOLOCK)
WHERE (ManagerUserID IS NULL OR ManagerUserID = 0)
  AND AffiliatesGroupsID > 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 8.3/10, Logic: 5.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 10/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.tblaff_AffiliatesGroups | Type: Table | Source: fiktivo/dbo/Tables/dbo.tblaff_AffiliatesGroups.sql*
