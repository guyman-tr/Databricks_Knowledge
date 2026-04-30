# Price.GetInstrumentRateSources

> Enriched instrument rate source view that adds human-readable source names, benchmark designation, and quality scores to the raw InstrumentRateSources priority table - the primary read API for pricing configuration dashboards and tooling.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | View |
| **Key Identifier** | InstrumentID + AccountRateSourceID (composite) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetInstrumentRateSources answers: "For each instrument, what are its configured rate sources with human-readable names, priorities, benchmark status, and quality scores?" It enriches the raw Price.InstrumentRateSources routing table with four additional attributes: the source name from Price.AccountRateSource, the price server ID from Trade.Instrument, the benchmark flag from Price.BenchmarkFeedConfiguration, and the benchmark quality score.

The view exists so pricing configuration tools, dashboards, and operations queries can read a fully-labelled source allocation table without joining AccountRateSource and BenchmarkFeedConfiguration manually. It is the standard read interface for the instrument-to-source routing configuration.

Data: mirrors Price.InstrumentRateSources row count (656 rows). EUR/USD (ID=1) has two rows: primary "ZBFX Price1" (ARS=21, Priority=10, PriceServerID=1) and secondary "FD Demo" (ARS=301, Priority=30). All IsBenchmark=0 and Quality=-1 (BenchmarkFeedConfiguration is empty). PriceServerID varies by instrument (1 for most; 3 for GBP/USD etc.), indicating different price servers handle different instruments.

---

## 2. Business Logic

### 2.1 Rate Source Name Resolution

**What**: AccountRateSourceID (integer) is resolved to its human-readable Name via LEFT JOIN to Price.AccountRateSource.

**Columns/Parameters Involved**: `AccountRateSourceID`, `Name`

**Rules**:
- LEFT JOIN to AccountRateSource: Name is NULL if no matching AccountRateSource row (unusual, would indicate orphaned config)
- Name examples from live data: "ZBFX Price1" (ARS=21), "FD Demo" (ARS=301), "FX NDF Provider" (ARS=300)
- The Name column is the human-readable label used in all tooling and dashboards to identify the price feed

### 2.2 Benchmark and Quality Flag

**What**: IsBenchmark and Quality indicate whether this rate source is designated as the benchmark for the instrument's type, and the quality score of that benchmark designation.

**Columns/Parameters Involved**: `IsBenchmark`, `Quality`, `AccountRateSourceID`

**Rules**:
- LEFT JOIN Price.BenchmarkFeedConfiguration ON BenchmarkAccountRateSourceID = AccountRateSourceID AND InstrumentTypeID = CurrencyTypeID
- IsBenchmark = IIF(BenchmarkAccountRateSourceID IS NULL, 0, 1): 1 if this source is designated as benchmark for this instrument's type
- Quality = ISNULL(BFC.Quality, -1): the benchmark quality score; -1 when no benchmark configured (BenchmarkFeedConfiguration is currently empty, so always -1)
- The InstrumentTypeID for the JOIN comes from Trade.GetInstrument (not Trade.Instrument - the GI JOIN provides it)

### 2.3 Dual Instrument JOIN Pattern

**What**: The view joins both Trade.Instrument (for PriceServerID) and Trade.GetInstrument (for InstrumentTypeID used in the benchmark JOIN). Two separate instrument sources serve different purposes.

**Columns/Parameters Involved**: `PriceServerID`, `InstrumentTypeID`

**Rules**:
- Trade.Instrument (INNER JOIN): provides PriceServerID; ensures instrument exists at the base table level
- Trade.GetInstrument (INNER JOIN): provides InstrumentTypeID for the BenchmarkFeedConfiguration JOIN; also filters out placeholder/incomplete instruments (InstrumentID != 0, InstrumentTypeID NOT NULL)
- Both JOINs must succeed; instruments failing either are excluded from results

---

## 3. Data Overview

