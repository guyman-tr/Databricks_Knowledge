# KYC.MetadataLoader

> Returns four metadata result sets: question descriptions, answer descriptions, extended user fields, and extended value types - used for caching at service startup.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No input params |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.MetadataLoader returns four result sets in a single call for efficient metadata loading at service startup: (1) question short descriptions, (2) answer short descriptions, (3) extended user field metadata, (4) extended value type metadata. The service caches these for ID-to-name resolution during KYC processing.

---

## 2. Business Logic

### 2.1 Multi-Result Set Pattern

**What**: Four SELECTs returning four result sets in one call.

**Rules**:
- Result 1: KYC.Questions - QuestionId, QuestionShortDescription
- Result 2: KYC.Answers - AnswerId, AnswerShortDescription
- Result 3: Dictionary.ExtendedUserField - FieldId, FieldTypeId, ExtendedUserFieldShortName
- Result 4: Dictionary.ExtendedUserValueType - ValueTypeID, ExtendedUserValueTypeShortName, FieldTypeID

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

No input parameters. Four result sets returned.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | KYC.Questions | SELECT FROM | Question descriptions |
| - | KYC.Answers | SELECT FROM | Answer descriptions |
| - | Dictionary.ExtendedUserField | SELECT FROM | Field metadata |
| - | Dictionary.ExtendedUserValueType | SELECT FROM | Value type metadata |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
KYC.MetadataLoader (procedure)
  +-- KYC.Questions (table) [done]
  +-- KYC.Answers (table) [done]
  +-- Dictionary.ExtendedUserField (table) [done]
  +-- Dictionary.ExtendedUserValueType (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| KYC.Questions | Table | SELECT FROM |
| KYC.Answers | Table | SELECT FROM |
| Dictionary.ExtendedUserField | Table | SELECT FROM |
| Dictionary.ExtendedUserValueType | Table | SELECT FROM |

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

### 8.1 Load all metadata
```sql
EXEC KYC.MetadataLoader
```

### 8.2 Individual result sets
```sql
SELECT QuestionId, QuestionShortDescription FROM KYC.Questions WITH (NOLOCK)
SELECT AnswerId, AnswerShortDescription FROM KYC.Answers WITH (NOLOCK)
SELECT FieldId, FieldTypeId, ExtendedUserFieldShortName FROM Dictionary.ExtendedUserField WITH (NOLOCK)
SELECT ValueTypeID, ExtendedUserValueTypeShortName, FieldTypeID FROM Dictionary.ExtendedUserValueType WITH (NOLOCK)
```

### 8.3 Count metadata items
```sql
SELECT 'Questions' AS Type, COUNT(*) FROM KYC.Questions WITH (NOLOCK)
UNION ALL SELECT 'Answers', COUNT(*) FROM KYC.Answers WITH (NOLOCK)
UNION ALL SELECT 'Fields', COUNT(*) FROM Dictionary.ExtendedUserField WITH (NOLOCK)
UNION ALL SELECT 'ValueTypes', COUNT(*) FROM Dictionary.ExtendedUserValueType WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: KYC.MetadataLoader | Type: Stored Procedure | Source: UserApiDB/UserApiDB/KYC/Stored Procedures/KYC.MetadataLoader.sql*
