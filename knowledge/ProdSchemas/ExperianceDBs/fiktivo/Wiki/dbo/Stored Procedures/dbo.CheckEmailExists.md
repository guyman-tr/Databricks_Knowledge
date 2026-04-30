# dbo.CheckEmailExists

> Checks whether a given email address is already registered to any affiliate account. Returns 1 if the email exists, 0 if it does not, enabling duplicate-email validation during registration.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Ran Ovadia |
| **Created** | 2020-02-26 |

---

## 1. Business Meaning

Each affiliate account in the platform must have a unique email address. Before completing affiliate registration or account creation, the calling application must verify that the supplied email is not already in use. This procedure provides that validation as a single, reusable database call.

The procedure returns a single-row, single-column result: 1 if at least one affiliate row exists with the supplied email, 0 otherwise. The WITH (NOLOCK) hint is used to avoid blocking in high-concurrency registration flows, accepting the small risk of a phantom read in exchange for availability.

This check is called by the affiliate self-registration portal and by admin-side account creation workflows (including dbo.CreateAffiliate) before committing a new affiliate record.

---

## 2. Business Logic

### 2.1 Email Uniqueness Check

**What**: Queries tblaff_Affiliates for any row whose Email matches the supplied value.

**Columns/Parameters Involved**: `@Email`, `tblaff_Affiliates.Email`

**Rules**:
- The match is case-insensitive (SQL Server default collation on the Email column)
- WITH (NOLOCK) is applied; a concurrent INSERT that has not yet committed will not be seen, which may allow a rare race condition where two registrations with the same email succeed simultaneously - the caller or a unique index must handle this edge case
- The procedure returns a scalar result, not an OUTPUT parameter; callers read the first column of the first row
- Soft-deleted or inactive affiliates (AccountStatus != 1) are included in the check; the email is considered taken regardless of account status

### 2.2 Return Value Convention

**What**: Scalar bit result conveying existence.

**Rules**:
- Returns 1 if EXISTS (SELECT 1 FROM tblaff_Affiliates WHERE Email = @Email) is true
- Returns 0 otherwise
- No exception is raised for not-found; 0 is a valid business answer

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @Email | IN | nvarchar(255) | (required) | The email address to check for existence in tblaff_Affiliates. Comparison is case-insensitive per database collation. |

### Return Value

| Column | Type | Description |
|--------|------|-------------|
| (unnamed) | bit | 1 if the email is already registered to at least one affiliate; 0 if not found. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_Affiliates | SELECT EXISTS | Read with NOLOCK hint; checks Email column for a match |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CheckEmailExists (stored procedure)
+-- dbo.tblaff_Affiliates (table) [SELECT WITH NOLOCK]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | Source table for email existence check; uses the Email NC index for efficient lookup |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.CreateAffiliate | Stored Procedure | Calls this procedure to validate email uniqueness before inserting a new affiliate |
| Affiliate registration portal | Application | Calls this procedure during self-registration form validation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- The Email column on tblaff_Affiliates has a dedicated NC index, making this lookup highly efficient (index seek)
- WITH (NOLOCK) is intentional to prevent registration blocking; callers should be aware of the dirty-read trade-off
- No row-level locking or serializable isolation is used; a unique constraint on Email in tblaff_Affiliates is the ultimate safeguard against duplicates

---

## 8. Sample Queries

### 8.1 Check if an email is already registered

```sql
EXEC dbo.CheckEmailExists
    @Email = N'partner@example.com';
-- Returns: 1 (exists) or 0 (not found)
```

### 8.2 Use the result in application logic (T-SQL pattern)

```sql
DECLARE @Exists bit;

EXEC @Exists = dbo.CheckEmailExists
    @Email = N'partner@example.com';

IF @Exists = 1
    RAISERROR('Email address is already registered.', 16, 1);
ELSE
    -- Proceed with registration
    EXEC dbo.CreateAffiliate /* ... parameters ... */;
```

### 8.3 Direct query equivalent (for reference/debugging)

```sql
SELECT CASE WHEN EXISTS (
    SELECT 1
    FROM dbo.tblaff_Affiliates WITH (NOLOCK)
    WHERE Email = N'partner@example.com'
) THEN 1 ELSE 0 END AS EmailExists;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.CheckEmailExists | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.CheckEmailExists.sql*
