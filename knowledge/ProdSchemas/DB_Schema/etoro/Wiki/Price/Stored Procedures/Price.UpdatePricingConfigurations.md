# Price.UpdatePricingConfigurations

> Atomically updates pricing engine configuration across three tables (Price.PricingConfigurations, Trade.InstrumentMetaData, Trade.ProviderToInstrument) for a batch of instruments supplied via TVP, using COALESCE-based partial updates so only non-NULL fields overwrite existing values.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Updates 3 tables via Price.PricingConfigurationList TVP; returns final combined state |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.UpdatePricingConfigurations is the multi-table batch update procedure for pricing engine configuration. When pricing parameters need to change for one or more instruments - for example, adjusting throttling, switching pricing type, changing the provider, or updating price precision - this procedure applies all changes atomically across the three tables that together define an instrument's complete pricing profile:

1. **Price.PricingConfigurations**: The core pricing engine settings (PricingType, DistributionType, ProviderId, AccountId, and three throttling values)
2. **Trade.InstrumentMetaData**: The instrument's declared price source (PricesBy/PriceSourceID)
3. **Trade.ProviderToInstrument**: The decimal precision for displaying this instrument's prices (Precision, AboveDollarPrecision)

The TVP uses the `Price.PricingConfigurationList` UDT, which carries all fields that can be updated. Each field uses COALESCE in the SET clause, meaning NULL values in the TVP are treated as "no change" - the existing DB value is preserved. This enables partial updates where a caller only needs to change one or two fields without knowing all current values.

All three UPDATEs use OUTPUT clauses to capture changed rows into table variables, and the final SELECT joins PricingConfigurations, InstrumentMetaData, and ProviderToInstrument to return the complete post-update state for all affected instruments.

---

## 2. Business Logic

### 2.1 COALESCE-Based Partial Update Pattern

**What**: Each field uses COALESCE(TVP_value, current_value) so NULL in the TVP preserves the existing DB value.

**Columns/Parameters Involved**: `DistributionType`, `PricingType`, `ProviderId`, `AccountId`, `TopOfBookThrottlingInMs`, `FeedThrottlingInMs`, `ClientThrottlingInMs`, `PricesBy`, `Precision`, `AboveDollarPrecision`

**Rules**:
- PricingConfigurations fields: `SET PC.Field = COALESCE(U.Field, PC.Field)` for all 7 updatable fields
- InstrumentMetaData.PriceSourceID: `SET IM.PriceSourceID = U.PricesBy` WHERE U.PricesBy IS NOT NULL (conditional JOIN, not COALESCE - uses WHERE filter instead)
- ProviderToInstrument fields: `SET PTI.Field = COALESCE(U.Field, PTI.Field)` WHERE U.Precision IS NOT NULL OR U.AboveDollarPrecision IS NOT NULL (only runs if either is non-NULL)
- An instrument in the TVP that has ALL NULL update fields will still match PricingConfigurations JOIN but SET values = existing values (no-op update)

### 2.2 Three-Table Atomic Transaction

**What**: All three UPDATEs execute in a single BEGIN TRANSACTION / COMMIT TRANSACTION to guarantee consistency.

**Columns/Parameters Involved**: All fields across 3 tables

**Rules**:
- Temp table #Updates created from TVP with CLUSTERED index on InstrumentID for JOIN performance
- UPDATE 1: Price.PricingConfigurations INNER JOIN #Updates ON InstrumentID -> captures OUTPUT into @Results_PricingConfigurations
- UPDATE 2: Trade.InstrumentMetaData INNER JOIN #Updates WHERE U.PricesBy IS NOT NULL -> captures OUTPUT into @Results_InstrumentMetaData
- UPDATE 3: Trade.ProviderToInstrument INNER JOIN #Updates WHERE U.Precision IS NOT NULL OR U.AboveDollarPrecision IS NOT NULL -> captures OUTPUT into @Results_ProviderToInstrument
- CATCH: IF XACT_STATE() <> 0 ROLLBACK; THROW (re-raises original error)
- Final SELECT: PricingConfigurations LEFT JOIN InstrumentMetaData LEFT JOIN ProviderToInstrument INNER JOIN #Updates (returns only submitted instruments)

