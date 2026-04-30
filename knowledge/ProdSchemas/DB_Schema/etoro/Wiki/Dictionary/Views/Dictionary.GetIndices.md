# Dictionary.GetIndices

> Filtered view returning only index instruments (CurrencyTypeID=3) from Dictionary.Currency with a computed bitmask position column.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | View |
| **Key Identifier** | CurrencyID (from Currency) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.GetIndices is the indices-specific member of three legacy "asset class filter" views that partition Dictionary.Currency by CurrencyTypeID. This view filters on CurrencyTypeID = 3, which was historically used for index instruments (S&P 500, NASDAQ, Dow Jones, etc.). However, live data shows this filter currently returns zero rows — indices appear to have been reclassified under CurrencyTypeID = 4 ("Indices" in the CurrencyType table) at some point, while CurrencyTypeID = 3 is now labeled "CFD" in CurrencyType.

This means the view is effectively dormant — it exists for backward compatibility with legacy code that references it, but returns no data. Any code actively querying index instruments should use CurrencyTypeID = 4 or query Dictionary.Currency directly with appropriate CurrencyTypeID filtering.

Like its sister views GetCurrency (type 1) and GetCommodity (type 2), it computes `ForexType` from the legacy `Mask` bitmask using `CAST((LOG(Mask)/LOG(2)+1) AS SMALLINT)`.

---

## 2. Business Logic

### 2.1 CurrencyTypeID Mismatch (Historical Artifact)

**What**: The view filters on CurrencyTypeID=3, but indices now live under CurrencyTypeID=4.

**Columns/Parameters Involved**: `CurrencyTypeID` (filter), all output columns

**Rules**:
- View was created when CurrencyTypeID=3 meant "Indices"
- CurrencyType table was later reorganized: type 3 became "CFD", type 4 became "Indices"
- No instruments currently have CurrencyTypeID=3, so the view returns empty results
- The view is retained for backward compatibility — dropping it would require checking all consumers

**Diagram**:
```
CurrencyType Evolution:
│
│  ORIGINAL               CURRENT
│  ────────               ───────
│  1 = Forex              1 = Forex         (unchanged)
│  2 = Commodity          2 = Commodity     (unchanged)
│  3 = Indices  ──X──→   3 = CFD           (RENAMED - no instruments)
│                         4 = Indices       (NEW - holds index instruments)
│
│  GetIndices view: WHERE CurrencyTypeID = 3
│  ──→ Returns 0 rows (CurrencyTypeID=3 has no instruments)
│
│  To find actual indices: WHERE CurrencyTypeID = 4
```

---

## 3. Data Overview

N/A — This view currently returns zero rows. CurrencyTypeID=3 ("CFD") has no instruments assigned to it. Index instruments are classified under CurrencyTypeID=4 ("Indices") in the current CurrencyType schema.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyID | int | NO | - | VERIFIED | Instrument identifier from Dictionary.Currency. Would contain index instrument IDs if any instruments had CurrencyTypeID=3. Currently returns no rows. |
| 2 | Name | varchar(100) | YES | - | VERIFIED | Instrument display name. Would show index names like "S&P 500", "NASDAQ 100", "Dow Jones 30" if the view returned data. Inherited from Dictionary.Currency.Name. |
| 3 | Abbreviation | varchar(10) | YES | - | VERIFIED | Trading symbol / ticker. Would show abbreviations like "SPX500", "NSDQ100". Inherited from Dictionary.Currency.Abbreviation. |
| 4 | Mask | bigint | YES | - | CODE-BACKED | Legacy bitmask value for bitwise instrument identification. Index instruments typically have NULL Mask (bitmask system predates index instrument support). Inherited from Dictionary.Currency.Mask. |
| 5 | ForexType | smallint | YES | - | CODE-BACKED | Computed: `CAST((LOG(Mask)/LOG(2)+1) AS SMALLINT)`. Derives bit position from Mask. Would be NULL for modern index instruments. Despite the "Forex" name, this computed column exists in all three sister views. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyID | Dictionary.Currency | Base table (filtered) | Source data filtered on CurrencyTypeID = 3 (historically Indices, now CFD — returns empty) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No active consumers found) | - | - | View is dormant — consumers likely migrated to querying CurrencyTypeID=4 directly |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.GetIndices (view)
└── Dictionary.Currency (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | Base table — filtered WHERE CurrencyTypeID = 3 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found — view is dormant) | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check if any instruments use CurrencyTypeID=3
```sql
SELECT  COUNT(*) AS InstrumentCount
FROM    Dictionary.GetIndices WITH (NOLOCK)
```

### 8.2 Find actual index instruments (using correct CurrencyTypeID=4)
```sql
SELECT  CurrencyID, Name, Abbreviation
FROM    Dictionary.Currency WITH (NOLOCK)
WHERE   CurrencyTypeID = 4
ORDER BY Name
```

### 8.3 Compare instrument counts across all CurrencyTypes
```sql
SELECT  ct.CurrencyTypeID, ct.Name AS AssetClass, COUNT(c.CurrencyID) AS InstrumentCount
FROM    Dictionary.CurrencyType ct WITH (NOLOCK)
LEFT JOIN Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyTypeID = ct.CurrencyTypeID
GROUP BY ct.CurrencyTypeID, ct.Name
ORDER BY ct.CurrencyTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.GetIndices | Type: View | Source: etoro/etoro/Dictionary/Views/Dictionary.GetIndices.sql*
