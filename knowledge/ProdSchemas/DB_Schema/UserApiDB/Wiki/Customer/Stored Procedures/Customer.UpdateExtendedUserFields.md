# Customer.UpdateExtendedUserFields

> Older MERGE-based upsert for extended user fields using ExtendedUserFieldType TVP - same logic as UpdateExtendedUserField but without @ID output and without AdditionalDetails, using OUTPUT clause for history instead of separate INSERT.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | MERGE Customer.ExtendedUserField + History via OUTPUT clause |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateExtendedUserFields is an older version of UpdateExtendedUserField. It uses the Customer.ExtendedUserFieldType TVP (instead of Customer.ExtendedUserField TVP), does not support AdditionalDetails, and does not return the @ID output. History logging for the UPDATE action uses the MERGE OUTPUT clause (instead of a separate INSERT after MERGE). Otherwise the logic is identical: country-scoped replacement, type resolution, history tracking.

---

## 2. Business Logic

### 2.1 Same as UpdateExtendedUserField

**Rules**: Same country-scoped replacement + MERGE pattern. Key difference: MERGE OUTPUT clause feeds directly into ExtendedUserField_History for the UPDATE action (more efficient for batch updates).

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @extendedUserFields | Customer.ExtendedUserFieldType (TVP) | NO | - | CODE-BACKED | Table-valued parameter: FieldId, ExtendedFieldType, Value, CountryId, TypeId. No AdditionalDetails. |
| 2 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.ExtendedUserField | MERGE | Upsert field values |
| - | Customer.ExtendedUserField_History | INSERT + OUTPUT | Audit trail |
| TypeId | Dictionary.ExtendedUserValueType | LEFT JOIN | Type resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Older extended field update path |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateExtendedUserFields (procedure)
+-- Customer.ExtendedUserField (table)
+-- Customer.ExtendedUserField_History (table)
+-- Dictionary.ExtendedUserValueType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ExtendedUserField | Table | MERGE |
| Customer.ExtendedUserField_History | Table | INSERT + OUTPUT |
| Dictionary.ExtendedUserValueType | Table | LEFT JOIN |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Older callers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic index | Performance | Same per-SPID temp table index as UpdateExtendedUserField |
| MERGE OUTPUT | History logging | Inserts UPDATE actions directly via OUTPUT clause |

---

## 8. Sample Queries

### 8.1 Update extended fields (older TVP)
```sql
DECLARE @fields Customer.ExtendedUserFieldType
INSERT @fields (FieldId, ExtendedFieldType, Value, CountryId, TypeId)
VALUES (6, 3, N'RSSMRA80A01H501U', 106, 'ItalianFiscalCode')
EXEC Customer.UpdateExtendedUserFields @extendedUserFields=@fields, @GCID=12345
```

### 8.2 Compare with newer version
```sql
-- UpdateExtendedUserField: Customer.ExtendedUserField TVP, @ID output, AdditionalDetails support
-- UpdateExtendedUserFields: Customer.ExtendedUserFieldType TVP, no @ID, no AdditionalDetails, OUTPUT clause for history
```

### 8.3 Check history
```sql
SELECT * FROM Customer.ExtendedUserField_History WITH (NOLOCK) WHERE GCID = 12345 ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateExtendedUserFields | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateExtendedUserFields.sql*
