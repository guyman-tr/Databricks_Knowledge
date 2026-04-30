# Price.InsertPricingConfiguration

> Creates a new pricing engine configuration for an instrument in a single atomic transaction: inserts the row into Price.PricingConfigurations and automatically creates a zero-spread baseline in Trade.InstrumentSpread - both or neither.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.InsertPricingConfiguration is the write procedure for onboarding a new instrument to the pricing engine. It does two things atomically:

1. **Creates the pricing configuration** (`Price.PricingConfigurations`): defines how this instrument's price will be computed (PricingType), which distribution channels receive its prices (DistributionType), its provider association, and optional throttling parameters.

2. **Creates the spread baseline** (`Trade.InstrumentSpread`): inserts a default zero-spread row (Bid=0, Ask=0, MarketSpreadThreshold=0, ReferenceBid=0, ReferenceAsk=0, SpreadTypeID=1, SpreadThresholdTypeID=1, FeedID=1). This ensures the pricing engine never encounters a missing spread entry for the new instrument - it starts with a zero spread that can be updated later via Price.SetActiveSkew or the spread management procedures.

The transactional guarantee is critical: without the InstrumentSpread row, the pricing engine would either error or apply undefined spread behavior for the new instrument. The TRY/CATCH + ROLLBACK ensures partial states (PricingConfigurations inserted but InstrumentSpread not) cannot persist.

No validation guards are included (unlike InsertLiquidityProviderPriceSource) - a duplicate InstrumentID would raise a PK violation error from the INSERT itself, which is caught by CATCH and re-raised via THROW.

---

## 2. Business Logic

### 2.1 Atomic Dual-Table Insert

**What**: Two INSERT statements in a single transaction - PricingConfigurations and InstrumentSpread.

**Columns/Parameters Involved**: All parameters, `Trade.InstrumentSpread`

**Rules**:
- `BEGIN TRANSACTION` -> `INSERT PricingConfigurations` -> `INSERT InstrumentSpread` -> `COMMIT`
- `BEGIN CATCH` -> `ROLLBACK; THROW` - on any error, both inserts are rolled back and the original error is re-raised to the caller
- InstrumentSpread hardcoded defaults: SpreadTypeID=1, Bid=0, Ask=0, MarketSpreadThreshold=0, ReferenceBid=0, ReferenceAsk=0, SpreadThresholdTypeID=1, FeedID=1
- The zero spread means: no bid/ask markup initially; the spread becomes effective when updated (e.g., via SetActiveSkew or direct update)

### 2.2 Pricing Configuration Parameters

**What**: All required and optional parameters for the pricing engine configuration row.

**Columns/Parameters Involved**: `@DistributionType`, `@PricingType`, `@ProviderId`, `@AccountId`, `@TopOfBookThrottlingInMs`, `@FeedThrottlingInMs`, `@ClientThrottlingInMs`

**Rules**:
- `@DistributionType INT` (required): bitmask of distribution channels. Standard value: 1 (channel 1 only). Multi-channel: 3 (channels 1+2).
- `@PricingType INT` (required): 0=Standard pricing, 1=Raw Redistribution.
- `@ProviderId INT` (required, but can be 0/NULL for standard instruments): the pricing provider. Populated for PricingType=1.
- `@AccountId VARCHAR(100) NULL` (optional): provider account string. "RawRedistribution" for PricingType=1.
- Throttling parameters: all default NULL (use global pricing engine defaults).

### 2.3 Error Propagation

**What**: Any error in either INSERT is caught, rolled back, and re-raised to the caller.

**Rules**:
- `THROW` (no arguments in CATCH): re-raises the caught exception with original error number, message, and severity. Caller receives the original DB error (e.g., PK violation if InstrumentID already exists in PricingConfigurations).
- No custom RAISERROR messages; errors propagate as-is.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NOT NULL | - | CODE-BACKED | eToro instrument to configure. PK of Price.PricingConfigurations - must be unique. PK violation if instrument already has a configuration. Also inserted into Trade.InstrumentSpread. |
| 2 | @DistributionType | INT | NOT NULL | - | CODE-BACKED | Bitmask of distribution channels: 1=channel 1 (standard for most instruments), 3=channels 1+2, 0=none. Determines which pricing distribution channels receive this instrument's prices. |
| 3 | @PricingType | INT | NOT NULL | - | CODE-BACKED | Pricing algorithm: 0=Standard (default for ~99.9% of instruments), 1=Raw Redistribution (9 instruments - prices distributed as-is from raw feed). |
| 4 | @ProviderId | INT | NOT NULL | - | CODE-BACKED | Pricing provider identifier. Set to the provider ID for PricingType=1 instruments (Raw Redistribution uses ProviderId=1). Standard instruments typically use a default/null value. |
| 5 | @AccountId | VARCHAR(100) | YES | NULL | CODE-BACKED | Provider account string. "RawRedistribution" for PricingType=1. NULL or empty for standard instruments. |
| 6 | @TopOfBookThrottlingInMs | INT | YES | NULL | CODE-BACKED | Optional: minimum ms between top-of-book price publication updates. NULL = use global pricing engine default. |
| 7 | @FeedThrottlingInMs | INT | YES | NULL | CODE-BACKED | Optional: minimum ms between internal feed price updates. NULL = use global default. |
| 8 | @ClientThrottlingInMs | INT | YES | NULL | CODE-BACKED | Optional: minimum ms between client-facing price updates. NULL = use global default. |

