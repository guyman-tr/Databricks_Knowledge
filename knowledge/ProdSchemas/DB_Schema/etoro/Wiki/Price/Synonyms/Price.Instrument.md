# Price.Instrument

> Synonym that provides a local Price-schema alias to the Trade.Instrument table on a remote linked server (AO-CANDLES-LSN-ROR), enabling the Price schema to reference candle/analytics instrument data from the AO-CANDLES system without qualifying the full linked server path.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Synonym |
| **Target** | [AO-CANDLES-LSN-ROR].[Candles].[Trade].[Instrument] |
| **Target Type** | Remote Table (via Linked Server) |

---

## 1. Business Meaning

`Price.Instrument` is a SQL Server synonym that creates an alias `Price.Instrument` pointing to `[AO-CANDLES-LSN-ROR].[Candles].[Trade].[Instrument]`. This allows any query within the Price schema (or by Price schema consumers) to reference this remote table using the shorter `Price.Instrument` name instead of the full four-part linked server notation.

The target is a `Trade.Instrument` table on the `AO-CANDLES-LSN-ROR` linked server, which is the "AO Candles" system - an external system (possibly a candles/OHLC data service or analytics database). The synonym is named `Price.Instrument` to distinguish it from the local `Trade.Instrument` table and to emphasize that this is the instrument registry as used by the Candles/AO pricing context.

No stored procedures or views in the Price schema SSDT repo currently reference `Price.Instrument`. The synonym appears to be provisioned for future use or for ad-hoc cross-system queries from the Price schema context.

---

## 2. Business Logic

### 2.1 Remote Instrument Table Alias

**What**: Provides a shorthand reference to the instrument table on the AO-CANDLES linked server.

**Rules**:
- The synonym transparently forwards all queries to the remote table: `SELECT * FROM Price.Instrument` is equivalent to `SELECT * FROM [AO-CANDLES-LSN-ROR].[Candles].[Trade].[Instrument]`
- The remote table structure is the Trade.Instrument schema from the Candles database
- No local caching or transformation - all queries are distributed to the remote server via the linked server connection
- Linked server connection required at runtime; if AO-CANDLES-LSN-ROR is unavailable, queries against this synonym will fail

---

## 3. Data Overview

Data resides on the remote server `[AO-CANDLES-LSN-ROR]`. Structure matches `Trade.Instrument` in the Candles database.

---

## 4. Elements

Not applicable - synonym has no locally-defined columns. Column structure is inherited from the target table: `[AO-CANDLES-LSN-ROR].[Candles].[Trade].[Instrument]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (all columns) | [AO-CANDLES-LSN-ROR].[Candles].[Trade].[Instrument] | SYNONYM (aliased table) | Remote instrument table on the AO-CANDLES linked server |

### 5.2 Referenced By (other objects point to this)

No stored procedures or views in the Price schema SSDT repo currently reference Price.Instrument.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.Instrument (synonym)
|- [AO-CANDLES-LSN-ROR].[Candles].[Trade].[Instrument] (remote table, linked server dependency)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-CANDLES-LSN-ROR].[Candles].[Trade].[Instrument] | Remote Table | Synonym target - the actual data source |

### 6.2 Objects That Depend On This

No dependents found in the Price schema SSDT repo.

---

## 7. Technical Details

### 7.1 Synonym Definition

```sql
CREATE SYNONYM [Price].[Instrument]
FOR [AO-CANDLES-LSN-ROR].[Candles].[Trade].[Instrument]
```

- **Linked Server**: `AO-CANDLES-LSN-ROR` - the AO Candles system (likely an OHLC/candlestick analytics service)
- **Remote Database**: `Candles`
- **Remote Schema**: `Trade`
- **Remote Table**: `Instrument`

---

## 8. Sample Queries

### 8.1 Query remote instrument data via synonym

```sql
-- Note: requires AO-CANDLES-LSN-ROR linked server to be connected
SELECT TOP 10 *
FROM Price.Instrument WITH (NOLOCK)
ORDER BY InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.5/10 (Elements: N/A, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 4, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.Instrument | Type: Synonym | Source: etoro/etoro/Price/Synonyms/Price.Instrument.sql*
