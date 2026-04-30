# Price.PricingConfigurationList

> Table-valued parameter (TVP) for batch updates of instrument pricing configurations, carrying pricing type, distribution model, provider routing, throttling settings, and price precision for a set of instruments in a single transactional call.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (update key against Price.PricingConfigurations) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This TVP is the input contract for `Price.UpdatePricingConfigurations`. It packages a batch of pricing configuration changes for multiple instruments, allowing a single transactional call to update pricing settings across Price.PricingConfigurations, Trade.InstrumentMetaData, and Trade.ProviderToInstrument simultaneously.

Pricing configuration defines HOW an instrument's price is derived and distributed: which pricing model applies (PricingType), how rates are distributed to clients (DistributionType), which provider supplies the feed (ProviderId + AccountId), and how fast rates are throttled at different stages (TopOfBook, Feed, Client). These are control-plane settings managed by the pricing operations team, not real-time price data.

Data flows from the pricing management API/backoffice -> this TVP -> `UpdatePricingConfigurations` -> transactional UPDATE across three tables: Price.PricingConfigurations (pricing model), Trade.InstrumentMetaData (PriceSourceID), and Trade.ProviderToInstrument (precision columns). The procedure uses COALESCE so NULL columns in the TVP preserve existing values (partial update support).

---

## 2. Business Logic

### 2.1 COALESCE-Based Partial Update Pattern

**What**: NULL columns in the TVP mean "keep existing value" - callers only set the fields they want to change.

**Columns/Parameters Involved**: All nullable columns (DistributionType, PricingType, ProviderId, AccountId, TopOfBookThrottlingInMs, FeedThrottlingInMs, ClientThrottlingInMs, Precision, AboveDollarPrecision, PricesBy)

**Rules**:
- SP uses `COALESCE(U.Column, PC.Column)` for all nullable fields
- Passing NULL = preserve current value; passing a value = override
- InstrumentID is the only required field (determines which instrument to update)

**Diagram**:
```
Caller populates TVP:
  InstrumentID = 1001  (required)
  PricingType = 2      (will be updated)
  DistributionType = NULL  (will be preserved as-is)

UpdatePricingConfigurations SP:
  UPDATE Price.PricingConfigurations SET PricingType = COALESCE(2, existing) = 2
  UPDATE Price.PricingConfigurations SET DistributionType = COALESCE(NULL, existing) = unchanged
```

### 2.2 Cross-Table Atomic Configuration Update

**What**: A single TVP call atomically updates configuration in three related tables.

**Columns/Parameters Involved**: `InstrumentID`, `DistributionType`, `PricingType`, `ProviderId`, `AccountId`, `TopOfBookThrottlingInMs`, `FeedThrottlingInMs`, `ClientThrottlingInMs`, `Precision`, `AboveDollarPrecision`, `PricesBy`

**Rules**:
- Price.PricingConfigurations: updated with DistributionType, PricingType, ProviderId, AccountId, throttling fields
- Trade.InstrumentMetaData.PriceSourceID: updated from PricesBy (only when PricesBy IS NOT NULL)
- Trade.ProviderToInstrument: updated with Precision and AboveDollarPrecision (only when at least one is NOT NULL)
- All three updates are wrapped in a single transaction with TRY/CATCH rollback

### 2.3 Throttling Hierarchy

**What**: Three throttling fields control rate limiting at different pipeline stages.

**Columns/Parameters Involved**: `TopOfBookThrottlingInMs`, `FeedThrottlingInMs`, `ClientThrottlingInMs`

**Rules**:
- TopOfBookThrottlingInMs: rate limit for top-of-book price updates (raw feed stage)
- FeedThrottlingInMs: rate limit for feed distribution to internal systems
- ClientThrottlingInMs: rate limit for distribution to client-facing systems
- Lower values = higher update frequency = higher system load; managed carefully for volatile instruments

