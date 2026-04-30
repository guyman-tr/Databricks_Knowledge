# Customer.GetCloseAccountMetadata

> Returns the full close-account metadata hierarchy: categories, reasons (per category), solutions (per category+reason), and solve-problem options from four Dictionary tables in two result sets.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters - returns full metadata) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetCloseAccountMetadata retrieves the complete metadata hierarchy used in the account closure workflow. When a user requests to close their account, the UI presents a cascading set of choices: first a category (why they want to close), then reasons within that category, then available solutions (to potentially retain the user), and a separate list of solve-problem options.

This procedure serves the account closure UI and retention flow. The metadata is entirely from Dictionary tables and does not change per user - it defines the available options for all users.

The procedure returns two result sets: (1) the category-reason-solution hierarchy via LEFT JOINs across CloseUserCategory, CloseUserReason, and CloseUserSolution, (2) a flat list of CloseUserSolveProblem entries.

---

## 2. Business Logic

### 2.1 Category-Reason-Solution Hierarchy

**What**: Three-level cascading metadata for account closure decisions.

**Columns/Parameters Involved**: `CloseUserCategoryId`, `CloseUserReasonId`, `CloseUserSolutionId`

**Rules**:
- Categories are the top level (e.g., "Not satisfied with service", "Personal reasons")
- Reasons are per category (LEFT JOIN on CloseUserCategoryId)
- Solutions are per category+reason pair (LEFT JOIN on both CloseUserCategoryId AND CloseUserReasonId)
- LEFT JOINs ensure categories with no reasons, and reasons with no solutions, are still returned
- SolveProblem options are independent of the hierarchy (separate result set)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no input parameters.

**Result Set 1 - Category/Reason/Solution Hierarchy:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | CloseUserCategoryId | Dictionary.CloseUserCategory | CODE-BACKED | Close account category ID. See [Close User Category](_glossary.md#close-user-category). |
| 2 | CloseUserCategoryName | Dictionary.CloseUserCategory | CODE-BACKED | Category display name. |
| 3 | CloseUserReasonId | Dictionary.CloseUserReason | CODE-BACKED | Close account reason ID within the category. See [Close User Reason](_glossary.md#close-user-reason). |
| 4 | CloseUserReasonName | Dictionary.CloseUserReason | CODE-BACKED | Reason display name. |
| 5 | CloseUserSolutionId | Dictionary.CloseUserSolution | CODE-BACKED | Proposed solution ID for the category+reason. See [Close User Solution](_glossary.md#close-user-solution). |
| 6 | CloseUserSolutionName | Dictionary.CloseUserSolution | CODE-BACKED | Solution display name. |

**Result Set 2 - SolveProblem Options:**

| # | Element | Source | Confidence | Description |
|---|---------|-------|------------|-------------|
| 1 | CloseUserSolveProblemId | Dictionary.CloseUserSolveProblem | CODE-BACKED | Solve-problem option ID. See [Close User Solve Problem](_glossary.md#close-user-solve-problem). |
| 2 | CloseUserSolveProblemName | Dictionary.CloseUserSolveProblem | CODE-BACKED | Solve-problem option display name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Dictionary.CloseUserCategory | SELECT (READER) | Close account categories |
| (body) | Dictionary.CloseUserReason | LEFT JOIN (READER) | Reasons per category |
| (body) | Dictionary.CloseUserSolution | LEFT JOIN (READER) | Solutions per category+reason |
| (body) | Dictionary.CloseUserSolveProblem | SELECT (READER) | Solve-problem options |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (external callers) | - | Application | Called by account closure UI to populate dropdown choices |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetCloseAccountMetadata (procedure)
+-- Dictionary.CloseUserCategory (table)
+-- Dictionary.CloseUserReason (table)
+-- Dictionary.CloseUserSolution (table)
+-- Dictionary.CloseUserSolveProblem (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CloseUserCategory | Table | SELECT - close categories |
| Dictionary.CloseUserReason | Table | LEFT JOIN - reasons per category |
| Dictionary.CloseUserSolution | Table | LEFT JOIN - solutions per category+reason |
| Dictionary.CloseUserSolveProblem | Table | SELECT - solve-problem options |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (no database callers found) | - | Called from application layer |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all close account metadata
```sql
EXEC Customer.GetCloseAccountMetadata
-- Returns 2 result sets: hierarchy + solve-problem options
```

### 8.2 View category-reason-solution hierarchy directly
```sql
SELECT cuc.CloseUserCategoryId, cuc.CloseUserCategoryName, cur.CloseUserReasonId, cur.CloseUserReasonName
FROM Dictionary.CloseUserCategory cuc WITH (NOLOCK)
LEFT JOIN Dictionary.CloseUserReason cur WITH (NOLOCK) ON cuc.CloseUserCategoryId = cur.CloseUserCategoryId
ORDER BY cuc.CloseUserCategoryId, cur.CloseUserReasonId
```

### 8.3 View solve-problem options
```sql
SELECT * FROM Dictionary.CloseUserSolveProblem WITH (NOLOCK) ORDER BY CloseUserSolveProblemId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetCloseAccountMetadata | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetCloseAccountMetadata.sql*
