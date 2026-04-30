# Price.PricingConfigurations

> Central per-instrument pricing engine configuration table that defines how each instrument's price is computed and distributed: the pricing algorithm type, distribution channel flags, provider association, and rate throttling parameters.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID (int, CLUSTERED PK) |
| **Partition** | Yes - DICTIONARY partition scheme on InstrumentID (DATA_COMPRESSION = PAGE) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

PricingConfigurations is the master configuration table for the pricing engine's per-instrument behavior. With 10,335 rows covering nearly all active instruments, it defines:

1. **How prices are calculated** (`PricingType`): Standard (0) vs Raw Redistribution (1)
2. **How prices are distributed** (`DistributionType`): A bitmask indicating which client/system distribution channels receive prices for this instrument
3. **Rate throttling** (`TopOfBookThrottlingInMs`, `FeedThrottlingInMs`, `ClientThrottlingInMs`): Minimum milliseconds between price updates for top-of-book data, feed data, and client-facing prices
4. **Provider association** (`ProviderId`): The pricing provider (currently only populated for raw redistribution instruments)
5. **Account identity** (`AccountId`): Provider account string (e.g., "RawRedistribution" for PricingType=1)

The `Price.GetPricingConfigurations` procedure is the primary consumer: it joins with `Trade.ProviderToInstrument` (adds Precision and AboveDollarPrecision for decimal formatting) and `Trade.InstrumentMetaData` (adds PriceSourceID as "PricesBy"), returning paginated results with cursor-based pagination (@First/@After).

`Price.InsertPricingConfiguration` has a critical side effect: inserting a new pricing configuration also inserts a default row into `Trade.InstrumentSpread`, creating the spread baseline for the instrument in a single atomic transaction.

The table uses PAGE compression and the DICTIONARY partition scheme - reflecting its large, read-intensive, rarely-modified access pattern.

---

## 2. Business Logic

### 2.1 DistributionType - Bitmask Channel Flags

**What**: DistributionType is a bitmask that controls which price distribution channels receive prices for this instrument.

**Columns/Parameters Involved**: `DistributionType`

**Rules**:
- `GetPricingConfigurations` filters using bitwise AND: `(PC.DistributionType & @DistributionType) <> 0` - any overlapping bit means the instrument is included
- Value 0 = no distribution channels (explicitly excluded instruments); queried via `@DistributionType = 0 AND PC.DistributionType = 0`
- Value 1 = channel 1 only (10,333 rows - the standard case: most instruments)
- Value 3 = channels 1 AND 2 (2 rows - instruments 1005 and 1010 distributed to both channels)
- Specific channel meaning (bit 1 vs bit 2) depends on the pricing engine's channel configuration

### 2.2 PricingType - Pricing Algorithm Selection

**What**: PricingType selects the algorithm used to compute this instrument's price.

**Columns/Parameters Involved**: `PricingType`, `AccountId`, `ProviderId`

**Rules**:
- PricingType=0 (Standard): 10,326 rows (99.9% of instruments). Standard pricing algorithm - computes prices from feed data with spread, skew, and throttling applied
- PricingType=1 (Raw Redistribution): 9 rows. Prices are redistributed directly from raw feed without standard algorithm processing. AccountId="RawRedistribution", ProviderId=1. These are instruments priced as-is from source
- When @PricingType filter is NULL in GetPricingConfigurations, all types are returned

### 2.3 Throttling Parameters

**What**: Three independent throttling controls limit price update frequency at different stages of the pricing pipeline.

**Columns/Parameters Involved**: `TopOfBookThrottlingInMs`, `FeedThrottlingInMs`, `ClientThrottlingInMs`

**Rules**:
- All three are NULL for most instruments (99%+) - meaning the default/global throttling applies
- TopOfBookThrottlingInMs: minimum interval between top-of-book price publication updates
- FeedThrottlingInMs: minimum interval between internal feed price updates
- ClientThrottlingInMs: minimum interval between prices sent to clients
- Only populated for instruments that need non-default throttling (high-frequency instruments or instruments requiring slower client price updates)

### 2.4 InsertPricingConfiguration - Cascade to InstrumentSpread

**What**: Creating a new pricing configuration automatically creates a default spread baseline for the instrument.

**Columns/Parameters Involved**: `InstrumentID`

**Rules**:
- `Price.InsertPricingConfiguration` inserts into PricingConfigurations AND then inserts into `Trade.InstrumentSpread` (SpreadTypeID=1, Bid=0, Ask=0, MarketSpreadThreshold=0, ReferenceBid=0, ReferenceAsk=0, SpreadThresholdTypeID=1, FeedID=1) in a single transaction
- If either insert fails, both are rolled back (TRY/CATCH with ROLLBACK)
- This means: every instrument in PricingConfigurations should have a corresponding row in Trade.InstrumentSpread

