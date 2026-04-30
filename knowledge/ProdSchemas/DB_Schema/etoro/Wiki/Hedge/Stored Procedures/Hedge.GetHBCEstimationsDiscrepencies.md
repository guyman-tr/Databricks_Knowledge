# Hedge.GetHBCEstimationsDiscrepencies

> Reconciliation procedure that detects HBC execution discrepancies: finds cases where the lots executed in HBCExecutionLog do not match the sum of customer position lot counts for the same execution, within a time window driven by Maintenance.Feature configuration.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxTime OUTPUT - the upper bound of the analysis window (returned to caller) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHBCEstimationsDiscrepencies is the primary HBC reconciliation check. It compares the lots actually executed by the HBC subsystem (ExecutionAmountInLots in Hedge.HBCExecutionLog) against the sum of lots from all customer positions that are linked to the same execution (via InitExecutionID/EndExecutionID in Trade.GetPositionDataSlim). When these don't match, it signals a hedging error that may require correction.

The discrepancy check exists because HBC rounds lot amounts at execution time (requested lots -> whole-lot ceiling). If the rounded execution amount doesn't match the total of the customer position lots it was supposed to hedge, the hedge position is out of alignment with customer exposure. The HedgeAlertService calls this procedure on a scheduled basis and forwards any returned rows to the operations/alerting system for investigation.

The time window is fully configurable via Maintenance.Feature flags: FeatureID 43 sets the last-processed time (cursor), FeatureID 42 sets the lookback window in seconds. The procedure returns @MaxTime as an OUTPUT parameter so the caller can advance the cursor after processing.

PlayerLevelID=4 customers (internal/test accounts) are excluded via a join to Customer.Customer - the reconciliation is only meaningful for real customer positions.

---

## 2. Business Logic

### 2.1 Time Window from Maintenance.Feature Configuration

**What**: The analysis window is defined by two Maintenance.Feature rows rather than caller-supplied parameters.

**Columns/Parameters Involved**: `@MaxTime` (OUTPUT), Maintenance.Feature (FeatureID 42, FeatureID 43)

**Rules**:
- FeatureID 43 -> Value (cast to datetime) = @LastTime: the start of the window (last processed up to here).
- FeatureID 42 -> Value (cast to int) = @TimeRangeSeconds: how many seconds back from NOW to look.
- @MaxTime (OUTPUT) = DATEADD(second, -@TimeRangeSeconds, GETUTCDATE()): the upper bound, calculated internally.
- Query filter: `exe.EndTime >= @LastTime AND exe.EndTime < @MaxTime`.
- The caller receives @MaxTime so it can update FeatureID 43 to advance the cursor after processing the returned discrepancies.

**Diagram**:
```
Timeline:
  |--- @LastTime (FeatureID 43) ----------- @MaxTime (= NOW - @TimeRangeSeconds) --- NOW
       ^                                    ^
       Window start (last processed)        Window end (returned as OUTPUT)
       exe.EndTime >= @LastTime             exe.EndTime < @MaxTime
```

### 2.2 Discrepancy Detection Logic

**What**: For each successful HBC execution in the window, sum the LotCountDecimal of all linked customer positions and compare to ExecutionAmountInLots.

**Columns/Parameters Involved**: `ExecutionAmountInLots`, `SumLotDecimal`, `IsOpen`, `AmountInLots`

**Rules**:
- Join: HBCExecutionLog -> Trade.GetPositionDataSlim on `(InitExecutionID = ExecutionID OR EndExecutionID = ExecutionID)` AND `HedgeServerID` match.
- Group by ExecutionID, compute `SUM(pos.LotCountDecimal) as SumLotDecimal`.
- Filter executions: `IsSuccess = 1` (successful executions only); `cust.PlayerLevelID <> 4` (exclude internal accounts).
- Position filter: `(OpenOccurred >= @LastTime AND IsOpened = 1)` OR `(CloseOccurred >= @LastTime AND IsOpened = 0)` - only recently opened or closed positions.
- Discrepancy condition: `SumLotDecimal <> ExecutionAmountInLots`.
- `AmountInLots` in the output = SumLotDecimal - ExecutionAmountInLots (the gap, positive or negative).
- Two temp table indexes on (ExecutionAmountInLots) and (SumLotDecimal) speed up the final inequality filter.

### 2.3 Open vs Close Classification

