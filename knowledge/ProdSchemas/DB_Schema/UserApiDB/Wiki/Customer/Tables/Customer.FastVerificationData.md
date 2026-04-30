# Customer.FastVerificationData

> Stores pre-populated identity document data for fast electronic verification, including document numbers, Medicare details, and expiration dates. System-versioned for temporal history.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Table |
| **Key Identifier** | GCID (INT, PK NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 (PK + NC on ExtendedUserFieldId) |

---

## 1. Business Meaning

Customer.FastVerificationData stores pre-collected identity document data that enables faster electronic verification. When a user provides document details (national ID number, passport, Medicare card, etc.), this data is stored here and used to pre-populate EV provider requests. This reduces verification friction and improves match rates with data sources.

The table uses system versioning (temporal) with History.FastVerificationData as the history table, providing automatic audit trail of document data changes.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Australia-specific Medicare fields (MedicareReference, MedicareColor) suggest this table is particularly relevant for ASIC-regulated users.

---

## 3. Data Overview

N/A - transactional table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | GCID | int | NO | - | CODE-BACKED | Primary key. Global Customer ID. One row per user. |
| 2 | ExtendedUserValueTypeId | int | NO | - | CODE-BACKED | FK to Dictionary.ExtendedUserValueType. The specific document type (e.g., NationalNumber, PassportNumber, Medicare). See [Extended User Value Type](_glossary.md#extended-user-value-type). |
| 3 | ExtendedUserFieldId | int | NO | - | CODE-BACKED | The extended field this data belongs to. Maps to Dictionary.ExtendedUserField. Indexed. |
| 4 | Value | nvarchar(128) | NO | - | CODE-BACKED | The actual document number (e.g., national ID number, passport number). |
| 5 | MedicareReference | nvarchar(2) | YES | - | CODE-BACKED | Medicare card reference number (Australia-specific). 1-2 character reference identifying the individual on a family Medicare card. |
| 6 | MedicareColor | nvarchar(10) | YES | - | CODE-BACKED | Medicare card color (Australia-specific): Green (resident), Blue (temporary), Yellow (reciprocal). |
| 7 | ExpirationDate | nvarchar(7) | YES | - | CODE-BACKED | Document expiration date in compact format (e.g., "2025-12" or "12/2025"). |
| 8 | ProvinceId | int | YES | - | CODE-BACKED | Province/state of document issuance. |
| 9 | BeginTime | datetime2(7) | NO | - | CODE-BACKED | System versioning row start (GENERATED ALWAYS AS ROW START). |
| 10 | EndTime | datetime2(7) | NO | - | CODE-BACKED | System versioning row end (GENERATED ALWAYS AS ROW END). |
| 11 | CardNumber | nvarchar(30) | YES | - | CODE-BACKED | Card number for document types that have a separate card number (e.g., Medicare card number distinct from reference). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExtendedUserValueTypeId | Dictionary.ExtendedUserValueType | Explicit FK | Document subtype classification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.FastVerificationData | - | System Versioning | Temporal history |
| Customer.SaveFastVerificationDocumentData | GCID | SP writes | Saves document data |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.FastVerificationData (table)
  +-- Dictionary.ExtendedUserValueType (table) [done]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ExtendedUserValueType | Table | FK: ExtendedUserValueTypeId -> ValueTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.FastVerificationData | Table | System versioning history |
| Customer.SaveFastVerificationDocumentData | Stored Procedure | Writes to |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Customer_FastVerificationData | NONCLUSTERED PK | GCID | - | - | Active |
| ix_FastVerificationData_ExtendedUserFieldId | NONCLUSTERED | ExtendedUserFieldId | ExtendedUserValueTypeId, MedicareReference, MedicareColor, ExpirationDate, ProvinceId, CardNumber | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_FastVerificationData_ExtendedUserValueTypeId | FOREIGN KEY | ExtendedUserValueTypeId -> Dictionary.ExtendedUserValueType(ValueTypeID) |
| SYSTEM_VERSIONING | Temporal | History table: History.FastVerificationData |

---

## 8. Sample Queries

### 8.1 Get fast verification data for a user
```sql
SELECT fv.GCID, vt.Name AS DocumentType, fv.Value, fv.ExpirationDate, fv.MedicareColor
FROM Customer.FastVerificationData fv WITH (NOLOCK)
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON fv.ExtendedUserValueTypeId = vt.ValueTypeID
WHERE fv.GCID = @GCID
```

### 8.2 Find users with Medicare data
```sql
SELECT GCID, MedicareReference, MedicareColor, ExpirationDate
FROM Customer.FastVerificationData WITH (NOLOCK)
WHERE MedicareColor IS NOT NULL
```

### 8.3 Document data change history (temporal)
```sql
SELECT fv.GCID, vt.Name, fv.Value, fv.BeginTime, fv.EndTime
FROM Customer.FastVerificationData FOR SYSTEM_TIME ALL fv
JOIN Dictionary.ExtendedUserValueType vt WITH (NOLOCK) ON fv.ExtendedUserValueTypeId = vt.ValueTypeID
WHERE fv.GCID = @GCID ORDER BY fv.BeginTime
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Object: Customer.FastVerificationData | Type: Table | Source: UserApiDB/UserApiDB/Customer/Tables/Customer.FastVerificationData.sql*
