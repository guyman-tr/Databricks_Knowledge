# History.CustomerAnswers

> Archive table storing deleted KYC customer answers, populated by KYC.ClearCustomerAnswers before deleting from the source table.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (INT IDENTITY, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (PK + NC on OccurredAt,QuestionId + NC on GCID,QuestionId,OccurredAt) |

---

## 1. Business Meaning

History.CustomerAnswers archives KYC answers that were cleared (deleted) from KYC.CustomerAnswers. When KYC.ClearCustomerAnswers runs, it first copies answers here before deleting them. Preserves: GCID, QuestionId, AnswerId, OccurredAt_InSource (original timestamp), OccurredAt (archive timestamp), and FreeText.

KYC.GetCustomerAnswers uses this table's MIN(OccurredAt) to calculate FirstUpdated for each question.

---

## 2. Business Logic

### 2.1 Dual Timestamp Design

**What**: Two OccurredAt columns distinguish original answer time from archive time.

**Columns/Parameters Involved**: `OccurredAt_InSource`, `OccurredAt`

**Rules**:
- OccurredAt_InSource = when the answer was originally submitted in KYC.CustomerAnswers
- OccurredAt = when the answer was archived (cleared) - the archive timestamp

---

## 3. Data Overview

N/A - archive table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int (IDENTITY) | NO | - | CODE-BACKED | Primary key. Archive record ID. |
| 2 | GCID | int | NO | - | CODE-BACKED | User who originally answered. |
| 3 | QuestionId | int | NO | - | CODE-BACKED | Question that was answered. |
| 4 | AnswerId | int | NO | - | CODE-BACKED | Answer that was selected. |
| 5 | OccurredAt_InSource | datetime | NO | - | CODE-BACKED | When the answer was originally submitted in KYC.CustomerAnswers. |
| 6 | OccurredAt | datetime | NO | - | CODE-BACKED | When the answer was archived (cleared from the source table). |
| 7 | FreeText | nvarchar(max) | YES | - | CODE-BACKED | Free-text response that was provided. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.ClearCustomerAnswers | ID | SP writes | Archives answers before deleting |
| KYC.GetCustomerAnswers | GCID+QuestionId | SP reads | MIN(OccurredAt) for FirstUpdated |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.ClearCustomerAnswers | Stored Procedure | INSERT INTO |
| KYC.GetCustomerAnswers | Stored Procedure | Subquery for MIN(OccurredAt) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryAnswers | CLUSTERED PK | ID | - | - | Active (PAGE compressed) |
| IDX_HistoryCustomerAnswers_OccurredAt | NC | OccurredAt, QuestionId | GCID | - | Active (PAGE compressed) |
| Idx_History_CustomerAnswers_GCID_QuestionId_OccurredAt | NC | GCID, QuestionId, OccurredAt | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Archived answers for a user
```sql
SELECT QuestionId, AnswerId, OccurredAt_InSource, OccurredAt FROM History.CustomerAnswers WITH (NOLOCK) WHERE GCID = @GCID ORDER BY OccurredAt DESC
```

### 8.2 First answer date for a question
```sql
SELECT MIN(OccurredAt) AS FirstAnswer FROM History.CustomerAnswers WITH (NOLOCK) WHERE GCID = @GCID AND QuestionId = @QId
```

### 8.3 Recent archives
```sql
SELECT TOP 100 GCID, QuestionId, AnswerId, OccurredAt FROM History.CustomerAnswers WITH (NOLOCK) ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: History.CustomerAnswers | Type: Table | Source: UserApiDB/UserApiDB/History/Tables/History.CustomerAnswers.sql*
