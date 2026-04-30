# Trade.RolloverFeesAlertIfNeeded1

> Legacy version of the rollover fee alert procedure, using Trade.InstrumentToFeeConfig (non-V2) to detect fee changes exceeding per-instrument-type thresholds; email delivery is disabled (commented out) and results are stored in a global temp table ##FinalAlertsTbl for manual inspection.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @IsAlertTriggered BIT OUTPUT - indicates whether any fee anomalies were detected |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the predecessor to `Trade.RolloverFeesAlertIfNeeded` (the V2 version). It performs the same core function - detecting suspicious rollover fee changes in `Trade.InstrumentToFeeConfig` by comparing current values to previous values via the temporal chain (BeginTime/EndTime), flagging any of the 8 fee columns that change by more than the configured threshold percentage.

The key difference from the V2 version: **email sending is entirely commented out**. The procedure still populates `##FinalAlertsTbl` (a global temp table) with the alert details and sets `@IsAlertTriggered = 1`, but the `sp_send_dbmail` calls are commented out with `--`. This makes the procedure effectively a **detection-only tool** - any caller must read `##FinalAlertsTbl` to obtain the results.

The procedure also uses a slightly different price cross-validation: instead of the V2's `ABS(ABS(price%) - ABS(fee%)) <= 1` tolerance check, this version uses an exact equality `(((CurrentPrice-PreviousPrice)/PreviousPrice)*100) = ChangeRate` with no tolerance. Additionally, the threshold filter uses `> AlertThreshold` (positive only) rather than the V2's absolute-value check, so only fee increases (not decreases) trigger alerts.

The global temp table `##FinalAlertsTbl` survives after the procedure returns, allowing the caller or an ad-hoc query to inspect the flagged records.

---

## 2. Business Logic

### 2.1 Fee Change Detection (Positive Direction Only)

**What**: Identifies fee updates where any of the 8 fee types increased by more than the threshold.

**Columns/Parameters Involved**: `Trade.InstrumentToFeeConfig`, `History.InstrumentToFeeConfig`, `Trade.RolloverFeeAlertThreshold.RolloverFeeThreshold`, `Trade.InstrumentMetaData.InstrumentTypeID`

**Rules**:
- Joins current (`Trade.InstrumentToFeeConfig`) to previous (`History.InstrumentToFeeConfig`) via `curr.BeginTime = prev.EndTime`
- Calculates change% using `Trade.GetChangePercent(current, previous)` for all 8 fee types
- Threshold filter: `ChangePercent > AlertThreshold` (positive only - decreases do NOT trigger)
- Excludes `UpdatedByUser = 'split'` (automated split process)
- Filters: `VisibleInternallyOnly=0 AND Tradable=1`

**Difference from V2**: V2 uses `ABS(changePercent) > threshold` so both increases AND decreases trigger. This version only triggers on increases.

### 2.2 Result Pivoting Into Individual Fee Rows

**What**: Unpivots the 8 fee columns into individual rows, one per fee type that exceeded the threshold.

**Rules**:
- 8 UNION SELECT blocks, one per fee column
- Each row: InstrumentTypeID, InstrumentID, InstrumentName, FeeName (string), CurrentValue, PreviousValue, ChangeRate, UpdateTime, User, AlertThreshold, BeginTime_Prev
- Price cross-validation added: CurrentPrice = TOP 1 Bid from HistoryClosingPrices before UpdateTime; PreviousPrice = TOP 1 Bid before BeginTime_Prev
- Final output stored in `##FinalAlertsTbl`

### 2.3 CheckResult - Exact Price Match

**What**: Validates fee change against price change - exact equality, no tolerance.

**Columns/Parameters Involved**: `HistoryClosingPrices.Bid`, `CheckResult`

**Rules**:
- `CheckResult = IIF((((CurrentPrice-PreviousPrice)/PreviousPrice)*100) = ChangeRate, 'OK', ' - ')`
- 'OK' only if price change percentage equals fee change percentage EXACTLY (no tolerance)
- ' - ' for any mismatch, even if off by fractions of a percent
- This is stricter than V2's 1% tolerance and will produce more ' - ' flags in practice

**Diagram**:
```
Fee +15.00% change:
  Price also changed +15.00% exactly? -> CheckResult = 'OK'
  Price changed +14.99%?              -> CheckResult = ' - ' (no tolerance)
```

### 2.4 Email Disabled - Results in ##FinalAlertsTbl Only

**What**: Email code is commented out; detection results must be read from the global temp table.

