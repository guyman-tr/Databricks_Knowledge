# KYC.AnswerThresholds

> Stores numeric min/max threshold values for KYC answers that represent ranges (e.g., income brackets, experience years).

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | AnswerID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

KYC.AnswerThresholds stores numeric range thresholds for KYC answers that represent quantities or ranges. For example, an income question answer "50,000-100,000" would have MinThreshold=50000 and MaxThreshold=100000. Contains 26 threshold entries. Used by GetKycQuestions to return threshold data alongside answer text for suitability scoring.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Numeric ranges attached to answers.

---

## 3. Data Overview

26 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AnswerID | int | NO | - | CODE-BACKED | Primary key. FK to KYC.Answers.AnswerId. One threshold record per answer. |
| 2 | MinThreshold | int | YES | - | CODE-BACKED | Minimum numeric value for this answer's range. NULL for open-ended lower bound. |
| 3 | MaxThreshold | int | YES | - | CODE-BACKED | Maximum numeric value for this answer's range. NULL for open-ended upper bound. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| AnswerID | KYC.Answers | Explicit FK | Answer this threshold applies to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.GetKycQuestions | AnswerID | SP reads | LEFT JOINed for threshold data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.AnswerThresholds (table)
  +-- KYC.Answers (table) [done in this batch]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.Answers | Table | FK: AnswerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.GetKycQuestions | Stored Procedure | LEFT JOIN |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AnswerThresholds | CLUSTERED PK | AnswerID | - | - | Active (PAGE compressed) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_KYC_AnswerThresholds_AnswerID | FOREIGN KEY | AnswerID -> KYC.Answers(AnswerId) |

---

## 8. Sample Queries

### 8.1 All thresholds with answer text
```sql
SELECT a.AnswerText, t.MinThreshold, t.MaxThreshold FROM KYC.AnswerThresholds t WITH (NOLOCK)
JOIN KYC.Answers a WITH (NOLOCK) ON t.AnswerID = a.AnswerId ORDER BY t.MinThreshold
```

### 8.2 Open-ended thresholds
```sql
SELECT * FROM KYC.AnswerThresholds WITH (NOLOCK) WHERE MinThreshold IS NULL OR MaxThreshold IS NULL
```

### 8.3 Threshold for specific answer
```sql
SELECT MinThreshold, MaxThreshold FROM KYC.AnswerThresholds WITH (NOLOCK) WHERE AnswerID = @AnswerID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.AnswerThresholds | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.AnswerThresholds.sql*
