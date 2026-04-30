# History.InstrumentToFeeConfigV2

> Temporal history table capturing all changes to the per-instrument, per-settlement-type overnight and end-of-week fee configuration (V2), the current active fee config system that differentiates fee rates by settlement type (CFD, real stock, TRS, etc.).

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | Clustered index on (EndTime, BeginTime) - temporal history access pattern |
| **Partition** | No |
| **Indexes** | 1 active (clustered on EndTime, BeginTime, PAGE compressed) |

---

## 1. Business Meaning

History.InstrumentToFeeConfigV2 is the SQL Server system-versioning history table for `Trade.InstrumentToFeeConfigV2`, the current (V2) per-instrument fee configuration table. V2 supersedes the legacy `Trade.InstrumentToFeeConfig` by adding two critical dimensions: SettlementTypeID (differentiating fee rates by how the position is settled - CFD, real stock, TRS, etc.) and FeeCalculationTypeID (specifying whether fee values represent dollars-per-unit or daily-interest-percentage). This makes V2 far more expressive than V1.

This history table provides the complete audit trail of fee rate changes per instrument per settlement type, enabling verification of what fees were charged on specific past positions. Since the live table has a PK of (InstrumentID, SettlementTypeID), this history table can contain multiple rows per instrument at overlapping or adjacent time windows - one per settlement type that changed.

Data flows in automatically via SYSTEM_VERSIONING. The live data shows very frequent changes (multiple per day for instrument 1/EUR/USD, updating throughout March 2026), confirming this table is actively maintained by the fee calculation processes. Changes are driven by market conditions, interest rate updates, and overnight fee recalculation jobs.

---

## 2. Business Logic

### 2.1 Settlement-Type-Differentiated Fee Rates

**What**: V2 stores separate fee configurations for each settlement type, allowing CFD positions and real stock positions on the same instrument to have completely different overnight fee structures.

**Columns/Parameters Involved**: `InstrumentID`, `SettlementTypeID`, `LeveragedBuyOverNightFee`, `LeveragedSellOverNightFee`, etc.

**Rules**:
- PK in live table: (InstrumentID, SettlementTypeID) - one row per instrument per settlement type
- SettlementTypeID: 0=CFD, 1=REAL (real stock ownership), 2=TRS (total return swap), 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE
- Live data shows SettlementTypeID=1 (REAL) with FeeCalculationTypeID=0 (ExposureFormula)
- A REAL position (actual stock ownership) typically has NonLeveragedBuyOverNightFee=0 (no borrow cost for long real stock) but positive sell fees (borrowing cost for shorting)

**Diagram**:
```
InstrumentID=1 (EUR/USD) fee configuration by settlement type:
  SettlementTypeID=1 (REAL):  LevBuyON=0.074666, LevSellON=-1.0, FeeCalcType=0 (ExposureFormula)
  SettlementTypeID=0 (CFD):   [separate row with different rates]

LeveragedSellOverNightFee = -1.0:
  Negative value = customer RECEIVES this amount when holding a short leveraged position overnight
  (market is paying the short seller a daily carry on some instruments)
```

### 2.2 Fee Calculation Method Selection

**What**: FeeCalculationTypeID determines how fee values in this row are mathematically applied to compute the actual fee charged to a customer.

**Columns/Parameters Involved**: `FeeCalculationTypeID`, all fee rate columns

**Rules**:
- 0 = ExposureFormula: fee = ExposureInUnits * FeeRate (FeeRate is in USD per unit of exposure)
- 1 = LoanFormula: fee = PositionValue * (DailyInterestRate / 100) (FeeRate is daily interest %)
- The calculation method is stored per row, enabling different instruments to use different formulas
- Trade.CalculatePositionOvernightFee and Trade.CalcOverNightFeeRates branch on this value

### 2.3 High-Frequency Updates

**What**: Unlike V1, V2 is updated very frequently - multiple times per day as market conditions change.

**Columns/Parameters Involved**: `BeginTime`, `EndTime`, `Occurred`, `UpdatedByUser`

**Rules**:
- Live data shows multiple history rows for instrument 1 on 2026-03-17 and 2026-03-18, some with windows of only minutes
- Occurred records the business timestamp; BeginTime/EndTime are the temporal system timestamps
- UpdatedByUser is typically null for automated recalculations (fee recalc jobs), populated for manual changes
- This high frequency means the history table accumulates substantial data over time

