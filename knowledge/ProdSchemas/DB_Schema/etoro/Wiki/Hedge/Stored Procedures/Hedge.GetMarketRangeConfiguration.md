# Hedge.GetMarketRangeConfiguration

> Returns market range (slippage tolerance) configuration for all instruments as seen from the default provider (ProviderID=1), providing the hedge engine with per-instrument price deviation thresholds used to validate order execution quality.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - always returns ProviderID=1 instrument configurations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetMarketRangeConfiguration` loads the market range validation settings for all instruments from the default eToro provider (ProviderID=1). "Market range" is the maximum allowed price deviation between the requested execution price and the actual fill price - a form of slippage control. If a hedge order fills at a price beyond the market range threshold, the hedge engine may reject it or flag it for review.

This procedure exists because different instruments have different acceptable slippage thresholds based on their liquidity and volatility profiles. Major forex pairs allow tighter ranges (e.g., 0.1 pips) while equity stocks allow wider ranges (e.g., 0.5%). The `MarketRangeValidationType` column further controls whether the range is applied as an absolute value, a percentage, or through some other validation logic.

Data flows as follows: on startup, the hedge engine calls this procedure to cache the market range configuration for all instruments. When a FIX execution response arrives with a fill price, the engine looks up the instrument's market range from this cache and validates the fill quality. The hardcoded ProviderID=1 reflects that market range configuration is maintained from eToro's perspective (the "self" provider), not per-LP.

---

## 2. Business Logic

### 2.1 Default Provider (ProviderID=1) Scope

**What**: Market range configuration is read from Trade.ProviderToInstrument with a hardcoded filter WHERE ProviderID=1, returning configuration as seen from eToro's default provider perspective.

**Columns/Parameters Involved**: `MarketRange`, `MarketRangeValidationType`, `MarketRangePercentage`

**Rules**:
- ProviderID=1 is eToro's own/default provider - the source of truth for instrument-level market range settings
- One row per instrument (InstrumentID is the effective key in the result set)
- MarketRange: absolute maximum price deviation allowed (in instrument price units)
- MarketRangePercentage: percentage-based deviation threshold (alternative to or complement of absolute range)
- MarketRangeValidationType: controls the validation logic applied - determines whether absolute, percentage, or a combined check is enforced

**Diagram**:
```
Hedge engine receives FIX fill: InstrumentID=1, fill price=1.08765
                                 requested price=1.08750
                                 deviation = 0.00015

GetMarketRangeConfiguration() -> InstrumentID=1, MarketRange=0.0005
   DevialRange check: 0.00015 < 0.0005 -> PASS
   Order fill accepted
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*No input parameters - procedure takes no arguments.*

**Output columns** (from Trade.ProviderToInstrument WHERE ProviderID=1):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. FK to Trade.Instrument. Key used by the hedge engine to look up market range settings per instrument when validating fill prices. |
| 2 | MarketRange | decimal | YES | - | CODE-BACKED | Maximum absolute price deviation allowed between requested and actual fill price. Instrument-specific threshold - tighter for liquid instruments (e.g., forex majors), wider for illiquid ones. Used with MarketRangeValidationType to determine the actual validation rule applied. |
| 3 | MarketRangeValidationType | int | YES | - | CODE-BACKED | Numeric code controlling which market range validation logic is applied: absolute check vs percentage check vs combined. Specific values are defined in application logic (not a Dictionary FK). |
| 4 | MarketRangePercentage | decimal | YES | - | CODE-BACKED | Percentage-based maximum deviation (as a decimal fraction, e.g., 0.001 = 0.1%). Used when MarketRangeValidationType specifies percentage-mode validation. Complementary to MarketRange for instruments where relative deviation is more meaningful than absolute. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Trade.ProviderToInstrument | SELECT | Source of market range configuration; filtered to ProviderID=1 (eToro default provider). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup to load market range cache for fill price validation. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetMarketRangeConfiguration (procedure)
└── Trade.ProviderToInstrument (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | SELECTed with NOLOCK WHERE ProviderID=1 - source of all market range columns |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | Called on startup to load instrument-level market range validation thresholds |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure. The hardcoded `ProviderID=1` means this procedure always returns eToro's default instrument configuration. If market range settings differ per LP, this procedure would need to be parameterized.

---

## 8. Sample Queries

### 8.1 Load all market range configurations
```sql
EXEC [Hedge].[GetMarketRangeConfiguration];
```

### 8.2 Direct table query for a specific instrument's market range
```sql
SELECT  InstrumentID,
        MarketRange,
        MarketRangeValidationType,
        MarketRangePercentage
FROM    [Trade].[ProviderToInstrument] WITH (NOLOCK)
WHERE   ProviderID = 1
  AND   InstrumentID = 1;
```

### 8.3 Review instruments with percentage-based validation
```sql
SELECT  InstrumentID,
        MarketRange,
        MarketRangeValidationType,
        MarketRangePercentage
FROM    [Trade].[ProviderToInstrument] WITH (NOLOCK)
WHERE   ProviderID = 1
  AND   MarketRangeValidationType IS NOT NULL
ORDER BY MarketRangePercentage DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetMarketRangeConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetMarketRangeConfiguration.sql*
