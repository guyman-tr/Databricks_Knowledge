# History.InterestRateOverride

> Temporal history table capturing all changes to per-instrument (or per-exchange or per-instrument-type) interest rate overrides, recording the complete audit trail of custom overnight fee rates that supersede the default base rates for specific instruments or categories.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (EndTime, BeginTime) - temporal history access pattern |
| **Partition** | No (stored on DICTIONARY filegroup) |
| **Indexes** | 1 active (clustered on EndTime, BeginTime, PAGE compressed) |

---

## 1. Business Meaning

History.InterestRateOverride is the SQL Server system-versioning history table for `Dictionary.InterestRateOverride`, which allows the trading operations team to define custom overnight fee rates that override the default rates in `Dictionary.InterestRate` for specific instruments, exchanges, or instrument types. While `Dictionary.InterestRate` provides a baseline rate by instrument type and settlement type, `Dictionary.InterestRateOverride` enables fine-grained control - for instance, applying a different overnight fee rate to a specific stock (InstrumentID), all instruments on a specific exchange (ExchangeID), or all instruments of a specific type (InstrumentTypeID).

This history table enables auditors to answer "what custom overnight rate was applied to instrument X during a specific period?" and "when did the override for exchange Y change?" — critical for explaining unusual overnight fees on past positions.

Data flows in via SYSTEM_VERSIONING from `Dictionary.InterestRateOverride`. Live data shows override ID 346 applied at the InstrumentTypeID=1 level (all instruments of that type) with null InstrumentID and ExchangeID, indicating type-level overrides are the most common pattern. The InterestRateBuy=-0.015456 (negative) means customers actually receive a small credit when buying certain instruments overnight.

---

## 2. Business Logic

### 2.1 Override Scope Hierarchy

**What**: An override can target three different scopes with implied priority: specific instrument > specific exchange > specific instrument type.

**Columns/Parameters Involved**: `InstrumentID`, `ExchangeID`, `InstrumentTypeID`

**Rules**:
- All three scope columns are nullable, allowing flexible targeting
- InstrumentID NOT NULL: override applies only to that specific instrument (highest specificity)
- InstrumentID NULL + ExchangeID NOT NULL: override applies to all instruments traded on that exchange
- InstrumentID NULL + ExchangeID NULL + InstrumentTypeID NOT NULL: override applies to all instruments of that type
- All NULL: invalid/catch-all (not expected in practice)
- When multiple overrides match an instrument, the most specific one takes precedence (instrument > exchange > type)

**Diagram**:
```
Override Resolution for Instrument X:
  1. Check: InstrumentID = X                 -> found? USE THIS (most specific)
  2. Check: ExchangeID = X.ExchangeID        -> found? USE THIS
  3. Check: InstrumentTypeID = X.TypeID      -> found? USE THIS
  4. No override found -> USE Dictionary.InterestRate default
```

### 2.2 Buy/Sell Rate Split with Markup

**What**: Same structure as InterestRate - market benchmark rates plus eToro markup, but at override granularity.

**Columns/Parameters Involved**: `InterestRateBuy`, `InterestRateSell`, `MarkupBuy`, `MarkupSell`

**Rules**:
- InterestRateBuy = the market benchmark rate for long positions for this specific override
- MarkupBuy = eToro's markup (can be 0.999 in samples, indicating a capped or near-100% markup)
- InterestRateBuy = -0.015456 (negative) means customer RECEIVES a small overnight credit for long positions on this type
- These values completely replace the base InterestRate values (not additive) when an override matches

---

## 3. Data Overview

