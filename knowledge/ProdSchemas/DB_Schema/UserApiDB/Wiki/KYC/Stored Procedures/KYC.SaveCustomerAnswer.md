# KYC.SaveCustomerAnswer

> Transactionally saves a user's KYC answer: archives previous answers to History, deletes old, inserts new, and returns the changes.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid + @questionId + @answers (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.SaveCustomerAnswer is the primary answer submission procedure for single-FreeText answers. Within a transaction: (1) archives existing answers for this GCID+QuestionId to History.CustomerAnswers, (2) deletes them from KYC.CustomerAnswers, (3) inserts new answers from the TVP with the shared @FreeText. Returns the inserted rows via OUTPUT clause. Uses KYC.CustomerAnswer TVP (AnswerId-only).

---

## 2. Business Logic

### 2.1 Archive-Delete-Insert Pattern

**What**: Atomic answer replacement with full audit trail.

**Columns/Parameters Involved**: `@gcid`, `@questionId`, `@answers`, `@occurredAt`, `@FreeText`

**Rules**:
- Step 1: INSERT existing answers into History.CustomerAnswers
- Step 2: DELETE from KYC.CustomerAnswers for GCID+QuestionId
- Step 3: INSERT new answers from TVP with shared @FreeText
- OUTPUT clause returns inserted rows for caller confirmation
- All in transaction - ROLLBACK on error

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | User answering the question. |
| 2 | @answers | KYC.CustomerAnswer READONLY (IN) | NO | - | CODE-BACKED | TVP with AnswerId values (one or more for multi-select). |
| 3 | @questionId | int (IN) | NO | - | CODE-BACKED | Question being answered. |
| 4 | @occurredAt | datetime (IN) | NO | - | CODE-BACKED | When the answer was submitted. |
| 5 | @FreeText | nvarchar(max) (IN) | YES | NULL | CODE-BACKED | Optional free-text response shared across all answers for this question. |

Output: GCID, QuestionId, AnswerId, OccurredAt, FreeText (the newly inserted answers).

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
KYC.SaveCustomerAnswer (procedure)
  +-- KYC.CustomerAnswers (table) [done]
  +-- History.CustomerAnswers (table) [done]
  +-- KYC.CustomerAnswer (UDT) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.CustomerAnswers | Table | SELECT + DELETE + INSERT |
| History.CustomerAnswers | Table | INSERT INTO |
| KYC.CustomerAnswer | UDT | Parameter type |

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

### 8.1 Save single answer
```sql
DECLARE @a KYC.CustomerAnswer
INSERT INTO @a VALUES (101)
EXEC KYC.SaveCustomerAnswer @gcid = 12345, @answers = @a, @questionId = 1, @occurredAt = '2026-04-12'
```

### 8.2 Save with free text
```sql
DECLARE @a KYC.CustomerAnswer
INSERT INTO @a VALUES (205)
EXEC KYC.SaveCustomerAnswer @gcid = 12345, @answers = @a, @questionId = 5, @occurredAt = '2026-04-12', @FreeText = N'Other reason'
```

### 8.3 Multi-select answer
```sql
DECLARE @a KYC.CustomerAnswer
INSERT INTO @a VALUES (101), (102), (103)
EXEC KYC.SaveCustomerAnswer @gcid = 12345, @answers = @a, @questionId = 10, @occurredAt = '2026-04-12'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.SaveCustomerAnswer | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.SaveCustomerAnswer.sql*
