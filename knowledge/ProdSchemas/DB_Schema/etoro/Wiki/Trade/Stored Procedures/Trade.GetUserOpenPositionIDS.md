# Trade.GetUserOpenPositionIDS

> Returns distinct InstrumentIDs from a customer's non-copy open positions and Stocks.Orders - used to determine which instruments the customer trades manually (excluding copy positions).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - customer whose non-copy instrument exposure is returned |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetUserOpenPositionIDS` returns the set of InstrumentIDs that a customer is directly/manually exposed to, excluding copy positions. By filtering `MirrorID = 0 OR MirrorID IS NULL`, it excludes positions opened via CopyTrader (which have a non-zero MirrorID). This is used in scenarios where the system needs to know what a customer trades on their own account rather than through copying.

It covers two position types:
1. **Trade.Position** (CFD/derivative open positions) - standard eToro positions
2. **Stocks.Orders** (stock orders from the Stocks schema) - stock/real asset positions

The UNION deduplicates across these two sources so each InstrumentID appears once.

---

## 2. Business Logic

### 2.1 Non-Copy Position Filter

**What**: Includes only positions/orders where the customer is acting independently (not as a copier).

**Rules**:
- `MirrorID = 0 OR MirrorID IS NULL` in both sources
- MirrorID > 0 = position was opened by the copy system (should be excluded)
- MirrorID = 0 or NULL = manual/direct position

### 2.2 Two Sources: Trade.Position and Stocks.Orders

**What**: Combines CFD positions and stock orders.

**Rules**:
- `Trade.Position WITH (NOLOCK)` - open CFD/derivative positions (view - already filtered to open StatusID)
- `Stocks.Orders WITH (NOLOCK)` - stock orders from the Stocks schema (different from Trade.Orders)
- UNION deduplicates - each InstrumentID returned once regardless of source count

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose non-copy instrument exposure is returned. |

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Distinct instrument ID from non-copy open positions or stock orders. FK to Trade.Instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| First SELECT | Trade.Position | FROM | Open CFD/derivative positions (non-copy only) |
| Second SELECT | Stocks.Orders | FROM | Stock orders (non-copy only, cross-schema) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (instrument eligibility checks) | @CID | EXEC caller | Determines customer's manual instrument exposure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetUserOpenPositionIDS (procedure)
+-- Trade.Position (view)
|     +-- Trade.PositionTbl (table)
+-- Stocks.Orders (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Non-copy open CFD positions |
| Stocks.Orders | Table | Non-copy stock orders (Stocks schema) |

### 6.2 Objects That Depend On This

No documented dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| MirrorID = 0 OR MirrorID IS NULL | Business filter | Excludes copy positions (MirrorID > 0 = copy) |
| WITH (NOLOCK) | Isolation | Dirty reads on both sources |
| UNION (not UNION ALL) | Deduplication | Each InstrumentID appears once |

---

## 8. Sample Queries

### 8.1 Get manually-traded instruments
```sql
EXEC Trade.GetUserOpenPositionIDS @CID = 123456
```

### 8.2 Compare non-copy vs all instruments
```sql
-- Non-copy only (GetUserOpenPositionIDS logic):
SELECT InstrumentID FROM Trade.Position WITH (NOLOCK)
WHERE CID = 123456 AND (MirrorID = 0 OR MirrorID IS NULL)
UNION
SELECT InstrumentID FROM Stocks.Orders WITH (NOLOCK)
WHERE CID = 123456 AND (MirrorID = 0 OR MirrorID IS NULL);

-- All instruments including copy (GetUserInstrumentIdsOnly):
EXEC Trade.GetUserInstrumentIdsOnly @CID = 123456;
```

### 8.3 N/A - third query not applicable

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Trade.GetUserOpenPositionIDS | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetUserOpenPositionIDS.sql*
