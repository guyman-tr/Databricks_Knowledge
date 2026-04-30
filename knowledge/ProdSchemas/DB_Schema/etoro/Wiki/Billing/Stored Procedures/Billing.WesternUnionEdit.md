# Billing.WesternUnionEdit

> Updates the country, MTCN (Money Transfer Control Number), and city fields on a Billing.WesternUnionToPayment record by WesternUnionID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @WesternUnionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.WesternUnionEdit` updates the payment details for a Western Union payment record in `Billing.WesternUnionToPayment`. The MTCN (Money Transfer Control Number) is the unique tracking reference issued by Western Union for each cash transfer, which operators enter after a payment has been confirmed. This procedure allows Back Office operators to record or correct the MTCN, country, and city for a pending or processed WU payment.

Created by Geri Reshef, 25/08/2015 (Case 28292 - VARCHAR to NVARCHAR migration for City field).

---

## 2. Business Logic

### 2.1 Direct Field Update

**What**: Overwrites CountryID, MTCN, and City for the specified WesternUnionID.

**Rules**:
- Single UPDATE: `Billing.WesternUnionToPayment SET CountryID=@CountryID, MTCN=@MTCN, City=@City WHERE WesternUnionID=@WesternUnionID`
- No existence check; if @WesternUnionID does not exist, UPDATE silently affects 0 rows
- `RETURN @@ERROR` - legacy pattern; returns 0 on success, non-zero SQL error code on failure
- No history logging, no transaction wrapper, no TRY/CATCH

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @WesternUnionID | INTEGER | NO | - | CODE-BACKED | PK of `Billing.WesternUnionToPayment`. Identifies the WU payment record to update. |
| 2 | @CountryID | INTEGER | NO | - | CODE-BACKED | Country where the payment was sent. FK to Dictionary.Country. |
| 3 | @MTCN | VARCHAR(15) | NO | - | CODE-BACKED | Money Transfer Control Number - Western Union's unique tracking reference for the cash transfer. 10 digits for most transfers. |
| 4 | @City | NVARCHAR(50) | NO | - | CODE-BACKED | City associated with the Western Union transfer (sender or receiver city). NVARCHAR to support non-Latin characters. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @WesternUnionID | Billing.WesternUnionToPayment | UPDATE | Updates payment details on the WU record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Back Office (application) | WU payment management | Application call | Operators record MTCN and payment details after WU transfer confirmation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.WesternUnionEdit (procedure)
+-- Billing.WesternUnionToPayment (table) [UPDATE]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.WesternUnionToPayment | Table | UPDATE target: sets CountryID, MTCN, City by WesternUnionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Back Office (application) | Application | Called by BO operators to record/correct WU payment details |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No existence check | Design | 0-row update if @WesternUnionID not found; no error raised |
| RETURN @@ERROR | Legacy | Legacy error handling pattern; returns SQL error code (0 = success). Callers should check return value. |
| No history logging | Design | No INSERT to History.WesternUnionToPayment or equivalent - changes are not audited |

---

## 8. Sample Queries

### 8.1 Record MTCN for a Western Union payment
```sql
EXEC Billing.WesternUnionEdit
    @WesternUnionID = 1234,
    @CountryID      = 184,       -- United Kingdom
    @MTCN           = '1234567890',
    @City           = N'London';
```

### 8.2 Verify update
```sql
SELECT WesternUnionID, CountryID, MTCN, City
FROM Billing.WesternUnionToPayment WITH (NOLOCK)
WHERE WesternUnionID = 1234;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: skipped (no Billing repos) | Corrections: 0 applied*
*Object: Billing.WesternUnionEdit | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.WesternUnionEdit.sql*
