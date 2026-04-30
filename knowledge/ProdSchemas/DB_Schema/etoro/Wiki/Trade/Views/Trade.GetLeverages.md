# Trade.GetLeverages

> Simple pass-through view exposing leverage IDs and values from Dictionary.Leverage for UI dropdowns and validation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | LeverageID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLeverages is a minimal view over Dictionary.Leverage that exposes LeverageID and Value for all available leverage multipliers (1x, 2x, 5x, 10x, 20x, etc.). The view exists to provide a clean, schema-qualified interface for trading clients that need to populate leverage dropdowns, validate user-selected leverage against allowed values, or display leverage options in the UI. Without it, clients would query Dictionary.Leverage directly; the Trade schema view provides a logical grouping for trading-domain consumers.

Data flows directly from Dictionary.Leverage. The view has no filter and returns every leverage definition. Trade.GetInternalLeveragesWhiteList and leverage restriction procedures (GetLeveragesRestrictionsWhiteList, CM_GetLeveragesRestrictionsWhiteList) use this view or the underlying leverage logic to determine which leverages are available to specific users or account types.

---

## 2. Business Logic

### 2.1 Leverage as Multiplier

**What**: Each row defines a leverage multiplier (Value) that determines how much exposure a position has relative to margin. 1x = no leverage, 2x = 2:1, etc.

**Columns/Parameters Involved**: `LeverageID`, `Value`

**Rules**:
- LeverageID is the primary key; Value is the numeric multiplier.
- ESMA and other regulators cap retail leverage by asset class (e.g., 30x for major forex, 2x for crypto).
- Trade.GetInternalLeveragesWhiteList filters leverages for internal/privileged users.

**Diagram**:
```
LeverageID 1  -> Value 1  (no leverage)
LeverageID 9  -> Value 2  (2x)
LeverageID 2  -> Value 5  (5x)
LeverageID 3  -> Value 10 (10x)
LeverageID 11 -> Value 20 (20x)
```

---

## 3. Data Overview

| LeverageID | Value | Meaning |
|------------|-------|---------|
| 1 | 1 | No leverage - full margin required. Used for REAL (settled) positions. |
| 9 | 2 | 2x leverage. Common for crypto (ESMA cap) and conservative retail. |
| 2 | 5 | 5x leverage. Typical for commodities and indices. |
| 3 | 10 | 10x leverage. Common for forex minors and indices. |
| 11 | 20 | 20x leverage. Used for forex minors and some indices. |

**Selection criteria**: First 5 rows from live data show range from 1x to 20x. Higher leverages (30x, 50x, etc.) exist for major forex.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | LeverageID | int | NO | - | CODE-BACKED | Primary key from Dictionary.Leverage. Identifies the leverage option. Used in position and order tables. |
| 2 | Value | int | NO | - | CODE-BACKED | The leverage multiplier (1=no leverage, 2=2x, 5=5x, 10=10x, 20=20x, 30=30x, etc.). Used for margin calculation and display. (Dictionary.Leverage) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| LeverageID, Value | Dictionary.Leverage | Lookup | Direct projection from base table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.GetInternalLeveragesWhiteList | FROM | JOIN | Procedure reads leverage options for internal white list. |
| Trade.GetLeveragesRestrictionsWhiteList | - | Related | Leverage restriction logic. |
| Trade.CM_GetLeveragesRestrictionsWhiteList | - | Related | Multi-user leverage restriction logic. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLeverages (view)
└── Dictionary.Leverage (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Leverage | Table | FROM - sole base table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInternalLeveragesWhiteList | Procedure | FROM Trade.GetLeverages |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List all leverage options
```sql
SELECT LeverageID, Value
  FROM Trade.GetLeverages WITH (NOLOCK)
 ORDER BY Value
```

### 8.2 Get leverage value for a specific ID
```sql
SELECT LeverageID, Value
  FROM Trade.GetLeverages WITH (NOLOCK)
 WHERE LeverageID = 3
```

### 8.3 List leverages suitable for retail (low leverage)
```sql
SELECT LeverageID, Value
  FROM Trade.GetLeverages WITH (NOLOCK)
 WHERE Value IN (1, 2, 5, 10)
 ORDER BY Value
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.5/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: N/A | Corrections: 0 applied*
*Object: Trade.GetLeverages | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetLeverages.sql*