**Rules**:
- `@EmailRecipients` read from `Maintenance.Feature WHERE FeatureID=113` (same as V2)
- `@subjectWithDate` built with server name, DB name, timestamp
- ALL `msdb.dbo.sp_send_dbmail` calls are commented out with `--`
- `##FinalAlertsTbl` is a global temp table (## prefix) - survives the procedure call
- `@IsAlertTriggered = 1` is still set, signaling to callers that alerts exist
- CATCH block error email is also commented out; `THROW` re-raises the exception

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @IsAlertTriggered | BIT OUTPUT | NO | - | CODE-BACKED | Returns 1 if any fee change exceeded the threshold and ##FinalAlertsTbl was populated; 0 if all fees are within threshold. Email is NOT sent regardless - caller must inspect ##FinalAlertsTbl for details. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| curr | Trade.InstrumentToFeeConfig | Lookup | Current (active) fee configuration records (non-V2 version) |
| prev | History.InstrumentToFeeConfig | Lookup | Previous fee records joined via temporal BeginTime=EndTime chain |
| meta | Trade.InstrumentMetaData | Lookup | InstrumentTypeID and display name |
| thresh | Trade.RolloverFeeAlertThreshold | Lookup | Per-instrument-type alert threshold percentage |
| pti | Trade.ProviderToInstrument | Lookup | Filters to externally-visible, tradable instruments |
| prices | dbo.HistoryClosingPrices | Lookup | Historical bid prices for price cross-validation |
| recipients | Maintenance.Feature | Lookup | FeatureID=113: email recipient list (read but email not sent) |
| function | Trade.GetChangePercent | Callee | Calculates percentage change between two values |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - legacy procedure, likely superseded by RolloverFeesAlertIfNeeded (V2).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RolloverFeesAlertIfNeeded1 (procedure - legacy)
|- Trade.InstrumentToFeeConfig (table - non-V2)
|- History.InstrumentToFeeConfig (table - non-V2 history)
|- Trade.InstrumentMetaData (table/view)
|- Trade.RolloverFeeAlertThreshold (table)
|- Trade.ProviderToInstrument (table)
|- dbo.HistoryClosingPrices (table)
|- Maintenance.Feature (table)
|- Trade.GetChangePercent (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.InstrumentToFeeConfig | Table | Current fee values (non-V2; legacy schema) |
| History.InstrumentToFeeConfig | Table | Previous fee values via temporal join |
| Trade.InstrumentMetaData | Table/View | InstrumentTypeID and display name |
| Trade.RolloverFeeAlertThreshold | Table | Alert threshold percentage per instrument type |
| Trade.ProviderToInstrument | Table | Filters to tradable, externally visible instruments |
| dbo.HistoryClosingPrices | Table | Historical price data for cross-validation |
| Maintenance.Feature | Table | FeatureID=113: email recipient list (not used - email disabled) |
| Trade.GetChangePercent | Function | Computes percentage change between fee values |

### 6.2 Objects That Depend On This

No dependents found - legacy procedure, likely called manually or by old SQL Agent job.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Positive-only threshold | Logic | ChangePercent > AlertThreshold (no ABS) - only increases trigger, decreases ignored |
| Exact price match | Logic | CheckResult 'OK' only if price% = fee% exactly (no tolerance, unlike V2's 1% tolerance) |
| Split exclusion | Logic | UpdatedByUser != 'split' - automated split updates excluded |
| Email disabled | Logic | All sp_send_dbmail calls commented out - results only in ##FinalAlertsTbl |
| Global temp table | Logic | ##FinalAlertsTbl persists after proc returns; allows post-call inspection |

---

## 8. Sample Queries

### 8.1 Execute the legacy rollover fee check

```sql
DECLARE @AlertTriggered BIT
EXEC Trade.RolloverFeesAlertIfNeeded1 @IsAlertTriggered = @AlertTriggered OUTPUT
SELECT @AlertTriggered AS WasAlertTriggered

-- If 1, inspect the results:
SELECT * FROM ##FinalAlertsTbl WITH (NOLOCK)
ORDER BY ChangeRate DESC
```

### 8.2 Compare V1 (legacy) vs V2 behavior

```sql
-- V1: Uses InstrumentToFeeConfig (non-V2), positive-only threshold, exact price match
-- V2: Uses InstrumentToFeeConfigV2, ABS threshold (both directions), 1% tolerance

-- Check if V1 table still has data (non-V2 config):
SELECT TOP 5 InstrumentID, BeginTime, UpdatedByUser
FROM Trade.InstrumentToFeeConfig WITH (NOLOCK)
ORDER BY BeginTime DESC

-- Compare with V2:
SELECT TOP 5 InstrumentID, BeginTime, UpdatedByUser
FROM Trade.InstrumentToFeeConfigV2 WITH (NOLOCK)
ORDER BY BeginTime DESC
```

### 8.3 Inspect ##FinalAlertsTbl after execution

```sql
-- Must run in same session after calling the procedure
SELECT InstrumentID, InstrumentName, FeeName,
    CurrentValue, PreviousValue, ChangeRate,
    PreviousPrice, CurrentPrice, CheckResult,
    UpdateTime, AlertThreshold
FROM ##FinalAlertsTbl WITH (NOLOCK)
WHERE CheckResult = ' - '  -- Suspicious: not explained by price movement
ORDER BY ChangeRate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RolloverFeesAlertIfNeeded1 | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RolloverFeesAlertIfNeeded1.sql*
