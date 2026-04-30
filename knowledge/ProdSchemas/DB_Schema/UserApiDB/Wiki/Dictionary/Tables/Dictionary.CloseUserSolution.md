# Dictionary.CloseUserSolution

> Lookup table defining retention solutions offered to users for each specific account closure reason, the third tier of the Category -> Reason -> Solution hierarchy.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CloseUserSolutionId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.CloseUserSolution provides tailored retention messages for each specific closure reason. When a user selects a reason for closing their account, the system presents a solution designed to address that specific concern. This is the third and final tier: Category -> Reason -> Solution.

Each solution maps 1:1 to a reason and inherits its category. The naming convention `{categoryName}Solution{SpecificReason}` mirrors the reason naming. All 17 solutions are localization keys that map to translated retention messages in the UI.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. 1:1 mapping to CloseUserReason.

---

## 3. Data Overview

| CloseUserSolutionId | CloseUserSolutionName | CategoryId | ReasonId | Meaning |
|---|---|---|---|---|
| 1 | paymentIssuesSolutionFeeTooHigh | 1 | 1 | Retention message addressing fee concerns - may highlight fee reductions or tier benefits |
| 5 | accountIssuesSolutionAccountBlocked | 2 | 5 | Offers to help resolve account block rather than close |
| 9 | notMeetNeedsSolutionMissingInstrument | 3 | 9 | Informs user about upcoming instrument additions or alternatives |

*3 of 17 rows shown.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CloseUserSolutionId | int | NO | - | CODE-BACKED | Primary key. Solution identifier (1-17), maps 1:1 to CloseUserReasonId. See [Close User Solution](_glossary.md#close-user-solution). |
| 2 | CloseUserSolutionName | varchar(60) | NO | - | CODE-BACKED | camelCase solution identifier: `{categoryName}Solution{SpecificReason}`. Localization key. |
| 3 | CloseUserCategoryId | int | NO | - | CODE-BACKED | Implicit FK to Dictionary.CloseUserCategory. Inherited from the parent reason. |
| 4 | CloseUserReasonId | int | NO | - | CODE-BACKED | Implicit FK to Dictionary.CloseUserReason. The specific reason this solution addresses. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CloseUserCategoryId | Dictionary.CloseUserCategory | Implicit FK | Parent category |
| CloseUserReasonId | Dictionary.CloseUserReason | Implicit FK | Specific reason this solution addresses |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer closure flow tables | SolutionId | Lookup | Records which solution was presented |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CloseUserSolution (table)
  +-- Dictionary.CloseUserCategory (table)
  +-- Dictionary.CloseUserReason (table)
        +-- Dictionary.CloseUserCategory (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CloseUserCategory | Table | Implicit FK via CloseUserCategoryId |
| Dictionary.CloseUserReason | Table | Implicit FK via CloseUserReasonId |

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCloseUserSolution | CLUSTERED PK | CloseUserSolutionId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Full closure hierarchy
```sql
SELECT c.CloseUserCategoryName, r.CloseUserReasonName, s.CloseUserSolutionName
FROM Dictionary.CloseUserSolution s WITH (NOLOCK)
JOIN Dictionary.CloseUserCategory c WITH (NOLOCK) ON s.CloseUserCategoryId = c.CloseUserCategoryId
JOIN Dictionary.CloseUserReason r WITH (NOLOCK) ON s.CloseUserReasonId = r.CloseUserReasonId
ORDER BY s.CloseUserCategoryId, s.CloseUserReasonId
```

### 8.2 Solutions for payment issues
```sql
SELECT CloseUserSolutionId, CloseUserSolutionName FROM Dictionary.CloseUserSolution WITH (NOLOCK)
WHERE CloseUserCategoryId = 1 ORDER BY CloseUserSolutionId
```

### 8.3 Verify 1:1 reason-solution mapping
```sql
SELECT r.CloseUserReasonId, r.CloseUserReasonName, s.CloseUserSolutionName
FROM Dictionary.CloseUserReason r WITH (NOLOCK)
LEFT JOIN Dictionary.CloseUserSolution s WITH (NOLOCK) ON r.CloseUserReasonId = s.CloseUserReasonId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.CloseUserSolution | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.CloseUserSolution.sql*
