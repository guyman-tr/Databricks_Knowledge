# KYC.ClearCustomerAnswers

> Transactionally archives then deletes specific question answers for a user, preserving history in History.CustomerAnswers.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid + @questionsToClear (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.ClearCustomerAnswers removes specific question answers for a user while preserving an audit trail. Within a transaction, it first copies the targeted answers to History.CustomerAnswers (with the original OccurredAt as OccurredAt_InSource and current UTC time as OccurredAt), then deletes them from KYC.CustomerAnswers. Used when KYC question requirements change and answers need to be re-collected.

---

## 2. Business Logic

### 2.1 Archive-Then-Delete Pattern

**What**: Transactional archive + delete for audit compliance.

**Columns/Parameters Involved**: `@gcid`, `@questionsToClear`

**Rules**:
- BEGIN TRAN -> INSERT INTO History -> DELETE FROM CustomerAnswers -> COMMIT
- On error: ROLLBACK (all or nothing)
- Uses KYC.CustomerAnswersQuestions TVP to specify which questions to clear

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID whose answers to clear. |
| 2 | @questionsToClear | KYC.CustomerAnswersQuestions READONLY (IN) | NO | - | CODE-BACKED | TVP containing QuestionId values to clear. Only specified questions are affected. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.CustomerAnswers | SELECT + DELETE | Archives then removes answers |
| - | History.CustomerAnswers | INSERT INTO | Archives deleted answers |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.ClearCustomerAnswers (procedure)
  +-- KYC.CustomerAnswers (table) [done]
  +-- History.CustomerAnswers (table, external)
  +-- KYC.CustomerAnswersQuestions (UDT) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.CustomerAnswers | Table | SELECT + DELETE FROM |
| History.CustomerAnswers | Table | INSERT INTO |
| KYC.CustomerAnswersQuestions | UDT | Parameter type |

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

### 8.1 Clear specific questions
```sql
DECLARE @Q KYC.CustomerAnswersQuestions
INSERT INTO @Q VALUES (1), (5)
EXEC KYC.ClearCustomerAnswers @gcid = 12345, @questionsToClear = @Q
```

### 8.2 Clear all questions for a user
```sql
DECLARE @Q KYC.CustomerAnswersQuestions
INSERT INTO @Q SELECT DISTINCT QuestionId FROM KYC.CustomerAnswers WITH (NOLOCK) WHERE GCID = 12345
EXEC KYC.ClearCustomerAnswers @gcid = 12345, @questionsToClear = @Q
```

### 8.3 Verify archive
```sql
SELECT * FROM History.CustomerAnswers WITH (NOLOCK) WHERE GCID = 12345 ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.ClearCustomerAnswers | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.ClearCustomerAnswers.sql*