**Result set**: None (SET NOCOUNT ON, no SELECT statement).

**On error**: ROLLBACK + THROW - re-raises original exception (e.g., PK violation if InstrumentID already exists).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID | Price.PricingConfigurations | WRITER | INSERT of new pricing configuration row |
| @InstrumentID | Trade.InstrumentSpread | WRITER | INSERT of default zero-spread baseline row (cascade on new instrument) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (instrument onboarding / pricing configuration API) | @InstrumentID | CALLER | Called when a new instrument is registered for live pricing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.InsertPricingConfiguration (procedure)
+-- Price.PricingConfigurations (table) - INSERT target (pricing engine config)
+-- Trade.InstrumentSpread (table) - INSERT target (zero-spread baseline)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.PricingConfigurations | Table | Primary INSERT target - creates the pricing configuration row |
| Trade.InstrumentSpread | Table | Cascade INSERT - creates the zero-spread baseline for the new instrument |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (instrument onboarding API) | External | Calls to register a new instrument for pricing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

SET NOCOUNT ON. TRY/CATCH with BEGIN TRANSACTION + COMMIT/ROLLBACK - full ACID guarantees. No input validation (relies on DB constraints: PK violation if InstrumentID already in PricingConfigurations; FK violations if InstrumentID not in Trade.Instrument). No return SELECT (unlike InsertLiquidityProviderPriceSource). No DbLoginName/AppLoginName parameters - the PricingConfigurations table has these columns but they are populated via trigger or default. The Trade.InstrumentSpread insert hardcodes: SpreadTypeID=1, all spread values=0, SpreadThresholdTypeID=1, FeedID=1 - these are the standard spread baseline values for a newly onboarded instrument.

---

## 8. Sample Queries

### 8.1 Add a new standard instrument to pricing

```sql
EXEC Price.InsertPricingConfiguration
    @InstrumentID = 99999,
    @DistributionType = 1,
    @PricingType = 0,
    @ProviderId = 0,
    @AccountId = NULL;
-- Inserts into PricingConfigurations + InstrumentSpread (SpreadTypeID=1, all zeros)
```

### 8.2 Add a Raw Redistribution instrument

```sql
EXEC Price.InsertPricingConfiguration
    @InstrumentID = 88888,
    @DistributionType = 1,
    @PricingType = 1,
    @ProviderId = 1,
    @AccountId = 'RawRedistribution';
```

### 8.3 Add instrument with custom throttling

```sql
EXEC Price.InsertPricingConfiguration
    @InstrumentID = 77777,
    @DistributionType = 3,         -- channels 1+2
    @PricingType = 0,
    @ProviderId = 0,
    @AccountId = NULL,
    @ClientThrottlingInMs = 500;   -- max 2 client price updates per second
```

### 8.4 Equivalent manual transaction

```sql
BEGIN TRY
    BEGIN TRANSACTION;
    INSERT INTO Price.PricingConfigurations (InstrumentID, DistributionType, PricingType, ProviderId, AccountId)
    VALUES (99999, 1, 0, 0, NULL);
    INSERT INTO Trade.InstrumentSpread
        (InstrumentID, SpreadTypeID, Bid, Ask, MarketSpreadThreshold, ReferenceBid, ReferenceAsk, SpreadThresholdTypeID, FeedID)
    VALUES (99999, 1, 0, 0, 0, 0, 0, 1, 1);
    COMMIT;
END TRY
BEGIN CATCH
    ROLLBACK;
    THROW;
END CATCH;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.InsertPricingConfiguration | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.InsertPricingConfiguration.sql*
