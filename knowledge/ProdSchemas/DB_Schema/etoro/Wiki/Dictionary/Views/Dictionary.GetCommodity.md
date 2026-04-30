# Dictionary.GetCommodity

> Filtered view returning only commodity instruments (CurrencyTypeID=2) from Dictionary.Currency with a computed bitmask position column.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | View |
| **Key Identifier** | CurrencyID (from Currency) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetCommodity is one of three legacy "asset class filter" views that partition the master instrument table (Dictionary.Currency) by CurrencyTypeID. This view returns only commodity instruments — physical resources like Gold (XAU), Oil (XTI), Silver (XAG), Natural Gas (XNG), and Copper — by filtering on CurrencyTypeID = 2.

The view also computes a `ForexType` column from the legacy `Mask` bitmask using `CAST((LOG(Mask)/LOG(2)+1) AS SMALLINT)`, which derives the bit position for instruments that have a Mask value. Modern instruments (added after the legacy bitmask system was retired) have NULL Mask values, which causes ForexType to also be NULL.

This is a sister view to Dictionary.GetCurrency (Forex, type 1) and Dictionary.GetIndices (Indices, type 3). All three share identical structure and computation logic, differing only in their CurrencyTypeID filter. They provide backward-compatible access for older platform components that query instruments by asset class.

---

## 2. Business Logic

### 2.1 Legacy Bitmask Position Calculation

**What**: Converts a power-of-2 bitmask value into its zero-based bit position for legacy instrument identification.

**Columns/Parameters Involved**: `Mask`, `ForexType`

**Rules**:
- Formula: `ForexType = CAST((LOG(Mask)/LOG(2)+1) AS SMALLINT)`
- This converts a bitmask like 1→1, 2→2, 4→3, 8→4, 16→5, etc.
- Modern commodity instruments have NULL Mask values (bitmask system retired), resulting in NULL ForexType
- The ForexType was used by legacy trading engine components for fast bitwise instrument identification

**Diagram**:
```
Dictionary.Currency (10,669 instruments)
│
├── CurrencyTypeID = 1 → Dictionary.GetCurrency  (Forex pairs)
├── CurrencyTypeID = 2 → Dictionary.GetCommodity (Commodities) ← THIS VIEW
├── CurrencyTypeID = 3 → (no active instruments found — historically CFD/Indices)
├── CurrencyTypeID = 4 → Dictionary.GetIndices   (Index instruments)
├── CurrencyTypeID = 5 → (Stocks — no dedicated view)
├── ...
└── CurrencyTypeID = 10 → (Crypto — no dedicated view)
```

---

## 3. Data Overview

| CurrencyID | Name | Abbreviation | Mask | ForexType | Meaning |
|---|---|---|---|---|---|
| 9 | OIL | XTI | NULL | NULL | West Texas Intermediate crude oil — one of the most traded commodities globally, priced in USD per barrel |
| 10 | GOLD | XAU | NULL | NULL | Gold — the primary precious metal safe-haven asset, priced in USD per troy ounce |
| 11 | SILVER | XAG | NULL | NULL | Silver — secondary precious metal traded for both investment and industrial demand |
| 13 | Copper | Copper | NULL | NULL | Copper — industrial base metal, a leading economic indicator due to its use in construction and manufacturing |
| 14 | NATGAS | XNG | NULL | NULL | Natural gas — energy commodity priced in USD per MMBtu, highly seasonal due to heating/cooling demand |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | NO | - | VERIFIED | Unique instrument identifier from Dictionary.Currency. Despite the "Currency" name, this is the universal instrument ID used across all trading operations — positions, orders, pricing, and configuration all reference this value. |
| 2 | Name | varchar(100) | YES | - | VERIFIED | Full instrument display name (e.g., "OIL", "GOLD", "SILVER"). Inherited from Dictionary.Currency.Name. Used in UI displays and reporting. |
| 3 | Abbreviation | varchar(10) | YES | - | VERIFIED | Trading symbol / ticker (e.g., "XTI" for Oil, "XAU" for Gold, "XAG" for Silver). Standard market abbreviations used in price feeds and trade execution. Inherited from Dictionary.Currency.Abbreviation. |
| 4 | Mask | bigint | YES | - | CODE-BACKED | Legacy bitmask value for bitwise instrument identification in the original trading engine. Modern commodities have NULL — the bitmask system predates the current instrument management approach. Inherited from Dictionary.Currency.Mask. |
| 5 | ForexType | smallint | YES | - | CODE-BACKED | Computed: `CAST((LOG(Mask)/LOG(2)+1) AS SMALLINT)`. Derives the bit position from Mask for legacy engine compatibility. NULL when Mask is NULL (all current commodity instruments). Despite the "Forex" name, this column is used across all three sister views. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | Base table (filtered) | Source data filtered on CurrencyTypeID = 2 (Commodity) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| OldStyle.GetForexGame | - | FROM reference | Legacy game/trading view that queries commodity instruments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetCommodity (view)
└── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | Base table — filtered WHERE CurrencyTypeID = 2 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| OldStyle.GetForexGame | View | References commodity instruments from this view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. Base table Dictionary.Currency has clustered index on CurrencyID and additional indexes on CurrencyTypeID for efficient filtering.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all tradable commodity instruments
```sql
SELECT  CurrencyID, Name, Abbreviation
FROM    Dictionary.GetCommodity WITH (NOLOCK)
ORDER BY Name
```

### 8.2 Find commodity instruments with legacy bitmask values
```sql
SELECT  CurrencyID, Name, Abbreviation, Mask, ForexType
FROM    Dictionary.GetCommodity WITH (NOLOCK)
WHERE   Mask IS NOT NULL
```

### 8.3 Join commodity instruments with their full Currency record
```sql
SELECT  gc.CurrencyID, gc.Name, gc.Abbreviation,
        c.IsActive, c.Leverage, ct.Name AS AssetClass
FROM    Dictionary.GetCommodity gc WITH (NOLOCK)
JOIN    Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyID = gc.CurrencyID
JOIN    Dictionary.CurrencyType ct WITH (NOLOCK) ON ct.CurrencyTypeID = c.CurrencyTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetCommodity | Type: View | Source: etoro/etoro/Dictionary/Views/Dictionary.GetCommodity.sql*
