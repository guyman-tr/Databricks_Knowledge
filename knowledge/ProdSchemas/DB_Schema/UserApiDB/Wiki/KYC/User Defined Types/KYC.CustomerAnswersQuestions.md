# KYC.CustomerAnswersQuestions (UDT)

> Table-valued parameter type for passing a list of question IDs to KYC stored procedures (e.g., clearing specific questions).

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | QuestionId (single column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.CustomerAnswersQuestions is a minimal TVP carrying question IDs. Used by KYC.ClearCustomerAnswers to specify which questions' answers should be deleted for a user.

---

## 2. Business Logic

No complex business logic. Data transport type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | QuestionId | int | NO | - | CODE-BACKED | KYC question identifier. References KYC.Questions.QuestionId. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.ClearCustomerAnswers | @questionsToClear | Parameter Type | TVP for specifying questions to clear |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.ClearCustomerAnswers | Stored Procedure | READONLY parameter type |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Clear specific question answers
```sql
DECLARE @Questions KYC.CustomerAnswersQuestions
INSERT INTO @Questions (QuestionId) VALUES (1), (5), (10)
EXEC KYC.ClearCustomerAnswers @gcid = 12345, @questionsToClear = @Questions
```

### 8.2 Inspect
```sql
DECLARE @Q KYC.CustomerAnswersQuestions
INSERT INTO @Q VALUES (1), (2)
SELECT * FROM @Q
```

### 8.3 Populate from query
```sql
DECLARE @Q KYC.CustomerAnswersQuestions
INSERT INTO @Q SELECT DISTINCT QuestionId FROM KYC.CustomerAnswers WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: KYC.CustomerAnswersQuestions | Type: User Defined Type | Source: UserApiDB/UserApiDB/KYC/User Defined Types/KYC.CustomerAnswersQuestions.sql*
