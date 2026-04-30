# Trade.GetInstrumentsRateSourceAllocationsByExchangeIds

> Returns price rate source allocation data for instruments, optionally filtered by exchange IDs, enabling the Dealing Front to view which liquidity accounts feed prices to each instrument.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns allocation data from Price.GetInstrumentAllocationData |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInstrumentsRateSourceAllocationsByExchangeIds returns the rate source allocation configuration for instruments - which liquidity accounts supply price data for each instrument, their priority ranking, and whether they serve as the benchmark source. This is critical for the price aggregation engine that combines multiple rate sources into a single tradable price.

This procedure exists because the Dealing Front needs visibility into price feed allocation per instrument for monitoring and troubleshooting. When price feeds diverge, dealers need to see which sources are active and their priority order.

When @Exchanges is NULL, all instrument allocations are returned. When provided, results are filtered to instruments on specified exchanges. Called by PROD\SQL_Dealing-Front.

---

## 2. Business Logic

### 2.1 Rate Source Allocation Structure

**What**: Each instrument can receive prices from multiple liquidity accounts, ranked by priority with one benchmark source.

**Columns/Parameters Involved**: `InstrumentID`, `AccountRateSourceID`, `Priority`, `LiquidityAccountID`, `IsBenchmark`, `Row`

**Rules**:
- Priority determines which source is preferred when multiple are available (lower = higher priority)
- IsBenchmark flags the source used as the reference rate for spread and margin calculations
- Each row represents one allocation: one source feeding one instrument
- Same conditional branching pattern as GetInstrumentsPipDifferenceThresholdByExchangeIds

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Exchanges | nvarchar(MAX) | YES | NULL | CODE-BACKED | Optional comma-separated exchange IDs. NULL returns all instruments; provided value filters by exchange via STRING_SPLIT + temp table JOIN. |

**Return Columns**:

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| R1 | InstrumentID | int | Price.GetInstrumentAllocationData | CODE-BACKED | Instrument identifier. |
| R2 | AccountRateSourceID | int | Price.GetInstrumentAllocationData | CODE-BACKED | Rate source account identifier within the price allocation system. |
| R3 | Priority | int | Price.GetInstrumentAllocationData | CODE-BACKED | Priority ranking of this source for the instrument. Lower values = higher priority in the price aggregation engine. |
| R4 | LiquidityAccountID | int | Price.GetInstrumentAllocationData | CODE-BACKED | Liquidity account providing the price feed. Identifies the specific market maker or data source. |
| R5 | IsBenchmark | bit | Price.GetInstrumentAllocationData | CODE-BACKED | 1 = this source is the benchmark rate used for spread and margin calculations; 0 = secondary source. |
| R6 | Row | int | Price.GetInstrumentAllocationData | CODE-BACKED | Row number within the allocation set for ordering purposes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Price.GetInstrumentAllocationData | Read (SELECT) | View providing price allocation data |
| JOIN | Trade.InstrumentMetaData | Read (SELECT) | Used in exchange-filtered path to resolve ExchangeID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PROD\SQL_Dealing-Front | EXECUTE | Permission | Dealing Front surveillance platform |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentsRateSourceAllocationsByExchangeIds (procedure)
+-- Price.GetInstrumentAllocationData (view)
+-- Trade.InstrumentMetaData (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.GetInstrumentAllocationData | View | SELECT - source of allocation data |
| Trade.InstrumentMetaData | Table | JOIN in exchange-filtered path for ExchangeID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| PROD\SQL_Dealing-Front | DB User | EXECUTE permission |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get all instrument rate source allocations

```sql
EXEC Trade.GetInstrumentsRateSourceAllocationsByExchangeIds;
```

### 8.2 Get allocations for specific exchanges

```sql
EXEC Trade.GetInstrumentsRateSourceAllocationsByExchangeIds @Exchanges = '1,5';
```

### 8.3 Find instruments with multiple rate sources

```sql
SELECT  InstrumentID, COUNT(*) AS SourceCount
FROM    Price.GetInstrumentAllocationData
GROUP BY InstrumentID
HAVING COUNT(*) > 1
ORDER BY SourceCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.1/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentsRateSourceAllocationsByExchangeIds | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentsRateSourceAllocationsByExchangeIds.sql*