---

## 3. Data Overview

| InstrumentID | SettlementTypeID | FeeCalculationTypeID | LeveragedBuyOverNightFee | LeveragedSellOverNightFee | BeginTime | EndTime | Meaning |
|---|---|---|---|---|---|---|---|
| 1 | 1 (REAL) | 0 (ExposureFormula) | 0.074666 | -1.0 | 2026-03-18 18:46 | 2026-03-18 18:47 | Brief config window for EUR/USD real settlement - fee was quickly superseded (34-second window) |
| 1 | 1 (REAL) | 0 (ExposureFormula) | 0.074666 | -1.0 | 2026-03-17 20:48 | 2026-03-18 18:46 | EUR/USD real overnight fee valid for ~22 hours before next update; negative sell fee = customers receive carry |
| 1 | 1 (REAL) | 0 (ExposureFormula) | 0.074666 | -1.0 | 2026-03-17 18:58 | 2026-03-17 20:47 | Earlier same-day config for EUR/USD: same rates, suggesting automated daily recalculation rather than a rate change |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | The trading instrument this fee configuration applies to. Part of composite PK (InstrumentID, SettlementTypeID) in the live table. FK to Trade.Instrument(InstrumentID). |
| 2 | SettlementTypeID | tinyint | NO | 0 | VERIFIED | Specifies which settlement type this fee row applies to: 0=CFD (contract for difference, no real ownership), 1=REAL (customer owns actual shares), 2=TRS (total return swap), 3=CMT, 4=REAL_FUTURES, 5=MARGIN_TRADE. (Dictionary.SettlementTypes). DEFAULT 0 = CFD. |
| 3 | FeeCalculationTypeID | tinyint | NO | 0 | VERIFIED | Determines how fee values are mathematically applied: 0=ExposureFormula (fee = units * rate, rate is $/unit), 1=LoanFormula (fee = value * rate/100, rate is daily %). (Dictionary.FeeCalculationTypes). DEFAULT 0 = ExposureFormula. |
| 4 | NonLeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for non-leveraged short sell positions. Charged when position held over weekend (3 days). Unit determined by FeeCalculationTypeID. |
| 5 | NonLeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for non-leveraged long buy positions. Typically 0 for REAL settlement (no borrow cost for owning stock). |
| 6 | NonLeveragedBuyOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee for non-leveraged long buy positions. Typically 0 for REAL settlement as customer owns the stock outright. Non-zero for CFD settlement where there is an implicit financing cost. |
| 7 | NonLeveragedSellOverNightFee | decimal(16,8) | NO | - | CODE-BACKED | Overnight fee for non-leveraged short sell positions. Positive = customer pays; reflects stock borrowing cost for short positions. |
| 8 | LeveragedSellEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for leveraged short sell positions. Covers the 3-day weekend holding period. |
| 9 | LeveragedBuyEndOfWeekFee | decimal(16,8) | NO | - | CODE-BACKED | End-of-week fee for leveraged long buy positions. Approximately 3x the daily overnight rate for the weekend. |
| 10 | LeveragedBuyOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee for leveraged long buy positions. Positive value = customer pays interest on borrowed capital for leveraged long. Example: 0.074666 in ExposureFormula = $0.074666 per unit of exposure per night. |
| 11 | LeveragedSellOverNightFee | decimal(16,8) | NO | - | VERIFIED | Overnight fee for leveraged short sell positions. Negative value (-1.0 in live data) means the customer RECEIVES this amount per unit when holding a leveraged short overnight (positive carry on short EUR/USD REAL positions). |
| 12 | Occurred | datetime | NO | - | CODE-BACKED | Business-layer timestamp when this fee configuration was calculated or updated. Set by the fee recalculation job or manual operator. Distinct from BeginTime which is the SQL Server temporal system timestamp. |
| 13 | UpdatedByUser | varchar(50) | YES | - | CODE-BACKED | Username of operator who set this configuration. NULL for automated fee recalculation jobs; populated for manual updates via the EtoroOps interface. |
| 14 | BeginTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this fee configuration row became active in Trade.InstrumentToFeeConfigV2 (non-standard name for SysStartTime). |
| 15 | EndTime | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this fee configuration was superseded (non-standard name for SysEndTime). Rows with EndTime = '9999-12-31' are active in the live table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit (FK in live table) | The instrument whose fee history is recorded. |
| SettlementTypeID | Dictionary.SettlementTypes | Lookup | Settlement type classification for the fee row: CFD, REAL, TRS, CMT, REAL_FUTURES, MARGIN_TRADE. |
| FeeCalculationTypeID | Dictionary.FeeCalculationTypes | Lookup | Fee calculation formula type referenced from History.FeeCalculationTypes. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.InstrumentToFeeConfigV2 | SYSTEM_VERSIONING | Temporal Source | Live table that populates this history table. |

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
| Trade.InstrumentToFeeConfigV2 | Table | Live temporal table whose history is stored here |
| Trade.UpdateInstrumentToFeeConfigTableV2 | Stored Procedure | Writer - updates V2 fee configuration, generating history rows |
| Trade.CalcOverNightFeeRates | Stored Procedure | Reader - calculates overnight fee rates using current V2 config |
| Trade.GetPositionsForFeeProcess | Stored Procedure | Reader - fetches positions needing fee processing with current fee rates |
| Trade.SplitHoldingFees | Stored Procedure | Reader - splits holding fees across positions using fee rates |
| Trade.CalculatePositionOvernightFee | Function | Reader - computes overnight fee using FeeCalculationTypeID formula |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstrumentToFeeConfigV2 | CLUSTERED | EndTime ASC, BeginTime ASC | - | - | Active |

### 7.2 Constraints

None. (History tables do not have PK, FK, or CHECK constraints.)

---

## 8. Sample Queries

### 8.1 Find fee configuration for an instrument-settlement combination at a specific time
```sql
DECLARE @InstrumentID int = 1
DECLARE @SettlementTypeID tinyint = 1  -- REAL
DECLARE @AsOf datetime2 = '2026-03-17 12:00:00'
SELECT
    InstrumentID,
    SettlementTypeID,
    FeeCalculationTypeID,
    LeveragedBuyOverNightFee,
    LeveragedSellOverNightFee,
    BeginTime,
    EndTime
FROM History.InstrumentToFeeConfigV2 WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND SettlementTypeID = @SettlementTypeID
  AND BeginTime <= @AsOf
  AND EndTime > @AsOf
```

### 8.2 Find all fee rate changes for a specific instrument in the last 30 days
```sql
SELECT
    InstrumentID,
    SettlementTypeID,
    FeeCalculationTypeID,
    LeveragedBuyOverNightFee,
    LeveragedSellOverNightFee,
    BeginTime AS EffectiveFrom,
    EndTime AS EffectiveTo,
    Occurred,
    UpdatedByUser
FROM History.InstrumentToFeeConfigV2 WITH (NOLOCK)
WHERE InstrumentID = 1
  AND EndTime > DATEADD(day, -30, GETUTCDATE())
ORDER BY SettlementTypeID, BeginTime DESC
```

### 8.3 Find instruments with negative sell overnight fees (customer receives carry)
```sql
SELECT DISTINCT
    InstrumentID,
    SettlementTypeID,
    LeveragedSellOverNightFee,
    BeginTime AS EffectiveFrom,
    EndTime AS EffectiveTo
FROM History.InstrumentToFeeConfigV2 WITH (NOLOCK)
WHERE LeveragedSellOverNightFee < 0
  AND EndTime > DATEADD(year, -1, GETUTCDATE())
ORDER BY LeveragedSellOverNightFee ASC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Payments in Non-USD - Overnight Fees, Dividends, Interest](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14039384103/Payments+in+Non-USD+Overnight+Fees+Dividends+Interest) | Confluence | Context on how overnight fees are structured and processed in the multi-currency payment system |
| [Supporting Services - Multi-Currency Changes](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14039679011/Supporting+Services+Multi-Currency+Changes) | Confluence | Architecture context for how fee configurations interact with multi-currency processing |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstrumentToFeeConfigV2 | Type: Table | Source: etoro/etoro/History/Tables/History.InstrumentToFeeConfigV2.sql*
