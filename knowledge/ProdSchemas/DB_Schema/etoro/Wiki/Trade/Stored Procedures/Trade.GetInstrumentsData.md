# Trade.GetInstrumentsData

> Returns core instrument display data - symbol, display name, currency, type, and image URL - for all instruments, enabling client-facing instrument catalogs and notification services.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + display metadata from multiple tables |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsData is a parameterless bulk-read procedure that returns the essential display metadata for every instrument in the system. It combines data from Trade.InstrumentMetaData (display name, symbol, type), Trade.Instrument (sell currency reference), Dictionary.Currency (currency abbreviation), and Trade.InstrumentImages (150x150 image URL) into a single result set used for rendering instrument catalogs in client applications and notification services.

This procedure exists because instrument display data is scattered across four tables, and consumers need a denormalized view for rendering. The 150x150 image size is specifically targeted for thumbnail display in instrument lists and notifications.

The procedure is called by CNPNotificationsUserProd (Copy & Paste Notifications service). It feeds instrument data into push notifications so users see instrument names, images, and currency labels when they receive trading alerts.

---

## 2. Business Logic

### 2.1 Instrument Display Data Assembly

**What**: Combines instrument metadata, currency labels, and image URLs from four tables into a single display-ready row per instrument.

**Columns/Parameters Involved**: `InstrumentMetaData.InstrumentID`, `InstrumentMetaData.SymbolFull`, `InstrumentMetaData.InstrumentDisplayName`, `InstrumentMetaData.InstrumentTypeID`, `Instrument.SellCurrencyID`, `Currency.Abbreviation`, `InstrumentImages.Uri`

**Rules**:
- INNER JOIN to Trade.Instrument and Dictionary.Currency ensures every returned instrument has a valid sell currency
- LEFT JOIN to Trade.InstrumentImages allows instruments without images (ImageUrl will be NULL)
- Only 150x150 pixel images are selected (Width=150 AND Height=150) - thumbnail size for catalog display
- Currency is derived from SellCurrencyID on Trade.Instrument, representing the denomination currency (e.g., USD for US stocks)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.InstrumentMetaData.InstrumentID | CODE-BACKED | Instrument identifier. FK to Trade.Instrument. |
| R2 | SymbolFull | nvarchar | Trade.InstrumentMetaData.SymbolFull | CODE-BACKED | Full trading symbol (e.g., "AAPL", "EURUSD", "BTC"). Used as the primary display symbol in client UIs. |
| R3 | InstrumentDisplayName | nvarchar | Trade.InstrumentMetaData.InstrumentDisplayName | CODE-BACKED | Human-readable display name (e.g., "Apple Inc.", "Euro/US Dollar", "Bitcoin"). Shown in instrument catalogs and notifications. |
| R4 | Currency | varchar | Dictionary.Currency.Abbreviation (aliased from SellCurrencyID) | CODE-BACKED | Currency abbreviation for the instrument's sell/denomination currency (e.g., "USD", "EUR", "GBP"). Resolved via Trade.Instrument.SellCurrencyID -> Dictionary.Currency. |
| R5 | InstrumentTypeID | int | Trade.InstrumentMetaData.InstrumentTypeID | CODE-BACKED | Instrument type classification. FK to Dictionary.InstrumentType (e.g., 1=Currencies, 4=Indices, 5=Commodities, 10=Stocks, 14=Futures). |
| R6 | ImageUrl | nvarchar | Trade.InstrumentImages.Uri (aliased) | CODE-BACKED | URL for the instrument's 150x150 pixel thumbnail image. NULL if no image exists for this instrument at that size. Used for visual instrument identification in UIs and notifications. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.InstrumentMetaData | Read (SELECT) | Primary source of instrument display metadata |
| JOIN | Trade.Instrument | Read (SELECT) | Source of SellCurrencyID for currency resolution |
| JOIN | Dictionary.Currency | Lookup | Resolves SellCurrencyID to currency abbreviation |
| LEFT JOIN | Trade.InstrumentImages | Read (SELECT) | Optional 150x150 thumbnail image URL |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| CNPNotificationsUserProd | EXECUTE | Permission | Copy & Paste Notifications service uses instrument display data for push notifications |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsData (procedure)
+-- Trade.InstrumentMetaData (table)
+-- Trade.Instrument (table)
+-- Dictionary.Currency (table)
+-- Trade.InstrumentImages (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentMetaData | Table | INNER JOIN - instrument display name, symbol, type |
| Trade.Instrument | Table | INNER JOIN - SellCurrencyID for currency resolution |
| Dictionary.Currency | Table | INNER JOIN - currency abbreviation lookup |
| Trade.InstrumentImages | Table | LEFT JOIN - 150x150 thumbnail image URL |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| CNPNotificationsUserProd | DB User | EXECUTE permission for notification service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all instrument display data

```sql
EXEC Trade.GetInstrumentsData;
```

### 8.2 Find instruments without images

```sql
SELECT  imd.InstrumentID, imd.SymbolFull, imd.InstrumentDisplayName
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
        LEFT JOIN Trade.InstrumentImages ii ON ii.InstrumentID = imd.InstrumentID AND ii.Width = 150 AND ii.Height = 150
WHERE   ii.Uri IS NULL
ORDER BY imd.InstrumentDisplayName;
```

### 8.3 Get instrument data with currency and type names

```sql
SELECT  imd.InstrumentID,
        imd.SymbolFull,
        imd.InstrumentDisplayName,
        c.Abbreviation AS Currency,
        dit.InstrumentType
FROM    Trade.InstrumentMetaData imd WITH (NOLOCK)
        INNER JOIN Trade.Instrument i WITH (NOLOCK) ON i.InstrumentID = imd.InstrumentID
        INNER JOIN Dictionary.Currency c WITH (NOLOCK) ON i.SellCurrencyID = c.CurrencyID
        INNER JOIN Dictionary.InstrumentType dit WITH (NOLOCK) ON imd.InstrumentTypeID = dit.InstrumentTypeID
ORDER BY imd.InstrumentDisplayName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsData.sql*
