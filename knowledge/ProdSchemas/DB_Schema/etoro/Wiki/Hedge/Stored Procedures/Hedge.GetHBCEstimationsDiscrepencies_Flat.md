# Hedge.GetHBCEstimationsDiscrepencies_Flat

> Flat-config variant of the HBC discrepancy check: identical logic to the parent but reads the time window from DB_Logs.Hedge.Feature (a cross-database Feature table) instead of Maintenance.Feature; "_Flat" = flat output from DB_Logs config.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxTime OUTPUT - upper bound of analysis window (returned to caller) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Hedge.GetHBCEstimationsDiscrepencies_Flat is a variant of the HBC discrepancy check that reads its Feature configuration from `DB_Logs.Hedge.Feature` rather than the standard `Maintenance.Feature` table. The reconciliation logic, output, and parameters are otherwise identical to the parent procedure (GetHBCEstimationsDiscrepencies).

The "_Flat" naming indicates this variant is used in a deployment context where the Feature configuration lives in the DB_Logs database under the Hedge schema. This separation allows the feature flags for different variants of the check to be managed independently (Maintenance.Feature for the primary, DB_Logs.Hedge.Feature for the flat variant), enabling different schedules, lookback windows, or cursor positions per deployment path.

Like the parent, it uses `Trade.GetPositionDataSlim`, OPTION(RECOMPILE), and temp table NC indexes - making it a performance-equivalent copy of the parent, differing only in the Feature table source.

---

## 2. Business Logic

### 2.1 DB_Logs.Hedge.Feature Configuration Source

**What**: Feature flags are read from DB_Logs.Hedge.Feature instead of Maintenance.Feature.

**Columns/Parameters Involved**: `@MaxTime` (OUTPUT), `DB_Logs.Hedge.Feature` (FeatureID 42, 43)

**Rules**:
- FeatureID 43 from DB_Logs.Hedge.Feature -> @LastTime (window cursor).
- FeatureID 42 from DB_Logs.Hedge.Feature -> @TimeRangeSeconds (lookback window).
- @MaxTime OUTPUT = DATEADD(second, -@TimeRangeSeconds, GETUTCDATE()) - same calculation as parent.
- The parent reads from `Maintenance.Feature` (same database, different schema). This variant reads from `DB_Logs.Hedge.Feature` (different database entirely).
- The caller uses @MaxTime to advance FeatureID 43 in DB_Logs.Hedge.Feature after processing.

### 2.2 Identical Reconciliation Logic to Parent

**What**: All discrepancy detection and output are identical to GetHBCEstimationsDiscrepencies.

**Rules**:
- Same JOIN: HBCExecutionLog -> Trade.GetPositionDataSlim -> Customer.Customer.
- Same GROUP BY and discrepancy filter: ExecutionAmountInLots <> SumLotDecimal.
- Same OPTION(RECOMPILE) and temp table NC indexes (ExecutionAmountInLots, SumLotDecimal).
- Same output: NotificationTime, HedgeServerID, InstrumentID, AmountInLots, IsBuy, IsOpen, Description.
- Same @MaxTime OUTPUT parameter signature.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxTime | datetime | NO | - | CODE-BACKED | OUTPUT parameter. Set internally to DATEADD(second, -@TimeRangeSeconds, GETUTCDATE()) where @TimeRangeSeconds comes from DB_Logs.Hedge.Feature FeatureID 42. Returned to caller to advance cursor in DB_Logs.Hedge.Feature FeatureID 43. Same semantics as parent's @MaxTime OUTPUT. |