**What**: IsOpen in the output distinguishes whether the discrepancy involves an opening or closing hedge.

**Columns/Parameters Involved**: `ExecutionIsBuy`, `PositionIsBuy`, `IsOpen`

**Rules**:
- `IsOpen = CASE WHEN ExecutionIsBuy = PositionIsBuy THEN 1 ELSE 0 END`
- When the execution direction matches the position direction: IsOpen=1 (this execution was an opening hedge).
- When directions differ: IsOpen=0 (this execution was a closing hedge).
- This follows the convention that opening a position and its hedge have the same IsBuy direction, while closing involves the opposite direction.

### 2.4 OPTION(RECOMPILE) for Plan Stability

**What**: The temp table population uses OPTION(RECOMPILE) to avoid parameter-sniffing issues.

**Rules**:
- The time window (@LastTime, @MaxTime) varies between calls, which could cause a poor cached plan.
- RECOMPILE forces a fresh plan per call, appropriate for a monitoring procedure called periodically (not high-frequency).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxTime | DATETIME | NO | - | CODE-BACKED | OUTPUT parameter. Set internally to DATEADD(second, -@TimeRangeSeconds, GETUTCDATE()) where @TimeRangeSeconds comes from Maintenance.Feature FeatureID 42. Returned to the caller so it can advance the processing cursor (update Maintenance.Feature FeatureID 43 to this value after processing discrepancies). |

**Output Columns** (returned resultset):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | NotificationTime | datetime | NO | - | CODE-BACKED | The EndTime of the HBC execution with the discrepancy. Used by the alerting system as the timestamp for the alert notification. |
| 3 | HedgeServerID | int | NO | - | CODE-BACKED | The hedge server that performed the discrepant execution. Joins to Trade.HedgeServer for server name/config. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | The instrument involved in the discrepancy. Implicit FK to Trade.Instrument. Identifies which market the lot mismatch occurred in. |
| 5 | AmountInLots | decimal | YES | - | CODE-BACKED | The discrepancy amount: SumLotDecimal - ExecutionAmountInLots. Positive = customer positions have more lots than were executed (under-hedged in lot terms). Negative = executed more lots than customer position sum (over-hedged). |
| 6 | IsBuy | bit | NO | - | CODE-BACKED | Direction of the customer position (PositionIsBuy). 1=customer positions were buys (eToro hedged with a sell); 0=customer positions were sells. Used by the alerting system to determine which side of the market the discrepancy affects. |
| 7 | IsOpen | bit | NO | - | CODE-BACKED | Whether the discrepancy involves an opening or closing hedge. 1=opening hedge (ExecutionIsBuy = PositionIsBuy), 0=closing hedge (directions differ). Helps triage whether the gap was introduced when the hedge was opened or closed. |
| 8 | Description | varchar | NO | - | CODE-BACKED | Diagnostic string concatenating key values: "ExecutionID: {id} ExecutionAmountInLots: {val} SumLotDecimal: {val} IsOpen: {0/1}". Included in alert notifications for quick diagnosis without a follow-up query. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExecutionID join | Hedge.HBCExecutionLog | Lookup / Read | Source of execution amounts; filtered by IsSuccess=1 and time window. |
| InitExecutionID/EndExecutionID join | Trade.GetPositionDataSlim | Cross-schema Lookup | Position lot sums grouped by execution; cross-schema join to Trade. |
| CID join | Customer.Customer | Cross-schema Lookup | Filters out PlayerLevelID=4 (internal/test) customers. |
| FeatureID 42, 43 | Maintenance.Feature | Configuration Read | Provides the time window bounds (@TimeRangeSeconds, @LastTime). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HedgeAlertService (external) | @MaxTime OUTPUT | Caller | Scheduled alerting service that calls this proc, processes returned rows, then advances cursor by updating FeatureID 43 to the returned @MaxTime. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHBCEstimationsDiscrepencies (procedure)
├── Hedge.HBCExecutionLog (table)
│     ├── Trade.HedgeServer (table) [FK]
│     └── Trade.LiquidityAccounts (table) [FK]
├── Trade.GetPositionDataSlim (view) [cross-schema]
├── Customer.Customer (table) [cross-schema]
└── Maintenance.Feature (table) [config - FeatureID 42, 43]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HBCExecutionLog | Table | Source of ExecutionID, ExecutionAmountInLots, EndTime, IsBuy, HedgeServerID; filtered IsSuccess=1 within time window. |
| Trade.GetPositionDataSlim | View | Cross-schema: provides LotCountDecimal, InitExecutionID, EndExecutionID, HedgeServerID, IsBuy, OpenOccurred, CloseOccurred, IsOpened, CID. |
| Customer.Customer | Table | Cross-schema: PlayerLevelID filter to exclude internal (=4) customer positions. |
| Maintenance.Feature | Table | Config source: FeatureID 42 = TimeRangeSeconds, FeatureID 43 = LastTime (window cursor). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| HedgeAlertService (external) | Application | Scheduled caller - processes discrepancy rows and advances the time cursor. |
| Hedge.GetHBCEstimationsDiscrepencies_Child | Procedure | Sister variant - likely handles cross-server or child-server scenarios. |
| Hedge.GetHBCEstimationsDiscrepencies_Child_ss | Procedure | Sister variant with snapshot isolation. |
| Hedge.GetHBCEstimationsDiscrepencies_Flat | Procedure | Sister variant returning flat (non-grouped) output. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Runtime temp table**: `#executions` - created per call with:
- NC index on `ExecutionAmountInLots`
- NC index on `SumLotDecimal`
(Both support the final `WHERE ExecutionAmountInLots <> SumLotDecimal` filter.)

