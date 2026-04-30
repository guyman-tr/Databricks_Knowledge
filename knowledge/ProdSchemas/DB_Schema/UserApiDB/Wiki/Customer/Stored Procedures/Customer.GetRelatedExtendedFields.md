# Customer.GetRelatedExtendedFields

> Finds all customers who have the same value for a specific extended field (e.g., same tax ID or national PIN) - fraud/compliance duplicate detection.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns GCID, FieldId, Value for matching records |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetRelatedExtendedFields finds all customers who share the same value for a given extended field type. For example, finding all customers with the same tax ID or national PIN number. This is a simpler version of GetCustomersWithSameExtendedField/GetCustomersWithSameSSN that does not filter by verification level, player status, or country.

This procedure supports compliance teams who need a broad view of all accounts sharing a specific document value, regardless of account status.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple exact match on FieldId + Value.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @fieldId | int | NO | - | CODE-BACKED | Extended field type to search. FK to Dictionary.ExtendedUserField (6=TaxId, 7=NationalPin, etc.). |
| 2 | @fieldValue | nvarchar(max) | NO | - | CODE-BACKED | The value to search for exact matches. |
| 3 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID of matching customer. |
| 4 | FieldId (output) | int | NO | - | CODE-BACKED | The extended field type ID (echoed). |
| 5 | Value (output) | nvarchar(128) | YES | - | CODE-BACKED | The field value (echoed, confirms match). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @fieldId, @fieldValue | Customer.ExtendedUserField | Lookup | Exact match search |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Compliance duplicate field search |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetRelatedExtendedFields (procedure)
+-- Customer.ExtendedUserField (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ExtendedUserField | Table | FROM - field value matching |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called by application |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find customers with same tax ID
```sql
EXEC Customer.GetRelatedExtendedFields @fieldId = 6, @fieldValue = N'RSSMRA80A01H501U'
```

### 8.2 Find customers with same national PIN
```sql
EXEC Customer.GetRelatedExtendedFields @fieldId = 7, @fieldValue = N'123456789'
```

### 8.3 Direct query equivalent
```sql
SELECT GCID, FieldId, Value
FROM Customer.ExtendedUserField WITH (NOLOCK)
WHERE FieldId = @fieldId AND Value = @fieldValue
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetRelatedExtendedFields | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetRelatedExtendedFields.sql*
