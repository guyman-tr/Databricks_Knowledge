# Dictionary.AnswerStatus

> Lookup table tracking the validity state of user-provided answers in KYC questionnaires and assessments.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | AnswerStatusID (INT, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

Dictionary.AnswerStatus defines whether a user's KYC questionnaire answer is still current or has been superseded by a newer response. When users update their risk profile or regulatory questionnaire answers, the old answer is marked as Outdated while the new one becomes Active.

This table is essential for compliance audit trails. Regulators require that platforms maintain a history of user responses and can distinguish between current and historical answers. Without this status tracking, it would be impossible to determine which set of answers represents the user's current risk profile.

Answer status is set during KYC questionnaire submission flows. When a user re-answers a question, the system marks the previous answer as Outdated (0) and creates a new Active (1) record.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Binary state lookup (Active/Outdated). See individual element descriptions in Section 4.

---

## 3. Data Overview

| AnswerStatusID | Name | Meaning |
|---|---|---|
| 0 | Outdated | Answer has been superseded by a newer response - retained for audit history but no longer represents the user's current profile |
| 1 | Active | Current valid answer - this is what the system uses for the user's risk profile and regulatory compliance |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AnswerStatusID | int | NO | - | CODE-BACKED | Primary key. 0=Outdated (superseded answer), 1=Active (current answer). Used in questionnaire answer tables to filter for current responses. |
| 2 | Name | varchar(10) | YES | - | CODE-BACKED | Human-readable status label: "Outdated" or "Active". |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer answer tables | AnswerStatusID | Lookup | Tracks whether each questionnaire answer is current or historical |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found in Dictionary schema. Referenced by Customer schema answer tables.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_AnswerStatus | CLUSTERED PK | AnswerStatusID | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all answer statuses
```sql
SELECT AnswerStatusID, Name
FROM Dictionary.AnswerStatus WITH (NOLOCK)
ORDER BY AnswerStatusID
```

### 8.2 Find active answers for a user
```sql
SELECT a.*, s.Name AS StatusName
FROM Customer.Answers a WITH (NOLOCK)
JOIN Dictionary.AnswerStatus s WITH (NOLOCK) ON a.AnswerStatusID = s.AnswerStatusID
WHERE a.CustomerID = @CustomerID AND s.AnswerStatusID = 1
```

### 8.3 Count active vs outdated answers
```sql
SELECT s.Name, COUNT(*) AS AnswerCount
FROM Customer.Answers a WITH (NOLOCK)
JOIN Dictionary.AnswerStatus s WITH (NOLOCK) ON a.AnswerStatusID = s.AnswerStatusID
GROUP BY s.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-11 | Enriched: - | Quality: 7.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.AnswerStatus | Type: Table | Source: UserApiDB/UserApiDB/Dictionary/Tables/Dictionary.AnswerStatus.sql*
