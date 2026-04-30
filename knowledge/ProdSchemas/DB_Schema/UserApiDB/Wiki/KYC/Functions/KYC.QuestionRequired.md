# KYC.QuestionRequired

> Scalar function that determines whether a KYC question is required for a specific user based on country and regulation conditions. Currently returns 0 (disabled).

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns BIT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.QuestionRequired is a conditional logic function designed to determine if a KYC question is required for a specific user based on their country or regulation. However, the function currently always returns 0 (RETURN 0 at the top), effectively disabling all conditional question logic. The remaining code (checking QuestionsOption by OptionId) is dead code below the early return.

The function was likely created for optional question support (referenced in code comments from 2017) but was subsequently disabled. It reads from KYC.QuestionsOption to check country-based (OptionId=1) and regulation-based (OptionId=2) conditions.

---

## 2. Business Logic

### 2.1 Disabled Conditional Logic

**What**: Question requirement evaluation based on country/regulation - currently disabled.

**Columns/Parameters Involved**: `@gcid`, `@questionid`

**Rules**:
- Currently: always returns 0 (not required) - early RETURN 0
- Designed logic (disabled): QuestionId > 1000 -> not required
- OptionId=1 check: country-based requirement
- OptionId=2 check: regulation-based requirement
- Default: 0 (optional questions not required)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int (IN) | NO | - | CODE-BACKED | Global Customer ID - intended to look up user's country/regulation. Currently unused due to early return. |
| 2 | @questionid | int (IN) | NO | - | CODE-BACKED | Question identifier to check. Currently unused. |
| 3 | RETURN | bit | NO | - | CODE-BACKED | Always returns 0 (not required). Designed to return 1 when question is required. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.QuestionsOption | SELECT FROM | Reads conditional rules (dead code) |

### 5.2 Referenced By (other objects point to this)

No objects reference this function (it is currently disabled with early RETURN 0).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.QuestionRequired (function)
  +-- KYC.QuestionsOption (table) [done] (dead code path)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.QuestionsOption | Table | SELECT FROM (dead code) |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if question is required
```sql
SELECT KYC.QuestionRequired(12345, 1) AS IsRequired -- Always returns 0
```

### 8.2 Test with various questions
```sql
SELECT KYC.QuestionRequired(12345, 1) AS Q1, KYC.QuestionRequired(12345, 1001) AS Q1001 -- Both return 0
```

### 8.3 Verify disabled state
```sql
SELECT DISTINCT KYC.QuestionRequired(GCID, 1) FROM Customer.BasicUserInfo WITH (NOLOCK) WHERE GCID < 100 -- All 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: KYC.QuestionRequired | Type: Scalar Function | Source: UserApiDB/UserApiDB/KYC/Functions/KYC.QuestionRequired.sql*
