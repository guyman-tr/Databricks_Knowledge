# Price.BuyRatioThresholds

> Per-instrument step-function table mapping buy ratio threshold levels to their corresponding skew offsets - when the measured buy ratio exceeds a Threshold value, the associated Skew offset is applied to bid/ask prices, allowing graduated price adjustments as client imbalance increases.

| Property | Value |
|----------|-------|
| **Schema** | Price |
| **Object Type** | Table |
| **Key Identifier** | InstrumentID + Threshold (CLUSTERED composite PK) |
| **Partition** | No |
| **Indexes** | 1 (PK clustered, FILLFACTOR=95) |

---

## 1. Business Meaning

Price.BuyRatioThresholds is the configuration table that defines the price skew step function for each instrument. It answers: "When buy ratio reaches level X, how much should prices be shifted?" Multiple rows per instrument define a graduated response: mild skew at moderate imbalance, stronger skew at severe imbalance.

The skew algorithm reads this table as a lookup: given a current BuyRatio (from Price.BuyRatio), find all thresholds for the instrument where BuyRatio >= Threshold, and apply the corresponding Skew value from the highest matching row. This creates a step-wise escalation - as client imbalance worsens, skew increases in discrete steps.

The Skew column is nullable - a NULL Skew on a threshold row means "no specific skew override at this level," allowing the algorithm to fall through to the next-lower threshold. In practice, all active threshold rows are expected to carry a Skew value.

Data lifecycle: rows are inserted/updated by the pricing operations team or tooling when configuring skew behavior for an instrument. All Skew value changes are audited to History.AuditHistory, and full row versions are preserved in History.BuyRatioThresholds via SQL Server temporal (system versioning).

---

## 2. Business Logic

### 2.1 Step-Function Skew Lookup

**What**: Multiple threshold rows per instrument create a graduated, step-wise skew response to buy/sell imbalance.

**Columns/Parameters Involved**: `InstrumentID`, `Threshold`, `Skew`

**Rules**:
- One or more rows per instrument; each row defines one "step" in the skew schedule
- Threshold: the buy ratio level (decimal(5,4), range 0.0000-1.0000) at which this skew step activates
- Skew: the price offset (in price units, decimal(10,4)) applied when BuyRatio >= this Threshold
- Algorithm: find the row with the largest Threshold value that is <= current BuyRatio; apply that row's Skew
- Threshold=0.5000, Skew=0.0000: base case - no skew when market is balanced
- Threshold=0.6500, Skew=0.0003: mild skew when 65% long (3 pips for a currency pair)
- Threshold=0.8000, Skew=0.0010: strong skew when 80% long (10 pips)
- Skew=NULL: skip this threshold level; fall through to lower threshold's skew value

**Diagram**:
```
Current BuyRatio for instrument 1 = 0.7200

Price.BuyRatioThresholds for InstrumentID=1:
  Threshold=0.5000, Skew=0.0000  <- base, not triggered (0.72 > 0.50 -> applies)
  Threshold=0.6000, Skew=0.0002  <- triggered (0.72 > 0.60 -> applies)
  Threshold=0.7000, Skew=0.0005  <- triggered (0.72 > 0.70 -> applies)  ** highest match **
  Threshold=0.8000, Skew=0.0010  <- NOT triggered (0.72 < 0.80)

Result: Apply Skew = 0.0005 to instrument 1's prices
  -> Price.SetActiveSkew updates Price.ActiveSkew
  -> SkewBid = 0.0005, SkewAsk = 0.0005 (or variant)
```

### 2.2 Symmetric vs Directional Skew

**What**: The same Skew value is mapped to both buy-side and sell-side adjustments through the skew algorithm.

**Columns/Parameters Involved**: `Skew`

**Rules**:
- The Skew value here is a magnitude; the algorithm determines directional application (positive = shift up for overbought, negative = shift down for oversold)
- When BuyRatio > 0.5: Skew applied upward (discourages buying, encourages selling)
- When BuyRatio < 0.5 (mirrored via separate threshold definitions): Skew applied downward
- The resulting bid/ask offsets flow into Price.ActiveSkew.SkewBid and SkewAsk

---

## 3. Data Overview

| Note | Value |
|------|-------|
| Row count (this environment) | 0 (read replica / pre-population state) |
| Multiple rows per instrument | Yes - one row per threshold step |
| Composite PK | (InstrumentID, Threshold) - ensures unique threshold level per instrument |

*Expected data pattern (inferred from schema):*

