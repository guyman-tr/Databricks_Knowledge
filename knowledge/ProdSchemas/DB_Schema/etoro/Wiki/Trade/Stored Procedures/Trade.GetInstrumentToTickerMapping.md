# Trade.GetInstrumentToTickerMapping

> Returns instrument-to-ticker mappings for a batch of instruments from a specific liquidity provider, similar to GetInstrumentsForDataApi but with TVP input for targeted lookups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns InstrumentID + Ticker from Trade.LiquidityProviderContracts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentToTickerMapping returns the external ticker symbol for a set of instruments from a specific liquidity provider. Unlike GetInstrumentsForDataApi (which returns ALL tickers for a provider), this procedure accepts a TVP of specific instrument IDs, making it suitable for targeted lookups during order routing when only certain instruments need ticker resolution.

The procedure reads from Trade.LiquidityProviderContracts filtered by both the input instrument set and the provider type ID. Uses Trade.Tv_InstrumentToTickerMapping TVP (which has an `ID` column, not `InstrumentID`).

---

## 2. Business Logic

### 2.1 Provider-Specific Ticker Resolution for Instrument Subset

**What**: Resolves tickers for a specific set of instruments from one liquidity provider.

**Columns/Parameters Involved**: `@InstrumentID`, `@ProviderTypeID`, `Trade.LiquidityProviderContracts.LiquidityProviderID`, `Trade.LiquidityProviderContracts.Ticker`

**Rules**:
- @InstrumentID TVP uses `ID` column (not `InstrumentID`) - different TVP type than Trade.InstrumentIDsTbl
- @ProviderTypeID maps to LiquidityProviderContracts.LiquidityProviderID
- Uses IN subquery rather than JOIN for instrument filtering
- No validation; missing instruments simply return no rows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | Trade.Tv_InstrumentToTickerMapping (READONLY) | NO | - | CODE-BACKED | TVP containing instrument IDs (column `ID`) to look up. Different type from Trade.InstrumentIDsTbl. |
| 2 | @ProviderTypeID | int | NO | - | CODE-BACKED | Liquidity provider ID to retrieve tickers for. Maps to LiquidityProviderContracts.LiquidityProviderID. |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | LiquidityProviderContracts.InstrumentID | CODE-BACKED | Instrument identifier. |
| R2 | Ticker | nvarchar | LiquidityProviderContracts.Ticker | CODE-BACKED | External ticker symbol used by the specified liquidity provider. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Trade.Tv_InstrumentToTickerMapping | TVP Type | Input parameter type |
| FROM | Trade.LiquidityProviderContracts | Read (SELECT) | Source of instrument-ticker mappings |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentToTickerMapping (procedure)
+-- Trade.LiquidityProviderContracts (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.LiquidityProviderContracts | Table | SELECT WHERE - source of tickers filtered by provider and instrument set |
| Trade.Tv_InstrumentToTickerMapping | User Defined Type | TVP type for @InstrumentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Order routing services | Application | Targeted ticker resolution during order execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get tickers for instruments from provider 1

```sql
DECLARE @Instruments Trade.Tv_InstrumentToTickerMapping;
INSERT INTO @Instruments (ID) VALUES (1), (5), (10);
EXEC Trade.GetInstrumentToTickerMapping @InstrumentID = @Instruments, @ProviderTypeID = 1;
```

### 8.2 View all ticker mappings for a provider

```sql
SELECT  InstrumentID, Ticker
FROM    Trade.LiquidityProviderContracts WITH (NOLOCK)
WHERE   LiquidityProviderID = 1
ORDER BY InstrumentID;
```

### 8.3 Find instruments with tickers across multiple providers

```sql
SELECT  InstrumentID, COUNT(DISTINCT LiquidityProviderID) AS ProviderCount
FROM    Trade.LiquidityProviderContracts WITH (NOLOCK)
GROUP BY InstrumentID
HAVING COUNT(DISTINCT LiquidityProviderID) > 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentToTickerMapping | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentToTickerMapping.sql*
