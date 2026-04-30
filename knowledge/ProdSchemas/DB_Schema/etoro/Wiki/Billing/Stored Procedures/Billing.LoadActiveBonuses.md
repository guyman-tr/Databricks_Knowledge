# Billing.LoadActiveBonuses

> Returns all active bonus type definitions from BackOffice.BonusType (WHERE IsActive=1) - a startup cache loader for active bonus configurations available in the billing payment flow.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM BackOffice.BonusType WHERE IsActive=1 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadActiveBonuses` is a filtered reference data loader that returns only the currently active bonus type definitions from the BackOffice schema. The billing service calls this at startup (or on cache refresh) to populate the list of bonus types that can be applied to customer deposits or payments. By filtering to `IsActive=1`, the billing layer only caches bonus types that are currently enabled for use, preventing expired or decommissioned bonus types from being offered or processed.

The distinction between `LoadActiveBonuses` (IsActive=1 filter) and `LoadBonuses` (no filter, all bonus types) allows callers to choose between the current active set (for payment processing) and the full historical set (for reporting and reconciliation of past bonus applications).

---

## 2. Business Logic

### 2.1 Active Bonus Filter

**What**: Returns all columns of BackOffice.BonusType for rows where IsActive=1 only.

**Columns/Parameters Involved**: `IsActive`

**Rules**:
- No parameters; single WHERE filter: `IsActive = 1`
- WITH (NOLOCK) for non-blocking reads
- RETURN 0 signals success
- All columns returned (SELECT *) - callers receive full bonus type definition including name, description, and configuration fields

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from `BackOffice.BonusType` WHERE IsActive=1 (cross-schema table; exact columns from BackOffice schema DDL). Typically includes BonusTypeID, BonusTypeName, IsActive flag, and bonus configuration parameters.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | BackOffice.BonusType | READ | Returns only active bonus types (IsActive=1); cross-schema read from BackOffice |

### 5.2 Referenced By (other objects point to this)

Called from the billing application at startup for active bonus type cache population.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadActiveBonuses (procedure)
└── BackOffice.BonusType (cross-schema table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BonusType | Table | Source of active bonus definitions; filtered by IsActive=1 |

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
- `WITH (NOLOCK)` prevents blocking on BackOffice.BonusType
- Complement to `Billing.LoadBonuses` (all bonus types, no filter)
- Part of the Load* family of startup cache loaders

---

## 8. Sample Queries

### 8.1 View active bonus types directly
```sql
SELECT * FROM BackOffice.BonusType WITH (NOLOCK) WHERE IsActive = 1
```

### 8.2 Compare active vs all bonus types
```sql
SELECT IsActive, COUNT(*) AS Count
FROM BackOffice.BonusType WITH (NOLOCK)
GROUP BY IsActive
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 sibling analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadActiveBonuses | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadActiveBonuses.sql*
