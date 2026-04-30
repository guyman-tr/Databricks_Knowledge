# AffiliateAdmin.SyncUsersFromAzure

> Synchronizes Azure AD users into the AffiliateAdmin.Users table using an insert-only pattern, returning newly added user records via OUTPUT clause.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | OUTPUT of newly inserted user rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** SyncUsersFromAzure imports user records from Azure Active Directory into the `AffiliateAdmin.Users` table. It accepts a table-valued parameter of type `AffiliateAdmin.UserTableType` containing the Azure AD user data and inserts only users that do not already exist in the local table. The OUTPUT clause returns the newly inserted rows to the caller.

**WHY:** The affiliate administration system needs to maintain a local copy of Azure AD users who have access to the platform. This synchronization enables Azure AD as the identity provider while maintaining a local user table for application-level features like group viewer assignments, audit log attribution, and access control. The insert-only design ensures that existing local user records (which may have been enriched with application-specific data) are never overwritten by the sync process.

**HOW:** The procedure uses a LEFT JOIN anti-pattern to identify which users in the @Users input do not yet exist in `AffiliateAdmin.Users`. It performs an INSERT...SELECT with an OUTPUT clause that returns the inserted rows to the caller. Users already present in the local table are skipped entirely -- no updates are performed. This makes the sync idempotent and safe to run repeatedly.

---

## 2. Business Logic

### 2.1 Insert-Only Pattern
The procedure only INSERTs new users. Existing users in `AffiliateAdmin.Users` are never updated, even if their Azure AD attributes have changed. This design choice preserves any local modifications or enrichments to user records.

### 2.2 LEFT JOIN Anti-Pattern
New users are identified using a LEFT JOIN from the @Users TVP to `AffiliateAdmin.Users` where the existing row is NULL. This is a standard SQL anti-join pattern for finding records that exist in one set but not another.

### 2.3 OUTPUT Clause
The INSERT statement includes an OUTPUT clause that returns the inserted rows. This allows the calling application to immediately know which users were newly added during this sync cycle, enabling follow-up actions like sending welcome notifications or assigning default permissions.

### 2.4 No Audit Logging
This procedure does not perform explicit audit logging. User sync events may be tracked at the application layer or through Azure AD sync logs.

### 2.5 Idempotent Execution
Because only new users are inserted, the procedure is fully idempotent. Running it multiple times with the same input produces the same final state, with subsequent executions returning empty result sets (no new users to insert).

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Users | AffiliateAdmin.UserTableType READONLY | No | - | CODE-BACKED | Table-valued parameter containing Azure AD user records to sync |

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `AffiliateAdmin.Users` | Table | INSERT new users not already present |
| `AffiliateAdmin.UserTableType` | User-Defined Table Type | Input parameter type for user data |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Azure AD sync service | Application | Periodic user synchronization job |
| User management module | Application | On-demand user import |

---

## 6. Dependencies

### 6.0 Chain
`SyncUsersFromAzure` -> LEFT JOIN `AffiliateAdmin.Users` (find new) -> INSERT `AffiliateAdmin.Users` (OUTPUT inserted)

### 6.1 Depends On
- `AffiliateAdmin.Users` - Target table for user storage
- `AffiliateAdmin.UserTableType` - User-defined table type defining the structure of Azure AD user input

### 6.2 Depend On This
No known database dependencies. Called from Azure AD synchronization service in the application layer.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Sync a batch of Azure AD users
DECLARE @AzureUsers AffiliateAdmin.UserTableType;
INSERT INTO @AzureUsers (UserID, Email, DisplayName)
VALUES
    (NEWID(), N'alice@company.com', N'Alice Johnson'),
    (NEWID(), N'bob@company.com', N'Bob Smith');
EXEC AffiliateAdmin.SyncUsersFromAzure
    @Users = @AzureUsers;
-- Returns: Only newly inserted user rows via OUTPUT
```

```sql
-- 2. Sync single user and capture result
DECLARE @AzureUsers AffiliateAdmin.UserTableType;
INSERT INTO @AzureUsers (UserID, Email, DisplayName)
VALUES (NEWID(), N'charlie@company.com', N'Charlie Brown');
EXEC AffiliateAdmin.SyncUsersFromAzure
    @Users = @AzureUsers;
```

```sql
-- 3. Verify sync by checking user count before and after
SELECT COUNT(*) AS BeforeCount FROM AffiliateAdmin.Users;
DECLARE @AzureUsers AffiliateAdmin.UserTableType;
INSERT INTO @AzureUsers (UserID, Email, DisplayName)
VALUES
    (NEWID(), N'new.user1@company.com', N'New User 1'),
    (NEWID(), N'new.user2@company.com', N'New User 2');
EXEC AffiliateAdmin.SyncUsersFromAzure @Users = @AzureUsers;
SELECT COUNT(*) AS AfterCount FROM AffiliateAdmin.Users;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4500.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.SyncUsersFromAzure | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.SyncUsersFromAzure.sql*
