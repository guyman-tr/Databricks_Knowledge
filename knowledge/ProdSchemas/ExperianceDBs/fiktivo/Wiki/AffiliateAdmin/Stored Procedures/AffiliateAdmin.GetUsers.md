# AffiliateAdmin.GetUsers

> Returns all admin users from the AffiliateAdmin.Users table with their display names for user selection interfaces.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UserObjectID, FirstName, LastName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetUsers retrieves the complete list of administrative users from the `AffiliateAdmin.Users` table, returning each user's object identifier, first name, and last name.

**WHY:** Various administrative workflows require user selection, such as assigning an account manager to an affiliate, filtering activities by user, or delegating responsibilities. This procedure provides the standard user lookup for dropdown menus and user selection controls across the affiliate administration interface.

**HOW:** The procedure executes a simple SELECT of UserObjectID, FirstName, and LastName from `AffiliateAdmin.Users`. No filtering, ordering, or parameterization is applied.

---

## 2. Business Logic

No complex business logic. This is a straightforward lookup that returns all users from the AffiliateAdmin.Users table. The result provides the minimal set of fields needed for user identification in selection interfaces.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure accepts no parameters |

**Result Set:** UserObjectID (UNIQUEIDENTIFIER/INT), FirstName (NVARCHAR), LastName (NVARCHAR) from `AffiliateAdmin.Users` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `AffiliateAdmin.Users` | Table | SELECT UserObjectID, FirstName, LastName |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| User selection dropdowns | Application | Populates user selection lists for assignment workflows |
| Activity filter panels | Application | Provides user filter options |

---

## 6. Dependencies

### 6.0 Chain
`GetUsers` -> `AffiliateAdmin.Users`

### 6.1 Depends On
- `AffiliateAdmin.Users` - Source table for admin user data

### 6.2 Depend On This
No known database dependencies. Called from application layer for UI population.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Get all admin users
EXEC AffiliateAdmin.GetUsers;
```

```sql
-- 2. Load users for account manager assignment dropdown
EXEC AffiliateAdmin.GetUsers;
-- Application populates dropdown with "FirstName LastName" display values
```

```sql
-- 3. Verify user count
EXEC AffiliateAdmin.GetUsers;
-- Compare with: SELECT COUNT(*) FROM AffiliateAdmin.Users;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4500.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetUsers | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetUsers.sql*
