# Customer.UpdateEtoroDltID

> Updates the DLT ID in the legacy dbo customer static table via dbo.Real_UpdateCustomerStaticDltID.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | EXEC dbo.Real_UpdateCustomerStaticDltID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.UpdateEtoroDltID updates the DLT wallet ID in the legacy dbo customer static table. This is a pass-through to dbo.Real_UpdateCustomerStaticDltID. Compare with Customer.SaveDltID which updates Customer.CustomerIdentification (new schema) with validation.

---

## 2. Business Logic

No complex logic. Pass-through to legacy procedure.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @DltID | uniqueidentifier | YES | NULL | CODE-BACKED | DLT wallet GUID. NULL to clear. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | dbo.Real_UpdateCustomerStaticDltID | EXEC | Legacy DLT update |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Legacy DLT management |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.UpdateEtoroDltID (procedure)
+-- dbo.Real_UpdateCustomerStaticDltID (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.Real_UpdateCustomerStaticDltID | Procedure | EXEC |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Legacy DLT service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Update DLT ID (legacy)
```sql
EXEC Customer.UpdateEtoroDltID @GCID=12345, @DltID='A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
```

### 8.2 Prefer new version
```sql
-- Use Customer.SaveDltID for new development (updates Customer schema with validation)
```

### 8.3 Clear DLT ID
```sql
EXEC Customer.UpdateEtoroDltID @GCID=12345, @DltID=NULL
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.UpdateEtoroDltID | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.UpdateEtoroDltID.sql*
