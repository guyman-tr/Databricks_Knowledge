# Trade.GetProvidersTradonomiContracts

> Join of instruments to liquidity provider contracts exposing InstrumentID, LiquidityProviderID, and instrument display name as Ticker for Tradonomi-related contract resolution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | View |
| **Key Identifier** | InstrumentID, LiquidityProviderID (composite from join) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetProvidersTradonomiContracts maps eToro instruments to liquidity provider contract tickers by joining Trade.GetInstrument with Trade.LiquidityProviderContracts. Each row represents "for Instrument X, liquidity provider type Y uses ticker Z." The view name references Tradonomi - the primary execution provider - but the data includes all liquidity provider types that have contracts for each instrument.

The view exists so callers can resolve eToro InstrumentID to provider-specific ticker symbols in one place. Used by price, hedge, and contract-resolution logic that needs to translate instrument IDs to external ticker conventions.

---

## 2. Business Logic

### 2.1 Instrument-to-Provider Ticker Mapping

**What**: Each row links an instrument to a liquidity provider type and its ticker.

**Columns/Parameters Involved**: `InstrumentID`, `LiquidityProviderID`, `Ticker`

**Rules**:
- INNER JOIN Trade.GetInstrument TGI ON TGI.InstrumentID = LPC.InstrumentID
- INNER JOIN Trade.LiquidityProviderContracts LPC
- SELECT DISTINCT to avoid duplicate rows when multiple exchanges or date ranges exist
- Ticker is provider-specific (e.g., EUR/USD vs EURUSD)

### 2.2 Ticker from GetInstrument

**What**: The Ticker column is aliased from TGI.Name (instrument display name) in the view DDL.

**Columns/Parameters Involved**: `Ticker`, `TGI.Name`

**Rules**:
- TGI.Name AS [Ticker] - uses instrument display name (BUY/SELL format, e.g., EUR/USD, PARAA/USD) as ticker
- Note: Trade.LiquidityProviderContracts has its own Ticker column with provider-specific format; this view uses GetInstrument.Name instead

---

## 3. Data Overview

| InstrumentID | LiquidityProviderID | Ticker | Meaning |
|--------------|---------------------|--------|---------|
| 10029 | 0 | PARAA/USD | eToro instrument 10029, provider 0 (eToro), ticker PARAA/USD |
| 10029 | 5 | PARAA/USD | Same instrument, XIGNITE (5), same ticker |
| 10029 | 8 | PARAA/USD | Same instrument, BitStamp (8) |
| 10029 | 11 | PARAA/USD | Same instrument, provider 11 |
| 10029 | 12 | PARAA/USD | Same instrument, provider 12 |

**Selection criteria**: Live MCP sample. Instrument 10029 (PARAA stock) has contracts across multiple liquidity providers. Ticker format from GetInstrument display name.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument. From Trade.GetInstrument / Trade.LiquidityProviderContracts. |
| 2 | LiquidityProviderID | int | NO | - | CODE-BACKED | Liquidity provider type (e.g., 0=eToro, 2=FXCM, 5=XIGNITE, 8=BitStamp). From Trade.LiquidityProviderContracts. |
| 3 | Ticker | varchar | NO | - | CODE-BACKED | Instrument display name (BUY/SELL format) from Trade.GetInstrument.Name. Used as ticker identifier. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|----------------|-------------------|-------------|
| InstrumentID | Trade.GetInstrument | INNER JOIN | Instrument definitions; TGI.InstrumentID = LPC.InstrumentID |
| InstrumentID, LiquidityProviderID | Trade.LiquidityProviderContracts | INNER JOIN | Provider-instrument ticker mapping |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.LiquidityProviderContracts (doc) | - | Documented | View links to Tradonomi contracts; referenced in dependency docs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetProvidersTradonomiContracts (view)
├── Trade.GetInstrument (view)
│   ├── Trade.Instrument
│   ├── Dictionary.Currency (x2)
│   └── Trade.InstrumentMetaData
└── Trade.LiquidityProviderContracts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetInstrument | View | INNER JOIN on InstrumentID for Name (as Ticker) |
| Trade.LiquidityProviderContracts | Table | INNER JOIN on InstrumentID; source of InstrumentID, LiquidityProviderID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (None found) | - | No direct procedure references in grep; documented in Trade.LiquidityProviderContracts as linked view |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 List contracts for an instrument
```sql
SELECT InstrumentID, LiquidityProviderID, Ticker
  FROM Trade.GetProvidersTradonomiContracts WITH (NOLOCK)
 WHERE InstrumentID = 1
 ORDER BY LiquidityProviderID;
```

### 8.2 Instruments with multiple provider contracts
```sql
SELECT InstrumentID, COUNT(*) AS ProviderCount, MAX(Ticker) AS Ticker
  FROM Trade.GetProvidersTradonomiContracts WITH (NOLOCK)
 GROUP BY InstrumentID
HAVING COUNT(*) > 1
 ORDER BY ProviderCount DESC;
```

### 8.3 Resolve instrument to ticker for a specific provider
```sql
SELECT InstrumentID, LiquidityProviderID, Ticker
  FROM Trade.GetProvidersTradonomiContracts WITH (NOLOCK)
 WHERE InstrumentID = @InstrumentID
   AND LiquidityProviderID = @LiquidityProviderID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.6/10 (Elements: 8/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetProvidersTradonomiContracts | Type: View | Source: etoro/etoro/Trade/Views/Trade.GetProvidersTradonomiContracts.sql*
