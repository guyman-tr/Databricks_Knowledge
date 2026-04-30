# Customer.GetExtendedUserFields

> Retrieves extended profile field values for a customer with type classification - a simplified version of GetExtendedUserField without fast verification data.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns extended field rows for a GCID (simplified) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.GetExtendedUserFields is a simplified variant of Customer.GetExtendedUserField. It retrieves the same core extended field data (field IDs, values, types, country context) but does NOT include fast verification metadata (Medicare reference, card number, expiration date, etc.). This makes it lighter-weight for callers that only need the field values themselves.

This procedure was originally created in June 2015 and has been updated multiple times to add TaxId and CountryId support. It serves callers that need the regulatory data fields but do not need the detailed verification metadata.

The procedure joins Customer.ExtendedUserField with Dictionary.ExtendedUserField and Dictionary.ExtendedUserValueType, using the same TypeId/FieldTypeID=3 logic for tax ID subtype resolution as GetExtendedUserField.

---

## 2. Business Logic

### 2.1 Tax ID Subtype Name Resolution

**What**: Same as GetExtendedUserField - resolves TypeId to a named subtype for FieldTypeID=3 fields.

**Columns/Parameters Involved**: `TypeId`, `FieldTypeId`, `Dictionary.ExtendedUserValueType`

**Rules**:
- ISNULL(dtyp.Name, euf.TypeId) returns the subtype name or raw TypeId
- Only matches Dictionary.ExtendedUserValueType when FieldTypeID = 3

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | int | NO | - | CODE-BACKED | Global Customer ID to retrieve extended fields for. |
| 2 | FieldId (output) | int | NO | - | CODE-BACKED | Extended field type identifier. FK to Dictionary.ExtendedUserField. See [Extended User Field](_glossary.md#extended-user-field). |
| 3 | FieldTypeId (output) | int | NO | - | CODE-BACKED | Field type category from Dictionary.ExtendedUserField. |
| 4 | Value (output) | nvarchar(128) | YES | - | CODE-BACKED | The user-provided field value (tax number, national PIN, etc.). |
| 5 | LastModified (output) | datetime | NO | - | CODE-BACKED | When this field value was last updated. |
| 6 | CountryId (output) | int | YES | - | CODE-BACKED | Country context for this field value. |
| 7 | TaxId (output) | sql_variant | YES | - | CODE-BACKED | Value subtype label: ISNULL(Dictionary.ExtendedUserValueType.Name, TypeId). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Gcid | Customer.ExtendedUserField | Lookup | Primary field values table |
| FieldId | Dictionary.ExtendedUserField | INNER JOIN | Field type metadata |
| TypeId | Dictionary.ExtendedUserValueType | LEFT JOIN | Value subtype names |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Lightweight extended field retrieval |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.GetExtendedUserFields (procedure)
+-- Customer.ExtendedUserField (table)
+-- Dictionary.ExtendedUserField (table)
+-- Dictionary.ExtendedUserValueType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.ExtendedUserField | Table | FROM - field values |
| Dictionary.ExtendedUserField | Table | INNER JOIN on FieldId - field type metadata |
| Dictionary.ExtendedUserValueType | Table | LEFT JOIN on TypeId (WHERE FieldTypeID=3) - subtype names |

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

### 8.1 Get extended fields (simplified)
```sql
EXEC Customer.GetExtendedUserFields @Gcid = 12345
```

### 8.2 Direct query equivalent
```sql
SELECT euf.FieldId, deuf.FieldTypeId, euf.Value, euf.LastModified, euf.CountryId,
       ISNULL(dtyp.Name, euf.TypeId) AS TaxId
FROM Customer.ExtendedUserField euf WITH (NOLOCK)
INNER JOIN Dictionary.ExtendedUserField deuf WITH (NOLOCK) ON deuf.FieldId = euf.FieldId
LEFT JOIN Dictionary.ExtendedUserValueType dtyp WITH (NOLOCK) ON euf.TypeId = dtyp.ValueTypeID AND FieldTypeID = 3
WHERE euf.GCID = @Gcid
ORDER BY euf.ID
```

### 8.3 Compare with full version
```sql
-- This SP returns 6 columns; GetExtendedUserField returns 15 (includes FastVerificationData)
-- Use this SP when you only need field values, not Medicare/card verification details
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.GetExtendedUserFields | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.GetExtendedUserFields.sql*
