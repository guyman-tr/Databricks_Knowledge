# dbo.GetPayments

> Returns payment history records using dynamic SQL with optional filters for eCost history, group code, date range, status bitmask, and user/affiliate scope; includes affiliate-group-based access control and was updated in 2026 to use the AffiliateAdmin schema for group management.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Geri Reshef (2018-07-12); updated by Gil Haba (2026-02-08) |
| **Created** | 2018-07-12 |

---

## 1. Business Meaning

The payment management screen in the affiliate admin portal must display payment records filtered by a combination of criteria that varies significantly by user role, date range, and payment status. To handle the many optional filter combinations efficiently, this procedure constructs a dynamic SQL string at runtime, appending only the clauses that correspond to non-NULL input parameters.

A critical security feature is the affiliate-group access control: if the requesting user is not a member of affiliate group 1 (the "all affiliates" viewer group), the result is restricted to only the affiliates assigned to groups that the user is permitted to view. This is enforced via the #Aff temporary table pattern.

A special case handles the "empty GUID" (@GroupCode = all-zeros GUID): this triggers a shortcut query that returns all grouped payments for the current period, bypassing the normal filter logic.

The 2026 update (PART-5531) migrated affiliate group membership lookups from the legacy dbo.tblaff_AffiliateGroups_Viewers and dbo.tblaff_AffiliatesGroups tables to the new AffiliateAdmin schema tables, and also switched from UserID-based to UserObjectID-based identification.

---

## 2. Business Logic

### 2.1 UserID to UserObjectID Mapping

**What**: Maps the legacy integer UserID to the new UUID-based UserObjectID in AffiliateAdmin.Users.

**Columns/Parameters Involved**: `@UserId`, `@UserObjectID`, `dbo.tblaff_User`, `AffiliateAdmin.Users`

**Rules**:
- If @UserId is non-NULL and no matching UserObjectID is found, a RAISERROR is raised (severity 16) and execution stops
- If @UserId is NULL, @UserObjectID remains NULL and the user-scoping logic is skipped

### 2.2 Affiliate Group Access Control

**What**: Restricts results to affiliates whose group the requesting user is authorised to view.

**Columns/Parameters Involved**: `@filterByAffiliateGroup`, `#Aff`, `AffiliateAdmin.AffiliatesGroups`, `AffiliateAdmin.AffiliateGroups_Viewers`

**Rules**:
- If the user is in AffiliatesGroupsID = 1 (the global viewer group), @filterByAffiliateGroup = FALSE and no restriction is applied
- Otherwise, the #Aff temp table is populated with the AffiliateIDs the user can see, and an EXISTS filter is added to the dynamic SQL

### 2.3 Empty GUID Shortcut

**What**: When @GroupCode equals the all-zeros GUID, returns all non-empty group codes that are not in PaymentRowStatusID = 8 or are recently approved.

**Rules**:
- This path bypasses all other filters and returns immediately
- Used to list all current payment groups for batch review

### 2.4 Dynamic SQL Filter Construction

**What**: Builds a WHERE clause by appending predicates for each non-NULL parameter.

**Columns/Parameters Involved**: `@ECostHistoryID`, `@GroupCode`, `@FromPeriod`, `@ToPeriod`, `@Status`, `@AffiliateId`

**Rules**:
- IIF() expressions append each predicate only when the parameter is non-NULL
- @Status uses bitmask logic: (PaymentRowStatusID & @Status) = PaymentRowStatusID; additionally, PaymentRowStatusID = 8 with a recent ApprovalDate is always included
- ORDER BY PaymentPeriod ASC is always applied
- tblaff_Administrative4 (WHERE ID=1) is used as an administrative guard; the payment query requires this sentinel row to exist

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @ECostHistoryID | IN | int | NULL | Filters results to payments linked to this eCostHistoryID. |
| 2 | @GroupCode | IN | uniqueidentifier | NULL | Filters results to payments in this payment group. All-zeros GUID triggers the shortcut mode returning all non-empty group codes. |
| 3 | @FromPeriod | IN | datetime | NULL | Filters results to payments with PaymentPeriod >= this date. |
| 4 | @ToPeriod | IN | datetime | NULL | Filters results to payments with PaymentPeriod <= this date. |
| 5 | @Status | IN | int | NULL | Bitmask filter on PaymentRowStatusID. Returns rows where (PaymentRowStatusID & @Status) = PaymentRowStatusID, plus status-8 rows within the current period. |
| 6 | @UserId | IN | int | NULL | The legacy UserID of the requesting user; used to determine affiliate-group access scope. If provided, must map to a UserObjectID in AffiliateAdmin.Users. |
| 7 | @AffiliateId | IN | int | NULL | Filters results to payments for this specific affiliate. |

