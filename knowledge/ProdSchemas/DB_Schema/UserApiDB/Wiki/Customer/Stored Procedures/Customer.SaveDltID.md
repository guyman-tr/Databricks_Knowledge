# Customer.SaveDltID

> Saves a DLT (blockchain) wallet ID for a customer with validation - checks user exists and does not already have a different DLT ID assigned.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPDATE Customer.CustomerIdentification SET DltID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.SaveDltID associates a DLT (Distributed Ledger Technology / blockchain) wallet identifier with a customer's account. This is called when a customer sets up a crypto wallet for the first time. The procedure includes validation: it checks the user exists and prevents overwriting an existing DLT ID with a different one (security safeguard against wallet reassignment).

On success, sets DltStatusID to 1 (Pending) and UpdateDate to GETUTCDATE().

---

## 2. Business Logic

### 2.1 DLT ID Assignment Validation

**What**: Prevents unauthorized wallet reassignment.

**Columns/Parameters Involved**: `@GCID`, `@DltID`, `DltID`, `DltStatusID`

**Rules**:
- If GCID not found in CustomerIdentification: RAISERROR 'User does not exist'
- If user already has a DIFFERENT DltID: RAISERROR 'User already has another DltID'
- If user has no DltID OR same DltID: UPDATE with new DltID, set DltStatusID=1 (Pending), UpdateDate=GETUTCDATE()
- Allows re-saving the same DltID (idempotent for same value)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @GCID | int | NO | - | CODE-BACKED | Global Customer ID. |
| 2 | @DltID | uniqueidentifier | NO | - | CODE-BACKED | DLT wallet identifier (GUID format). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @GCID | Customer.CustomerIdentification | UPDATE | Sets DltID, DltStatusID, UpdateDate |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Application layer) | - | Direct call | Crypto wallet setup |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SaveDltID (procedure)
+-- Customer.CustomerIdentification (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerIdentification | Table | SELECT + UPDATE |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in SSDT) | - | Crypto service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RAISERROR | Validation | User must exist in CustomerIdentification |
| RAISERROR | Validation | Cannot overwrite existing DltID with a different value |

---

## 8. Sample Queries

### 8.1 Save DLT ID
```sql
EXEC Customer.SaveDltID @GCID=12345, @DltID='A1B2C3D4-E5F6-7890-ABCD-EF1234567890'
```

### 8.2 Verify
```sql
SELECT DltID, DltStatusID, UpdateDate
FROM Customer.CustomerIdentification WITH (NOLOCK)
WHERE GCID = 12345
```

### 8.3 Read via getter
```sql
EXEC Customer.GetDltData @GCID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Object: Customer.SaveDltID | Type: Stored Procedure | Source: UserApiDB/UserApiDB/Customer/Stored Procedures/Customer.SaveDltID.sql*
