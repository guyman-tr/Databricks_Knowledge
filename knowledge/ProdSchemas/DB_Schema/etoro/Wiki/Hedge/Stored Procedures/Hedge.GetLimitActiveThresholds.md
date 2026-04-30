# Hedge.GetLimitActiveThresholds

> Returns the active limit execution threshold value (in Pips) per instrument, joining Trade.ActiveFeatureThreshold and Trade.FeatureThresholdValues for FeatureID=5 (Limit Execution). Used by the hedge engine to load per-instrument limit order execution tolerance at startup.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | None - no parameters; returns all instruments with FeatureID=5 thresholds |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetLimitActiveThresholds provides per-instrument limit order execution thresholds: how many pips away from the requested price a limit order fill is acceptable. The hedge engine uses this to determine whether an executed limit order was filled "close enough" to the requested price, or whether it should be rejected/flagged.

**Feature architecture context**: eToro's trading system has 6 configurable features per instrument (Price Filter, Execution Delay, Rate Volatility, Inactivity Timeout, Limit Execution, Rate Volatility %). This procedure specifically loads Feature 5 = Limit Execution (Pip). Each instrument has an "active threshold level" (Minimum/Low/Medium/High/Maximum) in Trade.ActiveFeatureThreshold, and the actual numeric value for that level is in Trade.FeatureThresholdValues. The JOIN between them (matching FeatureID, ThresholdID, and InstrumentID) resolves to a single pip value per instrument.

**DDL note**: The file also contains a commented-out procedure (`GetAllHBCAccountConfigurations`) that was explicitly not approved - "Not approve By Bonnie - returns 228K rows!" This commented code is inert and not executed; it serves as documentation that this approach was evaluated and rejected due to result set size concerns.

---

## 2. Business Logic

### 2.1 Feature 5 = Limit Execution (Pip)

**What**: FeatureID=5 is the Limit Execution feature - defines the pip tolerance for limit order fill acceptance.

**Columns/Parameters Involved**: `ath.FeatureID = 5`, `fth.Value`

**Rules**:
- WHERE `ath.FeatureID = 5` filters to the Limit Execution feature only.
- The "Value" returned is in Pips (as per the feature definition in Dictionary.Feature).
- A higher pip value = more tolerant of price slippage on limit fills.
- Each instrument has one active threshold level (Minimum=0, Low=5, Medium=10, High=15, Maximum=20 in terms of ThresholdID).

### 2.2 Three-Column Join for Active Threshold Resolution

**What**: Joins ActiveFeatureThreshold with FeatureThresholdValues to resolve the active threshold's numeric value.

**Columns/Parameters Involved**: `ath.FeatureID`, `ath.ActiveThresholdID`, `ath.InstrumentID`, `fth.ThresholdID`, `fth.InstrumentID`, `fth.Value`

**Rules**:
- `Trade.ActiveFeatureThreshold ath JOIN Trade.FeatureThresholdValues fth ON ath.FeatureID = fth.FeatureID AND ath.ActiveThresholdID = fth.ThresholdID AND ath.InstrumentID = fth.InstrumentID`
- The triple-condition join ensures the exact row for this instrument's active threshold level is selected.
- Result: one row per instrument (since each instrument has exactly one ActiveThresholdID for FeatureID=5).
- NOLOCK on both tables - appropriate for read-heavy startup loads of configuration data.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | eToro instrument identifier. One row per instrument that has a FeatureID=5 threshold configured. |
| 2 | Value | decimal | NO | - | CODE-BACKED | The active Limit Execution threshold in Pips. From Trade.FeatureThresholdValues.Value for the instrument's active threshold level. Hedge engine uses this to validate limit fill tolerance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ath source | Trade.ActiveFeatureThreshold | Cross-schema Lookup | Active threshold level per instrument for FeatureID=5. |
| fth join | Trade.FeatureThresholdValues | Cross-schema Lookup | Numeric pip value for the active threshold level. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge engine (external) | Result set | Caller | Loads limit order execution pip tolerance per instrument at startup. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetLimitActiveThresholds (procedure)
├── Trade.ActiveFeatureThreshold (table) [cross-schema]
└── Trade.FeatureThresholdValues (table) [cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ActiveFeatureThreshold | Table | Cross-schema: FeatureID=5 filter, ActiveThresholdID per instrument. |
| Trade.FeatureThresholdValues | Table | Cross-schema: numeric Value for the active threshold level per (InstrumentID, FeatureID, ThresholdID). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge engine (external) | Application | Startup load of limit execution pip tolerance for order fill validation. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

NOLOCK on both tables. No temp tables. No parameters. Triple-condition JOIN (FeatureID + ThresholdID + InstrumentID) resolves to one row per instrument.

**DDL comments note**: The SQL file also contains a commented-out CREATE PROC block for `Hedge.GetAllHBCAccountConfigurations` that was marked "Not approve By Bonnie - returns 228K rows!" This procedure was evaluated and rejected due to its large result set size. It is not deployed and the comment serves as a design history note.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Hedge.GetLimitActiveThresholds;
```

### 8.2 Manually resolve active threshold values for FeatureID=5

```sql
SELECT ath.InstrumentID, ath.ActiveThresholdID, fth.Value AS LimitExecutionPips
FROM   Trade.ActiveFeatureThreshold ath WITH (NOLOCK)
JOIN   Trade.FeatureThresholdValues fth WITH (NOLOCK)
       ON ath.FeatureID = fth.FeatureID
       AND ath.ActiveThresholdID = fth.ThresholdID
       AND ath.InstrumentID = fth.InstrumentID
WHERE  ath.FeatureID = 5
ORDER BY fth.Value DESC; -- Highest tolerance first
```

### 8.3 Compare limit execution thresholds across features

```sql
-- See all active threshold values for a specific instrument
SELECT ath.FeatureID, ath.ActiveThresholdID, fth.Value
FROM   Trade.ActiveFeatureThreshold ath WITH (NOLOCK)
JOIN   Trade.FeatureThresholdValues fth WITH (NOLOCK)
       ON ath.FeatureID = fth.FeatureID
       AND ath.ActiveThresholdID = fth.ThresholdID
       AND ath.InstrumentID = fth.InstrumentID
WHERE  ath.InstrumentID = 9920
ORDER BY ath.FeatureID;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | Limit order execution thresholds; per-instrument feature threshold configuration for hedge routing. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetLimitActiveThresholds | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetLimitActiveThresholds.sql*
