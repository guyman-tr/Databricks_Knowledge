# ASIC.TestResults

> Stores ASIC classification test results per user, recording pass/fail outcome and numeric score for each test attempt.

| Property | Value |
|----------|-------|
| **Schema** | ASIC |
| **Object Type** | Table |
| **Key Identifier** | TestId (PK IDENTITY) |
| **Partition** | No |
| **Indexes** | 2 (PK + NC on GCID DESC) |

---

## 1. Business Meaning

ASIC.TestResults is the primary table for ASIC (Australian Securities and Investments Commission) classification testing. Each row represents a single test attempt by a user, recording whether they passed, their score, and when the test occurred. Soft-delete (Deleted flag) is used instead of physical deletion, preserving history for audit and compliance purposes.

The GCID index (descending) supports fast retrieval of a user's most recent test results, which is the common query pattern when checking current classification status.

---

## 2. Business Logic

### 2.1 Soft Delete Pattern

**What**: Records are never physically deleted; instead the Deleted flag is set to 1.

**Columns Involved**: `Deleted`

**Rules**:
- Default value is 0 (active)
- ASIC.DeleteTestResult sets Deleted = 1
- All read procedures filter WHERE Deleted = 0
- Deleted records are excluded from classification decisions

---

## 3. Data Overview

Transactional table - one row per test attempt per user. Volume depends on how many users have taken ASIC classification tests. Soft-deleted records accumulate over time.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TestId | int IDENTITY | NO | - | CODE-BACKED | Primary key. Auto-generated unique identifier for each test attempt. |
| 2 | GCID | int | NO | - | CODE-BACKED | Global Customer ID. Identifies which user took the test. Indexed descending for fast per-user lookups. |
| 3 | Success | bit | NO | - | CODE-BACKED | Whether the user passed the ASIC classification test. 1 = passed, 0 = failed. |
| 4 | Score | int | YES | - | CODE-BACKED | Numeric score achieved on the test. May be NULL if scoring is not applicable. |
| 5 | OccurredAt | datetime | NO | - | CODE-BACKED | When the test was taken. Used for audit trails and ordering results. |
| 6 | Deleted | bit | NO | 0 | CODE-BACKED | Soft-delete flag. 0 = active, 1 = deleted. All active queries filter WHERE Deleted = 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit FK constraints.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ASIC.CustomerAnswers | TestId | FK | Each answer row links to a test result |
| ASIC.DeleteTestResult | TestId | SP writes | Soft-deletes a test result |
| ASIC.GetTestResults | GCID | SP reads | Returns non-deleted results for a user |
| ASIC.GetAnswers | TestId | SP reads | Joins to filter non-deleted tests |
| ASIC.InsertTestResult | TestId | SP writes | Inserts new test result rows |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies (no explicit FKs).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ASIC.CustomerAnswers | Table | FK on TestId |
| ASIC.DeleteTestResult | Stored Procedure | Updates Deleted flag |
| ASIC.GetTestResults | Stored Procedure | Reads from |
| ASIC.GetAnswers | Stored Procedure | Joins to filter Deleted = 0 |
| ASIC.InsertTestResult | Stored Procedure | Inserts into |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TestResults | CLUSTERED PK | TestId ASC | - | - | Active |
| IX_TestResults_GCID | NONCLUSTERED | GCID DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Definition |
|-----------|------|------------|
| PK_TestResults | PRIMARY KEY | TestId |
| DF_TestResults_Deleted | DEFAULT | Deleted = 0 |

---

## 8. Sample Queries

### 8.1 Get active test results for a user
```sql
SELECT TestId, GCID, Success, Score, OccurredAt
FROM ASIC.TestResults WITH (NOLOCK)
WHERE GCID = @GCID AND Deleted = 0
ORDER BY OccurredAt DESC
```

### 8.2 Get most recent test result for a user
```sql
SELECT TOP 1 TestId, Success, Score, OccurredAt
FROM ASIC.TestResults WITH (NOLOCK)
WHERE GCID = @GCID AND Deleted = 0
ORDER BY OccurredAt DESC
```

### 8.3 Count pass/fail breakdown
```sql
SELECT Success, COUNT(*) AS TestCount
FROM ASIC.TestResults WITH (NOLOCK)
WHERE Deleted = 0
GROUP BY Success
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Object: ASIC.TestResults | Type: Table | Source: UserApiDB/UserApiDB/ASIC/Tables/ASIC.TestResults.sql*
