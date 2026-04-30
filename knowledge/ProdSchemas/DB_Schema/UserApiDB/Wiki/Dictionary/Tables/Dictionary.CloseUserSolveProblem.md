# Dictionary.CloseUserSolveProblem

> Lookup table capturing the user's response to retention solutions offered during the account closure flow.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CloseUserSolveProblemId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.CloseUserSolveProblem defines the possible user responses after being presented with a retention solution during the account closure flow. This is the final step in the Category -> Reason -> Solution -> Response hierarchy, capturing whether the retention effort succeeded.

This table is critical for retention analytics. By tracking whether solutions resolve user concerns, the business can measure retention effectiveness by category, identify which solutions work, and optimize the closure flow. A high rate of "yesKeepOpen" indicates effective retention; a high rate of "noClose" suggests solutions need improvement.

The response is recorded after the user views the tailored retention solution (from Dictionary.CloseUserSolution). The user either decides to keep the account open (success), acknowledges the solution but still wants to close (partial failure), or rejects the solution entirely (failure).

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Three-option response lookup. See individual element descriptions in Section 4.

---

## 3. Data Overview

| CloseUserSolveProblemId | CloseUserSolveProblemName | Meaning |
|---|---|---|
| 1 | yesKeepOpen | Retention success - the solution addressed the user's concern and they choose to keep their account open |
| 2 | yesClose | Partial retention failure - user acknowledges the solution but still proceeds with account closure |
| 3 | noClose | Full retention failure - the offered solution did not address the user's problem, proceeding to close |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CloseUserSolveProblemId | int | NO | - | CODE-BACKED | Primary key. User response: 1=yesKeepOpen (retained), 2=yesClose (acknowledged but closing), 3=noClose (solution rejected, closing). See [Close User Solve Problem](_glossary.md#close-user-solve-problem). |
| 2 | CloseUserSolveProblemName | varchar(30) | NO | - | CODE-BACKED | camelCase response identifier used as localization key in the UI. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer closure tracking tables | CloseUserSolveProblemId | Lookup | Records the user's retention response |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCloseUserSolveProblem | CLUSTERED PK | CloseUserSolveProblemId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all response options
```sql
SELECT CloseUserSolveProblemId, CloseUserSolveProblemName
FROM Dictionary.CloseUserSolveProblem WITH (NOLOCK)
ORDER BY CloseUserSolveProblemId
```

### 8.2 Retention success rate
```sql
SELECT sp.CloseUserSolveProblemName, COUNT(*) AS ResponseCount
FROM Customer.CloseUserResponses cr WITH (NOLOCK)
JOIN Dictionary.CloseUserSolveProblem sp WITH (NOLOCK) ON cr.SolveProblemId = sp.CloseUserSolveProblemId
GROUP BY sp.CloseUserSolveProblemName
```

### 8.3 Retention rate by closure category
```sql
SELECT c.CloseUserCategoryName,
       SUM(CASE WHEN sp.CloseUserSolveProblemId = 1 THEN 1 ELSE 0 END) AS Retained,
       COUNT(*) AS Total
FROM Customer.CloseUserResponses cr WITH (NOLOCK)
JOIN Dictionary.CloseUserCategory c WITH (NOLOCK) ON cr.CategoryId = c.CloseUserCategoryId
JOIN Dictionary.CloseUserSolveProblem sp WITH (NOLOCK) ON cr.SolveProblemId = sp.CloseUserSolveProblemId
GROUP BY c.CloseUserCategoryName
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CloseUserSolveProblem | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.CloseUserSolveProblem.sql*
