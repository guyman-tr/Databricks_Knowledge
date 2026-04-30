# Trade.DeleteCopyTradeSettlementRestriction

> Removes copy-trade settlement restrictions matching a set of multi-column criteria (country, regulation, instrument type, exchange, instrument, restriction type) provided via TVP.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @RequestedRestrictionsTable (TVP of restriction criteria to match and delete) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DeleteCopyTradeSettlementRestriction removes specific copy-trade settlement restriction rules from Trade.CopyTradeSettlementRestrictions. These restrictions control which copy-trade operations are allowed or blocked based on combinations of country, regulation, instrument type, exchange, and specific instrument. When a restriction rule is no longer needed (e.g., a regulatory change), this procedure deletes matching rows.

This procedure exists to allow bulk removal of restriction rules by a set of matching criteria. The matching logic handles NULL-safe comparison on every dimension, meaning a NULL in the input matches a NULL in the table (both represent "any"/"all" for that dimension).

Data flow: The caller provides a TVP (Trade.BulkCopyTradeSettlementRestrictionsTbl) containing one or more sets of restriction criteria. The procedure deletes any existing CopyTradeSettlementRestrictions row where all dimensions match (using NULL-safe equality). Transaction handling with TRY/CATCH ensures atomicity.

---

## 2. Business Logic

### 2.1 Multi-Dimensional NULL-Safe Matching

**What**: Restriction rows are matched on 6 dimensions with NULL treated as a wildcard match.

**Columns/Parameters Involved**: `CountryID`, `RegulationID`, `InstrumentTypeID`, `ExchangeID`, `InstrumentID`, `RestrictionTypeID`

**Rules**:
- Each dimension uses the pattern: (R.Col = C.Col OR (R.Col IS NULL AND C.Col IS NULL))
- This ensures NULLs match NULLs (both meaning "applies to all")
- RestrictionTypeID is the only dimension with strict equality (never NULL) - it classifies the type of restriction
- EXISTS subquery with TOP 1 1 for performance

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RequestedRestrictionsTable | Trade.BulkCopyTradeSettlementRestrictionsTbl (READONLY) | NO | - | CODE-BACKED | TVP containing restriction criteria to match for deletion. Each row defines a combination of CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, and RestrictionTypeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (DELETE) | Trade.CopyTradeSettlementRestrictions | DELETER | Removes rows matching the multi-dimensional criteria |
| (@RequestedRestrictionsTable) | Trade.BulkCopyTradeSettlementRestrictionsTbl | Type Reference | Uses this UDT for batch input |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DeleteCopyTradeSettlementRestriction (procedure)
+-- Trade.CopyTradeSettlementRestrictions (table)
+-- Trade.BulkCopyTradeSettlementRestrictionsTbl (user-defined type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CopyTradeSettlementRestrictions | Table | DELETE target based on multi-column match |
| Trade.BulkCopyTradeSettlementRestrictionsTbl | User Defined Type | Input parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Delete restrictions using TVP

```sql
DECLARE @Restrictions Trade.BulkCopyTradeSettlementRestrictionsTbl
INSERT INTO @Restrictions (CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID)
VALUES (1, NULL, 5, NULL, NULL, 2)
EXEC Trade.DeleteCopyTradeSettlementRestriction @RequestedRestrictionsTable = @Restrictions
```

### 8.2 Preview restrictions before deletion

```sql
SELECT  CountryID, RegulationID, InstrumentTypeID, ExchangeID, InstrumentID, RestrictionTypeID
FROM    Trade.CopyTradeSettlementRestrictions WITH (NOLOCK)
ORDER BY RestrictionTypeID, CountryID
```

### 8.3 Count remaining restrictions after deletion

```sql
SELECT  RestrictionTypeID, COUNT(*) AS RuleCount
FROM    Trade.CopyTradeSettlementRestrictions WITH (NOLOCK)
GROUP BY RestrictionTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.5/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 5.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DeleteCopyTradeSettlementRestriction | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DeleteCopyTradeSettlementRestriction.sql*
