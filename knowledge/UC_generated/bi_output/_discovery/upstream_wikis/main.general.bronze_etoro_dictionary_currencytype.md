# Dictionary.CurrencyType

> Lookup table classifying tradeable instruments into asset classes (Forex, Stocks, Crypto, etc.), controlling trading rules, minimum position sizes, price sources, and UI presentation.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | CurrencyTypeID (INT, NONCLUSTERED PK) |
| **Partition** | DICTIONARY partition scheme |
| **Indexes** | 2 active (PK nonclustered + unique on Name) |

---

## 1. Business Meaning

Dictionary.CurrencyType defines the 10 asset classes available on the eToro platform. Every tradeable instrument (stored in Dictionary.Currency) belongs to exactly one currency type, which determines its fundamental trading characteristics: minimum position size, price feed source, SL/TP proximity rules, and UI display category.

This classification is essential because trading rules differ significantly between asset classes. Forex pairs have different leverage limits, spread behavior, and overnight fee calculations than stocks, which in turn differ from crypto. Without this table, the platform cannot correctly apply per-asset-class business rules, route orders to the correct execution systems, or present instruments in organized categories to users.

CurrencyTypeID is a foreign key in Dictionary.Currency and is propagated through to instrument metadata, trade views, and order execution procedures. It is read by Trade procedures for fee configuration, rollover calculations, and instrument setup; by Stocks procedures for equity-specific operations; by Price views for price feed routing; and by DWH for cross-asset analytics.

---

## 2. Business Logic

### 2.1 Asset Class Trading Parameters

**What**: Each asset class defines baseline trading parameters that instruments inherit.

**Columns/Parameters Involved**: `CurrencyTypeID`, `MinPositionAmountAbsolute`, `SLTPApproachPercent`, `PricesBy`

**Rules**:
- **MinPositionAmountAbsolute**: Minimum trade size in account currency. Ranges from $10 (Stocks, ETF, Crypto) to $200 (Indices). Forex = $25, Commodity = $25
- **SLTPApproachPercent**: How close SL/TP can be set to the current price. Forex = 0.1% (tight), Commodity/Indices/Stocks/ETF/Crypto = 1% (wider)
- **PricesBy**: Price feed provider. "eToro" for Forex, Commodity, Indices, Crypto; "Xignite" for Stocks and ETFs
- Priority controls the display order in platform category tabs

**Diagram**:
```
Asset Classes by Trading Parameters:
┌──────────┬──────────┬───────────┬──────────┐
│ Class    │ Min $    │ SLTP %    │ Prices   │
├──────────┼──────────┼───────────┼──────────┤
│ Stocks   │ $10      │ 1.0%      │ Xignite  │
│ ETF      │ $10      │ 1.0%      │ Xignite  │
│ Crypto   │ $10      │ 1.0%      │ eToro    │
│ Forex    │ $25      │ 0.1%      │ eToro    │
│ Commodity│ $25      │ 1.0%      │ eToro    │
│ Bonds    │ $50      │ -         │ -        │
│ Indices  │ $200     │ 1.0%      │ eToro    │
└──────────┴──────────┴───────────┴──────────┘
```

### 2.2 Active vs Inactive Asset Classes

**What**: Some asset classes are fully operational while others are configured but not actively trading.

**Columns/Parameters Involved**: `CurrencyTypeID`, `Priority`, `PricesBy`, `ImageUrl`

**Rules**:
- **Active** (have Priority, PricesBy, ImageUrl): Forex (1), Commodity (2), Indices (4), Stocks (5), ETF (6), Crypto (10)
- **Inactive/Legacy** (NULL Priority and PricesBy): CFD (3), Bonds (7), TrustFunds (8), Options (9)
- CFD (3) is a legacy catch-all — new instruments use specific asset class types
- Priority determines tab ordering: Stocks=1, Indices=2, Commodity=3, Forex=4, Crypto=5, ETF=6

---

## 3. Data Overview

| CurrencyTypeID | Name | MinPositionAmountAbsolute | PricesBy | Meaning |
|---|---|---|---|---|
| 1 | Forex | $25 | eToro | Foreign exchange currency pairs — the original eToro product. Includes majors (EUR/USD), minors, and exotics. Highest available leverage (up to 30x in EU). Tightest SL/TP approach (0.1%). |
| 5 | Stocks | $10 | Xignite | Individual company equities. Supports both CFD and REAL ownership (SettlementType). Lowest minimum position size. External price feed from Xignite. |
| 10 | Crypto | $10 | eToro | Cryptocurrencies (Bitcoin, Ethereum, etc.). Supports both CFD and REAL ownership (coins held in eToro wallet). eToro-sourced prices from internal matching engine. |
| 4 | Indices | $200 | eToro | Market indices (S&P 500, NASDAQ, DAX, etc.). CFD-only, highest minimum position size ($200). Used for diversified market exposure. |
| 3 | CFD | $100 | - | Legacy/generic CFD category. No active price feed or UI display. Historical instruments that predate the specific asset class taxonomy. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CurrencyTypeID | int | NO | - | VERIFIED | Primary key identifying the asset class. 1=Forex, 2=Commodity, 3=CFD (legacy), 4=Indices, 5=Stocks, 6=ETF, 7=Bonds, 8=TrustFunds, 9=Options, 10=Crypto. Foreign key in Dictionary.Currency. See [Currency Type](_glossary.md#currency-type). (Dictionary.CurrencyType) |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable asset class label. UNIQUE constraint. Used in UI category tabs, reporting, and API responses. |
| 3 | MinPositionAmountAbsolute | money | NO | (0) | CODE-BACKED | Minimum trade size in account currency (absolute amount, not percentage). Enforced at order entry time. Ranges from $10 (Stocks, ETF, Crypto) to $200 (Indices). Zero for inactive asset classes. |
| 4 | Priority | int | YES | - | CODE-BACKED | Display sort order in the platform's asset class navigation tabs. Lower number = higher priority (Stocks=1 appears first). NULL for inactive/legacy asset classes not shown in UI. |
| 5 | PricesBy | varchar(50) | YES | - | CODE-BACKED | Price feed provider name. "eToro" for internally-sourced prices (Forex, Commodity, Indices, Crypto). "Xignite" for externally-sourced equity prices (Stocks, ETF). NULL for inactive asset classes. |
| 6 | SLTPApproachPercent | decimal(5,2) | YES | (NULL) | CODE-BACKED | Minimum distance between current price and SL/TP levels, expressed as a percentage. 0.10% for Forex (tight stops allowed), 1.00% for most others. NULL for inactive asset classes. Enforced in order validation. |
| 7 | ImageUrl | varchar(max) | YES | - | CODE-BACKED | CDN URL for the asset class avatar/icon displayed in the mobile and web UI. Points to etoro-cdn.etorostatic.com. NULL for inactive asset classes. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.Currency | CurrencyTypeID | FK | Every instrument belongs to one asset class |
| Trade.GetInstrumentDeal (view) | CurrencyTypeID | JOIN | Instrument deal view includes asset class for routing |
| Price.GetInstrumentDisplayData (view) | CurrencyTypeID | JOIN | Instrument display data includes asset class metadata |
| Price.GetInstrumentAllocationData (view) | CurrencyTypeID | JOIN | Allocation data by asset class |
| Dictionary.GetCurrency (view) | CurrencyTypeID | JOIN | Currency view includes type classification |
| Dictionary.GetCurrencyType | CurrencyTypeID | Read | Procedure returning all currency types |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | CurrencyTypeID | Read | Instrument setup references asset class |
| Trade.InsertInstrumentRealTable | CurrencyTypeID | Read | Real instrument creation references asset class |
| Trade.GetRolloverFeeAlertThresholds | CurrencyTypeID | Read | Fee thresholds vary by asset class |
| Stocks.AddExitOrder | CurrencyTypeID | Read | Exit order handling references asset class |
| Stocks.AddNewStock | CurrencyTypeID | Read | New stock setup references asset class |
| Stocks.GetExposure | CurrencyTypeID | Read | Exposure calculation by asset class |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.Currency | Table | FK: CurrencyTypeID classifies every instrument |
| Price.BenchmarkFeedConfiguration | Table | Benchmark feed config per asset class |
| Trade.GetInstrumentDeal | View | Instrument deal data includes asset class |
| Price.GetInstrumentDisplayData | View | Display metadata by asset class |
| Price.GetInstrumentAllocationData | View | Allocation data by asset class |
| Dictionary.GetCurrency | View | Currency view joins to type |
| Trade.InsertInstrumentMetadataSecurityOpsAPI | Stored Procedure | Instrument setup |
| Trade.GetRolloverFeeAlertThresholds | Stored Procedure | Fee thresholds by asset class |
| Stocks.AddNewStock | Stored Procedure | Stock creation |
| Stocks.GetExposure | Stored Procedure | Exposure calculation |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCUT | NC PK | CurrencyTypeID ASC | - | - | Active |
| DCUT_NAME | NC UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DCUT | PRIMARY KEY (NC) | Unique asset class identifier — nonclustered, data physically ordered by insert sequence |
| DCUT_NAME | UNIQUE | Ensures no duplicate asset class names |
| DF_DictionaryCurrencyTypeMinPositionAmountAbsolute | DEFAULT | MinPositionAmountAbsolute defaults to 0 |

---

## 8. Sample Queries

### 8.1 List all active asset classes with trading parameters
```sql
SELECT  CurrencyTypeID,
        Name,
        MinPositionAmountAbsolute,
        PricesBy,
        SLTPApproachPercent,
        Priority
FROM    [Dictionary].[CurrencyType] WITH (NOLOCK)
WHERE   Priority IS NOT NULL
ORDER BY Priority;
```

### 8.2 Count instruments per asset class
```sql
SELECT  dct.Name AS AssetClass,
        COUNT(*) AS InstrumentCount
FROM    [Dictionary].[Currency] dc WITH (NOLOCK)
JOIN    [Dictionary].[CurrencyType] dct WITH (NOLOCK)
        ON dc.CurrencyTypeID = dct.CurrencyTypeID
GROUP BY dct.Name
ORDER BY InstrumentCount DESC;
```

### 8.3 Find instruments with their asset class parameters
```sql
SELECT  TOP 10
        dc.CurrencyID,
        dc.Name AS InstrumentName,
        dc.Abbreviation,
        dct.Name AS AssetClass,
        dct.MinPositionAmountAbsolute,
        dct.PricesBy
FROM    [Dictionary].[Currency] dc WITH (NOLOCK)
JOIN    [Dictionary].[CurrencyType] dct WITH (NOLOCK)
        ON dc.CurrencyTypeID = dct.CurrencyTypeID
WHERE   dct.Priority IS NOT NULL
ORDER BY dct.Priority, dc.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to Dictionary.CurrencyType. Business meaning derived from live data analysis and consumer procedure logic across Trade, Price, and Stocks schemas.

---

*Generated: 2026-03-13 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 12 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.CurrencyType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.CurrencyType.sql*
