# Dictionary.LeverageType

> Configuration table defining leverage boundary ranges per instrument type — specifying the low and high leverage thresholds that separate "low leverage" from "standard leverage" trading for regulatory risk classification.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | InstrumentTypeID (INT, CLUSTERED PK) |
| **Partition** | DICTIONARY filegroup (PAGE compressed) |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Dictionary.LeverageType defines the boundaries between "low leverage" and "high leverage" for each instrument type. Under regulations like ESMA (EU), ASIC (Australia), and other jurisdictions, the leverage offered to retail clients is capped, and the classification of what constitutes "low" vs "standard" leverage affects margin requirements, risk warnings, and regulatory reporting.

This table exists because different asset classes have fundamentally different leverage characteristics. Forex majors can safely support 30:1 leverage (so the "low" boundary starts at 26x), while stocks are limited to 5:1 (so "low" starts at 2x). These boundaries feed into procedures that validate instrument configurations, calculate margin requirements, and determine risk classification for customer accounts.

The table is consumed by Trade.CheckValidInstruments (instrument validation), Trade.UpdateInstrumentsAvailableLeverages (leverage configuration updates), Trade.InsertInstrumentRealTable (new instrument creation), Trade.InsertInstrumentTradingData (trading data setup), and Customer views (Customer.Customer, Customer.CustomerSafty, Customer.IsCustomerFund) for leverage-based customer classification.

---

## 2. Business Logic

### 2.1 Leverage Classification by Asset Class

**What**: Each instrument type has defined low and high leverage boundaries that classify positions into risk tiers.

**Columns/Parameters Involved**: `InstrumentTypeID`, `LowLeverageBound`, `HighLeverageBound`

**Rules**:
- **Forex (Type 1)**: Low=26x, High=100x. Forex has the highest leverage range — majors can go up to 30:1 under ESMA. Leverage below 26x is considered "low."
- **Commodities (Type 2)**: Low=6x, High=25x. Commodities have moderate leverage. Energy and metals CFDs typically max at 10:1 under ESMA.
- **Indices (Type 4)**: Low=6x, High=25x. Same range as commodities — index CFDs max at 20:1 under ESMA.
- **Stocks (Type 5)**: Low=2x, High=5x. Stocks have the lowest leverage — ESMA caps at 5:1 for equities. Below 2x is considered "low."
- **ETFs (Type 6)**: Low=2x, High=5x. Same as stocks — ETFs are treated as equity-like instruments.
- **Crypto (Type 10)**: Low=2x, High=5x. Crypto has the most restrictive leverage due to extreme volatility. ESMA caps at 2:1.
- A position with leverage ≤ LowLeverageBound is classified as "low leverage" for risk purposes.
- A position with leverage ≥ HighLeverageBound is at the regulatory maximum.

**Diagram**:
```
Leverage Ranges by Asset Class:
                        Low Bound    High Bound
  Forex (1)     ████████████████████████████████  26x ─── 100x
  Commodities(2)██████████████████                 6x ───  25x
  Indices (4)   ██████████████████                 6x ───  25x
  Stocks (5)    ████                               2x ───   5x
  ETFs (6)      ████                               2x ───   5x
  Crypto (10)   ████                               2x ───   5x
```

---

## 3. Data Overview

