# Customer.SaveFastVerificationDocumentData

> Saves fast verification document data (Medicare, card details) in a transaction - first updates the extended user field via UpdateExtendedUserField, then replaces the FastVerificationData record for the customer.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Transaction: EXEC UpdateExtendedUserField + DELETE/INSERT FastVerificationData |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SaveFastVerificationDocumentData saves fast-track verification document data (e.g., Australian Medicare card details) for a customer. This procedure orchestrates two operations in a single transaction: (1) upserts the extended user field value via Customer.UpdateExtendedUserField (which handles the field value and history), then (2) replaces the fast verification metadata (Medicare reference, card color, expiration, province, card number) in Customer.FastVerificationData.

The procedure links the FastVerificationData record to the ExtendedUserField record via the @ID output from UpdateExtendedUserField (stored as ExtendedUserFieldId).

---

## 2. Business Logic

### 2.1 Transactional Replace Pattern

**What**: Atomic replacement of fast verification data linked to extended fields.

**Columns/Parameters Involved**: `@GCID`, `@extendedUserField` (TVP), `@ExtendedUserValueTypeId`, Medicare/card fields

**Rules**:
1. BEGIN TRANSACTION
2. If existing FastVerificationData exists for @GCID: DELETE it
3. EXEC Customer.UpdateExtendedUserField with the TVP -> gets @ID (new ExtendedUserField row)
4. INSERT into FastVerificationData using @ID as ExtendedUserFieldId, with Value from the TVP
5. COMMIT TRANSACTION
- The entire operation is atomic - if UpdateExtendedUserField fails, FastVerificationData is not modified

### 2.2 ExtendedUserField Linkage

**What**: FastVerificationData.ExtendedUserFieldId points to the newly created/updated ExtendedUserField.ID.

**Rules**:
- @ID comes from SCOPE_IDENTITY() inside UpdateExtendedUserField
- The INSERT into FastVerificationData uses this @ID to establish the FK relationship
- Value column is read from the TVP (@extendedUserField) to store the field value alongside the metadata

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @ExtendedUserValueTypeId | int | NO | - | CODE-BACKED | Fast verification value type. FK to Dictionary.ExtendedUserValueType. |
| 3 | @MedicareReference | nvarchar(1) | YES | NULL | CODE-BACKED | Medicare reference character (Australia-specific). Single char. |
| 4 | @MedicareColor | nvarchar(10) | YES | NULL | CODE-BACKED | Medicare card color (e.g., 'Green', 'Blue', 'Yellow'). Australia-specific. |
| 5 | @ExpirationDate | nvarchar(7) | YES | NULL | CODE-BACKED | Document expiration in short format (e.g., '2026-12'). Stored as string, not date type. |
| 6 | @ProvinceId | int | YES | NULL | CODE-BACKED | Province/state identifier for the document. |
| 7 | @CardNumber | nvarchar(30) | YES | NULL | CODE-BACKED | Card number (e.g., Medicare card number). |
| 8 | @extendedUserField | Customer.ExtendedUserField (TVP) | NO | - | CODE-BACKED | Extended field data to save via UpdateExtendedUserField. Contains FieldId, Value, CountryId, TypeId, etc. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @extendedUserField, @GCID | Customer.UpdateExtendedUserField | EXEC | Upserts the extended field value, returns @ID |
| @GCID | Customer.FastVerificationData | DELETE + INSERT | Replaces fast verification metadata |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Fast verification document upload |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SaveFastVerificationDocumentData (procedure)
+-- Customer.UpdateExtendedUserField (procedure) [done]
    +-- Customer.ExtendedUserField (table) [done]
    +-- Customer.ExtendedUserField_History (table) [done]
    +-- Dictionary.ExtendedUserValueType (table) [done]
+-- Customer.FastVerificationData (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.UpdateExtendedUserField | Procedure | EXEC - field value upsert |
| Customer.FastVerificationData | Table | DELETE + INSERT - verification metadata |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Fast verification service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BEGIN/COMMIT TRANSACTION | Atomicity | Ensures field update and metadata save are atomic |

---

## 8. Sample Queries

### 8.1 Save Medicare verification data
```sql
DECLARE @fields Customer.ExtendedUserField
INSERT @fields (FieldId, ExtendedFieldType, Value, CountryId, TypeId)
VALUES (7, 3, N'1234567890', 13, 'Medicare')  -- Australia, NationalPin
EXEC Customer.SaveFastVerificationDocumentData
    @GCID=12345,
    @ExtendedUserValueTypeId=1,
    @MedicareReference=N'1',
    @MedicareColor=N'Green',
    @ExpirationDate=N'2028-06',
    @CardNumber=N'1234 56789 0',
    @extendedUserField=@fields
```

### 8.2 Read back via getter
```sql
EXEC Customer.GetExtendedUserField @Gcid = 12345
-- Returns field values with FastVerificationData columns joined
```

### 8.3 Check FastVerificationData directly
```sql
SELECT * FROM Customer.FastVerificationData WITH (NOLOCK) WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.6/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.SaveFastVerificationDocumentData | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.SaveFastVerificationDocumentData.sql*
