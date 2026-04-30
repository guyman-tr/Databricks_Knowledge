# KYC.SaveCustomerAnswerWithFreeText

> Transactionally saves KYC answers with per-answer free text (each answer can have its own free text, unlike SaveCustomerAnswer).

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid + @questionId + @answers (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.SaveCustomerAnswerWithFreeText is the answer submission procedure for questions where each answer can have its own free-text response. Same archive-delete-insert pattern as SaveCustomerAnswer, but uses KYC.CustomerAnswerWithFreeText TVP which includes per-answer FreeText. Each row in the TVP can have a different free text value.

---

## 2. Business Logic

### 2.1 Per-Answer Free Text

**What**: Same as SaveCustomerAnswer but FreeText comes from the TVP, not a shared parameter.

**Rules**:
- Archive existing -> Delete existing -> Insert from TVP
- FreeText is per-answer (from TVP), not shared
- OUTPUT returns inserted rows
- Transaction with ROLLBACK on error

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | User answering. |
| 2 | @answers | KYC.CustomerAnswerWithFreeText READONLY (IN) | NO | - | CODE-BACKED | TVP with AnswerId + per-answer FreeText. |
| 3 | @questionId | int (IN) | NO | - | CODE-BACKED | Question being answered. |
| 4 | @occurredAt | datetime (IN) | NO | - | CODE-BACKED | Submission timestamp. |

Output: GCID, QuestionId, AnswerId, OccurredAt, FreeText.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.CustomerAnswers | SELECT + DELETE + INSERT | Full answer replacement |
| - | History.CustomerAnswers | INSERT INTO | Archives previous answers |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.SaveCustomerAnswerWithFreeText (procedure)
  +-- KYC.CustomerAnswers (table) [done]
  +-- History.CustomerAnswers (table) [done]
  +-- KYC.CustomerAnswerWithFreeText (UDT) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.CustomerAnswers | Table | SELECT + DELETE + INSERT |
| History.CustomerAnswers | Table | INSERT INTO |
| KYC.CustomerAnswerWithFreeText | UDT | Parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Save with per-answer free text
```sql
DECLARE @a KYC.CustomerAnswerWithFreeText
INSERT INTO @a VALUES (101, N'Answer 1 details'), (102, N'Answer 2 details')
EXEC KYC.SaveCustomerAnswerWithFreeText @gcid = 12345, @answers = @a, @questionId = 5, @occurredAt = '2026-04-12'
```

### 8.2 Mixed free text (some NULL)
```sql
DECLARE @a KYC.CustomerAnswerWithFreeText
INSERT INTO @a VALUES (101, NULL), (102, N'Specific reason')
EXEC KYC.SaveCustomerAnswerWithFreeText @gcid = 12345, @answers = @a, @questionId = 10, @occurredAt = '2026-04-12'
```

### 8.3 Compare with SaveCustomerAnswer
```sql
-- SaveCustomerAnswer: shared FreeText for all answers
-- SaveCustomerAnswerWithFreeText: per-answer FreeText
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.SaveCustomerAnswerWithFreeText | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.SaveCustomerAnswerWithFreeText.sql*
