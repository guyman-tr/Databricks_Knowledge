# Trade.Position_DataFactory_Test

> Thin test wrapper view that simply selects all columns from Trade.PositionForExternalUseWithPnL. Used for data factory testing isolation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | PositionID (inherited from Trade.PositionForExternalUseWithPnL) |
| **Partition** | N/A |
| **Indexes** | N/A |
| **Status** | Test wrapper - not for production use |

---

## 1. Business Meaning

Trade.Position_DataFactory_Test is a trivial wrapper view consisting of `SELECT * FROM Trade.PositionForExternalUseWithPnL`. It exists as an isolation layer for data factory testing, allowing test infrastructure to reference a dedicated view that can be independently modified or replaced without affecting production consumers.

No additional logic, filtering, or column transformations are applied.

---

## 2. Business Logic

None. Pass-through to Trade.PositionForExternalUseWithPnL.

---

## 3. Data Overview

Identical to Trade.PositionForExternalUseWithPnL (all open positions with live PnL).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | * | (all) | - | - | VERIFIED | All columns from Trade.PositionForExternalUseWithPnL (position data + PnL). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| * | Trade.PositionForExternalUseWithPnL | SELECT * | Complete pass-through |

### 5.2 Referenced By (other objects point to this)

No SQL dependents found in the repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Position_DataFactory_Test (view)
+-- Trade.PositionForExternalUseWithPnL (view)
    +-- Trade.PositionForExternalUse (view)
    +-- Trade.PnL (view)
```

---

## 7. Technical Details

Trivial `SELECT *` wrapper. No performance characteristics beyond the underlying view.

---

## 8. Sample Queries

### 8.1 Use in test context
```sql
SELECT  PositionID, CID, PnLInDollars
FROM    Trade.Position_DataFactory_Test WITH (NOLOCK)
WHERE   CID = 12345;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found.

---

*Generated: 2026-03-15 | Quality: 7.5/10 (Elements: 10/10, Logic: 3/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Position_DataFactory_Test | Type: View | Source: etoro/etoro/Trade/Views/Trade.Position_DataFactory_Test.sql*
