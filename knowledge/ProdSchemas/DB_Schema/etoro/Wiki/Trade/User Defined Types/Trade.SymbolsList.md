# Trade.SymbolsList

> A table-valued parameter type for passing batches of instrument ticker symbols to stored procedures, with binary collation for case-sensitive matching and built-in deduplication.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | Symbol (nvarchar(100)) - clustered PK |
| **Partition** | N/A |
| **Indexes** | Clustered PK on Symbol |

---

## 1. Business Meaning

Trade.SymbolsList is a table-valued parameter (TVP) type for passing sets of instrument ticker symbols into stored procedures. Unlike the numeric ID-based TVPs (InstrumentIDsTbl, IdIntList), this type works with human-readable ticker symbols like "AAPL", "BTCUSD", or "EURUSD" - enabling lookups by symbol name rather than internal ID.

This type exists to support the US aggregation reporting flow, which needs to aggregate position data by ticker symbol. The Latin1_General_BIN binary collation ensures exact, case-sensitive matching - "AAPL" and "aapl" are treated as different symbols. The IGNORE_DUP_KEY=ON on the clustered PK silently discards duplicate symbols rather than raising an error, making it safe to insert from sources that may contain duplicates.

Application services populate this type from external symbol lists or user requests, and pass it to procedures that resolve symbols to instruments and aggregate data.

---

## 2. Business Logic

### 2.1 Binary Collation for Symbol Matching

**What**: Case-sensitive exact matching of ticker symbols

**Columns/Parameters Involved**: `Symbol`

**Rules**:
- Latin1_General_BIN collation means comparisons are byte-for-byte: "AAPL" != "aapl"
- This matches the exchange convention where ticker symbols are case-sensitive
- Prevents false matches between differently-cased symbols

### 2.2 Deduplication via IGNORE_DUP_KEY

**What**: Automatic silent deduplication of input symbols

**Columns/Parameters Involved**: `Symbol`

**Rules**:
- IGNORE_DUP_KEY=ON on the clustered PK means inserting a duplicate symbol is silently ignored (no error)
- Callers can safely INSERT from sources that may contain duplicate symbols without pre-filtering
- The procedure always receives a deduplicated set

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Symbol | nvarchar(100) | NO | - | CODE-BACKED | Instrument ticker symbol (e.g., "AAPL", "BTCUSD", "EURUSD"). Uses Latin1_General_BIN binary collation for case-sensitive matching. Clustered PK with IGNORE_DUP_KEY=ON silently deduplicates input. Maximum 100 characters accommodates even the longest composite symbols. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references. Symbol semantically references Trade.Instrument.SymbolFull but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.USAggregatePositionBySymbol | @Symbols | Parameter (TVP) | Aggregates US position data by ticker symbol for regulatory reporting |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.USAggregatePositionBySymbol | Stored Procedure | READONLY parameter for US regulatory aggregation by symbol |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK) | CLUSTERED | Symbol ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY | PK | IGNORE_DUP_KEY = ON - duplicate symbols are silently discarded, not rejected |

---

## 8. Sample Queries

### 8.1 Declare and populate a SymbolsList for US aggregation

```sql
DECLARE @Symbols Trade.SymbolsList;
INSERT INTO @Symbols (Symbol) VALUES (N'AAPL'), (N'TSLA'), (N'MSFT');
EXEC Trade.USAggregatePositionBySymbol @Symbols = @Symbols;
```

### 8.2 Demonstrate deduplication behavior

```sql
DECLARE @Symbols Trade.SymbolsList;
INSERT INTO @Symbols (Symbol) VALUES (N'AAPL'), (N'TSLA'), (N'AAPL');
SELECT * FROM @Symbols;
-- Returns 2 rows: AAPL, TSLA (duplicate silently dropped)
```

### 8.3 Populate from instrument table for a specific exchange

```sql
DECLARE @ExchangeSymbols Trade.SymbolsList;
INSERT INTO @ExchangeSymbols (Symbol)
SELECT  SymbolFull
FROM    Trade.Instrument WITH (NOLOCK)
WHERE   ExchangeID = 10;

EXEC Trade.USAggregatePositionBySymbol @Symbols = @ExchangeSymbols;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SymbolsList | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.SymbolsList.sql*
