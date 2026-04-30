# Customer.ConvertToaIdToMamcId

> Scalar function that converts a Transfer of Account (TOA) ID from a partner platform into an internal MAMC identifier using MD5 hashing.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns varchar(300) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.ConvertToaIdToMamcId is a deterministic scalar function that converts an external TOA (Transfer of Account) identifier from a Chinese partner platform into an internal MAMC (Mobile App Marketing Campaign) identifier. The conversion pads the input to 64 characters, computes an MD5 hash, and prepends 'M15' to create a standardized internal identifier.

This function is used when storing TOA details in Customer.ToaDetails_Lead and Customer.ToaDetails_Registration to generate the MamcId column value from the external ToaId.

---

## 2. Business Logic

### 2.1 ID Conversion Algorithm

**What**: Deterministic conversion from external TOA ID to internal MAMC ID.

**Columns/Parameters Involved**: `@ToaId` (input), return value

**Rules**:
- Input is right-padded with zeros to 64 characters
- MD5 hash is computed on the padded input
- Hash is converted to hexadecimal string (32 chars)
- 'M15' prefix is prepended
- Result format: `M15{32-char-hex-hash}` (35 chars total)
- Deterministic: same input always produces same output

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ToaId | varchar(300) | NO (param) | - | CODE-BACKED | Input: the external Transfer of Account identifier from the partner platform. |
| 2 | RETURN | varchar(300) | NO | - | CODE-BACKED | Output: internal MAMC identifier in format 'M15' + MD5 hex hash (35 chars). |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (pure computation, no table access).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| TOA insert procedures | MamcId derivation | Function call | Generates MamcId from ToaId |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.InsertToaLeadDetails | Stored Procedure | Calls to generate MamcId |
| Customer.InsertToaRegistrationDetails | Stored Procedure | Calls to generate MamcId |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Convert a ToaId
```sql
SELECT Customer.ConvertToaIdToMamcId('12345') AS MamcId
```

### 8.2 Verify conversion consistency
```sql
SELECT Customer.ConvertToaIdToMamcId('ABC123') AS Result1, Customer.ConvertToaIdToMamcId('ABC123') AS Result2
```

### 8.3 Use with TOA tables
```sql
SELECT ToaId, Customer.ConvertToaIdToMamcId(ToaId) AS ComputedMamcId, MamcId AS StoredMamcId
FROM Customer.ToaDetails_Lead WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Object: Customer.ConvertToaIdToMamcId | Type: Scalar Function | Source: UserApiDB/UserApiDB/Customer/Functions/Customer.ConvertToaIdToMamcId.sql*
