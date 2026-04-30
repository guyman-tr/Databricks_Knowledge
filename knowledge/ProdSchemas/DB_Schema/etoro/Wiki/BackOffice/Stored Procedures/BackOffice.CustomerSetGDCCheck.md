# BackOffice.CustomerSetGDCCheck

> Updates GDCCheckID on BackOffice.Customer for a given CID. Minimal SP - no validation, no error handling.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure sets the GDC (Global Data Check) status for a customer by updating `BackOffice.Customer.GDCCheckID`. GDC checks are data quality or identity verification checks against global databases - used to verify customer identity information against external data sources as part of the KYC/AML process.

`GDCCheckID` records the outcome or state of the global data check: whether it has been performed, what the result was, or what action is needed. The specific values are defined elsewhere (not validated here - no dictionary lookup is performed).

This is one of the most minimal SPs in the schema: no validation, no error handling, no NOCOUNT, no explicit transaction.

---

## 2. Business Logic

### 2.1 Bare Update

**What**: Direct UPDATE with no guards.

**Rules**:
- UPDATE BackOffice.Customer SET GDCCheckID=@GDCCheckID WHERE CID=@CID
- No SET NOCOUNT: row count message IS returned to caller (0 or 1)
- No validation of GDCCheckID value
- No CID existence check: silent no-op if not found
- No TRY/CATCH: SQL errors propagate unhandled

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID. No existence check - silent no-op if not found. |
| 2 | @GDCCheckID | INT | NO | - | CODE-BACKED | New GDC check status/outcome to record. No dictionary validation. Written to BackOffice.Customer.GDCCheckID. |

**Return Value**: No explicit RETURN. Row count message returned (1 row affected on success, 0 if CID not found).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | UPDATE | Sets GDCCheckID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice GDC/KYC verification workflows | External | Direct call | Record GDC check results for a customer |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetGDCCheck (procedure)
|- BackOffice.Customer (table) [UPDATE: GDCCheckID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE: GDCCheckID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| GDC verification workflow | External | Record global data check outcome |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No NOCOUNT | Design | Row count message IS sent to caller (unlike most other SPs in this schema) |
| No error handling | Design | SQL errors propagate unhandled |
| No validation | Design | @GDCCheckID not validated against any dictionary |

---

## 8. Sample Queries

### 8.1 Record a GDC check result

```sql
EXEC BackOffice.CustomerSetGDCCheck
    @CID = 12345,
    @GDCCheckID = 2;
```

### 8.2 Check current GDC status

```sql
SELECT CID, GDCCheckID
FROM BackOffice.Customer WITH (NOLOCK)
WHERE CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.6/10 (Elements: 8/10, Logic: 8/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: not searched (BackOffice schema) | Corrections: 0 applied*
*Object: BackOffice.CustomerSetGDCCheck | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetGDCCheck.sql*
