# KYC.CustomerAnswer (UDT)

> Table-valued parameter type for passing a list of answer IDs to KYC stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | KYC |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | AnswerId (single column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

KYC.CustomerAnswer is a minimal TVP type carrying a single AnswerId column. Used to pass lists of answer IDs to KYC procedures, such as when saving multiple customer answers in a single call.

---

## 2. Business Logic

No complex business logic. Data transport type with single column.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | AnswerId | int | NO | - | CODE-BACKED | KYC answer identifier. References KYC.Answers.AnswerId. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| KYC.SaveCustomerAnswer | Parameter | Parameter Type | TVP for batch answer submission |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| KYC.SaveCustomerAnswer | Stored Procedure | READONLY parameter type |

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
DECLARE @Answers KYC.CustomerAnswer
INSERT INTO @Answers (AnswerId) VALUES (101), (205), (310)
```

### 8.2 Use with SP
```sql
DECLARE @Answers KYC.CustomerAnswer
INSERT INTO @Answers VALUES (101)
EXEC KYC.SaveCustomerAnswer @GCID = 12345, @QuestionId = 1, @Answers = @Answers
```

### 8.3 Select from variable
```sql
DECLARE @A KYC.CustomerAnswer
INSERT INTO @A VALUES (1), (2), (3)
SELECT * FROM @A
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: KYC.CustomerAnswer | Type: User Defined Type | Source: UserApiDB/UserApiDB/KYC/User Defined Types/KYC.CustomerAnswer.sql*
