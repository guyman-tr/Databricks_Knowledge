# Dictionary.CloseUserReason

> Lookup table defining specific reasons within each closure category, the second tier of the Category -> Reason -> Solution hierarchy.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CloseUserReasonId (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.CloseUserReason provides the specific reason a user wants to close their account, within the context of a broader category (Dictionary.CloseUserCategory). This is the second tier in the three-tier closure flow: the user first selects a category (e.g., "paymentIssues"), then a specific reason (e.g., "paymentIssuesReasonFeeTooHigh"), and is then presented with a tailored retention solution.

Each reason maps to exactly one category via CloseUserCategoryId. The naming convention `{categoryName}Reason{SpecificReason}` makes the hierarchy explicit in the data. There are 17 reasons across 4 active categories (paymentIssues: 3, accountIssues: 5, notMeetNeeds: 4, personalReasons: 5).

---

## 2. Business Logic

### 2.1 Category-to-Reason Mapping

**What**: 17 reasons organized into 4 categories with 1:1 solution mapping.

**Columns/Parameters Involved**: `CloseUserReasonId`, `CloseUserReasonName`, `CloseUserCategoryId`

**Rules**:
- paymentIssues (cat 1): FeeTooHigh (1), DepositProblem (2), WithdrawalProblem (3)
- accountIssues (cat 2): ServiceProblem (4), AccountBlocked (5), PromotionalEmail (6), ChangeEmail (7), NewAccount (8)
- notMeetNeeds (cat 3): MissingInstrument (9), TransferToWallet (10), UnstablePlatform (11), MissingFeature (12)
- personalReasons (cat 4): NeedMoney (13), AchieveGoals (14), NotUsingAccount (15), NotHaveTime (16), NotSafe (17)

---

## 3. Data Overview

| CloseUserReasonId | CloseUserReasonName | CloseUserCategoryId | Meaning |
|---|---|---|---|
| 1 | paymentIssuesReasonFeeTooHigh | 1 | User finds trading or withdrawal fees too expensive |
| 5 | accountIssuesReasonAccountBlocked | 2 | User's account was blocked and they want to close rather than resolve |
| 9 | notMeetNeedsReasonMissingInstrument | 3 | Platform lacks a specific instrument the user wants to trade |
| 15 | personalReasonsReasonNotUsingAccount | 4 | User no longer actively uses the account |
| 17 | personalReasonsReasonNotSafe | 4 | User does not feel the platform is safe for their funds |

*5 of 17 rows shown.*

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CloseUserReasonId | int | NO | - | CODE-BACKED | Primary key. Specific closure reason (1-17). See [Close User Reason](_glossary.md#close-user-reason). |
| 2 | CloseUserReasonName | varchar(60) | NO | - | CODE-BACKED | camelCase reason identifier: `{categoryName}Reason{SpecificReason}`. Used as localization key. |
| 3 | CloseUserCategoryId | int | NO | - | CODE-BACKED | FK to Dictionary.CloseUserCategory. Groups this reason under its parent category (1-4). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CloseUserCategoryId | Dictionary.CloseUserCategory | Implicit FK | Each reason belongs to one closure category |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.CloseUserSolution | CloseUserReasonId | Implicit FK | Each solution maps to one reason |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CloseUserReason (table)
  +-- Dictionary.CloseUserCategory (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CloseUserCategory | Table | Implicit FK via CloseUserCategoryId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CloseUserSolution | Table | Implicit FK via CloseUserReasonId |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryCloseUserReason | CLUSTERED PK | CloseUserReasonId | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List reasons with category
```sql
SELECT r.CloseUserReasonId, r.CloseUserReasonName, c.CloseUserCategoryName
FROM Dictionary.CloseUserReason r WITH (NOLOCK)
JOIN Dictionary.CloseUserCategory c WITH (NOLOCK) ON r.CloseUserCategoryId = c.CloseUserCategoryId
ORDER BY r.CloseUserCategoryId, r.CloseUserReasonId
```

### 8.2 Full closure hierarchy
```sql
SELECT c.CloseUserCategoryName AS Category, r.CloseUserReasonName AS Reason, s.CloseUserSolutionName AS Solution
FROM Dictionary.CloseUserReason r WITH (NOLOCK)
JOIN Dictionary.CloseUserCategory c WITH (NOLOCK) ON r.CloseUserCategoryId = c.CloseUserCategoryId
JOIN Dictionary.CloseUserSolution s WITH (NOLOCK) ON r.CloseUserReasonId = s.CloseUserReasonId
ORDER BY c.CloseUserCategoryId, r.CloseUserReasonId
```

### 8.3 Reasons per category
```sql
SELECT c.CloseUserCategoryName, COUNT(*) AS ReasonCount FROM Dictionary.CloseUserReason r WITH (NOLOCK)
JOIN Dictionary.CloseUserCategory c WITH (NOLOCK) ON r.CloseUserCategoryId = c.CloseUserCategoryId
GROUP BY c.CloseUserCategoryName ORDER BY ReasonCount DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Dictionary.CloseUserReason | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.CloseUserReason.sql*
