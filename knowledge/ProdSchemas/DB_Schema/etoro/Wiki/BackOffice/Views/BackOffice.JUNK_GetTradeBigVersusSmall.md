# BackOffice.JUNK_GetTradeBigVersusSmall

> **DEPRECATED (JUNK prefix)** - Returns a two-row platform-wide split of historical positions into "Small Trade" (price moved < 10 pips) vs "Big Trade" (10+ pips) with percentage share.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | TradeName - always exactly 2 rows |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.JUNK_GetTradeBigVersusSmall` is a legacy analytics view (JUNK prefix = deprecated) that classifies all historical positions from `History.Position` into two categories based on how many pips the price moved during the position's lifetime: **Small Trade** (absolute pip movement < 10 pips) and **Big Trade** (10 or more pips). It returns the percentage share of each category.

The 10-pip threshold was a hardcoded business heuristic used to characterize position behavior - small trades are those that opened and closed with minimal price movement, while big trades experienced significant price changes. This analytics view always returns exactly 2 rows and is not referenced by any active objects.

History.Position is in EtoroArchive and not accessible via the current MCP connection.

---

## 2. Business Logic

### 2.1 Pip Movement Classification

**What**: Classifies each position by the pip range of its price movement, using a fixed 10-pip threshold.

**Columns/Parameters Involved**: `TradeName`, `Percentage`

**Rules**:
- Pip movement = `ABS(InitForexRate - EndForexRate) * 10000`
- The `* 10000` factor converts forex rate difference to pips (standard for 4-decimal-place currency pairs)
- `< 10` pips -> "Small Trade"; `>= 10` pips -> "Big Trade"
- Percentage = `COUNT(*) / total_History.Position * 100`, rounded to 2 decimal places
- Note: for pairs where EndForexRate IS NULL (open positions in History.Position), `ABS(NULL)` = NULL, which is not `< 10` so such rows would fall into "Big Trade"

**Diagram**:
```
|InitForexRate - EndForexRate| * 10000 = pip_movement

pip_movement < 10   ->  'Small Trade'
pip_movement >= 10  ->  'Big Trade'
```

---

## 3. Data Overview

*Live data not available - History.Position references EtoroArchive database.*

| TradeName | Percentage | Meaning |
|-----------|------------|---------|
| Small Trade | (estimated ~20-40%) | Positions where price moved less than 10 pips - quick in-and-out trades, scalp-style entries, or positions closed at a stop |
| Big Trade | (estimated ~60-80%) | Positions where price moved 10 or more pips - typical trend trades, positions held longer, or wide-ranging market moves |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TradeName | VARCHAR (computed) | NO | - | VERIFIED | Classification of the position by price movement magnitude. Always one of: `'Small Trade'` (pip movement < 10) or `'Big Trade'` (pip movement >= 10, or NULL EndForexRate). Exactly 2 rows always returned. |
| 2 | Percentage | FLOAT (computed) | YES | - | VERIFIED | Percentage of total `History.Position` rows in this TradeName category. Formula: `ROUND(COUNT(*) / total_History.Position * 100, 2)`. The two rows sum to approximately 100%. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InitForexRate, EndForexRate | History.Position | Source (cross-schema, NOLOCK) | All historical positions - used for classification and as denominator for percentage. |

### 5.2 Referenced By (other objects point to this)

No active dependents found. Legacy view with JUNK prefix.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.JUNK_GetTradeBigVersusSmall (view) [DEPRECATED]
└── History.Position (cross-schema table - EtoroArchive)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Position | Cross-schema Table | FROM clause (NOLOCK) - all historical positions; also used in subquery denominator |

### 6.2 Objects That Depend On This

No active dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: the `* 10000` pip conversion assumes 4-decimal forex pairs. For JPY pairs (2-decimal) or crypto, the threshold would need adjustment - this is a hardcoded heuristic.

---

## 8. Sample Queries

### 8.1 Get the big vs small trade split

```sql
SELECT TradeName, Percentage
FROM BackOffice.JUNK_GetTradeBigVersusSmall WITH (NOLOCK)
ORDER BY Percentage DESC
```

### 8.2 Check if small trades exceed 50%

```sql
SELECT TradeName, Percentage
FROM BackOffice.JUNK_GetTradeBigVersusSmall WITH (NOLOCK)
WHERE TradeName = 'Small Trade'
  AND Percentage > 50
```

### 8.3 Direct equivalent without the view

```sql
SELECT
    CASE WHEN ABS(InitForexRate - EndForexRate) * 10000 < 10 THEN 'Small Trade' ELSE 'Big Trade' END AS TradeName,
    ROUND(CAST(COUNT(*) AS FLOAT) / (SELECT COUNT(*) FROM History.Position WITH (NOLOCK)) * 100, 2) AS Percentage
FROM History.Position WITH (NOLOCK)
GROUP BY CASE WHEN ABS(InitForexRate - EndForexRate) * 10000 < 10 THEN 'Small Trade' ELSE 'Big Trade' END
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.3/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/7 (Phase 2 blocked - EtoroArchive)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.JUNK_GetTradeBigVersusSmall | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.JUNK_GetTradeBigVersusSmall.sql*
