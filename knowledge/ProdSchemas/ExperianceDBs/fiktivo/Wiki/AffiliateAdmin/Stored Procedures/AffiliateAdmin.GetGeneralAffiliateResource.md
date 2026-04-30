# AffiliateAdmin.GetGeneralAffiliateResource

> Returns all account status values from the Dictionary.AccountStatus reference table for affiliate management dropdowns.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | AccountStatusID, AccountStatusName |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetGeneralAffiliateResource retrieves the complete list of account statuses from `Dictionary.AccountStatus`, returning each status's identifier and display name ordered by AccountStatusID. These statuses represent the possible states of an affiliate's account in the system.

**WHY:** When managing affiliates, administrators need to view and set account statuses (e.g., active, suspended, pending review). This procedure provides the standardized set of status values for dropdown menus and filter controls across the affiliate management interface. By centralizing this lookup, the system ensures consistent status options wherever affiliate status selection is needed. See Account Status glossary for the full list of status values.

**HOW:** The procedure executes a simple SELECT of AccountStatusID and AccountStatusName from `Dictionary.AccountStatus`, ordered by AccountStatusID in ascending order. No filtering or parameterization is applied.

---

## 2. Business Logic

No complex business logic. This is a direct lookup against the Dictionary.AccountStatus reference table. The ordering by AccountStatusID provides a stable sort order consistent with the dictionary table's intended sequence.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure accepts no parameters |

**Result Set:** AccountStatusID (INT), AccountStatusName (NVARCHAR) from `Dictionary.AccountStatus` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `Dictionary.AccountStatus` | Table | SELECT AccountStatusID, AccountStatusName |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Affiliate status dropdowns | Application | Populates account status selection lists |
| Affiliate filter panels | Application | Provides status filter options |

---

## 6. Dependencies

### 6.0 Chain
`GetGeneralAffiliateResource` -> `Dictionary.AccountStatus`

### 6.1 Depends On
- `Dictionary.AccountStatus` - Reference table for account status definitions. See Account Status glossary.

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
-- 1. Get all account statuses for dropdown population
EXEC AffiliateAdmin.GetGeneralAffiliateResource;
```

```sql
-- 2. Load statuses before creating/editing an affiliate
EXEC AffiliateAdmin.GetGeneralAffiliateResource;
-- Use returned AccountStatusID values for affiliate status assignment
```

```sql
-- 3. Verify status list completeness
EXEC AffiliateAdmin.GetGeneralAffiliateResource;
-- Compare with: SELECT COUNT(*) FROM Dictionary.AccountStatus;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4021.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetGeneralAffiliateResource | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetGeneralAffiliateResource.sql*
