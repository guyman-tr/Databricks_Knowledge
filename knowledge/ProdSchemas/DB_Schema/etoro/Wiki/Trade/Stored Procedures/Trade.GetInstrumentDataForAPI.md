# Trade.GetInstrumentDataForAPI

> Returns the full instrument configuration catalog for the trading API - leverages, trading rules, fees, limits, and metadata across three result sets.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID (key in all result sets) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is one of the most important instrument configuration procedures in the platform. It returns the complete instrument catalog that powers the trading API's instrument configuration, delivering three result sets: (1) available leverages per instrument, (2) full instrument configuration including trading rules, limits, fees, precision, and regulatory flags, and (3) instrument-to-group mappings. This data drives what users see and can do on the trading platform.

The procedure exists to provide a single endpoint for the trading API to load all instrument configurations at startup or on refresh. It combines data from 7+ tables to produce a denormalized, API-ready dataset. The @getOnlyVisibleOrEnabledInstruments flag controls whether to include hidden/disabled instruments (for admin views) or only user-facing ones.

Data flow: caller optionally passes @getOnlyVisibleOrEnabledInstruments (defaults to 1). The SP returns three result sets:
- Result set 1: Instrument leverages from Trade.ProviderInstrumentToLeverage + Dictionary.Leverage
- Result set 2: Full instrument config from Trade.ProviderToInstrument + Trade.InstrumentMetaData + Trade.GetInstrument + Dictionary.CurrencyType + optional FuturesMetaData and UsAllowedInstruments
- Result set 3: Instrument groups from Trade.InstrumentGroups

---

## 2. Business Logic

### 2.1 Visibility/Enabled Filter

**What**: Controls which instruments appear in the API response.

**Columns/Parameters Involved**: `@getOnlyVisibleOrEnabledInstruments`, `InstrumentVisible`, `Enabled`

**Rules**:
- When flag = 1 (default): only instruments where InstrumentVisible=1 OR Enabled=1 are returned
- When flag = 0: all instruments returned regardless of visibility/enabled state
- ProviderID = 1 always applies (primary provider only)

### 2.2 SDRT Eligibility Computation

**What**: Determines if an instrument is subject to UK Stamp Duty Reserve Tax.

**Columns/Parameters Involved**: `ISINCountryCode`, `ExchangeID`, `InstrumentTypeID`

**Rules**:
- SdrtEligible = 1 when ISINCountryCode='GB' AND ExchangeID=7 AND InstrumentTypeID=5
- This means: UK-registered (GB ISIN), London Stock Exchange (ExchangeID=7), Stock type (5)
- All other instruments have SdrtEligible=0

### 2.3 US Allowed Check

**What**: Determines if an instrument is available in the US market.

**Columns/Parameters Involved**: `IsUsAllowed`, `Trade.UsAllowedInstruments`

**Rules**:
- IsUsAllowed = 1 when the instrument exists in Trade.UsAllowedInstruments with CountryID=219 (US)
- Uses OUTER APPLY with TOP 1 for existence check
- Instruments not in the whitelist get IsUsAllowed=0

### 2.4 Backward Compatibility Fee Columns

**What**: Legacy fee columns hardcoded to 0 for API backward compatibility.

**Rules**:
- 13 fee columns (SellOverWeekendFeePerUnit, BuyOverNightFeePerUnit, etc.) are all set to 0
- Marked with comment "temporary block for backward compatibility - will be removed in the future"
- Real fee calculations happen elsewhere; these are placeholder zeros for old API consumers

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @getOnlyVisibleOrEnabledInstruments | BIT | NO | 1 | CODE-BACKED | Filter flag: 1=only visible/enabled instruments, 0=all instruments. |

### Result Set 1 - Instrument Leverages

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. |
| 3 | Leverage | INT | NO | - | CODE-BACKED | Available leverage value (e.g., 1, 2, 5, 10, 20). From Dictionary.Leverage. |
| 4 | IsDefault | BIT | NO | - | CODE-BACKED | Whether this is the default leverage for the instrument. |

