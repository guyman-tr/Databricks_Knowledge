# Dictionary.CloseUserCategory

> Lookup table defining top-level categories for user account closure reasons in the self-service account closure flow.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CloseUserCategoryId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.CloseUserCategory defines the top-level categories that organize account closure reasons into business-meaningful groups. It is the first tier of a three-tier hierarchy: Category -> Reason (Dictionary.CloseUserReason) -> Solution (Dictionary.CloseUserSolution). This hierarchy powers the self-service account closure flow where users are guided through a structured questionnaire.

This table exists to organize closure reasons for both user experience and business analytics. By categorizing reasons, the platform can present relevant retention solutions, track closure trends by category, and identify systemic issues (e.g., a spike in "paymentIssues" closures might signal a payment provider problem).

Categories are presented to the user as the first step in the closure flow. After selecting a category, the user sees category-specific reasons, and for each reason, a tailored retention solution is offered. The CloseUserSolveProblem table captures whether the solution was accepted.

---

## 2. Business Logic

### 2.1 Account Closure Hierarchy

**What**: Three-tier structured flow for account closure with retention intervention at each level.

**Columns/Parameters Involved**: `CloseUserCategoryId`, `CloseUserCategoryName`

**Rules**:
- User selects a category first (this table)
- Each category has multiple specific reasons (Dictionary.CloseUserReason)
- Each reason has a tailored retention solution (Dictionary.CloseUserSolution)
- After seeing the solution, user responds via Dictionary.CloseUserSolveProblem (keep/close)

**Diagram**:
```
User Clicks "Close Account"
        |
  Select Category (this table)
  [paymentIssues|accountIssues|notMeetNeeds|personalReasons|other|privacyConcerns]
        |
  Select Reason (CloseUserReason)
        |
  View Solution (CloseUserSolution)
        |
  Respond (CloseUserSolveProblem)
  [yesKeepOpen|yesClose|noClose]
```

---

## 3. Data Overview

| CloseUserCategoryId | CloseUserCategoryName | Meaning |
|---|---|---|
| 1 | paymentIssues | User experiences problems with deposits, withdrawals, or fees - financial friction |
| 2 | accountIssues | User has account-level problems like blocks, service issues, or unwanted emails |
| 3 | notMeetNeeds | Platform lacks instruments, features, or stability the user requires |
| 4 | personalReasons | User's personal circumstances changed - no longer needs/wants the account |
| 5 | other | Reason does not fit predefined categories |
| 6 | privacyConcerns | User has concerns about data privacy, security, or data handling practices |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CloseUserCategoryId | int | NO | - | CODE-BACKED | Primary key. Closure category: 1=paymentIssues, 2=accountIssues, 3=notMeetNeeds, 4=personalReasons, 5=other, 6=privacyConcerns. See [Close User Category](_glossary.md#close-user-category). |
| 2 | CloseUserCategoryName | varchar(30) | NO | - | CODE-BACKED | Category identifier string used as localization key in the UI. Named in camelCase for frontend consumption. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.CloseUserReason | CloseUserCategoryId | Implicit FK | Each reason belongs to one category |
| Dictionary.CloseUserSolution | CloseUserCategoryId | Implicit FK | Each solution is linked to a category |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CloseUserReason | Table | References CloseUserCategoryId |
| Dictionary.CloseUserSolution | Table | References CloseUserCategoryId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCloseUserCategory | CLUSTERED PK | CloseUserCategoryId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all closure categories
```sql
SELECT CloseUserCategoryId, CloseUserCategoryName
FROM Dictionary.CloseUserCategory WITH (NOLOCK)
ORDER BY CloseUserCategoryId
```

### 8.2 Show full closure hierarchy
```sql
SELECT c.CloseUserCategoryName AS Category, r.CloseUserReasonName AS Reason, s.CloseUserSolutionName AS Solution
FROM Dictionary.CloseUserCategory c WITH (NOLOCK)
JOIN Dictionary.CloseUserReason r WITH (NOLOCK) ON c.CloseUserCategoryId = r.CloseUserCategoryId
JOIN Dictionary.CloseUserSolution s WITH (NOLOCK) ON r.CloseUserReasonId = s.CloseUserReasonId
ORDER BY c.CloseUserCategoryId, r.CloseUserReasonId
```

### 8.3 Count reasons per category
```sql
SELECT c.CloseUserCategoryName, COUNT(*) AS ReasonCount
FROM Dictionary.CloseUserCategory c WITH (NOLOCK)
JOIN Dictionary.CloseUserReason r WITH (NOLOCK) ON c.CloseUserCategoryId = r.CloseUserCategoryId
GROUP BY c.CloseUserCategoryName
ORDER BY ReasonCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CloseUserCategory | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.CloseUserCategory.sql*
