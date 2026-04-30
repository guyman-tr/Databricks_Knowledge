# dbo.GetPayments_New_NogaJunk0226

> DEPRECATED / DEVELOPER BACKUP. An older version of the GetPayments payment retrieval logic retained as a developer backup; uses the legacy dbo.tblaff_AffiliateGroups_Viewers and dbo.tblaff_AffiliatesGroups tables and UserID-based access control instead of the current AffiliateAdmin schema and UserObjectID pattern.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Unknown (Noga backup, February 2026) |
| **Created** | ~February 2026 (backup copy) |

---

## 1. Business Meaning

This procedure is a developer backup copy of the GetPayments logic as it existed before the PART-5531 migration (February 2026) that moved affiliate group management to the AffiliateAdmin schema and replaced UserID-based access control with UserObjectID.

The name suffix "NogaJunk0226" follows the naming convention used in this codebase for developer holding/backup procedures. This procedure is not intended for use by the application and should be treated as a historical reference only.

The business logic is identical in structure to dbo.GetPayments: it retrieves payment history records with optional filters (eCost history, group code, period range, status bitmask, user scope, affiliate scope) using dynamic SQL. The key differences from the current production procedure are:

- Uses dbo.tblaff_AffiliateGroups_Viewers and dbo.tblaff_AffiliatesGroups (legacy tables) instead of AffiliateAdmin.AffiliateGroups_Viewers and AffiliateAdmin.AffiliatesGroups
- Uses @UserId (integer) directly for access control instead of mapping to @UserObjectID (uniqueidentifier)
- Does not include the UserID-to-UserObjectID mapping and the RAISERROR guard present in the production procedure

---

## 2. Business Logic

### 2.1 Legacy Affiliate Group Access Control

**What**: Restricts results to affiliates in groups the requesting user can view, using legacy dbo tables.

**Columns/Parameters Involved**: `@UserId`, `@filterByAffiliateGroup`, `dbo.tblaff_AffiliateGroups_Viewers`, `dbo.tblaff_AffiliatesGroups`

**Rules**:
- Checks directly against dbo.tblaff_AffiliateGroups_Viewers using integer UserID
- If the user is not in AffiliatesGroupsID = 1 (global viewer group), #Aff is populated with accessible affiliate IDs
- No UserObjectID mapping; the legacy integer UserID is used throughout

### 2.2 Empty GUID Shortcut

**What**: When @GroupCode equals the all-zeros GUID, returns all grouped payments for the current period.

**Rules**:
- Same logic as dbo.GetPayments; see that procedure's documentation for details

### 2.3 Dynamic SQL Filter Construction

**What**: Builds the WHERE clause dynamically; same filter logic as dbo.GetPayments.

**Rules**:
- Same IIF()-based dynamic predicate pattern as dbo.GetPayments
- Same bitmask status logic
- Same tblaff_Administrative4 sentinel guard

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @ECostHistoryID | IN | int | NULL | Filters results to payments linked to this eCostHistoryID. |
| 2 | @GroupCode | IN | uniqueidentifier | NULL | Filters to a specific payment group. All-zeros GUID triggers the shortcut mode. |
| 3 | @FromPeriod | IN | datetime | NULL | Lower bound on PaymentPeriod. |
| 4 | @ToPeriod | IN | datetime | NULL | Upper bound on PaymentPeriod. |
| 5 | @Status | IN | int | NULL | Bitmask filter on PaymentRowStatusID. |
| 6 | @UserId | IN | int | NULL | Legacy integer UserID for affiliate-group access control. Used directly against dbo.tblaff_AffiliateGroups_Viewers. |
| 7 | @AffiliateId | IN | int | NULL | Filters to a specific affiliate. |

---

## 5. Relationships

### 5.1 Tables Written

| Table | Operation | Notes |
|-------|-----------|-------|
| #Aff (temp table) | CREATE / INSERT / DROP | Temporary holding table for accessible affiliate IDs |

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| dbo.tblaff_PaymentHistory | SELECT (dynamic) | Primary payment data source |
| dbo.tblaff_Administrative4 | SELECT (dynamic EXISTS) | Administrative sentinel |
| dbo.tblaff_AffiliateGroups_Viewers | SELECT | Legacy affiliate group viewer table (replaced by AffiliateAdmin.AffiliateGroups_Viewers in production) |
| dbo.tblaff_AffiliatesGroups | SELECT (JOIN) | Legacy affiliate group table (replaced by AffiliateAdmin.AffiliatesGroups in production) |
| dbo.tblaff_Affiliates | SELECT (JOIN) | Used when populating #Aff |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetPayments_New_NogaJunk0226 (stored procedure) [DEPRECATED]
+-- dbo.tblaff_PaymentHistory (table) [dynamic SELECT]
+-- dbo.tblaff_Administrative4 (table) [sentinel EXISTS]
+-- dbo.tblaff_AffiliateGroups_Viewers (table) [legacy access control]
+-- dbo.tblaff_AffiliatesGroups (table) [legacy group table]
+-- dbo.tblaff_Affiliates (table) [AffiliateID resolution]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.tblaff_PaymentHistory | Table | Primary payment data |
| dbo.tblaff_Administrative4 | Table | Sentinel guard |
| dbo.tblaff_AffiliateGroups_Viewers | Table | Legacy access control (deprecated) |
| dbo.tblaff_AffiliatesGroups | Table | Legacy group definitions (deprecated) |
| dbo.tblaff_Affiliates | Table | Affiliate records |

### 6.2 Objects That Depend On This

None. This procedure is a deprecated developer backup and is not called by any production workflow.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- This procedure uses dbo.tblaff_AffiliateGroups_Viewers and dbo.tblaff_AffiliatesGroups; the production version (dbo.GetPayments) has migrated to AffiliateAdmin.AffiliateGroups_Viewers and AffiliateAdmin.AffiliatesGroups
- The name suffix "NogaJunk0226" indicates this is a developer holding copy created in February 2026 prior to the PART-5531 migration
- Do not use this procedure in new integrations; use dbo.GetPayments instead
- The DROP TABLE #Aff at the end is inside the BEGIN...END block (unlike the production version which drops it after the EXEC)

---

## 8. Sample Queries

### 8.1 This procedure should not be called in production

```sql
-- Do not use; use dbo.GetPayments instead.
-- Kept for historical reference only.
-- EXEC dbo.GetPayments_New_NogaJunk0226 @AffiliateId = 1001;
```

### 8.2 Compare logic with the production procedure

```sql
-- View both procedure definitions side by side for migration audit
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.GetPayments')) AS ProductionProc;
SELECT OBJECT_DEFINITION(OBJECT_ID('dbo.GetPayments_New_NogaJunk0226')) AS BackupProc;
```

---

## 9. Atlassian Knowledge Sources

- PART-5531 (2026-02-08, Gil Haba): The migration that made this backup obsolete; moved affiliate group management to AffiliateAdmin schema and switched from UserID to UserObjectID in dbo.GetPayments.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10*
*Object: dbo.GetPayments_New_NogaJunk0226 | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetPayments_New_NogaJunk0226.sql*
