# dbo.V_CustomerAnswersNrml

> Extends V_CustomerAnswers with windowed analytics: earliest/latest answer timestamps per user and a rank column for latest answer per question.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | From V_CustomerAnswers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.V_CustomerAnswersNrml ("Normalized") adds analytical columns to V_CustomerAnswers: OccurredAtMin (user's first-ever answer), OccurredAtMax (user's most recent answer), and N (rank within each user+question partition, ordered by OccurredAt DESC, so N=1 is the latest answer). Enables filtering to latest answers only.

---

## 2. Business Logic

### 2.1 Windowed Analytics

**What**: Adds MIN/MAX timestamps and latest-answer ranking.

**Columns/Parameters Involved**: `OccurredAtMin`, `OccurredAtMax`, `N`

**Rules**:
- OccurredAtMin = MIN(OccurredAt) OVER(PARTITION BY GCID) - first answer ever
- OccurredAtMax = MAX(OccurredAt) OVER(PARTITION BY GCID) - most recent answer
- N = RANK() OVER(PARTITION BY GCID, QuestionId ORDER BY OccurredAt DESC) - 1 = latest

---

## 3. Data Overview

N/A - view.

---

## 4. Elements

All columns from V_CustomerAnswers plus:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1-10 | (inherited) | - | - | - | CODE-BACKED | All V_CustomerAnswers columns. |
| 11 | OccurredAtMin | datetime | NO | - | CODE-BACKED | Earliest answer date across all questions for this GCID. |
| 12 | OccurredAtMax | datetime | NO | - | CODE-BACKED | Latest answer date across all questions for this GCID. |
| 13 | N | bigint | NO | - | CODE-BACKED | Rank within GCID+QuestionId by OccurredAt DESC. N=1 is the latest answer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | dbo.V_CustomerAnswers | FROM | Base data |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_CustomerAnswersNrml (view)
  +-- dbo.V_CustomerAnswers (view) [done in this batch]
        +-- KYC.CustomerAnswers (table) [done]
        +-- dbo.V_KYC (view) [done in this batch]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_CustomerAnswers | View | FROM |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Latest answers only
```sql
SELECT * FROM dbo.V_CustomerAnswersNrml WITH (NOLOCK) WHERE GCID = @GCID AND N = 1
```

### 8.2 User's answer timeline
```sql
SELECT OccurredAtMin, OccurredAtMax, DATEDIFF(DAY, OccurredAtMin, OccurredAtMax) AS DaysSpan
FROM dbo.V_CustomerAnswersNrml WITH (NOLOCK) WHERE GCID = @GCID AND N = 1
```

### 8.3 All answers ranked
```sql
SELECT QuestionText, AnswerText, OccurredAt, N FROM dbo.V_CustomerAnswersNrml WITH (NOLOCK) WHERE GCID = @GCID ORDER BY QuestionId, N
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: dbo.V_CustomerAnswersNrml | Type: View | Source: UserApiDB/UserApiDB/dbo/Views/dbo.V_CustomerAnswersNrml.sql*