| PriceServerID | InstrumentID | AccountRateSourceID | Name | Priority | IsBenchmark | Quality | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | 1 | 21 | ZBFX Price1 | 10 | 0 | -1 | EUR/USD primary source: ZBFX Price1 via price server 1. Highest priority, queried first. No benchmark configured. |
| 1 | 1 | 301 | FD Demo | 30 | 0 | -1 | EUR/USD tertiary fallback: FD Demo. Note Priority=30 (no P20 row for this instrument). |
| 3 | 2 | 21 | ZBFX Price1 | 10 | 0 | -1 | GBP/USD primary: ZBFX Price1 via price server 3. Different PriceServerID shows GBP/USD routes to a different server than EUR/USD. |
| 1 | 3 | 21 | ZBFX Price1 | 10 | 0 | -1 | Instrument 3 primary: ZBFX Price1. |
| 1 | 3 | 300 | FX NDF Provider | 20 | 0 | -1 | Instrument 3 secondary: FX NDF Provider (ARS=300). Has a true P20 secondary source. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PriceServerID | int | NO | - | CODE-BACKED | Price server instance identifier from Trade.Instrument. Identifies which price server handles this instrument. Different instruments may route to different servers (PriceServerID=1 vs 3 seen in data). |
| 2 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier from Price.InstrumentRateSources. Must exist in both Trade.Instrument and Trade.GetInstrument. |
| 3 | AccountRateSourceID | int | NO | - | CODE-BACKED | Rate source identifier from Price.InstrumentRateSources. FK to Price.AccountRateSource. Integer key resolved to Name in this view. |
| 4 | Name | varchar(50) | YES | - | CODE-BACKED | Human-readable name of the rate source from Price.AccountRateSource. Examples: "ZBFX Price1", "FD Demo", "FX NDF Provider". NULL only if AccountRateSourceID has no matching row in AccountRateSource (data integrity issue). |
| 5 | Priority | int | NO | - | CODE-BACKED | Feed priority tier from Price.InstrumentRateSources: 10=primary, 20=secondary, 30=tertiary, 40=quaternary. Lower value = higher precedence. An instrument may skip tiers (e.g., P10 and P30 but no P20). |
| 6 | IsBenchmark | int | NO | - | CODE-BACKED | Whether this source is the designated benchmark for the instrument's type: 1=benchmark, 0=not benchmark. Computed: IIF(BenchmarkAccountRateSourceID IS NULL, 0, 1). Currently always 0 (BenchmarkFeedConfiguration is empty). |
| 7 | Quality | decimal/int | NO | - | CODE-BACKED | Benchmark quality score from Price.BenchmarkFeedConfiguration. -1 when no benchmark is configured (ISNULL default). A positive value indicates the quality weight of this benchmark source for the instrument's type. Currently always -1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Price.InstrumentRateSources | FROM source | Priority routing configuration |
| InstrumentID + PriceServerID | Trade.Instrument | INNER JOIN | Provides PriceServerID, validates instrument |
| InstrumentID | Trade.GetInstrument | INNER JOIN | Provides InstrumentTypeID for benchmark match, additional validation |
| AccountRateSourceID + Name | Price.AccountRateSource | LEFT JOIN | Resolves rate source name |
| AccountRateSourceID + IsBenchmark + Quality | Price.BenchmarkFeedConfiguration | LEFT JOIN | Benchmark designation per source-type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - no stored procedures found referencing this view directly in the Price schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetInstrumentRateSources (view)
├── Price.InstrumentRateSources (table)
├── Price.AccountRateSource (table)
├── Price.BenchmarkFeedConfiguration (table)
├── Trade.Instrument (table)
└── Trade.GetInstrument (view)
      ├── Trade.Instrument (table)
      ├── Dictionary.Currency (table)
      └── Trade.InstrumentMetaData (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentRateSources | Table | FROM - core routing data (InstrumentID, AccountRateSourceID, Priority) |
| Price.AccountRateSource | Table | LEFT JOIN on AccountRateSourceID - resolves Name |
| Price.BenchmarkFeedConfiguration | Table | LEFT JOIN on ARS + InstrumentTypeID - IsBenchmark and Quality |
| Trade.Instrument | Table | INNER JOIN on InstrumentID - provides PriceServerID |
| Trade.GetInstrument | View | INNER JOIN on InstrumentID - provides InstrumentTypeID; validates instrument |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Price schema stored procedures | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for view.

### 7.2 Constraints

N/A for view. No SCHEMABINDING. INNER JOINs to Trade.Instrument and Trade.GetInstrument mean instruments not in both are excluded. LEFT JOINs to AccountRateSource and BenchmarkFeedConfiguration allow NULL Name and Quality=-1.

---

## 8. Sample Queries

### 8.1 Get all rate sources for a specific instrument

```sql
SELECT PriceServerID, InstrumentID, AccountRateSourceID, Name, Priority, IsBenchmark, Quality
FROM Price.GetInstrumentRateSources WITH (NOLOCK)
WHERE InstrumentID = 1
ORDER BY Priority;
```

### 8.2 Find all instruments using a specific rate source by name

```sql
SELECT InstrumentID, AccountRateSourceID, Name, Priority
FROM Price.GetInstrumentRateSources WITH (NOLOCK)
WHERE Name = 'ZBFX Price1'
ORDER BY InstrumentID, Priority;
```

### 8.3 Instruments by price server with primary source

```sql
SELECT PriceServerID, InstrumentID, Name AS PrimarySource
FROM Price.GetInstrumentRateSources WITH (NOLOCK)
WHERE Priority = 10
ORDER BY PriceServerID, InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 5, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetInstrumentRateSources | Type: View | Source: etoro/etoro/Price/Views/Price.GetInstrumentRateSources.sql*
