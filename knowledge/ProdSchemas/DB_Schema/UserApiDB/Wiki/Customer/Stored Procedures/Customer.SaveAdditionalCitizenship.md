# Customer.SaveAdditionalCitizenship

> Upserts (INSERT or UPDATE) a customer's additional citizenship country - stores a secondary nationality for regulatory compliance.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPSERT on Customer.AdditionalCitizenship by GCID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SaveAdditionalCitizenship stores or updates a customer's additional citizenship (secondary nationality). Some regulations require disclosure of dual/multiple citizenships. The procedure uses an UPSERT pattern: if a record exists for the GCID, it updates the CountryID; otherwise it inserts a new row.

---

## 2. Business Logic

### 2.1 UPSERT Pattern

**What**: IF EXISTS then UPDATE, else INSERT.

**Rules**:
- Checks if GCID already has an AdditionalCitizenship record
- EXISTS: UPDATE CountryID to the new value
- NOT EXISTS: INSERT new row with GCID + CountryID
- Only stores ONE additional citizenship per customer (GCID is unique)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @CountryID | int | NO | - | CODE-BACKED | Country of additional citizenship. FK to Dictionary.Country. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID, @CountryID | Customer.AdditionalCitizenship | UPSERT | Citizenship storage |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | KYC/compliance citizenship update |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SaveAdditionalCitizenship (procedure)
+-- Customer.AdditionalCitizenship (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.AdditionalCitizenship | Table | UPSERT |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | KYC service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Save additional citizenship
```sql
EXEC Customer.SaveAdditionalCitizenship @GCID = 12345, @CountryID = 106 -- Italy
```

### 8.2 Verify
```sql
SELECT * FROM Customer.AdditionalCitizenship WITH (NOLOCK) WHERE GCID = 12345
```

### 8.3 Read back
```sql
EXEC Customer.GetAdditionalCitizenship @GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.SaveAdditionalCitizenship | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.SaveAdditionalCitizenship.sql*
