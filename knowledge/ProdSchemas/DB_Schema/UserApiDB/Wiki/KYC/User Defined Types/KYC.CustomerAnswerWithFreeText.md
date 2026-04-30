# KYC.CustomerAnswerWithFreeText (UDT)

> Table-valued parameter type for passing answer IDs with optional free-text responses to KYC stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | AnswerId + FreeText |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.CustomerAnswerWithFreeText extends CustomerAnswer with a FreeText column for KYC questions that allow additional user input (e.g., "Other - please specify"). Used by KYC.SaveCustomerAnswerWithFreeText.

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
| 1 | AnswerId | int | NO | - | CODE-BACKED | KYC answer identifier. References KYC.Answers.AnswerId. |
| 2 | FreeText | nvarchar(max) | YES | - | CODE-BACKED | Optional user-provided free-text response for "Other" or elaboration answers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.SaveCustomerAnswerWithFreeText | Parameter | Parameter Type | TVP for answers with free text |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.SaveCustomerAnswerWithFreeText | Stored Procedure | READONLY parameter type |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate
```sql
DECLARE @Answers KYC.CustomerAnswerWithFreeText
INSERT INTO @Answers (AnswerId, FreeText) VALUES (101, NULL), (205, N'Other: my specific reason')
```

### 8.2 Use with SP
```sql
DECLARE @A KYC.CustomerAnswerWithFreeText
INSERT INTO @A VALUES (101, N'Details here')
EXEC KYC.SaveCustomerAnswerWithFreeText @GCID = 12345, @QuestionId = 1, @Answers = @A
```

### 8.3 Inspect
```sql
DECLARE @A KYC.CustomerAnswerWithFreeText
INSERT INTO @A VALUES (1, NULL), (2, N'text')
SELECT * FROM @A
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: KYC.CustomerAnswerWithFreeText | Type: User Defined Type | Source: UserApiDB/UserApiDB/KYC/User Defined Types/KYC.CustomerAnswerWithFreeText.sql*
