# dbo.GetUserById_NogaJunk0226

## 1. Overview

Retrieves a full user record from `tblaff_User`, including all permission flags and role columns, joined to the affiliate group that the user manages. Used to load a user profile with its complete permission set for display or authorization checks in the affiliate management application.

> **Deprecated / Developer Backup:** The `NogaJunk0226` suffix indicates this is a developer backup snapshot created on 2026-02-26. It should not be used in production code. Refer to the current production equivalent procedure for active use.

## 2. Classification

| Property | Value |
|---|---|
| Schema | dbo |
| Type | Stored Procedure |
| Database | fiktivo |
| Primary Table | dbo.tblaff_User |
| Secondary Tables | dbo.tblaff_AffiliatesGroups |
| Operation | SELECT |
| Transaction | No |

## 3. Return / Result Set

N/A for stored procedure.

Returns a single result set with one row per user matching `@Id`. Columns include all fields from `tblaff_User` (UserID, Name, EmailAddress, LoginName, LoginPassword, ~80 permission bit flags, role columns such as AffiliateManager, ChiefMarketingOfficer, AccountingManager, MarketingManager, OperationsManager, FinanceManager, IsSystemAdministrator, IsDeleted, EncryptedLoginPassword, ChangedPasswordDate) plus `AffiliatesGroupsID` and `AffiliatesGroupsName` from the joined `tblaff_AffiliatesGroups` row for the group the user manages (if any).

## 4. Parameters

| Parameter | Direction | Type | Default | Description |
|---|---|---|---|---|
| @Id | IN | INT | required | UserID of the user to retrieve. |

## 5. Business Logic

1. Queries `tblaff_User WITH (NOLOCK)` for the row where `UserID = @Id`.
2. LEFT JOINs `tblaff_AffiliatesGroups WITH (NOLOCK)` on `ManagerUserID = UserID` to attach the group managed by this user, if any.
3. Returns all user columns including the full set of permission flags across every functional module (AffiliateTypes, Affiliates, Categories, Banners, Sales, Leads, Reports, Tools, Preferences, Announcements, Countries, Languages, Brands, CopyTraders, Audits, Pixels, eCost, Registrations, Chargebacks, Deposits, Bonuses).
4. `SET NOCOUNT ON` suppresses row-count messages.
5. No filtering beyond the primary key lookup; the result is either one row or empty.

## 6. Dependencies

| Object | Type | Schema | Purpose |
|---|---|---|---|
| tblaff_User | Table | dbo | Source of user data and all permission flags |
| tblaff_AffiliatesGroups | Table | dbo | Provides group name/ID for the group managed by the user |

## 7. Indexes and Performance

### 7.1 Recommendations

N/A for stored procedure.

### 7.2 Notes

- Both tables are queried with `NOLOCK`, avoiding shared-lock contention on busy user tables.
- The query is a simple primary-key point lookup on `UserID`; the clustered index on `tblaff_User.UserID` ensures efficient retrieval.
- The LEFT JOIN on `ManagerUserID` benefits from an index on `tblaff_AffiliatesGroups.ManagerUserID` if available.

## 8. Usage Examples

```sql
-- Retrieve the full profile for user ID 42
EXEC dbo.GetUserById_NogaJunk0226 @Id = 42;
```

## 9. Change History

| Date | Author | Jira / Note | Description |
|---|---|---|---|
| 2026-02-26 | Noga | N/A | Developer backup snapshot created (NogaJunk0226). Do not use in production. |

---
*Object: dbo.GetUserById_NogaJunk0226 | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetUserById_NogaJunk0226.sql*
