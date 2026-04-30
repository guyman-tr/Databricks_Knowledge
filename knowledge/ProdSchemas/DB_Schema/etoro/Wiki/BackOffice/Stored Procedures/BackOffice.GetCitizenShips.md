# BackOffice.GetCitizenShips

> Returns the complete sorted list of citizenship values from BackOffice.CitizenShips, used to populate citizenship dropdown controls in BackOffice customer management forms.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters; returns all CitizenShip values sorted alphabetically |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.GetCitizenShips` returns the full list of citizenship values maintained in `BackOffice.CitizenShips`, sorted alphabetically. This is a reference data lookup procedure used to populate UI dropdowns when BackOffice agents need to set or update a customer's citizenship during KYC processing or customer record management.

The procedure takes no parameters, returning the entire table in alphabetical order - consistent with a dropdown population pattern where the full list is needed once at page/form load.

---

## 2. Business Logic

### 2.1 Full Table Alphabetical Sort

**What**: Returns all citizenship values sorted ascending by name.

**Columns/Parameters Involved**: `BackOffice.CitizenShips.CitizenShip`

**Rules**:
- ORDER BY CitizenShip ASC - alphabetical order for UI display.
- NOLOCK - reads the reference data without locking.
- No filter - always returns all active citizenship values.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CitizenShip | NVARCHAR | NO | - | CODE-BACKED | Citizenship name value (e.g., "American", "British", "Israeli"). Sorted alphabetically. From BackOffice.CitizenShips.CitizenShip. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CitizenShip | BackOffice.CitizenShips | Primary source | Full list of citizenship reference values. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by BackOffice UI for dropdown population. No SQL procedure callers found in repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetCitizenShips (procedure)
└── BackOffice.CitizenShips (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CitizenShips | Table | Only source - full alphabetically sorted citizenship list. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found. | - | Called externally by BackOffice UI dropdown. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

SET NOCOUNT ON. NOLOCK. No parameters. Single-column SELECT. ORDER BY CitizenShip ASC.

---

## 8. Sample Queries

### 8.1 Get all citizenships
```sql
EXEC BackOffice.GetCitizenShips;
```

### 8.2 Inline equivalent
```sql
SELECT CitizenShip
FROM BackOffice.CitizenShips WITH (NOLOCK)
ORDER BY CitizenShip ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetCitizenShips | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.GetCitizenShips.sql*
