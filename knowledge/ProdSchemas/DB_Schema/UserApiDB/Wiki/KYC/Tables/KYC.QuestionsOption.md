# KYC.QuestionsOption

> Configuration table storing question-level options (e.g., country-based or regulation-based conditional display rules).

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Table |
| **Key Identifier** | QuestionId + OptionId (composite PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (PK only) |

---

## 1. Business Meaning

KYC.QuestionsOption stores conditional display options for questions. Each row defines an option (OptionId) with a value (OptionValue) for a question. The KYC.QuestionRequired function reads these options to determine if a question should be shown based on the user's country (OptionId=1) or regulation (OptionId=2). Contains only 2 rows.

---

## 2. Business Logic

### 2.1 Conditional Question Display

**What**: Questions can be conditionally shown based on country or regulation.

**Columns/Parameters Involved**: `QuestionId`, `OptionId`, `OptionValue`

**Rules**:
- OptionId=1: Country-based condition (OptionValue = CountryID)
- OptionId=2: Regulation-based condition (OptionValue = RegulationID)
- KYC.QuestionRequired function checks these options

---

## 3. Data Overview

2 rows.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | QuestionId | int | NO | - | CODE-BACKED | Part of composite PK. Which question this option applies to. |
| 2 | OptionId | int | NO | - | CODE-BACKED | Part of composite PK. Option type: 1=country-based, 2=regulation-based. |
| 3 | OptionValue | int | YES | - | CODE-BACKED | The value for this option (e.g., a CountryID or RegulationID). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.QuestionRequired | QuestionId | Function reads | Checks conditional display rules |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.QuestionRequired | Function | SELECT FROM to check conditions |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_QuestionsOption | CLUSTERED PK | QuestionId, OptionId | - | - | Active (PAGE compressed) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 All question options
```sql
SELECT QuestionId, OptionId, OptionValue FROM KYC.QuestionsOption WITH (NOLOCK)
```

### 8.2 Country-conditional questions
```sql
SELECT QuestionId, OptionValue AS CountryID FROM KYC.QuestionsOption WITH (NOLOCK) WHERE OptionId = 1
```

### 8.3 Check if question is conditional
```sql
SELECT CASE WHEN EXISTS (SELECT 1 FROM KYC.QuestionsOption WITH (NOLOCK) WHERE QuestionId = @QuestionId) THEN 1 ELSE 0 END AS IsConditional
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: KYC.QuestionsOption | Type: Table | Source: UserApiDB/UserApiDB/KYC/Tables/KYC.QuestionsOption.sql*