**Diagram**:
```
Raw Price Feed
    |-- TopOfBookThrottlingInMs (e.g., 50ms = max 20 updates/sec)
    v
Internal Feed Distribution
    |-- FeedThrottlingInMs (e.g., 100ms = max 10 updates/sec)
    v
Client Price Distribution
    |-- ClientThrottlingInMs (e.g., 200ms = max 5 updates/sec)
    v
Clients (app/web)
```

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. NOT NULL - the update key; determines which Price.PricingConfigurations row to update. |
| 2 | DistributionType | tinyint | YES | - | CODE-BACKED | Controls how prices are distributed to clients. NULL = preserve existing. Specific values defined in application configuration. Mapped to Price.PricingConfigurations.DistributionType. |
| 3 | PricingType | tinyint | YES | - | CODE-BACKED | Identifies which pricing model/algorithm to apply for this instrument. NULL = preserve existing. Mapped to Price.PricingConfigurations.PricingType. |
| 4 | ProviderId | int | YES | - | CODE-BACKED | Identifier of the liquidity provider supplying prices for this instrument. NULL = preserve existing. Mapped to Price.PricingConfigurations.ProviderId. |
| 5 | AccountId | varchar(100) | YES | - | CODE-BACKED | Provider account identifier (e.g., FIX session ID or API key) used to route price requests to the correct provider account. NULL = preserve existing. Collation: Latin1_General_BIN (case-sensitive, binary). |
| 6 | TopOfBookThrottlingInMs | int | YES | - | CODE-BACKED | Minimum interval in milliseconds between top-of-book price updates at the raw feed stage. NULL = preserve existing. Lower = faster updates. |
| 7 | FeedThrottlingInMs | int | YES | - | CODE-BACKED | Minimum interval in milliseconds between price updates distributed to internal feed consumers. NULL = preserve existing. |
| 8 | ClientThrottlingInMs | int | YES | - | CODE-BACKED | Minimum interval in milliseconds between price updates distributed to client-facing systems (app/web). NULL = preserve existing. Controls client-visible price update frequency. |
| 9 | Precision | tinyint | YES | - | CODE-BACKED | Number of decimal places for displaying instrument prices below the dollar threshold. Mapped to Trade.ProviderToInstrument.Precision. NULL = preserve existing. |
| 10 | AboveDollarPrecision | tinyint | YES | - | CODE-BACKED | Number of decimal places for displaying instrument prices above the dollar threshold (e.g., stocks >$1). Mapped to Trade.ProviderToInstrument.AboveDollarPrecision. NULL = preserve existing. |
| 11 | PricesBy | int | YES | - | CODE-BACKED | Identifier for the price source system providing prices for this instrument. Mapped to Trade.InstrumentMetaData.PriceSourceID. NULL = preserve existing / do not update PriceSourceID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references (TVP - no FK constraints).

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.UpdatePricingConfigurations | @Updates | TVP Parameter | Batch-updates pricing configuration across Price.PricingConfigurations, Trade.InstrumentMetaData, and Trade.ProviderToInstrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.UpdatePricingConfigurations | Stored Procedure | Declares @Updates as this type READONLY; transactionally updates 3 tables from this batch |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| InstrumentID NOT NULL | NOT NULL | Instrument identification required; determines which configuration rows to update |
| AccountId COLLATE Latin1_General_BIN | COLLATION | Binary, case-sensitive collation for AccountId; provider API keys/session IDs are case-sensitive |

---

## 8. Sample Queries

### 8.1 Update pricing type and throttling for two instruments

```sql
DECLARE @Updates Price.PricingConfigurationList;
INSERT INTO @Updates (InstrumentID, PricingType, ClientThrottlingInMs)
VALUES (1001, 2, 200),
       (1002, 2, 200);
EXEC Price.UpdatePricingConfigurations @Updates = @Updates;
```

### 8.2 Update only the provider for a single instrument (preserve other fields)

```sql
DECLARE @Updates Price.PricingConfigurationList;
INSERT INTO @Updates (InstrumentID, ProviderId, AccountId)
VALUES (500, 7, 'FIX_SESSION_PROD_07');
EXEC Price.UpdatePricingConfigurations @Updates = @Updates;
```

### 8.3 Check current pricing configuration after update

```sql
SELECT
    PC.InstrumentID, PC.DistributionType, PC.PricingType,
    PC.ProviderId, PC.AccountId,
    PC.TopOfBookThrottlingInMs, PC.FeedThrottlingInMs, PC.ClientThrottlingInMs,
    IM.PriceSourceID AS PricesBy,
    PTI.[Precision], PTI.AboveDollarPrecision
FROM Price.PricingConfigurations PC WITH (NOLOCK)
LEFT JOIN Trade.InstrumentMetaData IM WITH (NOLOCK) ON PC.InstrumentID = IM.InstrumentID
LEFT JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK) ON PC.InstrumentID = PTI.InstrumentID
WHERE PC.InstrumentID IN (500, 1001, 1002);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.PricingConfigurationList | Type: User Defined Type | Source: etoro/etoro/Price/User Defined Types/Price.PricingConfigurationList.sql*
