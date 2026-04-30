# Trade.GetLeveragesRestrictionsWhiteList

> Returns the custom leverage white-list entries (max, min, default leverage) for a given global customer ID (GCID), enriched with the instrument's type.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: GCID, InstrumentID, InstrumentTypeID, MaxLeverage, MinLeverage, DefaultLeverage |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetLeveragesRestrictionsWhiteList retrieves leverage override entries for a specific global customer ID (GCID). The white-list mechanism allows eToro to grant individual customers custom leverage limits that differ from their country's standard restrictions. Each entry defines the maximum, minimum, and default leverage for a specific instrument.

This procedure exists because certain customers (e.g., professional-classified clients, VIP traders, or those with special compliance arrangements) need leverage limits that differ from the standard country-based regulatory caps. The Trading API (TAPIUser) and Trading Settings API (TradingSettingsAPI) call this to check if a customer has custom leverage entries before applying default country rules.

The procedure joins to Trade.GetInstrument (view) to enrich results with InstrumentTypeID, which allows the application to apply leverage rules at the instrument-type level (e.g., crypto vs FX vs stocks).

---

## 2. Business Logic

### 2.1 White-List Leverage Lookup

**What**: Returns custom leverage boundaries per instrument for a specific GCID.

**Columns/Parameters Involved**: `@GCID`, `Trade.LeveragesRestrictionsWhiteList`, `Trade.GetInstrument`

**Rules**:
- Filters Trade.LeveragesRestrictionsWhiteList by GCID
- Joins to Trade.GetInstrument view to get InstrumentTypeID for each instrument
- MaxLeverage: upper bound of allowed leverage for this customer-instrument pair
- MinLeverage: lower bound
- DefaultLeverage: pre-selected leverage when the customer opens a position on this instrument
- If no rows returned for a GCID, the customer has no white-list overrides and standard country rules apply

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### 4.1 Parameters

| # | Element | Type | Direction | Default | Confidence | Description |
|---|---------|------|-----------|---------|------------|-------------|
| 1 | @GCID | int | IN | - | CODE-BACKED | Global Customer ID. Identifies the customer across eToro's global customer registry. Used to filter white-list entries. |

### 4.2 Result Set

| # | Element | Type | Nullable | Confidence | Description |
|---|---------|------|----------|------------|-------------|
| 1 | GCID | int | NO | CODE-BACKED | The global customer ID this entry belongs to. Matches the @GCID input. |
| 2 | InstrumentID | int | NO | CODE-BACKED | The instrument this leverage override applies to. FK to Trade.Instrument. |
| 3 | InstrumentTypeID | int | NO | CODE-BACKED | Instrument type classification (e.g., FX, Stock, Crypto, ETF). Sourced from Trade.GetInstrument view. FK to Dictionary.InstrumentType. |
| 4 | MaxLeverage | int | YES | CODE-BACKED | Maximum leverage multiplier allowed for this customer-instrument pair. |
| 5 | MinLeverage | int | YES | CODE-BACKED | Minimum leverage multiplier allowed. |
| 6 | DefaultLeverage | int | YES | CODE-BACKED | Default (pre-selected) leverage when the customer opens a position on this instrument. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.LeveragesRestrictionsWhiteList | SELECT (READER) | Reads customer-specific leverage override entries |
| JOIN | Trade.GetInstrument | SELECT (READER) | Joins to get InstrumentTypeID for each instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CM_GetLeveragesRestrictionsWhiteList | EXEC | Stored Procedure | Wrapper procedure that calls this |
| TAPIUser | GRANT EXECUTE | Application User | Trading API checks white-list entries |
| TradingSettingsAPI | GRANT EXECUTE | Application User | Trading Settings API for UI display |
| PROD_BIadmins | GRANT EXECUTE | Application User | BI analytics |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetLeveragesRestrictionsWhiteList (procedure)
+-- Trade.LeveragesRestrictionsWhiteList (table)
+-- Trade.GetInstrument (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LeveragesRestrictionsWhiteList | Table | SELECT to get leverage overrides for the GCID |
| Trade.GetInstrument | View | JOIN on InstrumentID to get InstrumentTypeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CM_GetLeveragesRestrictionsWhiteList | Stored Procedure | Calls this procedure |
| TAPIUser | Application User | Trading API |
| TradingSettingsAPI | Application User | Settings API |
| PROD_BIadmins | Application User | BI analytics |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get leverage white-list for a customer

```sql
EXEC Trade.GetLeveragesRestrictionsWhiteList @GCID = 12345;
```

### 8.2 Check white-list entries with instrument names

```sql
SELECT  TL.GCID,
        TL.InstrumentID,
        GI.InstrumentTypeID,
        GI.SymbolFull,
        TL.MaxLeverage,
        TL.MinLeverage,
        TL.DefaultLeverage
FROM    Trade.LeveragesRestrictionsWhiteList TL WITH (NOLOCK)
        INNER JOIN Trade.GetInstrument GI WITH (NOLOCK) ON TL.InstrumentID = GI.InstrumentID
WHERE   TL.GCID = 12345
ORDER BY GI.InstrumentTypeID, TL.InstrumentID;
```

### 8.3 Count white-listed customers per instrument type

```sql
SELECT  GI.InstrumentTypeID,
        COUNT(DISTINCT TL.GCID) AS WhiteListedCustomers,
        COUNT(*) AS TotalEntries
FROM    Trade.LeveragesRestrictionsWhiteList TL WITH (NOLOCK)
        INNER JOIN Trade.GetInstrument GI WITH (NOLOCK) ON TL.InstrumentID = GI.InstrumentID
GROUP BY GI.InstrumentTypeID
ORDER BY WhiteListedCustomers DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetLeveragesRestrictionsWhiteList | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetLeveragesRestrictionsWhiteList.sql*
