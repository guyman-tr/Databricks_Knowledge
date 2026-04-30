# BackOffice.GetTradeSingleVersusCombo

> Returns a two-row platform-wide breakdown of game results into "Single Trade" vs "Combo Trade" categories with percentage share, based on game sub-type classification.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | TradeName - always exactly 2 rows |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.GetTradeSingleVersusCombo` is a platform-level analytics summary that classifies all historical game results (`History.ForexResult`) into two categories: **Single Trade** (games played on game sub-types MAP and ROPE - GameSubTypeIDs 4 and 6) versus **Combo Trade** (all other game sub-types). It returns the percentage share of each category across the entire ForexResult history.

This view answers a product analytics question: "What proportion of all game activity is single-instrument trades vs. multi-instrument combo trades?" The data shows that Combo Trades dominate at ~98.5% of activity while Single Trades account for ~1.5%.

The view always returns exactly 2 rows - one for each TradeName category. It reads `Game.ForexGame` to look up the GameSubTypeID for each game result and applies the Single/Combo classification via a hardcoded CASE expression with inline comments identifying which game sub-types map to Single Trade (GameSubTypeID 4=MAP, 6=ROPE).

---

## 2. Business Logic

### 2.1 Single vs Combo Trade Classification

**What**: Classifies each game result as a single-instrument trade (player trades one instrument) or a combo trade (player trades multiple instruments simultaneously).

**Columns/Parameters Involved**: `TradeName`, `Percentage`

**Rules**:
- `GameSubTypeID IN (4, 6)` -> "Single Trade" (code comments confirm: 4=MAP, 6=ROPE)
- All other GameSubTypeIDs -> "Combo Trade"
- Percentage = `COUNT(*) / total_ForexResult_rows * 100`, rounded to 2 decimal places
- The denominator subquery counts ALL rows in `History.ForexResult` (including those not joined to `Game.ForexGame`)
- Result is always 2 rows - one per TradeName value

**Diagram**:
```
History.ForexResult JOIN Game.ForexGame ON ForexGameID
         |
    CASE GameSubTypeID
      IN (4=MAP, 6=ROPE)  ->  'Single Trade'
      else                ->  'Combo Trade'
         |
    GROUP BY TradeName
    COUNT(*) / total_count * 100

Result (live data):
  Combo Trade:   98.52%
  Single Trade:   1.48%
```

---

## 3. Data Overview

| TradeName | Percentage | Meaning |
|-----------|------------|---------|
| Combo Trade | 98.52 | 98.52% of all historical game results are from combo game sub-types - multi-instrument games like Horse Race, Globe Trader, and eToro Trading dominate overall activity |
| Single Trade | 1.48 | Only 1.48% of results come from single-trade game types (MAP=GameSubTypeID 4 and ROPE=GameSubTypeID 6), indicating these were niche or short-lived game formats |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TradeName | VARCHAR (computed) | NO | - | VERIFIED | Classification label for the game result category. Always one of two values: `'Single Trade'` (GameSubTypeID IN (4=MAP, 6=ROPE)) or `'Combo Trade'` (all other GameSubTypeIDs). Exactly 2 rows are returned. |
| 2 | Percentage | FLOAT (computed) | YES | - | VERIFIED | Percentage of total `History.ForexResult` rows that fall into this TradeName category. Formula: `ROUND(COUNT(*) / total_ForexResult_count * 100, 2)`. Rounded to 2 decimal places. The two rows sum to approximately 100% (small variance possible if some ForexResult rows have no matching ForexGame). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ForexGameID, (count denominator) | History.ForexResult | Source (cross-schema, NOLOCK) | All game results - provides the data being classified and the total row count for percentage calculation. |
| GameSubTypeID | Game.ForexGame | Lookup (cross-schema) | Joined on ForexGameID to resolve the GameSubTypeID used for Single/Combo classification. |

### 5.2 Referenced By (other objects point to this)

No dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.GetTradeSingleVersusCombo (view)
├── History.ForexResult (cross-schema table)
└── Game.ForexGame (cross-schema table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ForexResult | Cross-schema Table | FROM clause (alias HFXR, NOLOCK) - all game results being classified; also used in subquery for total count denominator |
| Game.ForexGame | Cross-schema Table | FROM clause (alias GFXG) - provides GameSubTypeID per ForexGameID for classification |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. Note: implicit INNER JOIN via old-style comma syntax - ForexResult rows with no matching ForexGame are excluded from the numerator but included in the denominator subquery, causing the two rows to sum to slightly less than 100% if orphan records exist.

---

## 8. Sample Queries

### 8.1 Get the current single vs combo trade split

```sql
SELECT TradeName, Percentage
FROM BackOffice.GetTradeSingleVersusCombo WITH (NOLOCK)
ORDER BY Percentage DESC
```

### 8.2 Check whether single trade usage is above 5%

```sql
SELECT TradeName, Percentage
FROM BackOffice.GetTradeSingleVersusCombo WITH (NOLOCK)
WHERE TradeName = 'Single Trade'
  AND Percentage > 5
```

### 8.3 Verify the two rows sum to ~100%

```sql
SELECT SUM(Percentage) AS TotalPercentage
FROM BackOffice.GetTradeSingleVersusCombo WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.GetTradeSingleVersusCombo | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.GetTradeSingleVersusCombo.sql*