| InstrumentID | Threshold | Skew | Meaning |
|---|---|---|---|
| 1 | 0.5000 | 0.0000 | EUR/USD: balanced market, no skew |
| 1 | 0.6000 | 0.0002 | EUR/USD: mild imbalance (60% long), 2-pip skew |
| 1 | 0.7000 | 0.0005 | EUR/USD: moderate imbalance (70% long), 5-pip skew |
| 1 | 0.8000 | 0.0010 | EUR/USD: severe imbalance (80% long), 10-pip skew |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NOT NULL | - | CODE-BACKED | eToro instrument identifier. Part of the composite PK (InstrumentID, Threshold). No explicit FK in DDL, but implicitly references Trade.Instrument. Partitions the threshold configuration per instrument - each instrument can have a unique skew schedule. |
| 2 | Threshold | decimal(5,4) | NOT NULL | - | CODE-BACKED | The buy ratio level at which this skew step activates. Range [0.0000, 1.0000]. Part of the composite PK - one entry per threshold level per instrument. The skew algorithm looks up the highest Threshold where current BuyRatio >= Threshold to determine the applicable skew step. |
| 3 | Skew | decimal(10,4) | YES | - | CODE-BACKED | The price skew offset (in instrument price units) applied when the buy ratio reaches or exceeds the corresponding Threshold. NULL = no skew at this threshold level (algorithm skips to lower threshold). decimal(10,4) supports both large-price instruments (equities) and small-price instruments (micro-lot forex). |
| 4 | DbLoginName | varchar (computed) | NOT NULL | suser_name() | CODE-BACKED | Computed: SQL Server login of last row modifier. Auto-set by SQL Server on every DML. DB-level audit tracking. |
| 5 | AppLoginName | varchar(500) (computed) | YES | context_info() | CODE-BACKED | Computed: application identity via SQL Server context_info(). Populated when the calling service sets context_info before DML. NULL when not set. |
| 6 | SysStartTime | datetime2(7) | NOT NULL | getutcdate() | CODE-BACKED | Temporal row validity start. Auto-managed by system versioning. Enables point-in-time queries via FOR SYSTEM_TIME AS OF. |
| 7 | SysEndTime | datetime2(7) | NOT NULL | '9999-12-31...' | CODE-BACKED | Temporal row validity end. '9999-12-31...' = currently active. Historical versions in History.BuyRatioThresholds. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| InstrumentID | Trade.Instrument | Implicit | Thresholds are defined per instrument; no explicit FK enforced in DDL |

### 5.2 Referenced By (other objects point to this)

No SSDT objects explicitly reference this table. The skew algorithm reads it at runtime (application code).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Price.BuyRatioThresholds (table) - leaf node (no FK enforced)
  |-- Read by: skew algorithm (application code)
  |-- Sibling: Price.BuyRatioSkewConditions (eligibility gate - checked first)
  |-- Input: Price.BuyRatio (runtime ratio measurement)
  |-- Output: Price.ActiveSkew (live applied skew - written after threshold lookup)
```

---

### 6.1 Objects This Depends On

No formal dependencies (implicit reference to Trade.Instrument via InstrumentID).

### 6.2 Objects That Depend On This

No SSDT objects depend on this table (consumed by application-layer skew algorithm).

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Price_BuyRatioThresholds | CLUSTERED PK | InstrumentID ASC, Threshold ASC | - | - | Active, FILLFACTOR=95 |

*The composite clustered PK on (InstrumentID, Threshold) is ideal for the algorithm's access pattern: range scan within an InstrumentID to find all thresholds, ordered to find the highest applicable one.*

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_BuyRatioThresholds_SysStart | DEFAULT | SysStartTime = getutcdate() |
| DF_BuyRatioThresholds_SysEnd | DEFAULT | SysEndTime = '9999-12-31 23:59:59.9999999' |
| SYSTEM_VERSIONING = ON | Temporal | History in History.BuyRatioThresholds |
| AuditDelete_Price_BuyRatioThresholds | TRIGGER (DELETE) | Logs Skew old value to History.AuditHistory; PK_Value = 'InstrumentID,Threshold' |
| AuditInsert_Price_BuyRatioThresholds | TRIGGER (INSERT) | Logs Skew new value to History.AuditHistory |
| AuditUpdate_Price_BuyRatioThresholds | TRIGGER (UPDATE) | Logs old/new Skew when changed |
| TRG_T_BuyRatioThresholds | TRIGGER (INSERT) | ASM no-op placeholder: self-update on composite PK |

---

## 8. Sample Queries

### 8.1 View complete skew schedule for all instruments

```sql
SELECT InstrumentID, Threshold, Skew, DbLoginName, SysStartTime
FROM Price.BuyRatioThresholds WITH (NOLOCK)
ORDER BY InstrumentID, Threshold;
```

### 8.2 Find applicable skew for a given instrument at a given buy ratio

```sql
DECLARE @InstrumentID int = 1;
DECLARE @CurrentBuyRatio decimal(5,4) = 0.72;

SELECT TOP 1 InstrumentID, Threshold, Skew
FROM Price.BuyRatioThresholds WITH (NOLOCK)
WHERE InstrumentID = @InstrumentID
  AND Threshold <= @CurrentBuyRatio
  AND Skew IS NOT NULL
ORDER BY Threshold DESC;
```

### 8.3 View change history for an instrument's thresholds (temporal)

```sql
SELECT InstrumentID, Threshold, Skew, SysStartTime, SysEndTime
FROM Price.BuyRatioThresholds
FOR SYSTEM_TIME ALL
WHERE InstrumentID = 1
ORDER BY Threshold, SysStartTime;
```

### 8.4 Instruments with aggressive skew schedules

```sql
SELECT InstrumentID, MAX(ISNULL(Skew, 0)) AS MaxSkew, COUNT(*) AS ThresholdSteps
FROM Price.BuyRatioThresholds WITH (NOLOCK)
GROUP BY InstrumentID
ORDER BY MaxSkew DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 2, 8, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Price.BuyRatioThresholds | Type: Table | Source: etoro/etoro/Price/Tables/Price.BuyRatioThresholds.sql*