### Result Set 2 - Full Instrument Configuration (key columns)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 5 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. |
| 6 | Precision | INT | - | - | CODE-BACKED | Decimal precision for rates. |
| 7 | AboveDollarPrecision | INT | YES | - | CODE-BACKED | Alternative precision when rate > $1. |
| 8 | InstrumentTypeID | INT | - | - | CODE-BACKED | Asset class. |
| 9 | UnitMargin | DECIMAL | - | - | CODE-BACKED | Margin per unit. |
| 10 | BuyCurrencyID | INT | - | - | CODE-BACKED | Base currency. FK to Dictionary.Currency. |
| 11 | SellCurrencyID | INT | - | - | CODE-BACKED | Quote currency. FK to Dictionary.Currency. |
| 12 | Tradable | BIT | - | - | CODE-BACKED | Whether instrument can be traded. |
| 13 | MaxPositionUnits | DECIMAL | - | - | CODE-BACKED | Maximum units per position. |
| 14 | MinPositionAmount | DECIMAL | - | - | CODE-BACKED | Minimum position amount. |
| 15 | Enabled | BIT | - | - | CODE-BACKED | Whether instrument is enabled for trading. |
| 16 | AllowBuy | BIT | - | - | CODE-BACKED | Whether Buy/Long is allowed. |
| 17 | AllowSell | BIT | - | - | CODE-BACKED | Whether Sell/Short is allowed. |
| 18 | GuaranteeSLTP | BIT | - | - | CODE-BACKED | Whether guaranteed SL/TP is available. |
| 19 | SettledBuyMaxLeverage | INT | - | - | CODE-BACKED | Maximum leverage for settled (real stock) buy. |
| 20 | SettledSellMaxLeverage | INT | - | - | CODE-BACKED | Maximum leverage for settled sell. |
| 21 | RequiresW8Ben | BIT | - | - | CODE-BACKED | Whether US tax form W-8BEN is required for this instrument. |
| 22 | Exchange | VARCHAR | YES | - | CODE-BACKED | Normalized exchange name (lowercase, no spaces). |
| 23 | AllowRedeem | BIT | - | - | CODE-BACKED | Whether share redemption is allowed. |
| 24 | SdrtEligible | BIT | NO | - | CODE-BACKED | UK Stamp Duty Reserve Tax eligibility. Computed: GB ISIN + LSE + Stock type. |
| 25 | IsUsAllowed | BIT | NO | - | CODE-BACKED | Whether instrument is available in US market. From Trade.UsAllowedInstruments. |
| 26 | InstrumentTypeSubCategory | VARCHAR | YES | - | CODE-BACKED | Sub-category classification (spaces removed). |
| 27 | MarketRange | DECIMAL | NO | 0 | CODE-BACKED | Market range tolerance. ISNULL to 0. |
| 28 | MarketRangeValidationType | INT | - | - | CODE-BACKED | Type of market range validation. |
| 29 | Unit | DECIMAL | - | - | CODE-BACKED | Lot size (units per lot). |
| 30 | Multiplier | DECIMAL | YES | - | CODE-BACKED | Futures contract multiplier. From Trade.FuturesMetaData. NULL for non-futures. |
| 31 | Slippage | DECIMAL | YES | - | CODE-BACKED | Allowed slippage for this instrument. |
| 32 | ExtendedMarginAllowed | BIT | YES | - | CODE-BACKED | Whether extended margin is allowed. |

### Result Set 3 - Instrument Groups

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 33 | InstrumentID | INT | NO | - | CODE-BACKED | Instrument identifier. |
| 34 | GroupID | INT | NO | - | CODE-BACKED | Trading group classification. FK to Dictionary.TradingInstrumentGroups. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Trade.ProviderToInstrument | FROM | Primary source of trading rules and configuration |
| (body) | Trade.InstrumentMetaData | JOIN | Instrument metadata, visibility, ISIN, exchange |
| (body) | Trade.GetInstrument | JOIN (view) | InstrumentTypeID, currencies |
| (body) | Dictionary.CurrencyType | JOIN | MinPositionAmountAbsolute |
| (body) | Dictionary.InstrumentTypeSubCategory | LEFT JOIN | Sub-category name |
| (body) | Trade.FuturesMetaData | LEFT JOIN | Futures multiplier |
| (body) | Trade.UsAllowedInstruments | OUTER APPLY | US market availability check |
| (body) | Trade.ProviderInstrumentToLeverage | FROM | Available leverages |
| (body) | Dictionary.Leverage | JOIN | Leverage value lookup |
| (body) | Trade.InstrumentGroups | FROM | Instrument group mappings |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInstrumentDataForAPI (procedure)
+-- Trade.ProviderToInstrument (table)
+-- Trade.InstrumentMetaData (table)
+-- Trade.GetInstrument (view)
+-- Dictionary.CurrencyType (table)
+-- Dictionary.InstrumentTypeSubCategory (table)
+-- Trade.FuturesMetaData (table)
+-- Trade.UsAllowedInstruments (table)
+-- Trade.ProviderInstrumentToLeverage (table)
+-- Dictionary.Leverage (table)
+-- Trade.InstrumentGroups (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | FROM - trading rules, limits, SL/TP config |
| Trade.InstrumentMetaData | Table | JOIN - metadata, visibility, ISIN |
| Trade.GetInstrument | View | JOIN - asset type, currencies |
| Dictionary.CurrencyType | Table | JOIN - MinPositionAmountAbsolute |
| Dictionary.InstrumentTypeSubCategory | Table | LEFT JOIN - sub-category name |
| Trade.FuturesMetaData | Table | LEFT JOIN - futures multiplier |
| Trade.UsAllowedInstruments | Table | OUTER APPLY - US availability |
| Trade.ProviderInstrumentToLeverage | Table | FROM - leverage options |
| Dictionary.Leverage | Table | JOIN - leverage values |
| Trade.InstrumentGroups | Table | FROM - group memberships |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None. Filters to ProviderID=1 (primary provider) in both result sets 1 and 2.

---

## 8. Sample Queries

### 8.1 Execute for visible/enabled instruments

```sql
EXEC Trade.GetInstrumentDataForAPI;
```

### 8.2 Execute for all instruments (admin view)

```sql
EXEC Trade.GetInstrumentDataForAPI @getOnlyVisibleOrEnabledInstruments = 0;
```

### 8.3 Check instrument trading rules directly

```sql
SELECT  pti.InstrumentID, pti.AllowBuy, pti.AllowSell, pti.Enabled,
        pti.GuaranteeSLTP, pti.MaxPositionUnits, pti.MinPositionAmount
FROM    Trade.ProviderToInstrument pti WITH (NOLOCK)
WHERE   pti.ProviderID = 1
AND     pti.InstrumentID = 1001;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 34 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInstrumentDataForAPI | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInstrumentDataForAPI.sql*
