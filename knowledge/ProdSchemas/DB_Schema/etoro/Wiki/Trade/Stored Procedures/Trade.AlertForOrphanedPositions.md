# Trade.AlertForOrphanedPositions

> Detects child positions (from copy trading splits) that remain open after their parent position was closed, alerts the team, and queues automated close commands for remediation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters - parameterless alert with auto-remediation) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure detects and remediates "orphaned" child positions from copy-trading operations. When a parent position is closed (e.g., a leader's position in CopyTrader), all child positions should close automatically. If the child position close fails, the child remains open in `Trade.Position` while the parent appears in `History.PositionSlim` as closed. This creates a financial discrepancy - the copier's position is still live but the leader's is gone.

This is the only alert procedure in the batch that also performs **automatic remediation**: it queues close commands into `Trade.Syn_TradeOrphanedPositionsCloseByJob` for the orphaned positions to be closed using the parent's close rate.

The detection logic: (1) find positions with ParentPositionID > 0 in Trade.Position (child positions), (2) check if parent exists in History.PositionSlim with CloseOccurred between 1 day and 5 hours ago, (3) exclude US users via Trade.IsUsUser function (US regulations may have different handling), (4) join to Trade.GetProviderToInstrument for rate precision, (5) generate close commands using the parent's EndForexRate and FullCommissionOnClose.

---

## 2. Business Logic

### 2.1 Orphan Detection Window

**What**: Detects orphans within a specific time window to avoid false positives and allow normal processing to complete.

**Rules**:
- Parent must have closed between 1 day ago and 5 hours ago (DATEADD(DAY,-1,GETUTCDATE()) to DATEADD(HOUR,-5,GETUTCDATE()))
- This gives the system 5 hours to close children normally before flagging as orphaned
- US users are excluded (IsUsUser = 0) - they may have separate handling

### 2.2 Automated Close Command Generation

**What**: Builds and queues SQL close commands for each orphaned position.

**Columns/Parameters Involved**: `PositionID`, `EndForexRate`, `FullCommissionOnClose`, `AmountInUnitsDecimal`, `LastOpConversionRate`, `Precision`, `IsBuy`

**Rules**:
- Close command calls `Trade.Syn_P_ManualPositionClose_Crisis` with OperationID=5
- BidSpread/AskSpread calculated from parent's EndForexRate adjusted by commission: BidSpread = IIF(IsBuy=1, EndForexRate, EndForexRate - Commission/Units/ConversionRate), rounded to instrument precision
- Command is wrapped in an EXISTS check to prevent closing already-closed positions
- Deduplication: only inserts if no existing entry with same PositionID + ParentPositionID and ExecuteStatus=0

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No parameters. Detects orphans, alerts, and queues remediation commands automatically. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Trade.Position (view) | READER | Child positions with ParentPositionID > 0 |
| JOIN | History.PositionSlim | READER | Parent position close details |
| JOIN | Trade.GetProviderToInstrument | READER | Rate precision for the instrument |
| LEFT JOIN | History.PositionFail | READER | Failure reasons for enrichment |
| CROSS APPLY | Trade.IsUsUser | Function call | Excludes US users |
| INSERT INTO | Trade.Syn_TradeOrphanedPositionsCloseByJob | WRITER | Queues automated close commands |
| SELECT | Maintenance.Feature | READER | Email address config (FeatureID=105) |
| EXEC | msdb.dbo.sp_send_dbmail | System call | HTML email alert |

### 5.2 Referenced By (other objects point to this)

No SQL-level dependents found.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.AlertForOrphanedPositions (procedure)
+-- Trade.Position (view)
+-- History.PositionSlim (table)
+-- Trade.GetProviderToInstrument (view/table)
+-- History.PositionFail (table)
+-- Trade.IsUsUser (function)
+-- Trade.Syn_TradeOrphanedPositionsCloseByJob (table)
+-- Maintenance.Feature (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | READER - child positions |
| History.PositionSlim | Table | READER - parent close details |
| Trade.GetProviderToInstrument | View/Table | READER - rate precision |
| History.PositionFail | Table | READER - failure reasons |
| Trade.IsUsUser | Function | Filters out US users |
| Trade.Syn_TradeOrphanedPositionsCloseByJob | Table | WRITER - queues close commands |
| Maintenance.Feature | Table | READER - email config |

### 6.2 Objects That Depend On This

No SQL-level dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Preview orphaned child positions

```sql
SELECT  S.PositionID, S.ParentPositionID, H.CloseOccurred
FROM    Trade.Position S WITH (NOLOCK)
JOIN    History.PositionSlim H WITH (NOLOCK) ON H.PositionID = S.ParentPositionID
WHERE   S.ParentPositionID > 0
        AND H.CloseOccurred BETWEEN DATEADD(DAY, -1, GETUTCDATE()) AND DATEADD(HOUR, -5, GETUTCDATE());
```

### 8.2 Check queued close commands

```sql
SELECT  TOP 20 *
FROM    Trade.Syn_TradeOrphanedPositionsCloseByJob WITH (NOLOCK)
WHERE   ExecuteStatus = 0
ORDER BY EntryDate DESC;
```

### 8.3 Run the alert

```sql
EXEC Trade.AlertForOrphanedPositions;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.AlertForOrphanedPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.AlertForOrphanedPositions.sql*
