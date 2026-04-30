# Customer.GetExtendedUserField

> Retrieves all extended profile field values for a customer, with full type classification and fast verification data, including tax IDs, national PINs, and Medicare details.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all extended field rows for a GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetExtendedUserField retrieves the complete set of extended profile field values for a customer. Extended fields are regulation-specific data points like tax IDs, national PINs, employer names, and Medicare numbers that vary by country and regulatory requirement. This is the primary read procedure for the extended field system.

This procedure exists because the application needs to display and validate a customer's complete set of regulatory data fields. It is called during profile viewing, KYC validation, compliance checks, and aggregated info retrieval.

The procedure joins Customer.ExtendedUserField (the values), Dictionary.ExtendedUserField (field type metadata), Dictionary.ExtendedUserValueType (value subtype names), and Customer.FastVerificationData (additional fast-verification metadata like Medicare reference numbers and card details). Results are ordered by the ExtendedUserField.ID for consistent presentation.

---

## 2. Business Logic

### 2.1 Tax ID Subtype Name Resolution

**What**: The TypeId column has a dual meaning - for FieldTypeID=3 (tax-related fields), it maps to a named subtype in Dictionary.ExtendedUserValueType. For other field types, the raw TypeId is used as the TaxId label.

**Columns/Parameters Involved**: `TypeId`, `FieldTypeId`, `Dictionary.ExtendedUserValueType`

**Rules**:
- LEFT JOIN to Dictionary.ExtendedUserValueType matches on TypeId = ValueTypeID AND FieldTypeID = 3
- ISNULL(dtyp.Name, euf.TypeId) returns the subtype name when available, or falls back to the raw TypeId integer
- This produces the "TaxId" output column (misleadingly named - it is really the value subtype label)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | int | NO | - | CODE-BACKED | Global Customer ID to retrieve extended fields for. |
| 2 | FieldId (output) | int | NO | - | CODE-BACKED | Extended field type identifier. FK to Dictionary.ExtendedUserField: 0=province, 6=TaxId, 7=NationalPin, etc. See [Extended User Field](_glossary.md#extended-user-field). |
| 3 | FieldTypeId (output) | int | NO | - | CODE-BACKED | Field type category from Dictionary.ExtendedUserField. Determines validation rules and UI behavior. |
| 4 | Value (output) | nvarchar(128) | YES | - | CODE-BACKED | The user-provided field value (e.g., actual tax number, national PIN string). |
| 5 | LastModified (output) | datetime | NO | - | CODE-BACKED | When this field value was last updated. |
| 6 | CountryId (output) | int | YES | - | CODE-BACKED | Country context for this field value. Allows per-country field values. |
| 7 | TaxId (output) | sql_variant | YES | - | CODE-BACKED | Value subtype label: ISNULL(Dictionary.ExtendedUserValueType.Name, TypeId). For FieldTypeID=3, resolves to a named subtype; otherwise the raw TypeId. |
| 8 | AdditionalDetails (output) | varchar(max) | YES | - | CODE-BACKED | JSON or freeform additional data from Customer.ExtendedUserField. |
| 9 | GCID (output) | int | NO | - | CODE-BACKED | Global Customer ID (echoed from input for multi-row correlation). |
| 10 | ExtendedUserValueTypeId (output) | int | YES | - | CODE-BACKED | Fast verification value type from Customer.FastVerificationData. |
| 11 | MedicareReference (output) | varchar | YES | - | CODE-BACKED | Medicare reference number from fast verification data. Australia-specific. |
| 12 | MedicareColor (output) | varchar | YES | - | CODE-BACKED | Medicare card color from fast verification data. Australia-specific. |
| 13 | ExpirationDate (output) | date | YES | - | CODE-BACKED | Document expiration date from fast verification data. |
| 14 | ProvinceId (output) | int | YES | - | CODE-BACKED | Province/state identifier from fast verification data. |
| 15 | CardNumber (output) | varchar | YES | - | CODE-BACKED | Card number from fast verification data (e.g., Medicare card number). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid | Customer.ExtendedUserField | Lookup | Primary field values table |
| FieldId | Dictionary.ExtendedUserField | INNER JOIN | Field type metadata (FieldTypeId) |
| TypeId | Dictionary.ExtendedUserValueType | LEFT JOIN | Value subtype names (for FieldTypeID=3) |
| ID | Customer.FastVerificationData | LEFT JOIN | Fast verification details (Medicare, etc.) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Called to display/validate extended profile fields |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetExtendedUserField (procedure)
+-- Customer.ExtendedUserField (table)
+-- Customer.FastVerificationData (table)
+-- Dictionary.ExtendedUserField (table)
+-- Dictionary.ExtendedUserValueType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ExtendedUserField | Table | FROM - field values |
| Customer.FastVerificationData | Table | LEFT JOIN on ExtendedUserFieldId = ID - fast verification details |
| Dictionary.ExtendedUserField | Table | INNER JOIN on FieldId - field type metadata |
| Dictionary.ExtendedUserValueType | Table | LEFT JOIN on TypeId (WHERE FieldTypeID=3) - value subtype names |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Called directly by application code |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all extended fields for a customer
```sql
EXEC Customer.GetExtendedUserField @Gcid = 12345
```

### 8.2 Direct query with type resolution
```sql
SELECT euf.FieldId, deuf.FieldTypeId, euf.Value, euf.LastModified, euf.CountryId,
       ISNULL(dtyp.Name, euf.TypeId) AS TaxId, euf.AdditionalDetails, euf.GCID,
       cfvd.ExtendedUserValueTypeId, cfvd.MedicareReference, cfvd.MedicareColor,
       cfvd.ExpirationDate, cfvd.ProvinceId, cfvd.CardNumber
FROM Customer.ExtendedUserField euf WITH (NOLOCK)
LEFT JOIN Customer.FastVerificationData cfvd WITH (NOLOCK) ON cfvd.ExtendedUserFieldId = euf.ID
INNER JOIN Dictionary.ExtendedUserField deuf WITH (NOLOCK) ON deuf.FieldId = euf.FieldId
LEFT JOIN Dictionary.ExtendedUserValueType dtyp WITH (NOLOCK) ON euf.TypeId = dtyp.ValueTypeID AND FieldTypeID = 3
WHERE euf.GCID = @Gcid
ORDER BY euf.ID
```

### 8.3 Get only tax ID fields
```sql
SELECT euf.FieldId, euf.Value, ISNULL(dtyp.Name, euf.TypeId) AS TaxIdType
FROM Customer.ExtendedUserField euf WITH (NOLOCK)
INNER JOIN Dictionary.ExtendedUserField deuf WITH (NOLOCK) ON deuf.FieldId = euf.FieldId
LEFT JOIN Dictionary.ExtendedUserValueType dtyp WITH (NOLOCK) ON euf.TypeId = dtyp.ValueTypeID AND deuf.FieldTypeID = 3
WHERE euf.GCID = @Gcid AND euf.FieldId = 6
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 15 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetExtendedUserField | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetExtendedUserField.sql*