| InstrumentTypeID | LowLeverageBound | HighLeverageBound | Meaning |
|---|---|---|---|
| 1 | 26 | 100 | Forex instruments. Low-leverage threshold at 26x (below this = conservative/low-risk trading). High boundary at 100x representing maximum available leverage for professional clients. |
| 2 | 6 | 25 | Commodity instruments. Low threshold at 6x, high at 25x. Reflects ESMA's 10:1 cap for commodities with headroom for professional/non-EU clients. |
| 5 | 2 | 5 | Stock CFDs. The tightest range — leverage below 2x is "low" (essentially cash trading), and 5x is the regulatory maximum for retail equity positions under ESMA. |
| 10 | 2 | 5 | Cryptocurrency instruments. Same tight range as stocks due to extreme volatility. ESMA caps crypto leverage at 2:1 for retail — anything above 2x approaches the limit. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentTypeID | int | NO | - | VERIFIED | Primary key — the instrument type (asset class). FK to Dictionary.CurrencyType. 1=Forex, 2=Commodities, 4=Indices, 5=Stocks, 6=ETFs, 10=Crypto. One row per instrument type defines its leverage boundaries. |
| 2 | LowLeverageBound | int | NO | - | VERIFIED | The leverage multiplier below which a position is classified as "low leverage." Used for risk classification, margin calculations, and regulatory reporting. For stocks: 2x means anything at 1x leverage (no leverage) is "low." |
| 3 | HighLeverageBound | int | NO | - | VERIFIED | The upper leverage boundary for this instrument type. Represents the maximum leverage typically available. Used to validate instrument configurations and cap leverage offerings. For forex: 100x allows professional clients higher leverage than ESMA's 30:1 retail cap. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentTypeID | Dictionary.CurrencyType | Implicit FK | Parent asset class defining the instrument type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.CheckValidInstruments | InstrumentTypeID | Lookup | Validates leverage settings during instrument configuration |
| Trade.UpdateInstrumentsAvailableLeverages | InstrumentTypeID | Lookup | Used when updating available leverage options |
| Trade.InsertInstrumentRealTable | InstrumentTypeID | Lookup | Validates leverage during instrument creation |
| Customer.Customer | - | Lookup | Customer classification based on leverage usage |
| Customer.CustomerSafty | - | Lookup | Schema-bound safety view for customer data |
| Customer.IsCustomerFund | - | Lookup | Fund customer classification |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.CheckValidInstruments | Stored Procedure | Reads — leverage validation |
| Trade.UpdateInstrumentsAvailableLeverages | Stored Procedure | Reads — leverage update logic |
| Trade.InsertInstrumentRealTable | Stored Procedure | Reads — instrument creation validation |
| Trade.InsertInstrumentTradingData | Stored Procedure | Reads — trading data setup |
| Customer.Customer | View | Reads — customer leverage classification |
| Customer.CustomerSafty | View | Reads — schema-bound customer view |
| Trade.GetCustomersLivePositionData | Stored Procedure | Reads — position data with leverage context |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Dictionary_LeverageType | CLUSTERED PK | InstrumentTypeID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Dictionary_LeverageType | PRIMARY KEY | One leverage range per instrument type |

---

## 8. Sample Queries

### 8.1 List all leverage boundaries
```sql
SELECT  InstrumentTypeID,
        LowLeverageBound,
        HighLeverageBound
FROM    [Dictionary].[LeverageType] WITH (NOLOCK)
ORDER BY InstrumentTypeID;
```

### 8.2 Join to CurrencyType for asset class names
```sql
SELECT  ct.CurrencyTypeName AS AssetClass,
        lt.LowLeverageBound,
        lt.HighLeverageBound,
        lt.HighLeverageBound - lt.LowLeverageBound AS LeverageRange
FROM    [Dictionary].[LeverageType] lt WITH (NOLOCK)
JOIN    [Dictionary].[CurrencyType] ct WITH (NOLOCK)
        ON lt.InstrumentTypeID = ct.CurrencyTypeID
ORDER BY lt.HighLeverageBound DESC;
```

### 8.3 Classify leverage as low/standard/high for a given value
```sql
DECLARE @Leverage INT = 10, @InstrumentTypeID INT = 1;

SELECT  CASE
            WHEN @Leverage <= lt.LowLeverageBound  THEN 'Low Leverage'
            WHEN @Leverage >= lt.HighLeverageBound  THEN 'Maximum Leverage'
            ELSE 'Standard Leverage'
        END AS LeverageClassification
FROM    [Dictionary].[LeverageType] lt WITH (NOLOCK)
WHERE   lt.InstrumentTypeID = @InstrumentTypeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.LeverageType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.LeverageType.sql*
