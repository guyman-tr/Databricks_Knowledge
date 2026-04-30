# AffiliateAdmin.UserTableType

> Table-valued parameter type used to pass batches of Azure AD user records into the AffiliateAdmin schema for synchronization.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | UserObjectID (uniqueidentifier) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

UserTableType is a table-valued parameter type that serves as the data transport mechanism for synchronizing user accounts from Azure Active Directory into the AffiliateAdmin system. It defines the minimal user profile structure needed for the affiliate admin portal: a unique Azure AD object identifier and the user's name and email.

This type exists because the SyncUsersFromAzure stored procedure needs to receive multiple user records in a single call, rather than making individual insert calls per user. This batch approach is essential for the periodic Azure AD sync process that keeps the affiliate admin user list in sync with the organization's identity provider.

Data flows through this type when the application calls AffiliateAdmin.SyncUsersFromAzure with a populated UserTableType parameter. The procedure uses the type to merge new users into AffiliateAdmin.Users, inserting only users whose UserObjectID does not already exist.

---

## 2. Business Logic

### 2.1 Binary Collation for Case-Sensitive Matching

**What**: All string columns use Latin1_General_BIN collation instead of the default database collation.

**Columns/Parameters Involved**: `FirstName`, `LastName`, `Email`

**Rules**:
- Binary collation ensures exact byte-level comparison during the sync merge
- This prevents duplicate insertions where names differ only by case (e.g., "John" vs "john")
- Matches Azure AD's case-sensitive identifier behavior

---

## 3. Data Overview

N/A for User Defined Type. This is a parameter type - it holds transient data during procedure execution, not persisted rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | UserObjectID | uniqueidentifier | NO | - | CODE-BACKED | Azure Active Directory Object ID for the user. Serves as the unique identity key for matching existing users in AffiliateAdmin.Users during sync. This is the GUID assigned by Azure AD, not a locally-generated identifier. |
| 2 | FirstName | nvarchar(100) | NO | - | CODE-BACKED | User's first name as stored in Azure AD. Uses Latin1_General_BIN collation for exact matching. Inserted into AffiliateAdmin.Users.FirstName during sync. |
| 3 | LastName | nvarchar(100) | NO | - | CODE-BACKED | User's last name as stored in Azure AD. Uses Latin1_General_BIN collation for exact matching. Inserted into AffiliateAdmin.Users.LastName during sync. |
| 4 | Email | nvarchar(250) | NO | - | CODE-BACKED | User's email address from Azure AD. Uses Latin1_General_BIN collation for exact matching. Inserted into AffiliateAdmin.Users.Email during sync. Used elsewhere in the system as the primary user identifier for audit logging (@UserEmail parameter across many SPs). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. It is a standalone type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AffiliateAdmin.SyncUsersFromAzure | @Users parameter | Parameter Type | Accepts a batch of Azure AD users for insertion into AffiliateAdmin.Users |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.SyncUsersFromAzure | Stored Procedure | Uses as READONLY parameter type for batch user sync |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None. The type enforces NOT NULL on all four columns but has no CHECK, DEFAULT, or UNIQUE constraints.

---

## 8. Sample Queries

### 8.1 Declare and populate for sync call
```sql
DECLARE @Users AffiliateAdmin.UserTableType;
INSERT INTO @Users (UserObjectID, FirstName, LastName, Email)
VALUES
    ('A1B2C3D4-E5F6-7890-ABCD-EF1234567890', 'Jane', 'Smith', 'jane.smith@company.com'),
    ('B2C3D4E5-F6A7-8901-BCDE-F12345678901', 'John', 'Doe', 'john.doe@company.com');

EXEC AffiliateAdmin.SyncUsersFromAzure @Users = @Users;
```

### 8.2 Check which users from a batch already exist
```sql
DECLARE @Users AffiliateAdmin.UserTableType;
-- (populate @Users)

SELECT u1.UserObjectID, u1.FirstName, u1.LastName, u1.Email,
       CASE WHEN u2.UserObjectID IS NOT NULL THEN 'Already exists' ELSE 'New' END AS SyncStatus
FROM @Users AS u1
LEFT JOIN AffiliateAdmin.Users AS u2 WITH (NOLOCK) ON u1.UserObjectID = u2.UserObjectID;
```

### 8.3 Validate email format before sync
```sql
DECLARE @Users AffiliateAdmin.UserTableType;
-- (populate @Users)

SELECT UserObjectID, Email
FROM @Users
WHERE Email NOT LIKE '%_@_%.__%';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.UserTableType | Type: User Defined Type | Source: fiktivo/AffiliateAdmin/User Defined Types/AffiliateAdmin.UserTableType.sql*
