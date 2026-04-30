# Trade.PositionsWithWrongPnLAlert

> Monitoring alert that recalculates PnL for positions closed in the last hour and sends a CSV attachment email when the calculated P&L deviates from the stored NetProfit by more than $0.02.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A (monitoring/reporting SP) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionsWithWrongPnLAlert is a scheduled data-quality monitor for the P&L calculation pipeline. After positions close, their NetProfit is stored in History.PositionSlim. This SP re-derives the expected P&L using Trade.FnCalculatePnLWrapper (the same function used during position lifecycle) and compares it to the stored NetProfit. If any position has a discrepancy exceeding $0.02, the SP sends an email to the risk/operations team with a CSV attachment containing the full discrepancy list.

This catches cases where P&L was stored incorrectly due to stale rates, calculation bugs, or data pipeline issues. The $0.02 threshold filters out trivial floating-point rounding differences.

The email recipient is sourced from Maintenance.Feature (FeatureID=105), shared with Trade.PositionsGuaranteedSLWasNotAligned.

A notable implementation quirk: the pre-check query uses `IsSettled` as the settled flag, while the email body query uses `IsDiscounted` instead, with an inline comment noting "Should be IsSettled after IsDiscounted project is done" - indicating a migration in progress at the time of creation.

---

## 2. Business Logic

### 2.1 PnL Discrepancy Pre-Check (Early Exit)

**What**: Checks if any discrepancies exist in the last hour before building the email. Exits early if none found.

**Columns/Parameters Involved**: History.PositionSlim, Trade.FnCalculatePnLWrapper, PnLInDollars, NetProfit

**Rules**:
- IF NOT EXISTS the discrepancy query -> RETURN
- Window: CloseOccurred > DATEDIFF(HOUR,-1,GETUTCDATE()) (positions closed in last 1 hour)
- Discrepancy filter: abs(PnLInDollars - NetProfit) > 0.02
- PnL recalculated via Trade.FnCalculatePnLWrapper with: InstrumentID, IsBuy, AmountInUnitsDecimal, IsSettled, InitForexRate, InitConversionRate, PnLVersion, EstimatedMarkupRatio, EstimatedConversionMarkupRatio, CurrencyID, EndForexRate, 0, LastOpConversionRate, 0

### 2.2 CSV Email Alert

**What**: When discrepancies found, sends email with attached CSV of all mismatched positions.

**Columns/Parameters Involved**: @bodyQ (dynamic SQL string), @recipients from Maintenance.Feature FeatureID=105

**Rules**:
- @bodyQ = SQL string selecting discrepancies for sp_send_dbmail @query parameter
- Email body query uses IsDiscounted (not IsSettled) - implementation artifact with comment noting pending migration
- CSV attachment: PositionList.csv, comma-separated, 10000-char width
- Subject: 'Positions with wrong PnL ({ServerName}): {date}'
- @execute_query_database = DB_NAME() - runs the attachment query in current DB
- CompensatedAmount = NetProfit - PnL.PnLInDollars (actual vs calculated delta)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No parameters. SP is called without arguments.

**Result set (CSV attachment columns)**:

| Column | Description |
|--------|-------------|
| CalculatedNetProfit | PnL recalculated by FnCalculatePnLWrapper |
| NetProfit | Stored NetProfit from History.PositionSlim |
| CID | Customer ID |
| PositionID | Position identifier |
| CloseOccurred | When the position closed |
| ActionType | Close action type (SL, TP, manual, etc.) |
| AmountInUnitsDecimal | Position size in units |
| InitForexRate | Opening rate |
| EndForexRate | Closing rate |
| CompensatedAmount | NetProfit - CalculatedNetProfit (discrepancy) |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | History.PositionSlim | DML read | Source of closed position data for PnL verification |
| CROSS APPLY | Trade.FnCalculatePnLWrapper | Function call | Recalculates expected PnL for comparison |
| SELECT | Maintenance.Feature | DML read | FeatureID=105: email recipient address |
| EXEC | msdb.dbo.sp_send_dbmail | System SP call | Sends CSV attachment email alert |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by SQL Agent job on schedule.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionsWithWrongPnLAlert (procedure)
+-- History.PositionSlim (table/view) - closed position source
+-- Trade.FnCalculatePnLWrapper (function) - PnL recalculation
+-- Maintenance.Feature (table) - email recipient (FeatureID=105)
+-- msdb.dbo.sp_send_dbmail (system SP) - email dispatch
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionSlim | Table/View | Source of closed positions for PnL verification |
| Trade.FnCalculatePnLWrapper | Function | CROSS APPLY recalculation of expected PnL |
| Maintenance.Feature | Table | Email recipient (FeatureID=105) |
| msdb.dbo.sp_send_dbmail | System SP | CSV email dispatch |

### 6.2 Objects That Depend On This

No dependents in SSDT repo. Called by SQL Agent jobs.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- $0.02 discrepancy threshold excludes floating-point rounding noise
- IsSettled vs IsDiscounted inconsistency between pre-check and email body queries is a known migration artifact
- sp_send_dbmail @query executes in current DB (DB_NAME()) - important for cross-DB deployments
- No watermark - scans all positions in last 1 hour on every run (no deduplication)

---

## 8. Sample Queries

### 8.1 Run the PnL alert manually

```sql
EXEC Trade.PositionsWithWrongPnLAlert;
```

### 8.2 Manual PnL discrepancy check (last hour)

```sql
SELECT PnL.PnLInDollars AS CalculatedNetProfit, ps.NetProfit, ps.CID, ps.PositionID,
       ps.CloseOccurred, ps.ActionType, ABS(PnL.PnLInDollars - ps.NetProfit) AS Discrepancy
FROM History.PositionSlim ps WITH (NOLOCK)
CROSS APPLY Trade.FnCalculatePnLWrapper(
    ps.InstrumentID, ps.IsBuy, ps.AmountInUnitsDecimal, ps.IsSettled,
    ps.InitForexRate, ps.InitConversionRate, ps.PnLVersion,
    ps.EstimatedMarkupRatio, ps.EstimatedConversionMarkupRatio, ps.CurrencyID,
    ps.EndForexRate, 0, ps.LastOpConversionRate, 0) AS PnL
WHERE ABS(PnL.PnLInDollars - ps.NetProfit) > 0.02
  AND ps.CloseOccurred > DATEADD(HOUR, -1, GETUTCDATE())
ORDER BY ABS(PnL.PnLInDollars - ps.NetProfit) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionsWithWrongPnLAlert | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionsWithWrongPnLAlert.sql*
