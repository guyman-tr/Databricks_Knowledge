# Trade.InstrumentConversion

> Mapping table that defines how to convert an instrument's base currency (SellCurrencyID) to a target currency (typically USD) using a specific forex pair as the rate source, with a flag indicating whether to apply the rate directly or invert it.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | InstrumentBaseCurrencyID, ConversionCurrencyID, ConversionInstrumentID (composite PK) |
| **Partition** | No |
| **Indexes** | 2 active (1 clustered PK + 1 NC on ConversionInstrumentID) |

---

## 1. Business Meaning

Trade.InstrumentConversion answers the question: "Given an instrument whose position PnL or value is denominated in currency X (the instrument's SellCurrencyID), which Trade.Instrument forex pair should I use to get a conversion rate to currency Y (typically USD), and do I apply that rate directly or invert it?"

Each row defines a conversion path: (InstrumentBaseCurrencyID, ConversionCurrencyID) -> ConversionInstrumentID, with ReciprocalForConversion controlling rate application. Hedge.GetUnrealizedCustomersData uses this table to convert position values to USD for unrealized PnL calculation. When ReciprocalForConversion=0, the system multiplies by the ConversionInstrument's bid rate. When ReciprocalForConversion=1, the system multiplies by 1/bid (inverting the rate - e.g., for USD/CHF where the quote is "CHF per USD", converting CHF to USD requires 1/rate).

This table exists because major forex instruments (IsMajor=1) derive conversion from Trade.GetCurrencyConversionsView which infers paths from Trade.Instrument. Non-major instruments and edge cases require explicit mappings stored here. CheckValidInstruments enforces that every instrument has at least one row (creating a placeholder 0,0,InstrumentID,0 when missing). Without this table, hedge exposure and PnL calculations would fail for instruments without inferred conversion paths.

Data flows: Internal.Newcurrency and Trade.CheckValidInstruments insert rows from XML/config. Trade.InsertInstrumentRealTable bulk-loads from ##Trade_InstrumentConversion during instrument migration. Hedge.GetUnrealizedCustomersData and Hedge.AddAccountPositionsFromNetting read the table, joining on SellCurrencyID = InstrumentBaseCurrencyID. dbo.Delete_Instrument removes rows when instruments are deleted.

---

## 2. Business Logic

### 2.1 Conversion Path (Base -> Target via Instrument)

**What**: A triple (InstrumentBaseCurrencyID, ConversionCurrencyID, ConversionInstrumentID) defines which forex instrument provides the rate to convert from base to target currency.

**Columns/Parameters Involved**: `InstrumentBaseCurrencyID`, `ConversionCurrencyID`, `ConversionInstrumentID`, `ReciprocalForConversion`

**Rules**:
- InstrumentBaseCurrencyID: the source currency (matches Trade.Instrument.SellCurrencyID for the position's instrument). FK to Dictionary.Currency.
- ConversionCurrencyID: the target currency (typically 1=USD). FK to Dictionary.Currency.
- ConversionInstrumentID: the Trade.Instrument (forex pair) whose bid/ask provides the rate. FK to Trade.Instrument.
- ReciprocalForConversion: 0 = use rate as-is (e.g., EUR/USD: euros per dollar, multiply EUR by rate to get USD). 1 = invert rate (e.g., USD/CHF: francs per dollar, multiply CHF by 1/rate to get USD).

**Diagram**:
```
EUR (2) -> USD (1): ConversionInstrumentID=EUR/USD(1), Reciprocal=0  -> value * EUR/USD_bid
CHF (4) -> USD (1): ConversionInstrumentID=USD/CHF(5), Reciprocal=1  -> value * (1/USD/CHF_bid)
Placeholder: (0,0,InstrumentID,0) -> no real conversion, used when no path defined (Hedge uses 1.0)
```

### 2.2 Reciprocal Rate Application

**What**: Code in Hedge.GetUnrealizedCustomersData applies the conversion rate based on ReciprocalForConversion.

**Columns/Parameters Involved**: `ReciprocalForConversion`

**Rules**:
- ReciprocalForConversion = -1 (or NULL): use 1.0 - no conversion (fallback when no matching row).
- ReciprocalForConversion = 0: multiply by Con.Bid (direct rate).
- ReciprocalForConversion = 1: multiply by 1.0/Con.Bid when Con.Bid <> 0 (inverted rate).

---

## 3. Data Overview

| InstrumentBaseCurrencyID | ConversionCurrencyID | ConversionInstrumentID | ReciprocalForConversion | Meaning |
|---|---|---|---|---|
| 0 | 0 | 20 | 0 | Placeholder row: instrument 20 has no explicit conversion path. CheckValidInstruments creates (0,0,InstrumentID,0) when missing. Hedge uses 1.0 when no match. |
| 2 | 1 | 1 | 0 | EUR (2) to USD (1) via EUR/USD (InstrumentID=1). Rate applied directly - multiply EUR value by EUR/USD bid. |
| 3 | 1 | 2 | 0 | GBP (3) to USD (1) via GBP/USD (InstrumentID=2). Direct rate. |
| 4 | 1 | 5 | 1 | CHF (4) to USD (1) via USD/CHF (InstrumentID=5). Quote is CHF per USD; invert rate to convert CHF to USD. |
| 6 | 1 | 6 | 1 | CAD (6) to USD (1) via USD/CAD (InstrumentID=6). Invert rate. |

**Selection criteria for the 5 rows:**
- Placeholder (0,0,...) pattern is common and represents fallback
- EUR, GBP, CHF, CAD show major forex conversion with both direct and reciprocal application

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentBaseCurrencyID | int | NO | - | CODE-BACKED | FK to Dictionary.Currency. The source currency to convert from - matches Trade.Instrument.SellCurrencyID for the position's instrument. 0 = placeholder when no real path exists. Hedge.GetUnrealizedCustomersData joins ON SellCurrencyID = InstrumentBaseCurrencyID. |
| 2 | ConversionCurrencyID | int | NO | - | CODE-BACKED | FK to Dictionary.Currency. The target currency to convert to. Typically 1 (USD). 0 = placeholder. |
| 3 | ConversionInstrumentID | int | NO | - | CODE-BACKED | FK to Trade.Instrument. The forex pair (InstrumentID) whose bid/ask provides the conversion rate. E.g., EUR/USD (1), GBP/USD (2), USD/CHF (5). CheckValidInstruments enforces at least one row per instrument via this column. |
| 4 | ReciprocalForConversion | bit | NO | - | CODE-BACKED | 0 = apply rate directly (value * Bid). 1 = apply inverted rate (value * 1/Bid) when Bid <> 0. Used when the conversion instrument quotes target-per-source (e.g., USD/CHF) vs source-per-target (e.g., EUR/USD). Hedge.GetUnrealizedCustomersData: CASE WHEN 0 THEN Con.Bid WHEN 1 THEN 1.0/Con.Bid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentBaseCurrencyID | Dictionary.Currency | FK | Source currency (CurrencyID). |
| ConversionCurrencyID | Dictionary.Currency | FK | Target currency (typically USD). |
| ConversionInstrumentID | Trade.Instrument | FK | Forex pair providing the conversion rate. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.GetUnrealizedCustomersData | - | JOIN | LEFT JOIN on SellCurrencyID = InstrumentBaseCurrencyID for unrealized PnL conversion. |
| Hedge.AddAccountPositionsFromNetting | - | JOIN | Left Join on SellCurrencyID = InstrumentBaseCurrencyID. |
| Trade.CheckValidInstruments | - | Read/Write | Validates ConversionInstrumentID exists; inserts (0,0,InstrumentID,0) into ##Trade_InstrumentConversion when missing. |
| Internal.Newcurrency | - | INSERT | Inserts from XML NewInstrumentSchema/Trade.InstrumentConversion/Row. |
| Trade.InsertInstrumentRealTable | - | INSERT | Bulk load from ##Trade_InstrumentConversion. |
| dbo.Delete_Instrument | - | DELETE | Removes rows when instrument is deleted. |
| dbo.DeleteInstrumentDebug | - | Reference | Lists table for debug delete. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InstrumentConversion (table)
```

This object has no code-level dependencies (tables have no FROM/JOIN). FK targets Dictionary.Currency and Trade.Instrument are structural dependencies listed in Section 6.1.

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | FK: InstrumentBaseCurrencyID, ConversionCurrencyID |
| Trade.Instrument | Table | FK: ConversionInstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetUnrealizedCustomersData | Procedure | Reads for conversion rate in unrealized PnL |
| Hedge.AddAccountPositionsFromNetting | Procedure | Reads for conversion in netting |
| Trade.CheckValidInstruments | Procedure | Validates and populates ##Trade_InstrumentConversion |
| Internal.Newcurrency | Procedure | Inserts from XML |
| Trade.InsertInstrumentRealTable | Procedure | Bulk INSERT |
| dbo.Delete_Instrument | Procedure | DELETE on instrument removal |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Trade_InstrumentConversion | CLUSTERED PK | InstrumentBaseCurrencyID, ConversionCurrencyID, ConversionInstrumentID | - | - | Active |
| IX_InstrumentID | NC | ConversionInstrumentID | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Trade_InstrumentConversion | PRIMARY KEY | Unique (InstrumentBaseCurrencyID, ConversionCurrencyID, ConversionInstrumentID) |
| FK_TIC_ConversionInstrumentID | FOREIGN KEY | ConversionInstrumentID -> Trade.Instrument(InstrumentID) |
| FK_TIC_DC_ConversionCurrencyID | FOREIGN KEY | ConversionCurrencyID -> Dictionary.Currency(CurrencyID) |
| FK_TIC_DC_InstrumentBaseCurrencyID | FOREIGN KEY | InstrumentBaseCurrencyID -> Dictionary.Currency(CurrencyID) |

---

## 8. Sample Queries

### 8.1 Count rows and list distinct ConversionCurrencyID values
```sql
SELECT COUNT(*) AS Cnt FROM Trade.InstrumentConversion WITH (NOLOCK);

SELECT ConversionCurrencyID, COUNT(*) AS Cnt
FROM Trade.InstrumentConversion WITH (NOLOCK)
GROUP BY ConversionCurrencyID
ORDER BY Cnt DESC;
```

### 8.2 Get conversion paths for major forex to USD with human-readable names
```sql
SELECT ic.InstrumentBaseCurrencyID,
       base.Abbreviation AS BaseCurrency,
       ic.ConversionCurrencyID,
       tgt.Abbreviation AS ConversionCurrency,
       ic.ConversionInstrumentID,
       ins.Abbreviation AS ConversionPair,
       ic.ReciprocalForConversion
FROM Trade.InstrumentConversion ic WITH (NOLOCK)
JOIN Dictionary.Currency base WITH (NOLOCK) ON ic.InstrumentBaseCurrencyID = base.CurrencyID
JOIN Dictionary.Currency tgt WITH (NOLOCK) ON ic.ConversionCurrencyID = tgt.CurrencyID
JOIN Trade.Instrument ins WITH (NOLOCK) ON ic.ConversionInstrumentID = ins.InstrumentID
WHERE ic.InstrumentBaseCurrencyID NOT IN (0)
  AND ic.ConversionCurrencyID = 1
ORDER BY ic.InstrumentBaseCurrencyID;
```

### 8.3 Find instruments missing a non-placeholder conversion row
```sql
SELECT i.InstrumentID, i.Abbreviation, i.SellCurrencyID
FROM Trade.Instrument i WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM Trade.InstrumentConversion ic WITH (NOLOCK)
    WHERE ic.ConversionInstrumentID = i.InstrumentID
      AND (ic.InstrumentBaseCurrencyID <> 0 OR ic.ConversionCurrencyID <> 0)
)
ORDER BY i.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: 2026-03-14 | Quality: 8.4/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 8 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentConversion | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.InstrumentConversion.sql*
