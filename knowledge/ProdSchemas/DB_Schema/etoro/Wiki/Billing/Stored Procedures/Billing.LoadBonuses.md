# Billing.LoadBonuses

> Returns all bonus type definitions from BackOffice.BonusType (no filter) - a startup cache loader for the full bonus type catalog including inactive types, used for billing reporting and reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT * FROM BackOffice.BonusType (all rows) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LoadBonuses` is a full reference data loader that returns all bonus type definitions, including inactive ones. The billing service uses this to build a complete lookup map for bonus type IDs encountered in historical data - where a bonus type has been deactivated but previously-applied bonuses still reference it, the lookup must include the inactive record to resolve the ID correctly.

The distinction between `LoadBonuses` (all types) and `LoadActiveBonuses` (IsActive=1 only) serves different purposes: `LoadActiveBonuses` is used at payment-processing time to know which bonuses can be offered; `LoadBonuses` is used at reporting/reconciliation time to resolve any bonus type ID in historical records regardless of its current active status.

---

## 2. Business Logic

### 2.1 Full Bonus Type Load

**What**: SELECT * with no filter - returns all rows and all columns from BackOffice.BonusType.

**Columns/Parameters Involved**: All columns of BackOffice.BonusType

**Rules**:
- No parameters; no filtering
- WITH (NOLOCK) for non-blocking reads
- RETURN 0 signals success
- Complement to `LoadActiveBonuses` (active only)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Columns

All columns from `BackOffice.BonusType` (cross-schema; exact columns from BackOffice schema DDL). Includes both active and inactive bonus types.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | BackOffice.BonusType | READ | Returns all bonus types (no IsActive filter); cross-schema read |

### 5.2 Referenced By (other objects point to this)

Called from the billing application at startup for complete bonus type catalog cache population.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LoadBonuses (procedure)
└── BackOffice.BonusType (cross-schema table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.BonusType | Table | Source of all bonus definitions (no filter) |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

**Implementation notes**:
- `SET NOCOUNT ON` + `RETURN 0`; `WITH (NOLOCK)`
- Structurally identical to `LoadActiveBonuses` except without the `WHERE IsActive=1` filter
- Part of the Load* family of startup cache loaders

---

## 8. Sample Queries

### 8.1 View all bonus types
```sql
SELECT * FROM BackOffice.BonusType WITH (NOLOCK) ORDER BY BonusTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 7/10, Logic: 7/10, Relationships: 6/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 sibling analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LoadBonuses | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LoadBonuses.sql*