### 2.5 GetPricingConfigurations - Paginated Read API

**What**: The primary read procedure returns configuration rows enriched with precision and pricing source metadata, with cursor-based pagination.

**Columns/Parameters Involved**: All columns, plus Precision and AboveDollarPrecision from Trade.ProviderToInstrument, PricesBy from Trade.InstrumentMetaData

**Rules**:
- @First = page size (default 10000 - effectively no limit when NULL)
- @After = last-seen InstrumentID for cursor-based pagination (returns rows WHERE InstrumentID > @After)
- Returns HasNextPage and EndCursor for GraphQL-style cursor pagination
- INNER JOIN with Trade.ProviderToInstrument and Trade.InstrumentMetaData means instruments without entries in those tables are excluded

---

## 3. Data Overview

| InstrumentID | DistributionType | PricingType | ProviderId | AccountId | Meaning |
|---|---|---|---|---|---|
| 1 (EUR/USD) | 1 | 0 | NULL | NULL | Standard pricing, channel 1 distribution, no throttling |
| 2 | 1 | 0 | NULL | NULL | Standard pricing, same pattern as most instruments |
| 1005 | 3 | 0 | NULL | NULL | Standard pricing BUT distributed on both channels 1 AND 2 |
| 1010 | 3 | 0 | NULL | NULL | Same dual-channel distribution |
| 1001488 | 1 | 1 | 1 | RawRedistribution | Raw feed redistribution - price passed through unchanged from provider 1 |

Total: 10,335 rows. DistributionType: 10333 (type=1), 2 (type=3). PricingType: 10326 (type=0), 9 (type=1).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Primary key. The instrument this pricing configuration applies to. No FK constraint in DDL - InstrumentID validity enforced procedurally (InsertPricingConfiguration performs a transaction with Trade.InstrumentSpread, implying the instrument must already exist). One configuration per instrument. |
| 2 | DistributionType | tinyint | NOT NULL | - | VERIFIED | Bitmask flag indicating which price distribution channels receive this instrument's prices. Value 1 = channel 1 (standard, 99.98% of instruments); value 3 = channels 1+2 (2 instruments). Queried via bitwise AND: `(DistributionType & @filter) <> 0`. Value 0 = no distribution (excluded). |
| 3 | PricingType | tinyint | NOT NULL | - | VERIFIED | The pricing algorithm type. 0=Standard (10,326 rows, default - prices computed through full pricing pipeline with spread, skew, throttling); 1=RawRedistribution (9 rows - prices passed through from raw feed without modification, AccountId="RawRedistribution"). |
| 4 | ProviderId | int | YES | - | VERIFIED | The pricing provider association. NULL for standard instruments (99.9%). Only populated for PricingType=1 rows (ProviderId=1 for all RawRedistribution instruments). Likely references an external provider registry not in this DB. |
| 5 | TopOfBookThrottlingInMs | int | YES | - | VERIFIED | Minimum milliseconds between top-of-book price update publications. NULL = use default/global throttling. Only set for instruments requiring non-standard top-of-book rate limiting. |
| 6 | FeedThrottlingInMs | int | YES | - | VERIFIED | Minimum milliseconds between internal feed price updates for this instrument. NULL = use default. Controls the rate at which raw feed ticks are processed. |
| 7 | ClientThrottlingInMs | int | YES | - | VERIFIED | Minimum milliseconds between price updates sent to clients for this instrument. NULL = use default. Client-facing rate limiter - instruments with slow price movement may have a higher client throttle to reduce unnecessary updates. |
| 8 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set on DML. |
| 9 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). |
| 10 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. |
| 11 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Historical versions in History.PricingConfigurations. |
| 12 | AccountId | varchar(100) | YES | - | VERIFIED | Provider account identifier string. NULL for most instruments. Set to "RawRedistribution" for all PricingType=1 instruments. May support other values for future provider account types. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Logical (no FK constraint) | Instrument being configured; enforced by application layer |
| InstrumentID | Trade.ProviderToInstrument | JOIN (in GetPricingConfigurations) | Joined to retrieve Precision and AboveDollarPrecision for display formatting |
| InstrumentID | Trade.InstrumentMetaData | JOIN (in GetPricingConfigurations) | Joined to retrieve PriceSourceID (as "PricesBy" in output) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.GetPricingConfigurations | InstrumentID | READER | Paginated read with enrichment from ProviderToInstrument and InstrumentMetaData |
| Price.GetPricingConfigurationsByInstrumentIds | InstrumentID | READER | Returns configurations for a specific list of instrument IDs |
| Price.InsertPricingConfiguration | InstrumentID | WRITER | Inserts new configuration; also inserts default row into Trade.InstrumentSpread |
| Price.UpdatePricingConfigurations | InstrumentID | MODIFIER | Updates configuration fields for existing instruments |
| Price.CheckPricingConfigurationsExistence | InstrumentID | READER | Checks whether a pricing configuration exists for given instruments |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.PricingConfigurations (table)
|- (no FK constraints - all dependencies are logical/procedural)
|- Trade.ProviderToInstrument (joined in GetPricingConfigurations for Precision)
|- Trade.InstrumentMetaData (joined in GetPricingConfigurations for PriceSourceID)
|- Trade.InstrumentSpread (INSERT cascade via InsertPricingConfiguration)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | JOINED in GetPricingConfigurations to enrich output with Precision and AboveDollarPrecision |
| Trade.InstrumentMetaData | Table | JOINED in GetPricingConfigurations to enrich output with PriceSourceID (PricesBy) |
| Trade.InstrumentSpread | Table | Cascade INSERT target in InsertPricingConfiguration - default spread row created alongside config |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.GetPricingConfigurations | Stored Procedure | READER - paginated read with cursor pagination |
| Price.GetPricingConfigurationsByInstrumentIds | Stored Procedure | READER - reads by instrument ID list |
| Price.InsertPricingConfiguration | Stored Procedure | WRITER - inserts with Trade.InstrumentSpread cascade |
| Price.UpdatePricingConfigurations | Stored Procedure | MODIFIER - updates throttling and type fields |
| Price.CheckPricingConfigurationsExistence | Stored Procedure | READER - existence check |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PricingConfigurations | CLUSTERED PK | InstrumentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_PricingConfigurations | PRIMARY KEY | One pricing configuration per instrument (InstrumentID) |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.PricingConfigurations |
| TRG_INSERT_PricingConfigurations | TRIGGER (INSERT) | ASM no-op: self-update on PricingType after insert (temporal refresh) |
| DATA_COMPRESSION = PAGE | Storage | Page-level compression reduces storage footprint for this large, stable table |

