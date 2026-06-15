# KYC.CustomerAnswers

> Stores user responses to KYC suitability questionnaire questions, with 180M+ records tracking every answer submission.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | GCID + QuestionId + AnswerId (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (PK + NC on OccurredAt + NC on QuestionId,GCID) |

---

## 1. Business Meaning

KYC.CustomerAnswers is the primary transactional table for KYC questionnaire responses. Each row represents one user's selection of one answer for one question. The composite PK (GCID, QuestionId, AnswerId) allows a user to select multiple answers for multi-select questions. Contains 180M+ rows - one of the largest tables in UserApiDB.

This table is central to regulatory compliance. When users complete their suitability assessment, their answers are stored here and evaluated to determine product access (CFDs, crypto, copy trading). The OccurredAt timestamp enables audit trails. The AnswerId column uses dynamic data masking for PII protection.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Key-value store (user + question -> answer(s)).

---

## 3. Data Overview

180,268,547 rows. Transactional - not queryable in full.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Part of composite PK. Global Customer ID. |
| 2 | QuestionId | int | NO | - | CODE-BACKED | Part of composite PK. References KYC.Questions. Which question was answered. |
| 3 | AnswerId | int MASKED | NO | - | CODE-BACKED | Part of composite PK. References KYC.Answers. Which answer was selected. Dynamic data masking applied. |
| 4 | OccurredAt | datetime | NO | - | CODE-BACKED | When this answer was submitted. Used for audit trails and FirstUpdated calculation. |
| 5 | FreeText | nvarchar(max) | YES | - | CODE-BACKED | Optional free-text input for answers that support elaboration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no explicit FK constraints (performance optimization for 180M+ row table).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.GetCustomerAnswers | GCID | SP reads | Returns user's answers with FirstUpdated |
| KYC.ClearCustomerAnswers | GCID | SP deletes | Archives then deletes specific question answers |
| KYC.SaveCustomerAnswer | GCID, QuestionId | SP writes | Archive-delete-insert answer replacement |
| KYC.SaveCustomerAnswerWithFreeText | GCID, QuestionId | SP writes | Archive-delete-insert with per-answer free text |
| KYC.GetBulkGCIDForRecalculateAppropriateness | GCID | SP reads | JOIN for bulk appropriateness recalculation |
| KYC.GetGCIDForRecalculateAppropriateness | GCID | SP reads | JOIN for single/all-user appropriateness recalculation |
| KYC.GetUserAnswerHistory | GCID, QuestionId | SP reads | UNION with History for full answer timeline |
| KYC.GetUserDataForRestrictions | GCID | SP reads | Reads answers for restriction evaluation |
| History.CustomerAnswers | - | Archive | ClearCustomerAnswers/Save SPs copy here before delete |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies (no explicit FKs for performance).

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.GetCustomerAnswers | Stored Procedure | Reads from |
| KYC.ClearCustomerAnswers | Stored Procedure | Deletes from (after archiving to History) |
| KYC.SaveCustomerAnswer | Stored Procedure | Archive + delete + insert |
| KYC.SaveCustomerAnswerWithFreeText | Stored Procedure | Archive + delete + insert |
| KYC.GetBulkGCIDForRecalculateAppropriateness | Stored Procedure | JOIN for bulk recalc |
| KYC.GetGCIDForRecalculateAppropriateness | Stored Procedure | SELECT FROM for recalc |
| KYC.GetUserAnswerHistory | Stored Procedure | UNION for answer timeline |
| KYC.GetUserDataForRestrictions | Stored Procedure | SELECT FROM for restrictions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CustomerAnswers | CLUSTERED PK | GCID, QuestionId, AnswerId | - | - | Active (PAGE compressed) |
| IDX_CustomerAnswers_OccurredAt | NONCLUSTERED | OccurredAt | - | - | Active (PAGE compressed) |
| Idx_KYC_CustomerAnswers_QuestionId | NONCLUSTERED | QuestionId, GCID | OccurredAt | - | Active (PAGE compressed) |

### 7.2 Constraints

None (no FKs for performance on 180M+ row table).

---

## 8. Sample Queries

### 8.1 Get answers for a user
```sql
SELECT QuestionId, AnswerId, OccurredAt, FreeText FROM KYC.CustomerAnswers WITH (NOLOCK) WHERE GCID = @GCID
```

### 8.2 Get answers with question and answer text
```sql
SELECT ca.QuestionId, q.QuestionText, ca.AnswerId, a.AnswerText, ca.OccurredAt
FROM KYC.CustomerAnswers ca WITH (NOLOCK)
JOIN KYC.Questions q WITH (NOLOCK) ON ca.QuestionId = q.QuestionId AND q.LanguageId = 1
JOIN KYC.Answers a WITH (NOLOCK) ON ca.AnswerId = a.AnswerId
WHERE ca.GCID = @GCID
```

### 8.3 Recent answer submissions
```sql
SELECT TOP 100 GCID, QuestionId, AnswerId, OccurredAt FROM KYC.CustomerAnswers WITH (NOLOCK) ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 8.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.CustomerAnswers | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.CustomerAnswers.sql*