**Diagram**:
```
TVP Input (@Updates):
  [InstrumentID=1, PricingType=NULL, ClientThrottlingInMs=500, PricesBy=3, Precision=NULL]
  [InstrumentID=2, PricingType=1, ClientThrottlingInMs=NULL, PricesBy=NULL, Precision=4]

Transaction:
  UPDATE PricingConfigurations WHERE InstrumentID IN (1,2):
    Inst 1: ClientThrottlingInMs=500 (NULL kept existing for others)
    Inst 2: PricingType=1 (NULL kept existing for others)

  UPDATE InstrumentMetaData WHERE PricesBy IS NOT NULL:
    Inst 1: PriceSourceID=3 (only Inst 1 updated; Inst 2 has NULL PricesBy)

  UPDATE ProviderToInstrument WHERE Precision IS NOT NULL:
    Inst 2: Precision=4 (only Inst 2 updated; Inst 1 has NULL Precision)

Final SELECT: Returns full state for Inst 1 and Inst 2
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Updates | Price.PricingConfigurationList READONLY | NOT NULL | - | CODE-BACKED | Table-valued parameter using the Price.PricingConfigurationList UDT. Each row targets one instrument. Columns include: InstrumentID (required join key), DistributionType, PricingType, ProviderId, AccountId, TopOfBookThrottlingInMs, FeedThrottlingInMs, ClientThrottlingInMs (all update Price.PricingConfigurations), PricesBy (updates Trade.InstrumentMetaData.PriceSourceID), Precision, AboveDollarPrecision (update Trade.ProviderToInstrument). NULL fields in any row preserve existing DB values via COALESCE. |

**Return columns (one row per submitted InstrumentID):**

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| R1 | InstrumentID | INT | CODE-BACKED | Instrument ID (from Price.PricingConfigurations). |
| R2 | DistributionType | TINYINT | CODE-BACKED | Distribution channel bitmask from Price.PricingConfigurations. |
| R3 | PricingType | TINYINT | CODE-BACKED | Pricing algorithm type: 0=Standard, 1=RawRedistribution. From Price.PricingConfigurations. |
| R4 | ProviderId | INT | CODE-BACKED | Pricing provider association. From Price.PricingConfigurations. |
| R5 | AccountId | VARCHAR(100) | CODE-BACKED | Provider account string (e.g., "RawRedistribution"). From Price.PricingConfigurations. |
| R6 | TopOfBookThrottlingInMs | INT | CODE-BACKED | Min ms between top-of-book updates. From Price.PricingConfigurations. |
| R7 | FeedThrottlingInMs | INT | CODE-BACKED | Min ms between feed price updates. From Price.PricingConfigurations. |
| R8 | ClientThrottlingInMs | INT | CODE-BACKED | Min ms between client-facing price updates. From Price.PricingConfigurations. |
| R9 | PricesBy | INT | CODE-BACKED | Price source ID (Trade.InstrumentMetaData.PriceSourceID) aliased as PricesBy. NULL if instrument has no InstrumentMetaData row. |
| R10 | Precision | TINYINT | CODE-BACKED | Decimal precision for price display. From Trade.ProviderToInstrument. NULL if no row. |
| R11 | AboveDollarPrecision | TINYINT | CODE-BACKED | Decimal precision for prices above $1. From Trade.ProviderToInstrument. NULL if no row. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @Updates.InstrumentID | Price.PricingConfigurations | MODIFIER | Updates pricing engine fields via COALESCE partial update |
| @Updates.PricesBy | Trade.InstrumentMetaData | MODIFIER | Updates PriceSourceID where PricesBy IS NOT NULL |
| @Updates.Precision / AboveDollarPrecision | Trade.ProviderToInstrument | MODIFIER | Updates decimal precision fields where non-NULL |

### 5.2 Referenced By (other objects point to this)

No SQL callers found in the etoro SSDT repo. Called externally by the pricing configuration management API.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.UpdatePricingConfigurations (procedure)
├── Price.PricingConfigurations (table - UPDATE target 1)
├── Trade.InstrumentMetaData (table - UPDATE target 2, conditional)
└── Trade.ProviderToInstrument (table - UPDATE target 3, conditional)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.PricingConfigurations | Table | Primary UPDATE target - pricing engine configuration fields |
| Trade.InstrumentMetaData | Table | Conditional UPDATE target - PriceSourceID (when PricesBy IS NOT NULL in TVP) |
| Trade.ProviderToInstrument | Table | Conditional UPDATE target - Precision/AboveDollarPrecision (when non-NULL in TVP) |

### 6.2 Objects That Depend On This

No dependents found in SSDT repo.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| COALESCE partial update | Pattern | NULL TVP values = preserve existing; non-NULL = overwrite. Allows callers to patch specific fields only. |
| Temp table performance | Optimization | #Updates created with CLUSTERED INDEX IX_InstrumentID on InstrumentID to speed up JOIN in UPDATE statements |
| Three OUTPUT clauses | Pattern | All three UPDATEs capture changed rows to table variables (not used in final return, but available for debugging) |
| Atomic transaction | Safety | All three UPDATEs in BEGIN/COMMIT; CATCH -> ROLLBACK TRANSACTION via XACT_STATE() check |
| TVP type | Parameter | Uses Price.PricingConfigurationList UDT - caller must declare a compatible typed variable |
| SET NOCOUNT ON | Performance | Suppresses rows-affected messages |
| LEFT JOIN in final SELECT | Coverage | InstrumentMetaData and ProviderToInstrument are LEFT JOINed - instruments without rows in those tables still appear in results (with NULL columns) |

---

## 8. Sample Queries

### 8.1 Update throttling for instrument 1 only

```sql
DECLARE @Updates Price.PricingConfigurationList;
INSERT INTO @Updates (InstrumentID, ClientThrottlingInMs)
VALUES (1, 500);

EXEC Price.UpdatePricingConfigurations @Updates = @Updates;
-- Returns current state of Inst 1 across all 3 tables; ClientThrottlingInMs=500
```

### 8.2 Switch instrument 2 to RawRedistribution and update its price source

```sql
DECLARE @Updates Price.PricingConfigurationList;
INSERT INTO @Updates (InstrumentID, PricingType, AccountId, PricesBy)
VALUES (2, 1, 'RawRedistribution', 3);  -- PricingType=1, PriceSource=3 (NASDAQ)

EXEC Price.UpdatePricingConfigurations @Updates = @Updates;
```

### 8.3 Batch update precision for multiple instruments

```sql
DECLARE @Updates Price.PricingConfigurationList;
INSERT INTO @Updates (InstrumentID, Precision, AboveDollarPrecision)
VALUES (1, 5, 3), (2, 4, 2), (3, 5, 3);

EXEC Price.UpdatePricingConfigurations @Updates = @Updates;
-- Returns all 3 instruments with updated precision values
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Price.UpdatePricingConfigurations | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.UpdatePricingConfigurations.sql*
