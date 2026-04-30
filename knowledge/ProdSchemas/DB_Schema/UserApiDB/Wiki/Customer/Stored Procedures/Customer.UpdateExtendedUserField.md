# Customer.UpdateExtendedUserField

> MERGE-based upsert for extended user fields with full history tracking - handles country-scoped field replacement, type resolution via Dictionary.ExtendedUserValueType, and returns the new row ID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | MERGE Customer.ExtendedUserField + History logging + OUTPUT @ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateExtendedUserField is the primary write procedure for extended user fields (tax IDs, national PINs, etc.). It uses a MERGE statement to insert new fields or update existing ones, with full history tracking in Customer.ExtendedUserField_History. The procedure handles country-scoped field replacement: when a field has a country context, all existing entries for that GCID+FieldId are first archived to history (with 'Delete' action) and deleted, then the MERGE re-inserts/updates from the input TVP.

The procedure resolves TypeId via Dictionary.ExtendedUserValueType (for FieldTypeID=3 fields), filters out sentinel CountryId=-1 entries, and returns the last inserted ID via SCOPE_IDENTITY().

Called by Customer.SaveFastVerificationDocumentData (which also updates fast verification data).

---

## 2. Business Logic

### 2.1 Country-Scoped Field Replacement

**What**: Fields with non-NULL CountryId are fully replaced (delete all existing + re-insert from TVP).

**Columns/Parameters Involved**: `@extendedUserField` (TVP), `@GCID`, `CountryId`, `FieldId`

**Rules**:
1. Find all existing FieldIds that have country-scoped entries in both the table AND the input TVP
2. Archive those to ExtendedUserField_History with Action='Delete'
3. DELETE those rows from ExtendedUserField
4. MERGE from TVP: NOT MATCHED -> INSERT; MATCHED AND value changed -> UPDATE
5. After MERGE, log the final INSERT to History with Action='INSERT'
6. SET @ID = SCOPE_IDENTITY() (returns the last auto-generated ID)

### 2.2 Type Resolution

**What**: Resolves string TypeId to integer via Dictionary.ExtendedUserValueType.

**Rules**:
- LEFT JOIN Dictionary.ExtendedUserValueType ON Name=TypeId AND FieldTypeID=3
- ISNULL(ValueTypeID, TypeId) - uses the resolved integer ID, falls back to raw TypeId
- CountryId=-1 is a sentinel value meaning "skip this entry" (filtered out)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @extendedUserField | Customer.ExtendedUserField (TVP) | NO | - | CODE-BACKED | Table-valued parameter with fields to upsert: FieldId, ExtendedFieldType, Value, CountryId, TypeId, AdditionalDetails. |
| 2 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 3 | @ID (OUTPUT) | int | YES | NULL | CODE-BACKED | SCOPE_IDENTITY of the last inserted row. Returns the new ExtendedUserField.ID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Customer.ExtendedUserField | MERGE | Upsert field values |
| - | Customer.ExtendedUserField_History | INSERT | Audit trail (Delete + Insert actions) |
| TypeId | Dictionary.ExtendedUserValueType | LEFT JOIN | Type name resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SaveFastVerificationDocumentData | - | EXEC | Called to save extended fields before fast verification data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateExtendedUserField (procedure)
+-- Customer.ExtendedUserField (table)
+-- Customer.ExtendedUserField_History (table)
+-- Dictionary.ExtendedUserValueType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ExtendedUserField | Table | MERGE (upsert) |
| Customer.ExtendedUserField_History | Table | INSERT (audit trail) |
| Dictionary.ExtendedUserValueType | Table | LEFT JOIN (type resolution) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SaveFastVerificationDocumentData | Procedure | EXEC |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dynamic index | Performance | Creates unique clustered index on temp table per SPID |
| MERGE ON | Match key | GCID + FieldId + ISNULL(CountryId, 0) |

---

## 8. Sample Queries

### 8.1 Update extended fields
```sql
DECLARE @fields Customer.ExtendedUserField
INSERT @fields (FieldId, ExtendedFieldType, Value, CountryId, TypeId)
VALUES (6, 3, N'RSSMRA80A01H501U', 106, 'ItalianFiscalCode')
DECLARE @NewID int
EXEC Customer.UpdateExtendedUserField @extendedUserField=@fields, @GCID=12345, @ID=@NewID OUTPUT
SELECT @NewID AS NewFieldID
```

### 8.2 Check history
```sql
SELECT * FROM Customer.ExtendedUserField_History WITH (NOLOCK)
WHERE GCID = 12345 ORDER BY Occurred DESC
```

### 8.3 Read current fields
```sql
EXEC Customer.GetExtendedUserField @Gcid = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateExtendedUserField | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateExtendedUserField.sql*
