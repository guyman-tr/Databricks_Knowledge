# AffiliateAdmin.GetAffiliateGroupsWithoutPermissions

> Returns all affiliate groups without any permission filtering, for administrative contexts that require unrestricted access.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all AffiliatesGroups rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AffiliateAdmin.GetAffiliateGroupsWithoutPermissions is a simple lookup procedure that returns the complete list of affiliate groups from the AffiliatesGroups table without applying any user-based permission filtering. It serves administrative and system-level contexts where the full group list is needed regardless of who is requesting it.

This procedure exists as a counterpart to GetAffiliateGroups, which has parameters for permission-based filtering (even though that logic is currently commented out). GetAffiliateGroupsWithoutPermissions makes the intent explicit: the caller deliberately wants all groups with no access control checks. This is used in back-office reporting, system configuration screens, and batch processing scenarios.

Data flow: The procedure takes no input parameters and performs a straightforward SELECT from AffiliateAdmin.AffiliatesGroups, returning all rows. Unlike GetAffiliateGroups, this procedure does not exclude the sentinel group (ID 1), providing the truly complete group list.

---

## 2. Business Logic

No complex business logic detected. This is a simple, unfiltered SELECT from a single table with no parameters, conditions, or transformations. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | (no parameters) | - | - | - | CODE-BACKED | This procedure accepts no input parameters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | AffiliateAdmin.AffiliatesGroups | Read | Reads all groups without filtering |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateAdmin.GetAffiliateGroupsWithoutPermissions (procedure)
+-- AffiliateAdmin.AffiliatesGroups (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateAdmin.AffiliatesGroups | Table | SELECT for all group rows |

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

### 8.1 Get all affiliate groups
```sql
EXEC AffiliateAdmin.GetAffiliateGroupsWithoutPermissions;
-- Returns: all rows from AffiliatesGroups including sentinel group (ID 1)
```

### 8.2 Compare with permission-filtered version
```sql
-- This returns ALL groups (no filter)
EXEC AffiliateAdmin.GetAffiliateGroupsWithoutPermissions;

-- This excludes sentinel group and has permission params
EXEC AffiliateAdmin.GetAffiliateGroups @IsAdmin = 1, @UserEmail = 'admin@example.com';
```

### 8.3 Count total groups in the system
```sql
SELECT COUNT(*) AS TotalGroups
FROM AffiliateAdmin.AffiliatesGroups WITH (NOLOCK);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found. DDL references PART-3147, PART-5531.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 10.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAffiliateGroupsWithoutPermissions | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAffiliateGroupsWithoutPermissions.sql*
