# Price.GetPricingConfigurationsByInstrumentIds

> Returns pricing engine configuration for a specific list of instruments (via TVP), with audit trail columns (DbLoginName, AppLoginName) added - the instrument-scoped variant of GetPricingConfigurations without pagination or type filters.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentIds (TVP filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Price.GetPricingConfigurationsByInstrumentIds returns the full pricing configuration for a targeted set of instruments. It is the instrument-scoped sibling of Price.GetPricingConfigurations: same core data (DistributionType, PricingType, provider, throttling, precision, PricesBy), but filtered to a caller-supplied list of InstrumentIDs rather than paginating through all instruments.

This procedure adds two columns not returned by GetPricingConfigurations:
- `DbLoginName`: the database login that last modified this instrument's configuration
- `AppLoginName`: the application-level user that last modified this instrument's configuration

These audit trail columns are useful for diagnostics and change tracking - identifying who last changed a specific instrument's pricing configuration.

Key structural difference from GetPricingConfigurations: Trade.ProviderToInstrument is joined as LEFT JOIN (not INNER JOIN), meaning instruments that have no row in ProviderToInstrument are still returned (with Precision=4 and AboveDollarPrecision=2 from the ISNULL defaults). This avoids silently dropping instruments from the result.

A temp table with a clustered index is created for the input TVP to optimize join performance when large lists are passed.

---

## 2. Business Logic

### 2.1 TVP to Temp Table Optimization

**What**: The input TVP is materialized into a temp table with a clustered index before joining.

**Columns/Parameters Involved**: `@InstrumentIds`, `#InstrumentIds`

**Rules**:
- `SELECT InstrumentID INTO #InstrumentIds FROM @InstrumentIds`: copies TVP to temp table
- `CREATE CLUSTERED INDEX IX_InstrumentID ON #InstrumentIds(InstrumentID)`: adds index post-insert
- Purpose: TVPs cannot be indexed inline; a temp table with a clustered index allows the optimizer to use efficient seek/merge joins instead of nested loops over the TVP
- INNER JOIN `#InstrumentIds i ON PC.InstrumentID = i.InstrumentID`: filters PricingConfigurations to only the requested instruments

### 2.2 LEFT JOIN to ProviderToInstrument

**What**: ProviderToInstrument is joined as LEFT JOIN, preserving all requested instruments even if missing from PTI.

**Columns/Parameters Involved**: `Precision`, `AboveDollarPrecision`

**Rules**:
- Comment in code: `--inner join Trade.ProviderToInstrument PTI ... (Change to Left Join by Moshe temp)` - was originally INNER JOIN, changed to LEFT JOIN, marked "temp" but remains LEFT
- Effect: instruments without a ProviderToInstrument row get Precision=4 and AboveDollarPrecision=2 (from ISNULL defaults)
- Trade.InstrumentMetaData is still INNER JOIN - instruments missing from IMD are excluded
- This differs from GetPricingConfigurations which uses INNER JOIN to PTI, meaning this procedure may return different results for instruments that exist in PricingConfigurations but not in ProviderToInstrument

### 2.3 Audit Trail Columns

**What**: DbLoginName and AppLoginName are included to identify the last modifier of each instrument's configuration.

**Columns/Parameters Involved**: `PC.DbLoginName`, `PC.AppLoginName`

**Rules**:
- Sourced directly from Price.PricingConfigurations
- Not returned by GetPricingConfigurations (cursor-paginated variant)
- Useful for "who last changed this instrument's pricing?" queries

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentIds | Price.InstrumentsIDsList READONLY | NOT NULL (but can be empty) | - | CODE-BACKED | TVP of InstrumentIDs to retrieve pricing configurations for. Single column: InstrumentID INT. Empty TVP returns 0 rows (INNER JOIN to #InstrumentIds matches nothing). No all-instruments fallback - this procedure requires explicit instrument list. |

**Result set columns** (13 columns):

| # | Column | Description |
|---|--------|-------------|
| 1 | InstrumentID | eToro instrument identifier |
| 2 | DistributionType | Bitmask: 1=channel 1 (standard), 3=channels 1+2, 0=none |
| 3 | PricingType | 0=Standard, 1=Raw Redistribution |
| 4 | ProviderId | Pricing provider ID. Populated for Raw Redistribution; NULL for standard |
| 5 | AccountId | Provider account string. "RawRedistribution" for PricingType=1; NULL for standard |
| 6 | TopOfBookThrottlingInMs | Min ms between top-of-book price updates. NULL=use global default |
| 7 | FeedThrottlingInMs | Min ms between internal feed price updates. NULL=use global default |
| 8 | ClientThrottlingInMs | Min ms between client-facing price updates. NULL=use global default |
| 9 | Precision | Decimal places for price display below $1. Default 4 (ISNULL from ProviderToInstrument LEFT JOIN) |
| 10 | AboveDollarPrecision | Decimal places for price display above $1. Default 2 (ISNULL from ProviderToInstrument LEFT JOIN) |
| 11 | PricesBy | PriceSourceID from Trade.InstrumentMetaData - the authoritative feed source for this instrument |
| 12 | DbLoginName | Database login that last modified this row in PricingConfigurations. Audit trail. |
| 13 | AppLoginName | Application user that last modified this row. Set via application context (CONTEXT_INFO or similar). Audit trail. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentIds | Price.InstrumentsIDsList | TVP type | Input instrument ID filter |
| InstrumentID | Price.PricingConfigurations | READER (via temp table JOIN) | Primary data source |
| InstrumentID | Trade.ProviderToInstrument | READER (LEFT JOIN) | Precision and AboveDollarPrecision - LEFT JOIN preserves instruments missing from PTI |
| InstrumentID | Trade.InstrumentMetaData | READER (INNER JOIN) | PriceSourceID (PricesBy) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (pricing configuration API) | @InstrumentIds | CALLER | Called when specific instrument configurations are needed with audit trail |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.GetPricingConfigurationsByInstrumentIds (procedure)
+-- Price.InstrumentsIDsList (UDT) - TVP type
+-- Price.PricingConfigurations (table) - primary data
+-- Trade.ProviderToInstrument (table) - precision (LEFT JOIN)
+-- Trade.InstrumentMetaData (table) - PriceSourceID
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Price.InstrumentsIDsList | User Defined Type | TVP parameter type |
| Price.PricingConfigurations | Table | Primary source filtered to input instrument list |
| Trade.ProviderToInstrument | Table | LEFT JOIN - Precision and AboveDollarPrecision (defaults if missing) |
| Trade.InstrumentMetaData | Table | INNER JOIN - PriceSourceID as PricesBy |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (pricing configuration API) | External | Calls to retrieve configurations for specific instruments with audit columns |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Note: creates temp table #InstrumentIds with CLUSTERED INDEX IX_InstrumentID at runtime for TVP optimization.

### 7.2 Constraints

SET NOCOUNT ON. LEFT JOIN to Trade.ProviderToInstrument (originally INNER JOIN - changed by "Moshe", marked "temp" in comment, but still LEFT JOIN in current code). INNER JOIN to Trade.InstrumentMetaData - instruments missing from IMD are silently excluded. Uses old-style NOLOCK hint without WITH keyword on PTI and IMD (`(nolock)` not `WITH (NOLOCK)`) - valid but inconsistent with most other Price SPs. Temp table is session-scoped and dropped automatically on procedure exit. Empty TVP produces empty result set (no all-instruments fallback like in some other Price procedures).

---

## 8. Sample Queries

### 8.1 Get configurations for 3 specific instruments

```sql
DECLARE @Instruments Price.InstrumentsIDsList;
INSERT INTO @Instruments VALUES (1), (7654), (8000);

EXEC Price.GetPricingConfigurationsByInstrumentIds
    @InstrumentIds = @Instruments;
-- Returns: up to 3 rows with DbLoginName and AppLoginName included
```

### 8.2 Equivalent manual query

```sql
SELECT
    PC.InstrumentID,
    PC.DistributionType,
    PC.PricingType,
    PC.ProviderId,
    PC.AccountId,
    PC.TopOfBookThrottlingInMs,
    PC.FeedThrottlingInMs,
    PC.ClientThrottlingInMs,
    ISNULL(PTI.Precision, 4) AS Precision,
    ISNULL(PTI.AboveDollarPrecision, 2) AS AboveDollarPrecision,
    IMD.PriceSourceID AS PricesBy,
    PC.DbLoginName,
    PC.AppLoginName
FROM Price.PricingConfigurations AS PC WITH (NOLOCK)
LEFT JOIN Trade.ProviderToInstrument PTI WITH (NOLOCK)
    ON PC.InstrumentID = PTI.InstrumentID
INNER JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK)
    ON PC.InstrumentID = IMD.InstrumentID
WHERE PC.InstrumentID IN (1, 7654, 8000);
```

### 8.3 Find Raw Redistribution instruments via this procedure

```sql
DECLARE @All Price.InstrumentsIDsList;
-- Populate with all InstrumentIDs, then filter:
-- SELECT InstrumentID FROM results WHERE PricingType = 1
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 5, 8, 9B (skipped), 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.GetPricingConfigurationsByInstrumentIds | Type: Stored Procedure | Source: etoro/etoro/Price/Stored Procedures/Price.GetPricingConfigurationsByInstrumentIds.sql*