| InterestRateOverrideID | InstrumentID | ExchangeID | InstrumentTypeID | InterestRateBuy | InterestRateSell | MarkupBuy | MarkupSell | Meaning |
|---|---|---|---|---|---|---|---|---|
| 346 | NULL | NULL | 1 | -0.015456 | 0.468752 | 0.999 | -0.887799 | Type-level override for InstrumentType=1: all instruments of this type receive a small overnight buy credit (-0.015456 base) with large markup (0.999), resulting in net positive rate for sells |
| 346 | NULL | NULL | 1 | -0.015456 | 0.9 | 0.999 | -0.887799 | Previous config for same override - sell rate was 0.9 before being changed to 0.468752 |
| 346 | NULL | NULL | 1 | -0.017002 | 0.9 | 0.999 | -0.887799 | Even older version - buy rate was slightly more negative (-0.017 vs -0.015) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InterestRateOverrideID | int | NO | - | CODE-BACKED | Surrogate PK for the override record. IDENTITY(1,1) in the live table. Uniquely identifies each override rule. |
| 2 | InstrumentID | int | YES | - | VERIFIED | Specific instrument this override applies to. NULL = override is not instrument-specific. FK to Trade.Instrument in the live table. When NOT NULL, this is the highest-priority override scope. |
| 3 | ExchangeID | int | YES | - | VERIFIED | Specific exchange this override applies to. NULL = not exchange-specific. When InstrumentID is NULL but ExchangeID is NOT NULL, applies to all instruments on that exchange. |
| 4 | InstrumentTypeID | int | YES | - | VERIFIED | Instrument type this override applies to. NULL = not type-specific (would be a catch-all). When both InstrumentID and ExchangeID are NULL, applies to all instruments of this type. |
| 5 | UpdatedByUser | varchar(50) | NO | - | CODE-BACKED | Username of operator or service that set this override. NOT NULL - always attributed to a user or automated process. |
| 6 | InterestRateBuy | decimal(16,8) | NO | - | VERIFIED | Override market benchmark rate for long buy positions. Replaces the default InterestRate.InterestRateBuy for matched instruments. Negative values mean customer receives overnight credit on long positions. |
| 7 | InterestRateSell | decimal(16,8) | NO | - | VERIFIED | Override market benchmark rate for short sell positions. Replaces the default rate for matched instruments. |
| 8 | MarkupBuy | decimal(16,8) | NO | - | CODE-BACKED | eToro markup applied on top of InterestRateBuy for buy positions in this override. |
| 9 | MarkupSell | decimal(16,8) | NO | - | CODE-BACKED | eToro markup applied on top of InterestRateSell for sell positions in this override. Negative values reduce the effective sell rate. |
| 10 | BeginTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this override became active in Dictionary.InterestRateOverride (non-standard name for SysStartTime). |
| 11 | EndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this override was superseded (non-standard name for SysEndTime). |
| 12 | OverNightFeePatternID | tinyint | YES | - | CODE-BACKED | Fee pattern for this override: 0=Regular, 1=WithNonLeverageFee, 2=Manual. Nullable - when NULL, inherits pattern from the base InterestRate table. |
| 13 | SettlementTypeID | tinyint | NO | 0 | VERIFIED | Settlement type this override applies to: 0=CFD, 1=REAL, 2=TRS, etc. DEFAULT 0 = CFD. (Dictionary.SettlementTypes). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Specific instrument when override is instrument-level. NULL = type/exchange level. |
| SettlementTypeID | Dictionary.SettlementTypes | Implicit | Settlement type the override applies to. |
| InstrumentTypeID | Dictionary/Trade instrument types | Implicit | Instrument type when override is type-level. |
| (supplements) | Dictionary.InterestRate | Lookup override | This table provides exception rates on top of the base InterestRate table. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Dictionary.InterestRateOverride | SYSTEM_VERSIONING | Temporal Source | Live table that populates this history table. |

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
| Dictionary.InterestRateOverride | Table | Live temporal table whose history is stored here |
| Trade.GetInterestRateOverrides | Stored Procedure | Reader - retrieves current override configurations |
| Trade.GetInterestRateOverrides_TRDOPS | Stored Procedure | Reader - Trading OpsTool API version for override lookup |
| Trade.UpdateInterestRateOverride | Stored Procedure | Writer - creates/updates overrides, generating history rows |
| Trade.DeleteInterestRateOverride | Stored Procedure | Deleter - removes override entries, generating history rows |
| Trade.CalcOverNightFeeRates | Stored Procedure | Reader - checks overrides when calculating rates per instrument |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InterestRateOverride | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active |

### 7.2 Constraints

None. (History tables do not have PK, FK, or CHECK constraints.)

---

## 8. Sample Queries

### 8.1 Find active override for a specific instrument at a point in time
```sql
DECLARE @InstrumentID int = 100
DECLARE @AsOf datetime2 = '2024-06-01 00:00:00'
SELECT
    InterestRateOverrideID,
    InstrumentID,
    ExchangeID,
    InstrumentTypeID,
    InterestRateBuy,
    InterestRateSell,
    MarkupBuy,
    MarkupSell,
    SettlementTypeID,
    BeginTime,
    EndTime
FROM History.InterestRateOverride WITH (NOLOCK)
WHERE (InstrumentID = @InstrumentID OR InstrumentID IS NULL)
  AND BeginTime <= @AsOf
  AND EndTime > @AsOf
ORDER BY
    CASE WHEN InstrumentID IS NOT NULL THEN 0
         WHEN ExchangeID IS NOT NULL THEN 1
         ELSE 2 END  -- most specific first
```

### 8.2 Find all changes to a specific override
```sql
SELECT
    InterestRateOverrideID,
    InstrumentID,
    ExchangeID,
    InstrumentTypeID,
    InterestRateBuy,
    InterestRateSell,
    MarkupBuy,
    MarkupSell,
    BeginTime AS EffectiveFrom,
    EndTime AS EffectiveTo,
    UpdatedByUser
FROM History.InterestRateOverride WITH (NOLOCK)
WHERE InterestRateOverrideID = 346
ORDER BY BeginTime DESC
```

### 8.3 Find all overrides that were active during a specific month
```sql
DECLARE @MonthStart datetime2 = '2024-11-01'
DECLARE @MonthEnd   datetime2 = '2024-12-01'
SELECT DISTINCT
    InterestRateOverrideID,
    InstrumentID,
    ExchangeID,
    InstrumentTypeID,
    SettlementTypeID,
    InterestRateBuy + MarkupBuy AS EffectiveBuyRate,
    InterestRateSell + MarkupSell AS EffectiveSellRate
FROM History.InterestRateOverride WITH (NOLOCK)
WHERE BeginTime < @MonthEnd
  AND EndTime > @MonthStart
ORDER BY InterestRateOverrideID
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trading OpsTool API - InterestRate HLD](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/13637779527/Trading+OpsTool+API+-+InterestRate+HLD) | Confluence | High-level design confirming the override scope hierarchy (instrument > exchange > type) and the Trading OpsTool API operations for override management |
| [Automatic Update of Default Interest Rates](https://etoro-jira.atlassian.net/wiki/spaces/EMM/pages/14014939285/Automatic+Update+of+Default+Interest+Rates) | Confluence | Context on automated rate updates that may trigger override reevaluation |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 9/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InterestRateOverride | Type: Table | Source: etoro/etoro/History/Tables/History.InterestRateOverride.sql*
