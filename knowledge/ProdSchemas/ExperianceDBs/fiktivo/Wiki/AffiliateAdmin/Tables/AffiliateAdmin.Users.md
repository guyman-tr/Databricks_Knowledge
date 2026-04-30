# AffiliateAdmin.Users

> Internal back-office user accounts synced from Azure Active Directory, representing eToro employees who manage affiliate operations through the affiliate admin portal.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Table |
| **Key Identifier** | UserObjectID (uniqueidentifier, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

AffiliateAdmin.Users stores the identity records of internal eToro staff who operate the affiliate management back-office. Each row represents a single employee who can be assigned as an account manager for affiliate groups or granted visibility into specific affiliate group data. The table is the authoritative source of UUID-based user identity for the AffiliateAdmin schema.

This table exists because the affiliate admin portal needs to know which employees can manage affiliates, view group-scoped payment data, and perform administrative actions. Without it, there would be no way to link Azure AD identities to affiliate group management roles. It replaced the legacy integer-based `dbo.tblaff_User` table as part of the PART-4500 migration (June-July 2025).

Data flows into this table exclusively through `AffiliateAdmin.SyncUsersFromAzure`, which receives a batch of user records from Azure AD via a table-valued parameter and inserts any users not already present (insert-only - no updates). The table is read by multiple procedures across schemas: `dbo.GetAffiliateById`, `dbo.GetAffiliateByAzureObjectId`, and `Affiliate.GetAffiliates` all LEFT JOIN to this table via `AffiliatesGroups.ManagerUserID` to resolve the account manager's name and email for affiliate profile displays. `dbo.GetPayments` joins via email matching to map legacy UserIDs to the new UserObjectID-based access control.

---

## 2. Business Logic

### 2.1 Azure AD Sync (Insert-Only)

**What**: Users are synchronized from Azure Active Directory in a one-way, insert-only pattern - new users are added but existing users are never updated or deleted.

**Columns/Parameters Involved**: `UserObjectID`, `FirstName`, `LastName`, `Email`

**Rules**:
- `SyncUsersFromAzure` accepts a `AffiliateAdmin.UserTableType` TVP containing the full user list from Azure AD
- Only users whose `UserObjectID` does NOT already exist in the table are inserted (LEFT JOIN anti-pattern)
- Inserted rows are returned via OUTPUT clause for confirmation
- No UPDATE path exists - if an employee changes their name or email in Azure AD, the table retains the original values

**Diagram**:
```
Azure AD --> [UserTableType TVP] --> SyncUsersFromAzure
                                         |
                                    LEFT JOIN existing
                                         |
                                  INSERT new users only
                                         |
                                    OUTPUT inserted rows
```

### 2.2 Manager Identity Resolution

**What**: When displaying affiliate profiles, the system resolves the account manager's human-readable name and email by joining AffiliatesGroups.ManagerUserID to Users.UserObjectID.

**Columns/Parameters Involved**: `UserObjectID`, `FirstName`, `LastName`, `Email`

**Rules**:
- AffiliatesGroups.ManagerUserID stores a GUID referencing Users.UserObjectID
- Multiple procedures (GetAffiliateById, GetAffiliateByAzureObjectId, Affiliate.GetAffiliates) use LEFT JOIN to resolve the manager identity
- The LEFT JOIN means affiliates in groups with no assigned manager (NULL ManagerUserID) still return results
- The resolved FirstName/LastName/Email appear in the affiliate profile response as the group's account manager contact

---

## 3. Data Overview

| UserObjectID | FirstName | LastName | Email | Meaning |
|---|---|---|---|---|
| 3291C5CF-... | Adi | Rosha | adiro@etoro.com | An eToro employee who can be assigned as account manager for affiliate groups or granted viewer access to group data |
| 627AEEEE-... | Guy | Shahaf | guysh@etoro.com | Same role - all 18 users are internal eToro staff with @etoro.com emails, indicating this table exclusively holds employee accounts |
| 5BF5F160-... | Davit | Javakhishvili | davitja@etoro.com | International team member - the user pool spans multiple geographies (Israel, Georgia) reflecting the distributed affiliate management team |
| 72A7562A-... | Giorgi | Chkuaseli | giorgichk@etoro.com | Another Georgia-based team member - naming patterns show email format is first name + last name initials @etoro.com |
| B94C9D18-... | Yafit | Avichzer | yafitav@etoro.com | Standard employee record - table contains only 18 rows total, confirming this is a small admin user pool, not a customer-facing table |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserObjectID | uniqueidentifier | NO | - | VERIFIED | Azure Active Directory Object ID uniquely identifying the employee. This GUID is assigned by Azure AD and used as the primary key. Referenced by `AffiliateAdmin.AffiliatesGroups.ManagerUserID` to designate group account managers, and by `AffiliateAdmin.AffiliateGroups_Viewers.UserObjectID` to grant group data visibility. Also used by `dbo.GetPayments` for UserObjectID-based access control (replacing legacy integer UserIDs from `dbo.tblaff_User`). |
| 2 | FirstName | nvarchar(100) MASKED | NO | - | CODE-BACKED | Employee's first name as synced from Azure AD. Dynamic data masking applied (`default()` function) for PII protection - unprivileged database users see masked values. Used in `AffiliateAdmin.GetUsers` to populate admin UI dropdowns and in affiliate profile responses (GetAffiliateById, GetAffiliateByAzureObjectId) as the account manager's display name. Not updated after initial sync - retains the value from the first Azure AD synchronization. |
| 3 | LastName | nvarchar(100) MASKED | NO | - | CODE-BACKED | Employee's last name as synced from Azure AD. Dynamic data masking applied (`default()` function) for PII protection. Combined with FirstName for account manager display in affiliate profiles. Returned by `AffiliateAdmin.GetUsers` for admin UI population. Not updated after initial sync. |
| 4 | Email | nvarchar(250) MASKED | NO | - | CODE-BACKED | Employee's corporate email address as synced from Azure AD. Dynamic data masking applied (`default()` function) for PII protection. All current values follow the pattern `{name}@etoro.com`. Used by `dbo.GetPayments` to map legacy `dbo.tblaff_User.EmailAddress` to this table's UserObjectID via case-insensitive, trimmed email matching: `TRIM(LOWER(U.EmailAddress)) = TRIM(LOWER(AU.Email))`. Also displayed as the account manager's contact email in affiliate profile responses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a leaf table with no foreign keys or implicit lookups.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateAdmin.AffiliatesGroups | ManagerUserID | Implicit FK | Links an affiliate group to its assigned account manager. Used in multiple procedures via LEFT JOIN to resolve manager name/email for affiliate profile displays. |
| AffiliateAdmin.AffiliateGroups_Viewers | UserObjectID | Implicit FK (composite PK) | Grants a specific user visibility into a specific affiliate group's data. Part of the group-scoped access control system used by dbo.GetPayments to filter payment results. |
| dbo.GetPayments | @UserObjectID | JOIN (via email) | Maps legacy integer UserIDs to UserObjectID by matching email addresses between dbo.tblaff_User and this table. Enables the transition from old to new access control. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. It is a leaf table.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.AffiliatesGroups | Table | ManagerUserID references UserObjectID (implicit FK) |
| AffiliateAdmin.AffiliateGroups_Viewers | Table | UserObjectID references UserObjectID (implicit FK, composite PK member) |
| AffiliateAdmin.SyncUsersFromAzure | Stored Procedure | WRITER - inserts new users from Azure AD sync |
| AffiliateAdmin.GetUsers | Stored Procedure | READER - returns user list for admin UI |
| AffiliateAdmin.GetAffiliateGroups | Stored Procedure | READER - joins to resolve user names (currently commented out in code) |
| dbo.GetAffiliateById | Stored Procedure | READER - LEFT JOINs via AffiliatesGroups.ManagerUserID for manager profile |
| dbo.GetAffiliateByAzureObjectId | Stored Procedure | READER - LEFT JOINs via AffiliatesGroups.ManagerUserID for manager profile |
| dbo.GetPayments | Stored Procedure | READER - joins via email matching for UserObjectID-based access control |
| Affiliate.GetAffiliates | Stored Procedure | READER - JOINs via AffiliatesGroups.ManagerUserID for manager display |
| AffiliateAdmin.UserTableType | User Defined Type | TVP with identical column structure, used as parameter to SyncUsersFromAzure |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AffiliateAdmin.Users | CLUSTERED | UserObjectID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_AffiliateAdmin.Users | PRIMARY KEY | Enforces uniqueness on UserObjectID - each Azure AD user can appear only once |

**Dynamic Data Masking**: All PII columns (FirstName, LastName, Email) use `MASKED WITH (FUNCTION = 'default()')`. Unprivileged database users see masked values; only users with UNMASK permission see actual data. This protects employee PII at the database layer.

---

## 8. Sample Queries

### 8.1 List all admin users with their details
```sql
SELECT UserObjectID, FirstName, LastName, Email
FROM AffiliateAdmin.Users WITH (NOLOCK)
ORDER BY LastName, FirstName
```

### 8.2 Find which affiliate groups a specific user manages
```sql
SELECT ag.AffiliatesGroupsID, ag.AffiliatesGroupsName, u.FirstName, u.LastName, u.Email
FROM AffiliateAdmin.AffiliatesGroups ag WITH (NOLOCK)
JOIN AffiliateAdmin.Users u WITH (NOLOCK) ON u.UserObjectID = ag.ManagerUserID
ORDER BY ag.AffiliatesGroupsName
```

### 8.3 Find which affiliate groups a user has viewer access to
```sql
SELECT u.FirstName, u.LastName, ag.AffiliatesGroupsName
FROM AffiliateAdmin.AffiliateGroups_Viewers agv WITH (NOLOCK)
JOIN AffiliateAdmin.Users u WITH (NOLOCK) ON u.UserObjectID = agv.UserObjectID
JOIN AffiliateAdmin.AffiliatesGroups ag WITH (NOLOCK) ON ag.AffiliatesGroupsID = agv.AffiliatesGroupsID
ORDER BY u.LastName, ag.AffiliatesGroupsName
```

---

## 9. Atlassian Knowledge Sources

No dedicated Atlassian page found for AffiliateAdmin.Users. Peripheral mentions found in:

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Pay Affiliates API | Confluence | Confirms AffiliateAdmin.Users is part of the affiliate payment access control system |
| Payments API - Pending Database Migrations | Confluence | References the PART-5531 migration that integrated AffiliateAdmin.Users into dbo.GetPayments for UserObjectID-based access control |

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.7/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 6 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.Users | Type: Table | Source: fiktivo/AffiliateAdmin/Tables/AffiliateAdmin.Users.sql*
