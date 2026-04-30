# Trade.GetAllInstrumentTypesForAPI

> Returns all instrument type categories (asset classes) from the Dictionary.CurrencyType lookup table for the API layer.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns CurrencyTypeID, Name, Priority, SLTPApproachPercent, PricesBy, ImageUrl |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides the complete list of instrument type categories (asset classes) available on the platform. These categories define the top-level navigation in the trading platform - Stocks, Crypto, Commodities, Currencies, Indices, ETFs, etc. Each type has display properties (name, image, priority) and trading behavior settings (SL/TP approach, pricing method).

The procedure exists to feed the API's asset class catalog. The client uses this to build the main navigation tabs and apply the correct trading behavior settings per asset class (e.g., stocks use percentage-based SL/TP while currencies use pip-based).

Data is a simple full read of `Dictionary.CurrencyType` - a small reference table containing all defined asset classes.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a direct read of the CurrencyType dictionary. See individual element descriptions in Section 4.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Output columns:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyTypeID | INT | NO | - | CODE-BACKED | Primary key of the asset class type. Common values: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 10=Crypto, 12=ETFs. |
| 2 | Name | NVARCHAR | NO | - | CODE-BACKED | Display name of the asset class (e.g., "Stocks", "Crypto", "Commodities"). Used in UI navigation tabs. |
| 3 | Priority | INT | YES | - | CODE-BACKED | Display ordering priority for the asset class tabs in the UI. Lower numbers appear first. |
| 4 | SLTPApproachPercent | BIT | YES | - | CODE-BACKED | Whether SL/TP (Stop Loss/Take Profit) for this asset class is specified as a percentage. 1 = percentage-based SL/TP, 0 = rate/pip-based SL/TP. |
| 5 | PricesBy | INT | YES | - | CODE-BACKED | Pricing method for this asset class. Determines how prices are displayed and calculated. |
| 6 | ImageUrl | NVARCHAR | YES | - | CODE-BACKED | URL for the asset class icon/image used in the platform navigation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Dictionary.CurrencyType | SELECT FROM | Source dictionary table for all asset class types |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetAllInstrumentTypesForAPI (procedure)
+-- Dictionary.CurrencyType (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.CurrencyType | Table | SELECT FROM - reads all asset class types |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Trade.GetAllInstrumentTypesForAPI;
```

### 8.2 Query the dictionary table directly with ordering
```sql
SELECT  CurrencyTypeID, Name, Priority, SLTPApproachPercent, PricesBy, ImageUrl
FROM    Dictionary.CurrencyType WITH (NOLOCK)
ORDER BY Priority;
```

### 8.3 Count instruments per type
```sql
SELECT  ct.CurrencyTypeID, ct.Name, COUNT(imd.InstrumentID) AS InstrumentCount
FROM    Dictionary.CurrencyType ct WITH (NOLOCK)
        LEFT JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON ct.CurrencyTypeID = imd.InstrumentTypeID
GROUP BY ct.CurrencyTypeID, ct.Name
ORDER BY ct.Priority;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 7.4/10 (Elements: 10.0/10, Logic: 2.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetAllInstrumentTypesForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetAllInstrumentTypesForAPI.sql*
