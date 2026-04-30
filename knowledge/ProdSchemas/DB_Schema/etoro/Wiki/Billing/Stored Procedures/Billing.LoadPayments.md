# Billing.LoadPayments

> Returns all rows from the Payments table (unqualified/dbo schema reference) - a startup cache loader for the legacy Payments table; the absence of a schema qualifier suggests this is a legacy dbo-schema or synonym-based table.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM Payments (unqualified reference) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadPayments` is a startup cache loader that reads all rows from a table named `Payments` without a schema qualifier. In SQL Server, an unqualified table reference resolves first to the caller's schema (Billing), then to dbo. This suggests `Payments` is either:
- A legacy `dbo.Payments` table (pre-schema-separation era)
- A synonym pointing to another table
- An alias for the `Billing.Payment` table (note: different from `Billing.Deposit` which is the modern equivalent)

The legacy `Billing.Payment` table was the original deposit transaction table before the schema migration to `Billing.Deposit` + `Billing.Funding`. This procedure likely pre-dates the Billing schema reorganization and refers to the original `dbo.Payments` or `Billing.Payment` table that was the predecessor to the current system.

---

## 2. Business Logic

### 2.1 Full Legacy Payments Load

**What**: SELECT * with no filter - returns all rows and all columns from the unqualified `Payments` table.

**Rules**:
- No parameters; no filtering; WITH (NOLOCK)
- Unqualified table name `Payments` (no schema prefix) - resolves to dbo.Payments or current user's default schema
- RETURN 0 signals success
- Legacy procedure; likely not called in modern deployment if the Payments table no longer exists in the expected schema

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from the unqualified `Payments` table (structure depends on which table the unqualified name resolves to; likely the legacy payment transaction table).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Payments (unqualified) | READ | Legacy payments table; no schema qualifier - resolves to dbo.Payments or Billing.Payment via default schema resolution |

### 5.2 Referenced By (other objects point to this)

Called from the legacy billing application startup for payment cache population.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadPayments (procedure)
└── Payments (table - unqualified; likely dbo.Payments or Billing.Payment legacy table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Payments (unqualified) | Table | Legacy payment transaction table; SELECT * returns full contents |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

**Implementation notes**:
- `SET NOCOUNT ON` + `RETURN 0`; `WITH (NOLOCK)`
- Unqualified `Payments` reference: SQL Server resolves to user's schema first (Billing), then dbo; if neither exists, runtime error
- This is the only Load* procedure that references an unqualified table name, indicating legacy origins before the Billing schema was formalized
- Part of the Load* family of startup cache loaders

---

## 8. Sample Queries

### 8.1 Identify what Payments resolves to
```sql
-- Check if Billing.Payments exists
SELECT OBJECT_ID('Billing.Payments')  -- NULL if not found
SELECT OBJECT_ID('dbo.Payments')      -- Check dbo schema
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 6.5/10 (Elements: 6/10, Logic: 7/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadPayments | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadPayments.sql*
