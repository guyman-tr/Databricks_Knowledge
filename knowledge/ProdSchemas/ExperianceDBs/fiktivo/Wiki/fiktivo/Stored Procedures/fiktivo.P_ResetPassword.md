# fiktivo.P_ResetPassword

> Resets an affiliate's login password after validating the old password and checking that the affiliate is flagged for password reset.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | RETURN code (0=success, 13001-13004=error) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure handles the forced password reset flow for affiliates. When an affiliate's account has NeedsResetPassword=1, they must change their password at next login. The procedure validates the old password, ensures the new password differs from the old one, confirms the new password matches the confirmation, then updates the password and clears the reset flag.

Created by Robert (10/04/2016), ticket 35924. Updated by Ran Ovadia (18/12/2019) to increase @UserNameOrEmail to 50 characters.

---

## 2. Business Logic

### 2.1 Password Reset Validation Chain

**What**: Multi-step validation before allowing password reset.

**Columns/Parameters Involved**: `@UserNameOrEmail`, `@OldPassword`, `@NewPassword`, `@ConfirmPassword`

**Rules**:
- Error 13001: User not found OR NeedsResetPassword is not set (not required to reset)
- Error 13002: New password equals old password (must be different)
- Error 13003: New password does not match confirmation
- Error 13004: UPDATE affected 0 rows (old password was wrong)
- Success: Updates LoginPassword and sets NeedsResetPassword=0
- Lookup by LoginName OR Email (supports both for user convenience)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserNameOrEmail (IN) | NVARCHAR(50) | NO | - | CODE-BACKED | Affiliate login name or email address. Matched against both tblaff_Affiliates.LoginName and .Email. |
| 2 | @OldPassword (IN) | NVARCHAR(24) | NO | - | CODE-BACKED | Current password for verification. Must match LoginPassword in the database. |
| 3 | @NewPassword (IN) | NVARCHAR(24) | NO | - | CODE-BACKED | New password to set. Must differ from @OldPassword. Max 24 characters. |
| 4 | @ConfirmPassword (IN) | NVARCHAR(24) | NO | - | CODE-BACKED | Confirmation of new password. Must equal @NewPassword. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (SELECT/UPDATE) | dbo.tblaff_Affiliates | Table read/write | Reads NeedsResetPassword flag, LoginPassword; Updates LoginPassword and NeedsResetPassword. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.P_ResetPassword (procedure)
    └── dbo.tblaff_Affiliates (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table | SELECT for validation, UPDATE for password change |

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

### 8.1 Reset a password
```sql
EXEC fiktivo.P_ResetPassword @UserNameOrEmail = N'affiliate@example.com',
    @OldPassword = N'OldPass123', @NewPassword = N'NewPass456', @ConfirmPassword = N'NewPass456'
```

### 8.2 Find affiliates needing password reset
```sql
SELECT AffiliateID, LoginName, Email, NeedsResetPassword
FROM dbo.tblaff_Affiliates WITH (NOLOCK)
WHERE NeedsResetPassword = 1
```

### 8.3 Check error codes
```sql
-- Error codes: 13001=User not found/not flagged, 13002=Same password, 13003=Confirm mismatch, 13004=Wrong old password
DECLARE @rc INT
EXEC @rc = fiktivo.P_ResetPassword @UserNameOrEmail = N'test', @OldPassword = N'old', @NewPassword = N'new', @ConfirmPassword = N'new'
SELECT @rc AS ReturnCode
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.P_ResetPassword | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.P_ResetPassword.sql*
