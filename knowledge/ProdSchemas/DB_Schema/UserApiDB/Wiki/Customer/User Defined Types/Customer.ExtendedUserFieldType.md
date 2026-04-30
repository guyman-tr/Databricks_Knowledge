# Customer.ExtendedUserFieldType (UDT)

> Table-valued parameter type for passing extended user field entries with type classification, similar to Customer.ExtendedUserField but with NOT NULL Value constraint.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | FieldId (field identifier column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.ExtendedUserFieldType is a TVP type very similar to Customer.ExtendedUserField but with a NOT NULL constraint on the Value column. This variant is used when all field values must be provided (no NULLs allowed), enforcing data completeness at the parameter level. Used in operations that require all field values to be present.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Data transport type with stricter null constraints than Customer.ExtendedUserField.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FieldId | int | NO | - | CODE-BACKED | Extended field identifier. Maps to Dictionary.ExtendedUserField.FieldId. |
| 2 | ExtendedFieldType | int | NO | - | CODE-BACKED | Field type category. Maps to Dictionary.ExtendedUserFieldType. |
| 3 | Value | nvarchar(128) | NO | - | CODE-BACKED | The user-provided value - NOT NULL enforced (all values must be provided). |
| 4 | CountryId | int | YES | - | CODE-BACKED | Country context for this field value. |
| 5 | TypeId | varchar(50) | YES | - | CODE-BACKED | Value subtype identifier. Maps to Dictionary.ExtendedUserValueType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer procedures | Parameter | Parameter Type | TVP for field operations requiring non-null values |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None (NOT NULL on Value enforced by column definition).

---

## 8. Sample Queries

### 8.1 Declare and populate
```sql
DECLARE @Fields Customer.ExtendedUserFieldType
INSERT INTO @Fields (FieldId, ExtendedFieldType, Value) VALUES (6, 3, 'TAX123')
SELECT * FROM @Fields
```

### 8.2 Multiple fields
```sql
DECLARE @Fields Customer.ExtendedUserFieldType
INSERT INTO @Fields VALUES (6, 3, 'TAX123', 44, 'taxUTR'), (7, 4, 'PIN456', 44, 'NationalNumber')
```

### 8.3 Validate non-null requirement
```sql
DECLARE @Fields Customer.ExtendedUserFieldType
-- This will fail: INSERT INTO @Fields (FieldId, ExtendedFieldType, Value) VALUES (6, 3, NULL)
INSERT INTO @Fields (FieldId, ExtendedFieldType, Value) VALUES (6, 3, 'REQUIRED_VALUE')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: Customer.ExtendedUserFieldType | Type: User Defined Type | Source: UserApiDB/UserApiDB/Customer/User Defined Types/Customer.ExtendedUserFieldType.sql*
