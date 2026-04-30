# Trade.GetInstrumentsForDataApi

> Returns instrument ID-to-ticker mappings for a specific liquidity provider, enabling the Engine Data API to map internal instrument IDs to external provider ticker symbols.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + Ticker filtered by LiquidityProviderID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsForDataApi is a getter procedure that returns the instrument-to-ticker mapping for a specific liquidity provider. Liquidity providers (market makers and data sources) use their own ticker symbols for instruments (e.g., "AAPL.US" vs internal "AAPL"), and Trade.LiquidityProviderContracts stores the mapping between eToro internal InstrumentIDs and each provider's ticker nomenclature.

This procedure exists because the Engine Data API needs to translate between internal instrument IDs and external provider tickers when sending/receiving market data and order flow. Each liquidity provider may use different ticker conventions, so the mapping is provider-specific.

Created by Adam Porat on 2021-06-06. Called by the EngineDataApi service account for price feed integration and order routing.

---

## 2. Business Logic

### 2.1 Provider-Specific Ticker Resolution

**What**: Maps internal instrument IDs to the external ticker symbols used by a specific liquidity provider.

**Columns/Parameters Involved**: `@LiquidityProviderID`, `Trade.LiquidityProviderContracts.InstrumentID`, `Trade.LiquidityProviderContracts.Ticker`

**Rules**:
- Each liquidity provider has its own set of ticker symbols for instruments
- The same InstrumentID may have different Ticker values across different providers
- Filtered by @LiquidityProviderID to return only one provider's mappings at a time
- No validation; a non-existent LiquidityProviderID returns empty results

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @LiquidityProviderID | int | NO | - | CODE-BACKED | Identifies which liquidity provider's ticker mappings to retrieve. FK to the liquidity provider dimension. Each provider has unique ticker conventions. |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Trade.LiquidityProviderContracts.InstrumentID | CODE-BACKED | Internal eToro instrument identifier. FK to Trade.Instrument. |
| R2 | Ticker | nvarchar | Trade.LiquidityProviderContracts.Ticker | CODE-BACKED | External ticker symbol used by the specified liquidity provider for this instrument (e.g., "AAPL.US", "EUR/USD", "BTCUSD"). Used by Engine Data API for price feed mapping and order routing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.LiquidityProviderContracts | Read (SELECT) | Source of instrument-to-ticker mappings per liquidity provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| EngineDataApi | EXECUTE | Permission | Engine Data API service for price feed integration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsForDataApi (procedure)
+-- Trade.LiquidityProviderContracts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderContracts | Table | SELECT WHERE LiquidityProviderID - source of instrument-ticker mappings |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| EngineDataApi | DB User | EXECUTE permission for price feed instrument resolution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get ticker mappings for a specific liquidity provider

```sql
EXEC Trade.GetInstrumentsForDataApi @LiquidityProviderID = 1;
```

### 8.2 Compare ticker conventions across providers

```sql
SELECT  LiquidityProviderID,
        InstrumentID,
        Ticker
FROM    Trade.LiquidityProviderContracts WITH (NOLOCK)
WHERE   InstrumentID = 1001
ORDER BY LiquidityProviderID;
```

### 8.3 Find instruments with ticker mappings for a provider with display names

```sql
SELECT  lpc.InstrumentID,
        imd.InstrumentDisplayName,
        lpc.Ticker
FROM    Trade.LiquidityProviderContracts lpc WITH (NOLOCK)
        INNER JOIN Trade.InstrumentMetaData imd WITH (NOLOCK) ON lpc.InstrumentID = imd.InstrumentID
WHERE   lpc.LiquidityProviderID = 1
ORDER BY imd.InstrumentDisplayName;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsForDataApi | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsForDataApi.sql*
