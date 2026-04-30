# Dictionary.CurrencyTypeSafty

> Schema-bound view on Dictionary.CurrencyType providing a stable, alteration-proof contract for referencing asset class IDs and names.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | View (WITH SCHEMABINDING) |
| **Key Identifier** | CurrencyTypeID (from CurrencyType) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Dictionary.CurrencyTypeSafty (note: historical typo — "Safty" instead of "Safety") is a schema-bound view on the CurrencyType lookup table. The WITH SCHEMABINDING clause prevents anyone from dropping or altering the underlying CurrencyType table in ways that would break this view. This pattern is used when other schema-bound objects (such as indexed views or computed columns) need a guaranteed-stable reference to the currency type data.

Without schema binding, a DBA could alter Dictionary.CurrencyType (rename columns, change types) and silently break dependent objects. This view acts as a "contract" — SQL Server refuses DDL changes to CurrencyType that would invalidate CurrencyTypeSafty, ensuring downstream stability.

The view exposes only the two core columns — CurrencyTypeID and Name — providing a minimal, stable interface to the 10 asset class types that classify every tradable instrument on the eToro platform.

---

## 2. Business Logic

### 2.1 Asset Class Classification Contract

**What**: Provides an immutable reference to the 10 asset classes used across the entire trading platform.

**Columns/Parameters Involved**: `CurrencyTypeID`, `Name`

**Rules**:
- CurrencyTypeID values define the fundamental instrument taxonomy: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto
- Schema binding prevents unauthorized modification of these values at the table level
- Every instrument in Dictionary.Currency has a CurrencyTypeID that maps to one of these 10 types
- Sister views GetCurrency (type 1), GetCommodity (type 2), and GetIndices (type 3/4) filter by these exact values

**Diagram**:
```
Dictionary.CurrencyType (base table)
│  CurrencyTypeID │ Name
│  ───────────────│─────────────
│  1              │ Forex
│  2              │ Commodity
│  3              │ CFD
│  4              │ Indices
│  5              │ Stocks
│  ...            │ ...
│  10             │ Crypto
│
└── WITH SCHEMABINDING ──→ Dictionary.CurrencyTypeSafty (stable contract)
                                │  CurrencyTypeID
                                │  Name
                                │
                                └── Prevents ALTER/DROP on CurrencyType
```

---

## 3. Data Overview

| CurrencyTypeID | Name | Meaning |
|---|---|---|
| 1 | Forex | Foreign exchange currency pairs (EUR/USD, GBP/JPY) — the original eToro instrument class |
| 2 | Commodity | Physical commodities traded as CFDs (Gold, Oil, Silver, Natural Gas, Copper) |
| 5 | Stocks | Individual company equities traded as CFDs or real stock ownership |
| 10 | Crypto | Cryptocurrency assets (Bitcoin, Ethereum) — newest asset class added to the platform |
| 6 | ETF | Exchange-Traded Funds — baskets of securities traded as a single instrument |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyTypeID | int | NO | - | VERIFIED | Asset class identifier defining the fundamental instrument taxonomy: 1=Forex, 2=Commodity, 3=CFD, 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. Every instrument in Dictionary.Currency references one of these values. (Dictionary.CurrencyType) |
| 2 | Name | varchar | NO | - | VERIFIED | Human-readable asset class name displayed in UI and used in reporting. Inherited from Dictionary.CurrencyType.Name. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyTypeID | Dictionary.CurrencyType | Schema-bound base table | Direct 1:1 projection — all rows from CurrencyType with CurrencyTypeID and Name only |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (No direct SQL consumers found) | - | - | View exists as a schema-binding safety constraint rather than an actively queried interface |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.CurrencyTypeSafty (view)
└── Dictionary.CurrencyType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CurrencyType | Table | Schema-bound base table — SELECT CurrencyTypeID, Name |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found in codebase) | - | View serves as a schema-binding guard rather than a query target |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view. The WITH SCHEMABINDING clause enables this view to potentially support indexed views in the future, though no indexes are currently defined on it.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Retrieve all asset class types through the safe view
```sql
SELECT  CurrencyTypeID, Name
FROM    Dictionary.CurrencyTypeSafty WITH (NOLOCK)
ORDER BY CurrencyTypeID
```

### 8.2 Count instruments per asset class using the safe reference
```sql
SELECT  cts.CurrencyTypeID, cts.Name AS AssetClass, COUNT(c.CurrencyID) AS InstrumentCount
FROM    Dictionary.CurrencyTypeSafty cts WITH (NOLOCK)
JOIN    Dictionary.Currency c WITH (NOLOCK) ON c.CurrencyTypeID = cts.CurrencyTypeID
GROUP BY cts.CurrencyTypeID, cts.Name
ORDER BY InstrumentCount DESC
```

### 8.3 Verify schema binding prevents CurrencyType alteration
```sql
SELECT  v.name AS ViewName, d.referenced_entity_name AS BoundTable, d.is_schema_bound
FROM    sys.views v
JOIN    sys.sql_expression_dependencies d ON d.referencing_id = v.object_id
WHERE   v.name = 'CurrencyTypeSafty'
AND     SCHEMA_NAME(v.schema_id) = 'Dictionary'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CurrencyTypeSafty | Type: View | Source: etoro/etoro/Dictionary/Views/Dictionary.CurrencyTypeSafty.sql*
