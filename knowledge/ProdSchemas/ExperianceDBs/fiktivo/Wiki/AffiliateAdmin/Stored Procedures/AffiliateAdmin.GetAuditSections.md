# AffiliateAdmin.GetAuditSections

> Returns all audit section types from the Dictionary.ChangedSections reference table for use in audit log filtering dropdowns.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateAdmin |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SectionID, Name |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** GetAuditSections retrieves the complete list of audit section types from `Dictionary.ChangedSections`, returning each section's identifier and name ordered by SectionID. These sections represent the different areas of the system that are tracked by the audit log.

**WHY:** The audit log viewer requires a dropdown filter to allow administrators to narrow audit entries by the system section where changes occurred. This procedure provides the data for that dropdown, enabling focused investigation of changes within specific areas such as affiliates, banners, categories, or configuration settings. See Changed Sections glossary for the full list of section IDs.

**HOW:** The procedure executes a simple SELECT of SectionID and Name from `Dictionary.ChangedSections`, ordered by SectionID in ascending order. No filtering or parameterization is applied.

---

## 2. Business Logic

No complex business logic. This is a direct lookup against the Dictionary.ChangedSections reference table. The ordering by SectionID provides a stable, predictable sort order consistent with the dictionary table's intended sequence. The returned values are used as filter options in conjunction with the `GetAuditLog` procedure's @SectionIndex parameter.

---

## 3. Data Overview
N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| - | *(no parameters)* | - | - | - | - | This procedure accepts no parameters |

**Result Set:** SectionID (INT), Name (NVARCHAR) from `Dictionary.ChangedSections` (CODE-BACKED)

---

## 5. Relationships

### 5.1 References To
| Object | Type | Relationship |
|--------|------|-------------|
| `Dictionary.ChangedSections` | Table | SELECT SectionID, Name |

### 5.2 Referenced By
| Object | Type | Context |
|--------|------|---------|
| Audit log filter dropdown | Application | Populates section filter in audit log viewer |
| `AffiliateAdmin.GetAuditLog` | Procedure | Section values used as @SectionIndex filter |

---

## 6. Dependencies

### 6.0 Chain
`GetAuditSections` -> `Dictionary.ChangedSections`

### 6.1 Depends On
- `Dictionary.ChangedSections` - Reference table for audit section definitions. See Changed Sections glossary.

### 6.2 Depend On This
No known database dependencies. Called from application layer to populate filter controls.

---

## 7. Technical Details

### 7.1 Indexes
N/A

### 7.2 Constraints
N/A

---

## 8. Sample Queries

```sql
-- 1. Get all audit sections for dropdown population
EXEC AffiliateAdmin.GetAuditSections;
```

```sql
-- 2. Load sections before querying audit log
EXEC AffiliateAdmin.GetAuditSections;
-- User selects a SectionID, then:
-- EXEC AffiliateAdmin.GetAuditLog @SectionIndex = <selected>, ...
```

```sql
-- 3. Verify section count matches expectations
EXEC AffiliateAdmin.GetAuditSections;
-- Compare with: SELECT COUNT(*) FROM Dictionary.ChangedSections;
```

---

## 9. Atlassian Knowledge Sources
No Atlassian sources found. DDL reference: PART-4214.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateAdmin.GetAuditSections | Type: Stored Procedure | Source: fiktivo/AffiliateAdmin/Stored Procedures/AffiliateAdmin.GetAuditSections.sql*