**Output Columns** (identical to GetHBCEstimationsDiscrepencies parent):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | NotificationTime | datetime | NO | - | CODE-BACKED | EndTime of the discrepant execution. Inherited from parent. |
| 3 | HedgeServerID | int | NO | - | CODE-BACKED | Hedge server of the discrepant execution. Inherited from parent. |
| 4 | InstrumentID | int | NO | - | CODE-BACKED | Instrument with the lot mismatch. Inherited from parent. |
| 5 | AmountInLots | decimal | YES | - | CODE-BACKED | SumLotDecimal - ExecutionAmountInLots (lot gap). Inherited from parent. |
| 6 | IsBuy | bit | NO | - | CODE-BACKED | Customer position direction. Inherited from parent. |
| 7 | IsOpen | bit | NO | - | CODE-BACKED | Opening (1) vs closing (0) hedge. Inherited from parent. |
| 8 | Description | varchar | NO | - | CODE-BACKED | Diagnostic string with ExecutionID, lot values, IsOpen. Inherited from parent. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ExecutionID join | Hedge.HBCExecutionLog | Lookup / Read | Same as parent. |
| InitExecutionID/EndExecutionID join | Trade.GetPositionDataSlim | Cross-schema Lookup | Same Slim view as parent. |
| CID join | Customer.Customer | Cross-schema Lookup | Same PlayerLevelID filter as parent. |
| FeatureID 42, 43 | DB_Logs.Hedge.Feature | Cross-DB Config Read | Configuration source instead of Maintenance.Feature. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| HedgeAlertService (external) | @MaxTime OUTPUT | Caller | Flat-path caller; reads window from DB_Logs.Hedge.Feature and uses this variant. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetHBCEstimationsDiscrepencies_Flat (procedure)
├── Hedge.HBCExecutionLog (table)
├── Trade.GetPositionDataSlim (view) [cross-schema]
├── Customer.Customer (table) [cross-schema]
└── DB_Logs.Hedge.Feature (table) [cross-database config read - FeatureID 42, 43]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.HBCExecutionLog | Table | Same join as parent. IsSuccess=1, time window filter. |
| Trade.GetPositionDataSlim | View | Same Slim position view as parent. |
| Customer.Customer | Table | Same PlayerLevelID <> 4 filter. |
| DB_Logs.Hedge.Feature | Table | Cross-DB read: FeatureID 42 = TimeRangeSeconds, FeatureID 43 = LastTime cursor. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| HedgeAlertService (external) | Application | Called when Feature config lives in DB_Logs; advances FeatureID 43 there after receiving @MaxTime. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Runtime temp table**: `#executions` with NC indexes on ExecutionAmountInLots and SumLotDecimal (same as parent).

---

## 8. Sample Queries

### 8.1 Execute the Flat variant

```sql
DECLARE @MaxTime DATETIME;
EXEC Hedge.GetHBCEstimationsDiscrepencies_Flat @MaxTime = @MaxTime OUTPUT;
SELECT @MaxTime AS WindowUpperBound;
```

### 8.2 Check DB_Logs configuration

```sql
SELECT FeatureID,
       CASE FeatureID WHEN 42 THEN 'TimeRangeSeconds' WHEN 43 THEN 'LastTime' END AS FeatureName,
       Value
FROM   DB_Logs.Hedge.Feature
WHERE  FeatureID IN (42, 43);
```

### 8.3 Compare config between Flat and parent variants

```sql
-- Parent config source
SELECT 'Maintenance.Feature' AS Source, FeatureID, Value
FROM   Maintenance.Feature WITH (NOLOCK)
WHERE  FeatureID IN (42, 43)
UNION ALL
-- Flat config source
SELECT 'DB_Logs.Hedge.Feature' AS Source, FeatureID, Value
FROM   DB_Logs.Hedge.Feature
WHERE  FeatureID IN (42, 43);
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [HedgeServer Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11710727812) | Confluence (DROD) | HBC reconciliation family; _Flat uses DB_Logs config for feature flags. |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,9B,10,11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 parent analyzed | App Code: 2 repos searched / 0 files matched | Corrections: 0 applied*
*Object: Hedge.GetHBCEstimationsDiscrepencies_Flat | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetHBCEstimationsDiscrepencies_Flat.sql*