---

## 8. Sample Queries

### 8.1 Execute the discrepancy check (show current window and discrepancies)

```sql
DECLARE @MaxTime DATETIME;
EXEC Hedge.GetHBCEstimationsDiscrepencies @MaxTime = @MaxTime OUTPUT;
SELECT @MaxTime AS WindowUpperBound;
```

### 8.2 Manually replicate the check for a custom time range

```sql
-- Replace @LastTime and @MaxTime with desired window
DECLARE @LastTime DATETIME = DATEADD(hour, -2, GETUTCDATE());
DECLARE @MaxTime DATETIME = DATEADD(second, -30, GETUTCDATE());

SELECT exe.EndTime AS NotificationTime,
       exe.HedgeServerID, pos.InstrumentID,
       SUM(pos.LotCountDecimal) - exe.ExecutionAmountInLots AS AmountInLots,
       pos.IsBuy,
       CASE WHEN exe.IsBuy = pos.IsBuy THEN 1 ELSE 0 END AS IsOpen,
       exe.ExecutionID, exe.ExecutionAmountInLots,
       SUM(pos.LotCountDecimal) AS SumLotDecimal
FROM   Hedge.HBCExecutionLog exe WITH (NOLOCK)
JOIN   Trade.GetPositionDataSlim pos WITH (NOLOCK)
    ON (exe.ExecutionID = pos.InitExecutionID OR exe.ExecutionID = pos.EndExecutionID)
    AND pos.HedgeServerID = exe.HedgeServerID
JOIN   Customer.Customer cust WITH (NOLOCK) ON cust.CID = pos.CID
WHERE  exe.EndTime >= @LastTime AND exe.EndTime < @MaxTime
   AND exe.IsSuccess = 1
   AND cust.PlayerLevelID <> 4
   AND ((pos.OpenOccurred >= @LastTime AND pos.IsOpened = 1)
     OR (pos.CloseOccurred >= @LastTime AND pos.IsOpened = 0))
GROUP BY exe.ExecutionID, exe.ExecutionAmountInLots, exe.HedgeServerID,
         exe.EndTime, exe.IsBuy, pos.IsBuy, pos.InstrumentID
HAVING SUM(pos.LotCountDecimal) <> exe.ExecutionAmountInLots;
```

### 8.3 Check Maintenance.Feature window configuration

```sql
SELECT FeatureID,
       CASE FeatureID WHEN 42 THEN 'TimeRangeSeconds' WHEN 43 THEN 'LastTime' END AS FeatureName,
       Value
FROM   Maintenance.Feature WITH (NOLOCK)
WHERE  FeatureID IN (42, 43);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | GetHBCEstimationsDiscrepencies validates ExecutionAmountInLots against customer position lots; HedgeAlertService calls this on schedule; part of HBC reconciliation monitoring. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.1/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 sister variants analyzed | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHBCEstimationsDiscrepencies | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHBCEstimationsDiscrepencies.sql*
