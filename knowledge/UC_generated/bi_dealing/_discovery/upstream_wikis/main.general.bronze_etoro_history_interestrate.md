# History.InterestRate

> Temporal history table capturing all changes to the base interest rate configuration by instrument type and settlement type, preserving the audit trail of central bank rates and eToro markups used to calculate overnight fees.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (EndTime, BeginTime) - temporal history access pattern |
| **Partition** | No |
| **Indexes** | 1 active (clustered on EndTime, BeginTime, PAGE compressed) |

---

## 1. Business Meaning

History.InterestRate is the SQL Server system-versioning history table for `Dictionary.InterestRate`, which defines the base interest rates used to calculate overnight holding fees for trading instruments. The rate table is organized by instrument type (InstrumentTypeID) and settlement type (SettlementTypeID), providing a default set of buy and sell interest rates for each category of instruments. These rates derive from central bank benchmark rates (e.g., USD LIBOR/SOFR, CHF SARON) and are adjusted by eToro's markup to arrive at the customer-facing overnight fee.

This history table is essential for retroactively explaining why a specific overnight fee was charged on a particular date. By querying this table with a point-in-time filter, auditors can reconstruct the exact rate configuration that was active when the fee was applied, supporting regulatory compliance, customer dispute resolution, and internal fee calculation audits.

Data flows in via SYSTEM_VERSIONING from `Dictionary.InterestRate`. The live data shows named rate groups ("IR USD", "IR CHF") suggesting one row per currency denomination per instrument type, updated automatically as market rates change (confirmed by the "Automatic Update of Default Interest Rates" Confluence page). This history table stores all superseded versions of those rate rows.

---

## 2. Business Logic

### 2.1 Interest Rate Calculation Architecture

**What**: The final overnight fee for a position is derived from the base market rate plus eToro's markup, applied per instrument type and settlement type.

**Columns/Parameters Involved**: `InterestRateBuy`, `InterestRateSell`, `MarkupBuy`, `MarkupSell`, `InstrumentTypeID`, `SettlementTypeID`

**Rules**:
- InterestRateBuy: the benchmark market rate for long positions (e.g., SOFR for USD). Updated automatically from market data.
- InterestRateSell: the benchmark market rate for short positions.
- MarkupBuy: eToro's additional charge/credit on top of the market rate for long positions. Can be negative (reduces the fee) or positive (increases it).
- MarkupSell: eToro's markup for short positions.
- Final fee rate used = InterestRateBuy + MarkupBuy (buy) or InterestRateSell + MarkupSell (sell)
- The InterestRate column (legacy) is 0 in all recent data - superseded by InterestRateBuy/InterestRateSell split

**Diagram**:
```
Overnight Fee Calculation:
  InstrumentTypeID + SettlementTypeID -> Find InterestRate row

  Long Position:   fee = ExposureValue * (InterestRateBuy + MarkupBuy)
  Short Position:  fee = ExposureValue * (InterestRateSell + MarkupSell)

  Example (IR USD, InstrumentType=4, CFD):
    InterestRateBuy = 0.999, MarkupBuy = -0.000302
    -> Effective rate = 0.998698 per unit of exposure
```

### 2.2 Overnight Fee Pattern

**What**: OverNightFeePatternID controls whether non-leveraged buy positions are also subject to overnight fees.

**Columns/Parameters Involved**: `OverNightFeePatternID`

**Rules**:
- 0 = Regular: overnight fees do NOT apply to non-leveraged buy positions (customer owns the asset, no borrowing)
- 1 = WithNonLeverageFee: overnight fees DO apply to non-leveraged positions (instruments with holding costs regardless of leverage)
- 2 = Manual: fee rate is NOT automatically calculated; must be set manually by operations team
- All sampled InterestRate rows use pattern 1 (WithNonLeverageFee)

---

## 3. Data Overview

| InterestRateID | InterestRateName | InstrumentTypeID | SettlementTypeID | InterestRateBuy | InterestRateSell | MarkupBuy | MarkupSell | Meaning |
|---|---|---|---|---|---|---|---|---|
| 4 | IR CHF | 4 | 0 (CFD) | 0.04455 | 0.04945 | 0.288354 | -0.218125 | CHF-denominated Forex instrument overnight rates - the base CHF rate plus eToro's markup |
| 4 | IR CHF | 4 | 0 (CFD) | 0.04455 | 0.04945 | 0.226895 | 0.999 | Previous CHF config with different markups before last update |
| 1 | IR USD | 4 | 0 (CFD) | 0.999 | 0.1 | -0.000302 | -0.203931 | USD overnight rates for Forex instruments - high base buy rate (0.999) reflects Fed funds rate era |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InterestRateID | int | NO | - | CODE-BACKED | Identifier for the interest rate group. PK part in the live table (combined with InstrumentTypeID and SettlementTypeID). Corresponds to a named currency group (e.g., ID=1 = IR USD, ID=4 = IR CHF). |
| 2 | InterestRateName | varchar(50) | NO | - | VERIFIED | Human-readable name for this interest rate group, typically the currency denomination (e.g., "IR USD", "IR CHF"). Used for display in the Trading OpsTool interface. |
| 3 | InterestRate | decimal(16,8) | NO | - | CODE-BACKED | Legacy base rate field. Contains 0 in all recent data - superseded by the separate InterestRateBuy and InterestRateSell columns added when buy/sell rates were split. |
| 4 | UpdatedByUser | varchar(50) | NO | - | CODE-BACKED | Username of the operator or system process that last updated this rate. NOT NULL, so automated updates use a service account name. |
| 5 | BeginTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this rate configuration became active in Dictionary.InterestRate (non-standard name for SysStartTime). |
| 6 | EndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this rate configuration was superseded (non-standard name for SysEndTime). |
| 7 | InstrumentTypeID | int | NO | - | CODE-BACKED | Instrument type this rate applies to (e.g., 4 = Forex). Part of composite PK in live table. Determines which class of instruments uses this base rate. |
| 8 | InterestRateBuy | decimal(16,8) | NO | - | VERIFIED | Market benchmark rate for long buy positions (e.g., SOFR for USD, SARON for CHF). Updated automatically from market data. Combined with MarkupBuy to produce the customer-facing buy rate. |
| 9 | InterestRateSell | decimal(16,8) | NO | - | VERIFIED | Market benchmark rate for short sell positions. Combined with MarkupSell to produce the customer-facing sell rate. |
| 10 | MarkupBuy | decimal(16,8) | NO | - | VERIFIED | eToro's spread/markup added to InterestRateBuy to calculate the final overnight buy fee. Negative = eToro subsidizes the buy rate; positive = eToro charges above the market rate. |
| 11 | MarkupSell | decimal(16,8) | NO | - | VERIFIED | eToro's spread/markup added to InterestRateSell. Negative = eToro passes through a discount on short positions; positive = adds charge on top of market rate. |
| 12 | OverNightFeePatternID | tinyint | NO | 0 | VERIFIED | Determines fee calculation scope: 0=Regular (no non-leveraged buy fees), 1=WithNonLeverageFee (fees apply to non-leveraged positions too), 2=Manual (not auto-calculated). (History.OverNightFeePattern). |
| 13 | SettlementTypeID | tinyint | NO | 0 | VERIFIED | Settlement type this rate applies to: 0=CFD, 1=REAL, 2=TRS, 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. Part of composite PK in live table. (Dictionary.SettlementTypes). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentTypeID | Dictionary schema / instrument types | Implicit | The instrument category this rate applies to. |
| SettlementTypeID | Dictionary.SettlementTypes | Implicit | Settlement type classification. |
| OverNightFeePatternID | History.OverNightFeePattern | Implicit | Fee pattern type controlling non-leveraged fee inclusion. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.InterestRate | SYSTEM_VERSIONING | Temporal Source | Live table that populates this history table. |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies. (Temporal history table.)

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.InterestRate | Table | Live temporal table whose history is stored here |
| Trade.CalcOverNightFeeRates | Stored Procedure | Reader - uses interest rates to calculate per-instrument overnight fees |
| Trade.GetAllInterestRates | Stored Procedure | Reader - retrieves current interest rate configuration |
| Trade.GetInstrumentInterestRates | Stored Procedure | Reader - retrieves rates for a specific instrument |
| Trade.UpdateInterestRate | Stored Procedure | Writer - updates interest rates, generating history rows |
| Trade.UpdateInterestRates_TRDOPS | Stored Procedure | Writer - bulk update of interest rates via Trading OpsTool API |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InterestRate | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active |

### 7.2 Constraints

None. (History tables do not have PK, FK, or CHECK constraints.)

---

## 8. Sample Queries

### 8.1 Find interest rate configuration for a currency group at a specific point in time
```sql
DECLARE @AsOf datetime2 = '2024-01-01 00:00:00'
SELECT
    InterestRateID,
    InterestRateName,
    InstrumentTypeID,
    SettlementTypeID,
    InterestRateBuy,
    InterestRateSell,
    MarkupBuy,
    MarkupSell,
    OverNightFeePatternID,
    BeginTime,
    EndTime
FROM History.InterestRate WITH (NOLOCK)
WHERE InterestRateID = 1  -- IR USD
  AND BeginTime <= @AsOf
  AND EndTime > @AsOf
ORDER BY InstrumentTypeID, SettlementTypeID
```

### 8.2 Find all changes to USD interest rates
```sql
SELECT
    InterestRateID,
    InterestRateName,
    InstrumentTypeID,
    SettlementTypeID,
    InterestRateBuy,
    InterestRateSell,
    MarkupBuy,
    MarkupSell,
    BeginTime AS EffectiveFrom,
    EndTime AS EffectiveTo,
    UpdatedByUser
FROM History.InterestRate WITH (NOLOCK)
WHERE InterestRateName = 'IR USD'
ORDER BY BeginTime DESC
```

### 8.3 Compare buy and sell overnight rates across all currency groups at current time
```sql
SELECT
    h.InterestRateID,
    h.InterestRateName,
    h.InstrumentTypeID,
    h.SettlementTypeID,
    h.InterestRateBuy + h.MarkupBuy AS EffectiveBuyRate,
    h.InterestRateSell + h.MarkupSell AS EffectiveSellRate,
    h.BeginTime
FROM History.InterestRate h WITH (NOLOCK)
INNER JOIN Dictionary.InterestRate d WITH (NOLOCK)
    ON h.InterestRateID = d.InterestRateID
    AND h.InstrumentTypeID = d.InstrumentTypeID
    AND h.SettlementTypeID = d.SettlementTypeID
    AND h.BeginTime = d.BeginTime  -- join to get latest
ORDER BY h.InterestRateName, h.InstrumentTypeID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Automatic Update of Default Interest Rates](https://etoro-jira.atlassian.net/wiki/spaces/EMM/pages/14014939285/Automatic+Update+of+Default+Interest+Rates) | Confluence | Describes the automated process that updates InterestRate values from market benchmarks |
| [Trading OpsTool API - InterestRate HLD](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13637779527/Trading+OpsTool+API+-+InterestRate+HLD) | Confluence | High-level design of the Trading OpsTool API for interest rate management, confirming the rate structure and update flows |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InterestRate | Type: Table | Source: etoro/etoro/History/Tables/History.InterestRate.sql*
