# Billing.LoadAccountUpdateTypes

> Returns all rows from the Dictionary.AccountUpdateType reference table - a startup cache loader for account update type definitions used in billing account management.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM Dictionary.AccountUpdateType |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadAccountUpdateTypes` is a reference data loader that returns the complete contents of the account update type dictionary. It is called by the billing application at startup (or on demand) to populate an in-memory cache of account update type definitions, enabling the application to map AccountUpdateTypeID values to their display names and business meanings without repeated database queries.

AccountUpdateType is a small, low-change reference table listing the categories of account updates that can be applied in the billing domain (e.g., address changes, contact updates, KYC status changes). By loading this data once at startup, the billing service avoids repeated lookups during request processing.

**Note**: The DDL contains a typo - `Dictioanry.AccountUpdateType` (letters `i` and `o` transposed in "Dictionary"). If this procedure is called as written, it would fail with "Invalid object name 'Dictioanry.AccountUpdateType'". This appears to be a legacy DDL bug; the procedure may have been superseded or may not be actively called.

---

## 2. Business Logic

### 2.1 Full Reference Table Load

**What**: SELECT * with no filter - returns all rows and all columns from the account update type dictionary.

**Columns/Parameters Involved**: All columns of Dictionary.AccountUpdateType

**Rules**:
- No parameters; no filtering; returns entire table
- No WITH (NOLOCK) hint in the DDL (minor: not a concern for a tiny reference table)
- RETURN 0 signals success to callers that check the return code
- **BUG in DDL**: Schema name is `Dictioanry` (typo) instead of `Dictionary`; this will cause a runtime error if executed as-is

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from `Dictionary.AccountUpdateType` (exact columns derivable from the Dictionary schema DDL). Typically includes AccountUpdateTypeID (PK), AccountUpdateTypeName (display label), and potentially status/flag columns.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Dictionary.AccountUpdateType | READ | Returns full table; DDL contains typo `Dictioanry.AccountUpdateType` - runtime error if called |

### 5.2 Referenced By (other objects point to this)

Called from the billing application at startup for reference data cache population.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadAccountUpdateTypes (procedure)
└── Dictionary.AccountUpdateType (table - intended source; DDL has schema name typo)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.AccountUpdateType | Table | Intended SELECT source; DDL typo (`Dictioanry`) would cause runtime failure |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- `SET NOCOUNT ON` suppresses row-count messages
- `RETURN 0` signals success
- **Critical bug**: `Dictioanry` is a typo for `Dictionary` - the procedure will throw "Invalid object name 'Dictioanry.AccountUpdateType'" at runtime
- No WITH (NOLOCK) hint (acceptable for a tiny, rarely-written reference table)
- Part of the Load* family of startup cache loaders (LoadActiveBonuses, LoadBonuses, LoadCreditCards, etc.)

---

## 8. Sample Queries

### 8.1 View account update type definitions directly
```sql
-- Use direct query as workaround for DDL typo in LoadAccountUpdateTypes
SELECT *
FROM Dictionary.AccountUpdateType WITH (NOLOCK)
ORDER BY AccountUpdateTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 6.5/10 (Elements: 6/10, Logic: 7/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadAccountUpdateTypes | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadAccountUpdateTypes.sql*