---

## 5. Relationships

### 5.1 Tables Written

| Table | Operation | Notes |
|-------|-----------|-------|
| #Aff (temp table) | CREATE / INSERT / DROP | Temporary table holding affiliate IDs accessible to the requesting user; used in the dynamic SQL EXISTS filter |

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_PaymentHistory | SELECT (dynamic) | Primary source of payment records |
| dbo.tblaff_Administrative4 | SELECT (dynamic EXISTS) | Administrative sentinel; must have a row with ID=1 |
| dbo.tblaff_User | SELECT | Maps @UserId to email for UserObjectID lookup |
| AffiliateAdmin.Users | SELECT (JOIN) | Provides UserObjectID for the requesting user |
| AffiliateAdmin.AffiliateGroups_Viewers | SELECT | Determines whether user is in global viewer group; populates #Aff |
| AffiliateAdmin.AffiliatesGroups | SELECT (JOIN) | Links affiliate groups to viewer permissions |
| dbo.tblaff_Affiliates | SELECT (JOIN) | Used when populating #Aff to get AffiliateID from group membership |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetPayments (stored procedure)
+-- dbo.tblaff_PaymentHistory (table) [dynamic SELECT]
+-- dbo.tblaff_Administrative4 (table) [sentinel EXISTS]
+-- dbo.tblaff_User (table) [UserID lookup]
+-- AffiliateAdmin.Users (table) [UserObjectID resolution]
+-- AffiliateAdmin.AffiliateGroups_Viewers (table) [access control]
+-- AffiliateAdmin.AffiliatesGroups (table) [group membership]
+-- dbo.tblaff_Affiliates (table) [AffiliateID resolution for #Aff]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_PaymentHistory | Table | Primary payment data source |
| dbo.tblaff_Administrative4 | Table | Administrative sentinel guard |
| dbo.tblaff_User | Table | Legacy user table for UserID-to-email mapping |
| AffiliateAdmin.Users | Table | New user table for UserObjectID resolution |
| AffiliateAdmin.AffiliateGroups_Viewers | Table | Affiliate group viewer access control |
| AffiliateAdmin.AffiliatesGroups | Table | Affiliate group definitions |
| dbo.tblaff_Affiliates | Table | Affiliate records for group-scoped access |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment management screen (admin portal) | Application | Calls this procedure with various filter combinations to display payment lists |
| Payment batch export | Application | Calls with @GroupCode to retrieve a specific payment batch |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- Uses dynamic SQL via EXEC(@SQL); the SQL string is also PRINTed for debugging
- Bitmask status logic: (PaymentRowStatusID & @Status) = PaymentRowStatusID; status 8 rows within the current period are always included regardless of @Status
- CurrentPeriodStartDate logic: if the current day of month is <= 7, the previous month start is used; otherwise the current month start is used
- PART-5531 (2026-02-08, Gil Haba): migrated affiliate group lookups from legacy dbo tables to AffiliateAdmin schema; switched from UserID to UserObjectID
- Jira context: ticket 52162 (2018-07-12, Geri Reshef): original creation to improve GetPayments performance using dynamic SQL

---

## 8. Sample Queries

### 8.1 Return all payments (no filters, admin user in global group)

```sql
EXEC dbo.GetPayments;
```

### 8.2 Filter by affiliate and date range

```sql
EXEC dbo.GetPayments
    @AffiliateId = 1001,
    @FromPeriod  = '2025-01-01',
    @ToPeriod    = '2025-03-31';
```

### 8.3 Filter by status bitmask (approved = status bit 4)

```sql
EXEC dbo.GetPayments
    @Status = 4;
```

### 8.4 Retrieve all grouped payments (empty GUID shortcut)

```sql
EXEC dbo.GetPayments
    @GroupCode = '00000000-0000-0000-0000-000000000000';
```

---

## 9. Atlassian Knowledge Sources

- Ticket 52162 (2018-07-12, Geri Reshef): "Improve GetPayments performance in fiktivo by creating a dynamic code" -- original creation using dynamic SQL.
- PART-5531 (2026-02-08, Gil Haba): Migrated affiliate group management to new AffiliateAdmin schema (AffiliatesGroups, AffiliateGroups_Viewers) and switched from UserID to UserObjectID.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10*
*Object: dbo.GetPayments | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetPayments.sql*
