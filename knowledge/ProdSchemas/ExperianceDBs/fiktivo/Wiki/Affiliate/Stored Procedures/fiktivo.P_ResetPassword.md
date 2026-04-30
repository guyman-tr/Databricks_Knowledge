# fiktivo.P_ResetPassword

> Resets an affiliate's login password with multi-step validation including identity verification, duplication check, and confirmation matching.

| Property | Value |
|----------|-------|
| **Schema** | fiktivo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Password reset with error-code validation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

P_ResetPassword handles the password reset flow for affiliate portal users. It enforces a controlled reset process: only affiliates who have been flagged as requiring a password reset (NeedsResetPassword = 1) can use this procedure. This prevents unauthorized password changes and ensures resets are initiated through proper channels.

The procedure implements a four-stage validation pipeline before applying the change. First, it verifies the user exists and is flagged for reset. Second, it ensures the new password differs from the old one. Third, it confirms the new password matches the confirmation entry. Finally, it performs the UPDATE and verifies the row was affected. Each failure stage returns a distinct error code, enabling the calling application to display appropriate user-facing messages.

Upon successful reset, the procedure updates both the LoginPassword column and clears the NeedsResetPassword flag (set to 0), preventing the same reset link or session from being used again.

---

## 2. Business Logic

### 2.1 User Existence and Reset Flag Validation

**What**: Ensures the user exists and has been flagged for password reset.

**Columns/Parameters Involved**: `@UserNameOrEmail`, `@OldPassword`

**Rules**:
- Checks that a record exists in dbo.tblaff_Affiliates matching @UserNameOrEmail with NeedsResetPassword = 1
- If not found or not flagged, returns error code 13001

### 2.2 Password Uniqueness Check

**What**: Prevents setting the same password again.

**Columns/Parameters Involved**: `@OldPassword`, `@NewPassword`

**Rules**:
- Compares @NewPassword against @OldPassword
- If they are identical, returns error code 13002

### 2.3 Confirmation Match

**What**: Ensures the user typed the new password correctly twice.

**Columns/Parameters Involved**: `@NewPassword`, `@ConfirmPassword`

**Rules**:
- Compares @NewPassword to @ConfirmPassword
- If they do not match, returns error code 13003

### 2.4 Password Update

**What**: Applies the new password and clears the reset flag.

**Columns/Parameters Involved**: `@UserNameOrEmail`, `@NewPassword`

**Rules**:
- UPDATEs dbo.tblaff_Affiliates SET LoginPassword = @NewPassword, NeedsResetPassword = 0
- If @@ROWCOUNT = 0 after the UPDATE (no rows affected), returns error code 13004

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @UserNameOrEmail | NVARCHAR(50) (IN) | NO | - | CODE-BACKED | The affiliate's username or email address used to locate the account in tblaff_Affiliates. |
| 2 | @OldPassword | NVARCHAR(24) (IN) | NO | - | CODE-BACKED | The current password for validation. Used to ensure the new password is different from the existing one. |
| 3 | @NewPassword | NVARCHAR(24) (IN) | NO | - | CODE-BACKED | The desired new password. Must differ from @OldPassword and match @ConfirmPassword. |
| 4 | @ConfirmPassword | NVARCHAR(24) (IN) | NO | - | CODE-BACKED | Confirmation entry of the new password. Must exactly match @NewPassword to prevent typos. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @UserNameOrEmail | dbo.tblaff_Affiliates | SELECT / UPDATE | Reads to validate user and reset flag, updates LoginPassword and NeedsResetPassword |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
fiktivo.P_ResetPassword (procedure)
└── dbo.tblaff_Affiliates (table, cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_Affiliates | Table (cross-schema) | SELECT to validate user/reset flag, UPDATE to set new password and clear NeedsResetPassword |

### 6.2 Objects That Depend On This

No dependents found in the fiktivo schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Reset a password for a flagged affiliate
```sql
EXEC fiktivo.P_ResetPassword
    @UserNameOrEmail = 'affiliate@example.com',
    @OldPassword = 'OldPass123',
    @NewPassword = 'NewPass456',
    @ConfirmPassword = 'NewPass456'
```

### 8.2 Check which affiliates are flagged for password reset
```sql
SELECT AffiliateID, LoginName, Email, NeedsResetPassword
FROM dbo.tblaff_Affiliates WITH (NOLOCK)
WHERE NeedsResetPassword = 1
```

### 8.3 Audit affiliates who have completed password resets
```sql
SELECT AffiliateID, LoginName, Email, NeedsResetPassword
FROM dbo.tblaff_Affiliates WITH (NOLOCK)
WHERE NeedsResetPassword = 0
ORDER BY AffiliateID DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 6.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: fiktivo.P_ResetPassword | Type: Stored Procedure | Source: fiktivo/fiktivo/Stored Procedures/fiktivo.P_ResetPassword.sql*
