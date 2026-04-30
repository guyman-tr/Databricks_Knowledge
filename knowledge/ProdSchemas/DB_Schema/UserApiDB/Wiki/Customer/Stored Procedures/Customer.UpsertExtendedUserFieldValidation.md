# Customer.UpsertExtendedUserFieldValidation

> MERGE-based upsert for extended user field validation status - records whether a specific field value for a customer in a country has passed validation.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | MERGE on Customer.ExtendedUserFieldValidation (GCID + FieldID + CountryID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpsertExtendedUserFieldValidation records whether a customer's extended field value (tax ID, national PIN, etc.) has passed validation for a specific country. The MERGE pattern ensures one validation record per GCID + FieldID + CountryID combination. When the validation service checks a field value, this procedure stores the result (IsValid = 1/0).

The OUTPUT clause returns the action taken ('INSERT' or 'UPDATE') so the caller knows whether this was a new validation or an update to an existing one.

---

## 2. Business Logic

### 2.1 MERGE Upsert with Action Output

**What**: Single-row MERGE on composite key.

**Columns/Parameters Involved**: `@GCID`, `@FieldID`, `@CountryID`, `@IsValid`

**Rules**:
- Match key: Target.GCID = @GCID AND Target.CountryID = @CountryID AND Target.FieldID = @FieldID
- MATCHED: UPDATE SET IsValid = @IsValid
- NOT MATCHED: INSERT (GCID, CountryID, FieldID, IsValid)
- OUTPUT $action returns 'INSERT' or 'UPDATE'

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @FieldID | int | NO | - | CODE-BACKED | Extended field type. FK to Dictionary.ExtendedUserField (6=TaxId, 7=NationalPin, etc.). |
| 3 | @CountryID | int | NO | - | CODE-BACKED | Country context for the validation. |
| 4 | @IsValid | bit | NO | - | CODE-BACKED | Validation result: 1=passed, 0=failed. |
| 5 | (output) | varchar | - | - | CODE-BACKED | $action - 'INSERT' or 'UPDATE' indicating what the MERGE did. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Customer.ExtendedUserFieldValidation | MERGE | Validation status storage |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Field validation service |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpsertExtendedUserFieldValidation (procedure)
+-- Customer.ExtendedUserFieldValidation (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ExtendedUserFieldValidation | Table | MERGE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Validation service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Record validation result
```sql
EXEC Customer.UpsertExtendedUserFieldValidation @GCID=12345, @FieldID=6, @CountryID=106, @IsValid=1
-- Returns 'INSERT' or 'UPDATE'
```

### 8.2 Mark field as invalid
```sql
EXEC Customer.UpsertExtendedUserFieldValidation @GCID=12345, @FieldID=7, @CountryID=234, @IsValid=0
```

### 8.3 Check validation status
```sql
SELECT * FROM Customer.ExtendedUserFieldValidation WITH (NOLOCK)
WHERE GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpsertExtendedUserFieldValidation | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpsertExtendedUserFieldValidation.sql*
