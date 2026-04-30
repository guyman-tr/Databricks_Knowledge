# Trade.PositionsGuaranteedSLWasNotAligned

> Monitoring alert that detects positions closed without Guaranteed Stop Loss settings being applied when they should have been, and sends an HTML email to the risk team.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (monitoring/reporting SP, no primary key target) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionsGuaranteedSLWasNotAligned is a scheduled monitoring procedure that detects a compliance-critical anomaly: positions that were closed by a stop-loss trigger (ActionType=1) in the last 2 hours where the Guaranteed Stop Loss (GSL) protection was not properly aligned. The indicator is `ExecutedWithoutSettings=1` in the position change log combined with `Amount < -NetProfit` (loss exceeded the position amount, which should not happen if GSL was correctly applied).

GSL (Guaranteed Stop Loss) is a product feature where the broker guarantees the SL will execute at exactly the specified rate, not subject to slippage. If a position had a GSL and it was closed without the GSL settings being aligned, it represents a potential customer protection failure.

The SP filters to non-mirror positions (MirrorID=0), positions closed by SL (ActionType=1), and applies a risk-status filter: either TradingRiskStatusID != 4 OR CountryID=74. (CountryID=74 is typically Germany, which may have additional protection requirements.)

The email recipient is read from Maintenance.Feature (FeatureID=105) rather than hardcoded, allowing dynamic configuration without a code change.

---

## 2. Business Logic

### 2.1 Detection Window and Criteria

**What**: Identifies misaligned GSL positions closed in the last 2 hours.

**Columns/Parameters Involved**: History.PositionChangeLog_Active.ChangeTypeID=6, ExecutedWithoutSettings=1, History.Position_Active.ActionType=1, Amount, NetProfit

**Rules**:
- Time window: @FromDate = DATEADD(hour,-2,GETDATE()) to @ToDate = GETDATE()
- JOIN: History.PositionChangeLog_Active (pcl) + History.Position_Active (hp) on PositionID+CID
- JOIN: BackOffice.Customer (TradingRiskStatusID), Customer.Customer (CountryID)
- ChangeTypeID=6: position close change log entries
- hp.CloseOccurred BETWEEN @FromDate AND @ToDate: position was recently closed
- pcl.Occurred BETWEEN @FromDate AND @ToDate: the change log entry is in window
- hp.ActionType=1: closed by stop loss (not manual close, not take profit)
- hp.Amount < -hp.NetProfit: loss exceeded position amount (GSL not applied - position should have been protected)
- pcl.ExecutedWithoutSettings=1: the execution occurred without the proper settings flag
- pcl.MirrorID=0: non-mirror (retail) positions only
- (bc.TradingRiskStatusID <> 4 OR cc.CountryID=74): risk filter
- OPTION(RECOMPILE): added Nov 2021 for performance

### 2.2 Alert Suppression

**What**: SP returns early if no records are found.

**Rules**:
- IF NOT EXISTS (SELECT TOP 1 * FROM #PositionChangeLog_Active) -> RETURN (no email sent)

### 2.3 HTML Email Alert

**What**: Builds and sends HTML table to risk/compliance team.

**Rules**:
- Email recipient from Maintenance.Feature WHERE FeatureID=105 (configurable, not hardcoded)
- Subject: 'List of closed positions GuaranteedSL was not aligned: {date}'
- Table columns: PositionID, CID, InstrumentID, Amount, NetProfit, TradingRiskStatusID, CountryID, CloseOccurred
- Secondary check: tableHTML compared to an expected empty-table string before sending (belt-and-suspenders guard against false sends)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No parameters. SP is called without arguments.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | History.PositionChangeLog_Active | DML read | Source of recent position close change log entries (ChangeTypeID=6) |
| JOIN | History.Position_Active | DML read | Closed position details (Amount, NetProfit, ActionType, CloseOccurred) |
| JOIN | BackOffice.Customer | DML read | TradingRiskStatusID for risk filter |
| JOIN | Customer.Customer | DML read | CountryID for regional protection filter |
| SELECT | Maintenance.Feature | DML read | FeatureID=105: email recipient address |
| EXEC | msdb.dbo.sp_send_dbmail | System SP call | Sends HTML alert email to risk team |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by SQL Agent job on schedule.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionsGuaranteedSLWasNotAligned (procedure)
+-- History.PositionChangeLog_Active (table/view) - change log source
+-- History.Position_Active (table/view) - closed position data
+-- BackOffice.Customer (table) - risk status
+-- Customer.Customer (table) - country ID
+-- Maintenance.Feature (table) - email recipient (FeatureID=105)
+-- msdb.dbo.sp_send_dbmail (system SP) - email dispatch
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionChangeLog_Active | Table/View | ChangeTypeID=6 with ExecutedWithoutSettings=1 filter |
| History.Position_Active | Table/View | Amount, NetProfit, ActionType, CloseOccurred |
| BackOffice.Customer | Table | TradingRiskStatusID for eligibility filter |
| Customer.Customer | Table | CountryID for regional filter |
| Maintenance.Feature | Table | Email recipient address (FeatureID=105) |
| msdb.dbo.sp_send_dbmail | System SP | HTML email to risk team |

### 6.2 Objects That Depend On This

No dependents in SSDT repo. Called by SQL Agent jobs.

---

## 7. Technical Details

### 7.1 Indexes

N/A. Temp table #PositionChangeLog_Active has no explicit index.

### 7.2 Constraints

- OPTION(RECOMPILE) added 2021-11-02 for performance improvement
- ActionType=1 = Stop Loss close (not take profit, not manual)
- TradingRiskStatusID=4 is excluded UNLESS CountryID=74 (special country protection rule)
- ExecutedWithoutSettings=1: this flag in PositionChangeLog_Active is the key GSL misalignment indicator

---

## 8. Sample Queries

### 8.1 Run the GSL alignment check

```sql
EXEC Trade.PositionsGuaranteedSLWasNotAligned;
```

### 8.2 Manual check for GSL misalignment (last 2 hours)

```sql
SELECT hp.PositionID, hp.CID, hp.InstrumentID, hp.Amount, hp.NetProfit,
       bc.TradingRiskStatusID, cc.CountryID, pcl.Occurred, hp.CloseOccurred
FROM History.PositionChangeLog_Active pcl WITH (NOLOCK)
JOIN History.Position_Active hp WITH (NOLOCK) ON pcl.PositionID=hp.PositionID AND pcl.CID=hp.CID
JOIN BackOffice.Customer bc WITH (NOLOCK) ON bc.CID=pcl.CID
JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID=bc.CID
WHERE pcl.Occurred BETWEEN DATEADD(hour,-2,GETDATE()) AND GETDATE()
  AND hp.CloseOccurred BETWEEN DATEADD(hour,-2,GETDATE()) AND GETDATE()
  AND pcl.ChangeTypeID=6
  AND hp.Amount < -hp.NetProfit
  AND pcl.ExecutedWithoutSettings=1
  AND hp.ActionType=1
  AND pcl.MirrorID=0
  AND (bc.TradingRiskStatusID<>4 OR cc.CountryID=74)
OPTION (RECOMPILE);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 8/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionsGuaranteedSLWasNotAligned | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionsGuaranteedSLWasNotAligned.sql*
