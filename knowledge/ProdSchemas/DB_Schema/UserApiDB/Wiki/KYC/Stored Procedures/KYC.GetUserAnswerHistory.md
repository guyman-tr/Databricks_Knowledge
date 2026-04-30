# KYC.GetUserAnswerHistory

> Returns the full answer history for a user across specified questions, combining current answers with archived history via UNION.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @gcid + @questionIds (input params) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.GetUserAnswerHistory returns the complete answer timeline for specified questions by combining current answers (KYC.CustomerAnswers) with archived answers (History.CustomerAnswers) via UNION. For current answers, OccurredAt is aliased as OccurredAt_InSource. Results are ordered by QuestionId and timestamp. Uses dbo.IdList TVP for the question filter.

---

## 2. Business Logic

### 2.1 UNION of Current + History

**What**: Combines two sources into a unified timeline.

**Rules**:
- History.CustomerAnswers: has OccurredAt_InSource (original timestamp)
- KYC.CustomerAnswers: OccurredAt aliased as OccurredAt_InSource
- UNION (not UNION ALL) removes duplicates
- Ordered by QuestionId, OccurredAt_InSource

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @questionIds | IdList READONLY (IN) | NO | - | CODE-BACKED | TVP containing QuestionId values to retrieve history for. Uses dbo.IdList type. |

Output: GCID, QuestionId, AnswerId, OccurredAt_InSource, FreeText.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | History.CustomerAnswers | SELECT FROM | Archived answers |
| - | KYC.CustomerAnswers | SELECT FROM | Current answers |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.GetUserAnswerHistory (procedure)
  +-- History.CustomerAnswers (table) [done]
  +-- KYC.CustomerAnswers (table) [done]
  +-- dbo.IdList (UDT) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.CustomerAnswers | Table | SELECT FROM |
| KYC.CustomerAnswers | Table | SELECT FROM |
| dbo.IdList | UDT | Parameter type |

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

### 8.1 Get history for specific questions
```sql
DECLARE @q dbo.IdList
INSERT INTO @q VALUES (1), (5), (10)
EXEC KYC.GetUserAnswerHistory @gcid = 12345, @questionIds = @q
```

### 8.2 All questions
```sql
DECLARE @q dbo.IdList
INSERT INTO @q SELECT DISTINCT QuestionId FROM KYC.CustomerAnswers WITH (NOLOCK) WHERE GCID = 12345
EXEC KYC.GetUserAnswerHistory @gcid = 12345, @questionIds = @q
```

### 8.3 Single question
```sql
DECLARE @q dbo.IdList
INSERT INTO @q VALUES (3)
EXEC KYC.GetUserAnswerHistory @gcid = 12345, @questionIds = @q
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.GetUserAnswerHistory | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.GetUserAnswerHistory.sql*
