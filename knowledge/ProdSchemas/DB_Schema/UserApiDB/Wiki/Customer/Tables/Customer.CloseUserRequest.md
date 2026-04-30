# Customer.CloseUserRequest

> Records the full account closure flow: which category, reason, solution was presented, whether the user was retained, and any free-text feedback.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | Gcid + Occurred (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Customer.CloseUserRequest is the primary transactional table for the self-service account closure flow. Each row captures a complete closure interaction: the category of concern, the specific reason, which retention solution was shown, and whether it worked (SolveProblem response). It also captures free-text feedback from users.

This table is the main data source for closure/retention analytics. It links to all four levels of the closure hierarchy (Dictionary tables: CloseUserCategory, CloseUserReason, CloseUserSolution, CloseUserSolveProblem). The composite PK allows tracking multiple closure attempts by the same user over time.

---

## 2. Business Logic

### 2.1 Closure Flow Capture

**What**: Full closure interaction captured in a single row per attempt.

**Columns/Parameters Involved**: `CloseUserCategoryId`, `CloseUserReasonId`, `CloseUserSolutionId`, `CloseUserSolveProblemId`, `FreeText`

**Rules**:
- CategoryId is mandatory - user must at least select a category
- ReasonId, SolutionId, SolveProblemId are nullable - user may abandon the flow at any point
- FreeText captures additional unstructured feedback (max 4000 chars)
- Multiple rows per user (keyed by Occurred timestamp) track repeated closure attempts

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Gcid | int | NO | - | CODE-BACKED | Part of composite PK. Global Customer ID. |
| 2 | CloseUserCategoryId | int | NO | - | CODE-BACKED | FK to Dictionary.CloseUserCategory. Top-level closure reason: 1=paymentIssues, 2=accountIssues, 3=notMeetNeeds, 4=personalReasons, 5=other, 6=privacyConcerns. See [Close User Category](_glossary.md#close-user-category). |
| 3 | CloseUserReasonId | int | YES | - | CODE-BACKED | FK to Dictionary.CloseUserReason. Specific reason within the category. NULL if user did not proceed past category selection. See [Close User Reason](_glossary.md#close-user-reason). |
| 4 | CloseUserSolutionId | int | YES | - | CODE-BACKED | FK to Dictionary.CloseUserSolution. Which retention solution was presented. NULL if flow was abandoned before solution. See [Close User Solution](_glossary.md#close-user-solution). |
| 5 | CloseUserSolveProblemId | int | YES | - | CODE-BACKED | FK to Dictionary.CloseUserSolveProblem. User's response: 1=yesKeepOpen, 2=yesClose, 3=noClose. NULL if user did not respond. See [Close User Solve Problem](_glossary.md#close-user-solve-problem). |
| 6 | FreeText | nvarchar(4000) | YES | - | CODE-BACKED | User-provided free-text feedback about their closure decision. Unicode support for all languages. |
| 7 | Occurred | datetime | NO | getdate() | CODE-BACKED | Part of composite PK. When this closure attempt happened. Default: current datetime. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CloseUserCategoryId | Dictionary.CloseUserCategory | Explicit FK | Closure category |
| CloseUserReasonId | Dictionary.CloseUserReason | Explicit FK | Specific reason |
| CloseUserSolutionId | Dictionary.CloseUserSolution | Explicit FK | Retention solution presented |
| CloseUserSolveProblemId | Dictionary.CloseUserSolveProblem | Explicit FK | User's retention response |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.AddCloseUserRequest | Gcid | SP writes | Records closure flow data |
| Customer.GetCloseAccountMetadata | Gcid | SP reads | Returns closure history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.CloseUserRequest (table)
  +-- Dictionary.CloseUserCategory (table) [done]
  +-- Dictionary.CloseUserReason (table) [done]
  +-- Dictionary.CloseUserSolution (table) [done]
  +-- Dictionary.CloseUserSolveProblem (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CloseUserCategory | Table | FK: CloseUserCategoryId |
| Dictionary.CloseUserReason | Table | FK: CloseUserReasonId |
| Dictionary.CloseUserSolution | Table | FK: CloseUserSolutionId |
| Dictionary.CloseUserSolveProblem | Table | FK: CloseUserSolveProblemId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.AddCloseUserRequest | Stored Procedure | Inserts rows |
| Customer.GetCloseAccountMetadata | Stored Procedure | Reads from |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerCloseUserRequest | CLUSTERED PK | Gcid, Occurred | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| (unnamed) | DEFAULT | getdate() for Occurred |
| FK_CloseUserRequestCategory | FOREIGN KEY | CloseUserCategoryId -> Dictionary.CloseUserCategory |
| FK_CloseUserRequestReason | FOREIGN KEY | CloseUserReasonId -> Dictionary.CloseUserReason |
| FK_CloseUserRequestSolution | FOREIGN KEY | CloseUserSolutionId -> Dictionary.CloseUserSolution |
| FK_CloseUserRequestSolveProblem | FOREIGN KEY | CloseUserSolveProblemId -> Dictionary.CloseUserSolveProblem |

---

## 8. Sample Queries

### 8.1 Full closure flow for a user
```sql
SELECT c.CloseUserCategoryName AS Category, r.CloseUserReasonName AS Reason,
       s.CloseUserSolutionName AS Solution, sp.CloseUserSolveProblemName AS Response,
       cr.FreeText, cr.Occurred
FROM Customer.CloseUserRequest cr WITH (NOLOCK)
JOIN Dictionary.CloseUserCategory c WITH (NOLOCK) ON cr.CloseUserCategoryId = c.CloseUserCategoryId
LEFT JOIN Dictionary.CloseUserReason r WITH (NOLOCK) ON cr.CloseUserReasonId = r.CloseUserReasonId
LEFT JOIN Dictionary.CloseUserSolution s WITH (NOLOCK) ON cr.CloseUserSolutionId = s.CloseUserSolutionId
LEFT JOIN Dictionary.CloseUserSolveProblem sp WITH (NOLOCK) ON cr.CloseUserSolveProblemId = sp.CloseUserSolveProblemId
WHERE cr.Gcid = @GCID ORDER BY cr.Occurred DESC
```

### 8.2 Retention success rate
```sql
SELECT sp.CloseUserSolveProblemName, COUNT(*) AS Cnt
FROM Customer.CloseUserRequest cr WITH (NOLOCK)
JOIN Dictionary.CloseUserSolveProblem sp WITH (NOLOCK) ON cr.CloseUserSolveProblemId = sp.CloseUserSolveProblemId
GROUP BY sp.CloseUserSolveProblemName
```

### 8.3 Most common closure categories
```sql
SELECT c.CloseUserCategoryName, COUNT(*) AS RequestCount
FROM Customer.CloseUserRequest cr WITH (NOLOCK)
JOIN Dictionary.CloseUserCategory c WITH (NOLOCK) ON cr.CloseUserCategoryId = c.CloseUserCategoryId
GROUP BY c.CloseUserCategoryName ORDER BY RequestCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.CloseUserRequest | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.CloseUserRequest.sql*
