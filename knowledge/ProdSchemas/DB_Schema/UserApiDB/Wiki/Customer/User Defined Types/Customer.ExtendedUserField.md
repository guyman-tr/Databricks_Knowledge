# Customer.ExtendedUserField (UDT)

> Table-valued parameter type for passing batches of extended user field values (tax IDs, national PINs, etc.) to stored procedures.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | User Defined Type (Table Type) |
| **Key Identifier** | FieldId (field identifier column) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.ExtendedUserField is a TVP type for passing multiple extended user field values in a single procedure call. Extended fields are regulation-specific data points (tax IDs, national PINs, employer names) beyond core registration fields. Used by Customer.UpdateExtendedUserFields for batch field updates.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Data transport type.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | FieldId | int | NO | - | CODE-BACKED | Extended field identifier. Maps to Dictionary.ExtendedUserField.FieldId. 0=province, 6=TaxId, 7=NationalPin, etc. |
| 2 | ExtendedFieldType | int | NO | - | CODE-BACKED | Field type category. Maps to Dictionary.ExtendedUserFieldType. 0=Address, 3=Tax ID, 4=NationalPin, etc. |
| 3 | Value | nvarchar(128) | YES | - | CODE-BACKED | The user-provided value for this field (e.g., the actual tax ID number, national PIN). |
| 4 | CountryId | int | YES | - | CODE-BACKED | Country context for this field value. Some fields are country-specific (e.g., tax ID per country). |
| 5 | TypeId | varchar(50) | YES | - | CODE-BACKED | Value subtype identifier. Maps to Dictionary.ExtendedUserValueType for further classification. |
| 6 | AdditionalDetails | varchar(max) | YES | - | CODE-BACKED | JSON or freeform additional data associated with this field entry. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.UpdateExtendedUserFields | Parameter | Parameter Type | TVP for batch extended field updates |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.UpdateExtendedUserFields | Stored Procedure | Uses as READONLY parameter type |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and use for tax ID update
```sql
DECLARE @Fields Customer.ExtendedUserField
INSERT INTO @Fields (FieldId, ExtendedFieldType, Value, CountryId) VALUES (6, 3, '123456789', 44)
EXEC Customer.UpdateExtendedUserFields @GCID = 12345, @Fields = @Fields
```

### 8.2 Multiple fields at once
```sql
DECLARE @Fields Customer.ExtendedUserField
INSERT INTO @Fields VALUES (6, 3, 'TAX123', 44, 'taxUTR', NULL), (7, 4, 'PIN456', 44, 'NationalNumber', NULL)
```

### 8.3 Inspect
```sql
DECLARE @F Customer.ExtendedUserField
INSERT INTO @F (FieldId, ExtendedFieldType, Value) VALUES (6, 3, 'test')
SELECT * FROM @F
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Object: Customer.ExtendedUserField | Type: User Defined Type | Source: UserApiDB/UserApiDB/Customer/User Defined Types/Customer.ExtendedUserField.sql*
