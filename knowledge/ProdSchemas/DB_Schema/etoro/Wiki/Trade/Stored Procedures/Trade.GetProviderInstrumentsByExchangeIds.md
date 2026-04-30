# Trade.GetProviderInstrumentsByExchangeIds

> Returns instrument trading parameters (InstrumentID, Precision, MinimumSpread) from Trade.ProviderToInstrument, filtered by a comma-separated list of exchange IDs. If no exchange filter is provided, returns all instruments for ProviderID=1.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Exchanges NVARCHAR(MAX) = NULL |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves instrument precision and minimum spread data for use in price display and order validation. The optional @Exchanges parameter allows filtering to instruments on specific exchanges (e.g., for a market-specific instrument configuration load). When @Exchanges is NULL, the procedure returns all instruments for ProviderID=1 (the primary/default liquidity provider).

The Precision and MinimumSpread values are used by trading engines and UIs to display prices at the correct decimal precision and enforce minimum spread requirements on orders.

Note: the @Exchanges-filtered branch does NOT restrict by ProviderID - it returns all provider-instrument records for the given exchanges, regardless of provider.

Data flows: If @Exchanges is NULL: SELECT directly from Trade.ProviderToInstrument WHERE ProviderID=1. If @Exchanges is not NULL: STRING_SPLIT into #ExchangeIds, JOIN to InstrumentMetaData on ExchangeID, return matching instruments.

---

## 2. Business Logic

### 2.1 Two-Path Logic: All Provider-1 vs Exchange-Filtered

**What**: Two mutually exclusive paths based on whether an exchange filter is provided.

**Columns/Parameters Involved**: `@Exchanges`, `ProviderID`

**Rules**:
- @Exchanges IS NULL: return all Trade.ProviderToInstrument rows WHERE ProviderID=1 (default provider).
- @Exchanges NOT NULL: parse comma-separated exchange IDs, return all instruments on those exchanges (no ProviderID filter in this path).
- @Exchanges format: comma-delimited list of integers, e.g., '1,3,5'.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Exchanges | NVARCHAR(MAX) | YES | NULL | CODE-BACKED | Comma-separated list of ExchangeIDs to filter by (e.g., '1,3,31'). NULL = return all instruments for ProviderID=1 with no exchange filter. |

**Output Columns**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Traded instrument identifier. FK to Trade.Instrument. |
| 3 | Precision | INT | YES | - | CODE-BACKED | Number of decimal places for price display. E.g., 5 = display to 5 decimal places. |
| 4 | MinimumSpread | DECIMAL | YES | - | CODE-BACKED | Minimum allowed spread for orders on this instrument. Used for order validation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.ProviderToInstrument | Primary source | Precision and MinimumSpread per instrument |
| InstrumentID | Trade.InstrumentMetaData | JOIN (exchange filter path) | ExchangeID lookup for filtering |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading engine / configuration service | @Exchanges | Application call | Loads instrument precision and spread config on startup or exchange-specific refresh |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetProviderInstrumentsByExchangeIds (procedure)
+-- Trade.ProviderToInstrument (table) [primary source]
+-- Trade.InstrumentMetaData (table) [ExchangeID filter, exchange-filtered path only]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | InstrumentID, Precision, MinimumSpread per provider-instrument |
| Trade.InstrumentMetaData | Table | ExchangeID lookup for filtering when @Exchanges is provided |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading engine / config loader | External application | Instrument precision and spread data load |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure (temp table: #ExchangeIds with PRIMARY KEY on ExchangeID).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| ProviderID=1 filter | Business rule | NULL path restricted to primary/default provider (ProviderID=1) |
| No ProviderID filter in exchange path | Design | Exchange-filtered path returns across all providers |
| STRING_SPLIT parsing | Input | @Exchanges must be comma-separated integers; no validation performed |

---

## 8. Sample Queries

### 8.1 Get all instruments for the default provider

```sql
EXEC Trade.GetProviderInstrumentsByExchangeIds; -- @Exchanges = NULL
```

### 8.2 Get instruments for specific exchanges

```sql
EXEC Trade.GetProviderInstrumentsByExchangeIds @Exchanges = '1,3,31';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 8/10, Logic: 9/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetProviderInstrumentsByExchangeIds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetProviderInstrumentsByExchangeIds.sql*
