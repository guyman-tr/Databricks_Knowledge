# Price.PriceAlgoThresholds

> Per-instrument stepped skew lookup table that maps buy-ratio threshold levels to corresponding skew values, enabling the pricing algorithm to apply progressively larger price adjustments as the buy/sell imbalance increases.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | (InstrumentID, Threshold) - composite CLUSTERED PK |
| **Partition** | No |
| **Indexes** | 1 (PK clustered composite) |

---

## 1. Business Meaning

PriceAlgoThresholds defines a stepped skew function for each instrument. The composite PK `(InstrumentID, Threshold)` allows multiple threshold levels per instrument, each paired with a `Skew` value. This creates a piecewise linear (or step) mapping: when the buy ratio (proportion of clients buying vs. selling) crosses a threshold, the corresponding skew is applied to the instrument's mid-price.

For example, an instrument might have thresholds at 0.5 (neutral), 0.6 (moderately more buyers), and 0.8 (strongly bullish) - each with an increasing skew that pushes the ask price higher to reflect the supply/demand imbalance. The pricing algorithm selects the appropriate threshold row and applies the associated skew value.

The `Threshold` column is `decimal(5,4)` (range 0.0000 to 9.9999 with 4 decimal places), typical for a ratio between 0 and 1. The `Skew` column is `decimal(16,6)` and nullable - a NULL skew may indicate "no skew" at that threshold level.

The table is currently empty (0 rows) and not referenced by any stored procedures or views in the Price schema SSDT repo. Like `Price.PriceAlgoSkewConditions`, it appears to be provisioned infrastructure for a pricing algorithm skew feature not yet populated. InstrumentID has no FK constraint (unlike PriceAlgoSkewConditions).

---

## 2. Business Logic

### 2.1 Stepped Skew Function per Instrument

**What**: Multiple threshold/skew pairs per instrument define a function that maps buy ratio levels to price skew amounts.

**Columns/Parameters Involved**: `InstrumentID`, `Threshold`, `Skew`

**Rules**:
- Composite PK (InstrumentID, Threshold) allows multiple rows per instrument - one per threshold level
- Threshold is decimal(5,4) - likely a buy ratio fraction (0.0000 to 1.0000) or a percentage
- Skew is decimal(16,6) and nullable (NULL may mean "no skew adjustment at this level")
- No FK constraint on InstrumentID - allows pre-population for instruments pending other FK constraints
- No consumers currently apply these values - the step-function lookup logic lives in consuming application code or unpresent procedures

---

## 3. Data Overview

The table is currently empty (0 rows). No threshold-skew mappings are configured.

*When populated, rows would appear as:*

| InstrumentID | Threshold | Skew | Meaning |
|---|---|---|---|
| 1 (EUR/USD) | 0.5000 | NULL | At 50% buy ratio (neutral), no skew applied |
| 1 (EUR/USD) | 0.6000 | 0.000050 | At 60% buy ratio, ask is nudged up by 5 pips (0.00005) |
| 1 (EUR/USD) | 0.8000 | 0.000150 | At 80% buy ratio (heavily bullish), ask pushed up 15 pips |
| 5 | 0.5000 | 0.001000 | Instrument 5 applies 0.1% skew at the 50% threshold (higher base skew) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | VERIFIED | Part 1 of composite PK. The instrument for which this threshold-skew mapping applies. No FK constraint in DDL - InstrumentID validity enforced procedurally or by application. Multiple rows per instrument are expected (one per threshold level). |
| 2 | Threshold | decimal(5,4) | NOT NULL | - | NAME-INFERRED | Part 2 of composite PK. The buy-ratio or imbalance level at which this skew takes effect. Decimal(5,4) accommodates ratios in the 0.0000-9.9999 range, typically 0.0000-1.0000 for buy/sell fraction. Multiple thresholds per instrument create a stepped skew function. |
| 3 | Skew | decimal(16,6) | YES | - | NAME-INFERRED | The skew value to apply when the buy ratio meets or exceeds the Threshold. Nullable - NULL indicates no skew at this threshold level. Decimal(16,6) supports very precise fractional price adjustments (e.g., 0.000050 = 5 pips for a 4-decimal instrument). Applied by the pricing algorithm to shift the mid-price bid/ask asymmetrically. |
| 4 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set on DML. |
| 5 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity from context_info(). |
| 6 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal period start. Auto-managed by SQL Server system versioning. |
| 7 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31 23:59:59.9999999' | CODE-BACKED | Temporal period end. Historical row versions in History.PriceAlgoThresholds. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Procedural (no FK constraint) | No DB-level FK; InstrumentID validity enforced by application/procedure layer |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. No stored procedures or views currently reference this table.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.PriceAlgoThresholds (table)
|- (no FK constraints - InstrumentID is a logical dependency only)
```

---

### 6.1 Objects This Depends On

No FK constraints defined. Logically depends on Trade.Instrument for InstrumentID values.

### 6.2 Objects That Depend On This

No dependents found. The table is currently not referenced by any stored procedures or views.

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Price_PriceAlgoThresholds | CLUSTERED PK | InstrumentID ASC, Threshold ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_Price_PriceAlgoThresholds | PRIMARY KEY | Composite PK - one skew per (instrument, threshold level) |
| DF_PriceAlgoThresholds_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_PriceAlgoThresholds_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | Full history in History.PriceAlgoThresholds |
| TRG_T_PriceAlgoThresholds | TRIGGER (INSERT) | ASM no-op: self-update on InstrumentID after insert |

---

## 8. Sample Queries

### 8.1 View all threshold-skew mappings ordered by instrument and threshold

```sql
SELECT
    InstrumentID,
    Threshold,
    Skew,
    SysStartTime AS ConfiguredSince
FROM Price.PriceAlgoThresholds WITH (NOLOCK)
ORDER BY InstrumentID, Threshold;
```

### 8.2 View the full stepped skew function for a specific instrument

```sql
SELECT
    InstrumentID,
    Threshold,
    Skew,
    CASE WHEN Skew IS NULL THEN 'No skew at this level' ELSE CAST(Skew AS VARCHAR) END AS SkewDescription
FROM Price.PriceAlgoThresholds WITH (NOLOCK)
WHERE InstrumentID = 1  -- replace with target InstrumentID
ORDER BY Threshold;
```

### 8.3 View change history (temporal)

```sql
SELECT
    InstrumentID,
    Threshold,
    Skew,
    DbLoginName,
    SysStartTime,
    SysEndTime
FROM Price.PriceAlgoThresholds
FOR SYSTEM_TIME ALL
ORDER BY InstrumentID, Threshold, SysStartTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.0/10 (Elements: 8/10, Logic: 5/10, Relationships: 5/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 2 NAME-INFERRED | Phases: 1, 2, 4, 7, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.PriceAlgoThresholds | Type: Table | Source: etoro/etoro/Price/Tables/Price.PriceAlgoThresholds.sql*
