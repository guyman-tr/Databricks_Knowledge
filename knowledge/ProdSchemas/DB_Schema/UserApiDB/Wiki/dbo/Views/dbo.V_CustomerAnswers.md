# dbo.V_CustomerAnswers

> View joining KYC.CustomerAnswers with V_KYC to return user answers with question text, answer text, and thresholds.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | View |
| **Key Identifier** | GCID + QuestionId + AnswerId (from CustomerAnswers) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.V_CustomerAnswers combines user answer records (KYC.CustomerAnswers) with the full question-answer metadata (dbo.V_KYC view) to provide a denormalized view of what each user answered, including question text, answer text, thresholds, and multi-selection flag. Used for reporting and analytics.

---

## 2. Business Logic

No complex business logic. LEFT JOIN from CustomerAnswers to V_KYC on QuestionId + AnswerId.

---

## 3. Data Overview

N/A - view over 180M+ row CustomerAnswers table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | User who answered. From KYC.CustomerAnswers. |
| 2 | OccurredAt | datetime | NO | - | CODE-BACKED | When answer was submitted. From KYC.CustomerAnswers. |
| 3 | FreeText | nvarchar(max) | YES | - | CODE-BACKED | Free-text response. From KYC.CustomerAnswers. |
| 4 | QuestionId | int | YES | - | CODE-BACKED | Question identifier. From V_KYC. |
| 5 | QuestionText | nvarchar(250) | YES | - | CODE-BACKED | Question display text. From V_KYC -> KYC.Questions. |
| 6 | AnswerId | int | YES | - | CODE-BACKED | Answer identifier. From V_KYC. |
| 7 | AnswerText | nvarchar(250) | YES | - | CODE-BACKED | Answer display text. From V_KYC -> KYC.Answers. |
| 8 | MinThreshold | int | YES | - | CODE-BACKED | Min range value. From V_KYC -> KYC.AnswerThresholds. |
| 9 | MaxThreshold | int | YES | - | CODE-BACKED | Max range value. From V_KYC -> KYC.AnswerThresholds. |
| 10 | MultipleSelection | bit | YES | - | CODE-BACKED | Whether question allows multiple answers. From V_KYC -> KYC.Questions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.CustomerAnswers | FROM | User answer data |
| - | dbo.V_KYC | LEFT JOIN | Question-answer metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.V_CustomerAnswersNrml | - | FROM | Adds windowed ranking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.V_CustomerAnswers (view)
  +-- KYC.CustomerAnswers (table) [done]
  +-- dbo.V_KYC (view) [done in this batch]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.CustomerAnswers | Table | FROM |
| dbo.V_KYC | View | LEFT JOIN |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.V_CustomerAnswersNrml | View | FROM |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 User's answers with text
```sql
SELECT GCID, QuestionText, AnswerText, OccurredAt FROM dbo.V_CustomerAnswers WITH (NOLOCK) WHERE GCID = @GCID
```

### 8.2 Answers with thresholds
```sql
SELECT * FROM dbo.V_CustomerAnswers WITH (NOLOCK) WHERE GCID = @GCID AND MinThreshold IS NOT NULL
```

### 8.3 Recent answers
```sql
SELECT TOP 100 GCID, QuestionText, AnswerText, OccurredAt FROM dbo.V_CustomerAnswers WITH (NOLOCK) ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: dbo.V_CustomerAnswers | Type: View | Source: UserApiDB/UserApiDB/dbo/Views/dbo.V_CustomerAnswers.sql*