Note: Partitioned on [DICTIONARY] scheme (vs [MAIN] on most other Price tables) - unusual and may reflect a design decision to co-locate with dictionary/reference data.

---

## 8. Sample Queries

### 8.1 View configurations with pricing type labels

```sql
SELECT
    InstrumentID,
    DistributionType,
    CASE PricingType WHEN 0 THEN 'Standard' WHEN 1 THEN 'RawRedistribution' ELSE CAST(PricingType AS VARCHAR) END AS PricingTypeName,
    ProviderId,
    AccountId,
    TopOfBookThrottlingInMs,
    FeedThrottlingInMs,
    ClientThrottlingInMs
FROM Price.PricingConfigurations WITH (NOLOCK)
ORDER BY InstrumentID;
```

### 8.2 Find all Raw Redistribution instruments

```sql
SELECT InstrumentID, ProviderId, AccountId
FROM Price.PricingConfigurations WITH (NOLOCK)
WHERE PricingType = 1
ORDER BY InstrumentID;
```

### 8.3 Find instruments with non-default throttling configured

```sql
SELECT
    InstrumentID,
    TopOfBookThrottlingInMs,
    FeedThrottlingInMs,
    ClientThrottlingInMs
FROM Price.PricingConfigurations WITH (NOLOCK)
WHERE TopOfBookThrottlingInMs IS NOT NULL
   OR FeedThrottlingInMs IS NOT NULL
   OR ClientThrottlingInMs IS NOT NULL
ORDER BY InstrumentID;
```

### 8.4 Enriched view with precision and price source (using the stored proc pattern)

```sql
SELECT
    PC.InstrumentID,
    PC.DistributionType,
    PC.PricingType,
    PC.AccountId,
    isnull(PTI.Precision, 4) AS Precision,
    isnull(PTI.AboveDollarPrecision, 2) AS AboveDollarPrecision,
    IMD.PriceSourceID AS PricesBy
FROM Price.PricingConfigurations PC WITH (NOLOCK)
INNER JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK) ON PC.InstrumentID = PTI.InstrumentID
INNER JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK) ON PC.InstrumentID = IMD.InstrumentID
ORDER BY PC.InstrumentID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.PricingConfigurations | Type: Table | Source: etoro/etoro/Price/Tables/Price.PricingConfigurations.sql*
